# Copy obrigatória de telas e campos

## Ações

No objeto `actions` da tela, preserve exatamente estas propriedades e strings:

```json
{
  "archive": "Arquivar",
  "delete": "Excluir",
  "restore": "Restaurar",
  "create": "Cadastrar"
}
```

No create e no edit, o submit fica em `actions.submit`:

```json
{
  "create": { "actions": { "submit": "Cadastrar" } },
  "edit": { "actions": { "submit": "Salvar alterações" } }
}
```

## Confirmações

As confirmações ficam em `confirm`, com essa grafia exata, e nunca em outro namespace ou em `table.actions`:

```json
{
  "confirm": {
    "archive": {
      "title": "Arquivar",
      "description": "Deseja arquivar este <nome da entidade>? <consequências breves>. Esta ação pode ser revertida posteriormente.",
      "confirm": "Sim, arquivar!",
      "cancel": "Não, manter."
    },
    "restore": {
      "title": "Restaurar",
      "description": "Deseja restaurar este <nome da entidade>? <consequências breves>.",
      "confirm": "Sim, restaurar!",
      "cancel": "Não, manter."
    },
    "delete": {
      "title": "Excluir",
      "description": "Deseja excluir este <nome da entidade>? <consequências breves>. Esta ação pode ser revertida posteriormente.",
      "confirm": "Sim, excluir!",
      "cancel": "Não, manter."
    }
  }
}
```

A descrição fala da entidade, não de um registro técnico, e deve refletir a consequência verdadeira. Consulte requisito, documentação e backend. Se a consequência não estiver clara, pergunte ao usuário ou ao dev antes de criar ou alterar a string.

## Campos

Todo `form.fields.<field>` contém `label` e `placeholder`. Adicione `hint` quando houver regra de negócio, automação ou relação dependente para explicar.

- `label`: nome curto e direto do campo, usando o termo de negócio.
- campo de texto: `Informe o <nome do campo>`.
- seleção única: `Selecione o <nome do campo>`.
- seleção múltipla: `Selecione os <nome dos campos>`.
- não use strings visíveis hardcoded nos componentes.
