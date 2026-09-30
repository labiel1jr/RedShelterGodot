extends Node

## Sistema de vida do jogador (seção 7 do GDD). Chegar a 0 HP encerra
## a expedição, sem morte instantânea por um único toque.

signal health_changed(current: int, max_hp: int)
signal died

@export var max_hp := 100
## Multiplica todo dano recebido (atributo Sobrevivência, perk Couro grosso).
@export var damage_multiplier := 1.0

var current_hp := 100
# Dano fracionário acumulado, para o multiplicador valer também nos ticks de
# 1 HP do agarrão.
var _pending_damage := 0.0


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	_pending_damage += amount * damage_multiplier
	var whole := int(_pending_damage)
	if whole <= 0:
		return
	_pending_damage -= whole
	current_hp = max(0, current_hp - whole)
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		died.emit()


## Define o HP sem contar como dano (ex.: começar ferida por fome/sede).
func set_hp(value: int) -> void:
	current_hp = clampi(value, 1, max_hp)
	health_changed.emit(current_hp, max_hp)


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)
