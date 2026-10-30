'use client'

import { useCallback, useState } from 'react'
import { ApiError, endpoints, getUser, hasRole } from '@/lib/api'
import type { ApprovalRequest } from '@/lib/mission-sim'
import { ShieldAlert, Check, X } from 'lucide-react'

export type { ApprovalRequest } from '@/lib/mission-sim'

const RISK_STYLE: Record<string, { band: string; chip: string; icon: string; label: string }> = {
  GREEN: { band: 'border-emerald-100 bg-emerald-50/80', chip: 'bg-emerald-200/60 text-emerald-900', icon: 'bg-emerald-100 text-emerald-800', label: 'GREEN CLEARANCE' },
  AMBER: { band: 'border-amber-100 bg-amber-50/80', chip: 'bg-amber-200/60 text-amber-900', icon: 'bg-amber-100 text-amber-800', label: 'AMBER CLEARANCE' },
  RED: { band: 'border-red-100 bg-red-50/80', chip: 'bg-red-200/60 text-red-900', icon: 'bg-red-100 text-red-800', label: 'RED — BLOCKED BY DEFAULT' },
}

export function ApprovalModal({
  request,
  onResolved,
}: {
  request: ApprovalRequest
  onResolved: (approval_id: string) => void
}) {
  const [submitting, setSubmitting] = useState(false)
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)
  const canDecide = hasRole(getUser(), 'approver')
  const style = RISK_STYLE[request.risk] ?? RISK_STYLE.AMBER

  const handleDecision = useCallback(
    async (approved: boolean) => {
      setSubmitting(true)
      setError(null)
      try {
        await endpoints.respondApproval(request.approval_id, approved, note.trim() || undefined)
        onResolved(request.approval_id)
      } catch (err) {
        // 409: already decided or expired — nothing left to answer.
        if (err instanceof ApiError && (err.status === 409 || err.status === 404)) {
          onResolved(request.approval_id)
          return
        }
        setError(err instanceof Error ? err.message : String(err))
        setSubmitting(false)
      }
    },
    [request.approval_id, note, onResolved],
  )

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm"
    >
      <div className="w-full max-w-lg overflow-hidden rounded-3xl bg-white shadow-2xl animate-soft-enter">
        {/* Header */}
        <div className={`border-b p-5 ${style.band}`}>
          <div className="flex items-center gap-3">
            <div className={`flex h-10 w-10 items-center justify-center rounded-2xl ${style.icon}`}>
              <ShieldAlert className="h-5 w-5" />
            </div>
            <div>
              <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${style.chip}`}>
                {style.label}
                {request.category ? ` · ${request.category.toUpperCase()}` : ''}
              </span>
              <h3 className="text-base font-bold text-[#1c1a2e]">Human approval requested</h3>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="space-y-4 p-6 text-sm">
          <div>
            <p className="text-xs text-muted-foreground">Requesting agent</p>
            <p className="font-semibold text-[#1c1a2e]">
              {request.agent} → <span className="font-mono text-purple-600">{request.tool}</span>
            </p>
          </div>

          <div className="rounded-2xl bg-gray-50 p-4 border border-black/[0.04]">
            <p className="text-xs text-muted-foreground mb-1">Intent</p>
            <p className="text-sm font-medium leading-relaxed text-[#2a2640]">{request.intent}</p>
          </div>

          {request.reason && (
            <div>
              <p className="text-xs text-muted-foreground mb-1">Why it needs approval</p>
              <p className="text-xs text-[#524d68] leading-relaxed">{request.reason}</p>
            </div>
          )}

          {request.args_preview && (
            <div>
              <p className="text-xs text-muted-foreground mb-1">Arguments</p>
              <pre className="max-h-40 overflow-auto rounded-xl bg-[#1c1917] p-3 font-mono text-[11px] leading-relaxed text-rose-50 whitespace-pre-wrap break-all">
                {request.args_preview}
              </pre>
            </div>
          )}

          {canDecide ? (
            <input
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Note for the audit log (optional)"
              className="w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-xs outline-none focus:border-rose-300"
            />
          ) : (
            <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs text-amber-900">
              Your role cannot decide approvals — an approver or admin must answer this.
            </p>
          )}

          {error && <p className="rounded-xl bg-red-50 px-3 py-2 text-xs text-red-800">{error}</p>}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 border-t border-border/50 bg-gray-50/80 px-6 py-4">
          <button
            disabled={submitting || !canDecide}
            onClick={() => handleDecision(false)}
            className="flex items-center gap-1.5 rounded-full border border-black/10 bg-white px-5 py-2 text-xs font-semibold text-gray-700 transition-all hover:bg-gray-100 disabled:opacity-50"
          >
            <X className="h-3.5 w-3.5 text-red-500" />
            Deny
          </button>
          <button
            disabled={submitting || !canDecide}
            onClick={() => handleDecision(true)}
            className="flex items-center gap-1.5 rounded-full bg-[#191924] px-5 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:bg-[#2b2a3d] disabled:opacity-50"
          >
            <Check className="h-3.5 w-3.5 text-emerald-400" />
            Approve
          </button>
        </div>
      </div>
    </div>
  )
}
