extends Control

## Pausa da expedição (Fase 7): Esc / P ou o botão ‖ no HUD. Continuar,
## Configurações ou abandonar (conta como morte: metade do loot se perde).

@onready var panel: Control = $Center/Panel
@onready var resume_button: Button = $Center/Panel/Margin/VBox/Resume
@onready var settings_button: Button = $Center/Panel/Margin/VBox/SettingsButton
@onready var abandon_button: Button = $Center/Panel/Margin/VBox/Abandon
@onready var settings_panel: Control = $SettingsPanel
@onready var confirm_abandon: ConfirmationDialog = $ConfirmAbandon


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(func(): panel.hide(); settings_panel.show())
	settings_panel.closed.connect(panel.show)
	abandon_button.pressed.connect(confirm_abandon.popup_centered)
	confirm_abandon.confirmed.connect(_abandon)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	var run := get_tree().get_first_node_in_group("run_manager")
	if run and run.run_ended:
		return
	show()
	panel.show()
	settings_panel.hide()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _abandon() -> void:
	close()
	var run := get_tree().get_first_node_in_group("run_manager")
	if run:
		run.abandon()
