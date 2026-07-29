---
name: reverse-engineer-project
description: Mapeia um repo desconhecido e escreve docs/context/ por eixos (overview…gotchas) + preenche tech.md/structure.md vazios — carga seletiva por eixo. Também atualiza um repo já mapeado quando o código divergiu (drift). Use no onboarding de qualquer repo, ou quando disserem 'entenda este código', 'mapeie o projeto', 'como esse sistema funciona', 'herdei esse legado', 'atualize o context', 'esse eixo está desatualizado'.
---

# reverse-engineer-project

## Passos

1. Detectar stack e pontos de entrada (csproj/sln, pubspec, packages.config, schema Oracle).
2. `docs/context/` vazio ou ausente → **modo mapeamento**: gerar os 8 eixos do zero. `docs/context/` já existe → **modo atualização**: reler o código e o(s) eixo(s) pedido(s) (todos, se não especificado), atualizar só o que divergiu e reportar a mudança — nunca regerar por cima sem comparar com o que já está escrito.
3. Gerar/atualizar um arquivo por eixo em `docs/context/`: overview, architecture, integrations, data-flow, security, conventions, gotchas, feature-guide.
4. Cada eixo ≤ ~1 página, com caminhos reais do repo — otimizado para carga seletiva por outros agentes (token-efficiency).
5. Atualizar tech.md/structure.md do steering se estiverem vazios (templates) — nunca sobrescreve o que um humano já preencheu.
6. Em modo atualização: onde código e doc divergem, doc perde — atualiza e reporta a mudança. Exceção: texto que marca uma decisão deliberada ("intencional", "por design") vira conflito reportado ao humano, não sobrescrita silenciosa.

## Saída — docs/context/<eixo>.md (um arquivo por eixo, mesmo esqueleto nos 8)

```
# <Overview|Architecture|Integrations|Data Flow|Security|Conventions|Gotchas|Feature Guide>
<1 parágrafo: o que este eixo cobre NESTE repo especificamente — nunca genérico de framework>
<corpo: fatos concretos, caminho real do repo (arquivo:linha quando ajudar), não prosa de manual>
```

Conteúdo esperado por eixo (referência rápida): overview = o que o sistema faz; architecture = camadas/componentes/dependências; integrations = APIs externas/MCPs/filas; data-flow = modelos/persistência/transações; security = authn/z/segredos/superfícies; conventions = idioma do repo/nomes/padrões; gotchas = armadilhas/débito/"não mexa sem…"; feature-guide = onde nasce código novo, passo a passo.
Regra de formato: cada arquivo é standalone — um agente pode carregar só ESSE eixo (é o ponto da carga seletiva). Referência a outro eixo sempre com o caminho completo (`docs/context/security.md`), nunca "ver acima".

`docs/context/` é a fonte canônica do que este repo é; `AGENTS.md`/`CLAUDE.md` na raiz (instalados por `install.sh`, ver README "a dualidade") são ponteiros finos por design — nunca duplicar conteúdo de `docs/context/` neles.

## Regras

- Modo mapeamento roda 1x por repo, na adoção do time. Depois disso é sempre modo atualização — nunca gerar um eixo do zero por cima de um que já existe sem comparar primeiro.
- Auditor aciona atualização de eixo específico quando detecta drift; qualquer papel pode pedir atualização a qualquer momento ("esse eixo está desatualizado").
