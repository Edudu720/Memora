import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/conversa/texto_com_negrito.dart';

/// O analisador do negrito — T131, FR-020a.
///
/// Só `**trecho**` é lido. Marca sem par, marca vazia e qualquer outra
/// formatação ficam como texto comum, e **nenhum asterisco que fecha um par
/// chega à tela**.
void main() {
  TrechoDeTexto comum(String t) => TrechoDeTexto(t);
  TrechoDeTexto forte(String t) => TrechoDeTexto(t, negrito: true);

  group('analisarNegrito', () {
    test('um par vira negrito, e os asteriscos somem', () {
      expect(analisarNegrito('Toque em **Fotos** agora'), <TrechoDeTexto>[
        comum('Toque em '),
        forte('Fotos'),
        comum(' agora'),
      ]);
    });

    test('vários pares na mesma fala', () {
      expect(
        analisarNegrito('Abra o **WhatsApp** e toque em **Conversas**.'),
        <TrechoDeTexto>[
          comum('Abra o '),
          forte('WhatsApp'),
          comum(' e toque em '),
          forte('Conversas'),
          comum('.'),
        ],
      );
    });

    test('o texto todo em negrito, ou o negrito no começo e no fim', () {
      expect(analisarNegrito('**Olá**'), <TrechoDeTexto>[forte('Olá')]);
      expect(analisarNegrito('**um** e **dois**'), <TrechoDeTexto>[
        forte('um'),
        comum(' e '),
        forte('dois'),
      ]);
    });

    test('texto sem marca fica inteiro, e em um trecho só', () {
      expect(analisarNegrito('Nada a destacar aqui.'), <TrechoDeTexto>[
        comum('Nada a destacar aqui.'),
      ]);
    });

    test('texto vazio não tem trecho nenhum', () {
      expect(analisarNegrito(''), isEmpty);
      expect(textoSemMarcas(''), '');
    });

    test('marca sem par fica como texto comum, asteriscos e tudo', () {
      expect(analisarNegrito('Toque em **Fotos'), <TrechoDeTexto>[
        comum('Toque em **Fotos'),
      ]);
      expect(textoSemMarcas('Toque em **Fotos'), 'Toque em **Fotos');
    });

    test('`**` no fim do texto, sem nada depois, fica como texto', () {
      expect(analisarNegrito('Pronto**'), <TrechoDeTexto>[comum('Pronto**')]);
      expect(analisarNegrito('**'), <TrechoDeTexto>[comum('**')]);
    });

    test('um par e uma marca solta: o par vale, a solta fica', () {
      expect(analisarNegrito('**a** e **b'), <TrechoDeTexto>[
        forte('a'),
        comum(' e **b'),
      ]);
    });

    test('marca vazia (`****`) fica como texto: não há o que destacar', () {
      expect(textoSemMarcas('antes **** depois'), 'antes **** depois');
      expect(
        analisarNegrito('antes **** depois').any((TrechoDeTexto t) => t.negrito),
        isFalse,
      );
    });

    test('um asterisco sozinho é só um asterisco', () {
      expect(analisarNegrito('2 * 3 = 6'), <TrechoDeTexto>[comum('2 * 3 = 6')]);
    });

    test('só negrito: nenhuma outra marca é interpretada', () {
      const String outras = '_itálico_ `código` # título - lista [link](x)';
      expect(analisarNegrito(outras), <TrechoDeTexto>[comum(outras)]);
      // E um asterisco simples não vira itálico.
      expect(textoSemMarcas('*assim*'), '*assim*');
    });

    test('a quebra de linha dentro do par continua dentro do negrito', () {
      expect(analisarNegrito('**um\ndois**'), <TrechoDeTexto>[forte('um\ndois')]);
    });
  });

  group('textoSemMarcas — o que o leitor de tela recebe', () {
    test('nenhum asterisco de par sobra', () {
      const String fala = 'Abra o **WhatsApp** e toque em **Conversas**.';
      expect(textoSemMarcas(fala), 'Abra o WhatsApp e toque em Conversas.');
      expect(textoSemMarcas(fala), isNot(contains('*')));
    });
  });

  group('emAndamento — o texto ainda está chegando', () {
    test('`**` aberto vale como negrito até onde chegou, sem asteriscos', () {
      expect(analisarNegrito('Toque em **Fot', emAndamento: true),
          <TrechoDeTexto>[comum('Toque em '), forte('Fot')]);
    });

    test('`**` recém-aberto, sem nada depois, ainda não mostra nada dele', () {
      expect(analisarNegrito('Toque em **', emAndamento: true),
          <TrechoDeTexto>[comum('Toque em ')]);
    });

    test('um `*` no fim pode estar virando `**`: fica segurado', () {
      expect(analisarNegrito('Toque em *', emAndamento: true),
          <TrechoDeTexto>[comum('Toque em ')]);
      expect(textoSemMarcas('Abra o **WhatsApp**', emAndamento: true),
          'Abra o WhatsApp');
    });

    test('quando o texto termina, a regra normal volta', () {
      expect(textoSemMarcas('Toque em **Fot'), 'Toque em **Fot');
    });
  });
}
