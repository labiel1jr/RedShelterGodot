extends Node

## Autoload (Project Settings > Autoload). Guarda o estado que atravessa
## cenas e vai para o save: recursos, construções, armas e o resultado da
## última expedição. As regras de balanceamento ficam no ShelterData.

const SHELTER: ShelterData = preload("res://data/shelter/shelter.tres")
const WORLD: WorldData = preload("res://data/world.tres")
const RESOURCE_KEYS: Array[String] = ["food", "water", "scrap", "energy", "ammo", "components", "medicine", "fuel"]
const RESOURCE_NAMES := {
	"food": "Comida", "water": "Água", "scrap": "Sucata", "energy": "Energia", "ammo": "Munição",
	"components": "Componentes", "medicine": "Medicamentos", "fuel": "Combustível",
}
## Tipos de loot da pista, na ordem de `loot_type` (loot_pickup) e de
## ShelterData.loot_weight_kg.
const LOOT_KEYS: Array[String] = ["food", "water", "scrap", "ammo", "components", "medicine", "fuel"]

## Estados de um recurso do abrigo e da moral (seção 37 do GDD).
enum Supply { NORMAL, WARNING, CRITICAL, EXHAUSTED }

var food := 0
var water := 0
var scrap := 0
## Produzida pelo Gerador e pelos Painéis solares, gasta pela Oficina.
var energy := 0
## Munição da pistola (seção 35: limitada). A expedição leva toda.
var ammo := 0
## Seção 62: armas, construções avançadas (Mercado, Zona Industrial, Oficina).
var components := 0
## Seção 62: Enfermaria e kit médico.
var medicine := 0
## Seção 62: o nível 2 do Gerador gasta combustível.
var fuel := 0

## Moral do abrigo, 0 a 100 (seção 37).
var morale := 70
## Mudanças de moral desde o último fechamento do dia: ["+3 refeição"].
var morale_log: Array[String] = []
## Expedições que ainda começam com a personagem Ferida (seção 41).
var injured_days := 0
## Fraqueza por fome/sede tratada na Enfermaria para a próxima expedição.
var hunger_treated := false

## Cada expedição conta como um dia no abrigo.
var day := 1
## id da construção → nível (0 = não construída).
var building_levels := {}
## id da arma (WeaponTrack) → nível; 0 = ainda não fabricada (seções 11,
## 12 e 35).
var weapon_levels := {}
## id da arma branca → durabilidade (seção 16).
var melee_durability := {}
## Armas levadas na expedição: uma branca e uma de fogo (seção 35).
var equipped_melee: StringName = &"knife"
var equipped_gun: StringName = &"pistol"

var knife_level: int:
	get: return weapon_levels.get(&"knife", 1)
	set(value): weapon_levels[&"knife"] = value
var pistol_level: int:
	get: return weapon_levels.get(&"pistol", 1)
	set(value): weapon_levels[&"pistol"] = value
## Durabilidade da arma branca equipada.
var knife_durability: int:
	get: return melee_durability.get(equipped_melee, 0)
	set(value): melee_durability[equipped_melee] = value

# Progressão da personagem (seções 42 e 43; regras em Progression).
var level := 1
var xp := 0
var attribute_points := 0
var perk_points := 0
## id do atributo → pontos.
var attributes := {}
## id do perk → rank.
var perks := {}

## Moradores resgatados (seção 44): [{name, profession}].
var survivors: Array[Dictionary] = []

## Próxima expedição, escolhida na preparação (seções 25 e 28).
var next_region: StringName = &"bairro"
var next_distance := 500.0
## Seed da próxima expedição; -1 sorteia uma nova (seção 23 do GDD).
var next_seed := -1
var last_run_seed := 0

## Seção 45: dia do próximo ataque ao abrigo e o "calor" de ruído das
## últimas expedições (horda maior).
var next_attack_day := 8
var attack_noise := 0.0
## Resultado da última defesa: {won, kills, gate_hp, gate_max, lost {chave:
## quantidade}, xp}. Vazio = nenhuma defesa desde a última expedição.
var last_defense := {}

## Seção 47: o que se perdeu na última morte fica numa mochila no local.
## {region, seed, distance (da expedição), at (m da morte), loot {chave:
## quantidade}, runs_left}. Vazio = nenhuma mochila.
var death_bag := {}
## A próxima expedição é a volta ao local da morte (mesma região, seed e
## distância).
var recovering_bag := false
## Resultado da última expedição para a mochila: "", "left" (nova mochila),
## "recovered", "expired".
var last_run_bag := ""

