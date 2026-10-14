import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

/// A forma de pacote vive em dois lugares, Dart e Kotlin, e precisa ser a mesma:
/// um lado mais frouxo que o outro abre a pergunta ao sistema para quem controla
/// o argumento. Mesmo idioma do `PoliticaDeSenhaTest`, que lê um arquivo do
/// outro lado e confere.
void main() {
  test('a regex do canal Kotlin é a mesma do Dart', () {
    final File kt = File(
      'android/app/src/main/kotlin/br/fatec/memora/CanalDeAplicativos.kt',
    );
    expect(kt.existsSync(), isTrue, reason: 'rode a partir da pasta app/');

    final RegExpMatch? achado = RegExp(
      r'FORMA_DE_PACOTE\s*=\s*Regex\("""(.*?)"""\)',
      dotAll: true,
    ).firstMatch(kt.readAsStringSync());

    expect(achado, isNotNull, reason: 'não achei FORMA_DE_PACOTE no .kt');
    expect(achado!.group(1), formaDePacote.pattern);
  });
}
