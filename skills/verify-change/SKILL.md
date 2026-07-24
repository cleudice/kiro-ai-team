---
name: verify-change
description: Verifica que a mudança FUNCIONA exercitando comportamento real (HTTP, CLI, tela, procedure) e captura evidência por critério — PASS/FAIL/BLOCKED, nunca autorrelato. Use após implementar, quando perguntarem 'funciona?', 'verifique', 'rode e veja', 'confirme o fix', 'testa aí'.
---

# verify-change

## Passos

1. Fonte dos critérios: requirements.md (feature) ou reprodução do brief (manutenção/bug).
2. Detectar como rodar (tech.md): app, endpoint, tela, procedure.
3. Exercitar cada critério de verdade: chamada HTTP, execução da CLI, fluxo na tela, execução da procedure. Capturar evidência: stdout, status code, log, resultado de query.
4. Bug: provar que a reprodução original agora passa E que o comportamento vizinho não regrediu.

## Saída — docs/reviews/<PBI>-verify.md

Por critério, **uma linha começando exatamente** `R<n>.<n> - PASS - ...`, `R<n>.<n> - FAIL - ...` ou `R<n>.<n> - BLOCKED - ...` (hífen ou travessão, nunca as três palavras juntas) — é a âncora que `check-gates.sh` procura (G2), leitura mecânica igual a G3/G4. Depois do veredicto, a evidência: `R1.1 - PASS - evidência: <captura/trecho>`.
Nunca escrever `PASS`/`FAIL`/`BLOCKED` numa frase solta fora dessas linhas (ex.: no meio de um log colado) sem que a linha comece com `R<n>.<n>` — isso quebraria a leitura mecânica do gate. Cole evidência bruta (log completo, stdout) **depois** da linha do critério, nunca antes nem misturada a ela.

## Regras

- PASS só com evidência observada. "Deveria funcionar" = FAIL.
- Qualquer FAIL devolve ao dev-* (via task-preflight) ou ao qa-blackbox, conforme quem é dono da task; nada segue para review com verify vermelho.
