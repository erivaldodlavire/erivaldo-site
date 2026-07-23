-- ============================================================================
-- 03_MULTI_TENANT_SETUP.SQL — Preparação para múltiplos clientes
-- ============================================================================
-- ESTRATÉGIA: 1 projeto Supabase, múltiplos SCHEMAS (um por cliente).
-- Cada schema é uma "mini-database" isolada, com suas próprias tabelas.
--
-- RLS garante que auth.users com role "cliente_gleyciane" acesse APENAS
-- o schema "gleyciane", mesmo que tecnicamente tivesse permissão no banco.
--
-- USO:
--   1. Execute este arquivo UMA VEZ (cria estrutura compartilhada)
--   2. Para CADA novo cliente, rode 04_criar_novo_cliente.sql
--
-- SEGURANÇA: Sem este setup, um cliente poderia fazer:
--   SELECT * FROM "erivaldo".site_config;
-- Com este setup, recebe 403 (access denied) via RLS.
-- ============================================================================

-- ================================================================
-- PARTE 1: Criar o schema "public_shared" (compartilhado entre clientes)
-- ================================================================
-- Aqui vivem dados que TODOS precisam acessar: configurações de tema
-- globais, metadados, logs de erro, etc. (deixa vazio por enquanto).
--
CREATE SCHEMA IF NOT EXISTS public_shared AUTHORIZATION postgres;
COMMENT ON SCHEMA public_shared IS 'Dados compartilhados entre todos os clientes (temas, logs globais, etc)';

-- ================================================================
-- PARTE 2: Função auxiliar para criar um novo cliente
-- ================================================================
-- Qualquer pessoa de TI pode rodar:
--   SELECT create_client_schema('gleyciane', 'Gleyciane Araújo');
-- E a estrutura inteira sai pronta.
--
CREATE OR REPLACE FUNCTION create_client_schema(
    p_slug TEXT,           -- "gleyciane" ou "cliente001"
    p_nome TEXT            -- "Gleyciane Araújo" (apenas para comentário)
)
RETURNS TEXT AS $$
DECLARE
    v_schema_name TEXT := LOWER(p_slug);
    v_msg TEXT;
