#!/bin/bash
# Xcode Pre-build action: inject DART_DEFINES from secrets/prod.json
# vào ios/Flutter/Local.xcconfig (đã được include AFTER Generated.xcconfig
# trong Debug.xcconfig/Release.xcconfig → override DART_DEFINES).
#
# Không gọi `flutter build` để tránh deadlock với Xcode build pipeline.
# Đổi DEFINES_FILE bên dưới sang secrets/dev.json nếu muốn dev profile.

set -euo pipefail
exec > /tmp/flutter_pre_build.log 2>&1

DEFINES_FILE="${SRCROOT}/../secrets/prod.json"
LOCAL_XCCONFIG="${SRCROOT}/Flutter/Local.xcconfig"

if [ ! -f "$DEFINES_FILE" ]; then
  echo "[pre-build] ERROR: $DEFINES_FILE missing — copy from prod.json.example" >&2
  exit 1
fi

# Encode each non-comment KEY=value as base64, comma-joined → DART_DEFINES.
export DEFINES_FILE
ENCODED=$(/usr/bin/python3 - <<'PY'
import json, base64, os
with open(os.environ['DEFINES_FILE']) as f:
    data = json.load(f)
parts = []
for k, v in data.items():
    if k.startswith('_'):
        continue
    s = f'{k}={v}'.encode('utf-8')
    parts.append(base64.b64encode(s).decode('ascii'))
print(','.join(parts))
PY
)

if [ -z "$ENCODED" ]; then
  echo "[pre-build] ERROR: empty DART_DEFINES — kiểm tra $DEFINES_FILE" >&2
  exit 1
fi

# Rewrite Local.xcconfig: drop existing AUTO block, append new one. Preserve other lines (e.g. GMS_API_KEY).
MARKER_BEGIN="// >>> AUTO: DART_DEFINES from secrets/prod.json — DO NOT EDIT <<<"
MARKER_END="// <<< AUTO: DART_DEFINES end >>>"

TMP=$(mktemp)
if [ -f "$LOCAL_XCCONFIG" ]; then
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    BEGIN { skip=0 }
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$LOCAL_XCCONFIG" > "$TMP"
fi
{
  echo ""
  echo "$MARKER_BEGIN"
  echo "DART_DEFINES = $ENCODED"
  echo "$MARKER_END"
} >> "$TMP"
mv "$TMP" "$LOCAL_XCCONFIG"

echo "[pre-build] OK — DART_DEFINES written to $LOCAL_XCCONFIG"
