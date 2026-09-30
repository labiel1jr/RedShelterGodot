class_name Residents
extends RefCounted

## Personalidade e relacionamento dos moradores (seção 44 do GDD). Cada
## morador ({name, profession, trait, affinity, request}) tem um traço, uma
## afinidade de 0 a 100 com o grupo e, com afinidade alta, pode fazer um
## pedido: trazer recursos ou explorar uma região. A moral continua sendo do
## abrigo inteiro; os traços mudam como ela varia.


static func world() -> WorldData:
	return GameManager.WORLD


static func trait_of(info: Dictionary) -> TraitData:
	return world().trait_by_id(StringName(info.get("trait", "")))


## Morador novo: traço sorteado e afinidade inicial.
static func setup(info: Dictionary) -> Dictionary:
	var resident := info.duplicate()
	var traits := world().traits
	if not resident.has("trait") and not traits.is_empty():
		resident["trait"] = traits[randi() % traits.size()].id
	resident["affinity"] = int(resident.get("affinity", world().affinity_start))
	resident["request"] = resident.get("request", {})
	return resident


## Morador vindo do save (o JSON devolve números como float e chaves como
## String). Saves antigos não têm traço: sorteia um fixo pelo nome.
static func sanitize(info: Dictionary) -> Dictionary:
	var resident := {"name": str(info.name), "profession": StringName(info.profession)}
	var trait_id := StringName(info.get("trait", ""))
	if not world().trait_by_id(trait_id) and not world().traits.is_empty():
		trait_id = world().traits[absi(hash(resident.name)) % world().traits.size()].id
	resident["trait"] = trait_id
	resident["affinity"] = clampi(int(info.get("affinity", world().affinity_start)), 0, 100)
	var request: Dictionary = info.get("request", {})
	if request.has("kind"):
		resident["request"] = {
			"kind": str(request.kind), "key": str(request.get("key", "")), "amount": int(request.get("amount", 0)),
			"region": str(request.get("region", "")), "days_left": int(request.get("days_left", 1)),
		}
	else:
		resident["request"] = {}
	return resident


# --------------------------------------------------------------- efeitos

## Bônus da profissão deste morador: traço × afinidade alta.
static func profession_multiplier(info: Dictionary) -> float:
	var mult := 1.0
	var t := trait_of(info)
	if t:
		mult *= t.profession_multiplier
	if int(info.get("affinity", 0)) >= world().affinity_high:
		mult *= 1.0 + world().affinity_high_bonus
	return mult


## Multiplica as perdas de moral do abrigo (otimistas amortecem,
## pessimistas pioram).
static func morale_loss_multiplier() -> float:
	var mult := 1.0
	for info in GameManager.survivors:
		var t := trait_of(info)
		if t:
			mult *= t.morale_loss_multiplier
	return clampf(mult, 0.5, 2.0)


static func _sum(field: StringName) -> int:
	var total := 0
	for info in GameManager.survivors:
		var t := trait_of(info)
		if t:
			total += int(t.get(field))
	return total


static func daily_morale() -> int:
	return _sum(&"daily_morale")


static func extra_food() -> int:
	return _sum(&"extra_food")


static func extra_production() -> int:
	return _sum(&"extra_production")


# ------------------------------------------------------------- afinidade

## Moradores criados sem os campos da Fase 11 ganham os valores padrão.
static func _ensure_fields() -> void:
	for info in GameManager.survivors:
		if not info.has("affinity"):
			info["affinity"] = world().affinity_start
		if not info.has("request"):
			info["request"] = {}


static func change_affinity(info: Dictionary, amount: int) -> void:
	info["affinity"] = clampi(int(info.get("affinity", 0)) + amount, 0, 100)


static func change_affinity_all(amount: int) -> void:
	for info in GameManager.survivors:
		change_affinity(info, amount)


## Fechamento da expedição (GameManager.commit_run). Retorna linhas para o
## relatório do dia.
static func after_run(survived: bool, recovered_total: int, region_id: StringName, turned_away: int) -> Array[String]:
	var lines: Array[String] = []
	_ensure_fields()
	if GameManager.survivors.is_empty():
		return lines
	if survived and recovered_total > 0:
		change_affinity_all(world().affinity_loot)
	if turned_away > 0:
		change_affinity_all(world().affinity_turned_away * turned_away)
	if survived:
		for info in GameManager.survivors:
			var request: Dictionary = info.request
			if request.get("kind", "") == "visit" and StringName(request.region) == region_id:
				lines.append(_complete(info))
	return lines


