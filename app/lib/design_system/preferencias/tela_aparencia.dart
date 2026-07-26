import 'package:flutter/material.dart';

import '../componentes/botoes/botao_primario.dart';
import '../componentes/botoes/botao_secundario.dart';
import '../componentes/botoes/botao_terciario.dart';
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

/// Tela de preferências de aparência.
///
/// Toda mudança é **pré-visualizada imediatamente** e só é salva quando a
/// pessoa confirma (FR-023). Isso importa aqui mais do que em qualquer outra
/// tela: quem escolhe um tema difícil de enxergar precisa conseguir voltar sem
/// depender de ler a tela que acabou de ficar ilegível.
class TelaAparencia extends StatelessWidget {
  /// Cria a tela de aparência.
  const TelaAparencia({super.key});

  @override
  Widget build(BuildContext context) {
    final ControladorAparencia controlador = EscopoAparencia.de(context);
    final PreferenciaAparencia atual = controlador.atual;
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TextoMemora.tituloTela('Como você prefere ver o Memora?'),
              const SizedBox(height: MemoraEspacamento.sm),
              const TextoMemora.apoio(
                'Escolha e veja como fica. Só salva quando você confirmar 😊',
              ),

              const SizedBox(height: MemoraEspacamento.xxl),
              const TextoMemora.tituloSecao('Cores'),
              const SizedBox(height: MemoraEspacamento.md),
              for (final EscolhaDeTema tema in EscolhaDeTema.values) ...<Widget>[
                OpcaoSelecionavel(
                  rotulo: tema.rotulo,
                  descricao: tema.descricao,
                  selecionada: atual.tema == tema,
                  aoSelecionar: () => controlador.preVisualizarTema(tema),
                ),
                const SizedBox(height: MemoraEspacamento.md),
              ],

              const SizedBox(height: MemoraEspacamento.xl),
              const TextoMemora.tituloSecao('Tamanho da letra'),
              const SizedBox(height: MemoraEspacamento.md),
              for (final TamanhoDeLetra tamanho
                  in TamanhoDeLetra.values) ...<Widget>[
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

              if (controlador.temPreVisualizacao) ...<Widget>[
                BotaoPrimario(
                  rotulo: 'Salvar deste jeito',
                  icone: Icons.check,
                  aoTocar: controlador.confirmar,
                ),
                const SizedBox(height: MemoraEspacamento.md),
                BotaoSecundario(
                  rotulo: 'Deixar como estava',
                  aoTocar: controlador.descartar,
                ),
              ],

              // Saída de emergência de quem se perdeu: sempre presente e a um
              // toque de distância (FR-022).
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
      ),
    );
  }
}
