'use client'

import { useState } from 'react'
import {
  BLUEPRINT_STAGES,
  COUNCIL_DECISION,
  ROLLOUT_PHASES,
  type BlueprintStage,
} from '@/lib/blueprint'
import { BlueprintMap } from './blueprint-map'
import { GitFork, Lock } from 'lucide-react'

export function BlueprintTab({
  complete,
  architectureReport,
  loadingReport = false,
  demo = false,
  projectId,
}: {
  complete: boolean
  architectureReport?: any
  loadingReport?: boolean
  demo?: boolean
  projectId: string | null
}) {
  const [mapOpen, setMapOpen] = useState(false)

  const atlas = architectureReport?.atlas_executive
  const isLive = Array.isArray(atlas?.stages) && atlas.stages.length > 0
  const stages: BlueprintStage[] = isLive ? atlas.stages : BLUEPRINT_STAGES
  const decision = isLive && atlas.decision ? atlas.decision : COUNCIL_DECISION
  const rollout =
    isLive && Array.isArray(atlas.rollout) && atlas.rollout.length > 0
      ? atlas.rollout
      : ROLLOUT_PHASES

  if (!complete) {
    return (
      <div className="glass-panel flex h-full flex-col items-center justify-center p-8 text-center">
        <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-rose-100/70 text-rose-700 mb-2.5 animate-sakura-pulse">
          <Lock className="h-5 w-5" />
        </div>
        <h4 className="text-xs font-bold text-[#1c1917] uppercase tracking-wide">
          Shogun Blueprint Sealed
        </h4>
        <p className="max-w-xs text-[11px] text-[#78716c] mt-1 leading-relaxed">
          The final architecture blueprint unlocks once the Strategy Council concludes deliberations and Ethan independently signs off.
        </p>
      </div>
    )
  }

  return (
    <div className="glass-panel flex h-full flex-col overflow-hidden">
      {/* Top Header */}
      <div className="flex shrink-0 items-center justify-between border-b border-white/40 bg-white/30 px-4 py-2.5 backdrop-blur-md">
        <div className="flex items-center gap-2">
          <GitFork className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
            Shogun Blueprint
          </h3>
        </div>

        <button
          onClick={() => setMapOpen(true)}
          className="rounded-full bg-[#1c1917] px-3 py-1 text-[10px] font-semibold text-rose-200 transition-all hover:bg-rose-950"
        >
          View Topology Map →
        </button>
      </div>

      {/* Content */}
      <div
        className="clean-scroll min-h-0 flex-1 space-y-3.5 overflow-y-auto p-3.5"
        data-lenis-prevent
      >
        {/* Council Verdict Card */}
        <div className="rounded-xl border border-white/60 bg-white/40 p-3.5 backdrop-blur-md shadow-2xs">
          <span className="text-[9px] font-bold text-rose-700 uppercase tracking-wider">
            Consensus Verdict · Chaired by Sofia
          </span>
          <h4 className="mt-1 text-xs font-bold text-[#1c1917]">
            {decision.recommendation}
          </h4>
          <p className="mt-1 text-[11px] leading-relaxed text-[#57534e]">
            {decision.rationale}
          </p>
        </div>

        {/* Rollout Sequencing */}
        <div className="rounded-xl border border-white/60 bg-white/40 p-3.5 backdrop-blur-md shadow-2xs">
          <h4 className="text-xs font-bold text-[#1c1917] mb-2 uppercase tracking-wide">
            Execution Stages
          </h4>
          <div className="space-y-2">
            {rollout.map((phase: any, i: number) => (
              <div
                key={phase.title || i}
                className="flex items-start gap-2.5 rounded-lg border border-white/40 bg-white/40 p-2 text-xs"
              >
                <span className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-rose-100 text-[9px] font-bold text-rose-800">
                  {i + 1}
                </span>
                <div>
                  <h5 className="font-semibold text-[11px] text-[#1c1917]">
                    {phase.title}
                  </h5>
                  <p className="text-[10px] text-[#78716c] leading-relaxed">
                    {phase.detail || phase.action}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {mapOpen && (
        <BlueprintMap
          onClose={() => setMapOpen(false)}
          architectureReport={architectureReport}
          projectId={projectId}
        />
      )}
    </div>
  )
}
