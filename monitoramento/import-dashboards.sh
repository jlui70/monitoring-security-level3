#!/bin/bash

# 📊 Script de importação de dashboards para Grafana
# Importa dashboards iniciais mas deixa eles editáveis (não provisionados)

# Carregar variáveis de ambiente
if [ -f .env ]; then
    source .env
fi

# Definir credenciais do Grafana
GRAFANA_USER="${GF_SECURITY_ADMIN_USER:-admin}"
GRAFANA_PASS="${GF_SECURITY_ADMIN_PASSWORD:-admin}"

echo "📊 Importando dashboards iniciais para o Grafana..."

# Aguardar Grafana estar disponível
echo "⏳ Aguardando Grafana estar disponível..."
until curl -s http://localhost:3000/api/health >/dev/null 2>&1; do
    echo "   Aguardando Grafana..."
    sleep 5
done

echo "✅ Grafana disponível!"

# Configurar datasources se necessário
echo "🔗 Configurando datasources..."

# Verificar se Prometheus já existe
PROMETHEUS_EXISTS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:3000/api/datasources/name/Prometheus 2>/dev/null | grep -o '"name":"Prometheus"' || echo "")

if [ -z "$PROMETHEUS_EXISTS" ]; then
    echo "📈 Adicionando datasource Prometheus..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        http://localhost:3000/api/datasources \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://development-prometheus:9090",
            "access": "proxy",
            "isDefault": false
        }' >/dev/null
    echo "✅ Prometheus adicionado!"
else
    echo "✅ Prometheus já configurado!"
fi

# Verificar se Zabbix já existe
ZABBIX_EXISTS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:3000/api/datasources/name/Zabbix 2>/dev/null | grep -o '"name":"Zabbix"' || echo "")

if [ -z "$ZABBIX_EXISTS" ]; then
    echo "🎯 Adicionando datasource Zabbix..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        http://localhost:3000/api/datasources \
        -d '{
            "name": "Zabbix",
            "type": "alexanderzobnin-zabbix-datasource",
            "url": "http://development-zabbix-web:8080/api_jsonrpc.php",
            "access": "proxy",
            "isDefault": true,
            "jsonData": {
                "username": "Admin",
                "trends": true,
                "trendsFrom": "7d",
                "cacheTTL": "1h",
                "timeout": 60
            },
            "secureJsonData": {
                "password": "zabbix"
            }
        }' >/dev/null
    echo "✅ Zabbix adicionado!"
else
    echo "✅ Zabbix já configurado!"
fi

# Importar dashboards
echo "📋 Importando dashboards..."

DASHBOARD_DIR="./grafana/dashboards"

if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "⚠️  Pasta de dashboards não encontrada: $DASHBOARD_DIR"
    echo "📝 Nenhum dashboard para importar"
    exit 0
fi

for dashboard_file in "$DASHBOARD_DIR"/*.json; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name=$(basename "$dashboard_file" .json)
        echo "📊 Importando dashboard: $dashboard_name"
        
        # Descobrir UID do datasource Zabbix
        ZABBIX_UID=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "http://localhost:3000/api/datasources" | grep -o '"uid":"[^"]*"[^}]*"type":"alexanderzobnin-zabbix-datasource"' | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
        
        if [ -z "$ZABBIX_UID" ]; then
            echo "⚠️  Não foi possível descobrir UID do datasource Zabbix, usando dashboard original"
            dashboard_content=$(cat "$dashboard_file")
        else
            echo "   UID Zabbix detectado: $ZABBIX_UID"
            # Substituir UID hardcoded pelo UID real e remover id/uid do dashboard
            dashboard_content=$(cat "$dashboard_file" | sed "s/PA67C5EADE9207728/$ZABBIX_UID/g" | sed 's/"id":[0-9]*,//g; s/"uid":"[^"]*",//g')
        fi
        
        # Criar payload temporário para evitar "Argument list too long"
        temp_payload="/tmp/dashboard_payload_$$.json"
        echo "{" > "$temp_payload"
        echo "\"dashboard\": $dashboard_content," >> "$temp_payload"
        echo "\"overwrite\": true" >> "$temp_payload"
        echo "}" >> "$temp_payload"
        
        # Importar dashboard usando arquivo temporário
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASS" \
            http://localhost:3000/api/dashboards/db \
            -d @"$temp_payload" >/dev/null
        
        # Limpar arquivo temporário
        rm -f "$temp_payload"
        
        echo "✅ Dashboard $dashboard_name importado!"
    fi
done

echo ""
echo "🎉 Configuração completa!"
echo "📊 Dashboards importados e totalmente editáveis!"
echo "🔗 Acesse: http://localhost:3000 (${GRAFANA_USER}/<senha-configurada>)"
echo ""
echo "💡 Agora você pode:"
echo "   • Editar dashboards livremente"
echo "   • Salvar modificações permanentemente"
echo "   • Criar novos dashboards"
echo "   • Duplicar e personalizar existentes"
