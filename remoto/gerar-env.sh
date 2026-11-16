#!/usr/bin/env bash
# Gera o .env do Seu Emissor com segredos novos (secao 4 do manual).
# Uso, no servidor: bash /opt/emissor-saas/.gerar-env.sh DOMINIO EMAIL "NOME DO SISTEMA"
# Nao imprime nenhum segredo.
set -euo pipefail
cd /opt/emissor-saas

if [ "$#" -ne 3 ]; then
  echo "Uso: bash .gerar-env.sh DOMINIO EMAIL \"NOME\"" >&2
  exit 2
fi
if [ -e .env ]; then
  echo "ERRO: .env ja existe. Nada foi alterado." >&2
  exit 3
fi

IMG=node:24-bookworm-slim
U="$(id -u):$(id -g)"

docker run --rm --user "$U" -e npm_config_cache=/tmp/npm-cache -v "$PWD:/app" -w /app "$IMG" \
  npm ci --ignore-scripts --no-audit --no-fund >/tmp/emissor-npm-ci.log 2>&1 \
  || { echo "ERRO no npm ci. Veja /tmp/emissor-npm-ci.log" >&2; exit 4; }

docker run --rm --user "$U" -v "$PWD:/app" -w /app "$IMG" \
  node scripts/configurar-ambiente.js "$1" "$2" "$3"

chmod 600 .env
echo "OK: .env criado. Variaveis ainda vazias:"
grep -oE '^[A-Z_]+=$' .env | sed 's/=$//' || echo "(nenhuma)"
