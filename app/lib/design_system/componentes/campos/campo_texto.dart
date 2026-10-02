import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';

/// Campo de texto do Memora.
///
/// ## Duas regras que o protótipo não seguia
///
/// 1. **Rótulo acima e sempre visível.** No protótipo os campos tinham apenas
///    uma linha inferior. Rótulo que some ao digitar obriga a pessoa a lembrar
///    o que estava preenchendo — e ela não vai lembrar.
/// 2. **`textoAjuda` obrigatório**, explicando para que o dado serve
///    (FR-004 da feature 001). Um campo sem explicação é um campo que o idoso
///    preenche errado ou abandona.
///
/// Erros são comunicados por **ícone e texto**, nunca só por cor (FR-032).
class CampoTexto extends StatelessWidget {
  /// Nome do campo, exibido acima e sempre visível.
  final String rotulo;

  /// Para que serve este dado, em linguagem comum. **Obrigatório.**
  final String textoAjuda;

  /// Controlador do conteúdo digitado.
  final TextEditingController? controlador;

  /// Mensagem de erro. Quando presente, o campo entra em estado de erro.
  final String? erro;

  /// Tipo de teclado oferecido.
  final TextInputType tipoTeclado;

  /// Filtros de entrada.
  final List<TextInputFormatter>? formatadores;

  /// Chamada a cada alteração.
  final ValueChanged<String>? aoMudar;

  /// Oculta o conteúdo digitado.
  final bool ocultarConteudo;

  /// Elemento exibido ao final do campo, como o controle de revelar senha.
  final Widget? sufixo;

  /// Habilita ou desabilita a edição.
  final bool habilitado;

  /// Cria um campo de texto.
  const CampoTexto({
    required this.rotulo,
    required this.textoAjuda,
    this.controlador,
    this.erro,
    this.tipoTeclado = TextInputType.text,
    this.formatadores,
    this.aoMudar,
    this.ocultarConteudo = false,
    this.sufixo,
    this.habilitado = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool temErro = erro != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Rótulo acima, sempre visível. Placeholder não é rótulo.
        TextoMemora(rotulo, estilo: EstiloTexto.corpoForte),
        const SizedBox(height: MemoraEspacamento.xs),
        TextoMemora.apoio(textoAjuda),
        const SizedBox(height: MemoraEspacamento.sm),
        Semantics(
          textField: true,
          label: rotulo,
          hint: textoAjuda,
          enabled: habilitado,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraDimensoes.alvoDecisao,
            ),
            child: TextField(
              controller: controlador,
              onChanged: aoMudar,
              obscureText: ocultarConteudo,
              keyboardType: tipoTeclado,
              inputFormatters: formatadores,
              enabled: habilitado,
              style: MemoraTipografia.corpo.copyWith(color: cores.texto),
              decoration: InputDecoration(
                filled: true,
                fillColor: habilitado ? cores.superficie : cores.superficieAlt,
                suffixIcon: sufixo,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MemoraEspacamento.lg,
                  vertical: MemoraEspacamento.lg,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  borderSide: BorderSide(
                    color: temErro ? cores.perigo : cores.borda,
                    width: temErro ? 3 : 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  borderSide: BorderSide(
                    color: temErro ? cores.perigo : cores.primaria,
                    width: MemoraDimensoes.bordaSelecao,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  borderSide: BorderSide(color: cores.borda),
                ),
              ),
            ),
          ),
        ),
        if (temErro) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.sm),
          // Ícone E texto: erro nunca é comunicado apenas por cor.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline,
                  color: cores.perigo,
                  size: MemoraDimensoes.iconePadrao),
              const SizedBox(width: MemoraEspacamento.sm),
              Expanded(
                child: TextoMemora(erro!, estilo: EstiloTexto.apoio,
                    cor: cores.perigo),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
