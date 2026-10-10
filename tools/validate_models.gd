extends SceneTree

## Confere os modelos entregues em art/models/ contra o catálogo
## (docs/assets/asset_list.json) e as regras da seção 65 do GDD.
## Uso: godot --headless --path . -s res://tools/validate_models.gd
## Sai com código 1 se algum modelo tiver erro.

const CATALOG := "res://docs/assets/asset_list.json"
## Tolerância das medidas (fração do size_m).
const SIZE_TOLERANCE := 0.15
const PIVOT_TOLERANCE := 0.05


func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var assets := {}
	for asset in catalog.assets:
		assets[StringName(asset.id)] = asset
	var budgets := _budgets(catalog.global_specs.tri_budgets)

	var errors := 0
	var checked := 0
	for id in _model_ids():
		checked += 1
		var problems: Array[String] = []
		var warnings: Array[String] = []
		var asset: Dictionary = assets.get(id, {})
		var path := AssetLibrary.model_path(id)
		if asset.is_empty():
			problems.append("id fora do catálogo (nome do arquivo = id do asset)")
		elif not path.contains("/%s/" % asset.category):
			problems.append("pasta errada: deveria estar em art/models/%s/" % asset.category)

		var model := AssetLibrary.instantiate(id)
		if not model:
			problems.append("não abriu (glTF inválido?)")
		else:
			var stats := _measure(model)
			var aabb: AABB = stats.aabb
			if not asset.is_empty():
				var budget: int = budgets.get(asset.get("size_class", ""), 0)
				if budget > 0 and stats.tris > budget:
					problems.append("%d triângulos (limite %d para '%s')" % [stats.tris, budget, asset.size_class])
				if asset.has("size_m"):
					var want := Vector3(asset.size_m[0], asset.size_m[1], asset.size_m[2])
					var has_rules: bool = asset.has("gameplay_rules")
					for axis in 3:
						if want[axis] <= 0.0:
							continue
						var diff := absf(aabb.size[axis] - want[axis]) / want[axis]
						if diff > SIZE_TOLERANCE:
							var msg := "eixo %s mede %.2f m, esperado %.2f m" % ["XYZ"[axis], aabb.size[axis], want[axis]]
							if has_rules and aabb.size[axis] > want[axis]:
								problems.append(msg + " (passa da colisão)")
							else:
								warnings.append(msg)
			if absf(aabb.position.y) > PIVOT_TOLERANCE:
				problems.append("pivô fora do chão (base em y = %.2f)" % aabb.position.y)
			var center := aabb.get_center()
			if absf(center.x) > 0.25 or absf(center.z) > 0.25:
				warnings.append("pivô fora do centro da base (centro em x=%.2f, z=%.2f)" % [center.x, center.z])
			if stats.materials > 1:
				warnings.append("%d materiais (o padrão é 1, a textura-paleta)" % stats.materials)
			print("%s  %d tri  %.2f x %.2f x %.2f m" % [id, stats.tris, aabb.size.x, aabb.size.y, aabb.size.z])
			model.free()

		for p in problems:
			print("  ERRO  ", p)
		for w in warnings:
			print("  aviso ", w)
		if not problems.is_empty():
			errors += 1

	print("\n%d modelo(s) conferido(s), %d com erro." % [checked, errors])
	quit(1 if errors > 0 else 0)


func _model_ids() -> Array[StringName]:
	AssetLibrary.rescan()
	AssetLibrary.has_model(&"")
	var ids: Array[StringName] = []
	ids.assign(AssetLibrary._index.keys())
	ids.sort()
	return ids


## "até 300 triângulos (...)" → 300.
func _budgets(text: Dictionary) -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string("([\\d.]+)")
	for key in text:
		var m := re.search(String(text[key]))
		if m:
			out[key] = int(m.get_string(1).replace(".", ""))
	return out


func _measure(root: Node3D) -> Dictionary:
	var tris := 0
	var aabb := AABB()
	var first := true
	var materials := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D and node.mesh:
			var mesh: Mesh = node.mesh
			var xform: Transform3D = _xform_to(root, node)
			var box := xform * mesh.get_aabb()
			aabb = box if first else aabb.merge(box)
			first = false
			for i in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(i)
				var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += (index.size() if index.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				var mat := mesh.surface_get_material(i)
				if mat:
					materials[mat.resource_name if mat.resource_name != "" else str(mat.get_instance_id())] = true
	return {"tris": tris, "aabb": aabb, "materials": materials.size()}


func _xform_to(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n and n != root:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return xform
