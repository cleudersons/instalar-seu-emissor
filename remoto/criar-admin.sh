#!/usr/bin/env bash
# Cria o PRIMEIRO administrador do Seu Emissor (secao 5 do manual).
# Rodado pelo PROPRIO usuario, num terminal interativo:
#   ssh -t USUARIO@IP 'bash /opt/emissor-saas/.criar-admin.sh'
# A senha nao aparece na tela nem fica em argumentos de linha de comando.
set -euo pipefail
cd /opt/emissor-saas

if [ ! -t 0 ]; then
  echo "Rode em terminal interativo: ssh -t USUARIO@IP 'bash /opt/emissor-saas/.criar-admin.sh'" >&2
  exit 2
fi

read -r -p "E-mail do administrador: " ADMIN_EMAIL
while :; do
  read -r -s -p "Senha nova (minimo 12 caracteres): " ADMIN_PASSWORD; printf '\n'
  read -r -s -p "Repita a senha: " CONFIRMA; printf '\n'
  if [ "$ADMIN_PASSWORD" != "$CONFIRMA" ]; then echo "As senhas nao conferem. Tente de novo."; continue; fi
  if [ "${#ADMIN_PASSWORD}" -lt 12 ]; then echo "Senha curta. Use pelo menos 12 caracteres."; continue; fi
  break
done
unset CONFIRMA
export ADMIN_EMAIL ADMIN_PASSWORD
export ADMIN_NAME="Administrador"

STATUS=0
docker compose run --rm -e ADMIN_EMAIL -e ADMIN_PASSWORD -e ADMIN_NAME app npm run criar-admin || STATUS=$?
unset ADMIN_EMAIL ADMIN_PASSWORD ADMIN_NAME
rm -f /opt/emissor-saas/.criar-admin.sh
if [ "$STATUS" -eq 0 ]; then echo "OK: administrador criado. Pode voltar ao Claude e dizer 'feito'."; fi
exit "$STATUS"
