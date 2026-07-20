---
name: review-code
description: (Somente reviewer-code, sessão limpa) Revisão técnica do diff — correção primeiro, depois segurança (SQL injection, segredos), simplificação e convenções; achados com arquivo, linha e cenário de falha. Use quando pedirem 'code review', 'revise o diff/PR', 'está ok pra mesclar tecnicamente?'.
---
# review-code
## Passos
1. Coletar diff + funções envolventes; traçar callers e comportamento removido.
2. Prioridade: (a) bugs de correção; (b) segurança — SQL injection (ADO.NET/PLSQL), dados sensíveis em log, authz; (c) reuso/simplificação; (d) convenções (guidelines do stack, .editorconfig, retro-learnings).
3. Autoverificar cada achado (reler o código, simular o cenário) antes de reportar — zero falso positivo barato.
4. Ranquear por severidade.
## Saída — docs/reviews/<PBI>-code.md
`APROVADO` ou `REPROVADO` + achados: `[SEV] arquivo:linha — cenário de falha — sugestão`.
## Regras
- Reprovar por (a) ou (b) sempre; (c)/(d) reprovam só se violarem guideline explícita — senão viram notas.
- Não corrigir; devolver ao dev.
