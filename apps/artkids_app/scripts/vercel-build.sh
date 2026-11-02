#!/usr/bin/env bash
set -euo pipefail

api_base_url="${API_BASE_URL:-https://artkid-api.onrender.com/api/v1}"
if [[ "$api_base_url" != https://* ]]; then
  echo "API_BASE_URL must use HTTPS for the deployed frontend." >&2
  exit 1
fi

mkdir -p env
cat > env/prod.env <<'EOF'
FLAVOR=prod
ENABLE_FIREBASE=false
ENABLE_MOCK_SHOP=false
ENABLE_MOCK_ORDERS=false
ENABLE_MOCK_COURSES_PROGRESS=false
EOF

"$PWD/.vercel/flutter-sdk/bin/flutter" build web \
  --release --no-pub --no-web-resources-cdn --no-wasm-dry-run \
  --dart-define=FLAVOR=prod \
  --dart-define="API_BASE_URL=$api_base_url"
