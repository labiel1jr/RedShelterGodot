extends CharacterBody3D

## Movimento do runner (seções 2.1 e 5 do GDD): corrida automática para
## frente (-Z), troca de faixa, pulo e slide. Player é uma CharacterBody3D
## com uma cápsula primitiva como visual.

## Toque curto na tela (sem arrastar): na seção 5 do GDD, "Atirar = Toque".
signal tapped
## Dois toques curtos seguidos: ergue o Escudo de caçamba (seção 64).
signal double_tapped

const DOUBLE_TAP_TIME := 0.3

const LANE_WIDTH := 2.5
const GRAVITY := -25.0

@export var forward_speed := 8.0
@export var speed_increase_per_second := 0.05
@export var lane_change_speed := 12.0
@export var jump_height := 1.5
@export var slide_duration := 0.6
@export var standing_height := 2.0
@export var sliding_height := 1.0
@export var swipe_threshold := 50.0

var current_lane := 1
var target_x := 0.0
var is_sliding := false
var slide_timer := 0.0
var vertical_velocity := 0.0
var touch_start := Vector2.ZERO
var touch_active := false
## Reduzido pelo PlayerCombat enquanto um zumbi está agarrando.
var speed_multiplier := 1.0
## Faixa que não dá para entrar (-1 = nenhuma), ex.: a divisória da bifurcação.
var blocked_lane := -1
## Seção 63: definidos pelo veículo montado (PlayerVehicle).
var vehicle_speed := 1.0
var jump_multiplier := 1.0
var lane_speed_multiplier := 1.0
var can_slide := true
## Mochila a jato: segurar o botão sobe (`lift` = aceleração), soltar plana.
var hold_to_fly := false
var thrust_input := false
var lift := 0.0
var max_rise_speed := 7.0
var gravity_scale := 1.0
var ceiling := INF
var _drag_moved := false
## Furgão: ocupa duas faixas; `current_lane` vira 0 (faixas 1 e 2) ou 2
## (faixas 2 e 3) e a personagem fica entre as duas.
var two_lane := false
var _last_tap_time := -1.0
## Rota dos telhados (seção 64): >= 0 mantém a personagem nesta altura, sem
## gravidade, pulo nem deslize.
var rooftop_height := -1.0
## Rampa de entulho: > 0 substitui a gravidade durante o salto longo.
var ramp_gravity_scale := 0.0

var _mesh_base_y := 1.0
var _run_cycle := 0.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("player")
	target_x = _lane_x(current_lane)

	# Evita editar o recurso compartilhado do .tscn em tempo de execução.
	collision_shape.shape = collision_shape.shape.duplicate()
	mesh_instance.mesh = mesh_instance.mesh.duplicate()
	_mesh_base_y = mesh_instance.position.y


func _process(delta: float) -> void:
	# Animação com primitivas: passada (sobe e desce), inclinação para frente,
	# para o lado na troca de faixa, e esticada no pulo.
	var grounded := is_on_floor()
	_run_cycle += delta * forward_speed * speed_multiplier * vehicle_speed
	var bob := absf(sin(_run_cycle * 1.1)) * 0.12 if grounded and not is_sliding else 0.0
	mesh_instance.position.y = _mesh_base_y + bob
	mesh_instance.rotation.z = clampf(-velocity.x * 0.04, -0.35, 0.35)
	mesh_instance.rotation.x = -0.5 if is_sliding else -0.12
	mesh_instance.scale.y = 1.08 if not grounded and vertical_velocity > 0.0 else 1.0


