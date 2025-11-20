# 🔐 Monitoring Security Evolution - Nível 3: Vault Foundation
## Stack de Monitoramento com Zabbix, Grafana e Prometheus + HashiCorp Vault

![Security Level](https://img.shields.io/badge/Security%20Level-3%20Vault%20Foundation-yellow)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![Vault](https://img.shields.io/badge/HashiCorp-Vault-black)
![Status](https://img.shields.io/badge/Status-Production%20Ready-green)
> 🎯 **Posição na Série**: Este é o **Level 3 de 5** na evolução de segurança  
> 📈 **Próximo**: Level 4 (AWS Secrets Manager) → Level 5 (Kubernetes + External Secrets Operator)

---

## ⚠️ **Importante: Estado Atual da Integração Vault**

**O que este nível REALMENTE oferece:**

✅ **Vault configurado e funcional**
- Todos os secrets armazenados com **criptografia AES-256**
- **Auditoria completa** de todos os acessos aos secrets
- **Versionamento** de alterações de senhas
- **Políticas de acesso** granulares por serviço
- **Fundação sólida** para evolução futura

⚠️ **Limitação técnica (Docker Compose)**
- Containers ainda **leem senhas do `.env`** para compatibilidade
- `.env` necessário para inicialização dos containers
- **Não é consumo direto** do Vault (isso vem no Level 5)

**Por quê?**  
Docker Compose requer variáveis de ambiente no `docker-compose up`. Consumo direto do Vault requer:
- **Vault Agent** ou entrypoint scripts customizados (complexo em Docker Compose)
- **Kubernetes + External Secrets Operator** (implementado no Level 5)

**Benefícios REAIS mesmo com `.env`:**
1. 📊 **Auditoria**: Rastreamos QUEM acessou QUAL secret QUANDO
2. 🔐 **Centralização**: Vault é a fonte única de verdade
3. 🔄 **Versionamento**: Histórico de todas as alterações
4. 🎯 **Preparação**: Infraestrutura pronta para Level 5 (K8s + Vault)
5. 🛡️ **Segregação**: Políticas de acesso já configuradas

---
## 🎯 **Evolução da Série (5 Níveis COMPLETOS)**

| Nível                                                               | Foco | Secrets Storage | Onde Containers Leem | Orquestração | Status |
|---------------------------------------------------------------------|------|-----------------|----------------------|--------------|--------|
| **[Level 1](https://github.com/jlui70/monitoring-security-level1)** | Baseline | Hardcoded | Código fonte | Docker Compose | ✅ |
| **[Level 2](https://github.com/jlui70/monitoring-security-level2)** | Env Vars | `.env` files | `.env` | Docker Compose | ✅ |
| **[Level 3](https://github.com/jlui70/monitoring-security-level3)** | Vault Foundation | Vault + `.env` | `.env` | Docker Compose | **✅ VOCÊ ESTÁ AQUI** |
| **[Level 4](https://github.com/jlui70/monitoring-security-level4)** | AWS Cloud | AWS Secrets Manager | AWS API | Terraform + EC2 | ✅ |
| **[Level 5](https://github.com/jlui70/monitoring-security-level5)** | **K8s + Vault** | **Vault (KV v2)** | **Kubernetes Secrets** | **Kubernetes** | ✅ |

## 🎯 **Evolução da Série (5 Níveis COMPLETOS)**

<table>
<thead>
<tr>
<th style="min-width: 100px;">Nível</th>
<th>Foco</th>
<th>Secrets Storage</th>
<th>Onde Containers Leem</th>
<th>Orquestração</th>
<th>Status</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Level&nbsp;1</strong></td>
<td>Baseline</td>
<td>Hardcoded</td>
<td>Código fonte</td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;2</strong></td>
<td>Env Vars</td>
<td><code>.env</code> files</td>
<td><code>.env</code></td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;3</strong></td>
<td>Vault Foundation</td>
<td>Vault + <code>.env</code></td>
<td><code>.env</code></td>
<td>Docker Compose</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;4</strong></td>
<td>AWS Cloud</td>
<td>AWS Secrets Manager</td>
<td>AWS API</td>
<td>Terraform + EC2</td>
<td>✅</td>
</tr>
<tr>
<td><strong>Level&nbsp;5</strong></td>
<td><strong>K8s + Vault</strong></td>
<td><strong>Vault (KV v2)</strong></td>
<td><strong>Kubernetes Secrets</strong></td>
<td><strong>Kubernetes</strong></td>
<td><strong>✅ VOCÊ ESTÁ AQUI</strong></td>
</tr>
</tbody>
</table>

---

## 🚀 **Quick Start (2 comandos)**

```bash
# 1. Clone
git clone https://github.com/jlui70/monitoring-security-level3.git
cd monitoring-security-level3

# 2. Deploy
cd monitoramento && ./setup.sh
```

**Pronto!** Aguarde 8-10 minutos e acesse:
- **Vault UI**: http://localhost:8200 (Token: `vault-dev-root-token`)
- **Zabbix**: http://localhost:8080 (Consulte `monitoramento/CREDENTIALS.md`)
- **Grafana**: http://localhost:3000 (Consulte `monitoramento/CREDENTIALS.md`)

> 📄 **Senhas de acesso**: Consulte `monitoramento/CREDENTIALS.md` para credenciais atuais

### **🎬 Demo Rápida (5 minutos):**

```bash
# Demonstrar features do Vault implementadas
cd monitoramento && ./demo-vault-features.sh
```

**O script demonstra:**
- ✅ Auditoria habilitada e funcionando
- ✅ Versionamento automático de secrets
- ✅ Políticas de acesso segregadas
- ✅ Logs de auditoria com timestamps
- ✅ Rollback de versões anteriores

> 📖 **Explicações detalhadas**: Consulte `monitoramento/VAULT-FEATURES-DEMO.md`

---

## 🔧 **Setup Manual** (mesmo processo, passo a passo)

```bash
# 1. Verificar arquivo .env
cat .env  # Verificar se configurações estão OK

# 2. Deploy
cd monitoramento && ./setup.sh
```

---

## 🧹 **Limpeza (se não for primeira instalação)**

**⚠️ IMPORTANTE**: Se você já executou esta stack antes, limpe dados antigos:

```bash
# Pare e remova dados antigos
cd monitoramento && docker-compose down -v

# Reinstalação limpa
cd .. && git pull origin main
cd monitoramento && ./setup.sh
```

**💡 Por que limpar?** Volumes Docker persistem dados do MySQL/Vault com senhas antigas, causando conflitos.

---

## ⚙️ **Notas Técnicas (Primeira Instalação)**

### **MySQL Healthcheck:**
O MySQL pode levar até **3 minutos** para inicializar na primeira vez (criação do schema Zabbix). O healthcheck aguarda até **210 segundos** antes de considerar o container healthy.

**Comportamento normal:**
```bash
# Verificar status
docker-compose ps

# MySQL aparecerá como "starting" ou "health: starting"
# Aguarde até aparecer "healthy" antes que o Zabbix inicie
```

### **Startup Automático do Zabbix:**
O `setup.sh` inclui workaround que detecta se o Zabbix não iniciou automaticamente e corrige:
```bash
# O script verifica após docker-compose up
# Se Zabbix não estiver "Up", executa:
docker-compose up -d zabbix-server zabbix-web zabbix-agent2
```

**💡 Isso é transparente** - o `setup.sh` cuida de tudo automaticamente.

---

## 📊 **O que você ganha no Level 3?**

### **✅ Vault Foundation (Preparação para Produção):**
- 🏦 **HashiCorp Vault Configurado** - Servidor Vault rodando e integrado
- � **Secrets Criptografados** - AES-256 no armazenamento
- 📊 **Auditoria Habilitada** - Log de todos os acessos aos secrets
- 🔄 **Versionamento de Secrets** - Histórico de alterações
- 🛡️ **Políticas de Acesso** - Segregação por serviço (MySQL, Zabbix, Grafana)
- 🎯 **Infraestrutura Pronta** - Base para Level 5 (K8s + External Secrets)

### **⚠️ O que AINDA NÃO faz (vem no Level 5):**
- ❌ Consumo direto do Vault pelos containers (ainda leem do `.env`)
- ❌ Eliminação completa do arquivo `.env` (necessário para Docker Compose)
- ❌ Injeção dinâmica de secrets via Vault Agent

**Benefício REAL agora**: Auditoria + Centralização + Fundação para produção  
**Benefício COMPLETO**: Level 5 (Kubernetes + External Secrets Operator)

### **✅ Herda Tudo do Level 2:**
- 🌍 **Ambientes Separados** - Dev, Staging, Production
- ✅ **Validação Automática** - Configurações verificadas
- 🔐 **Senhas Complexas** - Geradas automaticamente

### **✅ Herda Tudo do Level 1:**
- 📊 **Stack Completa**: Zabbix 7.0.5 + Grafana 12.0.2 + Prometheus
- 🖥️ **Monitoramento Sistema**: CPU, RAM, Disk, Network
- 🗄️ **Monitoramento MySQL**: Performance e métricas avançadas
- 📈 **Dashboards Prontos**: 2 dashboards funcionais

---

## 🏦 **Gerenciando Secrets no Vault**

### **Comandos Úteis:**

```bash
# Listar todos os secrets
docker exec -it development-vault vault kv list secret/

# Ver secret específico
docker exec -it development-vault vault kv get secret/mysql/root-password

# Atualizar secret (cria nova versão automaticamente)
docker exec -it development-vault vault kv put secret/mysql/root-password value="NovaSenha123!"

# Ver histórico de versões (auditoria de mudanças)
docker exec -it development-vault vault kv metadata get secret/mysql/root-password

# Recuperar versão anterior (rollback)
docker exec -it development-vault vault kv get -version=1 secret/mysql/root-password

# Ver logs de auditoria (quem acessou o quê)
docker exec -it development-vault cat /vault/data/audit.log | tail -20
```

### **Demonstração de Auditoria:**

```bash
# Verificar que auditoria está habilitada
docker exec development-vault vault audit list
# Saída: file/    file    n/a

# Acessar um secret
docker exec development-vault vault kv get secret/zabbix/admin-password

# Ver registro de auditoria (JSON com timestamp, usuário, operação)
docker exec development-vault cat /vault/data/audit.log | tail -5 | jq
```

> 📊 **Exemplo completo de demonstração**: Consulte `monitoramento/VAULT-FEATURES-DEMO.md`

### **Acessar Vault UI:**
1. Abra http://localhost:8200
2. Use o token: `vault-dev-root-token`
3. Navegue em `secret/` para ver todos os secrets
4. Clique em qualquer secret → aba "Version History" para ver versionamento

---

## ⚙️ **Features Implementadas vs Roadmap**

### **✅ Implementado e Funcionando:**

| Feature | Status | Como Testar |
|---------|--------|-------------|
| **Auditoria Completa** | ✅ 100% | `vault audit list` + ver `/vault/data/audit.log` |
| **Versionamento Automático** | ✅ 100% | `vault kv metadata get secret/mysql/root-password` |
| **Políticas de Acesso** | ✅ 100% | `vault policy read mysql-policy` |
| **Criptografia AES-256** | ✅ 100% | Transparente (Vault encrypts at rest) |
| **Centralização de Secrets** | ✅ 100% | Todos os secrets em `secret/*` |

### **⚠️ Limitações Conhecidas (Docker Compose):**

| Feature | Status Atual | Quando vem? |
|---------|--------------|-------------|
| **Rotação Automática Agendada** | ❌ Manual apenas | Level 5 (Kubernetes + External Secrets) |
| **Consumo Direto do Vault** | ❌ Containers leem `.env` | Level 5 (External Secrets Operator) |
| **Injeção Dinâmica de Secrets** | ❌ Restart necessário | Level 5 (Vault Agent Injector) |
| **Eliminação do `.env`** | ❌ Ainda necessário | Level 5 (K8s ConfigMaps + Secrets) |

**Por quê?**  
Docker Compose requer variáveis de ambiente no startup. Mudanças no Vault não propagam para containers rodando. Soluções enterprise (Vault Agent, External Secrets) requerem Kubernetes.

> 📖 **Detalhes técnicos**: Consulte `monitoramento/VAULT-FEATURES-DEMO.md` para exemplos práticos e scripts de demonstração.

---

## 🛠️ **Comandos Úteis**

```bash
# Ver status dos containers
cd monitoramento && docker-compose ps

# Ver logs
docker-compose logs -f [serviço]

# Parar tudo
docker-compose down

# Limpar volumes (cuidado!)
docker-compose down -v

# Abrir Vault UI
./setup.sh vault-ui
```

---

## 📚 **Documentação Completa**

Para configurações avançadas e detalhes técnicos:
- 📖 [**Guia Completo do Vault**](DOCUMENTACAO-VAULT-COMPLETA.md)
- 🏗️ [**Visão Geral da Série**](SERIES-OVERVIEW.md)

---

## 🔗 **Série Monitoring Security**

- **[Level 1](https://github.com/jlui70/monitoring-security-level1)** - Baseline monitoring
- **[Level 2](https://github.com/jlui70/monitoring-security-level2)** - Environment management
- **[Level 3](https://github.com/jlui70/monitoring-security-level3)** - Secrets management ⬅️ **Você está aqui**
- **Level 4** - AWS Secrets Manager (em breve)
- **Level 5** - Full Security & Compliance (em breve)

---

## 🎯 **Estrutura de Secrets no Vault**

```
secret/
├── grafana/
│   ├── admin-password
│   └── database-password
├── zabbix/
│   ├── admin-password
│   ├── database-password
│   └── server-password
├── mysql/
│   ├── root-password
│   └── zabbix-password
└── monitoring/
    ├── prometheus-password
    └── exporter-password
```

---

## 🔐 **Políticas de Acesso (Vault Policies)**

O Vault implementa o princípio de **least privilege**:

- **grafana-policy**: Acesso apenas aos secrets do Grafana
- **zabbix-policy**: Acesso apenas aos secrets do Zabbix
- **mysql-policy**: Acesso apenas aos secrets do MySQL

Cada serviço possui seu próprio token com permissões limitadas.

---

## 📈 **Evolução da Segurança**

| Aspecto | **Level 2** | **Level 3** | **Melhoria** |
|---------|-------------|-------------|--------------|
| **Armazenamento** | `.env` files | HashiCorp Vault | +500% |
| **Acesso** | Variáveis ambiente | Políticas Vault | +400% |
| **Auditoria** | Nenhuma | Completa (arquivo + timestamp) | +1000% |
| **Versionamento** | Nenhum | Histórico completo | +800% |
| **Criptografia** | Nenhuma | AES-256 em repouso | +900% |
| **Rotação** | Manual sem rastreio | Manual com versionamento | +200% |

> 💡 **Nota**: Rotação **automática agendada** requer Kubernetes + External Secrets (Level 5)

---

## ⚙️ **Troubleshooting**

### **Vault não está acessível:**
```bash
# Verificar se Vault está rodando
docker ps | grep vault

# Ver logs do Vault
docker logs development-vault

# Reiniciar Vault
docker restart development-vault
```

### **Secrets não foram criados:**
```bash
# Executar script de inicialização manualmente
docker exec -it development-vault /bin/sh -c "cd /vault/scripts && ./init-vault.sh"
```

### **Erro de autenticação:**
```bash
# Verificar token do Vault
echo $VAULT_ROOT_TOKEN

# Verificar no .env
grep VAULT_ROOT_TOKEN monitoramento/.env
```

---

**💡 Dica**: Para ambientes corporativos, considere usar Vault em modo produção (não-dev) com armazenamento persistente e configuração de alta disponibilidade.

**🎉 Level 3 representa um salto qualitativo em segurança, adequado para uso corporativo e preparado para certificações de conformidade!**
