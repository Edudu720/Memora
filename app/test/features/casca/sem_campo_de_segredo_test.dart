import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-048 (T098a): Campo de segredo ([CampoSenha], [CampoCodigo]) só existe na autenticação.
///
/// Fora de `features/autenticacao/`, nenhuma tela do Memora pode pedir senha
/// nem código. Isso protege a pessoa idosa de golpes de tela falsa dentro do
/// aplicativo (especificação da feature 004, US9 e FR-048).
void main() {
  test(
    'nenhum arquivo fora de features/autenticacao/ usa CampoSenha ou CampoCodigo (FR-048)',
    () {
      final Directory pastaFeatures = Directory('lib/features');
      expect(
        pastaFeatures.existsSync(),
        isTrue,
        reason: 'Diretório lib/features deve existir ao rodar o teste na pasta app',
      );

      final List<String> arquivosInfratores = <String>[];

      for (final FileSystemEntity entidade in pastaFeatures.listSync(recursive: true)) {
        if (entidade is! File || !entidade.path.endsWith('.dart')) continue;

        final String caminhoNormalizado = entidade.path.replaceAll(r'\', '/');
        final String conteudo = entidade.readAsStringSync();

        if (!_verificarArquivo(caminhoNormalizado, conteudo)) {
          arquivosInfratores.add(caminhoNormalizado);
        }
      }

      expect(
        arquivosInfratores,
        isEmpty,
        reason:
            'Os seguintes arquivos fora de features/autenticacao/ usam campos de segredo: $arquivosInfratores',
      );
    },
  );

  test('portão: provar quebrando que CampoSenha na TelaPerfil reprova o verificador', () {
    const String caminhoSimulado = 'lib/features/perfil/presentation/tela_perfil.dart';
    const String conteudoComInfracao = '''
import 'package:flutter/material.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return const CampoSenha(rotulo: 'Senha');
  }
}
''';

    final bool passou = _verificarArquivo(caminhoSimulado, conteudoComInfracao);
    expect(
      passou,
      isFalse,
      reason: 'O verificador deve reprovar CampoSenha fora de features/autenticacao/',
    );
  });
}

String _removerComentarios(String codigo) {
  final String semBloco = codigo.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return semBloco.replaceAll(RegExp(r'//.*'), '');
}

bool _verificarArquivo(String caminho, String conteudo) {
  final String normalizado = caminho.replaceAll(r'\', '/');
  if (normalizado.contains('features/autenticacao/')) return true;

  final String limpo = _removerComentarios(conteudo);
  if (limpo.contains('CampoSenha') || limpo.contains('CampoCodigo')) {
    return false;
  }
  return true;
}

