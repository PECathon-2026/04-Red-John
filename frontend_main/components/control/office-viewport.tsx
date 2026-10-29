'use client'

import { useState } from 'react'
import { formatElapsed, type MissionState } from '@/lib/mission-sim'
import PixelOffice from '@/components/pixel/pixel-office'
import { ArchitectChat } from './architect-chat'
import { Maximize2, Minimize2 } from 'lucide-react'

export function OfficeViewport({
  mission,
  projectId,
}: {
  mission: MissionState
  projectId: string | null
}) {
  const { clock } = mission
  const [isFullscreen, setIsFullscreen] = useState(false)

  const activeCount = Object.values(mission.agents).filter(
    (a) => a.phase === 'working',
  ).length

  return (
    <section
      aria-label="Agent Office Floor"
      className={`glass-panel relative flex flex-col overflow-hidden transition-all duration-300 ${
        isFullscreen
          ? 'fixed inset-4 z-50 shadow-2xl ring-1 ring-black/10'
          : 'h-full w-full'
      }`}
    >
      {/* Clean Minimal Glass Header (Unnecessary badges & complete button removed) */}
      <div className="flex shrink-0 items-center justify-between border-b border-white/40 bg-white/30 px-5 py-3 backdrop-blur-md">
        <div className="flex items-center gap-2.5">
          <span className="h-2 w-2 rounded-full bg-rose-500 animate-sakura-pulse" />
          <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
            Autonomous Agent Floor
          </h3>
          <span className="text-[11px] text-[#78716c]">
            ({activeCount} active)
          </span>
        </div>

        <div className="flex items-center gap-2.5">
          {/* Minimalist Mission Clock */}
          <span className="font-mono text-xs font-medium text-[#78716c]">
            T+{formatElapsed(clock)}
          </span>

          {/* Minimalist Fullscreen Toggle */}
          <button
            onClick={() => setIsFullscreen(!isFullscreen)}
            aria-label={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
            className="flex h-7 w-7 items-center justify-center rounded-full text-muted-foreground transition-all hover:bg-white/60 hover:text-foreground"
          >
            {isFullscreen ? (
              <Minimize2 className="h-3.5 w-3.5" />
            ) : (
              <Maximize2 className="h-3.5 w-3.5" />
            )}
          </button>
        </div>
      </div>

      {/* Canvas Scene Container */}
      <div className="relative min-h-0 flex-1 overflow-hidden bg-[#0d0d12]">
        <PixelOffice mission={mission} />

        {/* Minimalist Architect Chat Button / Dock */}
        <div className="absolute bottom-4 right-4 z-40">
          <ArchitectChat projectId={projectId} />
        </div>
      </div>
    </section>
  )
}
