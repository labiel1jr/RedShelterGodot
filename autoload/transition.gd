extends CanvasLayer

## Autoload (Fase 7): transição entre cenas. Toda troca de cena termina com um
## fade saindo do preto; `change_scene()` também escurece antes de trocar.
## Enquanto a tela está preta, a cena nova pode aquecer shaders (ver
## Run._warm_up_shaders) sem o jogador ver.

signal faded_in

const FADE_OUT := 0.3
const FADE_IN := 0.45

var _rect: ColorRect
var _last_scene: Node
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene and scene != _last_scene:
		_last_scene = scene
		_fade_in()


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 1.0, FADE_OUT)
	await tween.finished
	get_tree().change_scene_to_file(path)
	_busy = false


func _fade_in() -> void:
	_rect.color.a = 1.0
	# Dois frames pretos: a cena nova monta e aquece shaders sem aparecer.
	await get_tree().process_frame
	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 0.0, FADE_IN)
	await tween.finished
	faded_in.emit()
