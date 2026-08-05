# DATA-MODEL.md — Finger Block

The schema for the program builder. Read this before writing or changing any code that touches programs, sessions, logging, or progression.

Status: design spec, not yet implemented. Written August 2026.

---

## The core idea

Finger Block does not ship training programs. It runs *whatever program the user brings* — one they wrote, one from a coach, one they found in a book or on a forum — and applies progress tracking to it.

This has one consequence that drives the entire model: **nothing about a specific training style may be hardcoded.** Not edge sizes, not "added weight," not hangs. The model describes *any* structured training, and finger training is just the first thing it happens to express.

The one thing Finger Block does that most trackers don't: **it calculates future prescribed loads from your own test results.** That feedback loop is the product. Everything else is logging.

---

## Three layers

**Library** — reusable definitions. What things *are*.
**Plan** — what you intend to do. Templates, no dates.
**Record** — what actually happened. Real dates, real numbers.

Data flows Library → Plan → Record, with one deliberate exception (see Progression rules).

---

## Entities

### Metric

A thing that can be measured. Metrics are **data, not code** — the user can define new ones. This is what makes arbitrary programs expressible.

| Field | Notes |
|---|---|
| `id` | |
| `name` | e.g. "Added weight", "Hold time", "V-grade", "Reps" |
| `unit` | e.g. lb, kg, sec, count, or a named scale |
| `kind` | `number` \| `duration` \| `count` \| `scale` \| `text` |
| `direction` | `higher_is_better` \| `lower_is_better` — needed for progress charts |

Ships with a default set. User can add more.

### Exercise

A thing you do. References the metrics it's measured by.

| Field | Notes |
|---|---|
| `id` | |
| `name` | e.g. "Tension block lift", "Max hang", "Lock-off hold" |
| `category` | finger / pulling / core / board / boulder / mobility / other |
| `metric_ids[]` | which metrics apply |
| `notes` | freeform |

### Program

A template. **No dates.** Shareable without sharing anyone's logs.

| Field | Notes |
|---|---|
| `id`, `name` | |
| `author` | may be someone other than the user |
| `description` | |
| `phase_ids[]` | ordered |

### Phase

A block of weeks with a focus.

| Field | Notes |
|---|---|
| `id`, `name` | e.g. "Tension block base" |
| `duration_weeks` | |
| `session_template_ids[]` | |

### Session template

What a given training day prescribes.

| Field | Notes |
|---|---|
| `id`, `name` | |
| `prescription_ids[]` | ordered |
| `schedule` | which day(s) within the week |

### Prescription

One exercise as prescribed within a session. This is the *intent* — distinct from what actually gets done.

| Field | Notes |
|---|---|
| `id` | |
| `exercise_id` | |
| `targets{}` | metric_id → target value |
| `sets`, `rest_seconds` | |
| `progression_rule_id` | nullable — null means fixed |
| `order` | |

### Progression rule

How prescribed values change over time. **This is the engine.**

| Field | Notes |
|---|---|
| `id`, `type` | see rule types below |
| `params{}` | shape depends on type |
| `source` | for percentage rules — what it derives from |

### Program run

An instance of a program, started on a real date. This is what allows multiple concurrent programs.

| Field | Notes |
|---|---|
| `id`, `program_id` | |
| `start_date`, `end_date` | |
| `status` | active / completed / archived |

### Session log

What actually happened on a given day.

| Field | Notes |
|---|---|
| `id`, `date` | |
| `program_run_id` | nullable — freeform sessions allowed |
| `session_template_id` | nullable |
| `duration_minutes` | |
| `rpe` | 1–10, session RPE |
| `readiness{}` | sleep / soreness / stress / motivation, 1–5, captured *before* the session |
| `notes` | |

