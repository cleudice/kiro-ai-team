---
name: task-preflight
description: Prepara o terreno antes da execução nativa das tasks do Kiro — confirma worktree/branch corretos e build/testes verdes — e faz checkpoint de build/teste após cada task marcada [x] no painel. NÃO substitui o "Start task" nativo do Kiro, que continua sendo quem implementa. Use quando disserem "vou começar as tasks do PBI X", "prepare o worktree", "checkpoint da task", ou logo após marcar uma task concluída no painel.
---
# task-preflight
## Por que este skill existe
O Kiro já executa `tasks.md` nativamente (botão "Start task" no painel da spec, task a task, marcando `[x]`). Este skill NÃO reimplementa esse loop — ele cobre só o que o nativo não garante sozinho: contexto de worktree e checkpoint de build/teste por task. A governança de fundo (nunca chutar, não aprovar o próprio trabalho) já vem do steering `always` (`escalation-rules.md`, `quality-gates.md`), injetado automaticamente em qualquer task, com ou sem este skill.

## Pré-flight (antes de clicar no 1º "Start task")
1. Confirmar que está no worktree/branch corretos: `git branch --show-current` deve ser `pbi/<ID>` (criado por `scripts/worktree.sh start <ID>`). Branch errada → parar e corrigir antes de tocar em código.
2. Rodar o comando de build/teste do `tech.md` do projeto. Não está verde? Não é o PBI atual que deve resolver — escalar.
3. Carregar guidelines do stack + `docs/context/` (eixos conventions/gotchas) se existirem.
4. Confirmar que `.kiro/specs/<slug>/tasks.md` existe e está com os gates G1–G5 no final.
5. A partir daqui: use o painel do Kiro para "Start task" em cada item, na ordem do `tasks.md`.

## Checkpoint (depois de cada task marcada [x] no painel)
1. Build + testes do módulo tocado → verdes antes de seguir para a próxima task.
2. Revisar o diff da task: ficou dentro do escopo dela? Nada fora da task atual — melhoria oportunista vira nota em `docs/reviews/<PBI>-notes.md`, não commit.
3. Implementação divergiu do design/requirements? PARAR e escalar (`escalation-rules.md`) — nunca "adaptar silenciosamente" e seguir para a próxima task.
4. Task tocou testes do `qa-blackbox`? Reprovação neles não se resolve editando o teste — ou a implementação está errada, ou a spec está errada; escalar no segundo caso.

## Fim das tasks
Todo `tasks.md` marcado `[x]` → sair do loop nativo e seguir para `verify-change` (evidência real, não o "concluído" do painel).

## Regras
- Este skill nunca substitui "Start task" — ele só cerca o loop nativo antes e depois.
- Sem worktree correto confirmado, não avance.
