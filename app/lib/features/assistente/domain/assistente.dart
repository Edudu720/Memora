import 'package:flutter/foundation.dart' show immutable;

/// Quem falou numa conversa.
enum AutorDaMensagem {
  /// A pessoa.
  pessoa,

  /// A Memora.
  memora,
}

/// Um turno da conversa.
///
/// Fica **apenas no aparelho** (FR-047). O servidor não guarda conteúdo de
/// conversa: guardá-lo criaria um acervo Confidencial sobre a intimidade de
/// pessoas idosas, que são o alvo preferencial de golpe no Brasil (decisão D3).
@immutable
class MensagemDaConversa {
  /// Quem falou.
  final AutorDaMensagem autor;

  /// O que foi dito.
  final String texto;

  /// Quando.
  final DateTime momento;

  /// Cria uma mensagem.
  const MensagemDaConversa({
    required this.autor,
    required this.texto,
    required this.momento,
  });
}

/// Um aplicativo que a Memora pode abrir, **já autorizado pelo servidor**.
///
/// ## A existência deste objeto é a autorização
///
/// Ele só chega ao aplicativo depois de o `AutorizadorDeAcao` consultar o
/// catálogo (FR-022). O aplicativo **não decide de novo** se aquilo pode ser
/// aberto — duas decisões sobre a mesma coisa divergem na primeira vez que
/// alguém mexer em uma delas.
///
/// O que o aplicativo decide é outra coisa, e é dele: **pedir a confirmação da
/// pessoa** (FR-015) antes de abrir qualquer coisa.
@immutable
class AcaoAutorizada {
  /// Identificador do serviço no catálogo.
  final String servicoId;

  /// Como a pessoa chama esse aplicativo.
  final String nomeExibido;

  /// O pacote Android a abrir.
  final String identificadorAndroid;

  /// Cria uma ação autorizada.
  const AcaoAutorizada({
    required this.servicoId,
    required this.nomeExibido,
    required this.identificadorAndroid,
  });
}

/// O que a Memora pode fazer com um serviço.
enum CategoriaDoServico {
  /// Governo, banco, saúde. A Memora **só ensina**.
  sensivel,

  /// Redes sociais, vídeo, mensagens. Ela ensina **e pode abrir**.
  cotidiano;

  /// Rótulo exibido à pessoa, dizendo o que esperar antes do toque (FR-045).
  String get oQueAMemoraFaz => switch (this) {
        CategoriaDoServico.sensivel => 'Eu te ensino o caminho',
        CategoriaDoServico.cotidiano => 'Eu te ensino e posso abrir',
      };
}

/// Um serviço que a Memora conhece.
@immutable
class ServicoDoCatalogo {
  /// Identificador.
  final String id;

  /// Como a pessoa o chama.
  final String nomeExibido;

  /// O que é, em linguagem comum.
  final String descricaoCurta;

  /// O que a Memora pode fazer com ele.
  final CategoriaDoServico categoria;

  /// A Memora pode abrir este serviço?
  ///
  /// Vem do servidor em vez de ser derivado de [categoria], de propósito: é o
  /// que a tela exibe, e derivá-lo aqui espalharia a regra da FR-041 por dois
  /// lugares que podem divergir.
  final bool memoraPodeAbrir;

  /// Cria um serviço do catálogo.
  const ServicoDoCatalogo({
    required this.id,
    required this.nomeExibido,
    required this.descricaoCurta,
    required this.categoria,
    required this.memoraPodeAbrir,
  });
}

/// Uma ação que a Memora executou, como a pessoa a vê (FR-023).
@immutable
class AcaoRegistrada {
  /// Que aplicativo foi aberto.
  final String nomeExibido;

  /// O que a pessoa tinha pedido.
  final String pedidoResumido;

  /// Quando aconteceu.
  final DateTime ocorridoEm;

  /// Cria um registro.
  const AcaoRegistrada({
    required this.nomeExibido,
    required this.pedidoResumido,
    required this.ocorridoEm,
  });
}

/// Falhas previstas da assistente.
///
/// São **códigos**, não mensagens: o texto exibido vive na camada de
/// apresentação, para que a persona da Memora fique num lugar só — mesma
/// escolha de `FalhaAutenticacao`.
enum FalhaDaAssistente {
  /// Sem conexão.
  semConexao,

  /// A sessão caiu.
  sessaoExpirada,

  /// A cota diária de conversas acabou (R7).
  limiteDeConversas,

  /// Qualquer outra falha.
  inesperada,
}

/// O que a Memora respondeu a um turno da conversa.
@immutable
sealed class RespostaDaAssistente {
  const RespostaDaAssistente();
}

/// A Memora respondeu.
@immutable
class AssistenteRespondeu extends RespostaDaAssistente {
  /// O texto da resposta.
  final String texto;

  /// O aplicativo que ela ofereceu abrir, se ofereceu.
  ///
  /// Quando presente, **já passou pelo catálogo do servidor**. Ainda assim, a
  /// pessoa precisa confirmar antes de qualquer coisa acontecer (FR-015).
  final AcaoAutorizada? acao;

  /// Cria uma resposta.
  const AssistenteRespondeu(this.texto, {this.acao});
}

/// Não deu para conversar.
@immutable
class AssistenteFalhou extends RespostaDaAssistente {
  /// Qual falha ocorreu.
  final FalhaDaAssistente falha;

  /// Quando tentar de novo, em segundos. Presente no limite diário.
  final int? tentarNovamenteEmSegundos;

  /// Cria uma falha.
  const AssistenteFalhou(this.falha, {this.tentarNovamenteEmSegundos});
}

/// Contrato da assistente, usado pela camada de apresentação.
///
/// A implementação real conversa com o backend, que é quem fala com o provedor
/// de IA — a chave nunca chega ao aparelho. A interface existe para que as
/// telas sejam construídas e testadas sem o servidor de pé, como as telas de
/// autenticação foram.
abstract interface class RepositorioAssistente {
  /// Envia uma mensagem e recebe a resposta.
  ///
  /// [historico] viaja a cada turno porque o servidor **não guarda** conversa
  /// (FR-047). O preço é conhecido e está registrado na R3 do research: o custo
  /// cresce com o número de turnos.
  ///
  /// [aoReceberTrecho] recebe a resposta em pedaços, para a tela mostrar o
  /// texto aparecendo. Tela parada é o que faz este público concluir que o
  /// aparelho travou.
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  });

  /// Os serviços que a Memora conhece, para as duas portas do Hub.
  Future<List<ServicoDoCatalogo>> catalogo();

  /// Registra que a pessoa confirmou e o aplicativo foi aberto (FR-020).
  ///
  /// Chamado **depois** de abrir. O servidor reconfere a autorização antes de
  /// gravar: se um pedido para serviço sensível chegar lá, algo está errado, e
  /// o registro disso vale mais do que a recusa silenciosa.
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  });

  /// O que a Memora fez em nome da pessoa (FR-023).
  Future<List<AcaoRegistrada>> registro();
}
