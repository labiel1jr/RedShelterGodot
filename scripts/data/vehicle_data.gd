class_name VehicleData
extends Resource

## Veículo da corrida (seção 63 do GDD): aparece estacionado numa faixa e,
## montada, a personagem ganha as habilidades dele. Todo dano vai para o HP
## do veículo; quando o HP ou o tempo acaba, ela cai sem dano.

@export var id: StringName
@export var display_name := ""
## Cor do veículo e do aviso na pista.
@export var color := Color(0.9, 0.9, 0.9)
@export var max_hp := 40
## Segundos até acabar (se o HP não acabar antes).
@export var duration := 20.0
## Dica mostrada na primeira vez que monta.
@export_multiline var hint := ""

@export_group("Movimento")
@export var speed_multiplier := 1.0
@export var jump_multiplier := 1.0
@export var lane_speed_multiplier := 1.0
## Sem deslize, as placas altas obrigam a trocar de faixa.
@export var can_slide := true

@export_group("Zumbis")
## Dano no veículo quando um zumbi que agarra encosta (ele é empurrado e não
## agarra).
@export var contact_damage := 10
## Skate: atravessa os zumbis fracos (comuns e runners), derrubando-os.
@export var passes_weak_zombies := false
@export var weak_zombie_cost := 8
## Dano do encontrão nos zumbis atravessados.
@export var knock_down_damage := 40
## Patins: um agarrão derruba e quebra o veículo (e o agarrão acontece).
@export var grab_breaks := false
## Skate: o golpe do Bruto para (quebra) o veículo.
@export var smash_breaks := false

@export_group("Armas")
## Mãos ocupadas: sem arma de fogo nem arma branca (bicicleta, moto).
@export var disables_weapons := false
## Bicicleta: lançamentos de jornal (0 = não lança). Cada toque lança dois,
## um na faixa dela e outro na faixa do lado.
@export var newspapers := 0
@export var newspaper_damage := 50
@export var newspaper_cooldown := 0.4
@export var newspaper_range := 22.0
@export var newspaper_speed := 30.0
@export var newspaper_knockback := 1.2

@export_group("Mochila a jato")
## Segurar o botão faz voar; soltar plana e desce.
@export var jetpack := false
## Aceleração para cima segurando (a gravidade é 25).
@export var thrust_acceleration := 50.0
@export var max_rise_speed := 7.0
## Altura máxima do voo (m); acima de ~2,6 passa por cima de tudo.
@export var max_height := 6.0
## Fração da gravidade ao planar (soltou o botão no ar).
@export var glide_gravity := 0.35
## Calor (0–100) que sobe por segundo segurando e desce soltando. Em 100,
## a mochila explode.
@export var heat_per_second := 28.0
@export var cool_per_second := 18.0
@export var explosion_damage := 20
@export var explosion_radius := 4.0
@export var explosion_zombie_damage := 80
## Ímã: puxa o loot da faixa dela e de uma faixa ao lado.
@export var magnet_range := 14.0
@export var magnet_speed := 20.0

@export_group("Combustível")
## Moto: segundos a mais para cada unidade de combustível coletada montada.
@export var fuel_time_bonus := 0.0

@export_group("Ruído e aparecimento")
## Ruído por segundo montada (seção 34); bicicleta, skate e patins: 0.
@export var noise_per_second := 0.0
## Regiões onde aparece (vazio = todas).
@export var regions: Array[StringName] = []
## Peso no sorteio entre os veículos possíveis.
@export var spawn_weight := 1.0
@export var min_level := 1
## Só em expedições a partir desta distância.
@export var min_expedition_distance := 0.0


func can_spawn(region_id: StringName, level: int, expedition_distance: float) -> bool:
	return (regions.is_empty() or region_id in regions) and level >= min_level \
		and expedition_distance >= min_expedition_distance


## Comum e runner (agarram e não têm armadura).
static func is_weak(zombie_data: ZombieData) -> bool:
	return zombie_data.attack == ZombieData.Attack.GRAB and zombie_data.armor == 0
