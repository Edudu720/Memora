import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../preferencias/reducao_de_movimento.dart';
import '../../../temas/memora_theme_extension.dart';
import '../../../tokens/cores_da_memora.dart';
import '../../../tokens/movimento.dart';
import 'agenda_da_anfitria.dart';
import 'gesto_da_memora.dart';
import 'pintores/contexto_de_pintura.dart';
import 'pintores/pintor_da_memora.dart';
import 'poses.dart';
import 'vida_da_memora.dart';

/// A Memora em 2.5D, desenhada e animada pelo aplicativo (feature 013,
/// FR-001 a FR-007).
///
/// ## O que ela é
///
/// Um robô vetorial com volume (gradiente, sombra no chão, leve perspectiva e
/// paralaxe entre camadas). **Não é imagem**: as cores vêm dos tokens
/// (`context.memora.personagem`), seguem a paleta escolhida e mudam com o
/// tema.
///
/// ## O que ela garante
///
/// - **Decorativa para o leitor de tela**, sempre: nunca é a única portadora de
///   uma informação, e o gesto de toque não existe para o TalkBack (FR-005,
///   FR-005b).
/// - **Reduzir movimento** (do aplicativo ou do sistema): pose parada, nenhum
///   relógio rodando, toque sem efeito (FR-004, FR-005d).
/// - **Toque** dispara um aceno ou uma piscada, alternados, e mais nada: não
///   navega, não fala (FR-005a). Toque durante um gesto é ignorado.
/// - **Viva em todas as expressões** (T083, FR-003a): além de respirar, cada
///   pose tem movimentos próprios e pequenos (ver [VidaDaPose]), que nunca
///   disputam a atenção com o texto. Com "reduzir movimento", nenhum.
/// - **Barata**: camada de repintura própria e relógios parados fora da tela
///   (`TickerMode`), para o aparelho de entrada (R11).
class MemoraAnimada extends StatefulWidget {
  /// A pose atual. Trocar interpola até a nova.
  final PoseDaMemora expressao;

  /// O lado do quadrado que ela ocupa.
  final double tamanho;

  /// Liga o ciclo de fala (a boca acompanha o texto que aparece).
  final bool falando;

  /// Se o toque nela dispara aceno ou piscada.
  final bool reageAoToque;

  /// Dispara um gesto único. Para repetir o mesmo gesto, volte a `null` antes.
  final GestoDaMemora? gesto;

  /// Se é a **anfitriã** do Início (feature 013, T087 e T088): acabamento de
  /// maior detalhe (brilho, luz de contorno, sombra de contato) e um repertório
  /// de comportamentos que ela faz sozinha ([AgendaDaAnfitria]). Mais animada
  /// que as outras e igualmente parada com "reduzir movimento".
  final bool anfitria;

  /// A semente do sorteio dos comportamentos da anfitriã. Só para teste; em
  /// uso, cada anfitriã tem a sua sequência.
  final int? sementeDaAgenda;

  /// O andamento da barra de carregamento que ela segura na pose
  /// [PoseDaMemora.carregando] (T092): de 0 a 1 é uma passada do trecho que
  /// corre dentro da barra. Quem segura o relógio é quem sabe o que está
  /// carregando (a abertura), e ele passa por `MemoraMovimento.efetiva`
  /// lá. **Nulo, ou com "reduzir movimento", a barra fica parada.**
  final Animation<double>? cicloDaBarra;

  /// Se ela **chega** ao aparecer: cresce um pouco a partir dos pés. Falso na
  /// abertura (T094): ali ela já estava na tela, parada, no desenho do
  /// Android, e o primeiro quadro do aplicativo precisa ser do mesmo tamanho
  /// (FR-037). Crescer de 90% ali seria um encolher seguido de um pulo.
  final bool chega;

  /// Cria a Memora animada.
  const MemoraAnimada({
    required this.expressao,
    required this.tamanho,
    this.falando = false,
    this.reageAoToque = true,
    this.gesto,
    this.anfitria = false,
    this.sementeDaAgenda,
    this.cicloDaBarra,
    this.chega = true,
    super.key,
  });

