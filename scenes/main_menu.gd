extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var settings_panel: Control = $SettingsPanel
@onready var confirm_new_game: ConfirmationDialog = $ConfirmNewGame


func _ready() -> void:
	play_button.pressed.connect(_go_to_shelter)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(settings_panel.show)
	confirm_new_game.confirmed.connect(_start_new_game)
	AudioManager.play_music("music_shelter")

	# Sem save, "Continuar" vira "Jogar" e já começa um jogo novo.
	if not SaveManager.has_save():
		play_button.text = "Jogar"
		new_game_button.hide()
	else:
		play_button.text = "Continuar (dia %d)" % GameManager.day


func _on_new_game_pressed() -> void:
	confirm_new_game.popup_centered()


func _start_new_game() -> void:
	SaveManager.start_new_game()
	_go_to_shelter()


func _go_to_shelter() -> void:
	if not SaveManager.has_save():
		SaveManager.save_game()
	# Fluxo da seção 48 do GDD: MAIN MENU → SHELTER → expedição.
	Transition.change_scene("res://scenes/shelter.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
