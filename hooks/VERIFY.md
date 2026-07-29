# Verificação dos hooks — o que está confirmado e o que ainda não

Até a 1.10, este documento tratava os 4 triggers usados pelo repo como "não
confirmados contra um Kiro real" e citava que `PostTaskExec` "não aparece em nenhuma
documentação pública do Kiro". Isso mudou na 1.11: em vez de só especular a partir da
doc pública, o schema real foi lido direto do bundle instalado
(`kiro.kiro-agent/dist/extension.js`, versão `1.0.406` — `resources/app/extensions/
kiro.kiro-agent/package.json` na instalação padrão do Kiro Desktop). O que segue
separa **confirmado por leitura de código** (o schema aceita, o runner existe) de
**confirmado empiricamente** (rodou de verdade e o efeito observado bate) — a régua
do próprio repo ("autorrelato não conta") vale aqui também: leitura de schema prova
que o Kiro *reconhece* o hook, não que ele dispara no seu ambiente específico.

## Confirmado por leitura do schema (1.11)

Os 10 triggers existem no enum (`s4`) do bundle, cada um com um runner dedicado
(`runPostTaskExecHooks`, `runSessionStartHooks`, `runPreToolUseHooks`, etc.) e uma
tabela de aliases camelCase que o Kiro normaliza antes de casar (`normalizeTriggerName`
— ex.: `preToolUse` → `PreToolUse`, `agentSpawn` → `SessionStart`, `fileEdited` →
`PostFileSave`). O selftest (`selftest.sh`, bloco `VALID_HOOK_TRIGGERS`) reprova
qualquer hook do repo com trigger fora desse conjunto.

| Trigger          | Usado por (neste repo)                                      | Confirmado                                    |
| ----------------- | ------------------------------------------------------------ | ----------------------------------------------- |
| `PostFileSave`    | `format-dotnet`, `format-flutter`, `format-oracle`           | schema (runPostFileSaveHooks)                  |
| `PostFileCreate`  | `issue-intake`                                               | schema (runPostFileCreateHooks)                |
| `SessionStart`    | `preflight-branch`                                           | schema (runSessionStartHooks)                  |
| `PostTaskExec`    | `task-checkpoint`                                             | schema (runPostTaskExecHooks) — **existe**, ao contrário do que a 1.10 registrava |
| `PreToolUse`/`preToolUse` | `qa-blackbox-guard`, `readonly-guard` (embutidos em agente) | schema (runPreToolUseHooks) — payload de stdin também confirmado, ver abaixo |

Também confirmado e **não usado** pelo repo hoje (oportunidade futura):
`PreTaskExec`, `PostToolUse`, `Stop`, `UserPromptSubmit`, `PostFileDelete`, `Manual`.

### O payload de stdin de `PreToolUse`

Função `j()` no bundle (`hooks-*.js`) monta, para `PreToolUse`:

```json
{"session_id": "...", "hook_event_name": "PreToolUse", "cwd": "...", "tool_name": "...", "tool_input": {...}}
```

`hooks/scripts/guard-common.sh:guard_payload_path` busca `tool_input` (e as chaves
tradicionais `path`/`file_path`/`filePath`/`file`/`paths`) — antes da 1.11 a chave
`tool_input` não estava na lista de busca, então o guard **sempre** caía no fallback
por grep. A estrutura interna de `tool_input` (que chave tem o path, por tool) segue
sem documentação pública — por isso a extração continua tentando várias chaves e
falhando aberto (`exit 0`) se não reconhecer nada.

### `matcher` de `PreToolUse`/`PostToolUse` casa com NOME DE TOOL, não capability

Erro presente até a 1.10 (`matcher: "fs_read"` / `matcher: "fs_write"`): essas são
*capabilities* (categorias de permissão), não nomes de tool — `tool_name` no payload
é sempre o nome real (`read_file`, `str_replace`, `execute_bash`, ...). Um matcher
`"fs_write"` nunca casa com `tool_name: "str_replace"`; `qa-blackbox-guard` com
`matcher: "fs_read"` nunca casava com nada. Confirmado em `TOOL_CAPABILITY_MAP`/
`TOOL_NAME` no bundle — lista completa em `hooks/README.md` e nos comentários de
`agents/qa-blackbox.md`/`agents/reviewer-code.md` (entre outros). Corrigido na 1.11:
os `matcher` agora citam os nomes de tool reais; `selftest.sh` reprova qualquer
matcher de hook `PreToolUse`/`PostToolUse` que cite um nome fora da lista conhecida.

