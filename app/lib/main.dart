import 'package:flutter/material.dart';

import 'design_system/design_system.dart';

void main() => runApp(const AplicativoMemora());

/// Raiz do aplicativo Memora.
///
/// Nesta etapa o aplicativo apenas exercita o Design System. As telas reais
/// chegam com a feature 001, que só é desbloqueada quando os componentes
/// estiverem prontos e validados.
class AplicativoMemora extends StatelessWidget {
  /// Cria a raiz do aplicativo.
  const AplicativoMemora({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memora',
      debugShowCheckedModeBanner: false,
      theme: TemasMemora.claro,
      darkTheme: TemasMemora.escuro,
      home: const _AmostraDeComponentes(),
    );
  }
}

/// Amostra provisória dos componentes, substituída pela galeria em T045.
///
/// Mostra lado a lado a distinção que a fase 3 resolve: **informação não pode
/// parecer ação**. No protótipo, os dados do Perfil eram pílulas azuis
/// idênticas aos botões do Hub.
class _AmostraDeComponentes extends StatelessWidget {
  const _AmostraDeComponentes();

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextoMemora.tituloTela('Memora', cor: cores.primaria),
              const SizedBox(height: MemoraEspacamento.xxl),

              // ---------- Informação: NÃO é clicável ----------
              const ListaInformacao(
                titulo: 'Isto é informação',
                campos: <CampoInformacao>[
                  CampoInformacao(
                    rotulo: 'Nome',
                    valor: 'Ana',
                    icone: Icons.person_outline,
                  ),
                  CampoInformacao(
                    rotulo: 'Idade',
                    valor: '72 anos',
                    icone: Icons.cake_outlined,
                  ),
                  CampoInformacao(
                    rotulo: 'E-mail',
                    valor: 'ana@email.com',
                    icone: Icons.mail_outline,
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              const DestaqueInformacao(
                rotulo: 'Seu plano',
                valor: 'Premium',
                icone: Icons.star_outline,
              ),

              const SizedBox(height: MemoraEspacamento.xxl),

              // ---------- Ação: É clicável ----------
              const TextoMemora.tituloSecao('Isto é ação'),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoPrimario(
                rotulo: 'Começar jornada',
                icone: Icons.arrow_forward,
                aoTocar: () {},
              ),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoSecundario(
                rotulo: 'Entrar com Google',
                aoTocar: () {},
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const BotaoPrimario(rotulo: 'Desabilitado'),
              const SizedBox(height: MemoraEspacamento.md),
              const BotaoPrimario(rotulo: 'Carregando', carregando: true),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoTerciario(
                rotulo: 'Esqueci minha senha',
                aoTocar: () {},
              ),

              // Ação destrutiva fica isolada por espaçamento maior (FR-013).
              const SizedBox(height: MemoraEspacamento.xxxl),
              BotaoPerigo(
                rotulo: 'Apagar minha conta',
                icone: Icons.warning_amber_rounded,
                aoTocar: () {},
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
