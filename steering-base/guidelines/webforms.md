---
inclusion: fileMatch
fileMatchPattern: "**/*.aspx*"
---
# Guidelines WebForms (.NET Framework 4.8)
- Prioridade absoluta: não quebrar comportamento existente. Mudança mínima e cirúrgica.
- Antes de editar: mapear postbacks, ViewState, eventos de ciclo de vida e quem mais usa o controle/página.
- ADO.NET: `using` em connection/command/reader; parâmetros sempre (`:param`), string concatenada em SQL é reprovação automática.
- Code-behind: lógica nova extraída para classes testáveis; não engordar o `.aspx.cs`.
- Session/ViewState: registrar no PR qualquer chave nova ou alterada.
- Compatibilidade: nada de sintaxe/APIs além do C# 7.3 / .NET 4.8.
