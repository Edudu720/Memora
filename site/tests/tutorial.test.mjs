import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const tutorial = require('../scripts/tutorial.js');
const memoraDados = require('../assets/memora/memora-dados.js');
const memoraPersonagem = require('../scripts/memora-personagem.js');

test('normaliza escalas e temas desconhecidos para padroes seguros', () => {
  assert.equal(tutorial.normalizarEscala('padrao'), 'padrao');
  assert.equal(tutorial.normalizarEscala('grande'), 'grande');
  assert.equal(tutorial.normalizarEscala('muito-grande'), 'muito-grande');
  assert.equal(tutorial.normalizarEscala('gigante-invalido'), 'padrao');
  assert.equal(tutorial.normalizarEscala(null), 'padrao');

  assert.equal(tutorial.normalizarTema('claro'), 'claro');
  assert.equal(tutorial.normalizarTema('escuro'), 'escuro');
  assert.equal(tutorial.normalizarTema('alto-contraste'), 'alto-contraste');
  assert.equal(tutorial.normalizarTema('neon'), 'claro');
  assert.equal(tutorial.normalizarTema(undefined), 'claro');

  assert.equal(tutorial.normalizarMovimento('normal'), 'normal');
  assert.equal(tutorial.normalizarMovimento('reduzido'), 'reduzido');
  assert.equal(tutorial.normalizarMovimento('invalido'), 'normal');
  assert.equal(tutorial.normalizarMovimento(null), 'normal');
});

test('repositorio de preferencias persiste no storage e degrada sem erro se storage estiver bloqueado', () => {
  const dados = new Map();
  const storageSimulado = {
    getItem(k) {
      return dados.has(k) ? dados.get(k) : null;
    },
    setItem(k, v) {
      dados.set(k, String(v));
    },
  };

  const repo = tutorial.criarRepositorioPreferencias(storageSimulado);
  assert.deepEqual(repo.carregar(), { escala: 'padrao', tema: 'claro', movimento: 'normal' });

  repo.salvarEscala('muito-grande');
  repo.salvarTema('alto-contraste');
  repo.salvarMovimento('reduzido');
  assert.deepEqual(repo.carregar(), {
    escala: 'muito-grande',
    tema: 'alto-contraste',
    movimento: 'reduzido',
  });

  const storageBloqueado = {
    getItem() {
      throw new Error('SecurityError');
    },
    setItem() {
      throw new Error('QuotaExceededError');
    },
  };

  const repoSemStorage = tutorial.criarRepositorioPreferencias(storageBloqueado);
  assert.deepEqual(repoSemStorage.carregar(), {
    escala: 'padrao',
    tema: 'claro',
    movimento: 'normal',
  });
  assert.equal(repoSemStorage.salvarEscala('grande'), 'grande');
  assert.equal(repoSemStorage.salvarTema('escuro'), 'escuro');
  assert.equal(repoSemStorage.salvarMovimento('reduzido'), 'reduzido');
});

test('reduzir movimento segue prefers-reduced-motion quando nao ha escolha salva e aceita alternancia manual', () => {
  const dados = new Map();
  const storageSimulado = {
    getItem(k) {
      return dados.has(k) ? dados.get(k) : null;
    },
    setItem(k, v) {
      dados.set(k, String(v));
    },
  };

  // Sem preferencia salva + sistema com movimento reduzido -> inicia reduzido
  const repoSistema = tutorial.criarRepositorioPreferencias(storageSimulado, {
    movimentoSistemaReduzido: true,
  });
  assert.equal(repoSistema.carregar().movimento, 'reduzido');

  // Escolha manual da pessoa para voltar ao normal prevalece sobre o sistema
  assert.equal(repoSistema.salvarMovimento('normal'), 'normal');
  assert.equal(repoSistema.carregar().movimento, 'normal');

  assert.equal(tutorial.resolverMovimentoSistema({ matchMedia: () => ({ matches: true }) }), true);
  assert.equal(tutorial.resolverMovimentoSistema({ matchMedia: () => ({ matches: false }) }), false);
  assert.equal(tutorial.resolverMovimentoSistema(null), false);
});

test('controlador de voz fica oculto quando navegador nao suporta speechSynthesis', () => {
  const controlador = tutorial.criarControladorDeVoz({
    speechSynthesis: null,
    Utterance: null,
  });

  assert.equal(controlador.estaSuportado(), false);
  assert.equal(controlador.alternar('boas-vindas', 'Texto de exemplo'), false);
  assert.deepEqual(controlador.obterEstado(), {
    suportado: false,
    secaoAtivaId: null,
    status: 'ocioso',
  });
});

