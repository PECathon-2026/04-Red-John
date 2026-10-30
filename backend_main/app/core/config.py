"""
Typed application settings, loaded from environment variables and `.env`.

Every knob the backend has lives here. Nothing else reads `os.environ`.
"""
from __future__ import annotations

import re
from enum import StrEnum
from functools import lru_cache
from pathlib import Path
from typing import Annotated

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, PydanticBaseSettingsSource, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parents[2]


class Environment(StrEnum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"
    TEST = "test"


class StorageBackend(StrEnum):
    MEMORY = "memory"
    MONGO = "mongo"


class BusBackend(StrEnum):
    MEMORY = "memory"
    REDIS = "redis"


class ExecutionMode(StrEnum):
    INLINE = "inline"   # missions run inside the API process (dev, single box)
    QUEUE = "queue"     # the API enqueues; `python -m app.worker` processes run them


def _split_csv(value: object) -> list[str]:
    """`a,b`, `[a, b]` and `["a", "b"]` all give ["a", "b"]; blanks and duplicates are dropped."""
    if value is None:
        return []
    if isinstance(value, str):
        text = value.strip()
        if text.startswith("[") and text.endswith("]"):
            text = text[1:-1]
        parts = text.split(",")
    else:
        parts = [str(v) for v in value]  # type: ignore[union-attr]
    cleaned = (p.strip().strip("\"'").strip() for p in parts)
    return list(dict.fromkeys(p for p in cleaned if p))


_MULTILINE_LIST = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(\[[^\]]*\])", re.MULTILINE)


