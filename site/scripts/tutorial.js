/**
 * Comportamento progressivo e sem dependências externas do site tutorial Memora.
 * - Preferências locais não sensíveis: tamanho da letra e modo visual.
 * - Leitura em voz alta local (speechSynthesis pt-BR) com exclusividade por capítulo.
 * - Destaque de capítulo ativo no sumário sem bloquear âncoras nativas.
 */
(function (globalObj) {
  'use strict';

  var CHAVES_ARMAZENAMENTO = {
    escala: 'memora.tutorial.escala_fonte',
    tema: 'memora.tutorial.modo_visual',
  };

  var ESCALAS_VALIDAS = ['padrao', 'grande', 'muito-grande'];
  var TEMAS_VALIDOS = ['claro', 'escuro', 'alto-contraste'];

  var ROTULOS_ESCALA = {
    padrao: 'Letra normal',
    grande: 'Letra grande',
    'muito-grande': 'Letra muito grande',
  };

  var ROTULOS_TEMA = {
    claro: 'Fundo claro',
    escuro: 'Fundo escuro',
    'alto-contraste': 'Alto contraste',
  };

  function normalizarEscala(valor) {
    return ESCALAS_VALIDAS.indexOf(valor) !== -1 ? valor : 'padrao';
  }

  function normalizarTema(valor) {
    return TEMAS_VALIDOS.indexOf(valor) !== -1 ? valor : 'claro';
  }

  function criarRepositorioPreferencias(storage) {
    var memoria = {
      escala: 'padrao',
      tema: 'claro',
    };

    function lerChave(chave, padrao) {
      if (!storage || typeof storage.getItem !== 'function') {
        return padrao;
      }
      try {
        var bruto = storage.getItem(chave);
        return bruto === null || bruto === undefined ? padrao : bruto;
      } catch (_) {
        return padrao;
      }
    }

    function gravarChave(chave, valor) {
      if (!storage || typeof storage.setItem !== 'function') {
        return false;
      }
      try {
        storage.setItem(chave, valor);
        return true;
      } catch (_) {
        return false;
      }
    }

    return {
      carregar: function () {
        memoria.escala = normalizarEscala(lerChave(CHAVES_ARMAZENAMENTO.escala, memoria.escala));
        memoria.tema = normalizarTema(lerChave(CHAVES_ARMAZENAMENTO.tema, memoria.tema));
        return {
          escala: memoria.escala,
          tema: memoria.tema,
        };
      },
      salvarEscala: function (valor) {
        var normalizada = normalizarEscala(valor);
        memoria.escala = normalizada;
        gravarChave(CHAVES_ARMAZENAMENTO.escala, normalizada);
        return normalizada;
      },
      salvarTema: function (valor) {
        var normalizado = normalizarTema(valor);
        memoria.tema = normalizado;
        gravarChave(CHAVES_ARMAZENAMENTO.tema, normalizado);
        return normalizado;
      },
    };
  }

  function extrairTextoEducativo(elementoSecao) {
    if (!elementoSecao || typeof elementoSecao.querySelectorAll !== 'function') {
      return '';
    }
    var blocos = elementoSecao.querySelectorAll('[data-leitura-conteudo]');
    if (!blocos || blocos.length === 0) {
      return '';
    }
    var partes = [];
    for (var i = 0; i < blocos.length; i += 1) {
      var texto = (blocos[i].textContent || '').replace(/\s+/g, ' ').trim();
      if (texto) {
        partes.push(texto);
      }
    }
    return partes.join('. ');
  }

  function criarControladorDeVoz(deps) {
    var synth = deps && deps.speechSynthesis ? deps.speechSynthesis : null;
    var UtteranceCtor = deps && deps.Utterance ? deps.Utterance : null;
    var aoMudarEstado = deps && typeof deps.aoMudarEstado === 'function' ? deps.aoMudarEstado : function () {};

    var estado = {
      suportado: Boolean(synth && typeof synth.speak === 'function' && typeof synth.cancel === 'function' && UtteranceCtor),
      secaoAtivaId: null,
      status: 'ocioso',
    };

    function notificar() {
      aoMudarEstado({
        suportado: estado.suportado,
        secaoAtivaId: estado.secaoAtivaId,
        status: estado.status,
      });
    }

    function parar() {
      if (estado.suportado) {
        try {
          synth.cancel();
        } catch (_) {
          // Segue limpando estado visual silenciosamente.
        }
      }
      estado.secaoAtivaId = null;
      estado.status = 'ocioso';
      notificar();
    }

    function alternar(secaoId, textoParaLer) {
      if (!estado.suportado) {
        return false;
      }
      if (estado.status === 'lendo' && estado.secaoAtivaId === secaoId) {
        parar();
        return false;
      }

      var textoLimpo = (textoParaLer || '').replace(/\s+/g, ' ').trim();
      if (!textoLimpo) {
        parar();
        return false;
      }

      try {
        synth.cancel();
      } catch (_) {
        // Ignora erro de cancelamento anterior.
      }

      var fala = new UtteranceCtor(textoLimpo);
      fala.lang = 'pt-BR';
      fala.rate = 0.94;
      fala.pitch = 1.0;

      estado.secaoAtivaId = secaoId;
      estado.status = 'lendo';
      notificar();

      function finalizarSeAtual() {
        if (estado.secaoAtivaId === secaoId) {
          estado.secaoAtivaId = null;
          estado.status = 'ocioso';
          notificar();
        }
      }

      fala.onend = finalizarSeAtual;
      fala.onerror = finalizarSeAtual;

      try {
        synth.speak(fala);
        return true;
      } catch (_) {
        estado.secaoAtivaId = null;
        estado.status = 'ocioso';
        notificar();
        return false;
      }
    }

    return {
      estaSuportado: function () {
        return estado.suportado;
      },
      obterEstado: function () {
        return {
          suportado: estado.suportado,
          secaoAtivaId: estado.secaoAtivaId,
          status: estado.status,
        };
      },
      alternar: alternar,
      parar: parar,
    };
  }

  function atualizarBotoesDeGrupo(botoes, atributo, valorAtivo) {
    for (var i = 0; i < botoes.length; i += 1) {
      var botao = botoes[i];
      var valorBotao = botao.getAttribute(atributo);
      botao.setAttribute('aria-pressed', valorBotao === valorAtivo ? 'true' : 'false');
    }
  }

  function inicializarPagina() {
    if (typeof document === 'undefined' || !document.documentElement) {
      return null;
    }

    var raiz = document.documentElement;
    var anuncio = document.getElementById('anuncio-acessibilidade');
    var botoesEscala = document.querySelectorAll('[data-acao-escala]');
    var botoesTema = document.querySelectorAll('[data-acao-tema]');
    var botoesOuvir = document.querySelectorAll('[data-botao-ouvir]');
    var linksSumario = document.querySelectorAll('[data-link-capitulo]');
    var detalhesDuvidas = document.querySelectorAll('.duvida-item');

    var storageSeguro = null;
    try {
      storageSeguro = globalObj.localStorage;
    } catch (_) {
      storageSeguro = null;
    }

    var repositorio = criarRepositorioPreferencias(storageSeguro);

    function anunciar(mensagem) {
      if (anuncio && mensagem) {
        anuncio.textContent = mensagem;
      }
    }

    function aplicarEscala(escala, anunciarMudanca) {
      var finalEscala = repositorio.salvarEscala(escala);
      raiz.setAttribute('data-escala', finalEscala);
      atualizarBotoesDeGrupo(botoesEscala, 'data-acao-escala', finalEscala);
      if (anunciarMudanca) {
        anunciar('Tamanho da letra ajustado para ' + ROTULOS_ESCALA[finalEscala] + '.');
      }
    }

    function aplicarTema(tema, anunciarMudanca) {
      var finalTema = repositorio.salvarTema(tema);
      raiz.setAttribute('data-tema', finalTema);
      atualizarBotoesDeGrupo(botoesTema, 'data-acao-tema', finalTema);
      if (anunciarMudanca) {
        anunciar('Aparência da página alterada para ' + ROTULOS_TEMA[finalTema] + '.');
      }
    }

    var iniciais = repositorio.carregar();
    aplicarEscala(iniciais.escala, false);
    aplicarTema(iniciais.tema, false);

    for (var i = 0; i < botoesEscala.length; i += 1) {
      botoesEscala[i].addEventListener('click', function () {
        aplicarEscala(this.getAttribute('data-acao-escala'), true);
      });
    }

    for (var j = 0; j < botoesTema.length; j += 1) {
      botoesTema[j].addEventListener('click', function () {
        aplicarTema(this.getAttribute('data-acao-tema'), true);
      });
    }

    function atualizarTextoIndicadoresDuvidas() {
      for (var d = 0; d < detalhesDuvidas.length; d += 1) {
        var indicador = detalhesDuvidas[d].querySelector('.duvida-indicador');
        if (indicador) {
          indicador.textContent = detalhesDuvidas[d].open ? 'Fechar resposta' : 'Ver resposta';
        }
      }
    }

    for (var k = 0; k < detalhesDuvidas.length; k += 1) {
      detalhesDuvidas[k].addEventListener('toggle', atualizarTextoIndicadoresDuvidas);
    }
    atualizarTextoIndicadoresDuvidas();

    var controladorVoz = criarControladorDeVoz({
      speechSynthesis: globalObj.speechSynthesis,
      Utterance: globalObj.SpeechSynthesisUtterance,
      aoMudarEstado: function (novoEstado) {
        for (var b = 0; b < botoesOuvir.length; b += 1) {
          var botao = botoesOuvir[b];
          var alvo = botao.getAttribute('data-leitura-alvo');
          var ativo = novoEstado.status === 'lendo' && novoEstado.secaoAtivaId === alvo;
          botao.setAttribute('aria-pressed', ativo ? 'true' : 'false');
          botao.textContent = ativo ? 'Parar leitura' : 'Ouvir este trecho';
        }
      },
    });

    if (controladorVoz.estaSuportado()) {
      for (var m = 0; m < botoesOuvir.length; m += 1) {
        botoesOuvir[m].hidden = false;
        botoesOuvir[m].addEventListener('click', function () {
          var secaoId = this.getAttribute('data-leitura-alvo');
          var secao = document.getElementById(secaoId);
          var texto = extrairTextoEducativo(secao);
          controladorVoz.alternar(secaoId, texto);
        });
      }
    }

    function marcarCapituloAtivo(capituloId) {
      for (var c = 0; c < linksSumario.length; c += 1) {
        var link = linksSumario[c];
        var href = link.getAttribute('href');
        if (href === '#' + capituloId) {
          link.setAttribute('aria-current', 'true');
        } else {
          link.removeAttribute('aria-current');
        }
      }
    }

    for (var s = 0; s < linksSumario.length; s += 1) {
      linksSumario[s].addEventListener('click', function () {
        var destino = (this.getAttribute('href') || '').replace(/^#/, '');
        if (destino) {
          marcarCapituloAtivo(destino);
        }
      });
    }

    if (typeof globalObj.IntersectionObserver === 'function' && linksSumario.length > 0) {
      var observador = new globalObj.IntersectionObserver(
        function (entradas) {
          for (var e = 0; e < entradas.length; e += 1) {
            if (entradas[e].isIntersecting && entradas[e].target && entradas[e].target.id) {
              marcarCapituloAtivo(entradas[e].target.id);
              break;
            }
          }
        },
        { rootMargin: '-20% 0px -65% 0px', threshold: 0.05 }
      );

      var capitulos = document.querySelectorAll('main section[id]');
      for (var p = 0; p < capitulos.length; p += 1) {
        observador.observe(capitulos[p]);
      }
    }

    return {
      repositorio: repositorio,
      controladorVoz: controladorVoz,
    };
  }

  var api = {
    CHAVES_ARMAZENAMENTO: CHAVES_ARMAZENAMENTO,
    ESCALAS_VALIDAS: ESCALAS_VALIDAS,
    TEMAS_VALIDOS: TEMAS_VALIDOS,
    normalizarEscala: normalizarEscala,
    normalizarTema: normalizarTema,
    criarRepositorioPreferencias: criarRepositorioPreferencias,
    extrairTextoEducativo: extrairTextoEducativo,
    criarControladorDeVoz: criarControladorDeVoz,
    inicializarPagina: inicializarPagina,
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  }
  if (globalObj) {
    globalObj.MemoraTutorial = api;
  }

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', inicializarPagina);
    } else {
      inicializarPagina();
    }
  }
})(typeof window !== 'undefined' ? window : globalThis);
