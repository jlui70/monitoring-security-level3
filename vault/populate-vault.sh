#!/bin/bash

# Script para popular o Vault com os secrets para demonstração
echo "🔐 Populando Vault com secrets para demonstração..."

# Usar o token root do desenvolvimento
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="vault-dev-root-token"

# Aguardar o Vault estar pronto
sleep 5

# Habilitar KV v2 engine
echo "📋 Habilitando KV v2 engine..."
vault secrets enable -path=secret kv-v2

# Criar secrets do MySQL
echo "💾 Criando secrets do MySQL..."
vault kv put secret/mysql/database \
    username="zabbix" \
    password="zabbixpass" \
    root_password="rootpass" \
    database="zabbix"

# Criar secrets do Zabbix
echo "📊 Criando secrets do Zabbix..."
vault kv put secret/zabbix/server \
    admin_user="Admin" \
    admin_password="zabbix" \
    db_host="development-mysql-server"

# Criar secrets do Grafana
echo "📈 Criando secrets do Grafana..."
vault kv put secret/grafana/admin \
    username="admin" \
    password="admin" \
    api_key="grafana-api-key-example"

echo "✅ Vault populado com sucesso!"
echo ""
echo "🌐 Acesse o Vault em: http://172.28.224.90:8200"
echo "🔑 Token: vault-dev-root-token"