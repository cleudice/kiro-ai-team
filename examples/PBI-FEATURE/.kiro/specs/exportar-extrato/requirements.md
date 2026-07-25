# Requirements — exportar-extrato (PBI: PBI-FEATURE)

## Introdução

O painel administrativo não oferece exportação do histórico de pedidos; a
conciliação contábil mensal é feita copiando a listagem tela a tela. Esta
feature adiciona exportação CSV por período, reusando o filtro de status da
listagem existente.

## Story 1 — Exportar pedidos do período

Como analista contábil, quero exportar os pedidos de um intervalo de datas em
CSV, para conciliar o fechamento mensal sem digitação manual.

R1.1 - QUANDO o usuário solicitar exportação com data inicial e final válidas, O SISTEMA DEVE retornar um arquivo CSV contendo exatamente os pedidos do intervalo (inclusivo nas duas pontas), com o cabeçalho `id,data,cliente,status,valor_total`
R1.2 - QUANDO a listagem estiver com filtro de status ativo no momento da exportação, O SISTEMA DEVE aplicar o mesmo filtro ao conteúdo exportado
R1.3 - QUANDO a data inicial for posterior à final, O SISTEMA DEVE recusar com a mensagem "intervalo inválido" e não gerar arquivo
R1.4 - QUANDO o intervalo não contiver nenhum pedido, O SISTEMA DEVE retornar um CSV só com a linha de cabeçalho (não erro, não arquivo vazio)

## Story 2 — Valores confiáveis para conciliação

Como analista contábil, quero valores formatados sem ambiguidade, para importar
o CSV na planilha de conciliação sem retrabalho.

R2.1 - QUANDO o CSV for gerado, O SISTEMA DEVE formatar `valor_total` com ponto decimal, duas casas, sem separador de milhar (ex.: `1234.50`)
R2.2 - QUANDO um campo de texto contiver vírgula ou aspas, O SISTEMA DEVE escapá-lo conforme RFC 4180 (campo entre aspas duplas, aspas internas duplicadas)

## Não-funcionais

RN.1 - QUANDO o intervalo contiver até 10.000 pedidos, O SISTEMA DEVE concluir a exportação em menos de 10 segundos
RN.2 - QUANDO o usuário não tiver a permissão `relatorios.exportar`, O SISTEMA DEVE recusar com o mesmo comportamento de acesso negado das demais telas do painel

## Fora de escopo

- Outros formatos (XLSX, PDF)
- Agendamento de exportação recorrente
- Alterar o filtro de status existente da listagem

## Changelog

- 2026-07-25 — congelado (v1)
