---
inclusion: fileMatch
fileMatchPattern: "**/*.ts*"
---
# Guidelines TypeScript / Node
- `strict: true` no tsconfig; nada de `any` implícito — tipar contratos externos (API, banco, mensageria) explicitamente.
- Async: todo `await` dentro de try/catch com erro tratado; nunca engolir rejeição de Promise sem log/rethrow.
- Regra de negócio fora do handler HTTP/trigger — função pura testável; o handler só orquestra (parse, chama, responde).
- Segredos (chaves de API, credenciais de serviço) via variável de ambiente/secret manager — nunca hardcoded nem versionado.
- Testes: mock só de fronteira externa (rede, banco, tempo); lógica de negócio testada sem mock.
- Lint (`eslint`) limpo antes de cada task; `// eslint-disable` exige justificativa no próprio comentário.
- Consistência de módulo: seguir o padrão de import/export já adotado no pacote (ESM vs CommonJS) — não misturar.
