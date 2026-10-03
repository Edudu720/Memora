package br.fatec.memora

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * O canal `memora/aplicativos` (T058, contrato `canal-aplicativos.md`).
 *
 * Responde duas perguntas que o Flutter nao responde sozinho: este aplicativo
 * esta instalado, e qual e o icone dele.
 *
 * Regras do contrato, uma a uma:
 *
 *  1. So le. Nao ha metodo `abrir`: abrir e do `AbridorDeAplicativo`, que passa
 *     pela confirmacao e pelo registro.
 *  2. So enxerga o que esta em `<queries>` (Android 11+). Pacote fora da lista
 *     aparece como "nao instalado" -- e esta certo, o Memora nao pede
 *     `QUERY_ALL_PACKAGES`.
 *  3. Recusa o que nao parece pacote, sem consultar o sistema.
 *  4. Nenhuma permissao nova.
 *
 * Nada aqui lanca para o Dart: toda falha vira `false` ou `null`.
 */
class CanalDeAplicativos(private val packageManager: PackageManager) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NOME = "memora/aplicativos"

        /** Lado do PNG devolvido, em pixels. */
        const val LADO_DO_ICONE = 192

        /** A mesma forma que o lado Dart confere. Mantenha as duas iguais. */
        private val FORMA_DE_PACOTE =
            Regex("""^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$""")

        /** Registra o canal no motor do Flutter. */
        fun registrar(executor: DartExecutor, packageManager: PackageManager) {
            MethodChannel(executor.binaryMessenger, NOME)
                .setMethodCallHandler(CanalDeAplicativos(packageManager))
        }

        /** O argumento so e aceito se for texto e tiver forma de pacote. */
        fun pacoteValido(argumento: Any?): String? {
            val texto = argumento as? String ?: return null
            return if (FORMA_DE_PACOTE.matches(texto)) texto else null
        }
    }

    // Renderizar icone nao deve segurar a thread principal: a grade pede
    // varios de uma vez. O resultado volta para a principal, que e onde o
    // MethodChannel exige responder.
    private val trabalho: ExecutorService = Executors.newSingleThreadExecutor()
    private val principal = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "estaInstalado" -> responder(result, false) { estaInstalado(call.arguments) }
            "iconeDe" -> responder(result, null) { iconeDe(call.arguments) }
            else -> result.notImplemented()
        }
    }

    private fun <T> responder(result: MethodChannel.Result, padrao: T, tarefa: () -> T) {
        trabalho.execute {
            val resposta = try {
                tarefa()
            } catch (_: Throwable) {
                padrao
            }
            principal.post { result.success(resposta) }
        }
    }

    private fun estaInstalado(argumento: Any?): Boolean {
        val pacote = pacoteValido(argumento) ?: return false
        return informacoesDe(pacote) != null
    }

    private fun iconeDe(argumento: Any?): ByteArray? {
        val pacote = pacoteValido(argumento) ?: return null
        if (informacoesDe(pacote) == null) return null

        val desenho = packageManager.getApplicationIcon(pacote)
        val imagem = Bitmap.createBitmap(LADO_DO_ICONE, LADO_DO_ICONE, Bitmap.Config.ARGB_8888)
        val tela = Canvas(imagem)
        desenho.setBounds(0, 0, LADO_DO_ICONE, LADO_DO_ICONE)
        desenho.draw(tela)

        val saida = ByteArrayOutputStream()
        imagem.compress(Bitmap.CompressFormat.PNG, 100, saida)
        imagem.recycle()
        return saida.toByteArray()
    }

    private fun informacoesDe(pacote: String): ApplicationInfo? =
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getApplicationInfo(
                    pacote,
                    PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getApplicationInfo(pacote, 0)
            }
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
}