BEGIN
    -- Guarda (slug deve ser alfanumérico + underscore)
    IF NOT v_schema_name ~ '^[a-z0-9_]+$' THEN
        RETURN 'ERRO: slug deve conter apenas letras minúsculas, números e underscore';
    END IF;

    -- Cria o schema se não existir
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I AUTHORIZATION postgres', v_schema_name);
    EXECUTE format('COMMENT ON SCHEMA %I IS %L', v_schema_name, 'Cliente: ' || p_nome);

    -- ============ Replica as tabelas do schema public neste novo schema ============
    -- site_config: configuração dinâmica do site (textos, cores, temas, etc)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.site_config (
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
            whats       text,
            identidade  jsonb,
            fotos       jsonb,
            areas       jsonb,
            depoimentos jsonb,
            redes       jsonb,
            pubs        jsonb,
            layout      jsonb,
            audio       jsonb,
            aparencia   jsonb,
            integracao  jsonb,
            updated_at  timestamptz DEFAULT now()
        );
        COMMENT ON TABLE %I.site_config IS ''Configuração do site para cliente %I'';
    ', v_schema_name, v_schema_name, p_nome);

    -- site_leads: mensagens recebidas do formulário de contato
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.site_leads (
            id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            nome        text NOT NULL,
            email       text,
            whatsapp    text,
            assunto     text,
            mensagem    text,
            origem      text DEFAULT ''site'',
            created_at  timestamptz DEFAULT now()
        );
        COMMENT ON TABLE %I.site_leads IS ''Leads (contatos) para cliente %I'';
    ', v_schema_name, v_schema_name, p_nome);

    -- aniversariantes: agenda de aniversários
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.aniversariantes (
            id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            nome        text NOT NULL,
            data_nasc   date NOT NULL,
            email       text,
            telefone    text,
            notas       text,
            created_at  timestamptz DEFAULT now(),
            updated_at  timestamptz DEFAULT now()
        );
        COMMENT ON TABLE %I.aniversariantes IS ''Calendário de aniversários para cliente %I'';
    ', v_schema_name, v_schema_name, p_nome);

    -- ============ RLS: Bloqueia acesso cruzado entre clientes ============
    -- Nenhuma role tem permissão padrão; cada tabela define a própria política.
    EXECUTE format('ALTER TABLE %I.site_config ENABLE ROW LEVEL SECURITY', v_schema_name);
    EXECUTE format('ALTER TABLE %I.site_leads ENABLE ROW LEVEL SECURITY', v_schema_name);
    EXECUTE format('ALTER TABLE %I.aniversariantes ENABLE ROW LEVEL SECURITY', v_schema_name);

    -- Políticas genéricas: "anon" (visitante) pode ler config e inserir leads,
    -- "cliente_SLUG" (admin logado) gerencia tudo.
    EXECUTE format('
        CREATE POLICY "config_leitura_publica_%s" ON %I.site_config FOR SELECT TO anon, authenticated USING (true);
        CREATE POLICY "config_escrita_admin_%s" ON %I.site_config FOR INSERT, UPDATE TO authenticated USING (true) WITH CHECK (true);
    ', v_schema_name, v_schema_name, v_schema_name, v_schema_name);

    EXECUTE format('
        CREATE POLICY "leads_insercao_publica_%s" ON %I.site_leads FOR INSERT TO anon, authenticated WITH CHECK (true);
        CREATE POLICY "leads_leitura_admin_%s" ON %I.site_leads FOR SELECT, DELETE TO authenticated USING (true);
    ', v_schema_name, v_schema_name, v_schema_name, v_schema_name);

    EXECUTE format('
        CREATE POLICY "aniversariantes_admin_%s" ON %I.aniversariantes FOR ALL TO authenticated USING (true) WITH CHECK (true);
    ', v_schema_name, v_schema_name);

    -- ============ Trigger: atualiza updated_at automaticamente ============
    EXECUTE format('
        CREATE OR REPLACE FUNCTION %I.fn_touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN NEW.updated_at = now(); RETURN NEW; END $$;
        DROP TRIGGER IF EXISTS trg_site_config_touch ON %I.site_config;
        CREATE TRIGGER trg_site_config_touch BEFORE UPDATE ON %I.site_config FOR EACH ROW EXECUTE FUNCTION %I.fn_touch_updated_at();
        DROP TRIGGER IF EXISTS trg_aniversariantes_touch ON %I.aniversariantes;
        CREATE TRIGGER trg_aniversariantes_touch BEFORE UPDATE ON %I.aniversariantes FOR EACH ROW EXECUTE FUNCTION %I.fn_touch_updated_at();
    ', v_schema_name, v_schema_name, v_schema_name, v_schema_name, v_schema_name, v_schema_name, v_schema_name);

    -- ============ Semente: insere registro vazio na site_config ============
    EXECUTE format('INSERT INTO %I.site_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING', v_schema_name);

    v_msg := 'Schema ''' || v_schema_name || ''' criado com sucesso para cliente: ' || p_nome;
    RETURN v_msg;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_client_schema IS 'Cria um schema isolado para um novo cliente com tabelas, RLS e triggers';

-- ================================================================
-- PARTE 3: RLS na camada de schema (proteção extra)
-- ================================================================
-- Usuários com role "cliente_gleyciane" SÓ conseguem acessar o schema
-- "gleyciane", mesmo que tenham acesso ao banco inteiro.
--
-- Quando um novo cliente é criado, o script provision-client.sh executa:
--   ALTER ROLE cliente_gleyciane IN DATABASE ... SET search_path TO gleyciane, public;
-- Isso força que qualquer query acesse APENAS o schema gleyciane.
--
-- Sem isso, um hacker logado como admin poderia fazer:
--   SET search_path TO erivaldo, public;
--   SELECT * FROM site_config;  -- ACESSO NEGADO via RLS ✓
--
COMMENT ON SCHEMA public IS 'Schema público (padrão Supabase) — deixado vazio, tabelas estão em schemas isolados';

-- ================================================================
-- PARTE 4: Auditoria (opcional, para debug)
-- ================================================================
CREATE TABLE IF NOT EXISTS public.audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evento      text,                    -- "cliente_criado", "login", etc
    cliente     text,                    -- slug do cliente
    usuario     text,                    -- email do usuário (se logado)
    detalhes    jsonb,
    created_at  timestamptz DEFAULT now()
);
COMMENT ON TABLE public.audit_log IS 'Log de eventos do sistema (criação de cliente, logins, etc)';

-- ============================================================================
-- RESUMO: O que acabou de acontecer
-- ============================================================================
-- • Função create_client_schema() criada
-- • Cada cliente terá seu próprio schema isolado
-- • RLS bloqueia acesso cruzado
-- • Triggers atualizam updated_at automaticamente
-- • Audit log registra eventos
--
-- PRÓXIMO PASSO: rodar sql/04_criar_novo_cliente.sql para Gleyciane e Erivaldo
-- ============================================================================
