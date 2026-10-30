'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { loginUser, resolveSession } from '@/lib/auth'
import { API_URL } from '@/lib/api'
import { Lock, User, ArrowRight } from 'lucide-react'

function nextPath(): string {
  if (typeof window === 'undefined') return '/control'
  const next = new URLSearchParams(window.location.search).get('next')
  // Only same-site paths.
  return next && next.startsWith('/') && !next.startsWith('//') ? next : '/control'
}

export default function LoginPage() {
  const router = useRouter()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [checking, setChecking] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Already signed in, or the backend runs without auth → straight through.
  useEffect(() => {
    resolveSession()
      .then((user) => {
        if (user) router.replace(nextPath())
        else setChecking(false)
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : String(err))
        setChecking(false)
      })
  }, [router])

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      await loginUser(username, password)
      router.push(nextPath())
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign-in failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="relative flex min-h-svh items-center justify-center bg-[#fff6f8] p-4">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute -left-20 -top-20 h-96 w-96 rounded-full bg-rose-200/40 blur-3xl" />
        <div className="absolute -right-20 -bottom-20 h-96 w-96 rounded-full bg-pink-200/40 blur-3xl" />
      </div>

      <div className="glass-panel relative z-10 w-full max-w-sm overflow-hidden p-6 sm:p-7 shadow-xl">
        <div className="text-center">
          <Link href="/" className="inline-block transition-transform hover:scale-105">
            <div className="mx-auto flex h-14 w-full max-w-[240px] items-center justify-center rounded-xl bg-[#0d0914] border border-white/10 px-3 py-1.5 shadow-md">
              <Image
                src="/images/devpilot-logo-cropped.png"
                alt="DevPilot Logo"
                width={200}
                height={30}
                className="h-7 w-auto object-contain"
                priority
              />
            </div>
          </Link>
          <h2 className="mt-3 text-base font-bold tracking-tight text-[#1c1917] uppercase">Sign in</h2>
          <p className="mt-0.5 text-xs text-[#78716c]">DevPilot mission control</p>
        </div>

        {error && (
          <div className="mt-4 rounded-xl border border-rose-200 bg-rose-50/80 p-2.5 text-center text-xs text-rose-800">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="mt-5 space-y-3.5">
          <div>
            <label htmlFor="username" className="text-[11px] font-semibold text-[#1c1917]">
              Username
            </label>
            <div className="relative mt-1">
              <input
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoComplete="username"
                required
                disabled={checking}
                className="w-full rounded-xl border border-white/70 bg-white/50 px-3 py-2 text-xs text-foreground outline-none transition-all focus:border-rose-300 focus:bg-white/80"
              />
              <User className="pointer-events-none absolute right-3 top-2.5 h-3.5 w-3.5 text-[#a8a29e]" />
            </div>
          </div>

          <div>
            <label htmlFor="password" className="text-[11px] font-semibold text-[#1c1917]">
              Password
            </label>
            <div className="relative mt-1">
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                required
                disabled={checking}
                className="w-full rounded-xl border border-white/70 bg-white/50 px-3 py-2 text-xs text-foreground outline-none transition-all focus:border-rose-300 focus:bg-white/80"
              />
              <Lock className="pointer-events-none absolute right-3 top-2.5 h-3.5 w-3.5 text-[#a8a29e]" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading || checking}
            className="flex w-full items-center justify-center gap-1.5 rounded-full bg-[#1c1917] py-2.5 text-xs font-semibold text-rose-100 shadow-xs transition-all hover:bg-rose-950 disabled:opacity-50"
          >
            <span>{checking ? 'Checking session…' : loading ? 'Signing in…' : 'Sign in'}</span>
            <ArrowRight className="h-3 w-3" />
          </button>
        </form>

        <p className="mt-5 text-center text-[10px] text-[#a8a29e]">
          Backend: <span className="font-mono">{API_URL}</span>
        </p>
      </div>
    </main>
  )
}
