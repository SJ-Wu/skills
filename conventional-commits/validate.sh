#!/usr/bin/env bash
# Checks a commit message against the Conventional Commits 1.0.0 spec.
#
#   ./validate.sh <file>     # e.g. a commit-msg hook's $1
#   ./validate.sh            # reads the message from stdin
#   ./validate.sh --strict   # an unconventional type becomes an error
#
# Only the spec's MUSTs are errors. A type outside the conventional set is a
# warning, because the spec explicitly permits types beyond feat and fix.
# Style preferences the spec does not mandate (description length, casing,
# trailing periods) are left to the skill's prose, not enforced here.
#
# Written for bash 3.2 — the version macOS ships — so no mapfile, no negative
# array indices, and every regex lives in a variable (3.2 treats quoted regex
# fragments as literals).
set -o pipefail

STRICT=0
FILE=""
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) FILE="$arg" ;;
  esac
done

KNOWN_TYPES="feat fix docs style refactor perf test build ci chore revert"

errors=0
warnings=0
err()  { echo "error: $1" >&2; errors=$((errors + 1)); }
warn() { echo "warning: $1" >&2; warnings=$((warnings + 1)); }

raw=()
if [ -n "$FILE" ]; then
  [ -f "$FILE" ] || { echo "error: no such file: $FILE" >&2; exit 2; }
  while IFS= read -r line || [ -n "$line" ]; do raw[${#raw[@]}]="$line"; done < "$FILE"
else
  while IFS= read -r line || [ -n "$line" ]; do raw[${#raw[@]}]="$line"; done
fi

# Drop the comment lines git's template leaves behind, then trailing blanks —
# they are noise, and a trailing blank would otherwise look like a missing footer.
msg=()
if [ ${#raw[@]} -gt 0 ]; then
  for line in "${raw[@]}"; do
    case "$line" in '#'*) continue ;; esac
    msg[${#msg[@]}]="$line"
  done
fi
while [ ${#msg[@]} -gt 0 ] && [ -z "${msg[$((${#msg[@]} - 1))]}" ]; do
  unset "msg[$((${#msg[@]} - 1))]"
done

if [ ${#msg[@]} -eq 0 ]; then
  echo "error: the commit message is empty" >&2
  exit 1
fi

header="${msg[0]}"

header_re='^([a-zA-Z]+)(\(([^()]*)\))?(!)?: (.+)$'
empty_desc_re='^[a-zA-Z]+(\([^()]*\))?(!)?:[[:space:]]*$'
missing_space_re='^[a-zA-Z]+(\([^()]*\))?(!)?:'
missing_colon_re='^[a-zA-Z]+(\([^()]*\))?(!)?[[:space:]]'

type=""
bang=""
if [[ "$header" =~ $header_re ]]; then
  type="${BASH_REMATCH[1]}"
  has_scope="${BASH_REMATCH[2]}"
  scope="${BASH_REMATCH[3]}"
  bang="${BASH_REMATCH[4]}"
  description="${BASH_REMATCH[5]}"

  lower_type=$(printf '%s' "$type" | tr '[:upper:]' '[:lower:]')
  case " $KNOWN_TYPES " in
    *" $lower_type "*) ;;
    *)
      if [ $STRICT -eq 1 ]; then
        err "unconventional type '$type'; expected one of: $KNOWN_TYPES"
      else
        warn "unconventional type '$type'; the spec allows it, the conventional set is: $KNOWN_TYPES"
      fi
      ;;
  esac

  # A scope MUST be a noun naming a section of the codebase, so empty
  # parentheses and multi-word scopes both fail the intent.
  if [ -n "$has_scope" ] && [ -z "$scope" ]; then
    err "empty scope '()' — a scope MUST be a noun, or be omitted"
  fi
  if [ -n "$scope" ] && [[ "$scope" =~ [[:space:]] ]]; then
    err "scope '$scope' contains whitespace — a scope MUST be a single noun"
  fi
else
  if [[ "$header" =~ $empty_desc_re ]]; then
    err "the description MUST NOT be empty: '$header'"
  elif [[ "$header" =~ $missing_space_re ]]; then
    err "a space MUST follow the colon: '$header'"
  elif [[ "$header" =~ $missing_colon_re ]]; then
    err "a colon MUST follow the type/scope: '$header'"
  else
    err "the header MUST begin with a type, e.g. 'feat: …' or 'fix(parser): …': '$header'"
  fi
fi

# A body or footer MUST begin one blank line after the description.
if [ ${#msg[@]} -gt 1 ] && [ -n "${msg[1]}" ]; then
  err "line 2 MUST be blank — the body begins one blank line after the description"
fi

# A footer is a token, then ': ' or ' #', then a value. Tokens use '-' in place
# of whitespace so they stay distinguishable from body prose; BREAKING CHANGE
# is the one token allowed to keep its space.
breaking_re='^(BREAKING CHANGE|BREAKING-CHANGE)(: | #).+$'
token_re='^[A-Za-z][A-Za-z0-9-]*(: | #).+$'
miscased_re='^[Bb][Rr][Ee][Aa][Kk][Ii][Nn][Gg][ -][Cc][Hh][Aa][Nn][Gg][Ee](: | #)'

breaking_footer=0
saw_footer=0
i=1
while [ $i -lt ${#msg[@]} ]; do
  line="${msg[$i]}"
  if [[ "$line" =~ $breaking_re ]]; then
    saw_footer=1
    breaking_footer=1
  elif [[ "$line" =~ $miscased_re ]]; then
    # Any other casing is not the footer the spec means, so the break would be
    # silently missed by every tool that reads these messages.
    err "BREAKING CHANGE MUST be uppercase as a footer token: '$line'"
  elif [[ "$line" =~ $token_re ]]; then
    saw_footer=1
  fi
  i=$((i + 1))
done

if [ $errors -eq 0 ]; then
  summary="ok: ${type:-?}"
  if [ -n "$bang" ] || [ $breaking_footer -eq 1 ]; then
    summary="$summary (breaking change)"
  fi
  [ $saw_footer -eq 1 ] && summary="$summary, footers present"
  [ $warnings -gt 0 ] && summary="$summary, $warnings warning(s)"
  echo "$summary"
  exit 0
fi

echo "$errors error(s)" >&2
exit 1