var last_run_survived := false
var last_run_distance := 0.0
var last_run_kills := 0
var last_run_hp := 0
var last_run_max_hp := 0

# O Abrigo consome esta flag para tocar a sequência de chegada da expedição.
var arrival_pending := false

# Coletado durante a run (chave de LOOT_KEYS → quantidade).
var last_run_loot := {}
var last_run_ammo := 0
var last_run_ammo_used := 0

# Efetivamente levado para o abrigo (menor que o coletado em caso de morte).
var last_run_recovered := {}
var last_run_ammo_recovered := 0
## A personagem voltou Ferida (morreu nesta expedição).
var last_run_wounded := false
## Voltou pela extração antecipada de uma bifurcação (seção 24).
var last_run_early := false
var last_run_medkit_used := false

## Linhas do fechamento do dia (produção, consumo, perdas), para o Abrigo.
var last_day_report: Array[String] = []
var last_run_xp := 0
var last_run_levels_gained := 0
## Nomes dos que viraram moradores / dos que não couberam no abrigo.
var last_run_new_survivors: Array[String] = []
var last_run_turned_away: Array[String] = []
var last_run_lost_survivors: Array[String] = []
## Linhas dos moradores vindas da expedição (pedidos cumpridos), que abrem o
## relatório do dia.
var resident_log: Array[String] = []


func _ready() -> void:
	new_game()


func new_game() -> void:
	for key in RESOURCE_KEYS:
		set(key, SHELTER.start_resources.get(key, 0))
	day = 1
	building_levels.clear()
	for b in SHELTER.buildings:
		building_levels[b.id] = b.start_level
	weapon_levels.clear()
	melee_durability.clear()
	for t in all_weapon_tracks():
		weapon_levels[t.id] = t.start_level
		if not t.ranged and t.start_level > 0:
			melee_durability[t.id] = t.level_data(t.start_level).max_durability
	equipped_melee = &"knife"
	equipped_gun = &"pistol"
	level = 1
	xp = 0
	attribute_points = 0
	perk_points = 0
	attributes.clear()
	perks.clear()
	survivors.clear()
	morale = SHELTER.morale_start
	morale_log.clear()
	injured_days = 0
	hunger_treated = false
	death_bag = {}
	recovering_bag = false
	next_attack_day = SHELTER.first_attack_day
	attack_noise = 0.0
	last_defense = {}
	next_region = &"bairro"
	next_distance = WORLD.distances[0]
	next_seed = -1
	arrival_pending = false
	last_day_report.clear()


# ------------------------------------------------------------- consultas

func level_of(id: StringName) -> int:
	return building_levels.get(id, 0)


## Arma branca equipada (a faca, ou facão, machado, katana...).
func knife() -> WeaponData:
	return weapon_data(equipped_melee)


func pistol() -> RangedWeaponData:
	return SHELTER.pistol_track.level_data(pistol_level)


## Arma de fogo equipada (pistola, escopeta ou SMG, seção 35).
func gun() -> RangedWeaponData:
	return weapon_data(equipped_gun)


## Faca e pistola sempre existem; as outras vêm de `weapon_tracks`.
func all_weapon_tracks() -> Array[WeaponTrack]:
	var tracks: Array[WeaponTrack] = []
	tracks.assign(SHELTER.weapon_tracks)
	for t in [SHELTER.knife_track, SHELTER.pistol_track]:
		if not tracks.has(t):
			tracks.push_front(t)
	return tracks


func weapon_level(id: StringName) -> int:
	return weapon_levels.get(id, 0)


func owns_weapon(id: StringName) -> bool:
	return weapon_level(id) > 0


## Dados da arma no nível atual (o 1 se ainda não fabricada).
func weapon_data(id: StringName) -> Resource:
	return SHELTER.weapon_track(id).level_data(maxi(1, weapon_level(id)))


func equip_weapon(id: StringName) -> void:
	if not owns_weapon(id):
		return
	if SHELTER.weapon_track(id).ranged:
		equipped_gun = id
	else:
		equipped_melee = id


## Capacidade do Depósito para comida, água e sucata.
func storage_capacity() -> int:
	return int(SHELTER.building(&"storage").effect_at(level_of(&"storage")) + Progression.stat(&"storage_bonus"))


