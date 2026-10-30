'use client'

import { useCallback, useEffect, useState } from 'react'
import { endpoints, getUser, hasRole, type MissionDoc } from '@/lib/api'
import { isTerminal, type MissionState } from '@/lib/mission-sim'
import {
  CheckCircle2,
  CircleDashed,
  XCircle,
  HelpCircle,
  ClipboardCheck,
  AlertTriangle,
  FileDiff,
  ScrollText,
  MessageSquareWarning,
  Play,
  Square,
  RefreshCw,
  GitMerge,
} from 'lucide-react'

const CRITERION_ICON = {
  met: { icon: CheckCircle2, cls: 'text-emerald-600' },
  unmet: { icon: XCircle, cls: 'text-red-600' },
  unverifiable: { icon: HelpCircle, cls: 'text-amber-600' },
  pending: { icon: CircleDashed, cls: 'text-stone-400' },
} as const

const SEVERITY_CLS: Record<string, string> = {
  critical: 'bg-red-600 text-white',
  high: 'bg-red-100 text-red-800',
  medium: 'bg-amber-100 text-amber-800',
  low: 'bg-sky-100 text-sky-800',
  info: 'bg-stone-100 text-stone-700',
}

export const STATUS_CLS: Record<string, string> = {
  created: 'bg-stone-100 text-stone-700',
  planning: 'bg-sky-100 text-sky-800',
  running: 'bg-rose-100 text-rose-800',
  awaiting_human: 'bg-amber-100 text-amber-900',
  completed: 'bg-emerald-100 text-emerald-800',
  failed: 'bg-red-100 text-red-800',
  stopped: 'bg-stone-200 text-stone-700',
}

function Section({ title, icon: Icon, count, children }: { title: string; icon: typeof ScrollText; count?: number; children: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-white/60 bg-white/50 p-3 shadow-2xs">
      <h4 className="mb-2 flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wide text-[#1c1917]">
        <Icon className="h-3.5 w-3.5 text-rose-600" />
        {title}
        {count !== undefined && <span className="font-mono text-[10px] font-medium text-[#a8a29e]">({count})</span>}
      </h4>
      {children}
    </section>
  )
}

