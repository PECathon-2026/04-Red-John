'use client'

import { useState } from 'react'
import { getAgent, TEAM_COLORS } from '@/lib/agents'
import { formatElapsed, type AgentState, type HireEvent } from '@/lib/mission-sim'
import { AgentSprite } from '@/components/pixel/agent-sprite'
import { HireDossierCard } from './hire-dossier-card'
import { Shield } from 'lucide-react'

export function HireCardsTab({
  hires,
  agents,
  clock,
}: {
  hires: HireEvent[]
  agents: Record<string, AgentState>
  clock: number
}) {
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const selected = selectedId != null ? hires.find((h) => h.id === selectedId) : undefined

  return (
    <div className="glass-panel flex h-full flex-col overflow-hidden">
      {/* Header */}
      <div className="flex shrink-0 items-center justify-between border-b border-white/40 bg-white/30 px-4 py-2.5 backdrop-blur-md">
        <div className="flex items-center gap-2">
          <Shield className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
            Team Personnel
          </h3>
          <span className="text-[10px] text-muted-foreground">
            ({hires.length} mobilized)
          </span>
        </div>
      </div>

      {/* Cards list */}
      <div
        className="clean-scroll min-h-0 flex-1 overflow-y-auto p-3"
        data-lenis-prevent
      >
        {hires.length === 0 ? (
          <div className="flex h-32 flex-col items-center justify-center text-center">
            <p className="text-xs text-muted-foreground">
              Reviewing mission parameters...
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2">
            {[...hires].reverse().map((hire) => (
              <IdentityCard
                key={hire.id}
                hire={hire}
                state={agents[hire.agent]}
                onOpen={() => setSelectedId(hire.id)}
              />
            ))}
          </div>
        )}
      </div>

      {selected ? (
        <HireDossierCard
          hire={selected}
          state={agents[selected.agent]}
          clock={clock}
          onClose={() => setSelectedId(null)}
        />
      ) : null}
    </div>
  )
}

function IdentityCard({
  hire,
  state,
  onOpen,
}: {
  hire: HireEvent
  state: AgentState | undefined
  onOpen: () => void
}) {
  const def = getAgent(hire.agent)
  const colors = TEAM_COLORS[hire.team]

  return (
    <button
      type="button"
      onClick={onOpen}
      className="group flex flex-col justify-between rounded-xl border border-white/60 bg-white/40 p-3 text-left backdrop-blur-md shadow-2xs transition-all hover:bg-white/60 hover:scale-[1.01]"
    >
      <div>
        <div className="flex items-center justify-between pb-1.5">
          <span
            className={`rounded-full px-2 py-0.5 text-[8px] font-bold ${
              colors ? colors.chip : 'bg-gray-100 text-gray-700'
            }`}
          >
            {hire.team}
          </span>
          <span className="rounded-full bg-rose-100/70 px-2 py-0.5 text-[8px] font-bold text-rose-800">
            {hire.clearance}
          </span>
        </div>

        <div className="flex items-center gap-2.5 py-0.5">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-rose-50/70">
            {def && <AgentSprite charIdx={def.charIdx} scale={1.4} />}
          </div>

          <div className="min-w-0 flex-1">
            <h4 className="text-xs font-semibold text-[#1c1917]">
              {hire.agent}
            </h4>
            <p className="line-clamp-1 text-[10px] text-muted-foreground">
              {hire.role}
            </p>
          </div>
        </div>
      </div>

      <div className="mt-2 flex items-center justify-between border-t border-rose-100/40 pt-1.5 text-[9px]">
        <span className="font-mono text-[#a8a29e]">
          T+{formatElapsed(hire.at)}
        </span>
        <span className="font-medium text-rose-700 group-hover:underline">
          View Dossier →
        </span>
      </div>
    </button>
  )
}
