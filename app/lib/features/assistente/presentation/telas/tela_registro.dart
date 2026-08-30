import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';

/// O que a Memora fez em nome da pessoa (T059, FR-023).
///
/// ## Por que esta tela existe
///
/// O Princípio VI exige log auditável de toda ação da IA. Um log que só a
/// equipe lê serve à equipe — e quem precisa poder desconfiar do que foi feito
/// em seu nome é a pessoa.
///
/// ## O que NÃO aparece aqui
///
/// Orientação apenas ensinada (FR-025). Quem fez aquilo foi ela, e listar isso
/// como "o que a Memora fez" tiraria dela o crédito que a US2 trabalhou para
/// dar — bem no lugar onde ela vem conferir se pode confiar.
///
/// Também não aparecem as recusas. Elas ficam na trilha do servidor, para nós:
/// mostrar à pessoa uma tentativa que ela nem soube que aconteceu criaria um
/// susto sem nada a fazer a respeito.
class TelaRegistro extends StatefulWidget {
  /// Chave da lista.
  static const Key chaveLista = Key('registro.lista');

  /// De onde vêm as ações.
  final RepositorioAssistente repositorio;

  /// Volta ao Hub.
  final VoidCallback? aoVoltar;

  /// Cria a tela de registro.
  const TelaRegistro({required this.repositorio, this.aoVoltar, super.key});

  @override
  State<TelaRegistro> createState() => _TelaRegistroState();
}

class _TelaRegistroState extends State<TelaRegistro> {
  List<AcaoRegistrada>? _acoes;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<AcaoRegistrada> lidas = await widget.repositorio.registro();
      if (!mounted) return;
      setState(() {
        _acoes = lidas;
        _falhou = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _falhou = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final List<AcaoRegistrada>? acoes = _acoes;

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: BarraSuperior(
        titulo: TextosAssistente.portaRegistro,
        aoVoltar: widget.aoVoltar,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: TelaRegistro.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          children: <Widget>[
            const TextoMemora(TextosAssistente.explicacaoDoRegistro),
            const SizedBox(height: MemoraEspacamento.xl),

            if (_falhou)
              MensagemErro(
                mensagem: TextosAssistente.semConexao,
                aoTentarNovamente: _carregar,
              )
            else if (acoes == null)
              const Carregando()
            else if (acoes.isEmpty)
              // Lista vazia é a notícia boa, e o texto diz isso: quem nunca
              // precisou que a Memora fizesse nada está fazendo tudo sozinha.
              const EstadoVazio(
                titulo: 'Você fez tudo sozinha até agora',
                explicacao: TextosAssistente.registroVazio,
                icone: Icons.emoji_events_outlined,
              )
            else
              for (final AcaoRegistrada acao in acoes) ...<Widget>[
                _LinhaDoRegistro(acao: acao),
                const SizedBox(height: MemoraEspacamento.md),
              ],
          ],
        ),
      ),
    );
  }
}

/// Uma ação executada, em linguagem comum.
///
/// Usa [CampoInformacao] porque é **dado**, não ação: o registro não é
/// clicável, e não deve parecer (FR-012 da feature 001).
class _LinhaDoRegistro extends StatelessWidget {
  final AcaoRegistrada acao;

  const _LinhaDoRegistro({required this.acao});

  @override
  Widget build(BuildContext context) {
    return CampoInformacao(
      rotulo: TextosAssistente.quandoAconteceu(acao.ocorridoEm),
      valor: TextosAssistente.oQueFoiFeito(
        acao.nomeExibido,
        acao.pedidoResumido,
      ),
    );
  }
}
