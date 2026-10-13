import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/configuracoes/presentation/tela_configuracoes.dart';
import 'package:memora/features/configuracoes/presentation/tela_conta.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import '../../suporte/aparelhos.dart';
import 'dubles_autenticacao.dart';

/// Monta o `FluxoAutenticacao` real, com assistente e limpeza, e entra na
/// conta pelo login. Compartilhado pelos testes que exercitam o fluxo por
/// dentro (saida com confirmacao, rotas e inatividade).
class FluxoDentroDaConta {
  /// Dado local que registra quantas vezes a limpeza o apagou.
  final DadoLocalQueRegistra dado = DadoLocalQueRegistra();

  /// Cofre que registra as limpezas.
  final CofreQueRegistra cofre = CofreQueRegistra();

  /// O repositório simulado do aparelho, para o teste semear outras contas
  /// (`registrarConta`) e entrar com elas no mesmo fluxo. Existe depois de
  /// [montar].
  late final RepositorioAutenticacaoSimulado repositorio;
  /// O último acesso do aparelho: o que a saída comum mantém e o
  /// `esquecerTudo` apaga.
  final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();

  /// A conversa guardada, **uma só** para o fluxo inteiro: é por ela que um
  /// teste vê se Privacidade apagou o que a conversa gravou.
  final ConversaEmMemoria conversa = ConversaEmMemoria();

  /// O id que o simulado dá à conta de Ana — o que a apresentação vista e a
  /// data de nascimento usam como chave.
  static final String idDaAna = 'simulado-${'ana@email.com'.hashCode.abs()}';

  /// Bombeia alguns quadros sem esperar quietude: o `Carregando` anima sem
  /// parar e `pumpAndSettle` travaria.
  static Future<void> avancar(WidgetTester t, [int quadros = 4]) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  /// Rola ate o alvo, toca e bombeia alguns quadros.
  static Future<void> tocar(WidgetTester t, Finder alvo) async {
    await t.ensureVisible(alvo);
    await t.pump();
    await t.tap(alvo);
    await avancar(t);
  }

  /// Monta o fluxo e deixa a pessoa no Início, a raiz do destino de mesmo nome.
  ///
  /// [em] põe a janela do teste no tamanho de um aparelho, com a ampliação e o
  /// tema da combinação (FR-044): é como a matriz roda **pelo fluxo real**, com
  /// a barra inferior e as pilhas da casca, e não só a tela isolada.
  ///
  /// [capturavel] põe um `RepaintBoundary` com essa chave em volta do
  /// aplicativo inteiro: é por onde o álbum de telas (T043) tira a foto da tela
  /// que a pessoa de fato vê.
  Future<void> montar(
    WidgetTester t, {
    Duration inatividade = const Duration(minutes: 30),
    Duration aviso = const Duration(minutes: 2),
    Combinacao? em,
    GlobalKey? capturavel,
    DataDeNascimentoDoAparelho? datas,
    ApresentacaoVistaDoAparelho? vistas,
  }) async {
    if (em != null) vestir(t, em.aparelho);
    // Com a guarda da apresentação, a conta de Ana já a viu: o cenário começa
    // no Início, e a guarda tem o que o `esquecerTudo` deve apagar.
    if (vistas != null) await vistas.marcarComoVista(idDaAna);
    repositorio = RepositorioAutenticacaoSimulado(demora: Duration.zero)
      ..registrarConta(
        identificador: 'ana@email.com',
        senha: 'uma frase que so eu lembro',
        nome: 'Ana',
      );

    // O `EscopoAparencia` em volta, como no `main.dart` de verdade: sem ele, a
    // tela de aparência — que a casca abre em Ajustes — não encontra quem a
    // controla. Um arnês que monta menos que o aplicativo testa menos que ele.
    final Widget app = EscopoAparencia(
      controlador: ControladorAparencia(PreferenciaEmMemoria()),
      child: MaterialApp(
        // A faixa "DEBUG" iria para dentro de toda imagem do álbum.
        debugShowCheckedModeBanner: capturavel == null,
        theme: TemasMemora.porId(em?.tema ?? MemoraTemaId.claro),
        // `builder`, e não um `MediaQuery` em volta de `home`: a ampliação
        // precisa valer também para os diálogos, que moram acima das rotas.
        builder: em == null
            ? null
            : (BuildContext contexto, Widget? filho) => MediaQuery(
                data: MediaQuery.of(
                  contexto,
                ).copyWith(textScaler: TextScaler.linear(em.escala)),
                child: filho!,
              ),
        home: FluxoAutenticacao(
          repositorio: repositorio,
          assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
          conversaLocal: () => conversa,
          ultimoAcesso: ultimoAcesso,
          dataDeNascimento: datas,
          apresentacaoVista: vistas,
          inatividade: inatividade,
          avisoDeInatividade: aviso,
          limpeza: LimpezaDeSessao(
            cofre: cofre,
            ultimoAcesso: ultimoAcesso,
            dadosLocais: <DadoLocalDaPessoa>[dado],
            dadosDoAparelho: <DadoLocalDoAparelho>[?datas, ?vistas],
          ),
        ),
      ),
    );
    await t.pumpWidget(
      capturavel == null ? app : RepaintBoundary(key: capturavel, child: app),
    );
    await avancar(t);

    await tocar(t, find.text(TextosAutenticacao.botaoJaTenhoConta));
    await entrarComConta(t, 'ana@email.com', 'uma frase que so eu lembro');

    expect(
      find.byKey(TelaInicio.chaveSaudacao),
      findsOneWidget,
      reason: 'o cenario pressupoe a pessoa dentro da conta, no Inicio',
    );
    expect(dado.apagamentos, 0);
  }

