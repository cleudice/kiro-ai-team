---
inclusion: always
---

# Quality gates — Definition of Done

Autorrelato não conta. Só evidência sobrevivente aos gates.

Um PBI só pode ser mesclado quando TODOS os checks abaixo estiverem registrados:

| #   | Gate                          | Evidência exigida (caminho exato — `check-gates.sh` só reconhece estes)   | Quem produz             |
| --- | ----------------------------- | ------------------------------------------------------------------------- | ----------------------- |
| 1   | Testes black-box verdes       | `docs/tests-spec/<slug>.md` (rastreabilidade) + suíte verde               | qa-blackbox             |
| 2   | Verify observado              | `docs/reviews/<PBI>-verify.md` — veredicto PASS/FAIL/BLOCKED por critério | dev-* via verify-change |
| 3   | Review de spec APROVADO       | `docs/reviews/<PBI>-spec.md`                                              | reviewer-spec           |
| 4   | Review de código APROVADO     | `docs/reviews/<PBI>-code.md`                                              | reviewer-code           |
| 5   | Regressão verde na integração | suíte do repo na branch alvo pós-merge simulado                           | merge-gate              |

Regras adicionais:

- 1 PBI = 1 worktree = 1 branch `pbi/<ID>`. Merge sempre serializado pelo orchestrator. Se algum papel executar fora do worktree (ex.: IDE agindo direto no working tree do repo principal), mover o trabalho para o worktree/branch correto **antes** do G5 — nunca simular merge a partir do estado solto em `main`.
- Reprovação em qualquer gate devolve o PBI ao papel de origem com a lista de lacunas.
- **Trilho manutenção**: gates 2–5 obrigatórios; gate 1 exigido quando houver critério de aceitação novo (bugfix com repro vira teste black-box do repro).
- A cada **5 merges**, o auditor roda `audit-integration`.
- **`tasks.md` marcado `[x]` ou um agente dizendo "aprovado"/"pronto para merge" não é evidência.** Antes de qualquer merge, rodar `check-gates.sh` de verdade e conferir o exit code — nomes de arquivo fora do padrão acima fazem o gate reprovar mecanicamente mesmo com o trabalho tecnicamente pronto.
- **Mudança de configuração de build/ambiente (TargetFramework, versão de SDK, flag de compilação) para contornar um problema do ambiente de execução é uma ambiguidade de escopo, não uma decisão livre do agente** — escalar via `escalation-rules.md` antes de aplicar. Preferir a solução que não altera o que o projeto declara suportar (ex.: `DOTNET_ROLL_FORWARD` no comando de teste em vez de subir o `TargetFramework`).
