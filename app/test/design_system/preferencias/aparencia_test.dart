import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Repositório em memória, para testar sem tocar no armazenamento do aparelho.
class _RepositorioFalso implements RepositorioPreferenciaAparencia {
  PreferenciaAparencia? salva;
  bool falharAoCarregar = false;
  int gravacoes = 0;

  @override
  Future<PreferenciaAparencia> carregar() async {
    if (falharAoCarregar) throw Exception('armazenamento indisponível');
    return salva ?? PreferenciaAparencia.padrao;
  }

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {
    salva = preferencia;
    gravacoes++;
  }
}

void main() {
  group('Entidade — faixa da ampliação', () {
    test('escala acima do teto é limitada', () {
      const PreferenciaAparencia p = PreferenciaAparencia();
      expect(
        p.copyWith(escalaTexto: 9.0).escalaTexto,
        MemoraDimensoes.escalaTextoMax,
        reason: 'Valor fora da faixa nunca pode chegar a ser persistido.',
      );
    });

    test('escala abaixo do piso é limitada', () {
      const PreferenciaAparencia p = PreferenciaAparencia();
      expect(p.copyWith(escalaTexto: 0.2).escalaTexto,
          MemoraDimensoes.escalaTextoMin);
    });

    test('padrão é seguir o sistema, sem ampliação extra', () {
      expect(PreferenciaAparencia.padrao.tema, EscolhaDeTema.seguirSistema);
      expect(PreferenciaAparencia.padrao.ehPadrao, isTrue);
    });
  });

  group('Pré-visualização antes de confirmar — FR-023', () {
    test('pré-visualizar muda a tela mas NÃO persiste', () async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      c.preVisualizarTema(EscolhaDeTema.altoContraste);

      expect(c.atual.tema, EscolhaDeTema.altoContraste);
      expect(c.confirmada.tema, EscolhaDeTema.seguirSistema);
      expect(repo.gravacoes, 0,
          reason: 'Experimentar não pode gravar. Quem escolhe um tema '
              'ilegível precisa poder voltar sem depender de ler a tela.');
    });

    test('confirmar persiste a pré-visualização', () async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      c.preVisualizarTema(EscolhaDeTema.escuro);
      await c.confirmar();

      expect(c.confirmada.tema, EscolhaDeTema.escuro);
      expect(repo.salva?.tema, EscolhaDeTema.escuro);
      expect(c.temPreVisualizacao, isFalse);
    });

    test('descartar volta ao que estava salvo', () async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      c.preVisualizarTema(EscolhaDeTema.altoContraste);
      c.descartar();

      expect(c.atual.tema, EscolhaDeTema.seguirSistema);
      expect(repo.gravacoes, 0);
    });

    test('confirmar sem pré-visualização não grava nada', () async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      await c.confirmar();

      expect(repo.gravacoes, 0);
    });
  });

  group('Voltar ao padrão — FR-022', () {
    test('restaura tudo e persiste em um único passo', () async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      c.preVisualizarTema(EscolhaDeTema.altoContraste);
      c.preVisualizarEscalaTexto(MemoraDimensoes.escalaTextoMax);
      await c.voltarAoPadrao();

      expect(c.atual, PreferenciaAparencia.padrao);
      expect(repo.salva, PreferenciaAparencia.padrao);
      expect(c.temPreVisualizacao, isFalse,
          reason: 'A saída de emergência não pode exigir uma confirmação '
              'adicional de quem já se perdeu.');
    });
  });

  group('Persistência — FR-021', () {
    test('carrega a preferência salva', () async {
      final _RepositorioFalso repo = _RepositorioFalso()
        ..salva = const PreferenciaAparencia(
          tema: EscolhaDeTema.escuro,
          escalaTexto: 1.4,
        );
      final ControladorAparencia c = ControladorAparencia(repo);

      await c.carregar();

      expect(c.atual.tema, EscolhaDeTema.escuro);
      expect(c.atual.escalaTexto, 1.4);
    });

    test('falha de leitura cai no padrão sem derrubar o aplicativo', () async {
      final _RepositorioFalso repo = _RepositorioFalso()
        ..falharAoCarregar = true;
      final ControladorAparencia c = ControladorAparencia(repo);

      await c.carregar();

      expect(c.atual, PreferenciaAparencia.padrao,
          reason: 'Não conseguir ler uma preferência visual jamais pode '
              'impedir alguém de usar o Memora.');
    });
  });

  group('Escolha explícita prevalece sobre o sistema — FR-020', () {
    test('seguir sistema usa ThemeMode.system', () {
      final AparenciaResolvida a =
          AparenciaResolvida.de(PreferenciaAparencia.padrao);
      expect(a.modo, ThemeMode.system);
    });

    test('tema claro escolhido ignora o modo escuro do aparelho', () {
      final AparenciaResolvida a = AparenciaResolvida.de(
        const PreferenciaAparencia(tema: EscolhaDeTema.claro),
      );
      expect(a.modo, ThemeMode.light);
      expect(a.temaClaro, a.temaEscuro,
          reason: 'Escolha explícita vale independentemente do aparelho.');
    });

    test('alto contraste vale mesmo com o sistema em modo claro', () {
      final AparenciaResolvida a = AparenciaResolvida.de(
        const PreferenciaAparencia(tema: EscolhaDeTema.altoContraste),
      );
      final MemoraTheme? tema =
          a.temaClaro.extension<MemoraTheme>();
      expect(tema?.id, MemoraTemaId.altoContraste);
      expect(tema?.contrasteMinimoTexto, 7.0);
    });
  });

  group('Ampliação combinada — FR-019', () {
    testWidgets('multiplica sistema e aplicativo, limitada ao teto',
        (WidgetTester tester) async {
      late double efetiva;

      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AmpliacaoDeTexto(
              fatorDoAplicativo: 1.4,
              child: Builder(
                builder: (BuildContext context) {
                  efetiva = MediaQuery.textScalerOf(context).scale(1);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      // 1.5 x 1.4 = 2.1, acima do teto.
      expect(efetiva, MemoraDimensoes.escalaTextoMax,
          reason: 'Somar as duas ampliações sem teto estoura o layout.');
    });

    testWidgets('dentro do teto, o produto é preservado',
        (WidgetTester tester) async {
      late double efetiva;

      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
            child: AmpliacaoDeTexto(
              fatorDoAplicativo: 1.4,
              child: Builder(
                builder: (BuildContext context) {
                  efetiva = MediaQuery.textScalerOf(context).scale(1);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(efetiva, closeTo(1.68, 0.001));
    });
  });

  group('Tamanhos de letra oferecidos', () {
    test('mapeiam para o mais próximo do valor salvo', () {
      expect(TamanhoDeLetra.maisProximoDe(1.0), TamanhoDeLetra.normal);
      expect(TamanhoDeLetra.maisProximoDe(1.4), TamanhoDeLetra.grande);
      expect(TamanhoDeLetra.maisProximoDe(2.0), TamanhoDeLetra.muitoGrande);
      expect(TamanhoDeLetra.maisProximoDe(1.9), TamanhoDeLetra.muitoGrande);
    });
  });
}
