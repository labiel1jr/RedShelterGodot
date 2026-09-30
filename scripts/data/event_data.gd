class_name EventData
extends Resource

## Evento procedural de expedição (seções 27 e 50 do GDD). O comportamento
## de cada `id` fica em ExpeditionEvents; aqui ficam textos e pesos.
## ids: horde, truck, explosion, rare_cache, survivor.

@export var id: StringName
@export var display_name := ""
## Aviso no HUD quando o evento começa, ex.: "HORDA!".
@export var banner := ""
@export var banner_color := Color(1, 0.4, 0.3)
@export var weight := 1.0
