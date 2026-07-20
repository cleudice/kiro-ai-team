---
name: review-spec
description: (Somente reviewer-spec, sessão limpa) Compara o diff do PBI com requirements.md critério a critério — pega requisito esquecido e scope creep. Use quando pedirem 'revisão de requisitos', 'o diff cobre a spec?', 'conferência de conformidade', antes do merge-gate.
---
# review-spec
## Passos
1. Entrada: diff completo do PBI (`git diff main...pbi/<ID>`) + requirements.md. NÃO ler a conversa dos devs.
2. Para cada critério EARS: `coberto | parcial | ausente` + evidência (arquivo:trecho).
3. Atenção especial a não-funcionais fáceis de esquecer: persistência, validação, tratamento de erro, permissão, i18n.
4. Checar também o inverso: o diff faz algo que NENHUM requisito pede? (scope creep → apontar)
## Saída — docs/reviews/<PBI>-spec.md
`APROVADO` ou `REPROVADO` + tabela critério→status→evidência + lacunas acionáveis.
## Regras
- Qualquer `ausente` = REPROVADO, mesmo com código impecável.
- Não corrige, não sugere implementação — só conformidade.
