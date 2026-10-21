extends Node2D
# Interior de una cueva elemental (S57.10): entorno aparte del mapa base, con el mismo contrato que las arenas de las grietas
# (collide / liquid_at / build / clear_props / th) para que main.gd lo trate como `arena`.
# Sala principal (oleada) + alcoba del altar cerrada por un porton que se abre al vencer la oleada.
# Sprites: assets/world/cave/*.png (hoja de cuevas y altares de los 18 tipos).

const HW := 420.0            # media anchura del suelo
const HH := 330.0            # media altura del suelo
const ALC_Y := -170.0        # linea de la pared de la alcoba
const GATE_HW := 100.0       # medio hueco del porton
const ALTAR_POS := Vector2(0.0, -232.0)
const ALTAR_R := 46.0
const EXIT_HW := 46.0
const SPAWN := Vector2(0.0, 240.0)
const TILE_SC := 1.5

var ty := "fire"
var col := Color.WHITE
var th := {}
var state := "idle"          # idle -> wave -> ready -> taken
var gate_open := 0.0         # 0 cerrado .. 1 abierto
var gate_opening := false
var gate_shake := 0.0
var t := 0.0
var seed_v := 1
var solids: Array = []       # [centro local, radio] fijos
var gate_solids: Array = []  # solo mientras el porton esta cerrado
var lights: Array = []       # [pos local, color, radio] (linternas y cristales)
var _st = null
var _dy = null
static var _cache := {}


static func tex(n: String) -> Texture2D:
	if _cache.has(n):
		return _cache[n]
	var p := "res://assets/world/cave/%s.png" % n
	var tx: Texture2D = null
	if ResourceLoader.exists(p):
		tx = load(p)
	else:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null and not img.is_empty():
			tx = ImageTexture.create_from_image(img)
	_cache[n] = tx
	return tx


static func tex_in(dir: String, n: String) -> Texture2D:
	var key := dir + "/" + n
	if _cache.has(key):
		return _cache[key]
	var p := "res://assets/world/%s/%s.png" % [dir, n]
	var tx: Texture2D = null
	if ResourceLoader.exists(p):
		tx = load(p)
	else:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null and not img.is_empty():
			tx = ImageTexture.create_from_image(img)
	_cache[key] = tx
	return tx


static func floor_set(type: String) -> Array:
	# texturas de suelo (0 gris azulado, 1 azul oscuro, 2 tierra, 3 gris claro, 4 tierra, 5 humedo)
	match type:
		"ground", "rock", "fire", "fighting", "steel":
			return [2, 4, 0, 3, 2, 4]
		"water", "ice":
			return [5, 1, 5, 0, 1, 5]
		_:
			return [0, 1, 3, 0, 5, 1]


func build(_world: Node2D) -> void:
	seed_v = int(Time.get_ticks_usec() % 100000)
	_make_solids()
	_st = Node2D.new()
	_st.set_script(StaticDraw)
	_st.cv = self
	add_child(_st)
	_dy = Node2D.new()
	_dy.set_script(DynDraw)
	_dy.cv = self
	_dy.z_index = 1   # por debajo del jugador (el altar no lo tapa)
	add_child(_dy)


func clear_props() -> void:
	pass


func liquid_at(_pos: Vector2) -> String:
	return ""


func _make_solids() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	# pared de la alcoba, con el hueco del porton
	var x := -HW + 20.0
	while x <= HW - 20.0:
		if absf(x) > GATE_HW + 6.0:
			solids.append([Vector2(x, ALC_Y), 30.0])
		x += 44.0
	var gx := -GATE_HW
	while gx <= GATE_HW:
		gate_solids.append([Vector2(gx, ALC_Y), 24.0])
		gx += 30.0
	# estalagmitas y rocas de la sala (posiciones fijas por semilla, lejos del centro y del paso al porton)
	var n := 0
	var guard := 0
	while n < 9 and guard < 80:
		guard += 1
		var p := Vector2(rng.randf_range(-HW + 50.0, HW - 50.0), rng.randf_range(ALC_Y + 70.0, HH - 90.0))
		if absf(p.x) < 130.0 and p.y < 40.0:
			continue          # pasillo hacia el porton
		if p.distance_to(SPAWN) < 120.0:
			continue
		var ok := true
		for s in solids:
			if p.distance_to(s[0]) < 90.0 and s[1] < 40.0:
				ok = false
		if ok:
			solids.append([p, 20.0])
			n += 1
	# luces: linternas en los postes y cristales
	lights.append([Vector2(-GATE_HW - 26.0, ALC_Y - 40.0), Color("#ffc46b"), 90.0])
	lights.append([Vector2(GATE_HW + 26.0, ALC_Y - 40.0), Color("#ffc46b"), 90.0])
	lights.append([Vector2(-HW + 40.0, 40.0), Color("#5fb8ff"), 80.0])
	lights.append([Vector2(HW - 40.0, 120.0), Color("#5fb8ff"), 80.0])


