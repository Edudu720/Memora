/// Textos do Perfil que dizem respeito à idade (T123, FR-042c).
///
/// Mesma estrutura de `textos_casca.dart`: as frases moram fora das telas, na
/// voz da Memora. O tom é de convite — a data é opcional e nada depende dela —
/// e os erros dizem o que fazer, sem bronca.
abstract final class TextosPerfil {
  // ---------------------------------------------------------------------------
  // Perfil geral (US8, FR-042)
  // ---------------------------------------------------------------------------

  /// Título da tela de perfil.
  static const String tituloPerfil = 'Meu perfil';

  /// Rótulo do nome.
  static const String rotuloNome = 'Como você quer ser chamada';

  /// Rótulo do canal de contato.
  static const String rotuloCanal = 'E-mail ou telefone da conta';

  /// Rótulo do aplicativo mais aprendido.
  static const String rotuloMaisAprendido = 'O que você mais aprendeu';

  /// Frase na voz da Memora quando a pessoa ainda não concluiu nenhum passo a passo.
  static const String maisAprendidoVazio = 'Ainda vamos aprender juntos!';

  // ---------------------------------------------------------------------------
  // A idade no Perfil
  // ---------------------------------------------------------------------------

  /// Rótulo da idade, mostrada como informação.
  static const String rotuloIdade = 'Idade';

  /// A idade por extenso: "1 ano", "72 anos".
  static String idade(int anos) {
    if (anos < 1) return 'Menos de 1 ano';
    return anos == 1 ? '1 ano' : '$anos anos';
  }

  /// Convite, quando a pessoa ainda não informou.
  static const String convite =
      'Se quiser, conte quando você nasceu e eu mostro a sua idade aqui. '
      'Fica só neste aparelho. Você não precisa informar.';

  /// Abre a tela de entrada, quando ainda não há data.
  static const String botaoInformar = 'Contar quando nasci';

  /// Abre a tela de entrada, quando já há data.
  static const String botaoMudar = 'Mudar a data';

  /// Tira a data do Perfil.
  static const String botaoTirar = 'Tirar a idade do meu perfil';

  /// Pergunta antes de tirar.
  static const String perguntaTirar = 'Tirar a sua idade do perfil?';

  /// O que acontece ao tirar.
  static const String avisoTirar =
      'A data de nascimento sai deste aparelho. Se quiser, você conta de novo '
      'depois.';

  /// Confirma a retirada.
  static const String botaoConfirmarTirar = 'Sim, tirar a idade';

  /// Desiste de tirar.
  static const String botaoManter = 'Não, deixar como está';

  // ---------------------------------------------------------------------------
  // A tela de entrada
  // ---------------------------------------------------------------------------

  /// Título da tela.
  static const String tituloEntrada = 'Quando você nasceu';

  /// Instrução da caixa de preenchimento da data (FR-002a).
  static const String instrucaoCamposData =
      'Escreva o dia, o mês e o ano em que você nasceu.';

  /// Instrução da caixa de ações da data (FR-002a).
  static const String instrucaoAcoesData =
      'Quando terminar de preencher, toque em guardar.';

  /// Rótulo do dia.
  static const String rotuloDia = 'Dia';

  /// Ajuda do dia.
  static const String ajudaDia = 'O dia do mês, de 1 a 31.';

  /// Rótulo do mês.
  static const String rotuloMes = 'Mês';

  /// Ajuda do mês.
  static const String ajudaMes = 'O número do mês, de 1 a 12.';

  /// Rótulo do ano.
  static const String rotuloAno = 'Ano';

  /// Ajuda do ano.
  static const String ajudaAno = 'Com quatro números, como 1952.';

  /// Guarda a data.
  static const String botaoGuardar = 'Guardar';

  /// Desiste.
  static const String botaoCancelar = 'Cancelar';

  /// Falta preencher algo.
  static const String erroIncompleta =
      'Falta preencher o dia, o mês e o ano. Use só números.';

  /// Ano curto demais.
  static const String erroAnoCurto =
      'Escreva o ano com quatro números, como 1952.';

  /// Não foi possível guardar (falha do aparelho).
  static const String erroAoGuardar =
      'Não consegui guardar agora. Tente de novo.';

  /// Data que não existe.
  static const String erroImpossivel =
      'Essa data não existe no calendário. Confira o dia e o mês.';

  /// Data que ainda não chegou.
  static const String erroFutura = 'Essa data ainda não chegou. Confira o ano.';

  /// Data de mais de 120 anos.
  static const String erroAntiga =
      'Essa data ficou longe demais. Confira o ano.';

  // ---------------------------------------------------------------------------
  // Foto de perfil e avatares (feature 011, US1–US3)
  // ---------------------------------------------------------------------------

  /// Ação principal quando ainda não há retrato escolhido.
  static const String botaoColocarFoto = 'Colocar foto de perfil';

  /// Ação para substituir a foto ou avatar atual.
  static const String botaoTrocarFoto = 'Trocar foto';

  /// Ação para retirar a foto ou avatar atual.
  static const String botaoRemoverFoto = 'Remover foto';

  /// Título da folha inferior de escolha de origem.
  static const String tituloEscolherOrigemFoto = 'Escolher foto de perfil';

