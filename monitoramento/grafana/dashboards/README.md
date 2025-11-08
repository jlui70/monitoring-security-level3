# Dashboards do Grafana

Esta pasta contém os dashboards JSON que serão importados automaticamente para o Grafana durante o setup.

## Como adicionar dashboards

1. Exporte dashboards do Grafana existente no formato JSON
2. Coloque os arquivos `.json` nesta pasta
3. Execute o script de importação: `./import-dashboards.sh`

## Dashboards do Level 2

Se você tem os dashboards do Level 2, copie-os para cá:

```bash
# Se você tem o projeto level 2 localmente
cp ~/monitoring-security-level2/monitoramento/grafana/dashboards/*.json ./
```

Os dashboards típicos do projeto incluem:
- **Node Exporter Full** - Métricas completas do sistema
- **Zabbix Server Overview** - Visão geral do Zabbix

## Importação automática

Durante o `./setup.sh`, o script `import-dashboards.sh` irá:
1. Configurar os datasources (Prometheus e Zabbix)
2. Importar todos os arquivos `.json` desta pasta
3. Deixar os dashboards totalmente editáveis (não provisionados)
