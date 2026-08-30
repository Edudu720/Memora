import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../features/assistente/data/repositorio_assistente_simulado.dart';
import '../features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import '../features/autenticacao/data/ultimo_acesso_local.dart';
import '../features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'tela_componentes.dart';

/// Casca provisória para testar o Design System e os fluxos no aparelho.
///
/// Substituída pelas telas reais quando o Hub existir.
class CasaDemonstracao extends StatefulWidget {
  /// Onde fica o identificador do último acesso (FR-012).
  final UltimoAcesso ultimoAcesso;

  /// Cria a casca de demonstração.
  const CasaDemonstracao({required this.ultimoAcesso, super.key});

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

  /// Repositório simulado: o aplicativo ainda não sabe de onde vem a URL base do
  /// servidor, e essa decisão não está na spec. Trocar por
  /// `RepositorioAutenticacaoApi` é uma linha, quando a URL for definida.
  ///
  /// O simulado reproduz a escada de bloqueio real (5 falhas seguidas, depois
  /// 1 minuto), para que o estado bloqueado da FR-015 possa ser visto no
  /// aparelho e não só no teste.
  final RepositorioAutenticacaoSimulado _repositorio =
      RepositorioAutenticacaoSimulado();

  /// A assistente, tambem simulada. O provedor de IA ainda nao foi escolhido
  /// (R2 do research), e o Hub inteiro funciona sem ele.
  final RepositorioAssistenteSimulado _assistente =
      RepositorioAssistenteSimulado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: <Widget>[
          FluxoAutenticacao(
            repositorio: _repositorio,
            ultimoAcesso: widget.ultimoAcesso,
            assistente: _assistente,
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
