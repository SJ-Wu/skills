---
name: conventional-commits
description: "Write git commit messages that follow the Conventional Commits 1.0.0 spec, with the description written in Traditional Chinese. Use this skill whenever you are about to commit, whenever the user says 'commit', 'commit 這些變更', 'help me write a commit message', 'squash these', or asks you to amend, reword, or review a commit message. Also use it when the user asks whether a message is valid, when a commit-msg hook rejects something, when writing a PR title that follows the same convention, or when a release tool (semantic-release, changesets, git-cliff) needs the history to be machine-readable. Even a one-word request like 'commit' should trigger this skill."
---

# Conventional Commits

A commit message is read twice: once by a person scanning `git log` for the
change that broke something, and once by a machine deciding the next version
number. The spec exists so that one message serves both. Every rule below is
in service of that — the structure is what makes the history parseable, and
the description is what makes it useful to a human six months from now.

The message is written in Traditional Chinese; the structural parts — type,
scope, and footer tokens — stay lowercase ASCII, because tooling matches on
them.

## The shape

```
<type>[(scope)][!]: <描述>

[正文]

[頁腳]
```

Only the first line is required. What is genuinely non-negotiable: a type, a
colon-and-space, and a non-empty description. Everything else is a judgement
call you make from the change itself.

## Step 1: Read the change before naming it

Run `git diff --staged` (or `git diff` if nothing is staged yet). You cannot
pick an honest type from the file names alone — a change under `src/api/`
might be a feature, a fix, or a refactor, and only the diff says which.

If the staged change turns out to be two unrelated things, say so and offer
to split it. A commit that needs "and" in its description is usually two
commits, and the history is more useful split than merged.

## Step 2: Choose the type

The type answers "what kind of change is this?", not "what files moved?".

| Type | Use when | Releases as |
|------|----------|-------------|
| `feat` | A new capability the user or caller can now reach. Required for any new feature. | minor |
| `fix` | Behaviour that was wrong is now correct. Required for any bug fix. | patch |
| `docs` | Documentation only — README, comments, this file. | — |
| `style` | Formatting with no behaviour change: whitespace, semicolons, import order. | — |
| `refactor` | Restructured code that behaves identically. Neither fixes a bug nor adds a feature. | — |
| `perf` | Faster or lighter, same behaviour. | patch |
| `test` | Adding or correcting tests. | — |
| `build` | Build system, bundler, or dependency changes. | — |
| `ci` | CI configuration and pipelines. | — |
| `chore` | Housekeeping that touches no source: lockfile bumps, ignore files. | — |
| `revert` | Undoing an earlier commit. Name the reverted hash in a footer. | — |

`feat` and `fix` are the two the spec mandates; the rest are convention and a
project MAY use others. When two types both fit, ask what the change *did for
someone*: fixing a crash by rewriting a module is still `fix`, because that is
what a reader cares about. When nothing fits and the change is real work, ask
the user rather than defaulting to `chore` — `chore` on a substantive change
hides it from the changelog, which is the one thing this convention exists to
prevent.

**Default when the diff is genuinely ambiguous:** prefer the type a reader
would search for. Between `refactor` and `chore`, choose `refactor`.

## Step 3: Add a scope, if one is obvious

A scope is a single noun naming the part of the codebase that changed:
`fix(parser):`, `feat(auth):`. It is optional, and a wrong scope is worse
than none — it makes `git log --grep` lie.

Use the vocabulary the project already uses. Look at `git log --oneline -30`
and reuse the scopes that appear there rather than inventing a parallel set.
Omit the scope when the change is repo-wide or when no single noun covers it.

## Step 4: Write the description

The description is the summary a person reads in `git log --oneline`. Write it
in Traditional Chinese.

- Say what the change *does*, not what you did. 「修正多重空白造成的解析錯誤」,
  not 「我修了 parser」.
- One line, ideally under 50 characters. If it will not fit, the detail
  belongs in the body.
- No trailing period — it is a title, not a sentence.
- Concrete over vague. 「更新設定」 tells a future reader nothing; 「將逾時預設值
  從 5 秒調整為 30 秒」 tells them everything.
- Keep identifiers, commands, and file names in their original form. Do not
  translate `useEffect` or `package.json`.

The spec is silent on language and capitalisation — those are the project's
call, and here the call is Traditional Chinese.

## Step 5: Add a body when the "why" is not obvious

