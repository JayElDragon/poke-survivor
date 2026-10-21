extends RefCounted
# S57.10: cuevas pequenas de desafio con altar elemental. Oleada acotada al entrar; el altar esta inerte mientras queden enemigos
# de la oleada; al limpiarla brilla y SOLO pisarlo da la mejora (permanente durante la partida, una vez por instancia).
# Las mejoras potencian efectos de estado de los movimientos del jugador (no el dano directo ni los peligros del entorno).
# Los 18 tipos estan definidos por datos; los que no tienen efecto de estado compatible quedan PENDIENTES y no se generan.

const RAD := 150.0
const ALTAR_R := 30.0
const MAX_LV := 3
const WAVE_BASE := 8
const IDLE_LIFE := 200.0
const FIRST_AT := 240.0
const GAP_MIN := 170.0
const GAP_MAX := 260.0
const CVI = preload("res://scripts/cave_int.gd")
const ENTER_R := 42.0
const INTRO := 1.4
# "fx": efectos de estado del tipo que mejora el altar; "txt": lo que mejora (mejora de la especialidad del tipo, no de poder bruto)
const TYPES := {
	"normal": {"name": "Normal", "col": "#d8d8cc", "fx": ["conf"], "txt": "La confusión dura más y se aplica con más frecuencia."},
	"fire": {"name": "Fuego", "col": "#ff7b3d", "fx": ["burn"], "txt": "La quemadura hace más daño."},
	"water": {"name": "Agua", "col": "#4f9fe8", "fx": ["slow"], "txt": "Los enemigos mojados se ralentizan más."},
	"grass": {"name": "Planta", "col": "#6bd66b", "fx": ["sleep"], "txt": "El sueño dura más."},
	"electric": {"name": "Eléctrico", "col": "#ffe14d", "fx": ["para"], "txt": "La parálisis dura más y paraliza con más frecuencia."},
	"ice": {"name": "Hielo", "col": "#8fe3ff", "fx": ["freeze"], "txt": "La congelación dura más y congela con más frecuencia."},
	"fighting": {"name": "Lucha", "col": "#d9573f", "fx": ["slow"], "txt": "Tus golpes frenan más a los enemigos."},
	"poison": {"name": "Veneno", "col": "#c86bdc", "fx": ["poison"], "txt": "El veneno hace más daño."},
	"ground": {"name": "Tierra", "col": "#c9a35a", "fx": ["burn"], "txt": "Las arenas ardientes queman más."},
	"flying": {"name": "Volador", "col": "#8fb4ff", "fx": ["slow"], "txt": "Las ráfagas frenan más a los enemigos."},
	"psychic": {"name": "Psíquico", "col": "#ff7ad9", "fx": ["conf", "sleep"], "txt": "La confusión y el sueño duran más."},
	"bug": {"name": "Bicho", "col": "#9fd24a", "fx": ["slow"], "txt": "Los hilos y picaduras frenan más."},
	"rock": {"name": "Roca", "col": "#c8b27a", "fx": ["para"], "txt": "Los aplastamientos dejan aturdidos más tiempo."},
	"ghost": {"name": "Fantasma", "col": "#8a7bd9", "fx": ["para"], "txt": "El miedo (parálisis) dura más."},
	"dragon": {"name": "Dragón", "col": "#6b7bff", "fx": ["para"], "txt": "La parálisis dura más y paraliza con más frecuencia."},
	"dark": {"name": "Siniestro", "col": "#7a6a8a", "fx": ["sleep"], "txt": "El sueño dura más."},
	"steel": {"name": "Acero", "col": "#aab4c8", "fx": ["freeze"], "txt": "Las ralentizaciones metálicas duran más."},
	"fairy": {"name": "Hada", "col": "#ffb3e6", "fx": ["charm"], "txt": "El enamoramiento dura más."},
}
const PENDING := []

var m = null
var poi = null
var lv := {}            # efecto -> nivel acumulado (0..MAX_LV), de todos los altares reclamados
var claimed_types := {} # tipo -> veces reclamado en esta partida
var cur = null
var t_next := FIRST_AT
var next_id := 1
var done := {}
var log: Array = []


