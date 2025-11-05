#!/bin/bash#!/bin/bash

# generate-secure-passwords.sh - Gerador de senhas seguras com integração Vault# generate-secure-passwords.sh - Gerador de senhas seguras para diferentes ambientes



set -eset -e



# Cores para output# Cores para output

RED='\033[0;31m'RED='\033[0;31m'

GREEN='\033[0;32m'GREEN='\033[0;32m'

YELLOW='\033[1;33m'YELLOW='\033[1;33m'

BLUE='\033[0;34m'BLUE='\033[0;34m'

NC='\033[0m'NC='\033[0m'



print_header() {print_header() {

    echo -e "${BLUE}🔐 ===============================================${NC}"    echo -e "${BLUE}🔐 ===============================================${NC}"

    echo -e "${BLUE}$1${NC}"    echo -e "${BLUE}$1${NC}"

    echo -e "${BLUE}🔐 ===============================================${NC}"    echo -e "${BLUE}🔐 ===============================================${NC}"

}}



print_success() {print_success() {

    echo -e "${GREEN}✅ $1${NC}"    echo -e "${GREEN}✅ $1${NC}"

}}



print_warning() {print_warning() {

    echo -e "${YELLOW}⚠️  $1${NC}"    echo -e "${YELLOW}⚠️  $1${NC}"

}}



print_error() {# Função para gerar senha segura

    echo -e "${RED}❌ $1${NC}"generate_password() {

}    local environment=$1

    local service=$2

# Verificar se Vault está rodando    local length=16

check_vault() {    

    if ! docker ps | grep -q "development-vault"; then    case $environment in

        print_error "Vault não está rodando!"        "dev")

        echo "Execute: ./setup.sh start"            # Desenvolvimento - senhas mais simples mas seguras

        exit 1            length=12

    fi            prefix="Dev"

}            suffix="2024!@"

            ;;

# Função para gerar senha segura        "staging")

generate_password() {            # Staging - senhas médias

    local service=$1            length=16

    local length=16            prefix="Stg"

                suffix="2024#$"

    # Gerar senha complexa            ;;

    password=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-${length})        "prod")

    echo "${service}_${password}_Vault_2024!@"            # Produção - senhas complexas

}            length=20

            prefix="Prod"

# Função para adicionar/atualizar secret no Vault            suffix="2024!@#$"

