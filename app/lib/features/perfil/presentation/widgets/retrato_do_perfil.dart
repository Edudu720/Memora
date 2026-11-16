import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_perfil.dart';
import '../../domain/retrato_de_perfil.dart';

/// Retrato circular da pessoa usuária na tela de Meu Perfil (`FR-001`, `FR-002`).
///
/// Exibe, conforme o estado atual:
/// 1. A **foto própria** salva localmente (`FotoPropriaDePerfil`);
/// 2. O **avatar ilustrado** escolhido da Memora (`AvatarIlustradoDePerfil`); ou
/// 3. O **retrato padrão neutro** (iniciais do nome ou silhueta humana), sem
///    se confundir com a assistente Memora.
class RetratoDoPerfil extends StatelessWidget {
  /// Diâmetro do retrato circular, em pixels lógicos.
  final double tamanho;

  /// Nome de tratamento usado para derivar as iniciais no retrato padrão.
  final String nome;

  /// Retrato atualmente salvo para a conta, ou `null` para retrato padrão.
  final RetratoDePerfil? retrato;

  /// Chave aplicada ao container circular do retrato (ex.: `TelaPerfil.chaveDesenho`).
  final Key? chaveDoRetrato;

  /// Cria o retrato de perfil.
  const RetratoDoPerfil({
    required this.nome,
    this.retrato,
    this.tamanho = 112,
    this.chaveDoRetrato,
    super.key,
  });

  /// Extrai até duas iniciais legíveis a partir do nome informado.
  static String? iniciaisDe(String nome) {
    final List<String> partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return null;

    String? primeiraLetra(String palavra) {
      for (final int rune in palavra.runes) {
        final String ch = String.fromCharCode(rune);
        if (RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(ch)) {
          return ch.toUpperCase();
        }
      }
      return null;
    }

    final String? primeira = primeiraLetra(partes.first);
    if (primeira == null) return null;
    if (partes.length == 1) return primeira;

    final String? ultima = primeiraLetra(partes.last);
    if (ultima == null) return primeira;
    return '$primeira$ultima';
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final RetratoDePerfil? atual = retrato;

    final String descricaoSemantica = switch (atual) {
      FotoPropriaDePerfil() => TextosPerfil.semanticaFotoPropria,
      AvatarIlustradoDePerfil(avatar: final AvatarIlustrado avatar) =>
        TextosPerfil.semanticaAvatarEscolhido(avatar.rotulo),
      null => TextosPerfil.semanticaSemFoto,
    };

    final Color fundoCirculo = switch (atual) {
      FotoPropriaDePerfil() => cores.superficieAlt,
      AvatarIlustradoDePerfil() => cores.medalhao,
      null => cores.primaria,
    };

    return Semantics(
      image: true,
      label: descricaoSemantica,
      child: ExcludeSemantics(
        child: Container(
          key: chaveDoRetrato,
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fundoCirculo,
            border: Border.all(
              color: cores.borda,
              width: MemoraDimensoes.bordaEnfase,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _conteudo(context, cores, atual),
        ),
      ),
    );
  }

  Widget _conteudo(
    BuildContext context,
    MemoraCores cores,
    RetratoDePerfil? atual,
  ) {
    if (atual is FotoPropriaDePerfil) {
      final Key chaveImagem = ValueKey<String>(
        '${atual.caminhoDoArquivo}|${atual.atualizadaEm.microsecondsSinceEpoch}',
      );
      if (atual.bytesEmMemoria != null) {
        return Image.memory(
          Uint8List.fromList(atual.bytesEmMemoria!),
          key: chaveImagem,
          width: tamanho,
          height: tamanho,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
              _padraoNeutro(cores),
        );
      }
      return Image.file(
        File(atual.caminhoDoArquivo),
        key: chaveImagem,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
            _padraoNeutro(cores),
      );
    }

    if (atual is AvatarIlustradoDePerfil) {
      final AvatarIlustrado avatar = atual.avatar;
      if (avatar.ehSvg) {
        return Padding(
          padding: EdgeInsets.all(tamanho * 0.08),
          child: SvgPicture.asset(avatar.caminhoAsset),
        );
      }
      final int cachePx = (tamanho * 2.5).clamp(48, 512).round();
      return Image.asset(
        avatar.caminhoAsset,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
      );
    }

    return _padraoNeutro(cores);
  }

  Widget _padraoNeutro(MemoraCores cores) {
    final String? iniciais = iniciaisDe(nome);
    if (iniciais == null) {
      return Icon(
        Icons.person_outline,
        size: tamanho * 0.5,
        color: cores.sobrePrimaria,
      );
    }
    return Container(
      color: cores.primaria,
      alignment: Alignment.center,
      child: Text(
        iniciais,
        maxLines: 1,
        style: TextStyle(
          fontSize: tamanho * 0.34,
          fontWeight: FontWeight.w700,
          color: cores.sobrePrimaria,
        ),
      ),
    );
  }
}
