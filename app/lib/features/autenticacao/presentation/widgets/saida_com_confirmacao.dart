import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

/// O botao de sair e a confirmacao que vem depois dele (FR-025).
///
/// Existe num lugar so porque a saida tem **dois** pontos de entrada, o Hub e
/// a tela de perfil, e a confirmacao precisa ser a mesma nos dois: com duas
/// copias, uma delas acaba sem a pergunta — foi o que aconteceu quando o Hub
/// ligou o botao direto na saida.
///
/// A [ConfirmacaoMemora] substitui o botao em vez de flutuar sobre a tela, e
/// nao e a variante irreversivel: sair nao destroi nada, e a pessoa entra de
/// novo com a senha. Nada e encerrado antes do segundo toque.
class SaidaComConfirmacao extends StatefulWidget {
  /// Desenha o primeiro botao; [aoTocar] abre a confirmacao.
  final Widget Function(VoidCallback aoTocar) botao;

  /// Chave da confirmacao, para os testes localizarem a pergunta.
  final Key chaveConfirmacao;

  /// Roda so depois de a pessoa confirmar.
  final Future<void> Function() aoConfirmar;

  /// Chamada depois que a saida termina, se a tela ainda existir.
  final VoidCallback? aoConcluir;

  /// Cria o conjunto botao + confirmacao.
  const SaidaComConfirmacao({
    required this.botao,
    required this.chaveConfirmacao,
    required this.aoConfirmar,
    this.aoConcluir,
    super.key,
  });

  @override
  State<SaidaComConfirmacao> createState() => _SaidaComConfirmacaoState();
}

class _SaidaComConfirmacaoState extends State<SaidaComConfirmacao> {
  bool _confirmando = false;
  bool _saindo = false;

  Future<void> _sair() async {
    setState(() => _saindo = true);
    await widget.aoConfirmar();
    if (!mounted) return;
    widget.aoConcluir?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_saindo) {
      return const Carregando(mensagem: TextosAutenticacao.saindo);
    }
    if (_confirmando) {
      return ConfirmacaoMemora(
        key: widget.chaveConfirmacao,
        pergunta: TextosAutenticacao.perguntaSair,
        aviso: TextosAutenticacao.avisoSair,
        rotuloConfirmar: TextosAutenticacao.botaoConfirmarSaida,
        rotuloRecusar: TextosAutenticacao.botaoFicar,
        aoConfirmar: _sair,
        aoRecusar: () => setState(() => _confirmando = false),
      );
    }
    return widget.botao(() => setState(() => _confirmando = true));
  }
}