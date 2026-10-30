import { Suspense } from 'react'
import { ControlRoom } from '@/components/control/control-room'

export const metadata = {
  title: 'DevPilot — Mission Control Dashboard',
}

export default function ControlPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-screen w-screen items-center justify-center bg-[#f4f3fb]">
          <div className="flex flex-col items-center gap-3">
            <div className="h-8 w-8 rounded-full border-2 border-purple-500 border-t-transparent animate-spin" />
            <p className="text-xs font-medium text-muted-foreground">
              Initializing Mission Control...
            </p>
          </div>
        </div>
      }
    >
      <ControlRoom />
    </Suspense>
  )
}

