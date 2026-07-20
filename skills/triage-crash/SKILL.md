---
name: triage-crash
description: Investiga um crash do Crashlytics via MCP firebase (stack trace, volume, versão), localiza o frame suspeito e emite o brief padrão em docs/issues/. Use quando mencionarem crash, Crashlytics, ANR, 'o app caiu/fechou sozinho', ou pedirem para investigar um erro do app em produção.
---
# triage-crash
## Passos
1. Via MCP firebase: coletar stack trace, versão do app, device/OS, volume e tendência do issue de crash.
2. Localizar o frame relevante no código do app; correlacionar com releases recentes.
3. Classificar severidade (volume × impacto) e agrupar duplicatas do mesmo root cause.
4. Emitir brief `docs/issues/CRASH-<id>.md` no formato do triage-issue (`origem: crashlytics`, tipo `manutencao`), com a reprodução hipotética e o frame suspeito.
## Regras
- Saída SEMPRE no formato padrão de brief — o orchestrator não trata crash como caso especial.
- Sem causa raiz clara: registrar hipóteses ranqueadas, não certezas.
