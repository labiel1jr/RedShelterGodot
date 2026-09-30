class_name CampaignLog

## Registro da campanha para balanceamento: uma linha por expedição e por
## defesa em user://campaign_log.csv (separado por ";", abre no Excel).
## Começa de novo a cada jogo novo. Mostra o que entrou (loot), o que foi
## gasto (construções, Oficina, Enfermaria) e o estoque no fim do dia.

const COLUMNS: Array[String] = [
	"dia", "tipo", "regiao", "distancia", "resultado", "hp", "hp_max", "abates", "xp", "nivel",
	"loot_comida", "loot_agua", "loot_sucata", "loot_municao", "loot_componentes", "loot_medicamentos", "loot_combustivel",
	"recuperado", "municao_gasta", "portao",
	"gasto_sucata", "gasto_componentes", "gasto_energia", "gasto_medicamentos", "gasto_outros",
	"comida", "agua", "sucata", "energia", "municao", "componentes", "medicamentos", "combustivel",
	"moral", "moradores", "ferida", "dias_ate_ataque", "horda_prevista", "construcoes", "armas",
]

## Nome do arquivo em user:// (os robôs de tests/ usam um por campanha).
static var file_name := "campaign_log.csv"
## Recursos gastos desde a última linha (GameManager.pay soma aqui).
static var spent := {}


static func path() -> String:
	return UserPaths.file(file_name)


static func reset() -> void:
	spent.clear()
	if FileAccess.file_exists(path()):
		DirAccess.remove_absolute(path())


static func add_spent(cost: Dictionary) -> void:
	for key in cost:
		spent[key] = spent.get(key, 0) + cost[key]


static func record_run(run_day: int) -> void:
	var gm := GameManager
	var result := "morreu"
	if gm.last_run_survived:
		result = "antecipada" if gm.last_run_early else "ok"
	var row := {
		"tipo": "expedicao", "regiao": gm.next_region, "distancia": int(gm.next_distance), "resultado": result,
		"hp": gm.last_run_hp, "hp_max": gm.last_run_max_hp, "abates": gm.last_run_kills, "xp": gm.last_run_xp,
		"municao_gasta": gm.last_run_ammo_used,
	}
	var loot_columns := ["loot_comida", "loot_agua", "loot_sucata", "loot_municao", "loot_componentes", "loot_medicamentos", "loot_combustivel"]
	var recovered := 0
	for i in gm.LOOT_KEYS.size():
		row[loot_columns[i]] = gm.last_run_loot.get(gm.LOOT_KEYS[i], 0)
		recovered += int(gm.last_run_recovered.get(gm.LOOT_KEYS[i], 0))
	row["recuperado"] = recovered
	_write(run_day, row)


static func record_defense() -> void:
	var gm := GameManager
	var d := gm.last_defense
	_write(gm.day, {
		"tipo": "defesa", "resultado": "venceu" if d.won else "perdeu", "abates": d.kills, "xp": d.xp,
		"portao": "%d/%d" % [d.gate_hp, d.gate_max],
	})


static func _write(day: int, row: Dictionary) -> void:
	var gm := GameManager
	row["dia"] = day
	row["nivel"] = gm.level
	for key in ["scrap", "components", "energy", "medicine"]:
		row["gasto_" + {"scrap": "sucata", "components": "componentes", "energy": "energia", "medicine": "medicamentos"}[key]] = spent.get(key, 0)
	var others := 0
	for key in spent:
		if not key in ["scrap", "components", "energy", "medicine"]:
			others += spent[key]
	row["gasto_outros"] = others
	var stock_columns := ["comida", "agua", "sucata", "energia", "municao", "componentes", "medicamentos", "combustivel"]
	for i in gm.RESOURCE_KEYS.size():
		row[stock_columns[i]] = gm.get(gm.RESOURCE_KEYS[i])
	row["moral"] = gm.morale
	row["moradores"] = gm.survivors.size()
	row["ferida"] = gm.injured_days
	row["dias_ate_ataque"] = gm.days_to_attack()
	row["horda_prevista"] = gm.horde_size()
	var buildings: Array[String] = []
	for b in gm.SHELTER.buildings:
		if gm.level_of(b.id) > 0:
			buildings.append("%s%d" % [b.id, gm.level_of(b.id)])
	row["construcoes"] = " ".join(buildings)
	var weapons: Array[String] = []
	for t in gm.all_weapon_tracks():
		if gm.weapon_level(t.id) > 0:
			weapons.append("%s%d" % [t.id, gm.weapon_level(t.id)])
	row["armas"] = " ".join(weapons)
	spent.clear()

	var exists := FileAccess.file_exists(path())
	var file := FileAccess.open(path(), FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if not file:
		return
	if exists:
		file.seek_end()
	else:
		file.store_line(";".join(COLUMNS))
	var values: Array[String] = []
	for column in COLUMNS:
		values.append(str(row.get(column, "")))
	file.store_line(";".join(values))
