import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_casca.dart';

/// O Início: a raiz do destino de mesmo nome (T037, FR-014 da feature 004).
///
/// ## A tela que a pessoa mais verá
///
/// É para onde ela chega ao entrar e para onde o "me tira daqui" da barra
/// inferior a devolve. A Memora a cumprimenta pelo nome de tratamento e mostra
/// o caminho para o que ela mais faz — conversar —, mais um para ver tudo o
/// que o aplicativo tem.
///
/// ## Dois atalhos, uma ação principal
///
/// Conversar é a razão de o Memora existir, e por isso é o botão preenchido
/// (FR-002). "Ver tudo" é secundário. Sem a assistente, só resta o segundo, e
/// aí ele passa a ser o principal: uma tela com um único caminho não o
/// apresenta como se fosse a segunda opção.
///
/// ## Só o que existe (FR-018)
///
/// Cada atalho é opcional: quem monta o fluxo só entrega o que leva a algum
/// lugar. Um botão sem destino seria a porta pintada na parede que a FR-003 da
/// 003 proíbe.
///
/// ## Não há "Sair" aqui (FR-019)
///
/// Sair fica em Ajustes → Conta. Era o botão do lado das portas do Hub, e um
/// toque errado custava a sessão inteira.
///
/// ## A Memora cede espaço, o texto e a ação não
///
/// O desenho ocupa uma fração da altura disponível e some abaixo do piso (regra
/// 7 da R2). A tela rola, de modo que a ação principal continua alcançável em
/// qualquer ampliação.
///
/// ## Estados da FR-006
///
/// Esta tela **não carrega nada**: o nome já veio da sessão e os atalhos são
/// dados prontos. Não há "carregando", "vazio" nem "erro" a desenhar.
class TelaInicio extends StatelessWidget {
  /// Chave da saudação, usada pelos testes — e o sinal de que a pessoa está
  /// dentro da conta.
  static const Key chaveSaudacao = Key('inicio.saudacao');

  /// Chave do atalho para a conversa.
  static const Key chaveConversar = Key('inicio.conversar');

  /// Chave do atalho para ver todas as partes.
  static const Key chaveVerTudo = Key('inicio.verTudo');

  /// Chave da Memora.
  static const Key chaveMemora = Key('inicio.memora');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// Abre a conversa. Nulo quando não há assistente, e aí o atalho não existe.
  final VoidCallback? aoConversar;

  /// Abre o Hub. Nulo quando não há nada para mostrar nele.
  final VoidCallback? aoVerTudo;

  /// Cria o Início.
  const TelaInicio({
    required this.nome,
    this.aoConversar,
    this.aoVerTudo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool conversarEPrincipal = aoConversar != null;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints caixa) {
            // A figura cede primeiro, e a conta é refeita por aparelho
            // (regra 3): fração da altura, nunca pixel.
            final double cabe =
                caixa.maxHeight * MemoraDimensoes.fracaoDaIlustracaoHeroi;
            final double figura = cabe < MemoraDimensoes.ilustracaoHeroi
                ? cabe
                : MemoraDimensoes.ilustracaoHeroi;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (figura >= MemoraDimensoes.pisoDeIlustracao) ...<Widget>[
                    Center(
                      child: MemoraPersonagem(
                        key: chaveMemora,
                        tamanho: figura,
                      ),
                    ),
                    const SizedBox(height: MemoraEspacamento.xl),
                  ],
                  TextoMemora(
                    TextosCasca.inicioSaudacao(nome),
                    key: chaveSaudacao,
                    estilo: EstiloTexto.destaque,
                    cabecalho: true,
                    alinhamento: TextAlign.center,
                  ),
                  const SizedBox(height: MemoraEspacamento.sm),
                  const TextoMemora(
                    TextosCasca.inicioConvite,
                    alinhamento: TextAlign.center,
                  ),
                  if (aoConversar != null || aoVerTudo != null) ...<Widget>[
                    const SizedBox(height: MemoraEspacamento.xxl),
                    if (aoConversar != null)
                      BotaoPrimario(
                        key: chaveConversar,
                        rotulo: TextosCasca.inicioConversar,
                        icone: Icons.chat_bubble_outline,
                        aoTocar: aoConversar,
                      ),
                    if (aoConversar != null && aoVerTudo != null)
                      const SizedBox(height: MemoraEspacamento.md),
                    if (aoVerTudo != null)
                      conversarEPrincipal
                          ? BotaoSecundario(
                              key: chaveVerTudo,
                              rotulo: TextosCasca.inicioVerTudo,
                              icone: Icons.apps_outlined,
                              aoTocar: aoVerTudo,
                            )
                          : BotaoPrimario(
                              key: chaveVerTudo,
                              rotulo: TextosCasca.inicioVerTudo,
                              icone: Icons.apps_outlined,
                              aoTocar: aoVerTudo,
                            ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
