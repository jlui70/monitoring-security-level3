#!/bin/bash

# ======================================
# SCRIPT PARA BUSCAR SECRETS DO VAULT
# Usado pelos containers para obter senhas
# ======================================

set -e

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
SECRET_PATH="$1"
VAULT_TOKEN="$2"

if [ -z "$SECRET_PATH" ] || [ -z "$VAULT_TOKEN" ]; then
    echo "Uso: $0 <secret_path> <vault_token>"
    echo "Exemplo: $0 secret/mysql/root-password hvs.token123"
    exit 1
fi

# Aguardar Vault estar disponível
echo "⏳ Aguardando Vault em $VAULT_ADDR..."
until curl -s "$VAULT_ADDR/v1/sys/health" >/dev/null 2>&1; do
    sleep 2
done

# Buscar secret
echo "🔑 Buscando secret: $SECRET_PATH"
SECRET_VALUE=$(curl -s \
    -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/$SECRET_PATH" | \
    grep -o '"value":"[^"]*"' | \
    cut -d'"' -f4)

if [ -z "$SECRET_VALUE" ]; then
    echo "❌ Erro: Secret não encontrado ou token inválido"
    exit 1
fi

echo "$SECRET_VALUE"