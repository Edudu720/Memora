import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_perfil.dart';
import '../../aprendizado/data/guias/guias.dart';
import '../../aprendizado/data/progresso_de_aprendizado.dart';
import '../../aprendizado/domain/guia.dart';
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
    super.key,
  });

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  String? _maisAprendidoNome;
  bool _carregouMaisAprendido = false;
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
    if (antiga.idDaConta != widget.idDaConta || antiga.progresso != widget.progresso) {
      _carregarMaisAprendido();
    }
  }

  Future<void> _carregarMaisAprendido() async {
    final ProgressoDeAprendizado? prog = widget.progresso;
    final String? id = widget.idDaConta;
    if (prog == null || id == null || id.trim().isEmpty) {
      if (mounted) setState(() => _carregouMaisAprendido = true);
      return;
    }

    final String? bruta = await prog.aplicativoMaisAprendido(id);
    // O progresso de um guia em seções é por `<guia>:<seção>` (FR-028d): o
    // nome que se mostra é o do guia.
    final String? chave = bruta?.split(':').first;
    if (!mounted) return;

    String? nomeExibido;
    if (chave != null) {
      for (final ServicoDoCatalogo s
          in RepositorioAssistenteSimulado.catalogoDaDemonstracao) {
        if (s.chave == chave) {
          nomeExibido = s.nomeExibido;
          break;
        }
      }
      if (nomeExibido == null) {
        final Guia? guia = guiaDe(chave);
        if (guia != null) {
          nomeExibido = guia.titulo;
        } else {
          nomeExibido = chave;
        }
      }
    }

    setState(() {
      _maisAprendidoNome = nomeExibido;
      _carregouMaisAprendido = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    final String textoMaisAprendido = _maisAprendidoNome != null
        ? _maisAprendidoNome!
        : TextosPerfil.maisAprendidoVazio;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          key: TelaPerfil.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título e retrato pessoal dedicado da pessoa usuária (FR-001, 011)
              // A bolinha do SOS fica à direita do título (feature 014).
              const TituloComSos(titulo: TextosPerfil.tituloPerfil),
              const SizedBox(height: MemoraEspacamento.lg),
              if (widget.idDaConta != null && widget.idDaConta!.trim().isNotEmpty)
                SecaoFotoPerfil(
                  chaveDoRetrato: TelaPerfil.chaveDesenho,
                  nome: widget.nome,
                  armazenamento: _fotosEfetivo,
                  idDaConta: widget.idDaConta!,
                  seletor: widget.seletorDeFoto,
                  processador: widget.processadorDeFoto ??
                      const ProcessadorDeImagemDePerfil(),
                )
              else
                Center(
                  child: RetratoDoPerfil(
                    chaveDoRetrato: TelaPerfil.chaveDesenho,
                    nome: widget.nome,
                  ),
                ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Informações da pessoa e da conta (sem parecer botão, FR-012 da 002)
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
                      CampoInformacao(
                        key: TelaPerfil.chaveMaisAprendido,
                        rotulo: TextosPerfil.rotuloMaisAprendido,
                        valor: _carregouMaisAprendido
                            ? textoMaisAprendido
                            : '...',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Seção de Idade (opcional, só neste aparelho, FR-042c)
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
