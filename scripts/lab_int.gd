extends Node2D
# Interior de un laboratorio abandonado (S57.4, Proyecto Mewtwo): entorno aparte del mapa (mismo contrato que las arenas:
# collide / liquid_at / build / clear_props / th). Dos tipos: "lab" (sala con notas de investigacion que recoger) y
# "chamber" (camara secreta con la capsula de Mewtwo). Sprites: assets/world/lab/*.png. La unica salida es la puerta.

const CVI = preload("res://scripts/cave_int.gd")
const HW := 440.0
const HH := 300.0
const EXIT_HW := 44.0
const SPAWN := Vector2(0.0, 220.0)
const FLOORS := ["floorA", "floorB", "floorC", "floorD"]
const FURN := {
	"desk_a": [0.95, 0.34], "desk_b": [1.0, 0.34], "shelf_a": [0.95, 0.34], "rack_a": [1.2, 0.3], "rack_b": [1.2, 0.3],
	"terminal": [1.15, 0.3], "machine": [1.0, 0.3], "cap_blue": [0.95, 0.3], "cap_br1": [0.95, 0.3], "cap_br2": [0.95, 0.3],
	"plant": [1.1, 0.3], "cab_a": [1.1, 0.3], "cab_b": [1.1, 0.3], "cab_c": [1.1, 0.3], "cab_d": [0.95, 0.34],
	"cab_e": [1.1, 0.3], "cab_f": [1.1, 0.3], "cab_g": [1.1, 0.3], "cab_h": [0.95, 0.34], "shelf_full": [1.2, 0.34], "table_s": [1.3, 0.3],
}

var kind := "lab"           # lab | chamber
var lab_id := 1
var note_count := 2
var th := {}
var t := 0.0
var seed_v := 1
var solids: Array = []      # [centro local, radio]
var furn: Array = []        # [nombre, pos local, escala]
var notes: Array = []       # {"pos","tex","got"}
var door_lit := false       # la puerta brilla cuando ya no queda nada por hacer
var cap_broken := false     # camara: la capsula se rompio
var cap_pos := Vector2(0.0, -170.0)
var _st = null
var _dy = null


static func tex(n: String) -> Texture2D:
	return CVI.tex_in("lab", n)


func build(_world: Node2D) -> void:
	seed_v = int(Time.get_ticks_usec() % 100000) + lab_id * 7
	_layout()
	_st = Node2D.new()
	_st.set_script(StaticDraw)
	_st.cv = self
	add_child(_st)
	_dy = Node2D.new()
	_dy.set_script(DynDraw)
	_dy.cv = self
	_dy.z_index = 2
	add_child(_dy)


func clear_props() -> void:
	pass


func liquid_at(_pos: Vector2) -> String:
	return ""


func _layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	if kind == "chamber":
		solids.append([cap_pos + Vector2(0, -14), 52.0])
		for sx in [-1.0, 1.0]:
			furn.append(["terminal", Vector2(sx * 250.0, -190.0), 1.15])
			solids.append([Vector2(sx * 250.0, -200.0), 34.0])
			furn.append(["rack_b", Vector2(sx * 370.0, -150.0), 1.2])
			solids.append([Vector2(sx * 370.0, -160.0), 34.0])
			furn.append(["cab_a", Vector2(sx * 380.0, 20.0), 1.1])
			solids.append([Vector2(sx * 380.0, 10.0), 28.0])
		furn.append(["plant", Vector2(-380.0, 230.0), 1.1])
		furn.append(["plant", Vector2(380.0, 230.0), 1.1])
		return
	var names: Array = FURN.keys()
	var slots: Array = []
	for sx in [-370.0, -250.0, -130.0, 130.0, 250.0, 370.0]:
		slots.append(Vector2(sx, -190.0))
	for sy in [-80.0, 30.0, 140.0]:
		slots.append(Vector2(-390.0, sy))
		slots.append(Vector2(390.0, sy))
	slots.append(Vector2(-200.0, 60.0))
	slots.append(Vector2(200.0, 70.0))
	slots.shuffle()
	var used: Array = []
	for i in range(mini(9, slots.size())):
		var nm: String = String(names[rng.randi() % names.size()])
		var info: Array = FURN[nm]
		var p: Vector2 = slots[i] + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-8.0, 8.0))
		if p.distance_to(SPAWN) < 120.0:
			continue
		furn.append([nm, p, float(info[0])])
		var tx: Texture2D = tex(nm)
		var r: float = (tx.get_size().x * float(info[0]) * float(info[1])) if tx != null else 32.0
		solids.append([p + Vector2(0, -r * 0.5), r])
		used.append(p)
	# notas de investigacion: 2 por laboratorio, en puntos libres
	var kinds := ["page_1", "page_2", "page_3", "page_4", "book_1", "book_2", "book_3", "book_4", "book_5", "folder", "tablet"]
	kinds.shuffle()
	var guard := 0
	while notes.size() < note_count and guard < 60:
		guard += 1
		var p2 := Vector2(rng.randf_range(-HW + 80.0, HW - 80.0), rng.randf_range(-HH + 130.0, HH - 100.0))
		if p2.distance_to(SPAWN) < 140.0:
			continue
		var ok := true
		for s in solids:
			if p2.distance_to(s[0]) < float(s[1]) + 34.0:
				ok = false
		for n in notes:
			if p2.distance_to(n["pos"]) < 260.0:
				ok = false
		if ok:
			notes.append({"pos": p2, "tex": String(kinds[notes.size()]), "got": false})


