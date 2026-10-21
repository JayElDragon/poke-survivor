extends RefCounted
# Maquina Gachapon: logica de desbloqueo + dibujo (maquina, monedas, capsulas y discos MT) y animacion.
const DATA := preload("res://scripts/gachapon_data.gd")
const MD := preload("res://scripts/moves_data.gd")
const SV := preload("res://scripts/save_data.gd")


static func unlocked() -> Array:
	if not SV.d.has("gp_moves") or not (SV.d["gp_moves"] is Array):
		SV.d["gp_moves"] = []
	for i in range(SV.d["gp_moves"].size() - 1, -1, -1):
		if String(SV.d["gp_moves"][i]).begins_with("gp_"):
			SV.d["gp_moves"].remove_at(i)   # restos de la lista provisional
	return SV.d["gp_moves"]


static func is_unlocked(id: String) -> bool:
	return unlocked().has(id)


static func def_of(id: String) -> Dictionary:
	for m in DATA.MOVES:
		if String(m["id"]) == id:
			return m
	return {}


# Un movimiento de la maquina solo se puede usar (cartas, inicial, MT) si ya esta desbloqueado.
static func playable(id: String) -> bool:
	if def_of(id).is_empty():
		return true
	return is_unlocked(id)


static func locked_ids() -> Array:
	var out: Array = []
	for m in DATA.MOVES:
		if not unlocked().has(String(m["id"])):
			out.append(String(m["id"]))
	return out


static func type_color(t: String) -> Color:
	return Color.html(String(MD.TYPE_COLOR.get(t, "#b0a99f")))


# Gasta una moneda y devuelve los ids desbloqueados ([] si no hay monedas o no queda nada por desbloquear).
static func spend(gold: bool) -> Array:
	var key := "gold_coins" if gold else "gcoins"
	if int(SV.d.get(key, 0)) <= 0:
		return []
	var locked := locked_ids()
	if locked.is_empty():
		return []
	var got: Array = []
	for _i in range(mini(2 if gold else 1, locked.size())):
		var tot := 0.0
		for id in locked:
			tot += float(def_of(String(id)).get("w", 2))
		var roll: float = randf() * tot
		var pick: String = String(locked[0])
		for id in locked:
			roll -= float(def_of(String(id)).get("w", 2))
			if roll <= 0.0:
				pick = String(id)
				break
		got.append(pick)
		locked.erase(pick)
	SV.d[key] = int(SV.d[key]) - 1
	for id in got:
		unlocked().append(id)
	SV.save()
	return got


