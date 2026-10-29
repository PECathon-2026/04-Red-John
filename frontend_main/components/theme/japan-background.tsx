'use client'

import React, { useEffect, useRef, useState } from 'react'

interface Petal {
  x: number
  y: number
  size: number
  speedY: number
  swaySpeed: number
  swayAmp: number
  swayPhase: number
  angle: number
  rotSpeed: number
  opacity: number
}

export function JapanBackground({
  isDark = false,
}: {
  isDark?: boolean
  showForePetals?: boolean
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [reducedMotion, setReducedMotion] = useState(false)
  const mouseRef = useRef({ x: 0, y: 0, targetX: 0, targetY: 0, isMoving: false })
  const parallaxRef = useRef<HTMLDivElement>(null)

  // 1. Accessibility: Detect prefers-reduced-motion
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    setReducedMotion(mq.matches)
    const listener = (e: MediaQueryListEvent) => setReducedMotion(e.matches)
    mq.addEventListener('change', listener)
    return () => mq.removeEventListener('change', listener)
  }, [])

  // 2. High-Performance Throttled Parallax (Sleeps when idle)
  useEffect(() => {
    if (reducedMotion) return
    let animId: number | null = null
    let isTicking = false

    const updateParallax = () => {
      const dx = mouseRef.current.targetX - mouseRef.current.x
      const dy = mouseRef.current.targetY - mouseRef.current.y

      // Only interpolate and update DOM if there's actual motion
      if (Math.abs(dx) > 0.05 || Math.abs(dy) > 0.05) {
        mouseRef.current.x += dx * 0.08
        mouseRef.current.y += dy * 0.08
        if (parallaxRef.current) {
          parallaxRef.current.style.transform = `translate3d(${mouseRef.current.x.toFixed(1)}px, ${mouseRef.current.y.toFixed(1)}px, 0)`
        }
        animId = requestAnimationFrame(updateParallax)
      } else {
        isTicking = false
      }
    }

    const handleMouseMove = (e: MouseEvent) => {
      const nx = (e.clientX / window.innerWidth) * 2 - 1
      const ny = (e.clientY / window.innerHeight) * 2 - 1
      mouseRef.current.targetX = -nx * 12
      mouseRef.current.targetY = -ny * 10

      if (!isTicking) {
        isTicking = true
        animId = requestAnimationFrame(updateParallax)
      }
    }

    window.addEventListener('mousemove', handleMouseMove, { passive: true })

    return () => {
      window.removeEventListener('mousemove', handleMouseMove)
      if (animId) cancelAnimationFrame(animId)
    }
  }, [reducedMotion])

  // 3. Falling Petals Simulation (Zero canvas filter blur for silky 60fps)
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d', { alpha: true })
    if (!ctx) return

    let animId: number
    let isTabVisible = !document.hidden

    const handleVisibility = () => {
      isTabVisible = !document.hidden
    }
    document.addEventListener('visibilitychange', handleVisibility)

    let width = window.innerWidth
    let height = window.innerHeight

    const resize = () => {
      width = window.innerWidth
      height = window.innerHeight
      canvas.width = width
      canvas.height = height
    }
    resize()
    window.addEventListener('resize', resize, { passive: true })

    // 18 lightweight petals
    const PETAL_COUNT = 18
    const petals: Petal[] = Array.from({ length: PETAL_COUNT }, () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      size: 7 + Math.random() * 8, // 7px - 15px
      speedY: 0.5 + Math.random() * 0.6,
      swaySpeed: 0.012 + Math.random() * 0.015,
      swayAmp: 14 + Math.random() * 18,
      swayPhase: Math.random() * Math.PI * 2,
      angle: Math.random() * 360,
      rotSpeed: (Math.random() - 0.5) * 0.6,
      opacity: 0.25 + Math.random() * 0.35,
    }))

    // Fast organic petal drawing without expensive canvas filter blurs
    const drawPetal = (
      x: number,
      y: number,
      size: number,
      angle: number,
      opacity: number,
    ) => {
      ctx.save()
      ctx.translate(x, y)
      ctx.rotate((angle * Math.PI) / 180)

      ctx.fillStyle = isDark
        ? `rgba(255, 183, 197, ${opacity * 0.8})`
        : `rgba(255, 183, 197, ${opacity})`

      ctx.beginPath()
      ctx.moveTo(0, -size * 0.6)
      ctx.bezierCurveTo(size * 0.5, -size * 0.5, size * 0.5, size * 0.35, 0, size * 0.6)
      ctx.bezierCurveTo(-size * 0.5, size * 0.35, -size * 0.5, -size * 0.5, 0, -size * 0.6)
      ctx.closePath()
      ctx.fill()
      ctx.restore()
    }

    if (reducedMotion) {
      ctx.clearRect(0, 0, width, height)
      petals.slice(0, 6).forEach((p) => drawPetal(p.x, p.y, p.size, p.angle, p.opacity))
      return () => {
        document.removeEventListener('visibilitychange', handleVisibility)
        window.removeEventListener('resize', resize)
      }
    }

    const loop = () => {
      if (!isTabVisible) {
        animId = requestAnimationFrame(loop)
        return
      }

      ctx.clearRect(0, 0, width, height)

      for (let i = 0; i < petals.length; i++) {
        const p = petals[i]
        p.y += p.speedY
        p.swayPhase += p.swaySpeed
        p.angle += p.rotSpeed

        const currentX = p.x + Math.sin(p.swayPhase) * p.swayAmp

        drawPetal(currentX, p.y, p.size, p.angle, p.opacity)

        if (p.y > height + 20) {
          p.y = -15
          p.x = Math.random() * width
        }
      }

      animId = requestAnimationFrame(loop)
    }

    animId = requestAnimationFrame(loop)

    return () => {
      document.removeEventListener('visibilitychange', handleVisibility)
      window.removeEventListener('resize', resize)
      cancelAnimationFrame(animId)
    }
  }, [reducedMotion, isDark])

  return (
    <div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 -z-10 overflow-hidden select-none"
    >
      {/* 1. Base Paper Tint */}
      <div
        className={`absolute inset-0 transition-colors duration-500 ${
          isDark
            ? 'bg-gradient-to-b from-[#0F1420] via-[#141A29] to-[#1B2440]'
            : 'bg-[#FBF6F0]'
        }`}
      />

      {/* 2. Parallax Animated Mesh Layer using High-Performance CSS Radial Gradients */}
      <div ref={parallaxRef} className="absolute inset-0 h-full w-full will-change-transform">
        {!isDark ? (
          <>
            {/* Sakura Pink Glow */}
            <div
              className="absolute -top-[10%] -left-[5%] h-[560px] w-[560px] rounded-full animate-blob-drift-1"
              style={{
                background: 'radial-gradient(circle, rgba(255,183,197,0.38) 0%, rgba(255,183,197,0) 70%)',
              }}
            />
            {/* Soft Peach Dawn Glow */}
            <div
              className="absolute top-[20%] -right-[8%] h-[600px] w-[600px] rounded-full animate-blob-drift-2"
              style={{
                background: 'radial-gradient(circle, rgba(255,217,192,0.38) 0%, rgba(255,217,192,0) 70%)',
              }}
            />
            {/* Lavender Glow */}
            <div
              className="absolute top-[48%] left-[25%] h-[520px] w-[520px] rounded-full animate-blob-drift-3"
              style={{
                background: 'radial-gradient(circle, rgba(217,212,242,0.35) 0%, rgba(217,212,242,0) 70%)',
              }}
            />
            {/* Matcha Glow */}
            <div
              className="absolute -bottom-[12%] -left-[6%] h-[580px] w-[580px] rounded-full animate-blob-drift-4"
              style={{
                background: 'radial-gradient(circle, rgba(221,235,196,0.35) 0%, rgba(221,235,196,0) 70%)',
              }}
            />
            {/* Light Teal Glow */}
            <div
              className="absolute -bottom-[10%] right-[12%] h-[540px] w-[540px] rounded-full animate-blob-drift-5"
              style={{
                background: 'radial-gradient(circle, rgba(191,232,232,0.38) 0%, rgba(191,232,232,0) 70%)',
              }}
            />
          </>
        ) : (
          <>
            <div
              className="absolute top-[10%] right-[15%] h-[400px] w-[400px] rounded-full animate-blob-drift-1"
              style={{
                background: 'radial-gradient(circle, rgba(243,232,208,0.15) 0%, transparent 70%)',
              }}
            />
            <div
              className="absolute bottom-[20%] left-[10%] h-[500px] w-[500px] rounded-full animate-blob-drift-2"
              style={{
                background: 'radial-gradient(circle, rgba(227,66,52,0.16) 0%, transparent 70%)',
              }}
            />
          </>
        )}

        {/* 3. Rising Sun / Moon Circle (Top-Right, 8% Opacity) */}
        <div className="absolute top-10 right-16 md:right-28">
          <div
            className={`h-36 w-36 rounded-full transition-all duration-500 ${
              isDark
                ? 'bg-[#F4ECE4]/10 shadow-[0_0_60px_rgba(244,236,228,0.15)]'
                : 'bg-[#E34234]/[0.08]'
            }`}
          />
        </div>

        {/* 4. Subtle Wave & Line Motifs */}
        <svg
          className="absolute top-6 left-6 h-56 w-56 opacity-[0.035] text-[#1c1917]"
          viewBox="0 0 100 100"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.2"
        >
          <path d="M 0 50 A 25 25 0 0 1 50 50 A 25 25 0 0 1 100 50" />
          <path d="M 5 50 A 20 20 0 0 1 45 50" />
          <path d="M 10 50 A 15 15 0 0 1 40 50" />
          <path d="M 15 50 A 10 10 0 0 1 35 50" />
          <path d="M 55 50 A 20 20 0 0 1 95 50" />
          <path d="M 60 50 A 15 15 0 0 1 90 50" />
          <path d="M 25 25 A 25 25 0 0 1 75 25" />
          <path d="M 30 25 A 20 20 0 0 1 70 25" />
        </svg>

        <svg
          className="absolute bottom-16 right-8 h-64 w-64 opacity-[0.035] text-[#1c1917]"
          viewBox="0 0 120 120"
          fill="none"
          stroke="currentColor"
          strokeWidth="1"
        >
          <polygon points="60,10 110,96 10,96" />
          <line x1="60" y1="10" x2="60" y2="67" />
          <line x1="10" y1="96" x2="60" y2="67" />
          <line x1="110" y1="96" x2="60" y2="67" />
          <line x1="60" y1="10" x2="60" y2="96" />
        </svg>

        {/* 5. Minimal Mountain Silhouettes */}
        <div className="absolute -bottom-2 left-0 right-0 h-44 w-full overflow-hidden opacity-[0.07]">
          <svg
            className="h-full w-full"
            preserveAspectRatio="none"
            viewBox="0 0 1440 280"
            fill="none"
          >
            <path
              d="M 580 280 L 720 80 L 760 80 L 900 280 Z"
              fill={isDark ? '#4A5568' : '#2D3748'}
            />
            <path
              d="M 0 240 Q 220 170 480 210 T 960 190 T 1440 230 L 1440 280 L 0 280 Z"
              fill={isDark ? '#2D3748' : '#4A5568'}
            />
            <path
              d="M 0 260 Q 320 200 680 240 T 1200 220 T 1440 250 L 1440 280 L 0 280 Z"
              fill={isDark ? '#1A202C' : '#1A202C'}
            />
          </svg>
        </div>
      </div>

      {/* 6. Hardware-Accelerated Lightweight Petals Canvas */}
      <canvas ref={canvasRef} className="absolute inset-0 h-full w-full" />
    </div>
  )
}