func collide(pos: Vector2, rad: float) -> Vector2:
	var lp: Vector2 = pos - position
	var in_exit: bool = absf(lp.x) < EXIT_HW and lp.y > HH - 40.0
	lp.x = clampf(lp.x, -HW + rad, HW - rad)
	lp.y = clampf(lp.y, -HH + rad + 40.0, (HH + 70.0) if in_exit else (HH - rad))
	if absf(lp.x) > EXIT_HW - rad and lp.y > HH - rad:
		lp.y = HH - rad
	for pass_i in range(2):
		for s in solids:
			var d: Vector2 = lp - (s[0] as Vector2)
			var r: float = float(s[1]) + rad
			var l: float = d.length()
			if l < r:
				lp = (s[0] as Vector2) + ((d / l) * r if l > 0.001 else Vector2(0.0, r))
	return position + lp


func on_exit(pos: Vector2) -> bool:
	var lp := pos - position
	return absf(lp.x) < EXIT_HW and lp.y > HH - 16.0


func notes_left() -> int:
	var n := 0
	for q in notes:
		if not bool(q["got"]):
			n += 1
	return n


func _process(delta: float) -> void:
	t += delta
	if _dy != null:
		_dy.queue_redraw()


class StaticDraw extends Node2D:
	var cv = null

	func _put(n: String, pos: Vector2, sc: float, tint: Color = Color.WHITE) -> void:
		var tx: Texture2D = cv.tex(n)
		if tx == null:
			return
		var sz: Vector2 = tx.get_size() * sc
		draw_texture_rect(tx, Rect2(pos - Vector2(sz.x * 0.5, sz.y), sz), false, tint)

	func _draw() -> void:
		var HW_: float = cv.HW
		var HH_: float = cv.HH
		var rng := RandomNumberGenerator.new()
		rng.seed = cv.seed_v
		draw_rect(Rect2(-3000, -3000, 6000, 6000), Color("#06070b"))
		var tw := 96.0 * 1.45
		var th_ := 78.0 * 1.45
		var cols := int(ceil(HW_ * 2.0 / tw))
		var rows := int(ceil(HH_ * 2.0 / th_))
		for r in range(rows):
			for c in range(cols):
				var nm: String = cv.FLOORS[rng.randi() % cv.FLOORS.size()]
				var tx: Texture2D = cv.tex(nm)
				if tx == null:
					continue
				var tint := Color(1, 1, 1)
				if cv.kind == "chamber":
					tint = Color(0.9, 0.8, 1.0)
				draw_texture_rect(tx, Rect2(Vector2(-HW_ + c * tw, -HH_ + r * th_), Vector2(tw + 1.0, th_ + 1.0)), false, tint)
		if cv.kind == "chamber":
			var lg: Texture2D = cv.tex("floorLogo")
			if lg != null:
				var sz: Vector2 = lg.get_size() * 1.7
				draw_texture_rect(lg, Rect2(Vector2(-sz.x * 0.5, -140.0), sz), false, Color(0.8, 0.7, 1.0, 0.9))
		# muebles ordenados por y
		var fl: Array = cv.furn.duplicate()
		fl.sort_custom(func(a, b): return (a[1] as Vector2).y < (b[1] as Vector2).y)
		for f in fl:
			_put(String(f[0]), f[1], float(f[2]))
		# pared superior con piezas, pilares laterales y puerta inferior
		var wx: float = -HW_ - 20.0
		var wn := ["wall_a", "wall_b", "wall_c", "wall_d", "wall_e"]
		var i := 0
		while wx < HW_ + 40.0:
			_put(wn[(i + cv.lab_id) % wn.size()], Vector2(wx + 70.0, -HH_ + 60.0), 1.45)
			wx += 130.0
			i += 1
		var py: float = -HH_ + 70.0
		while py < HH_ + 40.0:
			_put("pillar", Vector2(-HW_ - 12.0, py + 80.0), 1.5)
			_put("pillar", Vector2(HW_ + 12.0, py + 80.0), 1.5)
			py += 130.0
		var bx: float = -HW_ - 10.0
		while bx < HW_ + 30.0:
			if absf(bx) > cv.EXIT_HW + 60.0:
				_put("wall_b", Vector2(bx + 60.0, HH_ + 70.0), 1.45)
			bx += 120.0
		_put("door_a", Vector2(0.0, HH_ + 90.0), 0.95)
		for sx in [-1.0, 1.0]:
			_put("plant", Vector2(sx * (HW_ - 40.0), HH_ - 30.0), 1.0)
		# sombra en los bordes
		for k in range(6):
			var a: float = 0.18 - k * 0.028
			draw_rect(Rect2(-HW_, -HH_ + k * 20.0, HW_ * 2.0, 20.0), Color(0, 0, 0.05, a))
			draw_rect(Rect2(-HW_, HH_ - (k + 1) * 20.0, HW_ * 2.0, 20.0), Color(0, 0, 0.05, a))


