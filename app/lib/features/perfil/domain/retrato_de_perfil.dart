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

/// Catálogo fechado de ilustrações embarcadas do Memora disponíveis como avatar
/// sem solicitar permissões do aparelho (FR-003, FR-004).
enum AvatarIlustrado {
  /// Robô da Memora acenando.
  memoraAcenando(
    chave: 'memora_acenando',
    caminhoAsset: 'assets/ilustracoes/memora_perfil_robo.png',
    ehSvg: false,
  ),

  /// Robô da Memora pensando.
  memoraPensando(
    chave: 'memora_pensando',
    caminhoAsset: 'assets/ilustracoes/memora_ajuda_robo.png',
    ehSvg: false,
  ),

  /// Robô da Memora comemorando.
  memoraComemorando(
    chave: 'memora_comemorando',
    caminhoAsset: 'assets/ilustracoes/memora_conclusao_robo.png',
    ehSvg: false,
  ),

  /// Robô da Memora com escudo protetor.
  memoraProtegendo(
    chave: 'memora_protegendo',
    caminhoAsset: 'assets/ilustracoes/memora_alerta_robo.png',
    ehSvg: false,
  ),

  /// Casal idoso acolhedor em vetor.
  casalIdoso(
    chave: 'casal_idoso',
    caminhoAsset: 'assets/ilustracoes/casal_idoso.svg',
    ehSvg: true,
  ),

  /// Pessoa utilizando celular em vetor.
  pessoaComCelular(
    chave: 'pessoa_com_celular',
    caminhoAsset: 'assets/ilustracoes/pessoa_com_celular.svg',
    ehSvg: true,
  );

  /// Identificador estável persistido no índice local.
  final String chave;

  /// Caminho do ativo embarcado coberto por `LICENCAS.md`.
  final String caminhoAsset;

  /// Verdadeiro quando o ativo é SVG; falso quando é PNG em alta resolução.
  final bool ehSvg;

  const AvatarIlustrado({
    required this.chave,
    required this.caminhoAsset,
    required this.ehSvg,
  });

  /// Rótulo acessível em português para leitores de tela e cards.
  String get rotulo => switch (this) {
        AvatarIlustrado.memoraAcenando => TextosPerfil.avatarMemoraAcenando,
        AvatarIlustrado.memoraPensando => TextosPerfil.avatarMemoraPensando,
        AvatarIlustrado.memoraComemorando =>
          TextosPerfil.avatarMemoraComemorando,
        AvatarIlustrado.memoraProtegendo => TextosPerfil.avatarMemoraProtegendo,
        AvatarIlustrado.casalIdoso => TextosPerfil.avatarCasalIdoso,
        AvatarIlustrado.pessoaComCelular => TextosPerfil.avatarPessoaComCelular,
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
