# CLAUDE.md — AMI Final Project

## Project Context

**Course:** Interactive Multimedia Applications (AMI) — ISEL 2025/2026  
**Professor:** Diogo Cabral (diogo.cabral@isel.pt)  
**Deadline:** June 7th, 2026 | Discussions: June 16–18, 2026  
**Goal:** Functional prototype of a mobile app designed in Lab Projects 1 & 2.

**Stack:** Flutter (Dart) — multiplatform, valued by the professor.

---

## App: VoiceTask — Gestor de Tarefas por Voz

A mobile task manager where voice is the primary input. User speaks a task (e.g. "Take dogs on a walk tomorrow at 5pm") and the app auto-extracts title + date/time, creating the task with one confirmation tap.

### Screens (7 total, from Lab 2 Figma prototype)

| # | Screen | Description |
|---|--------|-------------|
| 1 | **My Tasks** (×3 variants) | Main list with tabs All / Work / Personal. Each task: checkbox + title + date + color bar (blue=Work, orange=Personal). Bottom hint: "Hold to reorder · Swipe to delete · Shake for options". FAB mic button "New task". |
| 2 | **Voice Input** | Large mic button (hold to activate / drag to lock hands-free). Waveform animation + "Listening...". Real-time speech-to-text transcription. Cancel / Next. |
| 3 | **Confirm Task** | Editable fields: Title, Date & Time, List (Work/Personal toggle). Optional Location Reminder (GPS toggle, on arrival/departure, 100m radius). Cancel / Save. |
| 4 | **Task Created!** | Green checkmark animation. Shows created task summary. Undo / Home. |
| 5 | **My Lists** | List of named collections (Work, Personal). Dashed "+ New List" area. Swipe to delete. |
| 6 | **Shake Overlay** | Modal over darkened screen: "Shake Detected!" → "Delete last task" / "Re-dictate". |
| 7 | **GPS Notification** | Lock-screen notification: "Chegaste a casa!" with task title. Done / Postpone 30min. |

### Inputs

| Input | Sensor | Use |
|-------|--------|-----|
| Touch | Screen | Navigate, mark complete, drag & drop reorder, swipe delete |
| Voice | Microphone | Create/edit tasks — primary input |
| Shake | Accelerometer | Quick menu: delete last task or re-dictate |
| GPS | Location | Location-based reminders (on arrival / departure) |

### Feedback

| Type | Implementation |
|------|----------------|
| Visual | Checkmark animation, waveform, color category bars, shake overlay, Task Created screen |
| Text | Real-time transcription, contextual hints bar, GPS notification text |
| Haptic | Vibration on: task complete, task delete, shake detection |
| Audio | Confirmation sound on task created, alarm for timed tasks |

### Design System

- Primary: blue (#007AFF-style), Secondary: grey
- Category bars: blue = Work, orange = Personal
- Typography: uniform across all screens
- Buttons: primary always blue, secondary always grey, always Cancel/Save pairs
- Navigation: `< Back` top-left, no bottom nav bar

### Known Usability Issues (from Labs 1 & 2 — to address in implementation)

- Swipe-to-delete and drag-to-reorder hints were missing from task screen in Lab 1 — fixed in Lab 2 with bottom hint bar.
- Mic button purpose was unclear in Lab 1 — fixed with "New task" label.
- Work/Personal tab filters did not work in Figma prototype — must be functional in Flutter.
- Participants suggested: keyboard/manual input option on Voice screen; pulse animation on mic at first launch.
- Creating a task should allow assigning to a new list (not only existing lists).

---

### Hard Requirements (non-negotiable)

- At least **2 types of user feedback**: choose from visual, text, audio, haptic/vibration
- **Touch input** + at least **2 types of input** (can use device sensors)
- Usability tests with **5–6 participants** — record quantitative interaction logs
- Source code in an **online repository** (link in report)

### Deliverables

- Screenshots of the functional prototype
- Report justifying any changes from paper/Figma prototype
- Photos of usability tests (with participant permission)
- Descriptive statistics from interaction logs
- Repo link

---

## Behavioral Guidelines (Karpathy-derived)

### 1. Think Before Coding

Before implementing anything:
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, surface them — don't pick silently.
- If a simpler approach exists, say so.
- Name what's confusing before asking for clarification.

### 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use widgets.
- No "flexibility" that wasn't requested.
- No error handling for impossible scenarios (e.g., sensor always available on device under test).
- If a widget tree is 200 lines and could be 50, rewrite it.

Ask: "Would a senior Flutter dev say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

Touch only what you must.

- Don't "improve" adjacent widgets, comments, or formatting.
- Match existing style (even if you'd do it differently).
- If you notice unrelated dead code, mention it — don't delete it.
- Every changed line must trace directly to the current request.

### 4. Goal-Driven Execution

Transform tasks into verifiable goals:

- "Add haptic feedback" → "Trigger HapticFeedback.mediumImpact() on button press, verify on device"
- "Fix navigation bug" → "Write a widget test reproducing the issue, then fix it"
- "Add sensor input" → "Read accelerometer stream, confirm values change on tilt"

For multi-step tasks, state a brief plan with verification steps before starting.

---

## Flutter Conventions

- Use `StatefulWidget` only when local state is genuinely needed; prefer `StatelessWidget`.
- State management: keep it simple — `setState` or `Provider` unless complexity justifies more.
- Sensor access via `sensors_plus` package.
- Haptics via `HapticFeedback` (Flutter built-in) or `vibration` package.
- Audio via `audioplayers` or `just_audio`.
- Interaction logging: write timestamped events to a local list, export as CSV for stats.
- Target: Android primary, iOS secondary (multiplatform gets extra credit).

---

## What NOT to do

- Don't add screens or features not in the original prototype without justification.
- Don't over-engineer state management for a prototype.
- Don't skip the usability logging — it's a graded deliverable.
- Don't commit secrets, API keys, or large binary assets to the repo.
