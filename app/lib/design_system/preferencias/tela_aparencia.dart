import 'package:flutter/material.dart';

import '../componentes/botoes/botao_primario.dart';
import '../componentes/botoes/botao_secundario.dart';
import '../componentes/botoes/botao_terciario.dart';
import '../componentes/ilustracao/ilustracao_memora.dart';
import '../componentes/navegacao/cabecalho_de_tela.dart';
import '../componentes/selecao/opcao_selecionavel.dart';
import '../componentes/texto/texto_memora.dart';
import '../temas/memora_theme_extension.dart';
import '../tokens/cores.dart';
import '../tokens/dimensoes.dart';
import '../tokens/espacamento.dart';
import 'controlador_aparencia.dart';
import 'escopo_aparencia.dart';
import 'preferencia_aparencia.dart';

/// Tamanhos de letra oferecidos dentro do aplicativo.
///
/// Opções discretas em vez de um controle deslizante: arrastar exige precisão
/// motora que não podemos pressupor, e a FR-015 proíbe depender de gesto
/// complexo. Três escolhas nomeadas são mais fáceis de entender e de acertar.
enum TamanhoDeLetra {
  /// Sem ampliação adicional.
  normal(MemoraDimensoes.escalaTextoMin, 'Normal'),

  /// Ampliação intermediária.
  grande(1.4, 'Grande'),

  /// Ampliação máxima permitida.
  muitoGrande(MemoraDimensoes.escalaTextoMax, 'Bem grande');

  const TamanhoDeLetra(this.fator, this.rotulo);

  /// Multiplicador aplicado sobre a ampliação do sistema.
  final double fator;

  /// Nome exibido à pessoa.
  final String rotulo;

  /// O tamanho correspondente a um fator salvo.
  static TamanhoDeLetra maisProximoDe(double fator) {
    TamanhoDeLetra escolhido = TamanhoDeLetra.normal;
    double menorDistancia = double.infinity;
    for (final TamanhoDeLetra t in TamanhoDeLetra.values) {
      final double distancia = (t.fator - fator).abs();
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        escolhido = t;
      }
    }
    return escolhido;
  }
}

/// Qual dos dois grupos de ajuste visual a [TelaAparencia] mostra (FR-038).
///
/// Separados na revisão da T044: acessibilidade é foco do produto, e escondê-la
/// dentro de "Aparência" a trata como gosto. As duas telas dividem a mesma
/// pré-visualização e o mesmo "desfazer" — por isso são uma classe só, com o
/// grupo por parâmetro, e não duas cópias que divergem na primeira melhoria.
enum GrupoDeAjusteVisual {
  /// Como o Memora se parece: as cores.
  aparencia,

  /// O que ajuda a enxergar e a usar melhor: letra, movimento e contraste.
  acessibilidade,
}

/// Tela de preferências de aparência e de acessibilidade.
///
/// Toda mudança é **pré-visualizada imediatamente** e só é salva quando a
/// pessoa confirma (FR-023). Isso importa aqui mais do que em qualquer outra
/// tela: quem escolhe um tema difícil de enxergar precisa conseguir voltar sem
/// depender de ler a tela que acabou de ficar ilegível.
///
/// ## Cada opção diz para quem serve (FR-039a)
///
/// "Se as letras parecem pequenas…": quem precisa de uma opção de
/// acessibilidade nem sempre sabe que ela existe, ou que é para ele.
class TelaAparencia extends StatelessWidget {
  /// Qual grupo mostrar.
  final GrupoDeAjusteVisual grupo;

  /// Volta à tela anterior. Quando existe, a tela ganha o cabeçalho com
  /// "Voltar" no canto de sempre (FR-001); sem ele — a tela montada fora das
  /// Configurações, ou num teste —, só o título.
  final VoidCallback? aoVoltar;

  /// Cria a tela de aparência.
  const TelaAparencia({
    this.grupo = GrupoDeAjusteVisual.aparencia,
    this.aoVoltar,
    super.key,
  });

  /// Chave do botão que salva o que está em pré-visualização.
  static const Key chaveSalvar = Key('aparencia.salvar');

  /// Chave do botão que descarta a pré-visualização.
  static const Key chaveDesfazer = Key('aparencia.desfazer');

  String get _titulo => switch (grupo) {
    GrupoDeAjusteVisual.aparencia => 'Como o Memora fica',
    GrupoDeAjusteVisual.acessibilidade => 'Enxergar e usar melhor',
  };