func collide(pos: Vector2, rad: float) -> Vector2:
	var lp: Vector2 = pos - position
	var in_exit: bool = absf(lp.x) < EXIT_HW and lp.y > HH - 40.0
	lp.x = clampf(lp.x, -HW + rad, HW - rad)
	lp.y = clampf(lp.y, -HH + rad, (HH + 70.0) if in_exit else (HH - rad))
	if absf(lp.x) > EXIT_HW - rad and lp.y > HH - rad:
		lp.y = HH - rad
	for pass_i in range(2):
		for s in solids:
			var d: Vector2 = lp - (s[0] as Vector2)
			var r: float = float(s[1]) + rad
			var l: float = d.length()
			if l < r:
				lp = (s[0] as Vector2) + (d / maxf(l, 0.001)) * r if l > 0.001 else (s[0] as Vector2) + Vector2(0.0, r)
		if gate_open < 0.9:
			for s in gate_solids:
				var d2: Vector2 = lp - (s[0] as Vector2)
				var r2: float = float(s[1]) + rad
				var l2: float = d2.length()
				if l2 < r2:
					lp = (s[0] as Vector2) + (d2 / maxf(l2, 0.001)) * r2 if l2 > 0.001 else (s[0] as Vector2) + Vector2(0.0, r2)
	return position + lp


func local_of(pos: Vector2) -> Vector2:
	return pos - position


func on_exit(pos: Vector2) -> bool:
	var lp := pos - position
	return absf(lp.x) < EXIT_HW and lp.y > HH - 16.0


func on_altar(pos: Vector2) -> bool:
	return (pos - position).distance_to(ALTAR_POS + Vector2(0.0, 30.0)) < ALTAR_R


func open_gate() -> void:
	gate_opening = true
	gate_shake = 1.0


func _process(delta: float) -> void:
	t += delta
	if gate_opening and gate_open < 1.0:
		gate_open = minf(1.0, gate_open + delta / 1.6)
	gate_shake = maxf(0.0, gate_shake - delta * 0.6)
	if _dy != null:
		_dy.queue_redraw()


