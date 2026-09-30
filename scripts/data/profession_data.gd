class_name ProfessionData
extends Resource

## Profissão de um sobrevivente (seção 44 do GDD). Cada morador soma
## `value` ao modificador `effect` (ver Progression.stat()).

@export var id: StringName
@export var display_name := ""
## Bônus para a interface, ex.: "+15 HP máximo (tratamento)".
@export var bonus_text := ""
@export var effect: StringName
@export var value := 0.0
@export var color := Color(0.8, 0.8, 0.8)
