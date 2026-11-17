#!/bin/bash
# Shared post-edit hook for TypeScript files
# Auto-formats and type-checks edited TypeScript files

# Require jq
if ! command -v jq &>/dev/null; then
  echo "Warning: jq not found — skipping post-edit hook" >&2
  exit 0
fi

# Extract filepath from tool input (supports both Claude and Copilot JSON formats)
filepath=$(cat | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process TypeScript files
if [ -n "$filepath" ] && echo "$filepath" | grep -qE '\.ts$'; then
  echo "🔧 Running post-edit hooks on: $filepath"
  
  # Run ESLint with auto-fix
  npx eslint --fix "$filepath" 2>&1 | tail -5
  
  # Optional: Type check (commented out by default for performance)
  # tsc -p ./tsconfig.json --noEmit 2>&1 | head -30
fi
