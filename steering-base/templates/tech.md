---
inclusion: always
---

# Stack — <NOME DO PROJETO>

<!-- Preencher: runtime/framework e versão exata, banco, integrações, como buildar e rodar testes. -->

- Runtime:
- Código-fonte: `src/` <!-- diretório(s) de implementação, separados por espaço (ex.: `lib/` no Flutter, `src/ web/` multi-módulo). Base do isolamento black-box: o worktree --qa exclui estes diretórios e os guards por-agente bloqueiam leitura (qa-blackbox) e escrita (papéis read-only) neles. Default se ausente: src/. -->
- Banco:
- Integrações:
- Build: `...`
- Testes: `...`
- Verificação/smoke: `...` <!-- OBRIGATÓRIO — é o que verify-change e check-gates executam. Legado WebForms/IIS: defina AQUI como exercitar (URL de homolog, script de smoke, procedure de teste) ou o gate G2 fica BLOCKED. -->
