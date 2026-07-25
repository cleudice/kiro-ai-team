# Tests spec — exportar-extrato (PBI-FEATURE)

Executor: qa-blackbox. Escrito só a partir de requirements.md + contratos do
design.md (trilho feature) — nunca de src/.

## Rastreabilidade R#.# → teste

| Critério | Arquivo de teste           | Testes                             |
| -------- | -------------------------- | ---------------------------------- |
| R1.1     | ExportarExtratoTests.cs    | 2 (bordas inclusivas do intervalo) |
| R1.2     | ExportarExtratoTests.cs    | 1                                  |
| R1.3     | ExportarExtratoTests.cs    | 1                                  |
| R1.4     | ExportarExtratoTests.cs    | 1                                  |
| R2.1     | ExportarCsvFormatoTests.cs | 1                                  |
| R2.2     | ExportarCsvFormatoTests.cs | 2 (vírgula; aspas internas)        |
| RN.1     | ExportarVolumeTests.cs     | 1 (fixture 10k linhas, limite 10s) |
| RN.2     | ExportarExtratoTests.cs    | 1                                  |

## Fixtures

Pedidos com data exatamente em `inicio` e `fim` (bordas R1.1); cliente
`"Silva, João \"Jr\""` (R2.2); valor `1234.50` (R2.1); fixture gerada de 10.000
pedidos (RN.1); usuário sem `relatorios.exportar` (RN.2).

## Cobertura

10 testes / 8 critérios — todos cobertos, nenhuma lacuna. Cada teste referencia
só o contrato `GET /api/pedidos/exportar` do design.md.
