---
name: git-commit
description: Fazer commit, escrever mensagem de commit, preparar push, revisar o que mudou no git.
---
# Commit no padrão do usuário

1. `git status --short` e `git diff --staged` (ou `git diff` se nada estiver staged).
2. Adicione arquivos PELO NOME. Nunca `git add -A` se houver .env, dados, backups ou binários grandes.
3. Mensagem em pt-BR, no padrão do repositório (veja `git log -5 --format=%B`):
   - título "Área: o que mudou" (até 72 caracteres)
   - linha em branco, depois tópicos "- " explicando o porquê
   - última linha: `Co-Authored-By: Qwen local <noreply@localhost>`
4. Escreva a mensagem num arquivo e use `git commit -F /tmp/msg.txt` (evita problema de aspas).
5. Mostre a mensagem e espere o OK antes de commitar.
6. `git push` é SEMPRE com o usuário (você não tem chave SSH). Nunca `--force`.
