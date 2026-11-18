import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';
import '../../domain/autenticacao.dart';
import '../controladores/controlador_login.dart';

/// Tela de entrada na conta (T052, US2).
///
/// ## Dois campos, e só
///
/// A FR-011 é literal: identificador e senha, nada mais. Não há escolha entre
/// e-mail e telefone — quem decide pela presença do `@` é o servidor. Devolver
/// essa pergunta à pessoa (*"com qual dos dois você se cadastrou?"*) é o tipo de
/// bifurcação que a FR-051 existe para evitar.
///
/// ## O estado bloqueado é uma tela, não um aviso
///
/// Quando o bloqueio começa, o formulário continua visível mas o botão sai do
/// ar e a mensagem toma o lugar dele, com a contagem regressiva embaixo. A
/// pessoa precisa ver **quanto falta** sem ter que tocar em nada — tocar num
/// botão desabilitado sem retorno é onde o idoso conclui que o aparelho quebrou.
///
/// Todos os componentes vêm do Design System: nenhum widget de interface é
/// construído aqui.
class TelaLogin extends StatefulWidget {
  /// Chave do campo de identificador, usada pelos testes.
  static const Key chaveIdentificador = Key('login.identificador');

  /// Chave do campo de senha.
  static const Key chaveSenha = Key('login.senha');

  /// Chave do botão que entra.
  static const Key chaveEntrar = Key('login.entrar');

  /// Chave da contagem regressiva do bloqueio.
  static const Key chaveContagem = Key('login.contagem');

  /// Controlador da tela.
  final ControladorLogin controlador;

  /// Chamada quando a pessoa entra — seja pelo formulário, seja pela renovação
  /// automática da sessão.
  final void Function(PessoaAutenticada pessoa) aoEntrar;

  /// Acionada ao voltar.
  final VoidCallback? aoVoltar;

  /// Caminho de recuperação de senha.
  ///
  /// Opcional de propósito: a recuperação chega na US3 (T066-T073). Enquanto
  /// não existir, o botão **não aparece** — oferecer uma saída que não leva a
  /// lugar nenhum é pior do que não oferecer. O texto do bloqueio já menciona o
  /// caminho, que é o que a FR-015 exige.
  final VoidCallback? aoRecuperar;

  /// Caminho para criar conta pela primeira vez (FR-010, FR-011).
  final VoidCallback? aoPrimeiroAcesso;

