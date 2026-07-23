#!/bin/bash

################################################################################
# PROVISION-CLIENT.SH — Automação de novo cliente multi-tenant
################################################################################
# USO:
#   ./provision-client.sh Nome aqui "Nome aqui Araújo" Nome aqui@adv.oabsp.org.br
#
# O que faz:
#   1. Cria schema isolado no Supabase (SQL)
#   2. Clona o repositório template do GitHub
#   3. Atualiza supabase-config.js com o schema do cliente
#   4. Faz commit e push inicial
#   5. Imprime instruções para criar o usuário no Dashboard
#
# REQUISITOS:
#   - git
#   - curl (para HTTP requests ao Supabase)
#   - gh (opcional, para criar repo no GitHub automaticamente)
#
################################################################################

set -e  # Sai se qualquer comando falhar

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuração (ajuste conforme necessário)
SUPABASE_PROJECT_ID="bguslrxqkrlrueafetzh"
SUPABASE_API_KEY="${SUPABASE_API_KEY:-}"  # Defina como env var ou no .env
GITHUB_OWNER="erivaldodlavire"
GITHUB_REPO_TEMPLATE="gleysite"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Defina como env var para clonar repos privados

# Argumentos
CLIENT_SLUG="${1:-}"
CLIENT_NOME="${2:-}"
CLIENT_EMAIL="${3:-}"

# Validação
if [ -z "$CLIENT_SLUG" ] || [ -z "$CLIENT_NOME" ] || [ -z "$CLIENT_EMAIL" ]; then
    echo -e "${RED}Uso: $0 <slug> <nome> <email>${NC}"
    echo "Exemplo: $0 Nome aqui 'Nome aqui Araújo' Nome aqui@gmail.com.br"
    exit 1
fi

# Slug deve ser minúsculas + números + underscore
if ! [[ "$CLIENT_SLUG" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}ERRO: slug deve conter apenas letras minúsculas, números e underscore${NC}"
    exit 1
fi

WORK_DIR="${CLIENT_SLUG}-site"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Provisionando novo cliente: $CLIENT_NOME${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# ============================================================================
# PASSO 1: Criar schema no Supabase (via SQL direto)
# ============================================================================
echo -e "\n${YELLOW}[1/5] Criando schema no Supabase...${NC}"

SQL_COMANDO="SELECT create_client_schema('$CLIENT_SLUG', '$CLIENT_NOME');"

# Se tem a API key, usa curl para executar SQL remotamente
if [ -n "$SUPABASE_API_KEY" ]; then
    curl -s -X POST "https://${SUPABASE_PROJECT_ID}.supabase.co/rest/v1/rpc/create_client_schema" \
        -H "Authorization: Bearer ${SUPABASE_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"p_slug\":\"$CLIENT_SLUG\",\"p_nome\":\"$CLIENT_NOME\"}" > /dev/null
    echo -e "${GREEN}✓ Schema criado${NC}"
else
    echo -e "${YELLOW}⚠ API key não definida. Você precisará rodar este SQL manualmente:${NC}"
    echo -e "${BLUE}$SQL_COMANDO${NC}"
    echo -e "${YELLOW}No SQL Editor do Supabase. Pressione ENTER quando terminar...${NC}"
    read
fi

# ============================================================================
# PASSO 2: Clonar o repositório template
# ============================================================================
echo -e "\n${YELLOW}[2/5] Clonando repositório template...${NC}"

if [ -d "$WORK_DIR" ]; then
    echo -e "${RED}Diretório $WORK_DIR já existe. Abortando.${NC}"
    exit 1
fi

git clone https://github.com/${GITHUB_OWNER}/${GITHUB_REPO_TEMPLATE}.git "$WORK_DIR" > /dev/null 2>&1
echo -e "${GREEN}✓ Repositório clonado em $WORK_DIR${NC}"

cd "$WORK_DIR"

# ============================================================================
# PASSO 3: Atualizar js/supabase-config.js
# ============================================================================
echo -e "\n${YELLOW}[3/5] Atualizando configuração do Supabase...${NC}"

# Usa sed para atualizar o schema no config
sed -i.bak "s/schema: 'Nome aqui'/schema: '$CLIENT_SLUG'/g" js/supabase-config.js
sed -i.bak "s/nome: 'Nome aqui Araújo'/nome: '$CLIENT_NOME'/g" js/supabase-config.js
sed -i.bak "s/id: 'Nome aqui-sobre nome'/id: '$CLIENT_SLUG'/g" js/supabase-config.js

rm -f js/supabase-config.js.bak
echo -e "${GREEN}✓ Configuração atualizada${NC}"

# ============================================================================
# PASSO 4: Criar .env com variáveis do cliente
# ============================================================================
echo -e "\n${YELLOW}[4/5] Criando .env...${NC}"

cat > .env << EOF
# Configuração para $CLIENT_NOME
CLIENT_SLUG=$CLIENT_SLUG
CLIENT_NOME=$CLIENT_NOME
CLIENT_EMAIL=$CLIENT_EMAIL
SUPABASE_PROJECT_ID=$SUPABASE_PROJECT_ID
EOF

echo -e "${GREEN}✓ .env criado${NC}"

# ============================================================================
# PASSO 5: Commit e push
# ============================================================================
echo -e "\n${YELLOW}[5/5] Commitando e fazendo push...${NC}"

git add js/supabase-config.js .env
git commit -m "Setup: Cliente $CLIENT_NOME - schema $CLIENT_SLUG" > /dev/null 2>&1
git push origin main > /dev/null 2>&1

echo -e "${GREEN}✓ Push realizado${NC}"

# ============================================================================
# RESUMO E PRÓXIMAS ETAPAS
# ============================================================================
echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Cliente provisionado com sucesso!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}PRÓXIMAS ETAPAS (manuais, no Dashboard do Supabase):${NC}"
echo -e "\n${YELLOW}1. Criar usuário admin no Supabase Auth:${NC}"
echo -e "   • Dashboard → Authentication → Users → Add user"
echo -e "   • E-mail: $CLIENT_EMAIL"
echo -e "   • Senha: 123456 (será obrigado a trocar no 1º login)"
echo -e "   • Auto Confirm: ✓ SIM"

echo -e "\n${YELLOW}2. Editar User Metadata do usuário criado (adicionar JSON):${NC}"
echo -e "   {\"must_change_password\": true, \"schema\": \"$CLIENT_SLUG\"}"

echo -e "\n${YELLOW}3. Criar repositório no GitHub (se quiser isolado):${NC}"
echo -e "   • github.com/${GITHUB_OWNER}/${WORK_DIR}"
echo -e "   • Push do código está pronto em $WORK_DIR/"

echo -e "\n${BLUE}Deploy options:${NC}"
echo -e "   • GitHub Pages: repo settings → Pages → branch main"
echo -e "   • Render.com: connect repo → build + deploy automático"
echo -e "   • Seu VPS: git clone $WORK_DIR na pasta pública"

echo -e "\n${BLUE}Testar:${NC}"
echo -e "   • Abrir site: https://<seu-dominio>/${WORK_DIR}/"
echo -e "   • Login: $CLIENT_EMAIL / 123456"
echo -e "   • Deve forçar troca de senha"

echo -e "\n${GREEN}Repositório local está em: ${NC}${BLUE}$WORK_DIR/${NC}"
echo ""
