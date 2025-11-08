#!/bin/sh

# ======================================
# SCRIPT DE INICIALIZAÇÃO DO VAULT
# Configura políticas e secrets iniciais
# ======================================

set -e

echo "🏦 Inicializando HashiCorp Vault..."

# Aguardar Vault estar pronto
echo "⏳ Aguardando Vault inicializar..."
sleep 5

# Verificar se Vault está respondendo
until vault status >/dev/null 2>&1; do
    echo "   Aguardando Vault..."
    sleep 2
done

echo "✅ Vault está pronto!"

# Configurar cliente Vault (já definido no container mas garantir)
export VAULT_ADDR="http://127.0.0.1:8200"

# Autenticar com root token (passado por variável de ambiente)
if [ -z "$VAULT_DEV_ROOT_TOKEN_ID" ]; then
    echo "❌ VAULT_DEV_ROOT_TOKEN_ID não definido"
    exit 1
fi

export VAULT_TOKEN="$VAULT_DEV_ROOT_TOKEN_ID"

echo "🔑 Criando políticas de acesso..."

# Criar políticas (se os arquivos existirem)
if [ -f /vault/policies/grafana-policy.hcl ]; then
    vault policy write grafana-policy /vault/policies/grafana-policy.hcl
fi

if [ -f /vault/policies/zabbix-policy.hcl ]; then
    vault policy write zabbix-policy /vault/policies/zabbix-policy.hcl
fi

if [ -f /vault/policies/mysql-policy.hcl ]; then
    vault policy write mysql-policy /vault/policies/mysql-policy.hcl
fi

echo "🔐 Configurando secrets iniciais..."

# Ativar KV secrets engine v2 se não estiver ativo
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "   KV engine já ativo"

# Buscar senhas das variáveis de ambiente do host (passadas via docker-compose)
# Como estamos em dev mode, usar valores padrão se não estiverem definidos

MYSQL_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-Dev_Root_Vault_2024!@}"
MYSQL_USER_PASS="${MYSQL_PASSWORD:-Dev_Zabbix_Vault_2024!@}"
ZABBIX_ADMIN_PASS="${ZABBIX_ADMIN_PASSWORD:-V@ultSecur3P@ss2024!}"
GRAFANA_ADMIN_PASS="${GF_SECURITY_ADMIN_PASSWORD:-Dev_Grafana_Vault_2024!@}"
MYSQL_EXP_PASS="${MYSQL_EXPORTER_PASSWORD:-Dev_Exporter_Vault_2024!@}"

# Secrets do MySQL
vault kv put secret/mysql/root-password value="$MYSQL_ROOT_PASS"
vault kv put secret/mysql/zabbix-password value="$MYSQL_USER_PASS"

# Secrets do Zabbix
vault kv put secret/zabbix/admin-password value="$ZABBIX_ADMIN_PASS"
vault kv put secret/zabbix/database-password value="$MYSQL_USER_PASS"

# Secrets do Grafana
vault kv put secret/grafana/admin-password value="$GRAFANA_ADMIN_PASS"

# Secrets do monitoramento
vault kv put secret/monitoring/mysql-exporter-password value="$MYSQL_EXP_PASS"

echo "📊 Habilitando auditoria..."
vault audit enable file file_path=/vault/data/audit.log 2>/dev/null || echo "   Auditoria já habilitada"

echo "✅ Vault configurado com sucesso!"
echo "🌐 UI disponível em: http://localhost:8200"
echo "🔑 Root Token: $VAULT_TOKEN"
echo ""
echo "🔍 Comandos úteis:"
echo "   vault kv list secret/"
echo "   vault kv get secret/mysql/root-password"
echo "   vault audit list"