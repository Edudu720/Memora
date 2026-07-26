import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';

/// Conta quantas vezes o cadastro foi efetivamente enviado.
class _RepositorioContador implements RepositorioAutenticacao {
  int chamadas = 0;

  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) async {
    chamadas++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const AutenticacaoConcluida(
      PessoaAutenticada(id: 'x', nomeTratamento: 'Ana'),
    );
  }
}

/// Guarda os dados recebidos, para verificar a normalização.
class _RepositorioEspiao implements RepositorioAutenticacao {
  DadosDeCadastro? recebidos;

  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) async {
    recebidos = dados;
    return const AutenticacaoConcluida(
      PessoaAutenticada(id: 'x', nomeTratamento: 'Ana'),
    );
  }
}

ControladorCadastro _preenchido(RepositorioAutenticacao repo) {
  return ControladorCadastro(repo)
    ..informarNome('Ana')
    ..informarCanal('ana@email.com')
    ..informarSenha('uma frase que so eu lembro');
}

void main() {
  group('Política de senha — comprimento sobre complexidade (FR-042)', () {
    test('senha curta é recusada', () {
      final ControladorCadastro c =
          ControladorCadastro(RepositorioAutenticacaoSimulado())
            ..informarSenha('curta');

      expect(c.senhaValida, isFalse);
    });

    test('frase longa e simples é aceita', () {
      final ControladorCadastro c =
          ControladorCadastro(RepositorioAutenticacaoSimulado())
            ..informarSenha('minha cachorra chama pipoca');

      expect(
        c.senhaValida,
        isTrue,
        reason: 'Exigir maiúscula, número e símbolo leva pessoas idosas a '
            'anotar a senha em papel, o que piora a segurança real.',
      );
    });

    test('senha notoriamente comum é recusada mesmo sendo longa', () {
      final ControladorCadastro c =
          ControladorCadastro(RepositorioAutenticacaoSimulado())
            ..informarSenha('1234567890');

      expect(c.senhaValida, isFalse);
    });
  });

  group('Validação de canal (decisão D1)', () {
    test('e-mail sem arroba não habilita o envio', () {
      final ControladorCadastro c = _preenchido(RepositorioAutenticacaoSimulado())
        ..informarCanal('ana.email.com');

      expect(c.podeEnviar, isFalse);
    });

    test('telefone com poucos dígitos não habilita o envio', () {
      final ControladorCadastro c = _preenchido(RepositorioAutenticacaoSimulado())
        ..escolherTipoCanal(TipoCanal.telefone)
        ..informarCanal('9999');

      expect(c.podeEnviar, isFalse);
    });

    test('trocar o tipo de canal limpa o valor digitado', () {
      final ControladorCadastro c = _preenchido(RepositorioAutenticacaoSimulado())
        ..escolherTipoCanal(TipoCanal.telefone);

      expect(
        c.canal,
        isEmpty,
        reason: 'Manter o e-mail no campo de telefone confunde e gera um erro '
            'que a pessoa não entende.',
      );
    });
  });

  group('Erros só aparecem depois da tentativa (FR-005)', () {
    test('não acusa erro enquanto a pessoa ainda está digitando', () {
      final ControladorCadastro c =
          ControladorCadastro(RepositorioAutenticacaoSimulado())
            ..informarCanal('an');

      expect(
        c.erroCanal,
        isNull,
        reason: 'Acusar erro a cada tecla digitada faz a pessoa achar que '
            'está errando o tempo todo.',
      );
    });

    test('acusa erro depois de tentar enviar', () async {
      final ControladorCadastro c =
          ControladorCadastro(RepositorioAutenticacaoSimulado())
            ..informarNome('Ana')
            ..informarCanal('ana.email.com');

      await c.enviar();

      expect(c.erroCanal, isNotNull);
    });
  });

  group('Toque duplo não cria duas contas', () {
    test('envios concorrentes resultam em uma única chamada', () async {
      final _RepositorioContador repo = _RepositorioContador();
      final ControladorCadastro c = _preenchido(repo);

      await Future.wait(<Future<void>>[c.enviar(), c.enviar()]);

      expect(
        repo.chamadas,
        1,
        reason: 'Mão trêmula gera toque duplo com facilidade. Duas contas '
            'para a mesma pessoa é um problema que ela não sabe resolver.',
      );
    });
  });

  group('Normalização antes de enviar', () {
    test('canal vai em minúsculas e sem espaços', () async {
      final _RepositorioEspiao espiao = _RepositorioEspiao();
      final ControladorCadastro c = _preenchido(espiao)
        ..informarCanal('  ANA@Email.COM  ');

      await c.enviar();

      expect(espiao.recebidos!.canal, 'ana@email.com');
    });

    test('modo assistido é informado ao servidor (decisão D3)', () async {
      final _RepositorioEspiao espiao = _RepositorioEspiao();
      final ControladorCadastro c = _preenchido(espiao)
        ..definirModoAssistido(true);

      await c.enviar();

      expect(espiao.recebidos!.modoAssistido, isTrue);
    });
  });

  group('Recuperação de erro', () {
    test('tentar novamente preserva os dados digitados (FR-006)', () async {
      final ControladorCadastro c = _preenchido(
        RepositorioAutenticacaoSimulado(
          demora: Duration.zero,
          falhaForcada: FalhaAutenticacao.semConexao,
        ),
      );

      await c.enviar();
      expect(c.estado, EstadoCadastro.comErro);

      c.tentarNovamente();

      expect(c.estado, EstadoCadastro.preenchendo);
      expect(c.nome, 'Ana');
      expect(c.canal, 'ana@email.com');
      expect(c.podeEnviar, isTrue);
    });
  });
}
