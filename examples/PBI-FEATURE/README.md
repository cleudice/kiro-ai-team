# PBI-FEATURE — trilho feature em miniatura

Fixture ilustrativa complementar ao `PBI-EXEMPLO/` (que cobre o trilho
manutenção e a evidência dos 5 gates). O foco aqui é a **frente da pipeline** —
os artefatos mais difíceis de acertar e dos quais o resto do ciclo depende:

- `docs/issues/PBI-FEATURE.md` — brief de feature (com a linha `status:` que o
  orchestrator usa como estado do PBI em disco)
- `.kiro/specs/exportar-extrato/requirements.md` — user stories com critérios
  EARS numerados (`R1.1`…), erro, borda, não-funcionais, fora de escopo
- `.kiro/specs/exportar-extrato/design.md` — contrato público **completo**
  (assinatura + entrada + toda saída de sucesso E de erro + `Cobre: R#.#`) — é
  a única fonte do qa-blackbox, que nunca lê `src/`
- `.kiro/specs/exportar-extrato/tasks.md` — tasks com dono + bloco G1–G5
- `docs/tests-spec/exportar-extrato.md` — rastreabilidade R#.# → teste,
  derivada só da spec

Repare no encadeamento: todo `R#.#` do requirements aparece no `Cobre:` de
algum contrato do design, e todo `R#.#` aparece na tabela do tests-spec. É essa
rastreabilidade tripla que os gates leem mecanicamente.

Este exemplo não traz evidência de gates (`docs/reviews/`) — as tasks estão
`[ ]` de propósito: é o retrato do PBI **antes** da implementação. Para ver os
gates passando de verdade, use `examples/PBI-EXEMPLO/`.
