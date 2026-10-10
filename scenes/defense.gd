extends Node3D

## Defesa do abrigo (seção 45 do GDD): o mesmo motor da expedição, invertido.
## A personagem fica parada logo atrás do portão; a horda desce pelas três
## faixas. Em cada faixa, os zumbis param na barricada (se houver) e depois
## no portão, e batem até derrubar. Troque de faixa para mirar: a arma de
## fogo e a branca funcionam como na corrida. Armadilhas explodem uma vez;
## torres atiram sozinhas gastando munição. Portão a 0 = derrota.

const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")
const STREET_CHUNKS: Array[String] = ["res://scenes/chunks/residential.tscn", "res://scenes/chunks/avenue.tscn", "res://scenes/chunks/residential.tscn"]

## Frente do portão (onde os zumbis param) e das barricadas; linha das
## armadilhas; onde a horda surge.
const GATE_Z := -1.6
const BARRICADE_Z := -14.0
const TRAP_Z := -26.0
const TRAP_RADIUS := 2.6
const SPAWN_Z := -72.0
const STOP_GAP := 0.6
const LANE_WIDTH := 2.5

@onready var player: CharacterBody3D = $Player
@onready var player_health: Node = $Player/Health
@onready var player_combat: Node = $Player/Combat
@onready var actors: Node3D = $Actors
@onready var camera: Camera3D = $Camera3D
@onready var hud: Control = $HUD

## Interface compatível com a Run (zumbis, combate e pausa usam).
var noise := 0.0
var run_ended := false
var zombies_killed := 0
var kill_xp := 0

var gate_hp := 0.0
var gate_max := 1.0
## HP de cada barricada (0 = caída ou inexistente).
var barricade_hp: Array[float] = [0.0, 0.0, 0.0]
var barricade_max := 0.0
var trap_ready: Array[bool] = [false, false, false]
var trap_damage := 0

var _to_spawn := 0
var _structure_damage := 1.0
var _spawned := 0
var _spawn_timer := 0.0
var _spawn_interval := 1.0
var _rng := RandomNumberGenerator.new()
var _towers: Array[Node3D] = []
var _tower_timer: Array[float] = []
var _tower_interval := 1.0
var _gate_nodes: Array[MeshInstance3D] = []
var _barricade_nodes: Array[Node3D] = []
var _trap_nodes: Array[Node3D] = []
var _gate_bar: ProgressBar
var _gate_label: Label
var _horde_label: Label
var _result_panel: PanelContainer


func _enter_tree() -> void:
	add_to_group("run_manager")


