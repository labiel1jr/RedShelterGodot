extends Area3D

## Zumbi com HP (seções 8, 9, 17 e 18 do GDD). O comportamento vem do
## ZombieData: comum, runner e blindado agarram; o bruto dá um golpe pesado;
## o explosivo explode perto da personagem ou ao morrer. A armadura do
## blindado reduz o dano de cada acerto.
## IDLE: parado na pista até perceber a personagem (mais longe com ruído).
## CHASE: avança em direção a ela e desliza de lado para a faixa dela.
## GRAB: agarrou — acompanha a personagem causando dano contínuo até morrer.
## DEAD: cai e some (ou desiste e some, se não consegue alcançar).

enum State { IDLE, CHASE, GRAB, DEAD }

## Posição relativa à personagem enquanto agarra, por ordem de chegada.
const GRAB_OFFSETS: Array[Vector3] = [Vector3(0.8, 0, 0.3), Vector3(-0.8, 0, 0.3)]
## Quanto cada ponto de ruído aumenta o alcance de percepção (seção 34).
const NOISE_DETECT_BONUS := 0.12
const SMASH_COOLDOWN := 1.5
const STAGGER_TIME := 0.25

@export var data: ZombieData
@export var destroy_behind_distance := 15.0
## Atrás da personagem por mais que isso, um zumbi mais lento que ela
## desiste (e não fica entre a câmera e a personagem tapando a visão).
@export var give_up_behind_distance := 1.5

var current_hp := 0
var state := State.IDLE
## Seção 45: na defesa do abrigo, desce pela própria faixa até a barricada ou
## o portão e bate neles (a Defense decide o que está em pé).
var defense: Node = null
var lane := 1
var _structure_damage := 0.0

var _player: Node3D
var _combat: Node
var _run_manager: Node
var _pending_damage := 0.0
var _grab_offset := Vector3.ZERO
var _material: StandardMaterial3D
var _smash_cooldown := 0.0
var _stagger := 0.0
var _anim_time := 0.0
## >= 0 quando o pavio do explosivo está aceso.
var _fuse := -1.0

@onready var body: Node3D = $Body
@onready var arms: Node3D = $Arms
@onready var hp_bar_fill: Node3D = $HPBar/Fill
@onready var hp_bar: Node3D = $HPBar


func _ready() -> void:
	add_to_group("zombie")
	body_entered.connect(_on_body_entered)

	current_hp = data.max_hp
	scale = Vector3.ONE * data.size
	_material = StandardMaterial3D.new()
	_material.albedo_color = data.color
	body.material_override = _material
	arms.material_override = _material
	_anim_time = randf() * TAU
	$Armor.visible = data.armor > 0
	if data.attack == ZombieData.Attack.EXPLODE:
		_material.emission_enabled = true
		_material.emission = Color(1.0, 0.45, 0.1)
		_material.emission_energy_multiplier = 0.4

	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_combat = _player.get_node_or_null("Combat")
	_run_manager = get_tree().get_first_node_in_group("run_manager")
	_update_hp_bar()


func _process(delta: float) -> void:
	if not _player or state == State.DEAD:
		return

	_smash_cooldown -= delta
	_stagger -= delta
	_anim_time += delta

	if _fuse >= 0.0:
		_burn_fuse(delta)
		return

	match state:
		State.IDLE:
			var ahead := _player.global_position.z - global_position.z
			if ahead <= _detect_distance():
				state = State.CHASE
				if randf() < 0.4:
					AudioManager.play("groan", -10.0, 1.0 / data.size, 0.15, 0.6)
		State.CHASE:
			if defense:
				if _stagger <= 0.0:
					_defense_step(delta)
				_animate()
				return
			if _stagger <= 0.0:
				_chase(delta)
			_face_player()
			if data.attack == ZombieData.Attack.EXPLODE and _distance_to_player() < data.explode_trigger_distance:
				_light_fuse()
				return
			if _cannot_catch_up():
				_give_up()
				return
		State.GRAB:
			_hold(delta)
			_face_player()

	_animate()

	if global_position.z > _player.global_position.z + destroy_behind_distance:
		queue_free()


func _exit_tree() -> void:
	# Garante que a personagem não fique presa/lenta se o zumbi sumir agarrado.
	if state == State.GRAB and _combat:
		_combat.release_grab(self)


func is_alive() -> bool:
	return state != State.DEAD


## Já começa perseguindo (zumbis atraídos pelo ruído).
func alert() -> void:
	if state == State.IDLE:
		state = State.CHASE


## `knockback` empurra o zumbi para longe (tiros); não afeta quem agarra.
func take_hit(amount: int, is_crit: bool, knockback := 0.0) -> void:
	if state == State.DEAD:
		return

	# Armadura: todo acerto causa ao menos 1.
	amount = maxi(1, amount - data.armor)
	current_hp = maxi(0, current_hp - amount)
	_update_hp_bar()
	_flash()
	Fx.burst(get_parent(), global_position + Vector3.UP * 1.3 * data.size, Fx.BLOOD_COLOR, 10)
	_show_damage(amount, is_crit)

	if current_hp == 0:
		_die()
		return

	if state == State.IDLE:
		state = State.CHASE
	if knockback > 0.0 and state != State.GRAB:
		global_position.z -= knockback
		_stagger = STAGGER_TIME


