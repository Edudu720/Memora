import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_casca.dart';

/// O Início: a tela-casa acolhedora do Memora (T037, T115, FR-014, FR-019).
///
/// Inspirado nos designs de referência:
/// - Topo com avatar em destaque do robozinho 3D Memora e saudação personalizada.
/// - Balão de fala acolhedor da Memora orientando a pessoa.
/// - Cartão herói de ação principal: "Conversar com a Memora".
/// - Acesso direto a todas as opções do "Vamos começar" (Meus aplicativos, Serviços sociais,
///   O que eu fiz por você e atalhos diretos aos aplicativos principais), sem exigir cliques adicionais.
class TelaInicio extends StatelessWidget {
  /// Chave da saudação, usada pelos testes.
  static const Key chaveSaudacao = Key('inicio.saudacao');

  /// Chave do atalho para a conversa.
  static const Key chaveConversar = Key('inicio.conversar');

  /// Chave do atalho para ver todas as partes.
  static const Key chaveVerTudo = Key('inicio.verTudo');

  /// Chave da Memora.
  static const Key chaveMemora = Key('inicio.memora');

  /// Chave do balão com a frase de tutorial.
  static const Key chaveTutorial = Key('inicio.tutorial');

  /// Chave da caixa do atalho para a conversa.
  static const Key chaveCaixaConversar = Key('inicio.caixaConversar');

  /// Chave da caixa do atalho para ver tudo.
  static const Key chaveCaixaVerTudo = Key('inicio.caixaVerTudo');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// Abre a conversa. Nulo quando não há assistente.
  final VoidCallback? aoConversar;

  /// Abre o Hub / catálogo completo.
  final VoidCallback? aoVerTudo;

  /// Abre diretamente a categoria de aplicativos cotidianos.
  final VoidCallback? aoAbrirAplicativos;

  /// Abre diretamente os serviços sociais / governo.
  final VoidCallback? aoAbrirServicos;

  /// Abre diretamente o histórico e registro de atividades.
  final VoidCallback? aoAbrirRegistro;

  /// Abre um guia ou serviço específico diretamente.
  final void Function(String chave)? aoAbrirServicoEspecifico;

