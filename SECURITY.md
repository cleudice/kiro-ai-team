# Segurança

## Reportar vulnerabilidade

Abra um [security advisory privado no GitHub](https://github.com/cleudice/kiro-ai-team/security/advisories/new) ou contate o mantenedor diretamente. Não abra issue pública para vulnerabilidade explorável.

## Modelo de segredos deste repo

- **Nenhum segredo é versionado** — os fragmentos `mcp/*.json` usam variáveis de ambiente (`${GITHUB_TOKEN}`, `${AZDO_ORG}`...) via `env`/`headers`, nunca em `args` (a exceção documentada e o racional estão em [mcp/README.md](mcp/README.md)).
- `autoApprove` nos fragmentos MCP é restrito a operações de **leitura** de tracker; servidores de banco (oracle-sqlcl) e experimentais (firebase) não têm auto-approve nenhum.
- **`kiroAgent.trustedCommands`**: nunca confie largo em comandos destrutivos (`git push`, `git reset --hard`, `npx *`) nem em `check-gates.sh` (recebe `--test-cmd` arbitrário — a aprovação manual é intencional). Ver OPERACAO.md §1.

## Superfícies a saber

- Hooks executam shell local (`hooks/scripts/*.sh`) em resposta a eventos do IDE — revise antes de copiar para `.kiro/hooks/`.
- `task-checkpoint.sh` e `check-gates.sh` executam os comandos declarados em `steering/tech.md` com `bash -c` — `tech.md` é parte da superfície de confiança do repo instalado.
