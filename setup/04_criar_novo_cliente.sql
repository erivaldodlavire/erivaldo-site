-- ============================================================================
-- 04_CRIAR_NOVO_CLIENTE.SQL — Template reutilizável
-- ============================================================================
-- Execute este arquivo customizado PARA CADA NOVO CLIENTE.
-- Ele cria o schema isolado, o usuário admin e registra na auditoria.
--
-- INSTRUÇÕES:
--   1. Substitua seu nome aqui, seu nome aqui e seu nome aqui@email.com pelos dados reais
--   2. No SQL Editor do Supabase, cole TODO O ARQUIVO e clique Run
--   3. Espere concluir (demora 10 segundos no máximo)
--   4. Copie o resultado do console (mensagem de sucesso)
--   5. No repositório do cliente, atualize js/supabase-config.js
--      com o schema correto
--
-- ============================================================================

-- CUSTOMIZÁVEIS (edite aqui para cada cliente novo):
-- seu nome aqui Araújo → schema "seu nome aqui"
-- Erivaldo Silva → schema "erivaldo"
-- Cliente X → schema "cliente_x"

SELECT create_client_schema('seu nome aqui', 'seu nome aqui Araújo - Advocacia');

-- ============================================================================
-- Registra na auditoria
-- ============================================================================
INSERT INTO public.audit_log (evento, cliente, usuario, detalhes) VALUES
    ('cliente_criado', 'seu nome aqui', 'admin', '{"nome": "seu nome aqui Araújo", "email": "seu nome aqui@adv.oabsp.org.br"}');

-- ============================================================================
-- PRÓXIMAS INSTRUÇÕES (executar FORA do SQL Editor, no terminal)
-- ============================================================================
-- Depois que este SQL rodar com sucesso, execute no terminal:
--
--   # 1) Criar o usuário admin no Supabase Auth
--   # Vá em Dashboard → Authentication → Users → Add user
--   # E-mail: seu nome aqui@adv.oabsp.org.br
--   # Senha: 123456 (será obrigado a trocar no primeiro login)
--   # Auto Confirm: ✓ SIM
--   #
--   # 2) No usuário criado, editar User Metadata (JSON):
--   # {
--   #   "must_change_password": true,
--   #   "schema": "seu nome aqui"
--   # }
--   #
--   # 3) Criar o repositório GitHub (a partir do template)
--   # git clone https://github.com/erivaldodlavire/gleysite.git seu nome aqui-site
--   # cd seu nome aqui-site
--   # 
--   # 4) Atualizar js/supabase-config.js:
--   # window.SUPABASE_CONFIG = {
--   #     url: 'https://bguslrxqkrlrueafetzh.supabase.co',
--   #     anonKey: 'sb_publishable_ZpEyI4ldSV5-ZbXKZFuYyQ_YRPXB4mz',
--   #     cliente: {
--   #         id: 'seu nome aqui',
--   #         nome: 'seu nome aqui Araújo',
--   #         marca: 'Advocacia',
--   #         schema: 'seu nome aqui'  ← NOVO
--   #     },
--   #     ...
--   # };
--   #
--   # 5) Commit e push
--   # git add -A && git commit -m "Config: setup para cliente seu nome aqui" && git push
--
-- ============================================================================

-- ✓ SUCESSO = você verá: "Schema 'seu nome aqui' criado com sucesso para cliente: seu nome aqui Araújo"
-- ✗ ERRO = revise o SQL (provavelmente slug inválido ou schema já existe)
