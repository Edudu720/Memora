import 'package:flutter/foundation.dart';

/// Aviso de que a sessão caiu **de verdade** no meio do uso (T111).
///
/// ## Por que existe
///
/// A camada de dados da assistente renova a sessão em silêncio (T108), e só a
/// renovação **recusada** significa que a pessoa precisa entrar de novo. Quem
/// sabe disso é a `ChamadaComRenovacao`; quem sabe levar a pessoa até a entrada
/// — fechar o que está aberto, apagar o que a saída apaga, parar o monitor — é
/// o `FluxoAutenticacao`, e o caminho dele já existe: o da inatividade.
///
/// Esta classe é o fio entre os dois. Sem ela, a sessão perdida na assistente
/// só virava uma frase numa tela sem saída, e a pessoa seguia "dentro" de uma
/// conta que o servidor já não reconhece.
///
/// ## O que **não** a aciona
///
/// Falta de conexão e falha inesperada. A rede que cai não encerra sessão
/// nenhuma, e mandar a pessoa digitar a senha por causa disso seria cobrar dela
/// um problema que não é dela.
///
/// ## Vive o aplicativo inteiro
///
/// É criada uma vez, na `Composicao`, e não se descarta: o `FluxoAutenticacao`
/// só a escuta enquanto a pessoa está dentro da conta.
class SessaoPerdida extends ChangeNotifier {
  int _avisos = 0;

  /// Quantas vezes a sessão foi dada como perdida. Só para o teste conferir.
  int get avisos => _avisos;

  /// A renovação foi recusada: a pessoa precisa entrar de novo.
  ///
  /// Pode ser chamada várias vezes em seguida — duas chamadas em voo levam o
  /// mesmo `401` —, e quem escuta é quem deduplica.
  void avisar() {
    _avisos++;
    notifyListeners();
  }
}
