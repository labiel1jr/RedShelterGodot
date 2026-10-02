class_name PowerUpPickup
extends Area3D

## Power-up na pista (seção 64 do GDD): anel branco pulsando com o nome no
## meio. Encostar ativa. Colocado pela Run e liberado junto com o chunk.

var data: PowerUpData

var _ring: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	add_to_group("powerup_pickup")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	shape.shape = sphere
	shape.position.y = 1.0
	add_child(shape)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.55
	_ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1)
	material.emission_enabled = true
	material.emission = Color(1, 1, 1)
	material.emission_energy_multiplier = 1.2
	_ring.material_override = material
	_ring.rotation.x = PI / 2.0
	_ring.position.y = 1.0
	add_child(_ring)

	var label := Label3D.new()
	label.text = data.short_name
	label.modulate = data.color
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.0
	add_child(label)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_ring.scale = Vector3.ONE * (1.0 + 0.12 * sin(_time * 6.0))


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var powerups := body.get_node_or_null("PowerUps")
	if powerups and not powerups.can_activate(data):
		return
	if powerups:
		powerups.activate(data)
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		if run_manager and data.hint != "" and Settings.should_show_hint(StringName("powerup_%s" % data.id)):
			run_manager.hud.show_hint(data.hint)
		queue_free()
