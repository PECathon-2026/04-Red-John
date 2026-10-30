'use client'

import { useEffect, useRef, useState } from 'react'
import { formatElapsed, type AtlasLog } from '@/lib/mission-sim'
import { Scroll, Maximize2, Minimize2 } from 'lucide-react'

const LEVEL_BADGES: Record<
  string,
  { label: string; badgeClass: string; textClass: string }
> = {
  info: {
    label: 'INFO',
    badgeClass: 'bg-stone-100/70 text-stone-700 border-stone-200/60',
    textClass: 'text-[#292524]',
  },
  action: {
    label: 'ACTION',
    badgeClass: 'bg-rose-100/70 text-rose-800 border-rose-200/60',
    textClass: 'text-rose-950 font-medium',
  },
  success: {
    label: 'DONE',
    badgeClass: 'bg-emerald-100/70 text-emerald-800 border-emerald-200/60',
    textClass: 'text-emerald-950',
  },
  warn: {
    label: 'ALERT',
    badgeClass: 'bg-amber-100/70 text-amber-800 border-amber-200/60',
    textClass: 'text-amber-950',
  },
  error: {
    label: 'ERROR',
    badgeClass: 'bg-red-100/70 text-red-800 border-red-200/60',
    textClass: 'text-red-950 font-semibold',
  },
  armor: {
    label: 'GATE',
    badgeClass: 'bg-rose-200/60 text-rose-900 border-rose-300/60',
    textClass: 'text-rose-950 font-medium',
  },
}

export function AtlasLogTab({
  logs,
  complete,
}: {
  logs: AtlasLog[]
  complete: boolean
}) {
  const [filter, setFilter] = useState<string>('all')
  const [isExpanded, setIsExpanded] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' })
  }, [logs.length])

  const filteredLogs =
    filter === 'all' ? logs : logs.filter((l) => l.level === filter)

  return (
    <div
      className={`glass-panel flex flex-col overflow-hidden transition-all duration-300 ${
        isExpanded ? 'fixed inset-4 z-50 shadow-2xl' : 'h-full'
      }`}
    >
      {/* Minimalist Glass Header */}
      <div className="flex shrink-0 items-center justify-between border-b border-white/40 bg-white/30 px-4 py-2.5 backdrop-blur-md">
        <div className="flex items-center gap-2">
          <Scroll className="h-3.5 w-3.5 text-rose-600" />
          <h3 className="text-xs font-semibold tracking-wide text-[#1c1917] uppercase">
            Activity Logs
          </h3>
          <span className="text-[10px] text-muted-foreground">
            ({logs.length})
          </span>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1">
          {['all', 'action', 'armor', 'success'].map((lvl) => (
            <button
              key={lvl}
              onClick={() => setFilter(lvl)}
              className={`rounded-full px-2 py-0.5 text-[9px] font-semibold transition-all ${
                filter === lvl
                  ? 'bg-[#1c1917] text-rose-100 shadow-2xs'
                  : 'bg-white/40 text-muted-foreground hover:bg-white/70'
              }`}
            >
              {lvl.toUpperCase()}
            </button>
          ))}

          <button
            onClick={() => setIsExpanded(!isExpanded)}
            aria-label={isExpanded ? 'Collapse' : 'Expand'}
            className="ml-1 flex h-6 w-6 items-center justify-center rounded-full text-muted-foreground hover:bg-white/60 hover:text-foreground"
          >
            {isExpanded ? (
              <Minimize2 className="h-3 w-3" />
            ) : (
              <Maximize2 className="h-3 w-3" />
            )}
          </button>
        </div>
      </div>

      {/* Log Feed */}
      <div
        className="clean-scroll min-h-0 flex-1 overflow-y-auto p-3"
        data-lenis-prevent
      >
        {filteredLogs.length === 0 ? (
          <div className="flex h-32 flex-col items-center justify-center text-center">
            <p className="text-xs text-muted-foreground">
              Awaiting clan mission scroll entries...
            </p>
          </div>
        ) : (
          <div className="space-y-1.5">
            {filteredLogs.map((log, idx) => {
              const meta = LEVEL_BADGES[log.level] || LEVEL_BADGES.info
              return (
                <div
                  key={`${log.id}-${idx}`}
                  className="flex items-start gap-2 rounded-xl border border-white/60 bg-white/40 p-2 text-left backdrop-blur-md shadow-2xs"
                >
                  <span className="shrink-0 font-mono text-[9px] text-[#a8a29e]">
                    T+{formatElapsed(log.at)}
                  </span>

                  <span
                    className={`shrink-0 rounded-md border px-1.5 py-0.2 text-[8px] font-bold tracking-wide ${meta.badgeClass}`}
                  >
                    {meta.label}
                  </span>

                  <span
                    className={`flex-1 text-[11px] leading-relaxed ${meta.textClass}`}
                  >
                    {log.text}
                  </span>
                </div>
              )
            })}
            <div ref={bottomRef} />
          </div>
        )}
      </div>
    </div>
  )
}
