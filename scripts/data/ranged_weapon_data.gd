class_name RangedWeaponData
extends Resource

## Arma de fogo (seções 34, 35 e 50 do GDD): eficiente à distância, mas cada
## tiro gasta munição e faz ruído.

@export var display_name := "Pistola"
@export var level := 1
@export var damage := 35
@export var fire_cooldown := 0.3
## Distância máxima à frente para acertar um zumbi.
@export var fire_range := 30.0
@export_range(0.0, 1.0) var crit_chance := 0.05
@export var crit_multiplier := 2.0
## Empurrão (m) que o tiro dá no zumbi atingido.
@export var knockback := 0.6
## Ruído gerado por disparo (seção 34: pistola +1, SMG +4 por rajada,
## escopeta +6).
@export var noise := 1.0

@export_group("Escopeta e SMG (seção 35)")
## Chumbos por disparo (escopeta): divididos entre os zumbis no cone.
@export var pellets := 1
## Faixas vizinhas que o disparo também atinge (0 = só a faixa; 1 = cone).
@export var spread_lanes := 0
## Dano restante no alcance máximo (1 = sem perda com a distância).
@export_range(0.0, 1.0) var range_falloff := 1.0
## Balas por toque (SMG); cada uma gasta 1 de munição.
@export var burst := 1
@export var burst_interval := 0.08

@export_group("Visual")
## Tamanho da arma na mão (multiplica o modelo da pistola).
@export var visual_scale := Vector3.ONE

@export_group("Oficina")
## Custo para chegar a este nível, ex.: {"scrap": 12, "energy": 3}.
@export var upgrade_cost := {}
@export var required_workshop := 1
