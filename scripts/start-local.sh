#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Keep existing configuration and generate local secrets only once.
python3 - <<'PY'
from pathlib import Path
import secrets

root_env = Path('.env')
if not root_env.exists():
    root_env.touch(mode=0o600)
    root_env.write_text(
        f'MYSQL_ROOT_PASSWORD={secrets.token_hex(24)}\n'
        f'MYSQL_PASSWORD={secrets.token_hex(24)}\n'
    )
values = dict(line.split('=', 1) for line in root_env.read_text().splitlines()
              if line.strip() and not line.startswith('#') and '=' in line)
backend_env = Path('backend/.env')
if not backend_env.exists():
    password = values['MYSQL_PASSWORD']
    backend_env.touch(mode=0o600)
    backend_env.write_text(
        f'DATABASE_URL=mysql+pymysql://jobboard:{password}@127.0.0.1:3307/job_board\n'
        f'SECRET_KEY={secrets.token_hex(32)}\n'
        'CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173\n'
    )
frontend_env = Path('frontend/.env')
if not frontend_env.exists():
    frontend_env.write_text('VITE_API_URL=http://127.0.0.1:8001\n')
PY

if ! docker info >/dev/null 2>&1; then
  echo 'Docker inaccessible : démarrez Docker et autorisez votre utilisateur à y accéder.' >&2
  echo 'Les fichiers de configuration ont été créés. Relancez ce script après correction.' >&2
  exit 1
fi
docker compose up -d --wait --wait-timeout 240 db

cat <<'EOF'
Base MySQL prête sur 127.0.0.1:3307 (données conservées dans un volume Docker).
Les données de démonstration sont importées uniquement au premier démarrage.

Backend (terminal 1) :
  cd backend
  python3 -m venv .venv
  .venv/bin/pip install -r requirements-dev.txt
  .venv/bin/python -m uvicorn app.main:app --reload --port 8001

Frontend (terminal 2) :
  cd frontend
  npm ci
  npm run dev -- --port 5173 --strictPort

Site : http://localhost:5173
Comptes : admin, recruiter, jdoe — mot de passe : admin1234
Configuration existante conservée : vérifiez les .env si vous en aviez déjà.
EOF
