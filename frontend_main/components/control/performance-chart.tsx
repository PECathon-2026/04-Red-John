'use client'

import { useState } from 'react'
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'

const MOCK_WEEKLY_DATA = [
  { day: 'Sun', shinobi: 32, samurai: 45, shogun: 22 },
  { day: 'Mon', shinobi: 38, samurai: 50, lexicon: 32 },
  { day: 'Tue', shinobi: 35, samurai: 56, shogun: 30 },
  { day: 'Wed', shinobi: 48, samurai: 62, shogun: 42 },
  { day: 'Thu', shinobi: 60, samurai: 70, shogun: 50 },
  { day: 'Fri', shinobi: 85, samurai: 78, shogun: 65 },
  { day: 'Sat', shinobi: 75, samurai: 68, shogun: 55 },
]

export function PerformanceChart() {
  const [timeframe, setTimeframe] = useState<'Weekly' | 'Daily'>('Weekly')

  return (
    <div className="glass-card-sm flex h-full flex-col justify-between p-3">
      {/* Minimal Header */}
      <div className="flex items-center justify-between pb-1">
        <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
          Performance Velocity
        </h3>

        {/* Legend */}
        <div className="flex items-center gap-2.5 text-[9px]">
          <div className="flex items-center gap-1">
            <span className="h-1.5 w-1.5 rounded-full bg-[#f43f5e]" />
            <span className="text-[#78716c]">Execution</span>
          </div>
          <div className="flex items-center gap-1">
            <span className="h-1.5 w-1.5 rounded-full bg-[#e11d48]" />
            <span className="text-[#78716c]">Resilience</span>
          </div>
          <div className="flex items-center gap-1">
            <span className="h-1.5 w-1.5 rounded-full bg-[#10b981]" />
            <span className="text-[#78716c]">Architecture</span>
          </div>
        </div>
      </div>

      {/* Smooth Sakura Spline Chart */}
      <div className="h-28 w-full pt-1">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={MOCK_WEEKLY_DATA}
            margin={{ top: 4, right: 4, left: -28, bottom: 0 }}
          >
            <defs>
              <linearGradient id="sakuraRose" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#f43f5e" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="toriiRed" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#e11d48" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#e11d48" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="bambooJade" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.25} />
                <stop offset="95%" stopColor="#10b981" stopOpacity={0.0} />
              </linearGradient>
            </defs>
            <XAxis
              dataKey="day"
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#a8a29e', fontSize: 9 }}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#a8a29e', fontSize: 9 }}
              domain={[0, 100]}
              ticks={[25, 50, 75]}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                backdropFilter: 'blur(12px)',
                borderRadius: '12px',
                border: '1px solid rgba(251, 207, 232, 0.6)',
                fontSize: '11px',
              }}
            />
            <Area
              type="monotone"
              dataKey="shinobi"
              stroke="#f43f5e"
              strokeWidth={1.8}
              fillOpacity={1}
              fill="url(#sakuraRose)"
            />
            <Area
              type="monotone"
              dataKey="samurai"
              stroke="#e11d48"
              strokeWidth={1.8}
              fillOpacity={1}
              fill="url(#toriiRed)"
            />
            <Area
              type="monotone"
              dataKey="shogun"
              stroke="#10b981"
              strokeWidth={1.8}
              fillOpacity={1}
              fill="url(#bambooJade)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
