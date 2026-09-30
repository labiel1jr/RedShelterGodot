extends Node

## Robô de balanceamento: joga uma campanha inteira (expedições, abrigo e
## defesas) e grava o CampaignLog. Veja tests/README.md para rodar.
##
## Políticas (--policy=):
## - "cauteloso": um jogador razoável. Economia primeiro, guarda sucata e
##   munição para o ataque, escolhe regiões abaixo do nível e volta ao
##   Bairro quando está ferido.
## - "atual": o robô antigo, ganancioso (sempre a região mais difícil, gasta
##   a sucata em munição e atira em tudo). Serve de comparação.

const LANES := [-2.5, 0.0, 2.5]

var days := 30
var policy := "cauteloso"
var bot_seed := 1

var _last_scene := ""
var _lane_cooldown := 0.0
var _leaving := false
var _logged_day := 0
var _runs := {}
var _deaths := {}
var _defenses: Array[String] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--days="):
			days = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			bot_seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--policy="):
			policy = arg.get_slice("=", 1)
	if not UserPaths.is_sandbox():
		# Sem --sandbox o jogo novo do robô apagaria o save de verdade.
		push_error("Rode com -- --sandbox (veja tests/README.md).")
		get_tree().quit(1)
		return
	Engine.time_scale = 6.0
	Engine.physics_ticks_per_second = 180
	Engine.max_physics_steps_per_frame = 40
	Settings.tutorial_enabled = false
	Settings.camera_shake = false
	CampaignLog.file_name = "campaign_%s_%d.csv" % [policy, bot_seed]
	SaveManager.start_new_game()
	seed(bot_seed)
	print("Campanha: política %s, seed %d, %d dias" % [policy, bot_seed, days])
	get_tree().change_scene_to_file.call_deferred("res://scenes/shelter.tscn")


func _process(delta: float) -> void:
	var sc := get_tree().current_scene
	if sc == null:
		return
	if sc.name != _last_scene:
		_last_scene = sc.name
		_leaving = false
		if sc.name == "Shelter":
			if GameManager.day > 1 and GameManager.day != _logged_day:
				_logged_day = GameManager.day
				_print_day()
			if GameManager.day > days:
				_summary()
				get_tree().quit()
				return
			_shelter_turn()
			GameManager.arrival_pending = false
			var next := "res://scenes/defense.tscn" if GameManager.attack_due() else "res://scenes/run.tscn"
			get_tree().change_scene_to_file.call_deferred(next)
		elif sc.name == "Result":
			get_tree().change_scene_to_file.call_deferred("res://scenes/shelter.tscn")
	if sc.name == "Run" and not sc.run_ended:
		_drive(sc, delta)
	elif sc.name == "Defense":
		if not sc.run_ended:
			_drive_defense(sc)
		elif not _leaving:
			_leaving = true
			var d: Dictionary = GameManager.last_defense
			_defenses.append("dia %d %s" % [GameManager.day, "V" if d.won else "D"])
			print("  DEFESA dia %d: %s  portão %d/%d  abates %d  munição sobrando %d  perdas %s" % [
				GameManager.day, "VENCEU" if d.won else "PERDEU", d.gate_hp, d.gate_max, d.kills, GameManager.ammo, d.lost])
			get_tree().change_scene_to_file.call_deferred("res://scenes/shelter.tscn")


# ------------------------------------------------------------- expedição

func _lane_of(x: float) -> int:
	return clampi(int(round(x / 2.5)) + 1, 0, 2)


## Munição que o cauteloso não gasta na rua (a do ataque volta com ele).
func _ammo_reserve() -> int:
	if policy != "cauteloso":
		return 0
	return 30 if GameManager.days_to_attack() <= 2 else 0


