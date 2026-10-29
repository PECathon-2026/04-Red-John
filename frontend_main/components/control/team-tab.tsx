'use client'

import { useState } from 'react'
import { AGENTS, TEAM_COLORS, type AgentDef, type Team } from '@/lib/agents'
import { AgentSprite } from '@/components/pixel/agent-sprite'
import { AgentDossierCard } from './agent-dossier-card'
import { Users, ArrowRight } from 'lucide-react'

const TEAM_ORDER: Team[] = [
  'Executive',
  'Intelligence',
  'Network',
  'Resilience',
  'Council',
  'Architecture',
]

export function TeamTab() {
  const [selected, setSelected] = useState<AgentDef | null>(null)

  return (
    <div className="flex h-full flex-col bg-[#faf9fe]">
      <div className="clean-scroll min-h-0 flex-1 overflow-y-auto p-6">
        <div className="space-y-8">
          {TEAM_ORDER.map((team) => {
            const members = AGENTS.filter((a) => a.team === team)
            const colors = TEAM_COLORS[team]

            return (
              <div key={team}>
                <div className="flex items-center gap-2.5 pb-3">
                  <span
                    className={`rounded-full px-3 py-1 text-xs font-bold ${colors.chip}`}
                  >
                    {team} Cabin
                  </span>
                  <span className="text-xs text-muted-foreground">
                    ({members.length} specialists)
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  {members.map((agent) => (
                    <button
                      key={agent.name}
                      onClick={() => setSelected(agent)}
                      className="group flex items-center gap-3.5 rounded-2xl border border-black/[0.04] bg-white p-3.5 text-left shadow-xs transition-all hover:scale-[1.01] hover:shadow-md"
                    >
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-purple-50">
                        <AgentSprite charIdx={agent.charIdx} scale={1.8} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <h4 className="text-xs font-bold text-[#1c1a2e]">
                          {agent.name}
                        </h4>
                        <p className="line-clamp-2 text-[11px] text-muted-foreground leading-snug">
                          {agent.role}
                        </p>
                      </div>
                      <ArrowRight className="h-4 w-4 text-purple-400 opacity-0 transition-opacity group-hover:opacity-100" />
                    </button>
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {selected && (
        <AgentDossierCard agent={selected} onClose={() => setSelected(null)} />
      )}
    </div>
  )
}

