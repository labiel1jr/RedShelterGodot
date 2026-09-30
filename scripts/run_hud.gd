extends Control

## HUD da cena Run: distância até a extração, HP com estado (seção 7 do
## GDD), loot, zumbis eliminados, seed, munição, ruído (seção 34), peso da
## mochila (seção 32), durabilidade da faca (seção 16), aviso de agarrão,
## flash de dano e botão de ataque.

const HP_STATES := [
	# [fração mínima de HP, nome, cor]
	[0.6, "NORMAL", Color(0.55, 0.9, 0.45)],
	[0.3, "FERIDO", Color(1.0, 0.8, 0.25)],
	[0.0, "CRÍTICO", Color(1.0, 0.3, 0.25)],
]

@onready var distance_label: Label = $DistanceLabel
@onready var hp_label: Label = $HPLabel
@onready var loot_label: Label = $LootLabel
@onready var grab_label: Label = $GrabLabel
@onready var attack_button: Button = $AttackButton
@onready var seed_label: Label = $SeedLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var noise_bar: ProgressBar = $NoiseBar
@onready var damage_flash: ColorRect = $DamageFlash
@onready var backpack_label: Label = $BackpackLabel
@onready var knife_label: Label = $KnifeLabel
@onready var xp_label: Label = $XPLabel
@onready var event_banner: Label = $EventBanner
@onready var survivors_label: Label = $SurvivorsLabel
@onready var low_hp_vignette: TextureRect = $LowHPVignette
@onready var tutorial_hint: Label = $TutorialHint
@onready var pause_button: Button = $PauseButton
@onready var medkit_button: Button = $MedkitButton

## Abreviações do loot além de comida, água e sucata (seção 62).
const EXTRA_LOOT := [["components", "Comp."], ["medicine", "Remédio"], ["fuel", "Comb."]]

var _critical := false
var _hint_tween: Tween

var run_manager: Node3D
var player_health: Node
var player_combat: Node
var _pulse_time := 0.0
var _last_hp := -1


func _ready() -> void:
	grab_label.hide()

	run_manager = get_tree().get_first_node_in_group("run_manager")
	if not run_manager:
		return

	player_health = run_manager.get_node("Player/Health")
	player_health.health_changed.connect(_on_health_changed)
	_on_health_changed(player_health.current_hp, player_health.max_hp)
	damage_flash.color.a = 0.0

	player_combat = run_manager.get_node("Player/Combat")
	player_combat.grab_changed.connect(_on_grab_changed)
	# button_down em vez de pressed: responde no toque, sem esperar soltar.
	attack_button.button_down.connect(player_combat.attack)
	player_combat.ammo_changed.connect(_on_ammo_changed)
	pause_button.pressed.connect(func(): run_manager.get_node("PauseLayer/PauseMenu").open())
	player_combat.knife_durability_changed.connect(_on_knife_durability_changed)
	noise_bar.max_value = run_manager.max_noise
	medkit_button.text = "KIT +%d" % GameManager.SHELTER.medkit_heal
	medkit_button.button_down.connect(run_manager.use_medkit)


func _process(delta: float) -> void:
	if not run_manager:
		return

	distance_label.text = "%s  ·  %.0f / %.0f m" % [
		run_manager.chunk_streamer.region.display_name,
		clampf(run_manager.distance_travelled(), 0.0, run_manager.extraction_distance),
		run_manager.extraction_distance,
	]
	var rescued: int = run_manager.rescued_survivors.size()
	survivors_label.text = ("Sobreviventes com você: %d (leve até a extração)" % rescued) if rescued > 0 else ""
	var collected: Dictionary = run_manager.collected
	var loot_text := "Comida %d  Água %d  Sucata %d" % [collected.food, collected.water, collected.scrap]
	for pair in EXTRA_LOOT:
		if collected[pair[0]] > 0:
			loot_text += "  %s %d" % [pair[1], collected[pair[0]]]
	loot_label.text = loot_text + "   Zumbis %d" % run_manager.zombies_killed

	medkit_button.visible = run_manager.medkit_available and not run_manager.medkit_used
	medkit_button.disabled = player_health.current_hp >= player_health.max_hp

	# Seção 30: a fase do Director, discreta, junto da seed.
	seed_label.text = "SEED %d  ·  %s" % [run_manager.expedition_seed, run_manager.director.phase_name()]
	noise_bar.value = run_manager.noise

	xp_label.text = "XP: %d (se extrair)" % run_manager.xp_if_extracted()

	var carried: float = run_manager.carried_weight()
	var capacity: float = run_manager.backpack_capacity()
	backpack_label.text = "Mochila: %.1f / %.0f kg" % [carried, capacity]
	backpack_label.modulate = Color(1, 0.45, 0.3) if carried >= capacity - 0.5 else Color.WHITE

	# Vinheta vermelha pulsando com HP crítico.
	if _critical:
		low_hp_vignette.modulate.a = 0.45 + 0.35 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
	elif low_hp_vignette.modulate.a > 0.0:
		low_hp_vignette.modulate.a = maxf(0.0, low_hp_vignette.modulate.a - delta * 2.0)

	if grab_label.visible:
		_pulse_time += delta
		grab_label.modulate.a = 0.6 + 0.4 * sin(_pulse_time * 10.0)


