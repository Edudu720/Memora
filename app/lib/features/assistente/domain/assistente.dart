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
  ///
  /// É o que o servidor usa para o resto — a trilha de auditoria, por exemplo.
  /// Muda de banco para banco; não serve para ligar o item ao que vive fora dele.
  final String id;

  /// Identificador estável, igual em qualquer banco.
  ///
  /// É o que liga o item ao guia de passo a passo embarcado no aplicativo
  /// (feature 004). Só letras minúsculas, números e hífen, até 40 caracteres —
  /// a mesma restrição que o banco aplica.
  final String chave;

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

  /// Identificador do pacote Android quando disponível no catálogo (T089).
  final String? identificadorAndroid;

  /// Cria um serviço do catálogo.
  const ServicoDoCatalogo({
    required this.id,
    required this.chave,
    required this.nomeExibido,
    required this.descricaoCurta,
    required this.categoria,
    required this.memoraPodeAbrir,
    this.identificadorAndroid,
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
///
/// ## O mapeamento que o repositório real vai fazer (T036)
///
/// O servidor responde sempre `200` e conta a falha dentro do stream, num
/// evento `erro` cujo campo `codigo` decide qual destas falhas é:
/// `LIMITE_DE_CONVERSAS` vira [limiteDeConversas], `ASSISTENTE_INDISPONIVEL`
/// vira [assistenteIndisponivel] e `ERRO_INESPERADO` vira [inesperada].
/// [semConexao] e [sessaoExpirada] nascem no aparelho, da rede e do `401`.
enum FalhaDaAssistente {
  /// Sem conexão.
  semConexao,

  /// A sessão caiu.
  sessaoExpirada,

  /// A cota diária de conversas acabou (R7). Volta no dia seguinte.
  limiteDeConversas,

  /// O serviço que gera as respostas está fora do ar, sem cota ou não
  /// respondeu no prazo (FR-057). A dificuldade é da Memora, e passa.
  assistenteIndisponivel,

  /// Qualquer outra falha.
  inesperada;

  /// A pessoa pode tentar de novo agora? (FR-052, FR-057)
  ///
  /// Só as falhas **passageiras** oferecem. O limite diário diz que volta
  /// amanhã — um botão ali prometeria o que não vai acontecer —, e a sessão
  /// caída não se resolve reenviando a mesma pergunta.
  bool get passageira => switch (this) {
        semConexao || assistenteIndisponivel || inesperada => true,
        limiteDeConversas || sessaoExpirada => false,
      };
}

/// Uma chamada da assistente que não pôde ser feita, e por quê.
///
/// É o que as chamadas **sem** tipo de resposta próprio (catálogo, registro,
/// ação) lançam: as telas já tratam qualquer `Exception` como "não consegui
/// carregar", e quem precisar distinguir a sessão perdida da rede tem o
/// [falha] para isso. A conversa a converte em `AssistenteFalhou`.
class FalhaDeChamadaDaAssistente implements Exception {
  /// O que aconteceu.
  final FalhaDaAssistente falha;

  /// Cria a falha.
  const FalhaDeChamadaDaAssistente(this.falha);

  @override
  String toString() => 'FalhaDeChamadaDaAssistente($falha)';
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

  /// Cria uma falha.
  ///
  /// Não há campo de espera: o contrato não o tem, e o limite diário diz
  /// "amanhã" em vez de um prazo (FR-053, T106).
  const AssistenteFalhou(this.falha);
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
  /// [aoCriarCancelamento] recebe uma função síncrona que aborta a conexão de
  /// streaming subjacente caso a espera expire ou a pessoa feche a tela (T096).
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
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
