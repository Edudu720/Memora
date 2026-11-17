/// Categorias funcionais dos aplicativos comuns exibidos nos atalhos rápidos.
enum CategoriaAplicativo {
  /// Aplicativos de mensagens e chamadas de vídeo ou áudio.
  comunicacao('Comunicação'),

  /// Aplicativos de reprodução de vídeos e entretenimento.
  video('Vídeos'),

  /// Aplicativos de redes sociais e contato com familiares.
  redesSociais('Redes sociais'),

  /// Aplicativos de organização e visualização de fotografias.
  fotos('Fotos e memórias');

  /// Rótulo amigável em português simples.
  final String rotulo;

  const CategoriaAplicativo(this.rotulo);
}
