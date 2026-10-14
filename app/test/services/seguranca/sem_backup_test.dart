import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Portão: o Android não copia os dados do aparelho para fora dele.
///
/// ## Por que importa
///
/// Sem estas declarações o Auto Backup leva `shared_prefs/` (data de
/// nascimento, último acesso, preferências, cofre das credenciais) e
/// `app_flutter/` (a conversa da assistente) para o Google Drive e para o
/// aparelho novo. Isso desmente a D3 da feature 003 ("a conversa fica só no
/// aparelho") e a FR-042c da 004 ("a data de nascimento fica só no aparelho").
/// No Android 12+, `allowBackup="false"` sozinho **não** barra a transferência
/// entre aparelhos: é preciso `dataExtractionRules`.
///
/// É teste de código-fonte, como o do V9: o que se afirma é o que está escrito
/// no manifesto e nas regras, e não há como montar o Auto Backup no
/// `flutter test`.
void main() {
  const String pastaAndroid = 'android/app/src/main';
  const List<String> dominios = <String>[
    'root',
    'file',
    'database',
    'sharedpref',
    'external',
  ];

  String ler(String caminho) {
    final File arquivo = File('$pastaAndroid/$caminho');
    expect(
      arquivo.existsSync(),
      isTrue,
      reason:
          '$caminho não existe; sem ele o backup do Android fica '
          'liberado e a D3 / FR-042c deixam de valer.',
    );
    return arquivo.readAsStringSync();
  }

  /// Tira os comentários, para um `allowBackup="true"` explicado em
  /// comentário não enganar o teste.
  String semComentarios(String xml) =>
      xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  /// O conteúdo da seção `<nome>...</nome>`, ou `null` se ela não existir.
  String? secao(String xml, String nome) {
    final Match? m = RegExp(
      '<$nome[^>]*>(.*?)</$nome>',
      dotAll: true,
    ).firstMatch(xml);
    return m?.group(1);
  }

  void exigeExclusaoTotal(String? corpo, String onde) {
    expect(
      corpo,
      isNotNull,
      reason:
          'Faltou a seção $onde. Sem ela o Android 12+ copia tudo '
          '(D3, FR-042c).',
    );
    for (final String dominio in dominios) {
      expect(
        RegExp(
          r'<exclude\s+domain="' + dominio + r'"\s+path="\."\s*/>',
        ).hasMatch(corpo!),
        isTrue,
        reason:
            '$onde não exclui o domínio "$dominio". O que ficar de fora '
            'da exclusão vai para o Drive ou para o aparelho novo '
            '(D3, FR-042c).',
      );
    }
    expect(
      corpo!.contains('<include'),
      isFalse,
      reason:
          '$onde tem <include>: abre de volta o que a exclusão fechou '
          '(D3, FR-042c).',
    );
  }

  test('o manifesto desliga o backup e aponta para as regras', () {
    final String manifesto = semComentarios(ler('AndroidManifest.xml'));
    expect(
      manifesto.contains('android:allowBackup="false"'),
      isTrue,
      reason:
          'allowBackup precisa ser "false": o padrão é ligar o Auto '
          'Backup e levar a conversa e a data de nascimento para o Drive '
          '(D3, FR-042c).',
    );
    expect(
      manifesto.contains(
        'android:dataExtractionRules="@xml/data_extraction_rules"',
      ),
      isTrue,
      reason:
          'Sem dataExtractionRules o Android 12+ ainda transfere os '
          'dados para o aparelho novo, mesmo com allowBackup="false" '
          '(D3, FR-042c).',
    );
    expect(
      manifesto.contains('android:fullBackupContent="@xml/backup_rules"'),
      isTrue,
      reason:
          'Sem fullBackupContent aparelhos com Android 11 ou anterior '
          'que ignorem allowBackup ficam sem regra de exclusão '
          '(D3, FR-042c).',
    );
  });

  test('data_extraction_rules.xml exclui tudo, na nuvem e entre aparelhos', () {
    final String regras = semComentarios(
      ler('res/xml/data_extraction_rules.xml'),
    );
    exigeExclusaoTotal(secao(regras, 'cloud-backup'), '<cloud-backup>');
    exigeExclusaoTotal(secao(regras, 'device-transfer'), '<device-transfer>');
  });

  test('backup_rules.xml (Android 11 ou anterior) exclui tudo', () {
    final String regras = semComentarios(ler('res/xml/backup_rules.xml'));
    exigeExclusaoTotal(
      secao(regras, 'full-backup-content'),
      '<full-backup-content>',
    );
  });
}
