extends Node

## Autoload de áudio (Fase 7). Canais Music / SFX / UI no mixer, volume vindo
## do Settings, um pool de players para efeitos (sem criar nós a cada som),
## música com crossfade e ambiente em loop. Todo botão do jogo toca o clique
## de interface sozinho.
##
## Os sons ficam em res://audio/ (sintetizados; troque os .wav por arte real
## mantendo os nomes).

const SOUNDS := [
	"shot", "empty", "swing", "hit", "crash", "explosion", "groan", "grab",
	"zombie_death", "hurt", "heartbeat", "pickup", "level_up", "extraction",
	"alarm", "ui_click", "ui_confirm", "build",
]
const LOOPS := ["music_shelter", "music_run", "wind_loop"]
const SFX_POOL_SIZE := 14

var _streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _ambient: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer
## Evita repetir o mesmo som várias vezes no mesmo instante (ex.: agarrão).
var _last_played := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")

	for sound in SOUNDS + LOOPS:
		var stream: AudioStreamWAV = load("res://audio/%s.wav" % sound)
		if sound in LOOPS or sound == "heartbeat":
			stream = stream.duplicate() as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_streams[sound] = stream

	for i in SFX_POOL_SIZE:
		_sfx_players.append(_new_player("SFX"))
	_music = _new_player("Music")
	_ambient = _new_player("Music")
	_heartbeat = _new_player("SFX")

	Settings.changed.connect(apply_volumes)
	apply_volumes()
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	# Sem isso, o stream tocando no fechamento do jogo fica "vazado".
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null


func _new_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(Settings.master_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(Settings.music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(maxf(Settings.sfx_volume, 0.0001)))


## Efeito sonoro. `pitch_jitter` varia o tom para não soar repetitivo.
func play(sound: String, volume_db := 0.0, pitch := 1.0, pitch_jitter := 0.08, min_interval := 0.04) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sound, -10.0) < min_interval:
		return
	_last_played[sound] = now
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	player.stream = _streams[sound]
	player.volume_db = volume_db
	player.pitch_scale = pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.bus = "UI" if sound.begins_with("ui_") else "SFX"
	player.play()


func play_music(sound: String, fade := 1.2) -> void:
	if _music_name == sound and _music.playing:
		return
	_music_name = sound
	var tween := create_tween()
	if _music.playing:
		tween.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tween.tween_callback(func():
		_music.stream = _streams[sound]
		_music.play()
	)
	tween.tween_property(_music, "volume_db", -6.0, fade)


func play_ambient(sound: String) -> void:
	if _ambient.playing and _ambient.stream == _streams[sound]:
		return
	_ambient.stream = _streams[sound]
	_ambient.volume_db = -10.0
	_ambient.play()


func stop_ambient() -> void:
	_ambient.stop()


## Batimento em loop enquanto o HP está crítico.
func set_heartbeat(active: bool) -> void:
	if active and not _heartbeat.playing:
		_heartbeat.stream = _streams["heartbeat"]
		_heartbeat.volume_db = -4.0
		_heartbeat.play()
	elif not active and _heartbeat.playing:
		_heartbeat.stop()


func _on_node_added(node: Node) -> void:
	# Botões com o metadado "silent" (ex.: ATACAR, que já tem o som da faca)
	# não tocam o clique.
	if node is BaseButton and not node.has_meta("silent"):
		node.pressed.connect(play.bind("ui_click", -4.0, 1.0, 0.0, 0.0))
