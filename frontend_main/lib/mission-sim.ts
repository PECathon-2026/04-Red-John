'use client'

/**
 * Live mission state for the control room.
 *
 * Loads `GET /missions/{id}/snapshot`, then follows the mission's event stream
 * over `WS /realtime/missions/{id}?after_seq=…&token=…`. Logs, hires and agent
 * phases are applied from events as they arrive; anything that changes the
 * mission board (tasks, criteria, findings, issues, evidence, status) triggers
 * a debounced snapshot refetch so the board always matches the backend.
 */

import { useCallback, useEffect, useRef, useState } from 'react'
import {
  ApiError,
  clearSession,
  endpoints,
  missionSocketUrl,
  type Criterion,
  type Decision,
  type EventEnvelope,
  type EvidenceItem,
  type Finding,
  type Issue,
  type MissionStatus,
  type MissionTask,
  type Progress,
} from './api'

export { API_URL } from './api'

/* ------------------------------------------------------------------ */
/* Types                                                                */
/* ------------------------------------------------------------------ */

export type LogLevel = 'info' | 'action' | 'success' | 'warn' | 'error' | 'armor'

export type AtlasLog = {
  id: number
  at: number // ms since mission start
  level: LogLevel
  text: string
}

export type HireEvent = {
  id: number
  at: number
  agent: string
  team: string
  role: string
  badge: string
  clearance: 'GREEN' | 'AMBER'
  mandate: string
}

export type AgentPhase = 'standby' | 'hired' | 'working' | 'done'

export type AgentState = {
  name: string
  phase: AgentPhase
  task: string
  startedAt: number | null // ms since mission start
  finishedAt: number | null
}

export type ApprovalRequest = {
  approval_id: string
  agent: string
  tool: string
  intent: string
  risk: 'GREEN' | 'AMBER' | 'RED'
  reason?: string
  category?: string
  args_preview?: string
  expires_at?: number
}

export type MissionHeader = {
  mission_id: string
  title: string
  request: string
  status: MissionStatus
  status_reason: string | null
  baseline_commit: string | null
  created_at: number
  updated_at: number
  hired_agents: string[]
}

export type ConnectionState = 'idle' | 'loading' | 'live' | 'reconnecting' | 'error'

export type MissionState = {
  /** ms elapsed since mission start */
  clock: number
  logs: AtlasLog[]
  hires: HireEvent[]
  agents: Record<string, AgentState>
  complete: boolean
  pendingApprovals: ApprovalRequest[]
  lastSeq: number
  mission: MissionHeader | null
  progress: Progress | null
  objectives: { id: string; text: string }[]
  acceptanceCriteria: Criterion[]
  tasks: MissionTask[]
  readyTasks: string[]
  findings: Finding[]
  decisions: Decision[]
  issues: Issue[]
  evidence: EvidenceItem[]
  connection: ConnectionState
  error: string | null
  /** refetch the snapshot now */
  refresh: () => void
  /** drop an approval locally once it has been answered */
  dismissApproval: (approval_id: string) => void
}

const TERMINAL: MissionStatus[] = ['completed', 'failed', 'stopped']

export function isTerminal(status: MissionStatus | undefined | null): boolean {
  return !!status && TERMINAL.includes(status)
}

type Snapshot = Omit<MissionState, 'connection' | 'error' | 'refresh' | 'dismissApproval'>

const EMPTY: Snapshot = {
  clock: 0,
  logs: [],
  hires: [],
  agents: {},
  complete: false,
  pendingApprovals: [],
  lastSeq: 0,
  mission: null,
  progress: null,
  objectives: [],
  acceptanceCriteria: [],
  tasks: [],
  readyTasks: [],
  findings: [],
  decisions: [],
  issues: [],
  evidence: [],
}

/* Events whose effect is applied locally; every other kind refetches the snapshot. */
const LOCAL_KINDS = new Set(['log', 'hire', 'start', 'finish', 'release', 'approval_request', 'approval_response', 'tool_call', 'tool_result', 'message'])

function applyEvent(state: Snapshot, ev: EventEnvelope): Snapshot {
  const start = state.mission?.created_at ?? ev.at
  const at = ev.at - start
  const d = ev.data ?? {}
  const next: Snapshot = { ...state, lastSeq: Math.max(state.lastSeq, ev.seq ?? 0) }

  switch (ev.kind) {
    case 'log':
      next.logs = [...state.logs, { id: state.logs.length, at, level: (d.level ?? 'info') as LogLevel, text: d.text ?? '' }]
      break
    case 'hire':
      next.hires = [
        ...state.hires,
        {
          id: state.hires.length,
          at,
          agent: d.agent,
          team: d.team ?? '',
          role: d.role ?? '',
          badge: d.badge ?? '',
          clearance: d.clearance ?? 'GREEN',
          mandate: d.mandate ?? '',
        },
      ]
      next.agents = {
        ...state.agents,
        [d.agent]: { name: d.agent, phase: 'hired', task: 'Awaiting assignment', startedAt: null, finishedAt: null },
      }
      break
    case 'start':
      next.agents = {
        ...state.agents,
        [d.agent]: { name: d.agent, phase: 'working', task: d.task ?? '', startedAt: at, finishedAt: null },
      }
      break
    case 'finish':
    case 'release':
      if (state.agents[d.agent]) {
        next.agents = {
          ...state.agents,
          [d.agent]: {
            ...state.agents[d.agent],
            phase: 'done',
            task: ev.kind === 'release' ? 'Released' : state.agents[d.agent].task,
            finishedAt: at,
          },
        }
      }
      break
    case 'approval_request':
      if (!state.pendingApprovals.some((a) => a.approval_id === d.approval_id)) {
        next.pendingApprovals = [...state.pendingApprovals, d as ApprovalRequest]
      }
      break
    case 'approval_response':
      next.pendingApprovals = state.pendingApprovals.filter((a) => a.approval_id !== d.approval_id)
      break
  }
  return next
}

