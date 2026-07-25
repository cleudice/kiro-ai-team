# Tasks — exportar-extrato (PBI: PBI-FEATURE, trilho: feature)

- [ ] 1. Endpoint GET /api/pedidos/exportar com validação de intervalo e permissão (R1.3, RN.2) — dono: dev-dotnet
- [ ] 2. Geração do CSV em streaming com cabeçalho fixo e escaping RFC 4180 (R1.1, R1.4, R2.1, R2.2) — dono: dev-dotnet
- [ ] 3. Propagação do filtro de status da listagem para a exportação (R1.2) — dono: dev-dotnet
- [ ] 4. Botão de exportação na tela da listagem chamando o endpoint (R1.1) — dono: dev-dotnet

## Gates (obrigatórios — quality-gates.md)

- [ ] G1. write-blackbox-tests — dono: qa-blackbox
- [ ] G2. verify-change com evidência — dono: dev-dotnet
- [ ] G3. review-spec APROVADO — dono: reviewer-spec
- [ ] G4. review-code APROVADO — dono: reviewer-code
- [ ] G5. regressão de integração verde — dono: orchestrator (via merge-gate)
