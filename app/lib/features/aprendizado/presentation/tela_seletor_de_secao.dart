import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../assistente/domain/assistente.dart';
import '../data/progresso_de_aprendizado.dart';
import '../domain/guia.dart';

/// Tela de escolha de assunto para guias extensos (`T052`, Feature 006).
///
/// Exibe cabeçalho acolhedor do aplicativo/serviço com [BadgeDeStatus] de
/// progresso e [ExpressaoDaMemora.dica], seguido pela lista de módulos em
/// [LinhaDeLista] com badges circulares numerados.
class TelaSeletorDeSecao extends StatefulWidget {
  /// Chave da lista de seções, para os testes.
  static const Key chaveLista = Key('seletor_secao.lista');

  /// Chave do botão de perguntar à Memora quando não achar o assunto.
  static const Key chaveConversar = Key('seletor_secao.conversar');

  /// Chave de uma seção, pela sua `chave`.
  static Key chaveDaSecao(String chave) => Key('seletor_secao.item.$chave');

  /// Guia seccionado a ser exibido.
  final Guia guia;

  /// Dados do serviço no catálogo (opcional).
  final ServicoDoCatalogo? servico;

  /// Progresso local para sinalizar seções já aprendidas.
  final ProgressoDeAprendizado? progresso;

  /// Identificador da conta conectada.
  final String? idDaConta;

  /// Chamado ao escolher uma seção para iniciar o passo a passo.
  final void Function(SecaoDoGuia secao) aoEscolherSecao;

  /// Chamado ao tocar em "Não achei o que procuro — perguntar à Memora".
  final VoidCallback? aoConversar;

  /// Chamado ao tocar em "Voltar".
  final VoidCallback aoVoltar;

  /// Cria a tela de seleção de seção.
  const TelaSeletorDeSecao({
    required this.guia,
    required this.aoEscolherSecao,
    required this.aoVoltar,
    this.servico,
    this.progresso,
    this.idDaConta,
    this.aoConversar,
    super.key,
  });

  @override
  State<TelaSeletorDeSecao> createState() => _TelaSeletorDeSecaoState();
}

class _TelaSeletorDeSecaoState extends State<TelaSeletorDeSecao> {
  final Set<String> _concluidas = <String>{};

  @override
  void initState() {
    super.initState();
    _carregarProgresso();
  }

  Future<void> _carregarProgresso() async {
    final ProgressoDeAprendizado? prog = widget.progresso;
    final String? id = widget.idDaConta;
    if (prog == null || id == null || id.trim().isEmpty) return;

    try {
      final Map<String, int> concluidos = await prog.concluidos(id);
      if (!mounted) return;
      final Set<String> feitos = <String>{
        for (final SecaoDoGuia secao in widget.guia.secoes)
          if ((concluidos['${widget.guia.chave}:${secao.chave}'] ?? 0) > 0)
            secao.chave,
      };
      if (feitos.isNotEmpty) {
        setState(() => _concluidas.addAll(feitos));
      }
    } catch (_) {
      // Falha silenciosa: erro local não impede escolher a seção.
    }
  }

  String get _nomeServico => widget.servico?.nomeExibido ?? widget.guia.titulo;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;
    final int totalSecoes = widget.guia.secoes.length;
    final int totalConcluidas = _concluidas.length;
    final bool todasConcluidas = totalSecoes > 0 && totalConcluidas == totalSecoes;

