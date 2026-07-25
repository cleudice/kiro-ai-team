---
name: merge-gate
description: Checklist final mecânico do PBI — executa scripts/check-gates.sh (G1–G4 por evidência em disco), orienta a regressão G5 e só então autoriza o merge serializado. Use quando perguntarem "pode mesclar?", "merge do PBI X", "fecha o PBI", "passou nos gates?". Somente o agente orchestrator.
---

# merge-gate

## Passos

1. Obter o comando de testes do `tech.md` do projeto.
2. Resolver onde a engine está instalada (necessário nos escopos hybrid/global, onde não é `.kiro/skills/...` direto — ver `.kiro/scripts/kiro-paths.sh`) e executar:
   `ENGINE="$(bash .kiro/scripts/kiro-paths.sh)"; bash "$ENGINE/skills/merge-gate/scripts/check-gates.sh" <PBI> <slug> --test-cmd "<cmd>" [--track manutencao]`
   Antes de rodar: se existir a branch `qa/pbi/<PBI>` (worktree QA em checkout sem `src/`), mescle-a em `pbi/<PBI>` no worktree do dev (`git merge qa/pbi/<PBI>`) — os testes do qa-blackbox precisam estar na branch que os gates avaliam.
   Escapes explícitos (nunca o default; todos ficam registrados em `docs/reviews/<PBI>-gate.md`): `--no-new-criteria "<motivo>"` (manutenção sem critério de aceitação novo — sem a flag, ausência de `docs/tests-spec/<slug>.md` REPROVA o G1) e `--allow-blocked "<motivo>"` (G2 com `BLOCKED` legítimo por falta de ambiente de smoke, ex.: legado WebForms/IIS).
   Sem `--repo`, o script resolve sozinho o worktree do PBI a partir da branch `pbi/<ID>` (`git worktree list`) e roda G1–G4 lá — nunca no diretório corrente por acidente. Se a branch existir sem worktree registrado, ele reprova cedo com a instrução de rodar `.kiro/scripts/worktree.sh start <PBI>`; não avance manualmente por cima disso. O script decide G1–G4 deterministicamente (exit 0/1). **Não interprete além do script**: sem evidência em disco = reprovado.
3. Exit 1 → devolver ao papel dono do gate reprovado com a saída do script; registrar em `docs/reviews/<PBI>-gate.md`. FIM.
4. Exit 0 (G1–G4 aprovados) → G5 é bloqueante por padrão: sem log de regressão, o próprio `check-gates.sh` já teria saído 1. Produza o log de verdade: na branch alvo, `git merge --no-commit --no-ff pbi/<PBI>` + suíte completa; `git merge --abort` em seguida (nunca deixar o merge não-commitado pendente). Registre o resultado com a linha-âncora `G5: PASS` ou `G5: FAIL` e, na linha seguinte, `Commit: <sha do HEAD de pbi/<PBI> no momento do merge simulado>` (`git rev-parse pbi/<PBI>`) — sem isso `check-gates.sh` reprova (B2: evidência precisa amarrar ao commit que vai mesclar de verdade). Revalide com `check-gates.sh <PBI> <slug> --g5-log <arquivo>`. Sem ambiente de integração disponível para simular o merge (caso raro, ex.: repo sem CI acessível): `--skip-g5 "<motivo>"` é o único escape — explícito e registrado em `docs/reviews/<PBI>-gate.md`, nunca silencioso.
5. Verde (G5 real ou `--skip-g5` registrado) → **antes de mesclar**, garanta que a evidência está commitada em `pbi/<PBI>` (`docs/reviews/<PBI>-*.md`, `docs/tests-spec/<slug>.md`) — commit só de paperwork (não invalida o vínculo evidência↔commit do B2, ver `check-gates.sh`). Sem isso, `.kiro/scripts/worktree.sh finish` já recusa remover o worktree (aborta em `alterações não commitadas`) — não contorne com `--force` pra "resolver" o aviso; commite de verdade. Aí sim: efetivar o merge de fato (serializado — um PBI por vez), **`git push origin <branch principal>`** e só então `.kiro/scripts/worktree.sh finish <PBI>` — o `finish` verifica `merge-base --is-ancestor` contra `origin/<main>`, então merge local sem push aborta com "não está mergeada em origin/<main>"; a resposta é o push, nunca `--force`. Vermelho → devolver ao dev.
6. Após o merge efetivo: atualizar `status: merged` no brief `docs/issues/<ID>.md`, `check-gates.sh bump-counter` (agenda audit-integration a cada 5; após a auditoria acontecer, quem rearma é o auditor com `check-gates.sh reset-counter`) e acionar resolve-issue.

## Saída — docs/reviews/<PBI>-gate.md (reprovação — passo 3 — ou registro de escape)

```
# Merge Gate — <PBI> (<slug>)
Executor: orchestrator  Data: <data>  Veredicto: REPROVADO
## Saída do check-gates.sh
<colar a saída completa do script — não resumir, não reinterpretar>
## Gate(s) reprovado(s) e devolvido(s) para
- G<n> → <papel dono> — <o que falta em disco>
```

G5 verde e merge efetivado: não precisa gerar este arquivo — a evidência do sucesso já é o próprio commit de merge + os arquivos G1–G4 que passaram. Exceção: se algum escape foi usado (`--skip-g5`, `--no-new-criteria`, `--allow-blocked`), o próprio `check-gates.sh` grava (idempotente, entre marcadores) o bloco de escapes neste arquivo — é o registro permanente de que o merge passou com dispensa explícita.

## Regras

- Este gate não avalia qualidade — confere evidência. O julgamento já aconteceu nos papéis anteriores.
- Nunca editar os arquivos de docs/reviews/ para "fazer passar".
- `.kiro/scripts/worktree.sh finish --force` nunca é resposta pro aviso de "alterações não commitadas" contendo evidência de gate — isso apaga a prova de que os gates passaram. `--force` é só pra descartar de propósito um worktree abandonado/errado.