func _ready() -> void:
	var gm := GameManager
	var rules := gm.SHELTER
	# Seção 65: a defesa acontece na rua do abrigo, com a luz do Bairro.
	gm.WORLD.region(&"bairro").apply_atmosphere($WorldEnvironment.environment, $DirectionalLight3D)
	_rng.seed = gm.day * 7919 + gm.next_attack_day

	# A personagem não corre: fica no pátio, atrás do portão.
	player.forward_speed = 0.0
	player.speed_increase_per_second = 0.0
	player_health.died.connect(func(): _finish(false))
	player_combat.weapon = gm.knife()
	player_combat.pistol = gm.gun()
	player_combat.apply_visuals()
	player_combat.set_knife_durability(gm.knife_durability)
	player_combat.set_ammo(gm.ammo)
	player_health.max_hp += int(Progression.stat(&"max_hp"))
	if gm.is_injured():
		player_health.max_hp = roundi(player_health.max_hp * rules.wound_max_hp)
	player_health.set_hp(player_health.max_hp)
	player_health.damage_multiplier = Progression.multiplier(&"damage_taken")
	player_combat.melee_damage_multiplier = Progression.multiplier(&"melee_damage")
	player_combat.crit_bonus = Progression.stat(&"crit_chance")
	player_combat.cooldown_multiplier = Progression.multiplier(&"cooldown", 0.5)
	player.lane_change_speed *= Progression.multiplier(&"lane_speed")

	# Estruturas conforme as construções de Defesa (seção 39).
	var reinforce := gm.defense_reinforcement()
	_structure_damage = rules.horde_structure_damage
	gate_max = rules.building(&"gate").effect_at(gm.level_of(&"gate")) * reinforce
	gate_hp = gate_max
	barricade_max = rules.building(&"barricades").effect_at(gm.level_of(&"barricades")) * reinforce
	trap_damage = int(rules.building(&"traps").effect_at(gm.level_of(&"traps")))
	for lane in 3:
		barricade_hp[lane] = barricade_max
		trap_ready[lane] = trap_damage > 0
	var towers := int(rules.building(&"towers").effect_at(gm.level_of(&"towers")))
	var soldiers := gm.soldier_count()
	# Sem torre, cada Soldado(a) atira do muro (até dois).
	var shooters := towers if towers > 0 else mini(soldiers, 2)
	_tower_interval = rules.tower_interval / (1.0 + (soldiers * rules.soldier_fire_bonus if towers > 0 else 0.0))

	_build_arena(shooters, towers > 0)
	_build_hud()

	_to_spawn = gm.horde_size()
	_spawn_interval = rules.horde_duration / maxf(1.0, _to_spawn)
	_spawn_timer = 2.0
	hud.get_node("EventBanner").text = ""
	_banner("A HORDA ESTÁ CHEGANDO! (%d)" % _to_spawn, Color(1.0, 0.3, 0.25))
	if Settings.should_show_hint(&"defense_intro"):
		_hint("Defenda o PORTÃO: troque de faixa para mirar; use a faca nos que chegam ao portão. Barricadas seguram, armadilhas explodem e torres atiram sozinhas (gastam munição).")
	AudioManager.play_music("music_run")


# --------------------------------------------------------- compatibilidade

func add_noise(_amount: float, _from_player := true) -> void:
	pass


func register_kill(xp_reward: int) -> void:
	zombies_killed += 1
	kill_xp += xp_reward


## Pausa → Abandonar: conta como derrota.
func abandon() -> void:
	_finish(false)


func distance_travelled() -> float:
	return 0.0


# ------------------------------------------------------------- estruturas

## Onde o zumbi da faixa `lane` para: barricada em pé ou o portão.
func block_z(lane: int) -> float:
	if barricade_hp[lane] > 0.0:
		return BARRICADE_Z - STOP_GAP
	return GATE_Z - STOP_GAP


func hit_structure(lane: int, amount: float) -> void:
	if run_ended:
		return
	amount *= _structure_damage
	if barricade_hp[lane] > 0.0:
		barricade_hp[lane] = maxf(0.0, barricade_hp[lane] - amount)
		var node := _barricade_nodes[lane]
		node.scale.y = maxf(0.25, barricade_hp[lane] / maxf(1.0, barricade_max))
		if barricade_hp[lane] <= 0.0:
			node.hide()
			AudioManager.play("crash", 0.0, 0.8)
			Fx.burst(actors, node.global_position + Vector3.UP, Color(0.5, 0.35, 0.2), 24, 5.0, 0.2)
			_banner("BARRICADA CAIU!", Color(1.0, 0.6, 0.3))
		return
	gate_hp = maxf(0.0, gate_hp - amount)
	var ratio := gate_hp / gate_max
	for g in _gate_nodes:
		(g.material_override as StandardMaterial3D).albedo_color = Color(0.45, 0.4, 0.36).lerp(Color(0.6, 0.15, 0.1), 1.0 - ratio)
	if int(gate_hp) % 10 == 0:
		camera.shake(0.08)
	if gate_hp <= 0.0:
		_finish(false)


func _process(delta: float) -> void:
	if run_ended:
		return
	# Horda chegando em ondas.
	if _spawned < _to_spawn:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = _spawn_interval * _rng.randf_range(0.5, 1.5)
			var burst := 1 + (1 if _rng.randf() < 0.25 else 0)
			for i in burst:
				if _spawned < _to_spawn:
					_spawn_zombie()
	_update_traps()
	_update_towers(delta)
	_update_hud()
	if _spawned >= _to_spawn and _alive_count() == 0:
		_finish(true)


func _alive_count() -> int:
	var count := 0
	for z in get_tree().get_nodes_in_group("zombie"):
		if z.is_alive():
			count += 1
	return count


