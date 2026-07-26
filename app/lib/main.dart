import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'services/preferencias/repositorio_preferencia_aparencia_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final RepositorioPreferenciaAparenciaLocal repositorio =
      await RepositorioPreferenciaAparenciaLocal.abrir();
  final ControladorAparencia controlador = ControladorAparencia(repositorio);
  await controlador.carregar();

  runApp(AplicativoMemora(controlador: controlador));
}

/// Raiz do aplicativo Memora.
///
/// Nesta etapa o aplicativo apenas exercita o Design System. As telas reais
/// chegam com a feature 001, que só é desbloqueada quando os componentes
/// estiverem prontos e validados.
class AplicativoMemora extends StatelessWidget {
  /// Controla o tema e a ampliação de texto escolhidos pela pessoa.
  final ControladorAparencia controlador;

  /// Cria a raiz do aplicativo.
  const AplicativoMemora({required this.controlador, super.key});

  @override
  Widget build(BuildContext context) {
    return EscopoAparencia(
      controlador: controlador,
      child: ListenableBuilder(
        listenable: controlador,
        builder: (BuildContext context, _) {
          final PreferenciaAparencia atual = controlador.atual;
          final AparenciaResolvida aparencia = AparenciaResolvida.de(atual);

          return MaterialApp(
            title: 'Memora',
            debugShowCheckedModeBanner: false,
            theme: aparencia.temaClaro,
            darkTheme: aparencia.temaEscuro,
            themeMode: aparencia.modo,
            builder: (BuildContext context, Widget? child) => AmpliacaoDeTexto(
              fatorDoAplicativo: atual.escalaTexto,
              child: child!,
            ),
            home: const TelaAparencia(),
          );
        },
      ),
    );
  }
}
