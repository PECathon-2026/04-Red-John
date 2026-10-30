'use client'

import Link from 'next/link'
import { ArrowRight, Users } from 'lucide-react'
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

  const onMission = new Set(Object.keys(mission.agents))
  const list = guild.filter((a) => onMission.has(a.name))
  // Working agents first.
  const rank = (a: AgentDef) => (mission.agents[a.name]?.phase === 'working' ? 0 : mission.agents[a.name] ? 1 : 2)
  list.sort((a, b) => rank(a) - rank(b))

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between pb-2.5 shrink-0">
        <h3 className="text-xs font-bold tracking-wide text-[#1D1D1F] uppercase">
          Specialist Leads
        </h3>
        <Link
          href="/team"
          className="flex items-center gap-1 rounded-full border border-rose-200 bg-rose-50 px-2.5 py-0.5 text-[10px] font-bold text-rose-700 shadow-2xs transition-all hover:bg-rose-600 hover:text-white hover:border-rose-600 hover:scale-105 active:scale-95 group"
          title="Open complete 21 Specialists Guild"
        >
          <span>View All</span>
          <ArrowRight className="h-2.5 w-2.5 transition-transform group-hover:translate-x-0.5" />
        </Link>
      </div>

      {/* Cards Area with Un-crushable TeamCards */}
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
              {error ? `Could not load the guild: ${error}` : 'No one on the mission yet.'}
            </p>
          </div>
        )}
      </div>

      {/* View All Roster footer button */}
      <div className="pt-2.5 shrink-0">
        <Link
          href="/team"
          className="flex w-full items-center justify-center gap-1.5 rounded-xl border border-rose-200/70 bg-white/70 py-2 text-xs font-semibold text-rose-900 shadow-2xs backdrop-blur-md transition-all hover:bg-white hover:border-rose-400 hover:scale-[1.01] active:scale-95 group"
        >
          <Users className="h-3.5 w-3.5 text-rose-600" />
          <span>View All 21 Specialists</span>
          <ArrowRight className="h-3 w-3 text-rose-600 transition-transform group-hover:translate-x-0.5" />
        </Link>
      </div>
    </div>
  )
}
