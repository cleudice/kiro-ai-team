---
name: write-blackbox-tests
description: (Somente qa-blackbox) Escreve os testes de aceitação usando APENAS requirements.md e os contratos do design.md — proibido ler src/ e docs/context/. Use em paralelo à implementação, quando pedirem 'testes do PBI', 'testes de aceitação', 'cubra os critérios'.
---
# write-blackbox-tests
## Restrições rígidas
- Fontes permitidas: `requirements.md`, `design.md` (contratos), tech.md (como rodar testes). **Proibido**: qualquer arquivo de `src/`, diffs, conversa dos devs.
- Precisa olhar o código para escrever o teste? → a spec está incompleta: devolver ao spec-analyst com a lacuna (contrato ausente, critério vago).
## Passos
1. Mapear 1 critério EARS → ≥1 teste. Tabela de rastreabilidade R#.# → teste.
2. Escrever contra os contratos públicos do design (endpoint, interface, procedure) no framework de teste do repo.
3. Incluir casos de erro e borda declarados nos critérios.
4. Salvar: código no diretório de testes; especificação + rastreabilidade em `docs/tests-spec/<slug>.md`.
## Regras
- Teste deve falhar de forma diagnóstica (mensagem aponta o critério violado).
- Nunca ajustar teste para acomodar implementação — o sentido é o inverso.