  /// Explicação integrada de privacidade antes de tocar em qualquer opção (FR-004).
  static const String avisoPrivacidadeFoto =
      'O Memora só vê a foto que você escolher, e ela fica guardada só neste '
      'aparelho. Se preferir, escolha um avatar sem usar câmera nem fotos.';

  /// Opção de escolher imagem da galeria do celular.
  static const String opcaoGaleriaFoto = 'Escolher da galeria';

  /// Opção de tirar uma foto nova com a câmera.
  static const String opcaoCameraFoto = 'Tirar foto agora';

  /// Opção de escolher um avatar ilustrado da Memora sem permissões.
  static const String opcaoAvataresFoto = 'Escolher avatar da Memora';

  /// Título da grade de avatares ilustrados.
  static const String tituloAvataresFoto = 'Escolha um desenho para você';

  /// Apoio curto na grade de avatares.
  static const String apoioAvataresFoto =
      'Você não precisa dar nenhuma permissão e pode trocar quando quiser.';

  /// Título da tela de pré-visualização após escolher foto (FR-005).
  static const String tituloPreVisualizacaoFoto = 'Ficou boa assim?';

  /// Texto de apoio na pré-visualização.
  static const String apoioPreVisualizacaoFoto =
      'Veja como a sua foto vai aparecer no seu perfil.';

  /// Botão de confirmação na pré-visualização.
  static const String botaoUsarEstaFoto = 'Usar esta foto';

  /// Botão para voltar e escolher outra opção/imagem.
  static const String botaoEscolherOutraFoto = 'Escolher outra';

  /// Pergunta de confirmação antes de remover o retrato atual (FR-008).
  static const String perguntaRemoverFoto = 'Tirar a foto do seu perfil?';

  /// Aviso do que acontece ao remover a foto.
  static const String avisoRemoverFoto =
      'O seu perfil volta a mostrar o retrato inicial. Você pode colocar outra '
      'foto quando quiser.';

  /// Confirma remoção da foto atual.
  static const String botaoConfirmarRemoverFoto = 'Sim, remover a foto';

  /// Cancela remoção e mantém o retrato atual.
  static const String botaoManterFoto = 'Não, deixar como está';

  /// Confirmação curta após salvar foto ou avatar.
  static const String fotoAtualizadaComSucesso =
      'Pronto! Sua foto de perfil foi atualizada.';

  /// Confirmação curta após remover foto ou avatar.
  static const String fotoRemovidaComSucesso =
      'Sua foto foi removida do perfil.';

  /// Orientação empática quando a permissão de câmera é recusada (FR-011).
  static const String erroPermissaoCamera =
      'Para tirar uma foto agora, o celular precisa liberar a câmera para o '
      'Memora. Se preferir, você pode abrir os ajustes ou escolher um avatar.';

  /// Orientação empática quando a permissão de fotos é recusada (FR-011).
  static const String erroPermissaoGaleria =
      'Para escolher uma imagem da sua galeria, o celular precisa liberar o '
      'acesso à foto escolhida. Você pode abrir os ajustes ou usar um avatar.';

  /// Botão para abrir as configurações de permissão do aplicativo no aparelho.
  static const String botaoAbrirAjustesAparelho = 'Abrir ajustes do aparelho';

  /// Mensagem calma quando a imagem ultrapassa 15 MB.
  static const String erroImagemMuitoGrande =
      'Essa foto é grande demais para este aparelho. Escolha uma imagem menor '
      'ou um avatar da Memora.';

  /// Mensagem calma quando o arquivo não é JPEG, PNG ou WebP estático válido.
  static const String erroImagemFormatoInvalido =
      'Não consegui abrir esse arquivo como foto. Escolha uma foto comum da '
      'galeria ou um avatar da Memora.';

  /// Mensagem calma para falha inesperada na leitura/gravação.
  static const String erroFotoGeral =
      'Não consegui usar essa imagem agora. Tente escolher outra foto ou um '
      'avatar da Memora.';

  /// Indicação curta enquanto a foto selecionada está sendo preparada.
  static const String preparandoFoto = 'Preparando a sua foto...';

  /// Descrição semântica quando a pessoa tem foto própria salva.
  static const String semanticaFotoPropria = 'Sua foto de perfil';

  /// Descrição semântica quando nenhuma foto nem avatar foi escolhido.
  static const String semanticaSemFoto = 'Nenhuma foto de perfil escolhida';

  /// Descrição semântica para avatar ilustrado escolhido.
  static String semanticaAvatarEscolhido(String rotuloAvatar) =>
      'Avatar de perfil escolhido: $rotuloAvatar';

  /// Rótulo acessível do avatar "Memora acenando".
  static const String avatarMemoraAcenando = 'Memora acenando';

  /// Rótulo acessível do avatar "Memora pensando".
  static const String avatarMemoraPensando = 'Memora pensando';

  /// Rótulo acessível do avatar "Memora comemorando".
  static const String avatarMemoraComemorando = 'Memora comemorando';

  /// Rótulo acessível do avatar "Memora com escudo".
  static const String avatarMemoraProtegendo = 'Memora com escudo';

  /// Rótulo acessível do avatar "Casal acolhedor".
  static const String avatarCasalIdoso = 'Casal acolhedor';

  /// Rótulo acessível do avatar "Pessoa com celular".
  static const String avatarPessoaComCelular = 'Pessoa com celular';
}
