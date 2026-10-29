'use client'

import { AgentSprite } from '@/components/pixel/agent-sprite'

export function AgentLeaderboardCard() {
  const leaders = [
    {
      name: 'Atlas',
      role: 'Lead Architect',
      score: '6,715',
      avatarIdx: 5,
    },
    {
      name: 'Maya',
      role: 'Resource Allocator',
      score: '5,104',
      avatarIdx: 4,
    },
    {
      name: 'Mira',
      role: 'Demand Intel',
      score: '3,235',
      avatarIdx: 0,
    },
    {
      name: 'Dev',
      role: 'Landed Cost',
      score: '1,969',
      avatarIdx: 5,
    },
  ]

  return (
    <div className="glass-card-sm flex h-full flex-col justify-between p-3">
      {/* Header */}
      <div className="flex items-center justify-between pb-1.5">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
          Mastery Ranks
        </h3>
        <span className="font-mono text-[10px] text-rose-600 font-bold">
          Top Ranked
        </span>
      </div>

      {/* Agents Ranks */}
      <div className="space-y-1.5">
        {leaders.map((leader, i) => (
          <div
            key={leader.name}
            className="flex items-center justify-between gap-2 rounded-lg p-1 transition-colors hover:bg-rose-50/50"
          >
            <div className="flex items-center gap-2">
              <div className="flex h-6 w-6 shrink-0 items-center justify-center overflow-hidden rounded-full border border-rose-200/80 bg-rose-50 shadow-2xs">
                <AgentSprite charIdx={leader.avatarIdx} scale={1} />
              </div>

              <div>
                <h4 className="text-[10px] font-bold text-[#1c1917] leading-tight">
                  {leader.name}
                </h4>
                <p className="text-[9px] text-[#78716c] leading-tight">
                  {leader.role}
                </p>
              </div>
            </div>

            <span className="font-mono text-[10px] font-bold tracking-tight text-[#1c1917]">
              {leader.score}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