function IssueAnswer({ missionId, issueId, onDone }: { missionId: string; issueId: string; onDone: () => void }) {
  const [text, setText] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function submit() {
    setBusy(true)
    setError(null)
    try {
      await endpoints.resolveIssue(missionId, issueId, text.trim())
      setText('')
      onDone()
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="mt-1.5 space-y-1">
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        rows={2}
        placeholder="Your answer — the mission resumes once every question is answered"
        className="w-full rounded-lg border border-amber-200 bg-white px-2 py-1.5 text-[11px] outline-none focus:border-amber-400"
      />
      {error && <p className="text-[10px] text-red-700">{error}</p>}
      <button
        onClick={submit}
        disabled={busy || !text.trim()}
        className="rounded-full bg-[#1c1917] px-3 py-1 text-[10px] font-semibold text-amber-100 disabled:opacity-50"
      >
        {busy ? 'Sending…' : 'Answer'}
      </button>
    </div>
  )
}

/** The mission board: questions for the human, criteria, findings, evidence, the report and the change. */
export function MissionBoardTab({ mission }: { mission: MissionState }) {
  const header = mission.mission
  const missionId = header?.mission_id ?? null
  const user = getUser()
  const canOperate = hasRole(user, 'operator')
  const terminal = isTerminal(header?.status)

  const [doc, setDoc] = useState<MissionDoc | null>(null)
  const [patch, setPatch] = useState<string | null>(null)
  const [showPatch, setShowPatch] = useState(false)
  const [busy, setBusy] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const loadDoc = useCallback(async () => {
    if (!missionId) return
    try {
      setDoc(await endpoints.mission(missionId))
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    }
  }, [missionId])

  // The report and apply record live on the mission document; reload when the status changes.
  useEffect(() => {
    void loadDoc()
  }, [loadDoc, header?.status, mission.pendingApprovals.length])

  async function act(name: string, fn: () => Promise<unknown>) {
    setBusy(name)
    setError(null)
    try {
      await fn()
      mission.refresh()
      await loadDoc()
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(null)
    }
  }

  async function togglePatch() {
    if (!missionId) return
    if (!showPatch && patch === null) {
      try {
        setPatch(await endpoints.patch(missionId))
      } catch (err) {
        setPatch(`Could not load the diff: ${err instanceof Error ? err.message : String(err)}`)
      }
    }
    setShowPatch((v) => !v)
  }

  if (!header) {
    return (
      <div className="glass-panel flex h-full items-center justify-center p-6 text-xs text-[#78716c]">
        Loading mission…
      </div>
    )
  }

  const openIssues = mission.issues.filter((i) => i.status === 'open')
  const findings = [...mission.findings].sort((a, b) => Number(b.status === 'open') - Number(a.status === 'open'))
  const apply = doc?.application ?? null
  const canRequestApply =
    header.status === 'completed' && canOperate && (!apply || apply.status === 'rejected' || apply.status === 'failed')

  return (
    <div className="glass-panel flex h-full flex-col overflow-hidden">
      {/* Header */}
      <div className="shrink-0 border-b border-white/40 bg-white/30 px-4 py-3 backdrop-blur-md">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <h3 className="truncate text-sm font-bold text-[#1c1917]" title={header.title}>
              {header.title}
            </h3>
            <p className="mt-0.5 line-clamp-2 text-[10px] text-[#78716c]" title={header.request}>
              {header.request}
            </p>
          </div>
          <span className={`shrink-0 rounded-full px-2 py-0.5 text-[9px] font-bold uppercase ${STATUS_CLS[header.status] ?? ''}`}>
            {header.status.replace('_', ' ')}
          </span>
        </div>
        {header.status_reason && <p className="mt-1 text-[10px] text-[#57534e]">{header.status_reason}</p>}

        <div className="mt-2 flex flex-wrap gap-1.5">
          {canOperate && !terminal && header.status !== 'running' && header.status !== 'planning' && (
            <button
              onClick={() => act('run', () => endpoints.run(header.mission_id))}
              disabled={!!busy}
              className="flex items-center gap-1 rounded-full bg-[#1c1917] px-3 py-1 text-[10px] font-semibold text-rose-100 disabled:opacity-50"
            >
              <Play className="h-3 w-3" /> {header.status === 'created' ? 'Start' : 'Resume'}
            </button>
          )}
          {canOperate && !terminal && (
            <button
              onClick={() => act('stop', () => endpoints.stop(header.mission_id, 'Stopped from mission control'))}
              disabled={!!busy}
              className="flex items-center gap-1 rounded-full border border-black/10 bg-white px-3 py-1 text-[10px] font-semibold text-[#44403c] disabled:opacity-50"
            >
              <Square className="h-3 w-3 text-red-500" /> Stop
            </button>
          )}
          {canRequestApply && (
            <button
              onClick={() => act('apply', () => endpoints.requestApply(header.mission_id))}
              disabled={!!busy}
              className="flex items-center gap-1 rounded-full bg-emerald-700 px-3 py-1 text-[10px] font-semibold text-white disabled:opacity-50"
            >
              <GitMerge className="h-3 w-3" /> Apply to repository…
            </button>
          )}
          <button
            onClick={() => act('refresh', async () => undefined)}
            disabled={!!busy}
            className="flex items-center gap-1 rounded-full border border-black/10 bg-white px-3 py-1 text-[10px] font-semibold text-[#44403c] disabled:opacity-50"
          >
            <RefreshCw className={`h-3 w-3 ${busy === 'refresh' ? 'animate-spin' : ''}`} /> Refresh
          </button>
        </div>
        {apply && (
          <p className="mt-1.5 text-[10px] text-[#57534e]">
            Apply: <span className="font-semibold">{apply.status}</span>
            {apply.files.length > 0 && ` · ${apply.files.length} file(s)`}
            {apply.decided_by && ` · decided by ${apply.decided_by}`}
            {apply.error && <span className="text-red-700"> · {apply.error}</span>}
          </p>
        )}
        {error && <p className="mt-1.5 rounded-lg bg-red-50 px-2 py-1 text-[10px] text-red-800">{error}</p>}
      </div>

      {/* Body */}
      <div className="clean-scroll min-h-0 flex-1 space-y-3 overflow-y-auto p-3" data-lenis-prevent>
        {openIssues.length > 0 && (
          <Section title="Needs your answer" icon={MessageSquareWarning} count={openIssues.length}>
            <ul className="space-y-2.5">
              {openIssues.map((issue) => (
                <li key={issue.id} className="rounded-xl border border-amber-200 bg-amber-50/80 p-2.5">
                  <p className="text-[10px] font-semibold uppercase text-amber-900">
                    {issue.kind} · from {issue.raised_by}
                  </p>
                  <p className="mt-0.5 whitespace-pre-wrap text-[11px] text-[#292524]">{issue.text}</p>
                  {issue.needs_human && canOperate && (
                    <IssueAnswer missionId={header.mission_id} issueId={issue.id} onDone={mission.refresh} />
                  )}
                </li>
              ))}
            </ul>
          </Section>
        )}

        <Section title="Acceptance criteria" icon={ClipboardCheck} count={mission.acceptanceCriteria.length}>
          {mission.acceptanceCriteria.length === 0 ? (
            <p className="text-[10px] text-[#78716c]">Kenji has not written the criteria yet.</p>
          ) : (
            <ul className="space-y-1.5">
              {mission.acceptanceCriteria.map((c) => {
                const { icon: Icon, cls } = CRITERION_ICON[c.status] ?? CRITERION_ICON.pending
                return (
                  <li key={c.id} className="flex items-start gap-1.5 text-[11px] text-[#292524]">
                    <Icon className={`mt-0.5 h-3.5 w-3.5 shrink-0 ${cls}`} />
                    <div className="min-w-0">
                      <p>{c.text}</p>
                      {(c.verified_by || c.note) && (
                        <p className="text-[9px] text-[#78716c]">
                          {c.verified_by && `verified by ${c.verified_by}`}
                          {c.evidence_ids.length > 0 && ` · ${c.evidence_ids.length} evidence`}
                          {c.note && ` · ${c.note}`}
                        </p>
                      )}
                    </div>
                  </li>
                )
              })}
            </ul>
          )}
        </Section>

        <Section title="Findings" icon={AlertTriangle} count={findings.length}>
          {findings.length === 0 ? (
            <p className="text-[10px] text-[#78716c]">No findings.</p>
          ) : (
            <ul className="space-y-1.5">
              {findings.map((f) => (
                <li key={f.id} className={`text-[11px] ${f.status === 'open' ? '' : 'opacity-60'}`}>
                  <div className="flex items-center gap-1.5">
                    <span className={`rounded px-1 text-[8px] font-bold uppercase ${SEVERITY_CLS[f.severity] ?? ''}`}>{f.severity}</span>
                    <span className="font-semibold text-[#292524]">{f.title}</span>
                  </div>
                  <p className="text-[9px] text-[#78716c]">
                    {f.kind} · {f.agent} · {f.status}
                    {f.file && ` · ${f.file}${f.line ? `:${f.line}` : ''}`}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </Section>

        <Section title="Evidence" icon={CheckCircle2} count={mission.evidence.length}>
          {mission.evidence.length === 0 ? (
            <p className="text-[10px] text-[#78716c]">No checks have run yet.</p>
          ) : (
            <ul className="space-y-1">
              {[...mission.evidence].reverse().map((e) => (
                <li key={e.evidence_id} className="flex items-start gap-1.5 text-[10px] text-[#292524]">
                  {e.passed === true ? (
                    <CheckCircle2 className="mt-0.5 h-3 w-3 shrink-0 text-emerald-600" />
                  ) : e.passed === false ? (
                    <XCircle className="mt-0.5 h-3 w-3 shrink-0 text-red-600" />
                  ) : (
                    <CircleDashed className="mt-0.5 h-3 w-3 shrink-0 text-stone-400" />
                  )}
                  <span className="min-w-0">
                    <span className="font-mono text-[9px] text-[#78716c]">{e.kind} · {e.agent}</span> {e.summary}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Section>

        <Section title="The change" icon={FileDiff}>
          <button onClick={togglePatch} className="text-[10px] font-semibold text-rose-700 hover:underline">
            {showPatch ? 'Hide diff' : 'Show the diff against the baseline'}
          </button>
          {showPatch && (
            <pre className="mt-2 max-h-80 overflow-auto rounded-xl bg-[#1c1917] p-2.5 font-mono text-[10px] leading-relaxed text-rose-50 whitespace-pre">
              {patch || '(no changes)'}
            </pre>
          )}
        </Section>

        <Section title="Evidence report" icon={ScrollText}>
          {doc?.report ? (
            <pre className="max-h-96 overflow-auto whitespace-pre-wrap rounded-xl bg-white/70 p-2.5 font-sans text-[11px] leading-relaxed text-[#292524]">
              {doc.report}
            </pre>
          ) : (
            <p className="text-[10px] text-[#78716c]">Scribe writes the report when the mission ends.</p>
          )}
        </Section>
      </div>
    </div>
  )
}
