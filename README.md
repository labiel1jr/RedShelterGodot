# RED SHELTER — Protótipo em Godot 4

> **Corra pela cidade, enfrente os mortos, saqueie o que conseguir e
> transforme um pequeno esconderijo no último lugar seguro do mundo.**

Survival runner mobile com abrigo. A sobrevivente corre sozinha por três
faixas, desvia, pula, desliza, luta contra zumbis que a agarram e saqueia o
que consegue carregar. De volta ao abrigo, os recursos viram construções,
armas e moradores, e a cada semana uma horda ataca o portão. É o protótipo
jogável do **GDD 0.6.4** (`../Red Shelter.MD`), feito com formas primitivas.
Cenas e dados são texto puro (`.tscn` / `.tres`) e abrem direto no editor.

| | |
| --- | --- |
| **Engine** | Godot 4.7 · GDScript · renderer Mobile |
| **Plataformas-alvo** | Android / iOS (testado no PC com teclado e mouse) |
| **Estado** | Fases 1–12 concluídas · 13 e 14 planejadas |
| **Próximo** | Fase 13 — Veículos, depois Fase 14 — Power-ups; em paralelo, jogar, balancear e trocar as primitivas por arte ([próximos passos](#próximos-passos)) |

## Índice

- [Como abrir e rodar](#como-abrir-e-rodar)
- [Como jogar](#como-jogar)
- [Status do roadmap](#status-do-roadmap)
- [Cenas e fluxo](#cenas-e-fluxo)
- [Expedição](#expedição)
- [Combate](#combate)
- [Abrigo](#abrigo)
- [Moradores](#moradores)
- [Defesa do abrigo](#defesa-do-abrigo)
- [Progressão da personagem](#progressão-da-personagem)
- [Interface, áudio e desempenho](#interface-áudio-e-desempenho)
- [Balanceamento](#balanceamento)
- [Como estender](#como-estender)
- [Arquitetura e dados](#arquitetura-e-dados)
- [Save e configurações](#save-e-configurações)
- [Próximos passos](#próximos-passos)
- [Problemas conhecidos](#problemas-conhecidos)

Os números entre parênteses nos títulos, como "(seção 24)", apontam para a
seção do GDD.

## Como abrir e rodar

1. Abra o **Godot Engine 4.7**.
2. `Import` → selecione o `project.godot` desta pasta → `Import & Edit`.
3. Dê Play (▶ no topo ou F5). A cena inicial é `scenes/main_menu.tscn`.

Para checar pelo terminal se o projeto importa sem erros (sem abrir a
janela):

```bash
godot --headless --path . --import
```

## Como jogar

Cada expedição é um dia:

1. **No abrigo**, construa, melhore armas e cuide dos moradores. Depois abra
   **Expedição**: escolha região, distância e as armas (uma branca e uma de
   fogo).
2. **Na rua**, a personagem corre sozinha. Desvie, pule, deslize, atire,
   use a arma branca em quem agarrar e pegue o loot que couber na mochila.
   Nas bifurcações, a faixa em que você estiver escolhe o caminho.
3. **Chegue à EXTRAÇÃO** para voltar com tudo. Morrer faz perder metade do
   loot (que fica numa mochila no local, para buscar depois) e deixa a
   personagem ferida. Construções, armas e XP nunca se perdem.
4. **No fechamento do dia**, o abrigo produz, todos comem e a moral muda.
   Comida e água acabando enfraquecem a próxima corrida.
5. **A cada 9 dias** (o primeiro no dia 8), uma horda ataca o abrigo. Nesse
   dia, é preciso defender o portão antes de sair de novo.

| Ação | Celular | Teclado / mouse |
| --- | --- | --- |
| Trocar de faixa | swipe ← → | A/D ou setas ← → |
| Pular | swipe ↑ | Espaço ou ↑ |
| Deslizar | swipe ↓ | Ctrl ou ↓ |
| Atirar (arma de fogo) | toque curto | clique ou K |
| Arma branca (ataque de emergência) | botão **ATACAR** | F ou J |
| Kit médico (Enfermaria nv 2) | botão **KIT** | H |
| Pausa | botão **II** | Esc ou P |

Dicas curtas aparecem uma única vez, na hora certa (tutorial). Elas podem ser
desligadas ou reexibidas em **Configurações**.

## Status do roadmap

Seção 58 do GDD. As Fases 1 a 12 estão concluídas; as Fases 13 e 14 estão planejadas.

| Fase | Conteúdo |
| --- | --- |
| 1 — Protótipo | corrida, 3 faixas, obstáculos, HP, zumbi, agarrão, faca |
| 2 — Procedural | chunks, rota, seed, loot, spawning, streaming |
| 3 — Combate | pistola, faca, tipos de zumbi, dano, efeitos, animações |
| 4 — Abrigo | construção, recursos, oficina, upgrades, inventário, save |
| 5 — Progressão | XP, níveis, atributos, perks |
| 6 — Conteúdo | Centro e Zona Industrial, Explosivo e Blindado, eventos, sobreviventes |
| 7 — Polimento | UI, áudio, VFX, otimização, tutorial, balanceamento |
| 8 — Economia do abrigo | componentes, medicamentos, combustível, moral, cozinha, enfermaria, painéis, baterias, rádio |
| 9 — Mundo | Mercado, Hospital, locais especiais, distância Especial, voltar ao local da morte |
| 10 — Expedição viva | bifurcações, extração antecipada, Expedition Director, escopeta, SMG, facão, machado, katana, machado pesado |
| 11 — Pessoas | traços de personalidade, afinidade, pedidos dos moradores |
| 12 — Defesa | ataques ao abrigo, portão, barricadas, armadilhas, torres |
| 13 — Veículos 🟡 V1–V3 | patins, skate, bicicleta de jornaleiro, moto, mochila a jato e furgão de destruição, cada um com HP e habilidade (seção 63) |
| 14 — Power-ups 📋 | 14 power-ups nos papéis dos de Subway Surfers: 5 na pista, 1 consumível, 2 na preparação e 6 raros (seção 64) |

## Cenas e fluxo

Seção 48 do GDD: **Menu → Abrigo → Expedição → Extração → Abrigo**. Na
morte: **Expedição → Resultado → Abrigo**. No dia do ataque: **Abrigo →
Defesa → Abrigo**. Há um fade em toda troca de cena.

| Cena | O que tem |
| --- | --- |
| **Menu** (`scenes/main_menu.tscn`) | Continuar (dia N), Novo Jogo (pede confirmação e apaga o save), Configurações e Sair. |
| **Abrigo** (`scenes/shelter.tscn`) | O abrigo em 3D, onde cada construção aparece quando é feita e os moradores ficam na sala. Duas barras de recursos no alto. Botões **Construir**, **Oficina**, **Sobrevivente** (nível, atributos, perks, saúde, moral e moradores; fica amarelo com pontos para gastar) e **Expedição** (região, distância, armas e voltar ao local da morte). O campo **Seed** repete uma expedição (vazio = aleatória). Na volta, o loot cai no depósito e aparece o **fechamento do dia**. |
| **Expedição** (`scenes/run.tscn`) | A pista montada por chunks a partir da seed. O HUD mostra região e distância, HP (Normal/Ferido/Crítico), loot, peso da mochila, arma de fogo e munição, arma branca e durabilidade, ruído, XP se extrair agora, a seed com a fase do Director e os botões ATACAR, KIT e pausa. |
| **Resultado** (`scenes/result.tscn`) | Só na morte: seed, distância, recursos obtidos e recuperados, e onde ficou a mochila. |
| **Defesa** (`scenes/defense.tscn`) | O ataque ao abrigo (ver [Defesa do abrigo](#defesa-do-abrigo)). O resultado aparece na própria cena. |

## Expedição

### Geração procedural (seções 19–23 e 51)

- **Região** (`RegionData`, em `data/regions/`): chunk inicial, chunk de
  extração, chunks do meio, padrões de gameplay, pesos do loot, tipos de
  zumbi, eventos, locais especiais e, se quiser, obstáculos próprios.
- **Rota** (`scripts/expedition/route_generator.gd`): começa na entrada da
  região. Os chunks do meio são sorteados pela seed, por peso e sem repetir
  o anterior, até cobrir a distância. No caminho entram eventos, locais
  especiais e bifurcações, e a rota termina na Extração. Mesma seed + mesma
  região + mesma distância = mesma rota e mesmo conteúdo.
- **Chunks artesanais** (`scenes/chunks/*.tscn` + `data/chunks/*.tres`): cada
  um traz a estrutura e a ambientação (camadas 1 e 4 da seção 21) e um nó
  **Rows** com `Marker3D`s. Em cada marcador, o `ChunkPopulator` aplica um
  padrão (camadas 2 e 3).

| Região | Chunks |
| --- | --- |
| Bairro | Saída do abrigo, Rua residencial, Avenida, Beco (`W.W` e `L.L` fixos), Supermercado, Estacionamento, Posto, Parque, Cruzamento, Extração |
| Mercado | Entrada, Hipermercado, Feira livre, Galeria (`H.H` fixo), Docas de carga, mais o Supermercado e o Estacionamento do Bairro |
| Centro | Entrada, Praça, Rua de lojas, Loja de departamentos, Engarrafamento, mais a Avenida e o Cruzamento |
| Hospital | Entrada, Pronto-socorro, Triagem, Corredor (paredes coladas, `L.H` e `H.L` fixos), Pátio interno, mais a Avenida |
| Zona Industrial | Portão, Fábrica, Pátio de contêineres, Ferrovia, Galpões, mais o Estacionamento |

**Padrões** (lista `patterns` da região): um caractere por faixa, da
esquerda para a direita.

| Símbolo | Significado |
| --- | --- |
| `.` | vazio |
| `W` | parede — trocar de faixa |
| `L` | barreira baixa — pular |
| `H` | barra alta — deslizar |
| `$` | loot (tipo sorteado pelos pesos da região ou do chunk) |
| `Z` | zumbi |
| `R` | baú de recurso raro (evento ou local especial) |
| `S` | sobrevivente pedindo socorro |

- **Validação:** todo padrão precisa de ao menos uma faixa passável sem
  lutar (`.` `$` `L` `H` `R` `S`). Padrões inválidos são rejeitados com erro
  no console.
- **Padrão fixo:** um `Marker3D` com o metadado `pattern` força um padrão.
- **Ajustes por chunk:** o `ChunkData` pode aumentar a chance de padrões com
  loot ou zumbi e trocar os pesos do loot.
- **Streaming:** ficam carregados só os chunks até 120 m à frente e 30 m
  atrás, no máximo 1 carregado por frame. Obstáculos e loot são liberados
  junto com o chunk. A neblina esconde os que estão carregando, e o chão de
  física é um plano infinito, sem emendas.

### Regiões e distâncias (seções 25 e 28)

O mundo fica em `data/world.tres` (`WorldData`).

| Região | Libera | Dificuldade | Destaques |
| --- | --- | --- | --- |
| Bairro | nível 1 | 1 | comida, água, materiais básicos |
| Mercado | nível 3 | 2 | muita comida e água, componentes; grupos de zumbis comuns; obstáculos de carrinhos, gôndolas e cartazes |
| Centro | nível 4 | 3 | +1 em cada loot; runners e explosivos |
| Hospital | nível 6 | 4 | medicamentos (+1 em cada loot); muitos runners e explosivos; mais pulos e deslizes; obstáculos de macas, armários e cortinas |
| Zona Industrial | nível 7 | 5 | muita sucata e componentes; brutos e blindados |

Os obstáculos próprios do Mercado e do Hospital têm a mesma colisão dos
padrões; só o visual muda.

| Distância | Libera | Locais especiais (máx.) | Bifurcações (máx.) |
| --- | --- | --- | --- |
| Curta — 500 m | nível 1 | 1 | 1 |
| Média — 1 km | nível 2 | 1 | 2 |
| Longa — 2 km | nível 5 | 2 | 3 |
| Especial — 3 km | nível 9 | 3 | 3 |

Quanto mais longe, mais eventos, loot e XP.

### Obstáculos e loot (seções 21 e 31)

| Visual | Tipo | Como passar |
| --- | --- | --- |
| Barricada vermelha com tábuas | Parede (`W`) | Trocar de faixa |
| Barreira laranja baixa | Barreira (`L`) | Pular |
| Barra roxa suspensa | Barra (`H`) | Deslizar |
| Caminhão tombado / fogo | Eventos | Trocar de faixa |

Cada obstáculo causa 15 de dano. O loot é um cubo girando na cor do recurso:

| Cor | Recurso | Por loot | Peso | Onde é mais comum |
| --- | --- | --- | --- | --- |
| laranja | comida | 1–3 | 1 kg | Supermercado, Mercado, Parque |
| azul | água | 1–3 | 1 kg | Supermercado, Mercado |
| cinza | sucata | 2–4 | 2 kg | Posto, Estacionamento, Zona Industrial |
| amarelo | munição | 3–6 | 0,1 kg | Estacionamento, Contêineres |
| ciano | componentes | 1–2 | 1 kg | Zona Industrial, Mercado, Centro |
| branco | medicamentos | 1–2 | 0,5 kg | Hospital, Centro, evento Recurso raro |
| vermelho | combustível | 1–3 | 2 kg | Posto, Engarrafamento, Zona Industrial |

O Centro, o Hospital e a Zona Industrial somam +1 em cada loot. Com a
mochila cheia, o loot fica na pista ("MOCHILA CHEIA"); se só parte cabe, ela
pega o que couber.

### Eventos (seção 27)

A seed sorteia eventos em alguns chunks do meio da rota (20% a 40% por
chunk, conforme a região), e um aviso aparece no HUD ao se aproximar.

| Evento | O que acontece |
| --- | --- |
| Horda | 4 + metade da dificuldade zumbis surgem à frente, já perseguindo |
| Caminhão | um caminhão tombado bloqueia duas faixas vizinhas |
| Explosão | tremor, ruído e fogo bloqueando faixas |
| Recurso raro | 8 sucata + 12 munição + 2 medicamentos num ponto guardado por zumbis |
| Sobrevivente | alguém pede socorro numa faixa; encoste para resgatar |

### Locais especiais (seção 26)

Chunks raros, reconhecíveis de longe, com aviso no HUD e o loot concentrado
num baú guardado por zumbis (`data/chunks/poi_*.tres`). Cada um aparece no
máximo uma vez por expedição, e cerca de metade das expedições curtas tem
um. A preparação lista os possíveis de cada região.

| Local | Baú | Onde |
| --- | --- | --- |
| Supermercado | 16 comida + 6 água | Bairro, Mercado |
| Ambulância | 6 medicamentos + 4 água | Centro, Hospital |
| Viatura | 32 munição + 2 componentes | Centro, Zona Industrial |
| Oficina mecânica | 8 componentes + 8 sucata | Mercado, Zona Industrial |
| Posto de combustível | 10 combustível + 6 sucata | todas |
| Casa segura | sobrevivente garantido, mas uma horda ao entrar | todas |

### Bifurcações (seções 24 e 33)

Cerca de 40 m antes, uma placa mostra os dois caminhos, cada um com
recompensa e perigo (●○○ a ●●●). Onde a mureta começa, a faixa decide:
esquerda ou direita. Na faixa do meio, a personagem é empurrada para o
caminho de menor perigo, e a faixa do meio fica bloqueada até o fim da
mureta. Os dois ramos saem da seed, mas só o escolhido carrega
(`data/branches/*.tres`).

| Caminho | Recompensa | Perigo | Chunks |
| --- | --- | --- | --- |
| Mercado | comida e água | ●●○ | Hipermercado, Feira, Supermercado |
| Farmácia | remédios e componentes (+1 no loot) | ●●● | Pronto-socorro, Lojas, Loja de departamentos |
| Garagens | sucata e combustível | ●●○ | Estacionamento, Posto, Galpões |
| Delegacia | munição e componentes (+1 no loot) | ●●● | Engarrafamento, Contêineres, Estacionamento |
| Atalho | caminho mais calmo (metade dos zumbis) | ●○○ | Rua residencial, Avenida, Parque |
| Saída antecipada | volta agora, sem o bônus de +50 XP | ●○○ | só na Longa e na Especial, depois de 40% da rota |

Em média são ~0,9 bifurcação numa expedição de 1 km e ~2 numa de 2 km.

### Expedition Director (seção 30)

`scripts/expedition/expedition_director.gd` lê a tensão da corrida (dano
recente, zumbis perto, agarrão, ruído e HP baixo) e alterna o ritmo. A fase
aparece discreta ao lado da seed, no HUD.

| Fase | Quando | Efeito |
| --- | --- | --- |
| Calmo | primeiros 12% da rota | o ruído atrai 30% |
| Tensão | 16 s sem ameaça | +2 zumbis no chunk que carrega; o ruído atrai 150% |
| Perigo | o resto | normal |
| Alívio | tensão acima de 75, por 12 s | nenhum zumbi atraído; +1 loot no chunk que carrega |
| Clímax | últimos 15% | na Longa e na Especial, uma horda (2 zumbis a menos que a do evento) |

O Director não mexe no que a seed sorteia (chunks, obstáculos, padrões), só
nos extras.

### Voltar ao local da morte (seção 47)

O que se perdeu na morte fica numa mochila no ponto exato. Durante 3
expedições, a preparação oferece **Voltar ao local da morte**: mesma região,
seed e distância, então a rota é idêntica.

- **Na pista:** o HUD avisa quando a mochila está perto, e há 3 zumbis a
  mais em volta dela.
- **Ao encostar:** recupera o que couber na mochila atual.
- **Prazo:** morrer de novo troca a mochila antiga pela nova; não voltar em
  3 expedições faz ela sumir.

### Veículos (seção 63)

Alguns chunks trazem um veículo estacionado numa faixa livre, com o aviso
"PATINS À FRENTE" uns 40 m antes. Para montar, basta encostar.

- **HP próprio:** montada, todo dano (batidas, golpes, explosões) vai para o
  veículo. O HUD mostra o HP e o tempo restante.
- **Fim:** quando o HP ou o tempo acaba, ela cai na faixa sem dano e fica 1 s
  invulnerável.
- **Agarrão:** ninguém agarra a personagem montada; o zumbi bate no veículo
  (10 de dano; 20 na moto) e fica para trás. Montar também solta quem já
  estava agarrando.
- **Mãos ocupadas:** na bicicleta e na moto, a pistola e a faca não funcionam.
- **Onde aparece:** nunca nos primeiros 120 m (ou na fase Calma, o que for
  maior), nos últimos 150 m nem perto de uma bifurcação; no máximo um a cada
  200 m. Chance de 7% por chunk elegível, sorteada pela seed do chunk.

| Veículo | HP | Duração | Habilidade | Fraqueza | Onde |
| --- | --: | --- | --- | --- | --- |
| Patins | 40 | 20 s | +15% de velocidade, pulo 1,6× mais alto, troca de faixa 30% mais rápida | um agarrão quebra os patins (e o zumbi agarra) | Bairro, Centro |
| Skate | 50 | 20 s | +20% de velocidade; atravessa comuns e runners, que levam 40 e ficam para trás (8 de HP do skate cada) | não desliza; o Bruto quebra o skate | Bairro, Centro |
| Bicicleta de jornaleiro | 60 | 25 s | +25% de velocidade; o toque (ou ATACAR) lança **dois jornais**, projéteis de 50 de dano: um na faixa dela e outro na do lado (na faixa do meio, para o lado com o zumbi mais perto); 20 lançamentos, sem gastar munição | sem armas; não desliza | Bairro, Mercado |
| Mochila a jato | 50 | 30 s | +10% de velocidade; **segurar** o dedo (ou Espaço, ↑, W, botão do mouse) sobe até 6 m e passa por cima de tudo; soltar plana (gravidade 35% na descida); deslizar o dedo para o lado troca de faixa segurando; **ímã**: puxa o loot até 14 m à frente na faixa dela e numa faixa ao lado | **calor**: sobe 28% por segundo segurando e desce 18% soltando; em 100% explode (20 de dano direto nela e 80 nos zumbis a 4 m); sem armas; ruído de 0,5 por segundo | Zona Industrial, Hospital (nível 6+) |
| Moto | 100 | 25 s (+5 s a cada combustível coletado) | +40% de velocidade, pulo 2× (passa por cima dos carros, que têm 2,5 m); derruba comuns e runners sem dano na moto | sem armas; não desliza; ruído de 1,2 por segundo; Bruto, Blindado e Explosivo ferem a moto | Centro, Zona Industrial |

Na primeira vez em cada veículo, uma dica explica o que ele faz. Na faixa do
meio, o ímã da mochila a jato escolhe o lado com o loot mais perto e fica
com ele até ela trocar de faixa. A câmera acompanha metade da altura da
personagem, para o pulo e o voo aparecerem na tela. O furgão vem na etapa V4.

## Combate

Seções 9–17, 34 e 35 do GDD.

### Armas

Uma branca e uma de fogo por expedição, escolhidas na preparação. A faca e a
pistola existem desde o início; as outras são fabricadas na Oficina
(`data/weapons/`).

| Arma | Tipo | Níveis | Valores | Fabricar |
| --- | --- | --- | --- | --- |
| Faca | branca | 4 | combo improvisada 25/30/45 → reforçada 35/42/63 → tática 50/60/90 → militar 70/84/126; durabilidade 100 → 160 | desde o início |
| Facão | branca | 1 | 40/45/60, alcance 3 m, durabilidade 120 | 18 sucata + 3 comp. |
| Machado | branca | 1 | 70/85, lento (0,8 s), durabilidade 160 | 25 sucata + 5 comp. (Oficina 2) |
| Katana | branca | 1 | 4 golpes 45/50/55/80, rápida (0,3 s), alcance 3,6 m, 18% crítico | 30 sucata + 8 comp. + 5 energia (Oficina 2) |
| Machado pesado | branca | 1 | 100/130, muito lento (1,1 s), durabilidade 200 | 40 sucata + 10 comp. + 6 energia (Oficina 2) |
| Pistola | fogo | 3 | 35 → 45 → 55, até 30 m na faixa, ruído +1 | desde o início |
| Escopeta | fogo | 3 | 6–7 chumbos de 15–21 divididos entre os zumbis da faixa e das vizinhas até 12–14 m, perde força com a distância; ruído +6 | 20 sucata + 6 comp. (Oficina 2) |
| SMG | fogo | 3 | rajada de 4–5 balas de 12–16 até 25–28 m; ruído +4 por rajada | 22 sucata + 8 comp. (Oficina 2) |

- **Arma branca:** o ataque de emergência, sem ruído. Atinge quem está
  agarrando; sem agarrão, o zumbi mais próximo à frente. Mais de 0,9 s entre
  os toques reinicia o combo. Crítico dá dano x2, em amarelo.
- **Durabilidade** (seção 16): cada golpe que acerta gasta 1. Em 0, vira
  soco (10 de dano, sem combo nem crítico) até o reparo. Cada arma branca
  tem a própria durabilidade.
- **Arma de fogo:** mira sozinha no zumbi mais próximo à frente e não atira
  em quem já agarrou. A munição é um recurso do abrigo (começa com 24) e
  vale para todas as armas de fogo.
- **Na mão:** a arma muda de tamanho e cor conforme a equipada.

**Ruído** (seção 34): cada disparo soma ao ruído (até 10), que baixa 0,5 por
segundo. O ruído aumenta o alcance em que os zumbis percebem a personagem e
faz surgir zumbis extras à frente, já alertas ("mais tiros → mais ruído →
mais zumbis"). Aparece numa barra laranja no HUD, e o ruído da expedição
inteira também aumenta a próxima horda que ataca o abrigo.

### Zumbis (seção 17)

`data/zombies/*.tres`, sorteados pelos pesos da região.

| Tipo | HP | XP | Comportamento |
| --- | --- | --- | --- |
| Comum (verde) | 100 | 10 | Lento; agarra (8 HP/s, corrida a 70%). Desiste se ficar para trás. |
| Runner (amarelado, menor) | 60 | 15 | Mais rápido que a personagem: alcança por trás e agarra. |
| Bruto (marrom, grande) | 350 | 40 | Muito lento; não agarra — golpe pesado de 20 ao encostar. |
| Explosivo (laranja brilhante) | 80 | 20 | Corre até você, pisca e explode: 22 de dano num raio de 2,2 m (trocar de faixa salva), fere outros zumbis e soma +10 de ruído. Encostar acende o pavio. Também explode ao morrer. |
| Blindado (colete e capacete) | 250 | 35 | Agarra (8 HP/s); a armadura tira 8 de cada acerto. |

**Efeitos e animações** (`scripts/fx.gd`):
- **Combate:** sangue ao acertar e ao matar, rastro e clarão do tiro, recuo
  da arma.
- **Pista:** destroços ao bater em obstáculo, texto "+N" ao coletar loot,
  tremor de câmera e flash vermelho ao levar dano.
- **Animações:** a personagem balança ao correr, inclina na troca de faixa e
  se estica no pulo; os zumbis cambaleiam, "mordem" ao agarrar e caem ao
  morrer.

## Abrigo

Seções 32 e 36–41 do GDD. As regras e os valores ficam em
`data/shelter/shelter.tres` (`ShelterData`), e as construções em
`data/buildings/*.tres` (`BuildingData`).

### Recursos e o dia (seções 37 e 62)

- **Primeira barra:** comida, água e sucata (limitadas pelo Depósito),
  energia (limitada pelas Baterias) e munição.
- **Segunda barra:** moral, componentes, medicamentos e combustível
  (limitados pelo Depósito). Também avisa FERIDA, FRACA e a contagem até o
  próximo ataque.

A cor de comida, água e moral segue os estados da seção 37:

| Cor | Estado | Comida e água | Moral |
| --- | --- | --- | --- |
| branco | normal | 10 ou mais | 60–100 |
| amarelo | atenção | menos de 10 | 35–59 |
| laranja | crítico | menos de 5 | 15–34 |
| vermelho | esgotado | 0 | 0–14 |

**Fechamento do dia**, nesta ordem:
1. o loot entra no depósito;
2. as construções produzem, multiplicadas pela moral; o Gerador nível 2 gasta
   1 combustível;
3. a sobrevivente come 3 e bebe 3, e cada morador come 1 e bebe 1 (a Cozinha
   economiza comida; Egoístas comem +1);
4. a moral e a afinidade dos moradores mudam, e surgem ou vencem os pedidos;
5. o que passar da capacidade se perde;
6. se o ataque estiver perto, aparece o aviso.

Comida ou água **esgotada** deixa a personagem **fraca**: a próxima
expedição começa com −25 HP cada.

### Construções (seções 38–41 e 45)

| Construção | Níveis | Efeito | Custo |
| --- | --- | --- | --- |
| Depósito | 1 → 3 | 60 / 120 / 250 de cada recurso | 15 · 35 sucata |
| Oficina | 1 → 2 | nv 2 libera armas e upgrades avançados | 25 sucata + 5 energia |
| Dormitório | 0 → 2 | +2 / +4 vagas para moradores | 15 · 30 sucata + 5 energia |
| Gerador | 0 → 2 | +4 / +8 energia por dia (o nv 2 gasta 1 combustível; sem ele, rende +4) | 10 · 30 sucata |
| Coletor de chuva | 0 → 2 | +2 / +4 água por dia | 8 · 20 sucata |
| Horta | 0 → 2 | +2 / +4 comida por dia | 10 sucata + 5 água · 24 sucata + 8 água |
| Cozinha | 0 → 2 | −1 / −2 comida no consumo diário; refeição quente: +3 moral | 12 sucata + 3 energia · 25 sucata + 3 comp. |
| Painéis solares | 0 → 2 | +2 / +4 energia por dia, sem combustível | 15 sucata + 3 comp. · 30 sucata + 6 comp. (Oficina 2) |
| Baterias | 0 → 2 | energia máxima 20 → 40 → 70 | 10 sucata + 2 comp. · 25 sucata + 5 comp. |
| Enfermaria | 0 → 2 | trata ferimento e fraqueza; nv 2: kit médico | 15 sucata + 2 comp. · 30 sucata + 4 comp. + 2 medicamentos (Oficina 2) |
| Rádio | 0 → 2 | +2 / +4 moral por dia | 8 sucata + 2 comp. · 20 sucata + 4 comp. + 5 energia |
| Portão | 1 → 3 | 300 / 450 / 600 de HP na defesa | 25 sucata + 2 comp. · 45 sucata + 5 comp. |
| Barricadas | 0 → 2 | uma por faixa na defesa: 80 / 160 de HP | 15 sucata · 30 sucata + 2 comp. |
| Armadilhas | 0 → 2 | uma por faixa: explode uma vez, 80 / 150 de dano em área | 12 sucata + 2 comp. · 25 sucata + 4 comp. |
| Torres | 0 → 2 | 1 / 2 torres que atiram sozinhas (30 de dano, 1 munição por tiro) | 25 sucata + 4 comp. + 5 energia · 40 sucata + 6 comp. + 8 energia (Oficina 2) |

No abrigo 3D, a Cozinha e o Rádio ficam na sala principal, as Baterias ao
lado do Gerador, os Painéis no alto da parede do fundo, a Enfermaria perto
da porta, e as defesas na frente (torres nos cantos, barricadas, armadilhas
e o portão reforçado).

### Oficina (seção 40)

| Ação | Custo |
| --- | --- |
| Reparar a arma branca equipada | 1 sucata a cada 10 pontos + 1 energia |
| Fabricar munição | 8 balas por 2 sucata + 2 energia |
| Desmontar sucata | 1 componente por 5 sucata + 1 energia (o jeito de ter componentes antes das regiões que os têm) |
| Fabricar e melhorar armas | ver a [tabela de armas](#armas) |
| Melhorar a mochila (seção 32) | 25 → 35 → 50 kg |

Uma arma nova ou melhorada sai da bancada inteira.

### Moral (seção 37)

Vai de 0 a 100 e começa em 70. É do abrigo inteiro.

| Sobe | Cai |
| --- | --- |
| refeição quente (Cozinha): +3/dia | fome ou sede: −10/dia |
| Rádio: +2 / +4 por dia | morte na expedição: −6 |
| expedição extraída com loot: +3 | sobrevivente recusado por falta de vaga: −5 |
| novo morador: +8 | ataque ao abrigo perdido: −15 |
| pedido de morador atendido: +5 | |
| abrigo defendido: +5 | |

| Estado | Efeito |
| --- | --- |
| Normal | — |
| Atenção | produção −15% |
| Crítica | produção −35%; moradores sem bônus de profissão; quem tem afinidade baixa pode ir embora |
| Esgotada | como Crítica, e qualquer morador (não Leal) pode ir embora |

### Saúde (seção 41)

No painel Sobrevivente → SAÚDE E MORAL:

| Situação | Efeito | Tratamento na Enfermaria |
| --- | --- | --- |
| **Ferida** | morrer deixa o HP máximo em 80% na expedição seguinte | 2 medicamentos (1 com Médico(a) no abrigo) |
| **Fraca** | comida/água esgotada: −25 HP cada no início da expedição | 1 medicamento |
| **Kit médico** | Enfermaria nv 2: botão **KIT** (ou H) na expedição cura 30 HP, uma vez | gasta 1 medicamento quando usado |

## Moradores

Seção 44 do GDD (`data/professions/`, `data/traits/`,
`scripts/shelter/residents.gd`).

**Resgate:** alguém pede socorro na pista (evento Sobrevivente ou Casa
segura). O resgatado só vira morador se você chegar à extração e houver
vaga: 1 na sala principal, mais as do Dormitório (+2 / +4). Cada morador
come 1 e bebe 1 por dia, e ganha uma profissão, um traço e uma afinidade de
0 a 100 (começa em 40). A moral continua sendo do abrigo; os traços mudam
como ela varia.

| Profissão | Bônus | Na defesa |
| --- | --- | --- |
| Médico(a) | +15 HP máximo; tratamento de ferimento com 1 medicamento a menos | reforça o portão |
| Engenheiro(a) | −15% de sucata nos custos | reforça o portão |
| Agricultor(a) | +2 comida por dia | reforça o portão |
| Soldado | +10% de dano com a arma branca | torres 50% mais rápidas (sem torre, atira do muro) |

| Traço | Efeito |
| --- | --- |
| Otimista | perdas de moral do abrigo 25% menores; +1 de moral por dia |
| Pessimista | perdas de moral 25% maiores; bônus da profissão +25% |
| Leal | nunca vai embora por moral baixa |
| Egoísta | come +1 por dia; bônus da profissão +50% |
| Medroso(a) | +1 de comida ou água por dia (a que estiver menor); não ajuda na defesa |

**Afinidade:**

| Muda | Quando |
| --- | --- |
| +2 | por dia com comida e água em Normal |
| +5 | a personagem volta viva com loot, ou o abrigo é defendido |
| +10 | um pedido é atendido |
| −5 | um resgatado é recusado por falta de vaga, um pedido expira ou o abrigo cai |
| −10 | falta comida ou água |

- **Afinidade 75 ou mais:** o bônus da profissão sobe 50%, e há 30% de chance
  por dia de o morador fazer um **pedido**: trazer recursos (entregues no
  painel Sobrevivente) ou voltar vivo de uma expedição numa região. O prazo é
  de 5 dias. Cumprir dá +80 XP, +5 de moral e +10 de afinidade.
- **Afinidade 20 ou menos:** com a moral crítica, é o primeiro a ir embora.
- **No abrigo 3D:** cada morador mostra o traço e a afinidade sobre a
  cabeça, e "(pedido)" quando tem um.

## Defesa do abrigo

Seção 45 do GDD (`scenes/defense.tscn` + `defense.gd`). É o mesmo motor da
expedição, invertido: a personagem fica parada logo atrás do portão e a
horda desce pelas 3 faixas.

- **Na pista:** em cada faixa, os zumbis param na barricada (se houver) e
  depois no portão, e batem. Troque de faixa para mirar: a arma de fogo pega
  os que vêm, e a arma branca alcança os que chegaram ao portão. Armadilhas
  explodem uma vez; torres atiram sozinhas gastando a mesma munição sua.
- **Agenda:** o primeiro ataque é no dia 8, depois a cada 9 dias (8, 17, 26, 35…). O
  fechamento do dia e a barra do abrigo avisam 2 dias antes. No dia do
  ataque, o botão Expedição vira **DEFENDER O ABRIGO!** e não dá para sair
  antes de defender.
- **Horda:** 6 + 0,3 zumbi por dia + o ruído das últimas expedições (máximo
  40). Runners a partir do dia 8, brutos e explosivos do 15, blindados do
  22. Os zumbis causam 75% do dano normal nas estruturas.
- **Moradores:** cada Soldado(a) acelera as torres em 50%, e cada morador
  que não é Medroso(a) reforça portão e barricadas em 12%.
- **Vitória:** XP dos abates + 100, +5 de moral, +5 de afinidade.
- **Derrota** (portão a 0, personagem a 0 ou abandonar): perde 25% de cada
  recurso do depósito, −15 de moral e −5 de afinidade. Construções e save
  ficam.

## Progressão da personagem

Seções 42 e 43 do GDD. As regras ficam em
`data/progression/progression.tres` (`ProgressionData`), e os atributos e
perks em `data/progression/attributes/` e `perks/`.

**XP:**
- **Expedição:** o XP de cada zumbi (tabela acima), +1 a cada 10 m e +50 ao
  extrair (a saída antecipada não dá esses +50). Na morte, fica só metade.
  O HUD mostra quanto XP você leva se extrair agora.
- **Defesa:** XP dos abates + 100 na vitória.
- **Pedidos:** +80 cada.

**Níveis:** o XP para o próximo nível é 150 + 75 × (nível − 1), até o nível
20. Cada nível dá 1 ponto de atributo e 1 de perk.

| Atributo (até 10 pontos) | Por ponto |
| --- | --- |
| Vigor | +10 HP máximo |
| Agilidade | +6% de velocidade de troca de faixa |
| Precisão | +2% de crítico |
| Força | +5% de dano com a arma branca |
| Sobrevivência | −4% de dano recebido (inclui o agarrão) |

**Perks.** Cada linha da tabela exige pontos já gastos na própria árvore: 0,
1, 2 e 3.

| Combate | Exploração | Abrigo |
| --- | --- | --- |
| Lâmina afiada: +10% dano da arma branca | Mochila bem arrumada: +5 kg | Organizada: +20 no Depósito |
| Olho clínico: +5% crítico | Faro para loot: 25% de +1 unidade | Agricultora: +1/dia em cada produção |
| Mãos rápidas: −10% intervalo de golpes e tiros | Catadora: +15% do loot mantido ao morrer | Mãos à obra: −15% de sucata nos custos |
| Couro grosso: −10% dano recebido | Passos leves: −25% ruído | Ração controlada: −1 comida e −1 água/dia (1 rank) |

Os demais perks têm 2 ranks, com o efeito da tabela em cada um. Há pisos: o
dano recebido nunca fica abaixo de 30%, e o intervalo de ataque nunca abaixo
de 50%.

## Interface, áudio e desempenho

**Interface:**
- **Tema:** único em `ui/theme.tres` (botões, painéis, campos, barras).
- **Configurações** (menu principal e pausa): volume geral, música, efeitos,
  tremor de câmera, dicas do tutorial e "mostrar todas as dicas de novo".
- **Pausa** (expedição e defesa): continuar, configurações e abandonar
  (abandonar conta como morte ou como defesa perdida).
- **Efeitos:** vinheta vermelha e batimento com HP crítico; estouro dourado
  e "NÍVEL N!" ao subir de nível.

**Tutorial:** dicas curtas, uma única vez, na hora certa.
- **Na corrida:** trocar de faixa, cada tipo de obstáculo, primeiro zumbi,
  primeiro agarrão, loot, mochila quase cheia, ruído, extração perto, HP
  crítico, kit médico, ferida e bifurcação.
- **No abrigo:** boas-vindas, pontos para gastar, construir, arma gasta,
  comida/água acabando, região nova, ferida, moral caindo, componentes,
  mochila deixada, moradores, pedidos e ataque chegando.
- **Na defesa:** como defender o portão.

**Áudio** (autoload `AudioManager`): 21 sons sintetizados em `audio/*.wav`
(tiro, faca, impacto, explosão, gemido, agarrão, dano, batimento, coleta,
alarme, extração, subida de nível, construção, cliques), as trilhas do abrigo
e da expedição e o vento de fundo. Canais Music, SFX e UI, com pool de
players. Todos os botões clicam sozinhos, menos os que têm o metadado
`silent`.

**Desempenho** (seção 51):

| Medida (Centro, Intel UHD) | Antes | Depois |
| --- | --- | --- |
| Draw calls | 688 | ~197 |
| Objetos desenhados | 864 | ~370 |
| Pior engasgo | ~135 ms | ~60 ms |

- **`MeshMerger`:** ao carregar um chunk, a geometria estática vira um mesh
  por material, em cache por cena (os `.tscn` continuam editáveis). A
  decoração pequena não projeta sombra.
- **Streaming:** no máximo 1 chunk por frame; os chunks da região (e dos
  ramos e locais especiais da rota) são pré-mesclados na largada.
- **Pools e caches:** partículas, meshes e materiais dos efeitos, players de
  áudio.
- **Aquecimento:** shaders e fontes são aquecidos na tela preta da
  transição, para a primeira vez que algo aparece não engasgar.

## Balanceamento

Os números vêm de um robô que joga sozinho: desvia, pula, desliza, atira, usa
a arma branca, gasta pontos, constrói e escolhe a região. Ele é pior que uma
pessoa (bate em paredes e brutos que um jogador evitaria), então **os números
são um piso**. Tudo fica nos `.tres`.

**Expedição** — teste padronizado: 8 seeds por linha, 1 km, com o
equipamento de quem acabou de liberar a região (com bifurcações e Director):

| Região | Sobrevivência |
| --- | --- |
| Bairro (nível 3) | 6/8 |
| Mercado (nível 3) | 5/8 |
| Centro (nível 4) | 6/8 |
| Hospital (nível 6) | 5/8 |
| Bairro, 2 km (nível 5) | 5/8 |

**Campanha** — o robô joga 36 dias seguidos (expedições, abrigo e 4
defesas) e grava o registro da campanha (veja [tests/README.md](tests/README.md)).
Duas políticas: **cauteloso** (escolhe regiões abaixo do nível, volta ao
Bairro quando está ferido, guarda munição para o ataque) e **ganancioso**
(sempre a região mais difícil, atira em tudo):

| Política | Sobrevivência nas expedições | Defesas vencidas (dias 8, 17, 26, 35) |
| --- | --- | --- |
| Cauteloso (4 campanhas) | 69–77% | 14/16 |
| Ganancioso (2 campanhas) | 33–41% | 4/8 |

**Principais ajustes feitos:**
- **Zumbis:** o Explosivo acende um pavio ao encostar (trocar de faixa
  salva), e o Bruto, o Blindado e o Runner ficaram mais justos.
- **Regiões:** o Hospital foi suavizado (1/8 → 4/8).
- **Director:** a horda do clímax ficou menor e só nas expedições longas.
- **Ferimento:** dura 1 expedição, para morrer em sequência não virar uma
  espiral.
- **Defesa:** portão mais forte, zumbis causando 75% do dano nas estruturas
  e primeira horda menor.
- **Economia da campanha:** o registro mostrou que quem limita a sucata é a
  mochila (volta cheia em quase toda expedição) e que munição e energia
  comiam a maior parte dela. Antes, até o robô cauteloso perdia todas as
  defesas do dia 22 em diante. Agora: ataques a cada 9 dias (eram 7), a
  horda cresce 0,3 por dia (era 0,5) e a munição sai 8 balas por 2 sucata
  (eram 6 por 3).

**Ainda não validado:**
- **Economia com uma pessoa jogando:** o robô cauteloso vence quase todas as
  defesas, mas ele luta pior e decide mais simples que um jogador. Jogue
  algumas semanas e abra o `campaign_log.csv` (seção Save e configurações)
  para ver se sobra ou falta sucata.
- **Regiões avançadas:** o Centro e a Zona Industrial só foram ajustados
  com o robô.

As duas coisas pedem teste jogando de verdade.

## Como estender

Quase tudo é dado (`.tres`) editável no Inspector:

| Quero… | Como |
| --- | --- |
| **Criar um chunk** | Duplique uma cena de `scenes/chunks/`, edite a geometria e os `Marker3D` do nó `Rows`. Crie um `ChunkData` apontando para ela (comprimento, peso, multiplicadores de loot e zumbi) e adicione-o em `chunks` da região. |
| **Criar um padrão** | Acrescente uma string de 3 caracteres em `patterns` da região (ver a notação acima). |
| **Criar uma região** | Duplique um `.tres` de `data/regions/`, troque chunks, padrões, zumbis, pesos, eventos, `difficulty` e `unlock_level`, e adicione-a em `regions` de `data/world.tres`. |
| **Obstáculos próprios de uma região** | Uma cena com `obstacle.gd`, o `kind` e a mesma colisão do padrão; aponte em `wall_scene` / `low_scene` / `high_scene` da região. |
| **Criar um local especial** | Um chunk com placa e padrões fixos (`R` = o baú), um `ChunkData` com `poi_banner`, `cache_loot` (`[[tipo, quantidade], ...]`) e, se quiser, `poi_event`; inclua em `pois` das regiões. |
| **Criar um caminho de bifurcação** | Novo `BranchData` em `data/branches/` (nome, recompensa, perigo 1–3, chunks de 40 m, modificadores de loot e zumbis, `early_extraction`), incluído em `branches` de `data/world.tres`. |
| **Criar um evento** | Novo `EventData` em `data/events/`, incluído em `events` da região. O layout fica em `chunk_populator.gd` e os gatilhos por distância em `expedition_events.gd` (pelo `id`). |
| **Ajustar o ritmo** | Os valores do Director ficam no nó `Director` da `scenes/run.tscn` (Inspector). |
| **Criar um tipo de zumbi** | Novo `ZombieData` em `data/zombies/` (HP, velocidades, ataque GRAB/SMASH/EXPLODE, armadura, XP, cor, tamanho), em `zombie_types` da região com o peso em `zombie_weights`. Para a defesa, também em `horde_zombies` do `shelter.tres`. |
| **Criar uma arma** | Um `WeaponData` (branca) ou `RangedWeaponData` (fogo, com `pellets`, `spread_lanes`, `burst`) por nível, um `WeaponTrack` (`start_level` 0 = fabricar) incluído em `weapon_tracks` do `shelter.tres`. |
| **Criar uma construção** | Novo `BuildingData` em `data/buildings/` (categoria, custos por nível, Oficina exigida, efeito), incluído em `buildings` do `shelter.tres`. Se produz algo, some a linha em `scripts/shelter/production.gd`; para aparecer no abrigo 3D, crie o nó em `scenes/shelter.tscn`. |
| **Criar um veículo** | Novo `VehicleData` em `data/vehicles/` (HP, duração, dica, velocidade, pulo, troca de faixa, deslize, regras com zumbis, armas bloqueadas, jornais, combustível, ruído, regiões, nível), incluído em `vehicles` de `data/world.tres`. O visual com primitivas fica em `PlayerVehicle.build_visual`. |
| **Criar um traço** | Novo `TraitData` em `data/traits/` (perdas de moral, moral por dia, bônus da profissão, comida a mais, produção, nunca vai embora), incluído em `traits` de `data/world.tres`. |
| **Ajustar a defesa** | Grupo "Defesa do abrigo" do `shelter.tres` (agenda, horda, perdas, torres, reforço) e as construções `gate`, `barricades`, `traps` e `towers`. |
| **Trocar um som** | Substitua o `.wav` em `audio/` mantendo o nome. |

## Arquitetura e dados

**Autoloads**, carregados nesta ordem:

| Autoload | Papel |
| --- | --- |
| `GameManager` | estado do jogo (recursos, dia, construções, armas, progressão, moradores, mochila da morte, agenda de ataques) e os fechamentos: `commit_run` (expedição) e `commit_defense` (defesa) |
| `SaveManager` | save em disco |
| `Settings` | volumes, tremor de câmera, tutorial |
| `AudioManager` | canais, pool de players, música e ambiente |
| `Transition` | fade entre cenas |

**Resources** (seção 50 do GDD), em `scripts/data/`, editáveis no Inspector:

| Grupo | Classes |
| --- | --- |
| Armas | `WeaponData` (branca), `RangedWeaponData` (fogo), `WeaponTrack` (níveis de uma arma) |
| Expedição | `WorldData`, `RegionData`, `ChunkData`, `ZombieData`, `EventData`, `BranchData`, `VehicleData` |
| Abrigo | `ShelterData` (regras), `BuildingData` |
| Pessoas | `ProfessionData`, `TraitData` |
| Progressão | `ProgressionData`, `AttributeData`, `PerkData` |

**Convenção de eixo:** a personagem corre no eixo **−Z** (o "para frente"
padrão do Godot). A distância percorrida é `-player.global_position.z`. Um
chunk vai de `z = 0` a `z = -length`; posicione os elementos com Z negativo
para ficarem à frente.

```
RedShelterGodot/
├── project.godot
├── autoload/                 game_manager, save_manager, settings,
│                             audio_manager, transition
├── art/materials/            materiais compartilhados pelos chunks
├── audio/                    sons e trilhas (.wav)
├── data/
│   ├── branches/             mercado, farmacia, garagens, delegacia, atalho, saida
│   ├── buildings/            BuildingData (15 construções + mochila)
│   ├── chunks/               ChunkData (chunks, locais especiais, bifurcação)
│   ├── events/               horde, truck, explosion, rare_cache, survivor
│   ├── professions/          medic, engineer, farmer, soldier
│   ├── progression/          progression.tres, attributes/, perks/
│   ├── regions/              bairro, mercado, centro, hospital, industrial
│   ├── shelter/shelter.tres  ShelterData (regras do abrigo e da defesa)
│   ├── traits/               optimist, pessimist, loyal, selfish, fearful
│   ├── vehicles/             patins, skate, bicicleta, moto, jetpack
│   ├── weapons/              knife_1-4, machete, axe, katana, heavy_axe,
│   │                         pistol_1-3, shotgun_1-3, smg_1-3, *_track
│   ├── world.tres            WorldData
│   └── zombies/              common, runner, brute, explosive, armored
├── scenes/
│   ├── main_menu / shelter / run / result / defense (.tscn + .gd)
│   ├── zombie.tscn, survivor_npc.tscn
│   ├── chunks/               chunks artesanais
│   ├── obstacles/            wall, barrier_low, bar_high, loot, truck, fire,
│   │                         cart_pile, gondola_low, price_sign_high (Mercado),
│   │                         gurney_wall, stretcher_low, curtain_high (Hospital),
│   │                         death_bag
│   └── ui/                   settings_panel, pause_menu
├── scripts/
│   ├── player_controller.gd, player_health.gd, player_combat.gd
│   ├── camera_follow.gd, run_hud.gd, fx.gd
│   ├── zombie.gd, obstacle.gd, loot_pickup.gd, extraction_zone.gd,
│   │   death_bag.gd, survivor_npc.gd, player_vehicle.gd, vehicle_pickup.gd, newspaper.gd,
│   │   campaign_log.gd, user_paths.gd
│   ├── expedition/           route_generator, chunk_populator, chunk_streamer,
│   │                         expedition_events, expedition_director,
│   │                         mesh_merger, tutorial
│   ├── shelter/              construction, production, workshop, infirmary,
│   │                         residents e os painéis
│   ├── progression/          progression.gd (XP, níveis, stat())
│   ├── ui/                   settings_panel, pause_menu
│   └── data/                 classes de Resource
└── ui/theme.tres             tema visual
```

## Save e configurações

| Arquivo | Conteúdo |
| --- | --- |
| `user://save.json` | o jogo: recursos, dia, construções, armas e durabilidades, progressão, moral, moradores (traço, afinidade, pedido), mochila da morte, próximo ataque. Salvo ao fim de cada expedição e defesa, e a cada ação no abrigo. |
| `user://settings.cfg` | volumes, tremor de câmera e dicas já vistas. Fica separado do save: um Novo Jogo não apaga as configurações. |
| `user://campaign_log.csv` | registro da campanha para balanceamento: uma linha por expedição e por defesa (loot, gastos do dia, estoque, moral, horda prevista), separado por `;`. Começa de novo a cada Novo Jogo. |
| `user://sandbox/` | save, configurações e registros dos robôs de `tests/` (rodam com `-- --sandbox` e não tocam no save de verdade). |

- **Onde fica:** no Windows, `user://` é
  `%APPDATA%\Godot\app_userdata\Red Shelter\`.
- **Recomeçar:** use **Novo Jogo** no menu ou apague o `save.json`.
- **Save corrompido:** é ignorado com aviso no console, e o jogo começa um
  novo.
- **Saves de versões antigas:** carregam; o que falta ganha um valor
  padrão (moral 70, traço fixo pelo nome, primeiro ataque uma semana depois).

## Próximos passos

As Fases 1 a 12 do roadmap estão concluídas. O que vem agora:

| Item | GDD |
| --- | --- |
| **Fase 13 — Veículos**: V1 (patins e skate), V2 (bicicleta e moto) e V3 (mochila a jato) ✅; falta V4 (furgão) | 63 |
| **Fase 14 — Power-ups**, em 3 etapas (P1 Ímã, Sinalizador e Escudo · P2 Telhados, Rampa e Adrenalina · P3 preparação e raros) | 64 |
| Jogar de verdade e ajustar os valores (economia da campanha, regiões avançadas, defesa) | — |
| Trocar as primitivas por arte low-poly e o áudio sintetizado pelo definitivo; nada na lógica depende disso | 52 |
| Rumor de local especial na preparação | 26 |
| Tratar moradores feridos na Enfermaria | 41 |
| Espada e colete | 11, 40 |
| Tipo de dano (perfurante) contra a armadura do Blindado | 13 |
| Pooling de zumbis e pickups, se o profiler pedir | 51 |

**Jogos de referência** (seção 61 do GDD):

| Jogo | Serviu de referência para |
| --- | --- |
| Into the Dead 2 | armas de fogo num runner mobile |
| Last Day on Earth | defesa da base, mochila deixada no local da morte, locais especiais |
| This War of Mine | moral, personalidade, cozinha, enfermaria |
| Left 4 Dead | o Director |
| Hades | escolher a bifurcação vendo a recompensa |

## Problemas conhecidos

- **Aviso ao fechar no modo headless:** aparece "ObjectDB instances leaked".
  Vem do driver de áudio falso desse modo; não acontece com janela e não
  afeta o jogo.
- **FPS irregular na máquina de teste:** o FPS medido variou até ±30% entre
  execuções iguais. Os números de draw calls são confiáveis; os de FPS,
  aproximados.
- **Seeds de versões antigas:** depois dos ajustes, dos locais especiais e
  das bifurcações, uma seed antiga gera outra expedição. A estrutura continua
  reproduzível; os extras do Director dependem de como se joga.
- **Placa da bifurcação:** o texto é legível, mas pequeno à distância.
