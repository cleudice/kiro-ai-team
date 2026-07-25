# Segurança

## Reportar vulnerabilidade

Abra um [security advisory privado no GitHub](https://github.com/cleudice/kiro-ai-team/security/advisories/new) ou contate o mantenedor diretamente. Não abra issue pública para vulnerabilidade explorável.

## Modelo de segredos deste repo

- **Nenhum segredo é versionado** — os fragmentos `mcp/*.json` usam variáveis de ambiente (`${GITHUB_TOKEN}`, `${AZDO_ORG}`...) via `env`/`headers`, nunca em `args` (a exceção documentada e o racional estão em [mcp/README.md](mcp/README.md)).
- `autoApprove` nos fragmentos MCP é restrito a operações de **leitura** de tracker; servidores de banco (oracle-sqlcl) e experimentais (firebase) não têm auto-approve nenhum.
- **`kiroAgent.trustedCommands`**: nunca confie largo em comandos destrutivos (`git push`, `git reset --hard`, `npx *`) nem em `check-gates.sh` (recebe `--test-cmd` arbitrário — a aprovação manual é intencional). Ver OPERACAO.md §1.

## Superfícies a saber

- Hooks executam shell local (`hooks/scripts/*.sh`) em resposta a eventos do IDE — revise antes de copiar para `.kiro/hooks/`.
- **`steering/tech.md` é código executável**: `task-checkpoint.sh` e `check-gates.sh` rodam os comandos de `Build:`/`Testes:` com `bash -c`, sem allowlist — um PR que edite `tech.md` executa o que quiser no checkpoint de cada task e na execução dos gates. Trate mudança em `tech.md` como mudança de CI: revisão obrigatória em PR. Cada execução dos gates registra o comando usado em `docs/reviews/.gate-ledger` (auditável a posteriori).
- **`.kiro/.kiro-ai-team-paths` é sourceado como shell** por `kiro-paths.sh` em toda invocação de hook — mesmo tratamento: arquivo gravado pelo installer, qualquer edição manual/PR é código executando na sua máquina.
- A linha `Código-fonte:` de `tech.md` define os diretórios que o isolamento black-box protege (worktree `--qa` e guards) — remover/apontar errado desliga a barreira física silenciosamente; revise junto.
