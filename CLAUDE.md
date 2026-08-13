# CLAUDE.md — Finger Block

## Who's asking
Andreas has no coding background. Always give exact file names, exact line numbers, and the exact text to find before describing a change. When adding new lines, match the indentation of the line above unless told otherwise. Explain technical terms briefly if they're worth knowing; skip lengthy explanations otherwise.

## What this is
A training-program tracker and activity logger for climbers, built as a static PWA (no build step, no framework, no bundler). Lives at the repo root as plain HTML/CSS/JS. Currently a free, personal tool — no payment, no accounts, no backend. Deployed on GitHub Pages at foodwise-hub.github.io/finger-block.

The app is structured around four tabs:
- **Programs** — up to 5 concurrent training programs, each with its own start and end dates. Programs arrive as importable files for now, with an in-app builder planned later. A program switcher lets Andreas jump between the 5 slots (name truncated to 20 chars; only in-use slots are selectable). Finished programs archive collapsed, with expand-to-review.
- **Logs** — free-form logging for any user-defined climbing or training activity, separate from the structured programs. Each entry uses a preset field list plus user-created custom fields plus a free notes box, defaults to today's date, and allows multiple entries per activity per day. Bouldering logs default to a session summary with optional per-problem detail; V-scale and Font grades are both supported and kept separate, never auto-converted. Whether Logs feeds the same charts as program data is still undecided.
- **Data** — in-app charts and analysis (not yet built out).
- **Settings** — app-level settings (not yet specified beyond the tab existing).

## Files
- `index.html` — the entire app (structure, styles, logic)
- `manifest.json` — PWA manifest (name, icons, display mode)
- `sw.js` — service worker; caches the app for offline use
- `icon-*.png` — app icons at various sizes
- `deploy.sh` — deploy script (auto-increments the sw.js cache version and pushes)

## Critical rules
- Before writing or changing any program-builder, session-logging, or progression code, read `DATA-MODEL.md`. It is the schema spec — do not invent structure that contradicts it.
- Also read `DATA-MODEL-PART-2.md` for anything touching logging, projects, climbs, or media — it extends DATA-MODEL.md and is not optional context for that surface area.
- **No build step, no framework, no bundler.** Don't introduce React, npm packages, or a build process. Keep it plain HTML/CSS/JS that runs by opening the file or serving it statically.
- **Every time `index.html` changes, bump the cache name in `sw.js`** (e.g. `fingerblock-v5` → `fingerblock-v6`). Without this, the service worker keeps serving the old cached version and changes won't appear to the user. `deploy.sh` may already automate this — check before doing it manually.
- **User data lives in `localStorage`**, key `fingerblock:v1`. Never move this to a server or external DB without an explicit request — it's a deliberate local-first design choice.
- **Program definitions live in `SESSIONS`** (near the top of the script), with phase structure in `PHASES` just below it. That's the one place to touch to change a training program's content.
- Don't add analytics, tracking, or any third-party network calls without asking first.

## Design direction — "Wall Face"
The Programs tab is visualized as a mountain face, using an **uploaded real mountain photo as a fixed hero image** (Calm.com was the mood reference — calm, not gamified/loud). On top of that photo:

- **5 vertical topo-style route lines**, drawn zig-zagging up the mountain rather than straight — one lane per concurrent program slot. The active program's lane is lit up with real progress; inactive lanes are grayed out with 20 placeholder points each, filling in left to right as new programs are added.
- Each route has a **green start marker** and a **purple end marker**.
- **Diamond "anchor" glyphs** mark the first session of each phase within a program.
- **Node states along the route:** current/next session = red, completed sessions = faded, future sessions = hollow.
- Tapping any node opens a day panel for that session (defaulting to the next-upcoming one if nothing's tapped), colored green if it's next-up or red if it's a locked future session — logging out of order is blocked.
- Import/Build buttons for a program only appear on a genuinely empty, unused slot.

Andreas may be moving styling toward CSS custom properties (design tokens) in a `:root` block — check current state of the file before assuming raw hardcoded values throughout.

## Working style
- Confirm the exact change before making it, if there's any ambiguity.
- After any meaningful change, remind Andreas to update `PROJECT-NOTES.md` (lives in this repo, used for the separate Claude Projects knowledge base) if the change affects scope, features, or direction. Update it here first, then manually re-upload it to the Claude Project — it is not auto-synced.
