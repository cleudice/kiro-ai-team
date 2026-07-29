# Contribuindo com o kiro-ai-team

Repo pequeno, regras fortes — quase todas são verificadas mecanicamente pelo CI. Este arquivo evita que você as descubra por CI vermelho.

## Antes de abrir PR

1. **Rode `bash selftest.sh`** — é o mesmo conjunto do CI: sintaxe de todo shell, JSON dos agents/hooks/mcp, frontmatter das skills, links, anti-drift de doc, e as 5 suítes de teste (`tests/`).
2. **`shellcheck -S warning`** em qualquer `.sh` tocado (o CI reprova em warning, não só error).
3. **Mudou comportamento?** (qualquer coisa fora de docs/exemplos/CI): bump de `VERSION` **e** entrada no `CHANGELOG.md` — o job `version-bump` reprova PR sem os dois. O CHANGELOG daqui explica **por que** o bug era um bug e qual garantia furava, não só "fix X"; mantenha o padrão.

## Regras que não são óbvias

- **`agents/*.json` são GERADOS** a partir de `agents/*.md` por `scripts/gen-agent-profiles.sh` — nunca edite o `.json` à mão; edite o `.md` (o formato que o Kiro realmente carrega na IDE) e rode o gerador. O selftest reprova dessincronia.
- **Todo agente/skill/hook novo precisa ser referenciado (entre crases) em `OPERACAO.md`**, e todo fragmento `mcp/*.json` em `mcp/README.md` — anti-drift mecânico.
- **`docs/archive/` só aceita `MIGRATION-v1.md`** — doc histórica nova não entra (é assim que doc derivando em paralelo começou a contradizer o código na v1.5.1).
- **Caminho `.kiro/<x>.sh` citado em prompt/skill/doc** precisa ser algo que `install.sh` de fato instala — o selftest confere.
- Hooks têm triggers **não verificados empiricamente** contra um Kiro real — se você verificar algum, registre o resultado em `hooks/VERIFY.md` (o procedimento está lá).

## Fluxo de mudança vinda de projeto (retrospective)

Regra que a skill `retrospective` gerou num projeto e vale para todos os projetos: abra PR aqui alterando `steering-base/` (a regra sai de `retro-learnings.md` do projeto e vira regra do time). No PR, cite o padrão de falha que a motivou.

## Release

Tag `vX.Y.Z` no commit onde `VERSION` == `X.Y.Z` (o selftest garante VERSION↔CHANGELOG; a correspondência tag↔VERSION é manual — confira antes de taggear). Toda versão com seção no CHANGELOG deve ter tag.
