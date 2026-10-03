import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../l10n/textos_autenticacao.dart';
import '../../l10n/textos_casca.dart';
import '../autenticacao/presentation/widgets/saida_com_confirmacao.dart';
import '../perfil/data/data_de_nascimento_local.dart';
import '../perfil/presentation/secao_idade.dart';

/// A raiz do destino Ajustes, **provisória até a US7** (T092).
///
/// Provisória não quer dizer vazia: destino da barra que não abre nada seria a
/// porta pintada na parede que a FR-018 proíbe. Ela já tem o que funciona
/// hoje — a aparência e a saída — e a galeria só no modo de desenvolvimento.
class AjustesProvisorios extends StatelessWidget {
  /// Abre a tela de aparência.
  final VoidCallback aoAbrirAparencia;

  /// Abre a galeria. Nula fora do `kDebugMode`, e aí a linha não existe (R9 da
  /// 002): em release não há botão que leve a uma recusa.
  final VoidCallback? aoAbrirGaleria;

  /// Encerra a sessão, depois da confirmação (FR-025 da 001).
  final Future<void> Function() aoSair;

  /// Cria a raiz provisória.
  const AjustesProvisorios({
    required this.aoAbrirAparencia,
    required this.aoSair,
    this.aoAbrirGaleria,
    super.key,
  });

  /// Chave da porta de aparência.
  static const Key chaveAparencia = Key('ajustes.aparencia');

  /// Chave da linha da galeria.
  static const Key chaveGaleria = Key('ajustes.galeria');

  /// Chave do botão de sair.
  static const Key chaveSair = Key('ajustes.sair');

  /// Chave da confirmação de saída.
  static const Key chaveConfirmacao = Key('ajustes.confirmacao');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: ListView(
        children: <Widget>[
          const CabecalhoDeTela(
            titulo: TextosCasca.tituloAjustes,
            ilustracao: Ilustracao.ajusteAparencia,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraEspacamento.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CartaoDePorta(
                  key: chaveAparencia,
                  nome: TextosCasca.portaAparencia,
                  explicacao: TextosCasca.descricaoAparencia,
                  ilustracao: Ilustracao.ajusteAparencia,
                  aoAbrir: aoAbrirAparencia,
                ),
                if (aoAbrirGaleria != null) ...<Widget>[
                  const SizedBox(height: MemoraEspacamento.md),
                  BotaoTerciario(
                    key: chaveGaleria,
                    rotulo: TextosCasca.galeria,
                    aoTocar: aoAbrirGaleria,
                  ),
                ],
                const SizedBox(height: MemoraEspacamento.xxl),
                SaidaComConfirmacao(
                  chaveConfirmacao: chaveConfirmacao,
                  aoConfirmar: aoSair,
                  botao: (VoidCallback aoTocar) => BotaoSecundario(
                    key: chaveSair,
                    rotulo: TextosAutenticacao.botaoSair,
                    icone: Icons.logout,
                    aoTocar: aoTocar,
                  ),
                ),
                const SizedBox(height: MemoraEspacamento.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

  /// Cria a raiz provisória.
  /// Onde a data de nascimento fica guardada, por conta (FR-042c).
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// A conta de quem é o Perfil. Sem ela não há de quem guardar a idade, e a
  /// seção não aparece.
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
          if (dataDeNascimento != null && idDaConta != null)
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
