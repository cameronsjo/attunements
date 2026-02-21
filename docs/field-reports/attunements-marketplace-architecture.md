# Attunements Marketplace Architecture — Field Report

**Date:** 2026-02-20
**Type:** architecture
**Project:** attunements (+ 12 product repos)

## Goal

Create onboarding skills for Cameron's project portfolio so a newcomer to any repo can type `/onboard` and get guided through setup and first use. Package these as a Claude Code marketplace.

## Architecture

The session went through three architectural phases, each an improvement on the last.

### Phase 1: Slash Commands (`.claude/commands/onboard.md`)

The naive approach. Five parallel agents surveyed 34 repos, read every README, and wrote `onboard.md` commands directly into each project's `.claude/commands/` directory. Fast to generate, but:

- No plugin structure — commands only exist locally
- No marketplace — can't install across machines
- Frontmatter was the simple `description:` format, not the full SKILL.md spec

This phase established the **content** (prerequisites, setup steps, first use, key files, common tasks) but not the **distribution**.

### Phase 2: Central Plugin (`project-onboard`)

Inspired by looking at [tobi/qmd](https://github.com/tobi/qmd), which uses proper `SKILL.md` files with rich YAML frontmatter, reference subdirectories, and `marketplace.json` for plugin delivery.

Built a single plugin containing all 15 skills (later trimmed to 12). Each repo got a symlink:

```
~/Projects/bosun/.claude/skills/onboard → plugin/skills/bosun
```

This solved distribution (install one plugin, get all skills) but had a fundamental flaw: **the product didn't own its own onboarding story**. If bosun's setup changes, you'd update the central plugin, not bosun itself. Cross-repo drift waiting to happen.

### Phase 3: Per-Repo Plugins (`attunements` marketplace)

The final architecture. Each product repo becomes its own Claude Code plugin:

```
bosun/
├── .claude-plugin/
│   ├── marketplace.json    # Standalone marketplace entry
│   └── plugin.json         # Plugin metadata
├── skills/
│   └── onboard/
│       └── SKILL.md        # Onboarding skill
└── (product code)
```

The `attunements` marketplace indexes all 12 repos by GitHub URL. Two install vectors:

1. `claude marketplace add cameronsjo/attunements` — install all at once
2. Install any single repo as a standalone plugin

This matches the qmd pattern exactly: a product repo that also happens to be a Claude Code plugin.

## Decisions Made

### Two marketplaces, not one

The workbench (16 plugins) is for **tools and workflows** — essentials, rules, superpowers, etc. Attunements (12 plugins) is for **products** — things Cameron built that solve specific problems. Different concerns, different registries.

### SKILL.md over commands

Skills have richer frontmatter (`name`, `description`, `compatibility`, `allowed-tools`, `metadata`) and can include reference subdirectories. Commands are simpler but less discoverable by the plugin system. For onboarding — which benefits from being findable — skills are the right choice.

### Skill lives at repo root (`skills/onboard/`) not in `.claude/`

Following the qmd convention. The `.claude/` directory is for session-local config. The `skills/` directory at repo root is for published plugin content. This also keeps skills visible in the repo file listing rather than hidden in dotfiles.

### Trimmed scope: 12 repos, not 15 or 25

Dropped risolve (single-file script, README covers it), workout-tracker (dormant), and HackMyResume (mid-modernization, unstable). Skipped all LOW-value repos (simple enough that README suffices) and non-products (homelab, homebridge, cameronsjo profile, etc.).

## Gotchas

- **macOS `sed`** doesn't support the GNU `{ }` grouping syntax. Had to rewrite frontmatter extraction with `awk` instead
- **Bash associative arrays with hyphens** (`declare -A` with keys like `auto-unraid-deploy`) caused `unbound variable` errors. Switched to pipe-delimited string arrays
- **Two repos had stale remotes** — `auto-unraid-deploy` remote points to `not-that-terrible-at-all.git` (renamed?), `mcp-server-template` remote not found. Commits landed but pushes failed for these two
- **Beads flush hook** blocked the llm-council commit entirely. Needs manual `bd sync --flush-only` to unblock

## Key Takeaways

- The qmd pattern (product repo = Claude Code plugin) is the right default for any repo that warrants onboarding. Add `.claude-plugin/` and `skills/`, done
- Separate marketplaces for separate concerns. Tools vs products is a real boundary worth respecting
- Parallel agent batches (5 agents x 3 repos) generated 15 onboarding skills in under 3 minutes. The content generation wasn't the hard part — the architecture decisions were
- Symlinks between repos are a maintenance liability. If you're symlinking, the ownership model is wrong. Each repo should own its own content
- The "attunements" name (from The Artificer brand) stuck immediately — naming matters when you're going to see it in every `marketplace list` output