The body starts one blank line after the description. Its job is context the
diff cannot carry: why this approach, what was rejected, what constraint
forced it. Skip it when the description already says everything — an empty
body is better than a restatement.

Write it as bullets, one point per line, starting with `-`:

```
fix(parser): 修正字串含多重空白時的解析錯誤

- 原本以單一空白切分 token，連續空白會產生空字串欄位
- 空欄位使下游的欄位對應整列偏移，症狀出現在離錯誤很遠的地方
- 改以正規表示式切分，同時涵蓋 tab 與全形空白
```

A commit body is skimmed, not read. Someone bisecting a regression wants to
find the relevant point in one pass, and a paragraph makes them parse prose
to get there. Bullets also keep each point honest — a bullet that needs an
"而且" is two bullets.

Prose is the better choice in one case: when the body is a single continuous
argument whose sentences depend on each other, and breaking it into bullets
would sever the reasoning. That is rarer than it feels.

Wrap at roughly 72 characters. Keep each bullet to one line where you can; a
bullet that spills over three lines is usually hiding two points.

## Step 6: Add footers when something references the commit

Footers start one blank line after the body. Each is a token, then either
`: ` or ` #`, then a value:

```
Refs: #123
Reviewed-by: someone
Closes #456
```

Tokens use `-` instead of spaces (`Reviewed-by`, not `Reviewed by`) so a
parser can tell a footer from an ordinary body paragraph. `BREAKING CHANGE`
is the single exception allowed to keep its space.

## Step 7: Mark breaking changes

A breaking change is signalled in one of two ways, and getting this wrong
means a consumer's build breaks on what looked like a patch release.

**A `!` before the colon** — compact, and the description carries the
explanation:

```
feat(api)!: 改用 v2 認證端點
```

**A `BREAKING CHANGE:` footer** — when the consequence needs more room:

```
feat: 調整設定的載入順序

BREAKING CHANGE: 環境變數的優先序現在高於設定檔，
原本依賴設定檔覆寫環境變數的部署需要調整。
```

The footer token MUST stay uppercase — `BREAKING CHANGE` or the equivalent
`BREAKING-CHANGE`. Any other casing is just an ordinary footer, and every
release tool will miss the break. Both signals together are fine, and using
`!` alone is complete on its own.

## Step 8: Validate before committing

`validate.sh` checks a draft against the spec's requirements:

```sh
printf '%s\n' "feat(auth): 新增雙因素驗證" | ./validate.sh
git commit -m "$(cat msg.txt)" # only after validate.sh exits 0
```

It reads a file argument or stdin, exits 0 when the message satisfies every
MUST, and prints the specific rule when it does not. It deliberately checks
only what the spec mandates — description length, tone, and language are this
skill's business, not the validator's.

Wire it into a repo as a `commit-msg` hook when the project wants it enforced:

```sh
ln -s ~/Projects/skills/conventional-commits/validate.sh .git/hooks/commit-msg
```

Git resolves a relative hook symlink against `.git/hooks/`, not the repo root,
so an absolute path is the one that actually works from an arbitrary repo.

`test.sh` runs the validator against the accepted and rejected cases from the
spec; run it after changing the validator.

## Examples

**A new feature**
```
feat(auth): 新增雙因素驗證流程
```

**A fix whose reason is not visible in the diff**
```
fix(parser): 修正字串含多重空白時的解析錯誤

- 原本以單一空白切分 token，連續空白會產生空字串欄位
- 空欄位使下游的欄位對應整列偏移
- 改以正規表示式切分，一併處理 tab 與全形空白

Refs: #482
```

**A breaking change, marked compactly**
```
feat(config)!: 移除已棄用的 legacy 設定格式
```

**A breaking change that needs explaining**
```
refactor(storage): 改以非同步介面存取快取

BREAKING CHANGE: getCache() 現在回傳 Promise，
所有呼叫端都需要加上 await。
```

**Reverting**
```
revert: 還原「feat(api): 新增批次查詢端點」

This reverts commit 676104e.
```

## Reminders

- Read the diff before choosing the type. A type picked from the file path is
  a guess, and a wrong type silently produces a wrong version number.
- Everything except the uppercase `BREAKING CHANGE` token is case-insensitive
  to a parser — but pick one casing and stay consistent with the project's
  existing history.
- Do not invent a scope the project has never used. Check `git log` first.
- If the change genuinely does not fit the convention, say so rather than
  forcing it. A clear message with an unconventional type is more useful than
  a conventional message that misleads.
