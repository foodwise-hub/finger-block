# PROJECT-NOTES.md — Finger Block

Reference doc for the separate Claude Projects knowledge base. Not auto-synced — update this file in the repo first, then manually re-upload it there. (See CLAUDE.md's Working style section.)

---

## What this is

A training-program tracker and activity logger for climbers. Static PWA — plain HTML/CSS/JS in one file (`index.html`), no build step, no framework, no backend. Deployed on GitHub Pages at `foodwise-hub.github.io/finger-block`. Free, personal tool; no accounts, no payment.

All user data lives in `localStorage` on the device, under the key `fingerblock:v1`. It does not sync between devices and does not transfer from any earlier Claude-artifact version. Clearing site data destroys it — the in-app Export is the only backup.

## Files

- `index.html` — the entire app (structure, styles, logic)
- `manifest.json` — PWA manifest
- `sw.js` — service worker, caches the app for offline use; cache name must be bumped every time `index.html` changes
- `icon-*.png` — app icons
- `deploy.sh` — bumps the `sw.js` cache version, commits, and pushes to main
- `DATA-MODEL.md` — schema spec for the program builder (see below — partially implemented)
- `CLAUDE.md` — instructions for working on this repo with Claude Code

## The four tabs — current state

### Programs
Up to 5 concurrent program slots, switchable from a sheet that lists all 5 (name truncated to 20 chars; empty slots show "Import"/"Build" — Build is disabled, not built yet). Two slots are in use:

**Slot 1 — 8-Week Finger Strength Block.** The one fully fleshed-out program: a hardcoded 24-session array (`SESSIONS`) grouped into 4 phases (`PHASES`), each session specifying block-pull or max-hang work with loads calculated as a percentage of the user's own tested max (`S.tests`, per-tool, append-only, never overwritten). Visualized as a mountain photo with 5 vertical topo-style route lines drawn up the rock face — one lane per program slot. The lane holding this program draws real progress (green start marker, purple end marker, diamond anchors at phase starts, red/faded/hollow node states); the other 4 lanes are gray 20-point placeholders. Tapping a node opens a day panel; logging out of order is blocked. Has its own set/rest interval timer with prep countdown, auto-advance, audio + vibration cues, and Wake Lock.

**Slot 2 — Jump Rope, 30 min.** Added later, structurally different: not a multi-week program, so it has no `SESSIONS`/`PHASES` array and no start/end date — same workout every time, start it whenever. Renders as a workout card (not a topo route) with a "Start workout" button, an expandable interval breakdown, and a history list. The workout is 4 sets of an 11-step interval pattern (regular jump, left/right foot, double jump, sway feet, more regular/left-right, with 10s breaks between), totaling 27:20, followed by a free-form phase that counts up until the session reaches 30:00. Its interval timer is independent of the finger-block timer: elapsed time is computed from `Date.now()` against a stored start timestamp every tick (not accumulated `setInterval` ticks, so it can't drift over 30 minutes or stall when backgrounded), breaks display in red vs. the normal gold accent for work intervals, it beeps at 3/2/1 seconds remaining on breaks using Web Audio oscillator tones (unlocked on the Start button's own tap, since iOS Safari blocks audio until a user gesture), and it holds a Wake Lock while running. On completion (or early stop) it logs date, duration, sets completed, finished-vs-early, RPE, and notes.

**Known gap:** the topo mountain visualization is built around a fixed session count and doesn't represent open-ended programs like Jump Rope — it only ever lights up the finger-block lane. Jump Rope's progress is only visible in its own workout card, not on the mountain.

Slots 3–5 are empty. "Import a program file" exists as a button; there's no in-app program builder yet.

### Logs
Free-form logging, separate from the structured programs. Three default activities ship out of the box — Bouldering, Strength training, Endurance — each with its own set of typed fields (number, duration, rating 1–10, pick-from-list, climbing grade, yes/no, short text). Bouldering entries default to a session summary (where, duration, problems tried, hardest grade, how it felt, skin) with optional per-problem detail (grade, attempts, sent). Climbing grades use V-scale and Font scales, kept strictly separate — never auto-converted. Every entry defaults to today's date but can be logged for any date, and multiple entries per activity per day are allowed. Whether Logs feeds the same Data charts as program data is still undecided (see DATA-MODEL.md open questions).

### Data
Built out, not a stub: 4 charts (strength-to-bodyweight over time, left/right asymmetry, session RPE over time, actual load vs. prescribed), a full test-result log, program session history, and a per-activity log view for everything logged in the Logs tab.

### Settings
Also built out: program start date, unit switching (lb/kg, converts everything already logged), plate increment and hardware tare, bodyweight, timer preferences (get-set countdown, sound/vibration toggle, keep-screen-awake toggle), manual test entry for results logged outside a session, and a full backup section — export/restore a JSON backup, export CSV (four tables: tests, sessions, logs, climbs), undo the last log entry, and reset everything.

## Data model

`DATA-MODEL.md` specifies a generic entity model — Metric, Exercise, Program, Phase, Session template, Prescription, Progression rule, Program run, Session log, Set log, Test result, Context log — designed so *any* structured training program can be expressed without hardcoding a training style. It's marked "design spec, not yet implemented."

The actual code doesn't yet build programs from that generic model: the finger-block program is hand-written directly as the `SESSIONS`/`PHASES` arrays, and Jump Rope is hand-written directly as its own interval/timer constants. Both write to a shared, append-only `S.log` array (tagged by `program` id) and follow the model's spirit — prescribed vs. actual stay separate, tests are append-only, nothing overwrites — but neither goes through a `Prescription`/`Progression rule` engine. Building the generic engine (and the wizard described in DATA-MODEL.md) is what "in-app builder — coming soon" refers to.

## Deployment

Public GitHub repo `foodwise-hub/finger-block`, `main` branch, GitHub Pages serving from the root — no CI, no build step. `deploy.sh` bumps the `sw.js` cache version, commits, and pushes; every manual edit to `index.html` needs that same cache bump or the service worker keeps serving the stale cached copy.
