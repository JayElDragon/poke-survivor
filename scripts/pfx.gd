extends Node2D
# Efectos pixel art: port de js/entities/fx.js del original (particulas cuadradas,
# anillos de puntos, golpes y rayos a bloques, sprites de G.VFX). Solo visual.
const VFX = preload("res://scripts/vfx.gd")
const PX := 2.0

var dens := 1.0
var cap_parts := 1400
var cap_sprites := 320
var parts: Array = []
var sprs: Array = []
var rings: Array = []
var slashes: Array = []
var beams: Array = []


# v5.2.1: menos particulas en todo el juego para evitar lag (el nivel Alta ya no es el 100% de antes).
const BASE_CUT := 0.3   # 5.2.2: otro -50% sobre el recorte anterior (0.6)
var skip := 0.0   # fraccion de particulas sueltas que se descartan


func setup(quality_dens: float) -> void:
	dens = clampf(quality_dens * BASE_CUT, 0.1, 1.0)
	skip = clampf(1.0 - quality_dens * 0.35, 0.5, 0.85)
	cap_parts = int(450.0 * clampf(quality_dens, 0.35, 1.0))
	cap_sprites = int(100.0 * clampf(quality_dens, 0.35, 1.0))


func clear() -> void:
	parts.clear()
	sprs.clear()
	rings.clear()
	slashes.clear()
	beams.clear()


static func snap(v: float) -> float:
	return roundf(v / PX) * PX


static func step(k: float) -> float:
	return 1.0 if k > 0.66 else (0.66 if k > 0.33 else 0.33)


static func rnd(a: float, b: float) -> float:
	return randf_range(a, b)


# ---------------- creacion ----------------
func px(pos: Vector2, color: Color, vel: Vector2 = Vector2.ZERO, life: float = 0.4, size: float = 1.0, grav: float = 0.0, drag: float = 0.9) -> void:
	if parts.size() >= cap_parts or randf() < skip:
		return
	parts.append({"p": pos, "v": vel, "t": 0.0, "life": life, "c": color, "s": size * PX, "g": grav, "d": drag})


func burst(pos: Vector2, color: Color, n: int = 8, power: float = 110.0) -> void:
	var cnt: int = maxi(1, roundi(float(n) * dens))
	for i in range(cnt):
		var a: float = randf() * TAU
		var s: float = rnd(power * 0.35, power)
		px(pos, color, Vector2.from_angle(a) * s, rnd(0.22, 0.5), 2.0 if randf() < 0.35 else 1.0)


func spark(pos: Vector2, color: Color, dir: Vector2, n: int = 4) -> void:
	var cnt: int = maxi(1, roundi(float(n) * dens))
	var base: float = dir.angle()
	for i in range(cnt):
		var a: float = base + rnd(-0.9, 0.9)
		px(pos, color, Vector2.from_angle(a) * rnd(60.0, 170.0), rnd(0.14, 0.32))


func sp(shape: String, pal: String, pos: Vector2, o: Dictionary = {}) -> void:
	if sprs.size() >= cap_sprites or randf() < skip * 0.9:
		return
	sprs.append({"shape": shape, "pal": pal, "p": pos, "v": o.get("v", Vector2.ZERO), "t": 0.0, "life": float(o.get("life", 0.4)),
		"scale": float(o.get("scale", 1.0)), "ang": float(o.get("angle", 0.0)), "spin": float(o.get("spin", 0.0)),
		"g": float(o.get("grav", 0.0)), "fr": float(o.get("fr", 10.0)), "fade": bool(o.get("fade", true))})


func trail(kind: String, pal: String, pos: Vector2, vel: Vector2) -> void:
	if randf() > dens:
		return
	var back: float = (-vel).angle()
	var j := Vector2(rnd(-3.0, 3.0), rnd(-3.0, 3.0))
	var c3: Color = VFX.pc(pal, 3)
	var c2: Color = VFX.pc(pal, 2)
	match kind:
		"ember":
			px(pos + j, c3 if randf() < 0.5 else c2, Vector2(cos(back) * 30.0, -40.0), 0.35)
		"flame":
			var fc: Color = c3 if randf() < 0.5 else (c2 if randf() < 0.6 else VFX.pc(pal, 4))
			px(pos + j * 2.0, fc, Vector2(cos(back) * 18.0 + rnd(-12.0, 12.0), rnd(-70.0, -40.0)), 0.5, 2.0 if randf() < 0.5 else 1.0)
		"drip":
			px(pos + j, c3, Vector2(cos(back) * 20.0, 10.0), 0.35, 1.0, 260.0)
		"spark":
			px(pos + j * 2.0, VFX.pc(pal, 4) if randf() < 0.5 else c3, Vector2(rnd(-60.0, 60.0), rnd(-60.0, 60.0)), 0.16)
		"bubbles":
			px(pos + j, c3, Vector2(0.0, -35.0), 0.45, 2.0 if randf() < 0.3 else 1.0)
		"dirt":
			px(pos + j, c2 if randf() < 0.5 else VFX.pc(pal, 1), Vector2(cos(back) * 25.0, -20.0), 0.35, 1.0, 300.0)
		"wisp":
			px(pos + j * 2.0, VFX.pc(pal, 1) if randf() < 0.5 else c2, Vector2(0.0, -30.0), 0.5, 2.0)


