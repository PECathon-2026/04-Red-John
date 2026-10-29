'use client'

import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { cn } from '@/lib/utils'
import {
  BLUEPRINT_STAGES,
  COUNCIL_DECISION,
  downstreamIds,
  findNode,
  upstreamIds,
  type BlueprintNode,
  type BlueprintStage,
} from '@/lib/blueprint'
import { TransformWrapper, TransformComponent } from 'react-zoom-pan-pinch'
import { ArchitectChat } from './architect-chat'
import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import { Download, X } from 'lucide-react'

const RISK_STYLES: Record<NonNullable<BlueprintNode['risk']>, string> = {
  low: 'bg-emerald-50 text-emerald-800 border-emerald-200',
  medium: 'bg-amber-50 text-amber-800 border-amber-200',
  high: 'bg-rose-50 text-rose-800 border-rose-200',
}

type Edge = { key: string; from: string; to: string; label?: string; d: string; mx: number; my: number }

export function BlueprintMap({
  onClose,
  architectureReport,
  projectId,
}: {
  onClose: () => void
  architectureReport?: any
  projectId: string | null
}) {
  const atlas = architectureReport?.atlas_executive
  const isLive = Array.isArray(atlas?.stages) && atlas.stages.length > 0
  const stages: BlueprintStage[] = isLive ? atlas.stages : BLUEPRINT_STAGES
  const decision = isLive && atlas.decision ? atlas.decision : COUNCIL_DECISION

  const dynamicNodes = useMemo(() => stages.flatMap((s: any) => s.nodes || []), [stages])
  const findNodeDynamic = useCallback(
    (id: string) => dynamicNodes.find((n: any) => n.id === id),
    [dynamicNodes],
  )

  const downstreamIdsDynamic = useCallback(
    (node: any) => {
      if (node.flowsTo?.length) return node.flowsTo
      const i = stages.findIndex((s: any) => s.id === node.stage)
      return stages[i + 1]?.nodes?.map((n: any) => n.id) ?? []
    },
    [stages],
  )

  const upstreamIdsDynamic = useCallback(
    (node: any) => {
      return dynamicNodes
        .filter((n: any) => downstreamIdsDynamic(n).includes(node.id))
        .map((n: any) => n.id)
    },
    [dynamicNodes, downstreamIdsDynamic],
  )

  const [selectedId, setSelectedId] = useState<string>(dynamicNodes[0]?.id || 'sup-a')
  const [hoverId, setHoverId] = useState<string | null>(null)
  const [edges, setEdges] = useState<Edge[]>([])
  const [canvas, setCanvas] = useState({ w: 0, h: 0 })

  const canvasRef = useRef<HTMLDivElement>(null)
  const nodeRefs = useRef(new Map<string, HTMLElement | null>())
  const closeRef = useRef<HTMLButtonElement>(null)

  const selected = findNodeDynamic(selectedId)
  const activeId = hoverId ?? selectedId

  const highlightedIds = useMemo(() => {
    const active = findNodeDynamic(activeId)
    if (!active) return new Set<string>()
    return new Set<string>([
      active.id,
      ...downstreamIdsDynamic(active),
      ...upstreamIdsDynamic(active),
    ])
  }, [activeId, findNodeDynamic, downstreamIdsDynamic, upstreamIdsDynamic])

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm"
    >
      <div className="flex h-[92vh] w-[95vw] max-w-7xl flex-col overflow-hidden rounded-3xl bg-white shadow-2xl animate-soft-enter">
        {/* Header */}
        <header className="flex shrink-0 items-center justify-between border-b border-border/60 bg-white px-6 py-4">
          <div>
            <h3 className="text-base font-bold text-[#1c1a2e]">
              Supply Network Topology Map
            </h3>
            <p className="text-xs text-muted-foreground">
              Autonomous supply network architecture & routing
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              ref={closeRef}
              onClick={onClose}
              className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-muted-foreground hover:bg-gray-200"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </header>

        {/* Map Stages */}
        <div className="clean-scroll flex-1 overflow-auto bg-[#faf9fe] p-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-5">
            {stages.map((stage) => (
              <div key={stage.id} className="space-y-3">
                <div className="border-b border-purple-200/60 pb-2">
                  <h4 className="text-xs font-bold text-purple-900 uppercase tracking-wider">
                    {stage.title}
                  </h4>
                </div>

                <div className="space-y-3">
                  {stage.nodes.map((node) => {
                    const isSelected = selectedId === node.id
                    return (
                      <button
                        key={node.id}
                        onClick={() => setSelectedId(node.id)}
                        className={`w-full rounded-2xl border p-3.5 text-left transition-all ${
                          isSelected
                            ? 'border-purple-500 bg-purple-50/70 shadow-sm ring-2 ring-purple-200'
                            : 'border-black/[0.04] bg-white hover:border-purple-200'
                        }`}
                      >
                        <div className="flex items-center justify-between pb-1">
                          <span className="font-semibold text-xs text-[#1c1a2e]">
                            {node.label}
                          </span>
                          {node.risk && (
                            <span
                              className={`rounded-full border px-2 py-0.5 text-[9px] font-bold ${
                                RISK_STYLES[node.risk]
                              }`}
                            >
                              {node.risk.toUpperCase()}
                            </span>
                          )}
                        </div>
                        <p className="line-clamp-2 text-[11px] text-muted-foreground">
                          {node.detail || node.location}
                        </p>
                      </button>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>

          {/* Selected Node Details Drawer */}
          {selected && (
            <div className="mt-8 rounded-2xl border border-purple-100 bg-white p-5 shadow-sm">
              <h4 className="text-sm font-bold text-[#1c1a2e]">
                Node Specification: {selected.label}
              </h4>
              <p className="mt-1 text-xs text-muted-foreground leading-relaxed">
                {selected.detail}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

