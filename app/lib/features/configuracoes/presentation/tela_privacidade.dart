import 'package:flutter/material.dart';

import '../../../design_system/componentes/botoes/botao_secundario.dart';
import '../../../design_system/componentes/cartoes/caixa_de_etapa.dart';
import '../../../design_system/componentes/cartoes/cartao.dart';
import '../../../design_system/componentes/confirmacao/confirmacao_memora.dart';
import '../../../design_system/componentes/feedback/carregando.dart';
import '../../../design_system/componentes/feedback/mensagem_erro.dart';
import '../../../design_system/componentes/ilustracao/ilustracao_memora.dart';
import '../../../design_system/componentes/informacao/campo_informacao.dart';
import '../../../design_system/componentes/informacao/lista_informacao.dart';
import '../../../design_system/componentes/navegacao/cabecalho_de_tela.dart';
import '../../../design_system/componentes/texto/texto_memora.dart';
import '../../../design_system/temas/memora_theme_extension.dart';
import '../../../design_system/tokens/espacamento.dart';
import '../../../l10n/textos_configuracoes.dart';

/// O que fica guardado no aparelho, e o que se pode apagar (US7, FR-040).
///
/// ## Informação, e depois uma ação
///
/// A primeira metade diz, em linguagem comum, **o que** o Memora guarda neste
/// celular e **quando** isso sai — como [CampoInformacao], que não aceita
/// toque. A segunda oferece a única ação: apagar a conversa.
///
/// ## Apagar é irreversível, e a tela trata assim (FR-040)
///
/// A pergunta é a [ConfirmacaoMemora.irreversivel], com as duas etapas dela e
/// o botão de apagar **longe** do de recusar. O primeiro botão da tela só
/// abre a pergunta: um toque, sozinho, não apaga nada. Um golpista que diga
/// "apague a conversa para liberar espaço" esbarra em três decisões.
class TelaPrivacidade extends StatefulWidget {
  /// Apaga a conversa do aparelho. Roda só depois das duas etapas.
  final Future<void> Function() aoApagarConversa;

  /// Volta a Ajustes.
  final VoidCallback aoVoltar;

  /// Cria a tela de Privacidade.
  const TelaPrivacidade({
    required this.aoApagarConversa,
    required this.aoVoltar,
    super.key,
  });

  /// Chave do botão que abre a pergunta.
  static const Key chaveApagar = Key('privacidade.apagar');

  /// Chave da confirmação irreversível.
  static const Key chaveConfirmacao = Key('privacidade.confirmacao');

  /// Chave do aviso de que a conversa foi apagada.
  static const Key chaveApagada = Key('privacidade.apagada');

  /// Chave do aviso de falha.
  static const Key chaveFalha = Key('privacidade.falha');

  @override
  State<TelaPrivacidade> createState() => _TelaPrivacidadeState();
}

enum _Fase { inicial, perguntando, apagando, apagada, falhou }

class _TelaPrivacidadeState extends State<TelaPrivacidade> {
  _Fase _fase = _Fase.inicial;

  Future<void> _apagar() async {
    setState(() => _fase = _Fase.apagando);
    try {
      await widget.aoApagarConversa();
      if (!mounted) return;
      setState(() => _fase = _Fase.apagada);
    } catch (_) {
      // Não deu para apagar: a conversa continua lá, e a tela diz isso em vez
      // de fingir que apagou.
      if (!mounted) return;
      setState(() => _fase = _Fase.falhou);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: TextosConfiguracoes.tituloPrivacidade,
              aoVoltar: widget.aoVoltar,
              ilustracao: Ilustracao.portaRegistro,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MemoraEspacamento.lg,
                0,
                MemoraEspacamento.lg,
                MemoraEspacamento.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Cartao(
                    padding: EdgeInsets.all(MemoraEspacamento.md),
                    child: TextoMemora.apoio(
                      TextosConfiguracoes.privacidadeIntro,
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.lg),
                  const ListaInformacao(
                    campos: <CampoInformacao>[
                      CampoInformacao(
                        rotulo: TextosConfiguracoes.guardadoConversa,
                        valor: TextosConfiguracoes.guardadoConversaValor,
                      ),
                      CampoInformacao(
                        rotulo: TextosConfiguracoes.guardadoIdade,
                        valor: TextosConfiguracoes.guardadoIdadeValor,
                      ),
                      CampoInformacao(
                        rotulo: TextosConfiguracoes.guardadoApresentacao,
                        valor: TextosConfiguracoes.guardadoApresentacaoValor,
                      ),
                      CampoInformacao(
                        rotulo: TextosConfiguracoes.guardadoContato,
                        valor: TextosConfiguracoes.guardadoContatoValor,
                      ),
                    ],
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                  const TextoMemora.apoio(
                    TextosConfiguracoes.guardadoNuncaFica,
                  ),
                  const SizedBox(height: MemoraEspacamento.xxl),
                  CaixaDeEtapa(
                    instrucao: TextosConfiguracoes.tituloApagarConversa,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const TextoMemora.apoio(
                          TextosConfiguracoes.explicacaoApagarConversa,
                        ),
                        const SizedBox(height: MemoraEspacamento.lg),
                        _parteQueApaga(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parteQueApaga() {
    return switch (_fase) {
      _Fase.inicial => BotaoSecundario(
        key: TelaPrivacidade.chaveApagar,
        rotulo: TextosConfiguracoes.botaoApagarConversa,
        icone: Icons.delete_outline_rounded,
        aoTocar: () => setState(() => _fase = _Fase.perguntando),
      ),
      _Fase.perguntando => ConfirmacaoMemora.irreversivel(
        key: TelaPrivacidade.chaveConfirmacao,
        pergunta: TextosConfiguracoes.perguntaApagarConversa,
        aviso: TextosConfiguracoes.avisoApagarConversa,
        rotuloConfirmar: TextosConfiguracoes.botaoApagarConversa,
        rotuloRecusar: TextosConfiguracoes.botaoManterConversa,
        aoConfirmar: _apagar,
        aoRecusar: () => setState(() => _fase = _Fase.inicial),
      ),
      _Fase.apagando => const Carregando(
        mensagem: TextosConfiguracoes.apagandoConversa,
      ),
      _Fase.apagada => const TextoMemora(
        TextosConfiguracoes.conversaApagada,
        key: TelaPrivacidade.chaveApagada,
        estilo: EstiloTexto.corpoForte,
      ),
      _Fase.falhou => MensagemErro(
        key: TelaPrivacidade.chaveFalha,
        mensagem: TextosConfiguracoes.conversaNaoApagada,
        aoTentarNovamente: () => setState(() => _fase = _Fase.inicial),
      ),
    };
  }
}
