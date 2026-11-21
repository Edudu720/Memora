import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../services/seguranca/limpeza_de_sessao.dart';

/// O que a pessoa já aprendeu a fazer, guardado **só no aparelho** (T062).
///
/// ## Por que isto é dado sensível
///
/// A lista do que alguém concluiu — e, por tabela, do que ainda não sabe fazer
/// — é um retrato da dificuldade dela. Num aparelho compartilhado, quem abrir o
/// Perfil não deve ver isso depois de a pessoa sair.
///
/// - **Vai ao servidor? Nunca** (FR-042a). O "aplicativo mais aprendido" é
///   calculado aqui. Esta classe não recebe repositório, cliente HTTP nem nada
///   que fale com a rede, e é isso que mantém a regra verdadeira.
/// - **Sai ao sair da conta? Sempre** (FR-042b). É [DadoLocalDaPessoa], apagado
///   pela `LimpezaDeSessao` em **toda** saída, inclusive a por inatividade.
///
/// ## Onde e como
///
/// Um arquivo JSON no diretório privado do aplicativo, com o progresso de todas
/// as contas que usaram o aparelho, cada uma sob o próprio id. Apagar leva o
/// arquivo inteiro: a saída não distingue conta, e deixar o de outra pessoa
/// para trás seria exatamente o vazamento que a FR-042b existe para evitar.
///
/// Gravação em arquivo temporário seguida de renomeação, para uma queda no meio
/// não deixar um arquivo pela metade. Leituras e gravações andam em fila: duas
/// conclusões seguidas não se atropelam.
class ProgressoDeAprendizado implements DadoLocalDaPessoa {
  /// Nome do arquivo dentro do diretório privado.
  static const String nomeDoArquivo = 'progresso_de_aprendizado.json';

  /// Diretório onde gravar. Trocável no teste, que não tem plataforma.
  final Future<Directory> Function() _diretorio;

  Future<void> _fila = Future<void>.value();
  final StreamController<void> _alteracoes = StreamController<void>.broadcast();

  /// Notifica quando o progresso local muda (nova conclusão ou limpeza).
  Stream<void> get alteracoes => _alteracoes.stream;

  /// Cria o armazenamento do progresso.
  ProgressoDeAprendizado({Future<Directory> Function()? diretorio})
    : _diretorio = diretorio ?? getApplicationDocumentsDirectory;

  /// Conta uma chegada ao passo [numeroDoPasso] (de 1 a [totalDePassos]) do
  /// guia [chave] e devolve se ela **contou**.
  ///
  /// Só conta ao chegar ao **último** passo: abrir o guia, ver o primeiro passo
  /// e desistir não é ter aprendido. Cada chegada ao último passo soma uma vez
  /// — quem refaz o guia inteiro aprendeu de novo.
  Future<bool> registrarChegadaAoPasso({
    required String idDaConta,
    required String chave,
    required int numeroDoPasso,
    required int totalDePassos,
  }) async {
    if (numeroDoPasso != totalDePassos) return false;
    await registrarConclusao(idDaConta: idDaConta, chave: chave);
    return true;
  }

  /// Soma uma conclusão do guia [chave] para [idDaConta].
  Future<void> registrarConclusao({
    required String idDaConta,
    required String chave,
  }) async {
    if (_semValor(idDaConta)) {
      // Sem id, todas as contas cairiam na mesma entrada, e uma veria o que a
      // outra aprendeu.
      throw ArgumentError.value(
        idDaConta,
        'idDaConta',
        'não identifica ninguém',
      );
    }
    if (_semValor(chave)) {
      throw ArgumentError.value(chave, 'chave', 'não identifica um guia');
    }

    await _naFila(() async {
      final Map<String, Map<String, _Entrada>> tudo = await _ler();
      final Map<String, _Entrada> daConta = tudo.putIfAbsent(
        idDaConta,
        () => <String, _Entrada>{},
      );

      // A ordem é um contador que só cresce, e não a hora: duas conclusões no
      // mesmo instante ainda têm uma mais recente que a outra.
      final int proxima = 1 + _maiorOrdem(tudo);
      final _Entrada? anterior = daConta[chave];
      daConta[chave] = _Entrada((anterior?.vezes ?? 0) + 1, proxima);

      await _gravar(tudo);
    });
    _notificarAlteracao();
  }

  /// Quantas vezes [idDaConta] concluiu cada guia. Vazio quando nenhuma.
  Future<Map<String, int>> concluidos(String idDaConta) async {
    if (_semValor(idDaConta)) return const <String, int>{};
    return _naFila(() async {
      final Map<String, _Entrada>? daConta = (await _ler())[idDaConta];
      if (daConta == null) return const <String, int>{};
      return <String, int>{
        for (final MapEntry<String, _Entrada> e in daConta.entries)
          e.key: e.value.vezes,
      };
    });
  }

  /// Ordem monotônica da conclusão mais recente de cada chave para [idDaConta].
  Future<Map<String, int>> ordensDeConclusao(String idDaConta) async {
    if (_semValor(idDaConta)) return const <String, int>{};
    return _naFila(() async {
      final Map<String, _Entrada>? daConta = (await _ler())[idDaConta];
      if (daConta == null) return const <String, int>{};
      return <String, int>{
        for (final MapEntry<String, _Entrada> e in daConta.entries)
          e.key: e.value.ordem,
      };
    });
  }

