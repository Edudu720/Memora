import 'dart:typed_data';

import '../../../assistente/domain/assistente.dart';

/// Entidade imutável que representa um aplicativo cotidiano na tela de abertura direta.
class AtalhoAplicativo {
  /// Identificador interno estável (ex.: `'whatsapp'`).
  final String chave;

  /// Nome amigável exibido na interface (ex.: `'WhatsApp'`).
  final String nomeExibido;

  /// Nome completo do pacote Android validado em `<queries>` (ex.: `'com.whatsapp'`).
  final String pacoteAndroid;

  /// Descrição curta de uma frase explicando para que o aplicativo serve.
  final String descricaoCurta;

  /// Categoria vinda diretamente do catálogo oficial do servidor.
  final CategoriaDoServico categoria;

  /// Indica se o aplicativo foi detectado como instalado no aparelho.
  final bool instalado;

  /// Ícone PNG real fornecido pelo sistema operacional, quando disponível.
  final Uint8List? iconeBytes;

  /// Cria uma instância de [AtalhoAplicativo].
  const AtalhoAplicativo({
    required this.chave,
    required this.nomeExibido,
    required this.pacoteAndroid,
    required this.descricaoCurta,
    this.categoria = CategoriaDoServico.cotidiano,
    this.instalado = false,
    this.iconeBytes,
  });

  /// Retorna uma cópia atualizada desta entidade.
  AtalhoAplicativo copyWith({
    bool? instalado,
    Uint8List? iconeBytes,
    bool limparIcone = false,
  }) {
    return AtalhoAplicativo(
      chave: chave,
      nomeExibido: nomeExibido,
      pacoteAndroid: pacoteAndroid,
      descricaoCurta: descricaoCurta,
      categoria: categoria,
      instalado: instalado ?? this.instalado,
      iconeBytes: limparIcone ? null : (iconeBytes ?? this.iconeBytes),
    );
  }
}
