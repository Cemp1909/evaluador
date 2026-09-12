#!/usr/bin/env bash
set -euo pipefail

required_variables=(
  ADMIN_USERNAME
  ADMIN_PASSWORD
  COORDINADOR_USERNAME
  COORDINADOR_PASSWORD
  COORDINADOR_ZONA
)

for variable in "${required_variables[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    echo "Falta configurar la variable de Vercel: $variable" >&2
    exit 1
  fi
done

cat > .env <<EOF
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
COORDINADOR_USERNAME=${COORDINADOR_USERNAME}
COORDINADOR_PASSWORD=${COORDINADOR_PASSWORD}
COORDINADOR_ZONA=${COORDINADOR_ZONA}
DEMO_PROFESOR_USERNAME=${DEMO_PROFESOR_USERNAME:-}
DEMO_PROFESOR_PASSWORD=${DEMO_PROFESOR_PASSWORD:-}
DEMO_PROFESOR_NOMBRE=${DEMO_PROFESOR_NOMBRE:-Profesor demo}
DEMO_PROFESOR_ZONA=${DEMO_PROFESOR_ZONA:-Zona Demo}
PROFESOR_1_USERNAME=${PROFESOR_1_USERNAME:-}
PROFESOR_1_PASSWORD=${PROFESOR_1_PASSWORD:-}
PROFESOR_1_NOMBRE=${PROFESOR_1_NOMBRE:-}
PROFESOR_1_ZONA=${PROFESOR_1_ZONA:-}
PROFESOR_2_USERNAME=${PROFESOR_2_USERNAME:-}
PROFESOR_2_PASSWORD=${PROFESOR_2_PASSWORD:-}
PROFESOR_2_NOMBRE=${PROFESOR_2_NOMBRE:-}
PROFESOR_2_ZONA=${PROFESOR_2_ZONA:-}
PROFESOR_3_USERNAME=${PROFESOR_3_USERNAME:-}
PROFESOR_3_PASSWORD=${PROFESOR_3_PASSWORD:-}
PROFESOR_3_NOMBRE=${PROFESOR_3_NOMBRE:-}
PROFESOR_3_ZONA=${PROFESOR_3_ZONA:-}
EOF

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
