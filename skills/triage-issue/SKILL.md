---
name: triage-issue
description: Normaliza qualquer issue (Jira, Azure Boards, GitHub, crash do Crashlytics ou texto colado) no brief padrão de docs/issues/ — classifica trilho, checa duplicatas, mapeia repos afetados. Use quando disserem 'triagem da PROJ-123', 'pegue a issue X', 'comece este ticket/chamado/card', colarem o texto de uma issue, ou mencionarem crash, Crashlytics, ANR, 'o app caiu/fechou sozinho'.
---

# triage-issue

## Objetivo

Normalizar qualquer origem de trabalho no brief padrão que o resto do time consome.

## Passos

1. Obter a issue: MCP do tracker (`atlassian`, `azure-devops`, `github`), MCP `firebase` para crash do Crashlytics, ou texto colado pelo humano. Registrar `origem` e `id externo`.
   - Crash (origem `crashlytics`): coletar stack trace, versão do app, device/OS, volume e tendência; localizar o frame suspeito e correlacionar com releases recentes; classificar severidade (volume × impacto) e agrupar duplicatas do mesmo root cause; brief em `docs/issues/CRASH-<id>.md`, tipo `manutencao`, com reprodução hipotética e frame suspeito. Sem causa raiz clara: hipóteses ranqueadas, não certezas. (Absorve a antiga skill `triage-crash` — mesmo formato de saída, o orchestrator nunca tratou crash como caso especial.) Anexo de imagem (screenshot de bug, mockup de feature) → descrever textualmente o que a imagem mostra, incorporado na seção correspondente (`Reprodução` p/ bug, `Objetivo`/`Escopo esperado` p/ feature) — nunca ignorar o anexo silenciosamente.
2. Classificar: `feature` | `manutencao/bug` | `tarefa`.
   - Bug: tentar reproduzir e localizar o código suspeito (grep dirigido, docs/context/ se existir).
   - Feature/tarefa com PRD (ou spec simples) na própria descrição do card: extrair Objetivo (o quê e por quê), Escopo esperado (o que o PRD já define como incluído) e Fora de escopo (se o PRD já declarar) — não inventar o que o PRD não disser; lacuna vira pergunta, não suposição.
3. Buscar duplicatas/similares no tracker; anexar links e a solução anterior se houver.
4. Avaliar: precisa de spike? (spike = investigação descartável, roda em "Kiro puro, sem o time" — ver OPERACAO §3; o resultado volta como contexto do brief, nunca vira PBI próprio) bloqueadores? repositórios afetados (pode ser >1 — gerar um brief por repo, vinculados).

## Saída — docs/issues/<TRACKER>-<ID>.md

Bug/manutenção:

```
# <título>
origem: jira|azdo|github|crashlytics  id: <externo>  tipo: manutencao
status: aberto
repo(s): <lista>  vinculado a: <briefs irmãos, se multi-repo>
## Contexto
## Reprodução (passos + o que anexos de imagem mostram)
## Código suspeito / área afetada
## Duplicatas & histórico
## Trilho recomendado: manutencao
```

Feature/tarefa:

```
# <título>
origem: jira|azdo|github|crashlytics  id: <externo>  tipo: feature|tarefa
status: aberto
repo(s): <lista>  vinculado a: <briefs irmãos, se multi-repo>
## Objetivo (o quê e por quê, do PRD/descrição do card)
## Escopo esperado (o que o PRD já define como incluído)
## Fora de escopo (se o PRD já declarar)
## Duplicatas & histórico
## Trilho recomendado: feature
```

## Regras

- A linha `status:` é o estado do PBI em disco — única fonte pro orchestrator retomar numa sessão nova sem reconstruir por inspeção. Valores: `aberto` (triage feito) → `em-spec` (write-requirements iniciado) → `em-dev` (worktree criado) → `em-review` (verify entregue) → `merged` (merge-gate verde) → `done` (resolve-issue fechou no tracker). Quem executa cada etapa atualiza a linha; nunca pular direto pra `done`.
- Vocabulário de trilho: `feature` | `manutencao` — os únicos valores que `check-gates.sh --track` aceita (valor desconhecido é erro, não default mudo). Nunca usar sinônimo (`spec-completa` era o legado que nenhum script reconhecia).
- Não planeja solução — entrega o problema enquadrado para o spec-analyst/write-tasks.
- Informação faltante na issue (inclusive o que um anexo de imagem não deixa claro): perguntar no próprio tracker (comentário) ou ao humano; não inventar contexto.
