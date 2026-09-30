extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var resources_label: Label = $VBoxContainer/ResourcesLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var menu_button: Button = $VBoxContainer/MenuButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	var gm := GameManager
	title_label.text = "Extração concluída" if gm.last_run_survived else "Você morreu"

	var text := "Seed: %d\nDistância: %.0f m   Zumbis eliminados: %d\n\n" % [
		gm.last_run_seed, gm.last_run_distance, gm.last_run_kills
	]
	text += "Obtido — %s\n" % _loot_text(gm.last_run_loot)
	if not gm.last_run_survived:
		# Seção 46 do GDD: parte do loot se perde na morte.
		text += "Recuperado — %s\n" % _loot_text(gm.last_run_recovered)
		# Seção 41: morrer deixa a personagem Ferida.
		text += "Você está FERIDA nas próximas %d expedições (trate na Enfermaria).\n" % gm.injured_days
		if gm.last_run_bag == "left":
			text += "O que se perdeu ficou numa mochila a %.0f m — dá para voltar buscar (%d expedições).\n" % [gm.death_bag.at, gm.death_bag.runs_left]
	text += "XP: +%d (metade, por ter morrido)\n" % gm.last_run_xp if not gm.last_run_survived else "XP: +%d\n" % gm.last_run_xp
	text += "\nTotal no abrigo — Comida: %d | Água: %d | Sucata: %d | Munição: %d" % [
		gm.food, gm.water, gm.scrap, gm.ammo
	]
	resources_label.text = text


## "Comida 3 | Água 2 | ..." com os tipos que vieram (sempre os 4 básicos).
static func _loot_text(loot: Dictionary) -> String:
	var parts: Array[String] = []
	for key in GameManager.LOOT_KEYS:
		var amount: int = loot.get(key, 0)
		if amount > 0 or key in ["food", "water", "scrap", "ammo"]:
			parts.append("%s: %d" % [GameManager.RESOURCE_NAMES[key], amount])
	return " | ".join(parts)


func _on_continue_pressed() -> void:
	Transition.change_scene("res://scenes/shelter.tscn")


func _on_menu_pressed() -> void:
	Transition.change_scene("res://scenes/main_menu.tscn")