func ring(pos: Vector2, r0: float, r1: float, color: Color, life: float = 0.3, width: float = 3.0) -> void:
	rings.append({"p": pos, "r0": r0, "r1": r1, "c": color, "life": life, "t": 0.0, "w": width})


# Golpe cuerpo a cuerpo. vis = VFX.for_move(...)
func slash(pos: Vector2, angle: float, radius: float, arc: float, vis: Dictionary) -> void:
	var pal: String = String(vis.get("pal", "normal"))
	var melee: String = String(vis.get("melee", ""))
	var life := 0.3 if melee == "vine" else 0.22
	slashes.append({"p": pos, "ang": angle, "r": radius, "arc": arc, "pal": pal, "t": 0.0, "life": life, "vine": melee == "vine", "seed": randf() * 100.0})
	var m: Vector2 = pos + Vector2.from_angle(angle) * radius * 0.7
	match melee:
		"impact":
			sp("impact", pal, m, {"life": 0.2, "scale": 1.5, "fr": 12.0, "fade": false})
		"jaws":
			sp("jaws", pal, m, {"life": 0.24, "scale": 1.5, "fr": 9.0, "fade": false})
		"claw":
			sp("claw", pal, m, {"life": 0.2, "scale": 1.5, "angle": angle - PI / 4.0})
		"slashx", "kick", "fist", "hammer", "xmark", "pincer":
			sp(melee, pal, m, {"life": 0.26, "scale": 2.0, "fr": 10.0, "fade": true, "spin": 0.0})
			for i in range(3):
				sp(melee, pal, pos + Vector2.from_angle(angle + rnd(-arc / 2.0, arc / 2.0)) * radius * rnd(0.55, 1.0), {"life": 0.2, "scale": 1.0, "fr": 10.0})
		"vine", "feather":
			for i in range(4):
				var a: float = angle + rnd(-arc / 2.0, arc / 2.0)
				var rr: float = radius * rnd(0.5, 1.0)
				sp("leaf", "flying" if melee == "feather" else pal, pos + Vector2.from_angle(a) * rr,
					{"v": Vector2(cos(a) * 40.0, sin(a) * 40.0 + 20.0), "life": 0.45, "spin": rnd(-8.0, 8.0), "grav": 60.0})


# (melee nuevos: ver slash_extra)
# Rayo recto. vis.beam = forma que viaja por el o "lightning".
func beam(pos: Vector2, angle: float, length: float, width: float, vis: Dictionary) -> void:
	var pal: String = String(vis.get("pal", "normal"))
	beams.append({"p": pos, "ang": angle, "len": length, "w": width, "pal": pal, "shape": String(vis.get("beam", "")), "t": 0.0, "life": 0.2, "seed": randf() * 100.0})
	var d := Vector2.from_angle(angle)
	sp("impact", pal, pos + d * 10.0, {"life": 0.12, "scale": 1.0})
	sp("impact", pal, pos + d * length, {"life": 0.18, "scale": 1.5})


