---
inclusion: always
---

# Workflow do time

Entrada (Jira / Azure Boards / GitHub / Crashlytics) → `triage-issue`/`triage-crash` → brief em `docs/issues/`.

- **Feature** → spec completa: `write-requirements` → `write-design` → `write-tasks` em `.kiro/specs/<slug>/`.
- **Manutenção** → `write-tasks` mínimo direto do brief (sem design formal). Gates continuam obrigatórios.

Execução: `task-preflight` (pré-flight/checkpoint) + "Start task" nativo do Kiro (worktree próprio) em paralelo com `write-blackbox-tests` (contexto separado) → `verify-change` → `review-spec` + `review-code` → `merge-gate` → `resolve-issue` no tracker de origem.

Loops: `audit-integration` a cada 5 merges; `retrospective` transforma falha recorrente em regra permanente em `retro-learnings.md`.

Papel decide, não o modelo: nenhum agente aprova o próprio trabalho; qa-blackbox nunca lê `src/`; revisores nunca leem a conversa dos devs.

Regras comuns de todo `dev-*` (fonte única — os prompts dos devs só carregam o específico do stack): (1) implementar exatamente as tasks do PBI em `.kiro/specs/<slug>/tasks.md`, uma por vez, dentro do worktree designado; (2) escopo travado: nada fora das tasks — refatoração oportunista vira sugestão, não commit; (3) build e testes verdes a cada task concluída; (4) ambiguidade na spec = escalar via `escalation-rules.md`, nunca chutar; (5) dev não escreve os testes de aceitação (são do qa-blackbox) e não aprova o próprio trabalho.
