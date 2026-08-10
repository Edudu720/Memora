import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';


/// tests for RecuperaoDeAcessoApi
void main() {
  final instance = MemoraApi().getRecuperaoDeAcessoApi();

  group(RecuperaoDeAcessoApi, () {
    // Definir nova senha
    //
    // Troca a senha e **revoga todas as sessões ativas** (FR-021). A pessoa é notificada pelo canal cadastrado (FR-022). 
    //
    //Future<SessaoResposta> authRecuperacaoConfirmarPost(AuthRecuperacaoConfirmarPostRequest authRecuperacaoConfirmarPostRequest) async
    test('test authRecuperacaoConfirmarPost', () async {
      // TODO
    });

    // Solicitar recuperação de acesso
    //
    // Responde **202 sempre**, exista a conta ou não (FR-019). O texto devolvido é idêntico nos dois casos.  Só envia para canal **verificado**. 
    //
    //Future<AuthRecuperacaoSolicitarPost202Response> authRecuperacaoSolicitarPost(AuthRecuperacaoSolicitarPostRequest authRecuperacaoSolicitarPostRequest) async
    test('test authRecuperacaoSolicitarPost', () async {
      // TODO
    });

  });
}
