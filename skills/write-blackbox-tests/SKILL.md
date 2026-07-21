---
name: write-blackbox-tests
description: (Somente qa-blackbox) Escreve os testes de aceitação usando APENAS requirements.md e os contratos do design.md — proibido ler src/ e docs/context/. Use em paralelo à implementação, quando pedirem 'testes do PBI', 'testes de aceitação', 'cubra os critérios'.
---

# write-blackbox-tests

## Restrições rígidas

- Fontes permitidas: `requirements.md`, `design.md` (contratos), tech.md (como rodar testes). **Proibido**: qualquer arquivo de `src/`, diffs, conversa dos devs.
- Precisa olhar o código para escrever o teste? → a spec está incompleta: devolver ao spec-analyst com a lacuna (contrato ausente, critério vago).

## Passos

0. Pré-flight: confirmar worktree correto (`scripts/worktree.sh start <PBI>` já rodado; branch `pbi/<ID>`) — mesmo quando o design decidiu zero mudança em `src/` e todas as tasks são suas. Nunca escrever teste direto no working tree do repo principal.
1. Mapear 1 critério EARS → ≥1 teste. Tabela de rastreabilidade R#.# → teste.
2. Escrever contra os contratos públicos do design (endpoint, interface, procedure) no framework de teste do repo.
3. Incluir casos de erro e borda declarados nos critérios.
4. Salvar: código no diretório de testes; especificação + rastreabilidade em `docs/tests-spec/<slug>.md` (nome exato — é o que `check-gates.sh` procura para o gate G1).
5. Quando nenhuma task de `dev-*` existir no PBI (design decidiu zero mudança de produção), você também é dono do gate G2 (verify-change) — rodar a suíte de verdade e produzir `docs/reviews/<PBI>-verify.md` (skill `verify-change`).

## Saída — docs/tests-spec/<slug>.md

```
# Tests spec — <slug> (PBI-<id>)
Executor: qa-blackbox. Escrito só a partir de requirements.md/design.md.
## Rastreabilidade R#.# → teste
| Critério | Arquivo de teste | Testes |
| --- | --- | --- |
| R1.1, R1.2 | <Classe>Tests.cs | N |
## Fixtures (se houver)
<arquivo> — <propósito>
## Cobertura
Total de testes / critérios cobertos. Lacuna encontrada (contrato ausente, critério vago) → registrar aqui e devolver ao spec-analyst, nunca inventar.
```

## Regras

- Teste deve falhar de forma diagnóstica (mensagem aponta o critério violado).
- Nunca ajustar teste para acomodar implementação — o sentido é o inverso.
- Código de teste é código: nomes de classe/método, comentários e mensagens seguem o idioma do código-fonte real, não o idioma padrão do time nem da spec/brief. Detecte o idioma pelos contratos públicos já citados em `design.md` (nomes de tipo/método/parâmetro são cópia literal da API real) — nunca abra `src/` só pra checar idioma, isso já viola a restrição rígida acima.
