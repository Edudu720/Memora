import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_perfil.dart';

/// Resultado da tela simples de pré-visualização da foto escolhida (`FR-005`).
enum AcaoPreVisualizacaoFoto {
  /// A pessoa confirmou e quer salvar esta foto no Perfil.
  usarEstaFoto,

  /// A pessoa quer voltar e escolher outra foto ou origem.
  escolherOutra,
}

/// Pré-visualização com recorte quadrado centralizado aplicado ("Ficou boa assim?").
///
/// Sem gestos complexos de pinça ou arraste (decisão de clarificação `Q1: A`),
/// oferecendo apenas dois botões claros com ícone e texto visível.
class TelaPreVisualizacaoFoto extends StatelessWidget {
  /// Chave do botão principal que confirma e salva a foto.
  static const Key chaveConfirmar = Key('perfil.pre_visualizacao.confirmar');

  /// Chave do botão secundário que volta para escolher outra foto.
  static const Key chaveEscolherOutra =
      Key('perfil.pre_visualizacao.escolher_outra');

  /// Bytes JPEG já recortados `1:1` e sem metadados EXIF.
  final Uint8List bytesJpegSemExif;

  /// Cria a tela de pré-visualização.
  const TelaPreVisualizacaoFoto({
    required this.bytesJpegSemExif,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Size tela = MediaQuery.sizeOf(context);
    final double diametro = (tela.width * 0.58).clamp(140.0, 220.0);

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CabecalhoDeTela(
                titulo: TextosPerfil.tituloPreVisualizacaoFoto,
                aoVoltar: () => Navigator.of(context)
                    .pop(AcaoPreVisualizacaoFoto.escolherOutra),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const TextoMemora.apoio(TextosPerfil.apoioPreVisualizacaoFoto),
              const SizedBox(height: MemoraEspacamento.xl),
              Center(
                child: Semantics(
                  image: true,
                  label: TextosPerfil.semanticaFotoPropria,
                  child: ExcludeSemantics(
                    child: Container(
                      width: diametro,
                      height: diametro,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cores.superficieAlt,
                        border: Border.all(
                          color: cores.borda,
                          width: MemoraDimensoes.bordaEnfase,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        bytesJpegSemExif,
                        width: diametro,
                        height: diametro,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xl),
              BotaoPrimario(
                key: chaveConfirmar,
                rotulo: TextosPerfil.botaoUsarEstaFoto,
                icone: Icons.check_circle_outline_rounded,
                aoTocar: () => Navigator.of(context)
                    .pop(AcaoPreVisualizacaoFoto.usarEstaFoto),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoSecundario(
                key: chaveEscolherOutra,
                rotulo: TextosPerfil.botaoEscolherOutraFoto,
                icone: Icons.photo_library_rounded,
                aoTocar: () => Navigator.of(context)
                    .pop(AcaoPreVisualizacaoFoto.escolherOutra),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
