export type Team =
  | 'Executive'
  | 'Planning'
  | 'Forge'
  | 'Sentinel'
  | 'Shadow'
  | 'Support'
  | 'Intelligence'
  | 'Network'
  | 'Resilience'
  | 'Council'
  | 'Architecture'

export type AgentDef = {
  name: string
  team: Team
  role: string
  /* two-letter initials for the pixel portrait */
  initials: string
  /* character sprite index (0-5) — matches /assets/pixel-agents/characters/char_{n}.png */
  charIdx: number
  /* detailed description of the work this agent does */
  detail: string
  skills?: string[]
}

export type TeamStyle = {
  bg: string
  text: string
  chip: string
  cardBg: string
  cardBorder: string
  badgeBg: string
  badgeText: string
}

export const TEAM_COLORS: Record<string, TeamStyle> = {
  Executive: {
    bg: 'bg-amber-50',
    text: 'text-amber-900',
    chip: 'bg-amber-100/70 text-amber-900 border border-amber-200/50',
    cardBg: 'bg-[#fffbeb]/60',
    cardBorder: 'border-amber-200/50',
    badgeBg: 'bg-[#1c1917]',
    badgeText: 'text-amber-100',
  },
  Planning: {
    bg: 'bg-sky-50',
    text: 'text-sky-900',
    chip: 'bg-sky-100/70 text-sky-900 border border-sky-200/50',
    cardBg: 'bg-[#f0f9ff]/60',
    cardBorder: 'border-sky-200/50',
    badgeBg: 'bg-[#0c2838]',
    badgeText: 'text-sky-100',
  },
  Forge: {
    bg: 'bg-rose-50',
    text: 'text-rose-900',
    chip: 'bg-rose-100/70 text-rose-900 border border-rose-200/50',
    cardBg: 'bg-[#fff1f2]/60',
    cardBorder: 'border-rose-200/50',
    badgeBg: 'bg-[#4c0519]',
    badgeText: 'text-rose-100',
  },
  Sentinel: {
    bg: 'bg-emerald-50',
    text: 'text-emerald-900',
    chip: 'bg-emerald-100/70 text-emerald-900 border border-emerald-200/50',
    cardBg: 'bg-[#f0fdf4]/60',
    cardBorder: 'border-emerald-200/50',
    badgeBg: 'bg-[#163022]',
    badgeText: 'text-emerald-100',
  },
  Shadow: {
    bg: 'bg-purple-50',
    text: 'text-purple-900',
    chip: 'bg-purple-100/70 text-purple-900 border border-purple-200/50',
    cardBg: 'bg-[#faf5ff]/60',
    cardBorder: 'border-purple-200/50',
    badgeBg: 'bg-[#2e1065]',
    badgeText: 'text-purple-100',
  },
  Support: {
    bg: 'bg-stone-50',
    text: 'text-stone-900',
    chip: 'bg-stone-100/70 text-stone-900 border border-stone-200/50',
    cardBg: 'bg-[#fafaf9]/60',
    cardBorder: 'border-stone-200/50',
    badgeBg: 'bg-[#292524]',
    badgeText: 'text-stone-100',
  },
  Intelligence: {
    bg: 'bg-emerald-50',
    text: 'text-emerald-900',
    chip: 'bg-emerald-100/70 text-emerald-900 border border-emerald-200/50',
    cardBg: 'bg-[#f0fdf4]/60',
    cardBorder: 'border-emerald-200/50',
    badgeBg: 'bg-[#163022]',
    badgeText: 'text-emerald-100',
  },
  Network: {
    bg: 'bg-sky-50',
    text: 'text-sky-900',
    chip: 'bg-sky-100/70 text-sky-900 border border-sky-200/50',
    cardBg: 'bg-[#f0f9ff]/60',
    cardBorder: 'border-sky-200/50',
    badgeBg: 'bg-[#0c2838]',
    badgeText: 'text-sky-100',
  },
  Resilience: {
    bg: 'bg-rose-50',
    text: 'text-rose-900',
    chip: 'bg-rose-100/70 text-rose-900 border border-rose-200/50',
    cardBg: 'bg-[#fff1f2]/60',
    cardBorder: 'border-rose-200/50',
    badgeBg: 'bg-[#4c0519]',
    badgeText: 'text-rose-100',
  },
  Council: {
    bg: 'bg-purple-50',
    text: 'text-purple-900',
    chip: 'bg-purple-100/70 text-purple-900 border border-purple-200/50',
    cardBg: 'bg-[#faf5ff]/60',
    cardBorder: 'border-purple-200/50',
    badgeBg: 'bg-[#2e1065]',
    badgeText: 'text-purple-100',
  },
  Architecture: {
    bg: 'bg-pink-50',
    text: 'text-pink-900',
    chip: 'bg-pink-100/70 text-pink-900 border border-pink-200/50',
    cardBg: 'bg-[#fdf2f8]/60',
    cardBorder: 'border-pink-200/50',
    badgeBg: 'bg-[#500724]',
    badgeText: 'text-pink-100',
  },
}

