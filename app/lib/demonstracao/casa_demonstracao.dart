import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import '../features/autenticacao/presentation/fluxo_cadastro.dart';
import 'tela_componentes.dart';

/// Casca provisória para testar o Design System no aparelho.
///
/// Substituída pelas telas reais quando a feature 001 for implementada.
class CasaDemonstracao extends StatefulWidget {
  /// Cria a casca de demonstração.
  const CasaDemonstracao({super.key});

  @override
  State<CasaDemonstracao> createState() => _CasaDemonstracaoState();
}

class _CasaDemonstracaoState extends State<CasaDemonstracao> {
  int _indice = 0;

  static const List<ItemNavegacao> _destinos = <ItemNavegacao>[
    ItemNavegacao(icone: Icons.person_add_outlined, rotulo: 'Cadastro'),
    ItemNavegacao(icone: Icons.widgets_outlined, rotulo: 'Componentes'),
    ItemNavegacao(icone: Icons.palette_outlined, rotulo: 'Aparência'),
  ];

  /// Repositório simulado: o backend ainda não expõe o endpoint de cadastro.
  final RepositorioAutenticacaoSimulado _repositorio =
      RepositorioAutenticacaoSimulado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: <Widget>[
          FluxoCadastro(repositorio: _repositorio),
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
