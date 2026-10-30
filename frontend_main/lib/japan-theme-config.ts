/**
 * Color System & Archetypes for DevPilot Engineering Organization
 * Blends dawn palettes, washi paper tones, and Apple-grade polish.
 */

export interface JapaneseColorTheme {
  name: string
  from: string
  to: string
  accent: string
  darkFrom: string
  darkTo: string
  darkAccent: string
}

export interface DepartmentConfig {
  english: string
  archetype: 'samurai' | 'ninja' | 'artisan' | 'strategist' | 'monk' | 'architect'
  icon: 'katana' | 'shuriken' | 'torii' | 'shield' | 'fan' | 'compass'
}

/**
 * Department Configurations
 */
export const DEPARTMENTS: Record<string, DepartmentConfig> = {
  Executive: {
    english: 'EXECUTIVE',
    archetype: 'samurai',
    icon: 'katana',
  },
  Intelligence: {
    english: 'INTELLIGENCE',
    archetype: 'ninja',
    icon: 'shuriken',
  },
  Network: {
    english: 'NETWORK',
    archetype: 'artisan',
    icon: 'torii',
  },
  Resilience: {
    english: 'RESILIENCE',
    archetype: 'samurai',
    icon: 'shield',
  },
  Council: {
    english: 'COUNCIL',
    archetype: 'strategist',
    icon: 'fan',
  },
  Architecture: {
    english: 'ARCHITECTURE',
    archetype: 'architect',
    icon: 'compass',
  },
  Planning: {
    english: 'SHOGUN COUNCIL (PLANNING)',
    archetype: 'strategist',
    icon: 'compass',
  },
  Forge: {
    english: 'SAMURAI FORGE (ENGINEERING)',
    archetype: 'samurai',
    icon: 'katana',
  },
  Sentinel: {
    english: 'SENTINEL DOJO (VERIFICATION)',
    archetype: 'monk',
    icon: 'shield',
  },
  Shadow: {
    english: 'SHADOW COUNCIL (SECURITY & REVIEW)',
    archetype: 'ninja',
    icon: 'shuriken',
  },
  Support: {
    english: 'SUPPORT (SCRIBE)',
    archetype: 'artisan',
    icon: 'torii',
  },
}

/**
 * Color Harmony Palettes
 */
export const MEMBER_THEMES: Record<string, JapaneseColorTheme> = {
  // Atlas (Executive, samurai): Vermilion / maple
  Atlas: {
    name: 'Vermilion',
    from: '#FFE3DC',
    to: '#FFC9BC',
    accent: '#D6372B',
    darkFrom: '#301716',
    darkTo: '#241010',
    darkAccent: '#FF6B5E',
  },
  // Maya (Executive, samurai): Gold / amber
  Maya: {
    name: 'Gold',
    from: '#FFF0CF',
    to: '#FFE0A0',
    accent: '#B7791F',
    darkFrom: '#2E2211',
    darkTo: '#20180B',
    darkAccent: '#F6BD60',
  },
  // Mira (Intelligence, ninja): Teal / cyan
  Mira: {
    name: 'Teal',
    from: '#D8F2F0',
    to: '#B5E3E0',
    accent: '#0E7C86',
    darkFrom: '#102528',
    darkTo: '#0B1B1E',
    darkAccent: '#4ED6DF',
  },
}

/**
 * Additional Cyclical Color Themes for team members
 */
export const CYCLIC_THEMES: JapaneseColorTheme[] = [
  // Sakura Pink
  {
    name: 'Sakura Pink',
    from: '#FFD6E0',
    to: '#FFBACB',
    accent: '#D6457A',
    darkFrom: '#2E121E',
    darkTo: '#210B14',
    darkAccent: '#FF7AA8',
  },
  // Wisteria Lavender
  {
    name: 'Wisteria Lavender',
    from: '#E4E0F7',
    to: '#D0CAEF',
    accent: '#6B5BB5',
    darkFrom: '#1E1933',
    darkTo: '#141024',
    darkAccent: '#9F90E8',
  },
  // Matcha Green
  {
    name: 'Matcha Green',
    from: '#E3F0C8',
    to: '#CDE5A2',
    accent: '#5E8C2A',
    darkFrom: '#1B270F',
    darkTo: '#121C09',
    darkAccent: '#98D64A',
  },
  // Indigo
  {
    name: 'Indigo',
    from: '#D5DEEE',
    to: '#B8C8E4',
    accent: '#2D4A8A',
    darkFrom: '#111A2B',
    darkTo: '#0A111F',
    darkAccent: '#6C94E8',
  },
  // Pearl Moon
  {
    name: 'Pearl Moon',
    from: '#F4ECE4',
    to: '#E6DAD0',
    accent: '#8C6D53',
    darkFrom: '#251F1A',
    darkTo: '#1A1512',
    darkAccent: '#D4B89F',
  },
]

/**
 * Resolve theme for any team member
 */
export function getMemberTheme(name: string, index = 0): JapaneseColorTheme {
  if (MEMBER_THEMES[name]) {
    return MEMBER_THEMES[name]
  }
  let hash = 0
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash)
  }
  const cyclicIndex = Math.abs(hash + index) % CYCLIC_THEMES.length
  return CYCLIC_THEMES[cyclicIndex]
}

export function getDepartmentConfig(department: string): DepartmentConfig {
  const normalized = department.charAt(0).toUpperCase() + department.slice(1).toLowerCase()
  return (
    DEPARTMENTS[normalized] ||
    DEPARTMENTS[department] || {
      english: department.toUpperCase(),
      archetype: 'artisan',
      icon: 'torii',
    }
  )
}
