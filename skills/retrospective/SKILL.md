---
name: retrospective
description: Converte falha recorrente em UMA regra objetiva em steering/retro-learnings.md (cap ~30 regras ativas); se valer para todos os projetos, vira PR no kiro-ai-team central. Use quando a mesma falha ocorrer pela 2ª vez ou pedirem 'retro', 'vire regra', 'como evitar de novo'.
---

# retrospective

## Gatilhos

Reprovação repetida no mesmo gate; achado repetido do auditor; escalação repetida sobre a mesma ambiguidade; regressão que escapou.

## Passos

1. Nomear o padrão de falha em 1 frase (o quê, não quem).
2. Derivar a MENOR regra que teria prevenido — verificável, sem "tomar cuidado com".
3. Registrar em `steering/retro-learnings.md`: `- [data][PBI] Falha: ... Regra: ...`
4. Regra vale para todos os projetos? → abrir issue/PR no repo kiro-ai-team (guidelines ou skill correspondente) em vez de duplicar por projeto.

## Regras

- Máx. 1–2 regras por retro — regra demais vira ruído que os agentes ignoram.
- Revisar semestralmente: regra que nunca mais disparou pode ser removida.
