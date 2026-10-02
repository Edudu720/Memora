import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/domain/monitor_de_sessao.dart';

/// Prazos minúsculos para a regra caber em milissegundos.
///
/// Com os valores reais — 30 minutos e 2 de aviso — este arquivo levaria meia
/// hora por caso, e ninguém rodaria. É a mesma razão pela qual o backend troca
/// o `Clock` inteiro em `BloqueioProgressivoNoLoginTest`.
const Duration _inatividade = Duration(milliseconds: 120);
const Duration _aviso = Duration(milliseconds: 40);

/// Um pouco além de um instante, para o temporizador ter chance de disparar.
Future<void> _passar(Duration tempo) =>
    Future<void>.delayed(tempo + const Duration(milliseconds: 15));

void main() {
  group('Monitor de sessão — FR-017', () {
    test('avisa antes de encerrar, nunca junto', () async {
      final List<String> eventos = <String>[];

      final MonitorDeSessao monitor = MonitorDeSessao(
        inatividade: _inatividade,
        aviso: _aviso,
        aoAvisar: (int _) => eventos.add('aviso'),
        aoExpirar: () => eventos.add('expirou'),
      )..iniciar();

      // No instante do aviso: avisou, mas ainda não expirou.
      await _passar(_inatividade - _aviso);
      expect(
        eventos,
        <String>['aviso'],
        reason: 'Sessão que cai sem avisar é indistinguível de defeito, e '
            '"o aplicativo me expulsou" é motivo para desinstalar.',
      );

      await _passar(_aviso);
      expect(eventos, <String>['aviso', 'expirou']);

      monitor.dispose();
    });

    test('o aviso diz quantos segundos ainda restam', () async {
      int? segundosAnunciados;

      final MonitorDeSessao monitor = MonitorDeSessao(
        inatividade: const Duration(milliseconds: 1200),
        aviso: const Duration(seconds: 1),
        aoAvisar: (int s) => segundosAnunciados = s,
        aoExpirar: () {},
      )..iniciar();

      await _passar(const Duration(milliseconds: 200));

      expect(
        segundosAnunciados,
        1,
        reason: 'A tela precisa do número para escrever a frase. Um aviso que '
            'só diz "vou te desconectar" deixa a pessoa sem saber se corre ou '
            'se termina de ler.',
      );

      monitor.dispose();
    });

    test('sem prazo informado, vale 30 minutos com 2 de aviso', () {
      final MonitorDeSessao monitor = MonitorDeSessao(
        aoAvisar: (int _) {},
        aoExpirar: () {},
      );

      expect(monitor.inatividade, const Duration(minutes: 30));
      expect(
        monitor.aviso,
        const Duration(minutes: 2),
        reason: 'Um minuto, o padrão de aplicativo bancário, expulsa '
            'exatamente quem este produto atende.',
      );

      monitor.dispose();
    });

    test('atividade zera a contagem', () async {
      final List<String> eventos = <String>[];

      final MonitorDeSessao monitor = MonitorDeSessao(
        inatividade: _inatividade,
        aviso: _aviso,
        aoAvisar: (int _) => eventos.add('aviso'),
        aoExpirar: () => eventos.add('expirou'),
      )..iniciar();

      // Mexe pouco antes do aviso, três vezes seguidas.
      for (int i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        monitor.registrarAtividade();
      }

      expect(
        eventos,
        isEmpty,
        reason: 'Quem está usando o Memora não pode ser interrompido. A FR-017 '
            'conta inatividade, não tempo desde o login.',
      );

      monitor.dispose();
    });

    test('responder ao aviso mantém a pessoa dentro', () async {
      final List<String> eventos = <String>[];

      final MonitorDeSessao monitor = MonitorDeSessao(
        inatividade: _inatividade,
        aviso: _aviso,
        aoAvisar: (int _) => eventos.add('aviso'),
        aoExpirar: () => eventos.add('expirou'),
      )..iniciar();

      await _passar(_inatividade - _aviso);
      expect(eventos, <String>['aviso']);
      expect(monitor.avisando, isTrue);

      // É isto que faz o "estou aqui, pode continuar" significar alguma coisa.
      monitor.registrarAtividade();
      expect(monitor.avisando, isFalse);

      await _passar(_aviso);
      expect(
        eventos,
        <String>['aviso'],
        reason: 'Expirar depois de a pessoa responder que está ali torna o '
            'botão do aviso uma mentira.',
      );

      monitor.dispose();
    });

    test('parar encerra a contagem sem expirar', () async {
      final List<String> eventos = <String>[];

      final MonitorDeSessao monitor = MonitorDeSessao(
        inatividade: _inatividade,
        aviso: _aviso,
        aoAvisar: (int _) => eventos.add('aviso'),
        aoExpirar: () => eventos.add('expirou'),
      )..iniciar();

      monitor.parar();
      await _passar(_inatividade);

      expect(
        eventos,
        isEmpty,
        reason: 'Quem saiu por vontade própria não pode receber depois um '
            'aviso de que a sessão vai cair.',
      );

      monitor.dispose();
    });

    test('aviso que não cabe antes da expiração é recusado na construção', () {
      expect(
        () => MonitorDeSessao(
          inatividade: const Duration(minutes: 5),
          aviso: const Duration(minutes: 5),
          aoAvisar: (int _) {},
          aoExpirar: () {},
        ),
        throwsA(isA<AssertionError>()),
        reason: 'Aviso simultâneo à expiração desconectaria a pessoa no mesmo '
            'instante em que ela soubesse que isso ia acontecer.',
      );
    });
  });
}
