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
- `DATA-MODEL-PART-2.md` — extends it for logging, projects, climbs and media (design spec, not implemented)
- `CLAUDE.md` — instructions for working on this repo with Claude Code

## The five tabs — current state

### Programs
Up to 5 concurrent program slots, switchable from a sheet that lists all 5 (name truncated to 20 chars; empty slots show "Import"/"Build" — Build is disabled, not built yet). Three slots are in use, and each is a different structural shape — that variety is the useful part, because it is what a generic program builder will eventually have to express:

**Slot 1 — 8-Week Finger Strength Block.** The one fully fleshed-out program: a hardcoded 24-session array (`SESSIONS`) grouped into 4 phases (`PHASES`), each session specifying block-pull or max-hang work with loads calculated as a percentage of the user's own tested max (`S.tests`, per-tool, append-only, never overwritten). Visualized as a mountain photo with 5 vertical topo-style route lines drawn up the rock face — one lane per program slot. The lane holding this program draws real progress (green start marker, purple end marker, diamond anchors at phase starts, red/faded/hollow node states); the other 4 lanes are gray 20-point placeholders. Tapping a node opens a day panel; logging out of order is blocked. Has its own set/rest interval timer with prep countdown, auto-advance, audio + vibration cues, and Wake Lock.

*Scheduling is a sequence, not a calendar.* Future dates continue from the last session actually logged — the next Mon/Wed/Fri after it — so doing one late pushes the whole remainder back. It never compresses to catch up and never drops content. This was originally anchored on the program start date instead, which meant abandoned grid dates stayed "free" and got handed out first: after doing a Friday session on the following Wednesday, the app scheduled the *next* session for that same Friday, five days before one already completed. Past dates are untouched by the change either way — each comes from its own log entry's stored `date`.

Because future dates now derive from completions, the log form carries an editable **Date trained** field defaulting to today. Sessions used to be recorded under the date they were *planned* for rather than the date they were done, which made deriving anything from them unreliable. Logging onto a date that already has a session asks first, since it would replace it.

*Undo.* A logged session can be deleted from its own day panel, rolling the program back: the session becomes un-done, the sequence returns to that point, and everything derived recalculates. Test results are the part that matters here — a test session writes separate records into `S.tests` that drive `S.maxes` and every prescription below it, and they carry no link back to the session that produced them (DATA-MODEL.md specifies `session_log_id` on Test result; never implemented), so they are matched on program + date. The confirmation names exactly what is going, test results included, because this destroys append-only data. Set-ticks and any stale unit-conversion snapshot go too, and maxes are re-derived. Only the most recently logged session offers undo: sessions are assigned to positions in date order, so removing one from the middle would silently renumber every session after it — rewriting history rather than rolling it back. Settings' "Undo last entry" routes through the same function, so there is one correct undo rather than two that behave differently.

**Slot 2 — Jump Rope, 30 min.** Added later, structurally different: not a multi-week program, so it has no `SESSIONS`/`PHASES` array and no start/end date — same workout every time, start it whenever. Renders as a workout card (not a topo route) with a "Start workout" button, an expandable interval breakdown, and a history list. The workout is 4 sets of a 12-step interval pattern — six 60s work intervals (regular jump, left/right foot, double jump, sway feet, regular jump, left/right foot) each followed by a 10s break, so a set is exactly 7:00 and four sets are 28:00 — followed by a free-form phase that counts up until the session reaches 30:00. The closing break on each set is what puts a gap between consecutive sets; an earlier version omitted it and ran sets straight into each other. Its interval timer is independent of the finger-block timer: elapsed time is computed from `Date.now()` against a stored start timestamp every tick (not accumulated `setInterval` ticks, so it can't drift over 30 minutes or stall when backgrounded), breaks display in red vs. the normal gold accent for work intervals, it beeps at 3/2/1 seconds remaining on breaks using Web Audio oscillator tones (unlocked on the Start button's own tap, since iOS Safari blocks audio until a user gesture), and it holds a Wake Lock while running. On completion (or early stop) it logs date, duration, sets completed, finished-vs-early, RPE, and notes.

