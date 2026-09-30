class_name WeaponData
extends Resource

## Dados de uma arma branca de emergência (seções 11-16 e 50 do GDD). Cada
## nível de upgrade é um .tres próprio, listado num WeaponTrack.

@export var display_name := "Faca"
@export var level := 1
## Dano de cada golpe do combo (seção 14). O tamanho do array define o combo.
@export var combo_damage := PackedInt32Array([25, 30, 45])
## Tempo máximo entre toques para o combo continuar; depois volta ao golpe 1.
@export var combo_window := 0.9
## Intervalo mínimo entre golpes.
@export var attack_cooldown := 0.45
## Alcance à frente da personagem para atingir um zumbi que ainda não agarrou.
@export var reach := 2.5
@export_range(0.0, 1.0) var crit_chance := 0.1
@export var crit_multiplier := 2.0
## Seção 16: cada golpe que acerta gasta 1. Em 0 a arma quebra e precisa
## ser reparada na Oficina.
@export var max_durability := 100

@export_group("Visual")
## Tamanho da lâmina na mão (multiplica o modelo da faca).
@export var visual_scale := Vector3.ONE
@export var blade_color := Color(0.75, 0.78, 0.8)

@export_group("Oficina")
## Custo para chegar a este nível (seção 12), ex.: {"scrap": 10, "energy": 3}.
@export var upgrade_cost := {}
@export var required_workshop := 1
