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

## Saída — docs/context/<eixo>.md (um arquivo por eixo, mesmo esqueleto nos 8)

```
# <Overview|Architecture|Integrations|Data Flow|Security|Conventions|Gotchas|Feature Guide>
<1 parágrafo: o que este eixo cobre NESTE repo especificamente — nunca genérico de framework>
<corpo: fatos concretos, caminho real do repo (arquivo:linha quando ajudar), não prosa de manual>
```

Conteúdo esperado por eixo (referência rápida — detalhe completo em MANUAL.md §3): overview = o que o sistema faz; architecture = camadas/componentes/dependências; integrations = APIs externas/MCPs/filas; data-flow = modelos/persistência/transações; security = authn/z/segredos/superfícies; conventions = idioma do repo/nomes/padrões; gotchas = armadilhas/débito/"não mexa sem…"; feature-guide = onde nasce código novo, passo a passo.
Regra de formato: cada arquivo é standalone — um agente pode carregar só ESSE eixo (é o ponto da carga seletiva). Referência a outro eixo sempre com o caminho completo (`docs/context/security.md`), nunca "ver acima".

## Regras

- Rodar 1x por repo na adoção do time; re-rodar eixo específico quando o auditor detectar drift.
