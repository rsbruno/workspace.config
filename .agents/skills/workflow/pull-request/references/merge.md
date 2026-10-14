# Merge

`main` é protegida: sem push direto, sem force-push, sem delete. Mesmo o dono faz o merge pela PR (UI ou API) quando `enforce_admins` está ligado. Se o repositório exige aprovações, siga a regra dele; em repositório solo, não há aprovação obrigatória.

Padrão: squash merge, a menos que o usuário peça outro.

```bash
gh pr merge <number> --squash --delete-branch
```

`--delete-branch` mantém a lista de branches limpa: não deixe branches já mergeadas por aí.

## Commits

Conventional Commits, alinhado ao histórico (`git log --oneline`):

- `feat:` nova capacidade
- `fix:` correção de bug
- `docs:` só documentação
- `refactor:` sem mudança de comportamento
- `chore:` ferramental e configuração

Assunto no imperativo, até 50 caracteres. Corpo só se o porquê não estiver claro no diff. Deixe os hooks de pre-commit (formatação, lint) rodarem; não use `--no-verify`.
