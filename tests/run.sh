#!/bin/sh
# Runs every spec file in its own headless nvim
cd "$(dirname "$0")/.." || exit 1
status=0
for spec in tests/*_spec.lua; do
  [ -e "$spec" ] || continue
  nvim --headless --clean -l tests/harness.lua "$spec" || status=1
done
exit $status
