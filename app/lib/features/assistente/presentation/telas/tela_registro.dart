import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';

/// O que a Memora fez em nome da pessoa (`T051`, `FR-023`, `FR-025`).
///
/// Agrupa o histórico em [Cartao] limpo com [LinhaDeLista] puramente
/// informativa (`aoTocar: null`, sem seta nem ação), preservando a distinção
/// rigorosa entre informação e ação (`002/FR-012`).
class TelaRegistro extends StatefulWidget {
  /// Chave da lista.
  static const Key chaveLista = Key('registro.lista');

  /// De onde vêm as ações.
  final RepositorioAssistente repositorio;

  /// Volta ao início.
  final VoidCallback? aoVoltar;

  /// Cria a tela de registro.
  const TelaRegistro({required this.repositorio, this.aoVoltar, super.key});

  @override
  State<TelaRegistro> createState() => _TelaRegistroState();
}

class _TelaRegistroState extends State<TelaRegistro> {
  List<AcaoRegistrada>? _acoes;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<AcaoRegistrada> lidas = await widget.repositorio.registro();
      if (!mounted) return;
      setState(() {
        _acoes = lidas;
        _falhou = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _falhou = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final List<AcaoRegistrada>? acoes = _acoes;

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: BarraSuperior(
        titulo: TextosAssistente.portaRegistro,
        aoVoltar: widget.aoVoltar,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: TelaRegistro.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          children: <Widget>[
            Cartao(
              padding: const EdgeInsets.all(MemoraEspacamento.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  MemoraPersonagem(
                    expressao: ExpressaoDaMemora.falando,
                    tamanho: MemoraDimensoes.alvoDecisao,
                  ),
                  SizedBox(width: MemoraEspacamento.md),
                  Expanded(
                    child: TextoMemora(TextosAssistente.explicacaoDoRegistro),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MemoraEspacamento.lg),

            if (_falhou)
              MensagemErro(
                mensagem: TextosAssistente.semConexao,
                aoTentarNovamente: _carregar,
              )
            else if (acoes == null)
              const Carregando()
            else if (acoes.isEmpty)
              // Lista vazia é notícia boa: a pessoa está fazendo tudo sozinha.
              const EstadoVazio(
                titulo: 'Você fez tudo sozinha até agora',
                explicacao: TextosAssistente.registroVazio,
                icone: Icons.emoji_events_outlined,
              )
            else
              Cartao(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MemoraRaio.cartao),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final AcaoRegistrada acao in acoes)
                        LinhaDeLista(
                          mostrarDivisorInferior: true,
                          esquerda: Container(
                            padding: const EdgeInsets.all(MemoraEspacamento.sm),
                            decoration: BoxDecoration(
                              color: cores.saudeSuave,
                              borderRadius: BorderRadius.circular(
                                MemoraRaio.padrao,
                              ),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: MemoraDimensoes.iconePadrao,
                              color: cores.sucessoTexto,
                            ),
                          ),
                          titulo: TextosAssistente.oQueFoiFeito(
                            acao.nomeExibido,
                            acao.pedidoResumido,
                          ),
                          subtitulo: TextosAssistente.quandoAconteceu(
                            acao.ocorridoEm,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
