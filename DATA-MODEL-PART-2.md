# DATA-MODEL — Part 2: Logging, Projects, and Media

Extends DATA-MODEL.md. Read both before writing or changing any code that touches logging, projects, climbs, photos, or annotations.

Status: design spec, not yet implemented. Written August 2026.

---

## Top-level structure

Three things sit at the top level:

- **Program** — structured training you follow (Plan layer)
- **Project** — a specific climb you're working toward (Plan layer)
- **Session log** — what actually happened (Record layer)

Program and Project are peers. Both express intent, both accumulate sessions over time. Neither contains the other.

A session log may reference a program, a project, **both**, or **neither**. One gym visit that included finger block work and twenty minutes on a board project is ONE log with two references — not two logs.

"Neither" must be fully supported: a casual session with friends is a valid log.

---

## The direction-of-flow rule

**Logs never modify a definition. Logs always feed state.**

| Never written by logs | Always derived from logs |
|---|---|
| `Program` — phases, prescriptions, rules | `Program run` — current week, computed loads, adherence |
| `Project` — name, grade, location, type | Project state — attempts, sessions, high point, status |

This preserves the existing feedback loop (test results recalculating future prescriptions; autoregulated rules reading actual sets) while guaranteeing that logging can never corrupt a plan.

**The project view is a derived view, not a data entry screen.** Nothing is typed there. Sessions, attempts, progress over time, and days-on-project are all computed from logs. The only directly-entered project data is the definition, entered once at creation.

**Projects are created inline from a log entry**, never from a separate screen. Logging a climb offers a "this is a project" toggle that links an existing project or creates one on the spot. Minimizing touchpoints is a hard requirement, not a preference.

---

## Entities

### Day

A thin container for once-per-day context, so the user is never asked the same question twice in one day.

| Field | Notes |
|---|---|
| `id`, `date` | one per calendar date |
| `readiness{}` | sleep / soreness / stress / motivation, 1–5 |
| `bodyweight` | optional, opt-in, off by default — see safety section in DATA-MODEL.md |
| `notes` | freeform |

Auto-created by the first logged interaction of the day. Every subsequent session that day attaches to the existing Day and inherits its context.

### Session log (extends the definition in DATA-MODEL.md)

Additional fields:

| Field | Notes |
|---|---|
| `day_id` | |
| `project_id` | nullable |
| `session_type` | training / boulder / rope / board / mixed / other |
| `location_id` | nullable |
| `is_outdoor` | bool — an ATTRIBUTE, not a type |
| `conditions{}` | temp, humidity, skin — optional, most relevant outdoors |

**Auto-generation:** interacting with a program or project creates the Day and the Session log without a separate step. The user can then add manual entries to that log freely.

### Climb log entry

One climb attempted or sent within a session. A session may have many.

| Field | Notes |
|---|---|
| `id`, `session_log_id` | |
| `climb_type` | `boulder` \| `rope` \| `board` |
| `name` | freeform |
| `grade`, `grade_scale` | V / Font for boulder and board; YDS / French for rope. **Never convert between scales.** |
| `attempts` | count |
| `outcome` | flash / send / repeat / project / no-send |
| `project_id` | nullable — links this attempt to a project |
| `notes` | |

**Type-specific fields:**

| Type | Extra fields |
|---|---|
| `boulder` | — |
| `rope` | `style` (onsight / flash / redpoint / toprope), `falls`, `pitches` |
| `board` | `board_type`, **`angle`**, `climb_id`, `share_url`, `setter` |

**`angle` is mandatory for board climbs.** Board grades are meaningless without it. If it is not in the model from the start, every board statistic built later is wrong.

### Project

| Field | Notes |
|---|---|
| `id`, `name` | |
| `climb_type` | boulder / rope / board |
| `grade`, `grade_scale` | |
| `location_id`, `is_outdoor` | |
| `board_type`, `angle` | board projects only |
| `status` | active / sent / shelved |
| `created_date`, `sent_date` | |
| `high_point` | free text, or a reference to a Move if a sequence exists |
| `notes` | |

**Derived, never stored:** total attempts, total sessions, days between first session and send, progress over time.

**Status auto-updates:** logging a send flips status to `sent` and sets `sent_date`. Requiring the user to do this manually would be exactly the redundant entry this design exists to avoid.

### Media

A photo or an extracted video frame. Attaches to a project or a session log.

