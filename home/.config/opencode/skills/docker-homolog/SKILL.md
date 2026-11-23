---
name: docker-homolog
description: Subir, atualizar ou ver logs de projeto em homologação Docker em /srv/docker.
---
# Homologação Docker

Projetos em /srv/docker/<projeto> (hoje: projeto-renata). Fluxo: editar em ~/Claudio/<projeto>, commit/push,
`git pull` em /srv/docker/<projeto> e subir o compose lá. NUNCA subir homolog a partir de ~/Claudio.

Você roda em sandbox SEM acesso ao Docker. Seu papel: ler arquivos, conferir o estado do git e entregar os
comandos prontos pro usuário rodar.

## Roteiro pro usuário
```bash
cd /srv/docker/<projeto>
git status --short        # árvore suja? pare e avise
git pull --ff-only
./deploy.sh               # se existir (faz dump e rollback); senão:
docker compose up -d --build
docker compose ps
docker compose logs --tail=80 <serviço>
```

## Proibido
`docker compose down -v`, `docker volume rm`, `docker system prune`, ler .env, backups/ ou .deploy/ (dados reais).
