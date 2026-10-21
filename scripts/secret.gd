extends RefCounted
# S57.15 y S57.16: secretos (claro oculto, runas, secreto lunar, nido secreto) y mecanismos elementales.
# Los mecanismos SOLO se activan al ser GOLPEADOS por un movimiento real del tipo exigido (proyectil o area), nunca por cercania.
# Todo es opcional; ningun secreto exige un tipo concreto para progresar. Un solo cobro por instancia, estado antes del premio.

const FIRST_AT := 150.0
const GAP_MIN := 130.0
const GAP_MAX := 210.0
const MAX_SITES := 3
const MAX_PER_RUN := 10
const MECH := {
	"fire": {"name": "Antorcha ancestral", "col": "#ff7b3d"},
	"water": {"name": "Fuente hidráulica", "col": "#4f9fe8"},
	"electric": {"name": "Generador antiguo", "col": "#ffe14d"},
	"psychic": {"name": "Sello de ilusión", "col": "#ff7ad9"},
	"ice": {"name": "Sello de hielo", "col": "#8fe3ff"},
	"grass": {"name": "Raíces mágicas", "col": "#6bd66b"},
	"ghost": {"name": "Marca espectral", "col": "#8a7bd9"},
	"fairy": {"name": "Cristal encantado", "col": "#ffb3e6"},
	"dragon": {"name": "Sello dracónico", "col": "#6b7bff"},
	"rock": {"name": "Mecanismo de piedra", "col": "#c9a35a"},
	"ground": {"name": "Mecanismo de piedra", "col": "#c9a35a"},
}

var m = null
var poi = null
var sites: Array = []
var t_next := FIRST_AT
var next_id := 1
var total := 0
var discovered := 0
var done := {}
var log: Array = []


class Site extends Node2D:
	var kind := "clearing"
	var col := Color.WHITE
	var shown := false
	var lit := false
	var t := 0.0
	var seq: Array = []
	var runes: Array = []
	var nxt := 0
	var actor = null
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if kind == "mech":
			draw_rect(Rect2(-9, -34, 18, 36), Color(0.22, 0.22, 0.28))
			draw_rect(Rect2(-7, -32, 14, 12), col if lit else col.darkened(0.6))
			if lit:
				draw_rect(Rect2(-9, -34, 18, 3), Color(1, 1, 1, 0.5 + 0.3 * sin(t * 6.0)))
			return
		if not shown:
			# pista sutil antes de descubrirlo: un destello tenue
			if kind != "runic" and kind != "nest":
				draw_circle(Vector2(0, -6), 3.0, Color(1, 1, 1, 0.10 + 0.08 * sin(t * 3.0)))
			if kind != "runic":
				return
		if kind == "clearing":
			draw_circle(Vector2(0, 0), 46.0, Color(0.2, 0.5, 0.25, 0.30))
			draw_circle(Vector2(0, -8), 10.0, Color("#ffd23f"))
			draw_circle(Vector2(0, -8), 18.0 + 3.0 * sin(t * 4.0), Color(1, 0.85, 0.3, 0.25))
		elif kind == "moon":
			draw_circle(Vector2(0, -10), 30.0 + 4.0 * sin(t * 3.0), Color(0.6, 0.7, 1.0, 0.25))
			draw_circle(Vector2(0, -10), 11.0, Color("#cfe0ff"))
			draw_circle(Vector2(4, -13), 9.0, Color(0.1, 0.12, 0.3, 0.9))
		elif kind == "runic":
			for r in runes:
				var rp: Vector2 = r["pos"]
				var done_r: bool = int(r["n"]) < nxt
				var c: Color = Color("#6bd66b") if done_r else Color("#b57bff")
				draw_rect(Rect2(rp - Vector2(18, 18), Vector2(36, 36)), Color(c.r, c.g, c.b, 0.25))
				draw_rect(Rect2(rp - Vector2(18, 18), Vector2(36, 36)), c, false, 3.0)
				# numero con trazos (1, 2, 3 como marcas)
				for q in range(int(r["n"]) + 1):
					draw_rect(Rect2(rp + Vector2(-10 + 9 * q, -9), Vector2(5, 18)), c)
		elif kind == "nest":
			draw_circle(Vector2(0, 2), 22.0, Color(0.45, 0.32, 0.2))
			draw_circle(Vector2(0, 0), 16.0, Color(0.6, 0.45, 0.28))


func _ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and m.arena == null and not m.poi._busy() and not m.shop_open \
		and not m.cave.active() and not m.inv.active() and m.run_time >= FIRST_AT


func _pos() -> Variant:
	for i in range(10):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(380.0, 700.0)
		if m.poi._ok_pos(c) and not m._blocked(c, 30.0):
			var far := true
			for s in sites:
				if is_instance_valid(s) and s.position.distance_to(c) < 260.0:
					far = false
			if far:
				return c
	return null


func _player_types() -> Array:
	var out: Array = []
	for mv in m.player.moves:
		var t: String = String(mv.get("type", ""))
		if MECH.has(t) and not out.has(t):
			out.append(t)
	return out


