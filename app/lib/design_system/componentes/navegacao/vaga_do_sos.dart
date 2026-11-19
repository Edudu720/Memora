import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';

/// Escopo herdado da casca autenticada: diz aos cabeçalhos que o botão SOS
/// existe e como construí-lo (feature 014, sessão de 2026-11-18).
///
/// ## Por que o cabeçalho, e não a casca, desenha o SOS
///
/// Até 2026-11-18 a casca desenhava uma faixa inteira no topo só para o SOS, e
/// a `BarraSuperior` "assumia" o botão quando cabia. A faixa gastava uma linha
/// de toda tela, e o botão mostrava três textos (ícone, "SOS" e "Ajuda").
/// Agora o SOS é uma bolinha, e quem a desenha é o cabeçalho de cada tela, no
/// canto superior direito, por uma [VagaDoSos]. A casca só desenha a bolinha
/// por conta própria — flutuando no canto — quando nenhum cabeçalho à vista
/// tem a vaga.
class EscopoSosNaCasca extends InheritedWidget {
  /// Constrói o botão SOS já com a ação configurada pela casca.
  final WidgetBuilder construirBotao;

  /// O lado da bolinha, nesta escala de texto. Os cabeçalhos medem com ele se
  /// o título ainda cabe ao lado dela.
  final double Function(BuildContext context) diametroDoBotao;

  /// Notifica a casca quando uma [VagaDoSos] à vista passa a mostrar (`true`)
  /// ou deixa de mostrar (`false`) o botão.
  final ValueChanged<bool> aoAlterarVagaAtiva;

  /// Cria o escopo herdado.
  const EscopoSosNaCasca({
    required this.construirBotao,
    required this.diametroDoBotao,
    required this.aoAlterarVagaAtiva,
    required super.child,
    super.key,
  });

  /// Retorna o escopo mais próximo, quando a tela está dentro da `CascaInterna`.
  static EscopoSosNaCasca? talvezDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EscopoSosNaCasca>();

  @override
  bool updateShouldNotify(EscopoSosNaCasca oldWidget) =>
      construirBotao != oldWidget.construirBotao ||
      diametroDoBotao != oldWidget.diametroDoBotao ||
      aoAlterarVagaAtiva != oldWidget.aoAlterarVagaAtiva;
}

/// O lugar do botão SOS no canto direito de um cabeçalho.
///
/// Fora da casca (sem [EscopoSosNaCasca]) não ocupa nada. Dentro, mostra a
/// bolinha a [MemoraDimensoes.separacaoAlvo] do que estiver à esquerda, e
/// avisa a casca enquanto está à vista — a casca então não desenha a bolinha
/// flutuante, e a tela nunca mostra duas.
class VagaDoSos extends StatefulWidget {
  /// Cria a vaga.
  const VagaDoSos({super.key});

  /// Quanto a vaga ocupa na linha, com a separação: zero fora da casca.
  static double larguraOcupada(BuildContext context) {
    final EscopoSosNaCasca? escopo = EscopoSosNaCasca.talvezDe(context);
    if (escopo == null) return 0;
    return escopo.diametroDoBotao(context) + MemoraDimensoes.separacaoAlvo;
  }

  /// A palavra mais longa de [texto], em [estilo] e na escala de texto da
  /// pessoa, cabe em [largura]?
  ///
  /// É a pergunta que decide se o SOS fica ao lado do título ou sobe uma
  /// linha: o título nunca é cortado (FR-001 da 004), e uma palavra que não
  /// cabe seria partida no meio.
  static bool palavrasCabem(
    BuildContext context, {
    required String texto,
    required TextStyle estilo,
    required double largura,
  }) {
    if (largura <= 0) return false;
    final TextScaler escala = escalaTextoLimitada(context);
    double maior = 0;
    for (final String palavra in texto.split(RegExp(r'\s+'))) {
      if (palavra.isEmpty) continue;
      final TextPainter medida = TextPainter(
        text: TextSpan(text: palavra, style: estilo),
        textDirection: TextDirection.ltr,
        textScaler: escala,
        maxLines: 1,
      )..layout();
      if (medida.width > maior) maior = medida.width;
      medida.dispose();
    }
    return maior <= largura;
  }

  @override
  State<VagaDoSos> createState() => _VagaDoSosState();
}

class _VagaDoSosState extends State<VagaDoSos> {
  bool _registrada = false;
  ValueChanged<bool>? _avisar;

