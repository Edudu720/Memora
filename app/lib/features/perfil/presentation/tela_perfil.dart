import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_perfil.dart';
import '../../aprendizado/data/guias/guias.dart';
import '../../aprendizado/data/progresso_de_aprendizado.dart';
import '../../aprendizado/domain/guia.dart';
import '../../assistente/data/repositorio_assistente_simulado.dart';
import '../../assistente/domain/assistente.dart';
import '../data/data_de_nascimento_local.dart';
import 'secao_idade.dart';

/// Tela de perfil da pessoa usuária (T096, T097, US8, FR-042).
///
/// Mostra o que o Memora já sabe como **informação** (nunca parecendo botão,
/// FR-012 da 002): nome, desenho que a representa, canal de contato da conta
/// e o aplicativo que ela mais aprendeu a usar pelo passo a passo.
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

  /// Id da conta autenticada.
  final String? idDaConta;

  /// Cria a tela de perfil.
  const TelaPerfil({
    required this.nome,
    required this.canal,
    this.progresso,
    this.dataDeNascimento,
    this.idDaConta,
    super.key,
  });

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  String? _maisAprendidoNome;
  bool _carregouMaisAprendido = false;

  @override
  void initState() {
    super.initState();
    _carregarMaisAprendido();
  }

  @override
  void didUpdateWidget(TelaPerfil antiga) {
    super.didUpdateWidget(antiga);
    if (antiga.idDaConta != widget.idDaConta ||
        antiga.progresso != widget.progresso) {
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

    final String? chave = await prog.aplicativoMaisAprendido(id);
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
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final double larguraUtil =
        MediaQuery.sizeOf(context).width - 2 * MemoraEspacamento.lg;
    final bool compacto =
        escala >= MemoraDimensoes.escalaColapsoGrade ||
        larguraUtil < MemoraDimensoes.larguraMinimaGrade;

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
              // Cabeçalho editorial com a Memora neutra (FR-042)
              Cartao(
                padding: const EdgeInsets.all(MemoraEspacamento.lg),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: TextoMemora.tituloTela(TextosPerfil.tituloPerfil),
                    ),
                    const SizedBox(width: MemoraEspacamento.md),
                    MemoraPersonagem(
                      key: TelaPerfil.chaveDesenho,
                      expressao: ExpressaoDaMemora.neutra,
                      tamanho: compacto
                          ? MemoraDimensoes.ilustracaoCabecalho
                          : MemoraDimensoes.ilustracaoHeroi,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xl),

              // Informações da pessoa e da conta (sem parecer botão, FR-012 da 002)
              FutureBuilder<String?>(
                future: widget.canal,
                builder:
                    (BuildContext _, AsyncSnapshot<String?> snapshotCanal) {
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
