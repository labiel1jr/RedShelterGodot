class_name RegionData
extends Resource

## Região de expedição (seções 25 e 29 do GDD): quais chunks, padrões, loot,
## zumbis e eventos o gerador pode usar.

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
## Dificuldade de 1 a 10 (seção 29), para a interface.
@export_range(1, 10) var difficulty := 1
## Nível da personagem para liberar a região.
@export var unlock_level := 1

@export var start_chunk: ChunkData
@export var end_chunk: ChunkData
@export var chunks: Array[ChunkData] = []
## Padrões de gameplay (seção 22), um caractere por faixa, esquerda → direita:
##   .  vazio      W  parede (trocar de faixa)   L  barreira baixa (pular)
##   H  barra alta (deslizar)   $  loot   Z  zumbi
## Cada padrão precisa de ao menos uma faixa passável sem lutar (. $ L H).
## Repetir um padrão na lista aumenta a chance dele.
@export var patterns := PackedStringArray()
## Pesos do loot na ordem de GameManager.LOOT_KEYS (comida, água, sucata,
## munição, componentes, medicamentos, combustível).
@export var loot_weights := PackedFloat32Array([1.0, 1.0, 1.0, 0.6])
## Unidades a mais em cada loot (regiões mais ricas).
@export var loot_amount_bonus := 0
@export var zombie_types: Array[ZombieData] = []
## Peso de cada tipo (mesmo índice de zombie_types); vazio usa o
## spawn_weight de cada ZombieData.
@export var zombie_weights := PackedFloat32Array()

@export_group("Luz e atmosfera (seção 65)")
## Céu e névoa (a névoa esconde o fim da pista carregada).
@export var sky_color := Color(0.42, 0.4, 0.42)
## Luz ambiente: no cel-shading é a cor da sombra.
@export var ambient_color := Color(0.6, 0.58, 0.6)
@export var ambient_energy := 0.6
@export var sun_color := Color(1, 1, 1)
@export var sun_energy := 1.0

@export_group("Obstáculos próprios (vazio = os padrões)")
@export var wall_scene: PackedScene
@export var low_scene: PackedScene
@export var high_scene: PackedScene

@export_group("Locais especiais (seção 26)")
@export var pois: Array[ChunkData] = []
## Chance de cada chunk do meio virar um POI (até o limite da distância).
@export_range(0.0, 1.0) var poi_chance := 0.07

@export_group("Eventos (seção 27)")
## Chance de cada chunk do meio da rota ter um evento.
@export_range(0.0, 1.0) var event_chance := 0.25
@export var events: Array[EventData] = []


## Aplica céu, névoa, sombra e sol da região na cena (corrida e defesa).
func apply_atmosphere(environment: Environment, sun: DirectionalLight3D) -> void:
	environment.background_color = sky_color
	environment.fog_light_color = sky_color
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy
	if sun:
		sun.light_color = sun_color
		sun.light_energy = sun_energy
