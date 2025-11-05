#!/bin/bash

# ======================================
# SCRIPT DE INICIALIZAÇÃO DO VAULT
# Configura políticas e secrets iniciais
# ======================================

set -e

echo "🏦 Inicializando HashiCorp Vault..."

# Aguardar Vault estar pronto
echo "⏳ Aguardando Vault inicializar..."
until vault status >/dev/null 2>&1; do
    sleep 2
done

echo "✅ Vault está pronto!"

# Configurar cliente Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="${VAULT_ROOT_TOKEN:-vault-dev-root-token}"

# Verificar autenticação
vault auth -token="${VAULT_TOKEN}" >/dev/null 2>&1 || {
    echo "❌ Erro na autenticação com Vault"
    exit 1
}

echo "🔑 Criando políticas de acesso..."

# Criar políticas
vault policy write grafana-policy /vault/policies/grafana-policy.hcl
vault policy write zabbix-policy /vault/policies/zabbix-policy.hcl  
vault policy write mysql-policy /vault/policies/mysql-policy.hcl

echo "🔐 Configurando secrets iniciais..."

# Ativar KV secrets engine se não estiver ativo
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV engine já ativo"

# Secrets do MySQL
vault kv put secret/mysql/root-password value="${MYSQL_ROOT_PASSWORD}"
vault kv put secret/mysql/zabbix-password value="${MYSQL_PASSWORD}"

# Secrets do Zabbix
vault kv put secret/zabbix/admin-password value="${ZABBIX_ADMIN_PASSWORD}"
vault kv put secret/zabbix/database-password value="${MYSQL_PASSWORD}"

# Secrets do Grafana
vault kv put secret/grafana/admin-password value="${GRAFANA_ADMIN_PASSWORD}"

# Secrets do monitoramento
vault kv put secret/monitoring/mysql-exporter-password value="${MYSQL_PASSWORD}"

echo "🎫 Criando tokens de aplicação..."

# Criar tokens para cada serviço
GRAFANA_TOKEN=$(vault token create -policy=grafana-policy -ttl=72h -format=json | jq -r '.auth.client_token')
ZABBIX_TOKEN=$(vault token create -policy=zabbix-policy -ttl=72h -format=json | jq -r '.auth.client_token')
MYSQL_TOKEN=$(vault token create -policy=mysql-policy -ttl=72h -format=json | jq -r '.auth.client_token')

# Salvar tokens em arquivo
cat > /vault/config/service-tokens.env << EOF
GRAFANA_VAULT_TOKEN=${GRAFANA_TOKEN}
ZABBIX_VAULT_TOKEN=${ZABBIX_TOKEN}
MYSQL_VAULT_TOKEN=${MYSQL_TOKEN}
EOF

echo "📊 Habilitando auditoria..."
vault audit enable file file_path=/vault/data/audit.log 2>/dev/null || echo "Auditoria já habilitada"

echo "✅ Vault configurado com sucesso!"
echo "🌐 UI disponível em: http://localhost:8200"
echo "🔑 Root Token: ${VAULT_TOKEN}"
echo ""
echo "📋 Tokens de serviço criados:"
echo "   Grafana: ${GRAFANA_TOKEN}"
echo "   Zabbix:  ${ZABBIX_TOKEN}"
echo "   MySQL:   ${MYSQL_TOKEN}"
echo ""
echo "🔍 Comandos úteis:"
echo "   vault kv list secret/"
echo "   vault kv get secret/mysql/root-password"
echo "   vault audit list"