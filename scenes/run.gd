extends Node3D

## Orquestra a expedição (seções 3 e 48 do GDD): acompanha distância,
## recursos coletados, zumbis eliminados e ruído, e encerra a run por
## extração ou morte.

## Expedição "Curta" da seção 28 do GDD. A rota real fecha no chunk de
## extração logo após essa distância.
@export var target_distance := 500.0
## Abaixo desta altura o jogador caiu para fora da pista.
@export var fall_limit_y := -10.0
## Duração do escurecimento de tela ao encerrar a run.
@export var fade_duration := 0.8

@export_group("Ruído (seção 34)")
@export var max_noise := 10.0
@export var noise_decay_per_second := 0.5
## Chance por segundo, por ponto de ruído, de um zumbi ser atraído.
@export var attract_chance_per_noise := 0.04
## Distância à frente em que surge o zumbi atraído.
@export var attract_spawn_ahead := 40.0
## Sem zumbis atraídos nesta distância antes da extração.
@export var attract_clear_before_extraction := 40.0

@onready var player: Node3D = $Player
@onready var player_health: Node = $Player/Health
@onready var player_combat: Node = $Player/Combat
@onready var chunk_streamer: Node3D = $Chunks
@onready var actors: Node3D = $Actors
@onready var events: Node = $Events
@onready var hud: Control = $HUD
@onready var camera: Camera3D = $Camera3D
@onready var director: ExpeditionDirector = $Director

## Loot coletado: chave de GameManager.LOOT_KEYS → quantidade.
var collected := {}
var zombies_killed := 0
## Kit médico da Enfermaria nível 2 (seção 41): uma cura por expedição.
var medkit_available := false
var medkit_used := false
## Seção 47: mochila da última morte, se esta é a volta ao local ({} = não).
var bag := {}
var bag_recovered := false
const BAG_SCENE := preload("res://scenes/obstacles/death_bag.tscn")
## XP dos zumbis eliminados (distância e extração entram no fim).
var kill_xp := 0
## 0 a max_noise. Tiros aumentam; baixa sozinho com o tempo.
var noise := 0.0
## Ruído somado na expedição inteira: atrai a próxima horda (seção 45).
var noise_total := 0.0
var expedition_seed := 0
## Distância até o portão de extração, definida pela rota gerada.
var extraction_distance := 0.0
var run_ended := false
## Seção 24: voltou pela saída antecipada de uma bifurcação.
var early_extraction := false
## Bifurcações ainda não decididas.
var _pending_forks: Array[RouteGenerator.Fork] = []
## A faixa do meio fica bloqueada até aqui (divisória da bifurcação).
var _divider_end := -1.0
## Resgatados nesta expedição: [{name, profession}] (seção 44).
var rescued_survivors: Array[Dictionary] = []
var _attract_rng := RandomNumberGenerator.new()
## Seção 63: o veículo montado (nó "Vehicle" da Player) e onde ficou o último
## veículo estacionado.
var vehicle: PlayerVehicle
var _last_vehicle_at := -INF


func _enter_tree() -> void:
	# Em _enter_tree (e não em _ready) porque os filhos — HUD, Spawner —
	# executam _ready antes do pai e já procuram este grupo.
	add_to_group("run_manager")


