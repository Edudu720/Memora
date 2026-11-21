import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/antigolpe/domain/entidades/analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/servicos/analisador_local_de_golpes.dart';

void main() {
  const AnalisadorLocalDeGolpes analisador = AnalisadorLocalDeGolpes();

  group('AnalisadorLocalDeGolpes — validações de entrada', () {
    test('recusa texto vazio ou só com espaços', () {
      expect(
        () => analisador.analisar('   \n\t '),
        throwsA(isA<ConteudoAnaliseInvalidoException>()),
      );
    });

    test('recusa texto acima do limite de 2000 caracteres', () {
      final String longo = 'a' * (AnalisadorLocalDeGolpes.limiteCaracteres + 1);
      expect(
        () => analisador.analisar(longo),
        throwsA(isA<ConteudoAnaliseInvalidoException>()),
      );
    });

    test('aceita exatamente 2000 caracteres', () {
      final String noLimite = 'Oi, tudo bem? ' * 142;
      final AnaliseGolpe resultado = analisador.analisar(noLimite);
      expect(resultado.origem, OrigemAnalise.localOffline);
      expect(resultado.analisadoPorIa, isFalse);
    });
  });

  group('AnalisadorLocalDeGolpes — mensagens e links seguros', () {
    test('classifica mensagem cotidiana comum como seguro', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Bom dia! Vou passar aí às 15 horas para tomarmos um café.',
      );

      expect(resultado.risco, NivelRisco.seguro);
      expect(resultado.origem, OrigemAnalise.localOffline);
      expect(resultado.analisadoPorIa, isFalse);
      expect(resultado.sinaisDetectados, isEmpty);
      expect(resultado.orientacoes, isNotEmpty);
    });

    test('classifica link oficial .gov.br sem iscas como seguro', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Para consultar o calendário oficial, acesse https://www.gov.br/inss',
      );

      expect(resultado.risco, NivelRisco.seguro);
      expect(resultado.origem, OrigemAnalise.localOffline);
      expect(resultado.analisadoPorIa, isFalse);
    });
  });

  group('AnalisadorLocalDeGolpes — links e mensagens suspeitas/golpes', () {
    test('detecta link com endereço IP direto como altoRisco', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Confira seu boleto em http://192.168.0.55/atualizar',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.origem, OrigemAnalise.localOffline);
      expect(resultado.analisadoPorIa, isFalse);
      expect(resultado.sinaisDetectados, isNotEmpty);
    });

    test('detecta disfarce com @ (userinfo) no link como altoRisco', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Acesse https://bb.com.br@golpe-falso.xyz/entrar agora',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(
        resultado.sinaisDetectados.any((String s) => s.contains('@')),
        isTrue,
      );
    });

    test('detecta punycode xn-- e TLD suspeito', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Regularize seu cadastro em https://xn--bnc-brasil-x7a.xyz/login',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.sinaisDetectados.length, greaterThanOrEqualTo(2));
    });

    test('detecta encurtador com pedido de ação urgente como altoRisco', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Último aviso: sua conta será bloqueada hoje. Clique aqui https://bit.ly/3xyz99',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(
        resultado.sinaisDetectados.any((String s) => s.contains('encurtado')),
        isTrue,
      );
    });

    test('detecta golpe de suporte pedindo código de 6 dígitos e senha', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Urgente! Sou do suporte e sua conta foi suspensa. Envie o código de 6 dígitos e sua senha para desbloquear.',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.orientacoes, isNotEmpty);
    });

    test('detecta falsificação dos Correios com taxa de alfândega', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Correios: sua encomenda está retida na alfândega com taxa pendente. Pague o PIX em https://correios-taxa.top/retirar',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.origem, OrigemAnalise.localOffline);
    });

    test('detecta isca isolada de prêmio/brinde com atenção ou alto risco', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Parabéns! Você ganhou um brinde especial no sorteio de hoje.',
      );

      expect(
        resultado.risco,
        anyOf(NivelRisco.atencao, NivelRisco.altoRisco),
      );
      expect(resultado.sinaisDetectados, isNotEmpty);
    });

    test('detecta link ofuscado com hxxp e [.]', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Atualize seu cadastro urgente em hxxp://caixa-seguro[.]xyz/entrar',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
    });
  });
}
