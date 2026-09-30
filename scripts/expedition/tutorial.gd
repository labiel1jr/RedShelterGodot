extends Node

## Tutorial contextual da expedição (Fase 7): cada dica aparece uma única
## vez, na hora em que a situação acontece (ver Settings.should_show_hint).

const HINTS := {
	&"lanes": "Deslize para os lados (ou ← → / A D) para trocar de faixa.",
	&"obstacle_wall": "Parede vermelha à frente: troque de faixa!",
	&"obstacle_low": "Barreira baixa: PULE — deslize para cima (↑ / Espaço).",
	&"obstacle_high": "Barra alta: DESLIZE — deslize para baixo (↓ / Ctrl).",
	&"zombie": "Zumbi à frente! Toque na tela, clique ou K para atirar — a pistola mira sozinha.",
	&"grab": "AGARRADA! Use a faca: botão ATACAR ou F / J. A pistola não mira em quem agarra.",
	&"loot": "Pegue os cubos coloridos: comida, água, sucata, munição — e os raros: componentes (ciano), remédios (branco), combustível (vermelho).",
	&"backpack": "Mochila quase cheia: o que não couber fica na pista.",
	&"noise": "Tiros fazem RUÍDO e atraem mais zumbis. A faca é silenciosa.",
	&"extraction": "O portão verde de EXTRAÇÃO está perto — chegue vivo nele!",
	&"critical": "HP crítico! Evite obstáculos e zumbis; no abrigo você se recupera.",
	&"fork": "BIFURCAÇÃO! A placa mostra o que há em cada lado. A faixa em que você estiver quando a divisória começar decide o caminho.",
	&"medkit": "Use o KIT médico (botão KIT ou H): cura uma vez por expedição.",
	&"wounded": "Você está FERIDA: HP máximo menor. Trate na Enfermaria com medicamentos.",
}
## Distância à frente em que um obstáculo/zumbi/loot dispara a dica.
const LOOKAHEAD := 20.0

var _run: Node
var _player: Node3D
var _elapsed := 0.0


func _ready() -> void:
	_run = get_parent()


func _process(delta: float) -> void:
	if _run.run_ended or not Settings.tutorial_enabled:
		return
	_player = _run.player
	_elapsed += delta

	if _elapsed > 1.2:
		_try(&"lanes")
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if _ahead_in_lane(obstacle, LOOKAHEAD):
			_try(StringName("obstacle_" + String(obstacle.kind)))
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if zombie.is_alive() and _ahead(zombie, 28.0):
			_try(&"zombie")
			break
	if _run.player_combat.is_grabbed():
		_try(&"grab")
	if _run.carried_weight() >= _run.backpack_capacity() * 0.8:
		_try(&"backpack")
	if _run.noise >= 4.0:
		_try(&"noise")
	if _run.extraction_distance - _run.distance_travelled() < 60.0:
		_try(&"extraction")
	var health: Node = _run.player_health
	if health.current_hp > 0 and float(health.current_hp) / health.max_hp < 0.3:
		_try(&"critical")
	if _run.medkit_available and not _run.medkit_used and health.current_hp > 0 and float(health.current_hp) / health.max_hp < 0.5:
		_try(&"medkit")
	for fork in _run.chunk_streamer.forks:
		if fork.decision_distance - _run.distance_travelled() < 55.0 and fork.decision_distance > _run.distance_travelled():
			_try(&"fork")
	if _elapsed > 6.0 and GameManager.is_injured():
		_try(&"wounded")


func _try(id: StringName) -> void:
	if Settings.should_show_hint(id):
		_run.hud.show_hint(HINTS[id])


func _ahead(node: Node3D, max_distance: float) -> bool:
	var ahead := _player.global_position.z - node.global_position.z
	return ahead > 2.0 and ahead < max_distance


func _ahead_in_lane(node: Node3D, max_distance: float) -> bool:
	return _ahead(node, max_distance) and absf(node.global_position.x - _player.global_position.x) < 1.2
