'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useRouter, useSearchParams } from 'next/navigation'
import { useMission } from '@/lib/mission-sim'
import { resolveSession, signOut } from '@/lib/auth'
import { OfficeViewport } from './office-viewport'
import { AgentCardsSidebar } from './agent-cards-sidebar'
import { PerformanceChart } from './performance-chart'
import { TaskProgressCard } from './task-progress-card'
import { AgentLeaderboardCard } from './agent-leaderboard-card'
import { AtlasLogTab } from './atlas-log'
import { AgentRosterTab } from './agent-roster'
import { MissionBoardTab } from './mission-board-tab'
import { MissionPicker } from './mission-picker'
import { HireCardsTab } from './hire-cards'
import { ApprovalModal } from './approval-modal'
import { AgentDossierCard } from './agent-dossier-card'
import { JapanBackground } from '@/components/theme/japan-background'
import type { AgentDef } from '@/lib/agents'
import {
  Compass,
  Users,
  Scroll,
  Shield,
  ClipboardList,
  Plus,
  LayoutList,
  LogOut,
} from 'lucide-react'

type NavSection = 'dashboard' | 'agents' | 'logs' | 'hires' | 'board'

interface NavItem {
  id: NavSection
  label: string
  icon: typeof Compass
  badge?: string | number
}

