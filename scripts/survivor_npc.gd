extends Area3D

## Sobrevivente pedindo ajuda na pista (seções 27 e 44 do GDD). Encostar
## resgata; ela só vira moradora do abrigo se a expedição terminar em
## extração (e houver vaga).

var survivor_name := ""
var profession: ProfessionData

var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = profession.color if profession else Color(0.8, 0.8, 0.8)
	$Body.material_override = mat
	$Label3D.text = "SOCORRO!\n%s · %s" % [survivor_name, profession.display_name if profession else "?"]


func _process(delta: float) -> void:
	# Acena e pula no lugar para chamar atenção.
	_time += delta
	$Body.position.y = 0.9 + absf(sin(_time * 5.0)) * 0.25
	$Arm.rotation.z = 2.2 + sin(_time * 10.0) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager:
		run_manager.rescue_survivor({"name": survivor_name, "profession": profession.id})
	AudioManager.play("ui_confirm")
	Fx.float_text(body, global_position + Vector3.UP * 2.6, "RESGATADO: %s" % survivor_name, Color(0.55, 0.85, 1.0), 52)
	Fx.burst(get_parent(), global_position + Vector3.UP, Color(0.55, 0.85, 1.0), 14, 3.0, 0.1)
	queue_free()
