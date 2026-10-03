extends ShelterPanel

## Preparar expedição (seções 25, 28 e 48 do GDD): escolher a região e a
## distância antes de partir. Regiões e distâncias longas liberam com o nível.

signal depart_requested


func _ready() -> void:
	super()
	action_sound = "ui_confirm"


func _build_rows() -> void:
	var gm := GameManager
	var world := gm.WORLD
	var region := gm.current_region()

	var summary := Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	summary.text = "Destino: %s  ·  %.0f m" % [region.display_name, gm.next_distance]
	if gm.recovering_bag:
		summary.text += "  ·  voltando ao local da morte"
	rows.add_child(summary)

	# Seção 47: mochila deixada na última morte.
	if not gm.death_bag.is_empty():
		var bag := gm.death_bag
		add_section("LOCAL DA MORTE (seção 47)")
		add_row(
			"Voltar ao local da morte",
			"Sua mochila está em %s, a %.0f m: %s.\nMesma rota da expedição em que você morreu, com mais zumbis perto da mochila. Some em %d expedição(ões)." % [
				world.region(StringName(bag.region)).display_name, bag.at, gm.bag_loot_text(), bag.runs_left
			],
			"Selecionada" if gm.recovering_bag else "",
			"Escolher",
			"",
			func(): gm.select_bag_recovery(); SaveManager.save_game(); return true,
			gm.recovering_bag,
		)

	add_section("REGIÃO")
	for r in world.regions:
		var zombie_names := PackedStringArray()
		for z in r.zombie_types:
			zombie_names.append(z.display_name.to_lower())
		var poi_names := PackedStringArray()
		for poi in r.pois:
			poi_names.append(poi.display_name)
		var unlocked := gm.is_region_unlocked(r)
		var selected := r == region and not gm.recovering_bag
		add_row(
			"%s  —  dificuldade %d/10" % [r.display_name, r.difficulty],
			"%s\nZumbis: %s\nLocais especiais possíveis: %s" % [r.description, ", ".join(zombie_names), ", ".join(poi_names) if not poi_names.is_empty() else "nenhum"],
			"Selecionada" if selected else "",
			"Escolher",
			"" if unlocked else "Requer nível %d" % r.unlock_level,
			func(): gm.next_region = r.id; gm.recovering_bag = false; SaveManager.save_game(); return true,
			selected,
		)

	add_section("DISTÂNCIA (seção 28)")
	for i in world.distances.size():
		var distance := world.distances[i]
		var selected := is_equal_approx(distance, gm.next_distance) and not gm.recovering_bag
		var max_pois := world.max_pois_for(distance)
		add_row(
			"%s  —  %.0f m" % [world.distance_names[i], distance],
			"Mais longe: mais risco e mais eventos, mas mais loot e XP. Até %d local(is) especial(is)." % max_pois,
			"Selecionada" if selected else "",
			"Escolher",
			"" if gm.is_distance_unlocked(i) else "Requer nível %d" % world.distance_unlocked_level(i),
			func(): gm.next_distance = distance; gm.recovering_bag = false; SaveManager.save_game(); return true,
			selected,
		)

	# Seção 35: uma arma branca e uma de fogo por expedição.
	for ranged in [false, true]:
		add_section("ARMA DE FOGO" if ranged else "ARMA BRANCA")
		for t in gm.all_weapon_tracks():
			if t.ranged != ranged:
				continue
			var id: StringName = t.id
			var owned := gm.owns_weapon(id)
			var data: Resource = gm.weapon_data(id)
			var selected: bool = id == (gm.equipped_gun if ranged else gm.equipped_melee)
			var detail: String = preload("res://scripts/shelter/workshop_panel.gd")._weapon_stats(data)
			if not ranged and owned:
				detail += "\nDurabilidade agora: %d / %d" % [gm.melee_durability.get(id, 0), data.max_durability]
			add_row(
				data.display_name if owned else "%s (não fabricada)" % data.display_name,
				detail,
				"Equipada" if selected else "",
				"Equipar",
				"" if owned else "Fabrique na Oficina",
				func(): gm.equip_weapon(id); SaveManager.save_game(); return true,
				selected,
			)

	# Seção 64: power-ups pagos ao partir.
	add_section("POWER-UPS DA PREPARAÇÃO (seção 64)")
	for power in world.powerups:
		if power.kind != PowerUpData.Kind.PREP:
			continue
		var cost := gm.prep_cost(power)
		var chosen := power.id in gm.prep_powerups
		var detail := power.hint.substr(power.hint.find(":") + 1).strip_edges()
		if power.prep_free_radio_level > 0:
			detail += " Com o Rádio nível %d, sai de graça." % power.prep_free_radio_level
		var power_id: StringName = power.id
		add_row(
			power.display_name,
			detail + " Pago ao partir.",
			"Levando" if chosen else gm.cost_text(cost),
			"Tirar" if chosen else "Levar",
			"" if chosen or gm.can_afford(cost) else gm.missing_text(cost),
			func():
				if power_id in gm.prep_powerups:
					gm.prep_powerups.erase(power_id)
				else:
					gm.prep_powerups.append(power_id)
				SaveManager.save_game()
				return true,
			chosen,
		)

	add_section("")
	add_row(
		"Partir para %s" % region.display_name,
		("%.0f m até a extração, pela mesma rota em que você morreu." % gm.next_distance) if gm.recovering_bag else ("%.0f m até a extração. A seed é a do campo na barra de baixo (vazio = aleatória)." % gm.next_distance),
		"",
		"PARTIR",
		"",
		func(): depart_requested.emit(); return false,
	)
