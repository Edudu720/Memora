import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';


/// tests for SessoApi
void main() {
  final instance = MemoraApi().getSessoApi();

  group(SessoApi, () {
    // Entrar com identificador e senha
    //
    // Aceita **qualquer canal verificado** da pessoa — e-mail ou telefone (FR-051).  O erro é sempre genérico: não distingue identificador inexistente de senha incorreta (FR-013). O servidor executa o hash mesmo quando a conta não existe, para que o tempo de resposta não denuncie a existência (R3). 
    //
    //Future<SessaoResposta> authEntrarPost(EntrarRequisicao entrarRequisicao) async
    test('test authEntrarPost', () async {
      // TODO
    });

    // Encerrar sessão
    //
    // Revoga a sessão atual (FR-026). O aplicativo é responsável por limpar todo dado pessoal e credencial do armazenamento seguro do aparelho. 
    //
    //Future authSairPost() async
    test('test authSairPost', () async {
      // TODO
    });

    // Renovar sessão
    //
    // Rotação de refresh token (R2). O token apresentado é invalidado e um novo é emitido.  **Detecção de reuso**: se o token já tiver sido usado, isso indica roubo. Toda a família de sessões é revogada e a pessoa é notificada. A resposta é `401`. 
    //
    //Future<SessaoResposta> authSessaoRenovarPost(AuthSessaoRenovarPostRequest authSessaoRenovarPostRequest) async
    test('test authSessaoRenovarPost', () async {
      // TODO
    });

    // Entrar com provedor externo
    //
    // Recebe o token de identidade obtido pelo aplicativo via Authorization Code com PKCE (R6). O backend **valida assinatura, emissor, audiência e expiração** antes de aceitar.  Se o identificador já existir como conta com senha, os acessos são vinculados à mesma pessoa, sem criar duplicata e **sem revelar** que a conta já existia (FR-057).  O token do provedor é validado e **descartado** — nunca armazenado. 
    //
    //Future<SessaoResposta> authSocialProvedorPost(String provedor, AuthSocialProvedorPostRequest authSocialProvedorPostRequest) async
    test('test authSocialProvedorPost', () async {
      // TODO
    });

    // Dados da pessoa autenticada
    //
    //Future<PessoaResposta> euGet() async
    test('test euGet', () async {
      // TODO
    });

  });
}