vault_put_secret() {            ;;

    local path=$1    esac

    local value=$2    

        # Gerar parte aleatória

    docker exec -it development-vault vault kv put "secret/${path}" value="${value}" > /dev/null 2>&1    random_part=$(openssl rand -base64 $((length-${#prefix}-${#suffix})) | tr -d "=+/" | cut -c1-$((length-${#prefix}-${#suffix})))

        

    if [ $? -eq 0 ]; then    # Combinar partes

        print_success "Secret atualizado: secret/${path}"    password="${prefix}_${service}_${random_part}_${suffix}"

    else    

        print_error "Erro ao atualizar secret: secret/${path}"    echo "$password"

        return 1}

    fi

}# Função para gerar todas as senhas de um ambiente

generate_environment_passwords() {

# Função para gerar e armazenar todas as senhas no Vault    local env=$1

generate_and_store_vault_passwords() {    local output_file=$2

    print_header "GERANDO SENHAS SEGURAS PARA VAULT"    

        print_header "GERANDO SENHAS PARA AMBIENTE: $env"

    check_vault    

        # Timestamp

    echo ""    timestamp=$(date '+%Y%m%d_%H%M%S')

    echo "📋 Gerando senhas..."    

        # Gerar senhas

    # Gerar senhas    mysql_password=$(generate_password "$env" "Zabbix")

    mysql_root_password=$(generate_password "Root")    mysql_root_password=$(generate_password "$env" "Root") 

    mysql_zabbix_password=$(generate_password "Zabbix")    mysql_exporter_password=$(generate_password "$env" "Exporter")

    mysql_exporter_password=$(generate_password "Exporter")    grafana_admin_password=$(generate_password "$env" "Admin")

        

    zabbix_admin_password=$(generate_password "Admin")    # Criar arquivo temporário com senhas

    zabbix_db_password=$(generate_password "Database")    cat > "$output_file" << EOF

    zabbix_server_password=$(generate_password "Server")# ===================================

    # SENHAS GERADAS AUTOMATICAMENTE

    grafana_admin_password=$(generate_password "Admin")# ===================================

    grafana_db_password=$(generate_password "Database")# Ambiente: $env

    # Timestamp: $timestamp

    prometheus_password=$(generate_password "Prometheus")# ATENÇÃO: Mantenha este arquivo seguro!

    

    echo ""# MySQL Passwords

    echo "🏦 Armazenando no Vault..."MYSQL_PASSWORD=$mysql_password

    MYSQL_ROOT_PASSWORD=$mysql_root_password

    # Armazenar MySQLMYSQL_EXPORTER_PASSWORD=$mysql_exporter_password

    vault_put_secret "mysql/root-password" "$mysql_root_password"

    vault_put_secret "mysql/zabbix-password" "$mysql_zabbix_password"# Grafana Passwords  

    vault_put_secret "mysql/exporter-password" "$mysql_exporter_password"GF_SECURITY_ADMIN_PASSWORD=$grafana_admin_password

    

    # Armazenar Zabbix# Informações de Segurança

    vault_put_secret "zabbix/admin-password" "$zabbix_admin_password"GENERATED_AT=$timestamp

    vault_put_secret "zabbix/database-password" "$zabbix_db_password"PASSWORD_ROTATION_NEEDED_AT=$(date -d "+90 days" '+%Y%m%d')

    vault_put_secret "zabbix/server-password" "$zabbix_server_password"ENVIRONMENT=$env

    EOF

    # Armazenar Grafana

    vault_put_secret "grafana/admin-password" "$grafana_admin_password"    print_success "Senhas geradas em: $output_file"

    vault_put_secret "grafana/database-password" "$grafana_db_password"    print_warning "Lembre-se de rotacionar senhas em 90 dias"

        

    # Armazenar Monitoring    echo ""

    vault_put_secret "monitoring/prometheus-password" "$prometheus_password"    echo "📋 Senhas geradas:"

        echo "  MySQL User: $mysql_password"

    echo ""    echo "  MySQL Root: $mysql_root_password" 

    print_success "Todas as senhas foram atualizadas no Vault!"    echo "  MySQL Exporter: $mysql_exporter_password"

        echo "  Grafana Admin: $grafana_admin_password"

    # Criar arquivo de backup (apenas para emergência)}

    backup_file="./password-backups/vault-passwords-backup-$(date '+%Y%m%d_%H%M%S').txt"

    mkdir -p ./password-backups# Função para rotacionar senhas existentes

    rotate_passwords() {

    cat > "$backup_file" << EOF    local env_file=$1

# ===================================    local backup_dir="./password-backups"

# BACKUP DE SENHAS DO VAULT    

# ===================================    print_header "ROTACIONANDO SENHAS: $env_file"

# Timestamp: $(date '+%Y-%m-%d %H:%M:%S')    

# ATENÇÃO: Este é um backup de emergência. Use sempre o Vault!    # Criar diretório de backup

    mkdir -p "$backup_dir"

# MySQL Passwords    

MYSQL_ROOT_PASSWORD=$mysql_root_password    # Backup do arquivo atual

MYSQL_ZABBIX_PASSWORD=$mysql_zabbix_password    backup_file="$backup_dir/$(basename $env_file).backup.$(date '+%Y%m%d_%H%M%S')"

MYSQL_EXPORTER_PASSWORD=$mysql_exporter_password    cp "$env_file" "$backup_file"

    print_success "Backup criado: $backup_file"

# Zabbix Passwords    

ZABBIX_ADMIN_PASSWORD=$zabbix_admin_password    # Extrair ambiente atual

ZABBIX_DB_PASSWORD=$zabbix_db_password    current_env=$(grep "ENVIRONMENT=" "$env_file" | cut -d'=' -f2)

ZABBIX_SERVER_PASSWORD=$zabbix_server_password    

    # Gerar novas senhas

# Grafana Passwords    temp_passwords="/tmp/new_passwords_$(date '+%Y%m%d_%H%M%S').env"

GRAFANA_ADMIN_PASSWORD=$grafana_admin_password    generate_environment_passwords "$current_env" "$temp_passwords"

GRAFANA_DB_PASSWORD=$grafana_db_password    

    # Atualizar arquivo original (mantendo outras configurações)

# Monitoring Passwords    # Substituir apenas as linhas de senha

PROMETHEUS_PASSWORD=$prometheus_password    while IFS='=' read -r key value; do

        if [[ $key =~ ^(MYSQL_PASSWORD|MYSQL_ROOT_PASSWORD|MYSQL_EXPORTER_PASSWORD|GF_SECURITY_ADMIN_PASSWORD)$ ]]; then

# Vault Access            sed -i "s/^$key=.*/$key=$value/" "$env_file"

VAULT_URL=http://localhost:8200            print_success "Atualizada: $key"

VAULT_ROOT_TOKEN=vault-dev-root-token        fi

    done < "$temp_passwords"

# Rotação Recomendada    

ROTATION_NEEDED_AT=$(date -d "+90 days" '+%Y-%m-%d')    # Limpar arquivo temporário

EOF    rm "$temp_passwords"

    

    print_warning "Backup criado em: $backup_file"    print_warning "IMPORTANTE: Reinicie os serviços para aplicar novas senhas!"

    print_warning "IMPORTANTE: Reinicie os serviços para aplicar novas senhas!"    print_warning "docker-compose down && docker-compose up -d"

    echo ""}

    echo "Execute: docker-compose down && docker-compose up -d"

}# Função para verificar idade das senhas

check_password_age() {

# Função para listar todos os secrets do Vault    local env_file=$1

list_vault_secrets() {    

    print_header "LISTANDO SECRETS DO VAULT"    if [ ! -f "$env_file" ]; then

            print_warning "Arquivo não encontrado: $env_file"

    check_vault        return 1

        fi

    echo ""    

    echo "📋 Secrets no Vault:"    if grep -q "GENERATED_AT=" "$env_file"; then

    echo ""        generated_date=$(grep "GENERATED_AT=" "$env_file" | cut -d'=' -f2)

            rotation_date=$(grep "PASSWORD_ROTATION_NEEDED_AT=" "$env_file" | cut -d'=' -f2)

    for path in mysql zabbix grafana monitoring; do        current_date=$(date '+%Y%m%d')

        echo -e "${BLUE}📁 secret/$path/${NC}"        

        docker exec -it development-vault vault kv list "secret/$path/" 2>/dev/null | tail -n +3 | sed 's/^/  ├─ /'        if [ "$current_date" -gt "$rotation_date" ]; then

        echo ""            print_warning "Senhas precisam ser rotacionadas! (geradas em: $generated_date)"

    done            return 1

}        else

            print_success "Senhas ainda válidas (geradas em: $generated_date, rotação em: $rotation_date)"

# Função para mostrar um secret específico            return 0

show_vault_secret() {        fi

    local path=$1    else

            print_warning "Arquivo não contém informações de geração automática"

    if [ -z "$path" ]; then        return 1

        print_error "Especifique o caminho do secret (ex: mysql/root-password)"    fi

        return 1}

    fi

    # Menu principal

    check_vaultshow_menu() {

        echo "🔐 Gerador de Senhas Seguras - Nível 2"

    echo ""    echo "======================================"

    echo -e "${BLUE}🔐 Secret: secret/$path${NC}"    echo "1. Gerar senhas para Development"

    docker exec -it development-vault vault kv get "secret/$path"    echo "2. Gerar senhas para Staging"  

}    echo "3. Gerar senhas para Production"

    echo "4. Rotacionar senhas existentes"

# Função para rotacionar uma senha específica    echo "5. Verificar idade das senhas"

rotate_specific_password() {    echo "6. Sair"

    local path=$1    echo ""

    }

    if [ -z "$path" ]; then

        print_error "Especifique o caminho do secret (ex: mysql/root-password)"# Programa principal

        return 1if [ $# -eq 0 ]; then

    fi    while true; do

            show_menu

    check_vault        read -p "Escolha uma opção: " choice

            

    # Extrair service name do path        case $choice in

    service_name=$(echo "$path" | sed 's/.*\///' | sed 's/-password//')            1)

                    generate_environment_passwords "dev" "./environments/.env.dev.passwords"

    # Gerar nova senha                ;;

    new_password=$(generate_password "$service_name")            2)

                    generate_environment_passwords "staging" "./environments/.env.staging.passwords"

    # Atualizar no Vault                ;;

    vault_put_secret "$path" "$new_password"            3)

                    generate_environment_passwords "prod" "./environments/.env.prod.passwords"

    print_success "Senha rotacionada para: secret/$path"                ;;

    print_warning "Nova senha: $new_password"            4)

}                read -p "Arquivo .env para rotacionar: " env_file

                rotate_passwords "$env_file"

# Função para verificar saúde do Vault                ;;

check_vault_health() {            5)

    print_header "VERIFICANDO SAÚDE DO VAULT"                read -p "Arquivo .env para verificar: " env_file

                    check_password_age "$env_file"

    if ! docker ps | grep -q "development-vault"; then                ;;

        print_error "Vault não está rodando!"            6)

        return 1                echo "Saindo..."

    fi                exit 0

                    ;;

    echo ""            *)

    echo "🏥 Status do Vault:"                print_warning "Opção inválida!"

    docker exec -it development-vault vault status                ;;

            esac

    echo ""        

    echo "📊 Auditoria:"        echo ""

    docker exec -it development-vault vault audit list        read -p "Pressione ENTER para continuar..."

}        clear

    done

