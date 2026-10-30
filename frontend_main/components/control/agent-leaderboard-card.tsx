'use client'

import { AgentSprite } from '@/components/pixel/agent-sprite'
import { getAgent } from '@/lib/agents'
import type { MissionState } from '@/lib/mission-sim'

/** Per-agent contribution on this mission: tasks finished and evidence captured. */
export function AgentLeaderboardCard({ mission }: { mission: MissionState }) {
  const scores = new Map<string, { tasks: number; evidence: number }>()
  const bump = (name: string | null, key: 'tasks' | 'evidence') => {
    if (!name) return
    const row = scores.get(name) ?? { tasks: 0, evidence: 0 }
    row[key] += 1
    scores.set(name, row)
  }
  mission.tasks.filter((t) => t.status === 'done').forEach((t) => bump(t.assignee, 'tasks'))
  mission.evidence.forEach((e) => bump(e.agent, 'evidence'))

  const leaders = [...scores.entries()]
    .map(([name, s]) => ({ name, ...s, score: s.tasks * 3 + s.evidence }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 6)

  return (
    <div className="glass-card-sm flex h-full flex-col p-3 overflow-hidden">
      <div className="flex items-center justify-between pb-1.5 shrink-0">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">Contributions</h3>
        <span className="font-mono text-[10px] text-rose-600 font-bold">tasks · evidence</span>
      </div>

      {leaders.length === 0 ? (
        <div className="flex flex-1 items-center justify-center text-center">
          <p className="text-[10px] text-[#78716c]">Nothing delivered yet.</p>
        </div>
      ) : (
        <div className="clean-scroll min-h-0 flex-1 space-y-1.5 overflow-y-auto" data-lenis-prevent>
          {leaders.map((leader) => {
            const def = getAgent(leader.name)
            return (
              <div
                key={leader.name}
                className="flex items-center justify-between gap-2 rounded-lg p-1 transition-colors hover:bg-rose-50/50"
              >
                <div className="flex items-center gap-2 min-w-0">
                  <div className="flex h-6 w-6 shrink-0 items-center justify-center overflow-hidden rounded-full border border-rose-200/80 bg-rose-50 shadow-2xs">
                    <AgentSprite charIdx={def?.charIdx ?? 0} scale={1} />
                  </div>
                  <div className="min-w-0">
                    <h4 className="text-[10px] font-bold text-[#1c1917] leading-tight">{leader.name}</h4>
                    <p className="truncate text-[9px] text-[#78716c] leading-tight">{def?.role ?? ''}</p>
                  </div>
                </div>
                <span className="shrink-0 font-mono text-[10px] font-bold tracking-tight text-[#1c1917]">
                  {leader.tasks} · {leader.evidence}
                </span>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
