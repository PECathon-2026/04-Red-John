'use client'

import Image from 'next/image'
import Link from 'next/link'
import { ArrowRight, Users, Shield, Compass } from 'lucide-react'

export default function FullscreenSamuraiHomePage() {
  return (
    <main className="relative flex h-screen min-h-screen w-full flex-col justify-between overflow-hidden bg-[#0d040c] select-none selection:bg-rose-900 selection:text-rose-100">
      {/* ── 1. FULL-SCREEN SAMURAI BACKDROP (1920x1080 Native 16:9, Ultra Clean) ── */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/images/samurai-hero-fullscreen-1080p.png"
          alt="DevPilot Samurai Sentinel"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center select-none pointer-events-none"
        />

        {/* Ambient radial crimson glow blooms */}
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_90%_60%_at_50%_0%,rgba(186,24,76,0.18)_0%,transparent_60%)]" />
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_40%_at_50%_100%,rgba(112,13,43,0.15)_0%,transparent_60%)]" />
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_100%_100%_at_50%_50%,transparent_50%,rgba(10,2,8,0.5)_100%)]" />

        {/* Subtle breathing visor pulse overlay */}
        <div className="pointer-events-none absolute left-1/2 top-[34%] -translate-x-1/2 -translate-y-1/2 h-16 w-32 rounded-full bg-red-600/15 blur-xl animate-pulse" />
      </div>

      {/* ── 2. TOP HEADER (DevPilot Logo on left, Only Previous Links on right) ── */}
      <header className="relative z-20 flex items-center justify-between px-6 py-5 md:px-12 md:py-8">
        {/* DevPilot Logo (Clickable -> /) */}
        <Link
          href="/"
          className="group flex items-center transition-transform hover:scale-105 active:scale-95"
          title="DevPilot — Autonomous AI Engineering Organization"
        >
          <div className="relative">
            <Image
              src="/images/devpilot-logo-cropped.png"
              alt="DevPilot Logo"
              width={260}
              height={38}
              priority
              className="h-7 sm:h-8 md:h-9 w-auto object-contain drop-shadow-[0_2px_14px_rgba(255,255,255,0.2)] transition-all duration-300 group-hover:brightness-125 group-hover:drop-shadow-[0_0_18px_rgba(239,68,68,0.7)]"
            />
            {/* Katana light shine streak on hover */}
            <div className="pointer-events-none absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/20 to-transparent transition-transform duration-700 ease-in-out group-hover:translate-x-full" />
          </div>
        </Link>

        {/* Previous Homescreen Links: Specialists Roster, Sign In, Enter Dashboard */}
        <div className="flex items-center gap-2.5 sm:gap-3.5">
          <Link
            href="/team"
            className="hidden sm:flex items-center gap-2 rounded-full border border-white/15 bg-black/40 px-4 py-2 text-xs font-medium text-white/85 shadow-sm backdrop-blur-md transition-all hover:bg-white/10 hover:border-white/30 hover:text-white hover:scale-105 active:scale-95"
          >
            <Users className="h-3.5 w-3.5 text-rose-400" />
            <span>Specialists (21)</span>
          </Link>

          <Link
            href="/login"
            className="rounded-full border border-white/15 bg-black/40 px-4 py-2 text-xs font-semibold text-white/90 shadow-sm backdrop-blur-md transition-all hover:bg-white/10 hover:border-white/30 hover:text-white hover:scale-105 active:scale-95"
          >
            Sign In
          </Link>

          <Link
            href="/control"
            className="group flex items-center gap-1.5 rounded-full bg-gradient-to-r from-rose-600 via-rose-600 to-red-600 px-4 sm:px-5 py-2 text-xs font-bold text-white shadow-[0_0_25px_rgba(225,29,72,0.45)] backdrop-blur-md transition-all hover:scale-105 hover:brightness-110 active:scale-95"
          >
            <span>Enter Dashboard</span>
            <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
          </Link>
        </div>
      </header>

      {/* ── 3. CENTER HERO AREA (Samurai stands in center, clear and unobstructed) ── */}
      <div className="relative z-10 flex flex-1 flex-col items-center justify-end pb-8 sm:pb-10 px-6 pointer-events-none">
        {/* Mobile-only quick navigation pills */}
        <div className="pointer-events-auto flex sm:hidden flex-wrap items-center justify-center gap-2.5">
          <Link
            href="/control"
            className="flex items-center gap-1.5 rounded-full bg-rose-600 px-4 py-2 text-xs font-bold text-white shadow-lg active:scale-95"
          >
            <span>Launch Mission Control</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
          <Link
            href="/team"
            className="flex items-center gap-1.5 rounded-full border border-white/20 bg-black/50 px-3.5 py-2 text-xs font-medium text-white backdrop-blur-md active:scale-95"
          >
            <Users className="h-3.5 w-3.5 text-rose-400" />
            <span>Specialists (16)</span>
          </Link>
        </div>
      </div>

      {/* ── 4. MINIMAL FOOTER (Operational status from original homescreen) ── */}
      <footer className="relative z-20 flex items-center justify-between border-t border-white/10 bg-black/40 px-6 py-3.5 md:px-12 backdrop-blur-md text-xs text-white/60">
        <div className="flex items-center gap-2">
          <span className="h-1.5 w-1.5 rounded-full bg-rose-500 animate-pulse" />
          <span className="font-medium text-white/80">Mission systems operational</span>
        </div>

        <div className="flex items-center gap-4">
          <Link href="/team" className="hover:text-white transition-colors">
            21 AI Specialists
          </Link>
          <span className="text-white/20">•</span>
          <span className="text-white/70">DevPilot Autonomous Systems</span>
        </div>
      </footer>
    </main>
  )
}
