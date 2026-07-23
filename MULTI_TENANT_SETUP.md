# 🏗️ Multi-Tenant Setup — Guia Completo

**Objetivo:** 1 projeto Supabase + 50 clientes isolados + fácil provisioning.

---

## 📐 Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│  Supabase Project (bguslrxqkrlrueafetzh)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Schema "Seu nome aqui"    Schema "erivaldo"  ...         │  │
│  │ ├─ site_config        ├─ site_config                │  │
│  │ ├─ site_leads         ├─ site_leads                 │  │
│  │ └─ aniversariantes    └─ aniversariantes            │  │
│  │                                                      │  │
│  │ RLS: Cada usuário ONLY acessa seu schema             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
        ↑                ↑                ↑
        │                │                │
   Seu nome aqui site    Erivaldo site    Cliente-001 site
   (GitHub repo)    (GitHub repo)    (GitHub repo)
   deploy auto      deploy auto      deploy auto
```

---

## 🚀 Passo 1: Executar o Setup Multi-Tenant (UMA VEZ)

Você faz isso **1 única vez** para preparar o Supabase.

### Via SQL Editor do Supabase

1. Vá para Dashboard → **SQL Editor**
2. Clique **New Query**
3. Cole o conteúdo de `sql/03_multi_tenant_setup.sql` **INTEIRO**
4. Clique **Run**
5. Espere concluir (você verá confirmações no console)

Isto criará:
- Função `create_client_schema()` para criar clientes rapidinho
- Tabelas compartilhadas (audit_log, etc)
- Estrutura de RLS

**Status:** ✅ Feito. Pronto para criar quantos clientes quiser.

---

## 👤 Passo 2: Provisionar Um Novo Cliente

Para cada novo cliente (Seu nome aqui, Erivaldo, Cliente-001...), execute:

### Opção A: Automático (Bash + Git + API) — RECOMENDADO

```bash
# Terminal (Linux/Mac) ou Git Bash (Windows)
cd seu-repo
chmod +x provision-client.sh

./provision-client.sh Seu nome aqui "Seu nome aqui Araújo" Seu nome aqui@adv.oabsp.org.br
```

O script faz TUDO:
1. ✅ Cria schema "Seu nome aqui" no Supabase
2. ✅ Clona o repositório template
3. ✅ Atualiza `js/supabase-config.js` com schema correto
4. ✅ Faz commit e push automático

**Resultado:** Diretório `Seu nome aqui-site/` pronto com repositório GitHub atualizado.

### Opção B: Manual (sem script) — para Windows sem Bash

#### 2.1) Criar Schema no Supabase

1. Dashboard → **SQL Editor**
2. Cole e rode:

```sql
SELECT create_client_schema('Seu nome aqui', 'Seu nome aqui Araújo');
```

Resultado esperado: `"Schema 'Seu nome aqui' criado com sucesso para cliente: Seu nome aqui Araújo"`

#### 2.2) Clonar repositório e atualizar config

```bash
git clone https://github.com/erivaldodlavire/gleysite.git Seu nome aqui-site
cd Seu nome aqui-site
```

Abra `js/supabase-config.js` e atualize:

```javascript
cliente: {
    id: 'Seu nome aqui',              // mudou de 'Seu nome aqui-'
    nome: 'Seu nome aqui Araújo',
    marca: 'Advocacia',
    schema: 'Seu nome aqui',          // ← NOVO: aponta pro schema isolado
},
```

#### 2.3) Commit e Push

```bash
git add js/supabase-config.js
git commit -m "Setup: Cliente Seu nome aqui - schema Seu nome aqui"
git push origin main
```

---

## 🔐 Passo 3: Criar Usuário Admin (Supabase Dashboard)

Para CADA cliente, crie um usuário de login:

1. Dashboard → **Authentication** → **Users**
2. Clique **Add user**
3. Preencha:
   - Email: `Seu nome aqui@adv.oabsp.org.br`
   - Password: `123456` (será obrigado a trocar no 1º login)
   - **Auto Confirm User**: ✅ SIM (importante!)
4. Clique **Save**

5. Clique no usuário criado → aba **User Metadata**
6. Edite o JSON para:

```json
{
  "must_change_password": true,
  "schema": "Seu nome aqui"
}
```

**Resultado:** Usuário pode logar em `admin.html` com `Seu nome aqui@adv.oabsp.org.br / 123456` → será forçado a trocar senha → terá acesso APENAS aos dados do schema "Seu nome aqui".

---

## 📦 Passo 4: Deploy do Site (GitHub Pages / Render / VPS)

Escolha UM:

### Opção A: GitHub Pages (GRÁTIS, estático)

No repositório `Seu nome aqui-site`:

1. Settings → **Pages**
2. Source: **Deploy from a branch**
3. Branch: **main**
4. Folder: **/ (root)**
5. Save

Seu site aparece em `https://erivaldodlavire.github.io/Seu nome aqui-site/`

