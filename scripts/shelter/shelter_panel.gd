class_name ShelterPanel
extends PanelContainer

## Base dos painéis do abrigo (Construir, Oficina): uma lista de linhas com
## nome, detalhe, custo e um botão de ação. Subclasses preenchem
## `_build_rows()`.

## Emitido depois de uma ação bem-sucedida (recursos/níveis mudaram).
signal changed

## Som de uma ação bem-sucedida.
var action_sound := "build"

const COLOR_BLOCKED := Color(1.0, 0.55, 0.45)
const COLOR_SELECTED := Color(0.55, 0.9, 0.5)
const COLOR_DETAIL := Color(0.78, 0.78, 0.78)

@onready var rows: VBoxContainer = $Margin/VBox/Scroll/Rows
@onready var close_button: Button = $Margin/VBox/CloseButton


func _ready() -> void:
	close_button.pressed.connect(hide)


func open() -> void:
	refresh()
	show()


func refresh() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	_build_rows()


func _build_rows() -> void:
	pass


func add_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.95, 0.4, 0.3)
	rows.add_child(label)


## Linha só informativa (sem botão).
func add_info(title: String, detail: String) -> void:
	var texts := VBoxContainer.new()
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	texts.add_child(title_label)
	if detail != "":
		var detail_label := Label.new()
		detail_label.text = detail
		detail_label.add_theme_font_size_override("font_size", 14)
		detail_label.modulate = COLOR_DETAIL
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(detail_label)
	rows.add_child(texts)


## `block_reason` vazio = ação disponível. `action` retorna true se deu certo.
## `selected` marca a opção atual (botão desligado, texto em verde).
func add_row(title: String, detail: String, cost: String, button_text: String, block_reason: String, action: Callable, selected := false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 19)
	texts.add_child(title_label)
	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.modulate = COLOR_DETAIL
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(detail_label)
	row.add_child(texts)

	var cost_label := Label.new()
	cost_label.custom_minimum_size = Vector2(190, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_font_size_override("font_size", 15)
	var blocked := block_reason != ""
	cost_label.text = block_reason if blocked else cost
	if blocked:
		cost_label.modulate = COLOR_BLOCKED
	elif selected:
		cost_label.modulate = COLOR_SELECTED
	row.add_child(cost_label)

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(130, 44)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = blocked or selected
	button.pressed.connect(func():
		if action.call():
			AudioManager.play(action_sound, -2.0, 1.0, 0.0)
			refresh()
			changed.emit()
	)
	row.add_child(button)

	rows.add_child(row)
	rows.add_child(HSeparator.new())
