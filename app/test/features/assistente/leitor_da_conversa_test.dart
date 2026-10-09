import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/leitor_da_conversa.dart';
import 'package:memora/features/assistente/domain/assistente.dart';

import 'suporte_da_api_falsa.dart';

/// O leitor de Server-Sent Events escrito à mão (T036).
///
/// O formato é traiçoeiro de formas que um `split('\n')` não vê — fim de linha
/// `\r\n`, caractere multibyte cortado entre dois pedaços da rede, um espaço
/// que pertence ao dado. Cada caso aqui é uma dessas armadilhas.
void main() {
  Stream<List<int>> deTextos(List<String> pedacos) =>
      Stream<List<int>>.fromIterable(pedacos.map((String p) => utf8.encode(p)));

  Future<List<EventoSse>> eventos(Stream<List<int>> bytes) =>
      lerEventosSse(bytes).toList();

  group('lerEventosSse', () {
    test('um evento por bloco, com nome e dado', () async {
      final List<EventoSse> lidos = await eventos(
        deTextos(<String>[evento('texto', 'Olá'), evento('fim')]),
      );

      expect(lidos.map((EventoSse e) => '${e.nome}|${e.dados}'), <String>[
        'texto|Olá',
        'fim|',
      ]);
    });

    test('várias linhas data: são juntas com \\n', () async {
      final List<EventoSse> lidos = await eventos(
        deTextos(<String>['event:texto\ndata:linha um\ndata:linha dois\n\n']),
      );

      expect(lidos.single.dados, 'linha um\nlinha dois');
    });

    test('aceita \\r\\n e \\r como fim de linha', () async {
      final List<EventoSse> crlf = await eventos(
        deTextos(<String>['event:texto\r\ndata:oi\r\n\r\n']),
      );
      final List<EventoSse> cr = await eventos(
        deTextos(<String>['event:texto\rdata:oi\r\r']),
      );

      expect(crlf.single.dados, 'oi');
      expect(cr.single.dados, 'oi');
    });

    test(
      '\\r\\n cortado entre dois pedaços não vira linha em branco extra',
      () async {
        final List<EventoSse> lidos = await eventos(
          deTextos(<String>['event:texto\r', '\ndata:oi\r', '\n\r', '\n']),
        );

        expect(lidos, hasLength(1));
        expect(lidos.single.dados, 'oi');
      },
    );

    test('linha de comentário some', () async {
      final List<EventoSse> lidos = await eventos(
        deTextos(<String>[': mantendo a conexão\nevent:texto\ndata:oi\n\n']),
      );

      expect(lidos, hasLength(1));
      expect(lidos.single.dados, 'oi');
    });

    test('só UM espaço depois dos dois-pontos é removido', () async {
      // Um trecho que começa com espaço perderia o espaço entre as palavras.
      final List<EventoSse> lidos = await eventos(
        deTextos(<String>[
          'event:texto\ndata:  duas palavras\n\n',
          'event:texto\ndata: uma\n\n',
          'event:texto\ndata:nenhum\n\n',
        ]),
      );

      expect(lidos.map((EventoSse e) => e.dados), <String>[
        ' duas palavras',
        'uma',
        'nenhum',
      ]);
    });

    test('caractere multibyte cortado entre dois pedaços sobrevive', () async {
      // "ã" (2 bytes) e o emoji da Memora (4 bytes), com os bytes entregues
      // um por vez: decodificar pedaço a pedaço estragaria os dois.
      final List<int> todos = utf8.encode(evento('texto', 'Olá, não 😊'));
      final List<EventoSse> lidos = await eventos(
        Stream<List<int>>.fromIterable(<List<int>>[
          for (final int b in todos) <int>[b],
        ]),
      );

      expect(lidos.single.dados, 'Olá, não 😊');
    });

    test(
      'evento cortado no meio de uma palavra do campo é remontado',
      () async {
        final List<EventoSse> lidos = await eventos(
          deTextos(<String>['eve', 'nt:te', 'xto\nda', 'ta:oi\n', '\n']),
        );

        expect(lidos.single.nome, 'texto');
        expect(lidos.single.dados, 'oi');
      },
    );

    test('evento sem a linha em branco final NÃO é entregue', () async {
      // A conexão caiu no meio: texto pela metade tratado como resposta seria
      // pior que falha.
      final List<EventoSse> lidos = await eventos(
        deTextos(<String>[
          evento('texto', 'inteiro'),
          'event:texto\ndata:meta',
        ]),
      );

      expect(lidos.map((EventoSse e) => e.dados), <String>['inteiro']);
    });
  });

  group('lerConversa', () {
    test(
      'texto + fim: entrega os trechos assim que chegam e o texto inteiro',
      () async {
        final List<String> trechos = <String>[];

        final RespostaDaAssistente resposta = await lerConversa(
          deTextos(<String>[
            evento('texto', 'Vamos '),
            evento('texto', 'juntos.'),
            evento('fim'),
          ]),
          aoReceberTrecho: trechos.add,
        );

        expect(trechos, <String>['Vamos ', 'juntos.']);
        expect(resposta, isA<AssistenteRespondeu>());
        final AssistenteRespondeu r = resposta as AssistenteRespondeu;
        expect(r.texto, 'Vamos juntos.');
        expect(r.acao, isNull);
      },
    );

    test('trecho com quebra de linha chega inteiro', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[
          'event:texto\ndata:primeiro\ndata:segundo\n\n',
          evento('fim'),
        ]),
      );

      expect((resposta as AssistenteRespondeu).texto, 'primeiro\nsegundo');
    });

    test('evento acao vira a AcaoAutorizada da resposta', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[
          evento('texto', 'Quer que eu abra?'),
          evento(
            'acao',
            jsonEncode(<String, String>{
              'servico_id': 'a1b2',
              'nome_exibido': 'WhatsApp',
              'identificador_android': 'com.whatsapp',
            }),
          ),
          evento('fim'),
        ]),
      );

      final AcaoAutorizada? acao = (resposta as AssistenteRespondeu).acao;
      expect(acao, isNotNull);
      expect(acao!.servicoId, 'a1b2');
      expect(acao.nomeExibido, 'WhatsApp');
      expect(acao.identificadorAndroid, 'com.whatsapp');
    });

    test(
      'ação que não bate com o contrato é descartada, o texto fica',
      () async {
        // Errar para o lado de NÃO oferecer abrir aplicativo (Princípio VI).
        final RespostaDaAssistente resposta = await lerConversa(
          deTextos(<String>[
            evento('texto', 'Vamos com calma.'),
            evento(
              'acao',
              jsonEncode(<String, String>{'servico_id': 'só isto'}),
            ),
            evento('fim'),
          ]),
        );

        final AssistenteRespondeu r = resposta as AssistenteRespondeu;
        expect(r.texto, 'Vamos com calma.');
        expect(r.acao, isNull);
      },
    );

    test('ação que não é JSON é descartada', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[evento('acao', 'isto não é json'), evento('fim')]),
      );

      expect((resposta as AssistenteRespondeu).acao, isNull);
    });

    for (final (String codigo, FalhaDaAssistente falha)
        in <(String, FalhaDaAssistente)>[
          ('LIMITE_DE_CONVERSAS', FalhaDaAssistente.limiteDeConversas),
          ('ASSISTENTE_INDISPONIVEL', FalhaDaAssistente.assistenteIndisponivel),
          ('ERRO_INESPERADO', FalhaDaAssistente.inesperada),
        ]) {
      test('evento erro $codigo vira $falha', () async {
        final RespostaDaAssistente resposta = await lerConversa(
          deTextos(<String>[
            evento(
              'erro',
              jsonEncode(<String, String>{'codigo': codigo, 'mensagem': 'x'}),
            ),
          ]),
        );

        expect(resposta, isA<AssistenteFalhou>());
        expect((resposta as AssistenteFalhou).falha, falha);
      });
    }

    test(
      'erro depois de texto é falha — o texto parcial não vira resposta',
      () async {
        final RespostaDaAssistente resposta = await lerConversa(
          deTextos(<String>[
            evento('texto', 'Vamos'),
            evento(
              'erro',
              jsonEncode(<String, String>{
                'codigo': 'ASSISTENTE_INDISPONIVEL',
                'mensagem': 'x',
              }),
            ),
          ]),
        );

        expect(
          (resposta as AssistenteFalhou).falha,
          FalhaDaAssistente.assistenteIndisponivel,
        );
      },
    );

    test(
      'código de erro desconhecido vira inesperada, nunca silêncio',
      () async {
        final RespostaDaAssistente resposta = await lerConversa(
          deTextos(<String>[
            evento(
              'erro',
              jsonEncode(<String, String>{'codigo': 'NOVO', 'mensagem': 'x'}),
            ),
          ]),
        );

        expect(
          (resposta as AssistenteFalhou).falha,
          FalhaDaAssistente.inesperada,
        );
      },
    );

    test('erro sem JSON válido vira inesperada', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[evento('erro', 'não é json')]),
      );

      expect(
        (resposta as AssistenteFalhou).falha,
        FalhaDaAssistente.inesperada,
      );
    });

    test('fluxo que acaba sem fim nem erro é semConexao', () async {
      final List<String> trechos = <String>[];
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[evento('texto', 'Vamos ')]),
        aoReceberTrecho: trechos.add,
      );

      expect(
        (resposta as AssistenteFalhou).falha,
        FalhaDaAssistente.semConexao,
        reason:
            'a conexão caiu no meio da resposta: o texto parcial não é '
            'uma resposta',
      );
      expect(trechos, <String>['Vamos '], reason: 'ele chegou a aparecer');
    });

    test('evento de nome desconhecido é ignorado', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        deTextos(<String>[
          evento('batimento'),
          evento('texto', 'oi'),
          evento('fim'),
        ]),
      );

      expect((resposta as AssistenteRespondeu).texto, 'oi');
    });

    test('bytes que não são UTF-8 viram inesperada', () async {
      final RespostaDaAssistente resposta = await lerConversa(
        Stream<List<int>>.fromIterable(<List<int>>[
          <int>[...utf8.encode('event:texto\ndata:'), 0xFF, 0xFE],
        ]),
      );

      expect(
        (resposta as AssistenteFalhou).falha,
        FalhaDaAssistente.inesperada,
      );
    });
  });
}
