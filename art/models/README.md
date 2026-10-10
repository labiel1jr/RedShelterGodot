# Modelos 3D — como entregar

Cada asset do catálogo ([`docs/assets/asset_list.json`](../../docs/assets/asset_list.json))
vira **um arquivo** `art/models/<categoria>/<id>.glb`, por exemplo
`art/models/obstacles/obs_low_barrier.glb`. Fontes (`.blend`) em
`art/source/<categoria>/`.

Assim que o arquivo é colocado aqui, o jogo troca sozinho a caixa
provisória pelo modelo. Não é preciso mexer em cena nem em código.

## Regras (resumo do catálogo, `global_specs`)

- glTF 2.0 binário (`.glb`), 1 unidade = 1 metro, escala aplicada.
- Y para cima; a frente aponta para **-Z**.
- Pivô **no chão, no centro da base**.
- Medidas de `size_m`; itens com `gameplay_rules` **não podem passar** da
  colisão.
- Limite de triângulos por `size_class` (`tri_budgets`).
- **1 material**, usando a textura-paleta
  [`art/palette/palette_256.png`](../palette/palette_256.png) (cores em
  [`palette.json`](../palette/palette.json)). Sem PBR, sem normal map, sem
  pintar sombra: luz em faixas e contorno são feitos pelo shader do jogo.
- Não modelar colisão nem contorno.

## Conferir antes de entregar

Com o Godot 4.7, na raiz do projeto:

```
godot --headless --path . -s res://tools/validate_models.gd
```

O validador lista cada modelo com triângulos e medidas e aponta:

- **ERRO** — id fora do catálogo, pasta errada, triângulos acima do limite,
  maior que a colisão, pivô fora do chão;
- **aviso** — medida diferente da referência, pivô fora do centro, mais de
  um material.

Modelo com ERRO não deve ser entregue.

## Onde cada modelo aparece

| Tipo | Como entra |
| --- | --- |
| Obstáculos (`obs_*`) | pelo `asset_id` de cada cena em `scenes/obstacles/` |
| Loot (`loot_*`) | pelo tipo do recurso (`loot_pickup.gd`); o jogo gira o modelo |
| Cenário dos chunks e do abrigo | qualquer nó com o metadado `asset_id` = id do asset |
