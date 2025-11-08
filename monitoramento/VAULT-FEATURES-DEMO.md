# 🔍 Vault Features - Demonstração Prática

## 📊 **1. Auditoria Completa (IMPLEMENTADO)**

### **Como Demonstrar:**

```bash
# 1. Verificar que auditoria está habilitada
docker exec development-vault vault audit list

# Saída esperada:
# Path     Type    Description
# ----     ----    -----------
# file/    file    n/a
```

### **Exemplos de Auditoria em Ação:**

```bash
# 2. Acessar um secret
docker exec development-vault vault kv get secret/mysql/root-password

# 3. Ver o log de auditoria (mostra QUEM, QUANDO, O QUÊ)
docker exec development-vault cat /vault/data/audit.log | tail -20
```

### **O que o Audit Log Registra:**

```json
{
  "time": "2024-11-08T10:30:45.123Z",
  "type": "response",
  "auth": {
    "token_type": "service",
    "display_name": "root"
  },
  "request": {
    "operation": "read",
    "path": "secret/data/mysql/root-password"
  },
  "response": {
    "data": {
      "data": "***sensitive***"
    }
  }
}
```

**Informações capturadas:**
- ✅ **Timestamp**: Quando o acesso ocorreu
- ✅ **Autenticação**: Qual token/usuário acessou
- ✅ **Operação**: Read, write, delete, list
- ✅ **Path**: Qual secret foi acessado
- ✅ **IP**: De onde veio a requisição

---

## 🔄 **2. Versionamento de Secrets (IMPLEMENTADO)**

### **Como Demonstrar:**

```bash
# 1. Ver versão atual de um secret
docker exec development-vault vault kv get secret/mysql/root-password

# Saída mostra:
# ====== Metadata ======
# Key              Value
# ---              -----
# created_time     2024-11-08T10:00:00.000Z
# deletion_time    n/a
# destroyed        false
# version          1

# 2. Atualizar o secret (criar nova versão)
docker exec development-vault vault kv put secret/mysql/root-password value="NovaSenha456!"

# 3. Ver histórico de versões
docker exec development-vault vault kv metadata get secret/mysql/root-password

# 4. Recuperar versão antiga
docker exec development-vault vault kv get -version=1 secret/mysql/root-password
```

### **Cenário de Apresentação:**

```bash
# Simular erro: senha alterada mas quebrou sistema
echo "1. Senha original funcionando..."
docker exec development-vault vault kv get secret/zabbix/admin-password

echo "2. Alguém alterou a senha (simulando erro)..."
docker exec development-vault vault kv put secret/zabbix/admin-password value="SenhaErrada123"

echo "3. Sistema quebrou! Recuperando versão anterior..."
docker exec development-vault vault kv get -version=1 secret/zabbix/admin-password

echo "4. Rollback da senha..."
OLD_PASS=$(docker exec development-vault vault kv get -version=1 -field=value secret/zabbix/admin-password)
docker exec development-vault vault kv put secret/zabbix/admin-password value="$OLD_PASS"

echo "✅ Sistema restaurado!"
```

---

## 🔐 **3. Políticas de Acesso (IMPLEMENTADO)**

### **Como Demonstrar:**

```bash
# Ver políticas criadas
docker exec development-vault vault policy list

# Saída:
# default
# grafana-policy
# mysql-policy
# root
# zabbix-policy

# Ver conteúdo da política do MySQL
docker exec development-vault vault policy read mysql-policy

# Saída:
# path "secret/data/mysql/*" {
#   capabilities = ["read", "list"]
# }
```

### **Teste de Segregação:**

```bash
# Criar token com política do MySQL (só acessa MySQL secrets)
MYSQL_TOKEN=$(docker exec development-vault vault token create -policy=mysql-policy -format=json | jq -r '.auth.client_token')

# Testar acesso permitido
docker exec -e VAULT_TOKEN=$MYSQL_TOKEN development-vault vault kv get secret/mysql/root-password
# ✅ Sucesso

# Testar acesso negado
docker exec -e VAULT_TOKEN=$MYSQL_TOKEN development-vault vault kv get secret/zabbix/admin-password
# ❌ Error: permission denied
```

---

## 🔄 **4. Rotação de Senhas (PARCIALMENTE IMPLEMENTADO)**

