class_name MeshMerger
extends RefCounted

## Otimização de chunks (seção 51 do GDD). Os chunks são feitos de muitas
## caixas separadas — cada uma seria um draw call (mais outro na sombra).
## Ao carregar um chunk, a geometria estática (fora de Area3D) é mesclada num
## mesh por material, e o resultado fica em cache por cena: da segunda vez em
## diante é só trocar as caixas pelos meshes prontos. A cena .tscn continua
## editável normalmente.

## Peças pequenas que não projetam sombra (economiza o passe de sombra).
const NO_SHADOW_PREFIXES := [
	"LaneDash", "Debris", "Windows", "Window", "Glass", "Sleeper", "Rail", "Line",
	"Crosswalk", "Stripe", "Pipe", "Door", "Awning", "Sign", "Cart", "Pallet", "Barrel",
]

## caminho da cena → [[ArrayMesh, material, projeta sombra?], ...]
static var _cache := {}


static func merge_static(root: Node3D, key: String) -> void:
	# Modelos dos artistas entram antes, para serem mesclados também.
	AssetLibrary.resolve_slots(root)
	var meshes := _collect(root)
	if meshes.is_empty():
		return
	if not _cache.has(key):
		_cache[key] = _build(root, meshes)

	# Das folhas para a raiz: filhos (janelas) antes dos pais (prédios). Um
	# mesh que ainda tenha outros filhos só perde a geometria.
	for i in range(meshes.size() - 1, -1, -1):
		var mi := meshes[i]
		if mi.get_child_count() > 0:
			mi.mesh = null
			continue
		mi.get_parent().remove_child(mi)
		mi.free()
	for entry in _cache[key]:
		var merged := MeshInstance3D.new()
		merged.name = "Merged"
		merged.mesh = entry[0]
		merged.material_override = entry[1]
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if entry[2] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(merged)


## Monta o cache de uma cena sem esperar ela aparecer na corrida.
static func prewarm(scene: PackedScene) -> void:
	if _cache.has(scene.resource_path):
		return
	var instance: Node3D = scene.instantiate()
	merge_static(instance, scene.resource_path)
	instance.free()


static func _collect(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	for child in root.get_children():
		if child is Area3D:
			continue  # obstáculos, extração: têm lógica própria
		if child is MeshInstance3D and child.mesh and child.visible:
			found.append(child)
		found.append_array(_collect(child))
	return found


static func _build(root: Node3D, meshes: Array[MeshInstance3D]) -> Array:
	var groups := {}  # [material, sombra] → SurfaceTool
	var group_info := {}
	for mi in meshes:
		var shadow := not _is_decor(mi.name)
		var material: Material = mi.material_override
		var group_key := [material.get_instance_id() if material else 0, shadow]
		if not groups.has(group_key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[group_key] = st
			group_info[group_key] = [material, shadow]
		for surface in mi.mesh.get_surface_count():
			groups[group_key].append_from(mi.mesh, surface, _relative_transform(root, mi))

	var result := []
	for group_key in groups:
		result.append([groups[group_key].commit(), group_info[group_key][0], group_info[group_key][1]])
	return result


static func _is_decor(node_name: String) -> bool:
	for prefix in NO_SHADOW_PREFIXES:
		if node_name.begins_with(prefix):
			return true
	return false


## Transformação do nó relativa à raiz do chunk (a cena ainda não está na
## árvore, então não dá para usar global_transform).
static func _relative_transform(root: Node, node: Node3D) -> Transform3D:
	var xform := node.transform
	var parent := node.get_parent()
	while parent and parent != root:
		if parent is Node3D:
			xform = parent.transform * xform
		parent = parent.get_parent()
	return xform