func _ready() -> void:
	player_health.died.connect(_on_player_died)
	for key in GameManager.LOOT_KEYS:
		collected[key] = 0
	medkit_available = Infirmary.has_medkit()

	# Região e distância escolhidas na preparação (seções 25, 28 e 48).
	chunk_streamer.region = GameManager.current_region()
	target_distance = GameManager.next_distance

	# Seção 23 do GDD: a seed determina chunks, obstáculos, loot, zumbis e
	# eventos.
	expedition_seed = GameManager.take_expedition_seed()
	# Seção 47: voltando ao local da morte, a mesma seed refaz a mesma rota e
	# a mochila espera no ponto exato.
	var gm_bag: Dictionary = GameManager.death_bag
	if GameManager.recovering_bag and not gm_bag.is_empty() and int(gm_bag.seed) == expedition_seed \
			and StringName(gm_bag.region) == chunk_streamer.region.id and is_equal_approx(float(gm_bag.distance), target_distance):
		bag = gm_bag
		chunk_streamer.chunk_loaded.connect(_on_chunk_loaded)
		events.schedule_banner("SUA MOCHILA À FRENTE", Color(1.0, 0.8, 0.35), bag.at)
	director.rng.seed = expedition_seed + 1
	vehicle = PlayerVehicle.new()
	vehicle.name = "Vehicle"
	player.add_child(vehicle)
	vehicle.mounted_changed.connect(_on_vehicle_changed)
	chunk_streamer.chunk_loaded.connect(_place_vehicle)
	extraction_distance = chunk_streamer.build(expedition_seed, target_distance)
	_pending_forks.assign(chunk_streamer.forks)
	_attract_rng.seed = expedition_seed

	# Armas equipadas na preparação (seção 35), no nível atual da Oficina e
	# com a durabilidade salva.
	player_combat.weapon = GameManager.knife()
	player_combat.pistol = GameManager.gun()
	player_combat.apply_visuals()
	player_combat.set_knife_durability(GameManager.knife_durability)
	player_combat.set_ammo(GameManager.ammo)

	AudioManager.play_music("music_run")
	AudioManager.play_ambient("wind_loop")
	_warm_up_shaders()


const WARM_UP_CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÇÉÊÍÓÔÕÚabcdefghijklmnopqrstuvwxyzàáâãçéêíóôõú0123456789 -+!?:.,/()%·"


## Seção 51: a primeira vez que um tipo de material é desenhado, o shader
## compila e o jogo engasga (morte de zumbi com transparência, explosivo
## brilhando, rastro de tiro...). Desenha um exemplar de cada na frente da
## câmera enquanto a transição ainda está preta.
func _warm_up_shaders() -> void:
	var warm := Node3D.new()
	warm.name = "ShaderWarmUp"
	add_child(warm)
	warm.global_position = player.global_position + Vector3(0, 1.2, -3.0)
	var variants: Array[StandardMaterial3D] = []
	var plain := StandardMaterial3D.new()
	variants.append(plain)
	var faded := StandardMaterial3D.new()
	faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	faded.albedo_color = Color(1, 1, 1, 0.5)
	variants.append(faded)
	var glowing := StandardMaterial3D.new()
	glowing.emission_enabled = true
	glowing.emission = Color(1, 0.5, 0.1)
	variants.append(glowing)
	var metal := StandardMaterial3D.new()
	metal.metallic = 0.7
	variants.append(metal)
	var unshaded := StandardMaterial3D.new()
	unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	unshaded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	variants.append(unshaded)
	for i in variants.size():
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.2
		mi.mesh = box
		mi.material_override = variants[i]
		mi.position = Vector3((i - 2) * 0.3, 0, 0)
		warm.add_child(mi)
	# Glifos: cada tamanho de fonte rasteriza as letras na primeira vez que
	# aparece (avisos de evento, números de dano). Faz isso agora, no escuro.
	for font_size in [40, 44, 48, 52, 56, 60, 72]:
		var label := Label3D.new()
		label.text = WARM_UP_CHARSET
		label.font_size = font_size
		label.outline_size = 14 if font_size >= 56 else 12
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.pixel_size = 0.0005
		warm.add_child(label)
	hud.warm_up_fonts(WARM_UP_CHARSET)
	Fx.burst(actors, warm.global_position, Fx.BLOOD_COLOR, 4, 1.0)
	Fx.muzzle_flash(actors, warm.global_position)
	for i in 4:
		await get_tree().process_frame
	warm.queue_free()

	_apply_progression()

	# Seção 37: comida ou água esgotada no abrigo = começa ferida.
	var penalty := GameManager.start_hp_penalty()
	if penalty > 0:
		player_health.set_hp(player_health.max_hp - penalty)


## Atributos e perks da personagem (seções 42 e 43) aplicados à expedição.
func _apply_progression() -> void:
	player_health.max_hp += int(Progression.stat(&"max_hp"))
	# Seção 41: depois de morrer, sai Ferida (HP máximo menor).
	if GameManager.is_injured():
		player_health.max_hp = roundi(player_health.max_hp * GameManager.SHELTER.wound_max_hp)
	player_health.set_hp(player_health.max_hp)
	player_health.damage_multiplier = Progression.multiplier(&"damage_taken")
	player.lane_change_speed *= Progression.multiplier(&"lane_speed")
	player_combat.melee_damage_multiplier = Progression.multiplier(&"melee_damage")
	player_combat.crit_bonus = Progression.stat(&"crit_chance")
	player_combat.cooldown_multiplier = Progression.multiplier(&"cooldown", 0.5)


