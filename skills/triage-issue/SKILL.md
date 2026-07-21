---
name: triage-issue
description: Normaliza qualquer issue (Jira, Azure Boards, GitHub ou texto colado) no brief padrão de docs/issues/ — classifica trilho, checa duplicatas, mapeia repos afetados. Use quando disserem 'triagem da PROJ-123', 'pegue a issue X', 'comece este ticket/chamado/card', ou colarem o texto de uma issue.
---

# triage-issue

## Objetivo

Normalizar qualquer origem de trabalho no brief padrão que o resto do time consome.

## Passos

1. Obter a issue: MCP do tracker (`atlassian`, `azure-devops`, `github`) ou texto colado pelo humano. Registrar `origem` e `id externo`. Anexo de imagem (screenshot de bug, mockup de feature) → descrever textualmente o que a imagem mostra, incorporado na seção correspondente (`Reprodução` p/ bug, `Objetivo`/`Escopo esperado` p/ feature) — nunca ignorar o anexo silenciosamente.
2. Classificar: `feature` | `manutencao/bug` | `tarefa`.
   - Bug: tentar reproduzir e localizar o código suspeito (grep dirigido, docs/context/ se existir).
   - Feature/tarefa com PRD (ou spec simples) na própria descrição do card: extrair Objetivo (o quê e por quê), Escopo esperado (o que o PRD já define como incluído) e Fora de escopo (se o PRD já declarar) — não inventar o que o PRD não disser; lacuna vira pergunta, não suposição.
3. Buscar duplicatas/similares no tracker; anexar links e a solução anterior se houver.
4. Avaliar: precisa de spike? bloqueadores? repositórios afetados (pode ser >1 — gerar um brief por repo, vinculados).

## Saída — docs/issues/<TRACKER>-<ID>.md

Bug/manutenção:

```
# <título>
origem: jira|azdo|github|crashlytics  id: <externo>  tipo: manutencao
repo(s): <lista>  vinculado a: <briefs irmãos, se multi-repo>
## Contexto
## Reprodução (passos + o que anexos de imagem mostram)
## Código suspeito / área afetada
## Duplicatas & histórico
## Trilho recomendado: tasks-minimas
```

Feature/tarefa:

```
# <título>
origem: jira|azdo|github|crashlytics  id: <externo>  tipo: feature|tarefa
repo(s): <lista>  vinculado a: <briefs irmãos, se multi-repo>
## Objetivo (o quê e por quê, do PRD/descrição do card)
## Escopo esperado (o que o PRD já define como incluído)
## Fora de escopo (se o PRD já declarar)
## Duplicatas & histórico
## Trilho recomendado: spec-completa
```

## Regras

- Não planeja solução — entrega o problema enquadrado para o spec-analyst/write-tasks.
- Informação faltante na issue (inclusive o que um anexo de imagem não deixa claro): perguntar no próprio tracker (comentário) ou ao humano; não inventar contexto.