# --- dibujo estatico: suelo, paredes, decoracion (se dibuja una vez) ---
class StaticDraw extends Node2D:
	var cv = null

	func _tx(n: String):
		return cv.tex(n)

	func _put(n: String, pos: Vector2, sc: float, tint: Color = Color.WHITE, flip: bool = false) -> void:
		var tx: Texture2D = _tx(n)
		if tx == null:
			return
		var sz: Vector2 = tx.get_size() * sc
		var r := Rect2(pos - Vector2(sz.x * 0.5, sz.y), sz)
		if flip:
			r = Rect2(Vector2(r.position.x + r.size.x, r.position.y), Vector2(-r.size.x, r.size.y))
		draw_texture_rect(tx, r, false, tint)

	func _draw() -> void:
		var HW_: float = cv.HW
		var HH_: float = cv.HH
		var rng := RandomNumberGenerator.new()
		rng.seed = cv.seed_v
		draw_rect(Rect2(-3000, -3000, 6000, 6000), Color("#05060c"))
		draw_rect(Rect2(-HW_, -HH_, HW_ * 2.0, HH_ * 2.0), Color("#2b3350").lerp(cv.col, 0.06))   # base del suelo: sin rejilla negra entre baldosas
		var fs: Array = cv.floor_set(cv.ty)
		var tint := Color(1, 1, 1).lerp(cv.col, 0.10)
		var tw: float = 112.0 * cv.TILE_SC
		var th_: float = 86.0 * cv.TILE_SC
		var cols := int(ceil(HW_ * 2.0 / tw))
		var rows := int(ceil(HH_ * 2.0 / th_))
		for r in range(rows):
			for c in range(cols):
				var tx: Texture2D = _tx("floor%d" % int(fs[rng.randi() % fs.size()]))
				if tx == null:
					continue
				var p := Vector2(-HW_ + c * tw, -HH_ + r * th_)
				var tn := tint
				if p.y + th_ < cv.ALC_Y + 10.0:
					tn = Color(1, 1, 1).lerp(cv.col, 0.28)   # alcoba del altar teñida del tipo
				draw_texture_rect(tx, Rect2(p, Vector2(tw + 2.0, th_ + 2.0)), false, tn)
		# estanque y minas (decoracion de la sala, sin bloquear)
		_put("pond", Vector2(-250.0, 90.0), 1.15)
		_put("mine_cart", Vector2(285.0, 70.0), 0.85)
		# cristales y charcos de luz
		for p in [Vector2(-370, -60), Vector2(360, 200), Vector2(-150, 250), Vector2(190, -80)]:
			_put(["crys_b", "crystal_cl", "crys_b2"][rng.randi() % 3], p, 0.9)
		_put("crys_p1", Vector2(-330.0, 230.0), 0.8)
		_put("crys_p2", Vector2(-305.0, 236.0), 0.8)
		# estalagmitas con colision
		var names := ["stal_a", "stal_b", "stal_c", "stal_d", "rock_a", "rock_b"]
		for s in cv.solids:
			if float(s[1]) < 25.0:
				_put(names[rng.randi() % names.size()], (s[0] as Vector2) + Vector2(0, 22), 0.95, Color.WHITE, rng.randf() < 0.5)
		# pared de la alcoba
		var x: float = -HW_ + 20.0
		while x <= HW_ - 20.0:
			if absf(x) > cv.GATE_HW + 6.0:
				_put("rockcrys", Vector2(x, cv.ALC_Y + 30.0), 0.8)
			x += 44.0
		# techo con estalactitas (arriba) y paredes laterales
		var cx: float = -HW_ - 20.0
		while cx < HW_ + 60.0:
			_put("ceil_d", Vector2(cx + 92.0, -HH_ + 70.0), 1.2)
			cx += 200.0
		var cy: float = -HH_ + 40.0
		while cy < HH_ + 40.0:
			_put("col_a", Vector2(-HW_ - 6.0, cy + 100.0), 1.4)
			_put("col_b", Vector2(HW_ + 6.0, cy + 100.0), 1.4, Color.WHITE, true)
			cy += 120.0
		# pared inferior con el hueco de la salida
		var bx: float = -HW_ - 30.0
		while bx <= HW_ + 30.0:
			if absf(bx) > cv.EXIT_HW + 40.0:
				_put("rockcrys", Vector2(bx, HH_ + 80.0), 0.95)
			bx += 100.0
		_put("mouth", Vector2(0.0, HH_ + 120.0), 0.62)
		# postes del porton
		_put("post_a", Vector2(-cv.GATE_HW - 6.0, cv.ALC_Y + 8.0), 1.7)
		_put("post_b", Vector2(cv.GATE_HW + 6.0, cv.ALC_Y + 8.0), 1.7)
		_put("lantern", Vector2(-cv.GATE_HW - 30.0, cv.ALC_Y - 10.0), 0.62)
		_put("lantern", Vector2(cv.GATE_HW + 30.0, cv.ALC_Y - 10.0), 0.62, Color.WHITE, true)
		# sombra suave en los bordes de la sala
		for i in range(6):
			var a: float = 0.16 - i * 0.025
			draw_rect(Rect2(-HW_, -HH_ + i * 22.0, HW_ * 2.0, 22.0), Color(0, 0, 0.04, a))
			draw_rect(Rect2(-HW_, HH_ - (i + 1) * 22.0, HW_ * 2.0, 22.0), Color(0, 0, 0.04, a))


