class_name Progression
extends RefCounted

## Progressão da personagem (seções 42 e 43 do GDD, PlayerProgression da
## seção 49): XP → nível → pontos de atributo e de perk. `stat()` soma o
## efeito de atributos e perks num modificador que os outros sistemas usam.
##
## Modificadores (StringName → valor somado):
##   max_hp, backpack_kg, storage_bonus, production_bonus,
##   consumption_reduction, food_per_day → valores absolutos
##   lane_speed, crit_chance, melee_damage, death_recovery,
##   loot_bonus_chance               → frações somadas (0.1 = +10%)
##   damage_taken, cooldown, noise   → frações negativas (-0.1 = -10%)
##   scrap_cost                      → fração negativa no custo de sucata

const DATA: ProgressionData = preload("res://data/progression/progression.tres")


static func stat(effect: StringName) -> float:
	var gm := GameManager
	var total := 0.0
	for a in DATA.attributes:
		if a.effect == effect:
			total += gm.attributes.get(a.id, 0) * a.value_per_point
	for p in DATA.perks:
		if p.effect == effect:
			total += gm.perks.get(p.id, 0) * p.value_per_rank
	# Moradores do abrigo (seção 44) também dão bônus pela profissão — menos
	# com a moral crítica ou esgotada (seção 37).
	if gm.morale_state() >= GameManager.Supply.CRITICAL:
		return total
	for info in gm.survivors:
		var profession := gm.WORLD.profession(info.profession)
		if profession and profession.effect == effect:
			# Traço e afinidade alta aumentam o bônus (seção 44).
			total += profession.value * Residents.profession_multiplier(info)
	return total


## Multiplicador para modificadores em fração, com piso (ex.: dano recebido
## nunca abaixo de 30%).
static func multiplier(effect: StringName, minimum := 0.3) -> float:
	return maxf(minimum, 1.0 + stat(effect))


# -------------------------------------------------------------------- XP

static func xp_to_next() -> int:
	return DATA.xp_to_next(GameManager.level)


static func is_max_level() -> bool:
	return GameManager.level >= DATA.max_level


## Soma XP e sobe de nível quantas vezes der. Retorna os níveis ganhos.
static func add_xp(amount: int) -> int:
	var gm := GameManager
	if is_max_level():
		return 0
	gm.xp += amount
	var gained := 0
	while not is_max_level() and gm.xp >= xp_to_next():
		gm.xp -= xp_to_next()
		gm.level += 1
		gm.attribute_points += DATA.attribute_points_per_level
		gm.perk_points += DATA.perk_points_per_level
		gained += 1
	if is_max_level():
		gm.xp = 0
	return gained


## XP de uma expedição: zumbis + distância + bônus de extração; na morte,
## só uma parte (seção 46).
## `full_extraction`: false na extração antecipada (seção 24) — sem o bônus.
static func expedition_xp(kill_xp: int, distance: float, survived: bool, full_extraction := true) -> int:
	var total := kill_xp + int(distance * DATA.xp_per_meter)
	if survived:
		if full_extraction:
			total += DATA.extraction_bonus_xp
	else:
		total = int(round(total * DATA.death_xp_rate))
	return total


# -------------------------------------------------------------- atributos

static func attribute_block_reason(attribute: AttributeData) -> String:
	var gm := GameManager
	if gm.attributes.get(attribute.id, 0) >= attribute.max_points:
		return "Máximo"
	if gm.attribute_points <= 0:
		return "Sem pontos de atributo"
	return ""


static func raise_attribute(attribute: AttributeData) -> bool:
	if attribute_block_reason(attribute) != "":
		return false
	var gm := GameManager
	gm.attributes[attribute.id] = gm.attributes.get(attribute.id, 0) + 1
	gm.attribute_points -= 1
	SaveManager.save_game()
	return true


# ------------------------------------------------------------------ perks

## Pontos já gastos numa árvore (soma dos ranks dos perks dela).
static func branch_points(branch: int) -> int:
	var total := 0
	for p in DATA.perks:
		if p.branch == branch:
			total += GameManager.perks.get(p.id, 0)
	return total


static func perk_block_reason(perk: PerkData) -> String:
	var gm := GameManager
	if gm.perks.get(perk.id, 0) >= perk.max_rank:
		return "Máximo"
	var have := branch_points(perk.branch)
	if have < perk.required_tree_points:
		var unit := "ponto" if perk.required_tree_points == 1 else "pontos"
		return "Requer %d %s em %s" % [perk.required_tree_points, unit, DATA.BRANCH_NAMES[perk.branch]]
	if gm.perk_points <= 0:
		return "Sem pontos de perk"
	return ""


static func learn_perk(perk: PerkData) -> bool:
	if perk_block_reason(perk) != "":
		return false
	var gm := GameManager
	gm.perks[perk.id] = gm.perks.get(perk.id, 0) + 1
	gm.perk_points -= 1
	SaveManager.save_game()
	return true
