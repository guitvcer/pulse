#!/bin/bash
# Claude Code hook: after a Swift file in this project is edited, run lint + tests.
# Exit code 2 feeds the failure back to Claude so it gets fixed right away.
cd "$(dirname "$0")/.."
file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[[ "$file" == "$PWD"/* && ( "$file" == *.swift || "$file" == */Makefile ) ]] || exit 0

if ! output=$(make check 2>&1); then
    echo "Automatic check failed after editing $file:" >&2
    echo "$output" | grep -E "error|warning:|✘|\.swift:[0-9]+" | head -40 >&2
    exit 2
fi
