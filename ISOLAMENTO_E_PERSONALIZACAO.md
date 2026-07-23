# 🚀 GUIA COMPLETO: Criar Cliente Novo (Gleyciane, Erivaldo, Cliente-X)

**Objetivo:** Cada site é 100% isolado. Mudanças em um NÃO afetam o outro.

---

## 📐 Arquitetura: Múltiplos Repositórios

```
GitHub (seu):
├── gleyciane-site/          ← Repositório de Gleyciane (isolado)
│   └── js/supabase-config.js → schema: 'gleyciane'
│
├── erivaldo-site/           ← Repositório seu (isolado)
│   └── js/supabase-config.js → schema: 'erivaldo'
│
└── cliente_001-site/        ← Repositório de Cliente (isolado)
    └── js/supabase-config.js → schema: 'cliente_001'
```

**Cada repositório é uma cópia isolada:**
- Git push em `gleyciane-site/` NÃO afeta `erivaldo-site/`
- Editar `js/supabase-config.js` em um repositório é completamente isolado
- Zero conflitos, zero sincronizações acidentais

---

## 🎯 Passo-a-Passo: Criar Novo Cliente

### OPÇÃO A: Com Script Automático (RECOMENDADO)

```bash
# 1. Clone o repositório template
git clone https://github.com/erivaldodlavire/gleysite.git gleyciane-site
cd gleyciane-site

# 2. Execute o script de setup (automatiza TUDO)
chmod +x setup-client.sh
./setup-client.sh gleyciane "Gleyciane Araújo" "Advocacia"

# 3. Pronto! Arquivo já está personalizado e commitado
git push origin main
```

**O script faz:**
- ✅ Substitui TEMPLATE_ID por "gleyciane"
- ✅ Substitui TEMPLATE_NOME por "Gleyciane Araújo"
- ✅ Substitui TEMPLATE_MARCA por "Advocacia"
- ✅ Substitui TEMPLATE_SCHEMA por "gleyciane"
- ✅ Verifica que nenhum TEMPLATE_ ficou pra trás
- ✅ Faz commit automaticamente
- ✅ Dá instruções do próximo passo

**Resultado:** 2 minutos, arquivo 100% personalizado e seguro.

---

### OPÇÃO B: Manual (sem script)

```bash
# 1. Clone
git clone https://github.com/erivaldodlavire/gleysite.git gleyciane-site
cd gleyciane-site

# 2. Abra js/supabase-config.js no VSCode

# 3. Substitua MANUALMENTE:
#    TEMPLATE_ID      → gleyciane
#    TEMPLATE_NOME    → Gleyciane Araújo
#    TEMPLATE_MARCA   → Advocacia
#    TEMPLATE_SCHEMA  → gleyciane

# 4. Salve (Ctrl+S)

# 5. Commit
git add js/supabase-config.js
git commit -m "Config: Gleyciane Araújo - schema gleyciane"
git push origin main
```

---

## 🔒 Garantias de Isolamento

### 1️⃣ Repositórios Separados no GitHub

Cada cliente tem sua **própria URL de repositório:**

```
Gleyciane:  github.com/erivaldodlavire/gleyciane-site
Erivaldo:   github.com/erivaldodlavire/erivaldo-site
Cliente-X:  github.com/erivaldodlavire/cliente_x-site
```

**Benefício:** Um commit em `gleyciane-site` NUNCA afeta `erivaldo-site`. Git garante isso nativamente.

### 2️⃣ Supabase: Schemas Isolados + RLS

Mesmo que alguém acesse o Supabase diretamente:

```
Banco de dados único (bguslrxqkrlrueafetzh):
├── schema "gleyciane"
│   └── Só usuários de Gleyciane conseguem ler/escrever
├── schema "erivaldo"
│   └── Só usuários de Erivaldo conseguem ler/escrever
└── schema "cliente_001"
    └── Só usuários do Cliente conseguem ler/escrever
```

**Proteção dupla:** RLS + schema = segurança máxima.

### 3️⃣ Arquivo de Config Customizado

Cada `supabase-config.js` aponta pro **schema correto:**

```javascript
// gleyciane-site/js/supabase-config.js
cliente: {
    id: 'gleyciane',
    schema: 'gleyciane',  // ← Todas as queries vão aqui
}

// erivaldo-site/js/supabase-config.js
cliente: {
    id: 'erivaldo',
    schema: 'erivaldo',   // ← Todas as queries vão aqui
}
```

---

## ✅ Checklist: Novo Cliente Criado

