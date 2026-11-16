import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/retrato_de_perfil.dart';

/// Origem escolhida pela pessoa usuária para capturar ou selecionar sua foto.
enum OrigemDaFoto {
  /// Foto já salva no aparelho (Android Photo Picker sem permissão ampla).
  galeria,

  /// Nova foto capturada pela câmera do aparelho sob demanda.
  camera,
}

/// Resultado estruturado da seleção de foto no aparelho.
sealed class ResultadoDaSelecao {
  const ResultadoDaSelecao();
}

/// A pessoa escolheu/capturou uma foto e seus bytes foram carregados.
final class SelecaoConfirmada extends ResultadoDaSelecao {
  /// Conteúdo bruto lido do arquivo escolhido (antes do processamento).
  final Uint8List bytesBrutos;

  /// Cria o resultado bem-sucedido.
  const SelecaoConfirmada(this.bytesBrutos);
}

/// A pessoa fechou a câmera ou galeria sem escolher nenhuma foto.
final class SelecaoCancelada extends ResultadoDaSelecao {
  /// Cria o resultado de cancelamento.
  const SelecaoCancelada();
}

/// O sistema operacional recusou a permissão necessária para a origem pedida.
final class SelecaoSemPermissao extends ResultadoDaSelecao {
  /// Qual origem teve a permissão recusada.
  final OrigemDaFoto origem;

  /// Cria o resultado de permissão negada.
  const SelecaoSemPermissao(this.origem);
}

/// O arquivo escolhido já ultrapassa 15 MB antes mesmo da leitura completa.
final class SelecaoExcedeuLimite extends ResultadoDaSelecao {
  /// Cria o resultado de tamanho excedido.
  const SelecaoExcedeuLimite();
}

/// Falha inesperada ao abrir o seletor ou ler a foto escolhida.
final class SelecaoComFalha extends ResultadoDaSelecao {
  /// Detalhe técnico resumido apenas para depuração local (não exibir cru).
  final String detalhe;

  /// Cria o resultado de falha.
  const SelecaoComFalha(this.detalhe);
}

/// Abstrai o acesso à galeria/câmera e aos ajustes de permissão do sistema.
abstract interface class SeletorDeImagemDoAparelho {
  /// Abre a galeria ou a câmera para [origem] e retorna os bytes ou o motivo
  /// de saída/falha sem lançar exceções de plataforma.
  Future<ResultadoDaSelecao> selecionar(OrigemDaFoto origem);

  /// Abre as configurações do aplicativo no aparelho para revisão de
  /// permissões. Retorna `false` caso a plataforma ou intent não responda.
  Future<bool> abrirConfiguracoesDoAparelho();
}

/// Implementação real sobre `image_picker` e `android_intent_plus`.
class SeletorDeImagemDoAparelhoReal implements SeletorDeImagemDoAparelho {
  final ImagePicker _picker;

  /// Cria o seletor real.
  SeletorDeImagemDoAparelhoReal({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<ResultadoDaSelecao> selecionar(OrigemDaFoto origem) async {
    try {
      final ImageSource source = switch (origem) {
        OrigemDaFoto.galeria => ImageSource.gallery,
        OrigemDaFoto.camera => ImageSource.camera,
      };
      final XFile? arquivo = await _picker.pickImage(source: source);
      if (arquivo == null) return const SelecaoCancelada();

      try {
        final int tamanho = await arquivo.length();
        if (tamanho > PoliticaDeImagemDePerfil.tamanhoMaximoEntradaBytes) {
          return const SelecaoExcedeuLimite();
        }
        final Uint8List bytes = await arquivo.readAsBytes();
        if (bytes.length > PoliticaDeImagemDePerfil.tamanhoMaximoEntradaBytes) {
          return const SelecaoExcedeuLimite();
        }
        return SelecaoConfirmada(bytes);
      } finally {
        // Garante remoção do arquivo temporário bruto gerado pelo plugin em
        // cache para não manter foto original com metadados EXIF no aparelho.
        await _apagarTemporario(arquivo.path);
      }
    } on PlatformException catch (erro) {
      if (erro.code == 'camera_access_denied' ||
          erro.code == 'photo_access_denied') {
        return SelecaoSemPermissao(origem);
      }
      return SelecaoComFalha(erro.code);
    } catch (erro) {
      return SelecaoComFalha(erro.toString());
    }
  }

  @override
  Future<bool> abrirConfiguracoesDoAparelho() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:br.fatec.memora',
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _apagarTemporario(String caminho) async {
    if (caminho.trim().isEmpty) return;
    try {
      final File temp = File(caminho);
      if (temp.existsSync()) {
        temp.deleteSync();
      }
    } catch (_) {
      // Melhor esforço na limpeza do arquivo temporário de cache.
    }
  }
}
