'use client'

import Link from 'next/link'
import { ArrowRight, Users } from 'lucide-react'
import { AGENTS, type AgentDef } from '@/lib/agents'
import { TeamCard } from '@/components/theme/team-card'

export function AgentCardsSidebar({
  onSelectAgent,
}: {
  onSelectAgent?: (agent: AgentDef) => void
}) {
  // Featured Organization Leads
  const featuredLeaderNames = ['Atlas', 'Maya', 'Kenji']
  const featuredAgents = featuredLeaderNames
    .map((name) => AGENTS.find((a) => a.name === name))
    .filter(Boolean) as AgentDef[]

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
        {featuredAgents.map((agent, idx) => (
          <TeamCard
            key={agent.name}
            index={idx}
            name={agent.name}
            title={agent.role}
            department={agent.team}
            status="working"
            avatar={agent.charIdx}
            onOpenDetails={() => onSelectAgent?.(agent)}
            className="p-3.5 sm:p-4"
          />
        ))}
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