## Tipo pelo dia: runners a partir do dia 8, brutos e explosivos do 15,
## blindados do 22 (ShelterData.horde_*).
func _spawn_zombie() -> void:
	var rules := GameManager.SHELTER
	var weights := PackedFloat32Array()
	for i in rules.horde_zombies.size():
		var min_day: int = rules.horde_zombie_min_day[i] if i < rules.horde_zombie_min_day.size() else 0
		weights.append(rules.horde_zombie_weights[i] if GameManager.day >= min_day else 0.0)
	var zombie: Node3D = ZOMBIE_SCENE.instantiate()
	zombie.data = rules.horde_zombies[_rng.rand_weighted(weights)]
	zombie.defense = self
	zombie.lane = _rng.randi_range(0, 2)
	actors.add_child(zombie)
	zombie.global_position = Vector3((zombie.lane - 1) * LANE_WIDTH, 0.0, SPAWN_Z - _rng.randf_range(0.0, 8.0))
	zombie.alert()
	_spawned += 1


## Armadilha: o primeiro zumbi que passa dispara; fere todos por perto.
func _update_traps() -> void:
	for lane in 3:
		if not trap_ready[lane]:
			continue
		for z in get_tree().get_nodes_in_group("zombie"):
			if z.is_alive() and z.lane == lane and absf(z.global_position.z - TRAP_Z) < 0.8:
				trap_ready[lane] = false
				var center := Vector3((lane - 1) * LANE_WIDTH, 0.5, TRAP_Z)
				_trap_nodes[lane].hide()
				AudioManager.play("explosion", -4.0, 1.2)
				Fx.burst(actors, center, Color(1.0, 0.55, 0.1), 30, 7.0, 0.25)
				Fx.muzzle_flash(actors, center)
				for other in get_tree().get_nodes_in_group("zombie"):
					if other.is_alive() and other.global_position.distance_to(center) <= TRAP_RADIUS:
						other.take_hit(trap_damage, false)
				break


## Torres: o zumbi vivo mais próximo do portão, dentro do alcance.
func _update_towers(delta: float) -> void:
	var rules := GameManager.SHELTER
	for i in _towers.size():
		_tower_timer[i] -= delta
		if _tower_timer[i] > 0.0:
			continue
		if player_combat.ammo <= 0:
			continue
		var target: Node3D = null
		var best := -INF
		for z in get_tree().get_nodes_in_group("zombie"):
			if not z.is_alive():
				continue
			var dist: float = _towers[i].global_position.distance_to(z.global_position)
			if dist <= rules.tower_range and z.global_position.z > best:
				best = z.global_position.z
				target = z
		if not target:
			continue
		_tower_timer[i] = _tower_interval
		player_combat.set_ammo(player_combat.ammo - 1)
		var from: Vector3 = _towers[i].global_position + Vector3.UP * 4.2
		var to: Vector3 = target.global_position + Vector3.UP * 1.3
		Fx.tracer(actors, from, to)
		Fx.muzzle_flash(actors, from)
		AudioManager.play("shot", -8.0, 1.2, 0.05)
		target.take_hit(rules.tower_damage, false, 0.3)


# ------------------------------------------------------------------- fim

func _finish(won: bool) -> void:
	if run_ended:
		return
	run_ended = true
	player.set_physics_process(false)
	for z in get_tree().get_nodes_in_group("zombie"):
		z.set_process(false)
	var gm := GameManager
	gm.commit_defense({
		"won": won, "kills": zombies_killed, "kill_xp": kill_xp,
		"ammo_left": player_combat.ammo, "knife_durability": player_combat.knife_durability,
		"gate_hp": int(gate_hp), "gate_max": int(gate_max), "hp": player_health.current_hp,
	})
	AudioManager.play("extraction" if won else "zombie_death", 0.0, 1.0 if won else 0.6)
	_show_result.call_deferred(won)


