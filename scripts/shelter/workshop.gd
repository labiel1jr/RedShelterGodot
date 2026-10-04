class_name Workshop
extends RefCounted

## Oficina (seção 40 do GDD): reparar a arma branca, fabricar munição e
## componentes, fabricar e melhorar as armas (seções 11, 12 e 35). Nível 0 →
## 1 é a fabricação. Todas as ações gastam recursos e salvam o jogo.


# ------------------------------------------------------------------ reparo

static func repair_cost() -> Dictionary:
	var gm := GameManager
	var missing := gm.knife().max_durability - gm.knife_durability
	if missing <= 0:
		return {}
	var steps := ceili(missing / 10.0)
	var cost := {}
	for key in gm.SHELTER.repair_cost_per_10:
		cost[key] = gm.SHELTER.repair_cost_per_10[key] * steps
	cost["energy"] = gm.SHELTER.repair_energy
	return gm.effective_cost(cost)


static func repair_block_reason() -> String:
	var cost := repair_cost()
	if cost.is_empty():
		return "Arma intacta"
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func repair() -> bool:
	if repair_block_reason() != "":
		return false
	var gm := GameManager
	gm.pay(repair_cost())
	gm.knife_durability = gm.knife().max_durability
	SaveManager.save_game()
	return true


# ----------------------------------------------------------------- munição

static func ammo_cost() -> Dictionary:
	return GameManager.effective_cost(GameManager.SHELTER.ammo_craft_cost)


static func craft_ammo_block_reason() -> String:
	var cost := ammo_cost()
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func craft_ammo() -> bool:
	if craft_ammo_block_reason() != "":
		return false
	var gm := GameManager
	gm.pay(ammo_cost())
	gm.ammo += gm.SHELTER.ammo_craft_amount
	SaveManager.save_game()
	return true


# ------------------------------------- melhorias dos power-ups (seção 64)

static func powerup_level(id: StringName) -> int:
	return int(GameManager.powerup_levels.get(id, 1))


static func powerup_upgrade_cost(power: PowerUpData) -> Dictionary:
	var level := powerup_level(power.id)
	if level >= power.max_level() or level - 1 >= power.upgrade_costs.size():
		return {}
	return GameManager.effective_cost(power.upgrade_costs[level - 1])


static func powerup_upgrade_block_reason(power: PowerUpData) -> String:
	var level := powerup_level(power.id)
	if level >= power.max_level():
		return "Nível máximo"
	var required := power.upgrade_workshop[level - 1] if level - 1 < power.upgrade_workshop.size() else 0
	if GameManager.level_of(&"workshop") < required:
		return "Requer Oficina nível %d" % required
	var cost := powerup_upgrade_cost(power)
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func upgrade_powerup(power: PowerUpData) -> bool:
	if powerup_upgrade_block_reason(power) != "":
		return false
	GameManager.pay(powerup_upgrade_cost(power))
	GameManager.powerup_levels[power.id] = powerup_level(power.id) + 1
	SaveManager.save_game()
	return true


# --------------------------------------------------- escudo (seção 64)

static func shield_data() -> PowerUpData:
	return GameManager.WORLD.powerup(&"escudo")


static func shield_cost() -> Dictionary:
	return GameManager.effective_cost(shield_data().craft_cost)


static func craft_shield_block_reason() -> String:
	if GameManager.shields >= shield_data().max_stock:
		return "Estoque cheio"
	var cost := shield_cost()
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func craft_shield() -> bool:
	if craft_shield_block_reason() != "":
		return false
	GameManager.pay(shield_cost())
	GameManager.shields += 1
	SaveManager.save_game()
	return true


# ------------------------------------------------------------- componentes

## Seção 62: desmontar sucata rende componentes (o jeito de consegui-los
## antes das regiões que os têm no loot).
static func dismantle_cost() -> Dictionary:
	return GameManager.effective_cost(GameManager.SHELTER.dismantle_cost)


static func dismantle_block_reason() -> String:
	var cost := dismantle_cost()
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	if GameManager.components >= GameManager.capacity_of("components"):
		return "Depósito cheio"
	return ""


static func dismantle() -> bool:
	if dismantle_block_reason() != "":
		return false
	var gm := GameManager
	gm.pay(dismantle_cost())
	gm.components += gm.SHELTER.dismantle_amount
	SaveManager.save_game()
	return true


# ---------------------------------------------------------------- upgrades

static func track(id: StringName) -> WeaponTrack:
	return GameManager.SHELTER.weapon_track(id)


## 0 = ainda não fabricada.
static func weapon_level(id: StringName) -> int:
	return GameManager.weapon_level(id)


## Dados do próximo nível, ou null se já está no máximo.
static func next_weapon(id: StringName) -> Resource:
	var level := weapon_level(id)
	var t := track(id)
	return t.level_data(level + 1) if level < t.max_level() else null


static func weapon_cost(id: StringName) -> Dictionary:
	var next := next_weapon(id)
	return GameManager.effective_cost(next.upgrade_cost) if next else {}


static func weapon_block_reason(id: StringName) -> String:
	var next := next_weapon(id)
	if not next:
		return "Nível máximo"
	if GameManager.level_of(&"workshop") < next.required_workshop:
		return "Requer Oficina nível %d" % next.required_workshop
	var cost := weapon_cost(id)
	if not GameManager.can_afford(cost):
		return GameManager.missing_text(cost)
	return ""


static func upgrade_weapon(id: StringName) -> bool:
	if weapon_block_reason(id) != "":
		return false
	var gm := GameManager
	gm.pay(weapon_cost(id))
	gm.weapon_levels[id] = weapon_level(id) + 1
	# Arma branca nova ou melhorada sai da bancada inteira.
	if not track(id).ranged:
		gm.melee_durability[id] = gm.weapon_data(id).max_durability
	SaveManager.save_game()
	return true
