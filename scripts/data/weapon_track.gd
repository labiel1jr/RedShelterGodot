class_name WeaponTrack
extends Resource

## Progressão de uma arma na Oficina (seção 12 do GDD): cada nível é um
## WeaponData ou RangedWeaponData com seus próprios valores e custo.

@export var id: StringName
@export var display_name := ""
@export var levels: Array[Resource] = []
## Arma de fogo (RangedWeaponData) ou branca (WeaponData).
@export var ranged := false
## Nível em que um jogo novo começa (0 = precisa fabricar na Oficina).
@export var start_level := 0


func level_data(level: int) -> Resource:
	return levels[clampi(level, 1, levels.size()) - 1]


func max_level() -> int:
	return levels.size()
