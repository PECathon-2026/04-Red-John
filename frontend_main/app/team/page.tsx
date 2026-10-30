'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { AGENTS, type AgentDef, type Team } from '@/lib/agents'
import { TeamCard } from '@/components/theme/team-card'
import { JapanBackground } from '@/components/theme/japan-background'
import { AgentDossierCard } from '@/components/control/agent-dossier-card'
import { ArrowLeft, Search, Sparkles } from 'lucide-react'

const TEAMS: (Team | 'All')[] = [
  'All',
  'Executive',
  'Planning',
  'Forge',
  'Sentinel',
  'Shadow',
  'Support',
]

export default function TeamShowcasePage() {
  const [selectedTeam, setSelectedTeam] = useState<Team | 'All'>('All')
  const [search, setSearch] = useState('')
  const [activeDossier, setActiveDossier] = useState<AgentDef | null>(null)

  const filtered = AGENTS.filter((a) => {
    const matchesTeam = selectedTeam === 'All' || a.team === selectedTeam
    const matchesSearch =
      a.name.toLowerCase().includes(search.toLowerCase()) ||
      a.role.toLowerCase().includes(search.toLowerCase())
    return matchesTeam && matchesSearch
  })

  return (
    <main className="relative min-h-screen w-full overflow-x-hidden p-6 md:p-10 selection:bg-rose-200 selection:text-rose-900">
      {/* ── Background: Washi paper, drift mesh blobs, sumi-e mountains, cherry blossoms ── */}
      <JapanBackground />

      <div className="mx-auto max-w-7xl">
        {/* ── Top Navigation Bar ── */}
        <header className="mb-8 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Link
              href="/control"
              className="flex items-center gap-1.5 rounded-full border border-white/70 bg-white/50 px-4 py-2 text-xs font-semibold text-[#1D1D1F] shadow-2xs backdrop-blur-md transition-all hover:bg-white hover:scale-105 active:scale-95"
            >
              <ArrowLeft className="h-3.5 w-3.5" />
              <span>Back to Mission Control</span>
            </Link>
          </div>

          <Link href="/" className="flex items-center gap-2 group">
            <div className="flex h-9 items-center justify-center rounded-lg bg-[#0d0914] px-3.5 py-1 border border-white/10 shadow-xs transition-transform group-hover:scale-105">
              <Image
                src="/images/devpilot-logo-cropped.png"
                alt="DevPilot Logo"
                width={150}
                height={24}
                className="h-5 w-auto object-contain"
                priority
              />
            </div>
            <span className="hidden sm:inline text-xs font-bold tracking-wider text-[#1D1D1F] uppercase">
              Engineering Guild
            </span>
          </Link>
        </header>

        {/* ── Hero / Title Section ── */}
        <div className="mb-8 max-w-3xl">
          <div className="inline-flex items-center gap-2 rounded-full border border-rose-200/60 bg-white/40 px-3.5 py-1 text-xs font-medium text-rose-900 shadow-2xs backdrop-blur-md">
            <Sparkles className="h-3 w-3 text-rose-600" />
            <span>Autonomous AI Engineering Guild Personnel</span>
          </div>

          <h1 className="mt-3 text-3xl font-bold tracking-tight text-[#1D1D1F] sm:text-5xl">
            Specialist Directory
          </h1>
          <p className="mt-2 text-sm leading-relaxed text-[#2B2B2B]/75 sm:text-base">
            Synchronized team of 21 AI specialists engineered for supply chain resilience,
            architecture, intelligence reconnaissance, and autonomous code execution.
          </p>
        </div>

        {/* ── Filter & Search Controls ── */}
        <div className="mb-8 flex flex-wrap items-center justify-between gap-4 rounded-3xl border border-white/70 bg-white/40 p-3 md:p-4 backdrop-blur-xl shadow-xs">
          {/* Team Filter Pills */}
          <div className="flex flex-wrap gap-1.5">
            {TEAMS.map((team) => {
              const isSelected = selectedTeam === team

              return (
                <button
                  key={team}
                  type="button"
                  onClick={() => setSelectedTeam(team)}
                  className={`flex items-center rounded-full px-3.5 py-1.5 text-xs font-medium transition-all ${
                    isSelected
                      ? 'bg-[#1D1D1F] text-rose-100 shadow-sm'
                      : 'bg-white/50 text-[#2B2B2B]/75 hover:bg-white/80'
                  }`}
                >
                  <span>{team}</span>
                </button>
              )
            })}
          </div>

          {/* Search Box */}
          <div className="relative w-full sm:w-64">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Filter by name or title..."
              className="w-full rounded-full border border-white/70 bg-white/60 px-4 py-2 pl-9 text-xs text-[#1D1D1F] outline-none placeholder:text-[#8c827a] shadow-2xs backdrop-blur-md focus:border-rose-400 focus:bg-white"
            />
            <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#8c827a]" />
          </div>
        </div>

        {/* ── Responsive 3-Column Grid of TeamCards ── */}
        <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
          {filtered.map((agent, idx) => (
            <TeamCard
              key={agent.name}
              index={idx}
              name={agent.name}
              title={agent.role}
              department={agent.team}
              status="working"
              avatar={agent.charIdx}
              onOpenDetails={() => setActiveDossier(agent)}
            />
          ))}
        </div>

        {filtered.length === 0 && (
          <div className="flex h-64 flex-col items-center justify-center text-center">
            <p className="text-sm font-medium text-[#2B2B2B]/70">
              No specialists found matching &quot;{search}&quot;.
            </p>
          </div>
        )}
      </div>

      {/* ── Dossier Modal ── */}
      {activeDossier && (
        <AgentDossierCard
          agent={activeDossier}
          onClose={() => setActiveDossier(null)}
        />
      )}
    </main>
  )
}
