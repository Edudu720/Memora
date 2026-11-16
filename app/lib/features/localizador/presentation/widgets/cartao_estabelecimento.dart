import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entidades/estabelecimento_servico.dart';

/// Cartão acessível de alto contraste para exibição de estabelecimento essencial (FR-007, FR-008, FR-011).
class CartaoEstabelecimento extends StatelessWidget {
  /// Dados do estabelecimento exibido neste cartão.
  final EstabelecimentoServico estabelecimento;

  /// Ação acionada ao solicitar direções no mapa externo.
  final VoidCallback aoPedirRota;

  /// Ação opcional para discar o telefone confirmado, quando existir.
  final VoidCallback? aoPedirLigacao;

  /// Cria o cartão acessível de um estabelecimento.
  const CartaoEstabelecimento({
    required this.estabelecimento,
    required this.aoPedirRota,
    this.aoPedirLigacao,
    super.key,
  });

  /// Chave do botão de rota externa identificada pelo [id].
  static Key chaveRota(String id) => Key('cartao.rota.$id');

  /// Chave do botão de ligação telefônica identificada pelo [id].
  static Key chaveLigar(String id) => Key('cartao.ligar.$id');

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return Cartao(
      comBorda: true,
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Cabeçalho do cartão com categoria e distância
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BadgeDeStatus(
                rotulo: estabelecimento.categoria.rotulo,
                tom: estabelecimento.categoria.name == 'emergencia'
                    ? TomBadgeStatus.atencao
                    : TomBadgeStatus.informativo,
              ),
              const Spacer(),
              if (estabelecimento.distanciaFormatada != null) ...<Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.near_me_outlined,
                      size: MemoraDimensoes.iconePequeno,
                      color: cores.primaria,
                    ),
                    const SizedBox(width: MemoraEspacamento.xs),
                    TextoMemora(
                      estabelecimento.distanciaFormatada!,
                      estilo: EstiloTexto.corpoForte,
                      cor: cores.primaria,
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: MemoraEspacamento.sm),

          // Nome do estabelecimento
          TextoMemora(
            estabelecimento.nome,
            estilo: EstiloTexto.corpoForte,
            cabecalho: true,
          ),
          const SizedBox(height: MemoraEspacamento.xs),

          // Subtítulo descritivo
          TextoMemora.apoio(estabelecimento.subtituloTipo),
          const SizedBox(height: MemoraEspacamento.sm),

          // Endereço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.location_on_outlined,
                size: MemoraDimensoes.iconePadrao,
                color: cores.texto,
              ),
              const SizedBox(width: MemoraEspacamento.xs),
              Expanded(
                child: TextoMemora.apoio(
                  estabelecimento.endereco.textoFormatado,
                ),
              ),
            ],
          ),

          // Horário de funcionamento se houver
          if (estabelecimento.horarioFuncionamento != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.access_time_rounded,
                  size: MemoraDimensoes.iconePadrao,
                  color: cores.texto,
                ),
                const SizedBox(width: MemoraEspacamento.xs),
                Expanded(
                  child: TextoMemora.apoio(
                    'Horário: ${estabelecimento.horarioFuncionamento!}',
                  ),
                ),
              ],
            ),
          ],

          // Transparência: aviso de dados incompletos ou não confirmados (FR-011)
          if (estabelecimento.avisoTransparencia != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.xs),
            Container(
              padding: const EdgeInsets.all(MemoraEspacamento.xs),
              decoration: BoxDecoration(
                color: ehAltoContraste ? cores.superficieSutil : cores.superficie,
                borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                border: Border.all(
                  color: cores.bordaSutil,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: MemoraDimensoes.iconePequeno,
                    color: cores.texto,
                  ),
                  const SizedBox(width: MemoraEspacamento.xs),
                  Expanded(
                    child: TextoMemora.apoio(
                      estabelecimento.avisoTransparencia!,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: MemoraEspacamento.md),

          // Ações em botões grandes (>= 48 dp) com confirmação prévia
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final bool podeTerLigacao = estabelecimento.temTelefone && aoPedirLigacao != null;
              final bool cabemLadoALado = box.maxWidth >= 300;

              final Widget botaoRota = BotaoPrimario(
                key: chaveRota(estabelecimento.id),
                rotulo: 'Como chegar',
                icone: Icons.directions_outlined,
                aoTocar: aoPedirRota,
              );

              final Widget? botaoLigar = podeTerLigacao
                  ? BotaoSecundario(
                      key: chaveLigar(estabelecimento.id),
                      rotulo: 'Ligar',
                      icone: Icons.phone_outlined,
                      aoTocar: aoPedirLigacao,
                    )
                  : null;

              if (!podeTerLigacao) {
                return botaoRota;
              }

              if (cabemLadoALado) {
                return Row(
                  children: <Widget>[
                    Expanded(child: botaoRota),
                    const SizedBox(width: MemoraEspacamento.sm),
                    Expanded(child: botaoLigar!),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  botaoRota,
                  const SizedBox(height: MemoraEspacamento.sm),
                  botaoLigar!,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
