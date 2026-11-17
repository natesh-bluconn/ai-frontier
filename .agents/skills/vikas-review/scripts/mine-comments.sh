#!/usr/bin/env bash
# Pull a reviewer's PR comments (inline, review bodies, PR conversation) since a date,
# one comment per line, so new recurring themes can be folded into rules/*.md.
#
# Usage: mine-comments.sh [SINCE=YYYY-MM-DD] [REVIEWER=<gh login>] [OUT_DIR]
#   defaults: SINCE = "Last mined" date in SKILL.md, REVIEWER = vikasparsa, OUT_DIR = mktemp
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SINCE="${1:-$(grep -oE 'Last mined:\*\* [0-9-]+' "$SKILL_DIR/SKILL.md" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')}"
REVIEWER="${2:-vikasparsa}"
OUT_DIR="${3:-$(mktemp -d)}"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
mkdir -p "$OUT_DIR"

echo "Mining comments by $REVIEWER in $REPO since $SINCE -> $OUT_DIR" >&2

gh api --paginate "repos/$REPO/pulls/comments?per_page=100&since=${SINCE}T00:00:00Z" \
  --jq ".[] | select(.user.login==\"$REVIEWER\") | \"#\(.pull_request_url|split(\"/\")|last) \(.path):\(.line // .original_line // 0): \(.body|gsub(\"\r\";\"\")|gsub(\"\n+\";\" ⏎ \"))\"" \
  > "$OUT_DIR/inline.txt"

gh api --paginate "repos/$REPO/issues/comments?per_page=100&since=${SINCE}T00:00:00Z" \
  --jq ".[] | select(.user.login==\"$REVIEWER\") | select(.html_url|test(\"/pull/\")) | \"#\(.html_url|split(\"/\")|.[-1]|split(\"#\")|.[0]): \(.body|gsub(\"\r\";\"\")|gsub(\"\n+\";\" ⏎ \"))\"" \
  > "$OUT_DIR/pr-comments.txt"

: > "$OUT_DIR/reviews.txt"
for pr in $(gh pr list --state all --limit 300 --search "updated:>=$SINCE" --json number -q '.[].number'); do
  gh api "repos/$REPO/pulls/$pr/reviews" \
    --jq ".[] | select(.user.login==\"$REVIEWER\" and .body != \"\") | \"#$pr [\(.state)]: \(.body|gsub(\"\r\";\"\")|gsub(\"\n+\";\" ⏎ \"))\"" \
    >> "$OUT_DIR/reviews.txt" || true
done

wc -l "$OUT_DIR"/*.txt >&2
echo "$OUT_DIR"
