#!/bin/bash

# 🚀 Setup script para Monitoring Security Level 3
# HashiCorp Vault + Secrets Management

set -e

echo "🔐 Monitoring Security Evolution - Level 3 Setup"
echo "================================================"
echo "HashiCorp Vault + Secrets Management"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logs coloridos
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    log_success "Docker encontrado: $(docker --version)"
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
        exit 1
    fi
    log_success "Docker Compose encontrado: $(docker-compose --version)"
    
    # Docker rodando
    if ! docker ps &> /dev/null; then
        log_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
    log_success "Docker está rodando"
    
    # Arquivo .env
    if [ ! -f .env ]; then
        log_error "Arquivo .env não encontrado!"
        log_error "Execute primeiro: generate-secure-passwords.sh e apply-passwords.sh"
        exit 1
    fi
    log_success "Arquivo .env encontrado"
}

# Verificar portas disponíveis
check_ports() {
    log_info "Verificando portas necessárias..."
    
    local ports=(3000 8080 8200 9090 9100 9104 3306)
    for port in "${ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            log_error "Porta $port já está em uso"
            exit 1
        else
            log_success "Porta $port disponível"
        fi
    done
}

# Inicializar stack
start_stack() {
    log_info "Iniciando setup da stack de monitoramento com Vault..."
    
    # Criar networks
    log_info "Criando networks Docker..."
    docker network create monitoring-network 2>/dev/null || log_warning "Network monitoring-network já existe"
    
    # Parar containers existentes se houver
    log_info "Parando containers existentes..."
    docker-compose down 2>/dev/null || true
    
    # Subir a stack
    log_info "Subindo a stack completa..."
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        log_success "Stack iniciada com sucesso!"
    else
        log_error "Erro ao iniciar a stack"
        exit 1
    fi
    
    # Garantir que containers Zabbix iniciem (workaround para depends_on)
    log_info "Verificando containers do Zabbix..."
    sleep 5
    
    # Verificar se containers Zabbix foram criados mas não iniciados
    local zabbix_created=$(docker-compose ps -a | grep -c "zabbix" || echo "0")
    local zabbix_running=$(docker-compose ps | grep -c "zabbix" || echo "0")
    
    if [ "$zabbix_created" -gt 0 ] && [ "$zabbix_running" -eq 0 ]; then
        log_warning "Containers Zabbix criados mas não iniciados - aplicando workaround..."
        docker-compose up -d zabbix-server zabbix-web zabbix-agent2
        log_success "Containers Zabbix iniciados manualmente"
    elif [ "$zabbix_running" -gt 0 ]; then
        log_success "Containers Zabbix já estão rodando"
    fi
}

# Aguardar Vault estar pronto
wait_for_vault() {
    log_info "Aguardando HashiCorp Vault inicializar..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        if curl -s --max-time 5 http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
            log_success "Vault está pronto!"
            return 0
        fi
        
        log_info "Aguardando Vault... (tentativa $attempt/$max_attempts)"
        sleep 10
    done
    
    log_error "Vault não ficou pronto em 5 minutos"
    return 1
}

# Inicializar e popular Vault
setup_vault() {
    log_info "Configurando HashiCorp Vault..."
    
    # Aguardar Vault estar pronto
    if ! wait_for_vault; then
        log_error "Falha ao aguardar Vault"
        exit 1
    fi
    
    # Carregar variáveis de ambiente do .env
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    fi
    
    # Executar script de inicialização do Vault
    log_info "Inicializando Vault com políticas e secrets..."
    docker exec -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
                -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
                -e ZABBIX_ADMIN_PASSWORD="${ZABBIX_ADMIN_PASSWORD}" \
                -e GF_SECURITY_ADMIN_PASSWORD="${GF_SECURITY_ADMIN_PASSWORD}" \
                -e MYSQL_EXPORTER_PASSWORD="${MYSQL_EXPORTER_PASSWORD}" \
                ${ENVIRONMENT:-development}-vault /bin/sh /vault/scripts/init-vault.sh || {
        log_warning "Script init-vault.sh falhou ou não foi encontrado"
        log_info "Vault está rodando mas sem secrets inicializados"
        log_info "Você pode configurar manualmente via UI em http://localhost:8200"
    }
    
    log_success "Vault configurado!"
}

