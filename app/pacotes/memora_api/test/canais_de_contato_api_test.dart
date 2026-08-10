import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';


/// tests for CanaisDeContatoApi
void main() {
  final instance = MemoraApi().getCanaisDeContatoApi();

  group(CanaisDeContatoApi, () {
    // Enviar código de verificação
    //
    // Envia código numérico de 6 dígitos, válido por 10 minutos, de uso único (R5).  **Código, não link.** A FR-046 desaconselha links de autenticação em canais imitáveis — a regra que ensinamos à pessoa é *\"nunca clique, sempre digite\"*.  Solicitar novo código invalida o anterior. 
    //
    //Future canaisCanalIdCodigoPost(String canalId) async
    test('test canaisCanalIdCodigoPost', () async {
      // TODO
    });

    // Confirmar posse do canal
    //
    // Confirma que a pessoa controla o canal. **Somente canal verificado serve para recuperar acesso** (FR-052).  Este é o ponto que impede o cenário do acompanhante que cadastra o próprio contato e mantém controle da conta alheia (FR-062). 
    //
    //Future<Canal> canaisCanalIdVerificarPost(String canalId, CanaisCanalIdVerificarPostRequest canaisCanalIdVerificarPostRequest) async
    test('test canaisCanalIdVerificarPost', () async {
      // TODO
    });

    // Adicionar segundo canal de contato
    //
    // Oferecido **após** o primeiro acesso, de forma não bloqueante, como reforço de segurança da conta (FR-050). Cria o canal como **não verificado**. 
    //
    //Future<Canal> canaisPost(CanalRequisicao canalRequisicao) async
    test('test canaisPost', () async {
      // TODO
    });

  });
}
