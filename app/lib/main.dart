import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_system/design_system.dart';
import 'features/assistente/data/abridor_de_aplicativo.dart';
import 'features/assistente/data/aceite_do_aviso.dart';
import 'features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'features/autenticacao/data/ultimo_acesso_local.dart';
import 'services/ambiente/ambiente.dart';
import 'services/ambiente/composicao.dart';
import 'services/preferencias/repositorio_preferencia_aparencia_local.dart';
import 'services/seguranca/cofre_de_credenciais.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registrarLicencasEmbarcadas();
  final RepositorioPreferenciaAparenciaLocal repositorio =
      await RepositorioPreferenciaAparenciaLocal.abrir();
  final ControladorAparencia controlador = ControladorAparencia(repositorio);
  await controlador.carregar();

  final UltimoAcessoLocal ultimoAcesso = await UltimoAcessoLocal.abrir();
  final AceiteDoAvisoLocal aceiteDoAviso = await AceiteDoAvisoLocal.abrir();

  // A escolha entre servidor real e simulado acontece aqui, e em nenhum outro
  // lugar. Ver `services/ambiente/composicao.dart`.
  final Composicao composicao = Composicao.resolver(
    ambiente: Ambiente.doAmbiente(),
    cofre: CofreSeguroDoSistema(),
    ultimoAcesso: ultimoAcesso,
    aceiteDoAviso: aceiteDoAviso,
  );

  final String? aviso = composicao.avisoDeIntegracaoParcial;
  if (aviso != null) {
    debugPrint('[Memora] $aviso');
  }

  runApp(
    AplicativoMemora(
      controlador: controlador,
      ultimoAcesso: ultimoAcesso,
      composicao: composicao,
    ),
  );
}

/// Raiz do aplicativo Memora.
///
/// A raiz leva direto ao fluxo de autenticação, que, com a pessoa dentro,
/// monta a casca com a barra inferior (R1 da feature 004).
class AplicativoMemora extends StatelessWidget {
  /// Controla o tema e a ampliação de texto escolhidos pela pessoa.
  final ControladorAparencia controlador;

  /// Onde fica o identificador do último acesso (FR-012).
  final UltimoAcesso ultimoAcesso;

  /// Com quem o aplicativo conversa — servidor real ou simulado.
  final Composicao composicao;

  /// Cria a raiz do aplicativo.
  const AplicativoMemora({
    required this.controlador,
    required this.ultimoAcesso,
    required this.composicao,
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
            // O aplicativo de verdade, sem a casca de demonstração que existiu
            // até a feature 004 (FR-007): quem abre o Memora não vê aba de
            // desenvolvimento nenhuma. A galeria continua existindo só no
            // modo de depuração, em Ajustes (R1).
            //
            // Quem escolheu entre servidor real e simulado foi a Composicao,
            // na subida; o fluxo não sabe — e não deve saber — com qual fala.
            home: FluxoAutenticacao(
              repositorio: composicao.autenticacao,
              ultimoAcesso: ultimoAcesso,
              limpeza: composicao.limpeza,
              assistente: composicao.assistente,
              aceiteDoAviso: composicao.aceiteDoAviso,
              abridor: const AbridorDeAplicativoAndroid(),
            ),
          );
        },
      ),
    );
  }
}

/// Põe a licença da fonte embarcada na lista de licenças do aplicativo.
///
/// A OFL permite embarcar a Atkinson Hyperlegible Next, desde que a licença
/// viaje junto. Só o resumo que vai dentro do próprio `.ttf` já bastaria;
/// registrar o texto inteiro deixa isso sem dúvida (revisão da #38).
void registrarLicencasEmbarcadas() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      <String>['Atkinson Hyperlegible Next'],
      await rootBundle.loadString(
        'assets/fontes/atkinson_hyperlegible_next/OFL.txt',
      ),
    );
  });
}