`session_load = rpe × duration_minutes` (Foster's session-RPE method). Computed, not stored.

### Set log

Actual performance, per set.

| Field | Notes |
|---|---|
| `id`, `session_log_id`, `prescription_id` | prescription_id nullable for freeform |
| `set_number` | |
| `actuals{}` | metric_id → actual value |
| `completed` | bool — feeds autoregulated rules |

**Prescribed and actual are always two separate numbers.** Every useful comparison — adherence, progress, "did I hit target" — depends on keeping both.

### Test result

A benchmark measurement that progression rules read from.

| Field | Notes |
|---|---|
| `id`, `exercise_id`, `date` | |
| `values{}` | metric_id → result |
| `session_log_id` | nullable — where it came from |

### Context log

Optional daily context. **See the privacy and safety section below.**

| Field | Notes |
|---|---|
| `id`, `date` | |
| `bodyweight` | optional, opt-in, off by default |
| `notes` | |

---

## Progression rule types

Build the engine to handle all of these. Expose a subset in the UI; adding a type later should mean exposing something that already works, not refactoring.

| Type | What it does | Params |
|---|---|---|
| `fixed` | Never changes | none |
| `manual` | Author enumerated every week | table of values per week |
| `percentage_of_source` | Derives from a reference value | `source`, `percent` |
| `linear_add` | Fixed increment on a schedule | `increment`, `every_n_sessions` |
| `autoregulated` | Adjusts from actual performance | `trigger`, `adjustment` |
| `grade_based` | Progresses by climbing grade | `scale`, `target_count` |

### Notes on specific rules

**`percentage_of_source` is deliberately general.** `source` may be a test result, bodyweight, or the user's last actual value. This single rule absorbs percentage-of-max, percentage-of-bodyweight, and "beat last week by 5%."

**`manual` is not a fallback — it is the most important rule.** Most real-world programs are tables, not formulas. Without it, "translate any program you found" fails immediately.

**`autoregulated` is the one architectural exception.** It reads the Record layer (Set log) to compute the Plan layer. Everything else flows Library → Plan → Record; this reaches back. Design the engine knowing this from the start.

**Undulating / wave periodization is not a rule type.** "80%, 85%, 90%, deload" is `manual` applied one level up. Do not build a periodization engine.

### Ship order

1. `manual`, `percentage_of_source`, `fixed` — minimum viable, covers the core pitch
2. `autoregulated` — what experienced climbers want
3. `grade_based` — when board/boulder sessions land
4. `linear_add` — arguably `manual` with a shortcut; ship on demand

**Validate before building:** express 4–5 real published programs (Eva López max hangs, Abrahangs, Lattice-style repeaters, a Hörst protocol, a linear max-hang progression) using this model. Every rule type that no real program needs should be deferred. Every program that can't be expressed reveals a gap.

---

## The wizard

Program setup uses a decision tree: **training type → goal → confirm and adjust.**

**The wizard is a preset layer, not a second system.** Every path through it produces an ordinary `Program` object using the entities above. It pre-fills fields. It never introduces a parallel format.

The user's *goal* selects the progression rule. They never see rule-type vocabulary.

| Type → goal | Sets up |
|---|---|
| Finger strength → max strength | Edge lift / max hang; added weight + hold time; `percentage_of_source` from a test; schedules a week-one test |
| Finger strength → endurance | Repeaters; hold time + reps; `manual` |
| Board → max strength | Grade + attempts; `grade_based` |

### Wizard constraints

- **Three steps maximum.** Each branch multiplies paths to design and test.
- **Four options per step maximum.** Past four it's a list, not a decision.
- **Always preview consequences** before committing — "this will set up…". Hidden complexity is only trustworthy when its effects are visible.
- **The escape hatch is load-bearing.** Every wizard result lands on an editable screen exposing all generic fields, and "build from scratch" must always be reachable. Without it, the wizard silently becomes a constraint and the core pitch stops being true.

---

## Privacy and safety

**Bodyweight logging is opt-in and off by default.**

Climbing has a well-documented disordered-eating and RED-S problem, driven specifically by strength-to-weight fixation. An app that charts bodyweight against performance is, for some users, actively harmful.

Rules:
- No goal weights, no targets, no streaks, no gamification around weight
- Never surface weight-vs-performance as a headline correlation
- Trends only — no daily-change alerts
- The feature must be as easy to ignore as it is to enable

**Do not have the app announce conclusions.** With ~15 tracked variables and ~100 sessions, spurious correlations are guaranteed. Show trends; let the user interpret.

**Injury disclaimer required** before first use. Maximal finger loading carries real pulley and tendon injury risk.

---

## Storage

Local-first. `localStorage`, key `fingerblock:v1`. No accounts, no server, no sync.

This is a deliberate design choice, not a limitation to fix later. Do not move data to a backend without an explicit decision.

Consequences to design around:
- Export must be prominent and easy — it is the only backup
- Clearing site data destroys everything
- iOS may evict storage for a home-screen web app unused for ~7 days

---

## Open questions

- How are programs shared between users? Export/import as a single file is the likely answer — decide the format before shipping the builder.
- Can a `Program` be edited after a `Program run` has started? Probably yes, but the run needs to keep what it was actually prescribed.
- Does a mid-program retest recalculate past prescriptions or only future ones? (Should be: future only.)
- How are freeform, off-program sessions handled in progress charts?