func _drive(sc: Node, delta: float) -> void:
	var p: CharacterBody3D = sc.player
	var combat = sc.player_combat
	_lane_cooldown -= delta / Engine.time_scale

	if combat.is_grabbed():
		combat.attack()

	var pz := p.global_position.z
	var hazard := [0.0, 0.0, 0.0]
	var low_ahead := [999.0, 999.0, 999.0]
	var high_ahead := [999.0, 999.0, 999.0]
	for o in get_tree().get_nodes_in_group("obstacle"):
		var ahead: float = pz - o.global_position.z
		if ahead < -0.6 or ahead > 16.0:
			continue
		var lane := _lane_of(o.global_position.x)
		match o.kind:
			&"wall":
				if ahead < 13.0:
					hazard[lane] += 100.0
			&"low":
				hazard[lane] += 1.5
				low_ahead[lane] = minf(low_ahead[lane], ahead)
			&"high":
				hazard[lane] += 1.5
				high_ahead[lane] = minf(high_ahead[lane], ahead)
	for z in get_tree().get_nodes_in_group("zombie"):
		if not z.is_alive():
			continue
		var ahead: float = pz - z.global_position.z
		if ahead < 0.5 or ahead > 18.0:
			continue
		hazard[_lane_of(z.global_position.x)] += 25.0 if z.data.attack != ZombieData.Attack.SMASH else 40.0
	if sc.carried_weight() < sc.backpack_capacity() - 2.0:
		for chunk in sc.chunk_streamer.get_children():
			for o in chunk.get_children():
				if o is Area3D and "loot_type" in o:
					var ahead: float = pz - o.global_position.z
					if ahead > 0.5 and ahead < 16.0:
						hazard[_lane_of(o.global_position.x)] -= 4.0 * (2.0 if o.rare else 1.0)

	# Bifurcação: com pouca vida, o cauteloso prefere a saída ou o ramo calmo.
	var fork_lane := _fork_lane(sc)
	if fork_lane >= 0:
		hazard[fork_lane] -= 30.0

	var current: int = p.current_lane
	var best := current
	for lane in 3:
		var cost: float = hazard[lane] + absf(lane - current) * 1.0
		if abs(lane - current) == 2 and hazard[1] >= 100.0:
			cost += 60.0  # teria que atravessar uma parede
		if p.blocked_lane == lane:
			cost += 200.0
		if cost < hazard[best] + absf(best - current) * 1.0 - 0.5:
			best = lane
	if best != current and _lane_cooldown <= 0.0:
		p._change_lane(1 if best > current else -1)
		_lane_cooldown = 0.12

	if low_ahead[current] < 3.4 and low_ahead[current] > 0.8:
		p._jump()
	if high_ahead[current] < 3.1 and high_ahead[current] > 0.8:
		p._slide()

	var target = combat._find_ranged_target()
	if target and combat.ammo > 0 and not combat.is_grabbed():
		var dist: float = pz - target.global_position.z
		var health = sc.player_health
		var desperate: bool = health.current_hp < health.max_hp * 0.3
		if policy == "cauteloso":
			if dist < 14.0 and (combat.ammo > _ammo_reserve() or desperate):
				combat.shoot()
		elif dist < 24.0:
			combat.shoot()


func _fork_lane(sc: Node) -> int:
	if policy != "cauteloso" or sc._pending_forks.is_empty():
		return -1
	var fork: RouteGenerator.Fork = sc._pending_forks[0]
	var left: float = fork.decision_distance - sc.distance_travelled()
	if left < 0.0 or left > 30.0:
		return -1
	var health = sc.player_health
	var hurt: bool = health.current_hp < health.max_hp * 0.5
	var best_side := 1
	for side in [1, 2]:
		var branch: BranchData = fork.sides[side]
		var other: BranchData = fork.sides[3 - side]
		if hurt:
			if branch.early_extraction or (not other.early_extraction and branch.danger < other.danger):
				best_side = side
		elif not branch.early_extraction and (other.early_extraction or branch.loot_multiplier > other.loot_multiplier):
			best_side = side
	return 0 if best_side == 1 else 2


## Defesa: vai para a faixa do zumbi mais perto do portão; arma branca se ele
## já chegou, tiro se ainda vem.
func _drive_defense(sc: Node) -> void:
	_lane_cooldown -= get_process_delta_time() / Engine.time_scale
	var best: Node3D = null
	for z in get_tree().get_nodes_in_group("zombie"):
		if z.is_alive() and (not best or z.global_position.z > best.global_position.z):
			best = z
	if not best:
		return
	var p: Node3D = sc.player
	if p.current_lane != best.lane:
		if _lane_cooldown <= 0.0:
			p._change_lane(1 if best.lane > p.current_lane else -1)
			_lane_cooldown = 0.15
	elif best.global_position.z > -4.0:
		sc.player_combat.attack()
	else:
		sc.player_combat.shoot()


# ----------------------------------------------------------------- abrigo

