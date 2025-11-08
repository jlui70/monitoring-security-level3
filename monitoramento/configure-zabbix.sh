#!/bin/bash

# 🔧 Script de configuração automática do Zabbix
# Configura o host Zabbix server para usar DNS em vez de IP

echo "🔧 Configurando Zabbix Host automaticamente..."

# Aguardar Zabbix estar disponível
echo "⏳ Aguardando Zabbix estar disponível..."
until curl -s http://localhost:8080/api_jsonrpc.php >/dev/null 2>&1; do
    echo "   Aguardando Zabbix..."
    sleep 5
done

echo "✅ Zabbix disponível!"

# Fazer login e obter auth token
echo "🔑 Fazendo login no Zabbix API..."

AUTH_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
            "username": "Admin",
            "password": "zabbix"
        },
        "id": 1
    }')

# Extrair token de forma mais robusta
AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$AUTH_TOKEN" ]; then
    echo "❌ Erro ao fazer login no Zabbix API"
    echo "Resposta: $AUTH_RESPONSE"
    exit 1
fi

echo "✅ Login realizado com sucesso!"

# Carregar senha do Vault do .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep 'ZABBIX_ADMIN_PASSWORD' | xargs)
fi

# Alterar senha do usuário Admin para a senha do Vault
echo "🔐 Alterando senha do Admin para senha do Vault..."

# Primeiro, buscar o userid do Admin
USER_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "user.get",
        "params": {
            "output": ["userid", "username"],
            "filter": {
                "username": "Admin"
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 2
    }')

ADMIN_USERID=$(echo "$USER_RESPONSE" | grep -o '"userid":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$ADMIN_USERID" ]; then
    echo "⚠️  Não foi possível encontrar userid do Admin"
else
    # Alterar a senha (precisa fornecer senha atual)
    PASSWD_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
        -H "Content-Type: application/json" \
        -d '{
            "jsonrpc": "2.0",
            "method": "user.update",
            "params": {
                "userid": "'$ADMIN_USERID'",
                "current_passwd": "zabbix",
                "passwd": "'"${ZABBIX_ADMIN_PASSWORD:-V@ultSecur3P@ss2024!}"'"
            },
            "auth": "'$AUTH_TOKEN'",
            "id": 3
        }')
    
    if echo "$PASSWD_RESPONSE" | grep -q '"result"'; then
        echo "✅ Senha do Admin alterada para a senha do Vault!"
        echo "   Nova senha: ${ZABBIX_ADMIN_PASSWORD:-V@ultSecur3P@ss2024!}"
        
        # Fazer re-login com a nova senha
        echo "🔄 Fazendo re-login com a nova senha..."
        AUTH_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
            -H "Content-Type: application/json" \
            -d '{
                "jsonrpc": "2.0",
                "method": "user.login",
                "params": {
                    "username": "Admin",
                    "password": "'"${ZABBIX_ADMIN_PASSWORD:-V@ultSecur3P@ss2024!}"'"
                },
                "id": 10
            }')
        
        AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$AUTH_TOKEN" ]; then
            echo "❌ Erro ao fazer re-login"
            exit 1
        fi
        echo "✅ Re-login realizado com sucesso!"
    else
        echo "⚠️  Falha ao alterar senha do Admin"
        echo "   Resposta: $PASSWD_RESPONSE"
    fi
fi

# Buscar o host "Zabbix server"
echo "🔍 Buscando host 'Zabbix server'..."

HOST_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "host.get",
        "params": {
            "filter": {
                "host": ["Zabbix server"]
            },
            "selectInterfaces": "extend"
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 2
    }')

