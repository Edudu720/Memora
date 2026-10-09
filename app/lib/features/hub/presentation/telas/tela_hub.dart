import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_casca.dart';
import '../../domain/hub.dart';

/// Todas as partes do Memora, numa tela (T038, FR-016 da feature 004).
///
/// ## A tela que o Início abre
///
/// O Hub não é mais a raiz de nada: o Início cumprimenta e leva ao que a
/// pessoa mais faz, e este é o "ver tudo". Por isso ele tem **"Voltar"** — a
/// raiz de um destino é que não tem —, no mesmo canto de todas as outras
/// telas (FR-001). O "Sair" que morava aqui foi para Ajustes → Conta
/// (FR-019): quem queria o Hub para escolher uma parte do aplicativo encontrava
/// ao lado dela a porta de saída, e um toque errado custava a sessão.
///
/// ## Ela mostra o que recebe, e só
///
/// A FR-003 da 003 e a FR-018 desta feature exigem que porta sem destino não
/// apareça. A tela não decide isso: ela exibe a lista que lhe passam, e
/// [PortaDoHub] torna o destino obrigatório. Quem sabe o que existe é quem
/// monta o fluxo.
///
/// ## A porta principal sempre à vista, e o aviso de que há mais (FR-017)
///
/// A FR-017 foi reescrita em 2026-10-02. Em qualquer aparelho e em qualquer
/// ampliação a porta principal (conversar com a Memora) aparece sem rolar; no
/// aparelho mais comum (360×800), em 100% e 150%, o Hub inteiro cabe. Fora
/// disso a lista rola — e **precisa dizer que rola**: uma porta cortada na
/// dobra pode ser lida como "a tela acaba aqui", e quem nunca rolou uma
/// lista não procura o que não sabe que existe.
///
/// Por isso, quando há portas abaixo da dobra, uma faixa com seta e a frase
/// "Há mais abaixo" aparece no pé da lista, sobre um esmaecer, e some quando a
/// pessoa chega ao fim. Ela é **informação**: não tem pílula, não tem
/// preenchimento e não recebe toque (FR-012 da 002). O leitor de tela a lê
/// com a frase inteira, gesto incluído ([TextosCasca.hubHaMaisLeitor]).
///
/// É uma faixa **sobreposta** (um `Stack`), e não uma linha a mais na coluna,
/// de propósito: tirar altura da lista para mostrá-la mudaria o que cabe, e
/// ela poderia ligar e desligar a si mesma no limite.
///
/// ## Porta é ação
///
/// Cada porta é um `CartaoDePorta`: pílula preenchida com desenho, nome e uma
/// linha do que há do outro lado. Cartão comum, o `Cartao`, é informação e
/// deliberadamente não aceita toque (FR-012 da 002).
class TelaHub extends StatefulWidget {
  /// Chave da lista de portas, para os testes.
  static const Key chaveLista = Key('hub.lista');

  /// Chave do estado vazio, para os testes.
  static const Key chaveVazio = Key('hub.vazio');

  /// Chave da faixa "há mais abaixo", para os testes. Só existe na árvore
  /// quando há portas abaixo da dobra.
  static const Key chaveHaMais = Key('hub.ha_mais');

  /// Chave de uma porta, pelo rótulo.
  static Key chaveDaPorta(String rotulo) => Key('hub.porta.$rotulo');

  /// As portas construídas. Ver a nota sobre a FR-003.
  final List<PortaDoHub> portas;

  /// Volta ao Início.
  final VoidCallback aoVoltar;

  /// Cria o Hub.
  const TelaHub({required this.portas, required this.aoVoltar, super.key});

  @override
  State<TelaHub> createState() => _TelaHubState();
}

class _TelaHubState extends State<TelaHub> {
  /// O que sobra para rolar abaixo disto não conta como "há mais" (meio dp).
  static const double _folgaMinima = 0.5;

  /// Há o que rolar para baixo. Falso até a primeira medição: o Hub nasce sem
  /// a faixa, e ela aparece no quadro seguinte se for o caso.
  bool _haMais = false;

