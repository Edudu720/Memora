import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_perfil.dart';
import '../../aprendizado/data/guias/guias.dart';
import '../../aprendizado/data/progresso_de_aprendizado.dart';
import '../../assistente/data/repositorio_assistente_simulado.dart';
import '../../assistente/domain/assistente.dart';
import '../data/data_de_nascimento_local.dart';
import '../data/foto_de_perfil_local.dart';
import '../data/seletor_de_imagem.dart';
import '../domain/processador_de_imagem.dart';
import 'secao_foto_perfil.dart';
import 'secao_idade.dart';
import 'widgets/retrato_do_perfil.dart';

/// Tela de perfil da pessoa usuária (T096, T097, US8, FR-042; feature 011).
///
/// Mostra o retrato pessoal dedicado à pessoa usuária ([SecaoFotoPerfil] /
/// [RetratoDoPerfil]), o que o Memora já sabe como **informação** (nunca
/// parecendo botão, FR-012 da 002): nome, canal de contato da conta e o
/// aplicativo que ela mais aprendeu a usar pelo passo a passo.
///
/// - **Sem rede ao abrir**: todas as informações vêm de dados locais do
///   aparelho ou da sessão ativa (FR-042a).
/// - **Quando vazio**: se ainda não concluiu nenhum passo a passo, a linha do
///   aplicativo mais aprendido exibe a frase acolhedora da Memora, e nunca fica
///   vazia.
/// - **Sem planos**: nenhum campo de plano, assinatura ou pagamento (US9).
/// - **Idade opcional**: embutida pela [SecaoIdade] (FR-042c).
class TelaPerfil extends StatefulWidget {
  /// Chave da tela / lista.
  static const Key chaveLista = Key('perfil.lista');

  /// Chave do campo com o nome.
  static const Key chaveNome = Key('perfil.nome');

  /// Chave do campo com o canal de contato.
  static const Key chaveCanal = Key('perfil.canal');

  /// Chave do campo com o aplicativo mais aprendido.
  static const Key chaveMaisAprendido = Key('perfil.mais_aprendido');

  /// Chave da seção de aprendizado local (Feature 016).
  static const Key chaveSecaoAprendizado = Key('perfil.secao_aprendizado');

  /// Chave do campo com o último módulo concluído (Feature 016 / reserva Item 14).
  static const Key chaveUltimoModulo = Key('perfil.ultimo_modulo');

  /// Chave do desenho da Memora.
  static const Key chaveDesenho = Key('perfil.desenho');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// O canal da conta, lido do último acesso local.
  final Future<String?> canal;

  /// Onde o progresso de aprendizado é guardado (local).
  final ProgressoDeAprendizado? progresso;

  /// Onde a data de nascimento fica guardada, por conta (FR-042c).
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// Onde a foto de perfil ou avatar fica guardado, por conta (FR-006, 011).
  final ArmazenamentoDeFotoDePerfil? fotoDePerfil;

  /// Seletor de foto de galeria/câmera (injetável em testes).
  final SeletorDeImagemDoAparelho? seletorDeFoto;

  /// Processador/sanitizador de imagem (injetável em testes sem isolate real).
  final ProcessadorDeImagemDePerfil? processadorDeFoto;

  /// Id da conta autenticada.
  final String? idDaConta;

  /// Nome opcional do último módulo concluído no passo a passo (reserva Item 14).
  final String? ultimoModuloConcluido;

  /// Cria a tela de perfil.
  const TelaPerfil({
    required this.nome,
    required this.canal,
    this.progresso,
    this.dataDeNascimento,
    this.fotoDePerfil,
    this.seletorDeFoto,
    this.processadorDeFoto,
    this.idDaConta,
    this.ultimoModuloConcluido,
    super.key,
  });

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  static final Map<String, String> _nomesDoCatalogo = <String, String>{
    for (final ServicoDoCatalogo servico
        in RepositorioAssistenteSimulado.catalogoDaDemonstracao)
      servico.chave: servico.nomeExibido,
  };

  String? _maisAprendidoNome;
  bool _carregouMaisAprendido = false;
  int _versaoCarga = 0;
  late ArmazenamentoDeFotoDePerfil _fotosEfetivo =
      widget.fotoDePerfil ?? FotoDePerfilEmMemoria();

  @override
  void initState() {
    super.initState();
    _carregarMaisAprendido();
  }