**Slot 3 — Climbing Flexibility.** The third shape: unlike the finger block it never ends, and unlike Jump Rope it has both a weekday schedule and a progression. Two sessions alternate by weekday — lower body on Tuesday and Thursday, upper body on Sunday — each six exercises mixing timed holds with rep-based work, and per-side exercises tracked left and right separately. Which session you get is decided by the weekday rather than by sequence position, so there is nothing to log out of order and no locked future session.

Progression is an 8-week table that then repeats: weeks 1–2 base, weeks 3–5 add 15s to every timed hold, weeks 6–8 return to base durations but add a third set to the first two exercises. That is `manual` from DATA-MODEL.md — an enumerated table — plus a modulo so week 9 is week 1 again. DATA-MODEL.md explicitly forbids building a periodization engine for this, and none was built. The card shows the *computed* duration for the current week rather than a hardcoded figure, so it stays honest if the prescription changes: lower body runs about 15 min in weeks 1–2 and about 18 in weeks 3–8, upper body about 12–14.

The session carries a standing note that it is general training guidance rather than physiotherapy advice, and that pain or joint instability means stopping and getting assessed.

**Known gap:** the topo mountain visualization is built around a fixed session count and doesn't represent open-ended programs like Jump Rope or Flexibility — it only ever lights up the finger-block lane. Their progress is visible only in their own cards, not on the mountain.

Slots 4–5 are empty. "Import a program file" exists as a button; there's no in-app program builder yet.

### Logs
Free-form logging, separate from the structured programs. Three default activities ship out of the box — Bouldering, Strength training, Endurance — each with its own set of typed fields (number, duration, rating 1–10, pick-from-list, climbing grade, yes/no, short text). Bouldering entries default to a session summary (where, duration, problems tried, hardest grade, how it felt, skin) with optional per-problem detail (grade, attempts, sent). Climbing grades use V-scale and Font scales, kept strictly separate — never auto-converted. Every entry defaults to today's date but can be logged for any date, and multiple entries per activity per day are allowed. Whether Logs feeds the same Data charts as program data is still undecided (see DATA-MODEL.md open questions).

### Test
A standalone benchmarking section, added after the four original tabs. Flow is: pick a grip category, set the parameters, optionally run a hold timer, save the result, then decide separately whether to apply it to a program.

Ten grip categories ship — half crimp, full crimp, open hand (4-finger), three-finger drag, front two, back two, middle two, mono, pinch, sloper. Each declares which parameters apply rather than having its own screen: `TEST_FIELDS` is a flat registry of field definitions and each category in `TEST_GRIPS` names the fields it uses, so adding a category later is one line of data and no new UI code. The renderer understands only a field's `kind` (choice / number / date / text) — it has no knowledge of what a sloper or a mono is. Edge grips vary by depth (6–35 mm from a list, plus custom entry), pinch by width in mm, sloper by angle in degrees. Mono shows an injury-risk warning, which is likewise plain data on the category (`warn`), not a special case in code.

Every test also records hands (one or two, and which hand if one), added weight, hold duration, protocol type, bodyweight at the time, date and notes. The two protocol types swap which field you type and which the test produces: "max weight for a set duration" takes the duration and yields a weight; "max duration at a set weight" is the reverse. That's encoded as `given`/`result` in `TEST_PROTOCOLS`, so the form relabels itself rather than branching.

The optional hold timer follows the jump-rope clock's construction — elapsed time recomputed from a stored timestamp against `Date.now()` on every tick, never accumulated, so it can't drift or stall when backgrounded. It counts down for a fixed hold and up for a max-duration test, writing the achieved time straight back into the form.

**Applying a test to a program is a deliberate, separate step.** A result may only drive a prescription when grip, edge or width, hands, protocol and hold duration all match what that prescription expects; `REF_REQUIRES` states those requirements for each existing reference. Otherwise the apply button is disabled with the specific reason ("needs 10mm, this test was 20mm"). When enabled, it previews every future prescription that would change and from what to what, then asks for confirmation. Applying never touches sessions already logged. Tests that map onto a program reference are stored `applied:false` until applied on purpose, so saving a benchmark never moves training loads by surprise.

