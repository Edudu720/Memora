import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/assistente.dart';
import '../../../services/seguranca/limpeza_de_sessao.dart';

/// A conversa guardada **no aparelho**, e em nenhum outro lugar (FR-047).
///
/// ## Por que não vai nas duas caixas que o projeto já usa
///
/// O Memora tem dois armazenamentos, e nenhum dos dois serve aqui:
///
/// - **`flutter_secure_storage`** é o cofre de credenciais. O cenário V8 da
///   feature 001 reprova se sobrar **qualquer coisa** lá depois de sair, e
///   afrouxar isso para caber a conversa enfraqueceria um portão que hoje é
///   absoluto.
/// - **`SharedPreferences`** é armazenamento comum, onde mora só o
///   identificador do último acesso — que não é dado sensível. A conversa é
///   **Confidencial**: ela revela rotina, relações e dificuldades da pessoa.
///
/// Sobra o diretório privado do aplicativo, que no Android é isolado por
/// sandbox e some quando o aplicativo é desinstalado. É o que o `data-model.md`
/// previu ao deixar esta escolha em aberto.
///
/// ## O que é apagado, e quando
///
/// Tudo, ao sair da conta (FR-048). A conversa não sobrevive à saída pelo mesmo
/// motivo que a credencial não sobrevive: o aparelho pode não estar mais com a
/// pessoa.
class ConversaLocal implements DadoLocalDaPessoa {
  /// Nome do arquivo dentro do diretório privado.
  static const String nomeDoArquivo = 'conversa_com_a_memora.json';

  /// Quantos turnos ficam guardados.
  ///
  /// O mesmo teto que viaja ao servidor. Guardar mais no aparelho seria
  /// acumular, sem proveito, um histórico Confidencial que nunca será usado.
  static const int turnosGuardados = 40;

  /// Prazo máximo de retenção das mensagens no aparelho (FR-054, T082).
  ///
  /// Mensagens com mais de 30 dias são expurgadas tanto na leitura quanto
  /// na gravação, garantindo que o histórico antigo não se acumule no aparelho.
  static const Duration retencaoMaxima = Duration(days: 30);

  /// Diretório onde gravar. Trocável no teste, que não tem plataforma.
  final Future<Directory> Function() _diretorio;

  /// Relógio, trocável no teste para simular passagem de dias.
  final DateTime Function() _agora;

  /// Cria o armazenamento da conversa.
  ConversaLocal({
    Future<Directory> Function()? diretorio,
    DateTime Function()? agora,
  })  : _diretorio = diretorio ?? getApplicationDocumentsDirectory,
        _agora = agora ?? DateTime.now;

  /// Lê a conversa guardada. Lista vazia quando não há nenhuma.
  ///
  /// Mensagens com mais de 30 dias são automaticamente expurgadas (FR-054).
  Future<List<MensagemDaConversa>> ler() async {
    try {
      // Le direto e trata a ausencia como conversa vazia, em vez de
      // perguntar antes se existe: sao duas idas ao disco para responder o
      // que a leitura ja responde.
      final dynamic conteudo = jsonDecode(
        await (await _arquivo()).readAsString(),
      );
      if (conteudo is! List) return const <MensagemDaConversa>[];

      final List<MensagemDaConversa> todas = conteudo
          .whereType<Map<String, dynamic>>()
          .map(_mensagemDe)
          .whereType<MensagemDaConversa>()
          .toList();

      final DateTime limite = _agora().subtract(retencaoMaxima);
      return todas
          .where((MensagemDaConversa m) => !m.momento.isBefore(limite))
          .toList();
    } on Exception {
      // Arquivo corrompido, permissão negada, disco cheio: a conversa é
      // conveniência, e perdê-la nunca pode impedir a pessoa de conversar de
      // novo. Devolver vazio é começar do zero, que é o pior caso aceitável.
      return const <MensagemDaConversa>[];
    }
  }

  /// Grava a conversa, mantendo apenas os turnos mais recentes dos últimos 30 dias.
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    final DateTime limite = _agora().subtract(retencaoMaxima);
    final List<MensagemDaConversa> validas = mensagens
        .where((MensagemDaConversa m) => !m.momento.isBefore(limite))
        .toList();

    final List<MensagemDaConversa> recentes =
        validas.length <= turnosGuardados
        ? validas
        : validas.sublist(validas.length - turnosGuardados);

    try {
      final File arquivo = await _arquivo();
      await arquivo.writeAsString(
        jsonEncode(recentes.map(_mapaDe).toList()),
        flush: true,
      );
    } on Exception {
      // Idem: não conseguir guardar não pode derrubar a conversa em curso.
    }
  }

  /// Apaga a conversa (FR-048, FR-050).
  @override
  Future<void> apagar() async {
    try {
      await (await _arquivo()).delete();
    } on PathNotFoundException {
      // Não há conversa guardada: o resultado que se queria já é verdade.
    }
    // Qualquer outra falha (permissão, disco) SOBE: quem apaga a pedido da
    // pessoa, em Privacidade, precisa saber que a conversa continua lá, em
    // vez de ouvir "pronto" de graça. A `LimpezaDeSessao` protege cada item,
    // então sair continua nunca falhando para a pessoa (FR-026).
  }

  Future<File> _arquivo() async =>
      File('${(await _diretorio()).path}/$nomeDoArquivo');

  Map<String, dynamic> _mapaDe(MensagemDaConversa m) => <String, dynamic>{
    'autor': m.autor.name,
    'texto': m.texto,
    'momento': m.momento.toIso8601String(),
  };

  MensagemDaConversa? _mensagemDe(Map<String, dynamic> mapa) {
    final String? texto = mapa['texto'] as String?;
    final String? momento = mapa['momento'] as String?;
    if (texto == null || momento == null) return null;

    final DateTime? quando = DateTime.tryParse(momento);
    if (quando == null) return null;

    return MensagemDaConversa(
      autor: mapa['autor'] == AutorDaMensagem.memora.name
          ? AutorDaMensagem.memora
          : AutorDaMensagem.pessoa,
      texto: texto,
      momento: quando,
    );
  }
}
