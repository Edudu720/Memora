import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';

/// O abridor visto do lado Dart (T136).
///
/// Prova o que o Dart controla: chama o canal certo com o pacote, devolve o que
/// o canal disse, e o que não parece pacote ou falha vira `false`. Que o Android
/// abre de fato é conferido no celular.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel canal = MethodChannel('memora/abridor');
  late List<MethodCall> chamadas;
  late Future<Object?> Function(MethodCall) resposta;

  setUp(() {
    chamadas = <MethodCall>[];
    resposta = (MethodCall _) async => true;
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

  const AbridorDeAplicativoPorCanal abridor = AbridorDeAplicativoPorCanal();

  group('chama o canal', () {
    test('com o método abrir e o pacote como argumento', () async {
      await abridor.abrir('com.zhiliaoapp.musically');

      expect(chamadas, hasLength(1));
      expect(chamadas.single.method, 'abrir');
      expect(chamadas.single.arguments, 'com.zhiliaoapp.musically');
    });

    test('e devolve true quando o canal abriu', () async {
      resposta = (MethodCall _) async => true;
      expect(await abridor.abrir('com.instagram.android'), isTrue);
    });

    test('e devolve false quando o canal não abriu', () async {
      resposta = (MethodCall _) async => false;
      expect(await abridor.abrir('com.instagram.android'), isFalse);
    });
  });

  group('o que não parece pacote não chega ao canal', () {
    for (final String texto in <String>[
      'com.x; rm',
      '',
      'semponto',
      'com..x',
      '../../etc/passwd',
    ]) {
      test('"$texto"', () async {
        expect(await abridor.abrir(texto), isFalse);
        expect(chamadas, isEmpty);
      });
    }
  });

  group('falha do canal vira false', () {
    test('PlatformException', () async {
      resposta = (MethodCall _) async =>
          throw PlatformException(code: 'falhou');
      expect(await abridor.abrir('com.instagram.android'), isFalse);
    });

    test('canal sem handler (MissingPluginException)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
      expect(await abridor.abrir('com.instagram.android'), isFalse);
    });

    test('resposta null', () async {
      resposta = (MethodCall _) async => null;
      expect(await abridor.abrir('com.instagram.android'), isFalse);
    });

    test('resposta de tipo errado', () async {
      resposta = (MethodCall _) async => 'sim';
      expect(await abridor.abrir('com.instagram.android'), isFalse);
    });
  });
}
