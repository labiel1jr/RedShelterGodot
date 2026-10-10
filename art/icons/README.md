# Ícone do Red Shelter — briefing para os artistas

Esta pasta é o projeto dos ícones do jogo (Android e Windows). Entregue os
arquivos com **exatamente** os nomes e as pastas abaixo: o jogo os usa
direto, sem renomear.

Especificação completa: catálogo de assets
([`docs/assets/asset_list.json`](../../docs/assets/asset_list.json),
categoria `branding`) e GDD, seção 65 "Ícone do jogo"
([`docs/GDD.md`](../../docs/GDD.md)).

## Conceito

**O abrigo vermelho**: silhueta de casa/barracão com tábuas pregadas e a
porta acesa com luz quente, sobre fundo carvão.

- Estilo **toon / cel-shading**: luz em 3 faixas chapadas (luz, meio-tom,
  sombra), contorno grosso escuro, sem degradê suave.
- Cores: vermelho do abrigo `#D2382F`, contorno `#16141F`, fundo carvão
  `#16141F` → cinza-azulado escuro `#2B2E38`, luz da porta âmbar `#F2CC4D`.
- **Sem texto**, **sem personagem** (ainda não definida) e sem zumbi
  explícito; no máximo silhuetas de prédios ou de mãos ao fundo.
- Tem que ser reconhecível reduzido a **48 px**.
- Duas propostas para escolha: **A** abrigo de frente com tábuas e porta
  acesa; **B** abrigo em perspectiva com a cidade escura atrás.

## Moldes

| Arquivo | Uso |
| --- | --- |
| `templates/master_guide_1024.svg` | arte-mestra 1024 × 1024, com as camadas FUNDO, FRENTE e MONOCROMATICO e a zona segura |
| `templates/android_adaptive_guide_432.svg` | ícone adaptativo Android: zona segura de 264 px e os recortes do sistema |

Apague a camada de guias antes de exportar.

## O que entregar

| Pasta / arquivo | Tamanho | Observação |
| --- | --- | --- |
| `source/icon_master.svg` (ou `.kra` / `.ai`) | 1024 × 1024, vetor | com as camadas FUNDO, FRENTE e MONOCROMATICO |
| `icon_master_1024.png` (nesta pasta) | 1024 × 1024 | exportação da arte-mestra |
| `android/icon_foreground_432.png` | 432 × 432 | só a FRENTE, fundo transparente, tudo dentro do círculo de 264 px |
| `android/icon_background_432.png` | 432 × 432 | só o FUNDO, opaco, preenchendo tudo |
| `android/icon_monochrome_432.png` | 432 × 432 | silhueta branca, fundo transparente (ícones temáticos do Android 13) |
| `android/icon_main_192.png` | 192 × 192 | fundo + frente juntos, cantos arredondados (Androids antigos) |
| `windows/icon.ico` | 16, 24, 32, 48, 64, 128 e 256 px | um .ico com todos os tamanhos; 16 e 24 **redesenhados** (só a silhueta e a porta) |
| `windows/icon_512.png` | 512 × 512 | ícone do projeto (janela e barra de tarefas) |
| `store/play_icon_512.png` | 512 × 512 | **depois**: Play Store, sem transparência |
| `store/feature_graphic_1024x500.png` | 1024 × 500 | **depois**: banner da loja, com o logotipo RED SHELTER |

Todos os PNG em RGBA 8 bits por canal (32 bits), sRGB.

## Como conferir antes de entregar

1. Reduza o ícone a 48 px e a 16 px: ainda dá para ver que é um abrigo?
2. No molde Android, recorte em círculo e em quadrado arredondado: nada
   importante foi cortado?
3. Veja o monocromático em fundo claro e escuro.
