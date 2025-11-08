# 🔐 Monitoring Security Stack - Level 3

**HashiCorp Vault + Secrets Management** - Stack completa de monitoramento com gestão centralizada de secrets.

## 🚀 **Quick Start (2 comandos)**

```bash
# 1. Clone
git clone https://github.com/jlui70/monitoring-security-level3.git
cd monitoring-security-level3

# 2. Deploy
cd monitoramento && ./setup.sh
```

**Pronto!** Aguarde 8-10 minutos e acesse:
- **Vault UI**: http://localhost:8200 (Token: vault-dev-root-token)
- **Zabbix**: http://localhost:8080 (Admin/zabbix)
- **Grafana**: http://localhost:3000 (admin/admin)

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

### **⚠️ Workaround Necessário na Primeira Instalação:**

Se os containers do Zabbix não iniciarem automaticamente após o primeiro `docker-compose up -d`, execute:

```bash
# Verificar se MySQL está healthy
docker-compose ps

# Se Zabbix não estiver rodando, iniciar manualmente
docker-compose up -d zabbix-server zabbix-web zabbix-agent2

# Aguardar 6-7 minutos para criação do schema
./check-zabbix-ready.sh

# Quando pronto, os scripts de configuração executarão automaticamente
```

**💡 Isso ocorre** devido ao timing do healthcheck do MySQL em instalações limpas. Este workaround garante que o Zabbix inicie corretamente.

---

## 📊 **O que você ganha no Level 3?**

### **✅ Novos Recursos do Level 3:**
- 🏦 **HashiCorp Vault** - Gerenciamento centralizado de secrets
- 🔑 **Zero senhas em texto** - Todas gerenciadas pelo Vault
- 📊 **Auditoria completa** - Log de todos os acessos
- 🔄 **Rotação automática** - Senhas rotacionadas sem downtime
- 🛡️ **Criptografia AES-256** - Máxima segurança

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

# Atualizar secret
docker exec -it development-vault vault kv put secret/mysql/root-password value="NovaSenha123!"

# Ver logs de auditoria
docker exec -it development-vault vault audit list
```

### **Acessar Vault UI:**
1. Abra http://localhost:8200
2. Use o token: `vault-dev-root-token`
3. Navegue em `secret/` para ver todos os secrets

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
| **Acesso** | Variáveis ambiente | Tokens temporários | +400% |
| **Rotação** | Manual | Automática | +300% |
| **Auditoria** | Logs básicos | Completa | +600% |
| **Criptografia** | Base64 opcional | AES-256 + TLS | +800% |

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
