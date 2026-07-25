## O que muda e por quê

<!-- qual garantia estava furada / que gap fecha — mesmo padrão do CHANGELOG -->

## Checklist (o CI confere, isto é só pra você não descobrir por CI vermelho)

- [ ] `bash selftest.sh` verde local
- [ ] Mudou comportamento → `VERSION` bumpada + entrada no `CHANGELOG.md` com racional
- [ ] Tocou `agents/*.json` → rodei `scripts/gen-agent-md.sh` (nunca editar `.md` à mão)
- [ ] Agente/skill/hook novo → referenciado em `OPERACAO.md`
