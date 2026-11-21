import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_ajuda.dart';
import '../data/abridor_site_tutorial.dart';
import '../domain/assunto_de_ajuda.dart';

/// A Ajuda: os assuntos do wireframe que funcionam, cada um com desenho e nome
/// (T087, FR-033, FR-004).
///
/// ## A tela mostra o que recebe, e só
///
/// Como o Hub: a lista de [assuntos] vem pronta, e quem sabe o que existe é
/// quem monta o fluxo. "Compartilhar" só está na lista quando há endereço
/// oficial de download (R12), e "Ver a apresentação de novo" só existe se
/// [aoVerApresentacao] não for nulo (FR-018: porta que não abre nada é pior que
/// porta que não existe).
///
/// ## Conteúdo embarcado: sem carregando, sem vazio, sem erro
///
/// Nada aqui vem do servidor (FR-006 vale para as telas que **têm** esses
/// estados). O único desvio possível é a folha de compartilhar que não abre, e
/// esse mora na [TelaAssunto].
///
/// ## Controle estrito de links externos
///
/// O wireframe terminava com "entre no site ajudamemora.com.br". Domínios não
/// controlados continuam proibidos (R12, FR-037); a única exceção é o site
/// oficial de tutoriais em `https://` fixado em tempo de compilação
/// ([abridorSiteTutorial]), mantido oculto enquanto não configurado e sempre
/// protegido por confirmação modal explícita antes de deixar o aplicativo.
/// A pessoa que não achou resposta aqui tem a conversa.
class TelaAjuda extends StatelessWidget {
  /// Chave de um assunto, para os testes.
  static Key chaveDoAssunto(IdDoAssunto id) => Key('ajuda.assunto.${id.name}');

  /// Chave da porta "Ver a apresentação de novo", para os testes.
  static const Key chaveReverApresentacao = Key('ajuda.rever_apresentacao');

  /// Chave do botão para abrir o site oficial de tutoriais (Feature 016).
  static const Key chaveAbrirSiteTutorial = Key('ajuda.site_tutorial.abrir');

  /// Chave do botão que confirma a abertura do site oficial no modal.
  static const Key chaveConfirmarSiteTutorial = Key(
    'ajuda.site_tutorial.confirmar',
  );

  /// Chave do botão que cancela a abertura do site oficial no modal.
  static const Key chaveCancelarSiteTutorial = Key(
    'ajuda.site_tutorial.cancelar',
  );

  /// Chave do aviso exibido quando o site oficial falha ao abrir.
  static const Key chaveErroSiteTutorial = Key('ajuda.site_tutorial.erro');

  /// Os assuntos que existem agora.
  final List<AssuntoDeAjuda> assuntos;

  /// Abre um assunto.
  final void Function(AssuntoDeAjuda assunto) aoAbrirAssunto;

  /// Rever a apresentação inicial (FR-013). Nulo: a porta não existe.
  final VoidCallback? aoVerApresentacao;

  /// Abridor seguro `https://` do site oficial de tutoriais. Nulo: oculto.
  final AbridorDeSiteTutorial? abridorSiteTutorial;

  /// Volta à tela de onde a Ajuda foi aberta.
  final VoidCallback aoVoltar;

