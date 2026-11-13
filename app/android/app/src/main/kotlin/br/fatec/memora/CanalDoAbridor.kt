package br.fatec.memora

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `memora/abridor` (T136): abre outro aplicativo, e so isso.
 *
 * Por que nao o `android_intent_plus`: ele so traduz alguns apelidos de acao
 * (`action_view` e poucos mais). `action_main` chegava ao Android literal e
 * nenhuma atividade o atendia. Trocar pela constante inteira tambem nao basta:
 * a atividade de entrada dos aplicativos declara MAIN + LAUNCHER, sem
 * CATEGORY_DEFAULT, e a conferencia do plugin (`MATCH_DEFAULT_ONLY`) a
 * recusava. Pior, quando nao resolve, o `launch()` do plugin manda uma intent
 * implicita e o Android abriria um seletor. `getLaunchIntentForPackage` e a
 * pergunta certa: devolve a atividade de entrada que o proprio aplicativo
 * declarou, ou nada.
 *
 * Por que canal separado: o `memora/aplicativos` e so leitura por contrato
 * ("Nao ha metodo abrir"). Abrir muda o que a pessoa ve, e mistura-lo com a
 * leitura apagaria essa garantia.
 *
 * O que este canal NAO decide: se o aplicativo pode ser aberto. Quem decide e
 * o servidor (`AutorizadorDeAcao`) e a pessoa confirma antes; aqui so se
 * executa. Nenhuma permissao nova: so abre o que esta em `<queries>` (sem
 * `QUERY_ALL_PACKAGES`), e o que estiver fora aparece como "nao abriu".
 *
 * Nada aqui lanca para o Dart: toda falha vira `false`.
 */
class CanalDoAbridor(private val contexto: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val NOME = "memora/abridor"

        /** Registra o canal no motor do Flutter. */
        fun registrar(executor: DartExecutor, contexto: Context) {
            MethodChannel(executor.binaryMessenger, NOME)
                .setMethodCallHandler(CanalDoAbridor(contexto.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "abrir" -> result.success(abrir(call.arguments))
            else -> result.notImplemented()
        }
    }

    private fun abrir(argumento: Any?): Boolean =
        try {
            // Mesma forma que o lado Dart confere: o que nao parece pacote nao
            // chega a consultar o sistema.
            val pacote = CanalDeAplicativos.pacoteValido(argumento)
            val intent = pacote?.let { contexto.packageManager.getLaunchIntentForPackage(it) }
            if (intent == null) {
                false
            } else {
                // Fora de uma Activity, iniciar atividade exige NEW_TASK.
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                contexto.startActivity(intent)
                true
            }
        } catch (_: Throwable) {
            false
        }
}
