class_name AssetLibrary
extends RefCounted

## Modelos dos artistas (seção 65 do GDD, Fase 15 / A2). Cada asset do
## catálogo (docs/assets/asset_list.json) é entregue em
## art/models/<categoria>/<id>.glb. Enquanto o arquivo não existe, o jogo
## mostra a forma provisória (caixas); quando ele chega, a troca é automática.
##
## Onde a troca acontece:
## - obstáculos e loot: pelo `asset_id` do próprio script (obstacle.gd,
##   loot_pickup.gd);
## - cenário dos chunks e do abrigo: qualquer nó com o metadado `asset_id`
##   (variantes: `<id>_<variante>`, ex.: prop_barrels_rust)
##   (resolve_slots, chamado pelo MeshMerger antes de mesclar).

const MODELS_DIR := "res://art/models/"
## Só nesta máquina (fora do Git e do APK): substitui o modelo de mesmo id.
const LOCAL_DIR := "res://art/models_local/"

## id → caminho do .glb (montado uma vez, varrendo a pasta).
static var _index := {}
static var _scanned := false
static var _scenes := {}


static func has_model(id: StringName) -> bool:
	_scan()
	return _index.has(id)


static func model_path(id: StringName) -> String:
	_scan()
	return _index.get(id, "")


## Nova instância do modelo, ou null se ele ainda não foi entregue.
static func instantiate(id: StringName) -> Node3D:
	var path := model_path(id)
	if path == "":
		return null
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var scene: PackedScene = _scenes[path]
	return scene.instantiate() if scene else null


## Troca a forma provisória de `root` pelo modelo `id`: esconde (e tira da
## mesclagem) as malhas filhas diretas e põe o modelo no lugar. Sem modelo,
## não faz nada. Retorna o modelo instanciado.
static func apply(root: Node3D, id: StringName) -> Node3D:
	if id == &"" or root.has_meta(&"asset_applied"):
		return null
	var model := instantiate(id)
	if not model:
		return null
	root.set_meta(&"asset_applied", true)
	model.name = "Model"
	if root is MeshInstance3D and root.mesh:
		# A própria forma provisória é o lugar (tambor, caixa do cenário): o
		# modelo fica com a base no chão dela e a mesma altura.
		var box: AABB = root.mesh.get_aabb()
		root.mesh = null
		root.material_override = null
		model.position = Vector3(box.get_center().x, box.position.y, box.get_center().z)
		var height := _height(model)
		# `asset_fit = false`: mantém o tamanho real do modelo (detritos).
		if height > 0.0 and root.get_meta(&"asset_fit", true):
			model.scale = Vector3.ONE * (box.size.y / height)
	for child in root.get_children():
		if child is MeshInstance3D:
			child.visible = false
	root.add_child(model)
	return model


static func _height(node: Node) -> float:
	var top := -INF
	var bottom := INF
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mi.transform * mi.mesh.get_aabb()
		top = maxf(top, box.end.y)
		bottom = minf(bottom, box.position.y)
	return top - bottom if top > bottom else 0.0


## Troca todos os nós com o metadado `asset_id` dentro de `root`.
static func resolve_slots(root: Node) -> void:
	if root is Node3D and root.has_meta(&"asset_id"):
		apply(root, StringName(root.get_meta(&"asset_id")))
		return
	for child in root.get_children():
		resolve_slots(child)


## Esquece a varredura (testes e recarga de modelos no editor).
static func rescan() -> void:
	_scanned = false
	_index.clear()
	_scenes.clear()


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	_scan_dir(MODELS_DIR)
	_scan_dir(LOCAL_DIR)


static func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	for sub in dir.get_directories():
		_scan_dir(dir_path.path_join(sub))
	for file in dir.get_files():
		# No jogo exportado o .glb vira "<arquivo>.glb.import" / ".remap".
		var name := file.trim_suffix(".import").trim_suffix(".remap")
		if name.get_extension().to_lower() in ["glb", "gltf"]:
			_index[StringName(name.get_basename())] = dir_path.path_join(name)
