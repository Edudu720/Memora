import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../assistente/domain/assistente.dart';
import '../data/progresso_de_aprendizado.dart';
import '../../../l10n/textos_guias.dart';
import '../domain/guia.dart';

/// Tela de escolha de assunto para guias extensos (FR-028d, T137).
///
/// Modelo vindo da PR #67 (Eduardo). Evita que a pessoa idosa precise percorrer dezenas de telas seguidas (como
/// no Gov.br ou Serasa) para chegar ao ponto desejado. Exibe as seções em
/// cartões amplos (>= 48 dp), com ícone + título + subtítulo + contagem de passos.
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
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(titulo: _nomeServico, aoVoltar: widget.aoVoltar),
            Expanded(
              child: SingleChildScrollView(
                key: TelaSeletorDeSecao.chaveLista,
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    BalaoDeFala(
                      autor: AutorDoBalao.memora,
                      texto: TextosGuias.perguntaDaSecao(_nomeServico),
                    ),
                    const SizedBox(height: MemoraEspacamento.lg),
                    for (final SecaoDoGuia secao
                        in widget.guia.secoes) ...<Widget>[
                      _CartaoSecao(
                        secao: secao,
                        concluida: _concluidas.contains(secao.chave),
                        aoTocar: () => widget.aoEscolherSecao(secao),
                      ),
                      const SizedBox(height: MemoraEspacamento.md),
                    ],
                    if (widget.aoConversar != null) ...<Widget>[
                      const SizedBox(height: MemoraEspacamento.sm),
                      BotaoSecundario(
                        key: TelaSeletorDeSecao.chaveConversar,
                        rotulo: TextosGuias.naoAcheiOQueProcuro,
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
}

class _CartaoSecao extends StatelessWidget {
  final SecaoDoGuia secao;
  final bool concluida;
  final VoidCallback aoTocar;

  const _CartaoSecao({
    required this.secao,
    required this.concluida,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final int qtd = secao.passos.length;
    final String contagem = TextosGuias.quantidadeDePassos(qtd);
    final String textoMeta = concluida
        ? TextosGuias.secaoJaAprendida(contagem)
        : contagem;

    return Semantics(
      button: true,
      label: TextosGuias.secaoDescrita(
        secao.titulo,
        secao.subtitulo,
        textoMeta,
      ),
      // Sem `onTap` aqui o TalkBack anuncia o botão e o duplo toque não faz nada.
      onTap: aoTocar,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MemoraDimensoes.alvoDecisao,
          ),
          child: Material(
            key: TelaSeletorDeSecao.chaveDaSecao(secao.chave),
            color: cores.superficie,
            elevation: MemoraElevacao.cartao,
            shadowColor: MemoraElevacao.sombra,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MemoraRaio.cartao),
              side: BorderSide(
                color: concluida ? cores.sucesso : cores.primaria,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(MemoraRaio.cartao),
              onTap: aoTocar,
              child: Padding(
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(MemoraEspacamento.sm),
                      decoration: BoxDecoration(
                        color: cores.destaque,
                        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                      ),
                      child: Icon(
                        secao.icone,
                        size: MemoraDimensoes.iconeDestaque,
                        color: cores.primaria,
                      ),
                    ),
                    const SizedBox(width: MemoraEspacamento.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextoMemora(
                            secao.titulo,
                            estilo: EstiloTexto.tituloSecao,
                          ),
                          const SizedBox(height: MemoraEspacamento.xs),
                          TextoMemora(secao.subtitulo, cor: cores.textoSuave),
                          const SizedBox(height: MemoraEspacamento.xs),
                          Row(
                            children: <Widget>[
                              if (concluida) ...<Widget>[
                                Icon(
                                  Icons.check_circle,
                                  size: MemoraDimensoes.iconePequeno,
                                  color: cores.sucesso,
                                ),
                                const SizedBox(width: MemoraEspacamento.xs),
                              ],
                              Flexible(
                                child: TextoMemora(
                                  textoMeta,
                                  estilo: EstiloTexto.apoio,
                                  cor: concluida
                                      ? cores.sucesso
                                      : cores.primaria,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
