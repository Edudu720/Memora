//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'servico.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Servico {
  /// Returns a new [Servico] instance.
  Servico({

    required  this.id,

    required  this.chave,

    required  this.nomeExibido,

     this.descricaoCurta,

    required  this.categoria,

    required  this.memoraPodeAbrir,

     this.identificadorAndroid,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Identificador estável do item, igual em qualquer banco. É o que liga o item ao guia de passo a passo embarcado no aplicativo. O `id` continua sendo o que a trilha de auditoria referencia. 
  @JsonKey(
    
    name: r'chave',
    required: true,
    includeIfNull: false,
  )


  final String chave;



  @JsonKey(
    
    name: r'nome_exibido',
    required: true,
    includeIfNull: false,
  )


  final String nomeExibido;



  @JsonKey(
    
    name: r'descricao_curta',
    required: false,
    includeIfNull: false,
  )


  final String? descricaoCurta;



  @JsonKey(
    
    name: r'categoria',
    required: true,
    includeIfNull: false,
  )


  final ServicoCategoriaEnum categoria;



      /// Redundante com `categoria`, e de propósito: é o que a tela exibe (FR-045), e derivar isso na tela espalharia a regra da FR-041 por dois lugares. 
  @JsonKey(
    
    name: r'memora_pode_abrir',
    required: true,
    includeIfNull: false,
  )


  final bool memoraPodeAbrir;



      /// Ausente quando `sensivel`.
  @JsonKey(
    
    name: r'identificador_android',
    required: false,
    includeIfNull: false,
  )


  final String? identificadorAndroid;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Servico &&
      other.id == id &&
      other.chave == chave &&
      other.nomeExibido == nomeExibido &&
      other.descricaoCurta == descricaoCurta &&
      other.categoria == categoria &&
      other.memoraPodeAbrir == memoraPodeAbrir &&
      other.identificadorAndroid == identificadorAndroid;

    @override
    int get hashCode =>
        id.hashCode +
        chave.hashCode +
        nomeExibido.hashCode +
        descricaoCurta.hashCode +
        categoria.hashCode +
        memoraPodeAbrir.hashCode +
        identificadorAndroid.hashCode;

  factory Servico.fromJson(Map<String, dynamic> json) => _$ServicoFromJson(json);

  Map<String, dynamic> toJson() => _$ServicoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ServicoCategoriaEnum {
@JsonValue(r'sensivel')
sensivel(r'sensivel'),
@JsonValue(r'cotidiano')
cotidiano(r'cotidiano');

const ServicoCategoriaEnum(this.value);

final String value;

@override
String toString() => value;
}