### Data
Built out, not a stub: 4 charts (strength-to-bodyweight over time, left/right asymmetry, session RPE over time, actual load vs. prescribed), a full test-result log, program session history, and a per-activity log view for everything logged in the Logs tab.

**Past prescriptions are now frozen.** The adherence chart used to recompute what each past session had prescribed from whatever the current maxes were, which meant saving a new test retroactively rewrote what the training record said you were meant to lift. Logging a session now stores the prescribed load alongside the load actually used, and the chart reads that stored value. Entries logged before this existed have no stored value and still fall back to recomputation; the chart says so in its caption. They are deliberately not backfilled — writing a computed guess into the record would present it as fact.

### Settings
Also built out: program start date, unit switching (lb/kg, converts everything already logged), plate increment and hardware tare, bodyweight, timer preferences (get-set countdown, sound/vibration toggle, keep-screen-awake toggle), manual test entry for results logged outside a session, and a full backup section — export/restore a JSON backup, export CSV (four tables: tests, sessions, logs, climbs), undo the last log entry, and reset everything.

## Data model

`DATA-MODEL.md` specifies a generic entity model — Metric, Exercise, Program, Phase, Session template, Prescription, Progression rule, Program run, Session log, Set log, Test result, Context log — designed so *any* structured training program can be expressed without hardcoding a training style. It's marked "design spec, not yet implemented."

The actual code doesn't yet build programs from that generic model: the finger-block program is hand-written directly as the `SESSIONS`/`PHASES` arrays, and Jump Rope is hand-written directly as its own interval/timer constants. Both write to a shared, append-only `S.log` array (tagged by `program` id) and follow the model's spirit — prescribed vs. actual stay separate, tests are append-only, nothing overwrites — but neither goes through a `Prescription`/`Progression rule` engine. Building the generic engine (and the wizard described in DATA-MODEL.md) is what "in-app builder — coming soon" refers to.

Test results are the part closest to the spec: they live in an append-only `S.tests` array, nothing overwrites, and each record carries the bodyweight and protocol that produced it so a number stays comparable months later. The Test tab's richer fields (grip, parameter, hands, protocol type, hold) were added alongside the fields older records already carried, not in place of them, so no stored data changed shape and no migration was needed.

All three interval clocks — jump rope, the Test tab's hold timer, and flexibility — now run on one shared timeline core (`seqState` / `seqElapsedMs` / `seqAt` / `seqTogglePause` / `seqSkip`). Elapsed time is always recomputed from a stored start timestamp against `Date.now()` rather than accumulated from ticks, so no clock can drift or stall when backgrounded. Each timer keeps its own paint layer, since the overlays differ.

Rep-based exercises were the one thing that did not fit a timeline built from fixed durations. They are given a nominal duration so the sequence maths still works, but they count *up* and end on a Done tap, which feeds the same `seqSkip` the skip button uses. If the nominal time runs out first the clock rewinds to the end of that set and holds there rather than cutting you off mid-set — implemented as a scan across the sequence, not a check on the current segment, because a screen lock can jump the clock by minutes and would otherwise skip straight past a narrow window.

One correction worth recording: the 10mm calibration session's block read `hold:8` while its own cue said "ramp to a 7s max" and every test actually recorded stored `"7s half crimp"`. The block was the odd one out and has been corrected to 7s, so definition, cue and stored data now agree. The 8-second holds elsewhere in the program are working sets and are unaffected.

## Deployment

Public GitHub repo `foodwise-hub/finger-block`, `main` branch, GitHub Pages serving from the root — no CI, no build step. `deploy.sh` bumps the `sw.js` cache version, commits, and pushes; every manual edit to `index.html` needs that same cache bump or the service worker keeps serving the stale cached copy.
