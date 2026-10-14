# Árvore obrigatória de locale de tela

Toda tela nova ou alteração de locale de tela usa esta estrutura em `pages.json`. A estrutura é fixa e não pode ser alterada sem perguntar ao usuário.

```json
{
  "groups": {
    "meta": {
      "title": "Nome da página, sem o nome do sistema"
    },
    "title": "Nome direto exibido no header",
    "subtitle": "Descrição curta do contexto da página",
    "actions": {
      "archive": "Arquivar",
      "delete": "Excluir",
      "restore": "Restaurar",
      "create": "Cadastrar"
    },
    "toolbar": {
      "search": {
        "placeholder": "Pesquise por <nome dos filtros tratados>"
      }
    },
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
    },
    "dialog": {
      "filter": {
        "fields": {
          "archived": {
            "label": "Nome do campo",
            "placeholder": "Selecione|Digite o(a) <nome do campo>"
          }
        }
      }
    },
    "table": {
      "empty": "Nenhum <nome da tela ou termo de domínio> encontrado.",
      "columns": {
        "name": "Nome das colunas da tabela"
      }
    },
    "create": {
      "meta": {
        "title": "Nome da página de criação, sem o nome do sistema"
      },
      "title": "Nome direto exibido no header",
      "subtitle": "Descrição curta do contexto da criação",
      "actions": {
        "submit": "Cadastrar"
      },
      "toast": {
        "success": "<nome da entidade> cadastrado."
      }
    },
    "edit": {
      "meta": {
        "title": "Nome da página de edição, sem o nome do sistema"
      },
      "title": "Nome direto exibido no header",
      "subtitle": "Descrição curta do contexto da edição",
      "actions": {
        "submit": "Salvar alterações"
      },
      "toast": {
        "success": "<nome da entidade> atualizado."
      }
    },
    "toast": {
      "archive-success": "<nome da entidade> arquivado.",
      "delete-success": "<nome da entidade> excluído.",
      "restore-success": "<nome da entidade> restaurado."
    },
    "not-found": {
      "title": "<nome da entidade> não encontrado.",
      "description": "<nome da entidade> não existe ou foi removido.",
      "back-to-list": "Voltar para <nome da tela>"
    },
    "sections": {
      "name": "Nome da seção"
    },
    "form": {
      "fields": {
        "code": {
          "label": "Nome do campo",
          "placeholder": "Selecione|Digite o(a) <nome do campo>",
          "hint": "Mensagem sobre a regra de negócio quando necessário"
        }
      }
    }
  }
}
```

`confirm` é grafado exatamente assim por decisão do projeto. `dialog.filter` é o único caminho do diálogo de filtros. A ação de criação da toolbar fica em `actions.create`, e os submits ficam em `create.actions.submit` e `edit.actions.submit`.
