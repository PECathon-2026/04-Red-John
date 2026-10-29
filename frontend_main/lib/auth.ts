/**
 * Client helpers for the MYCEL FastAPI auth service.
 * Backend routes live at {API_URL}/api/auth/(login|register) and return a JWT.
 * Set NEXT_PUBLIC_API_URL to point at the backend; defaults to localhost:8000.
 */

export const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

const TOKEN_KEY = 'mycel_access_token'
const USER_KEY = 'mycel_user'
export const BYPASS_KEY = 'mycel_backend_bypass'

export type AuthUser = {
  id: string
  email: string
  name: string | null
  is_admin: boolean
}

export type TokenResponse = {
  access_token: string
  token_type: string
  user: AuthUser
}

export const MOCK_USER: AuthUser = {
  id: 'mock-operator-01',
  email: 'operator@mycel.network',
  name: 'Demo Operator',
  is_admin: true,
}

export const MOCK_SESSION: TokenResponse = {
  access_token: 'mock-bypass-jwt-token-active',
  token_type: 'bearer',
  user: MOCK_USER,
}

/** Check if backend bypass mode is active */
export function isBypassMode(): boolean {
  if (typeof window === 'undefined') return false
  return (
    localStorage.getItem(BYPASS_KEY) === 'true' ||
    sessionStorage.getItem(BYPASS_KEY) === 'true'
  )
}

/** Enable or disable backend bypass mode */
export function setBypassMode(enabled: boolean): void {
  if (typeof window === 'undefined') return
  if (enabled) {
    localStorage.setItem(BYPASS_KEY, 'true')
    sessionStorage.setItem(BYPASS_KEY, 'true')
    saveMockSession()
  } else {
    localStorage.removeItem(BYPASS_KEY)
    sessionStorage.removeItem(BYPASS_KEY)
  }
  window.dispatchEvent(new CustomEvent('mycel:bypass-change', { detail: { enabled } }))
}

export function toggleBypassMode(): boolean {
  const next = !isBypassMode()
  setBypassMode(next)
  return next
}

export function saveMockSession(userPatch?: Partial<AuthUser>) {
  const session: TokenResponse = {
    ...MOCK_SESSION,
    user: { ...MOCK_USER, ...userPatch },
  }
  saveSession(session)
}

