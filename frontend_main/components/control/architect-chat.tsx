'use client'

import { useEffect, useRef, useState } from 'react'
import { X, Send, Sparkles } from 'lucide-react'

function getOfflineArchitectResponse(query: string): string {
  const q = query.toLowerCase()
  if (q.includes('dual') || q.includes('cheapest') || q.includes('supplier')) {
    return 'Dual-sourcing protects against single-point-of-failure risks. While primary suppliers offer lower unit costs, secondary suppliers provide redundancy in the event of port delays, customs freezes, or factory shutdowns.'
  }
  if (q.includes('down') || q.includes('fails') || q.includes('failure')) {
    return 'If Supplier A goes down, Atlas and Marco immediately trigger the autonomous rerouting protocol, shifting up to 60% of production allocation to pre-qualified secondary partners without human delay.'
  }
  if (q.includes('stock') || q.includes('30-day') || q.includes('inventory')) {
    return 'The 30-day buffer absorbs transpacific shipping volatility and port congestion without encumbering excess working capital, calculated from our Monte Carlo demand models.'
  }
  return 'Atlas (Lead Architect) reporting. In offline bypass mode, our 21-agent network architecture is operating under simulated parameters. All nodes from raw materials to final distribution remain fully verified and resilient.'
}

const SUGGESTIONS = [
  'Why dual-sourcing instead of cheapest?',
  'What happens if a node fails?',
  'Explain the safety stock buffer',
]

type Message = {
  id: string
  role: 'user' | 'assistant'
  content: string
}

export function ArchitectChat({ projectId }: { projectId: string | null }) {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'welcome',
      role: 'assistant',
      content:
        'Konnichiwa. I am Atlas, Lead Architect. Inquire about any node, clan decision, or stress test.',
    },
  ])
  const [input, setInput] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const el = scrollRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [messages])

  async function handleSend(textToSend?: string) {
    const text = (textToSend || input).trim()
    if (!text || busy) return

    const userMsg: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: text,
    }
    setMessages((prev) => [...prev, userMsg])
    setInput('')
    setBusy(true)

    try {
      const res = await fetch('/api/architect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: [...messages, userMsg].map((m) => ({
            role: m.role,
            content: m.content,
          })),
          projectId,
        }),
      })

      if (res.ok) {
        const textRes = await res.text()
        setMessages((prev) => [
          ...prev,
          {
            id: (Date.now() + 1).toString(),
            role: 'assistant',
            content: textRes || getOfflineArchitectResponse(text),
          },
        ])
      } else {
        throw new Error('API offline')
      }
    } catch {
      setTimeout(() => {
        setMessages((prev) => [
          ...prev,
          {
            id: (Date.now() + 1).toString(),
            role: 'assistant',
            content: getOfflineArchitectResponse(text),
          },
        ])
        setBusy(false)
      }, 400)
      return
    }
    setBusy(false)
  }

  return (
    <div>
      {/* Minimal Floating Glass Pill */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="flex items-center gap-1.5 rounded-full border border-white/70 bg-white/40 px-3.5 py-1.5 text-xs font-semibold text-[#1c1917] shadow-md backdrop-blur-xl transition-all hover:scale-105 hover:bg-white/60 active:scale-95"
        >
          <span className="text-xs">🌸</span>
          <span>Ask Architect</span>
        </button>
      )}

      {/* Expanded Floating Glass Chat Window */}
      {isOpen && (
        <div className="flex h-[380px] w-76 flex-col overflow-hidden rounded-3xl border border-white/70 bg-white/60 shadow-2xl backdrop-blur-2xl sm:w-88 animate-section-enter">
          {/* Minimal Glass Header */}
          <div className="flex shrink-0 items-center justify-between border-b border-rose-100/60 bg-white/40 px-4 py-2.5 backdrop-blur-md">
            <div className="flex items-center gap-2">
              <span className="text-sm">🌸</span>
              <h4 className="text-xs font-bold text-[#1c1917]">
                Atlas Directives
              </h4>
            </div>

            <button
              onClick={() => setIsOpen(false)}
              className="flex h-5 w-5 items-center justify-center rounded-full text-muted-foreground hover:bg-rose-100/60 hover:text-foreground"
            >
              <X className="h-3 w-3" />
            </button>
          </div>

          {/* Messages Feed */}
          <div
            ref={scrollRef}
            className="clean-scroll min-h-0 flex-1 space-y-2.5 overflow-y-auto p-3 text-xs"
          >
            {messages.map((m) => (
              <div
                key={m.id}
                className={`flex ${
                  m.role === 'user' ? 'justify-end' : 'justify-start'
                }`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-3 py-2 leading-relaxed ${
                    m.role === 'user'
                      ? 'bg-[#1c1917] text-rose-100'
                      : 'border border-white/60 bg-white/60 text-[#292524] shadow-2xs'
                  }`}
                >
                  {m.content}
                </div>
              </div>
            ))}
            {busy && (
              <div className="flex justify-start">
                <div className="flex items-center gap-1 rounded-2xl bg-white/50 px-3 py-1.5 text-rose-400">
                  <span className="h-1.5 w-1.5 rounded-full bg-rose-400 animate-bounce" />
                  <span className="h-1.5 w-1.5 rounded-full bg-rose-400 animate-bounce [animation-delay:0.15s]" />
                  <span className="h-1.5 w-1.5 rounded-full bg-rose-400 animate-bounce [animation-delay:0.3s]" />
                </div>
              </div>
            )}
          </div>

          {/* Suggestions */}
          <div className="border-t border-rose-100/40 bg-white/20 p-1.5">
            <div className="clean-scroll flex gap-1 overflow-x-auto pb-0.5">
              {SUGGESTIONS.map((sug) => (
                <button
                  key={sug}
                  onClick={() => handleSend(sug)}
                  className="shrink-0 rounded-full border border-white/70 bg-white/50 px-2 py-0.5 text-[9px] text-[#57534e] hover:bg-rose-50"
                >
                  {sug}
                </button>
              ))}
            </div>
          </div>

          {/* Form */}
          <form
            onSubmit={(e) => {
              e.preventDefault()
              handleSend()
            }}
            className="flex items-center gap-1 border-t border-rose-100/50 bg-white/50 p-1.5"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask Atlas..."
              className="flex-1 bg-transparent px-2 text-xs outline-none placeholder:text-[#a8a29e]"
            />
            <button
              type="submit"
              disabled={!input.trim() || busy}
              className="flex h-6 w-6 items-center justify-center rounded-full bg-[#1c1917] text-white disabled:opacity-30"
            >
              <Send className="h-2.5 w-2.5" />
            </button>
          </form>
        </div>
      )}
    </div>
  )
}
