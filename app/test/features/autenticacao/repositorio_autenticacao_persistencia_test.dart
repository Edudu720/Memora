import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Persistência local de contas no RepositorioAutenticacaoSimulado', () {
    test('conta cadastrada persiste e pode ser usada em uma nova instância', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Primeira execução do app: usuário cadastra uma conta
      final RepositorioAutenticacaoSimulado repo1 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      final ResultadoAutenticacao cad = await repo1.cadastrar(
        const DadosDeCadastro(
          nomeTratamento: 'Seu José',
          tipoCanal: TipoCanal.email,
          canal: 'seu.jose@email.com',
          senha: 'senhaSegura123',
        ),
      );

      expect(cad, isA<AutenticacaoConcluida>());

      // App é fechado e reaberto (nova instância com as mesmas preferências)
      final RepositorioAutenticacaoSimulado repo2 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      // A conta cadastrada deve existir na nova instância
      expect(repo2.identificadoresConhecidos, contains('seu.jose@email.com'));

      // E o login com a senha cadastrada deve ser bem-sucedido
      final ResultadoAutenticacao login = await repo2.entrar(
        const DadosDeEntrada(
          identificador: 'seu.jose@email.com',
          senha: 'senhaSegura123',
        ),
      );

      expect(login, isA<AutenticacaoConcluida>());
      final PessoaAutenticada pessoa =
          (login as AutenticacaoConcluida).pessoa;
      expect(pessoa.nomeTratamento, 'Seu José');
    });

    test('renovação automática de sessão restaura o usuário ativo após reinício', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final RepositorioAutenticacaoSimulado repo1 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      await repo1.cadastrar(
        const DadosDeCadastro(
          nomeTratamento: 'Dona Carmem',
          tipoCanal: TipoCanal.telefone,
          canal: '11987654321',
          senha: 'minhaFraseSegura123',
        ),
      );

      // App reaberto: renovação de sessão restaura Dona Carmem
      final RepositorioAutenticacaoSimulado repo2 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      final ResultadoAutenticacao renovado = await repo2.renovarSessao();
      expect(renovado, isA<AutenticacaoConcluida>());
      expect(
        (renovado as AutenticacaoConcluida).pessoa.nomeTratamento,
        'Dona Carmem',
      );
    });

    test('ao sair da conta, a renovação de sessão é desativada', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final RepositorioAutenticacaoSimulado repo1 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      await repo1.cadastrar(
        const DadosDeCadastro(
          nomeTratamento: 'Dona Carmem',
          tipoCanal: TipoCanal.email,
          canal: 'carmem@email.com',
          senha: 'minhaFraseSegura123',
        ),
      );

      // Usuário encerra a sessão
      await repo1.encerrarSessao();

      // App reaberto: renovação falha e pede login
      final RepositorioAutenticacaoSimulado repo2 =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      final ResultadoAutenticacao renovado = await repo2.renovarSessao();
      expect(renovado, isA<AutenticacaoFalhou>());

      // Mas o login com senha ainda funciona normalmente
      final ResultadoAutenticacao login = await repo2.entrar(
        const DadosDeEntrada(
          identificador: 'carmem@email.com',
          senha: 'minhaFraseSegura123',
        ),
      );
      expect(login, isA<AutenticacaoConcluida>());
    });

    test('conta padrão de demonstração fica disponível quando não há contas salvas', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final RepositorioAutenticacaoSimulado repo =
          RepositorioAutenticacaoSimulado(
        preferencias: prefs,
        demora: Duration.zero,
      );

      expect(repo.identificadoresConhecidos, contains('dona.maria@memora.app'));

      final ResultadoAutenticacao login = await repo.entrar(
        const DadosDeEntrada(
          identificador: 'dona.maria@memora.app',
          senha: 'senha123456',
        ),
      );
      expect(login, isA<AutenticacaoConcluida>());
    });
  });
}

