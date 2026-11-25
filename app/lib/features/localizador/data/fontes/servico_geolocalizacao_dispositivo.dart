import 'package:geolocator/geolocator.dart';

/// Posição simplificada do dispositivo.
class PosicaoSimples {
  /// Latitude em graus decimais.
  final double latitude;

  /// Longitude em graus decimais.
  final double longitude;

  /// Cria uma posição geográfica simples.
  const PosicaoSimples(this.latitude, this.longitude);
}

/// Status de acesso à localização do aparelho.
enum StatusPermissaoLocalizacao {
  /// Permissão concedida pelo sistema.
  concedida,

  /// Permissão ainda não concedida ou recusada.
  negada,

  /// Serviço de localização/GPS desligado no aparelho.
  desativadaNoAparelho,

  /// Permissão negada permanentemente nas configurações do sistema.
  bloqueadaPermanente,
}

/// Serviço seguro de geolocalização do dispositivo (FR-004, NFR-007).
class ServicoGeolocalizacaoDispositivo {
  /// Verifica o status atual de permissão e serviço de localização.
  Future<StatusPermissaoLocalizacao> verificarPermissao() async {
    try {
      final bool servicoHabilitado =
          await Geolocator.isLocationServiceEnabled();
      if (!servicoHabilitado) {
        return StatusPermissaoLocalizacao.desativadaNoAparelho;
      }

      final LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        return StatusPermissaoLocalizacao.negada;
      }
      if (permissao == LocationPermission.deniedForever) {
        return StatusPermissaoLocalizacao.bloqueadaPermanente;
      }
      return StatusPermissaoLocalizacao.concedida;
    } catch (_) {
      return StatusPermissaoLocalizacao.negada;
    }
  }

  /// Solicita a permissão de localização ao sistema operacional.
  Future<StatusPermissaoLocalizacao> solicitarPermissao() async {
    try {
      final LocationPermission permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.always ||
          permissao == LocationPermission.whileInUse) {
        return StatusPermissaoLocalizacao.concedida;
      }
      if (permissao == LocationPermission.deniedForever) {
        return StatusPermissaoLocalizacao.bloqueadaPermanente;
      }
      return StatusPermissaoLocalizacao.negada;
    } catch (_) {
      return StatusPermissaoLocalizacao.negada;
    }
  }

  /// Obtém a posição atual com precisão média e tempo limite de 7 segundos.
  Future<PosicaoSimples?> obterPosicaoAtual() async {
    try {
      final Position posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
      return PosicaoSimples(posicao.latitude, posicao.longitude);
    } catch (_) {
      try {
        final Position? ultima = await Geolocator.getLastKnownPosition();
        if (ultima != null) {
          return PosicaoSimples(ultima.latitude, ultima.longitude);
        }
      } catch (_) {}
      return null;
    }
  }
}