func capacity_of(key: String) -> int:
	match key:
		"food", "water", "scrap", "components", "medicine", "fuel":
			return storage_capacity()
		"energy":
			return energy_capacity()
	return -1  # sem limite


## Limite de energia: as Baterias (seção 38) aumentam.
func energy_capacity() -> int:
	var battery := SHELTER.building(&"battery")
	return int(battery.effect_at(level_of(&"battery"))) if battery else SHELTER.energy_capacity


func backpack_capacity_kg() -> float:
	return SHELTER.building(&"backpack").effect_at(level_of(&"backpack")) + Progression.stat(&"backpack_kg")


## Moradores que cabem: a cama extra da sala + o Dormitório.
func survivor_capacity() -> int:
	return WORLD.base_survivor_capacity + int(SHELTER.building(&"dormitory").effect_at(level_of(&"dormitory")))


func current_region() -> RegionData:
	return WORLD.region(next_region)


func is_region_unlocked(region: RegionData) -> bool:
	return level >= region.unlock_level


func is_distance_unlocked(index: int) -> bool:
	return level >= WORLD.distance_unlock_levels[index]


## Custo com os descontos de perk e de moradores (menos sucata).
func effective_cost(cost: Dictionary) -> Dictionary:
	var result := cost.duplicate()
	if result.has("scrap"):
		result["scrap"] = ceili(result["scrap"] * Progression.multiplier(&"scrap_cost", 0.2))
	return result


func supply_state(key: String) -> Supply:
	var amount: int = get(key)
	if amount <= 0:
		return Supply.EXHAUSTED
	if amount < SHELTER.critical_below:
		return Supply.CRITICAL
	if amount < SHELTER.warning_below:
		return Supply.WARNING
	return Supply.NORMAL


## HP a menos no início da próxima expedição por fome/sede (seção 37).
## `ignore_treatment`: o valor antes do tratamento na Enfermaria.
func start_hp_penalty(ignore_treatment := false) -> int:
	if hunger_treated and not ignore_treatment:
		return 0
	var penalty := 0
	for key in ["food", "water"]:
		if supply_state(key) == Supply.EXHAUSTED:
			penalty += SHELTER.exhausted_hp_penalty
	return penalty


## Seção 41: depois de morrer, a personagem sai Ferida (HP máximo menor).
func is_injured() -> bool:
	return injured_days > 0


## Seção 47: prepara a próxima expedição para voltar ao local da morte.
func select_bag_recovery() -> void:
	if death_bag.is_empty():
		return
	next_region = StringName(death_bag.region)
	next_distance = death_bag.distance
	recovering_bag = true


## "3 comida, 2 sucata" — o que está na mochila deixada.
func bag_loot_text() -> String:
	var parts: Array[String] = []
	for key in LOOT_KEYS:
		var amount: int = death_bag.get("loot", {}).get(key, 0)
		if amount > 0:
			parts.append("%d %s" % [amount, RESOURCE_NAMES[key].to_lower()])
	return ", ".join(parts)


# ---------------------------------------------------------------- defesa

## Seção 45: a horda chegou — defenda antes da próxima expedição.
func attack_due() -> bool:
	return day >= next_attack_day


func days_to_attack() -> int:
	return next_attack_day - day


## Zumbis da próxima horda: cresce com o dia e com o ruído recente.
func horde_size() -> int:
	return mini(SHELTER.horde_max, SHELTER.horde_base + int(day * SHELTER.horde_per_day + attack_noise * SHELTER.horde_per_noise))


## HP do portão e das barricadas: os moradores que não são medrosos reforçam.
func defense_reinforcement() -> float:
	var helpers := 0
	for info in survivors:
		var t := Residents.trait_of(info)
		if not (t and t.avoids_defense):
			helpers += 1
	return 1.0 + helpers * SHELTER.resident_reinforce


func soldier_count() -> int:
	var count := 0
	for info in survivors:
		var t := Residents.trait_of(info)
		if info.profession == &"soldier" and not (t and t.avoids_defense):
			count += 1
	return count


