extends Node3D

## Abrigo (seções 36-40 e 53 do GDD): lugar 3D com sala principal, depósito,
## oficina, gerador, coletor de chuva e horta. As construções aparecem
## conforme são feitas (painel Construir); a Oficina repara, fabrica e
## melhora. Ao voltar de uma expedição, a sobrevivente entra pela porta,
## deixa o loot no depósito (as caixas novas caem na pilha), descansa, e
## aparece o fechamento do dia.

## Cada caixa no depósito representa esta quantidade de recurso.
const UNITS_PER_CRATE := 5
const MAX_CRATES_PER_TYPE := 16
const CRATE_SIZE := 0.8
const WALK_SPEED := 3.5

# Ordem dos tipos: 0 = Comida, 1 = Água, 2 = Sucata (mesma do loot_pickup).
const CRATE_COLORS: Array[Color] = [Color(0.85, 0.5, 0.2), Color(0.25, 0.55, 0.9), Color(0.55, 0.55, 0.55)]
const CRATE_COLUMN_X: Array[float] = [-1.6, 0.0, 1.6]

## Cores dos estados de recurso da seção 37 (Normal, Atenção, Crítico, Esgotado).
const SUPPLY_COLORS: Array[Color] = [Color.WHITE, Color(1.0, 0.85, 0.3), Color(1.0, 0.55, 0.3), Color(1.0, 0.3, 0.25)]

const DOOR_POS := Vector3(0, 0, 8)
const DEPOSIT_DROP_POS := Vector3(-4, 0, 0.2)
const REST_POS := Vector3(0, 0, -0.8)

@onready var camera: Camera3D = $Camera3D
@onready var survivor: Node3D = $Survivor
@onready var crates_root: Node3D = $Deposito/Crates
@onready var deposit_label: Label3D = $Deposito/Label3D
@onready var workshop_label: Label3D = $Oficina/Label3D
@onready var generator_label: Label3D = $Gerador/Label3D
@onready var generator_light: OmniLight3D = $Gerador/Light
@onready var day_label: Label = $UI/TopBar/HBox/DayLabel
@onready var food_label: Label = $UI/TopBar/HBox/FoodLabel
@onready var water_label: Label = $UI/TopBar/HBox/WaterLabel
@onready var scrap_label: Label = $UI/TopBar/HBox/ScrapLabel
@onready var energy_label: Label = $UI/TopBar/HBox/EnergyLabel
@onready var ammo_label: Label = $UI/TopBar/HBox/AmmoLabel
@onready var morale_label: Label = $UI/TopBar2/HBox/MoraleLabel
@onready var components_label: Label = $UI/TopBar2/HBox/ComponentsLabel
@onready var medicine_label: Label = $UI/TopBar2/HBox/MedicineLabel
@onready var fuel_label: Label = $UI/TopBar2/HBox/FuelLabel
@onready var status_label: Label = $UI/TopBar2/HBox/StatusLabel
@onready var seed_edit: LineEdit = $UI/BottomBar/SeedEdit
@onready var build_button: Button = $UI/BottomBar/BuildButton
@onready var workshop_button: Button = $UI/BottomBar/WorkshopButton
@onready var survivor_button: Button = $UI/BottomBar/SurvivorButton
@onready var expedition_button: Button = $UI/BottomBar/ExpeditionButton
@onready var menu_button: Button = $UI/BottomBar/MenuButton
@onready var build_panel: ShelterPanel = $UI/BuildPanel
@onready var workshop_panel: ShelterPanel = $UI/WorkshopPanel
@onready var survivor_panel: ShelterPanel = $UI/SurvivorPanel
@onready var prep_panel: ShelterPanel = $UI/PrepPanel
@onready var sala_label: Label3D = $SalaPrincipal/Label3D
@onready var arrival_panel: Control = $UI/ArrivalPanel
@onready var arrival_title: Label = $UI/ArrivalPanel/Margin/VBox/ArrivalTitle
@onready var arrival_label: Label = $UI/ArrivalPanel/Margin/VBox/ArrivalLabel
@onready var ok_button: Button = $UI/ArrivalPanel/Margin/VBox/OkButton
@onready var hint_label: Label = $UI/HintLabel

var _hint_tween: Tween

