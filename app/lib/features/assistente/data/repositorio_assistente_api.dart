import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../domain/assistente.dart';
import 'chamada_com_renovacao.dart';
import 'leitor_da_conversa.dart';

/// A assistente de verdade: fala com o servidor pelo contrato (T036).
///
/// Catálogo, registro e ação usam o cliente **gerado**. Só a conversa é lida à
/// mão — o gerador entrega a resposta inteira como `String`, e a FR-052 exige
/// ver o texto aparecendo —, e usa o `Dio` do **mesmo** `MemoraApi`, para o
/// token e o endereço serem os da autenticação. Ver `leitor_da_conversa.dart`
/// para o formato e `leitor_da_conversa_contrato_test.dart` para a prova de que
/// o leitor bate com o contrato.
///
/// ## Quem decide se a Memora pode abrir um aplicativo
///
/// O servidor. A [AcaoAutorizada] que chega pelo evento `acao` **já passou**
/// pelo catálogo (FR-022), e este repositório a repassa sem reavaliar: duas
/// decisões sobre a mesma coisa divergem na primeira vez que alguém mexer em
/// uma. Nada aqui produz uma ação por conta própria.
///
/// ## Toda chamada passa pela renovação em silêncio
///
/// Ver [ChamadaComRenovacao] (T108): `401` renova a sessão e reenvia uma vez.
class RepositorioAssistenteApi implements RepositorioAssistente {
  final api.MemoraApi _api;
  final ChamadaComRenovacao _chamadas;

  /// O servidor desiste da conexão em 120 s (`TIMEOUT_MS`). Acima do tempo
  /// padrão do cliente gerado (3 s), que cortaria uma resposta que o modelo
  /// ainda está pensando: quem corta a espera, em 30 s, é o controlador
  /// (FR-052) — o transporte só não pode cortar antes dele.
  static const Duration _esperaDoFluxo = Duration(seconds: 120);