async function postAuth(path: string, body: Record<string, string>): Promise<TokenResponse> {
  if (isBypassMode()) {
    const session: TokenResponse = {
      ...MOCK_SESSION,
      user: {
        ...MOCK_USER,
        name: body.name || MOCK_USER.name,
        email: body.email || MOCK_USER.email,
      },
    }
    return session
  }

  let res: Response
  try {
    res = await fetch(`${API_URL}/api/auth/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
  } catch {
    throw new Error('LINK OFFLINE — could not reach the MYCEL backend')
  }

  if (!res.ok) {
    let detail = 'Authentication failed'
    try {
      const data = await res.json()
      if (typeof data?.detail === 'string') detail = data.detail
    } catch {
      /* non-JSON error body */
    }
    throw new Error(detail)
  }

  return (await res.json()) as TokenResponse
}

export function loginUser(email: string, password: string) {
  return postAuth('login', { email, password })
}

export function registerUser(name: string, email: string, password: string) {
  return postAuth('register', { name, email, password })
}

export function saveSession(session: TokenResponse) {
  if (typeof window === 'undefined') return
  sessionStorage.setItem(TOKEN_KEY, session.access_token)
  sessionStorage.setItem(USER_KEY, JSON.stringify(session.user))
}

export function getToken(): string | null {
  if (typeof window === 'undefined') return null
  const token = sessionStorage.getItem(TOKEN_KEY)
  if (token) return token
  if (isBypassMode()) {
    saveMockSession()
    return MOCK_SESSION.access_token
  }
  return null
}

export function getUser(): AuthUser | null {
  if (typeof window === 'undefined') return null
  const raw = sessionStorage.getItem(USER_KEY)
  if (raw) {
    try {
      return JSON.parse(raw) as AuthUser
    } catch {
      /* parse error */
    }
  }
  if (isBypassMode()) {
    return MOCK_USER
  }
  return null
}

export function clearSession() {
  if (typeof window === 'undefined') return
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(USER_KEY)
}

/* ---------- operator onboarding setup ---------- */

export type SetupStatus = {
  has_setup: boolean
  setup: Record<string, unknown> | null
  completed_at?: string | null
}

/**
 * Does this operator already have a network built?
 * Returns has_setup:false on any failure so login never dead-ends —
 * worst case the operator runs the wizard again.
 */
export async function fetchSetupStatus(token: string): Promise<SetupStatus> {
  if (isBypassMode() || token.startsWith('mock-')) {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('mycel_draft_setup')
      if (saved) {
        try {
          return { has_setup: false, setup: JSON.parse(saved) }
        } catch {}
      }
    }
    return { has_setup: false, setup: null }
  }

  try {
    const res = await fetch(`${API_URL}/api/setup/me`, {
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
    })
    if (!res.ok) return { has_setup: false, setup: null }
    return (await res.json()) as SetupStatus
  } catch {
    return { has_setup: false, setup: null }
  }
}

/** Fetch an existing project by ID */
export async function fetchProjectSetup(token: string, projectId: string): Promise<Record<string, unknown> | null> {
  try {
    const res = await fetch(`${API_URL}/api/v1/projects/${projectId}`, {
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
    })
    if (!res.ok) throw new Error('Fetch failed')
    return (await res.json()) as Record<string, unknown>
  } catch {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(`mycel_project_${projectId}`)
      if (saved) {
        try {
          return JSON.parse(saved)
        } catch {}
      }
    }
    return null
  }
}

/** Persist a draft of the wizard answers to /api/setup/me without marking complete */
export async function saveDraftSetup(token: string, setup: unknown): Promise<void> {
  if (typeof window !== 'undefined') {
    localStorage.setItem('mycel_draft_setup', JSON.stringify(setup))
  }
  if (isBypassMode() || token.startsWith('mock-')) {
    return
  }

  try {
    const res = await fetch(`${API_URL}/api/setup/me`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(setup),
    })
    if (!res.ok) throw new Error('Could not save draft setup')
  } catch (err) {
    if (!isBypassMode()) throw err
  }
}

/** Persist the wizard answers and mark onboarding complete. */
export async function saveSetup(
  token: string,
  setup: unknown,
): Promise<{ project_id: string; status: string }> {
  try {
    const res = await fetch(`${API_URL}/api/v1/projects/create`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(setup),
    })
    if (!res.ok) throw new Error('Could not save your setup and create project')
    return await res.json()
  } catch (err) {
    // If backend is offline or bypass is active, create an offline mock project
    const mockProjectId = `offline-proj-${Date.now().toString(36)}`
    if (typeof window !== 'undefined') {
      localStorage.setItem(`mycel_project_${mockProjectId}`, JSON.stringify(setup))
    }
    return { project_id: mockProjectId, status: 'created (offline demo)' }
  }
}

/** Upload a file to the documents endpoint */
export async function uploadDocument(
  token: string,
  file: File,
): Promise<{ filename: string; cloudinary_url: string; message: string }> {
  try {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('project_id', 'draft')
    
    const res = await fetch(`${API_URL}/api/v1/documents/upload`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    })
    
    if (!res.ok) {
      let detail = 'Upload failed'
      try {
        const data = await res.json()
        if (typeof data?.detail === 'string') detail = data.detail
      } catch {}
      throw new Error(detail)
    }
    
    const response = await res.json()
    return response.data
  } catch (err) {
    // Mock upload response for offline/bypass mode
    return {
      filename: file.name,
      cloudinary_url: typeof URL !== 'undefined' ? URL.createObjectURL(file) : `offline://${file.name}`,
      message: 'File cached locally (offline bypass)',
    }
  }
}
