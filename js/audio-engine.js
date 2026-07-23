/* ============================================================================
 * AUDIO-ENGINE.JS — Motor de Áudio Temático (UI/UX Sensorial)
 * ============================================================================
 * Decisão de arquitetura: os sons são SINTETIZADOS em tempo real com a
 * Web Audio API em vez de arquivos .mp3. Vantagens para um template SaaS:
 *   • Zero downloads extras → site continua leve (requisito do projeto).
 *   • Zero problemas de licença de áudio ao revender para clientes.
 *   • Sons ajustáveis por código (pitch/duração) para casar com cada tema.
 * (Se um dia quiser samples reais, basta adicionar um pacote que dê
 *  play em <audio> — a interface pública não muda.)
 *
 * Pacotes disponíveis (vinculados aos temas pelo theme-engine.js):
 *   elegante   → clique de madeira sutil (Advocacia, Contábil, Minimalista)
 *   engrenagem → tique mecânico duplo (Engenharia)
 *   clinico    → bip suave e limpo (Saúde)
 *   agua       → bolha subindo (Natação)
 *   quadra     → quique de bola grave (Basquete)
 *   impacto    → soco abafado (Artes Marciais)
 *   digital    → blip sci-fi descendente (Cyberpunk)
 *   arcade     → chirp 8-bit (Gamer/Youtuber)
 *
 * Regras de UX aplicadas:
 *   • Volume MUITO baixo por padrão (feedback, não trilha sonora).
 *   • Hover tem versão mais curta/baixa que o clique.
 *   • Throttle de 120ms no hover (passar o mouse rápido não vira metralhadora).
 *   • AudioContext só é criado após o 1º gesto do usuário (exigência dos
 *     navegadores) — antes disso, tudo falha em silêncio, sem erros.
 *   • Respeita prefers-reduced-motion como sinal de sensibilidade sensorial.
 * ========================================================================== */

