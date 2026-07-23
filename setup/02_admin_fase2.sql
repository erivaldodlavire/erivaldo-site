-- ============================================================================
-- 02_ADMIN_FASE2.SQL — Migração da Fase 2 (Painel Administrativo)
-- ============================================================================
-- Execute no Supabase: Dashboard → SQL Editor → colar → Run.
-- Idempotente (IF NOT EXISTS): pode rodar quantas vezes quiser.
--
-- Adiciona ao site_config as colunas que o novo Admin gerencia:
--   whats        → número do WhatsApp (só dígitos com DDI)
--   depoimentos  → [{ t: "texto", n: "nome do cliente" }]
--   aparencia    → { tema: "advogado", custom: { primary, accent } | null }
--   integracao   → { webhookLeads: url, webhookEventos: url }  (n8n)
-- (layout e audio já foram criados na Fase 1.)
-- ============================================================================

ALTER TABLE public.site_config
    ADD COLUMN IF NOT EXISTS whats        text,
    ADD COLUMN IF NOT EXISTS depoimentos  jsonb,
    ADD COLUMN IF NOT EXISTS aparencia    jsonb,
    ADD COLUMN IF NOT EXISTS integracao   jsonb;

-- Semente de aparência padrão para instalações que ainda estão vazias
UPDATE public.site_config
SET aparencia = '{"tema": "advogado", "custom": null}'::jsonb
WHERE id = 1 AND aparencia IS NULL;
