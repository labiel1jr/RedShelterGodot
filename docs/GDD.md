# RED SHELTER

## Game Design Document — GDD 0.9.1

**Gênero:** Survival Runner + Shooter + Scavenging + Shelter Management
**Plataformas:** Android / iOS
**Engine:** Godot 4.7 (GDScript)
**Perspectiva:** Terceira pessoa — câmera traseira elevada
**Modo:** Single-player
**Estrutura:** Expedições procedurais + gerenciamento de abrigo
**Status:** protótipo jogável com o roadmap completo (Fases 1–14; a 13 trouxe os veículos, seção 63, e a 14 os power-ups, seção 64) · em paralelo: jogar, balancear e trocar as primitivas por arte
**Protótipo:** `RedShelterGodot/` — o README do projeto traz os valores de cada sistema e como estender

> **Como ler este documento:** o texto de cada seção é o desenho do jogo. A
> linha **Status**, logo abaixo do título, diz o que o protótipo já faz:
> ✅ implementado · 🟡 parcial · 📋 planejado (especificado aqui, ainda não feito).
>
> Os **valores atuais** citados são os do protótipo (arquivos `data/*.tres` do
> projeto) e mudam com o balanceamento. Onde o texto original e o protótipo
> divergem, a decisão tomada está registrada na própria seção.

### Histórico de versões

| Versão | Mudanças |
| ------ | -------- |
| 0.9.1 | Estilo decidido: toon shading / cel-shading (luz em 3 faixas, contorno por classe de objeto, cor por região). Seção 65 reescrita a partir da recomendação; análise mantida. |
| 0.9 | Seção 65 nova: direção de arte — análise de estilos para o jogo, recomendação "toon noir vermelho", paleta, luz por região, técnica e plano da Fase 15. Roadmap (58) com a Fase 15. |
| 0.8.2 | Câmera do abrigo aproxima e afasta (rodinha ou pinça), até 150%. Seção 36 atualizada. |
| 0.8.1 | Câmera do abrigo gira 360° (botão do meio do mouse ou dedo segurado). Seção 36 atualizada. |
| 0.8 | Fase 14 concluída com as melhorias dos power-ups na Oficina (níveis 2 e 3). Roadmap do GDD completo de novo (Fases 1–14). Seções 0, 40, 58 e 64 atualizadas. |
| 0.7.3 | Fase 14, etapa P3 implementada: os dois da preparação (Arrancada de moto, Mapa marcado, com o boato de local especial da seção 26) e os 6 raros. Os 14 power-ups da referência estão no jogo. Seções 0, 26, 58 e 64 atualizadas. |
| 0.7.2 | Fase 14, etapa P2 implementada: Rota dos telhados (8 m de altura, linha de munição e componentes, desce numa faixa livre e antes da extração), Rampa de entulho (salto de ~40 m) e Adrenalina (XP em dobro, golpes 20% mais rápidos). Seções 0, 4, 58 e 64 atualizadas. |
| 0.7.1 | Fase 14, etapa P1 implementada: base dos power-ups (PowerUpData, anel na pista, barras de tempo no HUD, até 2 ativos), Ímã de sucata, Sinalizador e Escudo de caçamba (fabricado na Oficina, toque duplo). Seções 0, 40, 58 e 64 atualizadas. |
| 0.7 | Fase 13 concluída com a etapa V4: furgão de destruição (duas faixas, atravessa tudo pagando em HP, metralhadora no teto, para antes das bifurcações) e o ramo Garagens com mais veículos. Seções 0, 24, 58 e 63 atualizadas. |
| 0.6.4 | Fase 13, etapa V3 implementada: mochila a jato (segurar para voar, planar, ímã de loot, barra de calor e explosão). A câmera passa a acompanhar metade da altura. Seções 0, 4, 58 e 63 atualizadas. |
| 0.6.3 | Fase 13, etapa V2 implementada: bicicleta de jornaleiro (dois jornais como projéteis) e moto (pulo por cima dos carros, derruba os fracos, combustível dá tempo, ruído). Montar solta o agarrão. Seções 0, 58 e 63 atualizadas. |
| 0.6.2 | Fase 13, etapa V1 implementada: base dos veículos (VehicleData, montar, HP e tempo no HUD, queda com 1 s invulnerável) e os primeiros veículos, patins e skate. Seções 0, 58 e 63 atualizadas. |
| 0.6.1 | Decisões tomadas: a bicicleta lança dois jornais como projéteis (faixa dela e a do lado) e o Tênis de mola dá lugar ao Sinalizador. Seções 58, 63 e 64 atualizadas. |
| 0.6 | Planejamento de duas fases novas para a corrida: veículos (seção 63, Fase 13) e power-ups (seção 64, Fase 14). Seções 0, 58 e 62 atualizadas. |
| 0.5.2 | Balanceamento da campanha com o registro (`campaign_log.csv`) e o robô de `tests/`: ataques a cada 9 dias (eram 7), horda +0,3 por dia (era 0,5), munição 8 balas por 2 sucata (era 6 por 3). Seções 0, 40 e 45 atualizadas. |
| 0.5.1 | Revisão geral: resumo do estado do protótipo (seção 0), trechos de planejamento atualizados para o que existe (11, 13, 35, 36, 44, 45, 47), fluxo de cenas com a defesa (48), arquitetura atualizada (49–50) e o que fica depois do roadmap (58). |
| 0.5 | Fase 12 implementada: defesa do abrigo (portão, barricadas, armadilhas, torres, horda a cada 7 dias, soldados e moradores ajudando). Seções 36, 39, 44, 45 e 58 atualizadas. Roadmap do GDD completo. |
| 0.4.4 | Fase 11 implementada: traços de personalidade, afinidade com o grupo, pedidos dos moradores e regra de quem vai embora. Seção 44 atualizada com os valores reais. |
| 0.4.3 | Fase 10 implementada: bifurcações com placa e extração antecipada, Expedition Director, escopeta, SMG, facão, machado, katana e machado pesado. Seções 11, 13, 24, 28, 29, 30, 33, 35, 40, 49, 50, 58 e 59 atualizadas. |
| 0.4.2 | Fase 9 implementada: regiões Mercado e Hospital (com obstáculos próprios), 6 locais especiais, distância Especial, voltar ao local da morte. Seções 20, 25, 26, 28, 47 e 62 atualizadas. |
| 0.4.1 | Fase 8 implementada: recursos novos, moral, cozinha, enfermaria, painéis, baterias, rádio, combustível no Gerador. Valores reais registrados nas seções 7, 31, 37, 38, 39, 40, 41 e 62. |
| 0.4 | Engine passa a ser Godot. Status de cada sistema e valores atuais do protótipo. Especificação dos sistemas pós-slice: bifurcações (24), regiões (25), POIs (26), Director (30), armas de fogo (35), moral (37), produção e construção (38–41), sobreviventes (44), defesa (45), mochila (47). Arquitetura e dados em Godot (49–50). Roadmap com as Fases 8–12 (58). Novas seções 61 (jogos de referência) e 62 (economia de recursos). |
| 0.3 | Documento original de pré-produção (Unity). |

---

# 0. ESTADO DO PROTÓTIPO

O protótipo em Godot executa o ciclo inteiro do jogo com formas primitivas
no lugar da arte. Por área:

| Área | O que existe | Seções |
| ---- | ------------ | ------ |
| Corrida | 3 faixas, pulo, deslize, HP com estados, obstáculos, câmera traseira | 4–7 |
| Combate | agarrão, 5 armas brancas (faca em 4 níveis), pistola, escopeta e SMG em 3 níveis, combo, crítico, durabilidade, ruído | 8–16, 34, 35 |
| Zumbis | comum, runner, bruto, explosivo (com pavio) e blindado | 17, 18 |
| Procedural | chunks artesanais, padrões por faixa, seed, streaming, eventos, 6 locais especiais, bifurcações com 6 caminhos, Expedition Director | 19–30 |
| Mundo | 5 regiões com chunks e obstáculos próprios, 4 distâncias | 25, 28 |
| Loot e mochila | 7 recursos no loot, mochila por peso, metade perdida na morte, mochila deixada no local da morte | 31–33, 46, 47 |
| Abrigo | abrigo 3D com 15 construções em 3 categorias (mais a mochila), produção, consumo, moral, enfermaria, oficina | 36–41 |
| Progressão | XP, 20 níveis, 5 atributos, 12 perks em 3 árvores | 42, 43 |
| Moradores | resgate, 4 profissões, 5 traços, afinidade, pedidos, saída com moral baixa | 44 |
| Defesa | horda a cada 9 dias pelas mesmas 3 faixas; portão, barricadas, armadilhas, torres | 45 |
| Veículos | patins, skate, bicicleta de jornaleiro, moto, mochila a jato e furgão de destruição, com HP, habilidade e fraqueza próprios | 63 |
| Power-ups | 14, nos papéis dos de Subway Surfers: 5 na pista, o Escudo fabricado na Oficina, 2 na preparação e 6 raros; 5 melhoram na Oficina | 64 |
| Polimento | tema de interface, configurações, pausa, 21 sons, tutorial contextual, otimização (688 → ~197 draw calls) | 51, 58 |

**Pendências** (depois do roadmap):

* balancear jogando de verdade — os valores atuais vêm de um robô (`tests/`); o registro `campaign_log.csv` mostra a economia de uma campanha real (economia com uma pessoa jogando, regiões avançadas);
* arte low-poly e áudio definitivos no lugar das primitivas (seção 52);
* tratar moradores feridos na Enfermaria (41);
* espada e colete (11, 40);
* tipo de dano perfurante contra armadura (13);
* pooling de zumbis e pickups, se o profiler pedir (51).

---

# 1. VISÃO GERAL

**RED SHELTER** é um jogo mobile de sobrevivência em um mundo tomado por zumbis.

O jogador controla uma sobrevivente que parte de um pequeno abrigo para explorar áreas perigosas em busca de recursos.

A personagem corre automaticamente pelas ruas e o jogador controla sua movimentação, esquiva, salto, deslizamento e combate.

O objetivo de cada expedição é conseguir o máximo possível de recursos e retornar vivo ao abrigo.

Os recursos obtidos permitem:

* melhorar o abrigo;
* produzir comida e água;
* gerar energia;
* fabricar e reparar equipamentos;
* melhorar armas;
* desbloquear novas áreas;
* recrutar sobreviventes;
* preparar-se para expedições mais perigosas.

A experiência combina:

> **Runner + combate + risco/recompensa + exploração procedural + gerenciamento de abrigo.**

---

# 2. PILARES DO JOGO

O jogo será construído sobre cinco pilares.

## 2.1 CORRA

A personagem está constantemente avançando.

O jogador precisa reagir rapidamente aos obstáculos, inimigos e oportunidades.

## 2.2 SOBREVIVA

A personagem possui HP.

Ser alcançado por um zumbi não significa morte instantânea.

O jogador ainda possui tempo para reagir.

## 2.3 SAQUEIE

Durante a corrida existem recursos espalhados pelo cenário.

O jogador precisa decidir:

> "Vale a pena correr esse risco para pegar esse recurso?"

## 2.4 EVOLUA

Tudo que é conseguido durante as expedições alimenta o crescimento do abrigo e do personagem.

## 2.5 CONSTRUA

O abrigo começa como um esconderijo improvisado e evolui para uma verdadeira base de sobreviventes.

---

# 3. CORE LOOP

```text
                 🏠 ABRIGO
                     │
                     ▼
             Preparar expedição
                     │
                     ▼
             🏃 INICIAR RUN
                     │
                     ▼
          ┌────────────────────┐
          │ Correr             │
          │ Desviar            │
          │ Atacar             │
          │ Saquear            │
          │ Escolher caminhos  │
          └────────────────────┘
                     │
                     ▼
              ⚠️ PERIGO
                     │
              ┌──────┴──────┐
              ▼             ▼
          ESCAPAR          MORRER
              │             │
              ▼             ▼
          RETORNAR       PERDE RUN
              │
              ▼
           🏠 ABRIGO
              │
      ┌───────┼────────┐
      ▼       ▼        ▼
   Construir Melhorar  Produzir
      │       │        │
      └───────┼────────┘
              ▼
        Nova expedição
```

---

# 4. CÂMERA

**Status:** ✅ câmera traseira elevada, com tremor de impacto (pode ser desligado nas Configurações). Acompanha só metade da altura da personagem, para o pulo e o voo da mochila a jato (63) aparecerem subindo na tela; na Rota dos telhados (64) acompanha a altura toda.

A câmera será inspirada na sensação de jogos como Subway Surfers.

## Características

* terceira pessoa;
* atrás da personagem;
* levemente elevada;
* visão ampla da pista;
* personagem sempre avançando;
* câmera acompanha automaticamente;
* distância dinâmica.

```text
             CÂMERA
               📷
                \
                 \
                  🏃
                  │
                  │
          ────────┼────────
          FAIXA 1  2  3
```

A câmera não deve ficar excessivamente próxima.

O jogador precisa visualizar:

