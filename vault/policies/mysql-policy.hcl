# Política para MySQL - acesso apenas aos secrets do MySQL
path "secret/data/mysql/*" {
  capabilities = ["read"]
}

path "secret/metadata/mysql/*" {
  capabilities = ["list", "read"]
}

# Permite renovação do próprio token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Permite lookup do próprio token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}