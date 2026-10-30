/**
 * Typed client for the DevPilot backend (backend_main, FastAPI, /api/v1).
 * Every request carries the signed-in user's bearer token. A 401 clears the
 * session and sends the browser to /login.
 */

export const API_URL = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000').replace(/\/$/, '')
export const API_BASE = `${API_URL}/api/v1`
export const WS_BASE = API_BASE.replace(/^http/, 'ws')

const TOKEN_KEY = 'devpilot_access_token'
const USER_KEY = 'devpilot_user'

/* ------------------------------------------------------------------ */
/* Session                                                              */
/* ------------------------------------------------------------------ */

export type Role = 'viewer' | 'operator' | 'approver' | 'admin'

export type AuthUser = {
  user_id: string
  username: string
  role: Role
  disabled?: boolean
}

export function getToken(): string | null {
  if (typeof window === 'undefined') return null
  return sessionStorage.getItem(TOKEN_KEY)
}

export function getUser(): AuthUser | null {
  if (typeof window === 'undefined') return null
  const raw = sessionStorage.getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as AuthUser
  } catch {
    return null
  }
}

export function saveSession(token: string | null, user: AuthUser) {
  if (typeof window === 'undefined') return
  if (token) sessionStorage.setItem(TOKEN_KEY, token)
  else sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearSession() {
  if (typeof window === 'undefined') return
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(USER_KEY)
}

const ROLE_RANK: Record<Role, number> = { viewer: 0, operator: 1, approver: 2, admin: 3 }

export function hasRole(user: AuthUser | null, needed: Role): boolean {
  return !!user && ROLE_RANK[user.role] >= ROLE_RANK[needed]
}

/* ------------------------------------------------------------------ */
/* Transport                                                            */
/* ------------------------------------------------------------------ */

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code?: string,
  ) {
    super(message)
  }
}

function errorMessage(body: unknown, fallback: string): { message: string; code?: string } {
  if (body && typeof body === 'object') {
    const b = body as Record<string, any>
    // backend_main errors: {"error": {"code", "message", "details"}}; FastAPI validation: {"detail": [...]}
    if (b.error?.message) return { message: b.error.message, code: b.error.code }
    if (typeof b.detail === 'string') return { message: b.detail }
    if (Array.isArray(b.detail) && b.detail[0]?.msg) return { message: b.detail.map((d: any) => d.msg).join('; ') }
  }
  return { message: fallback }
}

type RequestOptions = { method?: string; body?: unknown; text?: boolean; auth?: boolean }

export async function api<T = any>(path: string, opts: RequestOptions = {}): Promise<T> {
  const headers: Record<string, string> = {}
  const token = opts.auth === false ? null : getToken()
  if (token) headers.Authorization = `Bearer ${token}`
  if (opts.body !== undefined) headers['Content-Type'] = 'application/json'

  let res: Response
  try {
    res = await fetch(`${API_BASE}${path}`, {
      method: opts.method ?? (opts.body !== undefined ? 'POST' : 'GET'),
      headers,
      body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
      cache: 'no-store',
    })
  } catch {
    throw new ApiError(`Cannot reach the DevPilot backend at ${API_URL}`, 0, 'offline')
  }

  if (!res.ok) {
    let body: unknown = null
    try {
      body = await res.json()
    } catch {
      /* non-JSON error body */
    }
    const { message, code } = errorMessage(body, `${res.status} ${res.statusText}`)
    if (res.status === 401 && opts.auth !== false && typeof window !== 'undefined') {
      clearSession()
      if (!window.location.pathname.startsWith('/login')) {
        window.location.href = `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`
      }
    }
    throw new ApiError(message, res.status, code)
  }
  return (opts.text ? await res.text() : await res.json()) as T
}

/* ------------------------------------------------------------------ */
/* Backend shapes                                                       */
/* ------------------------------------------------------------------ */

export type MissionStatus = 'created' | 'planning' | 'running' | 'awaiting_human' | 'completed' | 'failed' | 'stopped'

export type MissionSummary = {
  mission_id: string
  title: string
  status: MissionStatus
  created_at: number
  updated_at: number
  progress: Progress
}

