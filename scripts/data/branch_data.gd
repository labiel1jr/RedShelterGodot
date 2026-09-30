class_name BranchData
extends Resource

## Um dos caminhos de uma bifurcação (seção 24 do GDD). A placa mostra o
## nome, a recompensa e o perigo antes da escolha; os chunks do ramo usam
## estes modificadores de loot e zumbis.

@export var id: StringName
@export var display_name := ""
## Texto curto da recompensa na placa, ex.: "comida e água".
@export var reward_text := ""
## Perigo de 1 a 3 (bolinhas na placa). Na faixa do meio a personagem segue
## pelo ramo de menor perigo.
@export_range(1, 3) var danger := 2
@export var color := Color(1, 1, 1)
## Peso no sorteio dos ramos.
@export var weight := 1.0

## Chunks do ramo; vazio usa os chunks da região.
@export var chunks: Array[ChunkData] = []
@export var min_chunks := 2
@export var max_chunks := 3
## Pesos do loot (ordem de GameManager.LOOT_KEYS); vazio mantém os do chunk.
@export var loot_weights := PackedFloat32Array()
@export var loot_multiplier := 1.0
@export var zombie_multiplier := 1.0
@export var loot_amount_bonus := 0

## Seção 33: o ramo é uma saída — volta mais cedo, sem o bônus de extração
## completa. Só nas expedições Longa e Especial.
@export var early_extraction := false


## "perigo ●●○"
func danger_text() -> String:
	return "perigo " + "●".repeat(danger) + "○".repeat(3 - danger)


func mods() -> Dictionary:
	return {
		"loot_weights": loot_weights,
		"loot_multiplier": loot_multiplier,
		"zombie_multiplier": zombie_multiplier,
		"loot_amount_bonus": loot_amount_bonus,
	}
