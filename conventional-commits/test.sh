#!/usr/bin/env bash
# Regression tests for validate.sh. Run from anywhere: ./test.sh
# Each case is a commit message plus the exit code the spec demands.
set -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
V="$DIR/validate.sh"

pass=0
fail=0
check() { # check <expected-rc> <label> <line...>
  expect="$1"; label="$2"; shift 2
  out=$(printf '%s\n' "$@" | "$V" 2>&1); rc=$?
  if [ "$rc" -eq "$expect" ]; then
    pass=$((pass + 1))
    printf '  ok   %s\n' "$label"
  else
    fail=$((fail + 1))
    printf '  FAIL %s (expected rc=%s, got %s)\n%s\n' "$label" "$expect" "$rc" "$out"
  fi
}

echo "accepted:"
check 0 "type and description"          "feat: 新增使用者登入流程"
check 0 "scope"                         "fix(parser): 修正多重空白的解析錯誤"
check 0 "! marks a breaking change"     "feat(api)!: 改用 v2 認證端點"
check 0 "body after a blank line"       "feat: 新增匯出功能" "" "支援 CSV 與 JSON 兩種格式。"
check 0 "body and footer"               "fix: 修正逾時設定" "" "原本的預設值過短。" "" "Refs: #123"
check 0 "BREAKING CHANGE footer"        "feat: 調整設定載入順序" "" "BREAKING CHANGE: 環境變數的優先序高於設定檔"
check 0 "BREAKING-CHANGE is equivalent" "feat: 調整設定載入順序" "" "BREAKING-CHANGE: 環境變數優先"
check 0 "footer split by ' #'"          "fix: 修正崩潰" "" "Refs #123"
check 0 "types are case-insensitive"    "FEAT: 新增功能"
check 0 "a type beyond the set warns"   "wip: 進行中"
check 0 "multi-paragraph body"          "feat: 新增快取層" "" "第一段。" "" "第二段。" "" "Reviewed-by: someone"
check 0 "bullet body"                   "fix: 修正解析錯誤" "" "- 第一點" "- 第二點" "" "Refs: #482"
check 0 "bullet that looks like a footer" "fix: 修正解析錯誤" "" "- Refs: 這是內文不是頁腳"

echo "rejected:"
check 1 "no type"                       "更新了一些東西"
check 1 "no space after the colon"      "feat:新增登入"
check 1 "no colon"                      "feat 新增登入"
check 1 "empty description"             "feat: "
check 1 "line 2 is not blank"           "feat: 新增功能" "這行應該要空白"
check 1 "lowercased breaking footer"    "feat: 調整" "" "Breaking change: 有重大變更"
check 1 "empty scope"                   "fix(): 修正"
check 1 "multi-word scope"              "fix(user auth): 修正"
check 1 "empty message"                 ""

echo "--- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
