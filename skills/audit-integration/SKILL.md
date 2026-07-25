---
name: audit-integration
description: (Somente auditor) Audita o repo inteiro atrás do que a revisão por PBI não vê — duplicação entre PBIs, drift spec×código, segurança inconsistente — e emite briefs. Use a cada ~5 merges (o merge-gate avisa) ou quando pedirem 'auditoria', 'varre o repo inteiro', 'tem duplicação?'.
---

# audit-integration

## Passos

1. Delimitar a janela: merges `pbi/*` desde o marco em `docs/reviews/.last-audit` (data + SHA gravados pelo `reset-counter` da auditoria anterior; ausente = primeira auditoria, use o histórico inteiro ou um corte razoável e diga qual).
2. Caçar: (a) implementações duplicadas/quase-duplicadas entre PBIs da janela; (b) drift entre specs congeladas e comportamento atual; (c) padrões de segurança divergentes (um PBI valida, outro não); (d) débito que contradiz design registrado.
3. Cada achado confirmado → brief em `docs/issues/AUDIT-<n>.md`, com severidade e evidência.
4. Padrão de falha REPETIDO (2+ PBIs) → acionar retrospective.
5. Fechar a auditoria: `ENGINE="$(bash .kiro/scripts/kiro-paths.sh)"; bash "$ENGINE/skills/merge-gate/scripts/check-gates.sh" reset-counter` — zera o contador de merges e grava o marco (data+SHA) em `docs/reviews/.last-audit`, que delimita a janela da PRÓXIMA auditoria. Sem este passo o aviso "AUDITORIA DEVIDA" dispara pra sempre — e aviso constante é aviso ignorado.

## Saída — docs/issues/AUDIT-<n>.md (schema manutenção do triage-issue + 2 campos)

```
# <título do achado>
origem: audit  id: AUDIT-<n>  tipo: manutencao
repo(s): <lista>  vinculado a: <PBIs onde o padrão apareceu>
## Contexto
## Severidade: crítica|alta|média|baixa (impacto × probabilidade de virar bug real)
## Evidência (arquivo:linha, PBIs envolvidos — nunca achado sem isto)
## Código suspeito / área afetada
## Trilho recomendado: manutencao
```

## Regras

- Só reporta; nunca corrige. Achado sem evidência concreta não vira brief.