func _process(delta: float) -> void:
	if run_ended:
		return

	noise = maxf(0.0, noise - noise_decay_per_second * delta)
	# O Director (seção 30) decide quanto o ruído atrai em cada fase.
	if noise > 0.0 and _attract_rng.randf() < noise * attract_chance_per_noise * director.attract_multiplier() * delta:
		_spawn_attracted_zombie()
	_update_forks()


func _physics_process(_delta: float) -> void:
	if player.global_position.y < fall_limit_y:
		_end_run(false)


## Seção 24: a faixa da personagem quando a divisória começa decide o
## caminho; na faixa do meio ela é empurrada para o ramo de menor perigo.
func _update_forks() -> void:
	var distance := distance_travelled()
	# O furgão (duas faixas) não cabe num ramo: para antes da bifurcação.
	if vehicle and vehicle.is_mounted() and vehicle.data.two_lanes and not _pending_forks.is_empty() \
			and distance > _pending_forks[0].decision_distance - 30.0:
		vehicle.dismount("FURGÃO: A RUA SE DIVIDE")
	if _divider_end > 0.0 and distance > _divider_end:
		player.blocked_lane = -1
		_divider_end = -1.0
	if _pending_forks.is_empty() or distance < _pending_forks[0].decision_distance:
		return
	var fork: RouteGenerator.Fork = _pending_forks.pop_front()
	var lane: int = player.current_lane
	var side := 1 if lane == 0 else (2 if lane == 2 else fork.default_side)
	if lane == 1:
		player._change_lane(-1 if side == 1 else 1)
	player.blocked_lane = 1
	_divider_end = fork.divider_end
	chunk_streamer.choose(fork, side)
	var branch: BranchData = fork.sides[side]
	hud.show_banner("ROTA: %s" % branch.display_name.to_upper(), branch.color)
	if branch.early_extraction:
		early_extraction = true
		extraction_distance = fork.ends[side]


func distance_travelled() -> float:
	# Forward é -Z, então a distância percorrida é o inverso do Z do jogador.
	return -player.global_position.z


## Peso (kg) do loot coletado nesta run (seção 32: mochila com peso).
func carried_weight() -> float:
	var weights := GameManager.SHELTER.loot_weight_kg
	var total := 0.0
	for i in GameManager.LOOT_KEYS.size():
		total += collected.get(GameManager.LOOT_KEYS[i], 0) * weights[i]
	return total


func backpack_capacity() -> float:
	return GameManager.backpack_capacity_kg()


## Guarda o que couber na mochila e retorna quantas unidades entraram.
func collect_loot(loot_type: int, amount: int) -> int:
	# Perk Faro para loot: chance de uma unidade a mais.
	if _attract_rng.randf() < Progression.stat(&"loot_bonus_chance"):
		amount += 1

	var unit_weight: float = GameManager.SHELTER.loot_weight_kg[loot_type]
	var free := backpack_capacity() - carried_weight()
	var taken := mini(amount, int(floor((free + 0.0001) / unit_weight)))
	if taken <= 0:
		return 0
	var key := GameManager.LOOT_KEYS[loot_type]
	collected[key] += taken
	if key == "ammo":
		player_combat.set_ammo(player_combat.ammo + taken)
	elif key == "fuel" and vehicle:
		vehicle.add_fuel(taken)
	return taken


