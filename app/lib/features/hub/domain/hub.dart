import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show IconData, VoidCallback;

import '../../../design_system/design_system.dart' show Ilustracao;

/// Uma porta do Hub — um lugar do Memora que a pessoa pode abrir.
///
/// ## Por que [aoAbrir] é obrigatório
///
/// A FR-003 diz que o Hub exibe **apenas** portas que levam a funcionalidade
/// existente. Deixar o destino opcional permitiria que uma porta fosse
/// acrescentada "para depois", e porta que não abre nada é pior do que porta
/// que não existe: a pessoa toca, nada acontece, e ela conclui que o aparelho
/// quebrou — ou que ela fez algo errado.
///
/// Sendo obrigatório, uma porta sem destino **não compila**. É a mesma ideia
/// dos tokens do Design System: transformar o erro provável em erro de
/// compilação.
///
/// ## Por que a porta é dado, e não widget
///
/// A `TelaHub` recebe a lista pronta. Quem sabe o que existe é quem monta o
/// fluxo, não a tela — e é isso que permite o Hub crescer, uma porta por
/// entrega, sem que a tela precise conhecer cada destino.
@immutable
class PortaDoHub {
  /// Nome da porta, em linguagem comum.
  final String rotulo;

  /// O que há do outro lado, numa frase.
  ///
  /// Existe porque o rótulo sozinho às vezes não basta: *"Serviços sociais"*
  /// não diz que a Memora só ensina e não abre, e essa diferença precisa ser
  /// conhecida **antes** do toque (FR-045 da 003).
  final String descricao;

  /// O desenho da porta (FR-016 da feature 004).
  ///
  /// Nunca aparece sozinho: o `CartaoDePorta` sempre escreve o [rotulo] ao
  /// lado, porque desenho isolado é adivinhação (Princípio III). Substitui o
  /// ícone do Material que a porta carregava antes do redesenho.
  final Ilustracao ilustracao;

  /// Ícone opcional da família `_rounded` exibido no medalhão da porta.
  final IconData? icone;

  /// O que abrir. Obrigatório — ver a nota da classe.
  final VoidCallback aoAbrir;

  /// A porta é a ação principal do Hub?
  ///
  /// No máximo uma deve ser. O cenário 1 da User Story 1 da feature 001
  /// estabeleceu que o Memora não coloca duas ações de mesmo peso disputando a
  /// atenção, e o Hub herda essa regra (FR-002 da feature 004).
  final bool principal;

  /// Cria uma porta.
  const PortaDoHub({
    required this.rotulo,
    required this.descricao,
    required this.ilustracao,
    required this.aoAbrir,
    this.icone,
    this.principal = false,
  });
}
