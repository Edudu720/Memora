import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_ajuda.dart';
import '../data/compartilhar.dart';
import '../domain/assunto_de_ajuda.dart';

/// Um assunto da Ajuda, uma ideia por vez (T087, FR-033, FR-035, FR-036).
///
/// ## Uma ideia por tela
///
/// O texto vem em pedaços curtos, e a pessoa avança com "Continuar" — ou
/// "Próxima dica", na Segurança. Cada pedaço é um balão da Memora. Quem lê
/// devagar não perde o fio num muro de texto, e a 200% a tela não vira uma
/// rolagem sem fim. O contador ("Passo 2 de 3") diz quanto falta, e que são
/// poucas.
///
/// O "Voltar" do cabeçalho **sai do assunto**; "Anterior" volta uma ideia. Dois
/// "Voltar" na mesma tela seriam uma pergunta para quem não sabe qual é qual.
///
/// ## "Compartilhar" avisa antes, e não leva nada além do endereço
///
/// Na última ideia do assunto, o botão **não** abre a folha do sistema: abre
/// uma pergunta, que diz que a pessoa vai mandar uma mensagem **para fora do
/// Memora** e escreve o endereço que vai (FR-035, FR-037). Só o "sim" chama
/// [Compartilhador.compartilhar] — que não recebe texto nenhum.
///
/// A pergunta é inline, não diálogo: o diálogo não rola, e a 200% num
/// 320×568 o aviso mais os dois botões não cabem numa janela fixa.
class TelaAssunto extends StatefulWidget {
  /// Chave do botão que avança, para os testes.
  static const Key chaveContinuar = Key('assunto.continuar');

  /// Chave do botão que volta uma ideia, para os testes.
  static const Key chaveAnterior = Key('assunto.anterior');

  /// Chave do botão que sai do assunto, na última ideia.
  static const Key chaveSair = Key('assunto.sair');

  /// Chave do botão "Compartilhar o Memora".
  static const Key chaveCompartilhar = Key('assunto.compartilhar');

  /// Chave da pergunta de "antes de compartilhar".
  static const Key chaveConfirmacao = Key('assunto.confirmacao');

  /// Chave do aviso de que a folha não abriu.
  static const Key chaveErro = Key('assunto.erro');

  /// O assunto. Não é "A conversa", que tem a [AjudaGuiadaDaConversa].
  final AssuntoDeAjuda assunto;

  /// Sai do assunto, de volta à lista.
  final VoidCallback aoVoltar;

  /// Quem manda o endereço oficial. Só o assunto "Compartilhar" o usa; sem ele,
  /// o assunto não tem o botão (e a lista nem o oferece).
  final Compartilhador? compartilhador;

  /// Cria a tela de um assunto.
  TelaAssunto({
    required this.assunto,
    required this.aoVoltar,
    this.compartilhador,
    super.key,
  }) : assert(
         assunto.id != IdDoAssunto.conversa,
         'A conversa tem a ajuda guiada, não uma lista de ideias.',
       );

  @override
  State<TelaAssunto> createState() => _TelaAssuntoState();
}

class _TelaAssuntoState extends State<TelaAssunto> {
  int _indice = 0;
  bool _confirmando = false;
  bool _enviando = false;
  bool _falhou = false;

  List<String> get _telas => widget.assunto.telas;
  bool get _naUltima => _indice == _telas.length - 1;
  bool get _ehCompartilhar =>
      widget.assunto.id == IdDoAssunto.compartilhar &&
      widget.compartilhador != null;

  void _ir(int novo) => setState(() {
    _indice = novo;
    _confirmando = false;
    _falhou = false;
  });