export type Progress = {
  tasks: Record<string, number>
  criteria: Record<string, number>
  open_findings: number
  open_issues: number
  tool_calls?: number
}

export type GuildAgent = {
  agent_id: string
  name: string
  team: string
  role: string
  skills: string[]
  tools: string[]
  badge: string
  char_idx: number
  always_on: boolean
  clearance: 'GREEN' | 'AMBER'
  default_mandate: string
}

export type Criterion = {
  id: string
  text: string
  status: 'pending' | 'met' | 'unmet' | 'unverifiable'
  evidence_ids: string[]
  verified_by: string | null
  note: string | null
}

export type MissionTask = {
  id: string
  title: string
  description: string
  kind: string
  status: 'pending' | 'in_progress' | 'blocked' | 'done' | 'failed' | 'cancelled'
  depends_on: string[]
  assignee: string | null
  attempts: number
  failures: number
  result_summary: string | null
  origin: string | null
  updated_at: number
}

export type Finding = {
  id: string
  agent: string
  kind: string
  severity: 'info' | 'low' | 'medium' | 'high' | 'critical'
  title: string
  detail: string
  file: string | null
  line: number | null
  status: 'open' | 'addressed' | 'disputed' | 'dismissed'
  resolution: string | null
}

export type Decision = { id: string; by: string; decision: string; reason: string; task_id: string | null; at: number }

export type Issue = {
  id: string
  raised_by: string
  kind: 'question' | 'clarification' | 'blocker' | 'dispute'
  text: string
  needs_human: boolean
  status: 'open' | 'resolved'
  resolution: string | null
}

export type EvidenceItem = {
  evidence_id: string
  kind: string
  agent: string
  passed: boolean | null
  summary: string
  task_id: string | null
  at: number
}

export type ApplyRecord = {
  status: string
  approval_id: string
  requested_by: string
  decided_by: string | null
  files: string[]
  error: string | null
}

export type MissionDoc = {
  mission_id: string
  title: string
  request: string
  repo_path: string
  status: MissionStatus
  status_reason: string | null
  report: string | null
  application: ApplyRecord | null
  hired_agents: string[]
}

export type EventEnvelope = {
  event_id: string
  mission_id: string
  kind: string
  at: number
  seq: number
  data: Record<string, any>
}

/* ------------------------------------------------------------------ */
/* Endpoints                                                            */
/* ------------------------------------------------------------------ */

export const endpoints = {
  login: (username: string, password: string) =>
    api<{ access_token: string; user: AuthUser }>('/auth/login', { body: { username, password }, auth: false }),
  me: () => api<AuthUser & { auth_enabled?: boolean }>('/auth/me'),

  agents: () => api<{ agents: GuildAgent[] }>('/agents'),

  listMissions: (limit = 50) => api<{ missions: MissionSummary[] }>(`/missions?limit=${limit}`),
  createMission: (body: { request: string; repo_path: string; title?: string; start: boolean }) =>
    api<{ mission: MissionDoc }>('/missions', { body }),
  mission: (id: string) => api<{ mission: MissionDoc }>(`/missions/${id}`).then((r) => r.mission),
  snapshot: (id: string) => api<any>(`/missions/${id}/snapshot`),
  run: (id: string) => api(`/missions/${id}/run`, { method: 'POST' }),
  stop: (id: string, reason: string) => api(`/missions/${id}/stop`, { body: { reason } }),
  patch: (id: string) => api<string>(`/missions/${id}/patch`, { text: true }),
  requestApply: (id: string) => api<{ approval: { approval_id: string } }>(`/missions/${id}/apply`, { method: 'POST' }),
  resolveIssue: (id: string, issueId: string, resolution: string) =>
    api(`/missions/${id}/issues/${issueId}/resolve`, { body: { resolution } }),
  respondApproval: (approvalId: string, approved: boolean, note?: string) =>
    api(`/approvals/${approvalId}/respond`, { body: { approved, note } }),
}

export function missionSocketUrl(missionId: string, afterSeq: number): string {
  const token = getToken()
  const params = new URLSearchParams({ after_seq: String(afterSeq) })
  if (token) params.set('token', token)
  return `${WS_BASE}/realtime/missions/${missionId}?${params}`
}
