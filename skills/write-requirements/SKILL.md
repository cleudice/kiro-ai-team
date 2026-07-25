---
name: write-requirements
description: Gera .kiro/specs/<slug>/requirements.md — user stories com critérios EARS testáveis — a partir do brief, perguntando TODAS as ambiguidades antes de congelar. Use ao iniciar o trilho feature, ou quando pedirem 'requisitos', 'spec', 'user stories', 'critérios de aceitação', 'especifique a feature'.
---

# write-requirements

## Passos

1. Ler o brief e docs/context/ (eixo overview) se existir; atualizar `status: em-spec` no brief.
2. Levantar ambiguidades e fazer TODAS as perguntas de uma vez (formato escalation-rules). Aguardar respostas.
3. Escrever user stories: "Como <papel>, quero <ação>, para <valor>".
4. Para cada story, critérios EARS: "QUANDO <evento/condição>, O SISTEMA DEVE <comportamento observável>". Incluir erro, borda e não-funcionais (persistência, validação, permissão).
5. Teste do critério: um QA que nunca viu o código consegue verificá-lo? Se não, reescrever.

## Saída — .kiro/specs/<slug>/requirements.md

```
# Requirements — <slug>   (PBI: <id>)
## Introdução
<2-4 linhas: o problema e o valor, do brief — não repetir o brief inteiro>
## Story 1 — <título curto>
Como <papel>, quero <ação>, para <valor>.
R1.1 - QUANDO <evento/condição>, O SISTEMA DEVE <comportamento observável e mensurável>
R1.2 - QUANDO <caso de erro>, O SISTEMA DEVE <comportamento de erro observável>
R1.3 - QUANDO <borda: vazio/limite/concorrência>, O SISTEMA DEVE <...>
## Story 2 — ...
R2.1 - ...
## Não-funcionais
RN.1 - <persistência/validação/permissão/performance, no mesmo formato EARS>
## Fora de escopo
- <o que explicitamente NÃO entra — evita scope creep no review>
## Changelog
- <data> — congelado (v1)
```

A numeração `R<story>.<critério>` é contrato: `verify-change` reporta linha a linha por esses IDs e `check-gates.sh` conta essas linhas no G2 — renumerar depois de congelado quebra a rastreabilidade. Todo critério precisa passar no teste do passo 5 (QA que nunca viu o código consegue verificar); "deve funcionar corretamente" reprova.

## Regras

- Requisito congelado só muda via nova rodada com o humano — e a mudança fica registrada no arquivo (changelog no rodapé).