test('controlador de voz garante apenas um capitulo falando por vez e retorna a ocioso ao finalizar', () => {
  const eventos = [];
  let cancelamentos = 0;
  const falas = [];

  class UtteranceFalsa {
    constructor(texto) {
      this.text = texto;
      this.lang = '';
      this.rate = 1;
      this.pitch = 1;
      this.onend = null;
      this.onerror = null;
    }
  }

  const controlador = tutorial.criarControladorDeVoz({
    speechSynthesis: {
      cancel() {
        cancelamentos += 1;
      },
      speak(u) {
        falas.push(u);
      },
    },
    Utterance: UtteranceFalsa,
    aoMudarEstado(st) {
      eventos.push(st);
    },
  });

  assert.equal(controlador.estaSuportado(), true);

  assert.equal(controlador.alternar('boas-vindas', 'Bem-vindo ao Memora.'), true);
  assert.equal(falas.length, 1);
  assert.equal(falas[0].lang, 'pt-BR');
  assert.equal(controlador.obterEstado().secaoAtivaId, 'boas-vindas');
  assert.equal(controlador.obterEstado().status, 'lendo');

  // Acionar outro capítulo cancela o anterior antes de falar o novo
  assert.equal(controlador.alternar('primeiros-passos', 'Entre com sua frase secreta.'), true);
  assert.equal(cancelamentos, 2);
  assert.equal(controlador.obterEstado().secaoAtivaId, 'primeiros-passos');

  // Evento onend antigo do primeiro trecho nao zera o segundo trecho ativo
  falas[0].onend();
  assert.equal(controlador.obterEstado().status, 'lendo');
  assert.equal(controlador.obterEstado().secaoAtivaId, 'primeiros-passos');

  // Clicar novamente no mesmo capítulo interrompe a leitura
  assert.equal(controlador.alternar('primeiros-passos', 'Entre com sua frase secreta.'), false);
  assert.equal(controlador.obterEstado().status, 'ocioso');
  assert.equal(controlador.obterEstado().secaoAtivaId, null);
  assert.ok(eventos.length >= 3);
});

test('extrai exclusivamente conteudo educativo de leitura sem texto de controles', () => {
  const secaoFalsa = {
    querySelectorAll(seletor) {
      assert.equal(seletor, '[data-leitura-conteudo]');
      return [
        { textContent: '  Boas-vindas   ao Memora  ' },
        { textContent: 'Eu mostro o caminho e voce faz.' },
      ];
    },
  };

  assert.equal(
    tutorial.extrairTextoEducativo(secaoFalsa),
    'Boas-vindas ao Memora. Eu mostro o caminho e voce faz.'
  );
  assert.equal(tutorial.extrairTextoEducativo(null), '');
});

test('transicao entre capitulos usa startViewTransition quando permitido e desliga sob movimento reduzido', () => {
  let transicoes = 0;
  let executou = 0;

  const docComSuporte = {
    startViewTransition(fn) {
      transicoes += 1;
      fn();
    },
  };

  assert.equal(
    tutorial.executarNavegacaoComTransicao(() => { executou += 1; }, {
      document: docComSuporte,
      movimentoReduzido: false,
    }),
    true
  );
  assert.equal(transicoes, 1);
  assert.equal(executou, 1);

  assert.equal(
    tutorial.executarNavegacaoComTransicao(() => { executou += 1; }, {
      document: docComSuporte,
      movimentoReduzido: true,
    }),
    false
  );
  assert.equal(transicoes, 1);
  assert.equal(executou, 2);
});

