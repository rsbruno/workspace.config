---
name: pre-review
description: Code review rigoroso do que está na worktree pronto pra commit, e correção automática do que for mecânico. Roda inteiro num subagente Sonnet pra ficar barato sem perder achado real — o modelo principal só despacha e repassa o resultado. Detecta sozinha se a mudança é front (`<repo-web>`) ou back (`<repo-api>`), que são repos git separados, e aplica as regras do lado correspondente (`/pagina` e `/componente` no front, `/modulo` e `AGENTS.md` no back). Procura violação de padrão, arquivo/código morto, lógica mal resolvida e duplicação de helper/componente/schema/constante; corrige o que é mecânico e reporta o que exige decisão. NUNCA roda lint, prettier, build, tsc, teste, migration ou servidor. NÃO é auto-invocável — só usar quando o usuário mencionar explicitamente esta skill/o comando `/pre-review`, ou pedir review do que está pra commitar.
---

# pre-review

**O modelo principal não faz o review.** Ele só despacha um subagente Sonnet e repassa o resultado. Não leia diff, não leia arquivo, não rode grep aqui — é isso que torna a skill cara.

## Execução

Chame o `Agent` **uma vez**, com `subagent_type: "general-purpose"`, `model: "sonnet"`, `run_in_background: false`, e este prompt (ajuste o alvo conforme o que o usuário pediu — front, back, ou os dois):

> Você é revisor de código deste monorepo. Faça o review do que está na worktree e corrija o que for mecânico.
>
> **Alvo:** `<<repo-web> | <repo-api> | ambos>`. Raiz do monorepo: `<caminho absoluto>`.
>
> **Passo 1 — leia as regras.** Leia `.claude/skills/pre-review/checklist.md`. Ele tem o procedimento de coleta, os checklists por lado, o que corrigir sozinho e o formato de saída. Siga à risca.
>
> **Passo 2 — colete, analise, corrija, relate.** Máximo de 6 chamadas de ferramenta no total. Se estourar, entregue o que tiver.
>
> **Proibido, sem exceção:** lint, eslint, prettier, build, tsc, teste, `db:push`, migration, seed, servidor de dev. Só leitura, grep, git e edição de arquivo.
>
> Devolva o relatório no formato exato da seção "Saída" do checklist.

Se o usuário pediu os dois lados e os dois repos têm mudança, ainda assim **um subagente só** — não paralelize, o custo dobra sem ganho.

## Depois que o subagente responder

Repasse ao usuário **só o que é acionável**, sem reescrever nem reanalisar:

- os achados corrigidos (arquivo + o que mudou, uma linha cada),
- os achados 🔴/🟡 que ficaram pendentes, com motivo de não terem sido corrigidos,
- o veredito.

**Corte tudo que não muda a ação do usuário**: "fora do escopo" sem achado real dentro, arquivo/trecho que o subagente disse ter pulado mas que não importava, confirmação de coisa que está OK, a lista de comandos não-rodados (isso já é regra fixa da skill, não precisa repetir toda vez), narrativa de quantas chamadas usou. Achado 🔵 opinião só entra se for genuinamente útil — não liste por completude.

Se o subagente marcou algo como "fora do escopo" por ter cortado o diff, e esse arquivo é sensível (auth, pagamento, escrita em banco), confira você mesmo antes de aceitar o veredito — não repasse "não vi essa parte" como se fosse aprovação.

Se o subagente devolveu algo claramente errado (arquivo que não existe, achado sem evidência), diga isso em vez de repassar como verdade.
