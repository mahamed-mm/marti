#!/usr/bin/env bash
# Runs SwiftLint on the file Claude just wrote or edited.
# Silent unless there are issues.

# Read the JSON payload from stdin and extract the file path
FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only act on .swift files
if [[ "$FILE" != *.swift ]]; then
  exit 0
fi

# Skip if SwiftLint isn't installed
if ! command -v swiftlint &> /dev/null; then
  exit 0
fi

# Skip if there's no SwiftLint config in the project root
if [[ ! -f ".swiftlint.yml" ]]; then
  exit 0
fi

# Run SwiftLint quietly and surface only violations
OUTPUT=$(swiftlint lint --path "$FILE" --quiet 2>&1)

if [[ -n "$OUTPUT" ]]; then
  echo "🔍 SwiftLint findings in $FILE:" >&2
  echo "$OUTPUT" | head -10 >&2
fi

exit 0