class _MultilineListSource(PydanticBaseSettingsSource):
    """Reads `NAME=[a, b, ...]` values that span several lines of `.env`, which python-dotenv cannot parse:

        GROQ_API_KEYS=[key1,
          key2,
          key3]

    Only bracketed values that actually span lines are taken; everything else is left to the normal reader.
    """

    def __init__(self, settings_cls: type[BaseSettings], env_file: Path | None) -> None:
        super().__init__(settings_cls)
        self._env_file = env_file

    def get_field_value(self, field, field_name):  # noqa: ANN001, ANN201 - unused; __call__ does the work
        return None, field_name, False

    def __call__(self) -> dict[str, str]:
        if self._env_file is None or not self._env_file.is_file():
            return {}
        # Key each value the way the dotenv source does (the alias for aliased fields), so it replaces that
        # source's broken one-line value instead of sitting next to it.
        names: dict[str, str] = {}
        for field_name, field in self.settings_cls.model_fields.items():
            names[field_name.lower()] = field_name
            alias = field.validation_alias
            for choice in getattr(alias, "choices", [alias] if isinstance(alias, str) else []):
                if isinstance(choice, str):
                    names[choice.lower()] = choice
        text = self._env_file.read_text(encoding="utf-8")
        found: dict[str, str] = {}
        for match in _MULTILINE_LIST.finditer(text):
            name, value = match.group(1).lower(), match.group(2)
            if "\n" in value and name in names:
                # A line break separates items too, so a missing comma at the end of a line still works.
                found[names[name]] = ",".join(line.strip() for line in value.splitlines())
        return found


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
        # List fields are Annotated with NoDecode: env values are comma-separated, not JSON.
    # Fields with env aliases (GROQ_EXTREME_POOL…) must still accept their own name in code.
        populate_by_name=True,
    )

    # ── Application ───────────────────────────────────────────────
    app_name: str = "DevPilot"
    environment: Environment = Environment.DEVELOPMENT
    debug: bool = False
    api_prefix: str = "/api/v1"
    cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: [
            "http://localhost:3000",
            "http://localhost:3001",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:3001",
        ]
    )
    # Extra origins as a regex. Outside production this defaults to any localhost port, so the
    # Flutter app's web build (`flutter run -d chrome` picks a random port) can call the API.
    # Native Android/iOS builds don't send an Origin and need no CORS entry.
    cors_origin_regex: str | None = None

    # ── Logging ───────────────────────────────────────────────────
    log_level: str = "INFO"
    log_json: bool = False

    # ── Storage / bus ─────────────────────────────────────────────
    storage_backend: StorageBackend = StorageBackend.MEMORY
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_database: str = "devpilot"
    bus_backend: BusBackend = BusBackend.MEMORY
    redis_url: str = "redis://localhost:6379/0"

    # ── LLM ───────────────────────────────────────────────────────
    # Accepts Mycel's variable names so an existing .env keeps working.
    groq_api_keys: Annotated[list[str], NoDecode] = Field(
        default_factory=list,
        validation_alias=AliasChoices("GROQ_API_KEYS", "GROQ_EXTREME_POOL"),
    )
    groq_base_url: str = "https://api.groq.com/openai/v1"
    gemini_api_keys: Annotated[list[str], NoDecode] = Field(
        default_factory=list,
        validation_alias=AliasChoices("GEMINI_API_KEYS", "GEMINI_API_KEY"),
    )
    gemini_base_url: str = "https://generativelanguage.googleapis.com/v1beta/openai"
    # Azure OpenAI (e.g. a GPT deployment in Azure AI Foundry). When a key and endpoint are set it is
    # tried first for both tiers, with Groq and then Gemini as fallbacks.
    azure_openai_api_keys: Annotated[list[str], NoDecode] = Field(
        default_factory=list,
        validation_alias=AliasChoices("AZURE_OPENAI_API_KEYS", "AZURE_OPENAI_API_KEY"),
    )
    azure_openai_endpoint: str = ""         # https://<resource>.openai.azure.com (or .cognitiveservices.azure.com)
    azure_openai_deployment: str = ""       # deployment name for the smart tier
    azure_openai_deployment_fast: str = ""  # optional cheaper deployment for the fast tier; default = the above
    # GitHub Models (free GPT access with a GitHub token that has the "Models: read" permission). When set
    # it is tried after Azure and before Groq. The free tier allows ~150 requests/day on mini models; once
    # exhausted the gateway moves on to Groq/Gemini.
    github_models_tokens: Annotated[list[str], NoDecode] = Field(
        default_factory=list,
        validation_alias=AliasChoices("GITHUB_MODELS_TOKENS", "GITHUB_MODELS_TOKEN"),
    )
    github_models_base_url: str = "https://models.github.ai/inference"
    github_models_model: str = "openai/gpt-4.1-mini"
    github_models_model_fast: str = "openai/gpt-4.1-mini"
    llm_model_smart: str = "openai/gpt-oss-120b"
    llm_model_fast: str = "openai/gpt-oss-20b"
    llm_fallback_model: str = "gemini-3.8-flash"
    llm_max_concurrency: int = 4
    llm_request_timeout_s: float = 90.0
    llm_max_attempts: int = 12
    # Per-request limits. Groq's on_demand tier rejects any single request above 8,000 tokens (input plus
    # max_tokens), so agents fit their context to this. Raise it on a paid tier or another provider.
    llm_max_request_tokens: int = 7800
    llm_max_output_tokens: int = 2000
    llm_chars_per_token: float = 3.0       # conservative estimate for JSON-heavy prompts

    # ── Sandbox ───────────────────────────────────────────────────
    data_dir: Path = BACKEND_ROOT / "var"
    command_timeout_s: int = 180
    command_max_output_chars: int = 30_000
    max_file_read_bytes: int = 400_000
    # Target repos may only be opened from under these roots. Empty = any local path.
    allowed_repo_roots: Annotated[list[Path], NoDecode] = Field(default_factory=list)

    # ── Governance ────────────────────────────────────────────────
    approval_timeout_s: int = 300
    # Approval categories that skip the human (e.g. "install" on a trusted dev box). Empty in production.
    auto_approve_categories: Annotated[list[str], NoDecode] = Field(default_factory=list)
    mission_max_tool_calls: int = 400
    mission_max_llm_tokens: int = 2_000_000
    mission_max_wall_clock_s: int = 45 * 60
    mission_max_identical_failures: int = 3
    mission_max_consecutive_failures: int = 8

    # ── Hiring (Maya) ─────────────────────────────────────────────
    hiring_threshold: float = 0.5
    hiring_llm_mandates: bool = False      # let the LLM write each hire's mandate (costs a model call per hire)
    escalate_after_failures: int = 2       # a task failing this often goes to a different specialist

    # ── Orchestration (Atlas) ─────────────────────────────────────
    orchestrator_max_parallel: int = 3     # tasks run at once when the plan allows it
    orchestrator_max_rounds: int = 60      # hard stop for one run of the decision loop
    repair_max_attempts: int = 4           # rounds of fix → re-check before a human is asked
    llm_retry_backoff_s: float = 5.0       # wait before retrying a task whose model call failed
    # When every provider is out mid-run, the agent waits and resends the same step (keeping its work)
    # this many times before giving up; only then does the task fail and restart from scratch.
    llm_outage_retries: int = 3
    llm_outage_wait_s: float = 20.0

    # ── Execution (Phase 8) ───────────────────────────────────────
    # The queue and leases use Redis when BUS_BACKEND=redis, otherwise they are in-process.
    execution_mode: ExecutionMode = ExecutionMode.INLINE
    worker_concurrency: int = 4            # missions one worker runs at once
    lease_ttl_s: float = 60.0              # a runner that stops renewing for this long loses the mission
    job_claim_after_s: float = 180.0       # a job silent this long is handed to another worker
    worker_max_deliveries: int = 5         # a mission that crashes its worker this often is failed

    # ── Security (Phase 10) ───────────────────────────────────────
    auth_enabled: bool = True              # false only on a trusted local machine; refused in production
    jwt_secret: str = ""                   # ≥ 32 chars; required in production (dev: random per process)
    jwt_ttl_minutes: int = 480
    bootstrap_admin_username: str = "admin"
    bootstrap_admin_password: str = ""     # creates this admin on first start if it does not exist
    rate_limit_enabled: bool = True
    rate_limit_per_minute: int = 600       # all API requests, per client address
    login_rate_limit_per_minute: int = 10  # per client address and username (stops password guessing)
    mission_rate_limit_per_minute: int = 20  # missions created per user
    max_request_bytes: int = 2_000_000
    metrics_enabled: bool = True

    @field_validator("groq_api_keys", "gemini_api_keys", "azure_openai_api_keys", "github_models_tokens",
                     "cors_origins", "auto_approve_categories", mode="before")
    @classmethod
    def _csv(cls, value: object) -> list[str]:
        return _split_csv(value)

    @field_validator("allowed_repo_roots", mode="before")
    @classmethod
    def _csv_paths(cls, value: object) -> list[Path]:
        return [Path(p).expanduser().resolve() for p in _split_csv(value)]

    @classmethod
    def settings_customise_sources(
        cls, settings_cls, init_settings, env_settings, dotenv_settings, file_secret_settings,  # noqa: ANN001
    ):  # noqa: ANN206
        # The dotenv source knows which file is really in use (`_env_file=` overrides the configured one).
        env_file = getattr(dotenv_settings, "env_file", None)
        if isinstance(env_file, (list, tuple)):
            env_file = env_file[-1] if env_file else None
        multiline = _MultilineListSource(settings_cls, Path(env_file) if env_file else None)
        # Real environment variables still win; multi-line lists beat dotenv's broken first-line parse.
        return init_settings, env_settings, multiline, dotenv_settings, file_secret_settings

    @property
    def workspaces_dir(self) -> Path:
        return self.data_dir / "workspaces"

    @property
    def is_production(self) -> bool:
        return self.environment == Environment.PRODUCTION

    def production_problems(self) -> list[str]:
        """Settings that are fine on a laptop but unsafe on a server. The app refuses to start with any."""
        if not self.is_production:
            return []
        problems = []
        if not self.auth_enabled:
            problems.append("AUTH_ENABLED must be true in production")
        if len(self.jwt_secret) < 32:
            problems.append("JWT_SECRET must be set (at least 32 characters) in production")
        if "*" in self.cors_origins:
            problems.append("CORS_ORIGINS must list explicit origins in production, not '*'")
        if self.auto_approve_categories:
            problems.append("AUTO_APPROVE_CATEGORIES must be empty in production")
        return problems


@lru_cache
def get_settings() -> Settings:
    return Settings()