    final String rotuloProgresso = totalConcluidas > 0
        ? '$totalConcluidas de $totalSecoes assuntos aprendidos'
        : '$totalSecoes assuntos para aprender';

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: _nomeServico,
              aoVoltar: widget.aoVoltar,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: TelaSeletorDeSecao.chaveLista,
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Cabeçalho editorial do aplicativo/serviço com progresso e dica
                    Cartao(
                      padding: const EdgeInsets.all(MemoraEspacamento.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              if (escala <
                                  MemoraDimensoes.escalaTextoAlta) ...<Widget>[
                                IconeDoAplicativo(
                                  chave: widget.guia.chave,
                                  nome: _nomeServico,
                                  tamanho: MemoraDimensoes.alvoDecisao,
                                ),
                                const SizedBox(width: MemoraEspacamento.md),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    TextoMemora(
                                      _nomeServico,
                                      estilo: EstiloTexto.tituloSecao,
                                    ),
                                    const SizedBox(height: MemoraEspacamento.xs),
                                    BadgeDeStatus(
                                      rotulo: rotuloProgresso,
                                      icone: todasConcluidas
                                          ? Icons.check_circle_outline
                                          : Icons.menu_book_outlined,
                                      tom: todasConcluidas
                                          ? TomBadgeStatus.positivo
                                          : TomBadgeStatus.informativo,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: MemoraEspacamento.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (escala <
                                  MemoraDimensoes.escalaTextoAlta) ...<Widget>[
                                const MemoraPersonagem(
                                  expressao: ExpressaoDaMemora.dica,
                                  tamanho: MemoraDimensoes.alvoMinimo,
                                ),
                                const SizedBox(width: MemoraEspacamento.md),
                              ],
                              Expanded(
                                child: TextoMemora(
                                  'O que você quer aprender no $_nomeServico? Escolha um assunto abaixo:',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MemoraEspacamento.lg),

                    for (int i = 0;
                        i < widget.guia.secoes.length;
                        i++) ...<Widget>[
                      _buildModuloLinha(
                        context: context,
                        cores: cores,
                        ehAltoContraste: ehAltoContraste,
                        compacto: compacto,
                        indice: i,
                        secao: widget.guia.secoes[i],
                      ),
                      const SizedBox(height: MemoraEspacamento.sm),
                    ],

                    if (widget.aoConversar != null) ...<Widget>[
                      const SizedBox(height: MemoraEspacamento.md),
                      BotaoSecundario(
                        key: TelaSeletorDeSecao.chaveConversar,
                        rotulo: 'Não achei o que procuro — perguntar à Memora',
                        icone: Icons.chat_bubble_outline,
                        aoTocar: widget.aoConversar!,
                      ),
                    ],
                    const SizedBox(height: MemoraEspacamento.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuloLinha({
    required BuildContext context,
    required MemoraCores cores,
    required bool ehAltoContraste,
    required bool compacto,
    required int indice,
    required SecaoDoGuia secao,
  }) {
    final bool concluida = _concluidas.contains(secao.chave);
    final int qtd = secao.passos.length;
    final String contagem = '$qtd ${qtd == 1 ? 'passo' : 'passos'}';
    final String subtitulo = concluida && compacto
        ? '${secao.subtitulo} · $contagem · Já aprendeu'
        : (compacto
              ? '${secao.subtitulo} · $contagem'
              : (concluida
                    ? '${secao.subtitulo} · Já aprendeu'
                    : secao.subtitulo));

    return LinhaDeLista(
      key: TelaSeletorDeSecao.chaveDaSecao(secao.chave),
      esquerda: Container(
        width: MemoraDimensoes.alvoMinimo,
        height: MemoraDimensoes.alvoMinimo,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: concluida ? cores.saudeSuave : cores.destaque,
          shape: BoxShape.circle,
          border: ehAltoContraste
              ? Border.all(
                  color: cores.borda,
                  width: MemoraDimensoes.bordaEnfase,
                )
              : null,
        ),
        child: TextoMemora(
          '${indice + 1}',
          estilo: EstiloTexto.corpoForte,
          cor: concluida ? cores.sucessoTexto : cores.primaria,
        ),
      ),
      titulo: secao.titulo,
      subtitulo: subtitulo,
      direita: compacto
          ? null
          : TextoMemora.apoio(
              contagem,
              cor: concluida ? cores.sucessoTexto : cores.primaria,
            ),
      aoTocar: () => widget.aoEscolherSecao(secao),
    );
  }
}