/* ------------------------------------------------------------------ */
/* Hook                                                                 */
/* ------------------------------------------------------------------ */

export function useMission(missionId: string | null): MissionState {
  const [snap, setSnap] = useState<Snapshot>(EMPTY)
  const [connection, setConnection] = useState<ConnectionState>(missionId ? 'loading' : 'idle')
  const [error, setError] = useState<string | null>(null)
  const [clock, setClock] = useState(0)

  const snapRef = useRef<Snapshot>(EMPTY)
  // Server clock at the last snapshot, and when (client time) we received it.
  const clockBase = useRef<{ server: number; local: number }>({ server: 0, local: 0 })
  const refetchTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const fetchSnapshotRef = useRef<() => Promise<void>>(async () => {})

  const commit = useCallback((next: Snapshot) => {
    snapRef.current = next
    setSnap(next)
  }, [])

  const scheduleRefetch = useCallback((delay = 400) => {
    if (refetchTimer.current) return
    refetchTimer.current = setTimeout(() => {
      refetchTimer.current = null
      void fetchSnapshotRef.current()
    }, delay)
  }, [])

  const fetchSnapshot = useCallback(async () => {
    if (!missionId) return
    try {
      const data = (await endpoints.snapshot(missionId)) as Snapshot
      const merged: Snapshot = { ...EMPTY, ...data }
      // Live events got ahead of this snapshot: keep them and look again shortly.
      if (merged.lastSeq < snapRef.current.lastSeq) {
        scheduleRefetch()
        return
      }
      clockBase.current = { server: merged.clock, local: Date.now() }
      setClock(merged.clock)
      commit(merged)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
      if (err instanceof ApiError && err.status === 404) setConnection('error')
    }
  }, [missionId, commit, scheduleRefetch])
  fetchSnapshotRef.current = fetchSnapshot

  /* snapshot + websocket */
  useEffect(() => {
    commit(EMPTY)
    setError(null)
    if (!missionId) {
      setConnection('idle')
      return
    }
    setConnection('loading')

    let ws: WebSocket | null = null
    let closed = false
    let retry: ReturnType<typeof setTimeout> | null = null
    let attempt = 0

    const connect = () => {
      if (closed) return
      ws = new WebSocket(missionSocketUrl(missionId, snapRef.current.lastSeq))
      ws.onopen = () => {
        attempt = 0
        setConnection('live')
      }
      ws.onmessage = (msg) => {
        let ev: EventEnvelope
        try {
          ev = JSON.parse(msg.data)
        } catch {
          return
        }
        if (!ev || typeof ev.kind !== 'string') return
        if (ev.seq && ev.seq <= snapRef.current.lastSeq) return // replayed event we already have
        commit(applyEvent(snapRef.current, ev))
        if (!LOCAL_KINDS.has(ev.kind)) scheduleRefetch()
      }
      ws.onclose = (e) => {
        if (closed) return
        if (e.code === 4401 || e.code === 4403) {
          clearSession()
          setConnection('error')
          setError('Your session expired — sign in again.')
          window.location.href = `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`
          return
        }
        setConnection('reconnecting')
        attempt += 1
        retry = setTimeout(async () => {
          await fetchSnapshotRef.current()
          connect()
        }, Math.min(1000 * 2 ** attempt, 15000))
      }
    }

    ;(async () => {
      await fetchSnapshotRef.current()
      connect()
    })()

    return () => {
      closed = true
      if (retry) clearTimeout(retry)
      if (refetchTimer.current) {
        clearTimeout(refetchTimer.current)
        refetchTimer.current = null
      }
      ws?.close()
    }
  }, [missionId, commit, scheduleRefetch])

  /* local mission clock while the mission is live */
  const terminal = isTerminal(snap.mission?.status)
  useEffect(() => {
    if (!missionId || terminal) return
    const id = setInterval(() => {
      const base = clockBase.current
      setClock(base.server + (Date.now() - base.local))
    }, 1000)
    return () => clearInterval(id)
  }, [missionId, terminal])

  const dismissApproval = useCallback(
    (approval_id: string) => {
      commit({
        ...snapRef.current,
        pendingApprovals: snapRef.current.pendingApprovals.filter((a) => a.approval_id !== approval_id),
      })
    },
    [commit],
  )

  return {
    ...snap,
    clock: terminal ? snap.clock : clock,
    connection,
    error,
    refresh: () => void fetchSnapshot(),
    dismissApproval,
  }
}

export function formatElapsed(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000))
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  const mm = String(m).padStart(2, '0')
  const ss = String(s).padStart(2, '0')
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`
}
