import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../features/assistente/data/abridor_de_aplicativo.dart';
import '../features/autenticacao/data/ultimo_acesso_local.dart';
import '../features/autenticacao/presentation/fluxo_autenticacao.dart';
import '../services/ambiente/composicao.dart';

/// Casca provisória para testar o Design System e os fluxos no aparelho.
///
/// Substituída pelas telas reais quando o Hub existir.
class CasaDemonstracao extends StatefulWidget {
  /// Onde fica o identificador do último acesso (FR-012).
  final UltimoAcesso ultimoAcesso;

  /// Com quem o aplicativo conversa. Resolvido na subida, nunca aqui.
  final Composicao composicao;

  /// Cria a casca de demonstração.
  const CasaDemonstracao({
    required this.ultimoAcesso,
    required this.composicao,
    super.key,
  });

  @override
  State<CasaDemonstracao> createState() => _CasaDemonstracaoState();
}

class _CasaDemonstracaoState extends State<CasaDemonstracao> {
  int _indice = 0;

  static const List<ItemNavegacao> _destinos = <ItemNavegacao>[
    ItemNavegacao(icone: Icons.login_outlined, rotulo: 'Entrar'),
    ItemNavegacao(icone: Icons.widgets_outlined, rotulo: 'Componentes'),
    ItemNavegacao(icone: Icons.palette_outlined, rotulo: 'Aparência'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: <Widget>[
          FluxoAutenticacao(
            // Quem escolheu entre real e simulado foi a Composicao, na subida.
            // Esta tela nao sabe — e nao deve saber — com qual dos dois fala.
            repositorio: widget.composicao.autenticacao,
            ultimoAcesso: widget.ultimoAcesso,
            limpeza: widget.composicao.limpeza,
            assistente: widget.composicao.assistente,
            abridor: const AbridorDeAplicativoAndroid(),
          ),
          // A galeria E a vitrine: ter duas listas dos mesmos componentes e
          // como elas comecam a divergir. Fora do modo de depuracao ela nao
          // existe (R9), e a aba mostra por que — em vez de abrir vazia.
          GaleriaMemora.paraDesenvolvimento() ?? const _GaleriaForaDeDebug(),
          const TelaAparencia(),
        ],
      ),
      bottomNavigationBar: NavegacaoInferior(
        itens: _destinos,
        indiceAtivo: _indice,
        aoSelecionar: (int i) => setState(() => _indice = i),
      ),
    );
  }
}

/// O que aparece na aba da galeria num build que nao e de desenvolvimento.
///
/// A R9 quer a galeria so em desenvolvimento. Esconder a aba inteira mudaria
/// a contagem de destinos e o indice de todas as outras; dizer o porque custa
/// menos e nao mente.
class _GaleriaForaDeDebug extends StatelessWidget {
  const _GaleriaForaDeDebug();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(MemoraEspacamento.xl),
          child: EstadoVazio(
            titulo: 'A galeria so existe em desenvolvimento',
            explicacao:
                'Ela e ferramenta de quem constroi o Memora, nao de quem usa. '
                'Rode em modo de depuracao para abri-la.',
            icone: Icons.construction_outlined,
          ),
        ),
      ),
    );
  }
}
