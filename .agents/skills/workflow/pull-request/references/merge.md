# Merge

`main` e `develop` são protegidas: sem push direto, sem force-push, sem delete. Mesmo o dono faz o merge pela PR (UI ou API) quando `enforce_admins` está ligado. Se o repositório exige aprovações, siga a regra dele; em repositório solo, não há aprovação obrigatória.

Padrão: squash merge, a menos que o usuário peça outro.

```bash
gh pr merge <number> --squash
```

A branch sai da `main`, é mergeada na `develop` e depois na `main`, e só morre ao chegar na `main`. Por isso nunca use `--delete-branch`: o workflow de limpeza apaga a branch depois do merge na `main`. Depois disso, atualize a `main` local e apague a branch local.

## Commits

Regras de commit (tipos, assunto, corpo, hooks) vivem na skill `commit`. O agente nunca é autor nem coautor: sem `Co-Authored-By`, sem "Generated with".