func _build(id: StringName) -> bool:
	return Construction.upgrade(GameManager.SHELTER.building(id))


func _spend_points() -> void:
	var gm := GameManager
	var data := Progression.DATA
	var attr_order := [&"vigor", &"survival", &"strength", &"vigor", &"precision", &"agility"]
	var guard := 0
	while gm.attribute_points > 0 and guard < 50:
		guard += 1
		for id in attr_order:
			if gm.attribute_points > 0:
				Progression.raise_attribute(data.attribute(id))
	var perk_order := [&"packer", &"sharp_blade", &"organizer", &"scavenger_nose", &"keen_eye", &"farmer",
		&"quick_hands", &"salvager", &"handy", &"thick_skin", &"light_steps", &"rationing"]
	guard = 0
	while gm.perk_points > 0 and guard < 50:
		guard += 1
		for id in perk_order:
			if gm.perk_points > 0:
				Progression.learn_perk(data.perk(id))


func _shelter_turn() -> void:
	_spend_points()
	if policy == "cauteloso":
		_turn_cautious()
	else:
		_turn_greedy()
	GameManager.next_seed = randi() % 1_000_000


## Munição que o cauteloso quer ter no dia do ataque.
func _defense_ammo_target() -> int:
	return 40 + GameManager.day


func _turn_cautious() -> void:
	var gm := GameManager
	Infirmary.treat_wound()
	Infirmary.treat_hunger()
	if gm.knife_durability < gm.knife().max_durability * 0.5:
		Workshop.repair()

	var attack_soon := gm.days_to_attack() <= 3
	if attack_soon:
		# Primeiro a munição do ataque, depois as defesas mais baratas.
		while gm.ammo < _defense_ammo_target() and Workshop.craft_ammo_block_reason() == "":
			Workshop.craft_ammo()
		for id in [&"barricades", &"traps", &"gate", &"towers", &"barricades", &"traps", &"towers"]:
			_build(id)
	else:
		# Reserva de sucata para a próxima defesa quando ela se aproxima.
		var reserve := 0 if gm.days_to_attack() > 5 else 20
		var economy := [&"generator", &"rain_collector", &"garden", &"kitchen", &"backpack", &"storage", &"workshop",
			&"rain_collector", &"garden", &"infirmary", &"generator", &"dormitory", &"radio", &"battery", &"solar"]
		for id in economy:
			var b := gm.SHELTER.building(id)
			var cost := Construction.next_cost(b)
			if cost.is_empty() or gm.scrap - int(cost.get("scrap", 0)) < reserve:
				continue
			if id == &"storage" and gm.food < gm.storage_capacity() * 0.8 and gm.water < gm.storage_capacity() * 0.8 and gm.scrap < gm.storage_capacity() * 0.8:
				continue
			if id == &"dormitory" and gm.last_run_turned_away.is_empty():
				continue
			if id == &"radio" and gm.morale >= 60:
				continue
			_build(id)
		if gm.scrap > reserve + 15:
			Workshop.upgrade_weapon(&"pistol")
		if gm.scrap > reserve + 15:
			Workshop.upgrade_weapon(&"knife")
		# Defesas permanentes quando sobra.
		for id in [&"barricades", &"traps", &"gate", &"towers"]:
			var cost := Construction.next_cost(gm.SHELTER.building(id))
			if not cost.is_empty() and gm.scrap - int(cost.get("scrap", 0)) >= reserve + 10:
				_build(id)
		while gm.ammo < 18 and gm.scrap > reserve + 10 and Workshop.craft_ammo_block_reason() == "":
			Workshop.craft_ammo()

	# Região: dois níveis abaixo do desbloqueio; ferida ou depois de morrer,
	# o Bairro, perto.
	var regions: Array = gm.WORLD.regions.filter(func(r): return gm.level >= r.unlock_level + 2)
	if regions.is_empty():
		regions = [gm.WORLD.regions[0]]
	var pick: RegionData = regions[-1]
	var hurt := gm.is_injured() or not gm.last_run_survived and gm.day > 1
	if hurt:
		pick = gm.WORLD.regions[0]
	gm.next_region = pick.id
	var distance_index := 1 if gm.is_distance_unlocked(1) else 0
	if hurt or attack_soon:
		distance_index = 0
	elif gm.is_distance_unlocked(2) and gm.level >= 8 and gm.day % 3 == 0:
		distance_index = 2
	gm.next_distance = gm.WORLD.distances[distance_index]
	# Volta à mochila só em região fácil e sem ferimento.
	if not gm.death_bag.is_empty() and not hurt and StringName(gm.death_bag.region) in [&"bairro", &"mercado"]:
		gm.select_bag_recovery()
		gm.next_seed = int(gm.death_bag.seed)


