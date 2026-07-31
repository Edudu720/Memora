import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';


/// tests for CadastroApi
void main() {
  final instance = MemoraApi().getCadastroApi();

  group(CadastroApi, () {
    // Criar conta
    //
    // Cria a conta e **já devolve sessão iniciada** (FR-009). A pessoa não precisa fazer login em seguida.  Exige **apenas um** canal de contato (FR-049). O segundo é oferecido depois do primeiro acesso (FR-050).  Se o canal já pertencer a uma conta, responde **201 da mesma forma**, sem criar nada e sem revelar a existência (FR-010). O aplicativo conduz a pessoa ao login conforme o cenário 5 da User Story 1. 
    //
    //Future<SessaoResposta> authCadastroPost(CadastroRequisicao cadastroRequisicao) async
    test('test authCadastroPost', () async {
      // TODO
    });

  });
}