  /// Lê a posição da lista, tanto quando o conteúdo muda de tamanho (a janela
  /// mudou, a ampliação mudou) quanto quando a pessoa rola.
  bool _aoMedir(ScrollMetrics medidas) {
    // Tolerância de ponto flutuante: ao fim de uma rolagem a posição pode
    // ficar a 1e-13 do limite, e `> 0` deixaria a faixa ligada para sempre; e
    // meio pixel de "mais" não é uma porta.
    final bool haMais = medidas.extentAfter > _folgaMinima;
    if (haMais != _haMais && mounted) {
      setState(() => _haMais = haMais);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final List<PortaDoHub> portas = widget.portas;
    final double afastamento = CartaoDePorta.afastamentoEntrePortas(context);

    return Scaffold(
      backgroundColor: cores.fundo,
      body: Stack(
        children: <Widget>[
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (ScrollMetricsNotification n) =>
                _aoMedir(n.metrics),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification n) => _aoMedir(n.metrics),
              child: SingleChildScrollView(
                key: TelaHub.chaveLista,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CabecalhoDeTela(
                      titulo: TextosCasca.tituloHub,
                      aoVoltar: widget.aoVoltar,
                    ),
                    if (portas.isEmpty)
                      const EstadoVazio(
                        key: TelaHub.chaveVazio,
                        titulo: TextosCasca.hubVazioTitulo,
                        explicacao: TextosCasca.hubVazioExplicacao,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MemoraEspacamento.lg,
                          0,
                          MemoraEspacamento.lg,
                          MemoraEspacamento.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (final PortaDoHub porta in portas) ...<Widget>[
                              CartaoDePorta(
                                key: TelaHub.chaveDaPorta(porta.rotulo),
                                nome: porta.rotulo,
                                explicacao: porta.descricao,
                                ilustracao: porta.ilustracao,
                                aoAbrir: porta.aoAbrir,
                                principal: porta.principal,
                              ),
                              if (porta != portas.last)
                                SizedBox(height: afastamento),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_haMais)
            // `Align` e não `Positioned`: o pé da lista, na largura toda.
            const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                child: _FaixaHaMais(key: TelaHub.chaveHaMais),
              ),
            ),
        ],
      ),
    );
  }
}

/// A faixa "Há mais abaixo": seta e frase sobre um esmaecer do fundo.
///
/// Não recebe toque — `IgnorePointer` deixa o dedo passar para a lista por
/// baixo, que é onde a pessoa vai deslizar.
///
/// ## Só a seta, quando a ampliação é grande
///
/// A partir de [CartaoDePorta.ampliacaoQueTiraAIlustracao] a faixa perde a
/// frase e o esmaecer, e fica só a seta. Num 360×640 a 200% a porta principal
/// termina 27 dp acima da barra inferior: uma faixa de 86 dp (esmaecer, seta e
/// uma linha de 36 sp ampliados) cobriria o pé dela, e a regra de que a
/// principal aparece **inteira** sem rolar perderia para a regra de avisar que
/// há mais. A seta cabe nos 27; a frase, o leitor de tela continua dizendo.
class _FaixaHaMais extends StatelessWidget {
  const _FaixaHaMais({super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool soASeta =
        MediaQuery.textScalerOf(context).scale(1) >=
        CartaoDePorta.ampliacaoQueTiraAIlustracao;
    if (soASeta) {
      return IgnorePointer(
        child: Semantics(
          container: true,
          label: TextosCasca.hubHaMaisLeitor,
          child: ExcludeSemantics(
            // `Row` e não `Center`: o `Center` esticaria a faixa até a altura
            // toda do `Align` que a segura.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.keyboard_arrow_down,
                  size: MemoraDimensoes.iconePadrao,
                  color: cores.primaria,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return IgnorePointer(
      child: Semantics(
        container: true,
        label: TextosCasca.hubHaMaisLeitor,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Esmaecer do próprio fundo, e não de `Colors.transparent`: a
                // interpolação entre o preto transparente e uma cor opaca
                // passa por um cinza sujo.
                colors: <Color>[cores.fundo.withValues(alpha: 0), cores.fundo],
                stops: const <double>[0, 0.5],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MemoraEspacamento.lg,
                MemoraEspacamento.xl,
                MemoraEspacamento.lg,
                MemoraEspacamento.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: MemoraDimensoes.iconePadrao,
                    color: cores.primaria,
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                  Flexible(
                    child: TextoMemora(
                      TextosCasca.hubHaMais,
                      estilo: EstiloTexto.corpoForte,
                      cor: cores.primaria,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
