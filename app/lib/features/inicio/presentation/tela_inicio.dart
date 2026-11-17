import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_assistente.dart';
import '../../../l10n/textos_casca.dart';

/// A casa do Memora: primeiro ponto depois de entrar (T115, Feature 007).
///
/// Apresenta a saudação editorial com a mascote [ExpressaoDaMemora.mini], a
/// ação principal no [CartaoHeroi], uma grade responsiva 2x2 de [TileAcaoRapida]
/// para atalhos cotidianos e o acesso completo ao Hub ao final da tela.
class TelaInicio extends StatelessWidget {
  /// Saudação nominal no topo da tela.
  static const Key chaveSaudacao = Key('inicio.saudacao');

  /// Cartão herói de ação principal ("Conversar com a Memora").
  static const Key chaveConversar = Key('inicio.conversar');

  /// Atalho para abrir todas as áreas no Hub.
  static const Key chaveVerTudo = Key('inicio.verTudo');

  /// Mascote exibida junto à saudação (oculta em ampliações muito altas).
  static const Key chaveMemora = Key('inicio.memora');

  /// Balão de acolhimento com orientação breve logo abaixo da saudação.
  static const Key chaveTutorial = Key('inicio.tutorial');

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

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext contexto, BoxConstraints restricoes) {
            final double alturaPermitidaFigura =
                restricoes.maxHeight * MemoraDimensoes.fracaoDaFiguraDoInicio;
            final bool mostrarMascote =
                escala < MemoraDimensoes.escalaTextoAlta &&
                alturaPermitidaFigura >= MemoraDimensoes.pisoDeIlustracao;
            final double tamanhoMascote =
                alturaPermitidaFigura < MemoraDimensoes.iconeEstadoVazio
                ? alturaPermitidaFigura
                : MemoraDimensoes.iconeEstadoVazio;
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
                            mostrarMascote: mostrarMascote,
                            tamanhoMascote: tamanhoMascote,
                            quantidadeDeAcoes: acoesPrincipais,
                          ),
                          if (aoConversar != null) ...<Widget>[
                            const SizedBox(height: MemoraEspacamento.md),
                            KeyedSubtree(
                              key: chaveCaixaConversar,
                              child: CartaoHeroi(
                                key: chaveConversar,
                                titulo: TextosCasca.inicioConversar,
                                subtitulo: TextosCasca.inicioInstrucaoConversar,
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
                          key: chaveCaixaVerTudo,
                          child: LinhaDeLista(
                            key: chaveVerTudo,
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
    );
  }
}

class _CabecalhoInicio extends StatelessWidget {
  final String nome;
  final bool mostrarMascote;
  final double tamanhoMascote;
  final int quantidadeDeAcoes;

  const _CabecalhoInicio({
    required this.nome,
    required this.mostrarMascote,
    required this.tamanhoMascote,
    required this.quantidadeDeAcoes,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final String textoTutorial = quantidadeDeAcoes > 0
        ? TextosCasca.inicioTutorial(quantidadeDeAcoes)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextoMemora.tituloTela(
                TextosCasca.inicioSaudacao(nome),
                key: TelaInicio.chaveSaudacao,
              ),
            ),
            if (mostrarMascote) ...<Widget>[
              const SizedBox(width: MemoraEspacamento.md),
              MemoraPersonagem(
                key: TelaInicio.chaveMemora,
                expressao: ExpressaoDaMemora.mini,
                tamanho: tamanhoMascote,
              ),
            ],
          ],
        ),
        if (quantidadeDeAcoes > 0) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.sm),
          Semantics(
            container: true,
            label: 'Memora disse: $textoTutorial',
            child: ExcludeSemantics(
              child: Cartao(
                key: TelaInicio.chaveTutorial,
                comBorda: ehAltoContraste,
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraEspacamento.md,
                  vertical: MemoraEspacamento.sm,
                ),
                child: TextoMemora.apoio(textoTutorial),
              ),
            ),
          ),
        ],
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
