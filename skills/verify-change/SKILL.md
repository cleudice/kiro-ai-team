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
Por critério: `R1.1 — PASS|FAIL|BLOCKED — evidência: <captura/trecho>`.
## Regras
- PASS só com evidência observada. "Deveria funcionar" = FAIL.
- Qualquer FAIL devolve ao dev-* (via task-preflight) ou ao qa-blackbox, conforme quem é dono da task; nada segue para review com verify vermelho.