# --- dibujo dinamico: luces, porton, altar ---
class DynDraw extends Node2D:
	var cv = null

	func _draw() -> void:
		var tm: float = cv.t
		for l in cv.lights:
			var f: float = 0.85 + 0.15 * sin(tm * 3.0 + (l[0] as Vector2).x)
			var c: Color = l[1]
			draw_circle(l[0], float(l[2]) * f, Color(c.r, c.g, c.b, 0.10))
			draw_circle(l[0], float(l[2]) * 0.5 * f, Color(c.r, c.g, c.b, 0.12))
		_gate()
		_altar()

	func _gate() -> void:
		var open: float = cv.gate_open
		var top: float = cv.ALC_Y - 104.0
		var full_h := 120.0
		var vis_h: float = full_h * (1.0 - open)
		var sh: float = sin(cv.t * 60.0) * 3.0 * cv.gate_shake
		var hw: float = cv.GATE_HW - 6.0
		# barrotes
		if vis_h > 1.0:
			var x: float = -hw
			while x <= hw:
				draw_rect(Rect2(x + sh - 3.0, top, 6.0, vis_h), Color("#3a3f52"))
				draw_rect(Rect2(x + sh - 3.0, top, 2.0, vis_h), Color("#7a84a6"))
				x += 16.0
			for k in [0.33, 0.66]:
				var yy: float = top + full_h * k * (1.0 - open)
				draw_rect(Rect2(-hw + sh, yy - 3.0, hw * 2.0, 6.0), Color("#2c3040"))
				draw_circle(Vector2(sh, yy), 5.0, Color(cv.col.r, cv.col.g, cv.col.b, 0.9 if open < 0.01 else 0.9 * (1.0 - open)))
		# viga superior de madera
		draw_rect(Rect2(-cv.GATE_HW - 10.0, top - 14.0, cv.GATE_HW * 2.0 + 20.0, 16.0), Color("#5a3b22"))
		draw_rect(Rect2(-cv.GATE_HW - 10.0, top - 14.0, cv.GATE_HW * 2.0 + 20.0, 4.0), Color("#8a5d34"))
		if cv.gate_opening and open < 1.0:
			for i in range(3):
				var px: float = -hw + fmod(cv.t * 97.0 + i * 61.0, hw * 2.0)
				draw_circle(Vector2(px, cv.ALC_Y + 4.0), 3.0, Color(0.7, 0.68, 0.6, 0.5 * (1.0 - open)))

	func _altar() -> void:
		var tx: Texture2D = cv.tex("altar_" + cv.ty)
		if tx == null:
			return
		var sc := 0.78
		var sz: Vector2 = tx.get_size() * sc
		var base: Vector2 = cv.ALTAR_POS + Vector2(0.0, 52.0)
		var st: String = cv.state
		var tint := Color(0.55, 0.55, 0.66)
		if st == "ready":
			tint = Color(1.15, 1.15, 1.15)
			var pu: float = 0.5 + 0.5 * sin(cv.t * 4.0)
			draw_circle(base + Vector2(0, -20), 70.0 + 8.0 * pu, Color(cv.col.r, cv.col.g, cv.col.b, 0.22))
			draw_circle(base + Vector2(0, -20), 40.0 + 5.0 * pu, Color(cv.col.r, cv.col.g, cv.col.b, 0.22))
			for i in range(6):
				var a: float = cv.t * 1.4 + float(i) * TAU / 6.0
				var rr: float = 52.0 + 6.0 * sin(cv.t * 2.0 + i)
				draw_circle(base + Vector2(cos(a) * rr, -30.0 + sin(a) * rr * 0.4 - fmod(cv.t * 30.0 + i * 11.0, 40.0)), 2.5, Color(cv.col.r, cv.col.g, cv.col.b, 0.8))
		elif st == "taken":
			tint = Color(0.7, 0.7, 0.78)
		draw_texture_rect(tx, Rect2(base - Vector2(sz.x * 0.5, sz.y), sz), false, tint)
