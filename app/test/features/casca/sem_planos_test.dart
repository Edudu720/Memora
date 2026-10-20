import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/configuracoes/presentation/tela_configuracoes.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/features/perfil/presentation/tela_perfil.dart';

/// US9 e FR-008 (T098): Planos fora e linguagem comum na casca do Memora.
///
/// - Não existe plano, assinatura, pagamento nem premium em lugar nenhum do
///   aplicativo: protege a pessoa idosa do golpe "seu plano venceu" (US9).
/// - Termos técnicos como "Hub", "Chatbot" e "App" não aparecem para a pessoa
///   (FR-008); "aplicativo", por extenso, é linguagem comum.
void main() {
  const List<String> termosDePlanos = <String>[
    'plano',
    'assinatura',
    'pagamento',
    'premium',
  ];

  final RegExp regexFr008 = RegExp(r'\b(Hub|Chatbot|App)\b');

  group('US9 & FR-008 — Análise estática de lib/l10n/', () {
    test('nenhum texto de l10n contém termos de planos ou jargões técnicos da FR-008', () {
      final Directory pastaL10n = Directory('lib/l10n');
      expect(
        pastaL10n.existsSync(),
        isTrue,
        reason: 'Diretório lib/l10n deve existir ao rodar o teste na pasta app',
      );

      final List<String> infracoes = <String>[];

      for (final FileSystemEntity entidade in pastaL10n.listSync(recursive: true)) {
        if (entidade is! File || !entidade.path.endsWith('.dart')) continue;

        final String caminhoNormalizado = entidade.path.replaceAll(r'\', '/');
        final String nomeArquivo = caminhoNormalizado.split('/').last;
        final String conteudo = entidade.readAsStringSync();

        final List<String> literais = _extrairLiteraisDeTexto(conteudo);

        for (final String texto in literais) {
          final String textoMinusculo = texto.toLowerCase();

          for (final String termo in termosDePlanos) {
            if (textoMinusculo.contains(termo)) {
              infracoes.add(
                '$nomeArquivo: encontrado termo proibido de plano "$termo" no texto "$texto"',
              );
            }
          }

          final Match? matchFr008 = regexFr008.firstMatch(texto);
          if (matchFr008 != null) {
            infracoes.add(
              '$nomeArquivo: encontrado termo técnico da FR-008 "${matchFr008.group(0)}" no texto "$texto"',
            );
          }
        }
      }

      expect(
        infracoes,
        isEmpty,
        reason:
            'Foram encontrados textos proibidos em lib/l10n/:\n${infracoes.join('\n')}',
      );
    });
  });

  group('US9 — Varredura visual na árvore de cada tela da casca', () {
    Widget envelopar(Widget tela) {
      return MaterialApp(
        theme: TemasMemora.claro,
        home: tela,
      );
    }

    testWidgets('TelaInicio não contém termos de plano', (WidgetTester t) async {
      await t.pumpWidget(
        envelopar(
          TelaInicio(
            nome: 'Dona Ana',
            aoConversar: () {},
            aoVerTudo: () {},
          ),
        ),
      );
      await t.pumpAndSettle();

      final List<String> infracoes = _verificarTextosNaArvore();
      expect(infracoes, isEmpty);
    });

    testWidgets('TelaHub não contém termos de plano nas portas legítimas', (WidgetTester t) async {
      await t.pumpWidget(
        envelopar(
          TelaHub(
            portas: <PortaDoHub>[
              PortaDoHub(
                rotulo: 'Conversar com a Memora',
                descricao: 'Tire dúvidas e peça ajuda',
                ilustracao: Ilustracao.portaConversa,
                aoAbrir: () {},
                principal: true,
              ),
              PortaDoHub(
                rotulo: 'Aprender a usar aplicativos',
                descricao: 'Passo a passo ilustrado',
                ilustracao: Ilustracao.portaAplicativos,
                aoAbrir: () {},
              ),
            ],
            aoVoltar: () {},
          ),
        ),
      );
      await t.pumpAndSettle();

      final List<String> infracoes = _verificarTextosNaArvore();
      expect(infracoes, isEmpty);
    });

    testWidgets('TelaConfiguracoes não contém termos de plano', (WidgetTester t) async {
      await t.pumpWidget(
        envelopar(
          TelaConfiguracoes(
            aoAbrirAparencia: () {},
            aoAbrirAcessibilidade: () {},
            aoAbrirPrivacidade: () {},
            aoAbrirConta: () {},
          ),
        ),
      );
      await t.pumpAndSettle();

      final List<String> infracoes = _verificarTextosNaArvore();
      expect(infracoes, isEmpty);
    });

    testWidgets('TelaPerfil não contém termos de plano', (WidgetTester t) async {
      await t.pumpWidget(
        envelopar(
          TelaPerfil(
            nome: 'Dona Ana',
            canal: Future<String?>.value('ana@exemplo.com'),
          ),
        ),
      );
      await t.pumpAndSettle();

      final List<String> infracoes = _verificarTextosNaArvore();
      expect(infracoes, isEmpty);
    });

    testWidgets('portão: provar quebrando ao colocar "Plano" numa porta do Hub', (WidgetTester t) async {
      await t.pumpWidget(
        envelopar(
          TelaHub(
            portas: <PortaDoHub>[
              PortaDoHub(
                rotulo: 'Plano Familiar',
                descricao: 'Assinatura e pagamento mensal',
                ilustracao: Ilustracao.portaConversa,
                aoAbrir: () {},
              ),
            ],
            aoVoltar: () {},
          ),
        ),
      );
      await t.pumpAndSettle();

      final List<String> infracoes = _verificarTextosNaArvore();
      expect(
        infracoes,
        isNotEmpty,
        reason: 'O verificador visual deve flagrar porta com termo proibido no Hub',
      );
      expect(
        infracoes.any((String msg) => msg.contains('plano') || msg.contains('assinatura')),
        isTrue,
      );
    });
  });
}

List<String> _extrairLiteraisDeTexto(String codigo) {
  final List<String> linhas = codigo.split('\n');
  final List<String> codigoLimpo = <String>[];

  for (final String linha in linhas) {
    final String semEspacos = linha.trim();
    if (semEspacos.startsWith('///') || semEspacos.startsWith('//')) {
      continue;
    }
    if (linha.contains('//')) {
      codigoLimpo.add(linha.split('//').first);
    } else {
      codigoLimpo.add(linha);
    }
  }

  final String conteudo = codigoLimpo.join('\n');
  final RegExp regexLiterais = RegExp(
    r"""('''[\s\S]*?'''|""" r'"""[\s\S]*?"""|' r"""'[^']*'|"[^"]*")""",
  );

  final List<String> resultados = <String>[];
  for (final Match m in regexLiterais.allMatches(conteudo)) {
    final String bruto = m.group(0)!;
    if (bruto.startsWith("'''") || bruto.startsWith('"""')) {
      resultados.add(bruto.substring(3, bruto.length - 3));
    } else if (bruto.startsWith("'") || bruto.startsWith('"')) {
      resultados.add(bruto.substring(1, bruto.length - 1));
    }
  }
  return resultados;
}

List<String> _verificarTextosNaArvore() {
  const List<String> termosProibidos = <String>[
    'plano',
    'assinatura',
    'pagamento',
    'premium',
  ];

  final List<String> infracoes = <String>[];

  for (final Element elemento in find.byType(Text).evaluate()) {
    final Text widget = elemento.widget as Text;
    final String conteudo = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    final String minusculo = conteudo.toLowerCase();

    for (final String termo in termosProibidos) {
      if (minusculo.contains(termo)) {
        infracoes.add('Encontrado termo proibido "$termo" no texto "$conteudo"');
      }
    }
  }

  return infracoes;
}
