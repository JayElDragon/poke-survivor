extends Node2D
# Animaciones de los movimientos EVOLUCIONADOS (solo visuales; no tocan el dano).
# Cada movimiento evolucionado tiene firma propia: tipo (18 estilos de particula) x variante (3 por movimiento,
# segun su id) x clase de ataque (geometria del estallido) x paleta de dos colores. Se dibujan al lanzarlo,
# siguiendo cada proyectil/orbe y al evolucionar.

const MD = preload("res://scripts/moves_data.gd")
const LIFT := 18.0
const MAXP := 900

# segundo color por tipo
const SEC := {"fire": "#ffe066", "water": "#d4f6ff", "grass": "#e2ff9a", "electric": "#fff7b0", "ice": "#ffffff", "fighting": "#ffd6a8",
	"poison": "#f0b0ff", "ground": "#fff2c0", "flying": "#ffffff", "psychic": "#ffc8ec", "bug": "#ecffa6", "rock": "#ffffff",
	"ghost": "#e0d2ff", "dragon": "#b0c8ff", "dark": "#b88cff", "steel": "#ffffff", "fairy": "#ffffff", "normal": "#ffffff"}
# tipo -> particula por variante
const THEME := {
	"fire": ["ember", "spark", "flame"], "water": ["drop", "bubble", "ripple"], "grass": ["leaf", "leaf", "petal"],
	"electric": ["bolt", "bolt", "spark"], "ice": ["snow", "shard", "snow"], "fighting": ["impact", "ring", "impact"],
	"poison": ["bubble", "drop", "bubble"], "ground": ["chunk", "chunk", "dust"], "flying": ["feather", "crescent", "feather"],
	"psychic": ["ring", "ring", "orb"], "bug": ["dot", "dot", "leaf"], "rock": ["shard", "chunk", "shard"],
	"ghost": ["wisp", "wisp", "ring"], "dragon": ["crescent", "ember", "crescent"], "dark": ["slash", "wisp", "slash"],
	"steel": ["glint", "shard", "glint"], "fairy": ["star", "heart", "star"], "normal": ["star", "ring", "spark"],
}
const DIRKINDS := ["projectile", "cone", "beam", "melee", "dash", "boomerang", "chain", "turret"]

var main = null
var ps: Array = []          # particulas
var glyphs: Array = []      # simbolos en el suelo
var tracked: Array = []     # [nodo, firma, temporizador]
var cache := {}


func clear() -> void:
	ps.clear()
	glyphs.clear()
	tracked.clear()


# ------------------------------------------------------------------ firma de cada movimiento
func sig(m: Dictionary) -> Dictionary:
	var id: String = String(m.get("id", ""))
	if cache.has(id):
		return cache[id]
	var ty: String = String(m.get("type", "normal"))
	var h: int = absi(id.hash())
	var a := Color.html(String(MD.TYPE_COLOR.get(ty, "#b0a99f")))
	var b := Color.html(String(SEC.get(ty, "#ffffff")))
	b = b.lerp(a.lightened(0.35), float(h % 5) * 0.1)
	var th: Array = THEME.get(ty, THEME["normal"])
	var v: int = h % 3
	var s := {"ty": ty, "a": a, "b": b, "v": v, "h": h, "kind": String(m.get("kind", "")),
		"pk": String(th[v]), "pk2": String(th[(v + 1) % 3]), "size": 1.0 + float((h >> 3) % 4) * 0.18,
		"cnt": 22 + (h >> 5) % 12, "spin": 1.0 if (h >> 7) % 2 == 0 else -1.0, "pat": (h >> 9) % 6}
	cache[id] = s
	return s


func _pc(m: Dictionary) -> Vector2:
	return main.player.position + Vector2(0.0, -LIFT)


# ------------------------------------------------------------------ emision
func _add(p: Vector2, v: Vector2, life: float, size: float, k: String, c: Color, g: float = 0.0, spin: float = 0.0) -> void:
	if ps.size() >= MAXP:
		return
	ps.append({"p": p, "v": v, "t": 0.0, "l": life, "s": size, "k": k, "c": c, "g": g, "r": randf() * TAU, "w": spin, "ph": randf() * TAU})


func _pcol(sg: Dictionary) -> Color:
	return (sg["a"] as Color).lerp(sg["b"], randf() * 0.8)


