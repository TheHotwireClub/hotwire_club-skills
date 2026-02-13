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
- Copies mapped articles from corpus into `skills/hwc-*/references/`
- Rebuilds `references/INDEX.md` per skill

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
