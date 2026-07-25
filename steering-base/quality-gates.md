---
inclusion: always
---

# Quality gates — Definition of Done

Autorrelato não conta. Só evidência sobrevivente aos gates.

Um PBI só pode ser mesclado quando TODOS os checks abaixo estiverem registrados:

| #   | Gate                           | Evidência exigida (caminho exato — `check-gates.sh` só reconhece estes)                                                                                                                                 | Quem produz                                                              |
| --- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 0   | Spec revisada (trilho feature) | `docs/reviews/<PBI>-spec-draft.md` — `Veredicto: APROVADO` antes de `write-tasks` congelar (recomendado nesta versão; `check-gates.sh` avisa se ausente, não reprova)                                   | reviewer-spec (modo draft)                                               |
| 1   | Testes black-box verdes        | `docs/tests-spec/<slug>.md` (rastreabilidade) + suíte verde                                                                                                                                             | qa-blackbox                                                              |
| 2   | Verify observado               | `docs/reviews/<PBI>-verify.md` — `Commit: <sha>` + veredicto PASS/FAIL/BLOCKED por critério                                                                                                             | dev-* via verify-change (qa-blackbox quando o PBI não tem task de dev-*) |
| 3   | Review de spec APROVADO        | `docs/reviews/<PBI>-spec.md` — `Veredicto: APROVADO` + `Commit: <sha>`                                                                                                                                  | reviewer-spec                                                            |
| 4   | Review de código APROVADO      | `docs/reviews/<PBI>-code.md` — `Veredicto: APROVADO` + `Commit: <sha>`                                                                                                                                  | reviewer-code                                                            |
| 5   | Regressão verde na integração  | log com linhas-âncora `G5: PASS` + `Commit: <sha>` (via `check-gates.sh ... --g5-log <arquivo>`) — **bloqueante por padrão**: sem `--g5-log`, o gate reprova; escape explícito é `--skip-g5 "<motivo>"` | merge-gate                                                               |

Regras adicionais:

- 1 PBI = 1 worktree = 1 branch `pbi/<ID>`. O qa-blackbox trabalha no worktree QA próprio (`worktree.sh start <PBI> --qa` — branch `qa/pbi/<ID>`, checkout sem `src/`); os testes são mesclados em `pbi/<ID>` antes do merge-gate. Merge sempre serializado pelo orchestrator. Trabalho executado fora do worktree é movido pro worktree/branch correto **antes** do G5 — nunca simular merge a partir do estado solto em `main`.
- Reprovação em qualquer gate devolve o PBI ao papel de origem com a lista de lacunas.
- **Trilho manutenção**: gates 2–5 obrigatórios; gate 1 exigido quando houver critério de aceitação novo. A dispensa do G1 é EXPLÍCITA: `--no-new-criteria "<motivo>"` — sem a flag, `docs/tests-spec/<slug>.md` ausente reprova. Ausência de evidência nunca vira aprovação por omissão.
- **G2 `BLOCKED`**: reprova por padrão; sem ambiente pra observar o comportamento (ex.: legado sem smoke local), o escape explícito é `--allow-blocked "<motivo>"` — registrado em `docs/reviews/<PBI>-gate.md`, como todo escape.
- A cada **5 merges**, o auditor roda `audit-integration` e rearma o contador com `check-gates.sh reset-counter` (grava o marco da auditoria em `docs/reviews/.last-audit`).
- **Evidência amarrada ao commit**: G2/G3/G4 e o log de G5 precisam da linha `Commit: <sha>`, e esse sha precisa ser (prefixo d)o último commit de **código** de `pbi/<ID>` — commits que só tocam `docs/reviews/**` ou `docs/tests-spec/**` (o paperwork da própria evidência) não contam. Código novo commitado depois da aprovação a invalida; `check-gates.sh` reprova até o gate ser refeito sobre o commit atual.
- **`tasks.md` marcado `[x]` ou um agente dizendo "aprovado"/"pronto para merge" não é evidência.** Antes de qualquer merge, rodar `check-gates.sh` de verdade e conferir o exit code.
- **Mudança de configuração de build/ambiente para contornar problema do ambiente** é ambiguidade de escopo, não decisão livre do agente — regra completa e exemplos em `escalation-rules.md` (item 1b).
