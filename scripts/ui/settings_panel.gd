extends PanelContainer

## Painel de Configurações (Fase 7): volumes, tremor de câmera e tutorial.
## Usado no menu principal e na pausa da expedição.

signal closed

@onready var master_slider: HSlider = $Margin/VBox/Master/Slider
@onready var music_slider: HSlider = $Margin/VBox/Music/Slider
@onready var sfx_slider: HSlider = $Margin/VBox/Sfx/Slider
@onready var shake_check: CheckButton = $Margin/VBox/Shake
@onready var tutorial_check: CheckButton = $Margin/VBox/Tutorial
@onready var reset_button: Button = $Margin/VBox/ResetTutorial
@onready var close_button: Button = $Margin/VBox/Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume
	shake_check.button_pressed = Settings.camera_shake
	tutorial_check.button_pressed = Settings.tutorial_enabled

	master_slider.value_changed.connect(func(v): Settings.master_volume = v; Settings.save())
	music_slider.value_changed.connect(func(v): Settings.music_volume = v; Settings.save())
	sfx_slider.value_changed.connect(func(v): Settings.sfx_volume = v; Settings.save(); AudioManager.play("pickup", -6.0, 1.0, 0.0, 0.15))
	shake_check.toggled.connect(func(on): Settings.camera_shake = on; Settings.save())
	# Seção 66: opções de acessibilidade do game juice, logo abaixo do tremor.
	var index := shake_check.get_index()
	for option in [["Flashes de tela", "screen_flashes"], ["Câmera lenta e pausas de impacto", "impact_pauses"]]:
		var check := CheckButton.new()
		check.text = option[0]
		check.button_pressed = Settings.get(option[1])
		var key: String = option[1]
		check.toggled.connect(func(on): Settings.set(key, on); Settings.save())
		index += 1
		shake_check.get_parent().add_child(check)
		shake_check.get_parent().move_child(check, index)
	tutorial_check.toggled.connect(func(on): Settings.tutorial_enabled = on; Settings.save())
	reset_button.pressed.connect(_on_reset_tutorial)
	close_button.pressed.connect(func(): hide(); closed.emit())


func _on_reset_tutorial() -> void:
	Settings.reset_tutorial()
	tutorial_check.button_pressed = true
	reset_button.text = "Dicas reativadas!"