export function ControlRoom() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const missionId = searchParams.get('mission') || searchParams.get('project')
  const [authed, setAuthed] = useState(false)
  const mission = useMission(authed ? missionId : null)

  // No session (and the server requires one) → sign in first.
  useEffect(() => {
    resolveSession()
      .then((user) => {
        if (user) setAuthed(true)
        else router.replace(`/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`)
      })
      .catch(() => setAuthed(true)) // backend unreachable: let the views show the error
  }, [router])

  const [activeSection, setActiveSection] = useState<NavSection>('dashboard')
  const [selectedAgent, setSelectedAgent] = useState<AgentDef | null>(null)

  const pendingApprovals = mission.pendingApprovals ?? []
  const topApproval = pendingApprovals[0] ?? null

  function dismissApproval(approval_id: string) {
    mission.dismissApproval(approval_id)
  }

  const navItems: NavItem[] = [
    { id: 'dashboard', label: 'Dashboard', icon: Compass },
    { id: 'board', label: 'Mission Board', icon: ClipboardList, badge: mission.issues.filter((i) => i.status === 'open').length || undefined },
    { id: 'agents', label: 'Specialists', icon: Users, badge: Object.keys(mission.agents).length },
    { id: 'logs', label: 'Activity Logs', icon: Scroll, badge: mission.logs.length },
    { id: 'hires', label: 'Personnel', icon: Shield, badge: mission.hires.length },
  ]

  return (
    <div className="relative flex h-screen w-screen overflow-hidden bg-transparent p-3 md:p-3.5 gap-3 md:gap-3.5 text-[#1c1917]">
      {/* ── BACKGROUND: WASHI PAPER + DRIFT BLOBS + INK MOUNTAINS + SAKURA PETALS ── */}
      <JapanBackground />

      {/* ── 1. MINIMALIST GLASS SIDEBAR ── */}
      <aside className="glass-sidebar flex h-full w-12 shrink-0 flex-col items-center justify-between rounded-full py-4 shadow-sm transition-all duration-300">
        {/* Top: Modern Hexagon Crest */}
        <div className="flex flex-col items-center gap-5">
          <Link
            href="/"
            className="group relative flex h-8 w-8 items-center justify-center rounded-full bg-[#0d0914] p-1 border border-white/20 shadow-xs transition-all duration-300 hover:scale-110 hover:border-rose-400 active:scale-95 overflow-hidden"
            title="DevPilot Overview"
          >
            <Image
              src="/images/devpilot-logo-cropped.png"
              alt="DevPilot"
              width={80}
              height={12}
              className="h-auto w-full object-contain transition-transform duration-300 group-hover:scale-110"
              priority
            />
          </Link>

          {/* Nav Icons with Smooth Fluid Indicator */}
          <nav className="flex flex-col items-center gap-2.5">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = activeSection === item.id

              return (
                <div key={item.id} className="relative group">
                  <button
                    onClick={() => setActiveSection(item.id)}
                    aria-label={item.label}
                    className={`relative flex h-8 w-8 items-center justify-center rounded-full transition-all duration-300 ease-out ${
                      isActive
                        ? 'bg-[#1c1917] text-rose-200 shadow-xs scale-105'
                        : 'text-[#78716c] hover:bg-rose-100/60 hover:text-[#1c1917] hover:scale-105'
                    }`}
                  >
                    <Icon className="h-3.5 w-3.5 transition-transform duration-200 group-hover:scale-110" />

                    {/* Minimalist alert dot */}
                    {item.id === 'board' && (mission.complete || mission.issues.some((i) => i.status === 'open')) && (
                      <span className="absolute right-0.5 top-0.5 h-1.5 w-1.5 rounded-full bg-rose-500 animate-sakura-pulse" />
                    )}
                  </button>

                  {/* Minimalist Floating Tooltip Pill */}
                  <div className="pointer-events-none absolute left-12 top-1/2 -translate-y-1/2 z-50 whitespace-nowrap rounded-xl bg-[#1c1917] px-2.5 py-1 text-[11px] font-medium text-rose-100 opacity-0 shadow-md transition-all duration-200 group-hover:opacity-100 group-hover:translate-x-1">
                    {item.label}
                    {item.badge !== undefined && (
                      <span className="ml-1 text-[9px] text-rose-300">
                        ({item.badge})
                      </span>
                    )}
                  </div>
                </div>
              )
            })}
          </nav>
        </div>

        {/* Bottom: Minimalist Exit / Setup */}
        <div className="flex flex-col items-center gap-2">
          <Link
            href="/control"
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#a8a29e] transition-all hover:bg-rose-100/60 hover:text-[#1c1917]"
            title="All missions"
          >
            <LayoutList className="h-3.5 w-3.5" />
          </Link>
          <Link
            href="/setup"
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#a8a29e] transition-all hover:bg-rose-100/60 hover:text-[#1c1917]"
            title="New mission"
          >
            <Plus className="h-3.5 w-3.5" />
          </Link>
          <button
            onClick={signOut}
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#a8a29e] transition-all hover:bg-rose-100/60 hover:text-rose-700"
            title="Sign out"
          >
            <LogOut className="h-3 w-3" />
          </button>
        </div>
      </aside>

      {/* ── 2. MAIN LAYOUT: PIXEL OFFICE (>60% SCREEN) + GLASS DISPLAY AREA (NO SCROLLING) ── */}
      {!missionId ? (
        <div className="flex min-w-0 flex-1 h-full overflow-hidden">
          {authed && <MissionPicker onPick={(id) => router.push(`/control?mission=${id}`)} />}
        </div>
      ) : (
      <div className="flex min-w-0 flex-1 gap-3 md:gap-3.5 h-full overflow-hidden">
        {/* LEFT / CENTER VIEWPORT: PIXEL OFFICE (STABLE, FIXED >60% SCREEN, NO EXTENDING) */}
        <section className="flex-[1.45] min-w-0 h-full overflow-hidden">
          <OfficeViewport mission={mission} />
        </section>

        {/* RIGHT DISPLAY PANEL (~38% SCREEN, PURE GLASSMORPHISM, SMOOTH TRANSITIONS) */}
        <section className="flex-1 min-w-[340px] max-w-[460px] h-full overflow-hidden">
          <div
            key={activeSection}
            className="animate-section-enter h-full w-full overflow-hidden"
          >
            {activeSection === 'dashboard' && (
              <div
                className="glass-panel clean-scroll flex h-full flex-col p-3.5 gap-3.5 overflow-y-auto"
                data-lenis-prevent
              >
                {/* 1. Top Section: Specialist Leads */}
                <div className="shrink-0">
                  <AgentCardsSidebar mission={mission} onSelectAgent={(agent) => setSelectedAgent(agent)} />
                </div>

                {/* 2. Middle Section: Performance Velocity Chart */}
                <div className="h-44 shrink-0">
                  <PerformanceChart mission={mission} />
                </div>

                {/* 3. Bottom Grid: Directives + Mastery Ranks */}
                <div className="grid grid-cols-2 gap-2.5 h-44 shrink-0 pb-1">
                  <div className="h-full">
                    <TaskProgressCard mission={mission} />
                  </div>
                  <div className="h-full">
                    <AgentLeaderboardCard mission={mission} />
                  </div>
                </div>
              </div>
            )}

            {activeSection === 'agents' && (
              <div className="h-full w-full overflow-hidden">
                <AgentRosterTab
                  agents={mission.agents}
                  clock={mission.clock}
                />
              </div>
            )}

            {activeSection === 'logs' && (
              <div className="h-full w-full overflow-hidden">
                <AtlasLogTab logs={mission.logs} complete={mission.complete} />
              </div>
            )}

            {activeSection === 'hires' && (
              <div className="h-full w-full overflow-hidden">
                <HireCardsTab
                  hires={mission.hires}
                  agents={mission.agents}
                  clock={mission.clock}
                />
              </div>
            )}

            {activeSection === 'board' && (
              <div className="h-full w-full overflow-hidden">
                <MissionBoardTab mission={mission} />
              </div>
            )}
          </div>
        </section>
      </div>
      )}

      {/* ── MODALS ── */}
      {selectedAgent && (
        <AgentDossierCard
          agent={selectedAgent}
          onClose={() => setSelectedAgent(null)}
        />
      )}

      {topApproval && (
        <ApprovalModal
          request={topApproval}
          onResolved={dismissApproval}
        />
      )}
    </div>
  )
}