  /// Cria a Ajuda.
  const TelaAjuda({
    required this.assuntos,
    required this.aoAbrirAssunto,
    required this.aoVoltar,
    this.aoVerApresentacao,
    this.abridorSiteTutorial,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool ocultarVisuais = escala >= MemoraDimensoes.escalaTextoAlta;

    return Scaffold(
      backgroundColor: cores.fundo,
      // `SingleChildScrollView` e não `ListView`: a lista preguiçosa só constrói
      // o que está perto da janela, e o leitor de tela não alcançaria o que
      // fica abaixo sem rolar às cegas.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(titulo: TextosAjuda.titulo, aoVoltar: aoVoltar),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Cartao(
                    padding: const EdgeInsets.all(MemoraEspacamento.md),
                    child: Row(
                      children: <Widget>[
                        if (!ocultarVisuais) ...<Widget>[
                          const MemoraPersonagem(
                            expressao: ExpressaoDaMemora.falando,
                            tamanho: MemoraDimensoes.alvoDecisao,
                          ),
                          const SizedBox(width: MemoraEspacamento.md),
                        ],
                        const Expanded(child: TextoMemora(TextosAjuda.convite)),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.lg),
                  CaixaDeEtapa(
                    instrucao: TextosAjuda.instrucaoAssuntos,
                    child: Cartao(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (int i = 0; i < assuntos.length; i++)
                              LinhaDeLista(
                                key: chaveDoAssunto(assuntos[i].id),
                                titulo: assuntos[i].titulo,
                                subtitulo: assuntos[i].explicacao,
                                esquerda: ocultarVisuais
                                    ? null
                                    : Container(
                                        width:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        height:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        decoration: BoxDecoration(
                                          color: cores.destaque,
                                          borderRadius: BorderRadius.circular(
                                            MemoraRaio.badge,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          assuntos[i].icone,
                                          size: MemoraDimensoes.iconePadrao,
                                          color: cores.primaria,
                                        ),
                                      ),
                                aoTocar: () => aoAbrirAssunto(assuntos[i]),
                                mostrarDivisorInferior:
                                    i < assuntos.length - 1 ||
                                    aoVerApresentacao != null,
                              ),
                            if (aoVerApresentacao != null)
                              LinhaDeLista(
                                key: chaveReverApresentacao,
                                titulo: TextosAjuda.reverApresentacao,
                                subtitulo:
                                    TextosAjuda.reverApresentacaoExplicacao,
                                esquerda: ocultarVisuais
                                    ? null
                                    : Container(
                                        width:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        height:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        decoration: BoxDecoration(
                                          color: cores.destaque,
                                          borderRadius: BorderRadius.circular(
                                            MemoraRaio.badge,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.play_circle_outline_rounded,
                                          size: MemoraDimensoes.iconePadrao,
                                          color: cores.primaria,
                                        ),
                                      ),
                                aoTocar: aoVerApresentacao,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.lg),
                  if (abridorSiteTutorial != null) ...<Widget>[
                    _CartaoSiteTutorial(abridor: abridorSiteTutorial!),
                    const SizedBox(height: MemoraEspacamento.lg),
                  ],
                  const SizedBox(height: MemoraEspacamento.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoSiteTutorial extends StatefulWidget {
  final AbridorDeSiteTutorial abridor;

  const _CartaoSiteTutorial({required this.abridor});

  @override
  State<_CartaoSiteTutorial> createState() => _CartaoSiteTutorialState();
}

class _CartaoSiteTutorialState extends State<_CartaoSiteTutorial> {
  bool _abrindo = false;
  String? _mensagemErro;

  Future<void> _pedirConfirmacao() async {
    final MemoraCores cores = context.memora.cores;
    final bool? confirmado = await DialogoMemora.mostrarConteudo<bool>(
      context,
      construtor: (BuildContext ctx) => Dialog(
        backgroundColor: cores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(MemoraEspacamento.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const TextoMemora.tituloSecao(
                  TextosAjuda.siteTutorialModalTitulo,
                ),
                const SizedBox(height: MemoraEspacamento.md),
                const TextoMemora(TextosAjuda.siteTutorialModalMensagem),
                const SizedBox(height: MemoraEspacamento.sm),
                Container(
                  padding: const EdgeInsets.all(MemoraEspacamento.md),
                  decoration: BoxDecoration(
                    color: cores.destaque,
                    borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  ),
                  child: TextoMemora(widget.abridor.endereco),
                ),
                const SizedBox(height: MemoraEspacamento.xl),
                BotaoPrimario(
                  key: TelaAjuda.chaveConfirmarSiteTutorial,
                  rotulo: TextosAjuda.siteTutorialConfirmar,
                  aoTocar: () => Navigator.of(ctx).pop(true),
                ),
                const SizedBox(height: MemoraEspacamento.md),
                BotaoSecundario(
                  key: TelaAjuda.chaveCancelarSiteTutorial,
                  rotulo: TextosAjuda.siteTutorialCancelar,
                  aoTocar: () => Navigator.of(ctx).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || confirmado != true) return;

    setState(() {
      _abrindo = true;
      _mensagemErro = null;
    });
    final bool abriu = await widget.abridor.abrir();
    if (!mounted) return;
    setState(() {
      _abrindo = false;
      _mensagemErro = abriu ? null : TextosAjuda.siteTutorialErro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Cartao(
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TextoMemora.tituloSecao(TextosAjuda.siteTutorialTitulo),
          const SizedBox(height: MemoraEspacamento.sm),
          const TextoMemora(TextosAjuda.siteTutorialExplicacao),
          if (_mensagemErro != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.md),
            Semantics(
              key: TelaAjuda.chaveErroSiteTutorial,
              liveRegion: true,
              label: _mensagemErro,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(MemoraEspacamento.md),
                  decoration: BoxDecoration(
                    color: cores.superficie,
                    borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                    border: Border.all(
                      color: cores.perigo,
                      width: MemoraDimensoes.bordaEnfase,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline_rounded,
                        color: cores.perigo,
                        size: MemoraDimensoes.iconePadrao,
                      ),
                      const SizedBox(width: MemoraEspacamento.md),
                      Expanded(child: TextoMemora(_mensagemErro!)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: MemoraEspacamento.md),
          BotaoSecundario(
            key: TelaAjuda.chaveAbrirSiteTutorial,
            rotulo: TextosAjuda.siteTutorialBotao,
            icone: Icons.open_in_new_rounded,
            carregando: _abrindo,
            aoTocar: _abrindo ? null : _pedirConfirmacao,
          ),
        ],
      ),
    );
  }
}
