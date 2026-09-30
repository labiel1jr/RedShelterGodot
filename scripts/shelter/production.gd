class_name Production
extends RefCounted

## Fechamento do dia no abrigo (seções 37 e 38 do GDD, ProductionManager da
## seção 49): as construções produzem, a sobrevivente e os moradores
## consomem, a moral muda e o Depósito limita o estoque. Cada expedição
## conta como um dia.


static func end_of_day() -> Array[String]:
	var gm := GameManager
	var rules := gm.SHELTER
	var report: Array[String] = []
	# Pedidos cumpridos na expedição (seção 44) abrem o relatório.
	report.append_array(gm.resident_log)
	gm.resident_log.clear()

	# Produção das construções, reduzida pela moral (o perk Agricultora soma
	# em cada construção já feita).
	var bonus := Progression.stat(&"production_bonus")
	var morale_factor := gm.morale_production()
	var produced := {"energy": 0.0, "water": 0.0, "food": 0.0}
	for pair in [["energy", &"generator"], ["energy", &"solar"], ["water", &"rain_collector"], ["food", &"garden"]]:
		var building_level := gm.level_of(pair[1])
		if building_level <= 0:
			continue
		if pair[1] == &"generator" and building_level >= 2:
			# Seção 38: o nível 2 gasta combustível; sem ele, rende como o 1.
			if gm.fuel >= rules.generator_fuel_per_day:
				gm.fuel -= rules.generator_fuel_per_day
				report.append("Gerador: -%d combustível" % rules.generator_fuel_per_day)
			else:
				building_level = 1
				report.append("Gerador sem combustível: rendeu como nível 1")
		var amount: float = rules.building(pair[1]).effect_at(building_level) + bonus
		produced[pair[0]] += amount * morale_factor
	# Moradores de Agricultura produzem comida mesmo sem Horta.
	produced["food"] += Progression.stat(&"food_per_day")
	# Seção 44: medrosos cuidam da casa (comida ou água, a que estiver menor).
	var homebody := Residents.extra_production()
	if homebody > 0:
		produced["food" if gm.food <= gm.water else "water"] += homebody
	var produced_parts: Array[String] = []
	for key in produced:
		var amount := roundi(produced[key])
		if amount > 0:
			gm.set(key, gm.get(key) + amount)
			produced_parts.append("+%d %s" % [amount, gm.RESOURCE_NAMES[key].to_lower()])
	if not produced_parts.is_empty():
		var line := "Produção: " + ", ".join(produced_parts)
		if morale_factor < 1.0:
			line += "  (moral baixa: %d%%)" % roundi(morale_factor * 100)
		report.append(line)

	# Consumo da sobrevivente (o perk Ração controlada reduz) e dos
	# moradores; a Cozinha aproveita melhor a comida.
	var reduction := int(Progression.stat(&"consumption_reduction"))
	var residents := gm.survivors.size()
	var kitchen := gm.level_of(&"kitchen")
	var kitchen_saving := int(rules.building(&"kitchen").effect_at(kitchen)) if kitchen > 0 else 0
	var consumption := {
		# Egoístas comem a mais (seção 44).
		"food": maxi(0, maxi(0, rules.daily_food - reduction) + residents * gm.WORLD.survivor_daily_food + Residents.extra_food() - kitchen_saving),
		"water": maxi(0, rules.daily_water - reduction) + residents * gm.WORLD.survivor_daily_water,
	}
	var short: Array[String] = []
	for key in consumption:
		var have: int = gm.get(key)
		if have < consumption[key]:
			short.append(gm.RESOURCE_NAMES[key].to_lower())
		gm.set(key, maxi(0, have - consumption[key]))
	var consumption_line := "Consumo: -%d comida, -%d água" % [consumption.food, consumption.water]
	if kitchen_saving > 0:
		consumption_line += "  (Cozinha: -%d comida)" % kitchen_saving
	report.append(consumption_line)
	if not short.is_empty():
		report.append("Faltou %s! A próxima expedição começa com -%d HP." % [" e ".join(short), gm.start_hp_penalty(true)])

	# Moral do dia (seção 37).
	if not short.is_empty():
		gm.change_morale(rules.morale_shortage, "fome/sede")
	elif kitchen > 0:
		gm.change_morale(rules.morale_meal, "refeição quente")
	var radio := gm.level_of(&"radio")
	if radio > 0:
		gm.change_morale(int(rules.building(&"radio").effect_at(radio)), "rádio")
	gm.change_morale(Residents.daily_morale(), "otimismo")
	if not gm.morale_log.is_empty():
		report.append("Moral %d (%s): %s" % [gm.morale, _morale_name(gm.morale_state()), ", ".join(gm.morale_log)])
	gm.morale_log.clear()

	# Seção 44: afinidade, pedidos e quem vai embora com a moral baixa.
	Residents.end_of_day(not short.is_empty(), report)

	# Limites do Depósito (e da energia).
	for key in gm.RESOURCE_KEYS:
		var cap := gm.capacity_of(key)
		var have: int = gm.get(key)
		if cap >= 0 and have > cap:
			gm.set(key, cap)
			if key == "energy":
				report.append("Energia no limite (%d): %d desperdiçada" % [cap, have - cap])
			else:
				report.append("Depósito cheio: %d de %s perdidos" % [have - cap, gm.RESOURCE_NAMES[key].to_lower()])

	gm.day += 1
	# Seção 45: aviso do ataque ao abrigo.
	var days_left := gm.days_to_attack()
	if days_left <= 0:
		report.append("A HORDA CHEGOU: defenda o abrigo antes da próxima expedição (%d zumbis)." % gm.horde_size())
	elif days_left <= rules.attack_warning_days:
		report.append("Ataque ao abrigo em %d dia(s): prepare portão, barricadas, armadilhas, torres e munição." % days_left)
	return report


static func _morale_name(state: int) -> String:
	return ["normal", "atenção", "crítica", "esgotada"][state]
