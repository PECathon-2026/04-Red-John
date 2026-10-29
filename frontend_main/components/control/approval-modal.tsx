'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { API_URL } from '@/lib/mission-sim'
import { getToken } from '@/lib/auth'
import { ShieldAlert, Check, X } from 'lucide-react'

export type ApprovalRequest = {
  approval_id: string
  agent: string
  tool: string
  intent: string
  risk: 'GREEN' | 'AMBER' | 'RED'
  reason?: string
  args_preview?: string
}

async function submitDecision(approval_id: string, approved: boolean) {
  const token = getToken()
  try {
    await fetch(`${API_URL}/api/v1/realtime/approvals/${approval_id}/respond`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ approved }),
    })
  } catch {
    // Backend offline: proceed with optimistic local resolution
  }
}

export function ApprovalModal({
  request,
  onResolved,
}: {
  request: ApprovalRequest
  onResolved: (approval_id: string) => void
}) {
  const [submitting, setSubmitting] = useState(false)

  const handleDecision = useCallback(
    async (approved: boolean) => {
      setSubmitting(true)
      try {
        await submitDecision(request.approval_id, approved)
      } finally {
        onResolved(request.approval_id)
      }
    },
    [request.approval_id, onResolved],
  )

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm"
    >
      <div className="w-full max-w-lg overflow-hidden rounded-3xl bg-white shadow-2xl animate-soft-enter">
        {/* Header */}
        <div className="border-b border-amber-100 bg-amber-50/80 p-5">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-amber-100 text-amber-800">
              <ShieldAlert className="h-5 w-5" />
            </div>
            <div>
              <span className="rounded-full bg-amber-200/60 px-2 py-0.5 text-[10px] font-bold text-amber-900">
                AMBER CLEARANCE
              </span>
              <h3 className="text-base font-bold text-[#1c1a2e]">
                Operator Approval Requested
              </h3>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="space-y-4 p-6 text-sm">
          <div>
            <p className="text-xs text-muted-foreground">Requesting Agent</p>
            <p className="font-semibold text-[#1c1a2e]">
              {request.agent} → <span className="font-mono text-purple-600">{request.tool}</span>
            </p>
          </div>

          <div className="rounded-2xl bg-gray-50 p-4 border border-black/[0.04]">
            <p className="text-xs text-muted-foreground mb-1">Declared Intent</p>
            <p className="text-sm font-medium leading-relaxed text-[#2a2640]">
              {request.intent}
            </p>
          </div>

          {request.reason && (
            <div>
              <p className="text-xs text-muted-foreground mb-1">Reasoning</p>
              <p className="text-xs text-[#524d68] leading-relaxed">
                {request.reason}
              </p>
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 border-t border-border/50 bg-gray-50/80 px-6 py-4">
          <button
            disabled={submitting}
            onClick={() => handleDecision(false)}
            className="flex items-center gap-1.5 rounded-full border border-black/10 bg-white px-5 py-2 text-xs font-semibold text-gray-700 transition-all hover:bg-gray-100 disabled:opacity-50"
          >
            <X className="h-3.5 w-3.5 text-red-500" />
            Deny Call
          </button>
          <button
            disabled={submitting}
            onClick={() => handleDecision(true)}
            className="flex items-center gap-1.5 rounded-full bg-[#191924] px-5 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:bg-[#2b2a3d] disabled:opacity-50"
          >
            <Check className="h-3.5 w-3.5 text-emerald-400" />
            Approve & Execute
          </button>
        </div>
      </div>
    </div>
  )
}

