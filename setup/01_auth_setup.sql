-- ============================================================================
-- 01_AUTH_SETUP.SQL — Fundação de Segurança (Fase 1)
-- ============================================================================
-- Execute no Supabase: Dashboard → SQL Editor → New Query → colar → Run.
-- Idempotente: pode rodar mais de uma vez sem quebrar nada.
--
-- O QUE ESTE SCRIPT CORRIGE:
--   A anon key é pública (vai pro navegador). Sem RLS, QUALQUER visitante
--   pode alterar o site_config e ler os leads dos seus clientes.
--   Com as políticas abaixo:
--     • site_config → leitura pública (o site precisa), escrita SÓ logado.
--     • site_leads  → inserção pública (formulário de contato), leitura SÓ logado.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1) GARANTIR A ESTRUTURA DAS TABELAS (cria se não existirem)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.site_config (
    id          integer PRIMARY KEY DEFAULT 1,
    tema        text,
    nome        text,
    oab         text,
    slogan      text,
    sobre       text,
    endereco    text,
    tel         text,
    email       text,
    horario     text,
    copy        text,
    identidade  jsonb,          -- { perfil, favicon, fundo } (base64/URLs)
    fotos       jsonb,          -- { f1, f2, f3 }
    areas       jsonb,          -- [{ i, t, d }]
    redes       jsonb,          -- [url, url, ...]
    pubs        jsonb,          -- [{ l, d }]
    layout      jsonb,          -- Fase 2: ordem das seções (Layout Builder)
    audio       jsonb,          -- Fase 2: { ativo, pacote } (Motor de Áudio)
    updated_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.site_leads (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome        text NOT NULL,
    email       text,
    whatsapp    text,
    assunto     text,
    mensagem    text,
    origem      text DEFAULT 'site',   -- rastreio p/ payloads do n8n
    created_at  timestamptz DEFAULT now()
);

-- Atualiza updated_at automaticamente a cada alteração de config
CREATE OR REPLACE FUNCTION public.fn_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_site_config_touch ON public.site_config;
CREATE TRIGGER trg_site_config_touch
    BEFORE UPDATE ON public.site_config
    FOR EACH ROW EXECUTE FUNCTION public.fn_touch_updated_at();

-- ---------------------------------------------------------------------------
-- 2) ATIVAR ROW LEVEL SECURITY (o coração da segurança)
-- ---------------------------------------------------------------------------
ALTER TABLE public.site_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_leads  ENABLE ROW LEVEL SECURITY;

-- Limpa políticas antigas para reexecução segura
DROP POLICY IF EXISTS "config_leitura_publica"      ON public.site_config;
DROP POLICY IF EXISTS "config_escrita_autenticada"  ON public.site_config;
DROP POLICY IF EXISTS "config_update_autenticado"   ON public.site_config;
DROP POLICY IF EXISTS "leads_insercao_publica"      ON public.site_leads;
DROP POLICY IF EXISTS "leads_leitura_autenticada"   ON public.site_leads;
DROP POLICY IF EXISTS "leads_delete_autenticado"    ON public.site_leads;

-- SITE_CONFIG ---------------------------------------------------------------
-- Qualquer visitante pode LER a configuração (o index.html precisa disso)
CREATE POLICY "config_leitura_publica"
    ON public.site_config FOR SELECT
    TO anon, authenticated
    USING (true);

-- Só usuários logados (Admin) podem CRIAR/ALTERAR a configuração
CREATE POLICY "config_escrita_autenticada"
    ON public.site_config FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "config_update_autenticado"
    ON public.site_config FOR UPDATE
    TO authenticated
    USING (true) WITH CHECK (true);

-- SITE_LEADS ----------------------------------------------------------------
-- Visitantes podem ENVIAR leads (formulário público)...
CREATE POLICY "leads_insercao_publica"
    ON public.site_leads FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- ...mas só o Admin logado pode LER e APAGAR
CREATE POLICY "leads_leitura_autenticada"
    ON public.site_leads FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "leads_delete_autenticado"
    ON public.site_leads FOR DELETE
    TO authenticated
    USING (true);

-- Garante o registro-semente da configuração (id = 1)
INSERT INTO public.site_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ============================================================================
-- 3) CRIAR O USUÁRIO ADMIN PADRÃO (feito no Dashboard, não em SQL)
-- ============================================================================
-- Senhas NUNCA ficam no código (a falha da versão antiga). O usuário de
-- fábrica é criado assim, uma vez por cliente:
--
--   a) Dashboard → Authentication → Users → "Add user" → "Create new user"
--   b) Email:    o e-mail do cliente (ex.: gleyciane_araujo@adv.oabsp.org.br)
--      Password: 123456          ← senha padrão de fábrica
--      Auto Confirm User: ✔ SIM
--
--   c) Depois de criado, clique no usuário → "User Metadata" → edite o JSON:
--          { "must_change_password": true }
--      É esta flag que faz o login.html FORÇAR a troca no primeiro acesso.
--
--      (Alternativa via SQL, se preferir — rode após criar o usuário:)
--
--      UPDATE auth.users
--      SET raw_user_meta_data = raw_user_meta_data || '{"must_change_password": true}'::jsonb
--      WHERE email = 'gleyciane_araujo@adv.oabsp.org.br';
--
-- ============================================================================
-- 4) HABILITAR O CÓDIGO OTP DE 6 DÍGITOS NO E-MAIL
-- ============================================================================
--   Dashboard → Authentication → Email Templates → template "Magic Link":
--   inclua {{ .Token }} no corpo do e-mail, por exemplo:
--
--       <h2>Seu código de verificação</h2>
--       <p>Use o código abaixo para recuperar seu acesso:</p>
--       <h1>{{ .Token }}</h1>
--       <p>Ele expira em 1 hora. Se você não solicitou, ignore este e-mail.</p>
--
-- ============================================================================
-- 5) (OPCIONAL) OTP POR SMS
-- ============================================================================
--   Dashboard → Authentication → Providers → Phone → habilitar e conectar
--   Twilio ou MessageBird. O auth.js já detecta telefone automaticamente
--   (basta o usuário digitar +55...), nenhuma mudança de código necessária.
-- ============================================================================
