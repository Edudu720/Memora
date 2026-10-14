import 'package:flutter/foundation.dart' show immutable;

import '../../../design_system/design_system.dart' show Ilustracao;
import '../../../l10n/textos_ajuda.dart';

/// Os assuntos da Ajuda (FR-033).
///
/// "Planos", do wireframe, não está aqui (US9). "Ver a apresentação de novo"
/// (FR-013) também não: não é um assunto que se lê, é uma ação, e a tela da
/// Ajuda a oferece em separado.
enum IdDoAssunto {
  /// Para que serve o Memora.
  aplicativo,

  /// Quem é a Memora.
  memora,

  /// Como conversar com ela — a ajuda guiada.
  conversa,

  /// Gov.br, Meu INSS e os outros serviços sociais.
  servicos,

  /// Só pela loja oficial, e conferindo o desenvolvedor (FR-036).
  baixarAplicativo,

  /// Mandar o Memora a alguém. Só existe com endereço de download (R12).
  compartilhar,

  /// Dicas contra golpe, inclusive o que ninguém do Memora faz (FR-036a).
  seguranca,
}

/// Um assunto da Ajuda: desenho, nome, uma linha, e o conteúdo (T086).
///
/// É **conteúdo embarcado**: nada vem do servidor, e por isso nenhuma tela de
/// Ajuda tem carregando nem erro de rede. O que pode falhar é o
/// "Compartilhar", que abre a folha do sistema — e essa falha tem frase própria.
///
/// ## Uma ideia por tela
///
/// [telas] é uma lista de textos curtos, e a pessoa os lê **um por vez**: o
/// parágrafo único com tudo é o que quem lê devagar abandona no meio. Para a
/// "Segurança" isso é o "uma dica por vez" da US6; para os demais, a mesma
/// regra evita um muro de texto a 200%.
///
/// O assunto "A conversa" não usa [telas]: o conteúdo dele é a ajuda guiada,
/// com balões, e [telas] é vazia (FR-034).
@immutable
class AssuntoDeAjuda {
  /// Qual assunto é.
  final IdDoAssunto id;

  /// O nome, em linguagem comum (FR-008).
  final String titulo;

  /// Uma linha do que há do outro lado.
  final String explicacao;

  /// O desenho. Nunca aparece sozinho: o nome vem escrito ao lado.
  final Ilustracao ilustracao;

  /// As ideias, uma por tela. Vazia só em "A conversa".
  final List<String> telas;

  /// Cria um assunto.
  const AssuntoDeAjuda({
    required this.id,
    required this.titulo,
    required this.explicacao,
    required this.ilustracao,
    this.telas = const <String>[],
  });

  /// Este assunto é uma lista de **dicas**, não de passos?
  ///
  /// Muda só o rótulo do contador e do botão ("Dica 2 de 8", "Próxima dica").
  bool get ehDeDicas => id == IdDoAssunto.seguranca;

  /// O desenho do assunto é a própria Memora?
  ///
  /// Na lista da Ajuda ela ilustra a porta; dentro do assunto, o balão já
  /// traz o rosto dela, e o cabeçalho com a mesma figura a mostraria duas vezes
  /// na mesma tela (revisão de design, T116).
  bool get ehDaMemora => switch (ilustracao) {
    Ilustracao.memoraNeutra ||
    Ilustracao.memoraFalando ||
    Ilustracao.memoraComemorando ||
    Ilustracao.memoraPreocupada => true,
    _ => false,
  };

  /// Os assuntos que **existem** agora, na ordem em que a Ajuda os mostra.
  ///
  /// [podeCompartilhar] só é verdadeiro quando há um endereço oficial de
  /// download (R12, FR-018): assunto que não leva a lugar nenhum é pior que
  /// assunto que não existe. A Ajuda não decide isso — recebe a lista pronta.
  static List<AssuntoDeAjuda> disponiveis({required bool podeCompartilhar}) {
    return <AssuntoDeAjuda>[
      const AssuntoDeAjuda(
        id: IdDoAssunto.aplicativo,
        titulo: TextosAjuda.tituloAplicativo,
        explicacao: TextosAjuda.explicacaoAplicativo,
        ilustracao: Ilustracao.pessoaComCelular,
        telas: TextosAjuda.telasDoAplicativo,
      ),
      const AssuntoDeAjuda(
        id: IdDoAssunto.memora,
        titulo: TextosAjuda.tituloMemora,
        explicacao: TextosAjuda.explicacaoMemora,
        ilustracao: Ilustracao.memoraFalando,
        telas: TextosAjuda.telasDaMemora,
      ),
      const AssuntoDeAjuda(
        id: IdDoAssunto.conversa,
        titulo: TextosAjuda.tituloConversa,
        explicacao: TextosAjuda.explicacaoConversa,
        ilustracao: Ilustracao.portaConversa,
      ),
      const AssuntoDeAjuda(
        id: IdDoAssunto.servicos,
        titulo: TextosAjuda.tituloServicos,
        explicacao: TextosAjuda.explicacaoServicos,
        ilustracao: Ilustracao.portaServicos,
        telas: TextosAjuda.telasDosServicos,
      ),
      const AssuntoDeAjuda(
        id: IdDoAssunto.baixarAplicativo,
        titulo: TextosAjuda.tituloBaixarAplicativo,
        explicacao: TextosAjuda.explicacaoBaixarAplicativo,
        ilustracao: Ilustracao.portaAplicativos,
        telas: TextosAjuda.telasDeBaixarAplicativo,
      ),
      if (podeCompartilhar)
        const AssuntoDeAjuda(
          id: IdDoAssunto.compartilhar,
          titulo: TextosAjuda.tituloCompartilhar,
          explicacao: TextosAjuda.explicacaoCompartilhar,
          ilustracao: Ilustracao.casalIdoso,
          telas: TextosAjuda.telasDeCompartilhar,
        ),
      const AssuntoDeAjuda(
        id: IdDoAssunto.seguranca,
        titulo: TextosAjuda.tituloSeguranca,
        explicacao: TextosAjuda.explicacaoSeguranca,
        ilustracao: Ilustracao.memoraPreocupada,
        telas: TextosAjuda.dicasDeSeguranca,
      ),
    ];
  }
}
