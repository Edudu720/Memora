import 'package:flutter/material.dart';

import 'design_system/design_system.dart';

void main() => runApp(const AplicativoMemora());

/// Raiz do aplicativo Memora.
///
/// Nesta etapa o aplicativo apenas exercita o Design System. As telas reais
/// chegam com a feature 001, que só é desbloqueada quando os componentes
/// estiverem prontos e validados.
class AplicativoMemora extends StatelessWidget {
  /// Cria a raiz do aplicativo.
  const AplicativoMemora({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: TemasMemora.claro,
      darkTheme: TemasMemora.escuro,
      home: const _AmostraDeTokens(),
    );
  }
}

/// Amostra provisória dos tokens, substituída pela galeria em T045.
class _AmostraDeTokens extends StatelessWidget {
  const _AmostraDeTokens();

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Memora',
                style: MemoraTipografia.tituloTela.copyWith(
                  color: cores.primaria,
                ),
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              Text(
                'Design System em construção. Os tokens já estão validados: '
                '48 pares de contraste aprovados nos três temas.',
                style: MemoraTipografia.corpo.copyWith(color: cores.texto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
