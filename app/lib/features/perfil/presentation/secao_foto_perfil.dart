import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_perfil.dart';
import '../data/foto_de_perfil_local.dart';
import '../data/seletor_de_imagem.dart';
import '../domain/processador_de_imagem.dart';
import '../domain/retrato_de_perfil.dart';
import 'tela_pre_visualizacao_foto.dart';
import 'widgets/retrato_do_perfil.dart';

/// Bloco do Perfil que exibe e gerencia o retrato da pessoa usuária (`011`).
///
/// Reúne o retrato circular (foto própria, avatar ilustrado ou retrato padrão
/// neutro) e os controles rotulados para colocar, trocar, remover ou lidar com
/// permissões recusadas e imagens inválidas sem assustar.
class SecaoFotoPerfil extends StatefulWidget {
  /// Chave do botão principal ("Colocar foto de perfil" ou "Trocar foto").
  static const Key chaveBotaoColocarOuTrocar =
      Key('perfil.foto.botao_colocar_ou_trocar');

  /// Chave do botão que solicita remoção da foto ou avatar atual.
  static const Key chaveBotaoRemover = Key('perfil.foto.botao_remover');

  /// Chave da confirmação em dois botões antes de remover a foto.
  static const Key chaveConfirmacaoRemover =
      Key('perfil.foto.confirmacao_remover');

  /// Chave do quadro de aviso amigável de permissão negada ou arquivo inválido.
  static const Key chaveAvisoErroOuPermissao = Key('perfil.foto.aviso');

  /// Chave do aviso breve de confirmação ("Pronto! Sua foto...").
  static const Key chaveFeedbackSucesso = Key('perfil.foto.sucesso');

  /// Chave da opção "Escolher da galeria" na folha inferior.
  static const Key chaveOpcaoGaleria = Key('perfil.foto.origem.galeria');

  /// Chave da opção "Tirar foto agora" na folha inferior.
  static const Key chaveOpcaoCamera = Key('perfil.foto.origem.camera');

  /// Chave da opção "Escolher avatar da Memora" na folha inferior.
  static const Key chaveOpcaoAvatares = Key('perfil.foto.origem.avatares');

  /// Chave do botão para abrir ajustes de permissão do aparelho.
  static const Key chaveBotaoAbrirAjustes = Key('perfil.foto.abrir_ajustes');

  /// Chave do atalho para escolher avatar quando foto/permissão falha.
  static const Key chaveBotaoUsarAvatarFallback =
      Key('perfil.foto.usar_avatar_fallback');

  /// Nome da pessoa autenticada (para iniciais do retrato padrão neutro).
  final String nome;

  /// Armazenamento local por conta.
  final ArmazenamentoDeFotoDePerfil armazenamento;

  /// Identificador da conta ativa (isolamento por conta).
  final String idDaConta;

  /// Abstração da câmera/galeria e ajustes do sistema.
  final SeletorDeImagemDoAparelho seletor;

  /// Validador e sanitizador de imagem em isolate.
  final ProcessadorDeImagemDePerfil processador;

  /// Chave aplicada ao círculo do retrato (ex.: `TelaPerfil.chaveDesenho`).
  final Key? chaveDoRetrato;

  /// Cria a seção de foto de perfil.
  SecaoFotoPerfil({
    required this.nome,
    required this.armazenamento,
    required this.idDaConta,
    SeletorDeImagemDoAparelho? seletor,
    this.processador = const ProcessadorDeImagemDePerfil(),
    this.chaveDoRetrato,
    super.key,
  }) : seletor = seletor ?? SeletorDeImagemDoAparelhoReal();

  @override
  State<SecaoFotoPerfil> createState() => _SecaoFotoPerfilState();
}

class _SecaoFotoPerfilState extends State<SecaoFotoPerfil> {
  RetratoDePerfil? _retrato;
  bool _ocupado = false;
  bool _confirmandoRemocao = false;
  String? _mensagemErro;
  OrigemDaFoto? _permissaoNegadaDe;
  String? _mensagemSucesso;

