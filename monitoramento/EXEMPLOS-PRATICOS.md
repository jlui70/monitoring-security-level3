# Evolução da Segurança em Stack de Monitoramento

## 📊 **Stack Atual - Nível 1 (Base Funcional)**

### **Componentes Implementados:**
- ✅ **MySQL 8.3** - Banco de dados
- ✅ **Zabbix Server 7.0.5** - Servidor de monitoramento  
- ✅ **Zabbix Web** - Interface web
- ✅ **Zabbix Agent2** - Agente local
- ✅ **Grafana 12.0.2** - Visualização e dashboards
- ✅ **Prometheus latest** - Coleta de métricas time-series
- ✅ **Node Exporter** - Métricas do sistema operacional

### **Dashboards Funcionais:**
1. **Node Exporter Full** (ID: 1860) - Métricas do sistema via Prometheus
2. **Dashboards customizados Zabbix** - 115 itens coletados
3. **Prometheus Self-monitoring** - Métricas do próprio Prometheus

### **Configuração Atual (Nível 1 - Development Security):**
```bash
# .env - Senhas em texto claro (APENAS DESENVOLVIMENTO)
MYSQL_VERSION=8.3
MYSQL_DATABASE=zabbix
MYSQL_USER=zabbix
MYSQL_PASSWORD=zabbixpass
MYSQL_ROOT_PASSWORD=rootpass
ZABBIX_VERSION=alpine-7.0.5
GRAFANA_VERSION=12.0.2-security-01-ubuntu
PROMETHEUS_VERSION=latest
```

### **Estrutura do Projeto:**
```
monitoramento/
├── docker-compose.yml          # Orquestração dos containers
├── .env                        # Variáveis de ambiente (Nível 1)
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   ├── zabbix.yml      # Datasource Zabbix
│       │   └── prometheus.yml  # Datasource Prometheus
│       └── dashboards/
│           └── dashboards.yml  # Configuração de dashboards
└── prometheus/
    └── prometheus.yml          # Configuração de coleta
```

### **Serviços e Portas:**
| Serviço | Porta | URL | Credenciais |
|---------|-------|-----|-------------|
| Zabbix Web | 8080 | http://172.28.224.90:8080 | Admin/zabbix |
| Grafana | 3000 | http://172.28.224.90:3000 | admin/admin |
| Prometheus | 9090 | http://172.28.224.90:9090 | - |
| MySQL | 3306 | - | root/rootpass |

---

## � **Evolução de Segurança Planejada (5 Níveis)**

### **Nível 2: Environment Variables Isoladas**
**Status:** 📋 Próxima implementação
- Separação de credenciais por serviço
- Configuração por ambiente (dev/prod)
- Validação de variáveis obrigatórias

### **Nível 3: Docker Secrets**
**Status:** 📋 Planejado
- Migração para Docker Swarm mode
- Secrets em arquivos separados
- Rotação automática de senhas

### **Nível 4: HashiCorp Vault Integration**
**Status:** 📋 Planejado
- Vault como source of truth
- Dynamic secrets
- Audit logs completos

### **Nível 5: Production-Ready Security**
**Status:** 📋 Planejado
- mTLS entre serviços
- RBAC granular
- Monitoring de segurança

---

## 📈 **Monitoramento Implementado**

### **Métricas Zabbix (115 itens):**
- 📊 **Sistema:** CPU, Memória, Disco, Rede
- 🔌 **Conectividade:** ICMP Ping, Packet Loss, Response Time
- 📦 **Containers:** Status e health checks
- 🗃️ **MySQL:** Connections, queries, performance

### **Métricas Prometheus:**
- 🖥️ **Node Exporter:** Sistema operacional completo
- 📊 **Self-monitoring:** Prometheus interno
- 🎯 **Targets:** grafana:3000, node-exporter:9100

### **Integração Grafana:**
- 🔗 **Zabbix Plugin:** alexanderzobnin-zabbix-app
- 📊 **Dashboards:** Auto-provisioning
- 🔄 **Datasources:** Configuração automática

---

## 🛠️ **Comandos para Gestão**

