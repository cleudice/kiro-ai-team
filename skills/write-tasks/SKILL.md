---
name: write-tasks
description: Gera .kiro/specs/<slug>/tasks.md — checklist executável com os gates G1–G5 embutidos no final. Trilho feature (do design) ou manutenção (mínimo, direto do brief). Use quando pedirem 'tasks', 'plano de implementação', 'quebre em tarefas', ou ao fechar a spec.
---
# write-tasks
## Passos
1. Feature: derivar tasks do design.md, ordenadas por dependência. Manutenção: derivar direto do brief (3–8 tasks).
2. Cada task: verbo + resultado verificável + referência aos requisitos (R1.2…). Independentemente verificável; sem task "misc".
3. Anexar SEMPRE o bloco final de gates.
## Saída — tasks.md
```
# Tasks — <slug>   (PBI: <id>, trilho: feature|manutencao)
- [ ] 1. <task> (R1.1)
- [ ] 2. ...
## Gates (obrigatórios — quality-gates.md)
- [ ] G1. write-blackbox-tests (qa-blackbox)   [manutenção: se houver critério novo]
- [ ] G2. verify-change com evidência
- [ ] G3. review-spec APROVADO
- [ ] G4. review-code APROVADO
- [ ] G5. merge-gate (orchestrator)
```
## Regras
- Task grande demais para 1 sessão = quebrar. Escopo do PBI travado aqui.