- [ ] Repositório clonado (ex: `gleyciane-site/`)
- [ ] `setup-client.sh` executado OU `supabase-config.js` editado manualmente
- [ ] Nenhum `TEMPLATE_` restante no arquivo
- [ ] Commit feito e pushed
- [ ] Schema criado no Supabase (SQL)
- [ ] Usuário criado em Auth (Dashboard)
- [ ] Teste de login funciona
- [ ] Verifica que NÃO consegue acessar schema de outro cliente (RLS test)

---

## 🆘 Se algo der errado

### Problema: "Editei gleyciane-site/ e erivaldo-site/ também mudou"

**Causa:** Provavelmente estão no mesmo repositório local ou você fez git pull global.

**Solução:**

```bash
# Verifique qual repositório você está
pwd
# Se disser /home/user/gleyciane-site → correto
# Se disser /home/user/gleysite → ERRADO (template, não deve editar)

# Se estiver no template, mude pra cópia do cliente
cd ../gleyciane-site
# ou clone novo
git clone https://github.com/erivaldodlavire/gleysite.git gleyciane-site
```

### Problema: "TEMPLATE_ ainda está no arquivo"

**Causa:** `setup-client.sh` foi saltado ou edição manual incompleta.

**Solução:**

```bash
# Se usou script, rode de novo
./setup-client.sh gleyciane "Gleyciane Araújo" "Advocacia"

# Se editou manualmente, abra js/supabase-config.js e procure por TEMPLATE_
grep TEMPLATE_ js/supabase-config.js
# Se retornar algo, edite e salve
```

### Problema: "Todos os sites estão iguais"

**Causa:** Alguém clonou o template padrão e não personalizou.

**Solução:**

```bash
# Verifique o conteúdo de supabase-config.js
cat js/supabase-config.js | grep "id:"
# Se disser TEMPLATE_ID, rode setup-client.sh
```

---

## 📝 Estrutura de Pastas Recomendada

No seu computador/VPS, organize assim:

```
/home/seu-usuario/
├── gleysite-template/      ← NÃO edita! Apenas referência
│   └── js/supabase-config.js → tem TEMPLATE_XXX
│
├── gleyciane-site/         ← EDITA quando for trabalhar com Gleyciane
│   └── js/supabase-config.js → schema: 'gleyciane'
│
├── erivaldo-site/          ← EDITA quando for trabalhar com Erivaldo
│   └── js/supabase-config.js → schema: 'erivaldo'
│
└── cliente_001-site/       ← EDITA quando trabalhar com Cliente 001
    └── js/supabase-config.js → schema: 'cliente_001'
```

**Nunca edita `gleysite-template/`** — apenas clona dele.

---

## 🔄 Workflow: Dia a Dia

### Quando trabalhar com Gleyciane:

```bash
cd gleyciane-site/
# edita, testa, commit, push
```

### Quando trabalhar com Erivaldo:

```bash
cd ../erivaldo-site/
# edita, testa, commit, push
```

**Nunca há conflito** porque são repositórios separados.

---

## 🚀 Escalando para 50 Clientes

O processo é o mesmo **repetido 50 vezes:**

```bash
# Cliente 001
git clone https://github.com/erivaldodlavire/gleysite.git cliente_001-site
cd cliente_001-site
./setup-client.sh cliente_001 "Cliente ABC Ltda" "Consultoria"
git push origin main

# Cliente 002
cd ..
git clone https://github.com/erivaldodlavire/gleysite.git cliente_002-site
cd cliente_002-site
./setup-client.sh cliente_002 "Empresa XYZ" "Engenharia"
git push origin main

# ... e assim por diante
```

Cada repositório é uma cópia isolada e segura.

---

## 📊 Resumo Visual

```
┌─────────────────────────────────────────────────────────────┐
│  1 Projeto Supabase (bguslrxqkrlrueafetzh)                 │
│  └─ Múltiplos schemas isolados (gleyciane, erivaldo, ...)  │
│     └─ RLS garante isolamento total                         │
└─────────────────────────────────────────────────────────────┘
         ↑              ↑              ↑
         │              │              │
    ┌────┴──┐      ┌────┴──┐      ┌────┴──┐
    │        │      │        │      │        │
GitHub     GitHub  GitHub   GitHub GitHub  GitHub
Repo 1     Repo 2  Repo 3   Repo 4 Repo 5 Repo 50

gleyciane  erivaldo cliente_001 ... cliente_050
-site      -site    -site         -site
```

Cada repositório é **100% isolado**.

---

## ✨ Resultado Final

✅ Seu site (Erivaldo) → totalmente independente
✅ Site da esposa (Gleyciane) → totalmente independente
✅ 50 clientes futuros → cada um totalmente isolado
✅ Sem conflitos, sem sincronizações acidentais
✅ RLS + Supabase garante segurança
✅ Pronto para vender! 🎉

Bora começar? 🚀
