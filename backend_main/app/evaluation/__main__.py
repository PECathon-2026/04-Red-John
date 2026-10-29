"""
Run the PS-001 evaluation scenarios.

    python -m app.evaluation --missions ../missions --mode both --out ../docs/runs/eval
    python -m app.evaluation --scenario 03-failing-test-durations --mode guild

Uses the normal settings (.env / environment) for the LLM keys. Missions run inline, one at a time.
AMBER approvals have no human here, so they time out (and count as denied) after --approval-timeout.
"""
from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from app.container import Container
from app.core.config import ExecutionMode, get_settings
from app.core.logging import configure_logging
from app.evaluation.harness import export_run, run_baseline, run_guild
from app.evaluation.scenarios import list_scenarios


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--missions", type=Path, default=Path(__file__).resolve().parents[3] / "missions")
    parser.add_argument("--scenario", action="append", help="scenario id (repeatable); default: all")
    parser.add_argument("--mode", choices=["guild", "baseline", "both"], default="both")
    parser.add_argument("--out", type=Path, default=Path("evaluation-runs"))
    parser.add_argument("--approval-timeout", type=int, default=20)
    args = parser.parse_args()

    settings = get_settings().model_copy(update={"execution_mode": ExecutionMode.INLINE,
                                                 "approval_timeout_s": args.approval_timeout})
    configure_logging("WARNING", settings.log_json)
    scenarios = [s for s in list_scenarios(args.missions) if not args.scenario or s.id in args.scenario]
    modes = ["guild", "baseline"] if args.mode == "both" else [args.mode]
    container = Container.build(settings)
    await container.start()
    summary = []
    try:
        for scenario in scenarios:
            for mode in modes:
                print(f"▶ {scenario.id} [{mode}] …", flush=True)
                runner = run_guild if mode == "guild" else run_baseline
                result = await runner(container, scenario)
                out = await export_run(container, scenario, result, args.out)
                print(f"  {result.outcome:15} hidden checks {'PASS' if result.hidden.passed else 'FAIL'}  "
                      f"{result.metrics['duration_s']}s  {result.metrics['llm_tokens']:,} tokens  → {out}", flush=True)
                summary.append(result.model_dump(mode="json") | {"verified_success": result.verified_success})
    finally:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "summary.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
        await container.stop()


if __name__ == "__main__":
    asyncio.run(main())
