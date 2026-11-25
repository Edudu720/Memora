import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'retrato_de_perfil.dart';

/// Motivos pelos quais uma imagem selecionada pode ser recusada (FR-005).
enum MotivoRejeicaoImagem {
  /// Arquivo ultrapassa 15 MB.
  arquivoMuitoGrande,

  /// Assinatura binária incompatível ou animação multi-quadro.
  formatoNaoSuportado,

  /// Arquivo truncado ou impossível de decodificar com dimensões válidas.
  imagemCorrompida,
}

/// Resultado do processamento e sanitização de uma foto de perfil.
sealed class ResultadoDoProcessamento {
  const ResultadoDoProcessamento();
}

/// Imagem validada, quadrada (`<= 512×512`), JPEG limpo sem EXIF/GPS.
final class ImagemProcessada extends ResultadoDoProcessamento {
  /// Conteúdo JPEG final pronto para exibição e persistência privada.
  final Uint8List bytesJpegSemExif;

  /// Largura final em pixels (`<= 512`).
  final int largura;

  /// Altura final em pixels (`<= 512`, igual a [largura]).
  final int altura;

  /// Cria o resultado bem-sucedido.
  const ImagemProcessada({
    required this.bytesJpegSemExif,
    required this.largura,
    required this.altura,
  });
}

/// Imagem rejeitada com segurança antes de ser exibida ou gravada.
final class ImagemRejeitada extends ResultadoDoProcessamento {
  /// Razão estruturada da recusa.
  final MotivoRejeicaoImagem motivo;

  /// Cria o resultado de recusa.
  const ImagemRejeitada(this.motivo);
}

enum _FormatoSuportado { jpeg, png, webp }

/// Valida, aplica orientação EXIF, recorta em quadrado centralizado `<= 512 px`
/// e re-encoda em JPEG sem nenhum metadado EXIF/GPS/XMP (FR-005, SC-003).
class ProcessadorDeImagemDePerfil {
  /// Quando verdadeiro (padrão em produção), executa fora da thread de UI.
  final bool emIsolate;

  /// Cria o processador.
  const ProcessadorDeImagemDePerfil({this.emIsolate = true});

  /// Processa [bytesBrutos] fora da thread de UI quando [emIsolate] é ativo.
  Future<ResultadoDoProcessamento> processar(Uint8List bytesBrutos) async {
    if (!emIsolate) {
      return processarSincrono(bytesBrutos);
    }
    return Isolate.run(() => processarSincrono(bytesBrutos));
  }

  /// Versão síncrona executada dentro do isolate e reutilizável em testes.
  static ResultadoDoProcessamento processarSincrono(Uint8List bytesBrutos) {
    if (bytesBrutos.isEmpty) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.imagemCorrompida);
    }

    if (bytesBrutos.length >
        PoliticaDeImagemDePerfil.tamanhoMaximoEntradaBytes) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.arquivoMuitoGrande);
    }

    final _FormatoSuportado? formato = _detectarAssinatura(bytesBrutos);
    if (formato == null) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.formatoNaoSuportado);
    }

    final img.Image? decodificada;
    try {
      decodificada = switch (formato) {
        _FormatoSuportado.jpeg => img.decodeJpg(bytesBrutos),
        _FormatoSuportado.png => img.decodePng(bytesBrutos),
        _FormatoSuportado.webp => img.decodeWebP(bytesBrutos),
      };
    } catch (_) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.imagemCorrompida);
    }

    if (decodificada == null ||
        decodificada.width < 1 ||
        decodificada.height < 1) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.imagemCorrompida);
    }

    // Imagens animadas multi-quadro (ex.: WebP animado / APNG) são recusadas
    // para evitar comportamento inesperado e consumo excessivo de memória.
    if (decodificada.numFrames > 1) {
      return const ImagemRejeitada(MotivoRejeicaoImagem.formatoNaoSuportado);
    }

    // Aplica a rotação EXIF nos pixels antes de descartar qualquer metadado.
    final img.Image orientada = img.bakeOrientation(decodificada);
    final int menorLado = math.min(orientada.width, orientada.height);
    final int ladoAlvo = math.min(
      PoliticaDeImagemDePerfil.dimensaoMaximaPx,
      menorLado,
    );

    final int origemX = (orientada.width - menorLado) ~/ 2;
    final int origemY = (orientada.height - menorLado) ~/ 2;
    final img.Image quadrada = img.copyCrop(
      orientada,
      x: origemX,
      y: origemY,
      width: menorLado,
      height: menorLado,
    );

    final img.Image finalImg = menorLado > ladoAlvo
        ? img.copyResize(
            quadrada,
            width: ladoAlvo,
            height: ladoAlvo,
            interpolation: img.Interpolation.average,
          )
        : quadrada;

    // Copia apenas os pixels RGB num novo buffer virgem para garantir que
    // nenhum metadado EXIF, GPS, IPTC ou XMP sobreviva no encode final.
    final img.Image limpa = img.Image.from(finalImg, noAnimation: true);
    limpa.exif.clear();

    final Uint8List jpegLimpo = Uint8List.fromList(
      img.encodeJpg(
        limpa,
        quality: PoliticaDeImagemDePerfil.qualidadeJpegSaida,
      ),
    );

    return ImagemProcessada(
      bytesJpegSemExif: jpegLimpo,
      largura: limpa.width,
      altura: limpa.height,
    );
  }

  static _FormatoSuportado? _detectarAssinatura(Uint8List b) {
    // JPEG: FF D8 FF
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return _FormatoSuportado.jpeg;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A) {
      return _FormatoSuportado.png;
    }

    // WebP: RIFF....WEBP
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return _FormatoSuportado.webp;
    }

    return null;
  }
}
