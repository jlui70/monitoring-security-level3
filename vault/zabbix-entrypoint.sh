#!/bin/bash

# ======================================
# ENTRYPOINT PERSONALIZADO PARA ZABBIX SERVER
# Carrega senhas do Vault antes de iniciar
# ======================================

set -e

echo "🔑 Zabbix Server: Carregando senhas do Vault..."

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
export MYSQL_ROOT_PASSWORD

# Definir variáveis padrão do Zabbix se não estiverem definidas
export ZBX_STARTPOLLERS="${ZBX_STARTPOLLERS:-5}"
export ZBX_STARTPINGERS="${ZBX_STARTPINGERS:-1}"
export ZBX_STARTUNREACHABLE="${ZBX_STARTUNREACHABLE:-1}"
export ZBX_STARTSNMPPOLLERS="${ZBX_STARTSNMPPOLLERS:-1}"
export ZBX_STARTTRAPPERS="${ZBX_STARTTRAPPERS:-5}"
export ZBX_STARTDBSYNCERS="${ZBX_STARTDBSYNCERS:-4}"
export ZBX_TIMEOUT="${ZBX_TIMEOUT:-4}"
export ZBX_VALUECACHESIZE="${ZBX_VALUECACHESIZE:-8M}"
export ZBX_HISTORYCACHESIZE="${ZBX_HISTORYCACHESIZE:-16M}"
export ZBX_HISTORYINDEXCACHESIZE="${ZBX_HISTORYINDEXCACHESIZE:-4M}"
export ZBX_CACHESIZE="${ZBX_CACHESIZE:-8M}"
export ZBX_TRENDCACHESIZE="${ZBX_TRENDCACHESIZE:-4M}"
export TZ="${TZ:-UTC}"

echo "🚀 Iniciando Zabbix Server..."

# Executar entrypoint original do Zabbix
exec docker-entrypoint.sh "$@"