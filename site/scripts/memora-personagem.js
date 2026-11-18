/**
 * Web Component <memora-personagem> baseado exclusivamente nos vetores
 * exportados de PintorDaMemora / poses.dart em site/assets/memora/memora-dados.js.
 * - Anima somente propriedades compositoras (transform, opacity) via Web Animations.
 * - Pausa automaticamente fora da viewport (IntersectionObserver) e sob [data-movimento="reduzido"].
 * - Sempre decorativa (aria-hidden="true") com Shadow DOM isolado (zero IDs duplicados no DOM).
 */
(function (globalObj) {
  'use strict';

  var EXPRESSOES_MEMORA = [
    'neutra',
    'falando',
    'pensando',
    'comemorando',
    'preocupada',
    'acenando',
    'dica',
    'mini',
    'carregando',
  ];

  function normalizarExpressaoMemora(valor) {
    return EXPRESSOES_MEMORA.indexOf(valor) !== -1 ? valor : 'neutra';
  }

  function montarSvgExpressao(dados, expressaoBruta) {
    if (!dados) {
      return '';
    }
    var expr = normalizarExpressaoMemora(expressaoBruta);
    if (dados.svgs && typeof dados.svgs[expr] === 'string') {
      return dados.svgs[expr];
    }
    var base = dados.base;
    var variacao = dados.variacoes && dados.variacoes[expr];
    if (!base || !variacao) {
      return '';
    }
    var corpoVis = variacao.corpoVisivel !== false;
    var tg = variacao.transformGlobal ? ' transform="' + variacao.transformGlobal + '"' : '';
    var rc = variacao.rotCabeca ? ' transform="' + variacao.rotCabeca + '"' : '';

    return (
      '<svg viewBox="0 0 240 240" role="img" aria-hidden="true" data-expressao="' +
      expr +
      '">' +
      '<defs>' +
      (base.defs || '') +
      '</defs>' +
      '<g' +
      tg +
      '>' +
      '<g id="sombra">' +
      (corpoVis ? base.sombra || '' : '') +
      '</g>' +
      '<g id="corpo">' +
      (corpoVis ? base.corpo || '' : '') +
      '</g>' +
      '<g id="painel-peito">' +
      (corpoVis ? base.painel || '' : '') +
      '</g>' +
      '<g data-parte="cabeca-conjunto"' +
      rc +
      '>' +
      '<g id="antena">' +
      (base.antena || '') +
      '</g>' +
      '<g id="cabeca">' +
      (base.cabeca || '') +
      '</g>' +
      '<g id="visor">' +
      (base.visor || '') +
      '</g>' +
      '<g id="rosto">' +
      (variacao.rostoOutras || '') +
      '<g id="olhos">' +
      (variacao.olhos || '') +
      '</g><g id="boca">' +
      (variacao.boca || '') +
      '</g></g>' +
      '</g>' +
      '<g id="barra">' +
      (variacao.barra || '') +
      '</g>' +
      '<g id="livro">' +
      (variacao.livro || '') +
      '</g>' +
      '<g id="braco-esquerdo">' +
      (variacao.bracoEsquerdo || '') +
      '</g>' +
      '<g id="braco-direito">' +
      (variacao.bracoDireito || '') +
      '</g>' +
      '<g id="escudo">' +
      (variacao.escudo || '') +
      '</g>' +
      '</g></svg>'
    );
  }

  function criarControladorPersonagem(opcoes) {
    var estado = {
      expressao: normalizarExpressaoMemora(opcoes && opcoes.expressao),
      falando: Boolean(opcoes && opcoes.falando),
      visivelNaTela: opcoes && typeof opcoes.visivelNaTela === 'boolean' ? opcoes.visivelNaTela : true,
      movimento: opcoes && opcoes.movimento === 'reduzido' ? 'reduzido' : 'normal',
      pulsosDeBoca: 0,
    };

    var aoAlterarAnimacao =
      opcoes && typeof opcoes.aoAlterarAnimacao === 'function'
        ? opcoes.aoAlterarAnimacao
        : function () {};

    function animacaoAtiva() {
      return estado.visivelNaTela && estado.movimento !== 'reduzido';
    }

    function notificar() {
      aoAlterarAnimacao({
        expressao: estado.expressao,
        falando: estado.falando,
        visivelNaTela: estado.visivelNaTela,
        movimento: estado.movimento,
        ativa: animacaoAtiva(),
      });
    }

    return {
      definirExpressao: function (nova) {
        var norm = normalizarExpressaoMemora(nova);
        if (norm !== estado.expressao) {
          estado.expressao = norm;
          notificar();
        }
        return estado.expressao;
      },
      definirFalando: function (valor) {
        var proximo = Boolean(valor);
        if (proximo !== estado.falando) {
          estado.falando = proximo;
          notificar();
        }
        return estado.falando;
      },
      definirVisivelNaTela: function (visivel) {
        var proximo = Boolean(visivel);
        if (proximo !== estado.visivelNaTela) {
          estado.visivelNaTela = proximo;
          notificar();
        }
        return animacaoAtiva();
      },
      definirMovimento: function (modo) {
        var proximo = modo === 'reduzido' ? 'reduzido' : 'normal';
        if (proximo !== estado.movimento) {
          estado.movimento = proximo;
          notificar();
        }
        return animacaoAtiva();
      },
      pulsarBoca: function () {
        if (!animacaoAtiva() || !estado.falando) {
          return false;
        }
        estado.pulsosDeBoca += 1;
        return true;
      },
      obterEstado: function () {
        return {
          expressao: estado.expressao,
          falando: estado.falando,
          visivelNaTela: estado.visivelNaTela,
          movimento: estado.movimento,
          ativa: animacaoAtiva(),
          pulsosDeBoca: estado.pulsosDeBoca,
        };
      },
    };
  }

  function lerMovimentoDocumento() {
    if (typeof document === 'undefined' || !document.documentElement) {
      return 'normal';
    }
    return document.documentElement.getAttribute('data-movimento') === 'reduzido'
      ? 'reduzido'
      : 'normal';
  }

  if (typeof HTMLElement !== 'undefined' && typeof customElements !== 'undefined') {
    var ESTILO_COMPONENTE =
      ':host{display:block;width:100%;height:100%;line-height:0}' +
      'svg{display:block;width:100%;height:100%;overflow:visible}' +
      '#cabeca,#corpo,#braco-direito,#braco-esquerdo,#olhos,#boca,.boca-falando{transform-box:fill-box;transform-origin:center center}' +
      '#antena{transform-box:fill-box;transform-origin:center bottom}' +
      '.boca-falando{opacity:0;transform-origin:center top}' +
      ':host([falando="true"]) .boca-repouso{opacity:0}' +
      ':host([falando="true"]) .boca-falando{opacity:1}';

    var MemoraPersonagemElement = class extends HTMLElement {
      static get observedAttributes() {
        return ['expressao', 'falando', 'anfitria'];
      }

      constructor() {
        super();
        this._animacoes = [];
        this._observadorVisibilidade = null;
        this._observadorMovimento = null;
        this._raizRender = typeof this.attachShadow === 'function' ? this.attachShadow({ mode: 'open' }) : this;
        this._controlador = criarControladorPersonagem({
          expressao: this.getAttribute('expressao'),
          falando: this.getAttribute('falando') === 'true',
          movimento: lerMovimentoDocumento(),
        });
      }

      connectedCallback() {
        this.setAttribute('aria-hidden', 'true');
        this._renderizar();
        this._conectarObservadores();
        this._sincronizarMovimento();
      }

      disconnectedCallback() {
        this._pararAnimacoes();
        if (this._observadorVisibilidade) {
          this._observadorVisibilidade.disconnect();
          this._observadorVisibilidade = null;
        }
        if (this._observadorMovimento) {
          this._observadorMovimento.disconnect();
          this._observadorMovimento = null;
        }
      }

      attributeChangedCallback(nome, antigo, novo) {
        if (antigo === novo) return;
        if (nome === 'expressao') {
          this._controlador.definirExpressao(novo);
          this._renderizar();
        } else if (nome === 'falando') {
          this._controlador.definirFalando(novo === 'true');
        }
        this._aplicarEstadoAnimacoes();
      }

      pulsarBoca() {
        if (!this._controlador.pulsarBoca() || !this._raizRender) {
          return false;
        }
        var boca = this._raizRender.querySelector('.boca-falando');
        if (boca && typeof boca.animate === 'function') {
          boca.animate(
            [
              { transform: 'scaleY(0.55)', opacity: 0.78 },
              { transform: 'scaleY(1.15)', opacity: 1 },
              { transform: 'scaleY(0.75)', opacity: 0.9 },
            ],
            { duration: 190, easing: 'ease-out' }
          );
          return true;
        }
        return false;
      }

      _conectarObservadores() {
        var self = this;
        if (typeof IntersectionObserver === 'function' && !this._observadorVisibilidade) {
          this._observadorVisibilidade = new IntersectionObserver(
            function (entradas) {
              if (entradas && entradas[0]) {
                self._controlador.definirVisivelNaTela(entradas[0].isIntersecting);
                self._aplicarEstadoAnimacoes();
              }
            },
            { threshold: 0.01 }
          );
          this._observadorVisibilidade.observe(this);
        }

        if (
          typeof MutationObserver === 'function' &&
          typeof document !== 'undefined' &&
          document.documentElement &&
          !this._observadorMovimento
        ) {
          this._observadorMovimento = new MutationObserver(function () {
            self._sincronizarMovimento();
          });
          this._observadorMovimento.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ['data-movimento'],
          });
        }
      }

      _sincronizarMovimento() {
        this._controlador.definirMovimento(lerMovimentoDocumento());
        this._aplicarEstadoAnimacoes();
      }

      _renderizar() {
        var dados = globalObj.MemoraDados;
        var svgHtml = montarSvgExpressao(dados, this.getAttribute('expressao'));
        if (!svgHtml || !this._raizRender) {
          return;
        }
        this._raizRender.innerHTML = '<style>' + ESTILO_COMPONENTE + '</style>' + svgHtml;
      }

      _pararAnimacoes() {
        for (var i = 0; i < this._animacoes.length; i += 1) {
          try {
            this._animacoes[i].cancel();
          } catch (_) {
            // Ambiente sem Web Animations completo.
          }
        }
        this._animacoes = [];
      }

      _aplicarEstadoAnimacoes() {
        this._pararAnimacoes();
        var estado = this._controlador.obterEstado();
        if (!estado.ativa || !this._raizRender) {
          return;
        }
        var podeAnimar = typeof Element !== 'undefined' && typeof Element.prototype.animate === 'function';
        if (!podeAnimar) {
          return;
        }

        var corpo = this._raizRender.querySelector('#corpo');
        if (corpo && this.getAttribute('expressao') !== 'mini') {
          this._animacoes.push(
            corpo.animate(
              [
                { transform: 'translateY(0px) scaleY(1)' },
                { transform: 'translateY(-1.5px) scaleY(1.015)' },
                { transform: 'translateY(0px) scaleY(1)' },
              ],
              { duration: this.getAttribute('anfitria') === 'true' ? 2800 : 3400, iterations: Infinity, easing: 'ease-in-out' }
            )
          );
        }

        var antena = this._raizRender.querySelector('#antena');
        if (antena) {
          this._animacoes.push(
            antena.animate(
              [
                { transform: 'rotate(0deg)' },
                { transform: 'rotate(2.5deg)' },
                { transform: 'rotate(-2deg)' },
                { transform: 'rotate(0deg)' },
              ],
              { duration: 3600, iterations: Infinity, easing: 'ease-in-out' }
            )
          );
        }

        var olhos = this._raizRender.querySelector('#olhos');
        if (olhos && estado.expressao !== 'comemorando') {
          this._animacoes.push(
            olhos.animate(
              [
                { transform: 'scaleY(1)' },
                { transform: 'scaleY(1)', offset: 0.93 },
                { transform: 'scaleY(0.12)', offset: 0.96 },
                { transform: 'scaleY(1)' },
              ],
              { duration: 4200, iterations: Infinity, easing: 'ease-in-out' }
            )
          );
        }

        if (estado.expressao === 'acenando' || estado.expressao === 'comemorando') {
          var braco = this._raizRender.querySelector('#braco-direito');
          if (braco) {
            this._animacoes.push(
              braco.animate(
                [
                  { transform: 'rotate(0deg)' },
                  { transform: 'rotate(-5deg)' },
                  { transform: 'rotate(0deg)' },
                ],
                { duration: 2000, iterations: Infinity, easing: 'ease-in-out' }
              )
            );
          }
        }
      }
    };

    if (!customElements.get('memora-personagem')) {
      customElements.define('memora-personagem', MemoraPersonagemElement);
    }
  }

  var api = {
    EXPRESSOES_MEMORA: EXPRESSOES_MEMORA,
    normalizarExpressaoMemora: normalizarExpressaoMemora,
    montarSvgExpressao: montarSvgExpressao,
    criarControladorPersonagem: criarControladorPersonagem,
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  }
  if (globalObj) {
    globalObj.MemoraPersonagem = api;
  }
})(typeof window !== 'undefined' ? window : globalThis);
