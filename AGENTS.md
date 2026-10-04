# Repository Maintenance Guide

This repository contains Hotwire skills under `skills/` and a sync script that copies source
articles into each skill's `references/` directory.

## Primary Workflow

### 1) Sync references from corpus

Run:

```bash
ruby scripts/sync-references.rb
```

What this does:

- Reads `config/supertopic-mapping.yml`
- Copies **new** mapped articles from corpus into `skills/hwc-*/references/`
  (already-synced references are skipped so post-sync normalization is preserved)
- Rebuilds `references/INDEX.md` per skill

To deliberately overwrite every reference with the raw corpus version
(discarding normalization), run `FORCE_SYNC=1 ruby scripts/sync-references.rb`.

### 2) Normalize skills after sync

After syncing, ensure each skill still follows repository structure standards.

For each skill directory `skills/hwc-*/`:

- Keep `SKILL.md` frontmatter to `name` and `description` only
- Keep `SKILL.md` body lean and procedural:
  - `Core Workflow`
  - `Guardrails`
  - `Load References Selectively`
  - `Escalate to Neighbor Skills`
- Keep full examples in `references/*.md` (not in `SKILL.md`)
- Keep `agents/openai.yaml` present with:
  - `interface.display_name`
  - `interface.short_description`
  - `interface.default_prompt` (must mention `$skill-name`)

For references:

- Keep `references/INDEX.md` aligned with existing files
- Ensure long reference docs (over 100 lines) include `## Table of Contents`
- Keep migrated pattern sections (`## Pattern Card: ...`) when applicable
- Remove stale references to deleted/unsupported articles
- List every reference in the skill's `SKILL.md` under `Load References Selectively`

### 3) Bump the plugin version

Bump `version` in `.claude-plugin/plugin.json` whenever skills or references change;
Claude Code only offers installed users an update when the version changes.
Use a minor bump for new references or skills, a patch bump for fixes, then tag the
release commit `vX.Y.Z`.

Source articles live in `../Landing Page/collections/_posts`. A new post is converted
into `corpus/` of `../hotwire_club-mcp` with the `Summarize Post` prompt in its
`PROMPTS.md`, with the Patreon sample solution code pasted in, before step 1.

## Validation Checklist

Before committing:

```bash
# No backup artifacts
find skills -type f \( -name '*~' -o -name '.*undo-tree*' \)

# Long references should have TOC
for f in skills/*/references/*.md; do \
  [ "$(basename "$f")" = "INDEX.md" ] && continue; \
  lines=$(wc -l < "$f"); \
  if [ "$lines" -gt 100 ]; then rg -q '^## Table of Contents' "$f" || echo "MISSING_TOC $f"; fi; \
done

# Spot check unresolved deleted references
rg -n '2024-08-27-turbo-frames-flash' skills
```

## Current Skill Layout

Each skill should follow:

```text
skills/hwc-<topic>/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
    ├── INDEX.md
    └── *.md
```
