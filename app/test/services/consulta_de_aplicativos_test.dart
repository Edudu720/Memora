import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

/// O canal `memora/aplicativos` visto do lado Dart (T060, R7).
///
/// O que se prova aqui é o que o contrato promete: argumento que não parece
/// pacote nem chega ao canal, falha do canal nunca chega à tela, e o ícone que
/// já veio não atravessa o canal de novo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel canal = MethodChannel('memora/aplicativos');
  late List<MethodCall> chamadas;
  late Future<Object?> Function(MethodCall) resposta;

  setUp(() {
    chamadas = <MethodCall>[];
    resposta = (MethodCall _) async => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (MethodCall chamada) {
          chamadas.add(chamada);
          return resposta(chamada);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  final Uint8List png = Uint8List.fromList(<int>[137, 80, 78, 71, 1, 2, 3]);

  /// O que a regra 3 do contrato recusa. Todos precisam parar antes do canal.
  const List<String> semFormaDePacote = <String>[
    '',
    ' ',
    'whatsapp',
    'com..whatsapp',
    '.com.whatsapp',
    'com.whatsapp.',
    '1com.whatsapp',
    'com.1whatsapp',
    'com.what-sapp',
    'com.whatsapp\n',
    'com.whatsapp; rm -rf',
    '../../etc/passwd',
    'com.whatsapp/..',
  ];

  group('ConsultaDeAplicativosPorCanal', () {
    test(
      'estaInstalado: argumento sem forma de pacote nem chega ao canal',
      () async {
        final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

        for (final String pacote in semFormaDePacote) {
          expect(
            await consulta.estaInstalado(pacote),
            isFalse,
            reason: '"$pacote"',
          );
        }
        expect(chamadas, isEmpty);
      },
    );

    test('iconeDe: argumento sem forma de pacote nem chega ao canal', () async {
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

      for (final String pacote in semFormaDePacote) {
        expect(await consulta.iconeDe(pacote), isNull, reason: '"$pacote"');
      }
      expect(chamadas, isEmpty);
    });

    test(
      'pacote com forma válida atravessa o canal, com o nome como argumento',
      () async {
        resposta = (MethodCall _) async => true;
        final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

        expect(await consulta.estaInstalado('com.whatsapp'), isTrue);
        expect(chamadas, hasLength(1));
        expect(chamadas.single.method, 'estaInstalado');
        expect(chamadas.single.arguments, 'com.whatsapp');
      },
    );

    test('falha do canal vira false e null, nunca exceção', () async {
      resposta = (MethodCall _) async =>
          throw PlatformException(code: 'quebrou');
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

      expect(await consulta.estaInstalado('com.whatsapp'), isFalse);
      expect(await consulta.iconeDe('com.whatsapp'), isNull);
    });

    test(
      'canal que não existe (sem o código nativo) vira false e null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, null);
        final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

        expect(await consulta.estaInstalado('com.whatsapp'), isFalse);
        expect(await consulta.iconeDe('com.whatsapp'), isNull);
      },
    );

    test('resposta de tipo errado também vira false e null', () async {
      resposta = (MethodCall _) async => 'sim';
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

      expect(await consulta.estaInstalado('com.whatsapp'), isFalse);
      expect(await consulta.iconeDe('com.whatsapp'), isNull);
    });

    test('o segundo pedido do mesmo ícone não atravessa o canal', () async {
      resposta = (MethodCall _) async => png;
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

      final Uint8List? primeiro = await consulta.iconeDe('com.whatsapp');
      final Uint8List? segundo = await consulta.iconeDe('com.whatsapp');

      expect(primeiro, png);
      expect(segundo, png);
      expect(
        chamadas.where((MethodCall c) => c.method == 'iconeDe'),
        hasLength(1),
      );
    });

    test(
      'pedidos simultâneos do mesmo ícone dividem uma ida ao canal',
      () async {
        resposta = (MethodCall _) async => png;
        final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

        final List<Uint8List?> icones = await Future.wait(<Future<Uint8List?>>[
          consulta.iconeDe('com.whatsapp'),
          consulta.iconeDe('com.whatsapp'),
          consulta.iconeDe('com.whatsapp'),
        ]);

        expect(icones, everyElement(png));
        expect(chamadas, hasLength(1));
      },
    );

    test('o cache é por pacote: outro aplicativo atravessa o canal', () async {
      resposta = (MethodCall _) async => png;
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

      await consulta.iconeDe('com.whatsapp');
      await consulta.iconeDe('com.instagram.android');

      expect(chamadas, hasLength(2));
    });

    test(
      'ícone ausente NÃO fica guardado: instalou depois, o ícone aparece',
      () async {
        resposta = (MethodCall _) async => null;
        final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();

        expect(await consulta.iconeDe('com.whatsapp'), isNull);

        // A pessoa foi à loja oficial, instalou, e voltou ao Memora.
        resposta = (MethodCall _) async => png;
        expect(await consulta.iconeDe('com.whatsapp'), png);
      },
    );

    test('estaInstalado nunca é guardado: reflete o aparelho agora', () async {
      resposta = (MethodCall _) async => false;
      final ConsultaDeAplicativos consulta = ConsultaDeAplicativosPorCanal();
      expect(await consulta.estaInstalado('com.whatsapp'), isFalse);

      resposta = (MethodCall _) async => true;
      expect(await consulta.estaInstalado('com.whatsapp'), isTrue);
      expect(chamadas, hasLength(2));
    });
  });

  group('ConsultaDeAplicativosSimulada', () {
    test('só o que o teste pôs como instalado está instalado', () async {
      final ConsultaDeAplicativosSimulada consulta =
          ConsultaDeAplicativosSimulada(
            instalados: <String>{'com.whatsapp'},
            icones: <String, Uint8List>{'com.whatsapp': png},
          );

      expect(await consulta.estaInstalado('com.whatsapp'), isTrue);
      expect(await consulta.estaInstalado('com.instagram.android'), isFalse);
      expect(await consulta.iconeDe('com.whatsapp'), png);
      expect(await consulta.iconeDe('com.instagram.android'), isNull);
    });

    test('respeita a mesma regra de forma que o canal', () async {
      final ConsultaDeAplicativosSimulada consulta =
          ConsultaDeAplicativosSimulada(
            instalados: <String>{'whatsapp'},
            icones: <String, Uint8List>{'whatsapp': png},
          );

      expect(await consulta.estaInstalado('whatsapp'), isFalse);
      expect(await consulta.iconeDe('whatsapp'), isNull);
    });
  });
}