# ---------------------------------------------------------------------------
# Disco MT: circulo del color del tipo del movimiento, con aro, etiqueta y las letras MT.
class Disc extends Control:
	var col: Color = Color("#b0a99f")
	var squash: float = 1.0     # 1 = de frente, 0 = de canto (giro)
	var locked: bool = false

	func _init(c: Color = Color("#b0a99f"), size: float = 64.0) -> void:
		col = c
		custom_minimum_size = Vector2(size, size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Disc.paint(self, size * 0.5, minf(size.x, size.y) * 0.5, col, squash, locked)

	# Mapa de tonos del disco (estilo sprite de MT): cuadricula N x N, cacheada por tamano.
	static var _maps: Dictionary = {}

	static func _tone_map(n: int) -> Array:
		if _maps.has(n):
			return _maps[n]
		var rows: Array = []
		for j in range(n):
			var row: Array = []
			for i in range(n):
				var nx: float = (float(i) + 0.5) / float(n) * 2.0 - 1.0
				var ny: float = (float(j) + 0.5) / float(n) * 2.0 - 1.0
				var d: float = sqrt(nx * nx + ny * ny)
				var t: int = -1
				if d <= 1.0:
					var hx: float = nx + 0.02
					var hy: float = ny + 0.02
					var hd: float = sqrt(hx * hx + hy * hy)
					if d > 0.9:
						t = 0                                  # contorno oscuro
					elif d > 0.8:
						t = 1 if (nx + ny * 0.6) > 0.15 else 2  # borde: sombra o gris
					elif hd < 0.13:
						t = 7                                  # agujero: blanco
					elif hd < 0.25:
						t = 8 if (hx - hy) < 0.12 else 9       # aro gris y oscuro del agujero
					else:
						var sh: float = -nx * 0.45 - ny * 0.75   # luz desde arriba-izquierda
						var band: float = absf(nx * 0.7 + ny * 0.7 + 0.15)   # banda clara diagonal
						if d > 0.66 and sh > 0.2:
							t = 6
						elif band < 0.16 and d > 0.3:
							t = 6
						elif sh > 0.35:
							t = 5
						elif sh < -0.4 or (d > 0.7 and sh < -0.1):
							t = 3
						else:
							t = 4
				row.append(t)
			rows.append(row)
		_maps[n] = rows
		return rows

	static func _tone_col(t: int, base: Color, lk: bool) -> Color:
		var b: Color = Color("#6b7085") if lk else base
		match t:
			0: return Color("#2a2a35")
			1: return Color("#4c4c6a")
			2: return Color("#8a8a92")
			3: return b.darkened(0.2)
			4: return b
			5: return b.lightened(0.38)
			6: return b.lightened(0.72)
			7: return Color("#ffffff")
			8: return Color("#7c7c86")
			9: return Color("#3a3a4c")
		return b

	static func paint(ci: CanvasItem, ctr: Vector2, r: float, c: Color, sq: float, lk: bool = false, xf: Vector2 = Vector2.ZERO, k: float = 1.0) -> void:
		var n: int = clampi(int(round(2.0 * r * k)), 14, 22)
		var rows: Array = _tone_map(n)
		var sx: float = maxf(absf(sq), 0.08)
		ci.draw_set_transform(xf + ctr * k, 0.0, Vector2(sx * k, k))
		var cell: float = 2.0 * r / float(n)
		var o: float = -r
		for j in range(n):
			var row: Array = rows[j]
			var i := 0
			while i < n:
				var t: int = int(row[i])
				if t < 0:
					i += 1
					continue
				var i2: int = i
				while i2 + 1 < n and int(row[i2 + 1]) == t:
					i2 += 1
				ci.draw_rect(Rect2(o + float(i) * cell, o + float(j) * cell, float(i2 - i + 1) * cell + 0.3, cell + 0.3), _tone_col(t, c, lk))
				i = i2 + 1
		if lk and sx > 0.55:
			var f: Font = ThemeDB.fallback_font
			var fs: int = int(maxf(10.0, r * 0.7))
			var w: float = f.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(f, Vector2(-w * 0.5, fs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffffff"))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------------------
# Maquina: se dibuja en un lienzo base de 400 x 520 y se escala al tamano del control.
class MachineArt extends Control:
	signal finished
	signal poked
	var bump: float = 0.0
	const BW := 400.0
	const BH := 520.0
	const CAPS := [Color("#e0434f"), Color("#4b9bff"), Color("#ffd33d"), Color("#5fcb6a"), Color("#ff9ed8"), Color("#ff7b3d")]
	var t: float = -1.0           # <0: en reposo
	var gold: bool = false
	var discs: Array = []         # [{col}] discos que salen
	var cap_col: Color = Color("#e0434f")
	var idle_t: float = 0.0
	var lever: float = 0.0
	var seed_caps: Array = []
	var sfx_cb: Callable = Callable()
	var _sfx_done: Dictionary = {}
	var fast: bool = false        # toque/tecla durante la animacion: la acelera (el premio ya esta decidido)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(300, 390)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var pts: Array = []
		while pts.size() < 54:
			var yy: float = lerpf(-34.0, 62.0, pow(rng.randf(), 0.7))
			var hw: float = 108.0 * sqrt(maxf(0.05, 1.0 - pow(yy / 84.0, 2.0)))
			var pp := Vector2(rng.randf_range(-hw, hw), yy)
			pts.append(pp)
		pts.sort_custom(func(a, b): return a.y < b.y)
		for i in pts.size():
			seed_caps.append({"p": pts[i], "c": CAPS[rng.randi() % CAPS.size()], "a": rng.randf() * TAU, "o": Vector2.ZERO, "v": Vector2.ZERO, "w": 0.0, "s": 0.0})
		for k in 90:
			_sim(0.033)

	func play(is_gold: bool, disc_cols: Array) -> void:
		gold = is_gold
		discs = disc_cols
		cap_col = Color("#ffd23f") if is_gold else CAPS[randi() % CAPS.size()]
		t = 0.0
		fast = false
		_sfx_done = {}

	func busy() -> bool:
		return t >= 0.0

	func _sfx(key: String, name: String) -> void:
		if _sfx_done.has(key):
			return
		_sfx_done[key] = true
		if sfx_cb.is_valid():
			sfx_cb.call(name)

	# Toque en la maquina: las capsulas saltan y ruedan dentro del globo (pos en coordenadas de la maquina, 400x520)
	func poke(local_pos: Vector2, power: float = 1.0) -> void:
		if t >= 0.0:
			return
		var GC := Vector2(200, 205)
		for cp in seed_caps:
			var cpos: Vector2 = GC + (cp["p"] as Vector2) + (cp["o"] as Vector2)
			var d: Vector2 = cpos - local_pos
			var dist: float = d.length()
			if dist < 130.0:
				var dir: Vector2 = d.normalized() if dist > 1.0 else Vector2.UP
				var k: float = (1.0 - dist / 130.0) * power
				cp["v"] = (cp["v"] as Vector2) + dir * 420.0 * k + Vector2(randf_range(-50.0, 50.0), -260.0 * k - randf_range(0.0, 80.0))
				cp["w"] = float(cp["w"]) + randf_range(-9.0, 9.0) * k
		bump = 1.0
		poked.emit()

	func _sim(delta: float) -> void:
		# Fisica de monton: las capsulas son cuerpos libres (gravedad, choques entre ellas y paredes del globo).
		# Despues de tocarlas ruedan y se reacomodan en otro sitio: ya no vuelven a su lugar de origen.
		var dt: float = minf(delta, 0.033)
		var n: int = seed_caps.size()
		for cp in seed_caps:
			var v: Vector2 = cp["v"]
			v.y += 900.0 * dt
			v *= maxf(0.0, 1.0 - (1.2 if v.length() > 120.0 else 7.0) * dt)
			if v.length() < 14.0:
				v = Vector2.ZERO
			cp["p"] = (cp["p"] as Vector2) + v * dt
			cp["v"] = v
		for it in 2:
			for i in range(n):
				var ci: Dictionary = seed_caps[i]
				var pi: Vector2 = ci["p"]
				for j in range(i + 1, n):
					var cj: Dictionary = seed_caps[j]
					var d: Vector2 = (cj["p"] as Vector2) - pi
					var dd: float = d.length_squared()
					if dd < 144.0 and dd > 0.0001:    # radio de contacto 12 px
						var dl: float = sqrt(dd)
						var push: Vector2 = d / dl * (12.0 - dl) * 0.5
						ci["p"] = (ci["p"] as Vector2) - push
						cj["p"] = (cj["p"] as Vector2) + push
						pi = ci["p"]
						var rv: Vector2 = (cj["v"] as Vector2) - (ci["v"] as Vector2)
						var nrm: Vector2 = d / dl
						var vn: float = rv.dot(nrm)
						if vn < 0.0:
							var imp: Vector2 = nrm * vn * 0.45
							ci["v"] = (ci["v"] as Vector2) + imp
							cj["v"] = (cj["v"] as Vector2) - imp
			for cp in seed_caps:
				var ap: Vector2 = cp["p"]
				var v2: Vector2 = cp["v"]
				var ex: float = ap.x / 108.0
				var ey: float = (ap.y - 6.0) / 78.0
				var e: float = ex * ex + ey * ey
				if e > 1.0:
					var sc2: float = 1.0 / sqrt(e)
					ap = Vector2(ap.x * sc2, 6.0 + (ap.y - 6.0) * sc2)
					var nn: Vector2 = Vector2(ap.x / (108.0 * 108.0), (ap.y - 6.0) / (78.0 * 78.0)).normalized()
					var vn2: float = v2.dot(nn)
					if vn2 > 0.0:
						v2 -= nn * vn2 * 1.4      # rebote suave contra el cristal
					v2.x *= 0.96
				if ap.y > 70.0:
					ap.y = 70.0
					if v2.y > 0.0:
						v2.y = -v2.y * 0.3
					v2.x *= 0.9
				cp["p"] = ap
				cp["v"] = v2
		for cp in seed_caps:
			cp["w"] = float(cp["w"]) * maxf(0.0, 1.0 - 1.8 * dt)
			var vv: Vector2 = cp["v"]
			cp["s"] = float(cp["s"]) + float(cp["w"]) * dt + vv.x * dt * 0.03
		bump = maxf(0.0, bump - dt * 4.0)

	func _process(delta: float) -> void:
		idle_t += delta
		if t < 0.0:
			_sim(delta)
		if t >= 0.0:
			t += delta * (3.0 if fast else 1.0)
			if t >= 5.2:
				t = -1.0
				lever = 0.0
				queue_redraw()
				finished.emit()
				return
		queue_redraw()

	# --- helpers de animacion
	static func _ease(x: float) -> float:
		x = clampf(x, 0.0, 1.0)
		return x * x * (3.0 - 2.0 * x)

	static func _seg(tt: float, a: float, b: float) -> float:
		return clampf((tt - a) / (b - a), 0.0, 1.0)

	func _draw() -> void:
		var sc: float = minf(size.x / BW, size.y / BH)
		var off := Vector2((size.x - BW * sc) * 0.5, (size.y - BH * sc) * 0.5)
		draw_set_transform(off + Vector2(sin(idle_t * 50.0) * bump * 2.0, -bump * 2.0) * sc, 0.0, Vector2(sc, sc))
		var line := Color("#1a1a2e")
		var white := Color("#f4f6fb")
		var shade := Color("#c9d2e6")
		var grey := Color("#a3a9b8")
		var red := Color("#e8262d")
		var dred := Color("#a8141c")
		var lred := Color("#ff6b5e")
		var GC := Vector2(200, 205)
		# sombra y patas
		draw_ellipse_shadow(Vector2(200, 508), 150.0, 10.0)
		_rr(Rect2(74, 486, 62, 22), 4, Color("#2b2d3a"), line)
		_rr(Rect2(264, 486, 62, 22), 4, Color("#2b2d3a"), line)
		# cuerpo rojo con paneles blancos laterales
		_rr(Rect2(92, 318, 216, 172), 8, red, line)
		draw_rect(Rect2(96, 322, 208, 6), lred)
		draw_rect(Rect2(96, 480, 208, 6), dred)
		_rr(Rect2(98, 344, 28, 110), 4, white, line)
		_rr(Rect2(274, 344, 28, 110), 4, white, line)
		draw_circle(Vector2(288, 410), 9.0, red)
		draw_circle(Vector2(288, 410), 9.0, line, false, 2.0)
		draw_rect(Rect2(279, 408, 18, 3), line)
		# banda roja bajo el globo
		_rr(Rect2(78, 286, 244, 34), 6, red, line)
		draw_rect(Rect2(84, 290, 232, 5), lred)
		# globo de cristal (elipse) + capsulas
		var shake: float = 0.0
		if t >= 0.0 and t > 0.95 and t < 2.5:
			shake = sin(t * 55.0) * 3.0
		draw_colored_polygon(_ell(GC, 130.0, 86.0, 0.0, TAU, 48), Color(0.68, 0.84, 1.0, 0.55))
		for i in seed_caps.size():
			var cp: Dictionary = seed_caps[i]
			var p: Vector2 = GC + (cp["p"] as Vector2) + (cp["o"] as Vector2) + Vector2(shake * (1.0 if i % 2 == 0 else -1.0), absf(shake) * 0.4)
			p += Vector2(cos(idle_t * 0.8 + float(i)) * 1.5, sin(idle_t * 0.9 + float(i) * 2.0) * 1.5)
			_capsule(p, 19.0, cp["c"], float(cp["a"]) * 0.3 + float(cp["s"]), 0.0)
		var gl := _ell(GC, 130.0, 86.0, 0.0, TAU, 48)
		gl.append(gl[0])
		draw_polyline(gl, Color("#7fa6d6"), 6.0)
		draw_polyline(gl, line, 2.5)
		draw_polyline(_ell(GC, 114.0, 72.0, 3.4, 4.5, 14), Color(1, 1, 1, 0.8), 5.0)
		draw_polyline(_ell(GC, 114.0, 72.0, 0.0, 0.5, 8), Color(1, 1, 1, 0.5), 4.0)
		# tapa roja con Poke Ball
		_rr(Rect2(86, 108, 228, 24), 8, dred, line)
		var cap := _ell(Vector2(200, 112), 108.0, 82.0, PI, TAU, 28)
		draw_colored_polygon(cap, red)
		cap.append(cap[0])
		draw_polyline(cap, line, 3.0)
		draw_polyline(_ell(Vector2(200, 112), 94.0, 68.0, 3.7, 4.7, 10), lred, 6.0)
		draw_circle(Vector2(200, 36), 11.0, Color("#ffae3d"))
		draw_circle(Vector2(200, 36), 11.0, line, false, 2.0)
		_rr(Rect2(86, 110, 228, 12), 4, red, line)
		draw_circle(Vector2(136, 98), 24.0, line)
		draw_circle(Vector2(136, 98), 20.0, red)
		draw_circle(Vector2(136, 98), 20.0, line, false, 2.0)
		draw_rect(Rect2(116, 96, 40, 4), line)
		draw_circle(Vector2(136, 98), 7.0, white)
		draw_circle(Vector2(136, 98), 7.0, line, false, 2.0)
		# panel gris con ranura y mando giratorio
		_rr(Rect2(118, 330, 164, 96), 12, grey, line)
		draw_rect(Rect2(122, 334, 156, 4), Color("#cfd3de"))
		_rr(Rect2(190, 340, 20, 8), 3, line, line)
		var la: float = 0.0
		if t >= 0.95:
			la = _ease(_seg(t, 0.95, 2.0)) * TAU
		lever = la
		var dc := Vector2(200, 380)
		draw_arc(dc, 40.0, PI * 1.05, PI * 1.45, 8, Color("#ffb82e"), 4.0)
		draw_arc(dc, 40.0, PI * 1.55, PI * 1.95, 8, Color("#ffb82e"), 4.0)
		draw_circle(dc, 30.0, line)
		draw_circle(dc, 27.0, Color("#b8bdc9"))
		draw_circle(dc, 20.0, Color("#8e94a3"))
		var hv := Vector2(cos(la), sin(la))
		draw_line(dc - hv * 19.0, dc + hv * 19.0, line, 11.0)
		draw_line(dc - hv * 18.0, dc + hv * 18.0, Color("#d6dae4"), 6.0)
		# bandeja de salida (rampa en la parte baja)
		_rr(Rect2(140, 428, 120, 62), 10, red, line)
		_rr(Rect2(150, 438, 100, 46), 8, Color("#2b2f45"), line)
		# --- animacion
		if t >= 0.0:
			_draw_anim(sc)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_anim(_sc: float) -> void:
		var line := Color("#1a1a2e")
		# 1) moneda: llega al slot
		if t < 1.0:
			var a: float = _ease(_seg(t, 0.0, 0.75))
			var p0 := Vector2(340, 60)
			var p1 := Vector2(200, 344)
			var p: Vector2 = p0.lerp(p1, a) + Vector2(0, -sin(a * PI) * 70.0)
			var spin: float = cos(t * 18.0)
			_coin(p, 22.0 * (1.0 - 0.45 * _seg(t, 0.75, 1.0)), spin)
			if t > 0.75:
				_sfx("coin", "coin")
		# 2) capsula cae del domo a la bandeja
		if t >= 1.9 and t < 3.3:
			_sfx("lever", "hover")
			var a2: float = _seg(t, 1.9, 2.8)
			var start := Vector2(200, 272)
			var endp := Vector2(200, 452)
			var y: float = lerpf(start.y, endp.y, a2 * a2)
			if t > 2.8:
				y = endp.y - absf(sin((t - 2.8) * 9.0)) * 22.0 * (1.0 - _seg(t, 2.8, 3.3))
			_capsule(Vector2(200, y), 26.0, cap_col, (t - 1.9) * 3.0 if t < 2.8 else 0.0, 0.0)
		elif t >= 3.3 and t < 3.9:
			# la capsula salta hacia delante y se agita antes de abrir
			var a3: float = _seg(t, 3.3, 3.9)
			var pp := Vector2(200, 452 - a3 * 120.0)
			_capsule(pp, 26.0 + a3 * 22.0, cap_col, sin(t * 40.0) * 0.25, 0.0)
			_sfx("shake", "click")
		elif t >= 3.9:
			# 3) se abre: dos mitades + destello + discos MT
			var ao: float = _seg(t, 3.9, 4.35)
			var ctr := Vector2(200, 332)
			var gap: float = ao * 40.0
			_capsule_half(ctr + Vector2(-gap * 0.4, -gap), 48.0, cap_col, -ao * 0.9, true)
			_capsule_half(ctr + Vector2(gap * 0.4, gap * 0.6), 48.0, cap_col, ao * 0.7, false)
			_sfx("open", "bossDown")
			if t < 4.5:
				var fl: float = 1.0 - _seg(t, 3.9, 4.5)
				draw_circle(ctr, 30.0 + (1.0 - fl) * 150.0, Color(1, 1, 0.8, 0.55 * fl))
				for k in 12:
					var ang: float = float(k) / 12.0 * TAU + 0.2
					var d1: float = 40.0 + (1.0 - fl) * 130.0
					draw_line(ctr + Vector2(cos(ang), sin(ang)) * d1, ctr + Vector2(cos(ang), sin(ang)) * (d1 + 24.0), Color(1, 0.95, 0.6, fl), 4.0)
			# discos: salen disparados hacia arriba y caen en arco
			var n: int = discs.size()
			for i in n:
				var st: float = 4.05 + float(i) * 0.14
				var ad: float = _seg(t, st, st + 1.05)
				if ad <= 0.0:
					continue
				var dir_x: float = (float(i) - float(n - 1) * 0.5) * 70.0
				var px: float = ctr.x + dir_x * _ease(ad)
				var py: float = ctr.y - sin(ad * PI) * 150.0 + ad * 30.0
				var rr: float = 30.0 + 6.0 * sin(ad * PI)
				var scd: float = minf(size.x / BW, size.y / BH)
				var offd := Vector2((size.x - BW * scd) * 0.5, (size.y - BH * scd) * 0.5)
				Disc.paint(self, Vector2(px, py), rr, discs[i], cos(ad * 14.0) if ad < 0.9 else 1.0, false, offd, scd)
				draw_set_transform(offd, 0.0, Vector2(scd, scd))
				if ad > 0.9:
					_sfx("disc%d" % i, "click")

	# --- piezas
	func draw_ellipse_shadow(c: Vector2, rx: float, ry: float) -> void:
		var pts := PackedVector2Array()
		for i in 28:
			var a: float = float(i) / 28.0 * TAU
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.28))

	static func _ell(c: Vector2, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n + 1):
			var a: float = lerpf(a0, a1, float(i) / float(n))
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func _rr(r: Rect2, rad: float, fill: Color, border: Color) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.border_color = border
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(int(rad))
		sb.anti_aliasing = false
		draw_style_box(sb, r)

	func _coin(p: Vector2, r: float, spin: float) -> void:
		var sx: float = maxf(absf(spin), 0.12)
		var sc0: float = minf(size.x / BW, size.y / BH)
		var off0 := Vector2((size.x - BW * sc0) * 0.5, (size.y - BH * sc0) * 0.5)
		draw_set_transform(off0 + p * sc0, 0.0, Vector2(sx * sc0, sc0))
		var gl: Color = Color("#ffd23f") if gold else Color("#f4f6fb")
		var pr: Color = Color("#c9791a") if gold else Color("#7a3fd0")
		draw_circle(Vector2.ZERO, r, Color("#1a1a2e"))
		draw_circle(Vector2.ZERO, r * 0.92, gl)
		draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 24, pr, r * 0.16)
		draw_rect(Rect2(-r * 0.2, -r * 1.12, r * 0.4, r * 0.28), Color("#e0434f"))
		draw_rect(Rect2(-r * 0.2, r * 0.84, r * 0.4, r * 0.28), Color("#e0434f"))
		draw_circle(Vector2.ZERO, r * 0.28, Color("#e0434f"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# restaurar la escala del lienzo base lo hace _draw al volver; aqui basta con reaplicar
		var sc: float = minf(size.x / BW, size.y / BH)
		var off := Vector2((size.x - BW * sc) * 0.5, (size.y - BH * sc) * 0.5)
		draw_set_transform(off, 0.0, Vector2(sc, sc))

	func _capsule(p: Vector2, r: float, c: Color, rot: float, _open: float) -> void:
		var sc: float = minf(size.x / BW, size.y / BH)
		var off := Vector2((size.x - BW * sc) * 0.5, (size.y - BH * sc) * 0.5)
		draw_set_transform(off + p * sc, rot, Vector2(sc, sc))
		draw_circle(Vector2.ZERO, r, Color("#1a1a2e"))
		draw_circle(Vector2.ZERO, r - 2.5, Color("#dfe3ee"))
		var pts := PackedVector2Array()
		for i in 17:
			var a: float = PI + float(i) / 16.0 * PI
			pts.append(Vector2(cos(a), sin(a)) * (r - 2.5))
		draw_colored_polygon(pts, c)
		draw_arc(Vector2.ZERO, r * 0.62, 3.6, 4.6, 8, Color(1, 1, 1, 0.8), maxf(2.0, r * 0.14))
		draw_rect(Rect2(-r + 1.0, -r * 0.09, 2.0 * r - 2.0, r * 0.18), Color("#1a1a2e"))
		draw_circle(Vector2.ZERO, r * 0.3, Color("#1a1a2e"))
		draw_circle(Vector2.ZERO, r * 0.18, Color("#f4f6fb"))
		draw_set_transform(off, 0.0, Vector2(sc, sc))

	func _capsule_half(p: Vector2, r: float, c: Color, rot: float, top: bool) -> void:
		var sc: float = minf(size.x / BW, size.y / BH)
		var off := Vector2((size.x - BW * sc) * 0.5, (size.y - BH * sc) * 0.5)
		draw_set_transform(off + p * sc, rot, Vector2(sc, sc))
		var pts := PackedVector2Array()
		for i in 17:
			var a: float = (PI if top else 0.0) + float(i) / 16.0 * PI
			pts.append(Vector2(cos(a), sin(a)) * (r - 2.5))
		draw_colored_polygon(pts, c if top else Color("#f4f6fb"))
		draw_polyline(pts, Color("#1a1a2e"), 3.0)
		draw_set_transform(off, 0.0, Vector2(sc, sc))


# ---------------------------------------------------------------------------
# Envoltorio pixelado: la maquina se dibuja a baja resolucion y se amplia sin suavizar.
class Machine extends SubViewportContainer:
	signal finished
	var art: MachineArt
	var vp: SubViewport
	var sfx_cb: Callable:
		set(v):
			sfx_cb = v
			if art != null:
				art.sfx_cb = v

	func _init() -> void:
		stretch = true
		stretch_shrink = 3
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = Vector2(300, 390)
		vp = SubViewport.new()
		vp.transparent_bg = true
		vp.size = Vector2i(100, 130)
		add_child(vp)
		art = MachineArt.new()
		art.custom_minimum_size = Vector2.ZERO
		art.size = Vector2(100, 130)
		vp.add_child(art)
		vp.size_changed.connect(func(): art.size = Vector2(vp.size))
		art.finished.connect(func(): finished.emit())

	func play(is_gold: bool, disc_cols: Array) -> void:
		art.play(is_gold, disc_cols)

	func busy() -> bool:
		return art.busy()

	# Acelera la animacion en curso; no inicia otra tirada ni cobra de nuevo (S37).
	func speed_up() -> void:
		if art.busy():
			art.fast = true

	func _gui_input(ev: InputEvent) -> void:
		if not art.busy():
			var pos := Vector2(-1, -1)
			var strong: float = 1.0
			if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
				pos = ev.position
			elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
				pos = ev.position   # arrastrar el dedo tambien las mueve
				strong = 0.35
			elif ev is InputEventScreenDrag:
				pos = ev.position
				strong = 0.35
			if pos.x >= 0.0 and size.x > 0.0 and art.size.x > 0.0:
				var ap: Vector2 = pos * (art.size / size)
				var sc: float = minf(art.size.x / art.BW, art.size.y / art.BH)
				var off := Vector2((art.size.x - art.BW * sc) * 0.5, (art.size.y - art.BH * sc) * 0.5)
				art.poke((ap - off) / sc, strong)
				if strong >= 1.0 and sfx_cb.is_valid():
					sfx_cb.call("click")
				accept_event()
			return
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			speed_up()
			accept_event()
