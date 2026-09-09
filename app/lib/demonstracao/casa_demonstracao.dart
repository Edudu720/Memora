import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../features/assistente/data/abridor_de_aplicativo.dart';
import '../features/autenticacao/data/ultimo_acesso_local.dart';
import '../features/autenticacao/presentation/fluxo_autenticacao.dart';
import '../services/ambiente/composicao.dart';
import 'tela_componentes.dart';

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
            assistente: widget.composicao.assistente,
            abridor: const AbridorDeAplicativoAndroid(),
          ),
          const TelaComponentes(),
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
