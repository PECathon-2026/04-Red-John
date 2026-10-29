'use client'

import { FileText, Cpu, ShieldAlert, Sparkles } from 'lucide-react'
import type { MissionState } from '@/lib/mission-sim'

export function TaskProgressCard({ mission }: { mission?: MissionState }) {
  const tasks = [
    {
      id: 1,
      title: 'Synthesize regional demand clustering',
      progress: 84,
      icon: FileText,
      iconBg: 'bg-[#1c1917]',
    },
    {
      id: 2,
      title: 'Landed cost matrix across 8 lanes',
      progress: 67,
      icon: Cpu,
      iconBg: 'bg-[#1c1917]',
    },
    {
      id: 3,
      title: 'Simulate 14 disruption scenarios',
      progress: 45,
      icon: ShieldAlert,
      iconBg: 'bg-[#1c1917]',
    },
    {
      id: 4,
      title: 'Executive consensus verdict',
      progress: 28,
      icon: Sparkles,
      iconBg: 'bg-[#1c1917]',
    },
  ]

  return (
    <div className="glass-card-sm flex h-full flex-col justify-between p-3">
      {/* Header */}
      <div className="flex items-center justify-between pb-1.5">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
          Active Directives
        </h3>
        <span className="font-mono text-[10px] text-rose-750 font-bold">
          4 in progress
        </span>
      </div>

      {/* Task List */}
      <div className="space-y-2">
        {tasks.map((task) => {
          const Icon = task.icon
          return (
            <div key={task.id} className="flex items-center gap-2">
              <div
                className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-md ${task.iconBg} text-rose-300 shadow-2xs`}
              >
                <Icon className="h-3 w-3" />
              </div>

              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between pb-0.5">
                  <span className="truncate text-[10px] font-medium text-[#292524]">
                    {task.title}
                  </span>
                  <span className="ml-1 font-mono text-[9px] font-bold text-rose-700">
                    {task.progress}%
                  </span>
                </div>

                {/* Sakura Gradient Progress Bar */}
                <div className="h-1 w-full overflow-hidden rounded-full bg-rose-100/60">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-rose-400 to-red-500 transition-all duration-500"
                    style={{ width: `${task.progress}%` }}
                  />
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