  @override
  Widget build(BuildContext context) {
    final ControladorAparencia controlador = EscopoAparencia.de(context);
    final PreferenciaAparencia atual = controlador.atual;
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (aoVoltar != null)
                CabecalhoDeTela(
                  titulo: _titulo,
                  aoVoltar: aoVoltar,
                  ilustracao: Ilustracao.ajusteAparencia,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  MemoraEspacamento.xl,
                  aoVoltar != null ? 0 : MemoraEspacamento.xl,
                  MemoraEspacamento.xl,
                  MemoraEspacamento.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (aoVoltar == null) ...<Widget>[
                      TextoMemora.tituloTela(_titulo),
                      const SizedBox(height: MemoraEspacamento.sm),
                    ],
                    const TextoMemora.apoio(
                      'Escolha e veja como fica. Só salva quando você '
                      'confirmar 😊',
                    ),
                    ..._opcoes(controlador, atual),
                    const SizedBox(height: MemoraEspacamento.xl),
                    if (controlador.temPreVisualizacao) ...<Widget>[
                      BotaoPrimario(
                        key: chaveSalvar,
                        rotulo: 'Salvar deste jeito',
                        icone: Icons.check,
                        aoTocar: controlador.confirmar,
                      ),
                      const SizedBox(height: MemoraEspacamento.md),
                      BotaoSecundario(
                        key: chaveDesfazer,
                        rotulo: 'Deixar como estava',
                        aoTocar: controlador.descartar,
                      ),
                    ],

                    // Saída de emergência de quem se perdeu: sempre presente e
                    // a um toque de distância (FR-022).
                    const SizedBox(height: MemoraEspacamento.xxl),
                    if (!controlador.ehPadrao)
                      BotaoTerciario(
                        rotulo: 'Voltar ao jeito original',
                        aoTocar: controlador.voltarAoPadrao,
                        larguraTotal: true,
                      ),
                    const SizedBox(height: MemoraEspacamento.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _opcoes(
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    return switch (grupo) {
      GrupoDeAjusteVisual.aparencia => _opcoesDeAparencia(controlador, atual),
      GrupoDeAjusteVisual.acessibilidade => _opcoesDeAcessibilidade(
        controlador,
        atual,
      ),
    };
  }

  /// O alto contraste mora em Acessibilidade (FR-039a): aqui ficam só as
  /// cores comuns.
  static const List<EscolhaDeTema> _temasComuns = <EscolhaDeTema>[
    EscolhaDeTema.seguirSistema,
    EscolhaDeTema.claro,
    EscolhaDeTema.escuro,
  ];

  List<Widget> _opcoesDeAparencia(
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    return <Widget>[
      const SizedBox(height: MemoraEspacamento.xxl),
      const TextoMemora.tituloSecao('Cores'),
      const SizedBox(height: MemoraEspacamento.md),
      if (atual.tema == EscolhaDeTema.altoContraste) ...<Widget>[
        const TextoMemora.apoio(
          'Você está com "Mais contraste" ligado. Para mudar, abra '
          '"Enxergar e usar melhor".',
        ),
        const SizedBox(height: MemoraEspacamento.md),
      ],
      for (final EscolhaDeTema tema in _temasComuns) ...<Widget>[
        OpcaoSelecionavel(
          rotulo: tema.rotulo,
          descricao: tema.descricao,
          selecionada: atual.tema == tema,
          aoSelecionar: () => controlador.preVisualizarTema(tema),
        ),
        const SizedBox(height: MemoraEspacamento.md),
      ],
    ];
  }

  List<Widget> _opcoesDeAcessibilidade(
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    final bool contrasteLigado = atual.tema == EscolhaDeTema.altoContraste;

    return <Widget>[
      const SizedBox(height: MemoraEspacamento.xxl),
      const TextoMemora.tituloSecao('Tamanho da letra'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora.apoio('Se as letras parecem pequenas, aumente aqui.'),
      const SizedBox(height: MemoraEspacamento.md),
      for (final TamanhoDeLetra tamanho in TamanhoDeLetra.values) ...<Widget>[
        OpcaoSelecionavel(
          rotulo: tamanho.rotulo,
          selecionada:
              TamanhoDeLetra.maisProximoDe(atual.escalaTexto) == tamanho,
          aoSelecionar: () =>
              controlador.preVisualizarEscalaTexto(tamanho.fator),
        ),
        const SizedBox(height: MemoraEspacamento.md),
      ],

      const SizedBox(height: MemoraEspacamento.xl),
      const TextoMemora.tituloSecao('Movimento'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora.apoio(
        'Se o que se mexe na tela cansa ou distrai você, o Memora pode se '
        'mexer menos.',
      ),
      const SizedBox(height: MemoraEspacamento.md),
      OpcaoSelecionavel(
        rotulo: 'Igual ao meu celular',
        descricao: 'O Memora segue o que o seu celular já tem escolhido',
        selecionada: !atual.reduzirMovimento,
        aoSelecionar: () =>
            controlador.preVisualizarReducaoDeMovimento(reduzir: false),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      OpcaoSelecionavel(
        rotulo: 'Menos movimento',
        descricao: 'As coisas aparecem e mudam na hora, sem deslizar',
        selecionada: atual.reduzirMovimento,
        aoSelecionar: () =>
            controlador.preVisualizarReducaoDeMovimento(reduzir: true),
      ),
      const SizedBox(height: MemoraEspacamento.md),

      const SizedBox(height: MemoraEspacamento.xl),
      const TextoMemora.tituloSecao('Contraste'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora.apoio(
        'Se é difícil separar a letra do fundo, deixe as cores mais fortes.',
      ),
      const SizedBox(height: MemoraEspacamento.md),
      OpcaoSelecionavel(
        rotulo: 'Cores do jeito normal',
        selecionada: !contrasteLigado,
        // Desligar volta a acompanhar o celular. Lembrar qual tema havia antes
        // pediria guardar mais um estado, para um caso em que a pessoa pode
        // escolher o tema de novo em Aparência.
        aoSelecionar: () {
          if (contrasteLigado) {
            controlador.preVisualizarTema(EscolhaDeTema.seguirSistema);
          }
        },
      ),
      const SizedBox(height: MemoraEspacamento.md),
      OpcaoSelecionavel(
        rotulo: EscolhaDeTema.altoContraste.rotulo,
        descricao: EscolhaDeTema.altoContraste.descricao,
        selecionada: contrasteLigado,
        aoSelecionar: () =>
            controlador.preVisualizarTema(EscolhaDeTema.altoContraste),
      ),
      const SizedBox(height: MemoraEspacamento.md),
    ];
  }
}
