import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A data de nascimento do Perfil, sem tela (T123, FR-042c): a validação, a
/// idade calculada na exibição e a guarda por conta.
void main() {
  final DateTime hoje = DateTime(2026, 10, 2);

  ResultadoDaData validar(String d, String m, String a, {DateTime? em}) =>
      DataDeNascimento.validar(dia: d, mes: m, ano: a, hoje: em ?? hoje);

  group('Validação', () {
    test('aceita uma data comum', () {
      final ResultadoDaData r = validar('15', '3', '1952');
      expect(r.problema, isNull);
      expect(r.data, isNotNull);
      expect(r.data!.dia, 15);
      expect(r.data!.mes, 3);
      expect(r.data!.ano, 1952);
    });

    test('aceita o dia de hoje (idade zero)', () {
      expect(validar('2', '10', '2026').problema, isNull);
    });

    test('recusa o que falta ou não é número', () {
      expect(validar('', '3', '1952').problema, ProblemaDaData.incompleta);
      expect(validar('15', '', '1952').problema, ProblemaDaData.incompleta);
      expect(validar('15', '3', '').problema, ProblemaDaData.incompleta);
      expect(validar('1x', '3', '1952').problema, ProblemaDaData.incompleta);
    });

    test('recusa ano com menos de quatro números', () {
      expect(validar('15', '3', '52').problema, ProblemaDaData.anoCurto);
      expect(validar('15', '3', '195').problema, ProblemaDaData.anoCurto);
    });

    test('recusa data que não existe no calendário', () {
      expect(validar('31', '2', '1952').problema, ProblemaDaData.impossivel);
      expect(validar('30', '2', '1952').problema, ProblemaDaData.impossivel);
      expect(validar('15', '13', '1952').problema, ProblemaDaData.impossivel);
      expect(validar('0', '3', '1952').problema, ProblemaDaData.impossivel);
      expect(validar('31', '4', '1952').problema, ProblemaDaData.impossivel);
      // 1953 não é bissexto: 29/02 não existe.
      expect(validar('29', '2', '1953').problema, ProblemaDaData.impossivel);
    });

    test('aceita 29 de fevereiro em ano bissexto', () {
      expect(validar('29', '2', '1952').problema, isNull);
    });

    test('recusa data futura', () {
      expect(validar('3', '10', '2026').problema, ProblemaDaData.futura);
      expect(validar('1', '1', '2027').problema, ProblemaDaData.futura);
      expect(validar('1', '1', '2999').problema, ProblemaDaData.futura);
    });

    test('recusa mais de 120 anos', () {
      // Em 02/10/2026, quem nasceu em 02/10/1906 faz exatamente 120: vale.
      expect(validar('2', '10', '1906').problema, isNull);
      // Quem nasceu em 02/10/1905 faz 121: passou do limite.
      expect(validar('2', '10', '1905').problema, ProblemaDaData.antiga);
      expect(validar('1', '1', '1850').problema, ProblemaDaData.antiga);
    });
  });

  group('Idade, calculada na exibição', () {
    DataDeNascimento de(String d, String m, String a) => validar(d, m, a).data!;

    test('antes do aniversário do ano, ainda é um ano a menos', () {
      // 15/03/1952: em 02/10/2026 já fez 74.
      expect(de('15', '3', '1952').idadeEm(DateTime(2026, 10, 2)), 74);
      // 15/12/1952: em 02/10/2026 ainda não fez 74.
      expect(de('15', '12', '1952').idadeEm(DateTime(2026, 10, 2)), 73);
    });

    test('no dia do aniversário já conta o ano novo', () {
      final DataDeNascimento d = de('2', '10', '1952');
      expect(d.idadeEm(DateTime.parse('2026-10-01')), 73);
      expect(d.idadeEm(DateTime(2026, 10, 2)), 74);
    });

    test('29 de fevereiro faz anos em 1º de março nos anos comuns', () {
      final DataDeNascimento d = de('29', '2', '1952');
      expect(d.idadeEm(DateTime(2027, 2, 28)), 74);
      expect(d.idadeEm(DateTime.parse('2027-03-01')), 75);
      expect(d.idadeEm(DateTime(2028, 2, 29)), 76);
    });

    test('muda sozinha com o tempo: a idade nunca é guardada', () {
      final DataDeNascimento d = de('2', '10', '1952');
      expect(d.paraArmazenar(), '1952-10-02');
      expect(d.idadeEm(DateTime(2027, 10, 2)), 75);
    });
  });

  group('Guarda local, por conta', () {
    late DataDeNascimentoLocal armazenamento;
    late SharedPreferences preferencias;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      preferencias = await SharedPreferences.getInstance();
      armazenamento = DataDeNascimentoLocal(preferencias);
    });

    final DataDeNascimento ana = DataDeNascimento.deArmazenado('1952-03-15')!;
    final DataDeNascimento bia = DataDeNascimento.deArmazenado('1980-07-01')!;

    test('grava e lê', () async {
      expect(await armazenamento.ler('conta-a'), isNull);
      await armazenamento.guardar('conta-a', ana);
      expect(await armazenamento.ler('conta-a'), ana);
    });

    test('guardar de novo troca a data', () async {
      await armazenamento.guardar('conta-a', ana);
      await armazenamento.guardar('conta-a', bia);
      expect(await armazenamento.ler('conta-a'), bia);
    });

    test('apaga só a da conta pedida', () async {
      await armazenamento.guardar('conta-a', ana);
      await armazenamento.guardar('conta-b', bia);
      await armazenamento.apagar('conta-a');
      expect(await armazenamento.ler('conta-a'), isNull);
      expect(await armazenamento.ler('conta-b'), bia);
    });

    test('a conta B não vê a data da conta A', () async {
      await armazenamento.guardar('conta-a', ana);
      expect(await armazenamento.ler('conta-b'), isNull);
    });

    test('uma conta cujo id é prefixo do outro não se mistura', () async {
      await armazenamento.guardar('conta-1', ana);
      expect(await armazenamento.ler('conta-12'), isNull);
      expect(await armazenamento.ler('conta-'), isNull);
    });

    test('valor corrompido vira ausência, não erro', () async {
      await preferencias.setString('${DataDeNascimentoLocal.prefixo}c', 'lixo');
      expect(await armazenamento.ler('c'), isNull);
      await preferencias.setString(
        '${DataDeNascimentoLocal.prefixo}c',
        '1953-02-29',
      );
      expect(await armazenamento.ler('c'), isNull);
    });

    test(
      'guarda só a data, e em armazenamento comum com prefixo próprio',
      () async {
        await armazenamento.guardar('conta-a', ana);
        expect(preferencias.getKeys(), <String>{
          '${DataDeNascimentoLocal.prefixo}conta-a',
        });
        expect(
          preferencias.getString('${DataDeNascimentoLocal.prefixo}conta-a'),
          '1952-03-15',
        );
      },
    );

    for (final String vazio in <String>['', '   ']) {
      test("id vazio ('$vazio') não guarda e não lê", () async {
        expect(() => armazenamento.guardar(vazio, ana), throwsArgumentError);
        expect(preferencias.getKeys(), isEmpty);

        // Mesmo que algo tenha caído na chave sem id, ninguém o lê.
        await preferencias.setString(
          '${DataDeNascimentoLocal.prefixo}$vazio',
          '1952-03-15',
        );
        expect(await armazenamento.ler(vazio), isNull);
      });
    }

    test('esquecer o aparelho apaga a de todas as contas, e só ela', () async {
      await preferencias.setString('memora.ultimo_identificador', 'x@y.com');
      await armazenamento.guardar('conta-a', ana);
      await armazenamento.guardar('conta-b', bia);

      await armazenamento.esquecerDoAparelho();

      expect(await armazenamento.ler('conta-a'), isNull);
      expect(await armazenamento.ler('conta-b'), isNull);
      expect(
        preferencias.getString('memora.ultimo_identificador'),
        'x@y.com',
        reason: 'o que não é data de nascimento não é da conta deste portão',
      );
    });
  });

  group('A guarda em memória se comporta como a local', () {
    final DataDeNascimento ana = DataDeNascimento.deArmazenado('1952-03-15')!;

    for (final String vazio in <String>['', '   ']) {
      test("id vazio ('$vazio') recusa, não guarda e não lê", () async {
        final DataDeNascimentoEmMemoria memoria = DataDeNascimentoEmMemoria();
        await expectLater(memoria.guardar(vazio, ana), throwsArgumentError);
        expect(await memoria.ler(vazio), isNull);
        await memoria.apagar(vazio);
        // E nada vazou para uma conta de verdade.
        expect(await memoria.ler('conta-a'), isNull);
      });
    }
  });
}
