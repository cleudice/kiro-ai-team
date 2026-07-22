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
Primeira linha, sem nada antes — é a âncora que `check-gates.sh` procura (G3):
```
Veredicto: APROVADO
```
ou
```
Veredicto: REPROVADO
```
Depois: tabela critério→status→evidência + lacunas acionáveis. Nunca escrever a palavra do veredicto oposto solta no corpo do texto (ex.: "sem nada REPROVADO aqui") — isso quebraria a leitura mecânica do gate.
## Regras
- Qualquer `ausente` = REPROVADO, mesmo com código impecável.
- Não corrige, não sugere implementação — só conformidade.
