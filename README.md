# skills

A shared collection of agent skills — reusable Markdown instructions that teach an AI
coding agent how to handle a particular kind of task.

Kept vendor-neutral on purpose: the same skill should work in Claude Code, OpenAI Codex, and
other agents or dev platforms, instead of being rewritten and drifting apart in each tool's
own config directory.

## Layout

```
<skill-name>/SKILL.md    # one directory per skill; the name matches the `name:` field
```

| Skill | What it does |
|-------|--------------|
| [`eli5`](eli5/SKILL.md) | Explains a topic, code, or error tailored to a specific audience — a 5-year-old, a manager, a grad student, your mum. |

## Skill format

Every `SKILL.md` starts with YAML frontmatter:

```yaml
---
name: eli5
description: "Explain any topic … Use this skill whenever the user says 'explain like I am', 'ELI5', …"
---
```

The `description` is all an agent sees when deciding whether to load the skill, so it has to
carry both the capability summary *and* the phrases that should trigger it — written as
concrete user utterances, not abstract categories.

The body is written as instructions **to the agent**: ordered steps, lookup tables that map an
input (audience, mode, target) to the behavior it selects, a stated default for every input so
the skill never stalls, worked examples, and the failure modes worth pre-empting. `eli5` is the
reference implementation; read it before adding a new skill.

Skills stay portable — no harness-specific tool names, no MCP references, no assumptions about
one agent's file layout — unless a skill exists specifically to target one platform.

See [CLAUDE.md](CLAUDE.md) for the full authoring conventions.

## Installing

```sh
git clone https://github.com/SJ-Wu/skills.git
cd skills
./install.sh
```

`install.sh` symlinks every `<skill-name>/` directory into `~/.claude/skills/`, so edits in the
repo take effect immediately with no reinstall. It is idempotent: correct symlinks are left
alone, a real directory already sitting at a target is moved aside into
`~/.claude/skills-backups/` first, and links pointing at skills that were since renamed or
removed are pruned. Adding a new skill means re-running it; changing an existing one does not.

The script deliberately depends on nothing outside this repo. Machine bootstrap lives in the
sibling [dotfiles](https://github.com/SJ-Wu/dotfiles) repo, which can call this script when the
repo is present — the dependency runs that way round so these skills stay usable on their own.

Codex is not wired up: the CLI reads `~/.codex/prompts/`, which is a different mechanism, and
whether it consumes `SKILL.md` natively still needs confirming.
