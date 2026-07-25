# PBI-EXEMPLO — ciclo completo em miniatura

Fixture ilustrativa: não é código real de nenhum stack, é só o esqueleto de
artefatos que o ciclo do kiro-ai-team produz — brief, tasks, evidência dos 5
gates — pra você ensaiar o fluxo e ver `check-gates.sh` passar de verdade antes
do primeiro PBI num repo real.

## O cenário (fictício)

Bug: "cálculo de desconto arredonda errado acima de R$100" — trilho manutenção
(reprodução clara, ajuste pontual, sem spec formal). Ver
`docs/issues/PBI-EXEMPLO.md` → `.kiro/specs/exemplo-desconto/tasks.md` (tasks
mínimas, trilho manutenção) → evidência de cada gate em `docs/reviews/` e
`docs/tests-spec/`.

## Rodar os gates contra este exemplo

Da raiz do `kiro-ai-team`:

```bash
bash skills/merge-gate/scripts/check-gates.sh PBI-EXEMPLO exemplo-desconto \
  --repo examples/PBI-EXEMPLO --track manutencao --test-cmd true \
  --skip-g5 "exemplo ilustrativo — sem branch/merge real pra simular regressão"
```

Esperado: `RESULTADO: GATES OK — autorizado a mesclar` (exit 0). `--test-cmd true`
simula a suíte (sempre verde) — num PBI real seria o comando de `tech.md`.
`--skip-g5` existe porque este diretório não é um worktree de verdade; num PBI
real, G5 exige `--g5-log` com merge simulado de fato (ver `skills/merge-gate/SKILL.md`).

Este fixture não vive numa branch `pbi/PBI-EXEMPLO` real — por isso a checagem
de vínculo evidência↔commit (`Commit: <sha>`, B2) fica pulada aqui; o sha
`3f2a91c` nos arquivos é ilustrativo (o fixture é o modelo que se copia, então
ele mostra o formato completo). Num PBI real, `docs/reviews/<PBI>-{verify,spec,code}.md`
e o log de G5 exigem a linha batendo com o último commit de código de `pbi/<ID>`,
ou o gate correspondente reprova.

Pra ver um gate reprovando, apague `docs/reviews/PBI-EXEMPLO-code.md` e rode de novo.
