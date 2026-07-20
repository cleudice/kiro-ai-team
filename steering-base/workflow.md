---
inclusion: always
---
# Workflow do time

Entrada (Jira / Azure Boards / GitHub / Crashlytics) → `triage-issue`/`triage-crash` → brief em `docs/issues/`.

- **Feature** → spec completa: `write-requirements` → `write-design` → `write-tasks` em `.kiro/specs/<slug>/`.
- **Manutenção** → `write-tasks` mínimo direto do brief (sem design formal). Gates continuam obrigatórios.

Execução: `implement-task` (worktree próprio) em paralelo com `write-blackbox-tests` (contexto separado) → `verify-change` → `review-spec` + `review-code` → `merge-gate` → `resolve-issue` no tracker de origem.

Loops: `audit-integration` a cada 5 merges; `retrospective` transforma falha recorrente em regra permanente em `retro-learnings.md`.

Papel decide, não o modelo: nenhum agente aprova o próprio trabalho; qa-blackbox nunca lê `src/`; revisores nunca leem a conversa dos devs.
