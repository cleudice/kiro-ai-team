# Tasks — exemplo-desconto (PBI: PBI-EXEMPLO, trilho: manutencao)

- [x] 1. Corrigir arredondamento do desconto percentual para baixo (R1.1) — dono: dev-dotnet
- [x] 2. Teste de regressão do valor exato do exemplo de reprodução (R1.1) — dono: qa-blackbox

## Gates (obrigatórios — quality-gates.md)

- [x] G1. write-blackbox-tests — dono: qa-blackbox
- [x] G2. verify-change com evidência — dono: dev-dotnet
- [x] G3. review-spec APROVADO — dono: reviewer-spec
- [x] G4. review-code APROVADO — dono: reviewer-code
- [ ] G5. regressão de integração verde — dono: orchestrator (via merge-gate; ver README.md deste exemplo — usa --skip-g5, não é um PBI real)
