'use client'

/**
 * The DevPilot guild, loaded from the backend (`GET /api/v1/agents`).
 * Components read it through `useGuild()`; `getAgent()` answers from the
 * last loaded roster.
 */

import { useEffect, useState } from 'react'
import { endpoints, type GuildAgent } from './api'

export type Team = 'Executive' | 'Planning' | 'Forge' | 'Sentinel' | 'Shadow' | 'Support'

export const TEAM_ORDER: Team[] = ['Executive', 'Planning', 'Forge', 'Sentinel', 'Shadow', 'Support']

export const TEAM_BLURBS: Record<Team, string> = {
  Executive: 'Atlas orchestrates the mission; Maya hires the specialists it needs.',
  Planning: 'Turns the request into acceptance criteria, recon notes and a task plan.',
  Forge: 'Writes, fixes and refactors the code inside the sandbox.',
  Sentinel: 'Authors and runs tests, then independently verifies every criterion.',
  Shadow: 'Reviews the change, scans it for security issues and arbitrates disputes.',
  Support: 'Writes the evidence report a human reads before approving.',
}

export type AgentDef = {
  name: string
  team: Team
  role: string
  /* two-letter initials for the pixel portrait */
  initials: string
  /* character sprite index (0-5) — matches /assets/pixel-agents/characters/char_{n}.png */
  charIdx: number
  /* what this agent is for (its default mandate) */
  detail: string
  badge: string
  skills: string[]
  tools: string[]
  clearance: 'GREEN' | 'AMBER'
  alwaysOn: boolean
}

type TeamColors = {
  bg: string
  text: string
  chip: string
  cardBg: string
  cardBorder: string
  badgeBg: string
  badgeText: string
}

export const TEAM_COLORS: Record<Team, TeamColors> = {
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
}

/** Backend team ids are lower-case ("forge"); hire events capitalise them. */
export function toTeam(team: string | null | undefined): Team {
  const t = (team ?? '').trim().toLowerCase()
  const match = TEAM_ORDER.find((name) => name.toLowerCase() === t)
  return match ?? 'Support'
}

export function teamColors(team: string | null | undefined): TeamColors {
  return TEAM_COLORS[toTeam(team)]
}

function fromBackend(a: GuildAgent): AgentDef {
  return {
    name: a.name,
    team: toTeam(a.team),
    role: a.role,
    initials: a.name.slice(0, 2).toUpperCase(),
    charIdx: a.char_idx,
    detail: a.default_mandate,
    badge: a.badge,
    skills: a.skills,
    tools: a.tools,
    clearance: a.clearance,
    alwaysOn: a.always_on,
  }
}

/* ------------------------------------------------------------------ */
/* Roster store                                                         */
/* ------------------------------------------------------------------ */

let roster: AgentDef[] = []
let inflight: Promise<AgentDef[]> | null = null
const listeners = new Set<(agents: AgentDef[]) => void>()

export function loadGuild(force = false): Promise<AgentDef[]> {
  if (roster.length && !force) return Promise.resolve(roster)
  if (!inflight) {
    inflight = endpoints
      .agents()
      .then((res) => {
        roster = res.agents.map(fromBackend)
        listeners.forEach((fn) => fn(roster))
        return roster
      })
      .finally(() => {
        inflight = null
      })
  }
  return inflight
}

export function useGuild(): { agents: AgentDef[]; loading: boolean; error: string | null } {
  const [agents, setAgents] = useState<AgentDef[]>(roster)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    listeners.add(setAgents)
    loadGuild().catch((err) => setError(err instanceof Error ? err.message : String(err)))
    return () => {
      listeners.delete(setAgents)
    }
  }, [])

  return { agents, loading: agents.length === 0 && !error, error }
}

export function getAgent(name: string): AgentDef | undefined {
  return roster.find((a) => a.name === name)
}