* obstáculos;
* zumbis;
* recursos;
* bifurcações;
* perigos à frente.

---

# 5. MOVIMENTAÇÃO

**Status:** ✅ swipe no celular; no PC (testes) A/D ou setas, Espaço, Ctrl, F/J (faca), K/clique (tiro), Esc/P (pausa).

A personagem corre automaticamente.

Controles principais:

| Ação                 | Controle         |
| -------------------- | ---------------- |
| Mover esquerda       | Swipe ←          |
| Mover direita        | Swipe →          |
| Pular                | Swipe ↑          |
| Deslizar             | Swipe ↓          |
| Atirar               | Toque            |
| Ataque de emergência | Botão de ataque  |
| Interação especial   | Toque contextual |

A movimentação deve ser simples para funcionar confortavelmente em telas de celular.

---

# 6. SISTEMA DE FAIXAS

**Status:** ✅ três faixas; todo padrão procedural é validado para ter ao menos uma faixa passável sem lutar (seção 22).

A pista utiliza três faixas principais.

```text
┌─────────┬─────────┬─────────┐
│ FAIXA 1 │ FAIXA 2 │ FAIXA 3 │
│         │         │         │
│   🧟    │         │   💧    │
│         │   🚧    │         │
│   🔩    │         │   🧟    │
└─────────┴─────────┴─────────┘
```

O jogador pode mudar de faixa rapidamente.

O cenário procedural deve sempre garantir pelo menos uma rota possível.

---

# 7. SISTEMA DE VIDA

**Status:** ✅ HP base 100 (+10 por ponto de Vigor, +15 por Médico no abrigo). Estados no HUD: Normal, Ferido e Crítico — no Crítico, vinheta vermelha e batimento cardíaco. Entre expedições: **Ferida** (depois de morrer, HP máximo 80% na expedição seguinte) e **Fraca** (fome/sede, −25 HP no início) — tratadas na Enfermaria (seção 41).

A personagem possui HP.

Exemplo:

```text
❤️ 100 / 100
████████████████
```

A vida pode ser reduzida por:

* zumbis;
* ataques;
* obstáculos;
* explosões;
* eventos;
* perigos ambientais.

## Estados

```text
NORMAL
   ↓
FERIDO
   ↓
CRÍTICO
   ↓
0 HP
   ↓
RUN PERDIDA
```

### Importante

**Chegar a 0 HP durante a corrida encerra a expedição.**

Não existe morte instantânea simplesmente porque um zumbi alcançou a personagem.

---

# 8. ZUMBIS COM HP

**Status:** ✅ todos os zumbis têm HP e barra própria (valores na seção 17).

Todos os zumbis possuem vida.

Exemplo:

```text
🧟 ZUMBI COMUM
██████████ 100 HP
```

Ataques reduzem o HP.

```text
100 HP
 ↓
75 HP
 ↓
40 HP
 ↓
0 HP
 ↓
💀
```

Isso permite diferentes estratégias e armas.

---

# 9. SISTEMA DE AGARRÃO

**Status:** ✅ agarrão de 8 HP/s; agarrada, a personagem corre a 70% da velocidade.

Uma das principais mecânicas de combate.

Quando um zumbi alcança a personagem, ele pode agarrá-la.

```text
🏃  ←  🧟
          ↓
       AGARRADO
```

O zumbi passa a causar dano continuamente.

Exemplo:

```text
Personagem: 100 HP

Zumbi agarra
      ↓
-8 HP/s
      ↓
92
      ↓
84
      ↓
76
```

O jogador precisa eliminar o zumbi antes que sua vida chegue a zero.

---

# 10. COMBATE CONTRA ZUMBI AGARRADO

**Status:** ✅ a faca atinge quem está agarrando sem interromper a corrida; a pistola não atira em quem já agarrou.

Quando um zumbi está agarrado, o jogador pode utilizar uma arma de emergência.

A personagem continua correndo.

```text
       🧟
      /
     /
   🏃 → → →
      🔪
```

O jogador pode atacar sem entrar em uma tela ou modo separado de combate.

O objetivo é manter o ritmo de runner.

---

# 11. ARMAS DE EMERGÊNCIA

**Status:** ✅ faca (4 níveis), facão, machado, katana e machado pesado (um nível cada, fabricados na Oficina) · espada 📋. Uma arma branca equipada por expedição, cada uma com a própria durabilidade.

As armas de emergência são utilizadas principalmente contra inimigos que conseguiram alcançar o jogador.

Armas previstas:

* faca — ✅ em 4 níveis (improvisada, reforçada, tática, militar), que incluem a faca tática;
* facão — ✅;
* machado — ✅;
* machado pesado — ✅;
* espada — 📋;
* katana — ✅;
* outras armas brancas posteriormente.

---

# 12. PROGRESSÃO DAS ARMAS

**Status:** ✅ exatamente estes valores (golpe 1 do combo; ver seção 14). Níveis 3 e 4 exigem Oficina nível 2.

As armas são melhoradas fora da expedição.

O jogador retorna ao abrigo e utiliza a oficina.

```text
🏠 ABRIGO
   ↓
🔧 OFICINA
   ↓
🔪 ARMAS
   ↓
UPGRADE
```

Exemplo:

### Faca improvisada

**Nível 1**

Dano: 25

### Faca reforçada

**Nível 2**

Dano: 35

### Faca tática

**Nível 3**

Dano: 50

### Faca militar

**Nível 4**

Dano: 70

---

# 13. ATRIBUTOS DAS ARMAS

**Status:** 🟡 dano, velocidade, alcance, crítico e durabilidade ✅ (valores das armas novas na seção 35 e no README) · knockback nas armas de fogo · tipo de dano 📋 (entra com a armadura do Blindado: dano perfurante ignora parte dela).

Cada arma pode possuir:

* dano;
* velocidade de ataque;
* alcance;
* chance crítica;
* durabilidade;
* animação;
* knockback;
* tipo de dano.

Exemplo:

| Arma           | Dano |  Velocidade | Alcance | Durabilidade |
| -------------- | ---: | ----------: | ------: | -----------: |
| Faca           |   25 |        Alta |   Baixo |          100 |
| Facão          |   40 |        Alta |   Médio |          120 |
| Machado        |   70 |       Baixa |   Médio |          160 |
| Katana         |   60 |  Muito alta |    Alto |          110 |
| Machado pesado |  100 | Muito baixa |   Médio |          200 |

Os valores são protótipos e deverão ser balanceados no Vertical Slice.

## Valores atuais

| Arma | Golpes (combo) | Intervalo | Alcance | Crítico | Durabilidade |
| ---- | -------------- | --------: | ------: | ------: | -----------: |
| Faca (nível 1 → 4) | 25/30/45 → 70/84/126 | 0,45 s | 2,5 m | 10% | 100 → 160 |
| Facão | 40/45/60 | 0,45 s | 3,0 m | 10% | 120 |
| Machado | 70/85 | 0,8 s | 3,0 m | 12% (x2,2) | 160 |
| Katana | 45/50/55/80 | 0,3 s | 3,6 m | 18% | 110 |
| Machado pesado | 100/130 | 1,1 s | 3,2 m | 10% (x2,5) | 200 |

Os valores de dano da tabela de exemplo viraram o primeiro golpe do combo;
a faca continua sendo a arma que evolui em níveis, e as outras são
alternativas de um nível só.
---

# 14. COMBO DE ATAQUE

**Status:** ✅ faca nível 1 = 25 / 30 / 45; mais de 0,9 s entre toques reinicia o combo.

O ataque de emergência pode utilizar uma sequência simples.

```text
TAP
 ↓
Golpe 1

TAP
 ↓
Golpe 2

TAP
 ↓
Golpe 3
```

Exemplo:

```text
Golpe 1 = 25
Golpe 2 = 30
Golpe 3 = 45
```

A velocidade e o dano podem variar de acordo com a arma.

---

# 15. DANO CRÍTICO

**Status:** ✅ 10% de chance base, crítico = dano × 2 (em amarelo). Precisão e o perk Olho clínico aumentam a chance.

Algumas armas possuem chance de causar dano crítico.

Exemplo:

```text
Faca
Dano: 25
Crítico: 50
Chance: 10%
```

Upgrades podem aumentar:

* dano;
* chance crítica;
* velocidade;
* durabilidade.

---

# 16. DURABILIDADE

**Status:** ✅ cada golpe que acerta gasta 1. Quebrada, a faca vira soco (10 de dano, sem combo nem crítico) até o reparo na Oficina.

Armas brancas possuem durabilidade.

```text
🔪 FACA
████████░░ 80%
```

Ataques reduzem a durabilidade.

Quando chega a zero:

```text
⚠️ ARMA QUEBRADA
```

A arma precisa ser reparada no abrigo.

---

# 17. TIPOS DE ZUMBI

## Zumbi comum

HP: 100

* velocidade média;
* pode agarrar;
* inimigo básico.

## Runner

HP: 60

* extremamente rápido;
* alcança o jogador com facilidade;
* pouco resistente.

## Bruto

HP: 350

* lento;
* muito resistente;
* ataques pesados;
* não precisa utilizar agarrão.

## Explosivo

HP: 80

* aproxima-se rapidamente;
* explode quando chega perto ou é eliminado.

## Blindado

HP: 250

* resistente;
* pode exigir armas melhores;
* aparece em regiões avançadas.

## Valores atuais

| Tipo | HP | Velocidade | Ataque | XP | Observação |
| ---- | -: | ---------: | ------ | -: | ---------- |
| Comum | 100 | lenta | agarrão 8 HP/s | 10 | desiste se ficar para trás |
| Runner | 60 | 11 (mais rápido que a personagem) | agarrão | 15 | alcança por trás |
| Bruto | 350 | 1,5 | golpe de 20 ao encostar | 40 | não agarra |
| Explosivo | 80 | 5 | 22 de dano num raio de 2,2 m | 20 | encostar **acende o pavio** (0,45 s): trocar de faixa salva. Explode também ao morrer e fere outros zumbis (reação em cadeia) |
| Blindado | 250 | 2,5 | agarrão 8 HP/s | 35 | armadura tira 8 de cada acerto |

**Decisão de balanceamento:** no texto original o Explosivo explode ao
chegar perto; no protótipo isso respondia por quase metade do dano recebido
e parecia injusto. Com o pavio, a explosão continua perigosa, mas o jogador
sempre tem uma chance de reagir — coerente com o pilar 2.2.

---

# 18. COMPORTAMENTO DOS ZUMBIS

**Status:** ✅ versão enxuta: IDLE (detecção por distância, que aumenta com o ruído) → CHASE → GRAB ou ataque (golpe / explosão) → DEAD. DETECT, ATTACK e DAMAGING ficaram embutidos nesses estados.

Máquina de estados simplificada:

```text
IDLE
 ↓
DETECT
 ↓
CHASE
 ↓
ATTACK
 ↓
GRAB
 ↓
DAMAGING
 ↓
DEAD
```

Nem todos os zumbis utilizarão todas as etapas.

---

# 19. CENÁRIO PROCEDURAL

**Status:** ✅ chunks artesanais (`.tscn`) combinados pela seed.

O mundo das expedições será gerado proceduralmente através de módulos.

O objetivo não é gerar uma cidade matematicamente aleatória.

O sistema utilizará **chunks criados manualmente** que serão combinados proceduralmente.

```text
CHUNK 01
Rua

      ↓

CHUNK 07
Beco

      ↓

CHUNK 12
Mercado

      ↓

CHUNK 04
Avenida
```

---

# 20. TIPOS DE CHUNKS

Exemplos:

* rua residencial;
* avenida;
* cruzamento;
* estacionamento;
* supermercado;
* posto;
* garagem;
* beco;
* parque;
* hospital;
* fábrica;
* construção;
* rodovia.

## Chunks existentes (protótipo)

| Região | Chunks |
| ------ | ------ |
| Bairro | Saída do abrigo, Rua residencial, Avenida, Beco, Supermercado, Estacionamento, Posto, Parque, Cruzamento, Extração |
| Centro | Entrada do Centro, Praça, Rua de lojas, Loja de departamentos, Engarrafamento |
| Zona Industrial | Portão, Fábrica, Pátio de contêineres, Ferrovia, Galpões |

| Mercado | Entrada, Hipermercado, Feira livre, Galeria, Docas de carga (+ Supermercado e Estacionamento do Bairro) |
| Hospital | Entrada, Pronto-socorro, Triagem, Corredor, Pátio interno (+ Avenida) |
| Locais especiais (seção 26) | Supermercado, Ambulância, Viatura, Oficina mecânica, Posto de combustível, Casa segura |

---

# 21. GERAÇÃO EM CAMADAS

**Status:** ✅ camadas 1 e 4 vêm da cena do chunk; camadas 2 e 3 são aplicadas pelo gerador em marcadores de linha do chunk.

O cenário será gerado em quatro camadas.

## Camada 1 — Estrutura

Define:

* rua;
* prédios;
* caminhos;
* áreas internas.

