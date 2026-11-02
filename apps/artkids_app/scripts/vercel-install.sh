#!/usr/bin/env bash
set -euo pipefail

flutter_dir="$PWD/.vercel/flutter-sdk"
if [[ ! -x "$flutter_dir/bin/flutter" ]]; then
  git clone --depth 1 --branch 3.44.1 https://github.com/flutter/flutter.git "$flutter_dir"
fi
"$flutter_dir/bin/flutter" config --no-analytics
"$flutter_dir/bin/flutter" pub get