  /// Cria a tela de login.
  const TelaLogin({
    required this.controlador,
    required this.aoEntrar,
    this.aoVoltar,
    this.aoRecuperar,
    this.aoPrimeiroAcesso,
    super.key,
  });

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _campoIdentificador = TextEditingController();
  final TextEditingController _campoSenha = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_aoMudarEstado);
    // A renovação automática roda antes de qualquer campo aparecer (FR-016).
    widget.controlador.iniciar();
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_aoMudarEstado);
    _campoIdentificador.dispose();
    _campoSenha.dispose();
    super.dispose();
  }

  void _aoMudarEstado() {
    final ControladorLogin c = widget.controlador;

    // O controlador é dono do valor; os campos apenas o refletem. Isso importa
    // em dois momentos que não vêm da digitação: o pré-preenchimento do último
    // acesso (FR-012) e a limpeza da senha após uma recusa.
    _sincronizar(_campoIdentificador, c.identificador);
    _sincronizar(_campoSenha, c.senha);

    if (c.estado == EstadoLogin.concluido && c.pessoa != null) {
      widget.aoEntrar(c.pessoa!);
    }
  }

  void _sincronizar(TextEditingController campo, String valor) {
    if (campo.text == valor) return;
    campo.value = TextEditingValue(
      text: valor,
      selection: TextSelection.collapsed(offset: valor.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorLogin c = widget.controlador;

        // Enquanto tenta renovar a sessão não há formulário nenhum: mostrar
        // campos que podem sumir no instante seguinte faz a tela piscar.
        //
        // Vale também depois de entrar: quem já está dentro não pode reencontrar
        // o formulário de login no quadro em que a navegação acontece.
        if (c.iniciando || c.estado == EstadoLogin.concluido) {
          return Scaffold(
            backgroundColor: cores.fundo,
            body: const SafeArea(child: Center(child: Carregando())),
          );
        }

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: widget.aoVoltar != null
              ? BarraSuperior(
                  titulo: TextosAutenticacao.tituloLogin,
                  aoVoltar: widget.aoVoltar,
                )
              : null,
          body: SafeArea(
            top: widget.aoVoltar == null,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints caixa) {
                final bool cabeMascote = caixa.maxHeight >= 640;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraEspacamento.lg,
                    vertical: MemoraEspacamento.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Top Hero Mascot Banner alinhado ao DS 2.0
                      if (cabeMascote)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: MemoraEspacamento.md,
                          ),
                          child: Cartao(
                            padding: const EdgeInsets.all(MemoraEspacamento.md),
                            child: Column(
                              children: <Widget>[
                                Center(
                                  // Uma Memora por tela (FR-006): enquanto a
                                  // espera tem a sua, esta cede o lugar (o
                                  // espaço fica, para a tela não pular).
                                  child: c.enviando
                                      ? const SizedBox.square(
                                          dimension: MemoraDimensoes
                                              .ilustracaoCabecalho,
                                        )
                                      : const MemoraPersonagem(),
                                ),
                                const SizedBox(height: MemoraEspacamento.sm),
                                const TextoMemora(
                                  'Memora',
                                  estilo: EstiloTexto.destaque,
                                  alinhamento: TextAlign.center,
                                ),
                                const SizedBox(height: MemoraEspacamento.xs),
                                const TextoMemora.apoio(
                                  'Seu assistente digital para usar o celular com facilidade',
                                  alinhamento: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                  CaixaDeEtapa(
                    instrucao: TextosAutenticacao.tituloLogin,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        CampoTexto(
                          key: TelaLogin.chaveIdentificador,
                          rotulo: TextosAutenticacao.rotuloIdentificador,
                          textoAjuda: TextosAutenticacao.ajudaIdentificador,
                          controlador: _campoIdentificador,
                          tipoTeclado: TextInputType.emailAddress,
                          aoMudar: c.informarIdentificador,
                          habilitado: !c.enviando,
                        ),
                        if (c.veioDoUltimoAcesso) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.xs),
                          const TextoMemora.apoio(
                            TextosAutenticacao.identificadorLembrado,
                          ),
                        ],
                        const SizedBox(height: MemoraEspacamento.md),
                        CampoSenha(
                          key: TelaLogin.chaveSenha,
                          rotulo: TextosAutenticacao.rotuloSenha,
                          textoAjuda: TextosAutenticacao.ajudaSenha,
                          controlador: _campoSenha,
                          aoMudar: c.informarSenha,
                        ),
                        if (c.mensagemDeErro != null) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.md),
                          MensagemErro(
                            mensagem: c.mensagemDeErro!,
                            // Durante o bloqueio não há o que tentar: o botão de
                            // repetir só reapresentaria a mesma recusa e faria a
                            // espera parecer defeito.
                            aoTentarNovamente: c.bloqueado
                                ? null
                                : c.tentarNovamente,
                          ),
                        ],
                        if (c.bloqueado) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.sm),
                          // Texto comum, não título: anunciar a contagem como
                          // cabeçalho a colocaria no índice de navegação do TalkBack,
                          // onde ela não é ponto de referência de nada.
                          TextoMemora(
                            TextosAutenticacao.contagem(c.segundosRestantes),
                            key: TelaLogin.chaveContagem,
                            alinhamento: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: MemoraEspacamento.lg),
                        if (c.enviando)
                          const Carregando(mensagem: TextosAutenticacao.entrando)
                        else if (!c.bloqueado)
                          BotaoPrimario(
                            key: TelaLogin.chaveEntrar,
                            rotulo: TextosAutenticacao.botaoEntrar,
                            icone: Icons.arrow_forward_rounded,
                            aoTocar: c.podeEnviar ? c.entrar : null,
                          ),
                      ],
                    ),
                  ),
                  if (widget.aoRecuperar != null ||
                      widget.aoPrimeiroAcesso != null) ...<Widget>[
                    const SizedBox(height: MemoraEspacamento.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (widget.aoRecuperar != null)
                          Flexible(
                            child: BotaoTerciario(
                              rotulo: TextosAutenticacao.botaoRecuperar,
                              aoTocar: widget.aoRecuperar,
                            ),
                          ),
                        if (widget.aoPrimeiroAcesso != null)
                          Flexible(
                            child: BotaoTerciario(
                              rotulo: TextosAutenticacao.botaoPrimeiroAcesso,
                              aoTocar: widget.aoPrimeiroAcesso,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
      },
    );
  }
}
