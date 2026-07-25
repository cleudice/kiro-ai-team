---
inclusion: always
---

# Quality gates — Definition of Done

Autorrelato não conta. Só evidência sobrevivente aos gates.

Um PBI só pode ser mesclado quando TODOS os checks abaixo estiverem registrados:

| #   | Gate                          | Evidência exigida (caminho exato — `check-gates.sh` só reconhece estes)                                                                                                                                 | Quem produz             |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| 1   | Testes black-box verdes       | `docs/tests-spec/<slug>.md` (rastreabilidade) + suíte verde                                                                                                                                             | qa-blackbox             |
| 2   | Verify observado              | `docs/reviews/<PBI>-verify.md` — `Commit: <sha>` + veredicto PASS/FAIL/BLOCKED por critério                                                                                                             | dev-* via verify-change |
| 3   | Review de spec APROVADO       | `docs/reviews/<PBI>-spec.md` — `Veredicto: APROVADO` + `Commit: <sha>`                                                                                                                                  | reviewer-spec           |
| 4   | Review de código APROVADO     | `docs/reviews/<PBI>-code.md` — `Veredicto: APROVADO` + `Commit: <sha>`                                                                                                                                  | reviewer-code           |
| 5   | Regressão verde na integração | log com linhas-âncora `G5: PASS` + `Commit: <sha>` (via `check-gates.sh ... --g5-log <arquivo>`) — **bloqueante por padrão**: sem `--g5-log`, o gate reprova; escape explícito é `--skip-g5 "<motivo>"` | merge-gate              |

Regras adicionais:

- 1 PBI = 1 worktree = 1 branch `pbi/<ID>`. Merge sempre serializado pelo orchestrator. Se algum papel executar fora do worktree (ex.: IDE agindo direto no working tree do repo principal), mover o trabalho para o worktree/branch correto **antes** do G5 — nunca simular merge a partir do estado solto em `main`.
- Reprovação em qualquer gate devolve o PBI ao papel de origem com a lista de lacunas.
- **Trilho manutenção**: gates 2–5 obrigatórios; gate 1 exigido quando houver critério de aceitação novo (bugfix com repro vira teste black-box do repro).
- A cada **5 merges**, o auditor roda `audit-integration`.
- **Evidência amarrada ao commit (B2)**: G2/G3/G4 e o log de G5 precisam da linha `Commit: <sha>`, e esse sha precisa ser (prefixo d)o último commit de **código** de `pbi/<ID>` (commits que só tocam `docs/reviews/**` ou `docs/tests-spec/**` — o paperwork da própria evidência — não contam) — aprovar num commit e commitar código novo depois no mesmo PBI invalida a aprovação; `check-gates.sh` reprova mecanicamente até o gate ser refeito sobre o commit atual.
- **`tasks.md` marcado `[x]` ou um agente dizendo "aprovado"/"pronto para merge" não é evidência.** Antes de qualquer merge, rodar `check-gates.sh` de verdade e conferir o exit code — nomes de arquivo fora do padrão acima fazem o gate reprovar mecanicamente mesmo com o trabalho tecnicamente pronto.
- **Mudança de configuração de build/ambiente (TargetFramework, versão de SDK, flag de compilação) para contornar um problema do ambiente de execução é uma ambiguidade de escopo, não uma decisão livre do agente** — escalar via `escalation-rules.md` antes de aplicar. Preferir a solução que não altera o que o projeto declara suportar (ex.: `DOTNET_ROLL_FORWARD` no comando de teste em vez de subir o `TargetFramework`).
- **Mecanização é defesa em profundidade, não substituto do prompt.** `qa-blackbox` tem um hook `preToolUse` embutido (`agents/qa-blackbox.json`, script `hooks/scripts/qa-blackbox-guard.sh`) que tenta bloquear leitura de `src/`; o contrato exato de payload que o Kiro passa pra um hook por-agente não é documentado publicamente, então o script falha ABERTO (não bloqueia) quando não reconhece o formato — ele reforça a regra, não a garante sozinho. A fonte da verdade continua sendo o prompt do agente + a revisão adversarial (reviewer-code/reviewer-spec nunca leem a conversa dos devs).