test('memora-personagem monta as 9 expressoes com 14 grupos e pausa sob movimento reduzido ou fora da tela', () => {
  assert.equal(memoraPersonagem.EXPRESSOES_MEMORA.length, 9);
  assert.equal(memoraPersonagem.normalizarExpressaoMemora('desconhecida'), 'neutra');
  assert.equal(memoraPersonagem.normalizarExpressaoMemora('acenando'), 'acenando');

  for (const expr of memoraPersonagem.EXPRESSOES_MEMORA) {
    const svg = memoraPersonagem.montarSvgExpressao(memoraDados, expr);
    assert.ok(svg.includes(`data-expressao="${expr}"`), `SVG deve marcar expressao ${expr}`);
    for (const grupo of memoraDados.grupos) {
      assert.ok(svg.includes(`id="${grupo}"`), `Expressao ${expr} deve conter grupo ${grupo}`);
    }
  }

  let notificacoes = 0;
  const ctrl = memoraPersonagem.criarControladorPersonagem({
    expressao: 'acenando',
    falando: false,
    visivelNaTela: true,
    movimento: 'normal',
    aoAlterarAnimacao() {
      notificacoes += 1;
    },
  });

  assert.equal(ctrl.obterEstado().ativa, true);
  assert.equal(ctrl.pulsarBoca(), false);

  ctrl.definirFalando(true);
  assert.equal(ctrl.pulsarBoca(), true);
  assert.equal(ctrl.obterEstado().pulsosDeBoca, 1);

  assert.equal(ctrl.definirVisivelNaTela(false), false);
  assert.equal(ctrl.pulsarBoca(), false);
  assert.equal(ctrl.definirVisivelNaTela(true), true);

  assert.equal(ctrl.definirMovimento('reduzido'), false);
  assert.equal(ctrl.pulsarBoca(), false);
  assert.ok(notificacoes >= 3);
});

test('controlador da anfitria gira em 20s, pausa sob foco ou movimento reduzido e para de vez apos acao manual', () => {
  let proximoId = 1;
  const timersAtivos = new Map();
  const mudancas = [];

  const ctrl = tutorial.criarControladorDaAnfitria({
    dicas: memoraDados.dicasDaAnfitria,
    intervaloMs: 20000,
    movimento: 'normal',
    setIntervalFn(fn, ms) {
      assert.equal(ms, 20000);
      const id = proximoId++;
      timersAtivos.set(id, fn);
      return id;
    },
    clearIntervalFn(id) {
      timersAtivos.delete(id);
    },
    aoMudarDica(dica, indice, manual) {
      mudancas.push({ dica, indice, manual });
    },
  });

  assert.equal(ctrl.obterEstado().rotacaoAutomaticaAtiva, true);
  assert.equal(timersAtivos.size, 1);

  // Tick automatico avanca sem marcar acao manual (leitor de tela fica silencioso)
  const [tickAuto] = Array.from(timersAtivos.values());
  tickAuto();
  assert.equal(mudancas.length, 1);
  assert.equal(mudancas[0].indice, 1);
  assert.equal(mudancas[0].manual, false);

  // Foco interno pausa o timer e saida do foco retoma enquanto nao houve clique manual
  assert.equal(ctrl.definirFocoDentro(true), false);
  assert.equal(timersAtivos.size, 0);
  assert.equal(ctrl.definirFocoDentro(false), true);
  assert.equal(timersAtivos.size, 1);

  // Movimento reduzido pausa o timer e normal retoma antes de clique manual
  assert.equal(ctrl.definirMovimento('reduzido'), false);
  assert.equal(timersAtivos.size, 0);
  assert.equal(ctrl.definirMovimento('normal'), true);
  assert.equal(timersAtivos.size, 1);

  // Clique em "Outra dica da Memora" anuncia e encerra definitivamente a rotacao automatica
  const resManual = ctrl.avancarManual();
  assert.equal(resManual.indice, 2);
  assert.equal(resManual.rotacaoAutomaticaAtiva, false);
  assert.equal(mudancas[1].manual, true);
  assert.equal(timersAtivos.size, 0);

  assert.equal(ctrl.definirMovimento('normal'), false);
  assert.equal(ctrl.definirFocoDentro(false), false);
  assert.equal(timersAtivos.size, 0);
});

