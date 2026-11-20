# Contrato de UI, Segurança e Estado: Dispositivo de Cuidado, Meu Perfil e Ajuda

**Feature**: `016-ajustes-pos-redesenho` | **Issue**: [#106 (Itens 7, 8, 9, 10, 11 e 14)](https://github.com/Edudu720/Memora/issues/106)  
**Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/016-ajustes-pos-redesenho/spec.md)

---

## 1. Dispositivo de Cuidado — `ControladorDispositivoCuidado.simularQuedaTeste()`

- **Assinatura preservada**: `void simularQuedaTeste()` em `ControladorDispositivoCuidado`.
- **Pós-condições obrigatórias**:
  1. Quando `_provedorAtual` for `ProvedorDeTelemetriaSimulado` e não houver `_quedaAtiva`: aciona `simularQueda()`, populando `quedaAtiva` via stream;
  2. Quando `_provedorAtual` for `ProvedorDeTelemetriaMqtt` (conectado **ou desconectado**) ou qualquer outra implementação de `ProvedorDeTelemetria`, e não houver `_quedaAtiva`: atribui `_quedaAtiva = EventoQueda.novo(bpm: _dispositivo.ultimaTelemetria?.bpm ?? 72, aceleracao: 2.8)` e chama `notifyListeners()`;
  3. **Reentrância**: se `_quedaAtiva != null` ou se `TelaDispositivoCuidado` já estiver com `TelaVerificacaoQueda` aberta (`_verificacaoQuedaAberta == true`), toques repetidos não criam alertas duplicados;
  4. **Segurança ao cancelar**: responder *"Estou bem"* em `TelaVerificacaoQueda` chama `provedor.enviarComandoCessarAlarme()` (seguro offline no MQTT) e fecha sem acionar contatos de emergência;
  5. **Higienização Wokwi**: zero ocorrências de `Wokwi`/`wokwi` em `app/lib/`, `app/test/` e `app/pubspec.yaml`.

---

## 2. Retratos e Tela Meu Perfil (`TelaPerfil`)

- **Catálogo `AvatarIlustrado`**: contém estritamente `memoraAcenando`, `memoraPensando`, `memoraComemorando` e `memoraProtegendo` (removidos `casalIdoso` e `pessoaComCelular`).
- **Invariante de fallback**: `FotoDePerfilLocal.ler(idDaConta)` retorna `null` sem exceção para chaves legadas/removidas (`'casal_idoso'`, `'pessoa_com_celular'`), permitindo renderização imediata no retrato padrão neutro (`RetratoDoPerfil`) e nova seleção posterior.
- **Interface de `TelaPerfil`**:
  - Mantém todos os parâmetros existentes e acrescenta `final String? ultimoModuloConcluido;` (opcional, default `null`, reserva compatível para o Item 14).
  - **Chaves públicas preservadas** (obrigatórias para compatibilidade de testes):
    - `TelaPerfil.chaveLista`
    - `TelaPerfil.chaveNome`
    - `TelaPerfil.chaveCanal`
    - `TelaPerfil.chaveMaisAprendido`
    - `TelaPerfil.chaveDesenho`
    - Novas chaves adicionadas: `TelaPerfil.chaveSecaoAprendizado` e `TelaPerfil.chaveUltimoModulo` (esta última renderizada somente quando `ultimoModuloConcluido != null && ultimoModuloConcluido!.trim().isNotEmpty`).
  - **Invariantes de UX e privacidade**:
    - 0 requisições de rede ao abrir ou reconstruir `TelaPerfil`;
    - Descarte de leituras assíncronas obsoletas caso `idDaConta` mude antes da resposta local e ausência de marcador provisório ruidoso antes da carga inicial;
    - Cabeçalhos semânticos claros em cada seção de cartão (`Semantics(header: true)`), sem transformar linhas informativas em botões;
    - `widget.nome` aparece em **exatamente um** texto visível (`TelaPerfil.chaveNome`);
    - Campos de informação (`chaveNome`, `chaveCanal`, `chaveMaisAprendido`, `chaveUltimoModulo`) não usam `InkWell` e anunciam `isButton: false` / `hasTapAction: false`;
    - Textos proibidos nunca aparecem (`plano`, `assinatura`, `pagamento`, `premium`, `upgrade`, `mensalidade`);
    - `SecaoIdade` permanece estritamente local;
    - Todos os visuais utilizam tokens do Design System (`validar_tokens.py` com 0 violações) e suportam fonte até `200%` em `320×568` sem cortes.

---

## 3. Ajuda — Acesso Seguro `https://` ao Site Tutorial (`AbridorDeSiteTutorial` + `TelaAjuda`)

- **Fonte única da URL**:
  - `Ambiente.urlSiteTutorial` vindo exclusivamente de `--dart-define=MEMORA_URL_SITE_TUTORIAL` e sanitizado por `Ambiente.enderecoOficial(...)`.
  - Esquemas permitidos: apenas `https://`; rejeita `http://`, `javascript:`, `file:`, URL sem host, URL com `user@host`, URL com espaços ou string vazia.
- **Contrato `AbridorDeSiteTutorial`**:
  - `AbridorDeSiteTutorial.doAmbiente(Ambiente)` devolve `null` sempre que não houver endereço oficial válido -> estado obrigatório **"botão oculto"** em `TelaAjuda` (`find.byKey(TelaAjuda.chaveAbrirSiteTutorial)` encontra zero widgets).
  - `Future<bool> abrir()` nunca aceita `String` nem `Uri` como parâmetro externo.
- **Contrato de confirmação modal e erro em `TelaAjuda`**:
  - Preserva exatamente um `CaixaDeEtapa` para os `assuntos` (`tela_ajuda_test.dart`).
  - Quando `abridorSiteTutorial != null`:
    1. Exibe botão acessível (`>= 56 dp` de altura) identificado por `TelaAjuda.chaveAbrirSiteTutorial`;
    2. Primeiro toque **sempre** abre diálogo modal rolável (`scrollable: true` para caber a `200%` em `320×568`), informando que a pessoa sairá do Memora para o site oficial no endereço explicitamente visível (`abridor.endereco`);
    3. Botão *"Agora não"* (`TelaAjuda.chaveCancelarSiteTutorial`) fecha o diálogo sem chamar `abrir()`;
    4. Botão *"Sim, abrir o site"* (`TelaAjuda.chaveConfirmarSiteTutorial`) fecha o diálogo e chama `abrir()`;
    5. Se `abrir()` devolver `false`, exibe aviso calmo (`TelaAjuda.chaveErroSiteTutorial`) com anúncio para leitor de tela (`liveRegion: true`) sem fechar a tela nem expor detalhes técnicos;
    6. Android `<queries>` declara `<intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>`.
