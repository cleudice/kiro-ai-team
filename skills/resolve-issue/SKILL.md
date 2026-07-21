---
name: resolve-issue
description: Fecha o ciclo no tracker de ORIGEM (Jira, Azure Boards ou GitHub) — causa raiz, guia de QA, notas de config/rollback Oracle, links — e transiciona o status. Use após o merge, quando pedirem 'feche a issue', 'atualize o Jira/board', 'escreva a resolução', 'comenta no ticket'.
---

# resolve-issue

## Passos

1. Ler `origem`/`id` do brief; montar a resolução: causa raiz e solução (2–5 linhas), passos de reprodução p/ QA, notas de config/migração (scripts Oracle + rollback!), links de PR/commit.
2. Postar via MCP correspondente (atlassian | azure-devops | github) e transicionar o status conforme o workflow do projeto — confirmar com o humano antes de status incomum.
3. Sem MCP disponível: imprimir a resolução formatada para colagem manual.
4. Registrar cópia local em `docs/issues/<ID>.md` (seção `## Resolução`).

## Saída — seção `## Resolução` anexada em docs/issues/<ID>.md (e no tracker, mesmo conteúdo)

```
## Resolução
Causa raiz: <2-5 linhas>
Solução: <o que mudou, arquivos/specs envolvidos>
Reprodução p/ QA: <passos ou comando pra confirmar>
Notas de config/migração: <scripts, rollback — obrigatório se houve mudança de schema/infra>
Gates: G1-G5 aprovados (docs/reviews/<PBI>-*.md)
Merge: commit <hash> em <branch>
```

## Regras

- Multi-repo: comentar em todos os briefs irmãos vinculados; fechar a issue externa só quando TODOS os PBIs vinculados passarem no merge-gate.
