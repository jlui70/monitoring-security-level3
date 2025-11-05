# Política para Grafana - acesso apenas aos secrets do Grafana
path "secret/data/grafana/*" {
  capabilities = ["read"]
}

path "secret/metadata/grafana/*" {
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