  void _atualizar(bool proximo) {
    if (_registrada == proximo) return;
    _registrada = proximo;
    final ValueChanged<bool>? avisar = _avisar;
    if (avisar == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) => avisar(proximo));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EscopoSosNaCasca? escopo = EscopoSosNaCasca.talvezDe(context);
    if (escopo?.aoAlterarVagaAtiva != _avisar) {
      // Trocou de casca (ou saiu dela): devolve o registro à anterior.
      _atualizar(false);
      _avisar = escopo?.aoAlterarVagaAtiva;
    }
    // Uma pilha fora de vista (outro destino, rota coberta) tem os tickers
    // desligados: a vaga dela não conta, e a da tela à vista, sim.
    _atualizar(escopo != null && TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _atualizar(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EscopoSosNaCasca? escopo = EscopoSosNaCasca.talvezDe(context);
    if (escopo == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: MemoraDimensoes.separacaoAlvo),
      child: escopo.construirBotao(context),
    );
  }
}

/// O título grande de uma tela com a vaga do SOS no canto direito.
///
/// É o que o [CabecalhoDeTela], o Início e o Meu perfil usam: o SOS fica **na
/// altura do título**, no espaço que sobrava à direita. Quando a palavra mais
/// longa do título não cabe ao lado da bolinha (letra muito ampliada, aparelho
/// estreito), o SOS sobe para a linha de [acima] — a do "Voltar" —, ou para
/// uma linha só dele, à direita, quando não há "Voltar". O título nunca é
/// cortado por causa dele.
///
/// ## A figura vai para a esquerda
///
/// Com o SOS na casca, a figura de [figura] (a ilustração de Ajustes, por
/// exemplo) sai do canto direito, que agora é do SOS, e fica **antes do
/// título**, do tamanho de [MemoraDimensoes.ilustracaoCartao] (decisão do
/// Henrique para Ajustes, 2026-11-18, aplicada a todo cabeçalho). Fora da
/// casca ela continua à direita, no tamanho de [tamanhoDaFigura].
class TituloComSos extends StatelessWidget {
  /// O título.
  final String titulo;

  /// Chave do texto do título, para os testes.
  final Key? chaveDoTitulo;

  /// O que vem acima do título (o "Voltar"). Nulo, nada.
  final Widget? acima;

  /// O lado da figura fora da casca. Nulo, sem figura.
  final double? tamanhoDaFigura;

  /// Constrói a figura no tamanho pedido.
  final Widget Function(double tamanho)? figura;

  /// Cria a linha do título.
  const TituloComSos({
    required this.titulo,
    this.chaveDoTitulo,
    this.acima,
    this.tamanhoDaFigura,
    this.figura,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final EscopoSosNaCasca? escopo = EscopoSosNaCasca.talvezDe(context);
    final Widget texto = TextoMemora.tituloTela(titulo, key: chaveDoTitulo);
    final bool temFigura = tamanhoDaFigura != null && figura != null;

    if (escopo == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (acima != null) ...<Widget>[
            acima!,
            const SizedBox(height: MemoraEspacamento.sm),
          ],
          Row(
            children: <Widget>[
              Expanded(child: texto),
              if (temFigura) ...<Widget>[
                const SizedBox(width: MemoraEspacamento.md),
                figura!(tamanhoDaFigura!),
              ],
            ],
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext contexto, BoxConstraints restricoes) {
        final double? ladoDaFigura = !temFigura
            ? null
            : (tamanhoDaFigura! < MemoraDimensoes.ilustracaoCartao
                  ? tamanhoDaFigura
                  : MemoraDimensoes.ilustracaoCartao);
        final double larguraDaFigura = ladoDaFigura == null
            ? 0
            : ladoDaFigura + MemoraEspacamento.md;
        final bool sosAoLado = VagaDoSos.palavrasCabem(
          contexto,
          texto: titulo,
          estilo: MemoraTipografia.tituloTela,
          largura:
              restricoes.maxWidth -
              larguraDaFigura -
              VagaDoSos.larguraOcupada(contexto),
        );

        final Widget linhaDoTitulo = Row(
          children: <Widget>[
            if (ladoDaFigura != null) ...<Widget>[
              figura!(ladoDaFigura),
              const SizedBox(width: MemoraEspacamento.md),
            ],
            Expanded(child: texto),
            if (sosAoLado) const VagaDoSos(),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (sosAoLado) ...<Widget>[
              if (acima != null) ...<Widget>[
                Align(alignment: Alignment.centerLeft, child: acima),
                const SizedBox(height: MemoraEspacamento.sm),
              ],
            ] else ...<Widget>[
              Row(
                mainAxisAlignment: acima == null
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (acima != null) Flexible(child: acima!),
                  const VagaDoSos(),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.sm),
            ],
            linhaDoTitulo,
          ],
        );
      },
    );
  }
}
