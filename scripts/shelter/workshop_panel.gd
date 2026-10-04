extends ShelterPanel

## Painel "Oficina" (seções 11, 12, 16, 32, 35 e 40 do GDD): reparar a arma
## branca, fabricar munição e componentes, fabricar e melhorar as armas e a
## mochila. A arma levada na expedição é escolhida na preparação.


func _build_rows() -> void:
	var gm := GameManager
	var knife := gm.knife()

	add_section("MANUTENÇÃO")
	add_row(
		"Reparar %s" % knife.display_name,
		"Durabilidade: %d / %d%s" % [gm.knife_durability, knife.max_durability, "  (QUEBRADA)" if gm.knife_durability <= 0 else ""],
		gm.cost_text(Workshop.repair_cost()),
		"Reparar",
		Workshop.repair_block_reason(),
		func(): return Workshop.repair(),
	)
	add_row(
		"Fabricar munição",
		"+%d balas (você tem %d). Serve para todas as armas de fogo." % [gm.SHELTER.ammo_craft_amount, gm.ammo],
		gm.cost_text(Workshop.ammo_cost()),
		"Fabricar",
		Workshop.craft_ammo_block_reason(),
		func(): return Workshop.craft_ammo(),
	)
	add_row(
		"Desmontar sucata",
		"+%d componente (você tem %d). Componentes constroem Painéis, Baterias, Enfermaria, Rádio e as armas novas." % [gm.SHELTER.dismantle_amount, gm.components],
		gm.cost_text(Workshop.dismantle_cost()),
		"Desmontar",
		Workshop.dismantle_block_reason(),
		func(): return Workshop.dismantle(),
	)

	add_section("ARMAS BRANCAS")
	for t in gm.all_weapon_tracks():
		if not t.ranged:
			_add_weapon_row(t.id)
	add_section("ARMAS DE FOGO")
	for t in gm.all_weapon_tracks():
		if t.ranged:
			_add_weapon_row(t.id)

	add_section("POWER-UPS (seção 64)")
	for power in gm.WORLD.powerups:
		if power.is_upgradable():
			_add_powerup_row(power)

	add_section("EQUIPAMENTO")
	var shield := Workshop.shield_data()
	add_row(
		shield.display_name,
		"Você tem %d (máximo %d). Leva até %d por expedição; toque duas vezes na corrida para erguer. Segura a próxima batida ou agarrão. Na morte, os levados se perdem." % [gm.shields, shield.max_stock, shield.max_per_run],
		gm.cost_text(Workshop.shield_cost()),
		"Fabricar",
		Workshop.craft_shield_block_reason(),
		func(): return Workshop.craft_shield(),
	)
	var backpack := gm.SHELTER.building(&"backpack")
	var level := gm.level_of(&"backpack")
	var maxed := level >= backpack.max_level()
	add_row(
		"Mochila  —  nível %d/%d" % [level, backpack.max_level()],
		("Capacidade: " + backpack.effect_text(level)) if maxed else ("Capacidade: %s  →  %s" % [backpack.effect_text(level), backpack.effect_text(level + 1)]),
		gm.cost_text(Construction.next_cost(backpack)),
		"Máximo" if maxed else "Melhorar",
		Construction.block_reason(backpack),
		func(): return Construction.upgrade(backpack),
	)


## O que cada nível do power-up faz.
static func powerup_level_text(power: PowerUpData, level: int) -> String:
	if power.kind == PowerUpData.Kind.CONSUMABLE:
		match level:
			1:
				return "segura uma batida ou agarrão"
			2:
				return "também empurra a faixa (%d de dano)" % power.push_damage
			_:
				return "também dá %.0f s sem dano" % power.invulnerability
	return "dura %.0f s" % power.duration(level)


func _add_powerup_row(power: PowerUpData) -> void:
	var level := Workshop.powerup_level(power.id)
	var maxed := level >= power.max_level()
	var detail := "Agora: " + powerup_level_text(power, level)
	if not maxed:
		detail += "  →  nível %d: %s" % [level + 1, powerup_level_text(power, level + 1)]
	add_row(
		"%s  —  nível %d/%d" % [power.display_name, level, power.max_level()],
		detail,
		GameManager.cost_text(Workshop.powerup_upgrade_cost(power)),
		"Máximo" if maxed else "Melhorar",
		Workshop.powerup_upgrade_block_reason(power),
		func(): return Workshop.upgrade_powerup(power),
	)


func _add_weapon_row(id: StringName) -> void:
	var t := Workshop.track(id)
	var level := Workshop.weapon_level(id)
	var next := Workshop.next_weapon(id)
	var title := ""
	var detail := ""
	if level == 0:
		title = "%s  —  não fabricada" % next.display_name
		detail = _weapon_stats(next)
	else:
		var current: Resource = t.level_data(level)
		title = "%s  (nível %d/%d)" % [current.display_name, level, t.max_level()]
		detail = _weapon_stats(current)
		if next:
			detail += "\n→ %s: %s" % [next.display_name, _weapon_stats(next)]

	add_row(
		title,
		detail,
		GameManager.cost_text(Workshop.weapon_cost(id)),
		"Fabricar" if level == 0 else ("Melhorar" if next else "Máximo"),
		Workshop.weapon_block_reason(id),
		func(): return Workshop.upgrade_weapon(id),
	)


static func _weapon_stats(weapon: Resource) -> String:
	if weapon is WeaponData:
		var combo := "/".join(PackedStringArray(Array(weapon.combo_damage).map(func(d): return str(d))))
		return "golpes %s · intervalo %.2f s · alcance %.1f m · crítico %d%% · durabilidade %d" % [
			combo, weapon.attack_cooldown, weapon.reach, int(weapon.crit_chance * 100), weapon.max_durability
		]
	var damage := "%d" % weapon.damage
	if weapon.pellets > 1:
		damage = "%d × %d chumbos" % [weapon.damage, weapon.pellets]
	elif weapon.burst > 1:
		damage = "%d × rajada de %d" % [weapon.damage, weapon.burst]
	var reach := "%.0f m" % weapon.fire_range + (" · atinge as faixas vizinhas" if weapon.spread_lanes > 0 else "")
	return "dano %s · intervalo %.2f s · alcance %s · ruído +%.0f" % [damage, weapon.fire_cooldown, reach, weapon.noise]