## Seção 47: coloca a mochila no chunk em que a personagem morreu, numa faixa
## sem obstáculo, com zumbis a mais por perto.
func _on_chunk_loaded(instance: Node3D, chunk: RouteGenerator.RouteChunk) -> void:
	var at: float = bag.at
	if at < chunk.start_distance or at >= chunk.end_distance():
		return
	chunk_streamer.chunk_loaded.disconnect(_on_chunk_loaded)
	var local_z := -(at - chunk.start_distance)
	var blocked := {}
	for child in instance.get_children():
		if child.is_in_group("obstacle") and absf(child.position.z - local_z) < 2.5:
			blocked[roundi(child.position.x / ChunkPopulator.LANE_WIDTH) + 1] = true
	var lane := 1
	for candidate in [1, 0, 2]:
		if not blocked.has(candidate):
			lane = candidate
			break
	var bag_node: Node3D = BAG_SCENE.instantiate()
	instance.add_child(bag_node)
	bag_node.position = Vector3((lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, local_z)
	for i in GameManager.SHELTER.bag_extra_zombies:
		var zombie_lane := _attract_rng.randi_range(0, 2)
		var pos := Vector3((zombie_lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -(at + 5.0 + i * 3.5))
		ChunkPopulator.spawn_zombie(chunk_streamer.region, _attract_rng, actors, pos)


## Seção 63: alguns chunks recebem um veículo estacionado, numa faixa sem
## obstáculo. Nunca no começo (fase Calma), perto da extração ou perto de uma
## bifurcação; a chance e o veículo saem da seed do chunk.
func _place_vehicle(instance: Node3D, chunk: RouteGenerator.RouteChunk) -> void:
	var world := GameManager.WORLD
	if chunk.fork or world.vehicles.is_empty() or extraction_distance <= 0.0:
		return
	var start := chunk.start_distance
	var end := chunk.end_distance()
	if start < maxf(world.vehicle_min_distance, extraction_distance * director.calm_fraction):
		return
	if end > extraction_distance - world.vehicle_clear_before_extraction:
		return
	if start - _last_vehicle_at < world.vehicle_min_gap:
		return
	for fork in chunk_streamer.forks:
		if end > fork.decision_distance - world.vehicle_clear_around_fork and start < fork.divider_end:
			return
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk.chunk_seed + 6311
	# Seção 24: alguns ramos (Garagens) têm mais veículos.
	var chance: float = chunk.mods.get("vehicle_chance", -1.0)
	if rng.randf() >= (chance if chance >= 0.0 else world.vehicle_chance):
		return
	var options: Array[VehicleData] = []
	var weights := PackedFloat32Array()
	var extra: Array = chunk.mods.get("extra_vehicles", [])
	for candidate in world.vehicles:
		if candidate.can_spawn(chunk_streamer.region.id, GameManager.level, target_distance, candidate.id in extra):
			options.append(candidate)
			weights.append(candidate.spawn_weight)
	if options.is_empty():
		return
	var chosen: VehicleData = options[rng.rand_weighted(weights)]

	var local_z := -chunk.data.length * 0.5
	var blocked := {}
	for child in instance.get_children():
		if child.is_in_group("obstacle") and absf(child.position.z - local_z) < 3.0:
			blocked[roundi(child.position.x / ChunkPopulator.LANE_WIDTH) + 1] = true
	# Posições possíveis em X: uma faixa livre, ou o meio de duas faixas
	# livres para o furgão.
	var spots: Array[float] = []
	if chosen.two_lanes:
		for pair in [[0, 1], [1, 2]]:
			if not blocked.has(pair[0]) and not blocked.has(pair[1]):
				spots.append((pair[0] + pair[1] - 2) * ChunkPopulator.LANE_WIDTH / 2.0)
	else:
		for lane in 3:
			if not blocked.has(lane):
				spots.append((lane - 1) * ChunkPopulator.LANE_WIDTH)
	if spots.is_empty():
		return
	var pickup := VehiclePickup.new()
	pickup.data = chosen
	instance.add_child(pickup)
	pickup.position = Vector3(spots[rng.randi() % spots.size()], 0.0, local_z)
	_last_vehicle_at = start - local_z
	# O aviso aparece WARN_AHEAD antes do ponto agendado.
	events.schedule_banner("%s À FRENTE" % chosen.display_name.to_upper(), chosen.color, _last_vehicle_at - world.vehicle_sign_distance + events.WARN_AHEAD)


func _on_vehicle_changed(data: VehicleData) -> void:
	if not data:
		return
	hud.show_banner(data.display_name.to_upper() + "!", data.color)
	if Settings.should_show_hint(&"vehicle"):
		hud.show_hint("VEÍCULO: o dano vai para o HP dele. Quando acabar, você cai sem se machucar.")
	elif data.hint != "" and Settings.should_show_hint(StringName("vehicle_%s" % data.id)):
		hud.show_hint(data.hint)


## Encostar na mochila: pega o que couber. Retorna as unidades recuperadas.
func collect_bag() -> int:
	bag_recovered = true
	var taken := 0
	for key in bag.loot:
		taken += collect_loot(GameManager.LOOT_KEYS.find(key), int(bag.loot[key]))
	return taken


## Kit médico (botão KIT ou H): cura uma vez por expedição.
func use_medkit() -> bool:
	if not medkit_available or medkit_used or run_ended:
		return false
	if player_health.current_hp <= 0 or player_health.current_hp >= player_health.max_hp:
		return false
	medkit_used = true
	player_health.heal(GameManager.SHELTER.medkit_heal)
	AudioManager.play("pickup", -2.0, 1.3)
	Fx.float_text(player, player.global_position + Vector3.UP * 2.2, "+%d HP" % GameManager.SHELTER.medkit_heal, Color(0.5, 1.0, 0.55), 56)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		use_medkit()


## `from_player`: tiros (reduzidos pelo perk Passos leves); explosões não.
func add_noise(amount: float, from_player := true) -> void:
	var multiplier := Progression.multiplier(&"noise", 0.2) if from_player else 1.0
	noise = minf(max_noise, noise + amount * multiplier)
	noise_total += amount * multiplier


## "Mais tiros → mais ruído → mais zumbis" (seção 35): surge um zumbi à
## frente, já alerta.
func _spawn_attracted_zombie() -> void:
	var distance := distance_travelled() + attract_spawn_ahead
	if distance > extraction_distance - attract_clear_before_extraction:
		return
	var lane := _attract_rng.randi_range(0, 2)
	var pos := Vector3((lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -distance)
	var zombie := ChunkPopulator.spawn_zombie(chunk_streamer.region, _attract_rng, actors, pos)
	zombie.alert()


func rescue_survivor(info: Dictionary) -> void:
	rescued_survivors.append(info)


func register_kill(xp_reward: int) -> void:
	zombies_killed += 1
	kill_xp += xp_reward


## XP que a expedição daria se terminasse agora com extração.
func xp_if_extracted() -> int:
	return Progression.expedition_xp(kill_xp, distance_travelled(), true)


## Pausa → Abandonar: conta como morte (seção 46).
func abandon() -> void:
	_end_run(false)


func extract_successfully() -> void:
	_end_run(true)


func _on_player_died() -> void:
	_end_run(false)


func _end_run(survived: bool) -> void:
	if run_ended:
		return
	run_ended = true

	GameManager.commit_run({
		"survived": survived,
		"loot": collected.duplicate(),
		"medkit_used": medkit_used,
		"bag_recovered": bag_recovered,
		"noise_total": noise_total,
		"early_extraction": early_extraction and survived,
		"ammo_left": player_combat.ammo,
		"knife_durability": player_combat.knife_durability,
		"distance": distance_travelled(),
		"kills": zombies_killed,
		"kill_xp": kill_xp,
		"survivors": rescued_survivors,
		"hp": player_health.current_hp,
		"max_hp": player_health.max_hp,
	})
	print(
		"[Run] %s — distância: %.0fm"
		% [("Extração concluída" if survived else "Personagem morreu"), distance_travelled()]
	)

	player.set_physics_process(false)
	AudioManager.set_heartbeat(false)
	AudioManager.stop_ambient()
	AudioManager.play("extraction" if survived else "zombie_death", 0.0, 1.0 if survived else 0.7)

	# Seção 48 do GDD: EXTRACTION → SHELTER direto; morte passa pelo RESULTADO.
	# Adiado: _end_run costuma vir de um callback de física (body_entered).
	if survived:
		_fade_out.call_deferred("Retornando ao abrigo...", "res://scenes/shelter.tscn")
	else:
		_fade_out.call_deferred("Você caiu...", "res://scenes/result.tscn")


func _fade_out(message: String, next_scene: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10

	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)

	var label := Label.new()
	label.text = message
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.modulate.a = 0.0
	layer.add_child(label)

	add_child(layer)

	var tween := create_tween().set_parallel()
	tween.tween_property(fade, "color:a", 1.0, fade_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)
	tween.chain().tween_interval(0.5)
	tween.chain().tween_callback(get_tree().change_scene_to_file.bind(next_scene))