func _gravity(k: String) -> float:
	match k:
		"ember", "flame", "bubble", "wisp", "orb":
			return -55.0
		"drop", "chunk", "snow", "dust":
			return 150.0 if k != "dust" else 40.0
		"leaf", "petal", "feather":
			return 20.0
	return 0.0


func _emit_kind(sg: Dictionary, k: String, p: Vector2, dir: Vector2, speed: float, size_k: float = 1.0) -> void:
	var life: float = randf_range(0.35, 0.7)
	var sz: float = float(sg["size"]) * size_k * randf_range(0.8, 1.3)
	match k:
		"bolt":
			life = randf_range(0.12, 0.22)
			sz *= 2.4
		"ring", "ripple", "crescent":
			life = randf_range(0.35, 0.55)
			sz *= 1.6
		"impact", "glint", "star", "heart":
			life = randf_range(0.3, 0.5)
			sz *= 1.5
		"slash":
			life = randf_range(0.14, 0.26)
			sz *= 2.2
	_add(p, dir * speed, life, sz * 4.2, k, _pcol(sg), _gravity(k), float(sg["spin"]) * randf_range(2.0, 7.0))


# estallido al lanzar: 6 patrones distintos (segun el movimiento) x tema del tipo
func cast(m: Dictionary) -> void:
	var sg: Dictionary = sig(m)
	var pc: Vector2 = _pc(m)
	var aim: float = main.player.aim
	var n: int = int(sg["cnt"])
	var dirv: Vector2 = Vector2.from_angle(aim)
	var pk: String = String(sg["pk"])
	var pk2: String = String(sg["pk2"])
	var reach: float = clampf(main._reach(m), 90.0, 340.0)
	match int(sg["pat"]):
		0:   # abanico hacia adelante
			for i in range(n * 2):
				var a: float = aim + randf_range(-0.6, 0.6)
				var d: float = randf_range(16.0, reach * 0.6)
				_emit_kind(sg, pk if i % 3 != 0 else pk2, pc + Vector2.from_angle(aim) * d, Vector2.from_angle(a), randf_range(60.0, 200.0), 1.3)
		1:   # onda radial doble
			for i in range(n * 2):
				var a2: float = float(i) / float(n * 2) * TAU
				_emit_kind(sg, pk, pc + Vector2.from_angle(a2) * 18.0, Vector2.from_angle(a2), 190.0, 1.3)
				if i % 2 == 0:
					_emit_kind(sg, pk2, pc + Vector2.from_angle(a2 + 0.1) * 18.0, Vector2.from_angle(a2 + 0.1), 95.0, 1.1)
		2:   # columnas que se alzan en el suelo delante
			for i in range(7):
				var cp: Vector2 = main.player.position + dirv * (40.0 + float(i) * reach * 0.12) + Vector2(randf_range(-26, 26), randf_range(-14, 14))
				for j in range(7):
					_add(cp + Vector2(randf_range(-5, 5), 0.0), Vector2(0.0, -randf_range(110.0, 260.0)), randf_range(0.4, 0.8), float(sg["size"]) * 5.0, pk if j % 2 == 0 else pk2, _pcol(sg), 40.0, float(sg["spin"]) * 3.0)
		3:   # estrella de rayos
			for ax in range(8):
				var aa: float = float(ax) / 8.0 * TAU + aim
				for j in range(5):
					_emit_kind(sg, pk if j % 2 == 0 else pk2, pc + Vector2.from_angle(aa) * (14.0 + float(j) * 16.0), Vector2.from_angle(aa), 70.0 + float(j) * 34.0, 1.4)
		4:   # doble helice hacia adelante
			for j in range(18):
				var t: float = float(j) / 18.0
				var base: Vector2 = pc + dirv * (14.0 + t * reach * 0.7)
				var off: Vector2 = Vector2(-dirv.y, dirv.x) * sin(t * 12.0) * 26.0
				_emit_kind(sg, pk, base + off, dirv, 50.0, 1.5)
				_emit_kind(sg, pk2, base - off, dirv, 50.0, 1.5)
		_:   # anillo que gira y se expande
			for j in range(n + 10):
				var a3: float = float(j) / float(n + 10) * TAU
				var ps2: Vector2 = pc + Vector2.from_angle(a3) * 30.0
				_add(ps2, Vector2.from_angle(a3 + 1.57 * float(sg["spin"])) * 130.0 + Vector2.from_angle(a3) * 70.0, randf_range(0.5, 0.8), float(sg["size"]) * 5.0, pk if j % 2 == 0 else pk2, _pcol(sg), _gravity(pk), float(sg["spin"]) * 4.0)
	# destello del tipo alrededor del jugador
	_add(pc, Vector2.ZERO, 0.28, 120.0, "flash", sg["a"], 0.0, 0.0)
	main.shake = maxf(main.shake, 1.5)
	glyphs.append({"p": main.player.position, "t": 0.0, "l": 0.8, "sg": sg, "r": 60.0 + 12.0 * float(sg["size"]), "dir": aim})


