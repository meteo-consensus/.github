#!/usr/bin/env bash
# Runs the pnpm build settings check of node-ci.yml on every example repository of this
# folder and compares the result with the case's `.expect` file (meteo-consensus/.github#24).
#
# Usage: run.sh <check script>, the script being the `run` block of the "Check pnpm build
# settings" step, extracted from node-ci.yml by the CI so that the tested code is the shipped one.
#
# `<case>.expect`: first line `pass` or `fail`; for `fail`, each following line is a fixed string
# that must appear in the output, one per expected `::error` line, and the output must hold
# exactly that many `::error` lines (no missing failure, no unexpected one).
set -euo pipefail

check=$(realpath "$1")
here=$(dirname "$(realpath "$0")")
work=$(mktemp -d)
failures=0

for dir in "$here"/*/; do
  name=$(basename "$dir")
  expect="$here/$name.expect"
  out="$work/$name.out"
  code=0
  (cd "$dir" && bash "$check") >"$out" 2>&1 || code=$?

  ok=1
  errors=$(grep -c '^::error' "$out" || true)
  case $(head -n 1 "$expect") in
    pass)
      if [ "$code" -ne 0 ] || [ "$errors" -ne 0 ]; then ok=0; fi
      ;;
    fail)
      if [ "$code" -eq 0 ]; then ok=0; fi
      wanted=0
      while IFS= read -r want; do
        wanted=$((wanted + 1))
        if ! grep -qF -- "$want" "$out"; then
          echo "  missing: $want"
          ok=0
        fi
      done < <(tail -n +2 "$expect")
      if [ "$errors" -ne "$wanted" ]; then
        echo "  expected $wanted ::error lines, got $errors"
        ok=0
      fi
      ;;
    *)
      echo "  $expect: first line must be pass or fail"
      ok=0
      ;;
  esac

  if [ "$ok" -eq 1 ]; then
    echo "ok   $name (exit $code)"
  else
    echo "FAIL $name (exit $code), output:"
    # Indented, so the runner does not act on the check's workflow commands.
    sed 's/^/  | /' "$out"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  echo "::error::$failures pnpm build settings case(s) failed"
  exit 1
fi
echo "All pnpm build settings cases passed."
