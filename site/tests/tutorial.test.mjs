import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const tutorial = require('../scripts/tutorial.js');

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
  assert.deepEqual(repo.carregar(), { escala: 'padrao', tema: 'claro' });

  repo.salvarEscala('muito-grande');
  repo.salvarTema('alto-contraste');
  assert.deepEqual(repo.carregar(), { escala: 'muito-grande', tema: 'alto-contraste' });

  const storageBloqueado = {
    getItem() {
      throw new Error('SecurityError');
    },
    setItem() {
      throw new Error('QuotaExceededError');
    },
  };

  const repoSemStorage = tutorial.criarRepositorioPreferencias(storageBloqueado);
  assert.deepEqual(repoSemStorage.carregar(), { escala: 'padrao', tema: 'claro' });
  assert.equal(repoSemStorage.salvarEscala('grande'), 'grande');
  assert.equal(repoSemStorage.salvarTema('escuro'), 'escuro');
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
