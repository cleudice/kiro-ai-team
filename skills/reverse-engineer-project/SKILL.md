---
name: reverse-engineer-project
description: Mapeia um repo desconhecido e escreve docs/context/ por eixos (overview…gotchas) + preenche tech.md/structure.md vazios — carga seletiva por eixo. Use no onboarding de qualquer repo, ou quando disserem 'entenda este código', 'mapeie o projeto', 'como esse sistema funciona', 'herdei esse legado'.
---
# reverse-engineer-project
## Passos
1. Detectar stack e pontos de entrada (csproj/sln, pubspec, packages.config, schema Oracle).
2. Gerar um arquivo por eixo em `docs/context/`: overview, architecture, integrations, data-flow, security, conventions, gotchas, feature-guide.
3. Cada eixo ≤ ~1 página, com caminhos reais do repo — otimizado para carga seletiva por outros agentes (token-efficiency).
4. Atualizar tech.md/structure.md do steering se estiverem vazios (templates).
## Regras
- Rodar 1x por repo na adoção do time; re-rodar eixo específico quando o auditor detectar drift.
