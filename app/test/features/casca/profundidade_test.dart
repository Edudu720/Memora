import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/domain/assunto_de_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_assunto.dart';
import 'package:memora/features/aprendizado/presentation/tela_passo_a_passo.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_registro.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/features/configuracoes/presentation/tela_configuracoes.dart';
import 'package:memora/features/configuracoes/presentation/tela_conta.dart';
import 'package:memora/features/configuracoes/presentation/tela_privacidade.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../autenticacao/fluxo_dentro_da_conta.dart';

/// SC-006 da feature 004: qualquer parte do aplicativo é alcançada em até 3
/// toques a partir do Início (T036).
///
/// ## Toques de verdade
///
/// Cada caminho abaixo é uma lista de **alvos que o teste toca** com
/// `tester.tap`, e o número de toques é contado em cada um. Navegar de dentro
/// do teste (`Navigator.push`) provaria que a tela existe, e não que a pessoa
/// chega até ela: uma porta pode existir e estar escondida atrás de um quarto
/// toque.
///
/// ## O que impede o teste de ficar para trás
///
/// Uma parte nova do aplicativo precisa entrar na tabela, senão o teste
/// reprova: toda porta do Hub tem de aparecer num caminho, e todo destino da
/// barra também. Sem isso, a SC-006 seria verdadeira para o que o teste
/// conhece — e nada além.
///
/// ## O que o contador **não** conta
///
/// A volta ao Início, entre um caminho e o seguinte. Ela é o toque no destino
/// "Início" da barra, que o teste usa só para recomeçar de um estado conhecido.
/// O que um caminho percorre: os alvos, em ordem, e o que prova a chegada.
///
/// [via] é o destino da barra que o caminho usa, quando usa; serve só para o
/// teste conferir que todo destino da barra tem um caminho na tabela.
typedef Caminho = ({
  String parte,
  List<Finder> toques,
  Finder chegada,
  DestinoDaCasca? via,
});

