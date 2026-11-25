import 'package:flutter/widgets.dart';

/// O ponto único para saber se o movimento deve ser reduzido (feature 013,
/// T007).
///
/// A `AmpliacaoDeTexto` envolve o aplicativo inteiro e já soma a preferência
/// "reduzir movimento" do aplicativo à do sistema em
/// `MediaQuery.disableAnimations`. Ler daqui cobre as duas: a Memora, a rota e
/// a troca de destino não precisam saber de onde veio o pedido.
extension ReducaoDeMovimento on BuildContext {
  /// Verdadeiro quando a pessoa pediu menos movimento, no aplicativo ou no
  /// sistema. Reconstrói quem chama quando isso muda.
  bool get reduzirMovimento => MediaQuery.disableAnimationsOf(this);
}
