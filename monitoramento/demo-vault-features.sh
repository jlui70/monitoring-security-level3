#!/bin/bash
# =============================================================================
# DEMO SCRIPT - Vault Features Level 3
# Demonstração de 5 minutos das funcionalidades realmente implementadas
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔐 VAULT LEVEL 3 - FEATURE DEMONSTRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar se Vault está rodando
if ! docker ps | grep -q development-vault; then
    echo -e "${RED}❌ Erro: Vault não está rodando${NC}"
    echo "Execute: cd monitoramento && ./setup.sh"
    exit 1
fi

sleep 1

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}1️⃣  AUDITORIA COMPLETA (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verificando se auditoria está habilitada..."
docker exec development-vault vault audit list
echo ""
echo -e "${GREEN}✓ Auditoria ativa: Todos os acessos são registrados${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}2️⃣  SECRETS ARMAZENADOS (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Listando estrutura de secrets..."
docker exec development-vault vault kv list secret/
echo ""
echo -e "${GREEN}✓ Todos os secrets centralizados no Vault${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}3️⃣  VERSIONAMENTO AUTOMÁTICO (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Consultando secret com metadata de versão..."
docker exec development-vault vault kv get secret/mysql/root-password
echo ""
echo -e "${GREEN}✓ Versionamento: Cada alteração cria nova versão automaticamente${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}4️⃣  HISTÓRICO DE VERSÕES (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Visualizando histórico completo de alterações..."
docker exec development-vault vault kv metadata get secret/mysql/root-password
echo ""
echo -e "${GREEN}✓ Histórico completo: Timestamps de criação e alterações${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}5️⃣  POLÍTICAS DE ACESSO (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Listando políticas configuradas..."
docker exec development-vault vault policy list
echo ""
echo "Detalhes da política do MySQL:"
docker exec development-vault vault policy read mysql-policy
echo ""
echo -e "${GREEN}✓ Segregação: Cada serviço acessa apenas seus próprios secrets${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}6️⃣  LOG DE AUDITORIA (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Últimas 5 operações registradas:"
echo ""
if command -v jq &> /dev/null; then
    docker exec development-vault cat /vault/data/audit.log | tail -5 | jq -r '. | "[\(.time)] \(.request.operation | ascii_upcase) \(.request.path)"' 2>/dev/null || {
        echo "Exibindo log bruto:"
        docker exec development-vault cat /vault/data/audit.log | tail -3
    }
else
    echo -e "${YELLOW}⚠️  Install 'jq' para visualização formatada${NC}"
    docker exec development-vault cat /vault/data/audit.log | tail -3 | grep -o '"operation":"[^"]*"' | head -5
fi
echo ""
echo -e "${GREEN}✓ Auditoria: Timestamp, usuário, operação, path registrados${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}7️⃣  TESTE DE ROLLBACK (✅ IMPLEMENTADO)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Simulando erro: Alguém mudou a senha do Grafana..."
OLD_VERSION=$(docker exec development-vault vault kv get -format=json secret/grafana/admin-password | jq -r '.data.metadata.version')
echo -e "Versão atual: ${YELLOW}$OLD_VERSION${NC}"

docker exec development-vault vault kv put secret/grafana/admin-password value="SenhaErrada123!" > /dev/null
echo -e "${RED}⚠️  Senha alterada para valor incorreto (versão $((OLD_VERSION + 1)))${NC}"
sleep 1

echo ""
echo "Recuperando versão anterior (rollback)..."
OLD_PASS=$(docker exec development-vault vault kv get -version=$OLD_VERSION -field=value secret/grafana/admin-password)
docker exec development-vault vault kv put secret/grafana/admin-password value="$OLD_PASS" > /dev/null
echo -e "${GREEN}✓ Senha restaurada para versão $OLD_VERSION${NC}"
echo ""
sleep 2

# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  ✅ DEMONSTRAÇÃO CONCLUÍDA${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 FEATURES DEMONSTRADAS:"
echo "  ✅ Auditoria completa de acessos"
echo "  ✅ Versionamento automático de alterações"
echo "  ✅ Histórico completo com timestamps"
echo "  ✅ Políticas de segregação de acesso"
echo "  ✅ Logs de auditoria (quem, quando, o quê)"
echo "  ✅ Rollback de versões anteriores"
echo ""
echo "⚠️  LIMITAÇÕES CONHECIDAS:"
echo "  ❌ Rotação automática agendada (requer Kubernetes - Level 5)"
echo "  ❌ Consumo direto do Vault (containers leem .env)"
echo "  ❌ Injeção dinâmica sem restart"
echo ""
echo "🌐 VAULT UI: http://localhost:8200"
echo "🔑 Token: vault-dev-root-token"
echo ""
echo "📖 Documentação completa: monitoramento/VAULT-FEATURES-DEMO.md"
echo ""
