'use client'

import { useState } from 'react'
import { formatElapsed, type MissionState } from '@/lib/mission-sim'
import PixelOffice from '@/components/pixel/pixel-office'
import { Maximize2, Minimize2 } from 'lucide-react'

const CONNECTION_LABEL: Record<MissionState['connection'], { text: string; dot: string }> = {
  idle: { text: 'idle', dot: 'bg-stone-400' },
  loading: { text: 'connecting', dot: 'bg-amber-400' },
  live: { text: 'live', dot: 'bg-rose-500 animate-sakura-pulse' },
  reconnecting: { text: 'reconnecting', dot: 'bg-amber-500 animate-pulse' },
  error: { text: 'offline', dot: 'bg-red-600' },
}

export function OfficeViewport({ mission }: { mission: MissionState }) {
  const { clock } = mission
  const [isFullscreen, setIsFullscreen] = useState(false)
  const conn = CONNECTION_LABEL[mission.connection]

  const activeCount = Object.values(mission.agents).filter((a) => a.phase === 'working').length

  return (
    <section
      aria-label="Agent Office Floor"
      className={`glass-panel relative flex flex-col overflow-hidden transition-all duration-300 ${
        isFullscreen ? 'fixed inset-4 z-50 shadow-2xl ring-1 ring-black/10' : 'h-full w-full'
      }`}
    >
      <div className="flex shrink-0 items-center justify-between gap-3 border-b border-white/40 bg-white/30 px-5 py-3 backdrop-blur-md">
        <div className="flex min-w-0 items-center gap-2.5">
          <span className={`h-2 w-2 shrink-0 rounded-full ${conn.dot}`} title={`Event stream: ${conn.text}`} />
          <h3 className="truncate text-xs font-semibold tracking-wide text-[#1c1917] uppercase" title={mission.mission?.request}>
            {mission.mission?.title ?? 'Guild floor'}
          </h3>
          <span className="shrink-0 text-[11px] text-[#78716c]">
            ({activeCount} working · {conn.text})
          </span>
        </div>

        <div className="flex shrink-0 items-center gap-2.5">
          <span className="font-mono text-xs font-medium text-[#78716c]">T+{formatElapsed(clock)}</span>
          <button
            onClick={() => setIsFullscreen(!isFullscreen)}
            aria-label={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
            className="flex h-7 w-7 items-center justify-center rounded-full text-muted-foreground transition-all hover:bg-white/60 hover:text-foreground"
          >
            {isFullscreen ? <Minimize2 className="h-3.5 w-3.5" /> : <Maximize2 className="h-3.5 w-3.5" />}
          </button>
        </div>
      </div>

      <div className="relative min-h-0 flex-1 overflow-hidden bg-[#0d0d12]">
        <PixelOffice mission={mission} />
        {mission.error && (
          <div className="absolute bottom-3 left-3 right-3 z-40 rounded-xl bg-red-950/85 px-3 py-2 text-[11px] text-red-100">
            {mission.error}
          </div>
        )}
      </div>
    </section>
  )
}