  /// Preenche o login (já aberto) com [identificador] e [senha] e entra.
  ///
  /// Troca o que houver no campo: depois de uma saída o identificador do
  /// último acesso volta preenchido (FR-012).
  static Future<void> entrarComConta(
    WidgetTester t,
    String identificador,
    String senha,
  ) async {
    await _preencher(t, TelaLogin.chaveIdentificador, identificador);
    await _preencher(t, TelaLogin.chaveSenha, senha);
    await tocar(t, find.byKey(TelaLogin.chaveEntrar));
    await avancar(t, 6);
  }

  /// Sai pela saída comum de Ajustes, confirmando, e espera o login.
  static Future<void> sairConfirmando(WidgetTester t) async {
    await tocarEmSair(t);
    await tocar(t, find.text(TextosAutenticacao.botaoConfirmarSaida));
    await avancar(t, 6);
  }

  /// Toca no destino [destino] da barra inferior.
  static Future<void> irPara(WidgetTester t, DestinoDaCasca destino) {
    return tocar(
      t,
      find.descendant(
        of: find.byKey(CascaInterna.chaveDaBarra),
        matching: find.text(destino.rotulo),
      ),
    );
  }

  /// Espera a transicao de uma rota (300 ms) terminar, sem `pumpAndSettle`:
  /// uma tela com `Carregando` anima sem parar e ele nunca voltaria.
  ///
  /// Enquanto a transicao corre, a tela de baixo ainda esta na arvore e a
  /// busca por ela acha o que ja deveria estar coberto.
  static Future<void> esperarATransicao(WidgetTester t) =>
      t.pump(const Duration(milliseconds: 400));

  /// Do Inicio ao Hub, tocando no atalho de verdade.
  static Future<void> irAoHub(WidgetTester t) async {
    await tocar(t, find.byKey(TelaInicio.chaveVerTudo));
    await esperarATransicao(t);
  }

  /// Vai a Ajustes e abre a porta de Conta.
  static Future<void> irAConta(WidgetTester t) async {
    await irPara(t, DestinoDaCasca.ajustes);
    await tocar(t, find.byKey(TelaConfiguracoes.chaveConta));
    await esperarATransicao(t);
  }

  /// Vai a Ajustes -> Conta e toca em "Sair" — o toque que pergunta, e nao o
  /// que sai.
  ///
  /// E o unico caminho de saida (FR-019): nao ha "Sair" no Inicio nem no Hub.
  static Future<void> tocarEmSair(WidgetTester t) async {
    await irAConta(t);
    await tocar(t, find.byKey(TelaConta.chaveSair));
  }

  /// Vai a Ajustes -> Conta e toca em "Sair e esquecer este aparelho" — o
  /// toque que abre a pergunta.
  static Future<void> tocarEmEsquecer(WidgetTester t) async {
    await irAConta(t);
    await tocar(t, find.byKey(TelaConta.chaveEsquecer));
  }

  /// Vai a Ajustes -> Privacidade.
  static Future<void> irAPrivacidade(WidgetTester t) async {
    await irPara(t, DestinoDaCasca.ajustes);
    await tocar(t, find.byKey(TelaConfiguracoes.chavePrivacidade));
    await esperarATransicao(t);
  }
}

Future<void> _preencher(WidgetTester t, Key chave, String valor) async {
  final Finder entrada = find.descendant(
    of: find.byKey(chave),
    matching: find.byType(TextField),
  );
  await t.ensureVisible(entrada);
  await t.enterText(entrada, valor);
  await t.pump();
}

/// A conversa guardada, em memoria, que conta quantas vezes foi apagada.
class ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  /// Quantas vezes `apagar` rodou.
  int apagamentos = 0;

  /// O que esta guardado agora.
  List<MensagemDaConversa> get guardadas => _guardadas;

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  /// Quando verdadeiro, `apagar` falha sem apagar nada (disco, permissão).
  bool falharAoApagar = false;

  @override
  Future<void> apagar() async {
    apagamentos++;
    if (falharAoApagar) throw const FileSystemException('sem permissão');
    _guardadas = <MensagemDaConversa>[];
  }
}

/// Dado local que so conta quantas vezes foi apagado.
class DadoLocalQueRegistra implements DadoLocalDaPessoa {
  /// Quantas vezes `apagar` rodou.
  int apagamentos = 0;

  @override
  Future<void> apagar() async => apagamentos++;
}

/// Cofre que so conta quantas vezes foi limpo.
class CofreQueRegistra implements CofreDeCredenciais {
  /// Quantas vezes `limpar` rodou.
  int limpezas = 0;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> tokenAcesso() async => null;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> limpar() async => limpezas++;
}

/// Preferência de aparência que não toca o disco: dentro de `testWidgets`,
/// I/O de arquivo real nunca completa.
class PreferenciaEmMemoria implements RepositorioPreferenciaAparencia {
  @override
  Future<PreferenciaAparencia> carregar() async => PreferenciaAparencia.padrao;

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {}
}