### `command` sob Windows é executado por cmd.exe, não bash

`spawnHookCommand` faz `spawn(command, { shell: true, cwd, env })` — `cwd` é a raiz do
workspace (por isso os comandos podem usar caminho relativo). No Windows, `shell:
true` resolve para `process.env.ComSpec` (cmd.exe). O `command` antigo
(`bash "$(bash .kiro/scripts/kiro-paths.sh)/hooks/scripts/X.sh"`) tem `$(...)` e aspas
aninhadas — sintaxe de bash; sob cmd.exe isso nunca resolvia ao script de verdade,
silenciosamente. Corrigido na 1.11: todo `command` é agora uma única invocação sem
sintaxe interpretada pelo shell (`bash .kiro/scripts/run-hook.sh <script>.sh`) — ver
`scripts/run-hook.sh` e `hooks/README.md`.

## Ainda não confirmado empiricamente

Leitura de schema prova que o Kiro *reconhece* o hook. Não prova que, na sua
instalação, o painel "Agent Hooks" o lista, que o trigger dispara no momento
esperado, ou que o `matcher`/payload batem exatamente como documentado acima (o
bundle lido é da versão `1.0.406` — outra versão pode divergir). O procedimento
abaixo fecha essa lacuna; ainda não foi executado contra um Kiro real por este repo.

### Procedimento

1. Instalar `hooks/diagnostics/_canary.json` num projeto de teste (`cp
   hooks/diagnostics/_canary.json <projeto>/.kiro/hooks/`) — **nunca instalar isto
   num projeto real via `install.sh`**, é só instrumentação.
2. Abrir o painel "Agent Hooks" no IDE/CLI do Kiro e confirmar que os 4 hooks
   (`_canary-postfilesave`, `_canary-postfilecreate`, `_canary-sessionstart`,
   `_canary-posttaskexec`) aparecem listados e habilitados.
3. Disparar cada trigger manualmente: salvar um arquivo (`PostFileSave`); criar um
   arquivo novo (`PostFileCreate`); abrir uma sessão/aba nova (`SessionStart`);
   marcar uma task `[x]` via "Start task" numa spec de teste (`PostTaskExec`).
4. Conferir quais `.kiro/hooks/.fired-<trigger>` foram gravados (com timestamp UTC)
   — prova que o `command` (agora via `run-hook.sh`) de fato rodou, no seu SO.
5. No mesmo projeto de teste, com o `qa-blackbox` (ou outro agente com guard
   embutido), pedir uma leitura/escrita em `src/` e conferir que é recusada — e
   checar em `~/.kiro/logs` a ausência de `resource-resolver.skill.read_failed` e a
   presença de `resource-resolver.skill.loaded` (prova que as skills carregaram —
   ver `hooks/README.md` e o comentário `resources` em qualquer `agents/*.md`).
6. Preencher a tabela abaixo com o resultado real — **isto é registro empírico, não
   previsão**. Trigger que não disparar: reabrir como achado, não rebaixar a doc em
   silêncio.
7. Apagar `_canary.json` e os `.fired-*` do projeto de teste ao final.

### Resultado (preencher após rodar o procedimento acima num Kiro real)

| Trigger           | Verificado em (data, versão do Kiro, SO) | Resultado  |
| ------------------ | ------------------------------------------ | ---------- |
| `PostFileSave`      | _pendente_                                  | _pendente_ |
| `PostFileCreate`    | _pendente_                                  | _pendente_ |
| `SessionStart`      | _pendente_                                  | _pendente_ |
| `PostTaskExec`      | _pendente_                                  | _pendente_ |
| `PreToolUse` (guards) | _pendente_                                | _pendente_ |
| `command` roda sob cmd.exe no Windows | _pendente_        | _pendente_ |
| skills carregam (`resource-resolver.skill.loaded`) | _pendente_ | _pendente_ |

Enquanto uma linha estiver `_pendente_`, trate a correspondente como "confirmada por
leitura de schema, não por execução real" — mais forte que a postura pré-1.11
("não documentado"), mas ainda abaixo do padrão de evidência que o resto do sistema
exige (`quality-gates.md`: "autorrelato não conta").
