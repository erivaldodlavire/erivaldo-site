/* ============================================================================
 * SUPABASE-CONFIG.JS — Configuração Central do Projeto (Multi-Tenant)
 * ============================================================================
 * WHITE-LABEL: Este é o ÚNICO arquivo que muda entre clientes/instâncias.
 * 
 * ANTES (1 projeto, 1 banco de dados):
 *   Gleyciane → tabelas na aba "public"
 *   Erivaldo → CONFLITO, mesmas tabelas
 * 
 * AGORA (1 projeto, múltiplos schemas):
 *   Gleyciane → schema "gleyciane" (tabelas isoladas)
 *   Erivaldo → schema "erivaldo" (tabelas isoladas)
 *   Cliente 001 → schema "cliente_001" (tabelas isoladas)
 *
 * O campo `schema` abaixo define qual mini-database este site acessa.
 * RLS garante que mesmo logado, você ONLY vê dados do seu schema.
 * ========================================================================== */

window.SUPABASE_CONFIG = {
    // URL do projeto (todos os clientes compartilham o mesmo projeto)
    url: 'https://bguslrxqkrlrueafetzh.supabase.co',

    // Chave pública "anon" (MESMO para todos — seguro via RLS + schema)
    anonKey: 'sb_publishable_ZpEyI4ldSV5-ZbXKZFuYyQ_YRPXB4mz',

    // Identidade do cliente desta instância
    cliente: {
        id: 'seunomeid',            // slug único
        nome: 'seu nome aqui',
        marca: 'Marca profissao',
        schema: 'seunomeaqui',               // ← NOVO: qual schema isolado usar
                                           // Cada cliente aponta pro seu próprio schema
    },

    // Webhooks do n8n (centralizado)
    n8n: {
        webhookLeads: '',
        webhookEventos: '',
    },

    // Rotas internas
    rotas: {
        login: 'login.html',
        admin: 'admin.html',
        site: 'index.html',
    },
};

/* ============================================================================
 * COMO USAR ISTO NO CÓDIGO
 * ============================================================================
 * 
 * Ao criar o cliente Supabase, IGNORE o schema por enquanto.
 * O seu app.js e admin.js já usam a anonKey, que funciona em qualquer schema
 * graças à RLS que configuramos.
 * 
 * MAS: se você quiser forçar o schema no auth.js (para performance),
 * seria assim:
 * 
 *   const db = supabase.createClient(cfgApp.url, cfgApp.anonKey, {
 *       db: {
 *           schema: cfgApp.cliente.schema,  // ← força o schema aqui
 *       }
 *   });
 * 
 * Atualmente, o nosso código NÃO faz isso (não é necessário, RLS resolve).
 * Se implementar, DEPOIS precisarei atualizar auth.js, app.js e admin.js
 * para passar o schema.
 * ========================================================================== */
