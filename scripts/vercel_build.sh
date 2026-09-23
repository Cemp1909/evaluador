#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY. La app requiere Supabase." >&2
  exit 1
fi
if [[ "${SUPABASE_PUBLISHABLE_KEY}" == sb_secret_* ]]; then
  echo "No uses una clave secreta de Supabase en Flutter." >&2
  exit 1
fi
printf 'SUPABASE_URL=%s\nSUPABASE_PUBLISHABLE_KEY=%s\n' \
  "$SUPABASE_URL" "$SUPABASE_PUBLISHABLE_KEY" > .env

cp .env .env.public-demo

if [[ -z "${FLUTTER_BIN:-}" ]]; then
  flutter_directory="${TMPDIR:-/tmp}/flutter-3.41.6"
  if [[ ! -x "$flutter_directory/bin/flutter" ]]; then
    git clone --depth 1 --branch 3.41.6 \
      https://github.com/flutter/flutter.git "$flutter_directory"
  fi
  FLUTTER_BIN="$flutter_directory/bin/flutter"
fi

"$FLUTTER_BIN" config --enable-web
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build web --release

python3 scripts/preparar_web_offline.py
