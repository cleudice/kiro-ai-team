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

## Saída — .kiro/specs/<slug>/design.md

```
# Design — <slug>   (PBI: <id>)
## Visão
<3-6 linhas: a forma da mudança e por quê essa forma>
## Contratos públicos   <!-- fonte ÚNICA do qa-blackbox; ele nunca lê src/ -->
### <endpoint|interface|procedure|tela>
- Assinatura: <método+rota | assinatura completa | nome+parâmetros com tipos>
- Entrada: <campos, tipos, obrigatoriedade, validações>
- Saída (sucesso): <shape exato, códigos/status>
- Saída (erro): <cada erro possível: condição → código/mensagem observável>
- Cobre: R1.1, R1.2, ...   <!-- todo R#.# do requirements aparece em algum contrato -->
## Modelo de dados
<tabelas/coleções tocadas, campos novos, migração + rollback se houver>
## Decisões
- Decisão: <X>. Alternativa descartada: <Y>. Motivo: <Z>.
## Raio de impacto
<quem chama o que muda; o que pode regredir; onde o G5 deve olhar>
## Estratégia de teste
<como o qa-blackbox exercita cada contrato sem ler src/: fixtures, ambiente, dados>
```

"Contrato completo" = um QA consegue escrever o teste só com esta seção: assinatura + entrada + toda saída de sucesso E de erro + qual R#.# cobre. Contrato sem os erros mapeados ou sem `Cobre:` está incompleto — o black-box vai inventar ou pular.

## Regras

- Contratos públicos completos são obrigatórios — é o que permite testes black-box sem ler src/. Critério R#.# sem contrato que o cubra = design incompleto, voltar antes de seguir pro write-tasks.
- Design que contradiz um requisito = voltar ao write-requirements, não contornar.
