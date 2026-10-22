import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../l10n/textos_casca.dart';
import '../perfil/data/data_de_nascimento_local.dart';
import '../perfil/presentation/secao_idade.dart';

/// A raiz do destino Meu perfil, **provisória até a US8** (T097).
///
/// Mostra o que o Memora já sabe — nome e canal —, como **informação**, e
/// nunca como botão (FR-012 da 002). O canal vem do identificador do último
/// acesso, que o aparelho já guarda (R10): nenhuma chamada nova ao servidor.
///
/// Embute a [SecaoIdade] (T123): a idade, se a pessoa quis informar, ou o
/// convite para informar. A tela definitiva (T097) reaproveita o mesmo widget.
class PerfilProvisorio extends StatelessWidget {
  /// Como a pessoa quer ser chamada.
  final String nome;

  /// O canal da conta, quando o aparelho o tem.
  final Future<String?> canal;

  /// Onde a data de nascimento fica guardada, por conta (FR-042c).
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// A conta de quem é o Perfil. Sem ela — ausente, vazia ou só espaços — não
  /// há de quem guardar a idade, e a seção não aparece: com id vazio, todas as
  /// contas cairiam na mesma chave e uma veria a idade da outra.
  final String? idDaConta;

  /// Cria a raiz provisória.
  const PerfilProvisorio({
    required this.nome,
    required this.canal,
    this.dataDeNascimento,
    this.idDaConta,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: ListView(
        children: <Widget>[
          const CabecalhoDeTela(
            titulo: TextosCasca.tituloPerfil,
            memora: ExpressaoDaMemora.neutra,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraEspacamento.lg,
            ),
            child: FutureBuilder<String?>(
              future: canal,
              builder: (BuildContext _, AsyncSnapshot<String?> canal) =>
                  ListaInformacao(
                    campos: <CampoInformacao>[
                      CampoInformacao(
                        rotulo: TextosCasca.rotuloNome,
                        valor: nome,
                      ),
                      if (canal.data != null)
                        CampoInformacao(
                          rotulo: TextosCasca.rotuloCanal,
                          valor: canal.data!,
                        ),
                    ],
                  ),
            ),
          ),
          if (dataDeNascimento != null &&
              idDaConta != null &&
              idDaConta!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: SecaoIdade(
                armazenamento: dataDeNascimento!,
                idDaConta: idDaConta!,
              ),
            ),
        ],
      ),
    );
  }
}