  /// Cria o Início.
  const TelaInicio({
    required this.nome,
    this.aoConversar,
    this.aoVerTudo,
    this.aoAbrirAplicativos,
    this.aoAbrirServicos,
    this.aoAbrirRegistro,
    this.aoAbrirServicoEspecifico,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool conversarEPrincipal = aoConversar != null;
    final int atalhos =
        (aoConversar != null ? 1 : 0) + (aoVerTudo != null ? 1 : 0);

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints caixa) {
            final double cabe =
                caixa.maxHeight * MemoraDimensoes.fracaoDaFiguraDoInicio;
            final double figura = cabe < MemoraDimensoes.ilustracaoHeroi
                ? cabe
                : MemoraDimensoes.ilustracaoHeroi;

            final double alturaMinima =
                (caixa.maxHeight - 2 * MemoraEspacamento.lg).clamp(
                  0.0,
                  double.infinity,
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
                vertical: MemoraEspacamento.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: alturaMinima),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // 1. Cabeçalho acolhedor com avatar do Memora
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: MemoraEspacamento.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    TextoMemora(
                                      TextosCasca.inicioSaudacao(nome),
                                      key: chaveSaudacao,
                                      estilo: EstiloTexto.destaque,
                                      cabecalho: true,
                                    ),
                                    const SizedBox(height: MemoraEspacamento.xs),
                                    TextoMemora.apoio(
                                      atalhos > 0
                                          ? 'Em que posso te ajudar hoje?'
                                          : 'Bom te ver por aqui!',
                                    ),
                                  ],
                                ),
                              ),
                              if (figura >=
                                  MemoraDimensoes.pisoDeIlustracao) ...<Widget>[
                                const SizedBox(width: MemoraEspacamento.md),
                                Semantics(
                                  label: 'Avatar da assistente Memora',
                                  child: MemoraPersonagem(
                                    key: chaveMemora,
                                    tamanho: figura.clamp(56.0, 80.0),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (atalhos > 0) ...<Widget>[
                            const SizedBox(height: MemoraEspacamento.md),
                            BalaoDeFala(
                              key: chaveTutorial,
                              autor: AutorDoBalao.memora,
                              texto: TextosCasca.inicioTutorial(atalhos),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 2. Atalhos e opções diretas do Hub
                    if (atalhos > 0)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Cartão herói: Conversar com a Memora
                          if (aoConversar != null) ...<Widget>[
                            CaixaDeEtapa(
                              key: chaveCaixaConversar,
                              instrucao: TextosCasca.inicioInstrucaoConversar,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  BotaoPrimario(
                                    key: chaveConversar,
                                    rotulo: TextosCasca.inicioConversar,
                                    icone: Icons.chat_bubble_rounded,
                                    aoTocar: aoConversar,
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: MemoraDimensoes.iconePequeno,
                                        color: cores.sucesso,
                                      ),
                                      const SizedBox(width: MemoraEspacamento.xs),
                                      const Expanded(
                                        child: TextoMemora.apoio(
                                          'Tire dúvidas sobre celular, aplicativos e internet',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: MemoraEspacamento.lg),
                          ],

                          // Seção: Vamos começar (todas as opções diretas na tela inicial)
                          if (aoVerTudo != null)
                            CaixaDeEtapa(
                              key: chaveCaixaVerTudo,
                              instrucao: TextosCasca.inicioInstrucaoVerTudo,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  // 3 Portais principais diretamente visíveis inspirados no design
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: _CartaoPortal(
                                          icone: Icons.phone_android_rounded,
                                          corIcone: cores.primaria,
                                          titulo: 'Aplicativos',
                                          descricao: 'WhatsApp...',
                                          aoTocar: aoAbrirAplicativos ?? aoVerTudo,
                                        ),
                                      ),
                                      const SizedBox(width: MemoraEspacamento.xs),
                                      Expanded(
                                        child: _CartaoPortal(
                                          icone: Icons.account_balance_rounded,
                                          corIcone: cores.sucesso,
                                          titulo: 'Serviços',
                                          descricao: 'Gov.br, INSS',
                                          aoTocar: aoAbrirServicos ?? aoVerTudo,
                                        ),
                                      ),
                                      const SizedBox(width: MemoraEspacamento.xs),
                                      Expanded(
                                        child: _CartaoPortal(
                                          icone: Icons.assignment_turned_in_rounded,
                                          corIcone: cores.destaque,
                                          titulo: 'Atividades',
                                          descricao: 'Histórico',
                                          aoTocar: aoAbrirRegistro ?? aoVerTudo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),

                                  // Botão para ver o catálogo completo
                                  conversarEPrincipal
                                      ? BotaoSecundario(
                                          key: chaveVerTudo,
                                          rotulo: TextosCasca.inicioVerTudo,
                                          icone: Icons.apps_rounded,
                                          aoTocar: aoVerTudo,
                                        )
                                      : BotaoPrimario(
                                          key: chaveVerTudo,
                                          rotulo: TextosCasca.inicioVerTudo,
                                          icone: Icons.apps_rounded,
                                          aoTocar: aoVerTudo,
                                        ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cartão de navegação para os portais do Hub diretamente na tela inicial.
class _CartaoPortal extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String descricao;
  final VoidCallback? aoTocar;

  const _CartaoPortal({
    required this.icone,
    required this.corIcone,
    required this.titulo,
    required this.descricao,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Material(
      color: cores.superficie,
      borderRadius: BorderRadius.circular(MemoraRaio.padrao),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.xs,
            vertical: MemoraEspacamento.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border.all(color: cores.borda),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: MemoraDimensoes.indicadorDeTela,
                height: MemoraDimensoes.indicadorDeTela,
                decoration: BoxDecoration(
                  color: cores.superficieAlt,
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icone,
                  color: corIcone,
                  size: MemoraDimensoes.iconePequeno,
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              TextoMemora(
                titulo,
                estilo: EstiloTexto.corpoForte,
                alinhamento: TextAlign.center,
                maxLinhas: 1,
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              TextoMemora.apoio(
                descricao,
                alinhamento: TextAlign.center,
                maxLinhas: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
