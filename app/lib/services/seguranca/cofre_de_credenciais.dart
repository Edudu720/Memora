import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde token e refresh ficam guardados no aparelho (T031, FR-036, R7).
///
/// ## Por que existe uma interface e não só a implementação
///
/// Teste de widget não tem Keystore. Sem esta interface, todo teste que toca
/// autenticação precisaria de canal simulado da plataforma — e o resultado
/// prático seria ninguém testar autenticação.
///
/// A interface também é o que torna verificável a regra que mais importa aqui:
/// o teste do cenário V8 substitui a implementação real por uma que **falha se
/// alguém tentar gravar credencial em armazenamento comum**.
abstract interface class CofreDeCredenciais {
  /// Guarda o par de tokens da sessão.
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  });

  /// O token de acesso guardado, ou `null` se não houver sessão.
  Future<String?> tokenAcesso();

  /// O refresh guardado, ou `null` se não houver sessão.
  Future<String?> refreshToken();

  /// Apaga tudo.
  ///
  /// Chamado ao sair da conta. A FR-026 exige que **nada reste** — o V8
  /// inspeciona o aparelho depois da saída.
  Future<void> limpar();
}

/// Implementação sobre o armazenamento seguro do sistema.
///
/// ## O que "seguro" quer dizer aqui, concretamente
///
/// No Android, o `flutter_secure_storage` cifra os valores com uma chave que
/// vive no **Keystore** — hardware dedicado nos aparelhos que o têm. Isso muda o
/// resultado de um cenário real: aparelho perdido, ou com root, entrega o
/// conteúdo de `shared_prefs` em texto puro, mas não entrega o que está aqui.
///
/// ## As opções abaixo não são enfeite
///
/// `encryptedSharedPreferences` liga o `EncryptedSharedPreferences` do Android;
/// sem ela, versões antigas do pacote caem num modo que guarda o valor cifrado
/// dentro do arquivo de preferências comum — que é exatamente o arquivo que o V8
/// manda inspecionar.
///
/// `first_unlock_this_device` no iOS impede que o valor seja lido antes do
/// primeiro desbloqueio depois de ligar o aparelho, e mantém o item fora do
/// backup do iCloud. Está aqui por completude: o produto é só Android hoje, e
/// deixar a opção correta escrita evita que a porta abra sozinha no dia em que
/// alguém acrescentar o iOS.
class CofreSeguroDoSistema implements CofreDeCredenciais {
  /// Chave do token de acesso.
  static const String chaveTokenAcesso = 'memora.token_acesso';

  /// Chave do refresh.
  static const String chaveRefreshToken = 'memora.refresh_token';

  final FlutterSecureStorage _armazenamento;

  /// Cria o cofre sobre o armazenamento seguro do sistema.
  CofreSeguroDoSistema({FlutterSecureStorage? armazenamento})
      : _armazenamento = armazenamento ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    await _armazenamento.write(key: chaveTokenAcesso, value: tokenAcesso);
    await _armazenamento.write(key: chaveRefreshToken, value: refreshToken);
  }

  @override
  Future<String?> tokenAcesso() =>
      _armazenamento.read(key: chaveTokenAcesso);

  @override
  Future<String?> refreshToken() =>
      _armazenamento.read(key: chaveRefreshToken);

  @override
  Future<void> limpar() async {
    await _armazenamento.delete(key: chaveTokenAcesso);
    await _armazenamento.delete(key: chaveRefreshToken);
  }
}
