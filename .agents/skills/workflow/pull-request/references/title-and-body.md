# PR title and body

## Title

```
[TIPO][FE|BE][branch-name][CARD]: breve descrição do que é
```

- **TIPO**: caixa alta, mesmo vocabulário do commit: `FEAT` `FIX` `DOCS` `REFACTOR` `CHORE`.
- **FE/BE**: `FE` para UI e tudo que o usuário vê (páginas, componentes, estilos, assets). `BE` para API, infra, build, CI e deploy. Se a mudança toca os dois, use o lado que concentra a maior parte do diff.
- **branch-name**: o nome real da branch, sem abreviar.
- **CARD**: caixa alta, só entra se existir ticket (Linear, Jira, issue). Sem card, o bloco some inteiro: nunca deixar `[]` vazio.
- **Descrição**: minúscula, direta, sem ponto final.

```
[FIX][FE][fix/cookie-toggle-default]: switches de cookie marcados por padrão
[DOCS][FE][docs/readme]: reescreve README com stack, envs e proteção da main
[CHORE][BE][chore/deploy-cache][PRJ-42]: cacheia store de dependências no workflow de deploy
```

## Body

Três perguntas, nessa ordem: o quê, por quê, como. Cada seção carrega informação real ou não existe.

```bash
git push -u origin <type>/<slug>
gh pr create --title "[TIPO][FE|BE][<type>/<slug>][CARD]: <descrição>" --body "$(cat <<'EOF'
### O quê

<1–2 frases, direto: o que mudou, sem narrar o diff arquivo por arquivo.>

### Por quê

<problema resolvido ou feature entregue. Se houver issue: Closes #42.>

### Como

<decisão técnica relevante: só o que não é óbvio olhando o diff.>

<details>
<summary>Alternativas descartadas</summary>

- <opção considerada e por que foi descartada. Omite a seção inteira se não houve trade-off real.>

</details>

---

**Test plan**
- [ ] <como foi/deve ser verificado: build, testes, checagem manual no navegador>
EOF
)" --assignee <github-user>
```

- `--assignee` é fixo e sempre presente. Em repositório solo, é o próprio dono.
- O bloco `<details>` só entra quando existiu uma decisão com trade-off de fato.
- A base é sempre `main` (default do repositório, não precisa `--base`).
