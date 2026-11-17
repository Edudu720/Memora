import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_anfitria.dart';
import '../../../l10n/textos_assistente.dart';
import '../../../l10n/textos_casca.dart';

/// A casa do Memora: primeiro ponto depois de entrar (T115, Feature 007).
///
/// Apresenta a saudação e, logo abaixo, a **anfitriã** ([MemoraAnfitria], feature
/// 013, T053): a Memora com um balão de dicas, no terço de cima da tela (FR-040).
/// Depois vêm a ação principal no [CartaoHeroi], uma grade responsiva 2x2 de
/// [TileAcaoRapida] para atalhos cotidianos e o acesso completo ao Hub ao final.
///
/// ## A anfitriã encolhe primeiro (FR-041)
///
/// Ela é a parte que cede quando falta altura: o lado do desenho é uma
/// **fração da altura da tela** dividida pela ampliação do texto, entre um
/// piso e um teto. Texto e ação nunca encolhem por causa dela — e a tela
/// continua rolando, com tudo ao alcance, quando nem assim cabe.
///
/// ## Quem fala é ela (uma Memora por tela, FR-006)
///
/// A frase que ensina a tela ("toque numa das caixas abaixo") é a primeira dica
/// da anfitriã, e não mais um balão à parte: a Memora que ensina e a que dá
/// dicas são a mesma, e o rosto dela aparece uma vez só.
///
/// ## O sinal de atividade (FR-052)
///
/// A anfitriã só sabe do toque nela e no balão. Para a dica não trocar no meio
/// da leitura de quem tocou em **qualquer** lugar do Início, a tela escuta
/// todo toque (sem consumi-lo) e avisa a anfitriã.
class TelaInicio extends StatefulWidget {
  /// Saudação nominal no topo da tela.
  static const Key chaveSaudacao = Key('inicio.saudacao');

  /// Cartão herói de ação principal ("Conversar com a Memora").
  static const Key chaveConversar = Key('inicio.conversar');

  /// Atalho para abrir todas as áreas no Hub.
  static const Key chaveVerTudo = Key('inicio.verTudo');

  /// A anfitriã, logo abaixo da saudação.
  static const Key chaveMemora = Key('inicio.memora');

  /// Contêiner semântico da ação principal de conversa.
  static const Key chaveCaixaConversar = Key('inicio.caixaConversar');

  /// Contêiner semântico da área "Ver tudo o que eu faço".
  static const Key chaveCaixaVerTudo = Key('inicio.caixaVerTudo');

  /// Nome de tratamento exibido na saudação.
  final String nome;

  /// Abre a conversa direta com a Memora.
  final VoidCallback? aoConversar;

  /// Abre o Hub completo com todas as áreas disponíveis.
  final VoidCallback? aoVerTudo;

  /// Abre o catálogo de aplicativos do dia a dia.
  final VoidCallback? aoAbrirAplicativos;

  /// Abre o catálogo de serviços públicos/sociais.
  final VoidCallback? aoAbrirServicos;

  /// Abre o registro do que a Memora fez pela pessoa.
  final VoidCallback? aoAbrirRegistro;

  /// Abre diretamente um serviço específico do catálogo.
  final void Function(String chave)? aoAbrirServicoEspecifico;

  /// Abre a área do Dispositivo de Cuidado (IoT).
  final VoidCallback? aoAbrirCuidado;

  /// Abre a tela de ajuda.
  final VoidCallback? aoAbrirAjuda;

  /// Cria a tela inicial da pessoa autenticada.
  const TelaInicio({
    required this.nome,
    this.aoConversar,
    this.aoVerTudo,
    this.aoAbrirAplicativos,
    this.aoAbrirServicos,
    this.aoAbrirRegistro,
    this.aoAbrirServicoEspecifico,
    this.aoAbrirCuidado,
    this.aoAbrirAjuda,
    super.key,
  });

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  /// Sobe a cada toque na tela: é o que a anfitriã escuta (FR-052).
  final ValueNotifier<int> _atividade = ValueNotifier<int>(0);

  @override
  void dispose() {
    _atividade.dispose();
    super.dispose();
  }

