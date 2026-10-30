import type { Metadata, Viewport } from 'next'
import { Montserrat, Press_Start_2P } from 'next/font/google'
import { SmoothScroll } from '@/components/theme/smooth-scroll'
import './globals.css'
import 'lenis/dist/lenis.css'

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
  weight: ['300', '400', '500', '600', '700', '800'],
})

const pressStart = Press_Start_2P({
  subsets: ['latin'],
  weight: '400',
  variable: '--font-pixel',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'DevPilot — Autonomous AI Engineering Organization',
  description:
    'Modern autonomous AI organization that plans, builds, tests, and reviews changes to your software & supply systems.',
  icons: {
    icon: '/images/devpilot-logo-cropped.png',
    apple: '/images/devpilot-logo-cropped.png',
  },
}

export const viewport: Viewport = {
  colorScheme: 'light',
  themeColor: '#fbf6f0',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${montserrat.variable} ${pressStart.variable}`}>
      <body className="antialiased font-sans text-foreground selection:bg-rose-200 selection:text-rose-900">
        <SmoothScroll />
        {children}
      </body>
    </html>
  )
}
