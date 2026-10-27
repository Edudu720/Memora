import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/services/ambiente/composicao.dart';

/// O prazo do transporte cabe no servidor de verdade.
///
/// No Render gratuito (0,1 de CPU) cadastro e entrada levaram até 20 s
/// (2026-10-27). Com os 3 s do cliente gerado, o servidor respondia e a pessoa
/// via "Não consegui falar com a internet".
void main() {
  const Duration piorMedido = Duration(seconds: 20);

  test('a espera pela resposta passa do pior tempo medido no Render', () {
    final opcoes = Composicao.opcoesDoTransporte('https://exemplo/v1');

    expect(opcoes.baseUrl, 'https://exemplo/v1');
    expect(opcoes.receiveTimeout, greaterThan(piorMedido));
    expect(opcoes.connectTimeout, isNotNull);
    expect(opcoes.sendTimeout, isNotNull);
  });

  // O cliente gerado cria um Dio de 3 s quando não recebe nenhum. Este caso
  // prende a Composicao ao transporte com os prazos acima: sem ele, apagar o
  // `Dio(...)` voltaria aos 3 s com todos os outros testes passando.
  test('a Composicao entrega esse transporte ao cliente gerado', () {
    final fonte = File(
      'lib/services/ambiente/composicao.dart',
    ).readAsStringSync();

    expect(fonte, contains('Dio(opcoesDoTransporte(ambiente.urlBase))'));
  });
}
