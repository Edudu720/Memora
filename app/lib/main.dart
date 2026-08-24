import 'package:flutter/material.dart';

import 'demonstracao/casa_demonstracao.dart';
import 'design_system/design_system.dart';
import 'features/autenticacao/data/ultimo_acesso_local.dart';
import 'services/preferencias/repositorio_preferencia_aparencia_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final RepositorioPreferenciaAparenciaLocal repositorio =
      await RepositorioPreferenciaAparenciaLocal.abrir();
  final ControladorAparencia controlador = ControladorAparencia(repositorio);
  await controlador.carregar();

  final UltimoAcessoLocal ultimoAcesso = await UltimoAcessoLocal.abrir();

  runApp(
    AplicativoMemora(controlador: controlador, ultimoAcesso: ultimoAcesso),
  );
}

/// Raiz do aplicativo Memora.
///
/// Nesta etapa o aplicativo apenas exercita o Design System. As telas reais
/// chegam com a feature 001, que só é desbloqueada quando os componentes
/// estiverem prontos e validados.
class AplicativoMemora extends StatelessWidget {
  /// Controla o tema e a ampliação de texto escolhidos pela pessoa.
  final ControladorAparencia controlador;

  /// Onde fica o identificador do último acesso (FR-012).
  final UltimoAcesso ultimoAcesso;

  /// Cria a raiz do aplicativo.
  const AplicativoMemora({
    required this.controlador,
    required this.ultimoAcesso,
    super.key,
  });

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
            home: CasaDemonstracao(ultimoAcesso: ultimoAcesso),
          );
        },
      ),
    );
  }
}
