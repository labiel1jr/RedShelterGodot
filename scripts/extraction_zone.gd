extends Area3D

## Ponto de extração no fim da pista (seção 48 do GDD: EXTRACTION).
## A Run posiciona este nó em Z = -extraction_distance.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager:
		run_manager.extract_successfully()
