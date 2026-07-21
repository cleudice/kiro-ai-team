---
name: merge-gate
description: Checklist final mecânico do PBI — executa scripts/check-gates.sh (G1–G4 por evidência em disco), orienta a regressão G5 e só então autoriza o merge serializado. Use quando perguntarem "pode mesclar?", "merge do PBI X", "fecha o PBI", "passou nos gates?". Somente o agente orchestrator.
---

# merge-gate

## Passos

1. Obter o comando de testes do `tech.md` do projeto.
2. Executar: `bash .kiro/skills/merge-gate/scripts/check-gates.sh <PBI> <slug> --test-cmd "<cmd>" [--track manutencao]`
   O script decide G1–G4 deterministicamente (exit 0/1). **Não interprete além do script**: sem evidência em disco = reprovado.
3. Exit 1 → devolver ao papel dono do gate reprovado com a saída do script; registrar em `docs/reviews/<PBI>-gate.md`. FIM.
4. Exit 0 → antes do G5, confirmar que o trabalho está no branch `pbi/<ID>` (worktree correto: `git worktree list`/`git branch`) — se o diff estiver solto direto na branch alvo (sem branch/worktree do PBI), é reprovação de processo: mover o trabalho para `pbi/<ID>` (branch + worktree) antes de prosseguir. Nunca simular merge a partir do estado solto.
5. G5: na branch alvo, `git merge --no-commit --no-ff pbi/<PBI>` + suíte completa. Verde → efetivar o merge (serializado — um PBI por vez), `scripts/worktree.sh finish <PBI>`; vermelho → `git merge --abort` e devolver ao dev.
6. Após o merge efetivo: `check-gates.sh bump-counter` (agenda audit-integration a cada 5) e acionar resolve-issue.

## Saída — docs/reviews/<PBI>-gate.md (só quando reprovado — passo 3)

```
# Merge Gate — <PBI> (<slug>)
Executor: orchestrator  Data: <data>  Veredicto: REPROVADO
## Saída do check-gates.sh
<colar a saída completa do script — não resumir, não reinterpretar>
## Gate(s) reprovado(s) e devolvido(s) para
- G<n> → <papel dono> — <o que falta em disco>
```

G5 verde e merge efetivado: não precisa gerar este arquivo — a evidência do sucesso já é o próprio commit de merge + os arquivos G1–G4 que passaram.

## Regras

- Este gate não avalia qualidade — confere evidência. O julgamento já aconteceu nos papéis anteriores.
- Nunca editar os arquivos de docs/reviews/ para "fazer passar".