  @override
  void didUpdateWidget(TelaPerfil antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.fotoDePerfil != widget.fotoDePerfil) {
      _fotosEfetivo = widget.fotoDePerfil ?? FotoDePerfilEmMemoria();
    }
    if (antiga.idDaConta != widget.idDaConta ||
        antiga.progresso != widget.progresso) {
      _maisAprendidoNome = null;
      _carregouMaisAprendido = false;
      _carregarMaisAprendido();
    }
  }

  static String _resolverNomeExibido(String chave) {
    return _nomesDoCatalogo[chave] ?? guiaDe(chave)?.titulo ?? chave;
  }

  Future<void> _carregarMaisAprendido() async {
    final int versao = ++_versaoCarga;
    final ProgressoDeAprendizado? prog = widget.progresso;
    final String? id = widget.idDaConta;
    if (prog == null || id == null || id.trim().isEmpty) {
      _maisAprendidoNome = null;
      _carregouMaisAprendido = true;
      return;
    }

    final String contaAlvo = id;
    String? bruta;
    try {
      bruta = await prog.aplicativoMaisAprendido(contaAlvo);
    } catch (_) {
      bruta = null;
    }
    if (!mounted || versao != _versaoCarga || widget.idDaConta != contaAlvo) {
      return;
    }

    // O progresso de um guia em seções é por `<guia>:<seção>` (FR-028d): o
    // nome que se mostra é o do guia.
    final String? chave = bruta?.split(':').first;
    final String? nomeExibido =
        (chave != null && chave.isNotEmpty) ? _resolverNomeExibido(chave) : null;

    setState(() {
      _maisAprendidoNome = nomeExibido;
      _carregouMaisAprendido = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    final String textoMaisAprendido = _carregouMaisAprendido
        ? (_maisAprendidoNome ?? TextosPerfil.maisAprendidoVazio)
        : TextosPerfil.carregandoAprendizado;
    final String? moduloBruto = widget.ultimoModuloConcluido?.trim();
    final String? ultimoModuloLimpo =
        (moduloBruto != null && moduloBruto.isNotEmpty) ? moduloBruto : null;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          key: TelaPerfil.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título da tela com o botão SOS à direita (feature 014).
              const TituloComSos(titulo: TextosPerfil.tituloPerfil),
              const SizedBox(height: MemoraEspacamento.lg),

              // Bloco 1: Seu retrato (FR-001, 011, Feature 016)
              Semantics(
                header: true,
                child: const TextoMemora.tituloSecao(TextosPerfil.secaoRetrato),
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              Cartao(
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                child: widget.idDaConta != null &&
                        widget.idDaConta!.trim().isNotEmpty
                    ? SecaoFotoPerfil(
                        chaveDoRetrato: TelaPerfil.chaveDesenho,
                        nome: widget.nome,
                        armazenamento: _fotosEfetivo,
                        idDaConta: widget.idDaConta!,
                        seletor: widget.seletorDeFoto,
                        processador: widget.processadorDeFoto ??
                            const ProcessadorDeImagemDePerfil(),
                      )
                    : Center(
                        child: RetratoDoPerfil(
                          chaveDoRetrato: TelaPerfil.chaveDesenho,
                          nome: widget.nome,
                        ),
                      ),
              ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Bloco 2: Sua conta (informação, nunca botão — FR-012 da 002)
              Semantics(
                header: true,
                child: const TextoMemora.tituloSecao(TextosPerfil.secaoConta),
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              FutureBuilder<String?>(
                future: widget.canal,
                builder: (BuildContext _, AsyncSnapshot<String?> snapshotCanal) {
                  return ListaInformacao(
                    campos: <CampoInformacao>[
                      CampoInformacao(
                        key: TelaPerfil.chaveNome,
                        rotulo: TextosPerfil.rotuloNome,
                        valor: widget.nome,
                      ),
                      if (snapshotCanal.data != null)
                        CampoInformacao(
                          key: TelaPerfil.chaveCanal,
                          rotulo: TextosPerfil.rotuloCanal,
                          valor: snapshotCanal.data!,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Bloco 3: Seu aprendizado local + slot compatível do Item 14
              Column(
                key: TelaPerfil.chaveSecaoAprendizado,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: const TextoMemora.tituloSecao(
                      TextosPerfil.secaoAprendizado,
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.sm),
                  ListaInformacao(
                    campos: <CampoInformacao>[
                      CampoInformacao(
                        key: TelaPerfil.chaveMaisAprendido,
                        rotulo: TextosPerfil.rotuloMaisAprendido,
                        valor: textoMaisAprendido,
                      ),
                      if (ultimoModuloLimpo != null)
                        CampoInformacao(
                          key: TelaPerfil.chaveUltimoModulo,
                          rotulo: TextosPerfil.rotuloUltimoModulo,
                          valor: ultimoModuloLimpo,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Bloco 4: Seção de Idade (opcional, só neste aparelho, FR-042c)
              if (widget.dataDeNascimento != null &&
                  widget.idDaConta != null &&
                  widget.idDaConta!.trim().isNotEmpty)
                SecaoIdade(
                  armazenamento: widget.dataDeNascimento!,
                  idDaConta: widget.idDaConta!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
