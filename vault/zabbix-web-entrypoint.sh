#!/bin/bash

# ======================================
# ENTRYPOINT PERSONALIZADO PARA ZABBIX WEB
# Carrega senhas do Vault antes de iniciar
# ======================================

set -e

echo "🌐 Zabbix Web: Carregando senhas do Vault..."

# Verificar se arquivo de secrets existe
if [ ! -f /shared/zabbix-secrets.env ]; then
    echo "❌ Erro: Arquivo de secrets do Zabbix não encontrado"
    exit 1
fi

# Carregar secrets
source /shared/zabbix-secrets.env

# Verificar se senhas foram carregadas
if [ -z "$MYSQL_PASSWORD" ]; then
    echo "❌ Erro: Senha do MySQL não foi carregada"
    exit 1
fi

echo "✅ Senhas carregadas do Vault com sucesso!"
echo "🔐 MySQL Password: ${MYSQL_PASSWORD:0:8}..."

# Exportar variáveis para o processo atual e subprocessos
export MYSQL_PASSWORD
export MYSQL_DATABASE
export MYSQL_USER
export DB_SERVER_HOST="development-mysql-server"
export ZBX_SERVER_HOST="development-zabbix-server"
export PHP_TZ
export TZ

echo "🌐 Iniciando Zabbix Web Interface..."

# Executar entrypoint original do Zabbix Web
exec docker-entrypoint.sh "$@"