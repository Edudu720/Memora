import 'package:flutter/material.dart';

import '../../../design_system/componentes/botoes/botao_terciario.dart';
import '../../../design_system/componentes/cartoes/caixa_de_etapa.dart';
import '../../../design_system/componentes/cartoes/cartao_de_porta.dart';
import '../../../design_system/componentes/ilustracao/ilustracao_memora.dart';
import '../../../design_system/componentes/navegacao/cabecalho_de_tela.dart';
import '../../../design_system/temas/memora_theme_extension.dart';
import '../../../design_system/tokens/espacamento.dart';
import '../../../l10n/textos_configuracoes.dart';

/// A raiz do destino Ajustes (US7, FR-038): as quatro portas.
///
/// ## Quatro grupos, e só os que existem
///
/// Aparência, Acessibilidade, Privacidade e Conta. "Notificações" e "Idiomas"
/// do wireframe só aparecem quando existirem (FR-038): porta que não abre
/// nada é pior que porta que não existe (FR-018).
///
/// **Acessibilidade não mora dentro de Aparência.** Foi separada na revisão da
/// T044: escondê-la lá a trata como gosto, e para parte das pessoas é
/// condição de uso.
///
/// ## A saída não está aqui
///
/// Sair mora em Conta (FR-019, FR-041), e não ao lado das portas: um toque
/// errado numa lista de ajustes não pode custar a sessão.
///
/// ## A galeria
///
/// [aoAbrirGaleria] é nulo fora do `kDebugMode` (R9 da 002), e aí a linha não
/// existe: em release não há botão que leve a uma recusa.
class TelaConfiguracoes extends StatelessWidget {
  /// Abre Aparência.
  final VoidCallback aoAbrirAparencia;

  /// Abre Acessibilidade.
  final VoidCallback aoAbrirAcessibilidade;

  /// Abre Privacidade.
  final VoidCallback aoAbrirPrivacidade;

  /// Abre Conta.
  final VoidCallback aoAbrirConta;

  /// Abre a galeria. Nulo fora do modo de desenvolvimento.
  final VoidCallback? aoAbrirGaleria;

  /// Cria Ajustes.
  const TelaConfiguracoes({
    required this.aoAbrirAparencia,
    required this.aoAbrirAcessibilidade,
    required this.aoAbrirPrivacidade,
    required this.aoAbrirConta,
    this.aoAbrirGaleria,
    super.key,
  });

  /// Chave da porta de Aparência.
  static const Key chaveAparencia = Key('ajustes.aparencia');

  /// Chave da porta de Acessibilidade.
  static const Key chaveAcessibilidade = Key('ajustes.acessibilidade');

  /// Chave da porta de Privacidade.
  static const Key chavePrivacidade = Key('ajustes.privacidade');

  /// Chave da porta de Conta.
  static const Key chaveConta = Key('ajustes.conta');

  /// Chave da linha da galeria.
  static const Key chaveGaleria = Key('ajustes.galeria');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: ListView(
        children: <Widget>[
          const CabecalhoDeTela(
            titulo: TextosConfiguracoes.tituloAjustes,
            ilustracao: Ilustracao.ajusteAparencia,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraEspacamento.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Os desenhos de Acessibilidade, Privacidade e Conta ainda não
                // existem (T011): cada porta usa o que já há, e a revisão de
                // design troca quando os desenhos chegarem.
                CaixaDeEtapa(
                  instrucao: TextosConfiguracoes.instrucaoAjustes,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CartaoDePorta(
                        key: chaveAparencia,
                        nome: TextosConfiguracoes.portaAparencia,
                        explicacao: TextosConfiguracoes.descricaoAparencia,
                        ilustracao: Ilustracao.ajusteAparencia,
                        aoAbrir: aoAbrirAparencia,
                      ),
                      const SizedBox(height: MemoraEspacamento.md),
                      CartaoDePorta(
                        key: chaveAcessibilidade,
                        nome: TextosConfiguracoes.portaAcessibilidade,
                        explicacao: TextosConfiguracoes.descricaoAcessibilidade,
                        ilustracao: Ilustracao.pessoaComCelular,
                        aoAbrir: aoAbrirAcessibilidade,
                      ),
                      const SizedBox(height: MemoraEspacamento.md),
                      CartaoDePorta(
                        key: chavePrivacidade,
                        nome: TextosConfiguracoes.portaPrivacidade,
                        explicacao: TextosConfiguracoes.descricaoPrivacidade,
                        ilustracao: Ilustracao.portaRegistro,
                        aoAbrir: aoAbrirPrivacidade,
                      ),
                      const SizedBox(height: MemoraEspacamento.md),
                      CartaoDePorta(
                        key: chaveConta,
                        nome: TextosConfiguracoes.portaConta,
                        explicacao: TextosConfiguracoes.descricaoConta,
                        ilustracao: Ilustracao.casalIdoso,
                        aoAbrir: aoAbrirConta,
                      ),
                    ],
                  ),
                ),
                if (aoAbrirGaleria != null) ...<Widget>[
                  const SizedBox(height: MemoraEspacamento.xl),
                  BotaoTerciario(
                    key: chaveGaleria,
                    rotulo: TextosConfiguracoes.galeria,
                    aoTocar: aoAbrirGaleria,
                  ),
                ],
                const SizedBox(height: MemoraEspacamento.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
