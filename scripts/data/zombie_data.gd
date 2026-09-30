class_name ZombieData
extends Resource

## Dados de um tipo de zumbi (seções 17 e 50 do GDD).

## GRAB: agarra e causa dano contínuo (comum, runner, blindado).
## SMASH: golpe pesado único ao encostar, sem agarrar (bruto).
## EXPLODE: explode perto da personagem ou ao morrer (explosivo).
enum Attack { GRAB, SMASH, EXPLODE }

@export var display_name := "Zumbi comum"
@export var max_hp := 100
## Distância à frente da personagem em que o zumbi a percebe (IDLE → CHASE).
## O ruído da expedição aumenta esse alcance.
@export var detect_distance := 20.0
## Velocidade em Z na perseguição (m/s). Abaixo da velocidade da personagem,
## o zumbi fica para trás e desiste depois que ela passa.
@export var chase_speed := 3.0
## Velocidade com que o zumbi se desloca de lado em direção à personagem.
@export var lateral_speed := 0.8
@export var attack := Attack.GRAB
@export var grab_damage_per_second := 8.0
@export var smash_damage := 30
@export var color := Color(0.45, 0.6, 0.35)
## Escala uniforme do zumbi (visual e colisão).
@export var size := 1.0
## Peso no sorteio entre os tipos da região.
@export var spawn_weight := 1.0
## XP dado ao ser eliminado (seção 42).
@export var xp_reward := 10
## Reduz o dano de cada golpe/tiro recebido (blindado: "pode exigir armas
## melhores"). Todo acerto causa ao menos 1.
@export var armor := 0

@export_group("Explosão")
## Distância da personagem em que o pavio acende.
@export var explode_trigger_distance := 2.5
@export var explode_fuse := 0.45
@export var explode_radius := 3.5
@export var explode_damage := 25
## Ruído da explosão (seção 34: explosão +10).
@export var explode_noise := 10.0
