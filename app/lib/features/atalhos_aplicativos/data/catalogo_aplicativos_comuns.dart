import '../domain/entidades/atalho_aplicativo.dart';
import '../domain/entidades/categoria_aplicativo.dart';

/// Catálogo estático e seguro exclusivamente com os 7 aplicativos comuns do cotidiano.
///
/// Serviços sociais, governamentais e financeiros são estritamente excluídos
/// desta tela por exigirem contexto pedagógico e salvaguardas específicas
/// presentes nos guias educativos (Feature 006 / Princípio II).
abstract final class CatalogoAplicativosComuns {
  /// Lista imutável dos 7 aplicativos comuns homologados em `<queries>`.
  static const List<AtalhoAplicativo> todos = <AtalhoAplicativo>[
    AtalhoAplicativo(
      chave: 'whatsapp',
      nomeExibido: 'WhatsApp',
      pacoteAndroid: 'com.whatsapp',
      descricaoCurta: 'Mensagens de texto, áudios e chamadas com a família.',
      categoria: CategoriaAplicativo.comunicacao,
    ),
    AtalhoAplicativo(
      chave: 'youtube',
      nomeExibido: 'YouTube',
      pacoteAndroid: 'com.google.android.youtube',
      descricaoCurta: 'Vídeos, músicas, receitas e programas para assistir.',
      categoria: CategoriaAplicativo.video,
    ),
    AtalhoAplicativo(
      chave: 'instagram',
      nomeExibido: 'Instagram',
      pacoteAndroid: 'com.instagram.android',
      descricaoCurta: 'Fotos e vídeos de amigos, parentes e páginas seguidas.',
      categoria: CategoriaAplicativo.redesSociais,
    ),
    AtalhoAplicativo(
      chave: 'facebook',
      nomeExibido: 'Facebook',
      pacoteAndroid: 'com.facebook.katana',
      descricaoCurta: 'Publicações, fotos e grupos de pessoas conhecidas.',
      categoria: CategoriaAplicativo.redesSociais,
    ),
    AtalhoAplicativo(
      chave: 'google_fotos',
      nomeExibido: 'Google Fotos',
      pacoteAndroid: 'com.google.android.apps.photos',
      descricaoCurta: 'Suas fotos, vídeos e recordações da família guardadas.',
      categoria: CategoriaAplicativo.fotos,
    ),
    AtalhoAplicativo(
      chave: 'telegram',
      nomeExibido: 'Telegram',
      pacoteAndroid: 'org.telegram.messenger',
      descricaoCurta: 'Mensagens rápidas, grupos de notícias e canais.',
      categoria: CategoriaAplicativo.comunicacao,
    ),
    AtalhoAplicativo(
      chave: 'tiktok',
      nomeExibido: 'TikTok',
      pacoteAndroid: 'com.zhiliaoapp.musically',
      descricaoCurta: 'Vídeos curtos, receitas rápidas e momentos divertidos.',
      categoria: CategoriaAplicativo.video,
    ),
  ];

  /// Verifica se um nome de pacote pertence estritamente à lista homologada.
  static bool pertenceAoCatalogo(String pacoteAndroid) {
    return todos.any(
      (AtalhoAplicativo app) => app.pacoteAndroid == pacoteAndroid,
    );
  }
}
