/**
 * Sign-in against backend_main (`POST /api/v1/auth/login`, username + password).
 * When the server runs with AUTH_ENABLED=false, `GET /auth/me` answers without a
 * token and the app signs in as the local principal.
 */

import { ApiError, clearSession, endpoints, getToken, getUser, saveSession, type AuthUser } from './api'

export { API_URL } from './api'
export { clearSession, getToken, getUser, hasRole, type AuthUser } from './api'

export async function loginUser(username: string, password: string): Promise<AuthUser> {
  const res = await endpoints.login(username.trim(), password)
  saveSession(res.access_token, res.user)
  return res.user
}

/**
 * Is there a usable session? Verifies a stored token with the backend, or
 * detects a server running without auth. Returns null when the user must sign in.
 */
export async function resolveSession(): Promise<AuthUser | null> {
  try {
    const me = await endpoints.me()
    const user: AuthUser = { user_id: me.user_id, username: me.username, role: me.role }
    saveSession(getToken(), user)
    return user
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      clearSession()
      return null
    }
    throw err
  }
}

export function signOut() {
  clearSession()
  if (typeof window !== 'undefined') window.location.href = '/login'
}

export function currentUser(): AuthUser | null {
  return getUser()
}
