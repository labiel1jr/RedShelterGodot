extends ShelterPanel

## Painel "Construir" (seções 38 e 39 do GDD): estruturas de suporte e de
## produção, com nível, efeito atual → próximo e custo.


func _build_rows() -> void:
	var sections := {
		BuildingData.Category.SUPPORT: "SUPORTE",
		BuildingData.Category.PRODUCTION: "PRODUÇÃO",
		BuildingData.Category.DEFENSE: "DEFESA (seção 45)",
	}
	for category in sections:
		add_section(sections[category])
		for building in GameManager.SHELTER.buildings:
			if building.category == category:
				_add_building_row(building)


func _add_building_row(building: BuildingData) -> void:
	var level := GameManager.level_of(building.id)
	var maxed := level >= building.max_level()

	var title := building.display_name
	title += "  —  não construído" if level == 0 else "  —  nível %d/%d" % [level, building.max_level()]

	var detail := building.description
	if maxed:
		detail += "\nAgora: " + building.effect_text(level)
	elif level == 0:
		detail += "\nAo construir: " + building.effect_text(1)
	else:
		detail += "\n%s  →  %s" % [building.effect_text(level), building.effect_text(level + 1)]

	add_row(
		title,
		detail,
		GameManager.cost_text(Construction.next_cost(building)),
		"Máximo" if maxed else ("Construir" if level == 0 else "Melhorar"),
		Construction.block_reason(building),
		func(): return Construction.upgrade(building),
	)
