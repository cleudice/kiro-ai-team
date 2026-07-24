# Verificação empírica dos hooks (B3)

O `selftest.sh` só confere que cada `hooks/*.json` é JSON válido — nada aqui garante
que o Kiro de fato reconhece o `trigger` declarado, dispara a `action` ou lê o
arquivo no formato esperado. `PostTaskExec` em particular não aparece em nenhuma
documentação pública do Kiro no momento em que este arquivo foi escrito. Toda a
alegação de "mecaniza a disciplina humana" (hooks `task-checkpoint`,
`preflight-branch`, `issue-intake`, `format-*`) depende de os triggers realmente
funcionarem — este documento é o procedimento pra provar isso uma vez, num Kiro
real, e registrar o resultado.

## Procedimento

1. Instalar `hooks/_canary.json` num projeto de teste (`cp hooks/_canary.json <projeto>/.kiro/hooks/`) — **nunca instalar isto num projeto real via `install.sh`**, é só instrumentação.
2. Abrir o painel "Agent Hooks" no IDE/CLI do Kiro e confirmar que os 4 hooks (`_canary-postfilesave`, `_canary-postfilecreate`, `_canary-sessionstart`, `_canary-posttaskexec`) aparecem listados e habilitados.
3. Disparar cada trigger manualmente:
   - `PostFileSave`: salvar qualquer arquivo.
   - `PostFileCreate`: criar um arquivo novo.
   - `SessionStart`: abrir uma sessão/aba nova de chat.
   - `PostTaskExec`: marcar uma task `[x]` via "Start task" numa spec de teste.
4. Conferir quais `.kiro/hooks/.fired-<trigger>` foram gravados (com timestamp UTC).
5. Preencher a tabela abaixo com o resultado real — **isto é registro empírico, não previsão**.
6. Trigger que NÃO disparou: remover o hook correspondente do central (`hooks/*.json`) ou rebaixar a doc que promete "mecaniza X" pra "tentativa best-effort" em `OPERACAO.md` §1.2/§2 e no `CHANGELOG.md`.
7. Apagar `_canary.json` e os `.fired-*` do projeto de teste ao final — não é pra ficar instalado em lugar nenhum.

## Resultado (preencher após rodar o passo 1–5 num Kiro real)

| Trigger                   | Usado por                                                   | Verificado em (data, versão do Kiro)                                                                                                                                              | Resultado             |
| ------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| `PostFileSave`            | `format-dotnet`, `format-flutter`, `format-oracle`          | _pendente_                                                                                                                                                                        | _pendente_            |
| `PostFileCreate`          | `issue-intake`                                              | _pendente_                                                                                                                                                                        | _pendente_            |
| `SessionStart`            | `preflight-branch`                                          | _pendente_                                                                                                                                                                        | _pendente_            |
| `PostTaskExec`            | `task-checkpoint`                                           | _pendente_                                                                                                                                                                        | _pendente_            |
| `preToolUse` (por-agente) | `qa-blackbox-guard` (embutido em `agents/qa-blackbox.json`) | já documentado como best-effort/falha-aberto em `steering-base/quality-gates.md` — não precisa deste procedimento, contrato de payload já é tratado como não confiável por design | best-effort conhecido |

Enquanto a linha de um trigger estiver `_pendente_`, trate a doc correspondente
("mecaniza automaticamente") como não confirmada — a fonte da verdade continua
sendo o passo manual descrito em `skills/task-preflight/SKILL.md` e nos prompts
dos agentes.