## Camada 2 — Obstáculos

Adiciona:

* carros;
* barricadas;
* entulho;
* buracos;
* veículos;
* objetos.

## Camada 3 — Gameplay

Adiciona:

* zumbis;
* loot;
* munição;
* recursos;
* eventos.

## Camada 4 — Ambientação

Adiciona:

* lixo;
* vegetação;
* placas;
* decoração;
* partículas;
* objetos menores.

---

# 22. PADRÕES PROCEDURAIS

**Status:** ✅ cada região tem a sua lista de padrões; padrões inválidos são rejeitados.

O sistema não deverá gerar obstáculos completamente aleatórios.

Utilizará padrões de gameplay.

Exemplo:

```text
🚧       ─       🚧
```

ou:

```text
🧟       🚧       💧
```

ou:

```text
🚧       🚧       ─
```

ou:

```text
💧       🚧       🔩
```

Cada padrão deverá possuir uma rota válida.

## Notação usada no projeto

Um caractere por faixa, da esquerda para a direita: `.` vazio, `W` parede
(trocar de faixa), `L` barreira baixa (pular), `H` barra alta (deslizar),
`$` loot, `Z` zumbi. Um padrão só é aceito se ao menos uma faixa for
passável sem lutar (`.` `$` `L` `H`).

---

# 23. SISTEMA DE SEED

**Status:** ✅ a seed define rota, obstáculos, loot, zumbis e eventos; o campo Seed da preparação repete uma expedição. Quando existirem, os ramos das bifurcações (24) também saem da seed. O Director (30) só mexe nos extras, que dependem do desempenho — a estrutura da expedição continua reproduzível.

Cada expedição recebe uma Seed.

Exemplo:

```text
SEED: 8492371
```

A seed determina:

* sequência de chunks;
* obstáculos;
* loot;
* inimigos;
* eventos;
* caminhos alternativos.

Isso permite reproduzir uma expedição específica.

---

# 24. ROTAS ALTERNATIVAS

**Status:** ✅ implementado (Fase 10): placa ~40 m antes, mureta na faixa do meio a partir de 16 m do chunk da bifurcação (60 m), faixa do meio → ramo de menor perigo, 6 caminhos (Mercado, Farmácia, Garagens, Delegacia, Atalho, Saída antecipada), só o ramo escolhido carrega. Cerca de 0,9 bifurcação por expedição de 1 km e 2 por expedição de 2 km. O ramo Garagens tem 35% de chance de veículo por chunk e traz moto e furgão em qualquer região (seção 63).

Alguns chunks podem apresentar bifurcações.

```text
             ┌── 🏪 Mercado
             │
🏃 ──────────┤
             │
             └── 🏥 Farmácia
```

Os caminhos possuem diferentes recompensas e perigos.

Exemplo:

**Mercado**

* comida
* água
* perigo médio

**Farmácia**

* medicamentos
* componentes
* perigo alto

## Como funciona na pista

A escolha precisa caber no runner de três faixas sem parar a corrida:

1. Cerca de 40 m antes, uma placa mostra os dois destinos com ícones de
   **recompensa** e de **perigo** — o jogador escolhe informado.
2. Um muro nasce na faixa do meio e divide a pista.
3. A faixa em que a personagem está quando o muro fecha decide o caminho:
   faixa 1 → ramo da esquerda, faixa 3 → ramo da direita. Na faixa 2 ela
   segue pelo ramo mais seguro.
4. Cada ramo tem de 2 a 4 chunks próprios e volta à rota principal.

```text
            placa (−40 m)      muro
🏃 ────────── 🪧 ──────────── ║ ──┬── 🏪 Mercado   comida, água · perigo médio
                                 └── 💊 Farmácia  remédios, componentes · perigo alto
```

## Regras

* os dois ramos saem da seed: a expedição continua reproduzível qualquer que seja a escolha;
* no máximo 1 bifurcação na Curta, 2 na Média, 3 na Longa e na Especial;
* o ramo mais perigoso sempre paga mais (loot +1 nível ou POI garantido, seção 26);
* nas expedições Longa e Especial, um dos ramos pode ser uma **extração antecipada**: volta mais cedo, com menos XP e sem o bônus de extração completa — é a resposta à pergunta da seção 33 ("É hora de voltar?");
* a escolha aparece no resultado da expedição.

Referência de desenho: Hades (seção 61).

---

# 25. REGIÕES

**Status:** ✅ as cinco regiões (Mercado e Hospital na Fase 9).

O mapa será dividido em regiões.

### Região 1 — Bairro

Baixa dificuldade.

Recursos:

* comida;
* água;
* materiais básicos.

### Região 2 — Mercado

Recursos:

* comida;
* água;
* componentes.

### Região 3 — Centro

Alta quantidade de loot.

Alta quantidade de zumbis.

### Região 4 — Hospital

Medicamentos raros.

Grande perigo.

### Região 5 — Zona Industrial

Materiais avançados.

Zumbis mais fortes.

## Progressão das regiões

| # | Região | Libera no nível | Dificuldade | Recurso principal | Status |
| - | ------ | --------------: | ----------: | ----------------- | ------ |
| 1 | Bairro | 1 | 1 | comida, água, sucata | ✅ |
| 2 | Mercado | 3 | 2 | comida, água, **componentes** | ✅ |
| 3 | Centro | 4 | 3 | muito loot (+1 em cada), runners e explosivos | ✅ |
| 4 | Hospital | 6 | 4 | **medicamentos** (+1 em cada loot) | ✅ |
| 5 | Zona Industrial | 7 | 5 | sucata e componentes, brutos e blindados | ✅ |

## Mercado

Galerias, estacionamento de hipermercado e corredores de prateleiras.
Obstáculos próprios: carrinhos (parede), gôndolas tombadas (barreira baixa)
e placas de preço penduradas (barra alta). Muitos zumbis comuns em grupo,
poucos runners. É a região que ensina a usar componentes (Fase 8).

## Hospital

Corredores estreitos, macas e portas de vaivém: mais `L` e `H`, menos
espaço para desviar. Mais runners e explosivos. Recompensa: medicamentos,
o único jeito constante de manter a Enfermaria (seção 41). Um POI
Ambulância (seção 26) é bem mais comum aqui.

Implementação: cada região tem 4 chunks próprios + a entrada, reusando
alguns do Bairro e do Centro. Os obstáculos próprios (carrinhos, gôndola,
cartaz de oferta; maca, armário, cortina) têm a mesma colisão dos padrões —
só o visual muda, a leitura "parede / pular / deslizar" continua a mesma. O
Corredor do Hospital tem padrões fixos `L.H` e `H.L`; a Galeria do Mercado,
`H.H`.

---

# 26. LOCAIS ESPECIAIS

**Status:** ✅ os seis (Fase 9) · rumor na preparação 📋 (hoje a preparação lista os POIs possíveis de cada região).

O procedural pode gerar POIs especiais.

### Supermercado

Alta quantidade de comida.

### Ambulância

Medicamentos.

### Viatura

Munição.

### Oficina

Componentes.

### Posto

Combustível.

### Casa segura

Possibilidade de encontrar sobreviventes.

| POI | Recompensa principal | Ameaça típica | Onde aparece |
| --- | -------------------- | ------------- | ------------ |
| Supermercado | muita comida | grupo de zumbis comuns | Bairro, Mercado |
| Ambulância | medicamentos | runners | Centro, Hospital |
| Viatura | munição | blindado | Centro, Zona Industrial |
| Oficina | componentes | bruto | Mercado, Zona Industrial |
| Posto | combustível | explosivos (reação em cadeia) | todas |
| Casa segura | sobrevivente garantido | horda na saída | todas |

## Regras

* um POI é um chunk artesanal **raro**, reconhecível de longe (placa e silhueta próprias);
* o loot fica concentrado numa faixa guardada: pegar tudo exige arriscar;
* no máximo 1 POI na Curta e na Média, 2 na Longa, 3 na Especial;
* a preparação da expedição pode mostrar um **rumor** ("dizem que há uma viatura no Centro") — ✅ com o power-up Mapa marcado (seção 64), que ao partir diz o primeiro local especial da rota principal e a que distância; sem ele, a preparação lista os POIs possíveis da região;
* ✅ implementado: cada chunk do meio tem 6–9% de chance de virar POI, até o limite da distância, e cada POI aparece no máximo uma vez por expedição — cerca de metade das expedições curtas tem um; a Especial quase sempre tem três. Aviso no HUD ~40 m antes;
* ✅ baús (padrão `R`): Supermercado 16 comida + 6 água; Ambulância 6 medicamentos + 4 água; Viatura 32 munição + 2 componentes; Oficina 8 componentes + 8 sucata; Posto 10 combustível + 6 sucata; Casa segura: sobrevivente garantido e horda ao entrar;
* os chunks Supermercado e Posto do Bairro já existem como chunks comuns; a versão POI é rara e rende bem mais.

Referência de desenho: Last Day on Earth (seção 61).

---

# 27. EVENTOS PROCEDURAIS

**Status:** ✅ todos os cinco. A seed sorteia os chunks com evento (chance por região: 20% Bairro, 30% Centro, 40% Zona Industrial) e um aviso aparece no HUD ao se aproximar.

Eventos podem aparecer durante uma expedição.

Exemplos:

### Sobrevivente

Um NPC pede ajuda.

### Horda

Um grupo de zumbis começa uma perseguição.

### Explosão

Parte da rota fica bloqueada.

### Caminhão

Um veículo cai na pista.

### Recurso raro

Surge uma oportunidade de alto risco.

## Valores atuais

| Evento | Protótipo |
| ------ | --------- |
| Sobrevivente | encoste para resgatar; vira morador só se você extrair e houver vaga |
| Horda | 4 + metade da dificuldade zumbis surgem à frente, já perseguindo |
| Explosão | tremor, ruído e fogo bloqueando faixas |
| Caminhão | caminhão tombado bloqueia duas faixas vizinhas |
| Recurso raro | 8 sucata + 12 munição guardadas por zumbis |

---

# 28. DISTÂNCIA DA EXPEDIÇÃO

**Status:** ✅ Curta, Média, Longa e Especial (liberadas nos níveis 1, 2, 5 e 9; até 1, 1, 2 e 3 locais especiais e 1, 2, 3 e 3 bifurcações). Mais longe = mais eventos, loot e XP; o consumo diário é o mesmo — o custo da distância é o risco.

As missões possuem diferentes tamanhos.

### Curta

500 m

### Média

1 km

### Longa

2 km

### Especial

3 km+

Quanto maior a expedição:

* maior o risco;
* maior o consumo;
* melhores recompensas;
* maior chance de eventos raros.

---

# 29. SISTEMA DE DIFICULDADE

**Status:** 🟡 a dificuldade é expressa pelos dados de cada região (padrões, pesos de zumbi, bônus de loot, chance de evento); o número de 1 a 10 dimensiona a horda. ✅ O Director (seção 30) varia a intensidade dentro da expedição. 📋 Uma DifficultyData que junte região + distância num teto de intensidade ainda não se pagou.

O gerador recebe um nível de dificuldade.

```text
Difficulty = 1
```

até:

```text
Difficulty = 10
```

Isso influencia:

* quantidade de zumbis;
* velocidade;
* frequência de obstáculos;
* quantidade de eventos;
* qualidade do loot;
* duração;
* probabilidade de hordas.

---

# 30. EXPEDITION DIRECTOR

**Status:** ✅ implementado (Fase 10). Valores: calmo nos primeiros 12% (ruído atrai 30%); tensão depois de 16 s sem ameaça (+2 zumbis no chunk que carrega, ruído atrai 150%); alívio quando a tensão passa de 75, por 12 s (nenhum zumbi atraído, +1 loot no chunk); clímax nos últimos 15% com uma horda menor (−2) só na Longa e na Especial. A fase aparece discreta no HUD, ao lado da seed.

Um sistema controla dinamicamente a intensidade da expedição.

```text
             EXPEDITION
               DIRECTOR
                  │
      ┌───────────┼───────────┐
      ▼           ▼           ▼
   ZUMBIS       LOOT       EVENTOS
```

Se o jogador passou muito tempo sem perigo:

→ aumenta a tensão.

Se acabou de enfrentar uma horda:

→ reduz temporariamente a intensidade.

O objetivo é criar ritmo:

```text
CALMO
 ↓
TENSÃO
 ↓
PERIGO
 ↓
ALÍVIO
 ↓
PERIGO
 ↓
CLÍMAX
 ↓
EXTRAÇÃO
```

## Medir a tensão

A cada segundo, uma tensão de 0 a 100 é calculada a partir de:

* dano recebido nos últimos 10 s;
* zumbis a menos de 15 m e agarrão ativo;
* ruído (seção 34);
* HP baixo;
* tempo sem ameaça (reduz a tensão — e, se durar demais, o Director quer subir o ritmo).

## Ritmo

