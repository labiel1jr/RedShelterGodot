class_name Construction
extends RefCounted

## Construir e melhorar estruturas do abrigo (seção 39 do GDD,
## ConstructionManager da seção 49). Também cobre a Mochila, que é melhorada
## na Oficina mas segue o mesmo modelo de níveis e custos.


## "" se pode melhorar; senão, o motivo (para a interface).
static func block_reason(building: BuildingData) -> String:
	var gm := GameManager
	var level := gm.level_of(building.id)
	if level >= building.max_level():
		return "Nível máximo"
	var required := building.required_workshop[level] if level < building.required_workshop.size() else 0
	if gm.level_of(&"workshop") < required:
		return "Requer Oficina nível %d" % required
	var cost := next_cost(building)
	if not gm.can_afford(cost):
		return gm.missing_text(cost)
	return ""


static func next_cost(building: BuildingData) -> Dictionary:
	var level := GameManager.level_of(building.id)
	return GameManager.effective_cost(building.costs[level]) if level < building.max_level() else {}


static func upgrade(building: BuildingData) -> bool:
	if block_reason(building) != "":
		return false
	var gm := GameManager
	gm.pay(next_cost(building))
	gm.building_levels[building.id] = gm.level_of(building.id) + 1
	SaveManager.save_game()
	return true
