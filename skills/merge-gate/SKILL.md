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
4. Exit 0 → G5: na branch alvo, `git merge --no-commit --no-ff pbi/<PBI>` + suíte completa. Verde → efetivar o merge (serializado — um PBI por vez), `scripts/worktree.sh finish <PBI>`; vermelho → `git merge --abort` e devolver ao dev.
5. Após o merge efetivo: `check-gates.sh bump-counter` (agenda audit-integration a cada 5) e acionar resolve-issue.
## Regras
- Este gate não avalia qualidade — confere evidência. O julgamento já aconteceu nos papéis anteriores.
- Nunca editar os arquivos de docs/reviews/ para "fazer passar".
