//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'acao_registrada.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcaoRegistrada {
  /// Returns a new [AcaoRegistrada] instance.
  AcaoRegistrada({

     this.nomeExibido,

     this.pedidoResumido,

     this.ocorridoEm,
  });

  @JsonKey(
    
    name: r'nome_exibido',
    required: false,
    includeIfNull: false,
  )


  final String? nomeExibido;



  @JsonKey(
    
    name: r'pedido_resumido',
    required: false,
    includeIfNull: false,
  )


  final String? pedidoResumido;



  @JsonKey(
    
    name: r'ocorrido_em',
    required: false,
    includeIfNull: false,
  )


  final DateTime? ocorridoEm;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcaoRegistrada &&
      other.nomeExibido == nomeExibido &&
      other.pedidoResumido == pedidoResumido &&
      other.ocorridoEm == ocorridoEm;

    @override
    int get hashCode =>
        nomeExibido.hashCode +
        pedidoResumido.hashCode +
        ocorridoEm.hashCode;

  factory AcaoRegistrada.fromJson(Map<String, dynamic> json) => _$AcaoRegistradaFromJson(json);

  Map<String, dynamic> toJson() => _$AcaoRegistradaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

