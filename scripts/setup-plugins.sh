#!/usr/bin/env bash
# Set up each product repo as a Claude Code plugin with its onboarding skill.
# Idempotent — safe to re-run.
set -euo pipefail

PLUGIN_SOURCE="${HOME}/Projects/claude-configurations/project-onboard/skills"
PROJECTS_DIR="${HOME}/Projects"

# Format: "skill_name|project_dir|description"
ENTRIES=(
  "bosun|bosun|GitOps CLI for Docker Compose on bare metal"
  "claude-tty|claude-tty|Phone-based server diagnostics terminal via ttyd+tmux+Claude"
  "feedly-summarize-to-obsidian|feedly-summarize-to-obsidian|Lambda+SQS pipeline that summarizes Feedly articles via LLM"
  "llm-council|llm-council|Multi-LLM deliberation web app with Council and Arena debate modes"
  "media-mcp|media-mcp|MCP server enriching Obsidian vaults with book, movie, and TV metadata"
  "mouse-mcp|mouse-mcp|Disney parks data MCP server with attraction wait times and fuzzy search"
  "obaass|obaass|Headless Obsidian orchestrator via Docker Compose"
  "obsidi-backup|obsidi-backup|Vault backup sidecar with AI commit messages and restic cloud storage"
  "obsidi-claude|obsidi-claude|Obsidian plugin for chatting with Claude AI"
  "obsidian-mcp|obsidian-mcp|Obsidian plugin exposing 28+ vault tools via MCP server"
)

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r skill project_dir description <<< "$entry"
  project_path="${PROJECTS_DIR}/${project_dir}"
  skill_source="${PLUGIN_SOURCE}/${skill}/SKILL.md"

  if [[ ! -d "$project_path" ]]; then
    echo "SKIP  ${skill} — project not found"
    continue
  fi

  # 1. Remove old symlink if present
  if [[ -L "${project_path}/.claude/skills/onboard" ]]; then
    rm "${project_path}/.claude/skills/onboard"
    echo "UNLINK ${skill} — removed old symlink"
  fi

  # 2. Create .claude-plugin/ with marketplace.json and plugin.json
  mkdir -p "${project_path}/.claude-plugin"

  if [[ ! -f "${project_path}/.claude-plugin/plugin.json" ]]; then
    cat > "${project_path}/.claude-plugin/plugin.json" << PEOF
{
  "name": "${skill}",
  "description": "${description}",
  "author": {
    "name": "cameronsjo"
  }
}
PEOF
    echo "WRITE ${skill} — plugin.json"
  else
    echo "OK    ${skill} — plugin.json already exists"
  fi

  if [[ ! -f "${project_path}/.claude-plugin/marketplace.json" ]]; then
    cat > "${project_path}/.claude-plugin/marketplace.json" << MEOF
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "${skill}",
  "owner": {
    "name": "Cameron Sjo",
    "github": "cameronsjo"
  },
  "plugins": [
    {
      "name": "${skill}",
      "source": "./.claude-plugin",
      "description": "${description}"
    }
  ]
}
MEOF
    echo "WRITE ${skill} — marketplace.json"
  else
    echo "OK    ${skill} — marketplace.json already exists"
  fi

  # 3. Move SKILL.md into the repo
  mkdir -p "${project_path}/skills/onboard"

  if [[ -f "$skill_source" ]] && [[ ! -f "${project_path}/skills/onboard/SKILL.md" ]]; then
    cp "$skill_source" "${project_path}/skills/onboard/SKILL.md"
    echo "COPY  ${skill} — SKILL.md → skills/onboard/"
  elif [[ -f "${project_path}/skills/onboard/SKILL.md" ]]; then
    echo "OK    ${skill} — SKILL.md already in place"
  else
    echo "WARN  ${skill} — no source SKILL.md found at ${skill_source}"
  fi

  echo ""
done

echo "Done. Each repo is now a standalone Claude Code plugin."
