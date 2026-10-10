extends Node

## Autoload: ferramentas de game juice (seção 66 do GDD, Fase 16). Todos os
## efeitos usam estas peças, que respeitam as opções de acessibilidade
## (Settings.camera_shake, screen_flashes, impact_pauses).

## Intensidades nomeadas do tremor de câmera.
const SHAKE_LIGHT := 0.15
const SHAKE_MEDIUM := 0.35
const SHAKE_STRONG := 0.6

var _layer: CanvasLayer
var _flash: ColorRect
var _flash_tween: Tween
## Escala de tempo pedida por pausa de impacto / câmera lenta; a menor vence.
var _time_requests := {}
var _next_request := 0
## Escala de tempo de antes dos efeitos (os testes aceleram o jogo).
var _base_time_scale := 1.0
## Linhas de velocidade nas bordas (0 = nenhuma).
var _speed_lines: Control
var _speed_amount := 0.0
## Contadores rolando: chave → valor mostrado.
var _rolling := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_layer.add_child(_flash)
	_speed_lines = Control.new()
	_speed_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed_lines.draw.connect(_draw_speed_lines)
	_layer.add_child(_speed_lines)
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_reset_time)


## Pausa de impacto: o tempo quase para por alguns milissegundos.
func hit_stop(seconds := 0.06) -> void:
	if Settings.impact_pauses:
		_time_scale(0.05, seconds)


## Câmera lenta curta (crítico, morte, extração).
func slow_motion(factor := 0.3, seconds := 0.4) -> void:
	if Settings.impact_pauses:
		_time_scale(factor, seconds)


## Tremor da câmera atual (se ela souber tremer).
func shake(trauma := SHAKE_LIGHT) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("shake"):
		camera.shake(trauma)


## Quique de escala em qualquer nó 2D ou 3D (botões, contadores, salas).
func punch(node: Node, amount := 0.25, seconds := 0.3) -> void:
	if not is_instance_valid(node) or not ("scale" in node):
		return
	if node is Control:
		node.pivot_offset = node.size / 2.0
	var base: Variant = node.get_meta(&"juice_base_scale", node.scale)
	node.set_meta(&"juice_base_scale", base)
	node.scale = base * (1.0 + amount)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", base, seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Surge de baixo para cima com quique (construção nova no abrigo).
func pop_in(node: Node3D, seconds := 0.45) -> void:
	var base := node.scale
	node.scale = Vector3(base.x * 1.1, base.y * 0.05, base.z * 1.1)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", base, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Flash de tela curto, respeitando "Flashes de tela".
func screen_flash(color: Color, intensity := 0.35, seconds := 0.25) -> void:
	if not Settings.screen_flashes:
		return
	if _flash_tween:
		_flash_tween.kill()
	_flash.color = Color(color, intensity)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, seconds)


## Um ponto colorido voa da posição no mundo até um controle do HUD, que dá
## um quique quando ele chega.
func fly_to_hud(world_pos: Vector3, target: Control, color: Color, size := 18.0) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not is_instance_valid(target) or camera.is_position_behind(world_pos):
		return
	var dot := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#16141F")
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(size))
	dot.add_theme_stylebox_override("panel", style)
	dot.size = Vector2.ONE * size
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.position = camera.unproject_position(world_pos) - dot.size / 2.0
	_layer.add_child(dot)
	var goal := target.get_global_rect().get_center() - dot.size / 2.0
	var tween := dot.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(dot, "position", goal, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(dot, "scale", Vector2.ONE * 0.6, 0.45)
	tween.tween_callback(func():
		dot.queue_free()
		punch(target, 0.15, 0.25))


## Linhas de velocidade nas bordas da tela, de 0 a 1.
func set_speed_lines(amount: float) -> void:
	_speed_amount = clampf(amount, 0.0, 1.0)
	_speed_lines.queue_redraw()


## Valor que rola até `target` em vez de trocar de vez (contadores).
func roll(key: StringName, target: float, delta: float) -> int:
	var shown: float = _rolling.get(key, target)
	shown = move_toward(shown, target, maxf(6.0, absf(target - shown) * 8.0) * delta)
	_rolling[key] = shown
	return roundi(shown)


func _draw_speed_lines() -> void:
	if _speed_amount <= 0.01:
		return
	var size := _speed_lines.size
	var center := size / 2.0
	var color := Color(1, 1, 1, 0.25 * _speed_amount)
	for i in int(10 + 14 * _speed_amount):
		var angle := randf() * TAU
		var dir := Vector2(cos(angle), sin(angle))
		# Só nas bordas: começa a 70% do caminho até a borda.
		var reach := (size / 2.0).length()
		var start := center + dir * reach * randf_range(0.7, 0.85)
		draw_line_on(start, start + dir * reach * randf_range(0.15, 0.3) * _speed_amount, color)


func draw_line_on(from: Vector2, to: Vector2, color: Color) -> void:
	_speed_lines.draw_line(from, to, color, 2.0)


func _process(_delta: float) -> void:
	if _speed_amount > 0.01:
		_speed_lines.queue_redraw()


## Botões afundam ao tocar (seção 66, interface).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.button_down.connect(func(): punch(node, -0.08, 0.2))


func _time_scale(factor: float, seconds: float) -> void:
	if _time_requests.is_empty():
		_base_time_scale = Engine.time_scale
	var id := _next_request
	_next_request += 1
	_time_requests[id] = factor
	_apply_time()
	# Conta em tempo real: o próprio efeito deixa o tempo do jogo lento.
	await get_tree().create_timer(seconds, true, false, true).timeout
	_time_requests.erase(id)
	_apply_time()


func _apply_time() -> void:
	var scale := 1.0
	for factor in _time_requests.values():
		scale = minf(scale, factor)
	Engine.time_scale = _base_time_scale * scale


func _reset_time() -> void:
	set_speed_lines(0.0)
	_rolling.clear()
	if not _time_requests.is_empty():
		_time_requests.clear()
		Engine.time_scale = _base_time_scale