## `result`: won, kills, kill_xp, ammo_left, knife_durability, gate_hp,
## gate_max, hp, max_hp.
func commit_defense(result: Dictionary) -> void:
	var won: bool = result.won
	ammo = result.ammo_left
	knife_durability = result.knife_durability
	morale_log.clear()
	var lost := {}
	var xp_gain: int = result.kill_xp
	if won:
		xp_gain += SHELTER.attack_win_xp
		change_morale(SHELTER.attack_win_morale, "abrigo defendido")
		Residents.change_affinity_all(SHELTER.attack_win_affinity)
	else:
		change_morale(SHELTER.attack_loss_morale, "ataque ao abrigo perdido")
		Residents.change_affinity_all(SHELTER.attack_loss_affinity)
		for key in ["food", "water", "scrap", "components", "medicine", "fuel"]:
			var amount := int(ceil(get(key) * SHELTER.attack_loss_fraction))
			if amount > 0:
				lost[key] = amount
				set(key, get(key) - amount)
	if result.get("hp", 1) <= 0:
		injured_days = SHELTER.wound_days
	var levels := Progression.add_xp(xp_gain)
	last_defense = {
		"won": won, "kills": result.kills, "gate_hp": result.gate_hp, "gate_max": result.gate_max,
		"lost": lost, "xp": xp_gain, "levels": levels, "morale": morale_log.duplicate(),
	}
	morale_log.clear()
	next_attack_day = day + SHELTER.attack_interval
	attack_noise = 0.0
	CampaignLog.record_defense()
	SaveManager.save_game()


func has_profession(id: StringName) -> bool:
	for info in survivors:
		if info.profession == id:
			return true
	return false


# ------------------------------------------------------------------ moral

func morale_state() -> Supply:
	if morale < SHELTER.morale_exhausted_below:
		return Supply.EXHAUSTED
	if morale < SHELTER.morale_critical_below:
		return Supply.CRITICAL
	if morale < SHELTER.morale_warning_below:
		return Supply.WARNING
	return Supply.NORMAL


## Multiplicador da produção das construções pela moral (seção 37).
func morale_production() -> float:
	# Via variável: com a constante, o analisador tenta resolver o array na
	# hora de compilar e falha.
	var rules: ShelterData = SHELTER
	return rules.morale_production[morale_state()]


## Soma `amount` à moral e anota o motivo para o fechamento do dia.
func change_morale(amount: int, reason: String) -> void:
	# Seção 44: otimistas amortecem as perdas, pessimistas pioram.
	if amount < 0:
		amount = mini(-1, roundi(amount * Residents.morale_loss_multiplier()))
	if amount == 0:
		return
	morale = clampi(morale + amount, 0, 100)
	morale_log.append("%+d %s" % [amount, reason])


func can_afford(cost: Dictionary) -> bool:
	for key in cost:
		if get(key) < cost[key]:
			return false
	return true


## Texto do que falta para pagar `cost`, ex.: "Faltam 5 sucata".
func missing_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost:
		var missing: int = cost[key] - get(key)
		if missing > 0:
			parts.append("%d %s" % [missing, RESOURCE_NAMES[key].to_lower()])
	return "Faltam " + ", ".join(parts) if not parts.is_empty() else ""


func pay(cost: Dictionary) -> void:
	for key in cost:
		set(key, get(key) - cost[key])
	CampaignLog.add_spent(cost)


static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in RESOURCE_KEYS:
		if cost.get(key, 0) > 0:
			parts.append("%d %s" % [cost[key], RESOURCE_NAMES[key]])
	return ", ".join(parts) if not parts.is_empty() else "grátis"


# -------------------------------------------------------------- expedição

func take_expedition_seed() -> int:
	var expedition_seed := next_seed if next_seed >= 0 else randi() % 10_000_000
	next_seed = -1
	last_run_seed = expedition_seed
	return expedition_seed


