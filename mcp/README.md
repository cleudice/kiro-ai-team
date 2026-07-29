# mcp/ — fragmentos de servidor MCP

Cada arquivo é um fragmento a mesclar manualmente em `.kiro/settings/mcp.json` (projeto) ou `~/.kiro/settings/mcp.json` (global) — nunca copiado automaticamente pelo `install.sh`. A chave `comment` foi tirada dos JSON (não faz parte do schema documentado do Kiro; risco de rejeição/silêncio); a documentação de dono/quirks de cada servidor vive aqui.

| Arquivo             | Dono(s)                                        | Nota                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `atlassian.json`    | `orchestrator`, `spec-analyst`                 | Jira + Bitbucket. Servidor remoto nativo (`url`, sem shim `mcp-remote`). Ajuste a URL se seu toolkit interno usar um proxy próprio. Autenticação normalmente é OAuth no primeiro uso — se sua organização exigir `clientId`/`redirectUri`/`oauthScopes` explícitos, adicione o bloco `oauth` (ver docs do Kiro); não há valor genérico correto pra preencher aqui.           |
| `azure-devops.json` | `orchestrator`, `triage-issue`/`resolve-issue` | Azure Boards. Requer `AZDO_ORG` no ambiente. `${AZDO_ORG}` fica em `args` porque o servidor recebe a organização como argumento posicional e o nome da org não é segredo (a regra "nunca em `args`" abaixo é sobre segredos). Sem a variável definida, o servidor recebe o literal `${AZDO_ORG}` e falha de forma confusa — confira com `echo $AZDO_ORG` antes de habilitar. |
| `firebase.json`     | `dev-flutter`, `triage-issue` (origem crashlytics)                  | Crashlytics/Firestore/Auth via `firebase-tools`.                                                                                                                                                                                                                                                                                                                             |
| `github.json`       | `orchestrator`, `triage-issue`/`resolve-issue` | Issues/PRs GitHub. Servidor hospedado oficial (`github/github-mcp-server`) — o antigo `@modelcontextprotocol/server-github` está deprecado. Servidor remoto nativo (`url`+`headers`); `GITHUB_TOKEN` via variável de ambiente, nunca hardcoded.                                                                                                                              |
| `oracle-sqlcl.json` | `dev-webforms`, `auditor`                      | SQLcl MCP. No Windows, usar o wrapper Git Bash (workaround `sql.exe`/Java).                                                                                                                                                                                                                                                                                                  |

## Por que `url`+`headers` em vez do shim `mcp-remote`

`github.json` e `atlassian.json` usavam `command: npx` + `args: ["-y", "mcp-remote", "<url>", ...]` — um proxy stdio-para-remoto. O Kiro suporta servidor remoto nativo (`url`, `headers`, `oauth`), que é mais simples e não depende de um pacote npm de terceiros só pra fazer a ponte. `azure-devops`, `firebase` e `oracle-sqlcl` continuam locais (`command`+`args`) porque não são serviços remotos com endpoint HTTP — são CLIs.

## Critério de `autoApprove`

Auto-aprovamos só **leituras de tracker** (`getJiraIssue`/`search`, `wit_get_work_item`, issues do GitHub) — baixo risco e alto volume no triage. `firebase.json` não auto-aprova nada porque o servidor é `experimental:` (superfície de tools instável entre versões — auto-aprovar um nome de tool que muda de semântica é risco). `oracle-sqlcl.json` não auto-aprova nada por princípio: acesso direto a banco, toda chamada passa por aprovação manual. Escritas (criar/editar/transicionar item, comentar) nunca entram em `autoApprove` em nenhum servidor.

## Interpolação de variáveis

`${VAR}` é expandido a partir do ambiente do processo que roda o Kiro. Prefira sempre colocar segredos em `env`/`headers`, nunca dentro de `args` (evita vazar em logs de processo que exibem a linha de comando completa).

## Um agente só alcança MCP se declarar isso — mesclar o fragmento aqui não basta

Até a 1.11, nenhum `agents/*.json`/`.md` declarava acesso a MCP — mesclar um fragmento
deste diretório em `mcp.json` deixava o servidor configurado no Kiro, mas **nenhum
agente do time conseguia chamá-lo**: `tools` era sempre `[read, write, shell]`, sem a
tag `@mcp`, e o campo `includeMcpJson` (que controla se o `mcp.json` efetivo do projeto
é injetado no agente) nunca era setado — confirmado no schema do bundle instalado
(`kiro.kiro-agent/dist/extension.js`). `triage-issue`/`resolve-issue` "contra
Jira/Azure Boards/GitHub" rodava sem nenhuma via de acesso real ao tracker.

Hoje só **`orchestrator`** declara `includeMcpJson: true` + `"@mcp"` em `tools`
(`agents/orchestrator.md`) — é quem de fato invoca `triage-issue`/`resolve-issue` no
próprio prompt. Os demais "dono(s)" na tabela acima descrevem quem **consome** o dado
já normalizado pelo orchestrator (o brief em `docs/issues/`), não quem chama o MCP
diretamente. Se o seu projeto precisa que outro agente (ex.: `dev-flutter` pra
Crashlytics, `auditor` pra SQLcl) fale com um servidor MCP por conta própria, adicione
os mesmos dois campos ao `agents/<nome>.md` correspondente antes de instalar.
