/* ============================================================================
 * SUPABASE-CONFIG.JS — Configuração Central (Multi-Tenant) — TEMPLATE PADRÃO
 * ============================================================================
 * IMPORTANTE: 
 * - Se contiver TEMPLATE_XXX → Site-modelo (MOLDE) → NÃO conecta a dados reais
 * - Se tiver dados reais (gleyciane, erivaldo, etc) → Conecta normalmente
 * ========================================================================== */

window.SUPABASE_CONFIG = {
    url: 'https://bguslrxqkrlrueafetzh.supabase.co',
    anonKey: 'sb_publishable_ZpEyI4ldSV5-ZbXKZFuYyQ_YRPXB4mz',

    cliente: {
        id: 'erivaldo',                    // ex: "gleyciane", "erivaldo"
        nome: 'Erivaldo Silva',                // ex: "Gleyciane Araújo"
        marca: 'Advocacia',              // ex: "Advocacia"
        schema: 'erivaldo',            // ex: "gleyciane"
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

/* ============================================================================
 * INICIALIZAÇÃO: Cria cliente Supabase com schema isolado
 * 
 * LÓGICA:
 * 1. Se ainda tem TEMPLATE_XXX → É Site-modelo (não conecta de verdade)
 * 2. Se tem dados reais → Conecta normalmente ao schema específico
 * ========================================================================== */

if (typeof supabase !== 'undefined') {
    const cfg = window.SUPABASE_CONFIG;
    
    // ⚠️ GUARDA: Se ainda tem TEMPLATE_, não conecta (é apenas molde visual)
    const temTemplate = Object.values(cfg.cliente).some(v => 
        typeof v === 'string' && v.includes('TEMPLATE')
    );
    
    if (temTemplate) {
        console.warn('⚠️ [Supabase] Modo TEMPLATE detectado.');
        console.warn('   Site-modelo está em modo OFFLINE/DEMO (sem dados reais).');
        console.warn('   Para ativar, execute: ./setup-client.sh <slug> "<nome>" "<marca>"');
        
        // Não conecta ao Supabase real quando tem TEMPLATE_
        // Isto impede que alterações em um cliente afetem o Site-modelo
        window.supabaseClient = null;
        window.SUPABASE_MODO_DEMO = true; // Flag para app.js/admin.js saberem que está em demo
        return;
    }
    
    // ✅ NORMAL: Tem dados reais, conecta normalmente
    const schemaCliente = cfg.cliente.schema;
    
    if (!schemaCliente || schemaCliente === '') {
        console.error('❌ ERRO: schema vazio!');
        throw new Error('Configuração do Supabase incompleta.');
    }
    
    window.supabaseClient = supabase.createClient(
        cfg.url,
        cfg.anonKey,
        { db: { schema: schemaCliente } }
    );
    
    console.log(`✅ [Supabase] Conectado para cliente: ${cfg.cliente.nome}`);
    console.log(`   Schema: ${schemaCliente}`);
}