# Aguardar MySQL estar pronto
wait_for_mysql() {
    log_info "Aguardando MySQL..."
    sleep 30
}

# Aguardar Zabbix criar tabelas
wait_for_zabbix() {
    log_info "Aguardando Zabbix iniciar criação do banco de dados..."
    
    local max_wait=30
    local attempt=0
    local creation_started=false
    
    while [ $attempt -lt $max_wait ]; do
        attempt=$((attempt + 1))
        
        local server_logs=$(docker logs development-zabbix-server 2>/dev/null || echo "")
        
        if echo "$server_logs" | grep -qE "Creating 'zabbix' user|Creating 'zabbix' schema|Database 'zabbix' already exists"; then
            log_success "Zabbix iniciou criação do banco de dados!"
            creation_started=true
            break
        fi
        
        if echo "$server_logs" | grep -q "MySQL server is not available"; then
            if [ $attempt -le 6 ]; then
                log_info "Aguardando MySQL ficar disponível... ($attempt/30)"
            elif [ $attempt -le 18 ]; then
                log_info "MySQL ainda inicializando... ($attempt/30)"
            else
                log_warning "MySQL demorando mais que o esperado... ($attempt/30)"
            fi
        else
            log_info "Verificando status do Zabbix... ($attempt/30)"
        fi
        
        if [ $attempt -eq 30 ]; then
            log_error "Zabbix não iniciou criação do banco após 5 minutos"
            log_error "Possível causa: volumes persistentes com senhas antigas"
            log_error "Solução: Execute 'docker-compose down -v' e tente novamente"
            return 1
        fi
        
        sleep 10
    done
    
    if [ "$creation_started" = false ]; then
        log_error "Falha ao detectar início da criação do banco Zabbix"
        return 1
    fi
    
    log_info "Aguardando criação completa das tabelas (6 minutos)..."
    log_info "Isso é normal - Zabbix cria mais de 150 tabelas no primeiro boot"
    sleep 360
    
    log_success "Zabbix inicialização concluída - aguardou 6 minutos para criação das tabelas"
    log_info "Zabbix estará totalmente operacional em alguns minutos"
    return 0
}

# Aguardar serviços
wait_for_services() {
    log_info "Aguardando serviços ficarem prontos..."
    
    wait_for_mysql
    
    if ! wait_for_zabbix; then
        log_error "Falha na inicialização do Zabbix - Abortando setup"
        exit 1
    fi
    
    log_info "Aguardando Grafana..."
    sleep 20
    
    log_success "Primeira fase de inicialização concluída"
}

# Validar serviços
validate_services() {
    log_info "Validando serviços..."
    
    log_info "Status dos containers:"
    docker-compose ps
    
    log_info "Testando endpoints..."
    
    # Vault
    if curl -s http://localhost:8200/v1/sys/health >/dev/null 2>&1; then
        log_success "Vault está respondendo"
    else
        log_warning "Vault pode não estar pronto ainda"
    fi
    
    # Grafana
    if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
        log_success "Grafana está respondendo"
    else
        log_warning "Grafana pode não estar pronto ainda"
    fi
    
    # Prometheus
    if curl -s http://localhost:9090/api/v1/status/config >/dev/null 2>&1; then
        log_success "Prometheus está respondendo"
    else
        log_warning "Prometheus pode não estar pronto ainda"
    fi
    
    # Zabbix
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        log_success "Zabbix está respondendo"
    else
        log_warning "Zabbix pode não estar pronto ainda"
    fi
}

