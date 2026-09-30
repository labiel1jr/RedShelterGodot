class_name ChunkData
extends Resource

## Um chunk artesanal de pista (seções 19, 20 e 50 do GDD). A cena contém a
## estrutura e a ambientação (camadas 1 e 4); obstáculos, loot e zumbis
## (camadas 2 e 3) são gerados nos Marker3D do nó "Rows" a partir da seed.
## Um Marker3D com o metadado "pattern" força aquele padrão (ex.: "W.W").

@export var display_name := ""
@export var scene: PackedScene
## Comprimento em metros ao longo de -Z (a cena vai de z = 0 a z = -length).
@export var length := 40.0
## Peso no sorteio da rota.
@export var weight := 1.0
## Multiplicam o peso dos padrões com loot ($) / zumbi (Z) neste chunk.
@export var loot_multiplier := 1.0
@export var zombie_multiplier := 1.0
## Pesos do loot na ordem de GameManager.LOOT_KEYS; vazio usa os da região.
@export var loot_weights := PackedFloat32Array()

@export_group("Local especial (seção 26)")
## Aviso no HUD ao se aproximar; não vazio = o chunk é um POI (raro, sorteado
## à parte dos chunks comuns da região).
@export var poi_banner := ""
@export var poi_color := Color(1.0, 0.85, 0.3)
## Conteúdo do padrão "R" neste chunk: [[tipo de loot, quantidade], ...];
## vazio usa o recurso raro padrão.
@export var cache_loot: Array = []
## Evento que sempre acontece neste chunk (ex.: horda na Casa segura).
@export var poi_event: EventData
