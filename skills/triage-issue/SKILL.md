---
name: triage-issue
description: Normaliza qualquer issue (Jira, Azure Boards, GitHub ou texto colado) no brief padrão de docs/issues/ — classifica trilho, checa duplicatas, mapeia repos afetados. Use quando disserem 'triagem da PROJ-123', 'pegue a issue X', 'comece este ticket/chamado/card', ou colarem o texto de uma issue.
---
# triage-issue
## Objetivo
Normalizar qualquer origem de trabalho no brief padrão que o resto do time consome.
## Passos
1. Obter a issue: MCP do tracker (`atlassian`, `azure-devops`, `github`) ou texto colado pelo humano. Registrar `origem` e `id externo`.
2. Classificar: `feature` | `manutencao/bug` | `tarefa`. Para bug: tentar reproduzir e localizar o código suspeito (grep dirigido, docs/context/ se existir).
3. Buscar duplicatas/similares no tracker; anexar links e a solução anterior se houver.
4. Avaliar: precisa de spike? bloqueadores? repositórios afetados (pode ser >1 — gerar um brief por repo, vinculados).
## Saída — docs/issues/<TRACKER>-<ID>.md
```
# <título>
origem: jira|azdo|github|crashlytics  id: <externo>  tipo: feature|manutencao|tarefa
repo(s): <lista>  vinculado a: <briefs irmãos, se multi-repo>
## Contexto
## Reprodução (se bug)
## Código suspeito / área afetada
## Duplicatas & histórico
## Trilho recomendado: spec-completa | tasks-minimas
```
## Regras
- Não planeja solução — entrega o problema enquadrado para o spec-analyst/write-tasks.
- Informação faltante na issue: perguntar no próprio tracker (comentário) ou ao humano; não inventar contexto.