window.AudioEngine = (() => {
    'use strict';

    let ctx = null;              // AudioContext (lazy)
    let master = null;           // GainNode geral
    let ativo = false;           // liga/desliga (controlado pelo Admin)
    let pacoteAtual = 'elegante';
    let fixadoManual = false;    // true = Admin escolheu pacote na mão (não segue o tema)
    let ultimoHover = 0;         // throttle

    const VOLUME_GERAL = 0.14;   // teto de volume — sutileza acima de tudo

    // ------------------------------------------------------------------ //
    // INFRAESTRUTURA
    // ------------------------------------------------------------------ //
    function garantirContexto() {
        if (ctx) return true;
        try {
            ctx = new (window.AudioContext || window.webkitAudioContext)();
            master = ctx.createGain();
            master.gain.value = VOLUME_GERAL;
            master.connect(ctx.destination);
            return true;
        } catch { return false; }
    }

    /** Toca um tom simples. Todos os parâmetros têm defaults sensatos.
     *  @param {object} o  { freq, freqFinal, tipo, dur, ganho, atraso, filtro } */
    function tom(o = {}) {
        const t0 = ctx.currentTime + (o.atraso || 0);
        const osc = ctx.createOscillator();
        const g = ctx.createGain();
        osc.type = o.tipo || 'sine';
        osc.frequency.setValueAtTime(o.freq || 440, t0);
        if (o.freqFinal) osc.frequency.exponentialRampToValueAtTime(o.freqFinal, t0 + (o.dur || 0.1));

        // Envelope: ataque instantâneo, decaimento exponencial (som "clique")
        g.gain.setValueAtTime(o.ganho ?? 0.8, t0);
        g.gain.exponentialRampToValueAtTime(0.001, t0 + (o.dur || 0.1));

        let saida = g;
        if (o.filtro) { // passa-baixa opcional para abafar (soco, quique)
            const f = ctx.createBiquadFilter();
            f.type = 'lowpass'; f.frequency.value = o.filtro;
            g.connect(f); saida = f;
        }
        osc.connect(g); saida.connect(master);
        osc.start(t0); osc.stop(t0 + (o.dur || 0.1) + 0.05);
    }

    /** Rajada de ruído filtrado (impactos, texturas) */
    function ruido(o = {}) {
        const t0 = ctx.currentTime + (o.atraso || 0);
        const dur = o.dur || 0.08;
        const buffer = ctx.createBuffer(1, ctx.sampleRate * dur, ctx.sampleRate);
        const dados = buffer.getChannelData(0);
        for (let i = 0; i < dados.length; i++) dados[i] = Math.random() * 2 - 1;

        const fonte = ctx.createBufferSource();
        fonte.buffer = buffer;
        const g = ctx.createGain();
        g.gain.setValueAtTime(o.ganho ?? 0.5, t0);
        g.gain.exponentialRampToValueAtTime(0.001, t0 + dur);
        const f = ctx.createBiquadFilter();
        f.type = o.tipoFiltro || 'lowpass';
        f.frequency.value = o.filtro || 800;
        fonte.connect(g); g.connect(f); f.connect(master);
        fonte.start(t0);
    }

    // ------------------------------------------------------------------ //
    // PACOTES SONOROS — cada um define { hover(), click() }
    // ------------------------------------------------------------------ //
    const PACOTES = {
        elegante: {
            nome: 'Elegante (clique clássico)',
            hover: () => tom({ freq: 1800, dur: 0.03, ganho: 0.25 }),
            click: () => tom({ freq: 1200, freqFinal: 700, dur: 0.06, ganho: 0.6, tipo: 'triangle' }),
        },
        engrenagem: {
            nome: 'Engrenagem (mecânico)',
            hover: () => tom({ freq: 900, dur: 0.02, ganho: 0.3, tipo: 'square', filtro: 1500 }),
            click: () => { // tique-taque duplo, como catraca de engrenagem
                tom({ freq: 700, dur: 0.03, ganho: 0.5, tipo: 'square', filtro: 1800 });
                tom({ freq: 500, dur: 0.04, ganho: 0.45, tipo: 'square', filtro: 1400, atraso: 0.06 });
            },
        },
        clinico: {
            nome: 'Clínico (bip suave)',
            hover: () => tom({ freq: 1400, dur: 0.04, ganho: 0.2 }),
            click: () => tom({ freq: 980, dur: 0.09, ganho: 0.5 }),
        },
        agua: {
            nome: 'Água (bolhas)',
            hover: () => tom({ freq: 500, freqFinal: 900, dur: 0.07, ganho: 0.3 }),
            click: () => { // bolha subindo + segunda bolha menor
                tom({ freq: 350, freqFinal: 1100, dur: 0.12, ganho: 0.55 });
                tom({ freq: 600, freqFinal: 1500, dur: 0.08, ganho: 0.3, atraso: 0.09 });
            },
        },
        quadra: {
            nome: 'Quadra (quique de bola)',
            hover: () => tom({ freq: 220, freqFinal: 140, dur: 0.05, ganho: 0.4, filtro: 500 }),
            click: () => { // quique grave + eco curto
                tom({ freq: 180, freqFinal: 90, dur: 0.12, ganho: 0.8, filtro: 400 });
                ruido({ dur: 0.03, ganho: 0.15, filtro: 600 });
            },
        },
        impacto: {
            nome: 'Impacto (soco abafado)',
            hover: () => ruido({ dur: 0.03, ganho: 0.2, filtro: 700 }),
            click: () => {
                ruido({ dur: 0.09, ganho: 0.6, filtro: 500 });
                tom({ freq: 120, freqFinal: 60, dur: 0.12, ganho: 0.7, filtro: 300 });
            },
        },
        digital: {
            nome: 'Digital (sci-fi)',
            hover: () => tom({ freq: 2400, freqFinal: 1800, dur: 0.04, ganho: 0.25, tipo: 'sawtooth', filtro: 3000 }),
            click: () => tom({ freq: 1600, freqFinal: 300, dur: 0.14, ganho: 0.5, tipo: 'sawtooth', filtro: 2500 }),
        },
        arcade: {
            nome: 'Arcade (8-bit)',
            hover: () => tom({ freq: 880, dur: 0.03, ganho: 0.25, tipo: 'square' }),
            click: () => { // chirp subindo estilo "coin"
                tom({ freq: 660, dur: 0.05, ganho: 0.45, tipo: 'square' });
                tom({ freq: 990, dur: 0.09, ganho: 0.45, tipo: 'square', atraso: 0.05 });
            },
        },
    };

    // ------------------------------------------------------------------ //
    // DISPARO
    // ------------------------------------------------------------------ //
    function tocar(tipo /* 'hover' | 'click' */) {
        if (!ativo) return;
        // Usuário sinalizou sensibilidade a estímulos → silêncio respeitoso
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
        if (!garantirContexto()) return;
        if (ctx.state === 'suspended') ctx.resume();

        if (tipo === 'hover') {
            const agora = performance.now();
            if (agora - ultimoHover < 120) return; // throttle anti-metralhadora
            ultimoHover = agora;
        }
        try { PACOTES[pacoteAtual]?.[tipo]?.(); } catch { /* nunca quebrar a UI por causa de som */ }
    }

    // ------------------------------------------------------------------ //
    // VÍNCULO AUTOMÁTICO COM O DOM (event delegation — 2 listeners no total,
    // funciona até para elementos criados dinamicamente pelo Layout Builder)
    // ------------------------------------------------------------------ //
    const SELETOR_INTERATIVO = 'a, button, .card, .tema-card, [data-som]';

    function ligarNoDom() {
        document.addEventListener('mouseover', (e) => {
            const alvo = e.target.closest(SELETOR_INTERATIVO);
            // mouseover borbulha entre filhos; só toca ao ENTRAR no elemento
            if (alvo && !alvo.contains(e.relatedTarget)) tocar('hover');
        });
        document.addEventListener('click', (e) => {
            if (e.target.closest(SELETOR_INTERATIVO)) tocar('click');
        });
    }

    // ------------------------------------------------------------------ //
    // API PÚBLICA (consumida pelo Admin e pelo theme-engine)
    // ------------------------------------------------------------------ //
    return {
        ligarNoDom,
        tocar,
        /** Aplica configuração salva: { ativo: bool, pacote: 'auto'|nome } */
        configurar(cfgAudio) {
            ativo = cfgAudio?.ativo === true;
            if (cfgAudio?.pacote && cfgAudio.pacote !== 'auto' && PACOTES[cfgAudio.pacote]) {
                pacoteAtual = cfgAudio.pacote;
                fixadoManual = true;
            } else {
                fixadoManual = false; // 'auto' → segue o tema
            }
        },
        setAtivo(v) { ativo = !!v; },
        setPacote(nome, { manual = true } = {}) {
            if (!PACOTES[nome]) return;
            pacoteAtual = nome;
            if (manual) fixadoManual = true;
        },
        pacoteManual: () => fixadoManual,
        listarPacotes: () => Object.entries(PACOTES).map(([id, p]) => ({ id, nome: p.nome })),
        getEstado: () => ({ ativo, pacote: fixadoManual ? pacoteAtual : 'auto', pacoteEfetivo: pacoteAtual }),
    };
})();