### **Deploy Completo:**
```bash
# Navegue para o projeto
cd /home/luiz7/Projects/zabbix-grafana/containers/monitoramento

# Suba a stack completa
docker-compose up -d

# Verificar status
docker-compose ps

# Logs (se necessário)
docker-compose logs -f [serviço]
```

### **Acessos da Stack:**
```bash
# Zabbix Web Interface
echo "Zabbix: http://172.28.224.90:8080 (Admin/zabbix)"

# Grafana
echo "Grafana: http://172.28.224.90:3000 (admin/admin)"

# Prometheus
echo "Prometheus: http://172.28.224.90:9090"

# Node Exporter
echo "Node Exporter: http://172.28.224.90:9100"
```

### **Troubleshooting:**
```bash
# Restart específico
docker-compose restart [serviço]

# Rebuild se necessário
docker-compose build --no-cache [serviço]

# Limpar volumes (CUIDADO - perde dados)
docker-compose down -v
```

---

## 📝 **Notas do Projeto**

### **Configuração WSL2:**
- **IP WSL2:** 172.28.224.90 (acessível do Windows)
- **Network Mode:** Explicit port mapping (não host mode)
- **Volumes:** Persistência em /var/lib/docker/volumes/

### **Validações Realizadas:**
✅ Todos os serviços acessíveis via WSL2 IP  
✅ Zabbix coletando 115 métricas  
✅ Grafana exibindo dashboards Node Exporter e Zabbix  
✅ Prometheus coletando targets com sucesso  
✅ Datasources auto-provisionados funcionais  

### **Estado do Projeto:**
- **Nível Atual:** Desenvolvimento funcional (Nível 1)
- **Próximo Passo:** Implementar Nível 2 (Environment Variables Isoladas)
- **Baseline:** Stack completa pronta para evolução de segurança

---

*Documentação atualizada e stack validada para início do Nível 2*

```

```bash
# setup-secrets.sh
#!/bin/bash
echo "Setup Docker Swarm Secrets"

# Inicializar swarm se não existir
docker swarm init 2>/dev/null || true

# Criar secrets
openssl rand -base64 32 | docker secret create mysql_root_password -
openssl rand -base64 32 | docker secret create mysql_password -
openssl rand -base64 32 | docker secret create grafana_admin_password -

echo "Secrets criados com sucesso!"
docker stack deploy -c docker-compose.prod.yml zabbix-stack
```

### **Nível 3: HashiCorp Vault Integration**
```yaml
# docker-compose.vault.yml
version: '3.8'