## Caixas instanciadas por tipo, na ordem de empilhamento.
var _crates: Array[Array] = [[], [], []]
var _crate_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	camera.look_at(Vector3(0, 0, 0.5))

	expedition_button.pressed.connect(_on_expedition_button)
	prep_panel.depart_requested.connect(_on_expedition_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	build_button.pressed.connect(_open_panel.bind(build_panel))
	workshop_button.pressed.connect(_open_panel.bind(workshop_panel))
	survivor_button.pressed.connect(_open_panel.bind(survivor_panel))
	for panel in [build_panel, workshop_panel, survivor_panel]:
		panel.changed.connect(_refresh)
	ok_button.pressed.connect(func(): arrival_panel.hide(); _show_next_hint())

	for color in CRATE_COLORS:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		_crate_materials.append(mat)

	_update_buildings()
	_update_survivor_button()
	_update_residents()
	_update_expedition_button()
	AudioManager.play_music("music_shelter")

	if GameManager.arrival_pending:
		GameManager.arrival_pending = false
		_play_arrival()
	else:
		survivor.position = REST_POS
		_refresh()
		_show_next_hint()


## Atualiza tudo o que depende dos recursos e níveis (após qualquer ação).
func _refresh() -> void:
	var gm := GameManager
	_show_resources([gm.food, gm.water, gm.scrap])
	_sync_crates([gm.food, gm.water, gm.scrap], false)
	_update_buildings()
	_update_survivor_button()
	_update_residents()


## Moradores resgatados (seção 44) na sala principal, com nome e cor da
## profissão.
func _update_residents() -> void:
	var gm := GameManager
	var old := get_node_or_null("Residents")
	if old:
		remove_child(old)
		old.queue_free()
	var residents := Node3D.new()
	residents.name = "Residents"
	add_child(residents)
	var spots := [Vector3(-2.0, 0, -1.4), Vector3(1.4, 0, -0.2), Vector3(-1.0, 0, 0.3), Vector3(2.4, 0, 0.6), Vector3(-2.6, 0, 0.4)]
	for i in mini(gm.survivors.size(), spots.size()):
		var info: Dictionary = gm.survivors[i]
		var profession := gm.WORLD.profession(info.profession)
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.35
		capsule.height = 1.6
		mesh.mesh = capsule
		var mat := StandardMaterial3D.new()
		mat.albedo_color = profession.color
		mesh.material_override = mat
		mesh.position = spots[i] + Vector3(0, 0.8, 0)
		residents.add_child(mesh)
		var label := Label3D.new()
		# Seção 44: traço e afinidade sobre a cabeça.
		var t := Residents.trait_of(info)
		label.text = "%s\n%s · %d" % [info.name, t.display_name if t else "", int(info.affinity)]
		if not info.get("request", {}).is_empty():
			label.text += "  (pedido)"
		label.modulate = t.color.lerp(Color.WHITE, 0.4) if t else Color.WHITE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.01
		label.font_size = 32
		label.outline_size = 8
		label.position = spots[i] + Vector3(0, 1.9, 0)
		residents.add_child(label)
	sala_label.text = "Sala Principal\nMoradores %d/%d" % [gm.survivors.size(), gm.survivor_capacity()]


## Seção 45: com a horda no portão, o botão de expedição vira a defesa.
func _on_expedition_button() -> void:
	if GameManager.attack_due():
		Transition.change_scene("res://scenes/defense.tscn")
	else:
		_open_panel(prep_panel)


func _update_expedition_button() -> void:
	var due := GameManager.attack_due()
	expedition_button.text = "DEFENDER O ABRIGO!" if due else "Expedição"
	expedition_button.modulate = Color(1.0, 0.45, 0.35) if due else Color.WHITE


func _update_survivor_button() -> void:
	var gm := GameManager
	var points := gm.attribute_points + gm.perk_points
	survivor_button.text = "Sobrevivente nv %d" % gm.level + ("  (+%d)" % points if points > 0 else "")
	survivor_button.modulate = Color(1.0, 0.85, 0.35) if points > 0 else Color.WHITE


func _open_panel(panel: ShelterPanel) -> void:
	for other in [build_panel, workshop_panel, survivor_panel, prep_panel, arrival_panel]:
		other.hide()
	panel.open()


func _set_actions_enabled(enabled: bool) -> void:
	for button in [build_button, workshop_button, survivor_button, expedition_button]:
		button.disabled = not enabled


func _play_arrival() -> void:
	var gm := GameManager
	var after := [gm.food, gm.water, gm.scrap]
	var before := [
		maxi(0, gm.food - gm.last_run_recovered.get("food", 0)),
		maxi(0, gm.water - gm.last_run_recovered.get("water", 0)),
		maxi(0, gm.scrap - gm.last_run_recovered.get("scrap", 0)),
	]

	# O depósito começa como estava antes da expedição.
	_show_resources(before)
	_sync_crates(before, false)
	_set_actions_enabled(false)

	survivor.position = DOOR_POS
	await _walk_to(DEPOSIT_DROP_POS)

	var drop_time := _sync_crates(after, true)
	if drop_time > 0.5:
		AudioManager.play("build", -6.0)
	await get_tree().create_timer(drop_time).timeout
	_show_resources(after)

	await _walk_to(REST_POS)
	_set_actions_enabled(true)
	_show_arrival_panel()
	if GameManager.last_run_levels_gained > 0:
		AudioManager.play("level_up")
		_celebrate_level_up()


func _walk_to(target: Vector3) -> void:
	var duration := survivor.position.distance_to(target) / WALK_SPEED
	var tween := create_tween()
	tween.tween_property(survivor, "position", target, duration)
	await tween.finished


## Deixa em cada pilha as caixas que representam `amounts`: cria as que
## faltam (caindo do alto, com `animate`) e remove as que sobram. Retorna a
## duração da animação.
func _sync_crates(amounts: Array, animate: bool) -> float:
	var delay := 0.0
	for type in 3:
		var stack: Array = _crates[type]
		var target := mini(ceili(float(amounts[type]) / UNITS_PER_CRATE), MAX_CRATES_PER_TYPE)

		while stack.size() > target:
			stack.pop_back().queue_free()

		while stack.size() < target:
			var slot := _crate_slot(type, stack.size())
			var crate := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3.ONE * (CRATE_SIZE - 0.05)
			crate.mesh = box
			crate.material_override = _crate_materials[type]
			crates_root.add_child(crate)
			stack.append(crate)

			if not animate:
				crate.position = slot
				continue

			crate.position = slot + Vector3(0, 6, 0)
			crate.visible = false
			var tween := create_tween()
			tween.tween_interval(delay)
			tween.tween_callback(crate.show)
			tween.tween_property(crate, "position", slot, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			delay += 0.1

	return delay + 0.4 if animate else 0.0


## Pilhas 2x2 por camada, uma coluna por tipo de recurso.
@warning_ignore("integer_division")
func _crate_slot(type: int, index: int) -> Vector3:
	var col := index % 2
	var row := (index / 2) % 2
	var layer := index / 4
	return Vector3(
		CRATE_COLUMN_X[type] + (col - 0.5) * CRATE_SIZE,
		CRATE_SIZE / 2.0 + layer * CRATE_SIZE,
		(row - 0.5) * CRATE_SIZE
	)


## Barra superior com capacidade e cor do estado (seção 37).
func _show_resources(amounts: Array) -> void:
	var gm := GameManager
	var cap := gm.storage_capacity()
	day_label.text = "Dia %d" % gm.day
	_set_supply(food_label, "Comida", "food", amounts[0], cap)
	_set_supply(water_label, "Água", "water", amounts[1], cap)
	_set_supply(scrap_label, "Sucata", "scrap", amounts[2], cap)
	energy_label.text = "Energia: %d/%d" % [gm.energy, gm.energy_capacity()]
	ammo_label.text = "Munição: %d" % gm.ammo
	deposit_label.text = "Depósito  nv %d\nComida %d · Água %d · Sucata %d\n(máx. %d cada)" % [
		gm.level_of(&"storage"), amounts[0], amounts[1], amounts[2], cap
	]

	# Segunda barra: moral (seção 37) e os recursos da seção 62.
	var morale_state := gm.morale_state()
	morale_label.text = "Moral: %d  %s" % [gm.morale, ["", "(atenção)", "(crítica)", "(esgotada)"][morale_state]]
	morale_label.modulate = SUPPLY_COLORS[morale_state]
	components_label.text = "Componentes: %d" % gm.components
	medicine_label.text = "Medicamentos: %d" % gm.medicine
	fuel_label.text = "Combustível: %d" % gm.fuel
	var status: Array[String] = []
	if gm.is_injured():
		status.append("FERIDA (%d exp.)" % gm.injured_days)
	if gm.start_hp_penalty() > 0:
		status.append("FRACA: -%d HP" % gm.start_hp_penalty())
	# Seção 45: contagem até o ataque.
	if gm.attack_due():
		status.append("HORDA NO PORTÃO!")
	elif gm.days_to_attack() <= gm.SHELTER.attack_warning_days:
		status.append("ATAQUE EM %d DIA(S)" % gm.days_to_attack())
	status_label.text = "  ·  ".join(status)
	status_label.modulate = SUPPLY_COLORS[gm.Supply.EXHAUSTED]


func _set_supply(label: Label, title: String, key: String, amount: int, cap: int) -> void:
	label.text = "%s: %d/%d" % [title, amount, cap]
	# Comida e água têm estados de necessidade; sucata só avisa se lotar.
	var state: int = GameManager.supply_state(key) if key != "scrap" else GameManager.Supply.NORMAL
	label.modulate = SUPPLY_COLORS[state]
	if amount >= cap:
		label.modulate = SUPPLY_COLORS[GameManager.Supply.WARNING]


## Mostra no 3D o que está construído e em que nível.
func _update_buildings() -> void:
	var gm := GameManager
	var rules := gm.SHELTER

	workshop_label.text = "Oficina  nv %d" % gm.level_of(&"workshop")

	var generator_level := gm.level_of(&"generator")
	generator_light.visible = generator_level > 0
	generator_label.text = (
		"Gerador  nv %d\n%s" % [generator_level, rules.building(&"generator").effect_text(generator_level)]
		if generator_level > 0 else "Gerador\n(desligado)"
	)

	_update_plot($Coletor, &"rain_collector")
	_update_plot($Horta, &"garden")
	$Coletor/Built/Barrel2.visible = gm.level_of(&"rain_collector") >= 2

	# Fase 12: fortaleza (seção 36) — torres, barricadas, armadilhas e o
	# portão reforçado aparecem na frente do abrigo.
	for pair in [[$Torres, &"towers"], [$Barricadas, &"barricades"], [$Armadilhas, &"traps"]]:
		_update_fixture(pair[0], pair[1])
	var gate_level := gm.level_of(&"gate")
	$PortaoReforcado/Built.visible = gate_level >= 2
	$PortaoReforcado/Built/Level2.visible = gate_level >= 3
	$PortaoReforcado/Label3D.visible = gate_level >= 2
	$PortaoReforcado/Label3D.text = "Portão  nv %d" % gate_level

	# Fase 8: construções das seções 38-41.
	_update_plot($Enfermaria, &"infirmary")
	for pair in [[$Cozinha, &"kitchen"], [$Radio, &"radio"], [$Baterias, &"battery"], [$Paineis, &"solar"]]:
		_update_fixture(pair[0], pair[1])


## Construção sem terreno próprio (dentro da sala ou ao lado de outra): só
## aparece depois de construída. `Built/Level2` aparece no nível 2.
func _update_fixture(fixture: Node3D, id: StringName) -> void:
	var building := GameManager.SHELTER.building(id)
	var level := GameManager.level_of(id)
	fixture.get_node("Built").visible = level > 0
	fixture.get_node("Built/Level2").visible = level >= 2
	var label: Label3D = fixture.get_node("Label3D")
	label.visible = level > 0
	label.text = "%s  nv %d" % [building.display_name, level]


func _update_plot(plot: Node3D, id: StringName) -> void:
	var building := GameManager.SHELTER.building(id)
	var level := GameManager.level_of(id)
	plot.get_node("Built").visible = level > 0
	var level2 := plot.get_node_or_null("Built/Level2")
	if level2:
		level2.visible = level >= 2
	plot.get_node("Placeholder").visible = level == 0
	plot.get_node("Label3D").text = (
		"%s  nv %d\n%s" % [building.display_name, level, building.effect_text(level)]
		if level > 0 else "Terreno livre\n(%s)" % building.display_name
	)


func _show_arrival_panel() -> void:
	var gm := GameManager
	arrival_title.text = ("De volta ao abrigo" if gm.last_run_survived else "Resgatada") + "  —  fim do dia %d" % (gm.day - 1)

	var text := "Seed: %d   Distância: %.0f m   Zumbis eliminados: %d\n" % [
		gm.last_run_seed, gm.last_run_distance, gm.last_run_kills
	]
	if not gm.last_run_survived:
		text += "A expedição falhou — parte do loot se perdeu.\n"
	var stored := "Guardado no depósito: +%d Comida  +%d Água  +%d Sucata" % [
		gm.last_run_recovered.get("food", 0), gm.last_run_recovered.get("water", 0), gm.last_run_recovered.get("scrap", 0)
	]
	for key in ["components", "medicine", "fuel"]:
		if gm.last_run_recovered.get(key, 0) > 0:
			stored += "  +%d %s" % [gm.last_run_recovered[key], gm.RESOURCE_NAMES[key]]
	text += stored + "\n"
	text += "Munição: %d gastas, +%d coletadas\n" % [gm.last_run_ammo_used, gm.last_run_ammo]
	if gm.last_run_medkit_used:
		text += "Kit médico usado: -1 medicamento\n"
	# Seção 55 do GDD: a personagem se recupera no abrigo entre expedições.
	text += "HP ao chegar: %d/%d → descansou\n" % [gm.last_run_hp, gm.last_run_max_hp]
	match gm.last_run_bag:
		"left":
			text += "Sua mochila ficou a %.0f m (%s). Volte em até %d expedições: Expedição → Voltar ao local da morte.\n" % [
				gm.death_bag.at, gm.bag_loot_text(), gm.death_bag.runs_left
			]
		"recovered":
			text += "Mochila do local da morte recuperada!\n"
		"expired":
			text += "A mochila deixada no local da morte se perdeu.\n"
	if gm.last_run_wounded:
		# Seção 41: morrer deixa a personagem Ferida.
		text += "FERIDA: HP máximo -%d%% nas próximas %d expedições. Trate na Enfermaria (Sobrevivente).\n" % [
			roundi((1.0 - gm.SHELTER.wound_max_hp) * 100), gm.injured_days
		]
	text += "+%d XP" % gm.last_run_xp
	if gm.last_run_early:
		# Seção 24: a saída antecipada não dá o bônus da extração completa.
		text += " (extração antecipada: sem o bônus de +%d)" % Progression.DATA.extraction_bonus_xp
	if gm.last_run_levels_gained > 0:
		# Seção 42: subir de nível dá pontos de atributo e de perk.
		text += "  —  SUBIU PARA O NÍVEL %d! Gaste os pontos em Sobrevivente." % gm.level
	text += "\n"
	for survivor_name in gm.last_run_new_survivors:
		var resident := _resident_named(survivor_name)
		if resident.is_empty():
			text += "Novo morador: %s!\n" % survivor_name
		else:
			var t := Residents.trait_of(resident)
			text += "Novo morador: %s (%s, %s)!\n" % [survivor_name, gm.WORLD.profession(resident.profession).display_name, t.display_name if t else "?"]
	for survivor_name in gm.last_run_turned_away:
		text += "Sem vaga para %s — construa um Dormitório.\n" % survivor_name
	for survivor_name in gm.last_run_lost_survivors:
		text += "%s não sobreviveu à expedição.\n" % survivor_name
	text += "\n"

	for line in gm.last_day_report:
		text += line + "\n"

	var knife := gm.knife()
	if gm.knife_durability <= 0:
		text += "\nA faca QUEBROU — repare na Oficina."
	elif gm.knife_durability <= knife.max_durability * 0.25:
		text += "\nFaca desgastada (%d/%d) — repare na Oficina." % [gm.knife_durability, knife.max_durability]

	arrival_label.text = text.strip_edges()
	arrival_panel.show()


## Subida de nível: estouro dourado e "NÍVEL N!" sobre a sobrevivente.
func _celebrate_level_up() -> void:
	var pos := survivor.global_position + Vector3.UP * 1.2
	for i in 3:
		Fx.burst(self, pos, Color(1.0, 0.85, 0.3), 18, 5.0, 0.12)
		await get_tree().create_timer(0.15).timeout
	Fx.float_text(survivor, pos + Vector3.UP * 1.4, "NÍVEL %d!" % GameManager.level, Color(1.0, 0.85, 0.3), 72)


## Tutorial do abrigo (Fase 7): a primeira dica pendente que se aplica agora.
func _show_next_hint() -> void:
	var gm := GameManager
	var candidates := [
		[&"shelter_welcome", true,
			"Bem-vinda ao abrigo! Cada expedição é um dia: você come %d comida e bebe %d água. Toque em Expedição para sair." % [gm.SHELTER.daily_food, gm.SHELTER.daily_water]],
		[&"shelter_points", gm.attribute_points + gm.perk_points > 0,
			"Você subiu de nível! Gaste os pontos em Sobrevivente."],
		[&"shelter_build", gm.scrap >= 8 and gm.level_of(&"generator") + gm.level_of(&"rain_collector") + gm.level_of(&"garden") == 0,
			"Com sucata dá para construir: Gerador (energia), Coletor de chuva (água) e Horta (comida). Toque em Construir."],
		[&"shelter_knife", gm.knife_durability <= gm.knife().max_durability * 0.5,
			"Sua faca está gasta. Repare na Oficina antes que ela quebre."],
		[&"shelter_supply", gm.supply_state("food") >= GameManager.Supply.CRITICAL or gm.supply_state("water") >= GameManager.Supply.CRITICAL,
			"Comida ou água acabando! Sem elas, a próxima expedição começa ferida. Construa Horta/Coletor ou colete mais."],
		[&"shelter_region", gm.is_region_unlocked(gm.WORLD.region(&"centro")),
			"Nova região liberada: o Centro! Escolha em Expedição."],
		[&"shelter_wounded", gm.is_injured(),
			"Você voltou FERIDA: HP máximo menor por %d expedições. A Enfermaria trata com medicamentos (painel Sobrevivente)." % gm.injured_days],
		[&"shelter_morale", gm.morale_state() >= GameManager.Supply.WARNING,
			"A moral do abrigo está caindo: a produção diminui. Cozinha e Rádio levantam a moral; fome, sede e mortes derrubam."],
		[&"shelter_attack", gm.days_to_attack() <= gm.SHELTER.attack_warning_days,
			"Uma HORDA vai atacar o abrigo! Em Construir → DEFESA: Portão, Barricadas, Armadilhas e Torres. Tenha munição: as torres gastam a mesma."],
		[&"shelter_traits", not gm.survivors.is_empty(),
			"Cada morador tem um traço e uma afinidade com o grupo (painel Sobrevivente). Comida e água em dia sobem a afinidade; com afinidade alta, o bônus da profissão cresce e surgem pedidos."],
		[&"shelter_request", gm.survivors.any(func(r): return not r.get("request", {}).is_empty()),
			"Um morador fez um pedido! Veja em Sobrevivente: entregue recursos ou volte vivo da região pedida. Rende XP, moral e afinidade."],
		[&"shelter_bag", not gm.death_bag.is_empty(),
			"Sua mochila ficou no local da morte. Em Expedição → Voltar ao local da morte, a mesma rota leva até ela (com mais zumbis)."],
		[&"shelter_components", gm.day >= 3 and gm.components == 0,
			"Componentes constroem Painéis, Baterias, Enfermaria e Rádio. Desmonte sucata na Oficina ou procure no Centro e na Zona Industrial."],
	]
	for hint in candidates:
		if hint[1] and Settings.should_show_hint(hint[0]):
			_show_hint(hint[2])
			return


func _show_hint(text: String) -> void:
	if _hint_tween:
		_hint_tween.kill()
	hint_label.text = text
	hint_label.modulate.a = 0.0
	hint_label.show()
	_hint_tween = create_tween()
	_hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.3)
	_hint_tween.tween_interval(6.0)
	_hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.6)
	_hint_tween.tween_callback(hint_label.hide)


func _on_expedition_pressed() -> void:
	# Seed digitada reproduz uma expedição específica (seção 23 do GDD).
	var typed := seed_edit.text.strip_edges()
	GameManager.next_seed = typed.to_int() if typed.is_valid_int() and typed.to_int() >= 0 else -1
	# Seção 47: a volta ao local da morte refaz a rota daquela expedição.
	if GameManager.recovering_bag and not GameManager.death_bag.is_empty():
		GameManager.next_seed = int(GameManager.death_bag.seed)
	Transition.change_scene("res://scenes/run.tscn")


func _on_menu_pressed() -> void:
	Transition.change_scene("res://scenes/main_menu.tscn")


func _resident_named(survivor_name: String) -> Dictionary:
	for info in GameManager.survivors:
		if info.name == survivor_name:
			return info
	return {}
