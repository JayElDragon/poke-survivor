extends Node
# Audio de PokeSurvivor: efectos y musica pre-renderizados (res://audio/*.ogg).
# Uso: Aud.setup(self) una vez por escena; Aud.sfx("coin"); Aud.music("village").

static var inst = null
static var wanted: String = ""

const MIN_GAP := {"hit": 45, "faint": 60, "xp": 35, "coin": 50, "grass": 70, "hover": 40, "break": 60, "shot": 70}
const POOL := 14

var players: Array = []
var mus_a: AudioStreamPlayer
var mus_b: AudioStreamPlayer
var cur_is_a := true
var cache := {}
var last := {}
var cur_name := ""
var tw: Tween = null
var xp_combo := 0
var xp_t := 0.0


static func setup(from: Node) -> void:
	if inst != null and is_instance_valid(inst):
		inst.apply()
		return
	inst = (load("res://scripts/audio.gd") as GDScript).new()
	inst.name = "Aud"
	from.get_tree().root.add_child.call_deferred(inst)


static func sfx(name: String, pitch: float = 1.0) -> void:
	if inst != null and is_instance_valid(inst) and inst.is_inside_tree():
		inst.play_sfx(name, pitch)


static func shot(kind: String, type: String) -> void:
	match kind:
		"melee", "beam", "nova", "aura", "buff", "orbit":
			sfx("shot_" + kind)
		_:
			sfx("shot_" + (type if type != "" else "normal"))


static func xp() -> void:
	if inst != null and is_instance_valid(inst) and inst.is_inside_tree():
		var now: float = Time.get_ticks_msec() / 1000.0
		inst.xp_combo = mini(inst.xp_combo + 1, 24) if now - inst.xp_t < 0.45 else 0
		inst.xp_t = now
		inst.play_sfx("xp", pow(2.0, float(inst.xp_combo) / 12.0))


static func music(name: String) -> void:
	wanted = name
	if inst != null and is_instance_valid(inst) and inst.is_inside_tree():
		inst.play_music(name)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	mus_a = AudioStreamPlayer.new()
	mus_b = AudioStreamPlayer.new()
	add_child(mus_a)
	add_child(mus_b)
	apply()
	if wanted != "":
		play_music(wanted)


func _vol(key: String) -> float:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var s: Dictionary = SV.d["settings"]
	if bool(s.get("mute", false)):
		return 0.0
	return clampf(float(s["master"]) / 100.0, 0.0, 1.0) * clampf(float(s[key]) / 100.0, 0.0, 1.0)


func apply() -> void:
	if mus_a == null:
		return
	var m: float = _vol("music") * 0.75
	for p in [mus_a, mus_b]:
		if p.playing and p == _cur():
			p.volume_db = linear_to_db(maxf(m, 0.0001)) if m > 0.0 else -80.0
	if tw != null and tw.is_valid():
		return


func _cur() -> AudioStreamPlayer:
	return mus_a if cur_is_a else mus_b


func _get_stream(path: String, loop: bool) -> AudioStream:
	if cache.has(path):
		return cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s = load(path)
	if loop and s is AudioStreamOggVorbis:
		s.loop = true
	cache[path] = s
	return s


func play_sfx(name: String, pitch: float = 1.0) -> void:
	var vol: float = _vol("sfx")
	if vol <= 0.0:
		return
	var now: int = Time.get_ticks_msec()
	var key: String = "shot" if name.begins_with("shot_") else name
	if now - int(last.get(key, 0)) < int(MIN_GAP.get(key, 0)):
		return
	var st := _get_stream("res://audio/sfx_%s.ogg" % name, false)
	if st == null:
		return
	last[key] = now
	var pl: AudioStreamPlayer = null
	for p in players:
		if not p.playing:
			pl = p
			break
	if pl == null:
		return
	pl.stream = st
	pl.pitch_scale = pitch
	pl.volume_db = linear_to_db(maxf(vol * 0.9, 0.0001))
	pl.play()


# v6.2: pistas WAV con bucle exacto en el import (sin costura ni fundido). La de Halloween es el
# inicio de "Haunted House", cortado en un compas que encaja con el principio. Suena de golpe, sin fade-in.
const NO_FADE_IN := ["halloween"]


func play_music(name: String) -> void:
	if name == cur_name:
		return
	cur_name = name
	var old: AudioStreamPlayer = _cur()
	cur_is_a = not cur_is_a
	var nw: AudioStreamPlayer = _cur()
	if tw != null and tw.is_valid():
		tw.kill()
	tw = create_tween().set_parallel(true)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, 0.7)
		tw.tween_callback(old.stop).set_delay(0.75)
	if not old.playing and (name == "" or NO_FADE_IN.has(name)):
		tw.kill()   # nada que fundir: un Tween vacio da error
	if name == "":
		return
	var path := "res://audio/mus_%s.ogg" % name
	if not ResourceLoader.exists(path) and ResourceLoader.exists("res://audio/mus_%s.wav" % name):
		path = "res://audio/mus_%s.wav" % name
	var st := _get_stream(path, true)
	if st == null:
		return
	var m: float = _vol("music") * 0.75
	var full: float = linear_to_db(maxf(m, 0.0001)) if m > 0.0 else -80.0
	nw.stream = st
	if NO_FADE_IN.has(name):
		nw.volume_db = full
		nw.play()
		return
	nw.volume_db = -60.0
	nw.play()
	tw.tween_property(nw, "volume_db", full, 0.8)