| Fase | Quando | O que o Director faz |
| ---- | ------ | -------------------- |
| Calmo | primeiros ~15% da rota | extras mínimos, loot fácil |
| Tensão | tensão baixa por muito tempo | zumbis extras nas linhas vazias |
| Perigo | pico | libera eventos e hordas opcionais |
| Alívio | 8–15 s após um pico, ou tensão > 80 | nenhum extra, loot de recompensa |
| Clímax | últimos ~15% | horda garantida perto da extração |

## Limite: a seed manda na estrutura

O Director **não altera** a sequência de chunks, os obstáculos nem os
padrões sorteados pela seed. Ele decide só os **extras** do próximo chunk
(que ainda não foi carregado): zumbis adicionais, loot bônus e o momento
dos eventos opcionais. Os zumbis extras por ruído de hoje (seção 34) viram
uma das entradas do Director.

Referência de desenho: Left 4 Dead (seção 61).

---

# 31. LOOT

**Status:** 🟡 comida, água, sucata, munição, componentes, medicamentos e combustível ✅ (seção 62; loot de 1–3 unidades, sucata 2–4, munição 3–6, componentes e medicamentos 1–2) · peças, armas e materiais raros: por enquanto só pelo evento Recurso raro (que agora também traz 2 medicamentos).

Durante a corrida podem aparecer:

* comida;
* água;
* sucata;
* componentes;
* medicamentos;
* munição;
* peças;
* armas;
* materiais raros.

O jogador deve escolher entre segurança e recompensa.

```text
🏃
   ↓
💧
```

Pegar o recurso pode obrigar o jogador a mudar de faixa.

---

# 32. INVENTÁRIO

**Status:** ✅ por **peso**, sem slots (decisão: um único limite é mais claro na tela do celular). Mochila 25 → 35 → 50 kg na Oficina (+5 kg com perk). Comida e água pesam 1 kg, sucata 2 kg, munição 0,1 kg. Mochila cheia: o loot fica na pista.

O inventário possui:

* slots;
* peso;
* capacidade máxima.

Exemplo:

```text
MOCHILA
████████░░

Peso:
18 / 25 kg
```

A mochila também pode ser melhorada no abrigo.

---

# 33. RISCO E RECOMPENSA

**Status:** ✅ risco maior com a distância, os eventos e o ruído · decidir voltar mais cedo: a **Saída antecipada** de uma bifurcação (Longa e Especial, depois de 40% da rota) encerra a expedição com o loot inteiro, mas sem o bônus de +50 XP da extração completa.

Quanto mais tempo o jogador permanece na expedição:

```text
RECOMPENSA ↑
RISCO ↑
```

A ameaça aumenta conforme:

* distância;
* tempo;
* número de zumbis eliminados;
* barulho;
* exploração;
* eventos.

O jogador pode decidir:

> "Já consegui recursos suficientes. É hora de voltar."

---

# 34. SISTEMA DE RUÍDO

**Status:** ✅ faca 0, pistola +1 por tiro, zumbi explosivo +10, evento de explosão +4; máximo 10, cai 0,5/s; o perk Passos leves reduz 25%. O ruído aumenta a distância de detecção e faz surgir zumbis extras já alertas. SMG (+4) e escopeta (+6) chegam com a seção 35.

Armas diferentes produzem níveis diferentes de ruído.

Exemplo:

| Ação     | Ruído |
| -------- | ----: |
| Faca     |     0 |
| Pistola  |    +1 |
| SMG      |    +4 |
| Escopeta |    +6 |
| Explosão |   +10 |

Quanto maior o ruído:

→ maior a chance de atrair zumbis.

Isso cria uma escolha entre:

**matar rapidamente**

ou

**evitar chamar atenção.**

---

# 35. ARMAS DE FOGO

**Status:** ✅ pistola, escopeta e SMG, cada uma em 3 níveis (Fase 10). Escopeta: chumbos divididos entre os zumbis da faixa e das vizinhas, perdendo até metade da força no alcance máximo. SMG: rajada de 4–5 balas por toque.

Armas iniciais:

* pistola;
* escopeta;
* SMG.

A munição é limitada.

A arma de fogo é eficiente para controlar ameaças à distância.

Porém:

```text
Mais tiros
   ↓
Mais ruído
   ↓
Mais zumbis
```

## Papéis

| Arma | Dano | Cadência | Alcance | Ruído | Papel |
| ---- | ---: | -------- | ------- | ----: | ----- |
| Pistola ✅ | 35 → 45 → 55 | 0,3 → 0,24 s | 30 m, na faixa | +1 | precisa e barata |
| Escopeta ✅ | 6–7 chumbos de 15 → 21 | 1,1 → 0,8 s | 12–14 m, a faixa e as vizinhas; perde até metade da força | +6 | segura o Bruto e limpa um grupo perto; a melhor na defesa |
| SMG ✅ | rajada de 4–5 balas de 12 → 16 | 0,6 → 0,45 s entre rajadas | 25–28 m, na faixa | +4 por rajada | horda; gasta munição rápido |

* uma arma de fogo equipada por vez, escolhida na preparação da expedição;
* munição única (a do abrigo): 1 por disparo na escopeta, 1 por bala na SMG;
* fabricadas na Oficina nível 2 com componentes (seção 62); 3 níveis de upgrade, como a pistola;
* a mira automática atual vale para as três; a escopeta atinge tudo no cone.

Referência de desenho: Into the Dead 2 (seção 61).

---

# 36. SISTEMA DE ABRIGO

**Status:** ✅ abrigo 3D com salas que aparecem conforme são construídas (sala principal, depósito com caixas, oficina, gerador com luz, coletor, horta, cozinha, rádio, enfermaria, baterias, painéis, moradores) e o estágio Fortaleza: torres, barricadas, armadilhas e portão reforçado na frente (Fase 12). A câmera gira 360° em volta do abrigo: no PC, segurando o botão do meio do mouse e arrastando; no celular, segurando o dedo um instante e arrastando. As paredes altas entre a câmera e o abrigo somem. Ela também aproxima e afasta (rodinha do mouse ou pinça): até o abrigo ficar 150% e, afastando, a mesma distância para trás.

O abrigo é o centro permanente do jogo.

Não será apenas um menu.

O jogador poderá visualizar e evoluir fisicamente o local.

Inicialmente:

```text
🏚️ ESCONDERIJO
```

Posteriormente:

```text
🏠 ABRIGO
```

E futuramente:

```text
🏰 FORTALEZA
```

No protótipo: o **esconderijo** é a sala principal com o depósito e a
oficina; o **abrigo** cresce com produção, cozinha, enfermaria e moradores;
a **fortaleza** aparece com as defesas da seção 45 (torres, barricadas,
armadilhas e o portão reforçado na frente).

---

# 37. NECESSIDADES DO ABRIGO

**Status:** ✅ água, comida, energia e moral (Fase 8).

O abrigo possui quatro recursos principais:

```text
💧 Água
🍖 Comida
⚡ Energia
❤️ Moral
```

Cada recurso possui estados:

```text
NORMAL
 ↓
ATENÇÃO
 ↓
CRÍTICO
 ↓
ESGOTADO
```

## Estados atuais

| Estado | Condição | Efeito |
| ------ | -------- | ------ |
| Normal | 10 ou mais | — |
| Atenção | abaixo de 10 | aviso na barra (amarelo) |
| Crítico | abaixo de 5 | aviso na barra (laranja) |
| Esgotado | 0 | comida ou água esgotada: a próxima expedição começa com −25 HP cada |

Consumo diário: a sobrevivente come 3 e bebe 3; cada morador, 1 e 1.

## Moral

De 0 a 100, começando em 70. É do abrigo inteiro.

| Sobe | Cai |
| ---- | --- |
| refeição cozida na Cozinha: +3/dia | comida ou água esgotada: −10/dia |
| novo morador (resgatado e com vaga): +8 | morte na expedição: −6 |
| expedição extraída com loot: +3 | sobrevivente recusado por falta de vaga: −5 |
| Rádio: +2 / +4 por dia | ataque ao abrigo perdido: −15 (Fase 12) |

| Estado | Faixa | Efeito |
| ------ | ----- | ------ |
| Normal | 60–100 | tudo normal |
| Atenção | 35–59 | produção −15% |
| Crítico | 15–34 | produção −35%; moradores sem bônus de profissão |
| Esgotado | 0–14 | como Crítico, e a cada dia 35% de chance de um morador ir embora |

A moral cai aos poucos e sempre avisa antes: o jogador precisa ver a crise
chegando e ter tempo de agir.

Referência de desenho: This War of Mine (seção 61).

---

# 38. PRODUÇÃO

**Status:** ✅ todas (Fase 8).

O jogador poderá construir estruturas.

### Coletor de chuva

Produz água.

### Horta

Produz comida.

### Cozinha

Processa alimentos.

### Gerador

Produz energia.

### Painéis solares

Produzem energia.

### Baterias

Armazenam energia.

| Construção | Níveis | Efeito | Status |
| ---------- | ------ | ------ | ------ |
| Coletor de chuva | 0 → 2 | +2 / +4 água por dia | ✅ |
| Horta | 0 → 2 | +2 / +4 comida por dia | ✅ |
| Gerador | 0 → 2 | +4 / +8 energia por dia | ✅ |
| Cozinha | 0 → 2 | −1 / −2 comida no consumo diário; refeição quente: +3 moral por dia | ✅ |
| Painéis solares | 0 → 2 | +2 / +4 energia por dia, sem combustível | ✅ |
| Baterias | 0 → 2 | limite de energia 20 → 40 → 70 | ✅ |

**Decisão (combustível):** o Gerador nível 2 gasta 1 combustível por dia;
sem combustível, rende como o nível 1 (+4). O nível 1 nunca precisa de
combustível, para não travar o começo do jogo. É o que dá sentido aos
painéis solares e ao POI Posto.

A produção das construções é multiplicada pela moral (seção 37).

---

# 39. CONSTRUÇÃO

As construções serão divididas em categorias.

## Suporte

* depósito;
* oficina;
* enfermaria;
* dormitórios.

## Produção

* horta;
* cozinha;
* coletor;
* gerador;
* painéis solares.

## Defesa

* barricadas;
* torres;
* armadilhas;
* portões.

**Status por item:**

| Categoria | ✅ implementado | 📋 planejado |
| --------- | --------------- | ------------ |
| Suporte | depósito (60 / 120 / 250), oficina (nível 1 → 2), dormitório (+2 / +4 vagas), enfermaria (41), baterias (38), rádio (+2 / +4 moral, seção 37) | — |
| Produção | horta, coletor, gerador, cozinha, painéis solares | — |
| Defesa | portão (300 / 450 / 600), barricadas, armadilhas, torres (45) | — |

Limite de escopo (seção 54): cerca de 15 construções no total, cada uma com
até 3 níveis.

---

# 40. OFICINA

**Status:** 🟡 reparar a arma branca equipada, fabricar e melhorar as 8 armas, fabricar munição e componentes, melhorar a mochila, fabricar o Escudo de caçamba e melhorar os power-ups (seção 64) ✅ · kit médico ✅ (vem da Enfermaria) · colete 📋.

A oficina é responsável por:

* fabricar armas;
* melhorar armas;
* reparar armas;
* fabricar munição (8 balas por 2 sucata + 2 energia);
* produzir componentes;
* criar equipamentos.

A oficina é fundamental para a progressão.

---

# 41. ENFERMARIA

**Status:** ✅ níveis 1 e 2 (Fase 8) · tratar moradores feridos 📋 (na defesa da Fase 12 os moradores não se ferem; fica para quando houver ferimento de morador).

Permite:

* curar personagem;
* tratar ferimentos;
* desbloquear melhorias;
* futuramente tratar sobreviventes.

| Nível | Custo | Efeito |
| ----- | ----- | ------ |
| 1 | 15 sucata + 2 componentes | trata **ferimentos**: morrer deixa a personagem Ferida (HP máximo 80% na expedição seguinte — era 2 no plano; 1 evita a espiral de mortes seguidas); a Enfermaria cura com 2 medicamentos. Também anula a fraqueza por fome/sede (−25 HP) da próxima expedição com 1 medicamento |
| 2 | 30 sucata + 4 componentes + 2 medicamentos (Oficina 2) | a expedição leva 1 **kit médico** (botão KIT ou H: cura 30 HP, uma vez; gasta 1 medicamento quando usado) · trata moradores feridos nos ataques (seção 45, Fase 12) |

Os tratamentos ficam no painel Sobrevivente (SAÚDE E MORAL). O Médico(a) no
abrigo tira 1 medicamento do tratamento de ferimento e mantém o bônus atual
(+15 HP máximo). Ferimento e doença são a razão de ir ao Hospital (Fase 9).

Referência de desenho: This War of Mine (seção 61).

---

# 42. PROGRESSÃO DO PERSONAGEM

**Status:** ✅ XP por zumbi (seção 17), +1 a cada 10 m e +50 ao extrair (na morte fica metade). Próximo nível = 150 + 75 × (nível − 1), máximo 20. Cada nível dá 1 ponto de atributo e 1 de perk; até 10 pontos por atributo.

