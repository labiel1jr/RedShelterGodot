class_name PowerUpData
extends Resource

## Power-up da corrida (seção 64 do GDD). Os temporizados aparecem na pista
## (um anel branco com o ícone) e duram alguns segundos; o consumível (Escudo
## de caçamba) é fabricado na Oficina e ativado com toque duplo.

enum Kind { TIMED, CONSUMABLE }

@export var id: StringName
@export var display_name := ""
## Texto curto do ícone na pista e no HUD.
@export var short_name := ""
@export var color := Color(1, 1, 1)
@export var kind := Kind.TIMED
## Dica mostrada na primeira vez que pega (ou ativa).
@export_multiline var hint := ""
## Duração em segundos em cada nível (melhorias na Oficina).
@export var durations := PackedFloat32Array([6.0, 9.0, 12.0])
## Aparece na pista? Peso no sorteio entre os da pista.
@export var on_track := true
@export var spawn_weight := 1.0

@export_group("Ímã de sucata")
## Puxa o loot das 3 faixas até esta distância à frente.
@export var magnet_range := 0.0
@export var magnet_speed := 22.0

@export_group("Sinalizador")
## Zumbis até esta distância da personagem vão atrás da luz e não agarram.
@export var flare_radius := 0.0

@export_group("Rota dos telhados")
## Altura dos telhados (m); 0 = não é este power-up.
@export var roof_height := 0.0
## Um item (munição ou componente) a cada tantos metros, por faixa.
@export var roof_loot_spacing := 8.0
## Sem rota dos telhados nesta distância antes da extração (ela desce antes).
@export var roof_clear_before_extraction := 200.0

@export_group("Rampa de entulho")
## Salto de `ramp_distance` metros com pico de `ramp_height` (0 = não é este).
@export var ramp_distance := 0.0
@export var ramp_height := 5.0

@export_group("Adrenalina")
@export var xp_multiplier := 1.0
## Golpes da arma branca mais rápidos (0,2 = intervalo 20% menor).
@export var attack_speed_bonus := 0.0

@export_group("Escudo de caçamba")
@export var craft_cost := {}
## Quantos levar por expedição e quantos guardar no abrigo.
@export var max_per_run := 3
@export var max_stock := 9
## A partir destes níveis: empurra os zumbis da faixa ao quebrar; e dá
## alguns segundos sem dano.
@export var push_from_level := 2
@export var push_damage := 40
@export var invulnerable_from_level := 3
@export var invulnerability := 1.0


func duration(level: int) -> float:
	if durations.is_empty():
		return 0.0
	return durations[clampi(level, 1, durations.size()) - 1]