test('anfitria global pausa ao recolher, retoma ao expandir e adapta expressao ao capitulo ativo', () => {
  let proximoId = 1;
  const timers = new Map();
  const expMudancas = [];
  const exprMudancas = [];

  assert.equal(tutorial.resolverExpressaoDoCapitulo('boas-vindas'), 'acenando');
  assert.equal(tutorial.resolverExpressaoDoCapitulo('protecao-golpes'), 'preocupada');
  assert.equal(tutorial.resolverExpressaoDoCapitulo('duvidas-frequentes'), 'comemorando');
  assert.equal(tutorial.deveIniciarAnfitriaExpandida({ innerWidth: 1280 }, 'padrao'), true);
  assert.equal(tutorial.deveIniciarAnfitriaExpandida({ innerWidth: 1280 }, 'muito-grande'), false);
  assert.equal(tutorial.deveIniciarAnfitriaExpandida({ innerWidth: 390 }, 'padrao'), false);

  const ctrl = tutorial.criarControladorDaAnfitria({
    dicas: memoraDados.dicasDaAnfitria,
    intervaloMs: 20000,
    expandida: true,
    capituloInicial: 'boas-vindas',
    movimento: 'normal',
    setIntervalFn(fn) {
      const id = proximoId++;
      timers.set(id, fn);
      return id;
    },
    clearIntervalFn(id) {
      timers.delete(id);
    },
    aoMudarExpansao(aberta) {
      expMudancas.push(aberta);
    },
    aoMudarExpressao(expr, cap) {
      exprMudancas.push({ expr, cap });
    },
  });

  assert.equal(ctrl.obterEstado().expandida, true);
  assert.equal(ctrl.obterEstado().expressaoAtual, 'acenando');
  assert.equal(timers.size, 1);

  // Recolher para capsula pausa rotacao automatica; expandir retoma antes de clique manual
  assert.equal(ctrl.alternarExpandida(), false);
  assert.equal(ctrl.obterEstado().rotacaoAutomaticaAtiva, false);
  assert.equal(timers.size, 0);
  assert.equal(ctrl.alternarExpandida(), true);
  assert.equal(ctrl.obterEstado().rotacaoAutomaticaAtiva, true);
  assert.equal(timers.size, 1);
  assert.deepEqual(expMudancas, [false, true]);

  // Troca de capitulo so dispara callback quando a expressao realmente muda
  assert.equal(ctrl.atualizarCapitulo('primeiros-passos'), 'acenando');
  assert.equal(exprMudancas.length, 0);
  assert.equal(ctrl.atualizarCapitulo('protecao-golpes'), 'preocupada');
  assert.deepEqual(exprMudancas, [{ expr: 'preocupada', cap: 'protecao-golpes' }]);
});

test('controlador de voz sincroniza boca por boundary, fallback em pulso e desliga em movimento reduzido', () => {
  const pulsos = [];
  const falas = [];
  let modoMovimento = 'normal';
  let proximoId = 1;
  const timers = new Map();

  class FalaFalsa {
    constructor(texto) {
      this.text = texto;
      falas.push(this);
    }
  }

  const sintese = {
    speak(fala) {
      if (fala.onstart) fala.onstart();
    },
    cancel() {},
  };

  const ctrl = tutorial.criarControladorDeVoz({
    speechSynthesis: sintese,
    Utterance: FalaFalsa,
    obterMovimento: () => modoMovimento,
    aoPulsarBoca(secaoId, origem) {
      pulsos.push({ secaoId, origem });
    },
    setIntervalFn(fn, ms) {
      const id = proximoId++;
      timers.set(id, { fn, ms });
      return id;
    },
    clearIntervalFn(id) {
      timers.delete(id);
    },
    intervaloPulsoMs: 200,
  });

  // Fallback por pulso quando onboundary nao dispara
  assert.equal(ctrl.alternar('boas-vindas', 'Texto de boas-vindas.'), true);
  assert.equal(ctrl.obterModoSincroniaBoca(), 'pulso');
  assert.equal(timers.size, 1);
  assert.deepEqual(pulsos.at(-1), { secaoId: 'boas-vindas', origem: 'pulso' });
  const [{ fn: pulsoFn }] = Array.from(timers.values());
  pulsoFn();
  assert.deepEqual(pulsos.at(-1), { secaoId: 'boas-vindas', origem: 'pulso' });

  // Quando navegador dispara onboundary, assume modo boundary e encerra fallback
  falas[0].onboundary({ name: 'word' });
  assert.equal(ctrl.obterModoSincroniaBoca(), 'boundary');
  assert.equal(timers.size, 0);
  assert.deepEqual(pulsos.at(-1), { secaoId: 'boas-vindas', origem: 'boundary' });

  const pulsosAntesReduzido = pulsos.length;
  assert.equal(pulsosAntesReduzido, 3);

  // Movimento reduzido desliga a sincronia de boca
  modoMovimento = 'reduzido';
  ctrl.notificarMovimento('reduzido');
  assert.equal(ctrl.obterModoSincroniaBoca(), 'parada');
  falas[0].onboundary({ name: 'word' });
  assert.equal(pulsos.length, pulsosAntesReduzido);

  ctrl.parar();
});
