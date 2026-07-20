---
name: write-requirements
description: Gera .kiro/specs/<slug>/requirements.md — user stories com critérios EARS testáveis — a partir do brief, perguntando TODAS as ambiguidades antes de congelar. Use ao iniciar o trilho feature, ou quando pedirem 'requisitos', 'spec', 'user stories', 'critérios de aceitação', 'especifique a feature'.
---
# write-requirements
## Passos
1. Ler o brief e docs/context/ (eixo overview) se existir.
2. Levantar ambiguidades e fazer TODAS as perguntas de uma vez (formato escalation-rules). Aguardar respostas.
3. Escrever user stories: "Como <papel>, quero <ação>, para <valor>".
4. Para cada story, critérios EARS: "QUANDO <evento/condição>, O SISTEMA DEVE <comportamento observável>". Incluir erro, borda e não-funcionais (persistência, validação, permissão).
5. Teste do critério: um QA que nunca viu o código consegue verificá-lo? Se não, reescrever.
## Saída
`.kiro/specs/<slug>/requirements.md` com: Introdução, Stories numeradas, Critérios EARS numerados (R1.1, R1.2…), Fora de escopo.
## Regras
- Requisito congelado só muda via nova rodada com o humano — e a mudança fica registrada no arquivo (changelog no rodapé).
