---
name: merge-gate
description: Checklist final mecânico do PBI — executa scripts/check-gates.sh (G1–G4 por evidência em disco), orienta a regressão G5 e só então autoriza o merge serializado. Use quando perguntarem "pode mesclar?", "merge do PBI X", "fecha o PBI", "passou nos gates?". Somente o agente orchestrator.
---

# merge-gate

## Passos

1. Obter o comando de testes do `tech.md` do projeto.
2. Executar: `bash .kiro/skills/merge-gate/scripts/check-gates.sh <PBI> <slug> --test-cmd "<cmd>" [--track manutencao]`
   Sem `--repo`, o script resolve sozinho o worktree do PBI a partir da branch `pbi/<ID>` (`git worktree list`) e roda G1–G4 lá — nunca no diretório corrente por acidente. Se a branch existir sem worktree registrado, ele reprova cedo com a instrução de rodar `scripts/worktree.sh start <PBI>`; não avance manualmente por cima disso. O script decide G1–G4 deterministicamente (exit 0/1). **Não interprete além do script**: sem evidência em disco = reprovado.
3. Exit 1 → devolver ao papel dono do gate reprovado com a saída do script; registrar em `docs/reviews/<PBI>-gate.md`. FIM.
4. Exit 0 (G1–G4 aprovados) → G5 é bloqueante por padrão: sem log de regressão, o próprio `check-gates.sh` já teria saído 1. Produza o log de verdade: na branch alvo, `git merge --no-commit --no-ff pbi/<PBI>` + suíte completa; `git merge --abort` em seguida (nunca deixar o merge não-commitado pendente). Registre o resultado com a linha-âncora `G5: PASS` ou `G5: FAIL` num arquivo e revalide com `check-gates.sh <PBI> <slug> --g5-log <arquivo>`. Sem ambiente de integração disponível para simular o merge (caso raro, ex.: repo sem CI acessível): `--skip-g5 "<motivo>"` é o único escape — explícito e registrado em `docs/reviews/<PBI>-gate.md`, nunca silencioso.
5. Verde (G5 real ou `--skip-g5` registrado) → efetivar o merge de fato (serializado — um PBI por vez), `scripts/worktree.sh finish <PBI>`; vermelho → devolver ao dev.
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