export function getTeamColors(teamName: string | undefined): TeamStyle {
  if (!teamName) return TEAM_COLORS.Executive
  const normalized = teamName.charAt(0).toUpperCase() + teamName.slice(1).toLowerCase()
  return TEAM_COLORS[normalized] || TEAM_COLORS[teamName] || TEAM_COLORS.Executive
}

export const AGENTS: AgentDef[] = [
  // ── Executive (Always On) ─────────────────────────
  {
    name: 'Atlas',
    team: 'Executive',
    role: 'Mission Orchestrator (The Shogun)',
    initials: 'AT',
    charIdx: 5,
    skills: ['orchestration', 'planning', 'arbitration'],
    detail:
      'The mission orchestrator. Atlas evaluates blackboard evidence to decide next actions: continue, retry, reassign, replan, clarify, escalate, or stop with bounded autonomy.',
  },
  {
    name: 'Maya',
    team: 'Executive',
    role: 'Guild HR — Hiring Engine',
    initials: 'MA',
    charIdx: 4,
    skills: ['hiring'],
    detail:
      'Staffs the mission dynamically by matching skill requirements against available specialists, authoring custom execution mandates for each specialist.',
  },

  // ── Planning — The Shogun\'s Council ─────────────────
  {
    name: 'Kenji',
    team: 'Planning',
    role: 'Requirements Analyst',
    initials: 'KJ',
    charIdx: 0,
    skills: ['requirements', 'verification'],
    detail:
      'Deconstructs plain-language requests into concrete objectives and checkable acceptance criteria, identifying ambiguities before code is touched.',
  },
  {
    name: 'Hana',
    team: 'Planning',
    role: 'Codebase Scout',
    initials: 'HN',
    charIdx: 1,
    skills: ['recon', 'testing', 'security'],
    detail:
      'Reconnoitres the repository structure, discovers build and test commands, runs baseline tests, and flags architectural risk hotspots.',
  },
  {
    name: 'Ryo',
    team: 'Planning',
    role: 'Task Planner',
    initials: 'RY',
    charIdx: 2,
    skills: ['planning'],
    detail:
      'Translates objectives and codebase reconnaissance into a dependency-ordered DAG of tasks, dynamically replanning if blockers or unexpected conditions arise.',
  },

  // ── Samurai Forge — Implementation ──────────────────
  {
    name: 'Takeshi',
    team: 'Forge',
    role: 'Backend Engineer',
    initials: 'TK',
    charIdx: 3,
    skills: ['python', 'api', 'backend', 'data'],
    detail:
      'Constructs backend features, APIs, database logic, and data pipelines with strict adherence to repository conventions and typing.',
  },
  {
    name: 'Yuki',
    team: 'Forge',
    role: 'Frontend Engineer',
    initials: 'YK',
    charIdx: 4,
    skills: ['frontend', 'javascript', 'typescript', 'react', 'css'],
    detail:
      'Crafts user interfaces, components, reactive states, and browser flows, ensuring seamless frontend-to-backend communication.',
  },
  {
    name: 'Daichi',
    team: 'Forge',
    role: 'Debugger & Triage Specialist',
    initials: 'DC',
    charIdx: 5,
    skills: ['debugging', 'fix', 'triage'],
    detail:
      'Diagnoses test failures, stack traces, and unhandled regressions, discovering root causes and executing surgical repairs.',
  },
  {
    name: 'Sora',
    team: 'Forge',
    role: 'Refactoring & Style Keeper',
    initials: 'SR',
    charIdx: 0,
    skills: ['refactor', 'style', 'lint'],
    detail:
      'Guarantees codebase hygiene, simplifies complex control flow, removes dead code, and resolves linter warnings without altering runtime behaviour.',
  },

  // ── Sentinel Dojo — Testing & Verification ──────────
  {
    name: 'Aiko',
    team: 'Sentinel',
    role: 'Test Runner',
    initials: 'AK',
    charIdx: 1,
    skills: ['test_runner', 'lint', 'build'],
    detail:
      'Executes test suites (pytest, jest, cargo, go) and captures verifiable test execution logs as evidence on the shared mission board.',
  },
  {
    name: 'Riku',
    team: 'Sentinel',
    role: 'Test Author',
    initials: 'RK',
    charIdx: 2,
    skills: ['test_author', 'testing'],
    detail:
      'Authors unit and regression tests for uncovered code and bug reproductions, ensuring changes are fortified before verification.',
  },
  {
    name: 'Mei',
    team: 'Sentinel',
    role: 'Independent Verifier',
    initials: 'ME',
    charIdx: 3,
    skills: ['verification'],
    detail:
      'Operates in read-only mode to independently audit acceptance criteria against recorded test runs and diff evidence before sign-off.',
  },

  // ── Shadow Council — Review & Security ──────────────
  {
    name: 'Haruto',
    team: 'Shadow',
    role: 'Code Reviewer',
    initials: 'HR',
    charIdx: 4,
    skills: ['review'],
    detail:
      'Inspects unified git diffs for maintainability, edge cases, backwards compatibility, and unintended side effects, recording formal findings.',
  },
  {
    name: 'Kaito',
    team: 'Shadow',
    role: 'Security Inspector',
    initials: 'KT',
    charIdx: 5,
    skills: ['security', 'audit'],
    detail:
      'Conducts static analysis for leaked secrets, injection vulnerabilities (SQL, shell), unsafe deserialization, and unvalidated inputs.',
  },
  {
    name: 'Emi',
    team: 'Shadow',
    role: 'Arbiter',
    initials: 'EM',
    charIdx: 0,
    skills: ['arbitration'],
    detail:
      'Resolves disputes between developers and reviewers based strictly on evidence, escalating to the human operator if irreconcilable.',
  },

  // ── Support ─────────────────────────────────────────
  {
    name: 'Scribe',
    team: 'Support',
    role: 'Evidence Scribe',
    initials: 'SC',
    charIdx: 1,
    skills: ['report', 'documentation'],
    detail:
      'Compiles the final mission evidence report, categorizing changes into verified facts vs agent claims with links to test artifacts.',
  },

  // ── Compatibility / Legacy Agents ───────────────────
  {
    name: 'Mira',
    team: 'Intelligence',
    role: 'Demand & assortment intelligence',
    initials: 'MI',
    charIdx: 0,
    detail: 'Maps demand, market size, and customer geography.',
  },
  {
    name: 'Ravi',
    team: 'Intelligence',
    role: 'Supplier intelligence',
    initials: 'RA',
    charIdx: 1,
    detail: 'Builds candidate supplier profiles and verifies capabilities.',
  },
  {
    name: 'Anika',
    team: 'Intelligence',
    role: 'Category benchmarking',
    initials: 'AN',
    charIdx: 2,
    detail: 'Benchmarks industry structures and lead times.',
  },
  {
    name: 'Noor',
    team: 'Intelligence',
    role: 'Geopolitical risk intelligence',
    initials: 'NO',
    charIdx: 3,
    detail: 'Scores route & region exposure to external shocks.',
  },
  {
    name: 'Dev',
    team: 'Network',
    role: 'Procurement & landed cost',
    initials: 'DE',
    charIdx: 5,
    detail: 'Calculates total landed cost and freight metrics.',
  },
  {
    name: 'Rohan',
    team: 'Architecture',
    role: 'Master system architect',
    initials: 'RO',
    charIdx: 0,
    detail: 'Assembles architectural topology and infrastructure blueprints.',
  },
]

export function getAgent(name: string): AgentDef {
  const found = AGENTS.find((a) => a.name.toLowerCase() === name.toLowerCase())
  if (found) return found

  // Fallback definition for any custom agent
  return {
    name,
    team: 'Support',
    role: 'Engineering Specialist',
    initials: name.slice(0, 2).toUpperCase(),
    charIdx: Math.abs(name.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0)) % 6,
    detail: `Guild specialist ${name} assigned to the mission.`,
  }
}

export const ARMORIQ_URL =
  process.env.NEXT_PUBLIC_ARMORIQ_URL || 'https://platform.armoriq.ai/dashboard/api'
