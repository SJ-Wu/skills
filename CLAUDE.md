# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A source-of-truth collection of reusable **agent skills**, kept vendor-neutral so the same
skill can be shared across Claude Code, OpenAI Codex, and other agents/dev platforms rather
than being duplicated per tool.

There is no application code here — no build, no test suite, no lint config, and (as of now)
no git repo. The deliverable is prose: each skill is a Markdown file that an agent loads as
instructions. "Correctness" means the skill triggers when it should and gives an agent enough
to act without further context.

## Layout

```
<skill-name>/SKILL.md    # one directory per skill, lowercase-kebab-case, matching `name:`
```

`eli5/SKILL.md` is the reference implementation — read it before authoring a new skill.

## Skill file conventions

Each `SKILL.md` opens with YAML frontmatter:

```yaml
---
name: <lowercase-kebab-case, must match the directory name>
description: "<what it does + the exact phrases that should trigger it>"
---
```

The `description` is the only thing an agent sees when deciding whether to load the skill, so
it carries double duty: a one-line capability summary *and* an explicit trigger list
(`eli5` enumerates "ELI5", "dumb it down", "explain this to my…", and states that partial
matches count). Write triggers as concrete user phrasings, not abstract categories.

The body is written as second-person instructions **to the agent**, not documentation about
the skill. `eli5` shows the working shape:

1. Numbered `## Step N` sections that run in order.
2. Lookup tables mapping an input variable (audience, mode, target) to the behavior it selects
   — keeps the skill deterministic instead of leaving the agent to improvise.
3. A stated default for every variable (`eli5`: "If the audience isn't explicitly stated,
   default to 'Age 5'"), so the skill never stalls on a missing input.
4. Worked `## Examples` pairing a literal user utterance with the expected response style.
5. `## Important Reminders` for the failure modes worth pre-empting.

Keep skills portable: no Claude-Code-specific tool names, no `mcp__*` references, no
assumptions about a particular harness's file layout, unless the skill exists specifically to
target one platform.

## Distribution

Skills are not yet wired into any agent — nothing symlinks this directory into `~/.claude/skills`
or a Codex equivalent. The sibling repo `../dotfiles` is where per-machine symlinking lives
(`dotfiles/install.sh` links `claude/settings.json` and `claude/statusline.sh` into `~/.claude/`);
if this repo needs to be installed onto a machine, extend that idempotent `link` helper rather
than inventing a second mechanism here.