func _turn_greedy() -> void:
	var gm := GameManager
	if gm.days_to_attack() <= 4:
		for id in [&"barricades", &"traps", &"gate", &"towers", &"barricades"]:
			_build(id)
		while gm.ammo < 40 and Workshop.craft_ammo_block_reason() == "":
			Workshop.craft_ammo()
	if gm.knife_durability < gm.knife().max_durability * 0.6:
		Workshop.repair()
	while gm.ammo < 18 and Workshop.craft_ammo_block_reason() == "" and gm.scrap > 12:
		Workshop.craft_ammo()
	for id in [&"generator", &"rain_collector", &"garden"]:
		if gm.level_of(id) == 0:
			_build(id)
	if not gm.last_run_turned_away.is_empty():
		_build(&"dormitory")
	for key in ["food", "water", "scrap"]:
		if gm.get(key) >= gm.storage_capacity() * 0.85:
			_build(&"storage")
	Workshop.upgrade_weapon(&"knife")
	_build(&"backpack")
	Workshop.upgrade_weapon(&"pistol")
	for id in [&"generator", &"rain_collector", &"garden"]:
		_build(id)
	if gm.level >= 4:
		_build(&"workshop")
	Infirmary.treat_wound()
	Infirmary.treat_hunger()
	while gm.components < 6 and gm.scrap > 25 and Workshop.dismantle_block_reason() == "":
		Workshop.dismantle()
	for id in [&"kitchen", &"infirmary", &"radio", &"battery", &"solar"]:
		_build(id)
	var regions: Array = gm.WORLD.regions.filter(func(r): return gm.is_region_unlocked(r))
	var pick: RegionData = regions[-1]
	if not gm.last_run_survived and gm.day > 1:
		pick = regions[0]
	gm.next_region = pick.id
	var distance_index := 1 if gm.is_distance_unlocked(1) else 0
	if gm.is_distance_unlocked(2) and gm.day % 3 == 0:
		distance_index = 2
	gm.next_distance = gm.WORLD.distances[distance_index]
	if not gm.death_bag.is_empty() and randf() < 0.3:
		gm.select_bag_recovery()
		gm.next_seed = int(gm.death_bag.seed)


# ---------------------------------------------------------------- saída

func _print_day() -> void:
	var gm := GameManager
	var key := "%s %.0fm" % [gm.WORLD.region(gm.next_region).display_name, gm.next_distance]
	_runs[key] = _runs.get(key, 0) + 1
	if not gm.last_run_survived:
		_deaths[key] = _deaths.get(key, 0) + 1
	print("dia %2d %-22s %-7s hp %3d/%3d | c%3d a%3d s%3d e%2d m%3d comp%2d med%2d | moral %3d nv%2d moradores %d | ataque em %d" % [
		gm.day - 1, key, "OK" if gm.last_run_survived else "MORREU", gm.last_run_hp, gm.last_run_max_hp,
		gm.food, gm.water, gm.scrap, gm.energy, gm.ammo, gm.components, gm.medicine,
		gm.morale, gm.level, gm.survivors.size(), gm.days_to_attack()])


func _summary() -> void:
	var gm := GameManager
	var total := 0
	var deaths := 0
	print("=== RESUMO (%s, seed %d) ===" % [policy, bot_seed])
	for key in _runs:
		total += _runs[key]
		deaths += _deaths.get(key, 0)
		print("  %-22s expedições %2d  mortes %2d" % [key, _runs[key], _deaths.get(key, 0)])
	print("  sobrevivência total: %d%%" % int(100.0 * (total - deaths) / maxi(1, total)))
	print("  defesas: %s" % ", ".join(_defenses))
	print("  fim: nível %d, moral %d, moradores %d, sucata %d, munição %d" % [gm.level, gm.morale, gm.survivors.size(), gm.scrap, gm.ammo])
	print("  CSV: %s" % ProjectSettings.globalize_path(CampaignLog.path()))
