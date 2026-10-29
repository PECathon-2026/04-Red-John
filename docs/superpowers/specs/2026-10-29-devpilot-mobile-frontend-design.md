# DevPilot / MYCEL Mobile Frontend Design Document

> **Date:** 2026-10-29  
> **Status:** Approved for Implementation Planning  
> **Target:** Flutter (Android & iOS) in `DevPilot/`  
> **Design References:** User Images 1 & 2 + Data Model from `frontend/` (`MYCEL` agent dossier & telemetry)

---

## 1. Intent and The Why

The goal of this application is to serve as the **mobile command-and-control companion** for an engineer running long AI pipelines, builds, and automated agents on their laptop or remote server. 

When the operator steps away from their desk, they need immediate situational awareness:
1. **At a Glance (Home Screen):** See active projects, live hardware vitals (CPU/RAM/battery/network), the current running task with an elapsed `T+MM:SS` timer, and what each AI agent is actively doing.
2. **Deep Inspection & Control (Detail Screen):** Inspect live color-coded terminal logs, review pipeline goal steps, view generated artifact previews (screenshots, APKs), type ad-hoc terminal commands, and approve/deny human-in-the-loop security gates.

---

## 2. Visual Design System

The visual design faithfully translates the modern warm-minimalist aesthetic from **Image 1** and **Image 2** into a responsive Flutter design system:

### 2.1 Palette & Surfaces
- **Canvas Base (`bgMain`):** Warm off-white / light cream (`#FAF8F5`).
- **Warm Detail Base (`bgWarm`):** Soft cream beige (`#F6ECD9`) used for detail headers and card accents.
- **Card Pastel 1 (`cardPeach`):** Warm tan/peach (`#FCEAD2`) for primary project card.
- **Card Pastel 2 (`cardMint`):** Soft light sage/mint (`#D8EFE9`) for secondary project card.
- **Card Pastel 3 (`cardLavender`):** Soft lavender (`#E8E0F2`) for auxiliary workflows.
- **Deep Contrast (`darkPill`):** Deep charcoal/black (`#161618`) with white text for schedule and high-contrast status pills.
- **Surface White (`surfaceCard`):** Pure white (`#FFFFFF`) with soft rounded borders for the detail sheet and goal cards.
- **Accent Orange (`accentOrange`):** `#E07A4C` for active progress and running indicators.
- **Success Green (`statusGreen`):** `#34C759` / `#B9D8AC` for completed steps and healthy telemetry.
- **Warning Amber (`statusAmber`):** `#FFB300` / `#EEC98F` for approval gates and warnings.
- **Error Red (`statusRed`):** `#FF3B30` for error terminal logs and emergency alerts.

### 2.2 Typography & Form
- Large, bold headlines (`fontFamily: 'Inter'` or system sans-serif with font weights 700/800).
- Curvy rounded corners (`BorderRadius.circular(24)` to `32`).
- Soft elevation and subtle border outlines (`Color(0x14000000)`).
- Distinctive circular action buttons with directional arrows (`↗`).

---

## 3. Screen Architecture & Feature Breakdown

### 3.1 Screen 1: Home Screen (Image 1 Aesthetic + Current Task)

1. **Header:** 
   - Grid icon `::`, user avatar, greeting *"Hello, Aryan"*, and bold title *"Your Projects (3)"*.
2. **Side-by-Side Workflow Cards (Image 1):**
   - **Card 1 (Warm Peach):** *Admin Dashboard / DevPilot Core*, active agent avatar chips, elapsed runtime *45 hours*, visual progress pill, and top-right arrow button `↗`.
   - **Card 2 (Soft Mint):** *Wallet Mobile / Pipeline*, active agent avatars, *9 hours*.
   - Tap any card to navigate to the **Detail Screen**.
3. **Current Running Task Card (Directly Below Cards):**
   - Status badge: Pulsing green/amber chip (`Compiling APK`, `Working`, `Idle`).
   - Live elapsed timer: `T+MM:SS` (updates every second via local timer).
   - Security badge: `LAN E2EE` with green lock icon.
   - Hardware Vitals Bar: Mini gauges for **CPU**, **RAM**, **Network I/O**, and **Battery %**.
   - Quick Macro Deck: 4 tactile buttons (*Run Tests*, *Deploy App*, *Restart Docker*, *Kill Processes*). Tapping *Kill Processes* dispatches the AMBER approval modal.
