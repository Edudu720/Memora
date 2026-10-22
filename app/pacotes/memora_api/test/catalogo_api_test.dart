import 'package:test/test.dart';
import 'package:memora_api/memora_api.dart';


/// tests for CatalogoApi
void main() {
  final instance = MemoraApi().getCatalogoApi();

  group(CatalogoApi, () {
    // Listar os serviços que a Memora conhece
    //
    // Alimenta as portas *Serviços do dia a dia* e *Meus aplicativos*. Cada item diz, antes do toque, se a Memora **ensina** ou **ensina e abre** (FR-045). 
    //
    //Future<AssistenteCatalogoGet200Response> assistenteCatalogoGet({ String categoria }) async
    test('test assistenteCatalogoGet', () async {
      // TODO
    });

  });
}
