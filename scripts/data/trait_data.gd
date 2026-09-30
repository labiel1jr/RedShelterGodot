class_name TraitData
extends Resource

## Traço de personalidade de um morador (seção 44 do GDD). Cada morador
## recebe um ao ser resgatado; ele muda a moral do abrigo, o bônus da
## profissão, o consumo e a produção.

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var color := Color(1, 1, 1)
## Multiplica as perdas de moral do abrigo (0.75 = perde 25% menos).
@export var morale_loss_multiplier := 1.0
## Moral somada ao abrigo por dia.
@export var daily_morale := 0
## Multiplica o bônus da profissão deste morador.
@export var profession_multiplier := 1.0
## Comida a mais que o morador come por dia.
@export var extra_food := 0
## Unidades produzidas por dia (vão para a comida ou a água, a que estiver
## menor).
@export var extra_production := 0
## Nunca vai embora por moral baixa.
@export var never_leaves := false
## Não luta na defesa do abrigo (Fase 12).
@export var avoids_defense := false