func _on_health_changed(current: int, max_hp: int) -> void:
	if current < _last_hp:
		# Som de dano: golpes fortes sempre; ticks do agarrão, espaçados.
		var damage := _last_hp - current
		AudioManager.play("hurt", -2.0 if damage >= 5 else -12.0, 1.0, 0.1, 0.1 if damage >= 5 else 0.9)
		# Flash vermelho proporcional ao dano.
		damage_flash.color.a = clampf(float(_last_hp - current) / 40.0, 0.08, 0.45)
		var tween := create_tween()
		tween.tween_property(damage_flash, "color:a", 0.0, 0.35)
	_last_hp = current

	var ratio := float(current) / float(max_hp)
	_critical = current > 0 and ratio < HP_STATES[1][0]
	AudioManager.set_heartbeat(_critical)
	for hp_state in HP_STATES:
		if ratio >= hp_state[0]:
			hp_label.text = "HP: %d/%d  %s" % [current, max_hp, hp_state[1]]
			hp_label.modulate = hp_state[2]
			return


## Desenha os caracteres uma vez nos rótulos grandes (invisíveis) para a
## fonte já estar rasterizada quando o primeiro aviso aparecer.
func warm_up_fonts(charset: String) -> void:
	for label in [event_banner, grab_label]:
		var old_text: String = label.text
		var was_visible: bool = label.visible
		label.text = charset
		label.visible = true
		label.self_modulate.a = 0.01
		await get_tree().process_frame
		await get_tree().process_frame
		label.text = old_text
		label.visible = was_visible
		label.self_modulate.a = 1.0


## Dica do tutorial na parte de baixo da tela; some sozinha.
func show_hint(text: String, duration := 4.5) -> void:
	if _hint_tween:
		_hint_tween.kill()
	tutorial_hint.text = text
	tutorial_hint.modulate.a = 0.0
	tutorial_hint.show()
	_hint_tween = create_tween()
	_hint_tween.tween_property(tutorial_hint, "modulate:a", 1.0, 0.25)
	_hint_tween.tween_interval(duration)
	_hint_tween.tween_property(tutorial_hint, "modulate:a", 0.0, 0.5)
	_hint_tween.tween_callback(tutorial_hint.hide)


## Aviso de evento (seção 27): aparece, pulsa e some.
func show_banner(text: String, color: Color) -> void:
	AudioManager.play("alarm", -4.0, 1.0, 0.0)
	event_banner.text = text
	event_banner.modulate = color
	event_banner.scale = Vector2.ONE * 1.3
	event_banner.pivot_offset = event_banner.size / 2.0
	var tween := create_tween()
	tween.tween_property(event_banner, "scale", Vector2.ONE, 0.25)
	tween.tween_interval(2.2)
	tween.tween_property(event_banner, "modulate:a", 0.0, 0.5)


func _on_ammo_changed(ammo: int) -> void:
	ammo_label.text = "%s · Munição: %d" % [player_combat.pistol.display_name, ammo]
	ammo_label.modulate = Color(1, 0.4, 0.3) if ammo == 0 else Color.WHITE


func _on_knife_durability_changed(current: int, max_durability: int) -> void:
	if current <= 0:
		knife_label.text = "%s: QUEBRADA (soco)" % player_combat.weapon.display_name
		knife_label.modulate = Color(1, 0.35, 0.25)
	else:
		knife_label.text = "%s: %d / %d" % [player_combat.weapon.display_name, current, max_durability]
		knife_label.modulate = Color(1, 0.8, 0.3) if current <= max_durability * 0.25 else Color.WHITE


func _on_grab_changed(is_grabbed: bool) -> void:
	grab_label.visible = is_grabbed
	_pulse_time = 0.0
