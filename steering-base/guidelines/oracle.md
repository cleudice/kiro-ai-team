---
inclusion: fileMatch
fileMatchPattern: "**/*.sql"
---
# Guidelines Oracle / PL-SQL
- Todo script de alteração (DDL/DML) acompanha script de **rollback** testado.
- Scripts idempotentes quando possível; sempre re-executáveis com segurança.
- Nomes seguem o padrão vigente do schema; nada de objeto novo fora da convenção sem escalar.
- Procedures: tratamento de exceção explícito; sem `WHEN OTHERS THEN NULL`.
- Performance: plano avaliado para query nova em tabela grande; bind variables sempre.
- Alteração em objeto compartilhado (package/procedure usado por múltiplas telas) exige mapeamento de dependentes ANTES do diff.
