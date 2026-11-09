import 'package:flutter/material.dart';

import '../../../design_system/componentes/botoes/botao_secundario.dart';
import '../../../design_system/componentes/cartoes/caixa_de_etapa.dart';
import '../../../design_system/componentes/confirmacao/confirmacao_memora.dart';
import '../../../design_system/componentes/feedback/carregando.dart';
import '../../../design_system/componentes/feedback/estado_vazio.dart';
import '../../../design_system/componentes/feedback/mensagem_erro.dart';
import '../../../design_system/componentes/ilustracao/ilustracao_memora.dart';
import '../../../design_system/componentes/informacao/campo_informacao.dart';
import '../../../design_system/componentes/informacao/lista_informacao.dart';
import '../../../design_system/componentes/navegacao/cabecalho_de_tela.dart';
import '../../../design_system/componentes/texto/texto_memora.dart';
import '../../../design_system/temas/memora_theme_extension.dart';
import '../../../design_system/tokens/espacamento.dart';
import '../../../l10n/textos_apresentacao.dart';
import '../../../l10n/textos_autenticacao.dart';
import '../../../l10n/textos_casca.dart';
import '../../../l10n/textos_configuracoes.dart';
import '../../autenticacao/presentation/widgets/saida_com_confirmacao.dart';

/// A conta: o contato, a saída e o que ninguém do Memora faz (US7, FR-041).
///
/// ## De cima para baixo, do mais seguro ao mais destrutivo
///
/// 1. **O contato da conta**, como informação. É o que a pessoa confere
///    quando alguém "do suporte" liga pedindo para ela ler o e-mail da tela —
///    e por isso o quadro seguinte existe.
/// 2. **O que ninguém do Memora faz** (FR-036a): as mesmas frases da
///    apresentação, de `TextosApresentacao`, para a regra não existir em dois
///    textos que divergem.
/// 3. **Sair**, que pergunta antes (FR-025 da 001).
/// 4. **Sair e esquecer este aparelho**, **separado e abaixo**, com a frase de
///    para que serve. É a mais destrutiva das duas, e não fica ao lado da
///    outra (Princípio II): num toque apressado, o "Sair" comum está longe o
///    bastante para não ser confundido com ela, e vice-versa.
///
/// ## Sair não falha
///
/// Sem estado de erro para a saída, e de propósito: o repositório engole a
/// falha de rede, e a limpeza local — o que de fato tira o acesso — acontece
/// de qualquer jeito. Os estados da FR-006 que a tela tem são os do contato:
/// carregando, ausente e erro.
class TelaConta extends StatefulWidget {
  /// O contato da conta, como o aparelho o lembra.
  final Future<String?> canal;

  /// Sai da conta. Quem chama cuida de apagar a conversa e as credenciais.
  final Future<void> Function() aoSair;

  /// Sai da conta e esquece o aparelho (`esquecerTudo`).
  final Future<void> Function() aoSairEEsquecer;

  /// Volta a Ajustes.
  final VoidCallback aoVoltar;

  /// Cria a tela de Conta.
  const TelaConta({
    required this.canal,
    required this.aoSair,
    required this.aoSairEEsquecer,
    required this.aoVoltar,
    super.key,
  });

  /// Chave do botão de sair.
  static const Key chaveSair = Key('conta.sair');

  /// Chave da confirmação de sair.
  static const Key chaveConfirmacao = Key('conta.confirmacao');

  /// Chave do botão que abre a pergunta de esquecer o aparelho.
  static const Key chaveEsquecer = Key('conta.esquecer');

  /// Chave da confirmação de esquecer o aparelho.
  static const Key chaveConfirmacaoEsquecer = Key('conta.confirmacao_esquecer');

  /// Chave do contato mostrado.
  static const Key chaveContato = Key('conta.contato');

  /// Chave do quadro do que ninguém do Memora faz.
  static const Key chaveNuncaFaco = Key('conta.nunca_faco');

  @override
  State<TelaConta> createState() => _TelaContaState();
}

class _TelaContaState extends State<TelaConta> {
  bool _confirmandoEsquecer = false;
  bool _esquecendo = false;

  /// Uma saída por vez: enquanto uma roda, a outra não começa.
  bool _saindo = false;

  Future<void> _sair() async {
    if (_saindo) return;
    _saindo = true;
    await widget.aoSair();
  }