| Field | Notes |
|---|---|
| `id` | |
| `project_id`, `session_log_id` | either or both, nullable |
| `kind` | `photo` \| `frame` |
| `sequence_id`, `frame_index` | frames only |
| `captured_date` | |
| `blob` | compressed image data (IndexedDB) |
| `width`, `height` | |
| `caption` | |

### Annotation

A pin on a media item with a note. This is the running memory of what's being learned about a climb.

| Field | Notes |
|---|---|
| `id`, `media_id` | |
| `x`, `y` | **normalized 0–1, never pixels** — must survive different screen sizes and re-encoding |
| `date` | **its own date, not the media's** |
| `type` | hold beta / foot beta / body position / mistake / condition / other |
| `text` | |

**Each annotation carries its own date.** This is what turns pinned notes into a learning history: in week 1 you thought the crux was the third move; by week 4 you'd worked out it was the foot placement before it. That progression IS the value.

### Move sequence and Move

Optional. A project can have a move sequence, annotated photos, **both, or neither.** These are complementary, not alternatives — no either/or choice is ever presented to the user.

**Move sequence:**

| Field | Notes |
|---|---|
| `id`, `project_id`, `name` | |
| `source` | manual / extracted-from-video |

**Move:**

| Field | Notes |
|---|---|
| `id`, `sequence_id`, `order` | |
| `media_id` | nullable — the frame showing this move |
| `description` | |
| `status` | linked / inconsistent / not-yet |
| `notes` | |

Annotations attach to a Move's frame exactly as they do to any other media. A pin on move four's frame saying "left hand too low" is the same entity as a pin on a wide shot.

### Location

| Field | Notes |
|---|---|
| `id`, `name`, `is_outdoor` | |
| `notes` | |

Reusable across logs and projects, so the user types a crag or gym name once.

---

## Board climbing — legal and technical constraints

**Do not replicate board layouts.** Kilter's March 2026 cease-and-desist against Aurora Climbing specifically covered its name, logo, and images of its board layout. Rendering any commercial board's hold layout in this app is an unacceptable legal risk.

**Do not import climbs from board APIs.** Those APIs are undocumented and unauthorized, and the Aurora backend shutdown in March 2026 took every dependent tool offline with no notice. Do not build features on them.

**Deep linking out is supported and safe.** Kilter publishes shareable climb URLs of the form `kilterboardapp.com/climbs/<id>`, configured as universal links — opening one launches the Kilter app at that climb. Store the URL as `share_url` on a board climb log entry and let the user tap through.

**The sanctioned design:** log board climbs as structured text (board type, angle, name, setter, grade, attempts) plus an optional pasted share URL. The user types or pastes everything. Full tracking, cross-board comparison, grade progression — zero exposure.

**For a visual, let users photograph their own board.** Their photo, their content, no IP question. This is what the Media entity is for.

---

## Storage — architectural change required

**`localStorage` cannot hold media.** It caps at roughly 5–10MB and stores text only. A single phone photo is 2–5MB.

**Migrate persistence to IndexedDB.** It handles binary data and offers far larger quotas. This is a change to how the app persists everything and should be done before media work begins, not retrofitted.

**Rules:**

- **Compress on import.** Resize to ~1600px longest edge and re-encode as JPEG. A 4MB photo becomes ~300KB. Non-negotiable — without it, a hundred logged sessions exhausts the quota.
- **Never store video.** Extract 10–20 frames from a camera-roll video via a video element and canvas, save the frames as compressed images, discard the video. ~3MB per sequence instead of 50MB+. Build and test frame extraction standalone before integrating — Safari seeking is unreliable.
- **Strip EXIF on import** unless the user explicitly opts in. Photo EXIF contains GPS coordinates; for outdoor projects this would silently store crag locations, which is a live access-sensitivity issue in climbing.
- **Export must handle media.** The current JSON export cannot carry images efficiently. Decide the format (a zip bundle, or JSON with media as separate files) before shipping media features. **Export is the only backup — this is not optional.**

---

## Open questions

- If a user deletes an auto-generated log, does the program run roll back its progress?
- If a project is archived, its logs stay in history — confirm and implement.
- Video annotation by timestamp (rather than by frame) — deferred; treat as a separate later feature, do not force one model to cover both.
- Media quota management: what happens as storage fills? Warn, or offer bulk export-and-purge?
- Does a session log attached to both a program and a project appear in both derived views? (Should be yes.)