## Fechamento do dia (Production.end_of_day), depois do consumo.
static func end_of_day(short: bool, report: Array[String]) -> void:
	var gm := GameManager
	_ensure_fields()
	if gm.survivors.is_empty():
		return
	var fed := not short and gm.supply_state("food") == gm.Supply.NORMAL and gm.supply_state("water") == gm.Supply.NORMAL
	if short:
		change_affinity_all(world().affinity_shortage)
		report.append("Afinidade de todos: %d (faltou comida ou água)" % world().affinity_shortage)
	elif fed:
		change_affinity_all(world().affinity_daily)

	# Pedidos: prazo, expiração e pedidos novos.
	for info in gm.survivors:
		var request: Dictionary = info.request
		if request.has("kind"):
			request.days_left -= 1
			if request.days_left <= 0:
				change_affinity(info, world().request_fail_affinity)
				report.append("%s ficou decepcionado(a): o pedido não foi atendido (afinidade %d)." % [info.name, world().request_fail_affinity])
				info.request = {}
		elif int(info.affinity) >= world().affinity_high and randf() < world().request_chance:
			info.request = _new_request()
			report.append("%s tem um pedido: %s" % [info.name, request_text(info)])

	_maybe_leave(report)


## Moral crítica: vai embora quem tem afinidade baixa; moral esgotada:
## qualquer um (o de menor afinidade primeiro). Leais nunca vão.
static func _maybe_leave(report: Array[String]) -> void:
	var gm := GameManager
	var state := gm.morale_state()
	if state < gm.Supply.CRITICAL or randf() >= gm.SHELTER.morale_leave_chance:
		return
	var candidate: Dictionary = {}
	for info in gm.survivors:
		var t := trait_of(info)
		if t and t.never_leaves:
			continue
		if state == gm.Supply.CRITICAL and int(info.affinity) > world().affinity_low:
			continue
		if candidate.is_empty() or int(info.affinity) < int(candidate.affinity):
			candidate = info
	if candidate.is_empty():
		return
	gm.survivors.erase(candidate)
	report.append("%s foi embora: a moral do abrigo está %s e a afinidade dele(a) era %d." % [
		candidate.name, "esgotada" if state == gm.Supply.EXHAUSTED else "crítica", int(candidate.affinity)
	])


# ---------------------------------------------------------------- pedidos

static func _new_request() -> Dictionary:
	var gm := GameManager
	# Metade das vezes, explorar uma região liberada (não o Bairro).
	var regions: Array = gm.WORLD.regions.filter(func(r): return gm.is_region_unlocked(r) and r.id != &"bairro")
	if not regions.is_empty() and randf() < 0.5:
		var region: RegionData = regions[randi() % regions.size()]
		return {"kind": "visit", "region": String(region.id), "key": "", "amount": 0, "days_left": world().request_days}
	var keys: Array = world().request_resources.keys()
	var key: String = keys[randi() % keys.size()]
	var range_: Array = world().request_resources[key]
	return {"kind": "bring", "key": key, "amount": randi_range(range_[0], range_[1]), "region": "", "days_left": world().request_days}


static func request_text(info: Dictionary) -> String:
	var request: Dictionary = info.get("request", {})
	match request.get("kind", ""):
		"bring":
			return "trazer %d %s (%d dias)" % [request.amount, GameManager.RESOURCE_NAMES[request.key].to_lower(), request.days_left]
		"visit":
			return "voltar vivo(a) de uma expedição em %s (%d dias)" % [world().region(StringName(request.region)).display_name, request.days_left]
	return ""


## "" se dá para entregar o pedido de recursos agora.
static func deliver_block_reason(info: Dictionary) -> String:
	var request: Dictionary = info.get("request", {})
	if request.get("kind", "") != "bring":
		return "Cumpra na expedição"
	var cost := {request.key: int(request.amount)}
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func deliver(info: Dictionary) -> bool:
	if deliver_block_reason(info) != "":
		return false
	var request: Dictionary = info.request
	GameManager.pay({request.key: int(request.amount)})
	_complete(info)
	SaveManager.save_game()
	return true


## Recompensa: XP, moral do abrigo e afinidade.
static func _complete(info: Dictionary) -> String:
	var gm := GameManager
	info.request = {}
	change_affinity(info, world().request_affinity)
	gm.change_morale(world().request_morale, "pedido de %s" % info.name)
	gm.last_run_levels_gained += Progression.add_xp(world().request_xp)
	return "Pedido de %s atendido: +%d XP, +%d moral, +%d afinidade." % [info.name, world().request_xp, world().request_morale, world().request_affinity]
