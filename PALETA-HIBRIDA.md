# Paleta Shadow Materia — versão híbrida (Material 3)

Escolhida em 01/11/2026 para o Nexus Worklog (e depois o site shadow.tec.br): a identidade do Shadow Materia
(grafite quase neutro, `#5294E2` sólido, pastéis do Google) com a **estrutura** do Material 3 (contêineres
sólidos, degraus tonais nomeados, papéis fixos para cada cor, status levemente harmonizados com o azul).
Este arquivo é a referência para atualizar o tema do desktop (Sway, GTK, Qt, rofi, terminal) depois.

Origem e contas: `Site ShadowTec 2/gauntlet-geral/tema/` (paleta-C.css, LEIAME.md, gera_paletas.py,
conceito-C-hibrido.png). Gerada com `material-color-utilities` 0.2.6 a partir da semente `#5294E2`
(HCT H257,3 C50,8 T60,3). Todas as combinações de texto passam WCAG AA (4,5:1; ícones 3:1).

## Escuro (o tema do desktop)

| Papel | Hex | Uso | Hoje no Shadow Materia |
|---|---|---|---|
| fundo (surface) | `#131314` | fundo da janela/tela | `#181818` (rofi base) |
| fundo mais fundo | `#0C0D0E` | atrás de tudo, barra, wallpaper escuro | — |
| lateral | `#161718` | painel lateral, barra | — |
| contêiner | `#1A1A1C` | cartões, campos | `#282828` (surface) |
| contêiner alto | `#222324` | menus, itens destacados | `#333333` (surface2) |
| contêiner mais alto | `#2C2C2D` | avisos (toast), hover forte | — |
| contêiner de destaque | `#262F3C` | faixa/barra com toque azul | — |
| texto | `#F0EDEE` | texto principal | `#dedede` |
| texto secundário | `#ACABAD` | descrições | — |
| texto apagado | `#919093` | rótulos, datas | `#999999` |
| divisor sutil | `#323235` | linhas entre itens | — |
| divisor forte | `#49494B` | bordas de campo | — |
| **primário** | **`#5294E2`** | ação, foco, seleção, workspace ativo | `#5294e2` (igual) |
| primário claro | `#8AB8F0` | links, ícones ativos | `#8ab4f8` |
| texto sobre primário | `#0B0D10` | rótulo do botão azul | — |
| contêiner primário | `#183A61` | item ativo do menu, seleção suave | (antes: azul 16% transparente) |
| secundário | `#3B5170` | barras secundárias, chips neutros | — |
| terciário (roxo) | `#B98EFF` | destaques especiais | `#C58AF9` (pastel Google) |
| ciano | `#62C7E0` | informação | `#5EC8D8` |
| sucesso | `#78CA9F` | ok, concluído | `#81C995` |
| aviso | `#F2DA66` | atenção | `#FDD663` |
| texto de aviso | `#EADDAD` | texto sobre fundo de aviso | — |
| erro | `#F28B82` | erro, urgente | `#f28b82` (igual) |
| texto sobre erro | `#370303` | rótulo do botão de erro | — |
| código | `#D6D4D5` | texto monoespaçado | — |

## Claro

| Papel | Hex | Uso |
|---|---|---|
| fundo | `#FBFAFF` | fundo com um toque de azul (sem virar lavanda) |
| fundo mais fundo | `#E8E8ED` | atrás de tudo |
| lateral | `#F5F4FA` | painel lateral |
| contêiner | `#F0F0F5` | cartões (destacam pelo tom, não pela borda) |
| contêiner alto | `#E9E9EE` | itens destacados |
| contêiner mais alto | `#E0E1E6` | hover forte |
| flutuantes | `#FFFFFF` | menus, avisos, diálogos (mais claros que o fundo) |
| contêiner de destaque | `#D6E3FB` | faixa com azul |
| texto | `#191C20` | texto principal |
| texto secundário | `#43474E` | descrições |
| texto apagado | `#5F636B` | rótulos |
| divisor sutil | `#DFE2EB` | quase invisível |
| divisor forte | `#A8ABB4` | bordas de campo |
| **primário** | **`#1A6AB5`** | o mesmo azul, escurecido só até passar AA (o `#5294E2` puro dá 3,3:1 no branco) |
| primário escuro | `#00569A` | links |
| texto sobre primário | `#FFFFFF` | |
| contêiner primário | `#CFE1FF` | item ativo, seleção |
| secundário | `#A6C3ED` | barras secundárias |
| terciário (roxo) | `#7B51BF` | |
| ciano | `#007286` | |
| sucesso | `#00774F` | |
| aviso | `#776600` | (texto de aviso `#4D4200`) |
| erro | `#B51F21` | |
| código | `#2E3035` | |
| sombra | `#1A1C20` a 14% | leve: a elevação vem do tom |

## Regras da híbrida (para manter ao adaptar cada programa)
1. `#5294E2` é a cor da marca e da ação no escuro; no claro, a ação usa `#1A6AB5` (mesmo matiz).
2. Nada de transparência para fazer cor: usar os contêineres sólidos (ex.: seleção = `#183A61`, não azul 16%).
3. Degraus de superfície regulares: fundo → contêiner → alto → mais alto (e o que flutua é o mais claro no claro).
4. Cada cor tem papel fixo: secundário = neutro azulado; terciário = roxo (destaque especial); status = sucesso/aviso/erro.
5. Status = pastéis do Google girados no máximo 7,5° na direção do azul (o erro fica igual).

## Onde aplicar no desktop (quando for atualizar)
- `home/.config/rofi/themes/shadow-materia.rasi`: base/surface/surface2/fg/fg-dim → fundo/contêiner/contêiner alto/texto/apagado; accent-lt → `#8AB8F0`; seleção com `#183A61`.
- `home/.config/qt6ct/colors/ShadowMateria.conf`: Window/Base/AlternateBase/Highlight/HighlightedText com a tabela escura.
- GTK (Materia), Sway (cores de borda/foco), Waybar, terminal (as 16 cores ANSI: manter os pastéis acima nos "brilhantes" e os
  tons escuros correspondentes nos normais), mako/notificações e o tema do Nexus/site passam a usar os mesmos hex.
