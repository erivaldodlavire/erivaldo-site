/* ============================================================================
 * SUPABASE-CONFIG.JS — Configuração Oficial (Erivaldo Silva)
 * ============================================================================ */

window.SUPABASE_CONFIG = {
    url: 'https://bguslrxqkrlrueafetzh.supabase.co',
    anonKey: 'sb_publishable_ZpEyI4ldSV5-ZbXKZFuYyQ_YRPXB4mz',

    cliente: {
        id: 'erivaldo',
        nome: 'Erivaldo Silva',
        marca: 'Advocacia',
        schema: 'erivaldo',
    },

    n8n: {
        webhookLeads: '',
        webhookEventos: '',
    },

    rotas: {
        login: 'login.html',
        admin: 'admin.html',
        site: 'index.html',
    },
};

if (typeof supabase !== 'undefined') {
    const cfg = window.SUPABASE_CONFIG;
    
    const schemaCliente = cfg.cliente.schema;
    window.supabaseClient = supabase.createClient(
        cfg.url,
        cfg.anonKey,
        { db: { schema: schemaCliente } }
    );
    
    console.log(`✅ [Supabase] Conectado para cliente: ${cfg.cliente.nome}`);
    console.log(`   Schema: ${schemaCliente}`);
}