import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/services/preferencias/repositorio_preferencia_aparencia_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('Reduzir movimento e paleta — FR-039, FR-039a', () {
    test('o padrão não reduz movimento: só a configuração do sistema vale', () {
      expect(PreferenciaAparencia.padrao.reduzirMovimento, isFalse);
      expect(
        PreferenciaAparencia.padrao.paleta,
        PreferenciaAparencia.paletaPadrao,
      );
    });

    test(
      'reduzir movimento tira a preferência do padrão, e voltar o repõe',
      () {
        const PreferenciaAparencia p = PreferenciaAparencia();
        expect(p.copyWith(reduzirMovimento: true).ehPadrao, isFalse);
        expect(p.copyWith(reduzirMovimento: true).reduzirMovimento, isTrue);
        expect(
          p.copyWith(reduzirMovimento: true).copyWith(reduzirMovimento: false),
          PreferenciaAparencia.padrao,
        );
      },
    );

    test('a igualdade enxerga os dois campos novos', () {
      expect(
        const PreferenciaAparencia(reduzirMovimento: true),
        isNot(PreferenciaAparencia.padrao),
      );
      expect(
        const PreferenciaAparencia(reduzirMovimento: true).hashCode,
        isNot(PreferenciaAparencia.padrao.hashCode),
      );
    });

    test('paleta que não existe volta ao padrão', () {
      const PreferenciaAparencia p = PreferenciaAparencia();
      expect(
        p.copyWith(paleta: 'verde-que-nao-existe').paleta,
        PreferenciaAparencia.paletaPadrao,
      );
      expect(
        PreferenciaAparencia.paletaValida(null),
        PreferenciaAparencia.paletaPadrao,
      );
      expect(
        PreferenciaAparencia.paletaValida(''),
        PreferenciaAparencia.paletaPadrao,
      );
      expect(
        PreferenciaAparencia.paletaValida(PreferenciaAparencia.paletaPadrao),
        PreferenciaAparencia.paletaPadrao,
      );
    });

    test('pré-visualizar reduzir movimento aplica na hora e não grava', () {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);

      c.preVisualizarReducaoDeMovimento(reduzir: true);

      expect(c.atual.reduzirMovimento, isTrue);
      expect(c.confirmada.reduzirMovimento, isFalse);
      expect(repo.gravacoes, 0);

      c.descartar();
      expect(c.atual.reduzirMovimento, isFalse, reason: 'desfazer volta');
    });

    test(
      'confirmar persiste reduzir movimento; voltar ao padrão o desfaz',
      () async {
        final _RepositorioFalso repo = _RepositorioFalso();
        final ControladorAparencia c = ControladorAparencia(repo);

        c.preVisualizarReducaoDeMovimento(reduzir: true);
        await c.confirmar();
        expect(repo.salva?.reduzirMovimento, isTrue);

        await c.voltarAoPadrao();
        expect(repo.salva?.reduzirMovimento, isFalse);
      },
    );
  });

  group('Persistência no aparelho — o repositório de verdade', () {
    Future<RepositorioPreferenciaAparenciaLocal> abrir(
      Map<String, Object> inicial,
    ) async {
      SharedPreferences.setMockInitialValues(inicial);
      return RepositorioPreferenciaAparenciaLocal.abrir();
    }

    test('sem nada guardado, devolve o padrão', () async {
      final RepositorioPreferenciaAparenciaLocal repo = await abrir(
        <String, Object>{},
      );
      expect(await repo.carregar(), PreferenciaAparencia.padrao);
    });

    test('guarda e lê tema, ampliação, movimento e paleta', () async {
      final RepositorioPreferenciaAparenciaLocal repo = await abrir(
        <String, Object>{},
      );
      const PreferenciaAparencia p = PreferenciaAparencia(
        tema: EscolhaDeTema.altoContraste,
        escalaTexto: 1.4,
        reduzirMovimento: true,
      );

      await repo.salvar(p);

      expect(await repo.carregar(), p);
    });

    test('reduzir movimento sobrevive a fechar e abrir o aplicativo', () async {
      final RepositorioPreferenciaAparenciaLocal repo = await abrir(
        <String, Object>{},
      );
      await repo.salvar(const PreferenciaAparencia(reduzirMovimento: true));

      // Outra instância sobre o mesmo armazenamento: é o aplicativo reaberto.
      final RepositorioPreferenciaAparenciaLocal reaberto =
          await RepositorioPreferenciaAparenciaLocal.abrir();

      expect((await reaberto.carregar()).reduzirMovimento, isTrue);
    });

    test(
      'paleta desconhecida volta ao padrão, sem derrubar a leitura',
      () async {
        final RepositorioPreferenciaAparenciaLocal repo =
            await abrir(<String, Object>{
              'aparencia.paleta': 'cor-de-uma-versao-futura',
              'aparencia.tema': 'escuro',
            });

        final PreferenciaAparencia lida = await repo.carregar();

        expect(lida.paleta, PreferenciaAparencia.paletaPadrao);
        expect(
          lida.tema,
          EscolhaDeTema.escuro,
          reason: 'o resto é lido normalmente',
        );
      },
    );

    test('tema desconhecido volta ao padrão', () async {
      final RepositorioPreferenciaAparenciaLocal repo = await abrir(
        <String, Object>{'aparencia.tema': 'tema-que-nao-existe'},
      );

      expect((await repo.carregar()).tema, PreferenciaAparencia.padrao.tema);
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
