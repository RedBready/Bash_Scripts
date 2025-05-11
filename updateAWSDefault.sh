#!/usr/bin/env bash
# update_aws_default.sh ─ overwrite the two credential lines under [default]
# Usage: update_aws_default.sh <ACCESS_KEY_ID> <SECRET_ACCESS_KEY>

set -euo pipefail

# ─── 1. Parse arguments ────────────────────────────────────────────────────────
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <ACCESS_KEY_ID> <SECRET_ACCESS_KEY>" >&2
  exit 1
fi
AK="$1"
SK="$2"

# ─── 2. Locate credentials file ────────────────────────────────────────────────
CREDS_FILE="$HOME/.aws/credentials"
[[ -f $CREDS_FILE ]] || {
  echo "Creating new credentials file at $CREDS_FILE"
  mkdir -p "$(dirname "$CREDS_FILE")"
  printf '[default]\naws_access_key_id = \naws_secret_access_key = \n' >"$CREDS_FILE"
}

# ─── 3. Ensure [default] header exists ─────────────────────────────────────────
if ! grep -q '^\[default\]' "$CREDS_FILE"; then
  printf '\n[default]\naws_access_key_id = \naws_secret_access_key = \n' >>"$CREDS_FILE"
fi

# ─── 4. Replace or add the two lines (portable awk) ────────────────────────────
awk -v ak="$AK" -v sk="$SK" '
  BEGIN             { section="none" }
  /^\[/              { section=$0 }
  section=="[default]" && /^aws_access_key_id/     { $0="aws_access_key_id = " ak; seen_ak=1 }
  section=="[default]" && /^aws_secret_access_key/ { $0="aws_secret_access_key = " sk; seen_sk=1 }
  { print }
  END {
    # If the lines were missing, append them
    if (section=="[default]" && !seen_ak) print "aws_access_key_id = " ak
    if (section=="[default]" && !seen_sk) print "aws_secret_access_key = " sk
  }
' "$CREDS_FILE" >"${CREDS_FILE}.tmp" && mv "${CREDS_FILE}.tmp" "$CREDS_FILE"

echo "✅  Updated [default] in $CREDS_FILE"