A personagem recebe XP durante as expedições.

```text
XP
 ↓
NÍVEL
 ↓
ATRIBUTOS
 ↓
PERKS
```

Atributos:

* Vigor;
* Agilidade;
* Precisão;
* Força;
* Sobrevivência.

| Atributo | Por ponto (atual) |
| -------- | ----------------- |
| Vigor | +10 HP máximo |
| Agilidade | +6% de velocidade na troca de faixa |
| Precisão | +2% de crítico |
| Força | +5% de dano com a faca |
| Sobrevivência | −4% de dano recebido |

---

# 43. PERKS

**Status:** ✅ quatro perks por árvore, cada um exigindo pontos já gastos na própria árvore. Combate: Lâmina afiada, Olho clínico, Mãos rápidas, Couro grosso. Exploração: Mochila bem arrumada, Faro para loot, Catadora, Passos leves. Abrigo: Organizada, Agricultora, Mãos à obra, Ração controlada.

Três árvores:

## COMBATE

* dano;
* crítico;
* recarga;
* resistência.

## EXPLORAÇÃO

* mochila;
* loot;
* recursos;
* redução de ruído.

## ABRIGO

* produção;
* eficiência;
* construção;
* capacidade.

---

# 44. SOBREVIVENTES

**Status:** ✅ resgate, vagas, profissões, personalidade, relacionamento e pedidos (Fase 11).

NPCs são encontrados nas expedições (evento Sobrevivente e local especial
Casa segura).

Os resgatados que chegam vivos à extração, e cabem no abrigo, viram moradores.

Cada sobrevivente possui:

* profissão;
* habilidade;
* bônus;
* personalidade;
* relacionamento.

Exemplos:

**Médico**

* tratamento.

**Engenheiro**

* construção.

**Agricultor**

* produção de comida.

**Soldado**

* defesa.

## Atual

O resgatado só vira morador se a personagem extrair (morrer = perdido) e
houver vaga (1 na sala principal + Dormitório). Cada morador come 1 e bebe 1
por dia.

| Profissão | Bônus atual | Depois |
| --------- | ----------- | ------ |
| Médico(a) | +15 HP máximo | reduz o custo da Enfermaria (41) |
| Engenheiro(a) | −15% de sucata nos custos | — |
| Agricultor(a) | +2 comida por dia | — |
| Soldado | +10% de dano com a faca | ✅ na defesa: torres 50% mais rápidas (sem torre, atira do muro) |

## Personalidade

Cada morador recebe **1 traço** ao ser resgatado:

| Traço | Efeito |
| ----- | ------ |
| Otimista | perdas de moral do abrigo 25% menores; +1 de moral por dia ao grupo |
| Pessimista | perdas de moral do abrigo 25% maiores; em troca, bônus de profissão +25% |
| Leal | nunca vai embora por moral baixa |
| Egoísta | come +1 por dia; bônus de profissão +50% |
| Medroso | não luta na defesa; +1 de produção por dia no abrigo |

## Relacionamento

Uma afinidade de 0 a 100 com o grupo, começando em 40:

* +2 por dia com comida e água em Normal; +5 quando a personagem volta viva com loot;
* −10 quando falta comida ou água; −5 quando um novo resgatado é recusado;
* com afinidade de 75 ou mais, o bônus da profissão sobe 50% e o morador pode fazer um **pedido** ("traga remédio do Hospital") que rende XP e moral;
* com afinidade de 20 ou menos e moral Crítica, é o primeiro a ir embora;
* ✅ implementado: pedido = trazer recursos (entregues pelo painel Sobrevivente) ou voltar vivo de uma expedição numa região; 30% de chance por dia com afinidade 75+, prazo de 5 dias; cumprir dá +80 XP, +5 moral e +10 afinidade; expirar custa −5.

**Decisão:** a moral continua **do abrigo** (seção 37), não de cada morador.
Os traços mudam como ela varia (multiplicam as perdas, somam por dia), para o
jogador ler um número só na barra superior.

Limite de escopo (seção 54): até 8 moradores e nenhuma árvore de diálogo.

Referência de desenho: This War of Mine (seção 61).

---

# 45. DEFESA DO ABRIGO

**Status:** ✅ implementado (Fase 12). Valores reais nas subseções abaixo.

**Decisão de câmera:** o portão fica **à frente** da personagem (que fica no
pátio, logo atrás dele). Assim a mira automática e a arma branca funcionam
como na corrida: os zumbis que chegam ao portão estão ao alcance.

Hordas atacam o abrigo.

```text
🏠 ABRIGO
   ↑
🧟🧟🧟
🧟🧟🧟
```

O jogador deverá preparar:

* barricadas;
* torres;
* armadilhas;
* sobreviventes;
* armas.

## Formato

A defesa usa **o mesmo motor da expedição, invertido**: a personagem fica
no portão do abrigo e a horda desce pelas três faixas. Faca, armas de fogo,
agarrão, zumbis e HUD são os mesmos — não é um modo de jogo novo.

## Ritmo

* primeiro ataque no dia 8, depois a cada 9 dias (8, 17, 26, 35…), avisado 2 dias antes no fechamento do dia e na barra do abrigo;
* no dia do ataque, não dá para sair em expedição antes de defender;
* horda = 6 + 0,3 zumbi por dia + 0,04 por ponto de ruído das últimas expedições (máximo 40);
* os tipos entram com o tempo: runners a partir do dia 8, brutos e explosivos do 15, blindados do 22;
* a horda chega ao longo de ~60 s; depois é lutar até o último.

**Decisão de balanceamento (0.5.2):** com ataques a cada 7 dias e a horda
crescendo 0,5 por dia, até um robô cauteloso perdia todas as defesas do dia
22 em diante: a sucata que entra (a mochila volta cheia em quase toda
expedição) não pagava munição, energia e as defesas de nível 2. Com 9 dias,
0,3 por dia e munição mais barata, o robô cauteloso vence 14 de 16 defesas
em 36 dias e o ganancioso, 4 de 8 — preparar-se compensa, descuidar pune.

## Defesas

| Construção | Função |
| ---------- | ------ |
| Portão | é o HP do abrigo: 300 / 450 / 600 |
| Barricada | uma por faixa, mais à frente: 80 / 160 de HP; os zumbis param nela até derrubá-la |
| Armadilha | uma por faixa: explode uma vez por ataque, 80 / 150 de dano em área |
| Torre | 1 / 2 torres: tiro automático (30 de dano) no zumbi mais perto do portão; gasta a munição da personagem |
| Sobreviventes | cada Soldado(a) deixa as torres 50% mais rápidas (sem torre, até dois atiram do muro); cada morador que não é Medroso(a) reforça portão e barricadas em 12% |

Os zumbis causam 75% do dano normal nas estruturas.

## Vitória e derrota

* **Vitória** (horda eliminada): XP dos abates + 100, +5 de moral, +5 de afinidade.
* **Derrota** (portão a 0, personagem a 0 ou abandonar): perde 25% de cada recurso do depósito, −15 de moral e −5 de afinidade. Nunca perde construções nem o save — mesma filosofia da seção 46.

Referência de desenho: Last Day on Earth (seção 61).

---

# 46. MORTE / FALHA DA EXPEDIÇÃO

**Status:** ✅ na morte fica metade do loot (o perk Catadora aumenta); melhorias, construções e XP já ganhos permanecem. A tela de resultado mostra obtido × recuperado.

Quando a personagem chega a:

```text
❤️ 0
```

a expedição termina.

Parte dos recursos coletados é perdida.

Porém, upgrades permanentes permanecem.

Exemplo:

```text
EXPEDIÇÃO

Obtido:
🍖 15
💧 10
🔩 20

MORTE

Recuperado:
🍖 7
💧 4
🔩 10
```

A evolução do abrigo permanece.

Isso mantém a sensação:

> "Perdi a expedição, mas não perdi todo o meu progresso."

---

# 47. RECUPERAÇÃO DE MOCHILA

**Status:** ✅ implementado (Fase 9).

Quando o jogador morre:

```text
💀 LOCAL DA MORTE
```

Uma próxima expedição permite recuperar os itens deixados para trás.

Isso cria uma situação de risco/recompensa:

> "Voltar ao local onde morri vale a pena?"

* ao morrer, a parte perdida (seção 46) fica numa mochila no ponto da morte;
* o abrigo guarda a região, a seed e a distância daquela expedição;
* durante 3 expedições, a preparação oferece **"Voltar ao local da morte"**: mesma região, seed e distância — a rota é idêntica e a mochila está no ponto exato;
* o chunk da mochila tem mais zumbis (3 a mais, perto dela);
* morrer de novo antes de recuperar substitui a mochila antiga pela nova;
* recuperar respeita o peso da mochila atual;
* a mochila aparece numa faixa livre de obstáculo no ponto exato, com aviso no HUD ~40 m antes (3 zumbis a mais em volta);
* no abrigo, o painel Expedição mostra "Voltar ao local da morte" com o conteúdo e o prazo; escolher outra região ou distância cancela a volta.

Referência de desenho: Last Day on Earth (seção 61).

---

# 48. FLUXO DE CENAS

**Status:** ✅ Menu → Abrigo → Preparação → Run → Extração → Abrigo (com o fechamento do dia). Na morte: Run → Resultado → Abrigo. No dia do ataque: Abrigo → Defesa → Abrigo. Fade entre todas as cenas.

```text
BOOT
  ↓
MAIN MENU
  ↓
SHELTER
  ↓
EXPEDITION PREPARATION
  ↓
PROCEDURAL GENERATION
  ↓
RUN
  ↓
EXTRACTION
  ↓
SHELTER
```

Em caso de morte:

```text
RUN
 ↓
0 HP
 ↓
DEFEAT
 ↓
RESULTADO
 ↓
SHELTER
```

No dia do ataque (seção 45):

```text
SHELTER
 ↓
DEFESA
 ↓
VITÓRIA / DERROTA
 ↓
SHELTER
```

---

# 49. ARQUITETURA (GODOT)

**Status:** ✅ a versão 0.3 previa Unity; o projeto foi feito em **Godot 4.7**
com GDScript. A divisão por responsabilidade foi mantida:

```text
autoload/            (singletons, sempre carregados)
├── GameManager      estado do jogo e os fechamentos da expedição e da defesa
├── SaveManager      save em user://save.json
├── Settings         volumes, tremor de câmera, tutorial
├── AudioManager     canais Music / SFX / UI, pool de players
└── Transition       fade entre cenas (o SceneManager do plano)

scenes/              main_menu, shelter, run, result e defense (.tscn + .gd)

scripts/
├── player_*         controller, health, combat (arma branca, de fogo, agarrão)
├── zombie.gd        IA, HP, agarrão, golpe, explosão; modo defesa
├── expedition/      route_generator, chunk_populator, chunk_streamer,
│                    expedition_events, expedition_director, mesh_merger, tutorial
├── shelter/         construction, production, workshop, infirmary,
│                    residents e os painéis
├── progression/     XP, níveis, atributos e perks
├── ui/              configurações e pausa
└── data/            classes de Resource (seção 50)
```

| Módulo do plano 0.3 | Onde ficou |
| ------------------- | ---------- |
| SceneManager | autoload `Transition` |
| PlayerInventory | mochila por peso em `run.gd` e `GameManager` |
| DamageSystem / GrabSystem | `player_health`, `player_combat`, `zombie` |
| ZombieSpawner / LootGenerator / EventGenerator | `chunk_populator` + `expedition_events` |
| SeedManager | `GameManager` + `route_generator` |
| ResourceManager / ProductionManager | `GameManager` + `shelter/production` |
| SurvivorManager | `GameManager` (lista de moradores) + `shelter/residents.gd` (traços, afinidade, pedidos) |
| ExpeditionDirector | `expedition/expedition_director.gd` (nó `Director` da Run) |

---

# 50. DADOS (RESOURCES)

Dados separados da lógica. No Godot, o equivalente aos ScriptableObjects são
os **Resources** (`.tres`), editáveis no Inspector.

| Plano 0.3 | Resource no projeto | Status |
| --------- | ------------------- | ------ |
| WeaponData | `WeaponData`, `RangedWeaponData`, `WeaponTrack` (níveis) | ✅ |
| ZombieData | `ZombieData` | ✅ |
| BuildingData | `BuildingData` | ✅ |
| ChunkData | `ChunkData` | ✅ |
| RegionData | `RegionData` (inclui tabela de loot e pesos de zumbi) | ✅ |
| EventData | `EventData` | ✅ |
| PerkData | `PerkData`, `AttributeData`, `ProgressionData` | ✅ |
| SurvivorData | `ProfessionData` + `TraitData` + dicionário do morador no save (nome, profissão, traço, afinidade, pedido) | ✅ |
| LootTableData | dentro de `RegionData` e `ChunkData` | ✅ |
| ObstaclePatternData | lista de padrões em texto na `RegionData` (seção 22) | ✅ |
| MissionData | `WorldData` (regiões, distâncias, liberação) | ✅ |
| ResourceData | lista `RESOURCE_KEYS` / `LOOT_KEYS` no `GameManager` (8 recursos, pesos e loot no `ShelterData`) — um Resource por recurso não se pagou | ✅ |
| DifficultyData | parâmetros exportados do nó `Director` + dados da região; `BranchData` para os caminhos das bifurcações | 🟡 |

