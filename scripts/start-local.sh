#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir/backend"
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
export DATABASE_URL="sqlite:///$project_dir/backend/local.db"
export DEMO_MODE=true
.venv/bin/python -m app.seed --stocks "$project_dir/examples/stocks_outubro_2026.xlsx" --fiis "$project_dir/examples/fiis_outubro_2026.xlsx" --reference 2026-10
exec .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --no-proxy-headers
