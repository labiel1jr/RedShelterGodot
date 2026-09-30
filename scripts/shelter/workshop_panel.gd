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

	add_section("EQUIPAMENTO")
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
