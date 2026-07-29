---
name: refine-brief
description: Explora e converge a direção de um brief vago do trilho feature ANTES do write-requirements — gera 2-4 direções distintas, critica risco/força de cada uma, recomenda 1 com justificativa. Só entra quando Objetivo/Escopo do brief comporta mais de uma interpretação de PRODUTO razoável — não é passo obrigatório do fluxo. Use quando disserem 'essa ideia está vaga', 'explora antes de especificar', 'qual direção faz mais sentido', 'brainstorm antes da spec', ou quando write-requirements achar ambiguidade estrutural (não pontual) no brief.
---

# refine-brief

Só use isto quando UMA pergunta de esclarecimento (formato `escalation-rules`) não resolve — o
brief comporta direções de produto genuinamente diferentes, não um detalhe faltando.
Ambiguidade pontual continua sendo "pare e pergunte" direto no `write-requirements`; isto é
para quando nem a pergunta certa está clara ainda.

## Passos

1. Ler o brief inteiro (`docs/issues/<ID>.md`) — Objetivo, Escopo esperado, Contexto.
2. Gerar 2-4 direções distintas de abordagem — variação cosmética não conta, cada direção muda
   o que é entregue ou como. Pelo menos 1 não-óbvia (inversão, corte de escopo, público diferente).
3. Para cada direção, sem exceção: maior risco (o que mata essa direção primeiro) e maior força
   (por que ela venceria as outras). Elogio vazio é proibido; se a ideia original tem um defeito
   estrutural, dizer agora, não só na conclusão.
4. Recomendar 1 direção com 2-3 frases de justificativa. O humano escolhe — aceitar a
   recomendação, trocar de direção, ou pedir uma nova rodada de exploração.
5. Atualizar o MESMO brief (nunca criar arquivo novo) — `Objetivo`/`Escopo esperado` passam a
   refletir a direção escolhida; as descartadas entram numa seção nova, com o motivo.

## Saída — atualiza docs/issues/<ID>.md (não cria arquivo novo)

```
## Objetivo (revisado)
<a direção escolhida, no mesmo formato do Objetivo original>
## Escopo esperado (revisado)
<escopo da direção escolhida>
## Direções descartadas
- <direção>: <maior risco> — descartada porque <motivo>
- <direção>: <maior risco> — descartada porque <motivo>
```

## Regras

- Nunca decide sozinho: a direção final é escolha do humano — mesmo quando uma direção é
  claramente melhor, pergunte antes de atualizar o brief.
- Não é o lugar pra detalhar requisito — critérios EARS, entrada/saída de erro etc. continuam
  no `write-requirements`, sempre depois deste passo.
- Se o humano rejeitar todas as direções, volte ao passo 2 — nunca force convergência numa
  direção já rejeitada.
- Trilho manutenção nunca passa por aqui — o brief de bug/manutenção já é concreto por
  natureza (reprodução + código suspeito); introduzir exploração de direção ali é fricção sem
  ganho.