func _detect_distance() -> float:
	var noise: float = _run_manager.noise if _run_manager else 0.0
	return data.detect_distance * (1.0 + noise * NOISE_DETECT_BONUS)


func _chase(delta: float) -> void:
	# Em Z vai na direção da personagem: de frente, se aproxima; depois que
	# ela passa, persegue por trás (e fica para trás se for mais lento).
	global_position.z = move_toward(global_position.z, _player.global_position.z, data.chase_speed * delta)
	global_position.x = move_toward(global_position.x, _player.global_position.x, data.lateral_speed * delta)


## Desce pela faixa; na barricada ou no portão, ataca a estrutura.
func _defense_step(delta: float) -> void:
	rotation.y = 0.0
	var target_z: float = defense.block_z(lane)
	global_position.x = move_toward(global_position.x, (lane - 1) * ChunkPopulator.LANE_WIDTH, data.lateral_speed * delta)
	if global_position.z < target_z - 0.05:
		global_position.z = move_toward(global_position.z, target_z, data.chase_speed * delta)
		return
	match data.attack:
		ZombieData.Attack.EXPLODE:
			_light_fuse()
		ZombieData.Attack.SMASH:
			if _smash_cooldown <= 0.0:
				_smash_cooldown = SMASH_COOLDOWN
				defense.hit_structure(lane, data.smash_damage * 2)
				var tween := create_tween()
				tween.tween_property(arms, "rotation:x", -1.2, 0.08)
				tween.tween_property(arms, "rotation:x", 0.0, 0.25)
		_:
			_structure_damage += data.grab_damage_per_second * delta
			var whole := int(_structure_damage)
			if whole > 0:
				_structure_damage -= whole
				defense.hit_structure(lane, whole)
			arms.position.z = 0.4 + sin(_anim_time * 14.0) * 0.1


func _cannot_catch_up() -> bool:
	var behind := global_position.z - _player.global_position.z
	var player_speed: float = -_player.velocity.z if _player is CharacterBody3D else 0.0
	return behind > give_up_behind_distance and data.chase_speed < player_speed


## Some com fade, sem contar como abate.
func _give_up() -> void:
	state = State.DEAD
	hp_bar.hide()
	set_deferred("monitoring", false)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _face_player() -> void:
	# Os braços apontam para +Z; vira 180° quando a personagem está à frente (-Z).
	rotation.y = PI if _player.global_position.z < global_position.z else 0.0


## Cambaleio ao andar e "mordidas" ao agarrar, só nos visuais (a colisão
## fica parada).
func _animate() -> void:
	match state:
		State.CHASE:
			var rate := 4.0 + data.chase_speed * 0.8
			body.rotation.z = sin(_anim_time * rate) * 0.12
			arms.position.y = 1.4 + sin(_anim_time * rate * 2.0) * 0.06
		State.GRAB:
			body.rotation.z = sin(_anim_time * 14.0) * 0.05
			arms.position.z = 0.4 + sin(_anim_time * 14.0) * 0.1


func _hold(delta: float) -> void:
	global_position = _player.global_position + _grab_offset

	# Dano fracionário acumulado entre frames (seção 9: -8 HP/s).
	_pending_damage += data.grab_damage_per_second * delta
	var whole := int(_pending_damage)
	if whole > 0:
		_pending_damage -= whole
		var health := _player.get_node_or_null("Health")
		if health:
			health.take_damage(whole)


func _on_body_entered(entered: Node3D) -> void:
	if not entered.is_in_group("player") or state == State.GRAB or state == State.DEAD:
		return

	# Seção 63: montada, o veículo decide o encontro.
	var vehicle := entered.get_node_or_null("Vehicle")
	if data.attack == ZombieData.Attack.SMASH:
		if vehicle and vehicle.on_smash():
			_smash_cooldown = SMASH_COOLDOWN
			return
		_smash()
		return
	if data.attack == ZombieData.Attack.EXPLODE:
		# Encostar acende o pavio: correndo, dá para sair do raio.
		_light_fuse()
		return

	if vehicle and vehicle.on_grabber_contact(self):
		return
	if not _combat:
		return
	var slot: int = _combat.register_grab(self)
	_grab_offset = GRAB_OFFSETS[slot % GRAB_OFFSETS.size()]
	state = State.GRAB
	AudioManager.play("grab", -2.0)


