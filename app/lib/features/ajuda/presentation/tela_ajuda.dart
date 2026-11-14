import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_ajuda.dart';
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
/// ## Nenhum link para fora
///
/// O wireframe terminava com "entre no site ajudamemora.com.br". O domínio não
/// é nosso, e link para domínio que não controlamos é o link que um golpista
/// compra (R12, FR-037). A pessoa que não achou resposta aqui tem a conversa.
class TelaAjuda extends StatelessWidget {
  /// Chave de um assunto, para os testes.
  static Key chaveDoAssunto(IdDoAssunto id) => Key('ajuda.assunto.${id.name}');

  /// Chave da porta "Ver a apresentação de novo", para os testes.
  static const Key chaveReverApresentacao = Key('ajuda.rever_apresentacao');

  /// Os assuntos que existem agora.
  final List<AssuntoDeAjuda> assuntos;

  /// Abre um assunto.
  final void Function(AssuntoDeAjuda assunto) aoAbrirAssunto;

  /// Rever a apresentação inicial (FR-013). Nulo: a porta não existe.
  final VoidCallback? aoVerApresentacao;

  /// Volta à tela de onde a Ajuda foi aberta.
  final VoidCallback aoVoltar;

  /// Cria a Ajuda.
  const TelaAjuda({
    required this.assuntos,
    required this.aoAbrirAssunto,
    required this.aoVoltar,
    this.aoVerApresentacao,
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
            CabecalhoDeTela(
              titulo: TextosAjuda.titulo,
              aoVoltar: aoVoltar,
            ),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        if (!ocultarVisuais) ...<Widget>[
                          const MemoraPersonagem(
                            expressao: ExpressaoDaMemora.falando,
                            tamanho: MemoraDimensoes.alvoDecisao,
                          ),
                          const SizedBox(width: MemoraEspacamento.md),
                        ],
                        const Expanded(
                          child: TextoMemora(TextosAjuda.convite),
                        ),
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
                                        width: MemoraDimensoes.badgeAtalhoRapido,
                                        height:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        decoration: BoxDecoration(
                                          color: cores.destaque,
                                          borderRadius: BorderRadius.circular(
                                            MemoraRaio.badge,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: IlustracaoMemora(
                                          assuntos[i].ilustracao,
                                          altura: MemoraDimensoes.iconeDestaque,
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
                                        width: MemoraDimensoes.badgeAtalhoRapido,
                                        height:
                                            MemoraDimensoes.badgeAtalhoRapido,
                                        decoration: BoxDecoration(
                                          color: cores.destaque,
                                          borderRadius: BorderRadius.circular(
                                            MemoraRaio.badge,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const MemoraPersonagem(
                                          expressao: ExpressaoDaMemora.neutra,
                                          tamanho:
                                              MemoraDimensoes.iconeDestaque,
                                        ),
                                      ),
                                aoTocar: aoVerApresentacao,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