Também existem `ShelterData` (regras do abrigo e da defesa: consumo, limites,
moral, enfermaria, horda, torres), `BranchData` (caminhos das bifurcações) e
`WorldData` (regiões, distâncias, profissões, traços, pedidos).

---

# 51. PERFORMANCE MOBILE

**Status:** 🟡 chunk streaming ✅ (até 120 m à frente, 1 chunk por frame) · pooling de efeitos e de áudio ✅ · pooling de zumbis e pickups 📋 (só se o profiler pedir) · projéteis não precisam de pool: os tiros são instantâneos. Medido no protótipo: de 688 para ~197 draw calls com a mescla de geometria por material; shaders e fontes pré-aquecidos na transição para evitar engasgos.

O jogo deverá ser desenvolvido desde o início considerando celulares intermediários.

Será utilizado:

### Object Pooling

Para:

* zumbis;
* projéteis;
* efeitos;
* pickups;
* obstáculos.

### Chunk Streaming

Somente os chunks próximos ao jogador permanecem ativos.

```text
CHUNK
CHUNK
CHUNK
  🏃
CHUNK
CHUNK
```

Chunks distantes são descarregados.

---

# 52. PROCEDURAL + HANDMADE

**Status:** ✅ chunks artesanais + padrões, loot, zumbis e eventos procedurais.

O cenário não será 100% procedural.

Estratégia:

> **Conteúdo artesanal + combinação procedural.**

Os artistas criam chunks de alta qualidade.

O sistema combina:

* chunks;
* padrões;
* inimigos;
* loot;
* eventos;
* rotas.

Isso permite alta qualidade visual sem sacrificar a rejogabilidade.

---

# 53. MVP — VERTICAL SLICE

**Status:** ✅ todo o escopo abaixo foi entregue — e além dele: Explosivo e Blindado, 3 regiões, eventos, sobreviventes, atributos, perks, áudio e tutorial.

A primeira versão jogável deverá conter:

## Personagem

* 1 personagem;
* corrida automática;
* troca de faixa;
* salto;
* slide;
* HP.

## Combate

* pistola;
* faca;
* ataque de emergência;
* zumbi com HP;
* sistema de agarrão;
* dano por segundo.

## Zumbis

* comum;
* runner;
* bruto.

## Procedural

* 1 região;
* 8–12 chunks;
* 3 faixas;
* obstáculos;
* loot;
* seed;
* geração de rota.

## Expedição

* início;
* corrida;
* loot;
* combate;
* extração;
* morte.

## Abrigo

* sala principal;
* depósito;
* oficina;
* gerador;
* recursos.

## Progressão

* XP;
* níveis;
* upgrade da faca;
* upgrade da pistola.

---

# 54. FORA DO MVP

Não implementar inicialmente:

* multiplayer;
* PvP;
* mundo aberto gigante;
* veículos;
* dezenas de sobreviventes;
* centenas de construções;
* clima complexo;
* ciclo completo de estações;
* centenas de armas;
* monetização;
* servidores;
* sistemas online;
* narrativa extremamente complexa.

Limites numéricos adotados: até **8 moradores**, cerca de **15 construções**
(3 níveis cada) e **5 regiões**.

---

# 55. EXEMPLO DE UMA RUN

```text
🏠 ABRIGO
    ↓
Preparar equipamento
    ↓
🔫 Pistola
🔪 Faca
🎒 Mochila
    ↓
🏃 INICIAR
    ↓
Rua residencial
    ↓
💧 Água
    ↓
🚧 Obstáculo
    ↓
🧟 Zumbi
    ↓
Troca de faixa
    ↓
🧟 Runner
    ↓
GRAB!
    ↓
❤️ 100 → 92 → 84
    ↓
🔪 ATAQUE
    ↓
🧟 100 → 70 → 35 → 0
    ↓
💀
    ↓
🏪 Mercado
    ↓
🍖 Comida
    ↓
🔀 Bifurcação
    ├── Hospital
    └── Garagem
    ↓
Escolha Hospital
    ↓
🧟🧟🧟 HORDA
    ↓
🏃 FUGA
    ↓
❤️ 48
    ↓
🚪 EXTRAÇÃO
    ↓
🏠 ABRIGO
    ↓
🔧 Melhorar faca
    ↓
❤️ Recuperação
    ↓
Nova expedição
```

---

# 56. IDENTIDADE DO JOGO

A experiência desejada pode ser resumida em:

> **"Você não está apenas correndo para sobreviver. Você está correndo para construir um lugar onde possa sobreviver."**

O abrigo dá significado à corrida.

A corrida fornece recursos para o abrigo.

O abrigo melhora a personagem.

A personagem permite chegar mais longe.

Chegar mais longe desbloqueia regiões mais perigosas.

E regiões mais perigosas fornecem recursos melhores.

```text
       🏠 ABRIGO
          ↑
          │
       RECURSOS
          ↑
          │
       🏃 RUN
          ↑
          │
       UPGRADE
          ↑
          │
       🏠 ABRIGO
```

Esse ciclo é o coração de **RED SHELTER**.

---

# 57. VISÃO DO PRODUTO

O objetivo não é criar simplesmente:

> "Subway Surfers com zumbis."

O objetivo é criar um **Survival Runner com progressão persistente e gerenciamento de abrigo**.

A corrida deve fornecer a adrenalina.

O combate deve fornecer tensão.

O procedural deve fornecer variedade.

O loot deve fornecer decisões.

O abrigo deve fornecer progressão.

E a combinação dos sistemas deve criar o desejo de fazer:

> **"Só mais uma run."**

---

# 58. ROADMAP DE DESENVOLVIMENTO

## ✅ Fase 1 — Protótipo

* personagem;
* câmera;
* três faixas;
* corrida;
* obstáculos;
* zumbi;
* HP;
* agarrão;
* faca.

## ✅ Fase 2 — Procedural

* chunks;
* geração de rota;
* seed;
* loot;
* spawning;
* streaming.

## ✅ Fase 3 — Combate

* pistola;
* faca;
* diferentes zumbis;
* dano;
* efeitos;
* animações.

## ✅ Fase 4 — Abrigo

* construção;
* recursos;
* oficina;
* upgrades;
* inventário.

## ✅ Fase 5 — Progressão

* XP;
* níveis;
* perks;
* upgrades de armas.

## ✅ Fase 6 — Conteúdo

* novas regiões;
* novos chunks;
* novos zumbis;
* eventos;
* sobreviventes.

## ✅ Fase 7 — Polimento

* UI;
* áudio;
* VFX;
* otimização;
* tutorial;
* balanceamento.

## ✅ Fase 8 — Economia do abrigo

* componentes, medicamentos e combustível (seção 62);
* moral (37);
* cozinha, enfermaria, painéis solares, baterias e rádio (38–41).

## ✅ Fase 9 — Mundo

* regiões Mercado e Hospital (25);
* POIs especiais (26);
* distância Especial (28);
* recuperação de mochila (47).

## ✅ Fase 10 — Expedição viva

* bifurcações e extração antecipada (24, 33);
* Expedition Director (30);
* escopeta e SMG (35);
* armas brancas novas (11).

## ✅ Fase 11 — Pessoas

* personalidade e relacionamento dos sobreviventes (44);
* pedidos dos moradores.

## ✅ Fase 12 — Defesa

* ataques ao abrigo (45);
* barricadas, torres, armadilhas e portão;
* soldados e moradores ajudando na defesa (44).

## ✅ Fase 13 — Veículos

A base de "item especial na pista" (placa antes, barra no HUD, estado
montada) serve também para os power-ups da Fase 14, por isso vem primeiro.

* ✅ **V1** — base: `VehicleData`, estado "montada" na personagem, HP e tempo do veículo no HUD, regras de aparecimento; patins e skate (63);
* ✅ **V2** — bicicleta de jornaleiro (dois jornais como projéteis) e moto (atropelar, combustível, ruído);
* ✅ **V3** — mochila a jato (segurar para voar, barra de calor, explosão);
* ✅ **V4** — furgão de destruição (2 faixas, metralhadora no teto) e o ramo Garagens com mais veículos (24);
* robô de campanha medindo o efeito na sobrevivência e no loot.

## ✅ Fase 14 — Power-ups

* ✅ **P1** — base: `PowerUpData`, ícones com barra de tempo no HUD, aparecimento nos chunks; Ímã de sucata, Sinalizador e Escudo de caçamba (64);
* ✅ **P2** — Rota dos telhados, Rampa de entulho e Adrenalina;
* ✅ **P3** — os dois da preparação (Arrancada de moto, Mapa marcado) e os 6 raros;
* ✅ melhorias dos power-ups na Oficina (40);
* robô de campanha medindo o efeito na economia.

## 📋 Fase 15 — Direção de arte

* A1 base técnica (shader toon, contorno, textura-paleta, névoa por região);
* A2 assets P1; A3 personagem; A4 zumbis; A5 assets P2; A6 acabamento (65).

## Depois do roadmap

* balancear jogando de verdade, com o `campaign_log.csv` (economia com uma pessoa jogando, regiões avançadas);
* tratar moradores feridos na Enfermaria (41);
* espada e colete (11, 40);
* tipo de dano perfurante contra armadura (13);
* pooling de zumbis e pickups, se o profiler pedir (51).

## Em paralelo — Arte e áudio finais

Modelos low-poly no lugar das primitivas; sons e trilhas definitivos. Nada
na lógica depende disso: os chunks trocam só os modelos, e os sons trocam o
arquivo mantendo o nome.

A ordem segue as dependências: a Fase 8 cria os recursos que o resto
consome, e a defesa fica por último porque usa armas, componentes, o
Soldado e a moral. Os veículos (13) vêm antes dos power-ups (14) porque
criam a base que os dois usam.

---

# 59. DEFINIÇÃO DO VERTICAL SLICE

**Status:** ✅ o protótipo executa o ciclo inteiro, incluindo a **🔀 ESCOLHA** (bifurcações, Fase 10).

O Vertical Slice ideal deverá permitir executar o ciclo completo:

```text
🏠 ABRIGO
   ↓
Preparação
   ↓
🏃 RUN
   ↓
🧟 COMBATE
   ↓
🎒 LOOT
   ↓
🔀 ESCOLHA
   ↓
🧟 HORDA
   ↓
🚪 EXTRAÇÃO
   ↓
🏠 ABRIGO
   ↓
🔧 UPGRADE
   ↓
🏃 NOVA RUN
```

Se esse ciclo for divertido mesmo com apenas uma região e poucos inimigos, o projeto terá uma base sólida para expansão.

---

# 60. FRASE DE PITCH

> **Corra pela cidade, enfrente os mortos, saqueie o que conseguir e transforme um pequeno esconderijo no último lugar seguro do mundo.**

**RED SHELTER — Run. Survive. Build.**

---

# 61. JOGOS DE REFERÊNCIA

Cinco jogos de sucesso orientam os sistemas pós-slice. A ideia é estudar
**o que funciona neles**, não copiar.

| Jogo | O que aprender | Seções |
| ---- | -------------- | ------ |
| **Into the Dead 2** (PikPok, 2017, mobile) | O parente mais próximo: corrida contra zumbis no celular, armas de fogo com papéis distintos, munição escassa e upgrades entre as corridas. | 11, 35 |
| **Last Day on Earth: Survival** (Kefir, mobile) | Base atacada, com muros e portões melhorados por nível de material. O que se carregava fica no local da morte, e dá para voltar buscar. Locais fixos no mapa com loot característico. | 26, 45, 47 |
| **This War of Mine** (11 bit studios, 2014) | Abrigo com cozinha e coletor de chuva, onde cozinhar rende mais comida. Ferimentos e doenças que pedem remédio. Moral que piora aos poucos até a pessoa desabar. Traços de personalidade. Cada local de saque com risco e loot próprios. | 25, 37, 38, 41, 44 |
| **Left 4 Dead** (Valve, 2008) | O "AI Director": o mapa é fixo, e o diretor lê a tensão dos jogadores para alternar preparação, pico e alívio. | 29, 30 |
| **Hades** (Supergiant Games, 2020) | Toda saída mostra a recompensa antes da escolha: decisão rápida e informada, que não quebra o ritmo da ação. | 24, 33 |

O que **não** trazer:

* a gestão lenta e punitiva de This War of Mine (Red Shelter é um jogo de sessões curtas);
* a construção livre e o grind de Last Day on Earth (seção 54);
* a monetização desses jogos mobile (fora do escopo, seção 54).

---

# 62. ECONOMIA DE RECURSOS

**Status:** ✅ todos (Fases 8 e 9).

