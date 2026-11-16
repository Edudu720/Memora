import 'package:flutter/rendering.dart';

import 'camada_antena.dart';
import 'camada_braco.dart';
import 'camada_cabeca.dart';
import 'camada_corpo.dart';
import 'camada_escudo.dart';
import 'camada_livro.dart';
import 'camada_painel_do_peito.dart';
import 'camada_rosto.dart';
import 'camada_sombra_no_chao.dart';
import 'camada_visor.dart';
import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// Monta as camadas da Memora num quadro só, de trás para a frente.
///
/// Uma pintura só (e não um `CustomPaint` por camada) porque o aparelho de
/// entrada não deve pagar uma camada de composição por peça. As camadas
/// continuam separadas em arquivos, e a paralaxe vem de cada grupo andar um
/// pouco mais que o anterior (`ContextoDePintura.deslocamento`).
class PintorDaMemora extends CustomPainter {
  /// Monta o contexto do quadro para um quadrado de [lado] pixels.
  final ContextoDePintura Function(double lado) criarContexto;

  /// Cria o pintor.
  const PintorDaMemora(this.criarContexto);

  static const CamadaDaMemora _sombra = CamadaSombraNoChao();
  static const CamadaDaMemora _corpo = CamadaCorpo();
  static const CamadaDaMemora _painel = CamadaPainelDoPeito();
  static const CamadaDaMemora _antena = CamadaAntena();
  static const CamadaDaMemora _cabeca = CamadaCabeca();
  static const CamadaDaMemora _visor = CamadaVisor();
  static const CamadaDaMemora _rosto = CamadaRosto();
  static const CamadaDaMemora _bracoEsquerdo = CamadaBraco(esquerdo: true);
  static const CamadaDaMemora _bracoDireito = CamadaBraco(esquerdo: false);
  static const CamadaDaMemora _escudo = CamadaEscudo();
  static const CamadaDaMemora _livro = CamadaLivro();

  @override
  void paint(Canvas canvas, Size size) {
    final double lado = size.shortestSide;
    final ContextoDePintura ctx = criarContexto(lado);
    final double mini = 1 - ctx.pose.corpo.clamp(0.0, 1.0);

    canvas.save();

    // Chegada: a Memora cresce um pouco, a partir dos pés.
    final double chegada = 0.9 + 0.1 * ctx.entrada;
    final Offset pes = ctx.p(0.5, 0.97);
    canvas.translate(pes.dx, pes.dy);
    canvas.scale(chegada);
    canvas.translate(-pes.dx, -pes.dy);

    // Só a cabeça: o desenho inteiro cresce para ela ocupar o quadrado.
    final double escala = 1 + 0.25 * mini;
    canvas.translate(0.5 * (1 - escala) * lado, mini * 0.0825 * lado);
    canvas.scale(escala);

    _sombra.pintar(canvas, ctx);

    // O que está acima do chão sobe junto com o salto.
    canvas.translate(0, -ctx.pulo * ctx.l(0.075));

    // O tronco some (esmaecendo) na versão só da cabeça.
    final double corpo = ctx.pose.corpo.clamp(0.0, 1.0);
    if (corpo > 0.01) {
      canvas.save();
      if (corpo < 1) {
        canvas.saveLayer(
          Offset.zero & Size.square(lado * 2),
          Paint()..color = ctx.cores.contorno.withValues(alpha: corpo),
        );
      }
      canvas.translate(ctx.deslocamento(0.3), 0);
      _corpo.pintar(canvas, ctx);
      _painel.pintar(canvas, ctx);
      if (corpo < 1) canvas.restore();
      canvas.restore();
    }

    // A cabeça gira em torno do pescoço e anda mais que o corpo.
    canvas.save();
    canvas.translate(ctx.deslocamento(0.8), -ctx.respira * ctx.l(0.006));
    final Offset pescoco = ctx.pp(GeometriaDaMemora.pescoco);
    canvas.translate(pescoco.dx, pescoco.dy);
    canvas.rotate(ctx.pose.inclinacaoDaCabeca + ctx.balanco * 0.012);
    canvas.translate(-pescoco.dx, -pescoco.dy);
    _antena.pintar(canvas, ctx);
    _cabeca.pintar(canvas, ctx);
    _visor.pintar(canvas, ctx);
    _rosto.pintar(canvas, ctx);
    canvas.restore();

    canvas.save();
    canvas.translate(ctx.deslocamento(1.2), 0);
    _livro.pintar(canvas, ctx);
    _bracoEsquerdo.pintar(canvas, ctx);
    _bracoDireito.pintar(canvas, ctx);
    canvas.restore();

    canvas.save();
    canvas.translate(ctx.deslocamento(1.4), 0);
    _escudo.pintar(canvas, ctx);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorDaMemora oldDelegate) => true;
}
