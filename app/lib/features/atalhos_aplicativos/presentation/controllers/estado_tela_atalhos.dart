import '../../domain/entidades/atalho_aplicativo.dart';

/// Estado imutável da tela de atalhos diretos para aplicativos.
class EstadoTelaAtalhos {
  /// Indica se a verificação de instalação no dispositivo está em andamento.
  final bool carregando;

  /// Lista completa dos aplicativos comuns homologados com seu status atual.
  final List<AtalhoAplicativo> aplicativos;

  /// Mensagem eventual de aviso operacional.
  final String? mensagemAviso;

  /// Cria o estado da tela de atalhos.
  const EstadoTelaAtalhos({
    this.carregando = true,
    this.aplicativos = const <AtalhoAplicativo>[],
    this.mensagemAviso,
  });

  /// Quantidade de aplicativos comuns instalados no dispositivo.
  int get totalInstalados =>
      aplicativos.where((AtalhoAplicativo app) => app.instalado).length;

  /// Total de aplicativos comuns suportados nesta tela.
  int get totalSuportados => aplicativos.length;
}
