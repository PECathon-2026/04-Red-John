'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { useMissionSim } from '@/lib/mission-sim'
import { OfficeViewport } from './office-viewport'
import { AgentCardsSidebar } from './agent-cards-sidebar'
import { PerformanceChart } from './performance-chart'
import { TaskProgressCard } from './task-progress-card'
import { AgentLeaderboardCard } from './agent-leaderboard-card'
import { AtlasLogTab } from './atlas-log'
import { AgentRosterTab } from './agent-roster'
import { BlueprintTab } from './blueprint-tab'
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
  GitFork,
  Settings as SettingsIcon,
  LogOut,
} from 'lucide-react'

type NavSection = 'dashboard' | 'agents' | 'logs' | 'hires' | 'blueprint'

interface NavItem {
  id: NavSection
  label: string
  icon: typeof Compass
  badge?: string | number
}

export function ControlRoom() {
  const searchParams = useSearchParams()
  const projectId = searchParams.get('project')
  const mission = useMissionSim(projectId)

  const [activeSection, setActiveSection] = useState<NavSection>('dashboard')
  const [selectedAgent, setSelectedAgent] = useState<AgentDef | null>(null)

  const pendingApprovals = mission.pendingApprovals ?? []
  const topApproval = pendingApprovals[0] ?? null

  function dismissApproval(approval_id: string) {
    if (mission.dismissApproval) {
      mission.dismissApproval(approval_id)
    }
  }

  const navItems: NavItem[] = [
    { id: 'dashboard', label: 'Dashboard', icon: Compass },
    { id: 'agents', label: 'Specialists', icon: Users, badge: 21 },
    { id: 'logs', label: 'Activity Logs', icon: Scroll, badge: mission.logs.length },
    { id: 'hires', label: 'Personnel', icon: Shield, badge: mission.hires.length },
    { id: 'blueprint', label: 'Blueprint', icon: GitFork },
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
            className="group flex h-8 w-8 items-center justify-center rounded-full bg-[#1c1917] text-rose-300 shadow-xs transition-all duration-300 hover:scale-110 hover:bg-rose-950 active:scale-95"
            title="Overview"
          >
            <Compass className="h-4 w-4 transition-transform duration-300 group-hover:rotate-45" />
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
                    {item.id === 'blueprint' && mission.complete && (
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
            href={`/setup?project=${projectId || ''}`}
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#a8a29e] transition-all hover:bg-rose-100/60 hover:text-[#1c1917]"
            title="Setup"
          >
            <SettingsIcon className="h-3.5 w-3.5" />
          </Link>
          <Link
            href="/"
            className="flex h-7 w-7 items-center justify-center rounded-full text-[#a8a29e] transition-all hover:bg-rose-100/60 hover:text-rose-700"
            title="Exit"
          >
            <LogOut className="h-3 w-3" />
          </Link>
        </div>
      </aside>

      {/* ── 2. MAIN LAYOUT: PIXEL OFFICE (>60% SCREEN) + GLASS DISPLAY AREA (NO SCROLLING) ── */}
      <div className="flex min-w-0 flex-1 gap-3 md:gap-3.5 h-full overflow-hidden">
        {/* LEFT / CENTER VIEWPORT: PIXEL OFFICE (STABLE, FIXED >60% SCREEN, NO EXTENDING) */}
        <section className="flex-[1.45] min-w-0 h-full overflow-hidden">
          <OfficeViewport mission={mission} projectId={projectId} />
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
                  <AgentCardsSidebar onSelectAgent={(agent) => setSelectedAgent(agent)} />
                </div>

                {/* 2. Middle Section: Performance Velocity Chart */}
                <div className="h-44 shrink-0">
                  <PerformanceChart />
                </div>

                {/* 3. Bottom Grid: Directives + Mastery Ranks */}
                <div className="grid grid-cols-2 gap-2.5 h-44 shrink-0 pb-1">
                  <div className="h-full">
                    <TaskProgressCard mission={mission} />
                  </div>
                  <div className="h-full">
                    <AgentLeaderboardCard />
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

            {activeSection === 'blueprint' && (
              <div className="h-full w-full overflow-hidden">
                <BlueprintTab
                  complete={mission.complete}
                  architectureReport={mission.architecture_report}
                  loadingReport={mission.loadingReport}
                  demo={mission.demo}
                  projectId={projectId}
                />
              </div>
            )}
          </div>
        </section>
      </div>

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
