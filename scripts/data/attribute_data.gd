class_name AttributeData
extends Resource

## Atributo da personagem (seção 42 do GDD). Cada ponto soma `value_per_point`
## ao modificador `effect` (ver Progression.stat()).

@export var id: StringName
@export var display_name := ""
@export var description := ""
@export var effect: StringName
@export var value_per_point := 0.0
@export var max_points := 10
## Formato do bônus total para a interface, ex.: "+%d HP máx.".
@export var effect_format := ""
## Multiplica o valor antes de formatar (ex.: 100 para mostrar em %).
@export var display_scale := 1.0


func effect_text(points: int) -> String:
	return effect_format % (points * value_per_point * display_scale)
