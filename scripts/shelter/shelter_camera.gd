class_name ShelterCamera
extends Camera3D

## Câmera do abrigo: gira 360° em volta dele. No PC, segure o botão do meio
## do mouse (o da rodinha) e arraste; no celular, segure o dedo na tela por
## um instante e arraste. Não gira a partir das barras e dos painéis. As
## paredes altas entre a câmera e o abrigo somem para não tapar as salas.

## Ponto em volta do qual a câmera gira (o centro do abrigo).
@export var target := Vector3(0, 0, 0.5)
## Graus por pixel arrastado.
@export var mouse_sensitivity := 0.35
@export var touch_sensitivity := 0.3
## Segundos com o dedo parado até começar a girar, e quanto ele pode mexer
## (pixels) nesse tempo sem cancelar.
@export var hold_time := 0.35
@export var hold_tolerance := 18.0
## Interface por cima da cena: toques nela não giram a câmera.
@export var ui_root: NodePath
## Paredes que somem quando ficam entre a câmera e o abrigo.
@export var fading_walls: Array[NodePath] = []

## Ângulo em volta do abrigo (graus; 0 = de frente).
var yaw := 0.0

var _radius := 0.0
var _height := 0.0
var _mouse_drag := false
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_time := 0.0
var _touch_orbit := false


func _ready() -> void:
	var offset := global_position - target
	_height = offset.y
	_radius = Vector2(offset.x, offset.z).length()
	yaw = rad_to_deg(atan2(offset.x, offset.z))
	_apply()


func _process(delta: float) -> void:
	if _touch_index >= 0 and not _touch_orbit:
		_touch_time += delta
		if _touch_time >= hold_time:
			_touch_orbit = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_mouse_drag = event.pressed and not _over_ui(event.position)
	elif event is InputEventMouseMotion and _mouse_drag:
		rotate_by(-event.relative.x * mouse_sensitivity)
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0 and not _over_ui(event.position):
			_touch_index = event.index
			_touch_start = event.position
			_touch_time = 0.0
			_touch_orbit = false
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_touch_orbit = false
	elif event is InputEventScreenDrag and event.index == _touch_index:
		if _touch_orbit:
			rotate_by(-event.relative.x * touch_sensitivity)
		elif event.position.distance_to(_touch_start) > hold_tolerance:
			# Arrastou antes de segurar: não é para girar.
			_touch_index = -1


func is_orbiting() -> bool:
	return _mouse_drag or _touch_orbit


func rotate_by(degrees: float) -> void:
	yaw = fposmod(yaw + degrees, 360.0)
	_apply()


func _apply() -> void:
	var angle := deg_to_rad(yaw)
	global_position = target + Vector3(sin(angle) * _radius, _height, cos(angle) * _radius)
	look_at(target)
	var view := Vector3(global_position.x - target.x, 0.0, global_position.z - target.z).normalized()
	for path in fading_walls:
		var wall := get_node_or_null(path) as Node3D
		if wall:
			var outward := Vector3(wall.global_position.x - target.x, 0.0, wall.global_position.z - target.z).normalized()
			wall.visible = outward.dot(view) < 0.35


## O ponto está sobre uma barra ou um painel visível?
func _over_ui(point: Vector2) -> bool:
	var ui := get_node_or_null(ui_root)
	if not ui:
		return false
	for child in ui.get_children():
		if child is Control and child.visible and child.mouse_filter != Control.MOUSE_FILTER_IGNORE \
				and child.get_global_rect().has_point(point):
			return true
	return false
