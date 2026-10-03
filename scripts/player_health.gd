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
## Seção 63: depois de cair do veículo, um instante sem dano.
var _invulnerable := 0.0


func _ready() -> void:
	current_hp = max_hp


func _process(delta: float) -> void:
	if _invulnerable > 0.0:
		_invulnerable -= delta


func make_invulnerable(seconds: float) -> void:
	_invulnerable = maxf(_invulnerable, seconds)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


## `direct`: ignora o veículo e a invulnerabilidade (a explosão da mochila
## a jato, que fere a própria personagem).
func take_damage(amount: int, direct := false) -> void:
	if current_hp <= 0 or (_invulnerable > 0.0 and not direct):
		return
	# Montada, o dano vai para o veículo (seção 63).
	var vehicle := get_parent().get_node_or_null("Vehicle")
	if not direct and vehicle and vehicle.absorb(amount):
		return
	# Seção 64: o Escudo de caçamba segura o golpe.
	var powerups := get_parent().get_node_or_null("PowerUps")
	if not direct and powerups and powerups.block_hit():
		return

	_pending_damage += amount * damage_multiplier
	var whole := int(_pending_damage)
	if whole <= 0:
		return
	_pending_damage -= whole
	current_hp = max(0, current_hp - whole)
	# Seção 64: o Segundo fôlego levanta uma vez.
	if current_hp == 0:
		var powerups := get_parent().get_node_or_null("PowerUps")
		var fraction: float = powerups.use_second_wind() if powerups else 0.0
		if fraction > 0.0:
			current_hp = maxi(1, roundi(max_hp * fraction))
			make_invulnerable(2.0)
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
