# Merge

`main` é protegida: sem push direto, sem force-push, sem delete. Mesmo o dono faz o merge pela PR (UI ou API) quando `enforce_admins` está ligado. Se o repositório exige aprovações, siga a regra dele; em repositório solo, não há aprovação obrigatória.

Padrão: squash merge, a menos que o usuário peça outro.

```bash
gh pr merge <number> --squash
```

Sem `--delete-branch`: apagar branch é decisão do dev (ou do workflow do repositório depois do merge). O hook `pre-bash-guard.sh` bloqueia essa flag.

## Commits

Regras de commit (tipos, assunto, corpo, hooks) vivem na skill `commit`. O agente nunca é autor nem coautor: sem `Co-Authored-By`, sem "Generated with".
