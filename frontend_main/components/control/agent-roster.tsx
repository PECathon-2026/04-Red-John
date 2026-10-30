'use client'

import { useState } from 'react'
import { TEAM_ORDER, useGuild, type AgentDef, type Team } from '@/lib/agents'
import type { AgentState } from '@/lib/mission-sim'
import { TeamCard } from '@/components/theme/team-card'
import { AgentDossierCard } from './agent-dossier-card'
import { Search, Users } from 'lucide-react'

const TEAMS: (Team | 'All')[] = ['All', ...TEAM_ORDER]

export function AgentRosterTab({
  agents,
  clock,
}: {
  agents: Record<string, AgentState>
  clock: number
}) {
  const [selectedTeam, setSelectedTeam] = useState<Team | 'All'>('All')
  const [search, setSearch] = useState('')
  const [activeDossier, setActiveDossier] = useState<AgentDef | null>(null)

  const { agents: guild, error } = useGuild()
  const filtered = guild.filter((a) => {
    const matchesTeam = selectedTeam === 'All' || a.team === selectedTeam
    const matchesSearch =
      a.name.toLowerCase().includes(search.toLowerCase()) ||
      a.role.toLowerCase().includes(search.toLowerCase())
    return matchesTeam && matchesSearch
  })

  return (
    <div className="japan-glass-card flex h-full flex-col overflow-hidden">
      {/* ── Header & Filter Bar ── */}
      <div className="shrink-0 border-b border-white/60 bg-white/40 p-4 backdrop-blur-xl">
        <div className="flex items-center justify-between gap-3 pb-3">
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-[#1D1D1F] text-rose-200 shadow-sm">
              <Users className="h-4 w-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold tracking-tight text-[#1D1D1F]">
                Specialist Directory
              </h3>
              <p className="text-[11px] font-normal text-[#2B2B2B]/65">
                {guild.length} specialists in the guild · {Object.keys(agents).length} on this mission
              </p>
            </div>
          </div>

          {/* Search Input */}
          <div className="relative w-44 sm:w-52">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Filter specialists..."
              className="w-full rounded-full border border-white/70 bg-white/60 px-3 py-1.5 pl-7.5 text-xs text-[#1D1D1F] outline-none placeholder:text-[#8c827a] shadow-xs backdrop-blur-md focus:border-rose-400 focus:bg-white"
            />
            <Search className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#8c827a]" />
          </div>
        </div>

        {/* Team Filter Pills */}
        <div className="flex flex-wrap gap-1.5 pt-0.5">
          {TEAMS.map((team) => {
            const isSelected = selectedTeam === team

            return (
              <button
                key={team}
                type="button"
                onClick={() => setSelectedTeam(team)}
                className={`flex items-center rounded-full px-3 py-1 text-[11px] font-medium transition-all ${
                  isSelected
                    ? 'bg-[#1D1D1F] text-rose-100 shadow-sm'
                    : 'bg-white/50 text-[#2B2B2B]/75 hover:bg-white/80'
                }`}
              >
                <span>{team}</span>
              </button>
            )
          })}
        </div>
      </div>

      {/* ── Vertical List of Team Cards (1-Column inside side panel so cards never crumble) ── */}
      <div
        className="clean-scroll min-h-0 flex-1 overflow-y-auto p-3.5 space-y-3"
        data-lenis-prevent
      >
        {filtered.map((agent, idx) => {
          const state = agents[agent.name]
          const phase = state?.phase ?? 'standby'

          return (
            <TeamCard
              key={agent.name}
              index={idx}
              name={agent.name}
              title={state?.task || agent.role}
              department={agent.team}
              status={phase}
              avatar={agent.charIdx}
              onOpenDetails={() => setActiveDossier(agent)}
            />
          )
        })}

        {filtered.length === 0 && (
          <div className="flex h-48 flex-col items-center justify-center text-center">
            <p className="text-xs font-medium text-[#2B2B2B]/60">
              {error ? `Could not load the guild: ${error}` : 'No specialists match the search.'}
            </p>
          </div>
        )}
      </div>

      {/* ── Active Specialist Dossier Modal ── */}
      {activeDossier && (
        <AgentDossierCard
          agent={activeDossier}
          onClose={() => setActiveDossier(null)}
        />
      )}
    </div>
  )
}
