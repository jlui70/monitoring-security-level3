#!/bin/bash

# ======================================
# INIT CONTAINER PARA ZABBIX
# Busca senhas do Vault antes de iniciar Zabbix
# ======================================

set -e

echo "🔑 Zabbix Init: Buscando secrets do Vault..."

# Aguardar Vault estar disponível
until curl -s http://vault:8200/v1/sys/health >/dev/null 2>&1; do
    echo "⏳ Aguardando Vault..."
    sleep 2
done

echo "✅ Vault disponível!"

# Buscar senha do admin Zabbix
ZABBIX_ADMIN_PASSWORD=$(curl -s \
    -H "X-Vault-Token: ${ZABBIX_VAULT_TOKEN}" \
    "http://vault:8200/v1/secret/data/zabbix/admin-password" | \
    grep -o '"value":"[^"]*"' | \
    cut -d'"' -f4)

# Buscar senha do banco MySQL (usuário zabbix)
MYSQL_PASSWORD=$(curl -s \
    -H "X-Vault-Token: ${ZABBIX_VAULT_TOKEN}" \
    "http://vault:8200/v1/secret/data/mysql/zabbix-password" | \
    grep -o '"value":"[^"]*"' | \
    cut -d'"' -f4)

if [ -z "$ZABBIX_ADMIN_PASSWORD" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "❌ Erro: Não foi possível obter senhas do Vault"
    echo "ZABBIX_ADMIN_PASSWORD: ${ZABBIX_ADMIN_PASSWORD:+[DEFINIDA]}"
    echo "MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[DEFINIDA]}"
    exit 1
fi

echo "✅ Secrets obtidos com sucesso!"

# Salvar secrets como variáveis de ambiente para o Zabbix
mkdir -p /shared
echo "MYSQL_PASSWORD=${MYSQL_PASSWORD}" > /shared/zabbix-secrets.env
echo "ZABBIX_ADMIN_PASSWORD=${ZABBIX_ADMIN_PASSWORD}" >> /shared/zabbix-secrets.env
chmod 644 /shared/zabbix-secrets.env

echo "📁 Secrets salvos em /shared/zabbix-secrets.env"