## `result`: survived, loot ({chave de LOOT_KEYS: quantidade}), ammo_left,
## knife_durability, distance, kills, kill_xp, hp, max_hp, survivors,
## medkit_used.
func commit_run(result: Dictionary) -> void:
	var run_day := day
	var survived: bool = result.survived
	last_run_survived = survived
	last_run_distance = result.distance
	last_run_kills = result.kills
	last_run_hp = result.hp
	last_run_max_hp = result.max_hp
	arrival_pending = true
	knife_durability = result.knife_durability
	morale_log.clear()

	# Esta expedição gastou um dos dias de ferimento e o tratamento de fome.
	injured_days = maxi(0, injured_days - 1)
	hunger_treated = false

	# Morte perde metade dos recursos coletados na run (seção 46 do GDD);
	# o perk Catadora reduz a perda.
	var recovery_rate := 1.0 if survived else minf(0.9, 0.5 + Progression.stat(&"death_recovery"))

	var loot: Dictionary = result.get("loot", {})
	last_run_loot.clear()
	last_run_recovered.clear()
	var recovered_total := 0
	for key in LOOT_KEYS:
		var amount: int = loot.get(key, 0)
		last_run_loot[key] = amount
		if key == "ammo":
			continue
		var recovered := int(round(amount * recovery_rate))
		last_run_recovered[key] = recovered
		recovered_total += recovered
		set(key, get(key) + recovered)

	# Munição: a expedição leva toda a do abrigo. Na morte, perde-se metade
	# da coletada na rua — limitado ao que ainda sobrou no pente.
	last_run_ammo = last_run_loot["ammo"]
	var ammo_left: int = result.ammo_left
	var lost := mini(ammo_left, last_run_ammo - int(round(last_run_ammo * recovery_rate)))
	last_run_ammo_recovered = last_run_ammo - lost
	last_run_ammo_used = ammo + last_run_ammo - ammo_left
	ammo = ammo_left - lost
	last_run_recovered["ammo"] = last_run_ammo_recovered

	# Seção 47: mochila deixada na morte. Esta expedição gasta um dos prazos;
	# recuperá-la limpa; morrer deixa uma nova no lugar (a antiga some).
	last_run_bag = ""
	if result.get("bag_recovered", false):
		death_bag = {}
		last_run_bag = "recovered"
	elif not death_bag.is_empty():
		death_bag.runs_left -= 1
		if death_bag.runs_left <= 0:
			death_bag = {}
			last_run_bag = "expired"
	recovering_bag = false
	if not survived:
		var lost_loot := {}
		for key in LOOT_KEYS:
			var lost_amount: int = last_run_loot[key] - last_run_recovered[key]
			if lost_amount > 0:
				lost_loot[key] = lost_amount
		if not lost_loot.is_empty():
			death_bag = {
				"region": String(next_region), "seed": last_run_seed, "distance": next_distance,
				"at": result.distance, "loot": lost_loot, "runs_left": SHELTER.bag_runs,
			}
			last_run_bag = "left"

	# Kit médico da Enfermaria (seção 41): gasta um medicamento do abrigo.
	last_run_medkit_used = result.get("medkit_used", false)
	if last_run_medkit_used:
		medicine = maxi(0, medicine - 1)

	# Seção 41: morrer deixa a personagem Ferida nas próximas expedições.
	last_run_wounded = not survived
	if not survived:
		injured_days = SHELTER.wound_days

	# Moral (seção 37).
	if survived and recovered_total > 0:
		change_morale(SHELTER.morale_extracted_with_loot, "expedição com loot")
	elif not survived:
		change_morale(SHELTER.morale_death, "morte na expedição")

	# Seção 44: resgatados só viram moradores se a expedição deu certo.
	last_run_new_survivors.clear()
	last_run_turned_away.clear()
	last_run_lost_survivors.clear()
	for info in result.get("survivors", []):
		if not survived:
			last_run_lost_survivors.append(info.name)
		elif survivors.size() < survivor_capacity():
			survivors.append(Residents.setup(info))
			last_run_new_survivors.append(info.name)
			change_morale(SHELTER.morale_new_resident, "novo morador")
		else:
			last_run_turned_away.append(info.name)
			change_morale(SHELTER.morale_turned_away, "sobrevivente recusado")

	# Seção 42: XP da expedição → nível → pontos. Progressão é permanente.
	# Seção 24: a extração antecipada não dá o bônus da extração completa.
	last_run_early = result.get("early_extraction", false)
	last_run_xp = Progression.expedition_xp(result.kill_xp, result.distance, survived, not last_run_early)
	last_run_levels_gained = Progression.add_xp(last_run_xp)

	# Seção 45: o ruído das expedições atrai a próxima horda.
	attack_noise = attack_noise * 0.7 + float(result.get("noise_total", 0.0))
	last_defense = {}

	# Seção 44: afinidade dos moradores e pedidos de "explorar a região".
	resident_log = Residents.after_run(survived, recovered_total, next_region, last_run_turned_away.size())

	last_day_report = Production.end_of_day()
	CampaignLog.record_run(run_day)
	SaveManager.save_game()