# Mostrar informações de acesso
show_access_info() {
    # Obter credenciais do .env
    GRAFANA_USER="${GF_SECURITY_ADMIN_USER:-admin}"
    GRAFANA_PASS="${GF_SECURITY_ADMIN_PASSWORD:-admin}"
    
    echo ""
    echo "🎉 Setup concluído! Acesse os serviços:"
    echo "========================================"
    echo ""
    echo "🏦 HashiCorp Vault:"
    echo "   URL: http://localhost:8200"
    echo "   Token: vault-dev-root-token"
    echo ""
    echo "🌐 Zabbix Web Interface:"
    echo "   URL: http://localhost:8080"
    echo "   User: Admin"
    echo "   Password: zabbix"
    echo ""
    echo "📊 Grafana:"
    echo "   URL: http://localhost:3000"
    echo "   User: ${GRAFANA_USER}"
    echo "   Password: ${GRAFANA_PASS}"
    echo ""
    echo "⚡ Prometheus:"
    echo "   URL: http://localhost:9090"
    echo ""
    echo "📈 Node Exporter:"
    echo "   URL: http://localhost:9100"
    echo ""
    echo "🗄️ MySQL Exporter:"
    echo "   URL: http://localhost:9104"
    echo ""
    echo "💡 Comandos úteis do Vault:"
    echo "   docker exec -it ${ENVIRONMENT:-development}-vault vault kv list secret/"
    echo "   docker exec -it ${ENVIRONMENT:-development}-vault vault kv get secret/mysql/root-password"
    echo ""
    echo "💡 Dicas:"
    echo "   - Aguarde 2-3 minutos para todos os serviços estarem 100% operacionais"
    echo "   - Use 'docker-compose logs -f [serviço]' para debug"
    echo "   - Use 'docker-compose down' para parar tudo"
    echo "   - Use 'docker-compose down -v' para limpar volumes"
}

# Função de help
show_help() {
    echo "🔐 Monitoring Security Evolution - Level 3"
    echo "=========================================="
    echo "HashiCorp Vault + Secrets Management"
    echo ""
    echo "Uso: ./setup.sh [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  (sem parâmetro)  Instalação completa"
    echo "  start            Iniciar stack existente"
    echo "  stop             Parar stack"
    echo "  restart          Reiniciar stack"
    echo "  status           Ver status containers"
    echo "  logs             Ver logs em tempo real"
    echo "  vault-ui         Abrir Vault UI no navegador"
    echo "  clean            Remover tudo (CUIDADO!)"
    echo "  help             Este help"
    echo ""
}

# Função principal
main() {
    case "${1:-}" in
        "")
            check_prerequisites
            check_ports
            start_stack
            setup_vault
            wait_for_services
            validate_services
            
            # Configurações adicionais após inicialização
            log_info "Executando configurações adicionais..."
            
            # Configurar Zabbix automaticamente
            log_info "Configurando Zabbix (templates e DNS)..."
            ./configure-zabbix.sh
            
            # Importar dashboards do Grafana
            log_info "Importando dashboards para Grafana..."
            ./import-dashboards.sh
            
            show_access_info
            ;;
        "start")
            log_info "Iniciando stack existente..."
            docker-compose up -d
            log_success "Stack iniciada!"
            ;;
        "stop")
            log_info "Parando stack..."
            docker-compose down
            log_success "Stack parada!"
            ;;
        "restart")
            log_info "Reiniciando stack..."
            docker-compose restart
            log_success "Stack reiniciada!"
            ;;
        "status")
            log_info "Status dos containers:"
            docker-compose ps
            ;;
        "logs")
            log_info "Logs em tempo real (Ctrl+C para sair):"
            docker-compose logs -f
            ;;
        "vault-ui")
            log_info "Abrindo Vault UI no navegador..."
            xdg-open http://localhost:8200 2>/dev/null || open http://localhost:8200 2>/dev/null || echo "Abra manualmente: http://localhost:8200"
            ;;
        "clean")
            log_warning "⚠️  ATENÇÃO: Isso vai remover TODOS os dados!"
            read -p "Tem certeza? Digite 'yes' para confirmar: " confirm
            if [ "$confirm" = "yes" ]; then
                log_info "Removendo stack e dados..."
                docker-compose down -v
                log_info "Removendo volumes órfãos e cache..."
                docker volume prune -f
                docker network prune -f
                log_success "Limpeza concluída!"
                log_info "Para instalação limpa, execute: ./setup.sh"
            else
                log_info "Operação cancelada."
            fi
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Comando não reconhecido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
