import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/leitor_da_conversa.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora_api/memora_api.dart' as api;
import 'package:yaml/yaml.dart';

import 'suporte_da_api_falsa.dart';

/// O portão que prende o leitor de SSE escrito à mão ao contrato (T110).
///
/// O leitor é a **única** parte do aplicativo que sai do cliente gerado, e por
/// isso a única que não quebra a compilação quando o contrato muda: se alguém
/// renomear o evento `texto`, ou um valor de `codigo`, o app continua
/// compilando e passa a falar uma língua que o servidor já não fala — uma
/// conversa que nunca termina, ou que termina vazia.
///
/// Este teste **lê o `openapi.yaml` do disco** e alimenta o leitor com o que
/// o contrato descreve, em vez de repetir nomes que o próprio leitor já
/// contém. `test` puro: é só leitura de arquivo, e `testWidgets` não completa
/// I/O real.
void main() {
  // O `flutter test` roda com a pasta `app/` como diretório atual.
  final File arquivo = File(
    '../specs/001-autenticacao-acessivel/contracts/openapi.yaml',
  );

  test('o contrato da 001 está onde o teste espera', () {
    expect(
      arquivo.existsSync(),
      isTrue,
      reason:
          'sem o contrato o portão não prova nada — falhar alto é melhor '
          'que passar em silêncio',
    );
  });

  late final YamlMap contrato = loadYaml(arquivo.readAsStringSync()) as YamlMap;

  YamlMap no(YamlMap raiz, List<String> caminho) {
    Object? atual = raiz;
    for (final String passo in caminho) {
      atual = (atual as YamlMap)[passo];
    }
    return atual! as YamlMap;
  }

  late final YamlMap operacao = no(contrato, <String>[
    'paths',
    '/assistente/conversa',
    'post',
  ]);
  YamlMap esquema(String nome) =>
      no(contrato, <String>['components', 'schemas', nome]);

  Set<String> conjunto(Object? lista) =>
      (lista! as YamlList).map((Object? e) => e! as String).toSet();

  Stream<List<int>> deEventos(List<String> eventos) =>
      Stream<List<int>>.fromIterable(eventos.map((String e) => utf8.encode(e)));

  group('os nomes de evento', () {
    test('os 4 que o leitor interpreta são os que o contrato descreve', () {
      final String descricao =
          no(operacao, <String>['responses', '200'])['description']! as String;

      // Os itens da lista da descrição: "- `texto` — ...".
      final Set<String> descritos = RegExp(
        r'^\s*-\s*`(\w+)`\s*—',
        multiLine: true,
      ).allMatches(descricao).map((RegExpMatch m) => m.group(1)!).toSet();

      expect(
        descritos,
        EventosDaConversa.todos,
        reason:
            'o contrato descreve $descritos e o leitor interpreta '
            '${EventosDaConversa.todos}',
      );
    });

    test(
      'o contrato continua dizendo que a falha da conversa não vira HTTP',
      () {
        final Set<String> status = (operacao['responses']! as YamlMap).keys
            .map((Object? k) => '$k')
            .toSet();

        expect(status, isNot(contains('429')));
        expect(status, isNot(contains('503')));
      },
    );
  });

  group('o evento erro', () {
    test('ErroDaConversa tem exatamente os campos que o leitor lê', () {
      final YamlMap erro = esquema('ErroDaConversa');

      expect(conjunto(erro['required']), <String>{'codigo', 'mensagem'});
      expect((erro['properties']! as YamlMap).keys.toSet(), <String>{
        'codigo',
        'mensagem',
      });
    });

    test('os valores de codigo são exatamente os 3 que o leitor mapeia', () {
      final Set<String> doContrato = conjunto(
        no(esquema('ErroDaConversa'), <String>['properties', 'codigo'])['enum'],
      );

      expect(doContrato, <String>{
        'LIMITE_DE_CONVERSAS',
        'ASSISTENTE_INDISPONIVEL',
        'ERRO_INESPERADO',
      });
    });

    test('cada codigo do contrato chega à FalhaDaAssistente certa', () async {
      // Alimenta o leitor com o JSON montado a partir das chaves e dos valores
      // do CONTRATO. Código renomeado lá e não aqui cai em `inesperada`, e o
      // mapa abaixo reprova.
      const Map<String, FalhaDaAssistente> esperado =
          <String, FalhaDaAssistente>{
            'LIMITE_DE_CONVERSAS': FalhaDaAssistente.limiteDeConversas,
            'ASSISTENTE_INDISPONIVEL': FalhaDaAssistente.assistenteIndisponivel,
            'ERRO_INESPERADO': FalhaDaAssistente.inesperada,
          };
      final YamlMap erro = esquema('ErroDaConversa');
      final Set<String> codigos = conjunto(
        no(erro, <String>['properties', 'codigo'])['enum'],
      );

      // Um código que o contrato ganhe e o mapa não tenha tem `esperado` nulo,
      // e a comparação reprova — `inesperada` nunca é igual a `null`.
      for (final String codigo in codigos) {
        final String json = jsonEncode(<String, String>{
          'codigo': codigo,
          'mensagem': 'texto da Memora',
        });
        final RespostaDaAssistente resposta = await lerConversa(
          deEventos(<String>[evento('erro', json)]),
        );

        expect(
          (resposta as AssistenteFalhou).falha,
          esperado[codigo],
          reason: 'codigo $codigo',
        );
      }
    });
  });

  group('o evento acao', () {
    test('AcaoAutorizada tem exatamente os 3 campos que o leitor lê', () {
      final YamlMap acao = esquema('AcaoAutorizada');

      expect(conjunto(acao['required']), <String>{
        'servico_id',
        'nome_exibido',
        'identificador_android',
      });
      expect((acao['properties']! as YamlMap).keys.toSet(), <String>{
        'servico_id',
        'nome_exibido',
        'identificador_android',
      });
    });

    test(
      'o JSON montado com as chaves do contrato vira a ação do domínio',
      () async {
        final YamlMap propriedades =
            esquema('AcaoAutorizada')['properties']! as YamlMap;
        final String json = jsonEncode(<String, String>{
          for (final Object? chave in propriedades.keys)
            '$chave': 'valor-$chave',
        });

        final RespostaDaAssistente resposta = await lerConversa(
          deEventos(<String>[evento('acao', json), evento('fim')]),
        );

        final AcaoAutorizada? acao = (resposta as AssistenteRespondeu).acao;
        expect(
          acao,
          isNotNull,
          reason:
              'o leitor não reconheceu o formato que o contrato descreve: o '
              'evento acao foi descartado',
        );
        expect(acao!.servicoId, 'valor-servico_id');
        expect(acao.nomeExibido, 'valor-nome_exibido');
        expect(acao.identificadorAndroid, 'valor-identificador_android');
      },
    );
  });

  group('o pedido', () {
    test('os autores do histórico são os que o contrato aceita', () {
      final Set<String> doContrato = conjunto(
        no(esquema('Mensagem'), <String>['properties', 'autor'])['enum'],
      );

      expect(
        AutorDaMensagem.values.map((AutorDaMensagem a) => a.name).toSet(),
        doContrato,
      );
      expect(
        api.MensagemAutorEnum.values.map((api.MensagemAutorEnum a) => a.value),
        unorderedEquals(doContrato),
        reason: 'o cliente gerado está atrás do contrato: regenerar',
      );
    });
  });
}
