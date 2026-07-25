---
name: review-spec
description: (Somente reviewer-spec, sessão limpa) Compara o diff do PBI com requirements.md critério a critério — pega requisito esquecido e scope creep. Use quando pedirem 'revisão de requisitos', 'o diff cobre a spec?', 'conferência de conformidade', antes do merge-gate. Também no modo DRAFT (G0): 'revise a spec antes de implementar', 'a spec está pronta pra congelar?' — revisão adversarial de requirements+design ANTES das tasks.
---

# review-spec

## Modo draft (G0) — revisar a spec ANTES da implementação

Sem isto, a spec é a única etapa do ciclo em que alguém (o spec-analyst) aprova o próprio trabalho — e é a etapa mais cara de errar: o qa-blackbox depende 100% dela, e a revisão pós-diff (G3) só pega a lacuna quando o retrabalho já custa um ciclo inteiro.

1. Entrada: `requirements.md` + `design.md` do PBI (antes de `write-tasks` congelar). NÃO ler a conversa do spec-analyst.
2. Checar: cada critério EARS é testável sem olhar implementação? Todo contrato público do design tem assinatura + entradas + TODAS as saídas (incl. erro) + `Cobre: R#.#`? Algum R#.# sem contrato que o cubra? Ambiguidade que forçaria o dev a decidir sozinho?
3. Saída — `docs/reviews/<PBI>-spec-draft.md`, mesmo formato de âncoras abaixo (`Veredicto:` na primeira linha; sem linha `Commit:` — ainda não há diff). REPROVADO devolve ao spec-analyst com as lacunas; APROVADO libera `write-tasks`.

`check-gates.sh` avisa (não reprova, nesta versão) quando um PBI de trilho feature chega ao merge-gate sem G0.

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

<!-- sync: veredicto-commit (idêntico em review-spec e review-code; selftest confere) -->
Segunda linha, sempre: `Commit: <sha do último commit de CÓDIGO de pbi/<ID>>` (commits que só tocam `docs/reviews/**`/`docs/tests-spec/**` não contam — é contra esse sha que `check-gates.sh` valida). Código novo commitado depois invalida a aprovação; revise de novo.
Depois: tabela critério→status→evidência + lacunas acionáveis. Nunca escrever a palavra do veredicto oposto solta no corpo do texto (ex.: "sem nada REPROVADO aqui") — isso quebraria a leitura mecânica do gate.

## Regras

- Qualquer `ausente` = REPROVADO, mesmo com código impecável.
- Não corrige, não sugere implementação — só conformidade.