# Menu principalelse

show_menu() {    # Modo comando direto

    echo "🔐 Gerador de Senhas Seguras - Nível 3 (Vault)"    case $1 in

    echo "============================================="        "generate")

    echo "1. Gerar e armazenar todas as senhas no Vault"            generate_environment_passwords "$2" "$3"

    echo "2. Listar todos os secrets do Vault"            ;;

    echo "3. Mostrar secret específico"        "rotate")

    echo "4. Rotacionar senha específica"            rotate_passwords "$2"

    echo "5. Verificar saúde do Vault"            ;;

    echo "6. Sair"        "check")

    echo ""            check_password_age "$2"

}            ;;

        *)

# Programa principal            echo "Uso: $0 [generate|rotate|check] [ambiente|arquivo] [arquivo_saida]"

if [ $# -eq 0 ]; then            exit 1

    while true; do            ;;

        show_menu    esac

        read -p "Escolha uma opção: " choicefi
        
        case $choice in
            1)
                generate_and_store_vault_passwords
                ;;
            2)
                list_vault_secrets
                ;;
            3)
                read -p "Caminho do secret (ex: mysql/root-password): " path
                show_vault_secret "$path"
                ;;
            4)
                read -p "Caminho do secret (ex: mysql/root-password): " path
                rotate_specific_password "$path"
                ;;
            5)
                check_vault_health
                ;;
            6)
                echo "Saindo..."
                exit 0
                ;;
            *)
                print_warning "Opção inválida!"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
        clear
    done
else
    # Modo comando direto
    case $1 in
        "generate")
            generate_and_store_vault_passwords
            ;;
        "list")
            list_vault_secrets
            ;;
        "show")
            show_vault_secret "$2"
            ;;
        "rotate")
            rotate_specific_password "$2"
            ;;
        "health")
            check_vault_health
            ;;
        *)
            echo "Uso: $0 [generate|list|show|rotate|health] [secret-path]"
            echo ""
            echo "Exemplos:"
            echo "  $0 generate              # Gerar todas as senhas"
            echo "  $0 list                  # Listar todos os secrets"
            echo "  $0 show mysql/root-password  # Mostrar secret específico"
            echo "  $0 rotate mysql/root-password  # Rotacionar senha"
            echo "  $0 health                # Verificar saúde do Vault"
            exit 1
            ;;
    esac
fi
