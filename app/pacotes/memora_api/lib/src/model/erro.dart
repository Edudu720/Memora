//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'erro.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Erro {
  /// Returns a new [Erro] instance.
  Erro({

    required  this.codigo,

    required  this.mensagem,

     this.tentarNovamenteEmSegundos,
  });

      /// Código estável, para o aplicativo decidir o comportamento
  @JsonKey(
    
    name: r'codigo',
    required: true,
    includeIfNull: false,
  )


  final String codigo;



      /// Texto **pronto para exibição**, na persona da Memora: acolhedor, sem jargão e sem culpar a pessoa. Nunca expõe detalhe interno (FR-041). 
  @JsonKey(
    
    name: r'mensagem',
    required: true,
    includeIfNull: false,
  )


  final String mensagem;



      /// Presente apenas em bloqueio temporário
  @JsonKey(
    
    name: r'tentar_novamente_em_segundos',
    required: false,
    includeIfNull: false,
  )


  final int? tentarNovamenteEmSegundos;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Erro &&
      other.codigo == codigo &&
      other.mensagem == mensagem &&
      other.tentarNovamenteEmSegundos == tentarNovamenteEmSegundos;

    @override
    int get hashCode =>
        codigo.hashCode +
        mensagem.hashCode +
        tentarNovamenteEmSegundos.hashCode;

  factory Erro.fromJson(Map<String, dynamic> json) => _$ErroFromJson(json);

  Map<String, dynamic> toJson() => _$ErroToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

