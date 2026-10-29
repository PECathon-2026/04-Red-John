import * as React from 'react'
import { Button as ButtonPrimitive } from '@base-ui/react/button'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex shrink-0 items-center justify-center font-medium transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 cursor-pointer active:scale-[0.98]',
  {
    variants: {
      variant: {
        default:
          'bg-[#191924] text-white hover:bg-[#2a293a] shadow-sm rounded-full',
        primary:
          'bg-accent text-white hover:bg-accent/90 shadow-sm rounded-full',
        pill:
          'bg-white text-foreground hover:bg-secondary/70 shadow-sm border border-black/5 rounded-full',
        pastel:
          'bg-secondary text-secondary-foreground hover:bg-secondary/80 rounded-2xl',
        outline:
          'border border-border bg-white/70 backdrop-blur hover:bg-white text-foreground rounded-2xl',
        ghost:
          'text-muted-foreground hover:text-foreground hover:bg-black/5 rounded-xl',
        destructive:
          'bg-red-50 text-red-600 hover:bg-red-100 rounded-2xl',
      },
      size: {
        default: 'h-9 px-4 py-2 text-sm',
        sm: 'h-8 px-3 text-xs',
        lg: 'h-11 px-6 text-base',
        icon: 'size-9 rounded-full',
        'icon-sm': 'size-8 rounded-full',
        'icon-lg': 'size-11 rounded-full',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  },
)

function Button({
  className,
  variant = 'default',
  size = 'default',
  ...props
}: ButtonPrimitive.Props & VariantProps<typeof buttonVariants>) {
  return (
    <ButtonPrimitive
      data-slot="button"
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }

