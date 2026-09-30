class_name ShelterData
extends Resource

## Regras e balanceamento do abrigo (seções 32, 36-40 e 50 do GDD) num só
## lugar: construções, progressão das armas, consumo diário e custos.

@export var buildings: Array[BuildingData] = []
@export var knife_track: WeaponTrack
@export var pistol_track: WeaponTrack
## Todas as armas da Oficina (seções 11, 12 e 35): faca, facão, machado,
## katana, machado pesado, pistola, escopeta e SMG. Nível 0 = não fabricada.
@export var weapon_tracks: Array[WeaponTrack] = []

@export_group("Recursos")
## Recursos de um jogo novo.
@export var start_resources := {"food": 20, "water": 20, "scrap": 10, "energy": 0, "ammo": 24}
## Energia não tem depósito: sem Baterias, fica limitada a este valor.
@export var energy_capacity := 20
## Consumo da sobrevivente por dia (cada expedição = 1 dia).
@export var daily_food := 2
@export var daily_water := 2
## HP a menos na próxima expedição para cada recurso esgotado (comida, água).
@export var exhausted_hp_penalty := 25
## Limites dos estados da seção 37: ATENÇÃO abaixo de `warning_below`,
## CRÍTICO abaixo de `critical_below`, ESGOTADO em 0.
@export var warning_below := 10
@export var critical_below := 5

@export_group("Oficina")
## Reparo: custo a cada 10 pontos de durabilidade (arredonda para cima).
@export var repair_cost_per_10 := {"scrap": 1}
@export var repair_energy := 1
@export var ammo_craft_cost := {"scrap": 3, "energy": 2}
@export var ammo_craft_amount := 6
## Desmontar sucata em componentes (seção 62).
@export var dismantle_cost := {"scrap": 5, "energy": 1}
@export var dismantle_amount := 1

@export_group("Gerador (seção 38)")
## O nível 2 do Gerador gasta combustível por dia; sem ele, rende como o 1.
@export var generator_fuel_per_day := 1

@export_group("Moral (seção 37)")
@export_range(0, 100) var morale_start := 70
## Estados: ATENÇÃO abaixo de `morale_warning_below`, CRÍTICO abaixo de
## `morale_critical_below`, ESGOTADO abaixo de `morale_exhausted_below`.
@export var morale_warning_below := 60
@export var morale_critical_below := 35
@export var morale_exhausted_below := 15
## Produção das construções em cada estado (Normal, Atenção, Crítico, Esgotado).
@export var morale_production := PackedFloat32Array([1.0, 0.85, 0.65, 0.65])
@export var morale_extracted_with_loot := 3
@export var morale_death := -6
@export var morale_new_resident := 8
@export var morale_turned_away := -5
@export var morale_shortage := -10
## Refeição cozida: Cozinha construída e comida suficiente no dia.
@export var morale_meal := 3
## Com a moral esgotada, chance por dia de um morador ir embora.
@export_range(0.0, 1.0) var morale_leave_chance := 0.35

@export_group("Enfermaria (seção 41)")
## Expedições em que a personagem fica Ferida depois de morrer.
@export var wound_days := 1
## Fração do HP máximo enquanto Ferida.
@export var wound_max_hp := 0.8
## Medicamentos para tratar o ferimento (o Médico(a) no abrigo tira 1).
@export var wound_treatment_medicine := 2
## Medicamentos para anular a penalidade de fome/sede do dia.
@export var hunger_treatment_medicine := 1
## Kit médico da Enfermaria nível 2: HP curado, uma vez por expedição.
@export var medkit_heal := 30

@export_group("Defesa do abrigo (seção 45)")
## Primeiro ataque, intervalo entre ataques e dias de aviso antes.
@export var first_attack_day := 8
@export var attack_interval := 7
@export var attack_warning_days := 2
## Tamanho da horda: base + por dia + pelo ruído das últimas expedições.
@export var horde_base := 6
@export var horde_per_day := 0.5
@export var horde_per_noise := 0.04
@export var horde_max := 40
## Fração do dano normal que os zumbis causam no portão e nas barricadas.
@export var horde_structure_damage := 0.75
## Segundos em que a horda vai chegando (depois é lutar até o fim).
@export var horde_duration := 60.0
## Tipos de zumbi da horda e a partir de que dia aparecem (mesmo índice).
@export var horde_zombies: Array[ZombieData] = []
@export var horde_zombie_min_day := PackedInt32Array()
@export var horde_zombie_weights := PackedFloat32Array()
## Derrota: fração perdida de cada recurso do depósito.
@export_range(0.0, 1.0) var attack_loss_fraction := 0.25
@export var attack_win_morale := 5
@export var attack_loss_morale := -15
@export var attack_win_xp := 100
@export var attack_win_affinity := 5
@export var attack_loss_affinity := -5
## Torre: dano por tiro, intervalo e alcance; gasta 1 munição por tiro.
@export var tower_damage := 30
@export var tower_interval := 0.9
@export var tower_range := 32.0
## Cada Soldado(a) morador acelera as torres (ou atira do muro sem torre).
@export var soldier_fire_bonus := 0.5
## Cada morador que não é medroso reforça portão e barricadas.
@export var resident_reinforce := 0.12

@export_group("Mochila deixada na morte (seção 47)")
## Expedições em que dá para voltar e recuperar a mochila.
@export var bag_runs := 3
## Zumbis a mais perto da mochila.
@export var bag_extra_zombies := 3

@export_group("Mochila")
## Peso (kg) de cada unidade de loot, na ordem de GameManager.LOOT_KEYS:
## comida, água, sucata, munição, componentes, medicamentos, combustível.
@export var loot_weight_kg := PackedFloat32Array([1.0, 1.0, 2.0, 0.1, 1.0, 0.5, 2.0])


func weapon_track(id: StringName) -> WeaponTrack:
	for t in weapon_tracks:
		if t.id == id:
			return t
	return knife_track if id == &"knife" else (pistol_track if id == &"pistol" else null)


func building(id: StringName) -> BuildingData:
	for b in buildings:
		if b.id == id:
			return b
	return null
