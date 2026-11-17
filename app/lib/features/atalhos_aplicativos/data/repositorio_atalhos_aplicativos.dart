import 'dart:typed_data';

import '../../../services/aplicativos/consulta_de_aplicativos.dart';
import '../../assistente/domain/assistente.dart';
import '../domain/entidades/atalho_aplicativo.dart';
import '../domain/entidades/categoria_aplicativo.dart';
import '../domain/repositorios/i_repositorio_atalhos.dart';

/// Implementação do repositório que obtém os aplicativos cotidianos do
/// catálogo oficial do servidor ([RepositorioAssistente]) e consulta em
/// paralelo o estado de instalação no aparelho via [ConsultaDeAplicativos].
///
/// Mantém o servidor como fonte única da verdade (R6 da 003: desativar ou
/// alterar aplicativos pelo banco reflete aqui sem nova versão do app) e exclui
/// estritamente serviços sensíveis (`CategoriaDoServico.sensivel`).
class RepositorioAtalhosAplicativos implements IRepositorioAtalhos {
  final RepositorioAssistente _assistente;
  final ConsultaDeAplicativos? _consulta;

  /// Cria o repositório de atalhos alimentado pelo catálogo do [assistente].
  /// Quando [consulta] é nula, os aplicativos permanecem visíveis com status
  /// não instalado para evitar omissões silenciosas.
  const RepositorioAtalhosAplicativos({
    required RepositorioAssistente assistente,
    ConsultaDeAplicativos? consulta,
  }) : _assistente = assistente,
       _consulta = consulta;

  @override
  Future<List<AtalhoAplicativo>> obterAtalhos() async {
    final List<ServicoDoCatalogo> todos = await _assistente.catalogo();
    final List<ServicoDoCatalogo> cotidianos = todos.where((
      ServicoDoCatalogo s,
    ) {
      final String? pacote = s.identificadorAndroid?.trim();
      return s.categoria == CategoriaDoServico.cotidiano &&
          s.memoraPodeAbrir &&
          pacote != null &&
          pacote.isNotEmpty &&
          pareceUmPacote(pacote);
    }).toList();

    final ConsultaDeAplicativos? consulta = _consulta;
    final List<AtalhoAplicativo> atualizados = await Future.wait(
      cotidianos.map((ServicoDoCatalogo servico) async {
        final String pacote = servico.identificadorAndroid!.trim();
        bool instalado = false;
        Uint8List? iconeBytes;

        if (consulta != null) {
          try {
            instalado = await consulta.estaInstalado(pacote);
            if (instalado) {
              iconeBytes = await consulta.iconeDe(pacote);
            }
          } catch (_) {
            instalado = false;
            iconeBytes = null;
          }
        }

        return AtalhoAplicativo(
          chave: servico.chave,
          nomeExibido: servico.nomeExibido,
          pacoteAndroid: pacote,
          descricaoCurta: servico.descricaoCurta,
          categoria: _categoriaDe(servico.chave),
          instalado: instalado,
          iconeBytes: iconeBytes,
        );
      }),
    );

    return List<AtalhoAplicativo>.unmodifiable(atualizados);
  }

  static CategoriaAplicativo _categoriaDe(String chave) => switch (chave) {
        'whatsapp' || 'telegram' => CategoriaAplicativo.comunicacao,
        'youtube' || 'tiktok' => CategoriaAplicativo.video,
        'google-fotos' => CategoriaAplicativo.fotos,
        _ => CategoriaAplicativo.redesSociais,
      };
}