# nodo (proyectil u orbe) que deja estela con la firma del movimiento
func track(b: Node, m: Dictionary) -> void:
	if tracked.size() > 90:
		return
	tracked.append([b, sig(m), randf() * 0.05])


# al evolucionar: columna de particulas del tipo, anillos dorados y simbolo grande
func evolve_burst(m: Dictionary) -> void:
	var sg: Dictionary = sig(m)
	var pc: Vector2 = main.player.position
	for i in range(46):
		var a: float = randf() * TAU
		var rr: float = randf_range(8.0, 60.0)
		_add(pc + Vector2(cos(a) * rr, -4.0), Vector2(0.0, randf_range(-230.0, -90.0)), randf_range(0.6, 1.1), float(sg["size"]) * randf_range(2.6, 5.0),
			String(sg["pk"]) if i % 2 == 0 else String(sg["pk2"]), _pcol(sg), -20.0, float(sg["spin"]) * 3.0)
	for i in range(18):
		var a3: float = float(i) / 18.0 * TAU
		_add(pc + Vector2(0.0, -LIFT), Vector2.from_angle(a3) * 190.0, 0.7, 4.0, "glint", Color("#ffd23f"), 0.0, 0.0)
	glyphs.append({"p": pc, "t": 0.0, "l": 1.1, "sg": sg, "r": 96.0, "dir": 0.0})


# ------------------------------------------------------------------ bucle
func step(delta: float) -> void:
	var i: int = tracked.size() - 1
	while i >= 0:
		var tr: Array = tracked[i]
		var nd = tr[0]
		if not is_instance_valid(nd) or nd.is_queued_for_deletion():
			tracked.remove_at(i)
		else:
			tr[2] = float(tr[2]) - delta
			if float(tr[2]) <= 0.0:
				tr[2] = 0.02
				var sg: Dictionary = tr[1]
				var p: Vector2 = nd.position + Vector2(0.0, -LIFT)
				var back: Vector2 = Vector2.ZERO
				if "vel" in nd and (nd.vel as Vector2).length() > 1.0:
					back = -(nd.vel as Vector2).normalized()
				var side: Vector2 = Vector2(-back.y, back.x) * randf_range(-6.0, 6.0)
				_emit_kind(sg, String(sg["pk"]), p + side, back.rotated(randf_range(-0.5, 0.5)) if back != Vector2.ZERO else Vector2.from_angle(randf() * TAU), randf_range(20.0, 80.0), 1.2)
				if randf() < 0.4:
					_emit_kind(sg, String(sg["pk2"]), p + side, Vector2.from_angle(randf() * TAU), randf_range(30.0, 90.0), 1.0)
		i -= 1
	i = ps.size() - 1
	while i >= 0:
		var q: Dictionary = ps[i]
		q["t"] = float(q["t"]) + delta
		if float(q["t"]) >= float(q["l"]):
			ps.remove_at(i)
		else:
			var v: Vector2 = q["v"]
			v.y += float(q["g"]) * delta
			if String(q["k"]) == "leaf" or String(q["k"]) == "petal" or String(q["k"]) == "feather":
				v.x += sin(float(q["t"]) * 7.0 + float(q["ph"])) * 90.0 * delta
			q["v"] = v * (1.0 - 1.6 * delta)
			q["p"] = (q["p"] as Vector2) + v * delta
			q["r"] = float(q["r"]) + float(q["w"]) * delta
		i -= 1
	i = glyphs.size() - 1
	while i >= 0:
		glyphs[i]["t"] = float(glyphs[i]["t"]) + delta
		if float(glyphs[i]["t"]) >= float(glyphs[i]["l"]):
			glyphs.remove_at(i)
		i -= 1
	queue_redraw()


# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	for g in glyphs:
		_draw_glyph(g)
	for q in ps:
		_draw_p(q)


