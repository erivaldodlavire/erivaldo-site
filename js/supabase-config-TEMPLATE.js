/* ============================================================================
 * SUPABASE-CONFIG.JS — Configuração Central (Multi-Tenant) — TEMPLATE PADRÃO
 * ============================================================================
 * INSTRUÇÕES PARA USAR ESTE ARQUIVO:
 * 
 * 1. Ao clonar um novo repositório para um cliente, ESTE arquivo já vem
 *    com placeholders genéricos (TEMPLATE_XXX)
 * 
 * 2. Você PERSONALIZA UMA VEZ e faz commit — pronto!
 * 
 * 3. A partir daí, este arquivo NO SEU REPOSITÓRIO é 100% ISOLADO do
 *    repositório de outro cliente (Gleyciane, outro cliente, etc.)
 * 
 * 4. Cada repositório tem sua própria branch/cópia com suas próprias
 *    configurações — sem conflitos, sem atualizações cruzadas.
 *
 * CAMPOS A PERSONALIZAR (abaixo):
 *   - TEMPLATE_ID           → slug único (ex: "gleyciane" ou "cliente_001")
 *   - TEMPLATE_NOME         → nome completo (ex: "Gleyciane Araújo")
 *   - TEMPLATE_MARCA        → profissão/marca (ex: "Advocacia")
 *   - TEMPLATE_SCHEMA       → nome do schema isolado (ex: "gleyciane")
 * ========================================================================== */

window.SUPABASE_CONFIG = {
    // ⚠️ ATENÇÃO: Estes valores são COMPARTILHADOS entre TODOS os clientes
    // (mesmo projeto Supabase, mesma chave pública)
    // RLS + schema isolado garantem segurança
    
    url: 'https://bguslrxqkrlrueafetzh.supabase.co',
    anonKey: 'sb_publishable_ZpEyI4ldSV5-ZbXKZFuYyQ_YRPXB4mz',

    // 🔧 CUSTOMIZE AQUI (substitua TEMPLATE_XXX pelos dados reais do cliente)
    cliente: {
        id: 'TEMPLATE_ID',                    // ex: "gleyciane", "erivaldo", "cliente_001"
        nome: 'TEMPLATE_NOME',                // ex: "Gleyciane Araújo"
        marca: 'TEMPLATE_MARCA',              // ex: "Advocacia", "Consultoria", "Fitness"
        schema: 'TEMPLATE_SCHEMA',            // ex: "gleyciane" (deve ser IGUAL ao id, em minúsculas)
    },

    // Webhooks do n8n (serão preenchidos depois quando n8n estiver rodando)
    n8n: {
        webhookLeads: '',
        webhookEventos: '',
    },

    // Rotas internas (deixa como está)
    rotas: {
        login: 'login.html',
        admin: 'admin.html',
        site: 'index.html',
    },
};

/* ============================================================================
 * INICIALIZAÇÃO: Cria cliente Supabase com schema isolado forçado
 * 
 * Quando o navegador carrega, isto garante que TODAS as queries vão para
 * o schema correto (definido acima em cliente.schema).
 * 
 * Exemplos:
 *   - Gleyciane carrega → todas as queries vão pro schema "gleyciane"
 *   - Erivaldo carrega → todas as queries vão pro schema "erivaldo"
 *   - Cliente X carrega → todas as queries vão pro schema "cliente_x"
 * 
 * RLS + schema duplo-isolamento = segurança máxima
 * ========================================================================== */

if (typeof supabase !== 'undefined') {
    const cfg = window.SUPABASE_CONFIG;
    
    // Validação: não pode deixar TEMPLATE_SCHEMA no código
    if (cfg.cliente.schema === 'TEMPLATE_SCHEMA' || cfg.cliente.schema === '') {
        console.error('❌ ERRO: supabase-config.js ainda tem TEMPLATE_SCHEMA não preenchido!');
        console.error('   Edite o arquivo e substitua TEMPLATE_XXX pelos dados reais.');
        throw new Error('Configuração do Supabase incompleta. Veja console para detalhes.');
    }
    
    const schemaCliente = cfg.cliente.schema;
    
    // Cria cliente Supabase com o schema forçado
    window.supabaseClient = supabase.createClient(
        cfg.url,
        cfg.anonKey,
        {
            db: { schema: schemaCliente },
        }
    );
    
    // Log de debug (remove em produção se quiser)
    console.log(`✅ [Supabase] Conectado para cliente: ${cfg.cliente.nome}`);
    console.log(`   Schema: ${schemaCliente}`);
}
