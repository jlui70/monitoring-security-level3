#!/bin/bash

# ======================================
# INIT CONTAINER PARA MYSQL
# Busca senhas do Vault antes de iniciar MySQL
# ======================================

set -e

echo "🔑 MySQL Init: Buscando secrets do Vault..."

# Aguardar Vault estar disponível
until curl -s http://vault:8200/v1/sys/health >/dev/null 2>&1; do
    echo "⏳ Aguardando Vault..."
    sleep 2
done

echo "✅ Vault disponível!"

# Buscar senha root do MySQL
MYSQL_ROOT_PASSWORD=$(curl -s \
    -H "X-Vault-Token: ${MYSQL_VAULT_TOKEN}" \
    "http://vault:8200/v1/secret/data/mysql/root-password" | \
    grep -o '"value":"[^"]*"' | \
    cut -d'"' -f4)

# Buscar senha do usuário zabbix
MYSQL_PASSWORD=$(curl -s \
    -H "X-Vault-Token: ${MYSQL_VAULT_TOKEN}" \
    "http://vault:8200/v1/secret/data/mysql/zabbix-password" | \
    grep -o '"value":"[^"]*"' | \
    cut -d'"' -f4)

if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "❌ Erro: Não foi possível obter senhas do Vault"
    exit 1
fi

echo "✅ Secrets obtidos com sucesso!"

# Salvar secrets como variáveis de ambiente para o MySQL
mkdir -p /shared
echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" > /shared/mysql-secrets.env
echo "MYSQL_PASSWORD=${MYSQL_PASSWORD}" >> /shared/mysql-secrets.env
chmod 644 /shared/mysql-secrets.env

echo "📁 Secrets salvos em /shared/mysql-secrets.env"