| Recurso | Vem de | Serve para | Peso na mochila | Status |
| ------- | ------ | ---------- | --------------: | ------ |
| 🍖 Comida | loot, Horta, Supermercado | consumo diário (3 + 1 por morador), Horta nível 2 | 1 kg | ✅ |
| 💧 Água | loot, Coletor | consumo diário, Horta | 1 kg | ✅ |
| 🔩 Sucata | loot | construções, reparo, munição, upgrades | 2 kg | ✅ |
| ⚡ Energia | Gerador, Painéis solares (limite: Baterias) | Oficina, munição, reparo, construções | — (só no abrigo) | ✅ |
| 🔫 Munição | loot, Oficina, Viatura | armas de fogo | 0,1 kg | ✅ |
| ⚙️ Componentes | Zona Industrial (Fábrica), Mercado, Centro, POI Oficina mecânica e Viatura, desmontar sucata na Oficina | Painéis, Baterias, Enfermaria, Rádio, Cozinha 2; depois armas, torres, armadilhas | 1 kg | ✅ |
| 💊 Medicamentos | Hospital, POI Ambulância, Centro (lojas), evento Recurso raro, um pouco no Bairro; ramo Farmácia (Fase 10) | Enfermaria, kit médico | 0,5 kg | ✅ |
| ⛽ Combustível | POI Posto de combustível, Posto, Engarrafamento, Estacionamento, Zona Industrial | Gerador nível 2 (seção 38); 📋 tanque da moto na corrida (63) e Arrancada de moto (64) | 2 kg | ✅ |
| ❤️ Moral | Cozinha, Rádio, resgates, extrações com loot | produção e bônus/permanência dos moradores | — | ✅ |

Regra geral: cada região e cada POI tem um recurso "assinatura". Assim o
jogador escolhe **para onde ir** conforme o que falta no abrigo — é aí que o
abrigo dá sentido à corrida (seção 56).

---

# 63. VEÍCULOS

**Status:** ✅ implementado (Fase 13, etapas V1–V4): base dos veículos, patins, skate, bicicleta de jornaleiro, moto, mochila a jato e furgão de destruição; o ramo Garagens tem mais veículos.

Valores atuais:

* **Aparecimento:** chance de 7% por chunk elegível (35% no ramo Garagens, que traz moto e furgão em qualquer região), no máximo um veículo a cada 200 m, nenhum nos primeiros 120 m (ou na fase Calma, o que for maior), nos últimos 150 m nem a 100 m de uma bifurcação; aviso uns 40 m antes.
* **Encontros:** o zumbi que agarra, empurrado pelo veículo, causa 10 de dano nele (20 na moto). Montar solta quem estava agarrando. Bicicleta, moto, mochila a jato e furgão não deslizam.
* **Bicicleta:** jornal com 50 de dano e 22 m de alcance, um lançamento a cada 0,4 s.
* **Moto:** ruído de 1,2 por segundo; pulo 2× (pico de ~3 m; o carro tem 2,5 m).
* **Mochila a jato:** sobe até 6 m (a 7 m/s no máximo) e plana com 35% da gravidade na descida; calor de +28% por segundo segurando e −18% soltando, com aviso em 80%; explosão de 20 de dano direto na personagem e 80 nos zumbis a até 4 m; o ímã puxa o loot até 14 m à frente, e na faixa do meio escolhe o lado com o loot mais perto, mantendo-o até ela trocar de faixa; ruído de 0,5 por segundo; a partir do nível 6.
* **Furgão:** atravessa carros (25 de HP), barreiras e placas (10) e zumbis (comum e runner 5, Blindado 15, Bruto 30, Explosivo 15 mais a explosão), que levam 200; metralhadora com 25 de dano, um tiro a cada 0,12 s, 30 m de alcance; ruído de 2 por segundo; troca de lado com metade da velocidade; não pula; para 30 m antes de uma bifurcação, porque não cabe num ramo; a partir do nível 7, em expedições de 1,5 km ou mais, e cerca de 1 a cada 6 expedições longas na Zona Industrial (simulado em 300 rotas); enquanto ela dirige, a câmera sobe 3 m e recua 3,5 m para o furgão não tapar a pista.

Durante a corrida aparecem veículos que ajudam e mudam um pouco o jeito de
jogar. Cada um tem **HP próprio**, uma **duração** e uma **habilidade**. Cada
um também tem uma **fraqueza**: é ela que faz o veículo mudar a jogabilidade,
em vez de só deixar a corrida mais fácil.

Os valores abaixo são o ponto de partida, na escala do protótipo: bater num
obstáculo tira 15, o golpe do Bruto 20, a explosão 25, o agarrão 8 por
segundo, e a personagem tem 100 de HP.

## Regras gerais

* **Aparecimento:** o veículo fica estacionado numa faixa, com uma placa uns 40 m antes. Para montar, basta encostar nele.
* **HP do veículo:** montada, todo dano vai para o veículo. O HUD mostra a barra de HP e o tempo restante.
* **Fim:** quando o HP ou o tempo zera, o veículo acaba. A personagem cai na faixa sem dano e fica 1 s invulnerável. A exceção é a mochila a jato, que pode explodir.
* **Agarrão:** montada, ninguém agarra a personagem; os zumbis batem no veículo.
* **Ruído (34):** moto e furgão fazem muito barulho, atraem zumbis na rota e somam ao ruído que aumenta a próxima horda (45). Bicicleta, skate e patins são silenciosos.
* **Onde não aparecem:** na fase Calma do Director (30), nos últimos 150 m antes da extração e a menos de 100 m de uma bifurcação (24). Na defesa do abrigo também não.
* **Loot:** montada, ela pega o loot normalmente, e a mochila continua limitando o peso (32).

## Os veículos

| Veículo | HP | Duração | Velocidade | Habilidade | Fraqueza |
| ------- | --: | ------- | ---------- | ---------- | -------- |
| **Patins** | 40 | 20 s | +15% | Pulo 1,6× mais alto; troca de faixa 30% mais rápida | Um agarrão derruba e quebra os patins na hora |
| **Skate** | 50 | 20 s | +20% | Os zumbis não param o skate: atravessa comuns e runners, derrubando-os (cada um custa 8 de HP do skate) | Não desliza (placas altas obrigam a trocar de faixa); um Bruto para o skate |
| **Bicicleta de jornaleiro** | 60 | 25 s | +25% | Cada toque lança **dois jornais**, que voam como projéteis: um na faixa da frente e outro na faixa do lado, como um tiro de escopeta; sem gastar munição (20 lançamentos) | Mãos ocupadas: sem pistola nem arma branca |
| **Moto** | 100 | 25 s de tanque (+5 s a cada combustível coletado) | +40% | Pula mais alto (passa por cima de carros); derruba zumbis e não sofre dano de zumbis fracos (comuns e runners) | Muito ruído; Brutos, Blindados e Explosivos ferem a moto; sem armas |
| **Mochila a jato** | 50 | 30 s | +10% | Segurar o botão faz a personagem voar mais tempo pela tela; puxa os itens da faixa dela e de uma faixa ao lado | Barra de calor: segurar demais esquenta e, no limite, ela explode (20 de dano na personagem; derruba os zumbis em volta); sem armas |
| **Furgão de destruição** | 300 | 30 s | +15% | Ocupa duas faixas e não é parado (atravessa paredes, barreiras e zumbis); metralhadora no teto atira sozinha nas 3 faixas, com 150 balas próprias | Cada batida tira HP (parede 25, Bruto 30, Explosivo 40); ruído máximo; troca de faixa lenta |

## Controles que mudam

* **Furgão:** como ocupa duas faixas, tem só duas posições, esquerda (faixas 1 e 2) e direita (faixas 2 e 3). Deslizar o dedo alterna entre elas.
* **Mochila a jato:** no celular, segurar o dedo em qualquer lugar faz subir; soltar faz planar e descer. No teclado, segurar o Espaço. Voando, ela passa por cima de tudo.
* **Bicicleta:** o toque, que normalmente atira com a arma de fogo, lança os dois jornais. Cada jornal é um projétil que percorre a faixa e acerta o primeiro zumbi dela. Nas faixas da ponta, o segundo jornal vai para a única faixa do lado; na faixa do meio, vai para o lado com o zumbi mais perto.

## O que cada um muda no jogo

| Veículo | Jogabilidade |
| ------- | ------------ |
| Patins | precisão nos pulos |
| Skate | atravessar a multidão |
| Bicicleta | vira um modo de tiro |
| Moto | velocidade e atropelar, pagando em ruído |
| Mochila a jato | controlar a altura e o risco de explodir |
| Furgão | o momento de poder máximo |

## Raridade e onde aparecem

| Veículo | Raridade | Onde |
| ------- | -------- | ---- |
| Patins, skate | comum (~1 a cada 2 expedições) | Bairro, Centro |
| Bicicleta | comum | Bairro, Mercado |
| Moto | incomum | Centro, Zona Industrial, ramo Garagens |
| Mochila a jato | rara (nível 6 ou mais) | Zona Industrial, Hospital |
| Furgão de destruição | muito rara (expedições de 1,5 km ou mais) | ramo Garagens, Zona Industrial |

O ramo **Garagens** das bifurcações (24) passa a ter chance maior de
veículo, o que dá à escolha do caminho mais um motivo.

## Dados

Um `VehicleData` (.tres) por veículo: HP, duração, multiplicadores de
velocidade, de pulo e de troca de faixa, faixas ocupadas, ruído por
segundo, habilidade, dano recebido de cada tipo de zumbi e de obstáculo,
raridade, regiões e distância mínima. Editável no Inspector, como o resto
do jogo (50).

---

# 64. POWER-UPS DA CORRIDA

**Status:** ✅ implementado (Fase 14, etapas P1–P3 e as melhorias): os 14 power-ups. Melhoram na Oficina o Ímã, o Sinalizador, a Rota dos telhados, a Adrenalina (durações dos níveis 2 e 3) e o Escudo (empurrão no 2, segundos sem dano no 3): nível 2 por 15 sucata + 3 componentes com a Oficina 1, nível 3 por 30 sucata + 6 componentes + 5 energia com a Oficina 2. A Rampa, os raros e os da preparação não melhoram. Valores da P3: a Arrancada de moto protege a moto nos primeiros 250 m; o Mapa marcado sai de graça com o Rádio nível 2 e mostra, ao partir, o primeiro local especial da rota principal; os raros aparecem com 22% de chance num chunk de local especial, 3,5% num de evento ou ramo e 0,3% nos outros (o Esconderijo), no máximo um a cada 300 m — cerca de 0,35 por expedição de 1 km (simulado em 300 rotas); a Mochila abandonada vira um power-up da pista metade das vezes, senão 3 medicamentos ou 4 componentes; o Segundo fôlego dá 2 s sem dano ao levantar; o Diário dá +50% em 1 de cada 5. Valores da P2: telhados a 8 m, com um item a cada 8 m por faixa (munição; componentes a cada três fileiras), sem pular nem deslizar lá em cima; ao acabar, desce na faixa com menos obstáculos e zumbis, com 1,5 s sem dano, e desce sozinha 40 m antes da extração (não aparece nos últimos 200 m); a rampa ajusta a gravidade à velocidade para saltar ~40 m com pico de ~5 m, dá 0,5 s sem dano ao pousar e não funciona no furgão nem na mochila a jato; a adrenalina dobra o XP dos abates e encurta 20% o intervalo dos golpes da arma branca. Valores da P1: chance de 30% por chunk elegível (×1,5 na fase Perigo, nenhum no Clímax), no máximo um a cada 230 m, nenhum nos primeiros e últimos 60 m nem no chunk de um veículo; o sinalizador acende onde a personagem está e os zumbis atraídos não agarram nem golpeiam (o Explosivo ainda acende o pavio); o escudo custa 4 sucata + 1 componente, guarda até 9, empurra com 40 de dano no nível 2 e dá 1 s sem dano no nível 3. Por enquanto todos ficam no nível 1.

Inspirados nos power-ups de **Subway Surfers**: a página de power-ups da
wiki do jogo lista 14 disponíveis. Aqui são 14 também, nos mesmos papéis,
com tema de sobrevivência.

Na referência, eles se dividem em quatro grupos: **5 principais**
coletados na pista (Coin Magnet, 2X Multiplier, Super Sneakers, Jetpack e
Pogo Stick; quatro deles melhoram em 6 níveis, +5 s por nível, até 30 s);
**1 consumível** ativado com toque duplo (Hoverboard, comprado, quebra na
próxima batida); **2 de início de corrida**, comprados (Headstart e Score
Booster); e **6 limitados**, de eventos e anúncios (Super Mysterizer,
Hourglass, Super Bubble, Score Blast, Multiplier Bonus e Coin Doubler).

## Como a referência vira Red Shelter

