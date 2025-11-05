# Política para Zabbix - acesso apenas aos secrets do Zabbix
path "secret/data/zabbix/*" {
  capabilities = ["read"]
}

path "secret/metadata/zabbix/*" {
  capabilities = ["list", "read"]
}

# Acesso aos secrets compartilhados do MySQL (somente leitura)
path "secret/data/mysql/zabbix-password" {
  capabilities = ["read"]
}

# Permite renovação do próprio token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Permite lookup do próprio token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}