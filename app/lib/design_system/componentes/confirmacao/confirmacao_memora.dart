import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_perigo.dart';
import '../botoes/botao_primario.dart';
import '../botoes/botao_secundario.dart';
import '../texto/texto_memora.dart';

/// Pergunta da assistente Memora que exige uma decisão da pessoa.
///
/// ## O defeito que este componente corrige
///
/// No protótipo, a confirmação eram dois botões **SIM** e **NÃO** de 77×24 px,
/// lado a lado. A medição está em `research.md`, R2: **24 px é metade dos
/// 48 dp exigidos**. Além do tamanho, os dois tinham peso visual idêntico —
/// e numa tela em que a assistente pede autorização para agir, isso viola o
/// Princípio VI da Constituição: a confirmação precisa ser deliberada, não um
/// toque entre dois iguais.
///
/// ## O que muda
///
/// - **Empilhamento vertical**, largura total: elimina a escolha por
///   proximidade horizontal, que é onde o toque acidental acontece.
/// - **56 dp de altura**, acima do mínimo, por ser ponto de decisão.
/// - **Frases completas** — *"Sim, pode abrir"* em vez de *"SIM"*. Palavra
///   isolada exige que a pessoa lembre a pergunta.
/// - **Ícone e texto**, nunca só cor.
/// - A recusa é secundária, mas **nunca escondida nem apagada**.
class ConfirmacaoMemora extends StatefulWidget {
  /// O que a assistente está perguntando.
  final String pergunta;

  /// Rótulo da ação que confirma. Use frase completa.
  final String rotuloConfirmar;

  /// Rótulo da ação que recusa. Use frase completa.
  final String rotuloRecusar;

  /// Acionada ao confirmar.
  final VoidCallback aoConfirmar;

  /// Acionada ao recusar.
  final VoidCallback aoRecusar;

  /// Explicação do que vai acontecer. Obrigatória na variante irreversível.
  final String? aviso;

  /// Quando verdadeiro, a ação é destrutiva e exige **dupla confirmação**.
  final bool irreversivel;

  /// Cria uma confirmação comum.
  const ConfirmacaoMemora({
    required this.pergunta,
    required this.rotuloConfirmar,
    required this.rotuloRecusar,
    required this.aoConfirmar,
    required this.aoRecusar,
    super.key,
  })  : irreversivel = false,
        aviso = null;

  /// Cria uma confirmação de ação **irreversível**.
  ///
  /// A ação destrutiva fica separada por espaçamento maior, em cor de perigo,
  /// e só é executada após uma **segunda** confirmação explícita (FR-013).
  const ConfirmacaoMemora.irreversivel({
    required this.pergunta,
    required String this.aviso,
    required this.rotuloConfirmar,
    required this.rotuloRecusar,
    required this.aoConfirmar,
    required this.aoRecusar,
    super.key,
  }) : irreversivel = true;

  @override
  State<ConfirmacaoMemora> createState() => _ConfirmacaoMemoraState();
}

class _ConfirmacaoMemoraState extends State<ConfirmacaoMemora> {
  /// Verdadeiro depois do primeiro toque na ação irreversível.
  bool _aguardandoSegundaConfirmacao = false;

  void _primeiroToque() {
    if (!widget.irreversivel) {
      widget.aoConfirmar();
      return;
    }
    setState(() => _aguardandoSegundaConfirmacao = true);
  }

  void _cancelar() {
    if (_aguardandoSegundaConfirmacao) {
      setState(() => _aguardandoSegundaConfirmacao = false);
      return;
    }
    widget.aoRecusar();
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MemoraEspacamento.lg),
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        border: Border.all(color: cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextoMemora(
            _aguardandoSegundaConfirmacao
                ? 'Tem certeza mesmo?'
                : widget.pergunta,
            estilo: EstiloTexto.corpoForte,
          ),
          if (widget.aviso != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.sm),
            TextoMemora.apoio(widget.aviso!),
          ],
          const SizedBox(height: MemoraEspacamento.xl),

          // A recusa vem PRIMEIRO na variante irreversível: o caminho seguro
          // fica mais perto do polegar e é o primeiro a ser lido.
          if (widget.irreversivel) ...<Widget>[
            BotaoSecundario(
              rotulo: _aguardandoSegundaConfirmacao
                  ? 'Não, deixa como está'
                  : widget.rotuloRecusar,
              icone: Icons.arrow_back,
              aoTocar: _cancelar,
            ),
            // Espaçamento grande isola a ação destrutiva (FR-013).
            const SizedBox(height: MemoraEspacamento.xxxl),
            BotaoPerigo(
              rotulo: _aguardandoSegundaConfirmacao
                  ? 'Sim, pode apagar'
                  : widget.rotuloConfirmar,
              icone: Icons.warning_amber_rounded,
              aoTocar: _aguardandoSegundaConfirmacao
                  ? widget.aoConfirmar
                  : _primeiroToque,
            ),
          ] else ...<Widget>[
            BotaoPrimario(
              rotulo: widget.rotuloConfirmar,
              icone: Icons.check,
              aoTocar: _primeiroToque,
            ),
            const SizedBox(height: MemoraEspacamento.md),
            BotaoSecundario(
              rotulo: widget.rotuloRecusar,
              icone: Icons.close,
              aoTocar: _cancelar,
            ),
          ],
        ],
      ),
    );
  }
}