  String get nome => widget.nome;
  VoidCallback? get aoConversar => widget.aoConversar;
  VoidCallback? get aoVerTudo => widget.aoVerTudo;
  VoidCallback? get aoAbrirAplicativos => widget.aoAbrirAplicativos;
  VoidCallback? get aoAbrirServicos => widget.aoAbrirServicos;
  VoidCallback? get aoAbrirRegistro => widget.aoAbrirRegistro;
  VoidCallback? get aoAbrirCuidado => widget.aoAbrirCuidado;
  VoidCallback? get aoAbrirAjuda => widget.aoAbrirAjuda;

  List<_AcaoRapida> _montarAtalhos() {
    return <_AcaoRapida>[
      if (aoAbrirAplicativos != null || aoVerTudo != null)
        _AcaoRapida(
          icone: Icons.apps_rounded,
          titulo: TextosAssistente.portaAplicativos,
          variacao: VarianteBadge.primario,
          aoTocar: aoAbrirAplicativos ?? aoVerTudo,
        ),
      if (aoAbrirServicos != null || aoVerTudo != null)
        _AcaoRapida(
          icone: Icons.account_balance_rounded,
          titulo: TextosAssistente.portaServicos,
          variacao: VarianteBadge.primario,
          aoTocar: aoAbrirServicos ?? aoVerTudo,
        ),
      if (aoAbrirCuidado != null ||
          aoAbrirRegistro != null ||
          aoVerTudo != null)
        _AcaoRapida(
          icone: aoAbrirCuidado != null || aoAbrirRegistro == null
              ? Icons.favorite_rounded
              : Icons.history_rounded,
          titulo: aoAbrirCuidado != null || aoAbrirRegistro == null
              ? TextosCasca.atalhoCuidado
              : TextosAssistente.portaRegistro,
          variacao: aoAbrirCuidado != null || aoAbrirRegistro == null
              ? VarianteBadge.saude
              : VarianteBadge.neutro,
          aoTocar: aoAbrirCuidado ?? aoAbrirRegistro ?? aoVerTudo,
        ),
      if (aoAbrirAjuda != null || aoVerTudo != null)
        _AcaoRapida(
          icone: Icons.help_outline_rounded,
          titulo: TextosAssistente.portaAjuda,
          variacao: VarianteBadge.neutro,
          aoTocar: aoAbrirAjuda ?? aoVerTudo,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final List<_AcaoRapida> atalhos = _montarAtalhos();
    final int acoesPrincipais =
        (aoConversar != null ? 1 : 0) + (aoVerTudo != null ? 1 : 0);

    return Listener(
      // Translúcido e só de ouvinte: o toque segue para quem estava embaixo.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _atividade.value++,
      child: Scaffold(
        backgroundColor: cores.fundo,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext contexto, BoxConstraints restricoes) {
              // O lado da anfitriã: fração da altura, descontada a ampliação do
              // texto (o texto ampliado come a altura que ela deixa), entre o
              // piso do alvo de toque e o teto da ilustração principal.
              final double tamanhoAnfitria =
                  (restricoes.maxHeight *
                          MemoraDimensoes.fracaoDaAnfitriaDoInicio /
                          escala)
                      .clamp(
                        MemoraDimensoes.alvoMinimo,
                        MemoraDimensoes.ilustracaoHeroi,
                      );
              final bool emDuasColunas =
                  restricoes.maxWidth - (MemoraEspacamento.md * 2) >=
                      MemoraDimensoes.larguraMinimaGrade &&
                  escala < MemoraDimensoes.escalaColapsoGrade;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: restricoes.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(MemoraEspacamento.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _CabecalhoInicio(
                              nome: nome,
                              tamanhoDaAnfitria: tamanhoAnfitria,
                              quantidadeDeAcoes: acoesPrincipais,
                              atividade: _atividade,
                            ),
                            if (aoConversar != null) ...<Widget>[
                              const SizedBox(height: MemoraEspacamento.md),
                              KeyedSubtree(
                                key: TelaInicio.chaveCaixaConversar,
                                child: CartaoHeroi(
                                  key: TelaInicio.chaveConversar,
                                  titulo: TextosCasca.inicioConversar,
                                  subtitulo:
                                      TextosCasca.inicioInstrucaoConversar,
                                  rotuloAcao: TextosCasca.acaoComecarConversa,
                                  icone: Icons.chat_bubble_outline_rounded,
                                  aoTocar: aoConversar!,
                                ),
                              ),
                            ],
                            if (atalhos.isNotEmpty) ...<Widget>[
                              const SizedBox(height: MemoraEspacamento.md),
                              TextoMemora(
                                TextosCasca.tituloAtalhosInicio,
                                estilo: EstiloTexto.tituloSecao,
                                cabecalho: true,
                              ),
                              const SizedBox(height: MemoraEspacamento.sm),
                              _GradeAtalhosRapidos(
                                atalhos: atalhos,
                                emDuasColunas: emDuasColunas,
                              ),
                            ],
                          ],
                        ),
                        if (aoVerTudo != null) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.md),
                          KeyedSubtree(
                            key: TelaInicio.chaveCaixaVerTudo,
                            child: LinhaDeLista(
                              key: TelaInicio.chaveVerTudo,
                              esquerda: Container(
                                width: MemoraDimensoes.badgeAtalhoRapido,
                                height: MemoraDimensoes.badgeAtalhoRapido,
                                decoration: BoxDecoration(
                                  color: cores.destaque,
                                  borderRadius: BorderRadius.circular(
                                    MemoraRaio.badge,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.grid_view_rounded,
                                  size: MemoraDimensoes.iconePadrao,
                                  color: cores.primaria,
                                ),
                              ),
                              titulo: TextosCasca.inicioVerTudo,
                              subtitulo: TextosCasca.inicioInstrucaoVerTudo,
                              aoTocar: aoVerTudo,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CabecalhoInicio extends StatelessWidget {
  final String nome;
  final double tamanhoDaAnfitria;
  final int quantidadeDeAcoes;
  final Listenable atividade;

  const _CabecalhoInicio({
    required this.nome,
    required this.tamanhoDaAnfitria,
    required this.quantidadeDeAcoes,
    required this.atividade,
  });

  @override
  Widget build(BuildContext context) {
    // A primeira coisa que ela diz é a frase que ensina esta tela; com nenhuma
    // caixa não há o que apontar (FR-018), e ela só dá as dicas de sempre.
    final List<String> dicas = <String>[
      if (quantidadeDeAcoes > 0) TextosCasca.inicioTutorial(quantidadeDeAcoes),
      ...TextosAnfitria.dicas,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextoMemora.tituloTela(
          TextosCasca.inicioSaudacao(nome),
          key: TelaInicio.chaveSaudacao,
        ),
        const SizedBox(height: MemoraEspacamento.sm),
        MemoraAnfitria(
          key: TelaInicio.chaveMemora,
          dicas: dicas,
          tamanho: tamanhoDaAnfitria,
          atividade: atividade,
        ),
      ],
    );
  }
}

class _GradeAtalhosRapidos extends StatelessWidget {
  final List<_AcaoRapida> atalhos;
  final bool emDuasColunas;

  const _GradeAtalhosRapidos({
    required this.atalhos,
    required this.emDuasColunas,
  });

  @override
  Widget build(BuildContext context) {
    if (!emDuasColunas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < atalhos.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: MemoraEspacamento.sm),
            _TileAtalho(atalho: atalhos[i]),
          ],
        ],
      );
    }

    final List<Widget> linhas = <Widget>[];
    for (int i = 0; i < atalhos.length; i += 2) {
      if (i > 0) linhas.add(const SizedBox(height: MemoraEspacamento.sm));
      final bool temPar = i + 1 < atalhos.length;
      linhas.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _TileAtalho(atalho: atalhos[i])),
            if (temPar) ...<Widget>[
              const SizedBox(width: MemoraEspacamento.sm),
              Expanded(child: _TileAtalho(atalho: atalhos[i + 1])),
            ] else
              const Spacer(),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: linhas,
    );
  }
}

class _TileAtalho extends StatelessWidget {
  final _AcaoRapida atalho;

  const _TileAtalho({required this.atalho});

  @override
  Widget build(BuildContext context) {
    return TileAcaoRapida(
      icone: atalho.icone,
      titulo: atalho.titulo,
      variacao: atalho.variacao,
      aoTocar: atalho.aoTocar,
    );
  }
}

class _AcaoRapida {
  final IconData icone;
  final String titulo;
  final VarianteBadge variacao;
  final VoidCallback? aoTocar;

  const _AcaoRapida({
    required this.icone,
    required this.titulo,
    required this.variacao,
    required this.aoTocar,
  });
}
