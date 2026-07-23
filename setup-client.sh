#!/bin/bash

################################################################################
# SETUP-CLIENT.SH — Personaliza supabase-config.js para novo cliente
################################################################################
# USO:
#   chmod +x setup-client.sh
#   ./setup-client.sh gleyciane "Gleyciane Araújo" "Advocacia"
#
# Isto substitui TEMPLATE_XXX pelos valores reais automaticamente.
# ################################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Argumentos
CLIENT_SLUG="${1:-}"
CLIENT_NOME="${2:-}"
CLIENT_MARCA="${3:-}"

# Validação
if [ -z "$CLIENT_SLUG" ] || [ -z "$CLIENT_NOME" ] || [ -z "$CLIENT_MARCA" ]; then
    echo -e "${RED}USO: $0 <slug> <nome-completo> <profissão>${NC}"
    echo "Exemplo: $0 gleyciane 'Gleyciane Araújo' 'Advocacia'"
    echo ""
    echo "Argumentos:"
    echo "  <slug>         = ID único (minúsculas, sem espaços)"
    echo "  <nome>         = Nome completo do cliente"
    echo "  <profissão>    = Seu segmento (Advocacia, Consultoria, etc)"
    exit 1
fi

# Slug só pode ter letras minúsculas, números e underscore
if ! [[ "$CLIENT_SLUG" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}ERRO: slug inválido. Use apenas letras minúsculas, números e underscore.${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Personalizando para: ${CLIENT_NOME}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Arquivo a ser editado
CONFIG_FILE="js/supabase-config.js"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ ERRO: Arquivo $CONFIG_FILE não encontrado!${NC}"
    echo -e "${RED}   Execute este script na raiz do repositório.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[1/3] Substituindo placeholders em $CONFIG_FILE...${NC}"

# Substitui TEMPLATE_ID
sed -i.bak "s/TEMPLATE_ID/$CLIENT_SLUG/g" "$CONFIG_FILE"
echo -e "  ${GREEN}✓${NC} TEMPLATE_ID → $CLIENT_SLUG"

# Substitui TEMPLATE_NOME
sed -i.bak "s/TEMPLATE_NOME/$CLIENT_NOME/g" "$CONFIG_FILE"
echo -e "  ${GREEN}✓${NC} TEMPLATE_NOME → $CLIENT_NOME"

# Substitui TEMPLATE_MARCA
sed -i.bak "s/TEMPLATE_MARCA/$CLIENT_MARCA/g" "$CONFIG_FILE"
echo -e "  ${GREEN}✓${NC} TEMPLATE_MARCA → $CLIENT_MARCA"

# Substitui TEMPLATE_SCHEMA (deve ser igual ao slug)
sed -i.bak "s/TEMPLATE_SCHEMA/$CLIENT_SLUG/g" "$CONFIG_FILE"
echo -e "  ${GREEN}✓${NC} TEMPLATE_SCHEMA → $CLIENT_SLUG"

# Remove arquivo de backup
rm -f "$CONFIG_FILE.bak"

echo -e "\n${YELLOW}[2/3] Verificando arquivo...${NC}"

# Verifica se ainda tem TEMPLATE_ (não deveria ter)
if grep -q "TEMPLATE_" "$CONFIG_FILE"; then
    echo -e "${RED}❌ ERRO: Ainda há placeholders TEMPLATE_ no arquivo!${NC}"
    grep "TEMPLATE_" "$CONFIG_FILE"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Nenhum placeholder restante"

echo -e "\n${YELLOW}[3/3] Commit automático...${NC}"

# Faz commit
git add "$CONFIG_FILE"
git commit -m "Config: Cliente $CLIENT_NOME - schema $CLIENT_SLUG" > /dev/null 2>&1

echo -e "  ${GREEN}✓${NC} Commit realizado"

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Personalização completa!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}Próximas etapas:${NC}"
echo -e "  1. git push origin main"
echo -e "  2. Criar schema no Supabase (SQL Editor):"
echo -e "     ${YELLOW}SELECT create_client_schema('$CLIENT_SLUG', '$CLIENT_NOME');${NC}"
echo -e "  3. Criar usuário em Auth (Dashboard)"
echo -e "  4. Testar login no site"

echo -e "\n${YELLOW}Dica:${NC} Se cometeu um erro, pode desfazer:"
echo -e "  git reset HEAD~1 && git checkout $CONFIG_FILE"
echo ""
