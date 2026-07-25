# Design — exportar-extrato (PBI: PBI-FEATURE)

## Visão

Um endpoint novo de exportação ao lado da listagem existente, reusando a mesma
query de pedidos + filtro de status. Geração do CSV em streaming (não montar o
arquivo inteiro em memória) para cumprir RN.1. Nenhuma mudança na listagem.

## Contratos públicos <!-- fonte ÚNICA do qa-blackbox; ele nunca lê src/ -->

### GET /api/pedidos/exportar

- Assinatura: `GET /api/pedidos/exportar?inicio=<yyyy-MM-dd>&fim=<yyyy-MM-dd>[&status=<status>]`
- Entrada: `inicio` e `fim` obrigatórios (datas `yyyy-MM-dd`); `status` opcional, mesmo domínio do filtro da listagem (`pendente|pago|cancelado`)
- Saída (sucesso): `200`, `Content-Type: text/csv; charset=utf-8`, `Content-Disposition: attachment; filename="pedidos-<inicio>-<fim>.csv"`; primeira linha sempre `id,data,cliente,status,valor_total`; uma linha por pedido do intervalo (inclusivo), na ordem de data crescente
- Saída (erro): `inicio > fim` → `400` com corpo `{"erro":"intervalo inválido"}` (R1.3); data mal formada → `400` `{"erro":"data inválida"}`; sem permissão `relatorios.exportar` → `403`, mesmo corpo padrão de acesso negado do painel (RN.2)
- Cobre: R1.1, R1.2, R1.3, R1.4, R2.1, R2.2, RN.2

## Modelo de dados

Nenhuma tabela nova. Leitura da query de listagem existente com os mesmos joins.
Sem migração, sem rollback.

## Decisões

- Decisão: streaming do CSV direto na resposta. Alternativa descartada: gerar arquivo temporário em disco e servir depois. Motivo: RN.1 (10k linhas < 10s) e nenhuma necessidade de reentrega posterior (agendamento está fora de escopo).
- Decisão: reusar a query da listagem em vez de query dedicada. Alternativa descartada: SQL próprio da exportação. Motivo: garante R1.2 por construção (mesmo filtro, mesma semântica) e evita divergência futura entre tela e arquivo.

## Raio de impacto

Quem chama: só a tela do painel (botão novo). A query da listagem ganha um
consumidor a mais — regressão possível se alguém alterar a query pensando só na
paginação da tela (a exportação não pagina). G5 deve rodar a suíte da listagem
junto.

## Estratégia de teste

qa-blackbox exercita só o endpoint: fixtures de pedidos com datas nas bordas do
intervalo (R1.1), com vírgula/aspas no nome do cliente (R2.2), valores com
milhar (R2.1), usuário sem permissão (RN.2). Intervalo vazio (R1.4) e invertido
(R1.3) sem fixture. Volume de RN.1 com fixture gerada de 10k linhas.
