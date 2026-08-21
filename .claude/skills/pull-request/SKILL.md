---
name: pull-request
description: Standardized workflow for branching, committing, and opening pull requests against main in this repo (rsbruno/portfolio.lp). Use whenever asked to "subir", "abrir PR", "criar PR", push changes, or ship work — main is protected and rejects direct pushes. NOT auto-invocable — only use when the user explicitly mentions this skill/asks to ship, or another skill calls into it; never invoke on inference alone.
---

# Open PR

`main` on `rsbruno/portfolio.lp` is branch-protected: no force-push, no delete, no direct push. Every change lands through a pull request. This skill is the fixed path for that, so PRs stay consistent whether it's a docs tweak or a feature.

## 1. Branch

Never commit on `main`. Branch name: `<type>/<short-slug>`, type matches the commit type below (e.g. `fix/cookie-toggle-default`, `docs/readme`, `feat/cases-de-sucesso-nav`).

```bash
git checkout -b <type>/<slug>
```

## 2. Commit

Conventional Commits, matches this repo's existing history (`git log --oneline`):

- `feat:` new capability
- `fix:` bug fix
- `docs:` docs only
- `refactor:` no behavior change
- `chore:` tooling/config

Subject imperative, ≤ 50 chars. Body only if the *why* isn't obvious from the diff. Husky pre-commit already runs prettier + eslint on `.astro` files — let it run, don't `--no-verify`.

Author is always `rsbruno` (git config + `gh` auth already point there) — no `Co-Authored-By` trailer on commits or PRs in this repo.

## 3. Push + PR

### Title

Fixed shape, no exceptions:

```
[TIPO][FE|BE][branch-name][CARD]: breve descrição do que é
```

- **TIPO** — caixa alta, mesmo vocabulário do commit: `FEAT` `FIX` `DOCS` `REFACTOR` `CHORE`.
- **FE/BE** — `FE` para tudo em `src/`, `public/`, config de UI (Tailwind, Astro components); `BE` para infra/build/CI (`.github/workflows`, `astro.config.mjs`, deploy). Este repo é majoritariamente `FE` — só é `BE` quando a mudança é de pipeline/infra, não de tela.
- **branch-name** — o nome real da branch (`fix/cookie-toggle-default`), sem abreviar.
- **CARD** — caixa alta, só entra se existir ticket (Linear/Jira/issue). Sem card, o bloco some inteiro — não deixa `[]` vazio.
- Descrição — minúscula, direta, sem ponto final.

```
[FIX][FE][fix/cookie-toggle-default]: switches de cookie marcados por padrão
[DOCS][FE][docs/readme]: reescreve README com stack, envs e proteção da main
[CHORE][BE][chore/deploy-cache][LP-42]: cacheia pnpm store no workflow de deploy
```

### Body

Três perguntas, nessa ordem — o quê, por quê, como. Nada de emoji em cabeçalho, nada de checklist genérica de "Changes"; cada seção carrega informação real ou não existe.

```bash
git push -u origin <type>/<slug>
gh pr create --title "[TIPO][FE|BE][<type>/<slug>][CARD]: <descrição>" --body "$(cat <<'EOF'
### O quê

<1–2 frases, direto — o que mudou, sem narrar o diff arquivo por arquivo.>

### Por quê

<problema resolvido ou feature entregue. Se houver issue: Closes #42.>

### Como

<decisão técnica relevante — só o que não é óbvio olhando o diff.>

<details>
<summary>Alternativas descartadas</summary>

- <opção considerada e por que foi descartada — omite a seção inteira se não houve trade-off real>

</details>

---

**Test plan**
- [ ] <como foi/deve ser verificado — pnpm build, checagem manual no navegador, etc.>
EOF
)" --assignee rsbruno
```

`--assignee rsbruno` é fixo, sempre — repo é solo, PR sem assignee é PR órfão.

O bloco `<details>` de alternativas só entra quando existiu de fato uma decisão com trade-off — não é preenchimento obrigatório. Base é sempre `main` (default do repo, não precisa `--base`).

## 4. Merge

This is a solo-owner repo — no required approvals, but `enforce_admins` is on, so even the owner merges through the PR UI/API, never a direct push. Default: squash merge, unless the user asks otherwise.

```bash
gh pr merge <number> --squash --delete-branch
```

`--delete-branch` keeps the branch list matching the "only main exists" convention already in place — don't leave merged branches around.

## When not to use this

Read-only exploration, or the user explicitly says to just commit locally without pushing.
