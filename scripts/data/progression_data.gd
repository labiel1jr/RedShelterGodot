class_name ProgressionData
extends Resource

## Regras de progressão da personagem (seções 42, 43 e 50 do GDD): curva de
## XP, recompensas da expedição, atributos e perks.

const BRANCH_NAMES := ["Combate", "Exploração", "Abrigo"]

@export var attributes: Array[AttributeData] = []
@export var perks: Array[PerkData] = []

@export_group("Níveis")
@export var max_level := 20
## XP para ir do nível N ao N + 1 = base + (N - 1) * incremento.
@export var xp_base := 100
@export var xp_increment := 50
@export var attribute_points_per_level := 1
@export var perk_points_per_level := 1

@export_group("XP da expedição")
## Os zumbis dão o xp_reward do ZombieData.
@export var xp_per_meter := 0.1
@export var extraction_bonus_xp := 50
## Fração do XP mantida quando a personagem morre (como o loot, seção 46).
@export var death_xp_rate := 0.5


func xp_to_next(level: int) -> int:
	return xp_base + (level - 1) * xp_increment


func attribute(id: StringName) -> AttributeData:
	for a in attributes:
		if a.id == id:
			return a
	return null


func perk(id: StringName) -> PerkData:
	for p in perks:
		if p.id == id:
			return p
	return null
