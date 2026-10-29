'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { saveSetup, getToken } from '@/lib/auth'
import {
  Check,
  ArrowRight,
  ArrowLeft,
  Layers,
  Globe2,
  Calendar,
  Sparkles,
} from 'lucide-react'

export default function SetupPage() {
  const router = useRouter()
  const [currentStep, setCurrentStep] = useState(0)
  const [submitting, setSubmitting] = useState(false)

  const [formData, setFormData] = useState({
    businessType: 'Hardware & IoT Electronics',
    productDescription: 'Autonomous sensor node with cellular backhaul',
    targetRegions: ['North America', 'European Union'],
    annualUnits: '50,000 units / year',
    targetLaunch: 'Q4 2026',
    priorities: 'Resilience over lowest initial landed cost; Dual-sourcing on MCUs',
  })

  const steps = [
    { title: 'Product Spec', icon: Layers },
    { title: 'Markets', icon: Globe2 },
    { title: 'Volume', icon: Calendar },
    { title: 'Directives', icon: Sparkles },
  ]

  async function handleComplete() {
    setSubmitting(true)
    const token = getToken() || 'mock-token'
    try {
      const res = await saveSetup(token, formData)
      router.push(`/control?project=${res.project_id}`)
    } catch {
      router.push('/control')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <main className="relative flex min-h-svh flex-col justify-between bg-[#fff6f8] p-5 md:p-8">
      {/* Top Header */}
      <header className="mx-auto flex w-full max-w-2xl items-center justify-between pb-6">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-base">🌸</span>
          <span className="text-xs font-bold text-[#1c1917] uppercase tracking-wider">
            Directives Setup
          </span>
        </Link>

        <Link
          href="/control"
          className="text-xs font-semibold text-[#78716c] hover:text-[#1c1917]"
        >
          Skip to Dojo →
        </Link>
      </header>

      {/* Stepper Wizard Card */}
      <div className="glass-panel mx-auto w-full max-w-2xl p-6 shadow-xl sm:p-8">
        {/* Step Indicators */}
        <div className="mb-6 flex items-center justify-between">
          {steps.map((st, i) => {
            const Icon = st.icon
            const isDone = i < currentStep
            const isCurrent = i === currentStep
            return (
              <div key={st.title} className="flex flex-1 items-center">
                <div className="flex flex-col items-center">
                  <div
                    className={`flex h-8 w-8 items-center justify-center rounded-xl transition-all ${
                      isDone
                        ? 'bg-[#1c1917] text-rose-200'
                        : isCurrent
                          ? 'border border-rose-400 bg-rose-50 text-rose-700 shadow-2xs'
                          : 'bg-white/40 text-[#a8a29e]'
                    }`}
                  >
                    {isDone ? <Check className="h-3.5 w-3.5" /> : <Icon className="h-3.5 w-3.5" />}
                  </div>
                  <span className="mt-1.5 hidden text-[10px] font-semibold text-[#1c1917] sm:block">
                    {st.title}
                  </span>
                </div>
                {i < steps.length - 1 && (
                  <div
                    className={`mx-2 h-0.5 flex-1 transition-all ${
                      i < currentStep ? 'bg-[#1c1917]' : 'bg-rose-100/60'
                    }`}
                  />
                )}
              </div>
            )
          })}
        </div>

        {/* Step Content */}
        <div className="min-h-[200px] space-y-4">
          {currentStep === 0 && (
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-[#1c1917]">
                  Category / Architecture Scope
                </label>
                <input
                  type="text"
                  value={formData.businessType}
                  onChange={(e) =>
                    setFormData({ ...formData, businessType: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-white/70 bg-white/40 px-3.5 py-2 text-xs outline-none focus:bg-white/70"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-[#1c1917]">
                  Technical Specification
                </label>
                <textarea
                  rows={3}
                  value={formData.productDescription}
                  onChange={(e) =>
                    setFormData({ ...formData, productDescription: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-white/70 bg-white/40 px-3.5 py-2 text-xs outline-none focus:bg-white/70"
                />
              </div>
            </div>
          )}

          {currentStep === 1 && (
            <div className="space-y-3">
              <label className="text-xs font-semibold text-[#1c1917]">
                Target Regions
              </label>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {['North America', 'European Union', 'East Asia', 'Southeast Asia', 'South America', 'India'].map(
                  (reg) => {
                    const selected = formData.targetRegions.includes(reg)
                    return (
                      <button
                        key={reg}
                        type="button"
                        onClick={() => {
                          const next = selected
                            ? formData.targetRegions.filter((r) => r !== reg)
                            : [...formData.targetRegions, reg]
                          setFormData({ ...formData, targetRegions: next })
                        }}
                        className={`rounded-xl border p-3 text-left transition-all ${
                          selected
                            ? 'border-rose-400 bg-rose-50/70 text-rose-950 font-semibold'
                            : 'border-white/60 bg-white/40 text-[#57534e] hover:bg-white/70'
                        }`}
                      >
                        <span className="text-xs">{reg}</span>
                      </button>
                    )
                  },
                )}
              </div>
            </div>
          )}

          {currentStep === 2 && (
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-[#1c1917]">
                  Volume
                </label>
                <input
                  type="text"
                  value={formData.annualUnits}
                  onChange={(e) =>
                    setFormData({ ...formData, annualUnits: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-white/70 bg-white/40 px-3.5 py-2 text-xs outline-none focus:bg-white/70"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-[#1c1917]">
                  Timeline
                </label>
                <input
                  type="text"
                  value={formData.targetLaunch}
                  onChange={(e) =>
                    setFormData({ ...formData, targetLaunch: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-white/70 bg-white/40 px-3.5 py-2 text-xs outline-none focus:bg-white/70"
                />
              </div>
            </div>
          )}

          {currentStep === 3 && (
            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-[#1c1917]">
                  Clan Resilience Directives
                </label>
                <textarea
                  rows={3}
                  value={formData.priorities}
                  onChange={(e) =>
                    setFormData({ ...formData, priorities: e.target.value })
                  }
                  className="mt-1 w-full rounded-xl border border-white/70 bg-white/40 px-3.5 py-2 text-xs outline-none focus:bg-white/70"
                />
              </div>
            </div>
          )}
        </div>

        {/* Buttons */}
        <div className="mt-6 flex items-center justify-between border-t border-rose-100/50 pt-4">
          <button
            type="button"
            disabled={currentStep === 0}
            onClick={() => setCurrentStep((prev) => prev - 1)}
            className="flex items-center gap-1 rounded-full px-4 py-2 text-xs font-semibold text-[#78716c] hover:bg-white/50 disabled:opacity-30"
          >
            <ArrowLeft className="h-3 w-3" />
            <span>Back</span>
          </button>

          {currentStep < steps.length - 1 ? (
            <button
              type="button"
              onClick={() => setCurrentStep((prev) => prev + 1)}
              className="flex items-center gap-1 rounded-full bg-[#1c1917] px-5 py-2 text-xs font-semibold text-rose-100 shadow-2xs hover:bg-rose-950"
            >
              <span>Continue</span>
              <ArrowRight className="h-3 w-3" />
            </button>
          ) : (
            <button
              type="button"
              disabled={submitting}
              onClick={handleComplete}
              className="flex items-center gap-1.5 rounded-full bg-[#1c1917] px-6 py-2 text-xs font-semibold text-rose-200 shadow-md hover:bg-rose-950 disabled:opacity-50"
            >
              <span>{submitting ? 'Commissioning...' : 'Launch Directives'}</span>
            </button>
          )}
        </div>
      </div>

      <footer className="mx-auto mt-4 text-center text-[10px] text-[#a8a29e]">
        DevPilot Dojo Directives
      </footer>
    </main>
  )
}
