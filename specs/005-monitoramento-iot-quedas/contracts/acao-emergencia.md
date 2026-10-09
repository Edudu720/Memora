# Contrato de Acionamento de Emergência

Define os canais, parâmetros e textos de acionamento do socorro quando um alerta de queda expira (45 segundos) ou quando a pessoa idosa clica em "Preciso de ajuda".

---

## 1. Disparo Telefônico (Discador Nativo)

- **Mecanismo**: Android Intent `android.intent.action.DIAL`
- **URI**: `tel:<numero_limpo>` (ex.: `tel:19999998888`)
- **Comportamento**: Abre a tela nativa de chamada do aparelho com o número do contato de emergência já preenchido.
- **Justificativa de Segurança**: A ação de discagem (`ACTION_DIAL`) é suportada de maneira confiável em todas as versões do Android sem exigir permissões sensíveis e perigosas de segundo plano (`CALL_PHONE`), mantendo conformidade com o Princípio I e as políticas da Google Play Store.

---

## 2. Mensagem / Notificação de Texto

- **Mecanismo**: Android Intent `android.intent.action.SENDTO` / SMS nativo ou link para WhatsApp (`https://wa.me/55...`)
- **Texto Padronizado Seguro**:

```text
ALERTA MEMORA - POSSÍVEL QUEDA DETECTADA

O sensor de cuidado de [Nome da Pessoa Idosa] detectou uma possível queda em [Data] às [Horário].
A verificação no celular não foi respondida após 45 segundos.

Por favor, faça contato telefônico imediatamente para verificar como ela está.

IMPORTANTE: O Memora NUNCA solicita dinheiro, transferências bancárias ou senhas. Não faça pagamentos a desconhecidos.
```

### Regras Antigolpe (Princípio II da Constituição):
1. O texto sempre inclui o aviso explícito de que o Memora nunca solicita dinheiro.
2. Nenhuma chave PIX ou link de pagamento pode constar no alerta.
3. O nome do idoso e a hora exata da ocorrência são fornecidos para facilitar a validação rápida pelo familiar.
