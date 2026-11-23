---
description: Commit em pt-BR no padrão do repositório
---
Estado: !`git status --short`
Diff: !`git diff --staged --stat; git diff --staged | head -300`
Últimos commits: !`git log -5 --format=%s`

Carregue a skill git-commit, proponha a mensagem e espere meu OK antes de commitar. $ARGUMENTS