### **❌ O que NÃO está implementado (automático):**

```bash
# Rotação automática COM restart de containers
# Rotação agendada (cron/scheduled)
# Notificação de expiração de senhas
```

### **✅ O que ESTÁ disponível (manual com helper):**

```bash
# Script auxiliar para rotação manual
./generate-secure-passwords.sh rotate

# Opções:
# 1. Rotacionar senha do MySQL root
# 2. Rotacionar senha do Zabbix admin
# 3. Rotacionar senha do Grafana admin
# 4. Rotacionar todas as senhas
```

### **⚠️ Limitação Atual:**

**Rotação manual** porque:
1. Containers Docker Compose leem `.env` no startup
2. Alterar secret no Vault não propaga para container rodando
3. Requer restart do container para aplicar nova senha

### **🎯 Como seria em Produção (Level 5 - Kubernetes):**

```yaml
# External Secrets Operator (K8s)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: mysql-secret
spec:
  refreshInterval: 1h  # ← ROTAÇÃO AUTOMÁTICA A CADA 1 HORA
  secretStoreRef:
    name: vault-backend
  target:
    name: mysql-credentials
  data:
  - secretKey: password
    remoteRef:
      key: secret/mysql/root-password
```

**Fluxo automático:**
1. ✅ Vault gera nova senha a cada 1h
2. ✅ External Secrets sincroniza automaticamente
3. ✅ Pod recebe nova senha via volume mount
4. ✅ Aplicação relê credenciais sem restart

---

## 📊 **Resumo: O que está REALMENTE implementado**

| Recurso | Status | Como Demonstrar | Limitação Atual |
|---------|--------|-----------------|-----------------|
| **Auditoria Completa** | ✅ **100%** | `vault audit list` + ver logs | Nenhuma |
| **Versionamento** | ✅ **100%** | `vault kv get -version=N` | Nenhuma |
| **Políticas de Acesso** | ✅ **100%** | `vault policy read mysql-policy` | Nenhuma |
| **Criptografia AES-256** | ✅ **100%** | Vault encrypts at rest | Nenhuma (modo dev não persiste) |
| **Rotação Manual** | ✅ **Parcial** | Script `generate-secure-passwords.sh` | Requer restart de containers |
| **Rotação Automática** | ❌ **0%** | - | Docker Compose limitation |

---

## 🎬 **Script de Demonstração (5 minutos)**

```bash
#!/bin/bash
echo "=== DEMO: Vault Features Level 3 ==="
echo ""

echo "1️⃣ Auditoria Habilitada"
docker exec development-vault vault audit list
echo ""

echo "2️⃣ Secrets Armazenados"
docker exec development-vault vault kv list secret/
echo ""

echo "3️⃣ Detalhes de um Secret (com versionamento)"
docker exec development-vault vault kv get secret/mysql/root-password
echo ""

echo "4️⃣ Políticas de Acesso Configuradas"
docker exec development-vault vault policy list
echo ""

echo "5️⃣ Exemplo de Política (MySQL)"
docker exec development-vault vault policy read mysql-policy
echo ""

echo "6️⃣ Log de Auditoria (últimas 10 linhas)"
docker exec development-vault cat /vault/data/audit.log | tail -10 | jq -r '.request.path + " | " + .request.operation'
echo ""

echo "✅ Todos os recursos demonstrados!"
```

---

## 💡 **Para a Apresentação - Mensagens Honestas**

### **Slide 1: O que funciona 100%**
- ✅ Auditoria completa de acessos
- ✅ Versionamento automático de alterações
- ✅ Políticas de segregação de acesso
- ✅ Criptografia AES-256 em repouso

### **Slide 2: O que é preparação (vem no Level 5)**
- ⚠️ Rotação automática agendada
- ⚠️ Consumo direto do Vault (sem `.env`)
- ⚠️ Injeção dinâmica de secrets

### **Slide 3: Por que essa abordagem?**
- **Level 3**: Foundation - Estabelece infraestrutura Vault
- **Level 4**: AWS Secrets Manager integration
- **Level 5**: Kubernetes + External Secrets (verdadeira automação)

**Mensagem**: "Level 3 é a fundação. Você ganha auditoria e centralização AGORA. Automação completa vem no Level 5 com Kubernetes."