# Entrada de la cueva en el mapa base: la boca de la cueva (sprite) con el emblema del tipo encima.
class Cv extends Node2D:
	var col := Color.WHITE
	var ty := "fire"
	var state := "idle"     # idle -> wave (dentro) -> taken
	var t := 0.0
	var life := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var a: float = 1.0 if state != "taken" else 0.55
		var f: float = 0.5 + 0.5 * sin(t * 3.0)
		if state != "taken":
			draw_circle(Vector2(0, 6), 78.0 + 6.0 * f, Color(col.r, col.g, col.b, 0.12))
			draw_arc(Vector2(0, 6), 70.0 + 4.0 * f, 0, TAU, 40, Color(col.r, col.g, col.b, 0.5), 3.0)
		var mt: Texture2D = CVI.tex("mouth")
		if mt != null:
			var sz: Vector2 = mt.get_size() * 0.5
			draw_texture_rect(mt, Rect2(Vector2(-sz.x * 0.5, 40.0 - sz.y), sz), false, Color(a, a, a, 1.0))
		var at: Texture2D = CVI.tex("altar_" + ty)
		if at != null and state != "taken":
			var s2: Vector2 = at.get_size() * 0.26
			draw_texture_rect(at, Rect2(Vector2(-s2.x * 0.5, -88.0 - s2.y * 0.5 - 4.0 * f), s2), false, Color(1, 1, 1, 0.95))


func lvl(effect: String) -> int:
	return int(lv.get(effect, 0))


func ccp_add(cc: String) -> float:
	return 0.10 * float(lvl(cc)) if cc != "" else 0.0


func dot_mul(effect: String) -> float:
	return 1.0 + 0.10 * float(lvl(effect))


func dur_mul(effect: String) -> float:
	return 1.0 + 0.10 * float(lvl(effect))


func slow_mul() -> float:
	return 1.0 + 0.10 * float(lvl("slow"))


func active() -> bool:
	return cur != null and cur["node"].state == "wave"


func supported() -> Array:
	return TYPES.keys()


func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not poi._busy() and not m.shop_open and m.run_time >= FIRST_AT \
		and (poi.supply == null or not is_instance_valid(poi.supply)) and (m.kec.active == null or not is_instance_valid(m.kec.active)) \
		and m.rescue.cur == null and m.alpha.cur == null and (m.inv == null or not m.inv.active())


func spawn(force: String = "") -> bool:
	if cur != null:
		return false
	var ty: String = force
	if ty == "":
		var ks: Array = TYPES.keys()
		# prefiere tipos aun no completados y cuyo efecto no este al maximo
		var pool: Array = []
		for k in ks:
			var capped := true
			for f in TYPES[k]["fx"]:
				if lvl(String(f)) < MAX_LV:
					capped = false
			if not capped:
				pool.append(k)
				if not claimed_types.has(k):
					pool.append(k)
		if pool.is_empty():
			return false
		ty = String(pool[randi() % pool.size()])
	if not TYPES.has(ty):
		return false
	var pos: Variant = null
	for i in range(8):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(420.0, 640.0)
		if poi._ok_pos(c) and not m._blocked(c, 30.0):
			pos = c
			break
	if pos == null:
		return false
	var node := Cv.new()
	node.col = Color(String(TYPES[ty]["col"]))
	node.ty = ty
	node.position = pos
	node.z_index = -1
	node.life = IDLE_LIFE
	m.world.add_child(node)
	cur = {"id": next_id, "type": ty, "node": node, "pos": pos, "tags": [], "wave": 0}
	next_id += 1
	m._say(m.L.t("¡Una cueva de tipo %s se abre cerca!") % m.L.t(String(TYPES[ty]["name"])), 3.0)
	m.Aud.sfx("rift")
	log.append(["spawn", ty])
	return true


func _clear(taken: bool) -> void:
	if cur == null:
		return
	var node = cur["node"]
	if is_instance_valid(node):
		if taken:
			node.state = "taken"
			node.get_tree().create_timer(6.0).timeout.connect(node.queue_free)
		else:
			node.queue_free()
	for e in cur["tags"]:
		if is_instance_valid(e) and e.has_meta("enc"):
			e.remove_meta("enc")
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)


func _alive() -> int:
	var n := 0
	for e in cur["tags"]:
		if is_instance_valid(e) and not e.dead:
			n += 1
	return n


func update(delta: float) -> void:
	if cur == null:
		t_next -= delta
		if t_next <= 0.0:
			if _spawn_ok() and spawn():
				pass
			else:
				t_next = 20.0
		return
	var node = cur["node"]
	if not is_instance_valid(node):
		cur = null
		return
	if node.state == "idle":
		node.life -= delta
		if node.life <= 0.0:
			_clear(false)
			return
		var d: float = m.player.position.distance_to(cur["pos"])
		if d < ENTER_R and not m.player.dead and not m._boss_alive():
			_enter()


# Entra al interior: entorno aparte (mismo sistema que las grietas); el mundo se guarda y se restaura al salir.
func _enter() -> void:
	var node = cur["node"]
	node.state = "wave"
	var ci = CVI.new()
	ci.ty = String(cur["type"])
	ci.col = node.col
	cur["inside"] = ci
	cur["intro"] = INTRO
	cur["exit_t"] = 0.0
	log.append(["enter", cur["type"]])
	m._cave_begin(ci, String(cur["type"]))
	m._say(m.L.t("¡Desafío de cueva! Derrota a la oleada para abrir el portón."), 3.0)
	m.Aud.sfx("boss")


