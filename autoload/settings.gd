extends Node

## Autoload: preferências do jogador (Fase 7), separadas do save do jogo, em
## user://settings.cfg — volumes, tremor de câmera e quais dicas do tutorial
## já foram mostradas.

signal changed

var path := UserPaths.file("settings.cfg")

var master_volume := 1.0
var music_volume := 0.7
var sfx_volume := 1.0
var camera_shake := true
var tutorial_enabled := true
## id da dica → true quando já foi mostrada.
var tutorial_seen := {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		master_volume = cfg.get_value("audio", "master", master_volume)
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
		camera_shake = cfg.get_value("game", "camera_shake", camera_shake)
		tutorial_enabled = cfg.get_value("tutorial", "enabled", tutorial_enabled)
		tutorial_seen = cfg.get_value("tutorial", "seen", {})


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "camera_shake", camera_shake)
	cfg.set_value("tutorial", "enabled", tutorial_enabled)
	cfg.set_value("tutorial", "seen", tutorial_seen)
	cfg.save(path)
	changed.emit()


## true na primeira vez (e marca como vista).
func should_show_hint(id: StringName) -> bool:
	if not tutorial_enabled or tutorial_seen.get(id, false):
		return false
	tutorial_seen[id] = true
	save()
	return true


func reset_tutorial() -> void:
	tutorial_seen.clear()
	tutorial_enabled = true
	save()