func _physics_process(delta: float) -> void:
	forward_speed += speed_increase_per_second * delta
	_handle_slide_timer(delta)

	if rooftop_height >= 0.0:
		vertical_velocity = clampf((rooftop_height - global_position.y) * 6.0, -8.0, 12.0)
	elif is_on_floor():
		if vertical_velocity < 0.0:
			vertical_velocity = -1.0
	else:
		vertical_velocity += GRAVITY * (ramp_gravity_scale if ramp_gravity_scale > 0.0 else gravity_scale) * delta
	if lift > 0.0:
		vertical_velocity = minf(maxf(vertical_velocity, 1.5) + lift * delta, max_rise_speed)
	if global_position.y >= ceiling and vertical_velocity > 0.0:
		vertical_velocity = 0.0

	var smoothed_x := lerpf(global_position.x, target_x, lane_change_speed * lane_speed_multiplier * delta)
	var delta_x := smoothed_x - global_position.x

	velocity.x = delta_x / maxf(delta, 0.0001)
	velocity.y = vertical_velocity
	velocity.z = -forward_speed * speed_multiplier * vehicle_speed

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if hold_to_fly and _fly_input(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_change_lane(-1)
			KEY_RIGHT, KEY_D:
				_change_lane(1)
			KEY_UP, KEY_SPACE:
				_jump()
			KEY_DOWN, KEY_CTRL:
				_slide()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_active = true
		elif touch_active:
			touch_active = false
			var delta_touch: Vector2 = event.position - touch_start
			if delta_touch.length() < swipe_threshold:
				tapped.emit()
				var now := Time.get_ticks_msec() / 1000.0
				if now - _last_tap_time < DOUBLE_TAP_TIME:
					double_tapped.emit()
					_last_tap_time = -1.0
				else:
					_last_tap_time = now
				return
			if abs(delta_touch.x) > abs(delta_touch.y):
				_change_lane(1 if delta_touch.x > 0 else -1)
			elif delta_touch.y < 0:
				_jump()
			else:
				_slide()


## Mochila a jato: segurar o toque, o Espaço (ou ↑) ou o botão do mouse faz
## voar. Deslizar o dedo para o lado troca de faixa mesmo segurando.
## Retorna true se o evento foi tratado aqui.
func _fly_input(event: InputEvent) -> bool:
	if event is InputEventKey and not event.echo and event.keycode in [KEY_UP, KEY_SPACE, KEY_W]:
		thrust_input = event.pressed
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		thrust_input = event.pressed
		return false
	if event is InputEventScreenTouch:
		thrust_input = event.pressed
		if event.pressed:
			touch_start = event.position
			_drag_moved = false
		elif not _drag_moved:
			var delta_touch: Vector2 = event.position - touch_start
			if absf(delta_touch.x) > swipe_threshold and absf(delta_touch.x) > absf(delta_touch.y):
				_change_lane(1 if delta_touch.x > 0 else -1)
		return true
	if event is InputEventScreenDrag:
		var dx: float = event.position.x - touch_start.x
		if absf(dx) > swipe_threshold:
			_change_lane(1 if dx > 0 else -1)
			touch_start = event.position
			_drag_moved = true
		return true
	return false


## Liga ou desliga o modo de duas faixas (furgão).
func set_two_lane(enabled: bool) -> void:
	two_lane = enabled
	if enabled:
		current_lane = 0 if global_position.x <= 0.0 else 2
		target_x = -LANE_WIDTH / 2.0 if current_lane == 0 else LANE_WIDTH / 2.0
	else:
		current_lane = 1
		target_x = _lane_x(1)


func _change_lane(direction: int) -> void:
	if two_lane:
		current_lane = 0 if direction < 0 else 2
		target_x = -LANE_WIDTH / 2.0 if current_lane == 0 else LANE_WIDTH / 2.0
		return
	var lane := clampi(current_lane + direction, 0, 2)
	# Seção 24: a divisória da bifurcação bloqueia a faixa do meio.
	if lane == blocked_lane:
		return
	current_lane = lane
	target_x = _lane_x(current_lane)


func _lane_x(lane: int) -> float:
	return float(lane - 1) * LANE_WIDTH


func _jump() -> void:
	if not is_on_floor() or is_sliding or rooftop_height >= 0.0:
		return
	vertical_velocity = sqrt(jump_height * jump_multiplier * 2.0 * -GRAVITY)


func _slide() -> void:
	if is_sliding or not is_on_floor() or not can_slide or rooftop_height >= 0.0:
		return
	is_sliding = true
	slide_timer = slide_duration
	_set_height(sliding_height)


func _handle_slide_timer(delta: float) -> void:
	if not is_sliding:
		return
	slide_timer -= delta
	if slide_timer <= 0.0:
		is_sliding = false
		_set_height(standing_height)


func _set_height(height: float) -> void:
	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = height
	collision_shape.position.y = height / 2.0

	if mesh_instance.mesh is CapsuleMesh:
		mesh_instance.mesh.height = height
	_mesh_base_y = height / 2.0
	mesh_instance.position.y = _mesh_base_y
