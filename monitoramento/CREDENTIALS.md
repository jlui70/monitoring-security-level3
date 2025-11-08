# 🔐 Credenciais de Acesso - Level 3

## ✅ Senhas Corretas Pós-Setup

### 🌐 Zabbix Web Interface
- **URL:** http://localhost:8080
- **Usuário:** `Admin`
- **Senha:** `V@ultSecur3P@ss2024!` ✅ **(Gerenciada pelo Vault)**

**Nota:** A senha padrão do Zabbix (`zabbix`) é **alterada automaticamente** pelo script `configure-zabbix.sh` para a senha armazenada no Vault.

---

### 📊 Grafana
- **URL:** http://localhost:3000
- **Usuário:** `admin`
- **Senha:** `Dev_Grafana_Vault_2024!@` ✅ **(Gerenciada pelo Vault)**

**Nota:** Grafana respeita a variável `GF_SECURITY_ADMIN_PASSWORD` do `.env` automaticamente.

---

### ⚡ Prometheus
- **URL:** http://localhost:9090
- **Autenticação:** ❌ Nenhuma (acesso público por padrão)

**Nota:** Em produção, recomenda-se configurar autenticação via reverse proxy (Nginx + basic auth).

---

### 🏦 HashiCorp Vault
- **URL:** http://localhost:8200
- **Método de Login:** Token
- **Token:** `vault-dev-root-token`

**Nota:** Em produção, usar tokens temporários com TTL e políticas específicas.

---

## 🔑 Secrets Armazenados no Vault

Todos os secrets estão criptografados com AES-256 no Vault:

```bash
# Listar todos os secrets
vault kv list secret/

# MySQL
vault kv get secret/mysql/root-password          # Dev_Root_Vault_2024!@
vault kv get secret/mysql/zabbix-password        # Dev_Zabbix_Vault_2024!@

# Zabbix
vault kv get secret/zabbix/admin-password        # V@ultSecur3P@ss2024!
vault kv get secret/zabbix/database-password     # Dev_Zabbix_Vault_2024!@

# Grafana
vault kv get secret/grafana/admin-password       # Dev_Grafana_Vault_2024!@

# Monitoring
vault kv get secret/monitoring/mysql-exporter-password  # Dev_Exporter_Vault_2024!@
```

---

## ⚠️ Importante: Política de Senhas do Zabbix

O Zabbix tem regras de validação de senha:

✅ **Permitido:**
- Mínimo 8 caracteres
- Letras maiúsculas e minúsculas
- Números
- Caracteres especiais

❌ **NÃO Permitido:**
- Senhas contendo o username (`Admin`)
- Senhas contendo o sobrenome do usuário
- Senhas muito simples

**Exemplo:**
- ❌ `Dev_Admin_Vault_2024!@` → Rejeitada (contém "Admin")
- ✅ `V@ultSecur3P@ss2024!` → Aceita

---

## 🔄 Fluxo de Alteração Automática (Zabbix)

Quando o `setup.sh` executa, o seguinte acontece:

1. **Containers iniciam** com senha padrão do Zabbix (`zabbix`)
2. **configure-zabbix.sh executa:**
   - Faz login com senha padrão
   - Lê `ZABBIX_ADMIN_PASSWORD` do `.env`
   - Chama API `user.update` com `current_passwd: "zabbix"` e `passwd: "V@ultSecur3P@ss2024!"`
   - Senha alterada com sucesso! ✅
   - Faz re-login com nova senha
   - Continua configuração (templates, DNS, etc.)

**Resultado:** Zabbix **nunca** fica acessível com senha padrão em produção!

---

## 📝 Comparação: Level 2 vs Level 3

| Aspecto | Level 2 | Level 3 |
|---------|---------|---------|
| **Zabbix Password** | ❌ Padrão (`zabbix`) ou manual | ✅ Vault (`V@ultSecur3P@ss2024!`) |
| **Grafana Password** | ✅ `.env` | ✅ Vault (via `.env`) |
| **Armazenamento** | `.env` texto plano | Vault AES-256 |
| **Rotação** | Manual, downtime | Automática via Vault |
| **Auditoria** | ❌ Nenhuma | ✅ Vault audit log |

---

## 🛡️ Boas Práticas de Segurança

### Em Desenvolvimento:
- ✅ Senhas complexas mas legíveis (ex: `V@ultSecur3P@ss2024!`)
- ✅ Vault em modo dev com root token
- ✅ Logs de auditoria habilitados

### Em Produção:
1. **Vault:**
   - Usar Vault em modo produção (HA, unsealed)
   - Tokens com TTL curto (1-24h)
   - Políticas granulares por serviço
   - Backup criptografado

2. **Senhas:**
   - Geradas randomicamente (32+ chars)
   - Rotação automática a cada 90 dias
   - Nunca commitadas no git

3. **Acesso:**
   - Prometheus atrás de autenticação
   - Vault atrás de firewall (apenas rede interna)
   - TLS/SSL em todos os serviços

---

## 🔍 Verificação de Senhas

### Testar Zabbix:
```bash
# Senha padrão (deve FALHAR)
curl -s -X POST http://localhost:8080/api_jsonrpc.php \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"zabbix"},"id":1}'
# Erro esperado: "Login name or password is incorrect"

# Senha do Vault (deve FUNCIONAR)
curl -s -X POST http://localhost:8080/api_jsonrpc.php \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"V@ultSecur3P@ss2024!"},"id":1}'
# Retorna: {"jsonrpc":"2.0","result":"<auth-token>","id":1}
```

### Testar Grafana:
```bash
# Login via API
curl -s -u admin:Dev_Grafana_Vault_2024!@ http://localhost:3000/api/org
# Retorna: {"id":1,"name":"Main Org."}
```

### Testar Vault:
```bash
# Login
docker exec development-vault vault login vault-dev-root-token

# Listar secrets
docker exec development-vault vault kv list secret/

# Ler secret específico
docker exec development-vault vault kv get secret/zabbix/admin-password
```

---

## 📚 Referências

- [Zabbix API Documentation](https://www.zabbix.com/documentation/current/en/manual/api)
- [HashiCorp Vault Secrets](https://www.vaultproject.io/docs/secrets)
- [Grafana Security](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/)

---

**✅ Todas as senhas agora são gerenciadas pelo Vault e aplicadas automaticamente!** 🎉