func _show_result(won: bool) -> void:
	var d: Dictionary = GameManager.last_defense
	var text := "Zumbis eliminados: %d   ·   Portão: %d / %d\n+%d XP" % [d.kills, d.gate_hp, d.gate_max, d.xp]
	if d.levels > 0:
		text += "  —  SUBIU PARA O NÍVEL %d!" % GameManager.level
	if not d.lost.is_empty():
		var parts: Array[String] = []
		for key in d.lost:
			parts.append("-%d %s" % [d.lost[key], GameManager.RESOURCE_NAMES[key].to_lower()])
		text += "\nA horda invadiu o depósito: " + ", ".join(parts)
	if not d.morale.is_empty():
		text += "\nMoral: " + ", ".join(d.morale)
	text += "\nPróximo ataque: dia %d." % GameManager.next_attack_day
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_result_panel.add_child(box)
	var title := Label.new()
	title.text = "ABRIGO DEFENDIDO!" if won else "O ABRIGO CAIU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(0.55, 1.0, 0.55) if won else Color(1.0, 0.35, 0.3)
	box.add_child(title)
	var body := Label.new()
	body.text = text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 18)
	box.add_child(body)
	var button := Button.new()
	button.text = "Voltar ao abrigo"
	button.custom_minimum_size = Vector2(260, 52)
	button.pressed.connect(func(): Transition.change_scene("res://scenes/shelter.tscn"))
	box.add_child(button)
	hud.add_child(_result_panel)
	_result_panel.position = (hud.size - _result_panel.get_combined_minimum_size()) / 2.0
	button.grab_focus()


# -------------------------------------------------------------- cenário

func _build_arena(shooters: int, real_towers: bool) -> void:
	var arena := Node3D.new()
	arena.name = "Arena"
	add_child(arena)
	# A rua que chega ao abrigo: chunks do Bairro, sem padrões.
	for i in STREET_CHUNKS.size():
		var chunk: Node3D = load(STREET_CHUNKS[i]).instantiate()
		MeshMerger.merge_static(chunk, STREET_CHUNKS[i])
		arena.add_child(chunk)
		chunk.position = Vector3(0, 0, -(i * 40.0) - 2.0)
	# Pátio atrás do portão.
	_box(arena, Vector3(18, 0.1, 12), Vector3(0, -0.04, 4.0), Color(0.3, 0.28, 0.26))
	# Muro do abrigo com o portão (três faixas) no meio.
	for side in [-1, 1]:
		_box(arena, Vector3(5.5, 3.0, 0.5), Vector3(side * 6.6, 1.5, GATE_Z + 0.25), Color(0.45, 0.4, 0.36))
	for lane in 3:
		var g := _box(arena, Vector3(LANE_WIDTH - 0.1, 1.3, 0.4), Vector3((lane - 1) * LANE_WIDTH, 0.65, GATE_Z + 0.2), Color(0.45, 0.4, 0.36))
		_gate_nodes.append(g)
	_label(arena, "PORTÃO", Vector3(0, 2.6, GATE_Z), 64, Color(1, 0.85, 0.5))
	# Barricadas e armadilhas por faixa.
	for lane in 3:
		var x := (lane - 1) * LANE_WIDTH
		var barricade := Node3D.new()
		arena.add_child(barricade)
		barricade.position = Vector3(x, 0, BARRICADE_Z)
		_box(barricade, Vector3(2.2, 1.2, 0.6), Vector3(0, 0.6, 0), Color(0.5, 0.35, 0.2))
		_box(barricade, Vector3(2.3, 0.2, 0.65), Vector3(0, 1.0, 0), Color(0.75, 0.6, 0.2))
		barricade.visible = barricade_max > 0.0
		_barricade_nodes.append(barricade)
		var trap := Node3D.new()
		arena.add_child(trap)
		trap.position = Vector3(x, 0, TRAP_Z)
		_box(trap, Vector3(1.4, 0.08, 1.0), Vector3(0, 0.04, 0), Color(0.35, 0.1, 0.08))
		for s in 4:
			_box(trap, Vector3(0.12, 0.3, 0.12), Vector3(-0.45 + s * 0.3, 0.2, 0), Color(0.7, 0.7, 0.72))
		trap.visible = trap_damage > 0
		_trap_nodes.append(trap)
	# Torres (ou Soldados no muro).
	for i in shooters:
		var side := -1 if i == 0 else 1
		var tower := Node3D.new()
		arena.add_child(tower)
		# Na frente do muro, fora das faixas, para aparecerem na câmera.
		tower.position = Vector3(side * 4.6, 0, GATE_Z - 1.2)
		if real_towers:
			_box(tower, Vector3(1.3, 4.0, 1.3), Vector3(0, 2.0, 0), Color(0.35, 0.33, 0.3))
			_box(tower, Vector3(1.7, 0.5, 1.7), Vector3(0, 4.2, 0), Color(0.5, 0.2, 0.15))
		else:
			_box(tower, Vector3(0.6, 1.6, 0.6), Vector3(0, 3.8, 0), Color(0.4, 0.45, 0.25))
		_towers.append(tower)
		_tower_timer.append(0.5 + i * 0.3)


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	parent.add_child(mi)
	mi.position = pos
	return mi


