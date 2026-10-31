extends RefCounted
# S57.13: invasiones = eventos de SUPERVIVENCIA con tiempo (no de recuento de derrotas). Aviso de 5 s y 60 s de oleadas acotadas.
# Sobrevivir hasta el final da UNA recompensa segun la categoria; morir antes no da nada. Los enemigos del evento van etiquetados.

const WARN := 5.0
const DURATION := 60.0
const FIRST_AT := 420.0
const GAP_MIN := 300.0
const GAP_MAX := 420.0
const TYPES := {
	"ghost": {"name": "Invasión fantasma", "types": ["ghost"], "cat": "normal", "col": "#8a7bd9"},
	"dark": {"name": "Invasión siniestra", "types": ["dark"], "cat": "normal", "col": "#7a6a8a"},
	"electric": {"name": "Invasión eléctrica", "types": ["electric"], "cat": "normal", "col": "#ffe14d"},
	"stampede": {"name": "Estampida", "types": [], "cat": "rare", "col": "#ffb347"},
	"shiny": {"name": "Invasión brillante", "types": [], "cat": "rare", "col": "#7fe8ff", "shiny": true},
	"mixed": {"name": "Invasión mixta", "types": ["ghost", "dark", "electric"], "cat": "rare", "col": "#ff8ad8"},
	"alpha": {"name": "Invasión Alfa", "types": [], "cat": "special", "col": "#ff6b6b"},
	"nightmare": {"name": "Horda de pesadilla", "types": ["ghost", "dark"], "cat": "special", "col": "#6a5acd", "night": true},
}

var m = null
var poi = null
var cur = null
var t_next := FIRST_AT
var next_id := 1
var done := {}
var log: Array = []


func active() -> bool:
	return cur != null


func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not poi._busy() and not m.shop_open and m.run_time >= FIRST_AT \
		and (poi.supply == null or not is_instance_valid(poi.supply)) and (m.kec.active == null or not is_instance_valid(m.kec.active)) \
		and m.rescue.cur == null and m.alpha.cur == null and not m.cave.active() and m.cave.cur == null


func _pick_kind() -> String:
	var ks: Array = []
	for k in TYPES.keys():
		var d: Dictionary = TYPES[k]
		if bool(d.get("night", false)) and not m.dn.is_night():
			continue
		if k == "alpha" and m.alpha.spawned >= m.alpha.MAX_PER_RUN:
			continue
		var w: int = 2 if (m.dn.is_night() and (k == "ghost" or k == "dark")) else 1
		if bool(d.get("night", false)):
			w = 3
		for i in range(w):
			ks.append(k)
	return String(ks[randi() % ks.size()])


func spawn(force: String = "") -> bool:
	if cur != null:
		return false
	var k: String = force if force != "" else _pick_kind()
	cur = {"id": next_id, "kind": k, "state": "warn", "t": WARN, "tags": [], "acc": 0.0}
	next_id += 1
	m._say(m.L.t("¡%s en camino! Sobrevive hasta que termine.") % m.L.t(String(TYPES[k]["name"])), 3.2)
	m.Aud.sfx("boss")
	log.append(["warn", k])
	return true


func _pool(k: String) -> Array:
	var want: Array = TYPES[k]["types"]
	var bag: Array = m._bag_at(m._dt())
	if want.is_empty():
		return bag
	var out: Array = []
	for d in bag:
		for t in d.get("types", []):
			if want.has(t):
				out.append(d)
				break
	return out if not out.is_empty() else bag


func _alive() -> int:
	var n := 0
	for e in cur["tags"]:
		if is_instance_valid(e) and not e.dead:
			n += 1
	return n


func update(delta: float) -> void:
	tick_ui(delta)
	if cur == null:
		t_next -= delta
		if t_next <= 0.0:
			if _spawn_ok() and spawn():
				pass
			else:
				t_next = 20.0
		return
	if m.player.dead:
		_end(false)
		return
	cur["t"] = float(cur["t"]) - delta
	match String(cur["state"]):
		"warn":
			if float(cur["t"]) <= 0.0:
				cur["state"] = "go"
				cur["t"] = DURATION
				_big(m.L.t("¡Te están invadiendo!"), m.L.t("Sobrevive hasta que se acabe el tiempo"))
				if cur["kind"] == "alpha":
					m.alpha.spawn()
				log.append(["start", cur["kind"]])
		"go":
			var cap: int = mini(10 + int(m.run_time / 120.0), 22)
			cur["acc"] = float(cur["acc"]) + delta
			if float(cur["acc"]) >= 1.1 and _alive() < cap and m.enemies.size() < m.ENEMY_CAP - 3:
				cur["acc"] = 0.0
				_spawn_one()
			if float(cur["t"]) <= 0.0:
				_end(true)


