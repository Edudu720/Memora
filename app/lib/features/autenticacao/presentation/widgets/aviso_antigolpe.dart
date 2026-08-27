import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

/// Aviso permanente de que o Memora nunca pede senha nem código (FR-023, T071).
///
/// ## Por que é permanente, e não um alerta que aparece
///
/// A FR-023 pede aviso **permanente** na tela de recuperação, e a razão está na
/// tabela de ameaças da spec: *"ligar dizendo ser o suporte do Memora e pedir a
/// senha"*. O golpe não acontece dentro do aplicativo — acontece ao telefone,
/// com a pessoa olhando exatamente esta tela enquanto alguém a instrui do outro
/// lado da linha.
///
/// Um alerta que some depois de alguns segundos, ou que precisa ser fechado,
/// não estaria mais lá no momento em que a pergunta é feita. Este fica.
///
/// ## Por que fala do número, e não só da senha
///
/// O texto da FR-023 menciona senha. Mas o golpe **desta tela** pede o número
/// de 6 dígitos: o golpista dispara a recuperação com o e-mail da vítima, liga
/// dizendo ser o suporte e pede "o código que acabou de chegar". Avisar só
/// sobre a senha deixaria de fora justamente o dado que está sendo digitado.
///
/// ## Por que não é um componente do Design System
///
/// Ele diz uma frase específica de um fluxo específico. Um componente genérico
/// de aviso convidaria a reescrever o texto em cada uso — e o valor deste aviso
/// está em ser sempre o mesmo, para virar reconhecível.
///
/// Como todo bloco de informação, **não aceita toque** e não usa preenchimento
/// com a cor primária: pílula e preenchimento são linguagem de ação (FR-012).
class AvisoAntigolpe extends StatelessWidget {
  /// Chave usada pelos testes para confirmar que o aviso está na tela.
  static const Key chave = Key('recuperacao.aviso_antigolpe');

  /// Cria o aviso.
  const AvisoAntigolpe({super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      key: chave,
      button: false,
      readOnly: true,
      label: TextosAutenticacao.tituloAvisoAntigolpe,
      value: TextosAutenticacao.avisoAntigolpe,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          decoration: BoxDecoration(
            color: cores.superficieAlt,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            // A borda é o que separa este bloco do resto da tela sem recorrer a
            // preenchimento forte, que o leria como botão.
            border: Border.all(color: cores.perigo, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.shield_outlined, size: 28, color: cores.perigo),
                  const SizedBox(width: MemoraEspacamento.sm),
                  Expanded(
                    child: TextoMemora(
                      TextosAutenticacao.tituloAvisoAntigolpe,
                      estilo: EstiloTexto.corpoForte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              const TextoMemora(TextosAutenticacao.avisoAntigolpe),
            ],
          ),
        ),
      ),
    );
  }
}