# Extrair hostid
HOST_ID=$(echo "$HOST_RESPONSE" | grep -o '"hostid":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$HOST_ID" ]; then
    echo "❌ Host 'Zabbix server' não encontrado"
    echo "Resposta: $HOST_RESPONSE"
    exit 1
fi

echo "✅ Host encontrado! ID: $HOST_ID"

# Extrair interface ID
INTERFACE_ID=$(echo "$HOST_RESPONSE" | grep -o '"interfaceid":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$INTERFACE_ID" ]; then
    echo "❌ Interface não encontrada"
    exit 1
fi

echo "🔧 Atualizando interface para usar DNS..."

# Atualizar interface para usar DNS
UPDATE_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hostinterface.update",
        "params": {
            "interfaceid": "'$INTERFACE_ID'",
            "useip": 0,
            "dns": "development-zabbix-agent2"
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 3
    }')

# Verificar resultado da atualização da interface
if echo "$UPDATE_RESPONSE" | grep -q '"result"'; then
    echo "✅ Interface atualizada com sucesso!"
    echo "🎯 Host 'Zabbix server' agora usa DNS: development-zabbix-agent2"
else
    echo "❌ Erro ao atualizar interface"
    echo "Resposta: $UPDATE_RESPONSE"
    exit 1
fi

# Buscar templates necessários
echo "🔍 Buscando templates necessários..."

# Template ICMP Ping
TEMPLATE_ICMP_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
            "filter": {
                "host": ["ICMP Ping"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 4
    }')

TEMPLATE_ICMP_ID=$(echo "$TEMPLATE_ICMP_RESPONSE" | grep -o '"templateid":"[^"]*"' | head -1 | cut -d'"' -f4)

# Template Zabbix server health
TEMPLATE_HEALTH_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
            "filter": {
                "host": ["Zabbix server health"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 5
    }')

TEMPLATE_HEALTH_ID=$(echo "$TEMPLATE_HEALTH_RESPONSE" | grep -o '"templateid":"[^"]*"' | head -1 | cut -d'"' -f4)

# Template Linux by Zabbix agent active
TEMPLATE_LINUX_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "template.get",
        "params": {
            "filter": {
                "host": ["Linux by Zabbix agent active"]
            }
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 6
    }')

TEMPLATE_LINUX_ID=$(echo "$TEMPLATE_LINUX_RESPONSE" | grep -o '"templateid":"[^"]*"' | head -1 | cut -d'"' -f4)

# Verificar se todos os templates foram encontrados
if [ -z "$TEMPLATE_ICMP_ID" ]; then
    echo "❌ Template 'ICMP Ping' não encontrado"
    exit 1
fi

if [ -z "$TEMPLATE_HEALTH_ID" ]; then
    echo "❌ Template 'Zabbix server health' não encontrado"
    exit 1
fi

if [ -z "$TEMPLATE_LINUX_ID" ]; then
    echo "❌ Template 'Linux by Zabbix agent active' não encontrado"
    exit 1
fi

echo "✅ Templates encontrados:"
echo "   • ICMP Ping (ID: $TEMPLATE_ICMP_ID)"
echo "   • Zabbix server health (ID: $TEMPLATE_HEALTH_ID)"
echo "   • Linux by Zabbix agent active (ID: $TEMPLATE_LINUX_ID)"

# Aplicar todos os templates ao host
echo "📋 Aplicando todos os templates ao host 'Zabbix server'..."

LINK_RESPONSE=$(curl -s -X POST http://localhost:8080/api_jsonrpc.php \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "host.update",
        "params": {
            "hostid": "'$HOST_ID'",
            "templates": [
                {
                    "templateid": "'$TEMPLATE_ICMP_ID'"
                },
                {
                    "templateid": "'$TEMPLATE_HEALTH_ID'"
                },
                {
                    "templateid": "'$TEMPLATE_LINUX_ID'"
                }
            ]
        },
        "auth": "'$AUTH_TOKEN'",
        "id": 7
    }')

# Verificar resultado da aplicação dos templates
if echo "$LINK_RESPONSE" | grep -q '"result"'; then
    echo "✅ Todos os templates aplicados com sucesso!"
    echo "📊 Templates ativos no host 'Zabbix server':"
    echo "   • ICMP Ping (conectividade)"
    echo "   • Zabbix server health (saúde do servidor)"
    echo "   • Linux by Zabbix agent active (métricas do sistema)"
else
    echo "❌ Erro ao aplicar templates"
    echo "Resposta: $LINK_RESPONSE"
    exit 1
fi

echo ""
echo "🎉 Configuração completa!"
echo "📋 Verificar em: Configuration → Hosts → Zabbix server"
echo "   Interface: Agent development-zabbix-agent2 Connect to DNS"
echo "   Templates aplicados:"
echo "   • ICMP Ping (conectividade)"
echo "   • Zabbix server health (saúde do servidor)"  
echo "   • Linux by Zabbix agent active (métricas do sistema)"
echo ""
echo "📊 Dashboards Grafana agora terão dados completos:"
echo "   • Ping, latência e perda de pacotes"
echo "   • Métricas de saúde do Zabbix"
echo "   • Métricas completas do sistema Linux"
