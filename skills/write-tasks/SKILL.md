---
name: write-tasks
description: Gera .kiro/specs/<slug>/tasks.md — checklist executável com os gates G1–G5 embutidos no final. Trilho feature (do design) ou manutenção (mínimo, direto do brief). Use quando pedirem 'tasks', 'plano de implementação', 'quebre em tarefas', ou ao fechar a spec.
---

# write-tasks

## Passos

1. Feature: derivar tasks do design.md, ordenadas por dependência. Manutenção: derivar direto do brief (3–8 tasks).
2. Cada task: verbo + resultado verificável + referência aos requisitos (R1.2…) + **agente dono entre parênteses** — o agente que vai executar aquela task (`dev-dotnet`, `dev-webforms`, `dev-flutter`, `qa-blackbox`). Sem dono = task não pode ser roteada; nunca deixar implícito. Independentemente verificável; sem task "misc".
3. Design decidiu zero mudança de produção (bugfix só de teste, por ex.)? Todas as tasks de código são do `qa-blackbox`; não inventar task de `dev-*` que não existe no design.
4. Anexar SEMPRE o bloco final de gates, cada gate já com o agente dono.

## Saída — tasks.md

```
# Tasks — <slug>   (PBI: <id>, trilho: feature|manutencao)
- [ ] 1. <task> (R1.1) — dono: <agente>
- [ ] 2. ...
## Gates (obrigatórios — quality-gates.md)
- [ ] G1. write-blackbox-tests — dono: qa-blackbox   [manutenção: se houver critério novo]
- [ ] G2. verify-change com evidência — dono: quem implementou a task (dev-* ou qa-blackbox)
- [ ] G3. review-spec APROVADO — dono: reviewer-spec
- [ ] G4. review-code APROVADO — dono: reviewer-code
- [ ] G5. merge-gate — dono: orchestrator
```

## Regras

- Task grande demais para 1 sessão = quebrar. Escopo do PBI travado aqui.
- Toda task e todo gate tem exatamente um dono declarado — é o que permite ao orchestrator rotear sem chutar e ao Kiro selecionar o agente certo antes de executar.