func _draw_glyph(g: Dictionary) -> void:
	var sg: Dictionary = g["sg"]
	var k: float = clampf(float(g["t"]) / float(g["l"]), 0.0, 1.0)
	var a: float = (1.0 - k) * 0.7
	var ca: Color = sg["a"]
	var cb: Color = sg["b"]
	var r: float = float(g["r"]) * (0.35 + 0.65 * sqrt(k))
	draw_set_transform((g["p"] as Vector2) + Vector2(0.0, -2.0), 0.0, Vector2(1.0, 0.5))
	var rot: float = float(sg["spin"]) * k * 2.2
	match int(sg["v"]):
		0:   # anillo y rayos
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(ca.r, ca.g, ca.b, a), 3.0)
			for i in range(8):
				var an: float = float(i) / 8.0 * TAU + rot
				draw_line(Vector2.from_angle(an) * r * 0.45, Vector2.from_angle(an) * r * 0.95, Color(cb.r, cb.g, cb.b, a), 2.0)
		1:   # espiral de puntos
			for i in range(18):
				var t2: float = float(i) / 18.0
				var an2: float = t2 * TAU * 1.6 + rot
				draw_circle(Vector2.from_angle(an2) * r * t2, 2.0 + 2.0 * (1.0 - t2), Color(ca.r, ca.g, ca.b, a * (0.4 + 0.6 * t2)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(cb.r, cb.g, cb.b, a * 0.6), 2.0)
		_:   # petalos
			for i in range(6):
				var an3: float = float(i) / 6.0 * TAU + rot
				draw_arc(Vector2.from_angle(an3) * r * 0.45, r * 0.45, an3 - 1.2, an3 + 1.2, 10, Color(ca.r, ca.g, ca.b, a), 3.0)
			draw_circle(Vector2.ZERO, r * 0.14, Color(cb.r, cb.g, cb.b, a))
	# aro dorado: marca de movimiento evolucionado
	draw_arc(Vector2.ZERO, r * 1.06, 0.0, TAU, 40, Color(1.0, 0.82, 0.25, a * 0.8), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_p(q: Dictionary) -> void:
	var k: float = float(q["t"]) / float(q["l"])
	var a: float = 1.0 - k
	var c: Color = q["c"]
	var cc := Color(c.r, c.g, c.b, a)
	var p: Vector2 = q["p"]
	var s: float = float(q["s"])
	var rot: float = float(q["r"])
	match String(q["k"]):
		"ember", "flame":
			var rr: float = s * (1.0 - k * 0.7) * 0.5
			draw_circle(p, rr * 1.5, Color(c.r, c.g, c.b, a * 0.35))
			draw_circle(p, rr, cc)
			draw_circle(p, rr * 0.45, Color(1, 1, 0.8, a))
		"spark", "glint":
			var l: float = s * (1.0 - k * 0.5)
			draw_line(p - Vector2(l, 0), p + Vector2(l, 0), cc, 2.0)
			draw_line(p - Vector2(0, l), p + Vector2(0, l), cc, 2.0)
			draw_circle(p, 1.6, Color(1, 1, 1, a))
		"drop":
			draw_line(p, p + Vector2(0, s * 0.8), cc, 3.0)
			draw_circle(p, s * 0.28, Color(1, 1, 1, a * 0.7))
		"bubble":
			draw_arc(p, s * 0.5 * (0.6 + k * 0.6), 0.0, TAU, 14, cc, 2.0)
			draw_circle(p + Vector2(-1.5, -1.5) * (s * 0.12), 1.4, Color(1, 1, 1, a))
		"ripple", "ring":
			draw_set_transform(p, 0.0, Vector2(1.0, 0.6))
			draw_arc(Vector2.ZERO, s * (0.5 + k * 1.6), 0.0, TAU, 24, cc, 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"leaf", "petal":
			var d: Vector2 = Vector2.from_angle(rot)
			var n: Vector2 = Vector2(-d.y, d.x)
			var pts := PackedVector2Array([p + d * s * 0.7, p + n * s * 0.28, p - d * s * 0.7, p - n * s * 0.28])
			draw_colored_polygon(pts, cc)
			draw_line(p - d * s * 0.6, p + d * s * 0.6, Color(1, 1, 1, a * 0.5), 1.0)
		"bolt":
			var pv: Vector2 = p
			var seed_f: float = float(q["ph"])
			for j in range(4):
				var nx: Vector2 = pv + Vector2(cos(seed_f + float(j) * 2.3) * s * 0.7, sin(seed_f * 1.7 + float(j) * 3.1) * s * 0.7)
				draw_line(pv, nx, Color(1, 1, 0.8, a), 2.5)
				draw_line(pv, nx, cc, 5.0 * 0.5)
				pv = nx
		"snow":
			for j in range(3):
				var an: float = rot + float(j) * PI / 3.0
				draw_line(p - Vector2.from_angle(an) * s * 0.5, p + Vector2.from_angle(an) * s * 0.5, cc, 2.0)
		"shard", "chunk":
			var d2: Vector2 = Vector2.from_angle(rot)
			var n2: Vector2 = Vector2(-d2.y, d2.x)
			var w: float = 0.35 if String(q["k"]) == "shard" else 0.6
			draw_colored_polygon(PackedVector2Array([p + d2 * s * 0.6, p + n2 * s * w, p - d2 * s * 0.6, p - n2 * s * w]), cc)
		"impact":
			for j in range(6):
				var an2: float = float(j) / 6.0 * TAU + rot
				draw_line(p + Vector2.from_angle(an2) * s * 0.25, p + Vector2.from_angle(an2) * s * (0.5 + 0.7 * k), cc, 2.0)
		"feather", "crescent":
			var base: float = rot
			draw_arc(p, s * (0.5 + k * 0.5), base - 0.9, base + 0.9, 10, cc, 2.5)
		"wisp", "orb":
			draw_circle(p, s * 0.45 * (1.0 - k * 0.5), Color(c.r, c.g, c.b, a * 0.55))
			draw_circle(p + Vector2(0, -s * 0.15), s * 0.22, Color(1, 1, 1, a * 0.7))
		"flash":
			draw_circle(p, s * (0.5 + k * 0.6), Color(c.r, c.g, c.b, a * 0.35))
			draw_circle(p, s * 0.3 * (1.0 - k), Color(1, 1, 1, a * 0.5))
		"dot":
			var o: Vector2 = Vector2.from_angle(rot) * s * 0.4
			draw_circle(p + o, 1.8, cc)
			draw_circle(p - o, 1.8, cc)
		"dust":
			draw_circle(p, s * 0.5 * (0.5 + k), Color(c.r, c.g, c.b, a * 0.4))
		"slash":
			var d3: Vector2 = Vector2.from_angle(rot)
			draw_line(p - d3 * s * 0.8, p + d3 * s * 0.8, Color(0.1, 0.05, 0.2, a), 4.0)
			draw_line(p - d3 * s * 0.8, p + d3 * s * 0.8, cc, 2.0)
		"star":
			var l2: float = s * (0.6 + 0.4 * sin(k * PI))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -l2), p + Vector2(l2 * 0.28, -l2 * 0.28), p + Vector2(l2, 0), p + Vector2(l2 * 0.28, l2 * 0.28), p + Vector2(0, l2), p + Vector2(-l2 * 0.28, l2 * 0.28), p + Vector2(-l2, 0), p + Vector2(-l2 * 0.28, -l2 * 0.28)]), cc)
		"heart":
			var hs: float = s * 0.3
			draw_circle(p + Vector2(-hs * 0.5, -hs * 0.3), hs * 0.6, cc)
			draw_circle(p + Vector2(hs * 0.5, -hs * 0.3), hs * 0.6, cc)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-hs * 1.05, -hs * 0.1), p + Vector2(hs * 1.05, -hs * 0.1), p + Vector2(0, hs * 1.2)]), cc)
		_:
			draw_circle(p, s * 0.3, cc)


# particulas del tipo en un punto cualquiera (habilidades de los evolucionados)
func puff(pos: Vector2, m: Dictionary, n: int = 12, up: float = 1.0) -> void:
	var sg: Dictionary = sig(m)
	for i in range(n):
		var a: float = randf() * TAU
		_add(pos + Vector2(cos(a), sin(a) * 0.5) * randf_range(2.0, 22.0), Vector2(cos(a) * 60.0, -randf_range(60.0, 200.0) * up), randf_range(0.4, 0.8),
			float(sg["size"]) * randf_range(3.0, 5.5), String(sg["pk"]) if i % 3 != 0 else String(sg["pk2"]), _pcol(sg), _gravity(String(sg["pk"])), float(sg["spin"]) * 3.0)
	_add(pos, Vector2.ZERO, 0.25, 70.0, "flash", sg["a"], 0.0, 0.0)
