---
inclusion: always
---
# Quality gates — Definition of Done

Autorrelato não conta. Só evidência sobrevivente aos gates.

Um PBI só pode ser mesclado quando TODOS os checks abaixo estiverem registrados:

| # | Gate | Evidência exigida | Quem produz |
|---|---|---|---|
| 1 | Testes black-box verdes | saída da execução dos testes escritos só da spec | qa-blackbox |
| 2 | Verify observado | comportamento real exercitado (stdout/HTTP/log), veredicto por critério | dev-* via verify-change |
| 3 | Review de spec APROVADO | docs/reviews/<PBI>-spec.md | reviewer-spec |
| 4 | Review de código APROVADO | docs/reviews/<PBI>-code.md | reviewer-code |
| 5 | Regressão verde na integração | suíte do repo na branch alvo pós-merge simulado | merge-gate |

Regras adicionais:
- 1 PBI = 1 worktree = 1 branch `pbi/<ID>`. Merge sempre serializado pelo orchestrator.
- Reprovação em qualquer gate devolve o PBI ao papel de origem com a lista de lacunas.
- **Trilho manutenção**: gates 2–5 obrigatórios; gate 1 exigido quando houver critério de aceitação novo (bugfix com repro vira teste black-box do repro).
- A cada **5 merges**, o auditor roda `audit-integration`.
