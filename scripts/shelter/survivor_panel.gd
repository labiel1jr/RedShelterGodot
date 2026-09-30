extends ShelterPanel

## Painel "Sobrevivente" (seções 42 e 43 do GDD): nível, XP, e onde gastar
## os pontos de atributo e de perk ganhos ao subir de nível.


func _ready() -> void:
	super()
	action_sound = "ui_confirm"


func _build_rows() -> void:
	var gm := GameManager
	var data := Progression.DATA

	var summary := Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	var xp_text := "nível máximo" if Progression.is_max_level() else "XP %d / %d" % [gm.xp, Progression.xp_to_next()]
	summary.text = "Nível %d  ·  %s\nPontos: %d de atributo  ·  %d de perk" % [gm.level, xp_text, gm.attribute_points, gm.perk_points]
	rows.add_child(summary)

	_add_health_rows()

	add_section("MORADORES  (%d/%d vagas)" % [gm.survivors.size(), gm.survivor_capacity()])
	if gm.survivors.is_empty():
		add_info("Ninguém ainda", "Resgate sobreviventes nas expedições (evento \"Alguém pede socorro\") e leve-os até a extração. Cada um come 1 comida e bebe 1 água por dia.")
	for info in gm.survivors:
		_add_resident(info)

	add_section("ATRIBUTOS")
	for attribute in data.attributes:
		var points: int = gm.attributes.get(attribute.id, 0)
		var detail := attribute.description
		if points > 0:
			detail += "  Agora: " + attribute.effect_text(points)
		if points < attribute.max_points:
			detail += "  →  " + attribute.effect_text(points + 1)
		add_row(
			"%s  %d/%d" % [attribute.display_name, points, attribute.max_points],
			detail,
			"1 ponto de atributo",
			"+1",
			Progression.attribute_block_reason(attribute),
			func(): return Progression.raise_attribute(attribute),
		)

	for branch in data.BRANCH_NAMES.size():
		add_section("%s  (%d pontos)" % [data.BRANCH_NAMES[branch].to_upper(), Progression.branch_points(branch)])
		for perk in data.perks:
			if perk.branch != branch:
				continue
			var rank: int = gm.perks.get(perk.id, 0)
			add_row(
				"%s  %d/%d" % [perk.display_name, rank, perk.max_rank],
				perk.description + (" por rank" if perk.max_rank > 1 else ""),
				"1 ponto de perk",
				"Aprender",
				Progression.perk_block_reason(perk),
				func(): return Progression.learn_perk(perk),
			)


## Moral do abrigo (seção 37) e Enfermaria (seção 41).
func _add_health_rows() -> void:
	var gm := GameManager
	var rules := gm.SHELTER
	add_section("SAÚDE E MORAL")

	var state := gm.morale_state()
	var morale_effects := [
		"Tudo normal",
		"Produção -%d%%" % roundi((1.0 - rules.morale_production[1]) * 100),
		"Produção -%d%%, moradores sem bônus de profissão" % roundi((1.0 - rules.morale_production[2]) * 100),
		"Produção -%d%%, moradores sem bônus e podem ir embora" % roundi((1.0 - rules.morale_production[3]) * 100),
	]
	add_info(
		"Moral do abrigo: %d/100  (%s)" % [gm.morale, ["Normal", "Atenção", "Crítica", "Esgotada"][state]],
		"%s. Sobe com refeição quente (Cozinha), Rádio, resgates e expedições com loot; cai com fome/sede, mortes e sobreviventes recusados." % morale_effects[state],
	)

	var infirmary := Infirmary.level()
	if gm.is_injured():
		add_row(
			"Tratar ferimento",
			"FERIDA: HP máximo -%d%% nas próximas %d expedições." % [roundi((1.0 - rules.wound_max_hp) * 100), gm.injured_days],
			gm.cost_text(Infirmary.wound_cost()),
			"Tratar",
			Infirmary.wound_block_reason(),
			func(): return Infirmary.treat_wound(),
		)
	var penalty := gm.start_hp_penalty(true)
	if penalty > 0:
		add_row(
			"Tratar fraqueza (fome/sede)",
			"Sem tratamento, a próxima expedição começa com -%d HP." % penalty if not gm.hunger_treated else "Tratada: a próxima expedição começa com o HP cheio.",
			gm.cost_text(Infirmary.hunger_cost()),
			"Tratar",
			Infirmary.hunger_block_reason(),
			func(): return Infirmary.treat_hunger(),
		)
	if infirmary >= 2:
		add_info(
			"Kit médico: %s" % ("pronto" if Infirmary.has_medkit() else "sem medicamentos"),
			"Na expedição, o botão KIT (ou H) cura %d HP uma vez e gasta 1 medicamento." % rules.medkit_heal,
		)
	elif infirmary == 0 and (gm.is_injured() or penalty > 0):
		add_info("Sem Enfermaria", "Construa a Enfermaria para tratar ferimentos e fraqueza com medicamentos.")


## Morador (seção 44): profissão, traço, afinidade e pedido.
func _add_resident(info: Dictionary) -> void:
	var world := GameManager.WORLD
	var profession := world.profession(info.profession)
	var t := Residents.trait_of(info)
	var affinity := int(info.affinity)
	var mult := Residents.profession_multiplier(info)
	var title := "%s  ·  %s  ·  %s  ·  afinidade %d/100" % [info.name, profession.display_name, t.display_name if t else "?", affinity]
	var detail := profession.bonus_text
	if not is_equal_approx(mult, 1.0):
		detail += "  (x%.2f: %s)" % [mult, "traço e afinidade alta" if affinity >= world.affinity_high and t and t.profession_multiplier != 1.0 else ("afinidade alta" if affinity >= world.affinity_high else "traço")]
	if t:
		detail += "\n%s: %s" % [t.display_name, t.description]
	if affinity >= world.affinity_high:
		detail += "\nAfinidade alta: bônus da profissão +%d%% e pode fazer pedidos." % roundi(world.affinity_high_bonus * 100)
	elif affinity <= world.affinity_low:
		detail += "\nAfinidade baixa: com a moral crítica, é o primeiro a ir embora."
	var request: Dictionary = info.get("request", {})
	if request.has("kind"):
		detail += "\nPEDIDO: %s. Recompensa: +%d XP, +%d moral, +%d afinidade." % [Residents.request_text(info), world.request_xp, world.request_morale, world.request_affinity]
		add_row(title, detail, "", "Entregar" if request.kind == "bring" else "Na expedição",
			Residents.deliver_block_reason(info), func(): return Residents.deliver(info))
	else:
		add_info(title, detail)
