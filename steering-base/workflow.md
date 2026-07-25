---
inclusion: always
---

# Workflow do time

Entrada (Jira / Azure Boards / GitHub / Crashlytics) → `triage-issue` (issues e crashes) → brief em `docs/issues/`.

- **Feature** → spec completa: `write-requirements` → `write-design` → revisão adversarial da spec (G0: `review-spec` em modo draft, reviewer-spec) → `write-tasks` em `.kiro/specs/<slug>/`.
- **Manutenção** → `write-tasks` mínimo direto do brief (sem design formal; dono: orchestrator). Gates continuam obrigatórios.

Execução: `task-preflight` (pré-flight/checkpoint) + "Start task" nativo do Kiro (worktree próprio) em paralelo com `write-blackbox-tests` (worktree QA separado, sem os diretórios de código do `tech.md`) → `verify-change` → `review-spec` + `review-code` → `merge-gate` → `resolve-issue` no tracker de origem.

Loops: `audit-integration` a cada 5 merges; `retrospective` transforma falha recorrente em regra permanente em `retro-learnings.md`.

Papel decide, não o modelo: nenhum agente aprova o próprio trabalho; qa-blackbox nunca lê o código de implementação (`Código-fonte:` do `tech.md`); revisores nunca leem a conversa dos devs.

Regras comuns de todo `dev-*` (fonte única — os prompts dos devs só carregam o específico do stack): (1) implementar exatamente as tasks do PBI em `.kiro/specs/<slug>/tasks.md`, uma por vez, dentro do worktree designado; (2) escopo travado: nada fora das tasks — refatoração oportunista vira sugestão, não commit; (3) build e testes verdes a cada task concluída; (4) ambiguidade na spec = escalar via `escalation-rules.md`, nunca chutar; (5) dev não escreve os testes de aceitação (são do qa-blackbox) e não aprova o próprio trabalho.
