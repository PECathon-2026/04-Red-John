'use client'

import { useState } from 'react'
import { Search, Sparkles } from 'lucide-react'
import { useGuild, type AgentDef } from '@/lib/agents'
import type { MissionState } from '@/lib/mission-sim'
import { TeamCard } from '@/components/theme/team-card'

/** The mission's task force (Atlas, Maya and whoever Maya hired), with live status. */
export function AgentCardsSidebar({
  mission,
  onSelectAgent,
}: {
  mission: MissionState
  onSelectAgent?: (agent: AgentDef) => void
}) {
  const { agents: guild, error } = useGuild()
  const [search, setSearch] = useState('')

  const onMission = new Set(Object.keys(mission.agents))
  const q = search.trim().toLowerCase()
  const list = guild.filter((a) =>
    q
      ? a.name.toLowerCase().includes(q) || a.role.toLowerCase().includes(q) || a.team.toLowerCase().includes(q)
      : onMission.has(a.name),
  )
  // Working agents first.
  const rank = (a: AgentDef) => (mission.agents[a.name]?.phase === 'working' ? 0 : mission.agents[a.name] ? 1 : 2)
  list.sort((a, b) => rank(a) - rank(b))

  return (
    <div className="flex h-full flex-col overflow-hidden">
      <div className="flex items-center justify-between pb-2 shrink-0">
        <div className="flex items-center gap-1.5">
          <Sparkles className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-bold tracking-wide text-[#1D1D1F] uppercase">Task Force</h3>
        </div>
        <span className="text-[10px] font-medium text-[#2B2B2B]/60">
          {q ? `${list.length} found` : `${onMission.size} on mission`}
        </span>
      </div>

      <div className="pb-2 shrink-0">
        <div className="flex items-center rounded-full border border-white/70 bg-white/50 p-1 pl-3 pr-1 backdrop-blur-md shadow-xs transition-all focus-within:border-rose-400 focus-within:bg-white/80">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search the guild..."
            className="w-full bg-transparent text-xs text-[#1D1D1F] outline-none placeholder:text-[#8c827a]"
          />
          <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[#1D1D1F] text-white">
            <Search className="h-2.5 w-2.5" />
          </span>
        </div>
      </div>

      <div className="space-y-2.5" data-lenis-prevent>
        {list.map((agent, idx) => (
          <TeamCard
            key={agent.name}
            index={idx}
            name={agent.name}
            title={mission.agents[agent.name]?.task || agent.role}
            department={agent.team}
            status={mission.agents[agent.name]?.phase ?? 'standby'}
            avatar={agent.charIdx}
            onOpenDetails={() => onSelectAgent?.(agent)}
            className="p-3.5 sm:p-4"
          />
        ))}

        {list.length === 0 && (
          <div className="flex h-24 flex-col items-center justify-center text-center">
            <p className="text-xs text-[#2B2B2B]/60">
              {error ? `Could not load the guild: ${error}` : q ? `No specialists match "${search}".` : 'No one on the mission yet.'}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
