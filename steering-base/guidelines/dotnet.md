---
inclusion: fileMatch
fileMatchPattern: "**/*.cs"
---
# Guidelines .NET 8/10
- Clean Architecture: dependências apontam para o domínio; Application sem referência a infraestrutura concreta.
- CQRS com MediatR: um handler por caso de uso; validação em pipeline behavior, não no handler.
- Result Pattern para fluxo de erro de negócio; exceções só para o excepcional.
- Rich Domain Model: invariantes dentro da entidade/VO; nada de domínio anêmico em código novo.
- Oracle: acesso via camada de infraestrutura; SQL parametrizado sempre; transação no boundary do caso de uso.
- Async de ponta a ponta (`CancellationToken` propagado); nada de `.Result`/`.Wait()`.
- Nullable habilitado; warnings tratados como erro em código novo.
- .NET 10/C# 14: recursos novos só quando reduzem código sem obscurecer — consistência do repo vence novidade.
- Testes: nomes `Metodo_Cenario_Resultado`; um assert lógico por teste.
