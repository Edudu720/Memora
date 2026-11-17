import 'dart:typed_data';

import '../../../services/aplicativos/consulta_de_aplicativos.dart';
import '../domain/entidades/atalho_aplicativo.dart';
import '../domain/repositorios/i_repositorio_atalhos.dart';
import 'catalogo_aplicativos_comuns.dart';

/// Implementação do repositório que consulta em paralelo o estado de instalação
/// dos aplicativos comuns usando [ConsultaDeAplicativos].
class RepositorioAtalhosAplicativos implements IRepositorioAtalhos {
  final ConsultaDeAplicativos? _consulta;

  /// Cria o repositório de atalhos. Quando [consulta] é nula, todos os itens
  /// aparecem como não instalados de forma segura.
  const RepositorioAtalhosAplicativos({ConsultaDeAplicativos? consulta})
    : _consulta = consulta;

  @override
  Future<List<AtalhoAplicativo>> obterAtalhos() async {
    final ConsultaDeAplicativos? consulta = _consulta;
    if (consulta == null) {
      return List<AtalhoAplicativo>.unmodifiable(CatalogoAplicativosComuns.todos);
    }

    final List<AtalhoAplicativo> atualizados = await Future.wait(
      CatalogoAplicativosComuns.todos.map((AtalhoAplicativo base) async {
        bool instalado = false;
        Uint8List? iconeBytes;
        try {
          instalado = await consulta.estaInstalado(base.pacoteAndroid);
          if (instalado) {
            iconeBytes = await consulta.iconeDe(base.pacoteAndroid);
          }
        } catch (_) {
          instalado = false;
          iconeBytes = null;
        }
        return base.copyWith(instalado: instalado, iconeBytes: iconeBytes);
      }),
    );

    return List<AtalhoAplicativo>.unmodifiable(atualizados);
  }
}
