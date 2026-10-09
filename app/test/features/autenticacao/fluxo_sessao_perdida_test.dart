import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/chamada_com_renovacao.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_api.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/services/seguranca/sessao_perdida.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../assistente/suporte_da_api_falsa.dart';
import 'dubles_autenticacao.dart';
import 'fluxo_dentro_da_conta.dart';

/// A sessão que cai no meio do uso leva à entrada (T111, Edge Cases de
/// 2026-10-09).
///
/// ## O que este teste prova que o de unidade não prova
///
/// Que o aviso chega **ao fluxo de verdade**: a assistente real (sobre um
/// transporte falso) recebe `401`, a renovação é recusada, e a pessoa — dentro
/// da casca, com a conversa aberta — é levada ao login pelo mesmo caminho da
/// inatividade, com a limpeza rodando. Um gancho que existisse e ninguém
/// escutasse passaria em todos os testes de unidade.
///
/// Usa o `FluxoAutenticacao` montado de verdade (ver `fluxo_dentro_da_conta`),
/// e o transporte falso não cria timer nem toca a rede.
void main() {
  late FluxoDentroDaConta fluxo;
  late SessaoPerdida sessaoPerdida;
  late RepositorioAssistenteApi assistente;

  /// Monta a assistente real sobre um servidor que recusa todo token.
  void prepararAssistente({bool renovacaoSemRede = false}) {
    final CofreEmMemoria cofre = CofreEmMemoria();
    final RenovadorFalso renovador = RenovadorFalso(
      cofre,
      recusar: !renovacaoSemRede,
      semRede: renovacaoSemRede,
    );
    final AdaptadorFalso servidor = AdaptadorFalso(
      (_, _) async => respostaJson(401, <String, Object>{
        'codigo': 'SESSAO_EXPIRADA',
        'mensagem': 'x',
      }),
    );
    final api.MemoraApi cliente = clienteFalso(servidor);
    assistente = RepositorioAssistenteApi(
      cliente: cliente,
      chamadas: ChamadaComRenovacao(
        cliente: cliente,
        cofre: cofre,
        renovar: renovador.renovar,
        sessaoPerdida: sessaoPerdida,
      ),
    );
  }

  setUp(() {
    fluxo = FluxoDentroDaConta();
    sessaoPerdida = SessaoPerdida();
  });

  Future<void> abrirConversaEPerguntar(WidgetTester t) async {
    await FluxoDentroDaConta.tocar(t, find.byKey(TelaInicio.chaveConversar));
    await FluxoDentroDaConta.avancar(t, 8);
    expect(
      find.byKey(TelaConversa.chaveCampo),
      findsOneWidget,
      reason: 'o cenário pressupõe a conversa aberta',
    );
    await t.enterText(find.byKey(TelaConversa.chaveCampo), 'como mando foto?');
    await FluxoDentroDaConta.avancar(t);
    await FluxoDentroDaConta.tocar(t, find.byKey(TelaConversa.chaveEnviar));
    await FluxoDentroDaConta.avancar(t, 10);
  }

  testWidgets('sessão perdida na conversa leva à entrada e roda a limpeza', (
    WidgetTester t,
  ) async {
    prepararAssistente();
    await fluxo.montar(t, assistente: assistente, sessaoPerdida: sessaoPerdida);

    await abrirConversaEPerguntar(t);
    await FluxoDentroDaConta.avancar(t, 10);

    expect(sessaoPerdida.avisos, 1, reason: 'a renovação foi recusada');
    expect(
      find.byKey(TelaLogin.chaveEntrar),
      findsOneWidget,
      reason: 'a pessoa voltou à entrada, e não ficou numa conversa sem saída',
    );
    expect(
      find.byKey(TelaConversa.chaveCampo),
      findsNothing,
      reason: 'a conversa não pode ficar por cima do login',
    );
    expect(
      fluxo.dado.apagamentos,
      1,
      reason: 'é a mesma limpeza da saída e da inatividade (FR-048)',
    );
    expect(fluxo.cofre.limpezas, greaterThanOrEqualTo(1));

    // Um segundo aviso — outra chamada em voo que levou o mesmo 401 — com a
    // pessoa já no login não a arrasta de novo.
    sessaoPerdida.avisar();
    await FluxoDentroDaConta.avancar(t, 6);
    expect(
      fluxo.dado.apagamentos,
      1,
      reason: 'fora da conta não há o que sair',
    );
    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
  });

  testWidgets('sessão perdida no catálogo também leva à entrada', (
    WidgetTester t,
  ) async {
    prepararAssistente();
    await fluxo.montar(t, assistente: assistente, sessaoPerdida: sessaoPerdida);

    await FluxoDentroDaConta.irAoHub(t);
    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAssistente.portaAplicativos),
    );
    await FluxoDentroDaConta.avancar(t, 12);

    expect(sessaoPerdida.avisos, 1);
    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(fluxo.dado.apagamentos, 1);
  });

  testWidgets('falta de conexão na renovação NÃO leva à entrada', (
    WidgetTester t,
  ) async {
    prepararAssistente(renovacaoSemRede: true);
    await fluxo.montar(t, assistente: assistente, sessaoPerdida: sessaoPerdida);

    await abrirConversaEPerguntar(t);
    await FluxoDentroDaConta.avancar(t, 10);

    expect(sessaoPerdida.avisos, 0);
    expect(
      find.byKey(TelaLogin.chaveEntrar),
      findsNothing,
      reason: 'a rede caiu, a sessão não: a pessoa continua dentro',
    );
    expect(find.byKey(TelaConversa.chaveErro), findsOneWidget);
    expect(fluxo.dado.apagamentos, 0);
  });
  testWidgets('fora da conta, o aviso não arrasta ninguém a lugar nenhum', (
    WidgetTester t,
  ) async {
    // Uma resposta tardia de uma conversa que já saiu da tela, ou um aviso
    // quando a pessoa ainda nem entrou: não há sessão para encerrar, e rodar a
    // saída automática apagaria o que a pessoa acabou de digitar.
    final DadoLocalQueRegistra dado = DadoLocalQueRegistra();
    final UltimoAcessoEmMemoria ultimo = UltimoAcessoEmMemoria();
    await t.pumpWidget(
      EscopoAparencia(
        controlador: ControladorAparencia(PreferenciaEmMemoria()),
        child: MaterialApp(
          theme: TemasMemora.claro,
          home: FluxoAutenticacao(
            repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
            ultimoAcesso: ultimo,
            sessaoPerdida: sessaoPerdida,
            limpeza: LimpezaDeSessao(
              cofre: CofreQueRegistra(),
              ultimoAcesso: ultimo,
              dadosLocais: <DadoLocalDaPessoa>[dado],
            ),
          ),
        ),
      ),
    );
    await FluxoDentroDaConta.avancar(t);
    expect(find.byKey(TelaBoasVindas.chaveComecar), findsOneWidget);

    sessaoPerdida.avisar();
    await FluxoDentroDaConta.avancar(t, 6);

    expect(dado.apagamentos, 0, reason: 'não há sessão para encerrar');
    expect(find.byKey(TelaBoasVindas.chaveComecar), findsOneWidget);
    expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);
  });
}
