extends Node

## Autoload (seção 49 do GDD: Core/SaveManager). Salva o progresso do abrigo
## em user://save.json: recursos, construções, armas e dia. Salva sozinho ao
## fim de cada expedição e a cada ação no abrigo.

## Com `-- --sandbox` fica em user://sandbox/ (veja UserPaths).
var save_path := UserPaths.file("save.json")
const SAVE_VERSION := 1


func _ready() -> void:
	# Roda depois do GameManager (ordem dos autoloads): carrega por cima do
	# jogo novo que ele montou.
	load_game()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> void:
	var data := GameManager.to_dict()
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Não foi possível salvar em %s (%s)" % [save_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save corrompido em %s; começando um jogo novo." % save_path)
		return false
	GameManager.from_dict(data)
	return true


func start_new_game() -> void:
	GameManager.new_game()
	CampaignLog.reset()
	save_game()
