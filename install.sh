#!/usr/bin/env bash
# Symlinks each skill in this repo into the agent skill directories.
#
# Self-contained: this repo has no dependency on any other, so a plain
# `git clone && ./install.sh` is enough. Safe to re-run — existing real
# directories are moved aside once into ~/.claude/skills-backups/, existing
# correct symlinks are left alone, and symlinks pointing at skills that no
# longer exist here are pruned.
set -euo pipefail
shopt -s nullglob

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
# Backups live outside the skill directory on purpose: a moved-aside copy still
# holds a SKILL.md, and left in place it would register as a duplicate skill.
BACKUP_DIR="$HOME/.claude/skills-backups"
BACKUP_SUFFIX="bak-$(date +%Y%m%d%H%M%S)"

link_skill() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 0
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup="$BACKUP_DIR/$(basename "$dest").$BACKUP_SUFFIX"
    mkdir -p "$BACKUP_DIR"
    echo "Backing up existing $dest -> $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
}

# A skill is any top-level directory holding a SKILL.md.
skills=()
for skill_path in "$SKILLS_DIR"/*/SKILL.md; do
  skills+=("$(basename "$(dirname "$skill_path")")")
done

if [[ ${#skills[@]} -eq 0 ]]; then
  echo "No skills found in $SKILLS_DIR (expected <skill-name>/SKILL.md)." >&2
  exit 1
fi

# The `name:` in the frontmatter is what the agent registers the skill under;
# a mismatch with the directory name is a silent source of confusion.
for name in "${skills[@]}"; do
  declared="$(sed -n 's/^name:[[:space:]]*//p' "$SKILLS_DIR/$name/SKILL.md" | head -1)"
  if [[ -n "$declared" && "$declared" != "$name" ]]; then
    echo "Warning: $name/SKILL.md declares name '$declared'; expected '$name'." >&2
  fi
done

echo "Installing ${#skills[@]} skill(s) for Claude Code..."
mkdir -p "$CLAUDE_SKILLS_DIR"
for name in "${skills[@]}"; do
  link_skill "$SKILLS_DIR/$name" "$CLAUDE_SKILLS_DIR/$name"
done

# Drop links left behind by skills that were renamed or removed. Only symlinks
# pointing into this repo are touched; anything else in there is left alone.
for entry in "$CLAUDE_SKILLS_DIR"/*; do
  [[ -L "$entry" ]] || continue
  target="$(readlink "$entry")"
  [[ "$target" == "$SKILLS_DIR/"* ]] || continue
  if [[ ! -e "$target" ]]; then
    echo "Removing stale link $entry -> $target"
    rm "$entry"
  fi
done

# TODO: Codex. The CLI is not installed here yet and it is unclear whether it
# reads SKILL.md natively (`~/.codex/prompts/` is a different mechanism), so
# there is nothing to link against until that is confirmed.

echo "Done. Skills are linked from $SKILLS_DIR — edits take effect immediately."
