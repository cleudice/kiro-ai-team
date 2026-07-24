# Desconto arredonda errado acima de R$100

origem: github id: EXEMPLO-1 tipo: manutencao
repo(s): app-exemplo vinculado a: —

## Contexto

Carrinho com subtotal > R$100 aplica 10% de desconto. O valor final está sendo
arredondado para cima em vez de para baixo, cobrando centavos a mais do cliente.

## Reprodução

1. Adicionar item de R$150,00 ao carrinho.
2. Aplicar cupom de 10%.
3. Esperado: R$135,00. Observado: R$135,01 (arredondamento para cima no passo
   de cálculo do desconto, antes da soma dos impostos).

## Código suspeito / área afetada

Serviço de cálculo de carrinho, função de aplicação de desconto percentual.

## Duplicatas & histórico

Nenhuma reportada antes.

## Trilho recomendado: tasks-minimas
