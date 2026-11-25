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
    movimento: 'memora.tutorial.reduzir_movimento',
  };

  var ESCALAS_VALIDAS = ['padrao', 'grande', 'muito-grande'];
  var TEMAS_VALIDOS = ['claro', 'escuro', 'alto-contraste'];
  var MOVIMENTOS_VALIDOS = ['normal', 'reduzido'];

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

  var ROTULOS_MOVIMENTO = {
    normal: 'Movimento normal',
    reduzido: 'Movimento reduzido',
  };

  function normalizarEscala(valor) {
    return ESCALAS_VALIDAS.indexOf(valor) !== -1 ? valor : 'padrao';
  }

  function normalizarTema(valor) {
    return TEMAS_VALIDOS.indexOf(valor) !== -1 ? valor : 'claro';
  }

  function normalizarMovimento(valor) {
    return MOVIMENTOS_VALIDOS.indexOf(valor) !== -1 ? valor : 'normal';
  }

  function movimentoValidoOuNulo(valor) {
    return MOVIMENTOS_VALIDOS.indexOf(valor) !== -1 ? valor : null;
  }

  function resolverMovimentoSistema(win) {
    try {
      return Boolean(
        win &&
          typeof win.matchMedia === 'function' &&
          win.matchMedia('(prefers-reduced-motion: reduce)').matches
      );
    } catch (_) {
      return false;
    }
  }

  function criarRepositorioPreferencias(storage, opcoes) {
    var movimentoSistemaReduzido = Boolean(opcoes && opcoes.movimentoSistemaReduzido);
    var memoria = {
      escala: 'padrao',
      tema: 'claro',
      movimento: null,
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
        var movimentoSalvo = movimentoValidoOuNulo(
          lerChave(CHAVES_ARMAZENAMENTO.movimento, memoria.movimento)
        );
        if (movimentoSalvo !== null) {
          memoria.movimento = movimentoSalvo;
        }
        var movimentoEfetivo =
          movimentoSalvo !== null
            ? movimentoSalvo
            : movimentoSistemaReduzido
              ? 'reduzido'
              : 'normal';
        return {
          escala: memoria.escala,
          tema: memoria.tema,
          movimento: movimentoEfetivo,
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
      salvarMovimento: function (valor) {
        var normalizado = normalizarMovimento(valor);
        memoria.movimento = normalizado;
        gravarChave(CHAVES_ARMAZENAMENTO.movimento, normalizado);
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

  var MAPA_EXPRESSAO_CAPITULO = {
    'boas-vindas': 'acenando',
    'primeiros-passos': 'acenando',
    'navegacao-3-toques': 'neutra',
    'conversa-e-historico': 'pensando',
    'aplicativos-e-servicos': 'dica',
    'ajustes-e-foto': 'neutra',
    'pulseira-cuidado': 'dica',
    'protecao-golpes': 'preocupada',
    'duvidas-frequentes': 'comemorando',
  };

  function resolverExpressaoDoCapitulo(capituloId) {
    return (capituloId && MAPA_EXPRESSAO_CAPITULO[capituloId]) || 'neutra';
  }

  function deveIniciarAnfitriaExpandida(globalRef, escala) {
    if (escala === 'muito-grande') {
      return false;
    }
    if (!globalRef) {
      return true;
    }
    if (typeof globalRef.matchMedia === 'function') {
      return Boolean(globalRef.matchMedia('(min-width: 64rem)').matches);
    }
    if (typeof globalRef.innerWidth === 'number') {
      return globalRef.innerWidth >= 1024;
    }
    return true;
  }

  function criarControladorDaAnfitria(opcoes) {
    var dicas =
      opcoes && Array.isArray(opcoes.dicas)
        ? opcoes.dicas.filter(function (d) {
            return typeof d === 'string' && d.trim().length > 0;
          })
        : [];
    var intervaloMs =
      opcoes && typeof opcoes.intervaloMs === 'number' && opcoes.intervaloMs > 0
        ? opcoes.intervaloMs
        : 20000;
    var setIntervalFn =
      opcoes && typeof opcoes.setIntervalFn === 'function'
        ? opcoes.setIntervalFn
        : typeof globalObj.setInterval === 'function'
          ? globalObj.setInterval.bind(globalObj)
          : null;
    var clearIntervalFn =
      opcoes && typeof opcoes.clearIntervalFn === 'function'
        ? opcoes.clearIntervalFn
        : typeof globalObj.clearInterval === 'function'
          ? globalObj.clearInterval.bind(globalObj)
          : null;
    var aoMudarDica =
      opcoes && typeof opcoes.aoMudarDica === 'function' ? opcoes.aoMudarDica : function () {};
    var aoMudarExpansao =
      opcoes && typeof opcoes.aoMudarExpansao === 'function' ? opcoes.aoMudarExpansao : function () {};
    var aoMudarExpressao =
      opcoes && typeof opcoes.aoMudarExpressao === 'function' ? opcoes.aoMudarExpressao : function () {};

    var capituloInicial = (opcoes && opcoes.capituloInicial) || 'boas-vindas';
    var estado = {
      indiceAtual: 0,
      interagiuManualmente: false,
      expandida: opcoes && typeof opcoes.expandida === 'boolean' ? opcoes.expandida : true,
      capituloAtivo: capituloInicial,
      expressaoAtual: resolverExpressaoDoCapitulo(capituloInicial),
      movimento: opcoes && opcoes.movimento === 'reduzido' ? 'reduzido' : 'normal',
      focoDentro: Boolean(opcoes && opcoes.focoDentro),
      leitorDeTelaAtivo: Boolean(opcoes && opcoes.leitorDeTelaAtivo),
      rotacaoAutomaticaAtiva: false,
    };

    var temporizador = null;

    function podeRodarAutomatico() {
      return (
        estado.expandida &&
        !estado.interagiuManualmente &&
        estado.movimento === 'normal' &&
        !estado.focoDentro &&
        !estado.leitorDeTelaAtivo &&
        dicas.length > 1
      );
    }

    function limparTemporizador() {
      if (temporizador !== null && clearIntervalFn) {
        clearIntervalFn(temporizador);
      }
      temporizador = null;
      estado.rotacaoAutomaticaAtiva = false;
    }

    function avancarAutomatico() {
      if (!podeRodarAutomatico()) {
        limparTemporizador();
        return null;
      }
      estado.indiceAtual = (estado.indiceAtual + 1) % dicas.length;
      var novaDica = dicas[estado.indiceAtual];
      aoMudarDica(novaDica, estado.indiceAtual, false);
      return novaDica;
    }

    function reavaliarTemporizador() {
      limparTemporizador();
      if (podeRodarAutomatico() && setIntervalFn) {
        temporizador = setIntervalFn(avancarAutomatico, intervaloMs);
        if (temporizador && typeof temporizador.unref === 'function') {
          temporizador.unref();
        }
        estado.rotacaoAutomaticaAtiva = true;
      }
    }

    function definirExpandida(valor) {
      var proximo = Boolean(valor);
      if (estado.expandida === proximo) {
        return estado.expandida;
      }
      estado.expandida = proximo;
      reavaliarTemporizador();
      aoMudarExpansao(estado.expandida);
      return estado.expandida;
    }

    reavaliarTemporizador();

    return {
      avancarManual: function () {
        estado.interagiuManualmente = true;
        limparTemporizador();
        if (dicas.length === 0) {
          return { dica: '', indice: 0, rotacaoAutomaticaAtiva: false };
        }
        estado.indiceAtual = (estado.indiceAtual + 1) % dicas.length;
        var novaDica = dicas[estado.indiceAtual];
        aoMudarDica(novaDica, estado.indiceAtual, true);
        return {
          dica: novaDica,
          indice: estado.indiceAtual,
          rotacaoAutomaticaAtiva: false,
        };
      },
      avancarAutomatico: avancarAutomatico,
      definirExpandida: definirExpandida,
      alternarExpandida: function () {
        return definirExpandida(!estado.expandida);
      },
      atualizarCapitulo: function (capituloId) {
        if (!capituloId) {
          return estado.expressaoAtual;
        }
        estado.capituloAtivo = capituloId;
        var novaExpressao = resolverExpressaoDoCapitulo(capituloId);
        if (novaExpressao !== estado.expressaoAtual) {
          estado.expressaoAtual = novaExpressao;
          aoMudarExpressao(novaExpressao, capituloId);
        }
        return estado.expressaoAtual;
      },
      definirMovimento: function (modo) {
        estado.movimento = normalizarMovimento(modo);
        reavaliarTemporizador();
        return estado.rotacaoAutomaticaAtiva;
      },
      definirFocoDentro: function (valor) {
        estado.focoDentro = Boolean(valor);
        reavaliarTemporizador();
        return estado.rotacaoAutomaticaAtiva;
      },
      definirLeitorDeTelaAtivo: function (valor) {
        estado.leitorDeTelaAtivo = Boolean(valor);
        reavaliarTemporizador();
        return estado.rotacaoAutomaticaAtiva;
      },
      obterDicaAtual: function () {
        return dicas[estado.indiceAtual] || '';
      },
      obterEstado: function () {
        return {
          totalDicas: dicas.length,
          indiceAtual: estado.indiceAtual,
          dicaAtual: dicas[estado.indiceAtual] || '',
          interagiuManualmente: estado.interagiuManualmente,
          expandida: estado.expandida,
          capituloAtivo: estado.capituloAtivo,
          expressaoAtual: estado.expressaoAtual,
          rotacaoAutomaticaAtiva: estado.rotacaoAutomaticaAtiva,
          movimento: estado.movimento,
        };
      },
      destruir: limparTemporizador,
    };
  }

  function criarControladorDeVoz(deps) {
    var synth = deps && deps.speechSynthesis ? deps.speechSynthesis : null;
    var UtteranceCtor = deps && deps.Utterance ? deps.Utterance : null;
    var aoMudarEstado = deps && typeof deps.aoMudarEstado === 'function' ? deps.aoMudarEstado : function () {};
    var aoPulsarBoca = deps && typeof deps.aoPulsarBoca === 'function' ? deps.aoPulsarBoca : function () {};
    var obterMovimento =
      deps && typeof deps.obterMovimento === 'function'
        ? deps.obterMovimento
        : function () {
            return 'normal';
          };
    var setIntervalFn =
      deps && typeof deps.setIntervalFn === 'function'
        ? deps.setIntervalFn
        : typeof globalObj.setInterval === 'function'
          ? globalObj.setInterval.bind(globalObj)
          : null;
    var clearIntervalFn =
      deps && typeof deps.clearIntervalFn === 'function'
        ? deps.clearIntervalFn
        : typeof globalObj.clearInterval === 'function'
          ? globalObj.clearInterval.bind(globalObj)
          : null;
    var intervaloPulsoMs =
      deps && typeof deps.intervaloPulsoMs === 'number' && deps.intervaloPulsoMs > 0
        ? deps.intervaloPulsoMs
        : 220;

    var estado = {
      suportado: Boolean(synth && typeof synth.speak === 'function' && typeof synth.cancel === 'function' && UtteranceCtor),
      secaoAtivaId: null,
      status: 'ocioso',
      modoSincroniaBoca: 'parada',
    };

    var pulsoTimer = null;

    function limparPulso() {
      if (pulsoTimer !== null && clearIntervalFn) {
        clearIntervalFn(pulsoTimer);
      }
      pulsoTimer = null;
    }

    function notificar() {
      aoMudarEstado({
        suportado: estado.suportado,
        secaoAtivaId: estado.secaoAtivaId,
        status: estado.status,
        modoSincroniaBoca: estado.modoSincroniaBoca,
      });
    }

    function iniciarPulsoRitmo(secaoId) {
      limparPulso();
      if (obterMovimento() === 'reduzido' || estado.status !== 'lendo' || estado.secaoAtivaId !== secaoId) {
        estado.modoSincroniaBoca = 'parada';
        return;
      }
      estado.modoSincroniaBoca = 'pulso';
      aoPulsarBoca(secaoId, 'pulso');
      if (setIntervalFn) {
        pulsoTimer = setIntervalFn(function () {
          if (estado.status === 'lendo' && estado.secaoAtivaId === secaoId && obterMovimento() !== 'reduzido') {
            aoPulsarBoca(secaoId, 'pulso');
          } else {
            limparPulso();
          }
        }, intervaloPulsoMs);
        if (pulsoTimer && typeof pulsoTimer.unref === 'function') {
          pulsoTimer.unref();
        }
      }
    }

    function parar() {
      limparPulso();
      if (estado.suportado) {
        try {
          synth.cancel();
        } catch (_) {
          // Segue limpando estado visual silenciosamente.
        }
      }
      estado.secaoAtivaId = null;
      estado.status = 'ocioso';
      estado.modoSincroniaBoca = 'parada';
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

      limparPulso();
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
      estado.modoSincroniaBoca = obterMovimento() === 'reduzido' ? 'parada' : 'pulso';
      notificar();

      function finalizarSeAtual() {
        if (estado.secaoAtivaId === secaoId) {
          limparPulso();
          estado.secaoAtivaId = null;
          estado.status = 'ocioso';
          estado.modoSincroniaBoca = 'parada';
          notificar();
        }
      }

      fala.onstart = function () {
        if (estado.secaoAtivaId === secaoId && estado.status === 'lendo' && estado.modoSincroniaBoca !== 'boundary') {
          iniciarPulsoRitmo(secaoId);
          notificar();
        }
      };

      fala.onboundary = function () {
        if (estado.secaoAtivaId !== secaoId || estado.status !== 'lendo') {
          return;
        }
        if (obterMovimento() === 'reduzido') {
          limparPulso();
          estado.modoSincroniaBoca = 'parada';
          return;
        }
        limparPulso();
        estado.modoSincroniaBoca = 'boundary';
        aoPulsarBoca(secaoId, 'boundary');
        notificar();
      };

      fala.onend = finalizarSeAtual;
      fala.onerror = finalizarSeAtual;

      try {
        synth.speak(fala);
        return true;
      } catch (_) {
        limparPulso();
        estado.secaoAtivaId = null;
        estado.status = 'ocioso';
        estado.modoSincroniaBoca = 'parada';
        notificar();
        return false;
      }
    }

    return {
      estaSuportado: function () {
        return estado.suportado;
      },
      notificarMovimento: function (modo) {
        if (modo === 'reduzido') {
          limparPulso();
          estado.modoSincroniaBoca = 'parada';
          notificar();
        } else if (estado.status === 'lendo' && estado.secaoAtivaId && estado.modoSincroniaBoca === 'parada') {
          iniciarPulsoRitmo(estado.secaoAtivaId);
          notificar();
        }
      },
      obterEstado: function () {
        return {
          suportado: estado.suportado,
          secaoAtivaId: estado.secaoAtivaId,
          status: estado.status,
        };
      },
      obterModoSincroniaBoca: function () {
        return estado.modoSincroniaBoca;
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
    var botaoMovimento = document.querySelector('[data-acao-movimento]');
    var botoesOuvir = document.querySelectorAll('[data-botao-ouvir]');
    var linksSumario = document.querySelectorAll('[data-link-capitulo]');
    var detalhesDuvidas = document.querySelectorAll('.duvida-item');
    var anfitriaBloco = document.querySelector('[data-anfitria-bloco]');
    var corpoAnfitria = document.querySelector('[data-anfitria-conteudo]');
    var balaoAnfitria = document.querySelector('[data-anfitria-balao]');
    var botaoOutraDica = document.querySelector('[data-acao-outra-dica]');
    var botaoAlternarAnfitria = document.querySelector('[data-acao-alternar-anfitria]');
    var personagemAnfitria = document.querySelector('[data-memora-anfitria]');
    var controladorAnfitria = null;
    var controladorVoz = null;
    var temporizadorFalaAnfitria = null;
    var capituloVisivelAtual = 'boas-vindas';
    var alternouExpansaoManualmente = false;
    var bloqueioScrollManualAte = 0;

    function aplicarExpressaoAnfitria(expressao) {
      if (!personagemAnfitria || !expressao) {
        return;
      }
      if (personagemAnfitria.getAttribute('expressao') !== expressao) {
        personagemAnfitria.setAttribute('expressao', expressao);
      }
    }

    function sincronizarEstadoExpansaoDOM(expandida) {
      raiz.setAttribute('data-anfitria', expandida ? 'expandida' : 'recolhida');
      if (anfitriaBloco) {
        anfitriaBloco.setAttribute('data-anfitria-estado', expandida ? 'expandida' : 'recolhida');
      }
      if (corpoAnfitria) {
        corpoAnfitria.hidden = !expandida;
      }
      if (botaoAlternarAnfitria) {
        botaoAlternarAnfitria.setAttribute('aria-expanded', expandida ? 'true' : 'false');
        botaoAlternarAnfitria.textContent = expandida ? 'Recolher dicas' : 'Ver dicas';
      }
    }

    var storageSeguro = null;
    try {
      storageSeguro = globalObj.localStorage;
    } catch (_) {
      storageSeguro = null;
    }

    var repositorio = criarRepositorioPreferencias(storageSeguro, {
      movimentoSistemaReduzido: resolverMovimentoSistema(globalObj),
    });

    function anunciar(mensagem) {
      if (anuncio && mensagem) {
        anuncio.textContent = mensagem;
      }
    }

    function aplicarEscala(escala, anunciarMudanca) {
      var finalEscala = repositorio.salvarEscala(escala);
      raiz.setAttribute('data-escala', finalEscala);
      atualizarBotoesDeGrupo(botoesEscala, 'data-acao-escala', finalEscala);
      if (controladorAnfitria) {
        if (finalEscala === 'muito-grande') {
          controladorAnfitria.definirExpandida(false);
        } else if (!alternouExpansaoManualmente) {
          controladorAnfitria.definirExpandida(deveIniciarAnfitriaExpandida(globalObj, finalEscala));
        }
      }
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

    function aplicarMovimento(movimento, salvarEscolha, anunciarMudanca) {
      var finalMovimento = salvarEscolha
        ? repositorio.salvarMovimento(movimento)
        : normalizarMovimento(movimento);
      raiz.setAttribute('data-movimento', finalMovimento);
      if (botaoMovimento) {
        botaoMovimento.setAttribute('aria-pressed', finalMovimento === 'reduzido' ? 'true' : 'false');
      }
      if (controladorAnfitria) {
        controladorAnfitria.definirMovimento(finalMovimento);
      }
      if (controladorVoz) {
        controladorVoz.notificarMovimento(finalMovimento);
      }
      if (finalMovimento === 'reduzido' && personagemAnfitria && (!controladorVoz || controladorVoz.obterEstado().status !== 'lendo')) {
        personagemAnfitria.setAttribute('falando', 'false');
      }
      if (anunciarMudanca) {
        anunciar('Configuração de tela alterada para ' + ROTULOS_MOVIMENTO[finalMovimento] + '.');
      }
    }

    var iniciais = repositorio.carregar();
    aplicarEscala(iniciais.escala, false);
    aplicarTema(iniciais.tema, false);
    aplicarMovimento(iniciais.movimento, false, false);

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

    if (botaoMovimento) {
      botaoMovimento.addEventListener('click', function () {
        var atual = raiz.getAttribute('data-movimento') === 'reduzido' ? 'reduzido' : 'normal';
        var proximo = atual === 'reduzido' ? 'normal' : 'reduzido';
        aplicarMovimento(proximo, true, true);
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

    function obterPersonagemDeFala() {
      return personagemAnfitria || null;
    }

    function limparFalaDosPersonagens() {
      var falantes = document.querySelectorAll('memora-personagem[falando="true"]');
      for (var f = 0; f < falantes.length; f += 1) {
        falantes[f].setAttribute('falando', 'false');
      }
    }

    controladorVoz = criarControladorDeVoz({
      speechSynthesis: globalObj.speechSynthesis,
      Utterance: globalObj.SpeechSynthesisUtterance,
      obterMovimento: function () {
        return raiz.getAttribute('data-movimento') === 'reduzido' ? 'reduzido' : 'normal';
      },
      aoPulsarBoca: function () {
        var alvo = obterPersonagemDeFala();
        if (alvo && typeof alvo.pulsarBoca === 'function') {
          alvo.pulsarBoca();
        }
      },
      aoMudarEstado: function (novoEstado) {
        for (var b = 0; b < botoesOuvir.length; b += 1) {
          var botao = botoesOuvir[b];
          var alvo = botao.getAttribute('data-leitura-alvo');
          var ativo = novoEstado.status === 'lendo' && novoEstado.secaoAtivaId === alvo;
          botao.setAttribute('aria-pressed', ativo ? 'true' : 'false');
          botao.textContent = ativo ? 'Parar leitura' : 'Ouvir este trecho';
        }
        limparFalaDosPersonagens();
        if (novoEstado.status === 'lendo' && novoEstado.secaoAtivaId && personagemAnfitria) {
          aplicarExpressaoAnfitria(resolverExpressaoDoCapitulo(novoEstado.secaoAtivaId));
          personagemAnfitria.setAttribute('falando', 'true');
        } else if (personagemAnfitria) {
          aplicarExpressaoAnfitria(resolverExpressaoDoCapitulo(capituloVisivelAtual));
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
      capituloVisivelAtual = capituloId;
      for (var c = 0; c < linksSumario.length; c += 1) {
        var link = linksSumario[c];
        var href = link.getAttribute('href');
        if (href === '#' + capituloId) {
          link.setAttribute('aria-current', 'true');
        } else {
          link.removeAttribute('aria-current');
        }
      }
      if (controladorAnfitria) {
        controladorAnfitria.atualizarCapitulo(capituloId);
      }
    }

    for (var s = 0; s < linksSumario.length; s += 1) {
      linksSumario[s].addEventListener('click', function () {
        var destino = (this.getAttribute('href') || '').replace(/^#/, '');
        if (destino) {
          bloqueioScrollManualAte = Date.now() + 900;
          var movimentoReduzido = raiz.getAttribute('data-movimento') === 'reduzido';
          executarNavegacaoComTransicao(
            function () {
              marcarCapituloAtivo(destino);
            },
            { document: document, movimentoReduzido: movimentoReduzido }
          );
        }
      });
    }

    if (typeof globalObj.IntersectionObserver === 'function' && linksSumario.length > 0) {
      var observador = new globalObj.IntersectionObserver(
        function (entradas) {
          if (Date.now() < bloqueioScrollManualAte) {
            return;
          }
          var melhorEntrada = null;
          for (var e = 0; e < entradas.length; e += 1) {
            if (entradas[e].isIntersecting && entradas[e].target && entradas[e].target.id) {
              if (!melhorEntrada || entradas[e].intersectionRatio >= melhorEntrada.intersectionRatio) {
                melhorEntrada = entradas[e];
              }
            }
          }
          if (melhorEntrada) {
            marcarCapituloAtivo(melhorEntrada.target.id);
          }
        },
        { rootMargin: '-20% 0px -65% 0px', threshold: 0.05 }
      );

      var capitulos = document.querySelectorAll('main section[id]');
      for (var p = 0; p < capitulos.length; p += 1) {
        observador.observe(capitulos[p]);
      }
    }

    var dicasAnfitria =
      globalObj.MemoraDados &&
      Array.isArray(globalObj.MemoraDados.dicasDaAnfitria) &&
      globalObj.MemoraDados.dicasDaAnfitria.length > 0
        ? globalObj.MemoraDados.dicasDaAnfitria
        : balaoAnfitria && balaoAnfitria.textContent
          ? [balaoAnfitria.textContent.replace(/\s+/g, ' ').trim()]
          : [];

    if ((anfitriaBloco || balaoAnfitria) && dicasAnfitria.length > 0) {
      var expandidaInicial = deveIniciarAnfitriaExpandida(globalObj, raiz.getAttribute('data-escala'));
      controladorAnfitria = criarControladorDaAnfitria({
        dicas: dicasAnfitria,
        intervaloMs: 20000,
        expandida: expandidaInicial,
        capituloInicial: capituloVisivelAtual,
        movimento: raiz.getAttribute('data-movimento'),
        aoMudarExpansao: sincronizarEstadoExpansaoDOM,
        aoMudarExpressao: function (novaExpressao) {
          if (!controladorVoz || controladorVoz.obterEstado().status !== 'lendo') {
            aplicarExpressaoAnfitria(novaExpressao);
          }
        },
        aoMudarDica: function (novaDica, _indice, porAcaoManual) {
          if (balaoAnfitria) {
            balaoAnfitria.textContent = novaDica;
          }
          if (porAcaoManual) {
            anunciar(novaDica);
            if (
              personagemAnfitria &&
              raiz.getAttribute('data-movimento') !== 'reduzido' &&
              (!controladorVoz || controladorVoz.obterEstado().status !== 'lendo')
            ) {
              if (temporizadorFalaAnfitria !== null && typeof globalObj.clearTimeout === 'function') {
                globalObj.clearTimeout(temporizadorFalaAnfitria);
              }
              personagemAnfitria.setAttribute('falando', 'true');
              if (typeof personagemAnfitria.pulsarBoca === 'function') {
                personagemAnfitria.pulsarBoca();
              }
              if (typeof globalObj.setTimeout === 'function') {
                temporizadorFalaAnfitria = globalObj.setTimeout(function () {
                  if (!controladorVoz || controladorVoz.obterEstado().status !== 'lendo') {
                    personagemAnfitria.setAttribute('falando', 'false');
                  }
                  temporizadorFalaAnfitria = null;
                }, 1600);
                if (temporizadorFalaAnfitria && typeof temporizadorFalaAnfitria.unref === 'function') {
                  temporizadorFalaAnfitria.unref();
                }
              }
            }
          }
        },
      });

      sincronizarEstadoExpansaoDOM(expandidaInicial);

      if (botaoAlternarAnfitria) {
        botaoAlternarAnfitria.addEventListener('click', function () {
          alternouExpansaoManualmente = true;
          var aberta = controladorAnfitria.alternarExpandida();
          anunciar(aberta ? 'Painel de dicas da Memora aberto.' : 'Painel de dicas da Memora recolhido.');
        });
      }

      if (typeof globalObj.addEventListener === 'function') {
        globalObj.addEventListener('resize', function () {
          if (!alternouExpansaoManualmente && controladorAnfitria) {
            controladorAnfitria.definirExpandida(
              deveIniciarAnfitriaExpandida(globalObj, raiz.getAttribute('data-escala'))
            );
          }
        });
      }

      if (botaoOutraDica) {
        botaoOutraDica.addEventListener('click', function () {
          controladorAnfitria.avancarManual();
        });
      }

      if (anfitriaBloco) {
        anfitriaBloco.addEventListener('focusin', function () {
          controladorAnfitria.definirFocoDentro(true);
        });
        anfitriaBloco.addEventListener('focusout', function (evento) {
          var destino = evento && evento.relatedTarget;
          if (!destino || !anfitriaBloco.contains(destino)) {
            controladorAnfitria.definirFocoDentro(false);
          }
        });
      }
    }

    return {
      repositorio: repositorio,
      controladorVoz: controladorVoz,
      controladorAnfitria: controladorAnfitria,
    };
  }

  function executarNavegacaoComTransicao(acao, opcoes) {
    var doc = opcoes && opcoes.document ? opcoes.document : null;
    var reduzido = Boolean(opcoes && opcoes.movimentoReduzido);
    if (!reduzido && doc && typeof doc.startViewTransition === 'function') {
      try {
        doc.startViewTransition(acao);
        return true;
      } catch (_) {
        // Fallback para navegador sem suporte completo.
      }
    }
    acao();
    return false;
  }

  var api = {
    CHAVES_ARMAZENAMENTO: CHAVES_ARMAZENAMENTO,
    ESCALAS_VALIDAS: ESCALAS_VALIDAS,
    TEMAS_VALIDOS: TEMAS_VALIDOS,
    MOVIMENTOS_VALIDOS: MOVIMENTOS_VALIDOS,
    normalizarEscala: normalizarEscala,
    normalizarTema: normalizarTema,
    normalizarMovimento: normalizarMovimento,
    resolverMovimentoSistema: resolverMovimentoSistema,
    executarNavegacaoComTransicao: executarNavegacaoComTransicao,
    criarRepositorioPreferencias: criarRepositorioPreferencias,
    extrairTextoEducativo: extrairTextoEducativo,
    MAPA_EXPRESSAO_CAPITULO: MAPA_EXPRESSAO_CAPITULO,
    resolverExpressaoDoCapitulo: resolverExpressaoDoCapitulo,
    deveIniciarAnfitriaExpandida: deveIniciarAnfitriaExpandida,
    criarControladorDaAnfitria: criarControladorDaAnfitria,
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
