#!/usr/bin/env bash
# Actualiza el código desde GitHub y reconstruye. Ejecutar en el servidor:
#   bash deploy/scripts/deploy.sh             -> todo
#   bash deploy/scripts/deploy.sh backend     -> solo Spring Boot
#   bash deploy/scripts/deploy.sh prediction  -> solo el prediction-service
set -euo pipefail
cd "$(dirname "$0")/.."          # carpeta deploy/
[ -f .env ] || { echo "Falta deploy/.env (cp .env.example .env)"; exit 1; }

echo ">> git pull"
git -C .. pull --ff-only

echo ">> build + up ${1:-todo}"
if [ -n "${1:-}" ]; then docker compose up -d --build "$1"; else docker compose up -d --build; fi

docker image prune -f >/dev/null
docker compose ps
