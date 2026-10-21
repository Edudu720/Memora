import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';

// tests for Servico
void main() {
  final Servico? instance = /* Servico(...) */ null;
  // TODO add properties to the entity

  group(Servico, () {
    // String id
    test('to test the property `id`', () async {
      // TODO
    });

    // Identificador estável do item, igual em qualquer banco. É o que liga o item ao guia de passo a passo embarcado no aplicativo. O `id` continua sendo o que a trilha de auditoria referencia. 
    // String chave
    test('to test the property `chave`', () async {
      // TODO
    });

    // String nomeExibido
    test('to test the property `nomeExibido`', () async {
      // TODO
    });

    // String descricaoCurta
    test('to test the property `descricaoCurta`', () async {
      // TODO
    });

    // String categoria
    test('to test the property `categoria`', () async {
      // TODO
    });

    // Redundante com `categoria`, e de propósito: é o que a tela exibe (FR-045), e derivar isso na tela espalharia a regra da FR-041 por dois lugares. 
    // bool memoraPodeAbrir
    test('to test the property `memoraPodeAbrir`', () async {
      // TODO
    });

    // Ausente quando `sensivel`.
    // String identificadorAndroid
    test('to test the property `identificadorAndroid`', () async {
      // TODO
    });

  });
}
