---
title: Zone-Level wiki + log
created: 2026-05-09
tags: [meta, vault-schema, zone-wiki, zone-log]
---

# Zone-Level wiki + log

Same multi-tier idea as projects (see [[multi-tier-model]]), now extended to all **distilled zones** that accumulate content. Same token-economy + write-routing rationale.

---

## 规则 Rule

**Any folder under `knowledge/`, `experience/`, `learning/`, `wiki/`, `projects/`, `work/<co>/`, or any of their sub-folders that contains direct content files OR descendant content** must carry these three sibling files alongside the existing folder MOC:

| File | Job | Update cadence |
|------|-----|----------------|
| `<folder>/<folder>.md` | **MOC** — concept-level entry, hand-curated. (MOC = parent folder name; see [[frontmatter-and-naming]].) | When semantic structure shifts. Optional for `work/<co>/` etc. that already have a `<co>.md`. |
| `<folder>/wiki.md` | **Directory index** — file-by-file (and/or sub-folder) table with description + keywords + write-routing hints. **Frequently updated by `/ingest` and `/wrap-work`**. AI **must read this before deciding where to write** within the folder. | Every ingest into the folder |
| `<folder>/log.md` | **Change log** — append-only timeline of additions / supersedes / removals / structural changes. Distinct from any `log/` weekly subfolder. | Every ingest into the folder |

## Mid-level vs leaf folders

- **Leaf folder** (contains atomic content pages directly, e.g. `knowledge/concurrency/`): wiki lists every atomic page with description / keywords / when-to-cite.
- **Mid-level folder** (contains only sub-folders, e.g. `knowledge/clouds/`): wiki lists subdirectories with description / status.
- **Top-level zone** (`knowledge/`, `experience/`): wiki lists all sub-domains.

Same template (`meta/templates/zone-wiki.md`, `zone-log.md`) — sections used differ.

## 何时创建 When to create

- **First time** a folder has any content (a new file or a new sub-folder with content), `/ingest` or `/wrap-work` creates `wiki.md` + `log.md` from `meta/templates/zone-wiki.md` / `zone-log.md`.
- **Empty placeholder folders** do NOT need them. Create on first content.
- **Capture / raw / meta zones** (`inbox/`, `raw/`, `archives/`, `meta/`, `thinking/`) do NOT need them — they're not distilled.

## `<folder>/wiki.md` vs `<folder>/<folder>.md` MOC 区别

Same folder, two roles:

| File | Audience | Role |
|------|----------|------|
| `<folder>.md` MOC | Human reading for **understanding** | Curated semantic entry — "what is this domain about, where to start" |
| `wiki.md` | AI deciding **where to write** + machine-checked completeness | Auto-maintained file inventory — "every file here, what's its keyword bag, what to cite it for" |

Both are kept; they have different jobs.

## Skill responsibilities

- **`/ingest`**: when writing a new page in a distilled folder, must:
  - Touch the `<folder>.md` MOC (already in the workflow)
  - Add an entry to `<folder>/wiki.md` and to every ancestor's `wiki.md` up to the zone root
  - Append a line to `<folder>/log.md` (the leaf log; ancestor logs only updated when structural change happens)
  - Create wiki + log if missing
- **`/wrap-work`**: when extracting knowledge / lesson into a distilled folder (Step 3), follow the same rule.
- **`/lint`**: verify zone-level wiki + log invariants — no orphan pages missing from `wiki.md`; no leaf folder with content but missing `wiki.md` / `log.md`.

## 已 bootstrap 的 folder Currently bootstrapped folders

(as of 2026-04-30)

- `knowledge/` (top), `knowledge/clouds/`, `knowledge/clouds/aws/`, `knowledge/clouds/aws/bedrock/`, `knowledge/concurrency/`
- `experience/` (top), `experience/lessons/`
- (Project-internal `wiki.md` + `log.md` per [[multi-tier-model]] already exist for `work/sapia/projects/agents/`)
