#!/bin/bash
# validate-environment.sh - Valida variáveis obrigatórias antes do deploy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🔍 ===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}🔍 ===============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Variáveis obrigatórias por categoria
REQUIRED_MYSQL_VARS=(
    "MYSQL_VERSION"
    "MYSQL_DATABASE"
    "MYSQL_USER"
    "MYSQL_PASSWORD"
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_EXPORTER_USER"
    "MYSQL_EXPORTER_PASSWORD"
)

REQUIRED_ZABBIX_VARS=(
    "ZABBIX_VERSION"
    "DB_SERVER_HOST"
    "ZBX_SERVER_HOST"
    "PHP_TZ"
    "TZ"
)

REQUIRED_GRAFANA_VARS=(
    "GRAFANA_VERSION"
    "GF_SECURITY_ADMIN_USER"
    "GF_SECURITY_ADMIN_PASSWORD"
)

REQUIRED_ENV_VARS=(
    "ENVIRONMENT"
)

# Função para validar se variável existe e não está vazia
validate_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        print_error "Variável obrigatória não definida: $var_name"
        return 1
    else
        print_success "✓ $var_name definida"
        return 0
    fi
}

# Função para validar força da senha
validate_password_strength() {
    local var_name=$1
    local password=${!var_name}
    local min_length=12
    
    if [ ${#password} -lt $min_length ]; then
        print_error "Senha $var_name muito curta (mínimo $min_length caracteres)"
        return 1
    fi
    
    # Verificar se tem pelo menos maiúscula, minúscula, número e símbolo
    if [[ ! $password =~ [A-Z] ]] || [[ ! $password =~ [a-z] ]] || [[ ! $password =~ [0-9] ]] || [[ ! $password =~ [^A-Za-z0-9] ]]; then
        print_warning "Senha $var_name pode ser mais segura (usar maiúsculas, minúsculas, números e símbolos)"
    else
        print_success "✓ $var_name atende critérios de segurança"
    fi
    
    return 0
}

# Função principal de validação
validate_environment() {
    local env_file=$1
    local errors=0
    
    print_header "VALIDANDO ARQUIVO: $env_file"
    
    # Carregar variáveis do arquivo
    if [ ! -f "$env_file" ]; then
        print_error "Arquivo não encontrado: $env_file"
        return 1
    fi
    
    # Source do arquivo (com precaução)
    set -a  # Export all variables
    source "$env_file"
    set +a
    
    echo "📋 Validando variáveis obrigatórias..."
    
    # Validar variáveis de ambiente
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        validate_var "$var" || ((errors++))
    done
    
    # Validar MySQL
    echo ""
    echo "🗄️  Validando configuração MySQL..."
    for var in "${REQUIRED_MYSQL_VARS[@]}"; do
        validate_var "$var" || ((errors++))
    done
    
    # Validar Zabbix  
    echo ""
    echo "📊 Validando configuração Zabbix..."
    for var in "${REQUIRED_ZABBIX_VARS[@]}"; do
        validate_var "$var" || ((errors++))
    done
    
    # Validar Grafana
    echo ""
    echo "📈 Validando configuração Grafana..."
    for var in "${REQUIRED_GRAFANA_VARS[@]}"; do
        validate_var "$var" || ((errors++))
    done
    
    # Validar força das senhas
    echo ""
    echo "🔐 Validando força das senhas..."
    validate_password_strength "MYSQL_PASSWORD"
    validate_password_strength "MYSQL_ROOT_PASSWORD"
    validate_password_strength "MYSQL_EXPORTER_PASSWORD"
    validate_password_strength "GF_SECURITY_ADMIN_PASSWORD"
    
    # Validações específicas por ambiente
    echo ""
    echo "🎯 Validando configurações específicas do ambiente..."
    
    case "$ENVIRONMENT" in
        "development")
            print_success "✓ Configuração para ambiente de desenvolvimento"
            if [ "$ENABLE_DEBUG_LOGS" != "true" ]; then
                print_warning "Debug logs desabilitados em desenvolvimento"
            fi
            ;;
        "staging")
            print_success "✓ Configuração para ambiente de homologação"
            if [ "$ENABLE_DEBUG_LOGS" = "true" ]; then
                print_warning "Debug logs habilitados em staging"
            fi
            ;;
        "production")
            print_success "✓ Configuração para ambiente de produção"
            if [ "$ENABLE_DEBUG_LOGS" = "true" ]; then
                print_error "Debug logs não devem estar habilitados em produção"
                ((errors++))
            fi
            if [ "$DISABLE_SSL_VERIFICATION" = "true" ]; then
                print_error "SSL verification não deve estar desabilitada em produção"
                ((errors++))
            fi
            ;;
        *)
            print_error "Ambiente desconhecido: $ENVIRONMENT"
            ((errors++))
            ;;
    esac
    
    # Resultado final
    echo ""
    if [ $errors -eq 0 ]; then
        print_header "✅ VALIDAÇÃO CONCLUÍDA COM SUCESSO"
        print_success "Ambiente $ENVIRONMENT está pronto para deploy!"
        return 0
    else
        print_header "❌ VALIDAÇÃO FALHOU"
        print_error "Encontrados $errors erros. Corrija antes de continuar."
        return 1
    fi
}

# Uso do script
if [ $# -eq 0 ]; then
    echo "❌ Uso: $0 <arquivo-env>"
    echo "📋 Exemplos:"
    echo "  $0 environments/.env.dev"
    echo "  $0 environments/.env.staging"
    echo "  $0 environments/.env.prod"
    exit 1
fi

validate_environment "$1"