import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/data/compartilhar.dart';
import 'package:memora/features/ajuda/domain/assunto_de_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_ajuda.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/apresentacao/presentation/fluxo_apresentacao.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_login.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_recuperacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_confirmar_canal.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_de_volta.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_entrega_do_aparelho.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_primeira_entrada.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_recuperacao.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/configuracoes/presentation/tela_configuracoes.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/perfil/presentation/secao_idade.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../features/autenticacao/dubles_autenticacao.dart';
import '../features/autenticacao/fluxo_dentro_da_conta.dart';
import '../suporte/aparelhos.dart';
import '../suporte/fonte.dart';

/// O álbum de telas completo (T043, T101, R13 da feature 004).
///
/// ## Para que serve
///
/// Existe para a **revisão de design** (SC-005) olhar todas as telas da Feature
/// 004 e as telas fora do wireframe redesenhadas na T099 lado a lado com o
/// wireframe, sem montar emulador nem aparelho. Cada tela é desenhada nos três
/// temas (`claro`, `escuro`, `altoContraste`), **com a Atkinson Hyperlegible
/// Next carregada**, e salva como PNG em `build/album/<tema>/`.
///
/// ## O que ele **não** faz
///
/// **Não compara nada.** Não é teste de *golden*: o motor de texto do Windows
/// e o do Linux (o CI) desenham o mesmo texto diferente, e um portão que
/// reprova por motivo que não é defeito ensina a equipe a ignorá-lo (R13).
/// Passa quando consegue desenhar e salvar todas as telas; quem decide se está
/// bonito é gente.
///
/// ## Como rodar
///
/// ```powershell
/// cd app; flutter test test/album
/// ```
///
/// As imagens ficam em `app/build/album/<tema>/`, que o Git ignora.
void main() {
  const Size aparelho = referencia;
  final Directory pasta = Directory('build/album');

  setUpAll(() async {
    await carregarAtkinson();
    await _carregarIcones();
    if (pasta.existsSync()) pasta.deleteSync(recursive: true);
  });

  /// Espera as ilustrações (SVG) carregarem com o relógio real.
  Future<void> esperarOsDesenhos(WidgetTester t) async {
    for (int i = 0; i < 2; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await t.pump(const Duration(milliseconds: 40));
    }
  }

  /// Fotografa o que está dentro de [chave] e grava em [arquivo].
  Future<File> salvar(
    WidgetTester t,
    GlobalKey chave,
    MemoraTemaId tema,
    String nomeArquivo,
  ) async {
    final File arquivo = File('${pasta.path}/${tema.name}/$nomeArquivo');
    await esperarOsDesenhos(t);
    await t.runAsync(() async {
      final RenderRepaintBoundary limite =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image imagem = await limite.toImage(pixelRatio: 2);
      final ByteData? bytes = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      expect(
        bytes,
        isNotNull,
        reason: 'não consegui codificar ${arquivo.path}',
      );
      await arquivo.parent.create(recursive: true);
      await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
    });
    return arquivo;
  }

  /// Monta uma tela fora da conta (sem barra inferior) dentro de um
  /// `RepaintBoundary` e a fotografa.
  Future<File> fotografarTelaIsolada(
    WidgetTester t, {
    required MemoraTemaId tema,
    required String nomeArquivo,
    required Widget tela,
  }) async {
    vestir(t, aparelho);
    final GlobalKey chave = GlobalKey(debugLabel: 'isolada.$nomeArquivo');
    await t.pumpWidget(
      RepaintBoundary(
        key: chave,
        child: EscopoAparencia(
          controlador: ControladorAparencia(PreferenciaEmMemoria()),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TemasMemora.porId(tema),
            home: tela,
          ),
        ),
      ),
    );
    await FluxoDentroDaConta.avancar(t);
    return salvar(t, chave, tema, nomeArquivo);
  }

  for (final MemoraTemaId tema in MemoraTemaId.values) {
    testWidgets(
      'renderiza e salva as 30 telas do álbum no tema ${tema.name} (T101)',
      (WidgetTester t) async {
        final List<File> gravados = <File>[];
        final RepositorioAutenticacaoSimulado repoAuth =
            RepositorioAutenticacaoSimulado(demora: Duration.zero);

        // ---------------------------------------------------------------------
        // 1. Telas fora da conta (US1 + T099)
        // ---------------------------------------------------------------------
        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '01_boas_vindas.png',
            tela: TelaBoasVindas(aoComecar: () {}, aoJaTerConta: () {}),
          ),
        );

        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '02_tela_de_volta.png',
            tela: TelaDeVolta(aoEntrar: () {}, aoCriarConta: () {}),
          ),
        );

        final ControladorCadastro cadastro = ControladorCadastro(repoAuth);
        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '03_cadastro.png',
            tela: TelaCadastro(
              controlador: cadastro,
              aoConcluir: (_) {},
              aoVoltar: () {},
              aoEntregarAparelho: () {},
            ),
          ),
        );
        cadastro.dispose();

        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '04_entrega_do_aparelho.png',
            tela: TelaEntregaDoAparelho(
              aoReceberOAparelho: () {},
              aoAdiar: () {},
            ),
          ),
        );

        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '05_confirmar_canal.png',
            tela: TelaConfirmarCanal(
              repositorio: repoAuth,
              canalId: 'canal-ana',
              canalVisivel: 'ana@email.com',
              aoConfirmar: () {},
            ),
          ),
        );

        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '06_primeira_entrada.png',
            tela: TelaPrimeiraEntrada(nome: 'Ana', aoEntrarSozinha: () {}),
          ),
        );

        final ControladorLogin login = ControladorLogin(
          repoAuth,
          UltimoAcessoEmMemoria(),
        );
        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '07_login.png',
            tela: TelaLogin(
              controlador: login,
              aoEntrar: (_) {},
              aoVoltar: () {},
              aoRecuperar: () {},
              aoPrimeiroAcesso: () {},
            ),
          ),
        );
        login.dispose();

        final ControladorRecuperacao recuperacao = ControladorRecuperacao(
          repoAuth,
          identificadorInicial: 'ana@email.com',
        );
        gravados.add(
          await fotografarTelaIsolada(
            t,
            tema: tema,
            nomeArquivo: '08_recuperacao.png',
            tela: TelaRecuperacao(
              controlador: recuperacao,
              aoConcluir: (_) {},
              aoVoltar: () {},
            ),
          ),
        );
        recuperacao.dispose();

        // ---------------------------------------------------------------------
        // 2. Apresentação inicial em 3 telas (US1 — Figuras 5, 6 e 7)
        // ---------------------------------------------------------------------
        final GlobalKey chaveApresentacao = GlobalKey(
          debugLabel: 'apresentacao.${tema.name}',
        );
        vestir(t, aparelho);
        await t.pumpWidget(
          RepaintBoundary(
            key: chaveApresentacao,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: TemasMemora.porId(tema),
              home: FluxoApresentacao(
                nome: 'Ana',
                idDaConta: 'ana-1',
                vista: ApresentacaoVistaEmMemoria(),
                aoConcluir: () {},
              ),
            ),
          ),
        );
        await FluxoDentroDaConta.avancar(t);
        gravados.add(
          await salvar(t, chaveApresentacao, tema, '09_apresentacao_1_ola.png'),
        );

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(FluxoApresentacao.chaveContinuar),
        );
        gravados.add(
          await salvar(
            t,
            chaveApresentacao,
            tema,
            '10_apresentacao_2_quem_sou.png',
          ),
        );

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(FluxoApresentacao.chaveContinuar),
        );
        gravados.add(
          await salvar(
            t,
            chaveApresentacao,
            tema,
            '11_apresentacao_3_exemplo.png',
          ),
        );

        // ---------------------------------------------------------------------
        // 3. Telas dentro da conta, com barra inferior (US2 a US8 + T099)
        // ---------------------------------------------------------------------
        final Combinacao c = (aparelho: aparelho, escala: 1.0, tema: tema);
        final GlobalKey chave = GlobalKey(debugLabel: 'album.${tema.name}');
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        await fluxo.montar(
          t,
          em: c,
          capturavel: chave,
          vistas: ApresentacaoVistaEmMemoria(),
          compartilhador: CompartilhadorSimulado(
            'https://memora.fatec.example/baixar',
          ),
        );

        // 12: Início (Figura 8)
        gravados.add(await salvar(t, chave, tema, '12_inicio.png'));

        // 13: Hub (Figura 9)
        Future<void> voltarAoHub() async {
          await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
          await FluxoDentroDaConta.esperarATransicao(t);
          await FluxoDentroDaConta.irAoHub(t);
        }

        await FluxoDentroDaConta.irAoHub(t);
        gravados.add(await salvar(t, chave, tema, '13_hub.png'));

        // 14: Conversa (Figuras 11-13)
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaConversa)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '14_conversa.png'));
        await voltarAoHub();

        // 15: Meus aplicativos (Figura 20) e 16: Passo a passo TikTok (Figuras 21-24)
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAplicativos)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '15_meus_aplicativos.png'));

        await t.drag(find.byKey(TelaCatalogo.chaveLista), const Offset(0, -500));
        await FluxoDentroDaConta.avancar(t);
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaCatalogo.chaveDoItem('TikTok')),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(
          await salvar(t, chave, tema, '16_passo_a_passo_tiktok.png'),
        );
        await voltarAoHub();

        // 17: Serviços sociais (Figura 28) e 18: Passo a passo Gov.br (Figuras 29-36)
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaServicos)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '17_servicos_sociais.png'));

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaCatalogo.chaveDoItem('Gov.br')),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(
          await salvar(t, chave, tema, '18_passo_a_passo_gov_br.png'),
        );
        await voltarAoHub();

        // 19: O que eu fiz por você — Registro (T099)
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaRegistro)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '19_registro.png'));
        await voltarAoHub();

        // 20: Ajuda (Figura 14) + 21: Ajuda guiada (Figuras 15-19) + 22: Segurança + 23: Compartilhar
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAjuda)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '20_ajuda.png'));

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.conversa)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(
          await salvar(t, chave, tema, '21_ajuda_guiada_conversa.png'),
        );
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(CabecalhoDeTela.chaveVoltar),
        );
        await FluxoDentroDaConta.esperarATransicao(t);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.seguranca)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '22_ajuda_seguranca.png'));
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(CabecalhoDeTela.chaveVoltar),
        );
        await FluxoDentroDaConta.esperarATransicao(t);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.compartilhar)),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '23_ajuda_compartilhar.png'));

        // 24: Ajustes (Figura 25) + 25: Aparência + 26: Acessibilidade (Figura 26) + 27: Privacidade + 28: Conta
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '24_ajustes.png'));

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaConfiguracoes.chaveAparencia),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '25_aparencia.png'));
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
        await FluxoDentroDaConta.esperarATransicao(t);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaConfiguracoes.chaveAcessibilidade),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '26_acessibilidade.png'));
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
        await FluxoDentroDaConta.esperarATransicao(t);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaConfiguracoes.chavePrivacidade),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '27_privacidade.png'));
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
        await FluxoDentroDaConta.esperarATransicao(t);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaConfiguracoes.chaveConta),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '28_conta.png'));

        // 29: Perfil (Figura 27) + 30: Data de nascimento (T123)
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(await salvar(t, chave, tema, '29_perfil.png'));

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(SecaoIdade.chaveInformar),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        gravados.add(
          await salvar(t, chave, tema, '30_data_de_nascimento.png'),
        );

        expect(gravados.length, 30);
        for (final File f in gravados) {
          expect(f.existsSync(), isTrue, reason: '${f.path} não foi gravado');
          expect(
            f.lengthSync(),
            greaterThan(10 * 1024),
            reason: '${f.path} saiu pequeno demais para ser uma tela',
          );
        }
      },
    );
  }
}

/// Carrega a fonte de ícones do Material.
Future<void> _carregarIcones() async {
  final String? raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null) return;
  final File arquivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (!arquivo.existsSync()) return;
  final FontLoader carregador = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(Uint8List.fromList(arquivo.readAsBytesSync())),
      ),
    );
  await carregador.load();
}