var _ui: CanvasLayer = null
var _l1: Label = null
var _l2: Label = null
var _ui_t := 0.0


# Mensaje grande al empezar la invasion (texto fijo en ingles, como pidio el diseno)
func _big(a: String, b: String) -> void:
	if _ui == null or not is_instance_valid(_ui):
		_ui = CanvasLayer.new()
		_ui.layer = 70
		m.add_child(_ui)
		_l1 = Label.new()
		_l2 = Label.new()
		for l in [_l1, _l2]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			l.add_theme_constant_override("outline_size", 10)
			_ui.add_child(l)
		_l1.add_theme_font_size_override("font_size", 54)
		_l1.add_theme_color_override("font_color", Color("#ff5a6e"))
		_l2.add_theme_font_size_override("font_size", 30)
		_l2.add_theme_color_override("font_color", Color("#ffe9a8"))
	_l1.text = a
	_l2.text = b
	_ui_t = 5.0


func tick_ui(delta: float) -> void:
	if _ui == null or not is_instance_valid(_ui):
		return
	if _ui_t > 0.0:
		_ui_t -= delta
	var al: float = clampf(minf((5.0 - _ui_t) / 0.3, _ui_t / 0.8), 0.0, 1.0) if _ui_t > 0.0 else 0.0
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	for l in [_l1, _l2]:
		l.size = Vector2(vp.x, 70)
		l.modulate.a = al
	_l1.position = Vector2(0.0, vp.y * 0.18 - (1.0 - al) * 20.0)
	_l2.position = Vector2(0.0, vp.y * 0.18 + 66.0)


func _spawn_one() -> void:
	var k: String = cur["kind"]
	var pool: Array = _pool(k)
	var e = m._spawn_one(randf() * TAU, true)
	if e == null:
		return
	# cambia la especie por una del conjunto del evento (misma escala de la partida)
	var def: Dictionary = (pool[randi() % pool.size()] as Dictionary).duplicate()
	if m._smeta.has(str(int(def.get("dex", 0)))) and int(def.get("dex", 0)) != int(e.dex):
		e.rebody(int(def["dex"]), m._sm(int(def["dex"])), false)
		e.types = (def.get("types", []) as Array).duplicate()
	if bool(TYPES[k].get("shiny", false)):
		e.set_shiny()
	if k == "stampede":
		e.spd *= 1.35
	e.set_meta("enc", "inv")
	cur["tags"].append(e)


func _end(win: bool) -> void:
	if cur == null:
		return
	var k: String = cur["kind"]
	var id: int = cur["id"]
	var tags: Array = cur["tags"]
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)
	# limpieza segura: solo los enemigos etiquetados del evento
	for e in tags:
		if is_instance_valid(e):
			m.enemies.erase(e)
			e.queue_free()
	if not win or done.has(id):
		log.append(["fail", k])
		return
	done[id] = true          # una unica recompensa por invasion
	var pos: Vector2 = m.player.position
	match String(TYPES[k]["cat"]):
		"normal":
			for i in range(24):
				m._spawn_orb(pos, "coin", 5.0)
		"rare":
			for i in range(24):
				m._spawn_orb(pos, "coin", 5.0)
			if randf() < 0.35:
				m._spawn_orb(pos, "ticket", 1.0)
		"special":
			for i in range(16):
				m._spawn_orb(pos, "coin", 5.0)
			m._spawn_orb(pos, "item", 0.0)
			m._spawn_orb(pos + Vector2(16, 0), "xpBig", ceilf(float(m._xp_for(m.player.level)) * 0.25))
	m._say(m.L.t("¡Sobreviviste a la invasión!"), 3.0)
	m.Aud.sfx("bossDown")
	log.append(["win", k])
	if m.has_method("ach_event"):
		m.ach_event("invasion", {"kind": k, "night": m.dn.is_night()})


func mark() -> Variant:
	if cur == null:
		return null
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var k: String = cur["kind"]
	var txt: String = m.L.t(String(TYPES[k]["name"])) + "  %d:%02d" % [int(ceili(float(cur["t"]))) / 60, int(ceili(float(cur["t"]))) % 60]
	if cur["state"] == "warn":
		txt = m.L.t("¡Se acerca!") + " " + txt
	return {"sp": Vector2(vp.x * 0.5, 150.0), "txt": txt, "col": Color(String(TYPES[k]["col"]))}
