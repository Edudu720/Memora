# Contrato de Acionamento de Emergência (WhatsApp Pré-Pronto e Fallback)

Define os canais, parâmetros e textos de acionamento do socorro quando um alerta de queda expira (45 segundos) ou quando a pessoa idosa toca em **"Preciso de ajuda"**.

---

## 1. Canal Prioritário: WhatsApp com Mensagem Pré-Pronta (`FR-020`)

- **Mecanismo Primário**: Android Intent `android.intent.action.VIEW`
- **Pacote Alvo**: `com.whatsapp`
- **URI**: `whatsapp://send?phone=55<numero_limpo>&text=<mensagem_codificada_uri>`
  - *Exemplo*: `whatsapp://send?phone=5519999998888&text=ALERTA%20MEMORA...`
- **Normalização de Telefone (`telefoneWhatsapp`)**:
  - Remove caracteres não numéricos.
  - Se o número possuir 10 ou 11 dígitos nacionais (DDD + telefone), prefixa automaticamente o código do Brasil (`55`).
- **Comportamento**: Abre diretamente a conversa do contato de emergência no WhatsApp com a mensagem de socorro e o aviso antigolpe **já preenchidos e prontos no campo de envio**.

---

## 2. Cascata de Fallback Resiliente (caso o WhatsApp não esteja instalado)

1. **Fallback Web/Deep Link (`https://wa.me/`)**:
   - Android Intent `android.intent.action.VIEW` com `https://wa.me/55<numero_limpo>?text=<mensagem_codificada_uri>`.
2. **Fallback SMS e Discador Nativo (`smsto:` + `tel:`)**:
   - Android Intent `android.intent.action.SENDTO` (`smsto:<numero_limpo>` com `sms_body`) e `android.intent.action.DIAL` (`tel:<numero_limpo>`).

---

## 3. Texto Padronizado Seguro (Cláusula Antigolpe — Princípio II)

```text
ALERTA MEMORA: O sensor de cuidado de [Nome da Pessoa Idosa] detectou uma possível queda em [DD/MM] às [HH:MM]. A verificação de bem-estar no celular não foi respondida após 45 segundos. Por favor, ligue para verificar. (AVISO DE SEGURANÇA: O Memora NUNCA solicita dinheiro, transferências ou senhas).
```

### Regras Antigolpe (Princípio II da Constituição):
1. O texto sempre inclui o aviso explícito de que o Memora **NUNCA** solicita dinheiro, transferências ou senhas.
2. Nenhuma chave PIX ou link de pagamento pode constar no alerta.
3. O nome do idoso, a data e a hora exata da ocorrência são fornecidos para facilitar a validação imediata pelo familiar.
