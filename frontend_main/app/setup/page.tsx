'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { endpoints, getUser, hasRole } from '@/lib/api'
import { resolveSession } from '@/lib/auth'
import { ArrowRight, FolderGit2, FileText, Rocket } from 'lucide-react'

const REPO_KEY = 'devpilot_last_repo'

/** New mission: a plain-language request plus the repository the guild should work on. */
export default function NewMissionPage() {
  const router = useRouter()
  const [request, setRequest] = useState('')
  const [repoPath, setRepoPath] = useState('')
  const [title, setTitle] = useState('')
  const [start, setStart] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [canCreate, setCanCreate] = useState(true)

  useEffect(() => {
    try {
      setRepoPath(localStorage.getItem(REPO_KEY) ?? '')
    } catch {
      /* storage unavailable */
    }
    resolveSession()
      .then((user) => {
        if (!user) router.replace('/login?next=/setup')
        else setCanCreate(hasRole(getUser(), 'operator'))
      })
      .catch((err) => setError(err instanceof Error ? err.message : String(err)))
  }, [router])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      const res = await endpoints.createMission({
        request: request.trim(),
        repo_path: repoPath.trim(),
        title: title.trim() || undefined,
        start,
      })
      try {
        localStorage.setItem(REPO_KEY, repoPath.trim())
      } catch {
        /* storage unavailable */
      }
      router.push(`/control?mission=${res.mission.mission_id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
      setSubmitting(false)
    }
  }

  return (
    <main className="relative flex min-h-svh flex-col bg-[#fff6f8] p-5 md:p-8">
      <header className="mx-auto flex w-full max-w-2xl items-center justify-between pb-6">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-base">🌸</span>
          <span className="text-xs font-bold text-[#1c1917] uppercase tracking-wider">New mission</span>
        </Link>
        <Link href="/control" className="text-xs font-semibold text-[#78716c] hover:text-[#1c1917]">
          Mission control →
        </Link>
      </header>

      <form onSubmit={handleSubmit} className="glass-panel mx-auto w-full max-w-2xl space-y-5 p-6 shadow-xl sm:p-8">
        <div>
          <h1 className="text-lg font-bold text-[#1c1917]">What should the guild build or fix?</h1>
          <p className="mt-1 text-xs text-[#78716c]">
            Kenji turns this into acceptance criteria, Maya hires the specialists, and nothing touches
            your repository until you approve the final change.
          </p>
        </div>

        <label className="block">
          <span className="flex items-center gap-1.5 text-[11px] font-semibold text-[#1c1917]">
            <FileText className="h-3.5 w-3.5" /> Request
          </span>
          <textarea
            value={request}
            onChange={(e) => setRequest(e.target.value)}
            required
            minLength={3}
            rows={6}
            placeholder="e.g. Add a discount code to the checkout: SAVE10 takes 10% off the subtotal. Reject unknown codes with a clear error and add tests."
            className="mt-1 w-full rounded-xl border border-white/70 bg-white/60 px-3 py-2 text-sm text-foreground outline-none transition-all focus:border-rose-300 focus:bg-white/90"
          />
        </label>

        <label className="block">
          <span className="flex items-center gap-1.5 text-[11px] font-semibold text-[#1c1917]">
            <FolderGit2 className="h-3.5 w-3.5" /> Repository path (on the backend machine)
          </span>
          <input
            value={repoPath}
            onChange={(e) => setRepoPath(e.target.value)}
            required
            placeholder="D:\Projects\devPolit\missions\01-feature-discounts\repo"
            className="mt-1 w-full rounded-xl border border-white/70 bg-white/60 px-3 py-2 font-mono text-xs text-foreground outline-none transition-all focus:border-rose-300 focus:bg-white/90"
          />
          <span className="mt-1 block text-[10px] text-[#a8a29e]">
            The guild works on a sandboxed copy; the original changes only after you approve the apply.
          </span>
        </label>

        <label className="block">
          <span className="text-[11px] font-semibold text-[#1c1917]">Title (optional)</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            maxLength={200}
            className="mt-1 w-full rounded-xl border border-white/70 bg-white/60 px-3 py-2 text-xs text-foreground outline-none transition-all focus:border-rose-300 focus:bg-white/90"
          />
        </label>

        <label className="flex items-center gap-2 text-xs text-[#44403c]">
          <input
            type="checkbox"
            checked={start}
            onChange={(e) => setStart(e.target.checked)}
            className="h-3.5 w-3.5 rounded accent-rose-600"
          />
          Start the guild right away
        </label>

        {!canCreate && (
          <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs text-amber-900">
            Your role is viewer — an operator, approver or admin must create missions.
          </p>
        )}
        {error && <p className="rounded-xl bg-rose-50 px-3 py-2 text-xs text-rose-800">{error}</p>}

        <button
          type="submit"
          disabled={submitting || !canCreate}
          className="flex w-full items-center justify-center gap-1.5 rounded-full bg-[#1c1917] py-2.5 text-xs font-semibold text-rose-100 shadow-xs transition-all hover:bg-rose-950 disabled:opacity-50"
        >
          <Rocket className="h-3.5 w-3.5" />
          <span>{submitting ? 'Creating mission…' : start ? 'Launch mission' : 'Create mission'}</span>
          <ArrowRight className="h-3 w-3" />
        </button>
      </form>
    </main>
  )
}