class DynDraw extends Node2D:
	var cv = null

	func _draw() -> void:
		var tm: float = cv.t
		# luz azul de los equipos
		for f in cv.furn:
			var nm: String = String(f[0])
			if nm == "terminal" or nm == "machine" or nm.begins_with("rack") or nm == "cap_blue":
				var p: Vector2 = (f[1] as Vector2) + Vector2(0, -34)
				draw_circle(p, 46.0 + 4.0 * sin(tm * 3.0 + p.x), Color(0.3, 0.6, 1.0, 0.07))
		# notas de investigacion
		for q in cv.notes:
			if bool(q["got"]):
				continue
			var tx: Texture2D = cv.tex(String(q["tex"]))
			var p2: Vector2 = q["pos"]
			var bob: float = sin(tm * 3.0 + p2.x) * 4.0
			draw_circle(p2 + Vector2(0, 4), 30.0 + 3.0 * sin(tm * 4.0), Color(1.0, 0.9, 0.5, 0.14))
			draw_arc(p2 + Vector2(0, 4), 26.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.5, 0.6), 2.0)
			if tx != null:
				var s: Vector2 = tx.get_size() * 0.62
				draw_texture_rect(tx, Rect2(p2 - Vector2(s.x * 0.5, s.y * 0.5 + 10.0 + bob), s), false)
		# camara: capsula rota
		if cv.kind == "chamber":
			var tb: Texture2D = cv.tex("capsule_ball" if cv.cap_broken else "capsule_mew")
			var cp: Vector2 = cv.cap_pos
			if cv.cap_broken:
				var pu: float = 0.5 + 0.5 * sin(tm * 5.0)
				draw_circle(cp + Vector2(0, -40), 90.0 + 8.0 * pu, Color(0.75, 0.4, 1.0, 0.16))
			else:
				var pu2: float = 0.5 + 0.5 * sin(tm * 2.0)
				draw_circle(cp + Vector2(0, -90), 70.0 + 6.0 * pu2, Color(0.7, 0.35, 1.0, 0.12))
			if tb != null:
				var cs: Vector2 = tb.get_size() * 1.5
				draw_texture_rect(tb, Rect2(cp - Vector2(cs.x * 0.5, cs.y), cs), false)
		# puerta iluminada
		if cv.door_lit:
			var f2: float = 0.5 + 0.5 * sin(tm * 4.0)
			draw_circle(Vector2(0, cv.HH - 6.0), 52.0 + 6.0 * f2, Color(0.5, 1.0, 0.7, 0.16))
			draw_arc(Vector2(0, cv.HH - 6.0), 44.0, 0.0, TAU, 32, Color(0.5, 1.0, 0.7, 0.7), 3.0)
