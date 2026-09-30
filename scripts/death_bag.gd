extends Area3D

## Mochila deixada no local da morte (seção 47 do GDD). A Run a coloca na
## pista quando a expedição é a volta ao local; encostar recupera o que
## couber na mochila atual.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	$Bag.rotate_y(1.2 * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if not run_manager:
		return
	var taken: int = run_manager.collect_bag()
	var pos: Vector3 = $Bag.global_position
	AudioManager.play("pickup", -2.0, 0.7)
	Fx.burst(get_parent(), pos, Color(1.0, 0.8, 0.35), 24, 4.0, 0.12)
	Fx.float_text(body, pos + Vector3.UP * 1.4, "MOCHILA RECUPERADA (+%d)" % taken if taken > 0 else "MOCHILA CHEIA — NADA COUBE", Color(1.0, 0.85, 0.4), 52)
	queue_free()
