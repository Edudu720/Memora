import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/antigolpe/domain/entidades/analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/servicos/analisador_local_de_golpes.dart';
import 'package:memora/l10n/textos_antigolpe.dart';

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

  group('AnalisadorLocalDeGolpes — mensagens e links seguros (zero falsos positivos)', () {
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

    test('reconhece domínios oficiais sincronizados com o backend', () {
      for (final String url in <String>[
        'https://www.bancodobrasil.com.br',
        'https://www.caixa.com.br',
        'https://banco.bradesco',
        'https://nu.com.br',
        'https://wa.me/5511999999999',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(
          'Acesse o canal oficial: $url',
        );
        expect(resultado.risco, NivelRisco.seguro, reason: url);
        expect(resultado.sinaisDetectados, isEmpty, reason: url);
      }
    });

    test('não dispara marca falsa em link oficial citado com WhatsApp ou múltiplos links oficiais', () {
      final AnaliseGolpe r1 = analisador.analisar(
        'Recebi no WhatsApp o link do INSS: https://www.gov.br/inss',
      );
      expect(r1.risco, NivelRisco.seguro);
      expect(r1.sinaisDetectados, isEmpty);

      final AnaliseGolpe r2 = analisador.analisar(
        'Consulte https://www.gov.br e https://www.caixa.gov.br',
      );
      expect(r2.risco, NivelRisco.seguro);
      expect(r2.sinaisDetectados, isEmpty);
    });

    test('não escala urgência com link oficial para altoRisco', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'INSS: faça sua prova de vida urgente em https://www.gov.br/inss',
      );
      expect(resultado.risco, isNot(NivelRisco.altoRisco));
    });

    test('ignora endereços de e-mail comuns sem confundi-los com domínios ou @ userinfo', () {
      for (final String texto in <String>[
        'Meu e-mail novo é carlos.me@gmail.com para contato.',
        'Envie a confirmação para maria.caixa@gmail.com quando puder.',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(texto);
        expect(resultado.risco, NivelRisco.seguro, reason: texto);
        expect(resultado.sinaisDetectados, isEmpty, reason: texto);
      }
    });

    test('não confunde frase com ponto sem espaço ("Consulta cancelada.Amanha") com URL', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Oi Maria, tudo bem.Amanha passo ai para conversar.',
      );
      expect(resultado.risco, NivelRisco.seguro);
      expect(resultado.sinaisDetectados, isEmpty);

      final AnaliseGolpe comCancelada = analisador.analisar(
        'Consulta cancelada.Amanha remarcamos no posto.',
      );
      expect(
        comCancelada.sinaisDetectados,
        isNot(contains(TextosAntigolpe.sinalTldSuspeito)),
      );
    });

    test('não acusa falso positivo em receitas.globo.com, receita.globo.com ou ao-vivo.globo.com', () {
      for (final String url in <String>[
        'https://receitas.globo.com/bolo-de-fuba',
        'https://receita.globo.com/alerta-culinaria',
        'https://ao-vivo.globo.com/jornal',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(
          'Veja esta matéria: $url',
        );
        expect(resultado.risco, NivelRisco.seguro, reason: url);
        expect(resultado.sinaisDetectados, isEmpty, reason: url);
      }
    });

    test('respeita fronteira de palavra para não confundir desenha com senha nem pixel com pix', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Minha neta desenha muito bem e a tela tem um pixel brilhante.',
      );
      expect(resultado.risco, NivelRisco.seguro);
      expect(resultado.sinaisDetectados, isEmpty);
    });

    test('não penaliza lembrete puramente protetivo sobre nunca compartilhar ou pedir senha', () {
      for (final String aviso in <String>[
        'Nunca compartilhe sua senha nem código de verificação com ninguém.',
        'O banco nunca pede sua senha nem código por mensagem.',
        'Eu nunca peço sua senha ou código de 6 dígitos.',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(aviso);
        expect(resultado.risco, NivelRisco.seguro, reason: aviso);
        expect(resultado.sinaisDetectados, isEmpty, reason: aviso);
      }
    });

    test('não confunde frase com palavra acentuada antes de ponto sem espaço ("Cheguei lá.Me liga!") nem Supremo Tribunal Federal com golpe', () {
      for (final String texto in <String>[
        'Cheguei lá.Me liga!',
        'Estou aqui já.Me avisa quando sair.',
        'O Supremo Tribunal Federal divulgou o calendário oficial de sessões.',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(texto);
        expect(resultado.risco, NivelRisco.seguro, reason: texto);
        expect(resultado.sinaisDetectados, isEmpty, reason: texto);
      }
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
      expect(resultado.sinaisDetectados, contains(TextosAntigolpe.sinalIp));
    });

    test('detecta disfarce com @ (userinfo com e sem esquema e @ no início da autoridade) como altoRisco', () {
      for (final String texto in <String>[
        'Acesse https://bb.com.br@golpe-falso.xyz/entrar agora',
        'Acesse bb.com.br@evil.site/login para confirmar',
        'Confira em https://@golpe.xyz/login',
      ]) {
        final AnaliseGolpe r = analisador.analisar(texto);
        expect(r.risco, NivelRisco.altoRisco, reason: texto);
        expect(
          r.sinaisDetectados,
          contains(TextosAntigolpe.sinalArroba),
          reason: texto,
        );
      }
    });

    test('detecta URLs sem esquema após dois-pontos e encurtadores is.gd / rb.gy / lnkd.in', () {
      for (final String texto in <String>[
        'Acesse:bit.ly/abc urgente para desbloquear sua conta',
        'Acesse:is.gd/abc urgente para desbloquear sua conta',
        'Acesse:rb.gy/abc urgente para desbloquear sua conta',
        'Acesse:lnkd.in/abc urgente para desbloquear sua conta',
        'Link:itau-seguro.xyz',
      ]) {
        final AnaliseGolpe r = analisador.analisar(texto);
        expect(r.risco, NivelRisco.altoRisco, reason: texto);
        expect(r.sinaisDetectados, isNotEmpty, reason: texto);
      }
    });

    test('detecta personificação de marca usando wa.me ou a.co como altoRisco', () {
      for (final String texto in <String>[
        'Nubank: sua conta foi bloqueada, desbloqueie em https://wa.me/5511999999999',
        'Banco do Brasil: valide sua conta em https://a.co/d/golpe',
      ]) {
        final AnaliseGolpe r = analisador.analisar(texto);
        expect(r.risco, NivelRisco.altoRisco, reason: texto);
        expect(
          r.sinaisDetectados,
          contains(TextosAntigolpe.sinalMarcaFalsa),
          reason: texto,
        );
      }
    });

    test('detecta instalação do aplicativo de acesso remoto Supremo como altoRisco', () {
      final AnaliseGolpe r = analisador.analisar(
        'Instale o aplicativo Supremo no celular para liberar sua conta.',
      );
      expect(r.risco, NivelRisco.altoRisco);
      expect(
        r.sinaisDetectados,
        contains(TextosAntigolpe.sinalAcessoRemotoOuApk),
      );
    });

    test('detecta barra invertida na autoridade da URL (https://evil.site\\.bb.com.br)', () {
      final AnaliseGolpe resultado = analisador.analisar(
        r'Acesse https://evil.site\.bb.com.br/login',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.sinaisDetectados, contains(TextosAntigolpe.sinalArroba));
      expect(
        resultado.sinaisDetectados,
        contains(TextosAntigolpe.sinalMarcaFalsa),
      );
    });

    test('detecta desofuscação de hxxp[:]//bb.com.br@evil.site antes do esquema', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Acesse hxxp[:]//bb.com.br@evil.site para liberar',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(resultado.sinaisDetectados, contains(TextosAntigolpe.sinalArroba));
    });

    test('detecta homógrafo cirílico / não-ASCII no domínio com e sem esquema (https://itаu.com.br e itаu.com.br)', () {
      for (final String texto in <String>[
        'Acesse https://it\u0430u.com.br para atualizar',
        'Acesse it\u0430u.com.br para atualizar',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(texto);

        expect(resultado.risco, NivelRisco.altoRisco, reason: texto);
        expect(
          resultado.sinaisDetectados,
          contains(TextosAntigolpe.sinalHomografo),
          reason: texto,
        );
      }
    });

    test('remove caracteres invisíveis zero-width e marcas combinantes na análise', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Urg\u200Bente: conta blo\u00ADqueada! Envie sua se\uFEFFnha e co\u0301digo de 6 digitos.',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(
        resultado.sinaisDetectados,
        contains(TextosAntigolpe.sinalUrgencia),
      );
      expect(
        resultado.sinaisDetectados,
        contains(TextosAntigolpe.sinalCredencialOuDinheiro),
      );
    });

    test('detecta domínios impostores compostos (govbr.com, correiosbr.com, meuinss.com, nubankbr.com, caixabr.com, receitafederal.com)', () {
      for (final String host in <String>[
        'https://govbr.com',
        'https://correiosbr.com',
        'https://meuinss.com',
        'https://nubankbr.com',
        'https://caixabr.com',
        'https://receitafederal.com',
      ]) {
        final AnaliseGolpe resultado = analisador.analisar(
          'Confira sua situação em $host',
        );
        expect(resultado.risco, NivelRisco.altoRisco, reason: host);
        expect(
          resultado.sinaisDetectados,
          contains(TextosAntigolpe.sinalMarcaFalsa),
          reason: host,
        );
      }
    });

    test('detecta acesso remoto, .apk e golpe do número novo', () {
      final AnaliseGolpe rRemoto = analisador.analisar(
        'Suporte do banco: instale o AnyDesk ou baixe modulo-seguranca.apk para verificar sua conta.',
      );
      expect(rRemoto.risco, NivelRisco.altoRisco);
      expect(
        rRemoto.sinaisDetectados,
        contains(TextosAntigolpe.sinalAcessoRemotoOuApk),
      );

      final AnaliseGolpe rNumeroNovo = analisador.analisar(
        'Oi mãe, troquei de número! Agenda esse número novo e me faz um PIX urgente para pagar um boleto.',
      );
      expect(rNumeroNovo.risco, NivelRisco.altoRisco);
      expect(
        rNumeroNovo.sinaisDetectados,
        contains(TextosAntigolpe.sinalTrocaDeNumero),
      );
    });

    test('negação por cláusula não desativa detecção quando seguida por pedido real de senha', () {
      final AnaliseGolpe resultado = analisador.analisar(
        'Aviso: nunca compartilhe sua senha com estranhos. Sua conta foi bloqueada, acesse https://golpe.xyz e digite sua senha para liberar conta.',
      );

      expect(resultado.risco, NivelRisco.altoRisco);
      expect(
        resultado.sinaisDetectados,
        contains(TextosAntigolpe.sinalCredencialOuDinheiro),
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
        resultado.sinaisDetectados,
        contains(TextosAntigolpe.sinalEncurtador),
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
