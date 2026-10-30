'use client'

import { useState } from 'react'
import { Search, Sparkles } from 'lucide-react'
import { AGENTS, type AgentDef } from '@/lib/agents'
import { TeamCard } from '@/components/theme/team-card'

export function AgentCardsSidebar({
  onSelectAgent,
}: {
  onSelectAgent?: (agent: AgentDef) => void
}) {
  const [search, setSearch] = useState('')

  // Featured Organization Leads
  const featuredLeaderNames = ['Atlas', 'Maya', 'Kenji']
  const featuredAgents = featuredLeaderNames
    .map((name) => AGENTS.find((a) => a.name === name))
    .filter(Boolean) as AgentDef[]

  const filteredAgents = AGENTS.filter(
    (a) =>
      a.name.toLowerCase().includes(search.toLowerCase()) ||
      a.role.toLowerCase().includes(search.toLowerCase()) ||
      a.team.toLowerCase().includes(search.toLowerCase()),
  )

  const displayList = search.trim() ? filteredAgents : featuredAgents

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between pb-2 shrink-0">
        <div className="flex items-center gap-1.5">
          <Sparkles className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-bold tracking-wide text-[#1D1D1F] uppercase">
            Specialist Leads
          </h3>
        </div>
        <span className="text-[10px] font-medium text-[#2B2B2B]/60">
          {search.trim() ? `${filteredAgents.length} found` : '3 Team Leads'}
        </span>
      </div>

      {/* Minimalist Glass Search Pill */}
      <div className="pb-2 shrink-0">
        <div className="flex items-center rounded-full border border-white/70 bg-white/50 p-1 pl-3 pr-1 backdrop-blur-md shadow-xs transition-all focus-within:border-rose-400 focus-within:bg-white/80">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search team specialists..."
            className="w-full bg-transparent text-xs text-[#1D1D1F] outline-none placeholder:text-[#8c827a]"
          />
          <button
            type="button"
            aria-label="Search"
            className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[#1D1D1F] text-white hover:bg-rose-900 transition-colors"
          >
            <Search className="h-2.5 w-2.5" />
          </button>
        </div>
      </div>

      {/* Cards Area with Un-crushable TeamCards */}
      <div className="space-y-2.5" data-lenis-prevent>
        {displayList.map((agent, idx) => (
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

        {displayList.length === 0 && (
          <div className="flex h-28 flex-col items-center justify-center text-center">
            <p className="text-xs text-[#2B2B2B]/60">
              No specialists found for &quot;{search}&quot;.
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