services:
  vault:
    image: vault:latest
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: myroot
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    cap_add:
      - IPC_LOCK

  vault-init:
    image: vault:latest
    depends_on:
      - vault
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: myroot
    command: |
      sh -c "
        sleep 5
        vault kv put secret/zabbix/mysql root_password='$(openssl rand -base64 32)' password='$(openssl rand -base64 32)'
        vault kv put secret/zabbix/grafana admin_password='$(openssl rand -base64 32)'
        echo 'Secrets stored in Vault'
      "

  secret-fetcher:
    image: vault:latest
    depends_on:
      - vault-init
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: myroot
    volumes:
      - ./secrets:/secrets
    command: |
      sh -c "
        sleep 10
        vault kv get -field=root_password secret/zabbix/mysql > /secrets/mysql_root_password
        vault kv get -field=password secret/zabbix/mysql > /secrets/mysql_password
        vault kv get -field=admin_password secret/zabbix/grafana > /secrets/grafana_password
        chmod 600 /secrets/*
      "

  mysql:
    image: mysql:8.0
    depends_on:
      - secret-fetcher
    volumes:
      - ./secrets:/secrets:ro
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /secrets/mysql_root_password
      MYSQL_PASSWORD_FILE: /secrets/mysql_password
```

### **Nível 4: AWS Secrets Manager (Cloud)**
```python
# scripts/fetch_secrets.py
import boto3
import json
import os

def get_secret(secret_name):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name='us-east-1'
    )
    
    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        return None

# Buscar secrets e gerar .env
secrets = get_secret('prod/zabbix/database')
if secrets:
    with open('.env.prod', 'w') as f:
        f.write(f"MYSQL_ROOT_PASSWORD={secrets['root_password']}\n")
        f.write(f"MYSQL_PASSWORD={secrets['password']}\n")
        f.write(f"MYSQL_USER={secrets['username']}\n")
```

```bash
# deploy-aws.sh
#!/bin/bash
echo "Deploying with AWS Secrets Manager"

# Instalar dependências
pip install boto3

# Buscar secrets
python scripts/fetch_secrets.py

# Deploy
docker-compose --env-file .env.prod up -d

# Limpar arquivo temporário
rm .env.prod
```

### **Nível 5: Kubernetes + External Secrets**
```yaml
# k8s/secret-store.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-secret-store
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "zabbix-role"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: zabbix-secrets
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-secret-store
    kind: SecretStore
  target:
    name: zabbix-mysql-secret
    creationPolicy: Owner
  data:
  - secretKey: mysql-root-password
    remoteRef:
      key: zabbix/mysql
      property: root_password
  - secretKey: mysql-password
    remoteRef:
      key: zabbix/mysql
      property: password
```

```yaml
# k8s/mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: zabbix-mysql-secret
              key: mysql-root-password
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: zabbix-mysql-secret
              key: mysql-password
```

## 🎯 Rotação Automática de Secrets

### **Script de Rotação (Vault)**
```bash
#!/bin/bash
# rotate-secrets.sh

VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="myroot"

echo "Iniciando rotação de secrets..."

# Gerar novas senhas
NEW_ROOT_PASS=$(openssl rand -base64 32)
NEW_USER_PASS=$(openssl rand -base64 32)

# Atualizar no Vault
vault kv put secret/zabbix/mysql \
  root_password="$NEW_ROOT_PASS" \
  password="$NEW_USER_PASS"

# Atualizar MySQL
mysql -u root -p"$OLD_ROOT_PASS" -e "
  ALTER USER 'root'@'%' IDENTIFIED BY '$NEW_ROOT_PASS';
  ALTER USER 'zabbix'@'%' IDENTIFIED BY '$NEW_USER_PASS';
  FLUSH PRIVILEGES;
"

# Restart containers to pick up new secrets
docker-compose restart mysql zabbix-server zabbix-frontend

echo "Rotação concluída com sucesso!"
```

### **Automation com Cron**
```bash
# /etc/cron.d/rotate-zabbix-secrets
# Rodar todo domingo às 2h da manhã
0 2 * * 0 /opt/zabbix/scripts/rotate-secrets.sh >> /var/log/secret-rotation.log 2>&1
```

## 📊 Comparação de Soluções

| Solução | Complexidade | Segurança | Custo | Auditoria | Rotação |
|---------|--------------|-----------|-------|-----------|---------|
| .env | ⭐ | ⭐ | ⭐⭐⭐ | ❌ | ❌ |
| Env Vars | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ❌ | ⭐ |
| Docker Secrets | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| Vault | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| AWS Secrets | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| K8s + External | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 🚀 Migração Step-by-Step

### **Para sua entrevista, sugiro essa sequência:**

1. **"Comecei com .env para desenvolvimento local"** ✅
2. **"Migrei para environment variables em staging"** ✅
3. **"Implementei Docker Secrets para produção simples"** ✅
4. **"Evoluí para Vault quando precisamos de auditoria"** ✅
5. **"Automatizei rotação e integrei com CI/CD"** ✅

### **Script de Demonstração**
```bash
# demo-evolution.sh
echo "=== Demonstração de Evolução de Secrets ==="

echo "1. Desenvolvimento (.env)"
cat .env

echo -e "\n2. Produção (Environment Variables)"
export MYSQL_PASSWORD="$(openssl rand -base64 32)"
echo "Password: $MYSQL_PASSWORD"

echo -e "\n3. Enterprise (Vault)"
# Simulação de busca no Vault
echo "vault kv get secret/zabbix/mysql"
echo "password: xxxxxxxxxxx (encrypted)"

echo -e "\n4. Auditoria"
echo "2024-11-02 14:30:15 user:deploy accessed secret/zabbix/mysql"
```

Essa progressão mostra maturidade técnica e entendimento de trade-offs - exatamente o que recrutadores procuram! 🎯