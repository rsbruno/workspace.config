# PR title and body

## Title

```text
[TIPO][FE|BE][branch-name][CARD]: breve descrição do que é
```

- **TIPO**: uppercase, using the same vocabulary as the commit: `FEAT`, `FIX`, `DOCS`, `REFACTOR`, `CHORE`.
- **FE/BE**: use `FE` for UI and everything the user sees (pages, components, styles, and assets). Use `BE` for API, infrastructure, build, CI, and deploy. If the change touches both, use the side that represents most of the diff.
- **branch-name**: the real branch name, written in uppercase in the title without shortening it; the branch itself remains lowercase.
- **CARD**: uppercase and included only when a ticket exists (Linear, Jira, or another issue tracker). Without a card, omit the entire block; never leave empty brackets.
- **General rule**: every text inside brackets is uppercase, without exception.
- **Description**: lowercase, direct, and without a final period.

```text
[FIX][FE][FIX/COOKIE-TOGGLE-DEFAULT]: switches de cookie marcados por padrão
[DOCS][FE][DOCS/README]: reescreve README com stack, envs e proteção da main
[CHORE][BE][CHORE/DEPLOY-CACHE][PRJ-42]: cacheia store de dependências no workflow de deploy
```

## Body

Answer three questions in this order: O quê, Por quê, Como. Each section must contain real information or must be omitted.

```bash
git push -u origin <type>/<slug>
gh pr create --base <target-branch> --title "[TIPO][FE|BE][<TYPE>/<SLUG>][CARD]: <descrição>" --body "$(cat <<'EOF'
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

- `--assignee` is mandatory. In a solo repository, use the repository owner.
- Include the `<details>` block only when there was a real trade-off.
- `--base` is mandatory and must point to the development branch defined by the flow. Never use `main` as this skill's target.

## Attribution

The PR body must never end with "Generated with Claude Code", 🤖, or any mention of the agent. If attribution seems necessary, ask the developer before continuing.
