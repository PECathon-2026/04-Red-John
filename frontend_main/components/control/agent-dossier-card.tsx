'use client'

import { useCallback, useEffect, useRef } from 'react'
import { cn } from '@/lib/utils'
import { TEAM_COLORS, type AgentDef } from '@/lib/agents'
import { AgentSprite } from '@/components/pixel/agent-sprite'
import { X, CheckCircle, Wrench } from 'lucide-react'

export function AgentDossierCard({
  agent,
  onClose,
}: {
  agent: AgentDef
  onClose: () => void
}) {
  const colors = TEAM_COLORS[agent.team]
  const closeRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    closeRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const onBackdrop = useCallback(
    (e: React.MouseEvent) => {
      if (e.target === e.currentTarget) onClose()
    },
    [onClose],
  )

  return (
    <div
      role="dialog"
      aria-modal="true"
      onClick={onBackdrop}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4 backdrop-blur-md"
    >
      <div className="flex max-h-[85vh] w-full max-w-xl flex-col overflow-hidden rounded-3xl border border-white/70 bg-white/90 shadow-2xl backdrop-blur-2xl animate-section-enter">
        {/* Header */}
        <header
          className={`relative flex items-center justify-between border-b px-5 py-4 ${
            colors ? colors.cardBg : 'bg-rose-50/70'
          }`}
        >
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-white/80 shadow-xs">
              <AgentSprite charIdx={agent.charIdx} scale={2} />
            </div>
            <div>
              <span
                className={`rounded-full px-2.5 py-0.5 text-[10px] font-semibold ${
                  colors ? colors.chip : 'bg-purple-100 text-purple-800'
                }`}
              >
                {agent.team} Team
              </span>
              <h3 className="mt-1 text-xl font-bold text-[#1c1a2e]">
                {agent.name}
              </h3>
              <p className="text-xs text-muted-foreground">{agent.role}</p>
              <p className="mt-0.5 font-mono text-[10px] text-muted-foreground">
                {agent.badge} · {agent.clearance} clearance{agent.alwaysOn ? ' · always on' : ''}
              </p>
            </div>
          </div>

          <button
            ref={closeRef}
            onClick={onClose}
            aria-label="Close"
            className="flex h-8 w-8 items-center justify-center rounded-full bg-white/80 text-muted-foreground transition-all hover:bg-white hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </header>

        {/* Scrollable Body */}
        <div className="clean-scroll min-h-0 flex-1 space-y-6 overflow-y-auto p-6 text-sm">
          {/* Mission */}
          <div className="rounded-2xl bg-[#faf9fe] p-4 border border-purple-100/60">
            <h4 className="text-xs font-semibold text-purple-900 uppercase tracking-wider mb-1">
              Default Mandate
            </h4>
            <p className="text-sm leading-relaxed text-[#2d2844]">
              {agent.detail || 'Assigned by Atlas per task.'}
            </p>
          </div>

          {/* Responsibilities */}
          <div>
            <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2.5">
              Skills (what Maya hires on)
            </h4>
            <ul className="grid grid-cols-1 gap-2.5 sm:grid-cols-2">
              {agent.skills.map((r) => (
                <li
                  key={r}
                  className="flex items-start gap-2.5 rounded-xl bg-gray-50/80 p-2.5 text-xs text-[#2b2742]"
                >
                  <CheckCircle className="h-3.5 w-3.5 shrink-0 text-purple-500 mt-0.5" />
                  <span>{r}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Tools */}
          {agent.tools.length > 0 && (
            <div>
              <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2.5">
                Tools
              </h4>
              <div className="flex flex-wrap gap-2">
                {agent.tools.map((t) => (
                  <span
                    key={t}
                    className="flex items-center gap-1.5 rounded-lg bg-gray-100 px-2.5 py-1 text-xs font-mono text-[#332f4a]"
                  >
                    <Wrench className="h-3 w-3 text-muted-foreground" />
                    {t}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <footer className="flex shrink-0 items-center justify-between border-t border-border/50 bg-gray-50/80 px-6 py-3 text-xs text-muted-foreground">
          <span>Agent Dossier · {agent.name}</span>
          <span>Press Esc to close</span>
        </footer>
      </div>
    </div>
  )
}

