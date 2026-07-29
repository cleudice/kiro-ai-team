# Hooks — o que é opcional, o que já vem, o que nunca instalar

Pergunta recorrente: "quando e quais hooks preciso copiar pro projeto? o script é só
do repositório? é só o `.json`?". Resposta direta:

| Artefato                         | Quem instala                | Onde vai                          |
| --------------------------------- | ---------------------------- | ---------------------------------- |
| `hooks/*.json` (os 6 deste diretório) | **você, à mão, um por um** | `<projeto>/.kiro/hooks/`           |
| `hooks/scripts/*.sh` (a implementação) | `install.sh`, automático   | `<engine>/hooks/scripts/`          |
| Guards por-agente (`qa-blackbox-guard`, `readonly-guard`) | `install.sh`, automático — já embutidos em `agents/*.md`/`.json` | dentro do próprio agente |
| `hooks/diagnostics/_canary.json`  | **ninguém, nunca**           | só num projeto de teste, temporário, pra rodar `VERIFY.md` |

**Sim, o que você copia é só o `.json`.** Os `.sh` que ele chama (`hooks/scripts/`) já
foram instalados pela engine — `install.sh` copia todo `hooks/scripts/*.sh` junto de
`agents/`/`skills/`, sempre, em qualquer escopo. Copiar o `.json` sem o `.sh` correspondente
não acontece: o `.sh` chega primeiro (na instalação do time), o `.json` é só o gatilho que
falta.

## Os 6 hooks deste diretório

| Hook                  | Trigger        | Dispara em                          | Requer                                  |
| ---------------------- | -------------- | ------------------------------------ | ---------------------------------------- |
| `format-dotnet`        | `PostFileSave` | salvar `.cs`                         | `dotnet` no PATH (falha aberto se ausente) |
| `format-flutter`       | `PostFileSave` | salvar `.dart`                       | `dart`/`flutter` no PATH                 |
| `format-oracle`        | `PostFileSave` | salvar `.sql`                        | nada além do repo — linter próprio       |
| `task-checkpoint`      | `PostTaskExec` | task marcada `[x]` numa spec         | `steering/tech.md` com `Testes:` preenchido |
| `preflight-branch`     | `SessionStart` | início de qualquer sessão            | `.kiro/specs/*/tasks.md` com pendência   |
| `issue-intake`         | `PostFileCreate` | novo arquivo em `docs/issues/`     | nada                                     |

Copie só os que fizerem sentido pro stack do projeto — `format-dotnet` num repo
Flutter puro é ruído. Depois de copiar, confirme no painel **Agent Hooks** do
Kiro que o hook aparece habilitado.

## Os guards por-agente (não copiar nada)

`qa-blackbox-guard` (bloqueia leitura de código pelo `qa-blackbox`) e `readonly-guard`
(bloqueia escrita de código por `orchestrator`/`reviewer-spec`/`reviewer-code`/`auditor`)
**já vêm dentro** de `agents/qa-blackbox.md` (e dos 4 `.md` read-only) — são hooks
`preToolUse` embutidos no próprio perfil do agente, instalados automaticamente com ele.
Nenhuma ação extra. São a 2ª camada (best-effort, fail-open, leem `tech.md` em runtime);
a 1ª camada é o bloco `permissions` no mesmo arquivo, aplicado pelo próprio Kiro antes
de qualquer tool rodar — ver comentário `permissions` em cada `agents/*.md`.

## Por que o "command" de cada hook é `bash .kiro/scripts/run-hook.sh <script>.sh`

O Kiro roda o `command` de um hook via `spawn(cmd, {shell:true})`. No Windows isso é
**cmd.exe**, não bash — `$(...)`/aspas aninhadas (a forma antiga, anterior à 1.11) são
sintaxe de bash, e sob cmd.exe simplesmente não resolviam a nada, silenciosamente:
nenhum hook rodava no Windows. `run-hook.sh` existe pra ser a única invocação de shell
no `command` — sem `$()`, sem aninhamento — válida tanto sob cmd.exe (que só encaminha
os argumentos pro `bash.exe` do PATH) quanto sob bash/sh. Ver `scripts/run-hook.sh` e
`hooks/VERIFY.md` §"Windows" para o detalhe verificado no bundle do Kiro.

## Status de verificação

Cada hook aqui foi conferido contra o schema real do Kiro (bundle instalado,
`kiro.kiro-agent/dist/extension.js`) — trigger, formato do `command`, payload de
`preToolUse`. A confirmação **empírica** (rodar num Kiro de verdade e ver o hook
disparar) é outro nível de evidência — ver [`VERIFY.md`](VERIFY.md).
