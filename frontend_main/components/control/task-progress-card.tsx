'use client'

import { FileText, Hammer, FlaskConical, ShieldCheck, ScrollText, ListChecks } from 'lucide-react'
import type { MissionState } from '@/lib/mission-sim'
import type { MissionTask } from '@/lib/api'

const KIND_ICON: Record<string, typeof FileText> = {
  analysis: FileText,
  plan: ListChecks,
  implement: Hammer,
  fix: Hammer,
  test: FlaskConical,
  verify: ShieldCheck,
  review: ShieldCheck,
  security: ShieldCheck,
  report: ScrollText,
}

const STATUS_STYLE: Record<MissionTask['status'], { label: string; bar: string; pct: number }> = {
  pending: { label: 'queued', bar: 'from-stone-300 to-stone-400', pct: 8 },
  in_progress: { label: 'working', bar: 'from-rose-400 to-red-500', pct: 55 },
  blocked: { label: 'blocked', bar: 'from-amber-400 to-amber-500', pct: 30 },
  done: { label: 'done', bar: 'from-emerald-400 to-emerald-500', pct: 100 },
  failed: { label: 'failed', bar: 'from-red-500 to-red-700', pct: 100 },
  cancelled: { label: 'cancelled', bar: 'from-stone-300 to-stone-400', pct: 100 },
}

const ORDER: MissionTask['status'][] = ['in_progress', 'blocked', 'pending', 'failed', 'done', 'cancelled']

export function TaskProgressCard({ mission }: { mission: MissionState }) {
  const tasks = [...mission.tasks].sort(
    (a, b) => ORDER.indexOf(a.status) - ORDER.indexOf(b.status) || b.updated_at - a.updated_at,
  )
  const done = mission.tasks.filter((t) => t.status === 'done').length

  return (
    <div className="glass-card-sm flex h-full flex-col p-3 overflow-hidden">
      <div className="flex items-center justify-between pb-1.5 shrink-0">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">Task Board</h3>
        <span className="font-mono text-[10px] text-rose-700 font-bold">
          {done}/{mission.tasks.length} done
        </span>
      </div>

      {tasks.length === 0 ? (
        <div className="flex flex-1 items-center justify-center text-center">
          <p className="text-[10px] text-[#78716c]">No tasks yet — Atlas plans once requirements are set.</p>
        </div>
      ) : (
        <div className="clean-scroll min-h-0 flex-1 space-y-2 overflow-y-auto pr-0.5" data-lenis-prevent>
          {tasks.map((task) => {
            const Icon = KIND_ICON[task.kind] ?? FileText
            const style = STATUS_STYLE[task.status] ?? STATUS_STYLE.pending
            return (
              <div key={task.id} className="flex items-center gap-2" title={task.result_summary ?? task.description}>
                <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-[#1c1917] text-rose-300 shadow-2xs">
                  <Icon className="h-3 w-3" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between pb-0.5">
                    <span className="truncate text-[10px] font-medium text-[#292524]">{task.title}</span>
                    <span className="ml-1 shrink-0 font-mono text-[9px] font-bold text-rose-700">
                      {task.assignee ? `${task.assignee} · ` : ''}
                      {style.label}
                    </span>
                  </div>
                  <div className="h-1 w-full overflow-hidden rounded-full bg-rose-100/60">
                    <div
                      className={`h-full rounded-full bg-gradient-to-r ${style.bar} transition-all duration-500`}
                      style={{ width: `${style.pct}%` }}
                    />
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