# ---------------- actualizacion ----------------
func _process(delta: float) -> void:
	for i in range(parts.size() - 1, -1, -1):
		var p: Dictionary = parts[i]
		p["t"] = float(p["t"]) + delta
		if float(p["t"]) >= float(p["life"]):
			parts.remove_at(i)
			continue
		var v: Vector2 = p["v"]
		v.y += float(p["g"]) * delta
		p["p"] = Vector2(p["p"]) + v * delta
		v *= pow(float(p["d"]), delta * 60.0)
		p["v"] = v
	for i in range(sprs.size() - 1, -1, -1):
		var s: Dictionary = sprs[i]
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) >= float(s["life"]):
			sprs.remove_at(i)
			continue
		var v2: Vector2 = s["v"]
		v2.y += float(s["g"]) * delta
		s["v"] = v2
		s["p"] = Vector2(s["p"]) + v2 * delta
		s["ang"] = float(s["ang"]) + float(s["spin"]) * delta
	for arr in [rings, slashes, beams]:
		for i in range(arr.size() - 1, -1, -1):
			arr[i]["t"] = float(arr[i]["t"]) + delta
			if float(arr[i]["t"]) >= float(arr[i]["life"]):
				arr.remove_at(i)
	if parts.is_empty() and sprs.is_empty() and rings.is_empty() and slashes.is_empty() and beams.is_empty():
		if _was_empty:
			return
		_was_empty = true
	else:
		_was_empty = false
	queue_redraw()

var _was_empty := false


# ---------------- dibujo ----------------
func _rect(x: float, y: float, w: float, h: float, c: Color, a: float = 1.0) -> void:
	draw_rect(Rect2(x, y, w, h), Color(c.r, c.g, c.b, c.a * a))


func _draw() -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	for b in beams:
		_draw_beam(b, now)
	for s in slashes:
		_draw_slash(s, now)
	for r in rings:
		var k: float = float(r["t"]) / float(r["life"])
		var rad: float = lerpf(float(r["r0"]), float(r["r1"]), k)
		var n: int = maxi(10, int(ceil(rad * TAU / (PX * 2.0))))
		var size: float = PX * 2.0 if float(r["w"]) >= 4.0 else PX
		var pos: Vector2 = r["p"]
		var col: Color = r["c"]
		var a: float = step(1.0 - k)
		for i in range(n):
			var an: float = float(i) / float(n) * TAU
			_rect(snap(pos.x + cos(an) * rad), snap(pos.y + sin(an) * rad * 0.9), size, size, col, a)
	for p in parts:
		var pp: Vector2 = p["p"]
		_rect(snap(pp.x), snap(pp.y), float(p["s"]), float(p["s"]), p["c"], step(1.0 - float(p["t"]) / float(p["life"])))
	for s in sprs:
		var k2: float = 1.0 - float(s["t"]) / float(s["life"])
		VFX.draw(self, String(s["shape"]), String(s["pal"]), s["p"], float(s["ang"]), float(s["scale"]), int(float(s["t"]) * float(s["fr"])), step(k2) if bool(s["fade"]) else 1.0)


func _draw_beam(b: Dictionary, now: float) -> void:
	var k: float = 1.0 - float(b["t"]) / float(b["life"])
	var pal: String = String(b["pal"])
	var ang: float = roundf(float(b["ang"]) / (PI / 16.0)) * (PI / 16.0)
	var pos := Vector2(snap(Vector2(b["p"]).x), snap(Vector2(b["p"]).y))
	var length: float = float(b["len"])
	var width: float = float(b["w"])
	var seed_v: float = float(b["seed"])
	var al: float = step(k)
	var seg: float = PX * 2.0
	draw_set_transform(pos, ang, Vector2.ONE)
	if String(b["shape"]) == "lightning":
		var py := 0.0
		var d := 0.0
		while d < length:
			var ny: float = 0.0
			if d + seg < length:
				ny = snap((VFX.hh(int(d), int(now * 30.0), int(seed_v)) - 0.5) * width)
			var lo: float = minf(py, ny)
			var hi: float = maxf(py, ny)
			_rect(d - PX, lo - PX * 2.0, seg + PX * 2.0, hi - lo + PX * 4.0, VFX.pc(pal, 3), al)
			_rect(d, lo - PX, seg, hi - lo + PX * 2.0, VFX.pc(pal, 4), al)
			py = ny
			d += seg
	else:
		var d2 := 0.0
		while d2 < length:
			var wob: float = 0.7 + 0.3 * sin(d2 * 0.18 + now * 30.0 + seed_v)
			var hw: float = maxf(PX, snap(width / 2.0 * wob * (0.6 + 0.4 * k)))
			_rect(d2, -hw - PX, seg, hw * 2.0 + PX * 2.0, VFX.pc(pal, 1), al)
			_rect(d2, -hw, seg, hw * 2.0, VFX.pc(pal, 2), al)
			var h2: float = snap(hw * 0.55)
			_rect(d2, -h2, seg, h2 * 2.0, VFX.pc(pal, 3), al)
			_rect(d2, -PX, seg, PX * 2.0, VFX.pc(pal, 4), al)
			d2 += seg
		var shape: String = String(b["shape"])
		if shape != "":
			var gap := 26.0
			var off: float = fmod(now * 420.0, gap)
			var dd: float = off
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			while dd < length - 6.0:
				var yo: float = sin(dd * 0.3 + seed_v) * width * 0.18
				VFX.draw(self, shape, pal, pos + dir * dd + perp * yo, ang, 1.5, int(dd / gap + now * 12.0), al, false)
				dd += gap
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slash(s: Dictionary, now: float) -> void:
	var life: float = float(s["life"])
	var k: float = 1.0 - float(s["t"]) / life
	var pal: String = String(s["pal"])
	var pos: Vector2 = s["p"]
	var angle: float = float(s["ang"])
	var arc: float = float(s["arc"])
	var half: float = minf(arc, TAU) / 2.0
	var radius: float = float(s["r"])
	var r: float = radius * (0.72 + 0.28 * (1.0 - k))
	var n: int = maxi(8, int(ceil(r * half * 2.0 / PX)))
	var al: float = step(k)
	if bool(s["vine"]):
		al *= 0.55          # el arco queda de fondo; el latigo es el protagonista
	for i in range(n + 1):
		var u: float = float(i) / float(n)
		var a: float = angle - half + u * half * 2.0
		var thick: int = roundi(sin(PI * u) * 3.0 * k)
		for j in range(-1, thick + 1):
			var rr: float = r - float(j) * PX
			var ci: int = 0 if j < 0 else (4 if j == thick else (3 if j > thick / 2 else 2))
			_rect(snap(pos.x + cos(a) * rr), snap(pos.y + sin(a) * rr), PX, PX, VFX.pc(pal, ci), al)
	if bool(s["vine"]):
		_draw_whip(s, now)


