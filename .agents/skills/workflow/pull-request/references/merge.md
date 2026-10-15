# Merge

`main` é protegida: sem push direto, sem force-push, sem delete. Mesmo o dono faz o merge pela PR (UI ou API) quando `enforce_admins` está ligado. Se o repositório exige aprovações, siga a regra dele; em repositório solo, não há aprovação obrigatória.

Padrão: merge comum (commit de merge), a menos que o usuário peça outro ou o repositório só permita squash. O título do commit de merge é o título do PR, por isso ele precisa seguir o formato.

```bash
gh pr merge <number> --merge
```

Sem `--delete-branch`: apagar branch é decisão do dev (ou do workflow do repositório depois do merge). O hook `pre-bash-guard.sh` bloqueia essa flag.

## Commits

Regras de commit (tipos, assunto, corpo, hooks) vivem na skill `commit`. O agente nunca é autor nem coautor: sem `Co-Authored-By`, sem "Generated with".
