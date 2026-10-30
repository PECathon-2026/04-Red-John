'use client'

import { useState, useEffect } from 'react'
import {
  BLUEPRINT_STAGES,
  COUNCIL_DECISION,
  ROLLOUT_PHASES,
  type BlueprintStage,
} from '@/lib/blueprint'
import { BlueprintMap } from './blueprint-map'
import { API_URL, type MissionState } from '@/lib/mission-sim'
import {
  GitFork,
  CheckCircle2,
  AlertCircle,
  FileCode,
  ShieldCheck,
  Check,
  RefreshCw,
  Clock,
} from 'lucide-react'

export function BlueprintTab({
  complete,
  architectureReport,
  loadingReport = false,
  demo = false,
  projectId,
  mission,
}: {
  complete: boolean
  architectureReport?: any
  loadingReport?: boolean
  demo?: boolean
  projectId: string | null
  mission?: MissionState
}) {
  const [mapOpen, setMapOpen] = useState(false)
  const [activeSubTab, setActiveSubTab] = useState<'board' | 'criteria' | 'patch' | 'blueprint'>('board')
  const [patchText, setPatchText] = useState<string | null>(null)
  const [patchLoading, setPatchLoading] = useState(false)
  const [applying, setApplying] = useState(false)
  const [applyMessage, setApplyMessage] = useState<string | null>(null)

  const atlas = architectureReport?.atlas_executive
  const isLive = Array.isArray(atlas?.stages) && atlas.stages.length > 0
  const stages: BlueprintStage[] = isLive ? atlas.stages : BLUEPRINT_STAGES
  const decision = isLive && atlas.decision ? atlas.decision : COUNCIL_DECISION
  const rollout =
    isLive && Array.isArray(atlas.rollout) && atlas.rollout.length > 0
      ? atlas.rollout
      : ROLLOUT_PHASES

  // Load patch if active tab is patch
  useEffect(() => {
    if (activeSubTab === 'patch' && projectId && !projectId.startsWith('offline-')) {
      setPatchLoading(true)
      fetch(`${API_URL}/api/v1/missions/${projectId}/patch`)
        .then((res) => (res.ok ? res.text() : ''))
        .then((txt) => {
          setPatchText(txt || 'No diff generated yet.')
        })
        .catch(() => {
          setPatchText('Unable to fetch unified diff.')
        })
        .finally(() => setPatchLoading(false))
    }
  }, [activeSubTab, projectId])

  const handleApply = async () => {
    if (!projectId) return
    setApplying(true)
    setApplyMessage(null)
    try {
      const res = await fetch(`${API_URL}/api/v1/missions/${projectId}/apply`, {
        method: 'POST',
      })
      if (res.ok) {
        setApplyMessage('Approval request created! Confirm in the oversight modal to apply.')
      } else {
        const err = await res.json().catch(() => ({}))
        setApplyMessage(err?.detail || err?.error?.message || 'Apply request rejected.')
      }
    } catch {
      setApplyMessage('Failed to submit apply request.')
    } finally {
      setApplying(false)
    }
  }

  const tasks = mission?.tasks || []
  const criteria = mission?.acceptanceCriteria || []
  const evidence = mission?.evidence || []

  return (
    <div className="glass-panel flex h-full flex-col overflow-hidden">
      {/* Top Header */}
      <div className="flex shrink-0 flex-wrap items-center justify-between border-b border-white/40 bg-white/30 px-3.5 py-2.5 backdrop-blur-md gap-2">
        <div className="flex items-center gap-2">
          <GitFork className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
            Mission Board
          </h3>
          {mission?.mission && (
            <span className="rounded-full bg-rose-100/70 px-2 py-0.5 text-[9px] font-bold text-rose-800">
              {mission.mission.status.toUpperCase()}
            </span>
          )}
        </div>

        {/* Sub-tab navigation */}
        <div className="flex items-center gap-1">
          <button
            onClick={() => setActiveSubTab('board')}
            className={`rounded-full px-2.5 py-1 text-[10px] font-medium transition-all ${
              activeSubTab === 'board'
                ? 'bg-[#1c1917] text-rose-100 shadow-2xs'
                : 'bg-white/40 text-[#78716c] hover:bg-white/70'
            }`}
          >
            Tasks ({tasks.length})
          </button>
          <button
            onClick={() => setActiveSubTab('criteria')}
            className={`rounded-full px-2.5 py-1 text-[10px] font-medium transition-all ${
              activeSubTab === 'criteria'
                ? 'bg-[#1c1917] text-rose-100 shadow-2xs'
                : 'bg-white/40 text-[#78716c] hover:bg-white/70'
            }`}
          >
            Criteria ({criteria.length})
          </button>
          <button
            onClick={() => setActiveSubTab('patch')}
            className={`rounded-full px-2.5 py-1 text-[10px] font-medium transition-all ${
              activeSubTab === 'patch'
                ? 'bg-[#1c1917] text-rose-100 shadow-2xs'
                : 'bg-white/40 text-[#78716c] hover:bg-white/70'
            }`}
          >
            Diff
          </button>
          <button
            onClick={() => setActiveSubTab('blueprint')}
            className={`rounded-full px-2.5 py-1 text-[10px] font-medium transition-all ${
              activeSubTab === 'blueprint'
                ? 'bg-[#1c1917] text-rose-100 shadow-2xs'
                : 'bg-white/40 text-[#78716c] hover:bg-white/70'
            }`}
          >
            Topology
          </button>
        </div>
      </div>

      {/* Content */}
      <div
        className="clean-scroll min-h-0 flex-1 space-y-3.5 overflow-y-auto p-3.5"
        data-lenis-prevent
      >
        {/* SUBTAB 1: TASKS BOARD */}
        {activeSubTab === 'board' && (
          <div className="space-y-2.5">
            {mission?.mission && (
              <div className="rounded-xl border border-white/60 bg-white/40 p-3 backdrop-blur-md shadow-2xs">
                <span className="text-[9px] font-bold text-rose-700 uppercase tracking-wider">
                  Request Directive
                </span>
                <p className="mt-1 text-xs font-medium text-[#1c1917] leading-relaxed">
                  {mission.mission.request}
                </p>
              </div>
            )}

            <div className="rounded-xl border border-white/60 bg-white/40 p-3 backdrop-blur-md shadow-2xs">
              <div className="flex items-center justify-between pb-2">
                <h4 className="text-xs font-bold text-[#1c1917] uppercase tracking-wide">
                  Execution DAG
                </h4>
                <span className="text-[10px] font-mono text-[#78716c]">
                  {tasks.filter((t) => t.status === 'done').length}/{tasks.length} completed
                </span>
              </div>

              {tasks.length === 0 ? (
                <p className="text-[11px] text-[#78716c] italic">
                  Awaiting Shogun Council task decomposition...
                </p>
              ) : (
                <div className="space-y-2">
                  {tasks.map((task, i) => {
                    const isDone = task.status === 'done'
                    const isRunning = task.status === 'in_progress'
                    const isFailed = task.status === 'failed'

                    return (
                      <div
                        key={task.id || i}
                        className={`rounded-lg border p-2.5 transition-all text-xs ${
                          isDone
                            ? 'border-emerald-200/60 bg-emerald-50/50'
                            : isRunning
                              ? 'border-rose-300/80 bg-rose-50/60 ring-1 ring-rose-300/40'
                              : isFailed
                                ? 'border-red-200/60 bg-red-50/50'
                                : 'border-white/50 bg-white/50 text-[#78716c]'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            {isDone ? (
                              <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                            ) : isRunning ? (
                              <RefreshCw className="h-3.5 w-3.5 animate-spin text-rose-600" />
                            ) : (
                              <Clock className="h-3.5 w-3.5 text-stone-400" />
                            )}
                            <span className="font-semibold text-[11px] text-[#1c1917]">
                              {task.title}
                            </span>
                          </div>
                          <span
                            className={`rounded-full px-2 py-0.5 text-[8px] font-bold uppercase ${
                              isDone
                                ? 'bg-emerald-100 text-emerald-800'
                                : isRunning
                                  ? 'bg-rose-100 text-rose-800 animate-pulse'
                                  : 'bg-stone-100 text-stone-600'
                            }`}
                          >
                            {task.status}
                          </span>
                        </div>
                        {task.description && (
                          <p className="mt-1 text-[10px] text-[#57534e] leading-relaxed">
                            {task.description}
                          </p>
                        )}
                        {task.assigned_to && (
                          <div className="mt-1.5 flex items-center gap-1 text-[9px] font-mono text-[#78716c]">
                            <span>Assigned to:</span>
                            <span className="font-semibold text-rose-900">{task.assigned_to}</span>
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          </div>
        )}

        {/* SUBTAB 2: ACCEPTANCE CRITERIA */}
        {activeSubTab === 'criteria' && (
          <div className="space-y-2.5">
            <div className="rounded-xl border border-white/60 bg-white/40 p-3.5 backdrop-blur-md shadow-2xs">
              <div className="flex items-center justify-between pb-2">
                <div className="flex items-center gap-1.5">
                  <ShieldCheck className="h-3.5 w-3.5 text-rose-600" />
                  <h4 className="text-xs font-bold text-[#1c1917] uppercase tracking-wide">
                    Verified Acceptance Criteria
                  </h4>
                </div>
                <span className="text-[10px] text-[#78716c]">
                  Audit by Mei (Sentinel)
                </span>
              </div>

              {criteria.length === 0 ? (
                <p className="text-[11px] text-[#78716c] italic">
                  Kenji is formulating testable acceptance criteria...
                </p>
              ) : (
                <div className="space-y-2">
                  {criteria.map((crit, idx) => {
                    const isMet = crit.status === 'met'
                    const isUnmet = crit.status === 'unmet'

                    return (
                      <div
                        key={crit.id || idx}
                        className={`rounded-lg border p-2.5 text-xs ${
                          isMet
                            ? 'border-emerald-200/60 bg-emerald-50/50'
                            : isUnmet
                              ? 'border-red-200/60 bg-red-50/50'
                              : 'border-white/50 bg-white/50'
                        }`}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-[11px] font-medium text-[#1c1917] leading-relaxed">
                            {crit.statement}
                          </span>
                          <span
                            className={`shrink-0 rounded-full px-2 py-0.5 text-[8px] font-bold uppercase ${
                              isMet
                                ? 'bg-emerald-100 text-emerald-800'
                                : isUnmet
                                  ? 'bg-red-100 text-red-800'
                                  : 'bg-stone-100 text-stone-600'
                            }`}
                          >
                            {crit.status}
                          </span>
                        </div>
                        {crit.evidence_ids && crit.evidence_ids.length > 0 && (
                          <div className="mt-1 text-[9px] font-mono text-[#78716c]">
                            Evidence: {crit.evidence_ids.join(', ')}
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </div>

            {/* Evidence List */}
            {evidence.length > 0 && (
              <div className="rounded-xl border border-white/60 bg-white/40 p-3.5 backdrop-blur-md shadow-2xs">
                <h4 className="text-xs font-bold text-[#1c1917] uppercase tracking-wide mb-2">
                  Recorded Evidence ({evidence.length})
                </h4>
                <div className="space-y-1.5">
                  {evidence.slice(-5).map((ev: any, idx: number) => (
                    <div
                      key={ev.evidence_id || idx}
                      className="rounded-md border border-white/40 bg-white/50 p-2 text-[10px]"
                    >
                      <div className="flex items-center justify-between font-mono">
                        <span className="font-semibold text-rose-900">{ev.kind}</span>
                        <span className={ev.passed ? 'text-emerald-700 font-bold' : 'text-stone-600'}>
                          {ev.passed === true ? 'PASSED' : ev.passed === false ? 'FAILED' : 'RECORDED'}
                        </span>
                      </div>
                      <p className="mt-0.5 text-[#57534e] truncate">{ev.summary}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* SUBTAB 3: UNIFIED DIFF / PATCH */}
        {activeSubTab === 'patch' && (
          <div className="space-y-3">
            <div className="rounded-xl border border-white/60 bg-white/40 p-3.5 backdrop-blur-md shadow-2xs">
              <div className="flex items-center justify-between pb-2">
                <div className="flex items-center gap-1.5">
                  <FileCode className="h-3.5 w-3.5 text-rose-600" />
                  <h4 className="text-xs font-bold text-[#1c1917] uppercase tracking-wide">
                    Repository Patch
                  </h4>
                </div>

                <button
                  onClick={handleApply}
                  disabled={applying || !patchText || patchText.includes('No diff')}
                  className="rounded-full bg-[#1c1917] px-3.5 py-1 text-[10px] font-semibold text-rose-100 shadow-xs hover:bg-rose-950 transition-all disabled:opacity-50"
                >
                  {applying ? 'Requesting Apply...' : 'Apply to Repository'}
                </button>
              </div>

              {applyMessage && (
                <div className="mb-2 rounded-lg bg-rose-50 border border-rose-200 p-2 text-[11px] text-rose-900">
                  {applyMessage}
                </div>
              )}

              {patchLoading ? (
                <div className="py-8 text-center text-xs text-[#78716c]">
                  Generating unified diff from workspace baseline...
                </div>
              ) : (
                <pre className="max-h-96 overflow-x-auto rounded-lg bg-[#0e0e14] p-3 font-mono text-[10px] leading-relaxed text-stone-200">
                  {patchText || 'No diff available.'}
                </pre>
              )}
            </div>
          </div>
        )}

        {/* SUBTAB 4: ARCHITECTURE BLUEPRINT & TOPOLOGY */}
        {activeSubTab === 'blueprint' && (
          <div className="space-y-3.5">
            <div className="flex justify-end">
              <button
                onClick={() => setMapOpen(true)}
                className="rounded-full bg-[#1c1917] px-3 py-1 text-[10px] font-semibold text-rose-200 transition-all hover:bg-rose-950"
              >
                View Topology Map →
              </button>
            </div>

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
        )}
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
