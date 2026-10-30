'use client'

import { useMemo } from 'react'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { formatElapsed, type MissionState } from '@/lib/mission-sim'

const BUCKETS = 12

/** Mission activity over time: Atlas log lines, and checks that passed or failed. */
export function PerformanceChart({ mission }: { mission: MissionState }) {
  const data = useMemo(() => {
    const span = Math.max(mission.clock, ...mission.logs.map((l) => l.at), 1)
    const size = span / BUCKETS
    const rows = Array.from({ length: BUCKETS }, (_, i) => ({
      t: formatElapsed((i + 1) * size),
      activity: 0,
      passed: 0,
      failed: 0,
    }))
    const slot = (at: number) => Math.min(BUCKETS - 1, Math.max(0, Math.floor(at / size)))
    mission.logs.forEach((l) => rows[slot(l.at)].activity++)
    mission.evidence.forEach((e) => {
      if (e.passed === true) rows[slot(e.at)].passed++
      else if (e.passed === false) rows[slot(e.at)].failed++
    })
    return rows
  }, [mission.clock, mission.logs, mission.evidence])

  const empty = mission.logs.length === 0 && mission.evidence.length === 0

  return (
    <div className="glass-card-sm flex h-full flex-col justify-between p-3">
      <div className="flex items-center justify-between pb-1">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">Mission Activity</h3>
        <div className="flex items-center gap-2.5 text-[9px]">
          <Legend color="#f43f5e" label="Events" />
          <Legend color="#10b981" label="Checks passed" />
          <Legend color="#f59e0b" label="Checks failed" />
        </div>
      </div>

      <div className="relative h-28 w-full pt-1">
        {empty && (
          <p className="absolute inset-0 z-10 flex items-center justify-center text-[10px] text-[#78716c]">
            Waiting for the first events…
          </p>
        )}
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 4, right: 4, left: -28, bottom: 0 }}>
            <defs>
              <linearGradient id="gEvents" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#f43f5e" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="gPassed" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#10b981" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="gFailed" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#f59e0b" stopOpacity={0.0} />
              </linearGradient>
            </defs>
            <XAxis dataKey="t" axisLine={false} tickLine={false} tick={{ fill: '#a8a29e', fontSize: 9 }} interval="preserveStartEnd" />
            <YAxis axisLine={false} tickLine={false} tick={{ fill: '#a8a29e', fontSize: 9 }} allowDecimals={false} />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                backdropFilter: 'blur(12px)',
                borderRadius: '12px',
                border: '1px solid rgba(251, 207, 232, 0.6)',
                fontSize: '11px',
              }}
            />
            <Area type="monotone" dataKey="activity" name="Events" stroke="#f43f5e" strokeWidth={1.8} fill="url(#gEvents)" />
            <Area type="monotone" dataKey="passed" name="Checks passed" stroke="#10b981" strokeWidth={1.8} fill="url(#gPassed)" />
            <Area type="monotone" dataKey="failed" name="Checks failed" stroke="#f59e0b" strokeWidth={1.8} fill="url(#gFailed)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <div className="flex items-center gap-1">
      <span className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: color }} />
      <span className="text-[#78716c]">{label}</span>
    </div>
  )
}
