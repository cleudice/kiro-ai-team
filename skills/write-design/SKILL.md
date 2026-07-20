---
name: write-design
description: Gera .kiro/specs/<slug>/design.md — arquitetura da mudança, contratos públicos completos (base do teste black-box), decisões com alternativa descartada e raio de impacto. Use após requirements aprovado, ou quando pedirem 'design', 'arquitetura da mudança', 'defina os contratos/endpoints'.
---
# write-design
## Passos
1. Ler requirements.md aprovado + docs/context/ (eixos architecture/conventions) + tech.md do projeto.
2. Definir: componentes tocados, contratos públicos (interfaces/endpoints/procedures) com assinaturas, modelo de dados, fluxo de erro.
3. Registrar cada decisão relevante como "Decisão: X. Alternativa descartada: Y. Motivo: Z."
4. Mapear raio de impacto: quem chama, o que pode regredir.
## Saída
`design.md` com: Visão, Contratos públicos (fonte para o qa-blackbox), Modelo de dados, Decisões, Raio de impacto, Estratégia de teste.
## Regras
- Contratos públicos completos são obrigatórios — é o que permite testes black-box sem ler src/.
- Design que contradiz um requisito = voltar ao write-requirements, não contornar.
