class_name LootPickup
extends Area3D

## Loot da pista (seção 31 do GDD). Instanciado pelo ChunkPopulator e
## liberado junto com o chunk.
## loot_type: índice de GameManager.LOOT_KEYS — 0 Comida, 1 Água, 2 Sucata,
## 3 Munição, 4 Componentes, 5 Medicamentos, 6 Combustível. Cores iguais às
## caixas do depósito no abrigo.

const COLORS: Array[Color] = [
	Color(0.95, 0.55, 0.2), Color(0.3, 0.6, 1.0), Color(0.7, 0.7, 0.72), Color(0.95, 0.8, 0.3),
	Color(0.3, 0.9, 0.8), Color(0.97, 0.97, 1.0), Color(0.61, 0.36, 0.9),
]
## Modelos do catálogo de assets, na mesma ordem.
const ASSET_IDS: Array[StringName] = [&"loot_food", &"loot_water", &"loot_scrap", &"loot_ammo", &"loot_components", &"loot_medicine", &"loot_fuel"]
const NAMES: Array[String] = ["Comida", "Água", "Sucata", "Munição", "Componentes", "Medicamentos", "Combustível"]

@export var loot_type := 2
@export var amount := 1
## Recurso raro de evento (seção 27): maior e brilhando.
@export var rare := false

## O que gira: o modelo do artista ou a forma provisória.
var _visual: Node3D


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)

	_visual = AssetLibrary.apply(self, ASSET_IDS[loot_type])
	if _visual:
		# O pivô do modelo fica na base (catálogo); a forma provisória, no centro.
		_visual.position = $MeshInstance3D.position - Vector3(0, 0.3, 0)
	else:
		_visual = $MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS[loot_type]
		mat.emission_enabled = true
		mat.emission = COLORS[loot_type] * 0.4
		$MeshInstance3D.material_override = mat
		if rare:
			mat.emission = COLORS[loot_type]
			mat.emission_energy_multiplier = 1.5
	if rare:
		_visual.scale = Vector3.ONE * 1.6


func _process(delta: float) -> void:
	_visual.rotate_y(2.0 * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if not run_manager:
		return

	var pos: Vector3 = _visual.global_position
	var taken: int = run_manager.collect_loot(loot_type, amount)
	if taken == 0:
		# Seção 32: mochila cheia — o loot fica na pista.
		AudioManager.play("empty")
		Fx.float_text(body, pos + Vector3.UP * 1.2, "MOCHILA CHEIA", Color(1, 0.4, 0.3), 44)
		return

	AudioManager.play("pickup", -4.0, 0.8 if rare else 1.0)
	Fx.burst(get_parent(), pos, COLORS[loot_type], 10, 3.0, 0.1)
	Fx.float_text(body, pos + Vector3.UP * 1.2, "+%d %s" % [taken, NAMES[loot_type]], COLORS[loot_type], 48)
	queue_free()