func update_inside(delta: float) -> void:
	if cur == null or not cur.has("inside") or not is_instance_valid(cur["inside"]):
		return
	var ci = cur["inside"]
	var pp: Vector2 = m.player.position
	match ci.state:
		"idle":
			cur["intro"] = float(cur["intro"]) - delta
			if float(cur["intro"]) <= 0.0:
				_start_wave()
		"wave":
			if _alive() == 0:
				ci.state = "ready"
				ci.open_gate()
				m._say(m.L.t("¡Oleada superada! El portón se abre: pisa el altar."), 3.0)
				m.pfx.burst(ci.position + Vector2(0.0, CVI.ALC_Y), ci.col, 28, 200.0)
				m.Aud.sfx("shinyGet")
				m.shake = maxf(m.shake, 5.0)
				log.append(["ready", cur["type"]])
		"ready":
			if ci.gate_open >= 0.95 and ci.on_altar(pp) and not done.has(cur["id"]) and not m.player.dead:
				_claim()
	# salir por la boca de la cueva (con o sin mejora)
	if String(m.ainfo.get("phase", "")) == "fight" and ci.on_exit(pp) and ci.state != "idle" and not m.player.dead:
		m.ainfo["phase"] = "lost" if ci.state != "taken" else "won"
		m.ainfo["end"] = 0.4
	elif String(m.ainfo.get("phase", "")) == "won" and ci.on_exit(pp):
		m.ainfo["end"] = minf(float(m.ainfo["end"]), 0.3)


func _start_wave() -> void:
	var ci = cur["inside"]
	ci.state = "wave"
	var n: int = mini(WAVE_BASE + int(m.run_time / 180.0), 14)
	n = maxi(mini(n, m.ENEMY_CAP - m.enemies.size() - 2), 4)
	m.cave_type = String(cur["type"])
	for i in range(n):
		var e = m._spawn_one(randf() * TAU, true)
		if e == null:
			continue
		var p := Vector2.ZERO
		for k in range(10):
			p = Vector2(randf_range(-HWX, HWX), randf_range(CVI.ALC_Y + 70.0, 150.0))
			if p.distance_to(CVI.SPAWN) > 170.0:
				break
		e.position = m._free_spot(ci.position + p, 14.0)
		e.set_meta("enc", "cave")
		cur["tags"].append(e)
	m.cave_type = ""
	if (cur["tags"] as Array).is_empty():
		ci.state = "ready"
		ci.open_gate()
	m.Aud.sfx("boss")
	log.append(["wave", cur["type"], (cur["tags"] as Array).size()])


const HWX := 340.0


func _claim() -> void:
	if done.has(cur["id"]):
		return
	done[cur["id"]] = true          # primero el estado, luego la mejora
	var ty: String = cur["type"]
	var added: Array = []
	for f in TYPES[ty]["fx"]:
		var k: String = String(f)
		if lvl(k) < MAX_LV:
			lv[k] = lvl(k) + 1
			added.append(k)
	claimed_types[ty] = int(claimed_types.get(ty, 0)) + 1
	var ci = cur["inside"]
	ci.state = "taken"
	var at: Vector2 = ci.position + CVI.ALTAR_POS + Vector2(0.0, 30.0)
	m._ring(at, 6.0, 160.0, ci.col, 0.7, 6.0)
	m.pfx.burst(at + Vector2(0, -20), ci.col, 40, 240.0)
	m.Aud.sfx("legend")
	m.shake = maxf(m.shake, 4.0)
	m._say(m.L.t("¡Altar de %s! ") % m.L.t(String(TYPES[ty]["name"])) + m.L.t(String(TYPES[ty]["txt"])), 3.6)
	log.append(["claim", ty, added])
	if m.has_method("ach_event"):
		m.ach_event("cave", {"type": ty})
	m.ainfo["phase"] = "won"
	m.ainfo["end"] = 3.0


# main llama aqui al salir del interior (_arena_end): la entrada del mapa queda gastada o se retira
func on_leave(_won: bool) -> void:
	if cur == null:
		return
	var taken: bool = done.has(cur["id"])
	cur.erase("inside")
	_clear(taken)


func mark() -> Variant:
	if cur == null or not is_instance_valid(cur["node"]) or m.arena != null:
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	var node = cur["node"]
	var nm: String = m.L.t("Cueva") + " " + m.L.t(String(TYPES[cur["type"]]["name"]))
	var st := ""
	if node.state == "idle":
		st = "%ds" % ceili(node.life)
	return {"sp": ct * ((cur["pos"] as Vector2) + Vector2(0, -90)), "txt": nm + "  " + st, "col": node.col}