func spawn(force: String = "") -> bool:
	if sites.size() >= MAX_SITES or total >= MAX_PER_RUN:
		return false
	var pos: Variant = _pos()
	if pos == null:
		return false
	var k: String = force
	if k == "":
		var ks: Array = ["clearing", "runic", "nest", "mech", "mech", "moon"]
		k = String(ks[randi() % ks.size()])
	var s := Site.new()
	s.kind = k
	s.position = pos
	m.world.add_child(s)
	var id: int = next_id
	next_id += 1
	s.set_meta("id", id)
	match k:
		"runic":
			s.shown = true
			var order: Array = [0, 1, 2]
			order.shuffle()
			for i in range(3):
				s.runes.append({"pos": Vector2.from_angle(TAU * float(i) / 3.0 - PI * 0.5) * 70.0, "n": int(order[i])})
		"nest":
			var bag: Array = m._bag_at(m._dt())
			var d: Dictionary = bag[randi() % bag.size()]
			var dex: int = int(d["dex"])
			if m._smeta.has(str(dex)):
				var a = m.Actor.new()
				a.setup(dex, m._sm(dex), m.flash_shader, 1.0)
				a.position = Vector2(0, -2)
				s.add_child(a)
				s.actor = a
				if a.has_anim("Faint"):
					a.play("Faint", 1.0, true)
		"mech":
			var pts: Array = _player_types()
			var ty: String = ""
			if not pts.is_empty() and randf() < 0.75:
				ty = String(pts[randi() % pts.size()])
			else:
				var ks2: Array = MECH.keys()
				ty = String(ks2[randi() % ks2.size()])
			s.set_meta("mtype", ty)
			s.col = Color(String(MECH[ty]["col"]))
			s.shown = true
		"moon":
			s.shown = false
	sites.append(s)
	total += 1
	log.append(["spawn", k])
	return true


func _reward(pos: Vector2, big: bool = false) -> void:
	var r: float = randf()
	if r < 0.45:
		for i in range(12 if not big else 20):
			m._spawn_orb(pos, "coin", 5.0)
	elif r < 0.75:
		for i in range(4):
			m._spawn_orb(pos, "xpBig", ceilf(float(m._xp_for(m.player.level)) * 0.05))
	elif r < 0.90:
		m._spawn_orb(pos, "heal", 0.0)
		for i in range(6):
			m._spawn_orb(pos, "coin", 5.0)
	else:
		m._spawn_orb(pos, "ticket", 1.0)
	m.pfx.burst(pos + Vector2(0, -16), Color("#ffd23f"), 24, 170.0)
	m.Aud.sfx("shinyGet")


func _claim(s, kind_label: String) -> void:
	var id: int = int(s.get_meta("id"))
	if done.has(id):
		return
	done[id] = true          # estado antes del premio
	discovered += 1
	_reward(s.position, kind_label == "runic")
	m._say(m.L.t("¡Secreto descubierto!"), 2.2)
	log.append(["claim", kind_label])
	if m.has_method("ach_event"):
		m.ach_event("secret", {"kind": kind_label, "n": discovered})
	sites.erase(s)
	if kind_label == "nest" and s.actor != null:
		s.actor.loop_anim("Idle", 1.0)
		var tw: Tween = s.create_tween()
		tw.tween_interval(1.4)
		tw.tween_property(s, "modulate:a", 0.0, 0.5)
		tw.tween_callback(s.queue_free)
	elif kind_label == "mech":
		var tw2: Tween = s.create_tween()
		tw2.tween_interval(5.0)
		tw2.tween_property(s, "modulate:a", 0.0, 0.6)
		tw2.tween_callback(s.queue_free)
	else:
		s.queue_free()


# Llamada por main cuando un movimiento real golpea: pos, radio y tipo del movimiento.
func hit(pos: Vector2, rad: float, mtype: String) -> void:
	for s in sites:
		if not is_instance_valid(s) or s.kind != "mech" or s.lit:
			continue
		if String(s.get_meta("mtype")) != mtype and not (mtype == "ground" and String(s.get_meta("mtype")) == "rock") and not (mtype == "rock" and String(s.get_meta("mtype")) == "ground"):
			continue
		if s.position.distance_to(pos) < rad + 22.0:
			s.lit = true                 # primero activar (evita duplicados por ticks simultaneos)
			m._ring(s.position, 4.0, 90.0, s.col, 0.5, 4.0)
			_claim(s, "mech")
			return


func update(delta: float) -> void:
	t_next -= delta
	if t_next <= 0.0:
		if _ok() and spawn():
			t_next = randf_range(GAP_MIN, GAP_MAX)
		else:
			t_next = 20.0
	var pp: Vector2 = m.player.position
	for s in sites.duplicate():
		if not is_instance_valid(s):
			sites.erase(s)
			continue
		var d: float = s.position.distance_to(pp)
		match s.kind:
			"clearing":
				if not s.shown and d < 150.0:
					s.shown = true
					m._say(m.L.t("Has encontrado un claro oculto."), 2.0)
				if s.shown and d < 36.0:
					_claim(s, "clearing")
			"moon":
				if m.dn.is_night():
					s.shown = true        # una vez revelado, permanece accesible tras el amanecer
				if s.shown and d < 40.0:
					_claim(s, "moon")
			"nest":
				if d < 70.0:
					s.shown = true
					_claim(s, "nest")
			"runic":
				for r in s.runes:
					if int(r["n"]) == s.nxt and (s.position + (r["pos"] as Vector2)).distance_to(pp) < 24.0:
						s.nxt += 1
						m.Aud.sfx("confirm")
						break
				# pisar una runa equivocada reinicia la secuencia (sin castigo)
				for r in s.runes:
					if int(r["n"]) > s.nxt and (s.position + (r["pos"] as Vector2)).distance_to(pp) < 20.0 and s.nxt > 0:
						s.nxt = 0
						m._say(m.L.t("La secuencia se reinicia."), 1.4)
						break
				if s.nxt >= 3:
					_claim(s, "runic")
			"mech":
				pass
		# los sitios no reclamados caducan lejos de la partida (se recolocan solos mas adelante)
		if d > 2400.0:
			sites.erase(s)
			s.queue_free()


func mark() -> Variant:
	return null
