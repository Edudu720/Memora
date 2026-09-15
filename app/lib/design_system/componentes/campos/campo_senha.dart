import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../texto/texto_memora.dart';
import 'campo_texto.dart';

/// Campo de senha, com controle de revelar rotulado em texto.
///
/// ## O controle de revelar tem rótulo escrito
///
/// Um ícone de olho é ambíguo: muita gente não sabe se ele mostra ou esconde.
/// Aqui o controle diz *"Mostrar senha"* ou *"Esconder senha"* por extenso.
///
/// ## Desativável para o cadastro assistido
///
/// Quando [permitirRevelar] é falso, não há como exibir a senha na tela. Isso
/// atende à FR-060 da feature 001: no cadastro assistido, o acompanhante está
/// ao lado, e revelar a senha entregaria a ele o segredo que o modo assistido
/// existe justamente para proteger.
class CampoSenha extends StatefulWidget {
  /// Nome do campo.
  final String rotulo;

  /// Para que serve este dado, em linguagem comum.
  final String textoAjuda;

  /// Controlador do conteúdo digitado.
  final TextEditingController? controlador;

  /// Mensagem de erro.
  final String? erro;

  /// Chamada a cada alteração.
  final ValueChanged<String>? aoMudar;

  /// Permite exibir a senha em texto claro.
  ///
  /// Passe `false` no cadastro assistido (FR-060 da feature 001).
  final bool permitirRevelar;

  /// Cria um campo de senha.
  const CampoSenha({
    required this.rotulo,
    required this.textoAjuda,
    this.controlador,
    this.erro,
    this.aoMudar,
    this.permitirRevelar = true,
    super.key,
  });

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _revelada = false;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CampoTexto(
          rotulo: widget.rotulo,
          textoAjuda: widget.textoAjuda,
          controlador: widget.controlador,
          erro: widget.erro,
          aoMudar: widget.aoMudar,
          ocultarConteudo: !(_revelada && widget.permitirRevelar),
        ),
        if (widget.permitirRevelar) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.sm),
          Semantics(
            button: true,
            label: _revelada ? 'Esconder senha' : 'Mostrar senha',
            onTap: () => setState(() => _revelada = !_revelada),
            child: ExcludeSemantics(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _revelada = !_revelada),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: MemoraDimensoes.alvoMinimo,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _revelada ? Icons.visibility_off : Icons.visibility,
                          color: cores.primaria,
                          size: 24,
                        ),
                        const SizedBox(width: MemoraEspacamento.sm),
                        // Rótulo por extenso: ícone de olho sozinho é ambíguo.
                        //
                        // O `Flexible` não é enfeite. Sem ele o rótulo exige a
                        // largura natural, e ela cresce com a ampliação: num
                        // 320×568 estourava 31 px pela direita **já em 100%**,
                        // e 265 px em 200%. Com ele o texto quebra em duas
                        // linhas — o mesmo que o `BotaoBase` já faz. Encurtar
                        // o rótulo não é alternativa: ele existe justamente
                        // porque o ícone sozinho não diz o que faz.
                        Flexible(
                          child: TextoMemora(
                            _revelada ? 'Esconder senha' : 'Mostrar senha',
                            cor: cores.primaria,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
