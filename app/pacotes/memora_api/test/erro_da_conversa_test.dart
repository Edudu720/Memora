import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';

// tests for ErroDaConversa
void main() {
  final ErroDaConversa? instance = /* ErroDaConversa(...) */ null;
  // TODO add properties to the entity

  group(ErroDaConversa, () {
    // `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
    // String codigo
    test('to test the property `codigo`', () async {
      // TODO
    });

    // Texto já pronto para a pessoa, na voz da Memora.
    // String mensagem
    test('to test the property `mensagem`', () async {
      // TODO
    });

  });
}