## Seção 17: o bruto não agarra — acerta um golpe pesado e segue.
func _smash() -> void:
	if _smash_cooldown > 0.0:
		return
	_smash_cooldown = SMASH_COOLDOWN
	state = State.CHASE

	var health := _player.get_node_or_null("Health")
	if health:
		health.take_damage(data.smash_damage)
	AudioManager.play("hit", 0.0, 0.6)
	Fx.burst(get_parent(), _player.global_position + Vector3.UP * 1.2, Fx.BLOOD_COLOR, 18, 5.0)

	var tween := create_tween()
	tween.tween_property(arms, "rotation:x", -1.2, 0.08)
	tween.tween_property(arms, "rotation:x", 0.0, 0.25)


## Seção 63: derrubado ou empurrado por um veículo — leva `damage` e fica
## para trás da personagem, cambaleando. Quem estava agarrando solta.
func shove(damage := 0) -> void:
	if state == State.DEAD:
		return
	if state == State.GRAB:
		state = State.CHASE
		if _combat:
			_combat.release_grab(self)
	if damage > 0:
		take_hit(damage, false)
		if state == State.DEAD:
			return
	state = State.CHASE
	global_position.z = _player.global_position.z + 1.5
	_stagger = 0.8


func _distance_to_player() -> float:
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z))


func _light_fuse() -> void:
	if _fuse < 0.0:
		_fuse = 0.0


## Pisca cada vez mais rápido e explode.
func _burn_fuse(delta: float) -> void:
	_fuse += delta
	_material.emission_energy_multiplier = 0.5 + 3.0 * absf(sin(_fuse * 30.0))
	if _fuse >= data.explode_fuse:
		_explode()


## Seção 17: explode quando chega perto ou é eliminado. Fere a personagem e
## outros zumbis no raio (inclusive outros explosivos) e faz muito ruído.
func _explode() -> void:
	if state == State.DEAD and _fuse == -2.0:
		return
	_fuse = -2.0
	state = State.DEAD
	hp_bar.hide()
	set_deferred("monitoring", false)

	AudioManager.play("explosion", 0.0, 1.0, 0.1, 0.1)
	var center := global_position + Vector3.UP
	var world := get_parent()
	Fx.burst(world, center, Color(1.0, 0.55, 0.1), 30, 8.0, 0.25)
	Fx.burst(world, center, Color(0.2, 0.18, 0.16), 20, 5.0, 0.3)
	Fx.muzzle_flash(world, center)

	if defense and absf(global_position.z - defense.block_z(lane)) < 1.5:
		defense.hit_structure(lane, data.explode_damage * 3)
	if _player and _distance_to_player() <= data.explode_radius:
		var health := _player.get_node_or_null("Health")
		if health:
			health.take_damage(data.explode_damage)
	for other in get_tree().get_nodes_in_group("zombie"):
		if other != self and other.is_alive() and other.global_position.distance_to(global_position) <= data.explode_radius:
			other.take_hit(data.explode_damage * 2, false)
	if _run_manager:
		_run_manager.add_noise(data.explode_noise, false)

	queue_free()


func _die() -> void:
	# O explosivo eliminado explode (e conta o abate uma vez só).
	if data.attack == ZombieData.Attack.EXPLODE:
		if _run_manager:
			_run_manager.register_kill(data.xp_reward)
		state = State.DEAD
		_explode.call_deferred()
		return

	var was_grabbing := state == State.GRAB
	state = State.DEAD
	hp_bar.hide()
	set_deferred("monitoring", false)

	if was_grabbing and _combat:
		_combat.release_grab(self)

	if _run_manager:
		_run_manager.register_kill(data.xp_reward)
	if _player:
		Fx.float_text(_player, global_position + Vector3.UP * 3.2 * data.size, "+%d XP" % data.xp_reward, Color(0.5, 0.8, 1.0), 44)

	Fx.burst(get_parent(), global_position + Vector3.UP * 1.0 * data.size, Fx.BLOOD_COLOR, 24, 5.0, 0.16)
	AudioManager.play("zombie_death", -5.0, 1.0 / data.size)

	# Cai para longe da câmera (-Z) e some com fade. Com rotation.y = PI a mesma
	# rotação em X o derrubaria para cima da câmera.
	rotation.y = 0.0
	body.rotation.z = 0.0
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.tween_property(self, "rotation:x", -PI / 2.0, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(_material, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _update_hp_bar() -> void:
	var ratio := float(current_hp) / float(data.max_hp)
	hp_bar_fill.scale.x = maxf(ratio, 0.001)
	hp_bar_fill.position.x = -(1.0 - ratio) / 2.0


func _flash() -> void:
	_material.albedo_color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color", data.color, 0.15)


func _show_damage(amount: int, is_crit: bool) -> void:
	# Ancorado na personagem: acompanha a corrida e não cai junto com o zumbi.
	var anchor: Node3D = _player if _player else get_parent()
	Fx.float_text(
		anchor,
		global_position + Vector3(randf_range(-0.3, 0.3), 2.7 * data.size, 0),
		("CRÍTICO -%d" if is_crit else "-%d") % amount,
		Color(1, 0.85, 0.2) if is_crit else Color.WHITE,
		72 if is_crit else 56,
	)
