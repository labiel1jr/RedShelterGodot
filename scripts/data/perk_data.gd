class_name PerkData
extends Resource

## Perk de uma das três árvores (seção 43 do GDD). Cada rank soma
## `value_per_rank` ao modificador `effect` (ver Progression.stat()).

enum Branch { COMBAT, EXPLORATION, SHELTER }

@export var id: StringName
@export var display_name := ""
@export var branch := Branch.COMBAT
## Descrição do efeito de um rank, ex.: "+10% de dano corpo a corpo".
@export var description := ""
@export var effect: StringName
@export var value_per_rank := 0.0
@export var max_rank := 2
## Pontos já gastos nesta árvore (branch) para liberar o perk.
@export var required_tree_points := 0