4. **Active Agent Cards (Inspired by MYCEL `hire-cards.tsx`):**
   - Renders what each AI agent is actively doing right now (e.g. *Atlas: Analyzing AST call-graph*, *Dev: Compiling Shaders*, *Nisha: Running E2E Suite*).
   - Shows agent team, security clearance (`GREEN` / `AMBER`), current phase, and elapsed time.
   - Tapping an agent card opens their full **Agent Dossier Modal**.
5. **Bottom Navigation Bar:**
   - Tabs: `Projects` (active), `Terminal` (opens CLI drawer), `Agents` (scrolls to roster), and `Settings` (opens Parameter & Connection sheet).

---

### 3.2 Screen 2: Detail & Pipeline Screen (Image 2 Aesthetic + Telemetry)

1. **Header & Date Banner:**
   - Soft beige background `#F6ECD9`, `< Back` navigation, `Done` button.
   - Title: *"Planning & Pipeline"* with subtitle date.
2. **Quick Session Pills (Image 2):**
   - Dark rounded card: `21 October, 10 AM` (execution window/session ID).
   - Side card: `devpilot.lan` with tactile `[ (🔗) Share Link ]` pill that copies host endpoint.
3. **Members & Agents Row:**
   - Stacked agent avatars + `Send telemetry reminder >` action capsule + `+` invite/dispatch button.
4. **White Rounded Goals & Pipeline Sheet:**
   - Ordered goal list: Step numbers in circular badges `(1)`, `(2)`, `(3)`, task category, bold title, and status pill.
   - **Live Terminal Feed Widget:** Dark monospace console displaying streaming color-coded logs (Green = success, Yellow = warning, Red = error). Auto-scrolls with pause-on-touch.
   - **Artifact Stream Carousel:** Interactive preview cards for files generated by the laptop (APK download pill, screenshot thumbnails, test reports).
   - **Slide-up CLI Action Button:** Bottom floating action bar allowing the operator to type ad-hoc terminal commands directly.

---

### 3.3 Interactive Modals & Security Gates

1. **Human-in-the-Loop Approval Modal (AMBER Gate):**
   - Pauses execution and pops up with haptic vibration when a high-risk command is triggered (e.g., `DROP DATABASE`, `FORCE KILL PRODUCTION`, `SPEND API CREDITS`).
   - Includes biometric Face ID / Fingerprint simulation & slide-to-confirm (`Approve` / `Deny`).
2. **Slide-Up Raw CLI Sheet:**
   - Monospace text input field with quick suggestions (`flutter doctor`, `docker ps`, `git status`). Submitted commands append to the Live Terminal Feed in real time.
3. **Parameter Sliders & Toggles Modal:**
   - Sliders for scraping threads / workers (1 to 16) and toggles for `--verbose` and `--no-cache`.
4. **Agent Dossier Modal (MYCEL format):**
   - Displays agent bio, assigned tools, clearance level, and live subtask checklist.

---

## 4. State Management & Real-time Simulation Engine

The frontend includes a self-contained **Telemetry & Simulation Provider**:
- **Live Timer Service:** Streams a monotonic `T+MM:SS` timer that ticks smoothly every second.
- **Hardware Vitals Stream:** Simulates natural laptop hardware telemetry (CPU fluctuation between 25-70%, RAM, network speed, battery drain/charge).
- **Terminal Log Streamer:** Pumps realistic logs (compilation steps, test results, warnings, and success messages) with real ANSI/colored text support.
- **Biometric Hook:** Face ID / Fingerprint simulation for destructive actions.
- **Extensible Architecture:** Ready to connect to real WebSockets (`ws://<laptop-ip>:8000/telemetry`) with zero UI refactoring.

---

## 5. Builder Calls & Settled Decisions

1. **Navigation Structure:** Hierarchical 2-screen architecture (`HomeScreen` → `DetailScreen`) with bottom navigation triggers (`Terminal` opens CLI drawer, `Settings` opens Parameter modal).
2. **Telemetry Service:** Implemented as a bidirectional reactive change notifier with local realistic streaming and pluggable WebSocket client.
3. **Biometrics:** Polished in-app biometric simulation (haptic feedback + Face ID icon + slide-to-approve) ensuring seamless execution on emulators and physical devices alike.
4. **Interactive Coupling:** Tapping `[Kill All]` opens the AMBER approval modal; submitting ad-hoc commands in the CLI sheet immediately appends colored log lines to the Live Terminal Feed.