  bool get _semConta => widget.idDaConta.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(SecaoFotoPerfil antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.idDaConta != widget.idDaConta ||
        antiga.armazenamento != widget.armazenamento) {
      _retrato = null;
      _confirmandoRemocao = false;
      _mensagemErro = null;
      _permissaoNegadaDe = null;
      _mensagemSucesso = null;
      _ocupado = false;
      _carregar();
    }
  }

  Future<void> _carregar() async {
    final String conta = widget.idDaConta;
    if (conta.trim().isEmpty) return;
    final RetratoDePerfil? lido = await widget.armazenamento.ler(conta);
    if (!mounted || conta != widget.idDaConta) return;
    setState(() => _retrato = lido);
  }

  void _limparAvisos() {
    _mensagemErro = null;
    _permissaoNegadaDe = null;
    _mensagemSucesso = null;
  }

  Future<void> _abrirEscolhaDeOrigem() async {
    if (_ocupado || _semConta) return;
    setState(() {
      _confirmandoRemocao = false;
      _limparAvisos();
    });

    await FolhaInferior.mostrar(
      context,
      folha: FolhaInferior(
        titulo: TextosPerfil.tituloEscolherOrigemFoto,
        child: _CorpoFolhaOrigem(
          aoEscolherGaleria: () {
            Navigator.of(context).pop();
            _processarOrigemDeMidia(OrigemDaFoto.galeria);
          },
          aoEscolherCamera: () {
            Navigator.of(context).pop();
            _processarOrigemDeMidia(OrigemDaFoto.camera);
          },
          aoEscolherAvatares: () {
            Navigator.of(context).pop();
            _abrirGradeDeAvatares();
          },
        ),
      ),
    );
  }

  Future<void> _processarOrigemDeMidia(OrigemDaFoto origem) async {
    if (_ocupado || _semConta) return;
    final String contaDaOperacao = widget.idDaConta;
    bool reabrirEscolha = false;

    setState(() {
      _ocupado = true;
      _limparAvisos();
    });

    try {
      final ResultadoDaSelecao selecao =
          await widget.seletor.selecionar(origem);
      if (!mounted || contaDaOperacao != widget.idDaConta) return;

      switch (selecao) {
        case SelecaoCancelada():
          return;
        case SelecaoSemPermissao(origem: final OrigemDaFoto qual):
          setState(() {
            _permissaoNegadaDe = qual;
            _mensagemErro = qual == OrigemDaFoto.camera
                ? TextosPerfil.erroPermissaoCamera
                : TextosPerfil.erroPermissaoGaleria;
          });
          return;
        case SelecaoExcedeuLimite():
          setState(() => _mensagemErro = TextosPerfil.erroImagemMuitoGrande);
          return;
        case SelecaoComFalha():
          setState(() => _mensagemErro = TextosPerfil.erroFotoGeral);
          return;
        case SelecaoConfirmada(bytesBrutos: final Uint8List bytesBrutos):
          final ResultadoDoProcessamento resultado =
              await widget.processador.processar(bytesBrutos);
          if (!mounted || contaDaOperacao != widget.idDaConta) return;

          switch (resultado) {
            case ImagemRejeitada(motivo: final MotivoRejeicaoImagem motivo):
              setState(() => _mensagemErro = _textoParaRejeicao(motivo));
              return;
            case ImagemProcessada(
                bytesJpegSemExif: final Uint8List jpegLimpo,
              ):
              final AcaoPreVisualizacaoFoto? acao =
                  await _abrirPreVisualizacao(jpegLimpo);
              if (!mounted || contaDaOperacao != widget.idDaConta) return;

              if (acao == AcaoPreVisualizacaoFoto.escolherOutra) {
                reabrirEscolha = true;
              } else if (acao == AcaoPreVisualizacaoFoto.usarEstaFoto) {
                final FotoPropriaDePerfil salvo = await widget.armazenamento
                    .salvarFoto(contaDaOperacao, jpegLimpo);
                if (!mounted || contaDaOperacao != widget.idDaConta) return;

                setState(() {
                  _retrato = salvo;
                  _mensagemSucesso = TextosPerfil.fotoAtualizadaComSucesso;
                });
              }
          }
      }
    } catch (_) {
      if (!mounted || contaDaOperacao != widget.idDaConta) return;
      setState(() => _mensagemErro = TextosPerfil.erroFotoGeral);
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }

    if (reabrirEscolha && mounted && contaDaOperacao == widget.idDaConta) {
      await _abrirEscolhaDeOrigem();
    }
  }

  Future<AcaoPreVisualizacaoFoto?> _abrirPreVisualizacao(
    Uint8List bytesJpegSemExif,
  ) {
    final bool reduzirMovimento = MediaQuery.disableAnimationsOf(context);
    if (reduzirMovimento) {
      return Navigator.of(context).push<AcaoPreVisualizacaoFoto>(
        PageRouteBuilder<AcaoPreVisualizacaoFoto>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) =>
              TelaPreVisualizacaoFoto(bytesJpegSemExif: bytesJpegSemExif),
        ),
      );
    }
    return Navigator.of(context).push<AcaoPreVisualizacaoFoto>(
      MaterialPageRoute<AcaoPreVisualizacaoFoto>(
        builder: (BuildContext _) =>
            TelaPreVisualizacaoFoto(bytesJpegSemExif: bytesJpegSemExif),
      ),
    );
  }

  Future<void> _abrirGradeDeAvatares() async {
    if (_ocupado || _semConta) return;
    final String contaDaOperacao = widget.idDaConta;

    setState(() {
      _confirmandoRemocao = false;
      _limparAvisos();
    });

    AvatarIlustrado? escolhido;
    await FolhaInferior.mostrar(
      context,
      folha: FolhaInferior(
        titulo: TextosPerfil.tituloAvataresFoto,
        child: _ListaAvataresMemora(
          avatarAtual: _retrato is AvatarIlustradoDePerfil
              ? (_retrato as AvatarIlustradoDePerfil).avatar
              : null,
          aoEscolher: (AvatarIlustrado avatar) {
            escolhido = avatar;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (escolhido == null || !mounted || contaDaOperacao != widget.idDaConta) {
      return;
    }

    setState(() => _ocupado = true);
    try {
      final AvatarIlustradoDePerfil salvo =
          await widget.armazenamento.salvarAvatar(contaDaOperacao, escolhido!);
      if (!mounted || contaDaOperacao != widget.idDaConta) return;
      setState(() {
        _retrato = salvo;
        _mensagemSucesso = TextosPerfil.fotoAtualizadaComSucesso;
      });
    } catch (_) {
      if (!mounted || contaDaOperacao != widget.idDaConta) return;
      setState(() => _mensagemErro = TextosPerfil.erroFotoGeral);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _removerFoto() async {
    if (_ocupado || _semConta) return;
    final String contaDaOperacao = widget.idDaConta;

    setState(() {
      _ocupado = true;
      _limparAvisos();
    });

    try {
      await widget.armazenamento.apagar(contaDaOperacao);
      if (!mounted || contaDaOperacao != widget.idDaConta) return;
      setState(() {
        _retrato = null;
        _confirmandoRemocao = false;
        _mensagemSucesso = TextosPerfil.fotoRemovidaComSucesso;
      });
    } catch (_) {
      if (!mounted || contaDaOperacao != widget.idDaConta) return;
      setState(() => _mensagemErro = TextosPerfil.erroFotoGeral);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _textoParaRejeicao(MotivoRejeicaoImagem motivo) => switch (motivo) {
        MotivoRejeicaoImagem.arquivoMuitoGrande =>
          TextosPerfil.erroImagemMuitoGrande,
        MotivoRejeicaoImagem.formatoNaoSuportado =>
          TextosPerfil.erroImagemFormatoInvalido,
        MotivoRejeicaoImagem.imagemCorrompida => TextosPerfil.erroFotoGeral,
      };

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool temRetrato = _retrato != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: RetratoDoPerfil(
            chaveDoRetrato: widget.chaveDoRetrato,
            nome: widget.nome,
            retrato: _retrato,
            tamanho: 108,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        if (_ocupado) ...<Widget>[
          Center(
            child: Semantics(
              liveRegion: true,
              child: const TextoMemora.apoio(TextosPerfil.preparandoFoto),
            ),
          ),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        if (_mensagemSucesso != null) ...<Widget>[
          _QuadroSucessoFoto(
            key: SecaoFotoPerfil.chaveFeedbackSucesso,
            mensagem: _mensagemSucesso!,
          ),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        if (_mensagemErro != null) ...<Widget>[
          Container(
            key: SecaoFotoPerfil.chaveAvisoErroOuPermissao,
            padding: const EdgeInsets.all(MemoraEspacamento.lg),
            decoration: BoxDecoration(
              color: cores.superficie,
              borderRadius: BorderRadius.circular(MemoraRaio.padrao),
              border: Border.all(
                color: cores.perigo,
                width: MemoraDimensoes.bordaEnfase,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      color: cores.perigo,
                      size: MemoraDimensoes.iconeDestaque,
                    ),
                    const SizedBox(width: MemoraEspacamento.md),
                    Expanded(child: TextoMemora(_mensagemErro!)),
                  ],
                ),
                const SizedBox(height: MemoraEspacamento.md),
                if (_permissaoNegadaDe != null) ...<Widget>[
                  BotaoSecundario(
                    key: SecaoFotoPerfil.chaveBotaoAbrirAjustes,
                    rotulo: TextosPerfil.botaoAbrirAjustesAparelho,
                    icone: Icons.settings_outlined,
                    aoTocar: _ocupado
                        ? null
                        : () => widget.seletor.abrirConfiguracoesDoAparelho(),
                  ),
                  const SizedBox(height: MemoraEspacamento.sm),
                ],
                BotaoSecundario(
                  key: SecaoFotoPerfil.chaveBotaoUsarAvatarFallback,
                  rotulo: TextosPerfil.opcaoAvataresFoto,
                  icone: Icons.face_retouching_natural_outlined,
                  aoTocar: _ocupado || _semConta ? null : _abrirGradeDeAvatares,
                ),
              ],
            ),
          ),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        if (_confirmandoRemocao)
          ConfirmacaoMemora(
            key: SecaoFotoPerfil.chaveConfirmacaoRemover,
            pergunta: TextosPerfil.perguntaRemoverFoto,
            aviso: TextosPerfil.avisoRemoverFoto,
            rotuloConfirmar: TextosPerfil.botaoConfirmarRemoverFoto,
            rotuloRecusar: TextosPerfil.botaoManterFoto,
            aoConfirmar: _removerFoto,
            aoRecusar: () => setState(() => _confirmandoRemocao = false),
          )
        else ...<Widget>[
          BotaoSecundario(
            key: SecaoFotoPerfil.chaveBotaoColocarOuTrocar,
            rotulo: temRetrato
                ? TextosPerfil.botaoTrocarFoto
                : TextosPerfil.botaoColocarFoto,
            icone: temRetrato
                ? Icons.photo_camera_outlined
                : Icons.add_a_photo_outlined,
            aoTocar: _ocupado || _semConta ? null : _abrirEscolhaDeOrigem,
          ),
          if (temRetrato) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.sm),
            BotaoSecundario(
              key: SecaoFotoPerfil.chaveBotaoRemover,
              rotulo: TextosPerfil.botaoRemoverFoto,
              icone: Icons.delete_outline,
              aoTocar: _ocupado || _semConta
                  ? null
                  : () => setState(() {
                        _confirmandoRemocao = true;
                        _limparAvisos();
                      }),
            ),
          ],
        ],
      ],
    );
  }
}

class _QuadroSucessoFoto extends StatelessWidget {
  final String mensagem;

  const _QuadroSucessoFoto({required this.mensagem, super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border.all(
              color: cores.sucesso,
              width: MemoraDimensoes.bordaEnfase,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline,
                color: cores.sucesso,
                size: MemoraDimensoes.iconePadrao,
              ),
              const SizedBox(width: MemoraEspacamento.md),
              Expanded(child: TextoMemora(mensagem)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorpoFolhaOrigem extends StatelessWidget {
  final VoidCallback aoEscolherGaleria;
  final VoidCallback aoEscolherCamera;
  final VoidCallback aoEscolherAvatares;

  const _CorpoFolhaOrigem({
    required this.aoEscolherGaleria,
    required this.aoEscolherCamera,
    required this.aoEscolherAvatares,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Explicação integrada de privacidade antes do toque (FR-004).
        Container(
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.destaque,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border.all(color: cores.borda),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                color: cores.texto,
                size: MemoraDimensoes.iconePadrao,
              ),
              const SizedBox(width: MemoraEspacamento.md),
              const Expanded(
                child: TextoMemora(TextosPerfil.avisoPrivacidadeFoto),
              ),
            ],
          ),
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        BotaoSecundario(
          key: SecaoFotoPerfil.chaveOpcaoGaleria,
          rotulo: TextosPerfil.opcaoGaleriaFoto,
          icone: Icons.photo_library_outlined,
          aoTocar: aoEscolherGaleria,
        ),
        const SizedBox(height: MemoraEspacamento.sm),
        BotaoSecundario(
          key: SecaoFotoPerfil.chaveOpcaoCamera,
          rotulo: TextosPerfil.opcaoCameraFoto,
          icone: Icons.photo_camera_outlined,
          aoTocar: aoEscolherCamera,
        ),
        const SizedBox(height: MemoraEspacamento.sm),
        BotaoSecundario(
          key: SecaoFotoPerfil.chaveOpcaoAvatares,
          rotulo: TextosPerfil.opcaoAvataresFoto,
          icone: Icons.face_retouching_natural_outlined,
          aoTocar: aoEscolherAvatares,
        ),
      ],
    );
  }
}

class _ListaAvataresMemora extends StatelessWidget {
  final AvatarIlustrado? avatarAtual;
  final void Function(AvatarIlustrado avatar) aoEscolher;

  const _ListaAvataresMemora({
    required this.avatarAtual,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const TextoMemora.apoio(TextosPerfil.apoioAvataresFoto),
        const SizedBox(height: MemoraEspacamento.md),
        for (final AvatarIlustrado item in AvatarIlustrado.values) ...<Widget>[
          OpcaoSelecionavel(
            key: Key('perfil.foto.avatar.${item.chave}'),
            rotulo: item.rotulo,
            selecionada: item == avatarAtual,
            aoSelecionar: () => aoEscolher(item),
            lider: _MiniaturaAvatar(avatar: item, cores: cores),
          ),
          const SizedBox(height: MemoraEspacamento.sm),
        ],
      ],
    );
  }
}

class _MiniaturaAvatar extends StatelessWidget {
  final AvatarIlustrado avatar;
  final MemoraCores cores;

  const _MiniaturaAvatar({required this.avatar, required this.cores});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MemoraDimensoes.alvoMinimo,
      height: MemoraDimensoes.alvoMinimo,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cores.medalhao,
        border: Border.all(color: cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatar.ehSvg
          ? Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.xs),
              child: SvgPicture.asset(avatar.caminhoAsset),
            )
          : Image.asset(
              avatar.caminhoAsset,
              fit: BoxFit.contain,
              cacheWidth: 120,
              cacheHeight: 120,
            ),
    );
  }
}