# Latigo de liana: segmentos con contorno oscuro que barren el arco y terminan en una hoja.
func _draw_whip(s: Dictionary, now: float) -> void:
	var u: float = float(s["t"]) / float(s["life"])
	var pos: Vector2 = s["p"]
	var angle: float = float(s["ang"])
	var half: float = minf(float(s["arc"]), TAU) / 2.0
	var radius: float = float(s["r"])
	var sw: float = clampf(u / 0.7, 0.0, 1.0)
	sw = 1.0 - (1.0 - sw) * (1.0 - sw)
	var head: float = angle - half + sw * half * 2.0
	var reach: float = minf(1.0, u * 5.0)
	if u > 0.75:
		reach = 1.0 - (u - 0.75) / 0.25 * 0.6          # se recoge
	var al: float = 1.0 if u < 0.8 else step(1.0 - (u - 0.8) / 0.2)
	var len_px: float = radius * reach
	var steps: int = maxi(4, int(len_px / PX))
	var seed_v: float = float(s["seed"])
	var pts: Array = []
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var a: float = head - (1.0 - f) * 0.45 * (1.0 if sw < 1.0 else 0.4)
		var wob: float = sin(f * 9.0 + u * 14.0 + seed_v) * 4.5 * sin(PI * f)
		var d: float = f * len_px
		var dir := Vector2.from_angle(a)
		var perp := Vector2(-dir.y, dir.x)
		pts.append(pos + dir * d + perp * wob)
	# contorno
	for i in range(pts.size()):
		var f2: float = float(i) / float(steps)
		var w: float = PX * (2.0 if f2 < 0.55 else 1.0)
		var q: Vector2 = pts[i]
		_rect(snap(q.x) - PX, snap(q.y) - PX, w + PX * 2.0, w + PX * 2.0, VFX.pc("grass", 0), al)
	# cuerpo
	for i in range(pts.size()):
		var f3: float = float(i) / float(steps)
		var w2: float = PX * (2.0 if f3 < 0.55 else 1.0)
		var q2: Vector2 = pts[i]
		var node: bool = (i % 5) == 0
		_rect(snap(q2.x), snap(q2.y), w2, w2, VFX.pc("grass", 1 if node else 2), al)
		if not node and w2 > PX:
			_rect(snap(q2.x), snap(q2.y), PX, PX, VFX.pc("grass", 3), al)
	# punta: hoja
	if pts.size() > 1:
		var tip: Vector2 = pts[pts.size() - 1]
		var prev: Vector2 = pts[pts.size() - 2]
		VFX.draw(self, "leaf", "grass", tip, (tip - prev).angle(), 1.5, 0, al)
