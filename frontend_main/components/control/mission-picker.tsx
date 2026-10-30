'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { endpoints, type MissionSummary } from '@/lib/api'
import { STATUS_CLS } from './mission-board-tab'
import { Plus, RefreshCw } from 'lucide-react'

function doneRatio(m: MissionSummary): string {
  const total = Object.values(m.progress?.tasks ?? {}).reduce((a, b) => a + b, 0)
  const done = m.progress?.tasks?.done ?? 0
  return total ? `${done}/${total} tasks` : 'not planned yet'
}

/** Every mission on the backend; picking one opens it in the control room. */
export function MissionPicker({ onPick }: { onPick: (missionId: string) => void }) {
  const [missions, setMissions] = useState<MissionSummary[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  const load = () => {
    setError(null)
    endpoints
      .listMissions()
      .then((res) => setMissions(res.missions))
      .catch((err) => setError(err instanceof Error ? err.message : String(err)))
  }
  useEffect(load, [])

  return (
    <div className="glass-panel mx-auto flex h-full w-full max-w-3xl flex-col overflow-hidden">
      <div className="flex shrink-0 items-center justify-between border-b border-white/40 bg-white/30 px-5 py-3 backdrop-blur-md">
        <h3 className="text-xs font-semibold uppercase tracking-wide text-[#1c1917]">Missions</h3>
        <div className="flex items-center gap-2">
          <button
            onClick={load}
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#78716c] hover:bg-white/60"
            aria-label="Refresh"
          >
            <RefreshCw className="h-3.5 w-3.5" />
          </button>
          <Link
            href="/setup"
            className="flex items-center gap-1 rounded-full bg-[#1c1917] px-3 py-1.5 text-[11px] font-semibold text-rose-100 hover:bg-rose-950"
          >
            <Plus className="h-3 w-3" /> New mission
          </Link>
        </div>
      </div>

      <div className="clean-scroll min-h-0 flex-1 overflow-y-auto p-4" data-lenis-prevent>
        {error && <p className="rounded-xl bg-rose-50 p-3 text-xs text-rose-800">{error}</p>}
        {!error && missions === null && <p className="text-xs text-[#78716c]">Loading missions…</p>}
        {missions?.length === 0 && (
          <div className="flex h-48 flex-col items-center justify-center gap-2 text-center">
            <p className="text-sm text-[#57534e]">No missions yet.</p>
            <Link href="/setup" className="text-xs font-semibold text-rose-700 hover:underline">
              Give the guild its first request →
            </Link>
          </div>
        )}
        <ul className="space-y-2">
          {missions?.map((m) => (
            <li key={m.mission_id}>
              <button
                onClick={() => onPick(m.mission_id)}
                className="flex w-full items-center justify-between gap-3 rounded-2xl border border-white/70 bg-white/50 p-3 text-left shadow-2xs transition-all hover:bg-white/80"
              >
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-[#1c1917]">{m.title}</p>
                  <p className="text-[10px] text-[#78716c]">
                    {new Date(m.created_at).toLocaleString()} · {doneRatio(m)}
                    {m.progress?.open_issues ? ` · ${m.progress.open_issues} open question(s)` : ''}
                  </p>
                </div>
                <span className={`shrink-0 rounded-full px-2 py-0.5 text-[9px] font-bold uppercase ${STATUS_CLS[m.status] ?? ''}`}>
                  {m.status.replace('_', ' ')}
                </span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
