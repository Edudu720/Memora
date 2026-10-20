import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_casca.dart';

/// O Início: a raiz do destino de mesmo nome (T037 e T115, FR-014 da feature
/// 004).
///
/// ## A tela que a pessoa mais verá
///
/// É para onde ela chega ao entrar e para onde o "me tira daqui" da barra
/// inferior a devolve. A Memora a cumprimenta pelo nome de tratamento, **diz em
/// uma frase o que se faz ali** e mostra o caminho para o que ela mais faz —
/// conversar —, mais um para ver tudo o que o aplicativo tem.
///
/// ## A Memora ensina a tela (R2, regra 9)
///
/// A revisão da T044 achou o Início "simples demais": uma saudação e dois
/// botões, e quem nunca usou o aplicativo sem saber o que esperar. A frase de
/// tutorial fica num balão da Memora, logo abaixo da saudação.
///
/// **Ela aparece sempre**, e não só na primeira vez: o Início é a tela-casa, a
/// frase é curta, e ainda não há onde guardar "já vi" por pessoa. Quando
/// houver, é aqui que a decisão de esconder a frase passa a existir — e
/// esconder só pode valer para quem de fato já a leu.
///
/// ## Cada atalho numa caixa que diz para que serve (FR-002a)
///
/// "Conversar com a Memora" sozinho diz o que o botão faz, não **quando**
/// tocá-lo. Cada atalho mora numa `CaixaDeEtapa` cuja frase responde a isso
/// ("Tem uma dúvida sobre o celular? Converse comigo."), escrita ao lado do
/// botão e não num parágrafo lá em cima.
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
/// 003 proíbe — e a **caixa dele** some junto, porque uma instrução sem o que
/// tocar é a mesma porta pintada. Sem atalho nenhum, some também a frase de
/// tutorial: ela apontaria para o nada.
///
/// ## Não há "Sair" aqui (FR-019)
///
/// Sair fica em Ajustes → Conta. Era o botão do lado das portas do Hub, e um
/// toque errado custava a sessão inteira.
///
/// ## O espaço da tela, repartido
///
/// Na primeira versão o conteúdo era empilhado no topo e, num 390×844, metade
/// da tela ficava vazia (T044: "vazio embaixo"). Agora o conteúdo tem **no
/// mínimo** a altura da área útil, e o que sobra vira respiro igual em cima, no
/// meio e embaixo — conta em fração, refeita por aparelho, nunca em pixel.
///
/// ## A Memora cede espaço, o texto e a ação não
///
/// O desenho ocupa uma fração da altura disponível e some abaixo do piso (regra
/// 7 da R2). Sem sobra de altura — pouca tela, ampliação alta — o respiro vai a
/// zero, a tela rola e a ação principal continua alcançável em qualquer
/// ampliação.
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

  /// Chave do balão com a frase de tutorial.
  static const Key chaveTutorial = Key('inicio.tutorial');

  /// Chave da caixa do atalho para a conversa.
  static const Key chaveCaixaConversar = Key('inicio.caixaConversar');

  /// Chave da caixa do atalho para ver tudo.
  static const Key chaveCaixaVerTudo = Key('inicio.caixaVerTudo');

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
    final int atalhos =
        (aoConversar != null ? 1 : 0) + (aoVerTudo != null ? 1 : 0);

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints caixa) {
            // A figura cede primeiro, e a conta é refeita por aparelho
            // (regra 3): fração da altura, nunca pixel.
            final double cabe =
                caixa.maxHeight * MemoraDimensoes.fracaoDaFiguraDoInicio;
            final double figura = cabe < MemoraDimensoes.ilustracaoHeroi
                ? cabe
                : MemoraDimensoes.ilustracaoHeroi;

            // A altura que o conteúdo ocupa **no mínimo**: a da área útil,
            // menos o respiro de cima e de baixo da rolagem. Sobrando espaço,
            // o `Column` abaixo o reparte entre os blocos; faltando, a tela
            // rola.
            final double alturaMinima =
                (caixa.maxHeight - 2 * MemoraEspacamento.lg).clamp(
                  0.0,
                  double.infinity,
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: alturaMinima),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Topo alinhado com o design: Saudação à esquerda, Memora à direita
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: MemoraEspacamento.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextoMemora(
                                  TextosCasca.inicioSaudacao(nome),
                                  key: chaveSaudacao,
                                  estilo: EstiloTexto.destaque,
                                  cabecalho: true,
                                ),
                              ),
                              if (figura >=
                                  MemoraDimensoes.pisoDeIlustracao) ...<Widget>[
                                const SizedBox(width: MemoraEspacamento.md),
                                MemoraPersonagem(
                                  key: chaveMemora,
                                  tamanho: figura.clamp(48.0, 72.0),
                                ),
                              ],
                            ],
                          ),
                          if (atalhos > 0) ...<Widget>[
                            const SizedBox(height: MemoraEspacamento.md),
                            BalaoDeFala(
                              key: chaveTutorial,
                              autor: AutorDoBalao.memora,
                              texto: TextosCasca.inicioTutorial(atalhos),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (atalhos > 0)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (aoConversar != null)
                            CaixaDeEtapa(
                              key: chaveCaixaConversar,
                              instrucao: TextosCasca.inicioInstrucaoConversar,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  BotaoPrimario(
                                    key: chaveConversar,
                                    rotulo: TextosCasca.inicioConversar,
                                    icone: Icons.chat_bubble_rounded,
                                    aoTocar: aoConversar,
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: MemoraDimensoes.iconePequeno,
                                        color: cores.sucesso,
                                      ),
                                      const SizedBox(width: MemoraEspacamento.xs),
                                      const Expanded(
                                        child: TextoMemora.apoio(
                                          'Tire d\xc3\xbavidas sobre celular, aplicativos e internet',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (aoConversar != null && aoVerTudo != null)
                            const SizedBox(height: MemoraEspacamento.lg),
                          if (aoVerTudo != null)
                            CaixaDeEtapa(
                              key: chaveCaixaVerTudo,
                              instrucao: TextosCasca.inicioInstrucaoVerTudo,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  conversarEPrincipal
                                      ? BotaoSecundario(
                                          key: chaveVerTudo,
                                          rotulo: TextosCasca.inicioVerTudo,
                                          icone: Icons.apps_rounded,
                                          aoTocar: aoVerTudo,
                                        )
                                      : BotaoPrimario(
                                          key: chaveVerTudo,
                                          rotulo: TextosCasca.inicioVerTudo,
                                          icone: Icons.apps_rounded,
                                          aoTocar: aoVerTudo,
                                        ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.grid_view_rounded,
                                        size: MemoraDimensoes.iconePequeno,
                                        color: cores.primaria,
                                      ),
                                      const SizedBox(width: MemoraEspacamento.xs),
                                      const Expanded(
                                        child: TextoMemora.apoio(
                                          'WhatsApp, Gov.br, fotos, ajuda e registros',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
