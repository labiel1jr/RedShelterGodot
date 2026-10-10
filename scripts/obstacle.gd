extends Area3D

## Obstáculo da pista (camada 2 da seção 21 do GDD). Instanciado pelo
## ChunkPopulator e liberado junto com o chunk.

@export var damage := 15
## wall / low / high — usado pelas dicas do tutorial.
@export var kind := &"wall"
## Modelo do catálogo de assets que substitui a forma provisória (AssetLibrary).
@export var asset_id := &""

## Seção 66: "POR POUCO!" ao passar raspando (pulando, deslizando ou
## trocando de faixa em cima da hora).
const NEAR_MISS_XP := 2
static var _last_near_miss_ms := -10000
var _player: Node3D
var _passed := false


func _ready() -> void:
	add_to_group("obstacle")
	AssetLibrary.apply(self, asset_id)
	_player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if _passed or not is_instance_valid(_player) or _player.global_position.z > global_position.z - 0.8:
		return
	_passed = true
	var dx := absf(_player.global_position.x - global_position.x)
	var dodging := dx < 2.2 and absf((_player as CharacterBody3D).velocity.x) > 3.0
	if dx > 1.0 and not dodging:
		return
	var now := Time.get_ticks_msec()
	if now - _last_near_miss_ms < 600:
		return
	_last_near_miss_ms = now
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager and run_manager.has_method("add_style_xp"):
		run_manager.add_style_xp(NEAR_MISS_XP)
	AudioManager.play("pickup", -8.0, 1.6, 0.0)
	Fx.float_text(_player, _player.global_position + Vector3.UP * 2.4, "POR POUCO! +%d XP" % NEAR_MISS_XP, Color(1.0, 0.9, 0.4), 46)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	# Seção 63: o furgão atravessa, pagando em HP.
	var vehicle := body.get_node_or_null("Vehicle")
	if vehicle and vehicle.hit_obstacle(self):
		return

	var health := body.get_node_or_null("Health")
	if health:
		health.take_damage(damage)
	_passed = true
	Juice.hit_stop(0.06)
	AudioManager.play("crash", -2.0)

	# Destroços na cor do obstáculo.
	var color := Color.GRAY
	for child in get_children():
		if child is MeshInstance3D and child.material_override:
			color = child.material_override.albedo_color
			break
	Fx.burst(get_parent(), body.global_position + Vector3(0, 1.0, -0.6), color, 16, 5.0, 0.18)
	queue_free()
