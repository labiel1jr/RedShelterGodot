class_name VehiclePickup
extends Area3D

## Veículo estacionado na pista (seção 63 do GDD). Encostar monta nele.
## Colocado pela Run e liberado junto com o chunk.

var data: VehicleData

var _visual: Node3D


func _ready() -> void:
	add_to_group("vehicle_pickup")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# O furgão, de duas faixas, monta em quem passar em qualquer uma delas.
	box.size = Vector3(4.4, 2.2, 3.0) if data.two_lanes else Vector3(1.6, 2.0, 1.6)
	shape.shape = box
	shape.position.y = 1.0
	add_child(shape)

	_visual = PlayerVehicle.build_visual(data)
	if not data.two_lanes:
		_visual.scale = Vector3.ONE * 1.8
		_visual.position.y = 0.35
	add_child(_visual)
	var material: StandardMaterial3D = _visual.get_meta("material")
	material.emission_energy_multiplier = 0.9

	var label := Label3D.new()
	label.text = data.display_name.to_upper()
	label.modulate = data.color
	label.font_size = 48
	label.outline_size = 12
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 3.4 if data.two_lanes else 1.7
	add_child(label)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not data.two_lanes:
		_visual.rotate_y(1.5 * delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var rider := body.get_node_or_null("Vehicle")
	if rider and rider.mount(data):
		queue_free()
