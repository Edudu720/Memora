import '../../../l10n/textos_perfil.dart';

/// Limites e regras de sanitização para imagens de perfil (FR-005, SC-003).
abstract final class PoliticaDeImagemDePerfil {
  /// 15 MB: teto aceito no arquivo original antes da decodificação completa.
  static const int tamanhoMaximoEntradaBytes = 15 * 1024 * 1024;

  /// Lado máximo (largura e altura) da imagem final salva no aparelho.
  static const int dimensaoMaximaPx = 512;

  /// Qualidade JPEG do re-encode limpo sem metadados EXIF/GPS.
  static const int qualidadeJpegSaida = 88;
}

/// Catálogo fechado de ilustrações vetoriais disponíveis como avatar
/// sem solicitar permissões do aparelho (FR-003, FR-004).
enum AvatarIlustrado {
  /// Memora acenando.
  memoraAcenando(chave: 'memora_acenando'),

  /// Memora pensando.
  memoraPensando(chave: 'memora_pensando'),

  /// Memora comemorando.
  memoraComemorando(chave: 'memora_comemorando'),

  /// Memora com escudo protetor.
  memoraProtegendo(chave: 'memora_protegendo');

  /// Identificador estável persistido no índice local.
  final String chave;

  const AvatarIlustrado({required this.chave});

  /// Rótulo acessível em português para leitores de tela e cards.
  String get rotulo => switch (this) {
        AvatarIlustrado.memoraAcenando => TextosPerfil.avatarMemoraAcenando,
        AvatarIlustrado.memoraPensando => TextosPerfil.avatarMemoraPensando,
        AvatarIlustrado.memoraComemorando =>
          TextosPerfil.avatarMemoraComemorando,
        AvatarIlustrado.memoraProtegendo => TextosPerfil.avatarMemoraProtegendo,
      };

  /// Recupera o avatar pelo identificador persistido, ou `null` se inválido.
  static AvatarIlustrado? porChave(String? chave) {
    if (chave == null) return null;
    for (final AvatarIlustrado item in values) {
      if (item.chave == chave) return item;
    }
    return null;
  }
}

/// Retrato escolhido opcionalmente pela pessoa usuária para a tela de Perfil.
sealed class RetratoDePerfil {
  const RetratoDePerfil();
}

/// Foto própria já validada, recortada em `1:1` e sem metadados EXIF.
final class FotoPropriaDePerfil extends RetratoDePerfil {
  /// Caminho absoluto do arquivo `.jpg` no diretório privado do app.
  final String caminhoDoArquivo;

  /// Instante UTC da gravação atual, usado para invalidar cache em troca.
  final DateTime atualizadaEm;

  /// Bytes já em memória quando o armazenamento opera em memória (testes).
  final List<int>? bytesEmMemoria;

  /// Cria referência de foto própria.
  const FotoPropriaDePerfil({
    required this.caminhoDoArquivo,
    required this.atualizadaEm,
    this.bytesEmMemoria,
  });
}

/// Avatar ilustrado pré-definido da coleção Memora.
final class AvatarIlustradoDePerfil extends RetratoDePerfil {
  /// Ilustração escolhida.
  final AvatarIlustrado avatar;

  /// Cria referência de avatar ilustrado.
  const AvatarIlustradoDePerfil(this.avatar);
}