# ------------------------------------------------------------------- save

func to_dict() -> Dictionary:
	var data := {
		"day": day,
		"buildings": building_levels.duplicate(),
		"weapons": weapon_levels.duplicate(),
		"melee_durability": melee_durability.duplicate(),
		"equipped_melee": equipped_melee,
		"equipped_gun": equipped_gun,
		"level": level,
		"xp": xp,
		"attribute_points": attribute_points,
		"perk_points": perk_points,
		"attributes": attributes.duplicate(),
		"perks": perks.duplicate(),
		"survivors": survivors.duplicate(true),
		"next_region": next_region,
		"next_distance": next_distance,
		"morale": morale,
		"injured_days": injured_days,
		"hunger_treated": hunger_treated,
		"death_bag": death_bag.duplicate(true),
		"next_attack_day": next_attack_day,
		"attack_noise": attack_noise,
		"recovering_bag": recovering_bag,
	}
	for key in RESOURCE_KEYS:
		data[key] = get(key)
	return data


func from_dict(data: Dictionary) -> void:
	new_game()
	for key in RESOURCE_KEYS:
		set(key, int(data.get(key, get(key))))
	day = int(data.get("day", 1))
	var saved_buildings: Dictionary = data.get("buildings", {})
	for id in saved_buildings:
		building_levels[StringName(id)] = int(saved_buildings[id])
	# Armas: a partir da Fase 10 vêm em "weapons"; saves antigos só têm a
	# faca e a pistola.
	var saved_weapons: Dictionary = data.get("weapons", {"knife": data.get("knife_level", 1), "pistol": data.get("pistol_level", 1)})
	for t in all_weapon_tracks():
		weapon_levels[t.id] = clampi(int(saved_weapons.get(String(t.id), t.start_level)), t.start_level, t.max_level())
	var saved_durability: Dictionary = data.get("melee_durability", {"knife": data.get("knife_durability", knife().max_durability)})
	for id in saved_durability:
		var melee_id := StringName(id)
		if owns_weapon(melee_id) and not SHELTER.weapon_track(melee_id).ranged:
			melee_durability[melee_id] = clampi(int(saved_durability[id]), 0, weapon_data(melee_id).max_durability)
	var melee_choice := StringName(data.get("equipped_melee", "knife"))
	var gun_choice := StringName(data.get("equipped_gun", "pistol"))
	if owns_weapon(melee_choice):
		equipped_melee = melee_choice
	if owns_weapon(gun_choice):
		equipped_gun = gun_choice
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	attribute_points = int(data.get("attribute_points", 0))
	perk_points = int(data.get("perk_points", 0))
	# O JSON devolve as chaves como String; os ids são StringName.
	for id in data.get("attributes", {}):
		attributes[StringName(id)] = int(data.attributes[id])
	for id in data.get("perks", {}):
		perks[StringName(id)] = int(data.perks[id])
	for info in data.get("survivors", []):
		if WORLD.profession(StringName(info.get("profession", ""))):
			survivors.append(Residents.sanitize(info))
	next_region = StringName(data.get("next_region", "bairro"))
	next_distance = float(data.get("next_distance", WORLD.distances[0]))
	# Saves antigos (antes da Fase 8) não têm moral nem ferimento.
	morale = clampi(int(data.get("morale", SHELTER.morale_start)), 0, 100)
	injured_days = maxi(0, int(data.get("injured_days", 0)))
	hunger_treated = bool(data.get("hunger_treated", false))
	# Saves antigos: o primeiro ataque vem uma semana depois de carregar.
	next_attack_day = int(data.get("next_attack_day", maxi(SHELTER.first_attack_day, day + SHELTER.attack_interval)))
	attack_noise = float(data.get("attack_noise", 0.0))
	# O JSON devolve números como float.
	var bag: Dictionary = data.get("death_bag", {})
	if bag.has("loot") and bag.has("seed"):
		var loot := {}
		for key in bag.loot:
			loot[str(key)] = int(bag.loot[key])
		death_bag = {
			"region": str(bag.get("region", "bairro")), "seed": int(bag.seed), "distance": float(bag.get("distance", 500.0)),
			"at": float(bag.get("at", 0.0)), "loot": loot, "runs_left": int(bag.get("runs_left", 1)),
		}
		recovering_bag = bool(data.get("recovering_bag", false))