  /// Cria o repositório sobre o cliente gerado.
  ///
  /// [cliente] precisa ser a mesma instância usada pela autenticação, e
  /// [chamadas] o envoltório que renova a sessão em silêncio.
  RepositorioAssistenteApi({
    required api.MemoraApi cliente,
    required ChamadaComRenovacao chamadas,
  }) : _api = cliente,
       _chamadas = chamadas;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) async {
    final String corpo = jsonEncode(
      api.AssistenteConversaPostRequest(
        mensagem: mensagem,
        historico: <api.Mensagem>[
          for (final MensagemDaConversa m in historico)
            api.Mensagem(
              autor: switch (m.autor) {
                AutorDaMensagem.pessoa => api.MensagemAutorEnum.pessoa,
                AutorDaMensagem.memora => api.MensagemAutorEnum.memora,
              },
              texto: m.texto,
            ),
        ],
      ),
    );

    final Response<ResponseBody> resposta;
    try {
      // O `401` chega **antes** do fluxo (a autenticação é decidida nos
      // cabeçalhos), então reenviar o pedido é seguro: nada foi consumido.
      resposta = await _chamadas.executar<Response<ResponseBody>>(
        () => _api.dio.post<ResponseBody>(
          '/assistente/conversa',
          data: corpo,
          options: Options(
            responseType: ResponseType.stream,
            contentType: 'application/json',
            headers: <String, dynamic>{'Accept': 'text/event-stream'},
            receiveTimeout: _esperaDoFluxo,
            // O mesmo gancho que o cliente gerado põe em toda operação
            // autenticada: é por ele que o interceptor casa o token com a
            // chamada. O nome vem do `securityScheme` do contrato.
            extra: <String, dynamic>{
              'secure': <Map<String, String>>[
                <String, String>{
                  'type': 'http',
                  'scheme': 'bearer',
                  'name': 'tokenDeAcesso',
                },
              ],
            },
          ),
        ),
      );
    } on FalhaDeChamadaDaAssistente catch (falha) {
      return AssistenteFalhou(falha.falha);
    } on DioException catch (excecao) {
      soltarCorpoDaResposta(excecao);
      return AssistenteFalhou(_falhaDoTransporte(excecao));
    }

    final ResponseBody? fluxo = resposta.data;
    if (fluxo == null) {
      return const AssistenteFalhou(FalhaDaAssistente.inesperada);
    }

    try {
      return await lerConversa(fluxo.stream, aoReceberTrecho: aoReceberTrecho);
    } on DioException catch (excecao) {
      // A conexão caiu com o fluxo aberto (ou estourou o tempo entre pedaços).
      return AssistenteFalhou(_falhaDoTransporte(excecao));
    }
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async {
    final Response<api.AssistenteCatalogoGet200Response> resposta =
        await _chamadas.executar(
          () => _api.getCatalogoApi().assistenteCatalogoGet(),
        );

    final List<api.Servico> servicos =
        resposta.data?.servicos ?? const <api.Servico>[];
    return <ServicoDoCatalogo>[
      for (final api.Servico s in servicos)
        ServicoDoCatalogo(
          id: s.id,
          chave: s.chave,
          nomeExibido: s.nomeExibido,
          descricaoCurta: s.descricaoCurta ?? '',
          categoria: switch (s.categoria) {
            api.ServicoCategoriaEnum.sensivel => CategoriaDoServico.sensivel,
            api.ServicoCategoriaEnum.cotidiano => CategoriaDoServico.cotidiano,
          },
          // Vem do servidor em vez de ser derivado da categoria, de propósito
          // (ver `ServicoDoCatalogo.memoraPodeAbrir`): a regra da FR-041 mora
          // num lugar só.
          memoraPodeAbrir: s.memoraPodeAbrir,
        ),
    ];
  }

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    await _chamadas.executar(
      () => _api.getAssistenteApi().assistenteAcaoPost(
        assistenteAcaoPostRequest: api.AssistenteAcaoPostRequest(
          servicoId: servicoId,
          pedidoResumido: pedidoResumido,
        ),
      ),
    );
  }

  @override
  Future<List<AcaoRegistrada>> registro() async {
    final Response<api.AssistenteRegistroGet200Response> resposta =
        await _chamadas.executar(
          () => _api.getAssistenteApi().assistenteRegistroGet(),
        );

    final List<api.AcaoRegistrada> acoes =
        resposta.data?.acoes ?? const <api.AcaoRegistrada>[];
    return <AcaoRegistrada>[
      for (final api.AcaoRegistrada a in acoes)
        // O contrato marca estes três campos como opcionais, mas o servidor
        // sempre os preenche (a coluna é `NOT NULL`). Linha incompleta é
        // defeito, e a escolha seria entre esconder uma ação do registro da
        // pessoa (FR-023) ou inventar quando ela aconteceu: nenhuma das duas.
        // A tela diz que não conseguiu carregar, e o defeito aparece.
        switch ((a.nomeExibido, a.pedidoResumido, a.ocorridoEm)) {
          (final String nome, final String pedido, final DateTime quando) =>
            AcaoRegistrada(
              nomeExibido: nome,
              pedidoResumido: pedido,
              ocorridoEm: quando,
            ),
          _ => throw const FalhaDeChamadaDaAssistente(
            FalhaDaAssistente.inesperada,
          ),
        },
    ];
  }

  /// Traduz a falha do transporte em falha da assistente.
  ///
  /// Sem resposta (tempo esgotado, rede caída, conexão recusada) é
  /// [FalhaDaAssistente.semConexao] — o caso mais comum neste público, com
  /// texto próprio. Com resposta, qualquer status que não seja o `401` (que a
  /// renovação já tratou) é defeito: `400` seria o aparelho mandando fora do
  /// contrato, e `5xx` uma falha que o servidor não soube explicar. Ambos são
  /// passageiros do ponto de vista da pessoa, e oferecem tentar de novo.
  FalhaDaAssistente _falhaDoTransporte(DioException excecao) {
    if (excecao.response == null) return FalhaDaAssistente.semConexao;
    return FalhaDaAssistente.inesperada;
  }
}
