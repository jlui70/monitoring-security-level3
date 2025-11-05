#!/bin/bash

# ======================================
# ENTRYPOINT PERSONALIZADO PARA MYSQL
# Carrega senhas do Vault antes de iniciar
# ======================================

set -e

echo "🔑 MySQL: Carregando senhas do Vault..."

# Verificar se arquivo de secrets existe
if [ ! -f /shared/mysql-secrets.env ]; then
    echo "❌ Erro: Arquivo de secrets não encontrado"
    exit 1
fi

# Carregar secrets
source /shared/mysql-secrets.env

# Verificar se senhas foram carregadas
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "❌ Erro: Senhas não foram carregadas corretamente"
    echo "MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:+[DEFINIDA]}"
    echo "MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[DEFINIDA]}"
    exit 1
fi

echo "✅ Senhas carregadas do Vault com sucesso!"
echo "🔐 Root Password: ${MYSQL_ROOT_PASSWORD:0:8}..."
echo "🔐 Zabbix Password: ${MYSQL_PASSWORD:0:8}..."

# Exportar variáveis para o processo atual e subprocessos
export MYSQL_ROOT_PASSWORD
export MYSQL_PASSWORD
export MYSQL_DATABASE
export MYSQL_USER
export MYSQL_INITDB_SKIP_TZINFO

# Executar entrypoint original do MySQL
exec docker-entrypoint.sh "$@"