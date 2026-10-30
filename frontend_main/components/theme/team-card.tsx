'use client'

import React, { useState } from 'react'
import {
  getMemberTheme,
  getDepartmentConfig,
  type JapaneseColorTheme,
} from '@/lib/japan-theme-config'
import { AgentSprite } from '@/components/pixel/agent-sprite'
import { ArrowRight } from 'lucide-react'

export interface TeamCardProps {
  name: string
  title: string
  department: string
  status: 'working' | 'standby' | 'done' | 'idle' | string
  avatar?: React.ReactNode | number
  color?: JapaneseColorTheme
  index?: number
  onClick?: () => void
  onOpenDetails?: () => void
  className?: string
}

/**
 * Line-art archetype icons (16px) for the avatar corner
 */
function ArchetypeCornerIcon({
  archetype,
  accent,
}: {
  archetype: string
  accent: string
}) {
  if (archetype === 'samurai') {
    return (
      <svg
        className="h-3.5 w-3.5"
        viewBox="0 0 24 24"
        fill="none"
        stroke={accent}
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M14.5 4L20 9.5" />
        <path d="M4 20l7.5-7.5" />
        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L7 20l-4 1 1-4L18.5 2.5z" />
      </svg>
    )
  }

  if (archetype === 'ninja') {
    return (
      <svg
        className="h-3.5 w-3.5"
        viewBox="0 0 24 24"
        fill="none"
        stroke={accent}
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <polygon points="12,2 14.5,9.5 22,12 14.5,14.5 12,22 9.5,14.5 2,12 9.5,9.5" />
        <circle cx="12" cy="12" r="2" />
      </svg>
    )
  }

  return (
    <svg
      className="h-3.5 w-3.5"
      viewBox="0 0 24 24"
      fill="none"
      stroke={accent}
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  )
}

export function TeamCard({
  name,
  title,
  department,
  status,
  avatar,
  color,
  index = 0,
  onClick,
  onOpenDetails,
  className = '',
}: TeamCardProps) {
  const [showTooltip, setShowTooltip] = useState(false)

  const theme = color ?? getMemberTheme(name, index)
  const deptConfig = getDepartmentConfig(department)

  const handleClick = (e: React.MouseEvent) => {
    if (onOpenDetails) {
      onOpenDetails()
    } else if (onClick) {
      onClick()
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      handleClick(e as unknown as React.MouseEvent)
    }
  }

  const isWorking = status.toLowerCase() === 'working'

  return (
    <div
      tabIndex={0}
      role="button"
      aria-label={`${name}, ${deptConfig.english}, ${title}, status ${status}`}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      className={`group relative flex flex-col justify-between rounded-2xl border border-white/80 p-4 sm:p-5 text-left cursor-pointer outline-none shadow-xs transition-all duration-200 hover:-translate-y-1 hover:shadow-md shrink-0 w-full overflow-hidden select-none focus-visible:ring-2 focus-visible:ring-offset-2 ${className}`}
      style={{
        backgroundColor: 'rgba(255, 255, 255, 0.72)',
      }}
    >
      {/* 1. Tinted Gradient Base Layer */}
      <div
        className="pointer-events-none absolute inset-0 -z-20 transition-opacity duration-300 group-hover:opacity-80"
        style={{
          background: `linear-gradient(135deg, ${theme.from} 0%, ${theme.to} 100%)`,
          opacity: 0.5,
        }}
      />

      {/* 2. Top Header Row: Plain Department Label & Status Dot */}
      <div className="flex items-center justify-between pb-2">
        {/* Department Label: e.g. "EXECUTIVE", "INTELLIGENCE" */}
        <span
          className="text-[11px] font-bold tracking-wider uppercase truncate max-w-[65%]"
          style={{ color: theme.accent }}
        >
          {deptConfig.english}
        </span>

        {/* Status: 7px dot + Plain English text */}
        <div className="flex items-center gap-1.5 shrink-0">
          <span
            className={`h-2 w-2 rounded-full ${
              isWorking ? 'animate-status-dot' : ''
            }`}
            style={{
              backgroundColor: isWorking ? theme.accent : '#94a3b8',
              boxShadow: isWorking ? `0 0 6px ${theme.accent}88` : 'none',
            }}
          />
          <span className="text-[11px] font-medium capitalize text-[#2B2B2B]/75">
            {status}
          </span>
        </div>
      </div>

      {/* 3. Middle Content: Avatar + Name + Title */}
      <div className="flex items-center gap-3.5 my-2.5">
        {/* Rounded-Square Avatar Container with Badge Icon */}
        <div className="relative shrink-0">
          <div
            className="flex h-12 w-12 sm:h-13 sm:w-13 items-center justify-center overflow-hidden rounded-2xl bg-white/90 border border-white/80 shadow-xs transition-transform duration-200 group-hover:scale-105"
          >
            <div className="pixelated flex items-center justify-center">
              {typeof avatar === 'number' ? (
                <AgentSprite charIdx={avatar} scale={1.8} />
              ) : avatar ? (
                avatar
              ) : (
                <span className="text-base font-bold text-[#1D1D1F]">
                  {name.charAt(0)}
                </span>
              )}
            </div>

            {/* Corner Role Icon */}
            <div
              className="absolute -bottom-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-white shadow-xs"
              title={deptConfig.english}
            >
              <ArchetypeCornerIcon
                archetype={deptConfig.archetype}
                accent={theme.accent}
              />
            </div>
          </div>
        </div>

        {/* Member Name & Job Title */}
        <div className="min-w-0 flex-1 overflow-hidden">
          <h3 className="text-sm sm:text-base font-bold text-[#1D1D1F] leading-tight truncate">
            {name}
          </h3>

          <div
            className="relative mt-0.5"
            onMouseEnter={() => setShowTooltip(true)}
            onMouseLeave={() => setShowTooltip(false)}
          >
            <p className="line-clamp-2 text-xs font-normal leading-relaxed text-[#57534e]">
              {title}
            </p>

            {/* Tooltip on hover */}
            {showTooltip && (
              <div className="pointer-events-none absolute left-0 bottom-full z-50 mb-1 max-w-xs rounded-lg bg-[#1D1D1F] px-2.5 py-1 text-[11px] font-normal leading-normal text-rose-50 shadow-lg">
                {title}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* 4. Footer: Department Category & "View Details" Link */}
      <div className="flex items-center justify-between border-t border-white/60 pt-2.5 mt-1">
        <span className="text-[10px] font-semibold tracking-wide uppercase text-[#2B2B2B]/50 truncate max-w-[50%]">
          {deptConfig.english} SPECIALIST
        </span>

        <button
          type="button"
          tabIndex={-1}
          onClick={(e) => {
            e.stopPropagation()
            handleClick(e)
          }}
          className="inline-flex items-center gap-1 text-xs font-semibold outline-none transition-colors"
          style={{ color: theme.accent }}
        >
          <span>View Details</span>
          <ArrowRight className="h-3 w-3 transition-transform duration-200 group-hover:translate-x-1" />
        </button>
      </div>
    </div>
  )
}
