import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';
import '../../domain/autenticacao.dart';

/// Tela de perfil, de onde se sai da conta (T075, T076, US4).
///
/// ## Dois toques, contados (FR-024)
///
/// A FR-024 exige a saída alcançável em **no máximo dois toques a partir da
/// tela de perfil**. Aqui são exatamente dois, e nenhum a mais: o primeiro abre
/// a confirmação, o segundo confirma. Não há menu, não há aba, não há
/// "Configurações → Conta → Sair" — cada nível a mais é um lugar onde a pessoa
/// idosa desiste e pede para alguém fazer por ela.
///
/// O botão fica **no fim da tela e sozinho**, sem concorrer com nada. Quem
/// procura sair não está lendo o resto.
///
/// ## Por que a confirmação não é um diálogo por cima
///
/// A [ConfirmacaoMemora] substitui o conteúdo em vez de flutuar sobre ele.
/// Diálogo modal com dois botões é o padrão que a pessoa aprende a fechar sem
/// ler — e a FR-025 pede confirmação **explícita**, o que significa uma decisão
/// tomada, não um obstáculo dispensado.
///
/// ## Sair não falha
///
/// Não há estado de erro nesta tela, e isso é deliberado. O repositório engole
/// a falha de rede de propósito: a limpeza local acontece de qualquer forma, e
/// é ela que tira o acesso deste aparelho. Mostrar "erro ao sair" faria a pessoa
/// concluir que continua conectada — sem saber que não está.
class TelaPerfil extends StatefulWidget {
  /// Chave do botão que inicia a saída.
  static const Key chaveSair = Key('perfil.sair');

  /// Chave da confirmação (FR-025).
  ///
  /// Os dois botões dela são localizados pelo rótulo, e não por chave: eles são
  /// únicos na árvore, e as frases *são* o requisito da FR-025 — um teste que os
  /// encontre por chave continuaria passando com o texto trocado por "OK".
  static const Key chaveConfirmacao = Key('perfil.confirmacao');

  /// Quem está conectada.
  final PessoaAutenticada pessoa;

  /// Encerra a sessão: avisa o servidor e limpa o aparelho.
  final Future<void> Function() aoSair;

  /// Chamada depois que a saída termina, para o fluxo voltar ao início.
  final VoidCallback aoSairConcluido;

  /// Cria a tela de perfil.
  const TelaPerfil({
    required this.pessoa,
    required this.aoSair,
    required this.aoSairConcluido,
    super.key,
  });

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  bool _confirmando = false;
  bool _saindo = false;

  Future<void> _sair() async {
    setState(() => _saindo = true);
    await widget.aoSair();

    if (!mounted) {
      return;
    }
    widget.aoSairConcluido();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TextoMemora.tituloTela(TextosAutenticacao.tituloPerfil),
              const SizedBox(height: MemoraEspacamento.xl),
              _dados(),
              const SizedBox(height: MemoraEspacamento.xxxl),
              if (_saindo)
                const Carregando(mensagem: TextosAutenticacao.saindo)
              else if (_confirmando)
                _confirmacao()
              else
                _botaoSair(),
            ],
          ),
        ),
      ),
    );
  }

  /// Informação, nunca ação: sem pílula e sem preenchimento (FR-012 da 002).
  Widget _dados() {
    return ListaInformacao(
      campos: <CampoInformacao>[
        CampoInformacao(
          rotulo: 'Como eu te chamo',
          valor: widget.pessoa.nomeTratamento,
        ),
      ],
    );
  }

  /// O primeiro toque.
  Widget _botaoSair() {
    return BotaoSecundario(
      key: TelaPerfil.chaveSair,
      rotulo: TextosAutenticacao.botaoSair,
      aoTocar: () => setState(() => _confirmando = true),
    );
  }

  /// O segundo toque, e o último (FR-025).
  ///
  /// Não é [ConfirmacaoMemora.irreversivel]: sair não destrói nada, e a pessoa
  /// entra de novo com a senha. Reservar o tom grave para o que é de fato
  /// irreversível é o que faz esse tom continuar significando alguma coisa.
  Widget _confirmacao() {
    return ConfirmacaoMemora(
      key: TelaPerfil.chaveConfirmacao,
      pergunta: TextosAutenticacao.perguntaSair,
      aviso: TextosAutenticacao.avisoSair,
      rotuloConfirmar: TextosAutenticacao.botaoConfirmarSaida,
      rotuloRecusar: TextosAutenticacao.botaoFicar,
      aoConfirmar: _sair,
      aoRecusar: () => setState(() => _confirmando = false),
    );
  }
}
