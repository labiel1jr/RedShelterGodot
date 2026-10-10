extends Node

## Autoload: aplica o estilo toon / cel-shading (seção 65 do GDD) em tudo o
## que entra na cena, sem trocar os materiais (o jogo muda cor, brilho e
## transparência deles em tempo de jogo):
## - luz em faixas: StandardMaterial3D com difuso e especular toon; a cor da
##   sombra vem da luz ambiente de cada região (RegionData);
## - contorno por casco invertido (art/shaders/outline.gdshader) como
##   material_overlay de cada objeto, com espessura pela classe dele.

const OUTLINE_SHADER := preload("res://art/shaders/outline.gdshader")

## Espessura (m) e distância em que some, por classe de objeto.
const CLASSES := {
	&"actor": {"width": 0.045, "fade_start": 0.0, "fade_end": 0.0},
	&"obstacle": {"width": 0.03, "fade_start": 0.0, "fade_end": 0.0},
	&"scenery": {"width": 0.018, "fade_start": 30.0, "fade_end": 45.0},
}
## Grupos que fazem um objeto ser ator (contorno grosso e brilho de borda).
const ACTOR_GROUPS: Array[StringName] = [&"player", &"zombie", &"loot", &"powerup_pickup", &"vehicle_pickup", &"survivor"]

## Ligado/desligado (para comparar e para celulares fracos).
var enabled := true
var _overlays := {}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if enabled and node is MeshInstance3D:
		# Adiado: muitos nós criam o material no próprio _ready.
		_style.call_deferred(node)


func _style(mesh: MeshInstance3D) -> void:
	if not is_instance_valid(mesh) or not mesh.is_inside_tree() or mesh.mesh == null:
		return
	var kind := _classify(mesh)
	var lit := false
	for material in _materials(mesh):
		if material is StandardMaterial3D:
			if material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			lit = true
			if not material.has_meta("toon"):
				material.set_meta("toon", true)
				material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				material.specular_mode = BaseMaterial3D.SPECULAR_TOON
				material.roughness = maxf(material.roughness, 0.7)
			if kind == &"actor" and not material.rim_enabled:
				material.rim_enabled = true
				material.rim = 0.5
				material.rim_tint = 0.4
	# Efeitos (rastros, clarões, transparentes) ficam sem contorno.
	if lit and kind != &"" and mesh.material_overlay == null:
		mesh.material_overlay = _overlay(kind, mesh.mesh is PrimitiveMesh)


## Classe pelo grupo do objeto ou de um ancestral; o cenário dos chunks e do
## abrigo é "scenery".
func _classify(mesh: Node) -> StringName:
	var node := mesh
	while node and node != get_tree().root:
		for group in ACTOR_GROUPS:
			if node.is_in_group(group):
				return &"actor"
		if node.is_in_group(&"obstacle"):
			return &"obstacle"
		node = node.get_parent()
	return &"scenery"


func _materials(mesh: MeshInstance3D) -> Array:
	var list := []
	if mesh.material_override:
		list.append(mesh.material_override)
	for i in mesh.mesh.get_surface_count():
		var material := mesh.get_surface_override_material(i)
		if not material:
			material = mesh.mesh.surface_get_material(i)
		if material and not material in list:
			list.append(material)
	return list


func _overlay(kind: StringName, from_center: bool) -> ShaderMaterial:
	var key := "%s_%s" % [kind, from_center]
	if not _overlays.has(key):
		var material := ShaderMaterial.new()
		material.shader = OUTLINE_SHADER
		var settings: Dictionary = CLASSES[kind]
		material.set_shader_parameter("width", settings.width)
		material.set_shader_parameter("fade_start", settings.fade_start)
		material.set_shader_parameter("fade_end", settings.fade_end)
		material.set_shader_parameter("from_center", from_center)
		_overlays[key] = material
	return _overlays[key]
