class_name Infirmary
extends RefCounted

## Enfermaria (seção 41 do GDD): gasta medicamentos para tratar o ferimento
## de quem morreu na expedição e a fraqueza por fome/sede. O nível 2 dá um
## kit médico por expedição (usado na Run).


static func level() -> int:
	return GameManager.level_of(&"infirmary")


## Kit médico disponível na próxima expedição: Enfermaria 2 e um medicamento.
static func has_medkit() -> bool:
	return level() >= 2 and GameManager.medicine >= 1


# --------------------------------------------------------------- ferimento

static func wound_cost() -> Dictionary:
	var amount := GameManager.SHELTER.wound_treatment_medicine
	# Seção 44: o Médico(a) no abrigo economiza um medicamento.
	if GameManager.has_profession(&"medic"):
		amount = maxi(1, amount - 1)
	return {"medicine": amount}


static func wound_block_reason() -> String:
	if not GameManager.is_injured():
		return "Sem ferimento"
	if level() < 1:
		return "Requer Enfermaria"
	if not GameManager.can_afford(wound_cost()):
		return GameManager.missing_text(wound_cost())
	return ""


static func treat_wound() -> bool:
	if wound_block_reason() != "":
		return false
	GameManager.pay(wound_cost())
	GameManager.injured_days = 0
	SaveManager.save_game()
	return true


# ------------------------------------------------------------- fome e sede

static func hunger_cost() -> Dictionary:
	return {"medicine": GameManager.SHELTER.hunger_treatment_medicine}


static func hunger_block_reason() -> String:
	if GameManager.start_hp_penalty() <= 0:
		return "Sem fraqueza" if not GameManager.hunger_treated else "Já tratada"
	if level() < 1:
		return "Requer Enfermaria"
	if not GameManager.can_afford(hunger_cost()):
		return GameManager.missing_text(hunger_cost())
	return ""


static func treat_hunger() -> bool:
	if hunger_block_reason() != "":
		return false
	GameManager.pay(hunger_cost())
	GameManager.hunger_treated = true
	SaveManager.save_game()
	return true
