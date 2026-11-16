import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memora/features/perfil/domain/processador_de_imagem.dart';
import 'package:memora/features/perfil/domain/retrato_de_perfil.dart';

void main() {
  group('ProcessadorDeImagemDePerfil (FR-005, SC-003)', () {
    const ProcessadorDeImagemDePerfil processador =
        ProcessadorDeImagemDePerfil();

    Uint8List criarJpegSintetico({
      required int largura,
      required int altura,
      bool comExifGps = false,
      int? orientation,
    }) {
      final img.Image imagem = img.Image(width: largura, height: altura);
      // Preenche metadado superior esquerda distinto para verificar rotação/corte.
      img.fillRect(
        imagem,
        x1: 0,
        y1: 0,
        x2: largura - 1,
        y2: altura - 1,
        color: img.ColorRgb8(20, 80, 160),
      );
      img.fillRect(
        imagem,
        x1: 0,
        y1: 0,
        x2: (largura ~/ 2) - 1,
        y2: (altura ~/ 2) - 1,
        color: img.ColorRgb8(230, 60, 40),
      );

      if (comExifGps || orientation != null) {
        if (orientation != null) {
          imagem.exif.imageIfd.orientation = orientation;
        }
        if (comExifGps) {
          imagem.exif.imageIfd.make = 'AparelhoTesteSecreto';
          imagem.exif.imageIfd.model = 'ModeloSecretoXYZ';
          imagem.exif.gpsIfd.gpsLatitudeRef = 'S';
          imagem.exif.gpsIfd.gpsLatitude = -23.55052;
          imagem.exif.gpsIfd.gpsLongitudeRef = 'W';
          imagem.exif.gpsIfd.gpsLongitude = -46.633308;
        }
      }

      return Uint8List.fromList(img.encodeJpg(imagem, quality: 92));
    }

    bool contemSegmentoApp1Exif(Uint8List jpeg) {
      // Varre marcadores JPEG procurando APP1 (0xFF 0xE1) com "Exif\0\0"
      int i = 2;
      while (i + 4 < jpeg.length) {
        if (jpeg[i] != 0xFF) break;
        final int marcador = jpeg[i + 1];
        if (marcador == 0xDA || marcador == 0xD9) break; // SOS ou EOI
        final int comprimento = (jpeg[i + 2] << 8) | jpeg[i + 3];
        if (marcador == 0xE1 && i + 10 < jpeg.length) {
          final String assinatura = ascii.decode(
            jpeg.sublist(i + 4, i + 8),
            allowInvalid: true,
          );
          if (assinatura == 'Exif') return true;
        }
        i += 2 + comprimento;
      }
      return false;
    }

    test(
        'recorta em quadrado 1:1 <= 512px e remove 100% dos metadados EXIF/GPS',
        () async {
      final Uint8List entrada = criarJpegSintetico(
        largura: 1200,
        altura: 800,
        comExifGps: true,
        orientation: 6, // 90° clockwise
      );

      // Confirma que a entrada realmente tinha bloco EXIF e string secreta.
      expect(contemSegmentoApp1Exif(entrada), isTrue);
      expect(
        latin1.decode(entrada).contains('AparelhoTesteSecreto'),
        isTrue,
      );

      final ResultadoDoProcessamento resultado =
          await processador.processar(entrada);

      expect(resultado, isA<ImagemProcessada>());
      final ImagemProcessada processada = resultado as ImagemProcessada;

      expect(processada.largura, 512);
      expect(processada.altura, 512);
      expect(
        contemSegmentoApp1Exif(processada.bytesJpegSemExif),
        isFalse,
        reason: 'Nenhum segmento APP1 Exif pode sobreviver no arquivo salvo',
      );
      expect(
        latin1
            .decode(processada.bytesJpegSemExif)
            .contains('AparelhoTesteSecreto'),
        isFalse,
      );

      final img.Image? decodificadaSaida =
          img.decodeJpg(processada.bytesJpegSemExif);
      expect(decodificadaSaida, isNotNull);
      expect(decodificadaSaida!.width, 512);
      expect(decodificadaSaida.height, 512);
      expect(decodificadaSaida.exif.isEmpty, isTrue);
      expect(decodificadaSaida.exif.gpsIfd.isEmpty, isTrue);
    });

    test('aceita PNG e WebP estático válidos reduzindo sem distorcer',
        () async {
      final img.Image retanguloPng = img.Image(width: 900, height: 600);
      img.fill(retanguloPng, color: img.ColorRgb8(50, 140, 90));
      final Uint8List pngBytes = Uint8List.fromList(img.encodePng(retanguloPng));

      final ResultadoDoProcessamento resPng =
          await processador.processar(pngBytes);
      expect(resPng, isA<ImagemProcessada>());
      final ImagemProcessada okPng = resPng as ImagemProcessada;
      expect(okPng.largura, 512);
      expect(okPng.altura, 512);

      // Imagem menor que 512 mantém lado menor sem ampliação artificial
      final img.Image pequena = img.Image(width: 320, height: 240);
      img.fill(pequena, color: img.ColorRgb8(180, 90, 20));
      final Uint8List pequenaPng = Uint8List.fromList(img.encodePng(pequena));
      final ResultadoDoProcessamento resPeq =
          await processador.processar(pequenaPng);
      expect(resPeq, isA<ImagemProcessada>());
      expect((resPeq as ImagemProcessada).largura, 240);
      expect(resPeq.altura, 240);
    });

    test('rejeita arquivo acima de 15 MB antes da decodificação', () {
      final Uint8List gigante = Uint8List(
        PoliticaDeImagemDePerfil.tamanhoMaximoEntradaBytes + 1,
      );
      gigante[0] = 0xFF;
      gigante[1] = 0xD8;
      gigante[2] = 0xFF;

      final ResultadoDoProcessamento resultado =
          ProcessadorDeImagemDePerfil.processarSincrono(gigante);

      expect(resultado, isA<ImagemRejeitada>());
      expect(
        (resultado as ImagemRejeitada).motivo,
        MotivoRejeicaoImagem.arquivoMuitoGrande,
      );
    });

    test('rejeita PDF renomeado para .jpg, GIF e bytes HEIC falsos', () async {
      final Uint8List pdfDisfarcado = Uint8List.fromList(
        utf8.encode('%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>'),
      );
      final Uint8List gifFake = Uint8List.fromList(
        utf8.encode('GIF89a..........'),
      );
      // Cabeçalho ISO BMFF/ftyp típica de HEIC
      final Uint8List heic = Uint8List.fromList(<int>[
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // ftyp
        0x68, 0x65, 0x69, 0x63, // heic
        0x00, 0x00, 0x00, 0x00,
      ]);

      for (final Uint8List invalido in <Uint8List>[
        pdfDisfarcado,
        gifFake,
        heic,
      ]) {
        final ResultadoDoProcessamento res =
            await processador.processar(invalido);
        expect(res, isA<ImagemRejeitada>());
        expect(
          (res as ImagemRejeitada).motivo,
          MotivoRejeicaoImagem.formatoNaoSuportado,
        );
      }
    });

    test('rejeita imagem multi-quadro animada (APNG)', () async {
      final img.Image frame1 = img.Image(width: 64, height: 64);
      img.fill(frame1, color: img.ColorRgb8(255, 0, 0));
      final img.Image frame2 = img.Image(width: 64, height: 64);
      img.fill(frame2, color: img.ColorRgb8(0, 255, 0));
      frame1.addFrame(frame2);
      final Uint8List apng = Uint8List.fromList(img.encodePng(frame1));

      final ResultadoDoProcessamento res = await processador.processar(apng);
      expect(res, isA<ImagemRejeitada>());
      expect(
        (res as ImagemRejeitada).motivo,
        MotivoRejeicaoImagem.formatoNaoSuportado,
      );
    });

    test('rejeita arquivo vazio ou JPEG corrompido sem lançar exceção',
        () async {
      final ResultadoDoProcessamento resVazio =
          await processador.processar(Uint8List(0));
      expect(resVazio, isA<ImagemRejeitada>());

      final Uint8List jpegCorrompido = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x12,
        0x34,
      ]);
      final ResultadoDoProcessamento resCorrompido =
          await processador.processar(jpegCorrompido);
      expect(resCorrompido, isA<ImagemRejeitada>());
      expect(
        (resCorrompido as ImagemRejeitada).motivo,
        MotivoRejeicaoImagem.imagemCorrompida,
      );
    });
  });
}
