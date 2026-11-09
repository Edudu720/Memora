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
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      // `SingleChildScrollView` e não `ListView`: a lista preguiçosa só constrói
      // o que está perto da janela, e o leitor de tela não alcançaria o que
      // fica abaixo sem rolar às cegas.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: TextosAjuda.titulo,
              memora: ExpressaoDaMemora.falando,
              aoVoltar: aoVoltar,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const TextoMemora(TextosAjuda.convite),
                  const SizedBox(height: MemoraEspacamento.lg),
                  CaixaDeEtapa(
                    instrucao: TextosAjuda.instrucaoAssuntos,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (int i = 0; i < assuntos.length; i++) ...<Widget>[
                          CartaoDePorta(
                            key: chaveDoAssunto(assuntos[i].id),
                            nome: assuntos[i].titulo,
                            explicacao: assuntos[i].explicacao,
                            ilustracao: assuntos[i].ilustracao,
                            aoAbrir: () => aoAbrirAssunto(assuntos[i]),
                          ),
                          if (i < assuntos.length - 1 ||
                              aoVerApresentacao != null)
                            const SizedBox(height: MemoraEspacamento.md),
                        ],
                        if (aoVerApresentacao != null)
                          CartaoDePorta(
                            key: chaveReverApresentacao,
                            nome: TextosAjuda.reverApresentacao,
                            explicacao: TextosAjuda.reverApresentacaoExplicacao,
                            ilustracao: Ilustracao.memoraNeutra,
                            aoAbrir: aoVerApresentacao,
                          ),
                      ],
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
