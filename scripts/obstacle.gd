extends Area3D

## Obstáculo da pista (camada 2 da seção 21 do GDD). Instanciado pelo
## ChunkPopulator e liberado junto com o chunk.

@export var damage := 15
## wall / low / high — usado pelas dicas do tutorial.
@export var kind := &"wall"


func _ready() -> void:
	add_to_group("obstacle")
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
	AudioManager.play("crash", -2.0)

	# Destroços na cor do obstáculo.
	var color := Color.GRAY
	for child in get_children():
		if child is MeshInstance3D and child.material_override:
			color = child.material_override.albedo_color
			break
	Fx.burst(get_parent(), body.global_position + Vector3(0, 1.0, -0.6), color, 16, 5.0, 0.18)
	queue_free()
