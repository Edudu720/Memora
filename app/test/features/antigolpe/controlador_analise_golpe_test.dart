import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/antigolpe/domain/entidades/analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/servicos/analisador_local_de_golpes.dart';
import 'package:memora/features/antigolpe/presentation/controladores/controlador_analise_golpe.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/l10n/textos_antigolpe.dart';

class _RepositorioFalso implements RepositorioAnaliseGolpe {
  final Future<AnaliseGolpe> Function(String conteudo) aoAnalisar;
  int chamadas = 0;

  _RepositorioFalso(this.aoAnalisar);

  @override
  Future<AnaliseGolpe> analisar(String conteudo) {
    chamadas++;
    return aoAnalisar(conteudo);
  }
}

void main() {
  const AnaliseGolpe resultadoExemplo = AnaliseGolpe(
    risco: NivelRisco.seguro,
    origem: OrigemAnalise.servidorIa,
    titulo: 'Sem sinais claros de golpe',
    explicacao: 'Mensagem comum.',
    orientacoes: <String>['Confirme o remetente.'],
    sinaisDetectados: <String>[],
    analisadoPorIa: true,
  );

  group('ControladorAnaliseGolpe', () {
    test('valida campo vazio e muito longo sem chamar o repositório', () async {
      final _RepositorioFalso repo = _RepositorioFalso(
        (_) async => resultadoExemplo,
      );
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: repo,
      );
      addTearDown(c.dispose);

      await c.analisar('   ');
      expect(c.erroCampo, TextosAntigolpe.erroVazio);
      expect(repo.chamadas, 0);

      await c.analisar('x' * (AnalisadorLocalDeGolpes.limiteCaracteres + 1));
      expect(c.erroCampo, TextosAntigolpe.erroMuitoLongo);
      expect(repo.chamadas, 0);
    });

    test('passa por carregando e entrega resultado ao concluir', () async {
      final Completer<AnaliseGolpe> portao = Completer<AnaliseGolpe>();
      final _RepositorioFalso repo = _RepositorioFalso((_) => portao.future);
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: repo,
      );
      addTearDown(c.dispose);

      final Future<void> futuro = c.analisar('Oi mãe, tudo bem?');
      expect(c.carregando, isTrue);
      expect(c.resultado, isNull);

      portao.complete(resultadoExemplo);
      await futuro;

      expect(c.carregando, isFalse);
      expect(c.erro, isNull);
      expect(c.resultado, resultadoExemplo);
    });

    test('expõe mensagem amigável quando a sessão expira', () async {
      final _RepositorioFalso repo = _RepositorioFalso(
        (_) async =>
            throw const FalhaDeChamadaDaAssistente(FalhaDaAssistente.sessaoExpirada),
      );
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: repo,
      );
      addTearDown(c.dispose);

      await c.analisar('Texto qualquer');

      expect(c.carregando, isFalse);
      expect(c.erro, TextosAntigolpe.sessaoExpirada);
      expect(c.resultado, isNull);
    });

    test('limpar() descarta resposta em voo e zera estado', () async {
      final Completer<AnaliseGolpe> portao = Completer<AnaliseGolpe>();
      final _RepositorioFalso repo = _RepositorioFalso((_) => portao.future);
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: repo,
      );
      addTearDown(c.dispose);

      final Future<void> emVoo = c.analisar('Link suspeito');
      expect(c.carregando, isTrue);

      c.limpar();
      expect(c.carregando, isFalse);
      expect(c.resultado, isNull);

      portao.complete(resultadoExemplo);
      await emVoo;

      expect(c.resultado, isNull);
      expect(c.carregando, isFalse);
    });

    test('colar() trata área de transferência vazia e preenchida', () async {
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: _RepositorioFalso((_) async => resultadoExemplo),
      );
      addTearDown(c.dispose);

      final String? vazio = await c.colar(() async => '   ');
      expect(vazio, isNull);
      expect(c.erroCampo, TextosAntigolpe.erroAreaTransferenciaVazia);

      final String? preenchido = await c.colar(
        () async => 'https://www.gov.br',
      );
      expect(preenchido, 'https://www.gov.br');
      expect(c.erroCampo, isNull);
    });

    test('não notifica após dispose() quando resposta atrasada chega', () async {
      final Completer<AnaliseGolpe> portao = Completer<AnaliseGolpe>();
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: _RepositorioFalso((_) => portao.future),
      );

      final Future<void> emVoo = c.analisar('Oi');
      c.dispose();
      portao.complete(resultadoExemplo);
      await emVoo;
    });
  });
}
