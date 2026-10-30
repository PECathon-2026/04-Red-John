'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
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
        <div className="flex items-center gap-3">
          <Link href="/" className="flex items-center gap-2 group">
            <div className="flex h-7 items-center justify-center rounded-md bg-[#0d0914] px-2 py-0.5 border border-white/10 shadow-2xs transition-transform group-hover:scale-105">
              <Image
                src="/images/devpilot-logo-cropped.png"
                alt="DevPilot"
                width={95}
                height={15}
                className="h-3.5 w-auto object-contain"
                priority
              />
            </div>
          </Link>
        </div>

        <div className="flex items-center gap-2.5">
          {mission.mission && (
            <span className="hidden sm:inline-block max-w-[200px] truncate rounded-full border border-rose-200/60 bg-white/50 px-2.5 py-0.5 text-[10px] font-semibold text-rose-900 shadow-2xs">
              {mission.mission.title || mission.mission.mission_id}
            </span>
          )}

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
