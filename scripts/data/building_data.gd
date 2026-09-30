class_name BuildingData
extends Resource

## Construção do abrigo ou equipamento melhorável (seções 38, 39 e 50 do
## GDD). O nível 0 significa "não construído".

enum Category { SUPPORT, PRODUCTION, EQUIPMENT, DEFENSE }

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var category := Category.SUPPORT
@export var start_level := 0
## costs[i] = custo para ir do nível i ao nível i + 1, ex.: {"scrap": 15}.
## O tamanho define o nível máximo.
@export var costs: Array[Dictionary] = []
## Nível mínimo da Oficina para cada melhoria (mesmo índice de `costs`).
@export var required_workshop := PackedInt32Array()
## Valor do efeito em cada nível (índice = nível), ex.: água por dia.
@export var effect_values := PackedFloat32Array()
## Formato do efeito para a interface, ex.: "+%d água/dia".
@export var effect_format := ""
## Texto do efeito por nível, quando não cabe num formato (tem prioridade).
@export var effect_texts := PackedStringArray()


func max_level() -> int:
	return costs.size()


func effect_at(level: int) -> float:
	return effect_values[clampi(level, 0, effect_values.size() - 1)]


func effect_text(level: int) -> String:
	if not effect_texts.is_empty():
		return effect_texts[clampi(level, 0, effect_texts.size() - 1)]
	return effect_format % effect_at(level)
