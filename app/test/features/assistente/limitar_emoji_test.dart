import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/conversa/texto_da_fala.dart';
import 'package:memora/design_system/temas/temas_memora.dart';
import 'package:memora/features/assistente/domain/limitar_emoji.dart';

/// Portão de limite de emoji na fala da IA (feature 013, T040, V11; FR-024).
///
/// Toda resposta da Memora exibe no máximo o primeiro emoji; emojis seguintes
/// são removidos sem deixar espaços duplos ou espaço antes de pontuação.
/// Emojis compostos (com modificador de tom de pele ou junção ZWJ) contam
/// como um único emoji.
void main() {
  group('limitarEmoji — regra pura', () {
    test('mantém texto sem emoji inalterado', () {
      const String texto = 'Vamos fazer isso juntos, um passo de cada vez.';
      expect(limitarEmoji(texto), texto);
    });

    test('mantém texto com um único emoji inalterado', () {
      const String texto = 'Toque no botão verde lá embaixo 😊';
      expect(limitarEmoji(texto), texto);
    });

    test('remove emojis seguintes sem deixar espaço duplo ou antes de pontuação', () {
      expect(
        limitarEmoji('Olá 😊 tudo bem 😄 vamos tentar 👍!'),
        'Olá 😊 tudo bem vamos tentar!',
      );
      expect(
        limitarEmoji('Primeiro passo 😊. Segundo passo 😄! Terceiro 👍'),
        'Primeiro passo 😊. Segundo passo! Terceiro',
      );
      expect(
        limitarEmoji('Oi 😊 😄 😀 tudo'),
        'Oi 😊 tudo',
      );
    });

    test('trata emoji composto com modificador de tom de pele como um só', () {
      expect(
        limitarEmoji('Muito bem 👍🏽 Vamos em frente 😄!'),
        'Muito bem 👍🏽 Vamos em frente!',
      );
      expect(
        limitarEmoji('Bom trabalho 😊 Parabéns 👍🏽'),
        'Bom trabalho 😊 Parabéns',
      );
    });

    test('trata emoji composto com junção ZWJ como um só', () {
      expect(
        limitarEmoji('Posso ajudar 👩‍💻 sem pressa 😊!'),
        'Posso ajudar 👩‍💻 sem pressa!',
      );
      expect(
        limitarEmoji('Que bom ❤️‍🔥 continuar assim 😄'),
        'Que bom ❤️‍🔥 continuar assim',
      );
    });

    test('preserva quebras de linha ao remover emojis adicionais', () {
      expect(
        limitarEmoji('Olá 😊\n😄 Tudo bem 😄'),
        'Olá 😊\nTudo bem',
      );
    });
  });

  group('TextoDaFala — integração do limite de emoji', () {
    testWidgets('exibe apenas o primeiro emoji recebido na fala da IA', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: const Scaffold(
            body: TextoDaFala(
              'Que bom te ver 😊 Vamos aprender 😄 juntos 👍!',
            ),
          ),
        ),
      );

      expect(find.text('Que bom te ver 😊 Vamos aprender juntos!'), findsOneWidget);
      expect(find.textContaining('😄'), findsNothing);
      expect(find.textContaining('👍'), findsNothing);
    });
  });
}