  Future<void> _compartilhar() async {
    if (_enviando) return;
    setState(() {
      _confirmando = false;
      _enviando = true;
      _falhou = false;
    });
    final bool abriu = await widget.compartilhador!.compartilhar();
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _falhou = !abriu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AssuntoDeAjuda assunto = widget.assunto;
    final int total = _telas.length;
    final String contador = assunto.ehDeDicas
        ? TextosAjuda.dica(_indice + 1, total)
        : TextosAjuda.passo(_indice + 1, total);

    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      // `SingleChildScrollView` e não `ListView`: tudo é construído, e o leitor
      // de tela alcança o botão sem rolar às cegas.
      body: SingleChildScrollView(
        // Uma ideia nova começa no topo: sem a chave, a rolagem da anterior
        // seguia valendo e a pessoa chegava no meio da seguinte.
        key: ValueKey<int>(_indice),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: assunto.titulo,
              ilustracao: assunto.ehDaMemora ? null : assunto.ilustracao,
              aoVoltar: widget.aoVoltar,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (total > 1) ...<Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        label: TextosAjuda.passoDescrito(
                          assunto.titulo,
                          _indice + 1,
                          total,
                        ),
                        child: ExcludeSemantics(
                          child: BadgeDeStatus(
                            rotulo: contador,
                            tom: TomBadgeStatus.informativo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MemoraEspacamento.md),
                  ],
                  BalaoDeFala(
                    autor: AutorDoBalao.memora,
                    texto: _telas[_indice],
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                  CaixaDeEtapa(
                    instrucao: TextosAjuda.instrucaoNavegacao,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _acoes(),
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _acoes() {
    const SizedBox espaco = SizedBox(height: MemoraEspacamento.md);

    if (!_naUltima) {
      return <Widget>[
        BotaoPrimario(
          key: TelaAssunto.chaveContinuar,
          rotulo: widget.assunto.ehDeDicas
              ? TextosAjuda.proximaDica
              : TextosAjuda.continuar,
          aoTocar: () => _ir(_indice + 1),
        ),
        if (_indice > 0) ...<Widget>[espaco, _anterior()],
      ];
    }

    // Última ideia.
    if (_ehCompartilhar) {
      return <Widget>[
        if (_falhou) ...<Widget>[
          const MensagemErro(
            key: TelaAssunto.chaveErro,
            // A Memora desta tela é a do balão (FR-006).
            comMemora: false,
            mensagem: TextosAjuda.erroAoCompartilhar,
          ),
          espaco,
        ],
        if (_confirmando)
          ConfirmacaoMemora(
            key: TelaAssunto.chaveConfirmacao,
            pergunta: TextosAjuda.perguntaCompartilhar,
            aviso: TextosAjuda.avisoCompartilhar(
              widget.compartilhador!.endereco,
            ),
            rotuloConfirmar: TextosAjuda.simCompartilhar,
            rotuloRecusar: TextosAjuda.naoCompartilhar,
            aoConfirmar: _compartilhar,
            aoRecusar: () => setState(() => _confirmando = false),
          )
        else ...<Widget>[
          BotaoPrimario(
            key: TelaAssunto.chaveCompartilhar,
            rotulo: TextosAjuda.botaoCompartilhar,
            icone: Icons.share_rounded,
            carregando: _enviando,
            aoTocar: _enviando
                ? null
                : () => setState(() => _confirmando = true),
          ),
          espaco,
          BotaoSecundario(
            key: TelaAssunto.chaveSair,
            rotulo: TextosAjuda.voltarParaAjuda,
            aoTocar: widget.aoVoltar,
          ),
        ],
        if (_indice > 0 && !_confirmando) ...<Widget>[espaco, _anterior()],
      ];
    }

    return <Widget>[
      BotaoPrimario(
        key: TelaAssunto.chaveSair,
        rotulo: TextosAjuda.voltarParaAjuda,
        aoTocar: widget.aoVoltar,
      ),
      if (_indice > 0) ...<Widget>[espaco, _anterior()],
    ];
  }

  Widget _anterior() => BotaoTerciario(
    key: TelaAssunto.chaveAnterior,
    rotulo: TextosAjuda.anterior,
    aoTocar: () => _ir(_indice - 1),
  );
}