  Future<void> _esquecer() async {
    if (_saindo) return;
    _saindo = true;
    setState(() => _esquecendo = true);
    await widget.aoSairEEsquecer();
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
              titulo: TextosConfiguracoes.tituloConta,
              aoVoltar: widget.aoVoltar,
              ilustracao: Ilustracao.casalIdoso,
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
                  _contato(),
                  const SizedBox(height: MemoraEspacamento.xl),
                  _nuncaFaco(),
                  const SizedBox(height: MemoraEspacamento.xl),
                  CaixaDeEtapa(
                    instrucao: TextosConfiguracoes.tituloSair,
                    child: SaidaComConfirmacao(
                      chaveConfirmacao: TelaConta.chaveConfirmacao,
                      aoConfirmar: _sair,
                      botao: (VoidCallback aoTocar) => BotaoSecundario(
                        key: TelaConta.chaveSair,
                        rotulo: TextosAutenticacao.botaoSair,
                        icone: Icons.logout,
                        aoTocar: aoTocar,
                      ),
                    ),
                  ),
                  // Longe do "Sair": a mais destrutiva das duas não fica
                  // adjacente à comum (FR-041, Princípio II).
                  const SizedBox(height: MemoraEspacamento.xxxl),
                  CaixaDeEtapa(
                    instrucao: TextosConfiguracoes.tituloEsquecer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const TextoMemora.apoio(
                          TextosConfiguracoes.paraQueServeEsquecer,
                        ),
                        const SizedBox(height: MemoraEspacamento.lg),
                        _esquecerOAparelho(),
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

  Widget _contato() {
    return FutureBuilder<String?>(
      future: widget.canal,
      builder: (BuildContext context, AsyncSnapshot<String?> canal) {
        if (canal.hasError) {
          return const MensagemErro(
            mensagem: TextosConfiguracoes.erroDoContato,
          );
        }
        if (canal.connectionState != ConnectionState.done) {
          return const Carregando(
            mensagem: TextosConfiguracoes.carregandoContato,
          );
        }
        final String? valor = canal.data;
        if (valor == null || valor.trim().isEmpty) {
          return const EstadoVazio(
            titulo: TextosConfiguracoes.semContatoTitulo,
            explicacao: TextosConfiguracoes.semContatoExplicacao,
          );
        }
        return ListaInformacao(
          campos: <CampoInformacao>[
            CampoInformacao(
              key: TelaConta.chaveContato,
              rotulo: TextosCasca.rotuloCanal,
              valor: valor,
            ),
          ],
        );
      },
    );
  }

  /// O que **ninguém do Memora** faz (FR-036a). As frases são as da
  /// apresentação, lidas de `TextosApresentacao`: um texto só.
  Widget _nuncaFaco() {
    return Column(
      key: TelaConta.chaveNuncaFaco,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const TextoMemora.tituloSecao(TextosApresentacao.tituloNunca),
        const SizedBox(height: MemoraEspacamento.sm),
        for (final String frase in TextosApresentacao.nuncaFaco) ...<Widget>[
          TextoMemora(frase),
          const SizedBox(height: MemoraEspacamento.sm),
        ],
        const TextoMemora.apoio(TextosApresentacao.seAlguemPedir),
      ],
    );
  }

  Widget _esquecerOAparelho() {
    if (_esquecendo) {
      return const Carregando(mensagem: TextosAutenticacao.saindo);
    }
    if (_confirmandoEsquecer) {
      return ConfirmacaoMemora.irreversivel(
        key: TelaConta.chaveConfirmacaoEsquecer,
        pergunta: TextosConfiguracoes.perguntaEsquecer,
        aviso: TextosConfiguracoes.avisoEsquecer,
        rotuloConfirmar: TextosConfiguracoes.botaoEsquecer,
        rotuloRecusar: TextosConfiguracoes.botaoNaoEsquecer,
        aoConfirmar: _esquecer,
        aoRecusar: () => setState(() => _confirmandoEsquecer = false),
      );
    }
    return BotaoSecundario(
      key: TelaConta.chaveEsquecer,
      rotulo: TextosConfiguracoes.botaoEsquecer,
      icone: Icons.phonelink_erase,
      aoTocar: () => setState(() => _confirmandoEsquecer = true),
    );
  }
}