  @override
  State<MemoraAnimada> createState() => _MemoraAnimadaState();
}

enum _EstadoDoGesto { ocioso, emGesto }

class _MemoraAnimadaState extends State<MemoraAnimada>
    with TickerProviderStateMixin {
  /// O relógio dos ciclos (respiração, fala, balanço, piscada). Ele só roda
  /// quando há movimento permitido, e para sozinho fora da tela.
  late final AnimationController _relogio = AnimationController(vsync: this);

  /// De uma pose para a outra.
  late final AnimationController _troca =
      AnimationController(vsync: this, value: 1);

  /// O gesto em curso.
  late final AnimationController _gestoCtrl = AnimationController(vsync: this);

  /// A chegada.
  late final AnimationController _chegada =
      AnimationController(vsync: this, value: 1);

  // ---- a anfitriã (T088) ----
  late final AgendaDaAnfitria _agenda = AgendaDaAnfitria(
    semente: widget.sementeDaAgenda,
  );
  ComportamentoDaAnfitria _comportamento = ComportamentoDaAnfitria.descansar;
  double _duracaoDoComportamento = AgendaDaAnfitria.primeiraPausa;
  double _tempoNoComportamento = 0;
  double _ladoDoComportamento = 1;
  double _ultimoValorDoRelogio = 0;

  late ValoresDaPose _de = ValoresDaPose.de(widget.expressao);
  late ValoresDaPose _para = _de;

  _EstadoDoGesto _estado = _EstadoDoGesto.ocioso;
  GestoDaMemora _gestoAtual = GestoDaMemora.aceno;
  GestoDaMemora _proximoToque = GestoDaMemora.aceno;
  bool _reduzir = true;
  bool _primeiraVez = true;

  /// A duração de um ciclo inteiro do relógio: 12 s, múltiplo de todos os
  /// períodos que ele alimenta (respiração 4 s, fala 0,6 s e 1,5 s, balanço
  /// 6 s, a vida de cada pose), para o ciclo emendar sem salto.
  static const int _segundosDoCiclo = 12;

  /// O piscar sozinho: os instantes (em segundos do ciclo de 12 s) em que ela
  /// pisca, de propósito sem intervalo regular — uma dupla no meio e depois um
  /// intervalo longo. Piscar a cada 4 s exatos parece máquina.
  static const List<double> _instantesDePiscar = <double>[3.9, 7.4, 8.1, 11.0];

  @override
  void initState() {
    super.initState();
    _relogio.addListener(_aoRelogio);
    _gestoCtrl.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _estado = _EstadoDoGesto.ocioso);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduzir = context.reduzirMovimento;
    if (reduzir != _reduzir || _primeiraVez) {
      _reduzir = reduzir;
      _aplicarReducao();
    }
    if (_primeiraVez) {
      _primeiraVez = false;
      if (!_reduzir) _comecar();
    }
  }

  /// A cada quadro do relógio, anda a agenda da anfitriã.
  ///
  /// O tempo vem da **diferença do relógio** (que dá a volta a cada 12 s), e
  /// não de um segundo `Ticker`: um relógio só, parado fora da tela junto com
  /// o resto (R11, FR-058). Uma diferença maior que um segundo é o relógio
  /// voltando de uma parada (fora da tela, rota de trás), e não tempo vivido:
  /// não conta.
  void _aoRelogio() {
    if (!widget.anfitria || _reduzir) return;
    double d = _relogio.value - _ultimoValorDoRelogio;
    if (d < 0) d += 1;
    _ultimoValorDoRelogio = _relogio.value;
    final double dt = d * _segundosDoCiclo;
    if (dt > 1) return;
    _tempoNoComportamento += dt;
    if (_tempoNoComportamento >= _duracaoDoComportamento) {
      _proximoComportamento();
    }
  }

  void _proximoComportamento() {
    final PassoDaAgenda passo = _agenda.proximo();
    _comportamento = passo.comportamento;
    _duracaoDoComportamento = passo.duracao;
    _ladoDoComportamento = passo.sinal;
    _tempoNoComportamento = 0;
    switch (passo.comportamento) {
      case ComportamentoDaAnfitria.acenar:
        _disparar(GestoDaMemora.aceno);
      case ComportamentoDaAnfitria.pular:
        _disparar(GestoDaMemora.pulinho);
      case ComportamentoDaAnfitria.descansar:
      case ComportamentoDaAnfitria.olharEmVolta:
      case ComportamentoDaAnfitria.inclinarACabeca:
        break;
    }
  }

  /// Liga ou desliga todo o movimento conforme a preferência.
  void _aplicarReducao() {
    if (_reduzir) {
      _relogio.stop();
      _gestoCtrl.stop();
      _troca.value = 1;
      _chegada.value = 1;
      _de = _para;
      _estado = _EstadoDoGesto.ocioso;
    } else if (!_relogio.isAnimating) {
      _ultimoValorDoRelogio = _relogio.value;
      _relogio.repeat(
        period: MemoraMovimento.respiracao * (_segundosDoCiclo ~/ 4),
      );
    }
  }

  /// A chegada de uma Memora que acabou de aparecer: um pequeno crescimento
  /// e, para o aceno e a comemoração, o gesto que combina com ela.
  void _comecar() {
    if (widget.chega) {
      _chegada.value = 0;
      _chegada.animateTo(
        1,
        duration: MemoraMovimento.efetiva(
          MemoraMovimento.trocaDeExpressao,
          reduzirMovimento: _reduzir,
        ),
        curve: Curves.easeOutBack,
      );
    }
    if (widget.gesto != null) {
      _disparar(widget.gesto!);
    } else if (widget.expressao == PoseDaMemora.acenando) {
      _disparar(GestoDaMemora.aceno);
    } else if (widget.expressao == PoseDaMemora.comemorando) {
      _disparar(GestoDaMemora.comemoracao);
    }
  }

  @override
  void didUpdateWidget(MemoraAnimada antigo) {
    super.didUpdateWidget(antigo);
    if (widget.expressao != antigo.expressao) {
      _de = _valoresAgora();
      _para = ValoresDaPose.de(widget.expressao);
      if (_reduzir) {
        _de = _para;
        _troca.value = 1;
      } else {
        _troca.value = 0;
        _troca.animateTo(
          1,
          duration: MemoraMovimento.efetiva(
            MemoraMovimento.trocaDeExpressao,
            reduzirMovimento: _reduzir,
          ),
        );
        if (widget.expressao == PoseDaMemora.acenando) {
          _disparar(GestoDaMemora.aceno);
        }
      }
    }
    if (widget.gesto != null && widget.gesto != antigo.gesto) {
      _disparar(widget.gesto!);
    }
  }

  @override
  void dispose() {
    _relogio.removeListener(_aoRelogio);
    _relogio.dispose();
    _troca.dispose();
    _gestoCtrl.dispose();
    _chegada.dispose();
    super.dispose();
  }

  Duration _duracaoDo(GestoDaMemora g) {
    switch (g) {
      case GestoDaMemora.aceno:
        return MemoraMovimento.aceno;
      case GestoDaMemora.piscada:
        return MemoraMovimento.piscada;
      case GestoDaMemora.comemoracao:
        return MemoraMovimento.comemoracao;
      case GestoDaMemora.pulinho:
        return MemoraMovimento.pulinho;
    }
  }

  /// A máquina `ocioso → emGesto → ocioso`. Gesto pedido durante outro é
  /// ignorado, e com reduzir movimento nada acontece.
  ///
  /// Com as mãos ocupadas pela barra (T092), o gesto que levanta os braços
  /// (o aceno, a comemoração) também não acontece: ela não larga a barra.
  void _disparar(GestoDaMemora g) {
    if (_reduzir || _estado == _EstadoDoGesto.emGesto) return;
    if (_maosOcupadas &&
        (g == GestoDaMemora.aceno || g == GestoDaMemora.comemoracao)) {
      return;
    }
    setState(() {
      _estado = _EstadoDoGesto.emGesto;
      _gestoAtual = g;
    });
    _gestoCtrl.value = 0;
    _gestoCtrl.animateTo(
      1,
      duration: MemoraMovimento.efetiva(
        _duracaoDo(g),
        reduzirMovimento: _reduzir,
      ),
    );
  }

  /// Se ela está segurando a barra (ou indo pegá-la).
  bool get _maosOcupadas => _para.barra > 0 || _de.barra > 0;

  void _aoTocar() {
    if (!widget.reageAoToque || _reduzir) return;
    if (_estado == _EstadoDoGesto.emGesto) return;
    final GestoDaMemora g = _proximoToque;
    _proximoToque = g == GestoDaMemora.aceno
        ? GestoDaMemora.piscada
        : GestoDaMemora.aceno;
    _disparar(g);
  }

  /// A pose que vale agora: a da troca em curso, com o gesto por cima.
  ValoresDaPose _valoresAgora() {
    ValoresDaPose v = ValoresDaPose.lerp(
      _de,
      _para,
      ValoresDaPose.suavizar(_troca.value),
    );
    if (_estado == _EstadoDoGesto.emGesto) {
      final double e = ValoresDaPose.envelope(_gestoCtrl.value);
      switch (_gestoAtual) {
        case GestoDaMemora.aceno:
          final ValoresDaPose acenando =
              ValoresDaPose.de(PoseDaMemora.acenando);
          v = v.copiar(
            bracoDireito: PosicaoDoBraco.lerp(
              v.bracoDireito,
              acenando.bracoDireito,
              math.min(1.0, e * 1.8),
            ),
          );
        case GestoDaMemora.piscada:
        case GestoDaMemora.pulinho:
          break;
        case GestoDaMemora.comemoracao:
          v = ValoresDaPose.lerp(
            v,
            ValoresDaPose.de(PoseDaMemora.comemorando),
            math.min(1.0, e * 1.4),
          );
      }
    }
    return v;
  }

  ContextoDePintura _quadro(double lado, CoresDaMemora cores) {
    final double segundos = _relogio.value * _segundosDoCiclo;
    const double volta = 2 * math.pi;

    double respira = 0;
    double fala = 0;
    double piscar = 0;
    double balanco = 0;
    double aceno = 0;
    double pulo = 0;
    double esticar = 0;
    double flutua = 0;
    VidaNoInstante vida = VidaNoInstante.parada;
    double giroDoComportamento = 0;
    double olharDoComportamento = 0;
    double olharYDoComportamento = 0;
    double cabecaDoComportamento = 0;

    if (!_reduzir) {
      respira = math.sin(volta * segundos / 4);
      balanco = 0.35 * math.sin(volta * segundos / 6);
      if (widget.falando) {
        final double silaba = 0.5 + 0.5 * math.sin(volta * segundos / 0.6);
        final double frase = 0.5 + 0.5 * math.sin(volta * segundos / 1.5);
        fala = silaba * (0.45 + 0.55 * frase);
      }
      for (final double instante in _instantesDePiscar) {
        double d = (segundos - instante).abs();
        if (d > _segundosDoCiclo / 2) d = _segundosDoCiclo - d;
        if (d < 0.12) {
          piscar = math.max(piscar, math.sin(math.pi * (1 - d / 0.12)));
        }
      }

      // A vida da pose (T083): a anfitriã se mexe mais que as outras.
      vida = VidaNoInstante.calcular(
        widget.expressao,
        segundos,
        intensidade: widget.anfitria ? 1.5 : 1,
      );

      if (widget.anfitria) {
        flutua = 0.5 + 0.5 * math.sin(volta * segundos / 6 + 1);
        final double p = (_tempoNoComportamento / _duracaoDoComportamento)
            .clamp(0.0, 1.0);
        switch (_comportamento) {
          case ComportamentoDaAnfitria.olharEmVolta:
            // Vai para um lado, depois para o outro, e volta ao centro.
            final double x = _ladoDoComportamento *
                math.sin(volta * p) *
                math.pow(math.sin(math.pi * p), 0.4);
            giroDoComportamento = 0.9 * x;
            olharDoComportamento = 1.5 * x;
            olharYDoComportamento = -0.4 * math.sin(math.pi * p);
          case ComportamentoDaAnfitria.inclinarACabeca:
            final double e = ValoresDaPose.envelope(p);
            cabecaDoComportamento = _ladoDoComportamento * 0.1 * e;
            olharDoComportamento = _ladoDoComportamento * 0.6 * e;
          case ComportamentoDaAnfitria.descansar:
          case ComportamentoDaAnfitria.acenar:
          case ComportamentoDaAnfitria.pular:
            break;
        }
      }

      if (_estado == _EstadoDoGesto.emGesto) {
        final double g = _gestoCtrl.value;
        final double e = ValoresDaPose.envelope(g);
        switch (_gestoAtual) {
          case GestoDaMemora.aceno:
            aceno = math.sin(volta * g * 3) * math.min(1.0, e * 2);
            balanco += 0.6 * e;
          case GestoDaMemora.piscada:
            piscar = math.max(piscar, e);
          case GestoDaMemora.comemoracao:
            pulo = e;
            if (widget.anfitria) esticar = PuloDaMemora.esticar(g);
          case GestoDaMemora.pulinho:
            pulo = PuloDaMemora.altura(g) * 0.75;
            esticar = PuloDaMemora.esticar(g);
        }
      }
    }

    final ValoresDaPose base = _valoresAgora();
    return ContextoDePintura(
      lado: lado,
      cores: cores,
      pose: base.copiar(
        olharX: base.olharX + vida.olharX + olharDoComportamento,
        olharY: base.olharY + vida.olharY + olharYDoComportamento,
        inclinacaoDaCabeca:
            base.inclinacaoDaCabeca + vida.cabeca + cabecaDoComportamento,
      ),
      respira: respira,
      fala: fala,
      piscar: piscar,
      aceno: aceno,
      pulo: pulo,
      balanco: balanco,
      entrada: _chegada.value,
      antena: vida.antena,
      ajeita: vida.ajeita,
      giro: (vida.giro + giroDoComportamento).clamp(-1.0, 1.0),
      flutua: flutua,
      esticar: esticar,
      detalhada: widget.anfitria,
      cicloDaBarra: _reduzir ? null : widget.cicloDaBarra?.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CoresDaMemora cores = context.memora.personagem;
    final double lado = widget.tamanho;

    final Widget desenho = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _relogio,
          _troca,
          _gestoCtrl,
          _chegada,
          if (widget.cicloDaBarra != null) widget.cicloDaBarra!,
        ]),
        builder: (BuildContext context, Widget? _) {
          final ContextoDePintura quadro = _quadro(lado, cores);
          // Leve perspectiva: a Memora vira poucos graus em torno do eixo
          // vertical, com ponto de fuga (setEntry 3,2), sem sair do quadrado.
          final Matrix4 perspectiva = Matrix4.identity()
            ..setEntry(3, 2, 0.3 / lado)
            ..rotateY(quadro.balanco * 0.12);
          return Transform(
            alignment: Alignment.center,
            transform: perspectiva,
            child: CustomPaint(
              size: Size.square(lado),
              painter: PintorDaMemora((double _) => quadro),
            ),
          );
        },
      ),
    );

    final Widget alvo = (widget.reageAoToque && !_reduzir)
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _aoTocar,
            child: desenho,
          )
        : desenho;

    return ExcludeSemantics(
      child: SizedBox.square(dimension: lado, child: alvo),
    );
  }
}
