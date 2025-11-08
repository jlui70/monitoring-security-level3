#!/bin/bash
# Script para verificar se o Zabbix terminou de criar o schema

# Carregar variáveis do .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

CONTAINER_NAME="${ENVIRONMENT:-development}-zabbix-server"

echo "🔍 Verificando schema do Zabbix..."

# Conta tabelas no banco zabbix
TABLE_COUNT=$(docker exec development-mysql-server mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema='zabbix';" -sN 2>/dev/null)

if [ -z "$TABLE_COUNT" ]; then
    echo "❌ Não foi possível conectar ao MySQL ou banco 'zabbix' não existe ainda"
    exit 1
fi

echo "📊 Tabelas encontradas: $TABLE_COUNT"

# Zabbix 7.0 tem cerca de 180-200 tabelas
if [ "$TABLE_COUNT" -ge 180 ]; then
    echo "✅ Schema do Zabbix completo! ($TABLE_COUNT tabelas)"
    echo "✅ Pronto para executar configure-zabbix.sh e import-dashboards.sh"
    exit 0
else
    echo "⏳ Schema ainda sendo criado... ($TABLE_COUNT/~190 tabelas)"
    echo "💡 Execute este script novamente em alguns minutos"
    exit 2
fi