* **Moedas e pontos viram loot e XP:** o jogo não tem pontuação.
* **Anúncio vira achado raro:** a monetização está fora do escopo (54), então os 6 limitados aparecem em locais especiais (26), eventos (27) e ramos de bifurcação (24).
* **Durações mais curtas:** uma expedição de 1 km dura uns 100 s (8 m/s, acelerando), então a base é **6 / 9 / 12 s**, em 3 níveis melhorados na Oficina (40), como as armas.
* **Os sistemas do jogo contam:** a mochila limita o peso (32), o ruído atrai a horda (34, 45), o Director decide onde aparecem (30) e o combustível ganha um uso novo (62).

## Os 14 power-ups

| Subway Surfers | Red Shelter | Efeito | Como vem |
| -------------- | ----------- | ------ | -------- |
| **Na pista (5)** | | | |
| Coin Magnet | **Ímã de sucata** | Puxa o loot das 3 faixas por 6 / 9 / 12 s; para quando a mochila enche | pista |
| 2X Multiplier | **Adrenalina** | XP dos abates em dobro e golpes 20% mais rápidos por 6 / 9 / 12 s | pista |
| Super Sneakers | **Sinalizador** | Acende um sinalizador: por 6 / 9 / 12 s, os zumbis num raio de 25 m vão atrás da luz e não agarram a personagem; quando acaba, voltam a persegui-la. Obstáculos continuam valendo | pista |
| Jetpack | **Rota dos telhados** | Sobe por uma escada de incêndio e corre nos telhados por 8 / 11 / 14 s, sem zumbis nem obstáculos, com uma linha de munição e componentes; desce numa faixa livre | pista |
| Pogo Stick | **Rampa de entulho** | Um salto longo, de ~40 m, por cima do que vier; não melhora, como o Pogo | pista |
| **Consumível (1)** | | | |
| Hoverboard | **Escudo de caçamba** | Ativado com toque duplo: absorve a próxima batida ou agarrão e quebra empurrando os zumbis da faixa; os níveis acrescentam o empurrão e depois 1 s sem dano | fabricado na Oficina (sucata + componente), até 3 por expedição |
| **Na preparação (2)** | | | |
| Headstart | **Arrancada de moto** | Começa a expedição montada na Moto (63): os primeiros 250 m sem dano, derrubando zumbis; muito ruído | gasta 3 combustível |
| Score Booster | **Mapa marcado** | +1 unidade em todo loot da expedição e mostra o boato de um local especial (26) | gasta 2 componentes, ou vem do Rádio |
| **Raros (6)** | | | |
| Super Mysterizer | **Mochila abandonada** | Vira um power-up aleatório ou um recurso raro | eventos, ramos |
| Hourglass | **Rádio de alerta** | +10 s de fase Calma, o que adia a horda do clímax (30) | locais especiais |
| Super Bubble | **Segundo fôlego** | Ao morrer, levanta uma vez com 30% de HP | locais especiais, raro |
| Score Blast | **Esconderijo de saqueador** | Pacote instantâneo, por exemplo 6 sucata + 10 munição | pista, raro |
| Multiplier Bonus | **Diário de sobrevivente** | +25% de XP no resto da expedição (+50% na versão rara) | eventos |
| Coin Doubler | **Saco de lona** | Loot em dobro por 15 s; o peso também dobra, então a mochila enche mais rápido | ramos de bifurcação |

## Regras

* **Frequência:** um dos 5 da pista a cada ~250–300 m; um raro a cada ~3 expedições; nenhum na fase de Clímax do Director, e mais chance na fase de Perigo (30).
* **Simultâneos:** até 2 ao mesmo tempo, com ícone e barra de tempo no HUD. Pegar o mesmo de novo soma tempo. A Rota dos telhados cancela os outros.
* **Mochila e morte:** power-ups não pesam na mochila. Na morte, os ativos acabam e o escudo não usado se perde.
* **Com veículo (63):** montada, a Rota dos telhados não funciona; o Ímã de sucata e o Sinalizador funcionam normalmente.
* **Visual:** um anel branco pulsante com ícone, sem vermelho (reservado pela direção de arte para a personagem, o abrigo e o perigo) e sem as cores do loot.

## Dados

Um `PowerUpData` (.tres) por power-up: duração por nível, custo das
melhorias, raridade, fases do Director em que aparece, regiões, cor e
ícone (50).

**Decisão:** o papel do Super Sneakers (pular mais alto) já é dos Patins e
da Moto (63). Por isso o power-up equivalente é o **Sinalizador**, que
ajuda a escapar dos zumbis em vez de pular.


---

# 65. DIREÇÃO DE ARTE

**Status:** ✅ estilo decidido — **toon shading / cel-shading** (GDD 0.9.1) · implementação 📋 (Fase 15). É a regra para os assets de `docs/assets/asset_list.json`.

## Critérios

O estilo de Red Shelter precisa servir a quatro coisas, nesta ordem:

1. **Leitura em meio segundo:** a personagem corre a 8–15 m/s numa tela de celular em retrato; parede, barreira baixa, placa alta, zumbi, loot e power-up têm que ser reconhecidos pela forma e pela cor antes da cor de detalhe.
2. **Desempenho em celular intermediário:** renderizador Mobile do Godot, 60 fps como meta (30 aceitável), poucos materiais, sem texturas grandes.
3. **Produção enxuta:** equipe pequena; o estilo tem que permitir kits reaproveitáveis e pouca textura pintada.
4. **Identidade:** tensão de sobrevivência (não comédia), algo que se reconheça num print da loja.

## Análise dos estilos

Notas de 1 (ruim) a 5 (ótimo) para este jogo.

| Estilo | Exemplos | Leitura | Desempenho | Custo de produção | Identidade | Tom de sobrevivência |
| ------ | -------- | :-----: | :--------: | :---------------: | :--------: | :------------------: |
| Low-poly flat (cor chapada, sem contorno) | Unturned, pacotes Synty | 4 | 5 | 5 | 2 | 3 |
| Cel-shading com contorno | Borderlands, Wind Waker, Hi-Fi Rush | 5 | 4 | 4 | 4 | 4 |
| Cartoon vibrante | Subway Surfers, Plants vs. Zombies | 5 | 4 | 3 | 3 | 1 |
| Noir gráfico (P&B + vermelho) | MadWorld | 3 | 5 | 4 | 5 | 5 |
| Realista estilizado (PBR) | Into the Dead 2, Last Day on Earth | 3 | 2 | 2 | 3 | 5 |
| Pintado à mão | Torchlight, World of Warcraft | 4 | 3 | 1 | 4 | 3 |

Leituras:

* **Realista/PBR** é o mais comum no gênero, mas exige texturas e materiais por objeto (pesado no celular e caro de produzir) e lê mal em movimento, porque tudo tem o mesmo peso visual.
* **Cartoon vibrante** é o mais legível e vende bem na loja, mas tira o peso da morte, da moral e da horda.
* **Noir gráfico** é o mais marcante e casa com o nome RED SHELTER, mas em preto e branco o loot e os obstáculos perdem a cor que os identifica.
* **Low-poly flat** é o mais barato e rápido, mas parece "pacote de assets".
* **Cel-shading com contorno** equilibra todos os critérios.

## Estilo escolhido: toon shading com cel-shading

**Decisão (GDD 0.9.1):** o jogo começa em **toon shading / cel-shading** — formas estilizadas, luz em faixas de tom chapado (sem degradê suave) e contorno escuro desenhado, no espírito de Borderlands, The Legend of Zelda: The Wind Waker e Hi-Fi Rush, adaptado ao celular.

Por que este e não os outros: é o melhor equilíbrio da tabela — lê bem em movimento (o contorno separa o que é ator do que é fundo), roda bem no renderizador Mobile (sem texturas grandes nem materiais PBR), aceita kits reaproveitáveis e mantém o peso da sobrevivência com uma paleta controlada. O vermelho continua reservado, como regra de leitura do jogo.

Frase-guia: **"Tudo desenhado, nada perdido."** — cada coisa que importa tem contorno e cor própria.

### Como o cel-shading é feito

* **Luz em faixas:** 3 tons por material — luz, meio-tom e sombra — com bordas duras entre eles (rampa de cor no shader, não textura). A sombra puxa para o azul-arroxeado da região, não para o preto.
* **Brilho de borda (rim):** uma faixa clara fina na borda contra a luz, só em personagem, zumbis, loot e veículos, para destacá-los do fundo.
* **Contorno:** linha escura de espessura constante na tela.
  * atores e coletáveis (personagem, zumbis, loot, pickups, power-ups, veículos): contorno grosso (casco invertido);
  * obstáculos de faixa e objetos da beira da pista: contorno médio, para o jogador ler o que bloqueia;
  * prédios e fundo: contorno fino ou nenhum, e só nos primeiros 40 m (o resto some na névoa).
* **Detalhe desenhado, não modelado:** rachaduras, costuras, tábuas e marcas como linhas pintadas na textura-paleta ou em decalques simples, no lugar de geometria.
* **Sem PBR:** sem mapas de normal, rugosidade ou metal; o brilho de metal é uma faixa de cor na rampa.

### Regras de forma

* Silhuetas simples e grossas; nada mais fino que 5 cm (some a 15% da tela).
* Proporção estilizada: objetos de interação (loot, armas, veículos) uns 15% maiores que o real; bordas levemente chanfradas para a linha de contorno ficar limpa.
* Obstáculos com forma que diz o tipo: parede é bloco alto e largo; baixo é horizontal e até o joelho; alto deixa o vão de baixo visivelmente livre.
* Fundo com menos detalhe e menos contorno que a beira da pista.

### Paleta

Mais cor que um estilo realista, mas com hierarquia: o cenário tem cor de região em saturação média; o que o jogador precisa ver tem saturação alta.

| Uso | Cor | Regra |
| --- | --- | --- |
| Cenário | cor de cada região em saturação média (tabela abaixo) | nunca mais saturado que o loot |
| Vermelho do abrigo | `#D2382F` | só a personagem (mochila-caixa), o abrigo, perigo e alertas |
| Zumbis | oliva doente `#7D8A62` | cada tipo especial com uma marca só |
| Loot | comida `#F28C33`, água `#4D99FF`, sucata `#B3B3B8`, munição `#F2CC4D`, componentes `#4DE6CC`, medicamentos `#F7F7FF`, combustível `#9B5DE5` | cores fixas, com contorno grosso |
| Power-ups | anel branco | sem vermelho e sem as cores do loot |
| Contorno | quase preto azulado `#16141F` | uma cor só no jogo inteiro |
| Interface | off-white `#ECE8DF` sobre carvão | vermelho só em alerta |

Decisão: o combustível deixa de ser vermelho (era `#D9334A`) e passa a roxo.

### Cor e luz por região

| Região | Cor do cenário | Céu e névoa | Sombra |
| ------ | -------------- | ----------- | ------ |
| Bairro | tijolo e ocre | fim de tarde dourado | lilás |
| Mercado | azul e amarelo gastos | nublado claro | azul |
| Centro | cinza-azulado e concreto | cinza, névoa média | azul-escuro |
| Hospital | verde-água e branco sujo | entardecer esverdeado | verde-escuro |
| Zona Industrial | ferrugem e cinza | fumaça alaranjada, contraluz | marrom-roxo |
| Abrigo | madeira e lona | interior com lâmpadas quentes | marrom |

A névoa esconde o fim do streaming de chunks (120 m) e dá profundidade sem custo.

### Técnica (Godot, renderizador Mobile)

* **Shader toon** próprio (`ShaderMaterial`): rampa de 3 tons + rim + cor de sombra por região, num material compartilhado.
* **Contorno por casco invertido:** segunda passada com a malha inflada e faces de trás, cor `#16141F`; espessura por classe de objeto (acima). Sem pós-processamento de borda (caro no celular).
* **Textura-paleta** 256 × 256 para quase tudo (UV nas faixas de cor e nas linhas desenhadas); placas e letreiros com textura própria de até 512 × 512.
* **Mescla:** com um material por chunk, a mescla de geometria que o jogo já faz (seção 51) continua valendo; o contorno do cenário entra na mesma malha mesclada.
* **Sombras:** projetada só na personagem; mancha simples nos zumbis e no loot.
* **Orçamento:** personagem ~3.000 triângulos; zumbi ~1.500; demais classes em `docs/assets/asset_list.json`.

## Plano de implementação (Fase 15)

* **A1 — Base técnica:** shader toon, contorno, textura-paleta, névoa e céu por região, aplicados sobre as primitivas atuais.
* **A2 — Kit P1:** os assets P1 do catálogo (obstáculos, loot, kit de rua, postes, árvores, carros, fachadas, estrutura do abrigo).
* **A3 — Personagem:** escolha do conceito e do nome (proposta: Entregadora, mochila-caixa vermelha), modelo e animações.
* **A4 — Zumbis:** os 5 tipos com o mesmo esqueleto.
* **A5 — Regiões, POIs, veículos e defesa:** os assets P2.
* **A6 — Acabamento:** P3, efeitos e interface com a paleta.

Cada etapa termina com medição no celular (FPS e draw calls) antes da seguinte.

## Decisões em aberto

* escolher o conceito e o nome da personagem;
* confirmar o roxo do combustível (muda também a cor no jogo).
