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
##   (resolve_slots, chamado pelo MeshMerger antes de mesclar).

const MODELS_DIR := "res://art/models/"

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
	for child in root.get_children():
		if child is MeshInstance3D:
			child.visible = false
	model.name = "Model"
	root.add_child(model)
	return model


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
