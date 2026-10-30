import Link from 'next/link'
import { ArrowRight, Compass, Shield, Users, Search } from 'lucide-react'

export default function WelcomePage() {
  return (
    <main className="relative flex min-h-svh flex-col justify-between overflow-hidden bg-[#fbf6f0]">
      {/* Background ambient glows */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute -left-20 -top-20 h-96 w-96 rounded-full bg-rose-200/35 blur-3xl" />
        <div className="absolute -right-20 top-40 h-96 w-96 rounded-full bg-pink-200/35 blur-3xl" />
        <div className="absolute bottom-20 left-1/3 h-96 w-96 rounded-full bg-red-100/30 blur-3xl" />
      </div>

      {/* Minimal Glass Header */}
      <header className="relative z-10 flex items-center justify-between px-6 py-5 md:px-10">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-[#1c1917] text-white">
            <Compass className="h-4 w-4" />
          </div>
          <span className="text-sm font-bold tracking-wider text-[#1c1917] uppercase">
            DevPilot
          </span>
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/login"
            className="rounded-full border border-white/70 bg-white/50 px-4 py-1.5 text-xs font-semibold text-[#1c1917] shadow-2xs backdrop-blur-md transition-all hover:bg-white/80"
          >
            Sign In
          </Link>
          <Link
            href="/control"
            className="flex items-center gap-1.5 rounded-full bg-[#1c1917] px-4 py-1.5 text-xs font-semibold text-rose-100 shadow-sm transition-all hover:bg-rose-950 hover:scale-105 active:scale-95"
          >
            <span>Enter Dashboard</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative z-10 mx-auto flex max-w-3xl flex-1 flex-col items-center justify-center px-6 py-12 text-center">
        {/* Pill */}
        <div className="inline-flex items-center gap-2 rounded-full border border-rose-200/60 bg-white/60 px-3.5 py-1 text-xs font-medium text-rose-900 shadow-2xs backdrop-blur-md">
          <Users className="h-3 w-3 text-rose-600" />
          <span>Autonomous AI Engineering Organization</span>
        </div>

        {/* Main Title */}
        <h1 className="mt-5 text-4xl font-extrabold tracking-tight text-[#1c1917] sm:text-6xl md:text-7xl">
          Quiet precision.{' '}
          <span className="bg-gradient-to-r from-rose-600 via-pink-600 to-red-600 bg-clip-text text-transparent">
            Autonomous execution.
          </span>
        </h1>

        {/* Subtitle */}
        <p className="mt-5 max-w-xl text-sm leading-relaxed text-[#57534e] sm:text-base">
          A guild of 16 AI specialists that turns a plain-language request into a tested, reviewed, evidence-backed change to your repository — and applies it only after a human approves.
        </p>

        {/* Actions */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Link
            href="/control"
            className="flex items-center gap-2 rounded-full bg-[#1c1917] px-6 py-2.5 text-xs font-semibold text-rose-100 shadow-md transition-all hover:scale-105 hover:bg-rose-950 active:scale-95"
          >
            <span>Launch Mission Control</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>

          <Link
            href="/team"
            className="flex items-center gap-2 rounded-full border border-white/70 bg-white/50 px-5 py-2.5 text-xs font-semibold text-[#1c1917] shadow-2xs backdrop-blur-md transition-all hover:bg-white/70"
          >
            <span>Specialist Guild (16)</span>
          </Link>
        </div>

        {/* 3 Minimal Glass Cards */}
        <div className="mt-12 grid grid-cols-1 gap-3 sm:grid-cols-3 max-w-2xl w-full">
          <div className="rounded-2xl border border-rose-100/70 bg-white/50 p-4 text-left backdrop-blur-md shadow-2xs">
            <h4 className="text-xs font-bold text-[#1c1917]">Executive Command</h4>
            <p className="mt-0.5 text-[10px] text-[#78716c]">Atlas & Maya coordinate organizational directives and specialist resource allocation.</p>
          </div>
          <div className="rounded-2xl border border-emerald-100/70 bg-white/50 p-4 text-left backdrop-blur-md shadow-2xs">
            <h4 className="text-xs font-bold text-[#1c1917]">Intelligence & Recon</h4>
            <p className="mt-0.5 text-[10px] text-[#78716c]">Deep supplier universe scouting and external vulnerability mapping.</p>
          </div>
          <div className="rounded-2xl border border-pink-100/70 bg-white/50 p-4 text-left backdrop-blur-md shadow-2xs">
            <h4 className="text-xs font-bold text-[#1c1917]">Resilience & Defense</h4>
            <p className="mt-0.5 text-[10px] text-[#78716c]">Disruption stress-testing and autonomous reroute playbooks.</p>
          </div>
        </div>
      </section>

      {/* Minimal Footer */}
      <footer className="relative z-10 border-t border-rose-100/40 bg-white/40 py-3 backdrop-blur-md">
        <div className="flex items-center justify-between px-6 text-xs text-[#78716c]">
          <div className="flex items-center gap-1.5">
            <span className="h-1.5 w-1.5 rounded-full bg-rose-500 animate-sakura-pulse" />
            <span>Mission systems operational</span>
          </div>
          <div>DevPilot Autonomous Systems</div>
        </div>
      </footer>
    </main>
  )
}