  /// Chave concluída por último por [idDaConta], ou `null` quando vazia.
  Future<String?> ultimoConcluido(String idDaConta) async {
    if (_semValor(idDaConta)) return null;
    final Map<String, int> ordens = await ordensDeConclusao(idDaConta);
    if (ordens.isEmpty) return null;
    String? recente;
    int maior = -1;
    for (final MapEntry<String, int> e in ordens.entries) {
      if (e.value > maior) {
        maior = e.value;
        recente = e.key;
      }
    }
    return recente;
  }

  /// A `chave` do guia mais concluído por [idDaConta], ou `null` quando ela
  /// ainda não concluiu nenhum (US8, cenário 3).
  ///
  /// Em caso de empate, vence o concluído por último.
  Future<String?> aplicativoMaisAprendido(String idDaConta) async {
    if (_semValor(idDaConta)) return null;
    return _naFila(() async {
      final Map<String, _Entrada>? daConta = (await _ler())[idDaConta];
      if (daConta == null || daConta.isEmpty) return null;

      String? melhor;
      _Entrada? melhorEntrada;
      for (final MapEntry<String, _Entrada> e in daConta.entries) {
        final _Entrada? atual = melhorEntrada;
        if (atual == null ||
            e.value.vezes > atual.vezes ||
            (e.value.vezes == atual.vezes && e.value.ordem > atual.ordem)) {
          melhor = e.key;
          melhorEntrada = e.value;
        }
      }
      return melhor;
    });
  }

  /// Apaga o progresso de todas as contas (FR-042b).
  ///
  /// Falha de verdade não é engolida aqui: a `LimpezaDeSessao` a registra e
  /// segue para os outros itens, e silenciar daria à pessoa a falsa certeza de
  /// que o que ela aprendeu saiu do aparelho.
  @override
  Future<void> apagar() async {
    await _naFila(() async {
      final File arquivo = await _arquivo();
      // O temporário também: se o processo morreu entre gravar e renomear, ele
      // guarda o progresso de todas as contas e sobreviveria à saída.
      for (final File f in <File>[arquivo, File('${arquivo.path}.tmp')]) {
        try {
          await f.delete();
        } on PathNotFoundException {
          // Já não existe: é o resultado que se queria.
        }
      }
    });
    _notificarAlteracao();
  }

  // ---------------------------------------------------------------------------

  void _notificarAlteracao() {
    if (!_alteracoes.isClosed) _alteracoes.add(null);
  }

  static bool _semValor(String texto) => texto.trim().isEmpty;

  /// Executa [tarefa] depois de tudo que já está na fila, e mantém a fila viva
  /// mesmo se ela falhar.
  Future<T> _naFila<T>(Future<T> Function() tarefa) {
    final Future<T> resultado = _fila.then((_) => tarefa());
    _fila = resultado.then<void>((_) {}, onError: (Object _) {});
    return resultado;
  }

  Future<File> _arquivo() async =>
      File('${(await _diretorio()).path}/$nomeDoArquivo');

  static int _maiorOrdem(Map<String, Map<String, _Entrada>> tudo) {
    int maior = 0;
    for (final Map<String, _Entrada> daConta in tudo.values) {
      for (final _Entrada e in daConta.values) {
        if (e.ordem > maior) maior = e.ordem;
      }
    }
    return maior;
  }

  /// Lê o arquivo. Ausente, corrompido ou de forma inesperada: começa do zero,
  /// que é o pior caso aceitável para uma conveniência.
  Future<Map<String, Map<String, _Entrada>>> _ler() async {
    final Map<String, Map<String, _Entrada>> tudo =
        <String, Map<String, _Entrada>>{};
    try {
      final dynamic bruto = jsonDecode(await (await _arquivo()).readAsString());
      if (bruto is! Map<String, dynamic>) return tudo;
      final dynamic contas = bruto['contas'];
      if (contas is! Map<String, dynamic>) return tudo;

      for (final MapEntry<String, dynamic> conta in contas.entries) {
        final dynamic guias = conta.value;
        if (guias is! Map<String, dynamic>) continue;
        final Map<String, _Entrada> daConta = <String, _Entrada>{};
        for (final MapEntry<String, dynamic> guia in guias.entries) {
          final _Entrada? entrada = _Entrada.deJson(guia.value);
          if (entrada != null) daConta[guia.key] = entrada;
        }
        if (daConta.isNotEmpty) tudo[conta.key] = daConta;
      }
    } on Exception {
      return <String, Map<String, _Entrada>>{};
    }
    return tudo;
  }

  Future<void> _gravar(Map<String, Map<String, _Entrada>> tudo) async {
    final File arquivo = await _arquivo();
    final File temporario = File('${arquivo.path}.tmp');
    final String conteudo = jsonEncode(<String, dynamic>{
      'contas': <String, dynamic>{
        for (final MapEntry<String, Map<String, _Entrada>> conta
            in tudo.entries)
          conta.key: <String, dynamic>{
            for (final MapEntry<String, _Entrada> guia in conta.value.entries)
              guia.key: guia.value.paraJson(),
          },
      },
    });
    await temporario.writeAsString(conteudo, flush: true);
    await temporario.rename(arquivo.path);
  }
}

class _Entrada {
  final int vezes;
  final int ordem;

  const _Entrada(this.vezes, this.ordem);

  static _Entrada? deJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final dynamic vezes = json['vezes'];
    final dynamic ordem = json['ordem'];
    if (vezes is! int || ordem is! int || vezes < 1 || ordem < 1) return null;
    return _Entrada(vezes, ordem);
  }

  Map<String, dynamic> paraJson() => <String, dynamic>{
    'vezes': vezes,
    'ordem': ordem,
  };
}
