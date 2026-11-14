import 'package:flutter/material.dart';

import '../componentes/botoes/botao_primario.dart';
import '../componentes/botoes/botao_secundario.dart';
import '../componentes/botoes/botao_terciario.dart';
import '../componentes/cartoes/cartao.dart';
import '../componentes/ilustracao/ilustracao_memora.dart';
import '../componentes/ilustracao/memora_personagem.dart';
import '../componentes/informacao/badge_de_status.dart';
import '../componentes/navegacao/cabecalho_de_tela.dart';
import '../componentes/selecao/opcao_selecionavel.dart';
import '../componentes/texto/texto_memora.dart';
import '../temas/memora_theme_extension.dart';
import '../tokens/cores.dart';
import '../tokens/dimensoes.dart';
import '../tokens/espacamento.dart';
import '../tokens/raio.dart';
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

  /// O título da tela. Quem a monta o dá, a partir do texto único do
  /// aplicativo (`l10n/`): o Design System não guarda frase da Memora, e o
  /// mesmo título aparece na porta que leva até aqui.
  final String titulo;

  /// Volta à tela anterior. Quando existe, a tela ganha o cabeçalho com
  /// "Voltar" no canto de sempre (FR-001); sem ele — a tela montada fora das
  /// Configurações, ou num teste —, só o título.
  final VoidCallback? aoVoltar;

  /// Cria a tela de aparência.
  const TelaAparencia({
    required this.titulo,
    this.grupo = GrupoDeAjusteVisual.aparencia,
    this.aoVoltar,
    super.key,
  });

  /// Chave do botão que salva o que está em pré-visualização.
  static const Key chaveSalvar = Key('aparencia.salvar');

  /// Chave do botão que descarta a pré-visualização.
  static const Key chaveDesfazer = Key('aparencia.desfazer');

  @override
  Widget build(BuildContext context) {
    final ControladorAparencia controlador = EscopoAparencia.de(context);
    final PreferenciaAparencia atual = controlador.atual;
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;
    final double margem = compacto
        ? MemoraEspacamento.lg
        : MemoraEspacamento.xl;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (aoVoltar != null)
                CabecalhoDeTela(
                  titulo: titulo,
                  aoVoltar: aoVoltar,
                  ilustracao: Ilustracao.ajusteAparencia,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  margem,
                  aoVoltar != null ? 0 : margem,
                  margem,
                  margem,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (aoVoltar == null) ...<Widget>[
                      TextoMemora.tituloTela(titulo),
                      const SizedBox(height: MemoraEspacamento.sm),
                    ],
                    const TextoMemora.apoio(
                      'Escolha e veja como fica. Só salva quando você confirmar.',
                    ),
                    ..._opcoes(context, controlador, atual),
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
    BuildContext context,
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    return switch (grupo) {
      GrupoDeAjusteVisual.aparencia => _opcoesDeAparencia(
        context,
        controlador,
        atual,
      ),
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

  static const List<({String id, String rotulo, String descricao})>
  _paletasDisponiveis = <({String id, String rotulo, String descricao})>[
    (id: 'azul', rotulo: 'Azul', descricao: 'A cor original do Memora'),
    (id: 'verde', rotulo: 'Verde', descricao: 'Tom suave de folha'),
    (id: 'roxo', rotulo: 'Roxo', descricao: 'Tom suave de violeta'),
    (
      id: 'laranja-terra',
      rotulo: 'Laranja-terra',
      descricao: 'Tom acolhedor de cerâmica',
    ),
    (id: 'rosa', rotulo: 'Rosa', descricao: 'Tom suave de flor'),
    (id: 'grafite', rotulo: 'Grafite', descricao: 'Tom neutro e sóbrio'),
  ];

  String _nomeDaPaleta(String id) {
    for (final ({String id, String rotulo, String descricao}) p
        in _paletasDisponiveis) {
      if (p.id == id) return p.rotulo;
    }
    return id;
  }

  List<Widget> _opcoesDeAparencia(
    BuildContext context,
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool ocultarVisuais = escala >= MemoraDimensoes.escalaTextoAlta;

    return <Widget>[
      const SizedBox(height: MemoraEspacamento.lg),
      // Prévia interativa dos 3 temas x 6 paletas (sem toque, FR-012).
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: MemoraEspacamento.sm,
              runSpacing: MemoraEspacamento.xs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const TextoMemora.tituloSecao('Como fica na tela'),
                BadgeDeStatus(
                  rotulo: ehAltoContraste
                      ? EscolhaDeTema.altoContraste.rotulo
                      : '${atual.tema.rotulo} • ${_nomeDaPaleta(atual.paleta)}',
                  tom: TomBadgeStatus.informativo,
                ),
              ],
            ),
            const SizedBox(height: MemoraEspacamento.md),
            Container(
              padding: const EdgeInsets.all(MemoraEspacamento.md),
              decoration: BoxDecoration(
                color: cores.fundo,
                borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
                border: Border.all(
                  color: ehAltoContraste ? cores.borda : cores.bordaSutil,
                  width: ehAltoContraste
                      ? MemoraDimensoes.bordaEnfase
                      : MemoraDimensoes.espessuraBordaSutil,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(MemoraEspacamento.md),
                    decoration: BoxDecoration(
                      color: cores.gradienteHeroiInicio,
                      gradient: ehAltoContraste
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                cores.gradienteHeroiInicio,
                                cores.gradienteHeroiFim,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                      border: ehAltoContraste
                          ? Border.all(
                              color: cores.borda,
                              width: MemoraDimensoes.espessuraBordaSutil,
                            )
                          : null,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (!ocultarVisuais) ...<Widget>[
                          const MemoraPersonagem(
                            expressao: ExpressaoDaMemora.dica,
                            tamanho: MemoraDimensoes.alvoMinimo,
                          ),
                          const SizedBox(width: MemoraEspacamento.sm),
                        ],
                        Expanded(
                          child: TextoMemora(
                            'Exemplo de painel',
                            estilo: EstiloTexto.corpoForte,
                            cor: cores.sobreGradienteHeroi,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.sm),
                  Wrap(
                    spacing: MemoraEspacamento.sm,
                    runSpacing: MemoraEspacamento.xs,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraEspacamento.md,
                          vertical: MemoraEspacamento.xs,
                        ),
                        decoration: BoxDecoration(
                          color: cores.primaria,
                          borderRadius: BorderRadius.circular(
                            MemoraRaio.pilula,
                          ),
                        ),
                        child: TextoMemora(
                          'Cor principal',
                          estilo: EstiloTexto.apoio,
                          cor: cores.sobrePrimaria,
                        ),
                      ),
                      const BadgeDeStatus(
                        rotulo: 'Saudável',
                        tom: TomBadgeStatus.positivo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: MemoraEspacamento.xl),
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const TextoMemora.tituloSecao('Cores'),
            const SizedBox(height: MemoraEspacamento.md),
            if (atual.tema == EscolhaDeTema.altoContraste) ...<Widget>[
              const TextoMemora.apoio(
                'Você está com "Mais contraste" ligado. Se escolher Claro ou '
                'Escuro, ele desliga.',
              ),
              const SizedBox(height: MemoraEspacamento.md),
            ],
            for (int i = 0; i < _temasComuns.length; i++) ...<Widget>[
              OpcaoSelecionavel(
                rotulo: _temasComuns[i].rotulo,
                descricao: _temasComuns[i].descricao,
                selecionada: atual.tema == _temasComuns[i],
                aoSelecionar: () =>
                    controlador.preVisualizarTema(_temasComuns[i]),
              ),
              if (i < _temasComuns.length - 1)
                const SizedBox(height: MemoraEspacamento.md),
            ],
          ],
        ),
      ),
      const SizedBox(height: MemoraEspacamento.xl),
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const TextoMemora.tituloSecao('Cor de destaque'),
            const SizedBox(height: MemoraEspacamento.sm),
            const TextoMemora.apoio(
              'Muda a cor dos botões principais e detalhes da tela.',
            ),
            const SizedBox(height: MemoraEspacamento.md),
            if (atual.tema == EscolhaDeTema.altoContraste)
              const TextoMemora.apoio(
                'No tema "Mais contraste", a cor de destaque fica desativada para manter o contraste máximo.',
              )
            else
              for (int i = 0; i < _paletasDisponiveis.length; i++) ...<Widget>[
                OpcaoSelecionavel(
                  key: Key('aparencia.paleta.${_paletasDisponiveis[i].id}'),
                  rotulo: _paletasDisponiveis[i].rotulo,
                  descricao: _paletasDisponiveis[i].descricao,
                  selecionada: atual.paleta == _paletasDisponiveis[i].id,
                  aoSelecionar: () => controlador.preVisualizarPaleta(
                    _paletasDisponiveis[i].id,
                  ),
                ),
                if (i < _paletasDisponiveis.length - 1)
                  const SizedBox(height: MemoraEspacamento.md),
              ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _opcoesDeAcessibilidade(
    ControladorAparencia controlador,
    PreferenciaAparencia atual,
  ) {
    final bool contrasteLigado = atual.tema == EscolhaDeTema.altoContraste;

    return <Widget>[
      const SizedBox(height: MemoraEspacamento.lg),
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const TextoMemora.tituloSecao('Tamanho da letra'),
            const SizedBox(height: MemoraEspacamento.sm),
            const TextoMemora.apoio(
              'Se as letras parecem pequenas, aumente aqui.',
            ),
            const SizedBox(height: MemoraEspacamento.md),
            for (int i = 0; i < TamanhoDeLetra.values.length; i++) ...<Widget>[
              OpcaoSelecionavel(
                rotulo: TamanhoDeLetra.values[i].rotulo,
                selecionada:
                    TamanhoDeLetra.maisProximoDe(atual.escalaTexto) ==
                    TamanhoDeLetra.values[i],
                aoSelecionar: () => controlador.preVisualizarEscalaTexto(
                  TamanhoDeLetra.values[i].fator,
                ),
              ),
              if (i < TamanhoDeLetra.values.length - 1)
                const SizedBox(height: MemoraEspacamento.md),
            ],
          ],
        ),
      ),
      const SizedBox(height: MemoraEspacamento.xl),
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
          ],
        ),
      ),
      const SizedBox(height: MemoraEspacamento.xl),
      Cartao(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
          ],
        ),
      ),
    ];
  }
}
