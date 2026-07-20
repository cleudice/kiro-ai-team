---
name: implement-task
description: Executa as tasks do tasks.md uma a uma no worktree do PBI — build/testes verdes por task, commit pequeno, escopo travado, escala em divergência da spec. Use quando disserem 'implemente o PBI X', 'execute as tasks', 'codifique isso', 'faça a mudança', dentro do worktree.
---
# implement-task
## Pré-flight
1. Confirmar worktree correto (`scripts/worktree.sh start <PBI>` já rodado; branch `pbi/<ID>`).
2. Detectar comandos de build/teste (tech.md do projeto). Build verde antes de começar.
3. Carregar guidelines do stack + docs/context/ (eixos conventions/gotchas) se existir.
## Loop por task
1. Implementar APENAS a task atual, no idioma do repo.
2. Build + testes do módulo verdes → marcar `[x]` no tasks.md → commit pequeno com mensagem `PBI-<ID> task N: <resumo>`.
3. Código real divergiu do design? PARAR e escalar (escalation-rules) — nunca "adaptar silenciosamente".
## Regras
- Nada fora das tasks; melhoria oportunista vira sugestão em docs/reviews/<PBI>-notes.md.
- Não editar os testes do qa-blackbox para fazê-los passar — teste vermelho legítimo = implementação errada ou spec errada; escalar se for a spec.