void main() {
  const int limite = 3;

  late FluxoDentroDaConta fluxo;
  int toques = 0;

  setUp(() {
    fluxo = FluxoDentroDaConta();
    toques = 0;
  });

  /// Um toque de verdade, contado.
  Future<void> tocar(WidgetTester t, Finder alvo) async {
    toques++;
    await FluxoDentroDaConta.tocar(t, alvo);
    await FluxoDentroDaConta.esperarATransicao(t);
  }

  Finder naBarra(DestinoDaCasca d) => find.descendant(
    of: find.byKey(CascaInterna.chaveDaBarra),
    matching: find.text(d.rotulo),
  );

  /// Recomeça do Início, **sem contar** como toque.
  ///
  /// Cada destino tem a própria pilha, e uma tela aberta em Ajustes continuaria
  /// lá quando o caminho seguinte começasse. Tocar duas vezes no mesmo destino
  /// o leva à raiz (a primeira troca, se for outro; a segunda volta à raiz), e
  /// o Início fica por último.
  Future<void> recomecar(WidgetTester t) async {
    for (final DestinoDaCasca d in <DestinoDaCasca>[
      DestinoDaCasca.ajustes,
      DestinoDaCasca.perfil,
      DestinoDaCasca.inicio,
    ]) {
      await FluxoDentroDaConta.tocar(t, naBarra(d));
      await FluxoDentroDaConta.tocar(t, naBarra(d));
    }
    await FluxoDentroDaConta.esperarATransicao(t);
    toques = 0;
  }

  final Finder deApps = find.byKey(
    TelaHub.chaveDaPorta(TextosAssistente.portaAplicativos),
  );
  final Finder deServicos = find.byKey(
    TelaHub.chaveDaPorta(TextosAssistente.portaServicos),
  );
  final Finder doRegistro = find.byKey(
    TelaHub.chaveDaPorta(TextosAssistente.portaRegistro),
  );
  final Finder daAjuda = find.byKey(
    TelaHub.chaveDaPorta(TextosAssistente.portaAjuda),
  );
  final Finder doHub = find.byKey(TelaInicio.chaveVerTudo);

  /// Todas as partes do aplicativo e o caminho até cada uma.
  final List<Caminho> caminhos = <Caminho>[
    (
      parte: 'conversa (pelo atalho do Início)',
      toques: <Finder>[find.byKey(TelaInicio.chaveConversar)],
      chegada: find.byKey(TelaConversa.chaveCampo),
      via: null,
    ),
    (
      parte: 'todas as partes (o Hub)',
      toques: <Finder>[doHub],
      chegada: find.byType(TelaHub),
      via: null,
    ),
    (
      parte: 'meus aplicativos',
      toques: <Finder>[doHub, deApps],
      chegada: find.byWidgetPredicate(
        (Widget w) => w is TelaCatalogo && w.categoria.name == 'cotidiano',
      ),
      via: null,
    ),
    (
      parte: 'serviços sociais',
      toques: <Finder>[doHub, deServicos],
      chegada: find.byWidgetPredicate(
        (Widget w) => w is TelaCatalogo && w.categoria.name == 'sensivel',
      ),
      via: null,
    ),
    (
      parte: 'o que eu fiz por você',
      toques: <Finder>[doHub, doRegistro],
      chegada: find.byType(TelaRegistro),
      via: null,
    ),
    (
      parte: 'ajuda',
      toques: <Finder>[doHub, daAjuda],
      chegada: find.byType(TelaAjuda),
      via: null,
    ),
    (
      // A US6 existe para isto: achar, pela Ajuda, como se proteger de um
      // golpe por telefone. Três toques a partir do Início.
      parte: 'dicas de segurança contra golpe (pela Ajuda)',
      toques: <Finder>[
        doHub,
        daAjuda,
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.seguranca)),
      ],
      chegada: find.byType(TelaAssunto),
      via: null,
    ),
    (
      parte: 'um aplicativo do catálogo (leva ao passo a passo)',
      toques: <Finder>[
        doHub,
        deApps,
        find.byKey(TelaCatalogo.chaveDoItem('WhatsApp')),
      ],
      chegada: find.byType(TelaPassoAPasso),
      via: null,
    ),
    (
      parte: 'um serviço social sem guia (leva à conversa)',
      toques: <Finder>[
        doHub,
        deServicos,
        find.byKey(TelaCatalogo.chaveDoItem('Gov.br')),
      ],
      chegada: find.byKey(TelaConversa.chaveCampo),
      via: null,
    ),
    (
      parte: 'ajustes',
      toques: <Finder>[naBarra(DestinoDaCasca.ajustes)],
      chegada: find.byType(TelaConfiguracoes),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'como o Memora fica (aparência)',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chaveAparencia),
      ],
      chegada: find.byWidgetPredicate(
        (Widget w) =>
            w is TelaAparencia && w.grupo == GrupoDeAjusteVisual.aparencia,
      ),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'enxergar e usar melhor (acessibilidade)',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chaveAcessibilidade),
      ],
      chegada: find.byWidgetPredicate(
        (Widget w) =>
            w is TelaAparencia && w.grupo == GrupoDeAjusteVisual.acessibilidade,
      ),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'o que fica guardado (privacidade)',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chavePrivacidade),
      ],
      chegada: find.byType(TelaPrivacidade),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'apagar a conversa (a pergunta)',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chavePrivacidade),
        find.byKey(TelaPrivacidade.chaveApagar),
      ],
      chegada: find.byKey(TelaPrivacidade.chaveConfirmacao),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'minha conta',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chaveConta),
      ],
      chegada: find.byType(TelaConta),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'a saída da conta',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chaveConta),
        find.byKey(TelaConta.chaveSair),
      ],
      chegada: find.byKey(TelaConta.chaveConfirmacao),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'sair e esquecer este aparelho (a pergunta)',
      toques: <Finder>[
        naBarra(DestinoDaCasca.ajustes),
        find.byKey(TelaConfiguracoes.chaveConta),
        find.byKey(TelaConta.chaveEsquecer),
      ],
      chegada: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
      via: DestinoDaCasca.ajustes,
    ),
    (
      parte: 'meu perfil',
      toques: <Finder>[naBarra(DestinoDaCasca.perfil)],
      chegada: find.byType(PerfilProvisorio),
      via: DestinoDaCasca.perfil,
    ),
    // A galeria só existe em depuração (R9 da 002); fora dela não há caminho.
    if (kDebugMode)
      (
        parte: 'a galeria (só em desenvolvimento)',
        toques: <Finder>[
          naBarra(DestinoDaCasca.ajustes),
          find.byKey(TelaConfiguracoes.chaveGaleria),
        ],
        chegada: find.byType(GaleriaMemora),
        via: DestinoDaCasca.ajustes,
      ),
  ];

  testWidgets('cada parte do aplicativo está a até $limite toques do Início', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t);

    for (final Caminho c in caminhos) {
      await recomecar(t);
      for (final Finder alvo in c.toques) {
        // Sem este aviso, um alvo que não existe vira "No element" e ninguém
        // sabe de qual caminho.
        expect(
          alvo,
          findsOneWidget,
          reason:
              'no caminho "${c.parte}", o toque ${toques + 1} não achou o '
              'alvo ($alvo)',
        );
        await tocar(t, alvo);
      }

      expect(
        c.chegada,
        findsOneWidget,
        reason: 'depois de ${c.toques.length} toques, "${c.parte}" não abriu',
      );
      expect(
        toques,
        lessThanOrEqualTo(limite),
        reason:
            '"${c.parte}" exige $toques toques a partir do Início; a SC-006 '
            'permite $limite',
      );
    }
  });

  testWidgets('toda porta do Hub e todo destino da barra estão na tabela', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t);
    await recomecar(t);
    await tocar(t, doHub);

    // As portas do Hub que existem no aplicativo...
    final Set<Key> daTela = <Key>{
      for (final Widget w in t.widgetList(find.byType(CartaoDePorta))) w.key!,
    };
    // ...e as que a tabela sabe alcançar.
    final Set<Key> daTabela = <Key>{
      TelaHub.chaveDaPorta(TextosAssistente.portaAplicativos),
      TelaHub.chaveDaPorta(TextosAssistente.portaServicos),
      TelaHub.chaveDaPorta(TextosAssistente.portaRegistro),
      TelaHub.chaveDaPorta(TextosAssistente.portaConversa),
      TelaHub.chaveDaPorta(TextosAssistente.portaAjuda),
    };
    expect(
      daTela.difference(daTabela),
      isEmpty,
      reason:
          'o Hub ganhou uma porta que `profundidade_test.dart` não conhece: '
          'acrescente o caminho dela à tabela (SC-006)',
    );

    // Os destinos da barra.
    // O Início é a raiz, de onde todo caminho parte; os outros dois precisam
    // de um caminho que passe por eles.
    final Set<DestinoDaCasca> cobertos = <DestinoDaCasca>{
      DestinoDaCasca.inicio,
      for (final Caminho c in caminhos)
        if (c.via != null) c.via!,
    };
    expect(
      cobertos,
      containsAll(DestinoDaCasca.values),
      reason: 'a barra ganhou um destino que a tabela não alcança (SC-006)',
    );
  });
}