### Opção B: Render.com (RECOMENDADO para dinâmico)

1. [render.com](https://render.com) → New → Static Site
2. Connect GitHub repo `Seu nome aqui-site`
3. Build command: *(deixe vazio)*
4. Publish directory: `.` (raiz)
5. Deploy

Seu site aparece em `https://Seu nome aqui-site.onrender.com/`

### Opção C: VPS Hostinger (seu próprio servidor)

```bash
# No VPS
cd /var/www/

git clone https://github.com/erivaldodlavire/Seu nome aqui-site.git Seu nome aqui
cd Seu nome aqui

# Configurar Nginx/Apache para servir /var/www/Seu nome aqui/
# Resultado: seu-dominio.com/Seu nome aqui/
```

---

## 🔑 Segurança: Como o RLS Funciona

Sem RLS, um hacker logado como `Seu nome aqui@adv.oabsp.org.br` poderia fazer:

```javascript
// ❌ PERIGOSO (sem RLS):
const { data } = await db.from('site_config').select().eq('id', 1);
// Retorna TUDO do schema public — dados de todos os clientes!
```

**COM RLS + schemas isolados:**

```javascript
// ✅ SEGURO (com RLS):
const { data } = await db.from('site_config').select().eq('id', 1);
// Retorna APENAS do schema Seu nome aqui (sua sessão está confinada)
// Se tentar acessar outro schema:
const { data } = await supabase
  .from('site_config', { schema: 'erivaldo' })
  .select();
// Erro 403: Access Denied via RLS
```

**Como ativa o confinamento de schema:**

(Opcional — já está parcialmente protegido com RLS, mas para máxima segurança):

No SQL Editor:

```sql
-- Para o usuário de Seu nome aqui:
ALTER ROLE "Seu nome aqui_admin" IN DATABASE postgres SET search_path TO Seu nome aqui, public;
```

Agora o usuário SÓ consegue acessar o schema Seu nome aqui, mesmo que tente forçar outro.

---

## 📊 Exemplo Completo: Criando 3 Clientes

### Cliente 1: Seu nome aqui Araújo (Advocacia)

```bash
./provision-client.sh Seu nome aqui "Seu nome aqui Araújo" Seu nome aqui@adv.oabsp.org.br
# → Cria Seu nome aqui-site/
```

Depois no Dashboard:
- Usuário: `Seu nome aqui@adv.oabsp.org.br`
- Metadata: `{"must_change_password": true, "schema": "Seu nome aqui"}`

### Cliente 2: Erivaldo Silva (Advocacia/Pessoal)

```bash
./provision-client.sh erivaldo "Erivaldo Silva" erivaldo@adv.oabsp.org.br
# → Cria erivaldo-site/
```

Depois no Dashboard:
- Usuário: `erivaldo@adv.oabsp.org.br`
- Metadata: `{"must_change_password": true, "schema": "erivaldo"}`

### Cliente 3: Cliente ABC Ltda (Engenharia)

```bash
./provision-client.sh cliente_abc "Cliente ABC Ltda" admin@clienteabc.com.br
# → Cria cliente_abc-site/
```

Depois no Dashboard:
- Usuário: `admin@clienteabc.com.br`
- Metadata: `{"must_change_password": true, "schema": "cliente_abc"}`

---

## 🐞 Troubleshooting

### "Schema já existe"
Nada de errado — a função é idempotente. Rodar de novo é seguro.

### "Usuário já existe no Auth"
Supabase não permite emails duplicados. Use um e-mail único por cliente.

### Site abre mas dados não carregam
1. Verificar se o `js/supabase-config.js` tem o `schema` correto
2. Verificar se o usuário foi criado no Dashboard
3. F12 → Console → procure por erro do Supabase

### "Access Denied" ao logar
1. Confirmar que User Metadata tem `"schema": "Seu nome aqui"`
2. Confirmar que o schema foi criado (SQL não deu erro)
3. Refrescar o navegador (Ctrl+Shift+R)

---

## 🎯 Checklist para Cada Novo Cliente

- [ ] Rodar `provision-client.sh` OU executar SQL + clonar repo manualmente
- [ ] Criar usuário no Supabase Auth com Auto Confirm
- [ ] Adicionar `"schema": "cliente_slug"` no User Metadata
- [ ] Fazer deploy (GitHub Pages / Render / VPS)
- [ ] Testar login em `admin.html`
- [ ] Testar que não consegue acessar dados de outro cliente (RLS)

---

## 📝 Próximas Etapas (opcional)

1. **Painel centralizado** para gerenciar 50 clientes (n8n dashboard)
2. **CI/CD automático**: quando clientes editam no Admin, deploy automático
3. **Billing**: integração com Stripe para cobrar clientes via Supabase
4. **Analytics**: rastreio de acessos, formulários por cliente

---

**Status:** ✅ Pronto para 50 clientes isolados e seguros!