func _label(parent: Node3D, text: String, pos: Vector3, font_size: int, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.012
	l.outline_size = 12
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	l.position = pos


# ------------------------------------------------------------------- HUD

func _build_hud() -> void:
	var hp_label: Label = hud.get_node("HPLabel")
	player_health.health_changed.connect(func(current, max_hp): hp_label.text = "HP: %d/%d" % [current, max_hp])
	hp_label.text = "HP: %d/%d" % [player_health.current_hp, player_health.max_hp]
	var ammo_label: Label = hud.get_node("AmmoLabel")
	player_combat.ammo_changed.connect(func(a): ammo_label.text = "%s · Munição: %d" % [player_combat.pistol.display_name, a]; ammo_label.modulate = Color(1, 0.4, 0.3) if a == 0 else Color.WHITE)
	ammo_label.text = "%s · Munição: %d" % [player_combat.pistol.display_name, player_combat.ammo]
	var knife_label: Label = hud.get_node("KnifeLabel")
	player_combat.knife_durability_changed.connect(func(c, m): knife_label.text = "%s: %d / %d" % [player_combat.weapon.display_name, c, m])
	knife_label.text = "%s: %d / %d" % [player_combat.weapon.display_name, player_combat.knife_durability, player_combat.weapon.max_durability]
	hud.get_node("AttackButton").button_down.connect(player_combat.attack)
	hud.get_node("PauseButton").pressed.connect(func(): $PauseLayer/PauseMenu.open())

	# Portão e horda no alto, ao centro (HP, munição e arma ficam à esquerda).
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.position = Vector2(-200, 12)
	top.custom_minimum_size = Vector2(400, 0)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	hud.add_child(top)
	_gate_label = Label.new()
	_gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_label.add_theme_font_size_override("font_size", 22)
	top.add_child(_gate_label)
	_gate_bar = ProgressBar.new()
	_gate_bar.custom_minimum_size = Vector2(400, 18)
	_gate_bar.show_percentage = false
	_gate_bar.max_value = gate_max
	top.add_child(_gate_bar)
	_horde_label = Label.new()
	_horde_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_horde_label.add_theme_font_size_override("font_size", 16)
	top.add_child(_horde_label)


func _update_hud() -> void:
	_gate_label.text = "PORTÃO: %d / %d" % [int(gate_hp), int(gate_max)]
	_gate_bar.value = gate_hp
	var standing := 0
	for hp in barricade_hp:
		if hp > 0.0:
			standing += 1
	_horde_label.text = "Horda: %d a caminho, %d na pista   ·   Barricadas: %d/3" % [_to_spawn - _spawned, _alive_count(), standing if barricade_max > 0.0 else 0]


func _banner(text: String, color: Color) -> void:
	var banner: Label = hud.get_node("EventBanner")
	AudioManager.play("alarm", -4.0, 1.0, 0.0)
	banner.text = text
	banner.modulate = color
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)


func _hint(text: String) -> void:
	var hint: Label = hud.get_node("TutorialHint")
	hint.text = text
	hint.show()
	hint.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(7.0)
	tween.tween_property(hint, "modulate:a", 0.0, 0.6)
	tween.tween_callback(hint.hide)
