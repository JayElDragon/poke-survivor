extends Control
# Menu principal: jugar, Pokemon, mejoras, gacha, misiones y ajustes.
# Funciona con toque, mando (cruceta + A / B) y teclado (flechas + Enter / Esc).

const NAVG = preload("res://scripts/navgrid.gd")
const SV = preload("res://scripts/save_data.gd")
const Aud = preload("res://scripts/audio.gd")
const PG = preload("res://scripts/progress.gd")
const CH = preload("res://scripts/challenges.gd")
const L = preload("res://scripts/lang.gd")
const MD = preload("res://scripts/moves_data.gd")
const FUS = preload("res://scripts/fusions.gd")
const TD = preload("res://scripts/types_data.gd")
const KCX = preload("res://scripts/kecleon.gd")
const AB = preload("res://scripts/abilities.gd")
const ZM = preload("res://scripts/zmove.gd")
const DYN = preload("res://scripts/dynamax.gd")
const ST = preload("res://scripts/starters_data.gd")
const IC = preload("res://scripts/icons.gd")
const TXS = preload("res://scripts/textscale.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const SLOTS = preload("res://scripts/slots.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const UPD = preload("res://scripts/updater.gd")
const PN = preload("res://scripts/patchnotes.gd")

var C_PANEL := Color("#27449a")
var C_PANEL_D := Color("#18296a")
var C_BTN := Color("#1c3a8c")
var C_BTN_H := Color("#2f58c9")
# Temas de interfaz: [panel, panel oscuro, boton, boton resaltado] (+ muestra en la posicion 2)
const UI_THEMES := [
	["#9a2e27", "#6a1e18", Color("#c8362c"), "#8c1c1c", "#c92f2f"],
	["#27449a", "#18296a", Color("#2f58c9"), "#1c3a8c", "#2f58c9"],
	["#2a8a3e", "#1a5a28", Color("#34b04c"), "#1c7a30", "#2fc94f"],
	["#5a2a9a", "#3a186a", Color("#7a3fd0"), "#4c1c8c", "#7a2fc9"],
]
const GP := preload("res://scripts/gachapon.gd")
const C_GOLD := Color("#ffd33d")
const PER_PAGE := 24

var theme_main := Theme.new()
var screens := {}
var cur := ""
var coin_lbl: Label
var coin_pill: PanelContainer
var tix_pill: PanelContainer
var name_pill: Button
var name_lbl: Button
var tab_sel: Button
var fav_btns: Array = []   # botones de los 3 favoritos (para devolverles el foco al elegir)
var tab_row: Control
var mute_top: Button
var set_top: Button
var ticket_lbl: Label
var ticket10_lbl: Label
var toast_lbl: Label
var is_overlay := false
signal closed
var ach_pop: PanelContainer
var ach_box: HBoxContainer
var ach_t := 0.0
var toast_t := 0.0
var back_btn: Button
var credit_lbl: Label
var credit_box: VBoxContainer
var pad_hint: HBoxContainer
var pad_hint_key := ""
var shade: ColorRect
var focus_first: Control = null
var news_top: Button
var support_top: Button
var support_focus: Button
var news_box: VBoxContainer
var news_scroll: ScrollContainer
var news_list: VBoxContainer
var news_btns: Array = []
var news_sel := 0

# estado de pantallas
var dex_gen := 0
var dex_page := 0
var dex_only_owned := false
var dex_sel := 25
var dex_grid: GridContainer
var dex_page_lbl: Label
var dex_detail: VBoxContainer
var dex_prev: Preview
var gacha_region := 1
var gacha_box: VBoxContainer
var gacha_result: Control
var gp_machine
var gp_info: VBoxContainer
var gp_msg: Label
var gp_btn1: Button
var gp_btn2: Button
var gp_focus: Control
var gp_collection: HFlowContainer
var up_picker: Control = null
var pk_gen := 0
var pk_type := ""
var pk_q := ""
var pk_focus := ""
var slots_ui: Control = null
var slots_busy := false
var goals_tab := "m"
var goals_box: VBoxContainer
var up_box: VBoxContainer
var up_dex := 25
var ban_open := false
var tm_open := false
var main_prev: Preview
var main_card: PanelContainer
var main_info: Label
var main_stats: VBoxContainer
var test_box: VBoxContainer
var test_idx := 0
var test_scores := {}
var test_result_dex := 0
var reset_armed := false
var settings_box: VBoxContainer


# ---------------------------------------------------------------
# Vista previa animada de un Pokemon (hoja Idle, fila 0)
# ---------------------------------------------------------------
class Preview extends Control:
	var dex := 25
	var shiny := false
	var scale_k := 5.0
	var fit_k := 0.92     # cuanto puede ocupar el fotograma respecto al cuadro (trae margen transparente)
	var dark := false
	var t := 0.0
	var frame := 0
	var tr: TextureRect = null
	var walk := false     # usa la hoja Walk (8 direcciones) en lugar de Idle
	var row := 0          # fila de la hoja = dirección

	func setup(d: int, shn: bool = false, k: float = 5.0, drk: bool = false) -> void:
		dex = d
		shiny = shn
		scale_k = k
		dark = drk
		frame = 0
		t = 0.0
		queue_redraw()

	static func anim_of(d: int, wk: bool = false) -> Dictionary:
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		if sm.is_empty():
			return {}
		var a: Dictionary = sm["a"]
		var nm := "Idle" if a.has("Idle") else "Walk"
		if wk and a.has("Walk"):
			nm = "Walk"
		return {"name": nm, "info": a[nm], "sm": sm}

	static func tex_of(d: int, nm: String, shn: bool) -> Texture2D:
		if shn:
			var ps := "res://assets/pokemon/%d/s/%s.png" % [d, nm]
			if ResourceLoader.exists(ps):
				return load(ps)
		var p := "res://assets/pokemon/%d/%s.png" % [d, nm]
		if ResourceLoader.exists(p):
			return load(p)
		return null

	func _process(delta: float) -> void:
		var an: Dictionary = anim_of(dex, walk)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		frame = frame % int(info["n"])
		t += delta * 60.0
		var guard := 0
		while t >= float(info["d"][frame]) and guard < 12:
			guard += 1
			t -= float(info["d"][frame])
			frame = (frame + 1) % int(info["n"])
		queue_redraw()

	func _draw() -> void:
		var an: Dictionary = anim_of(dex, walk)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		var tx: Texture2D = tex_of(dex, String(an["name"]), shiny)
		if tx == null:
			draw_rect(Rect2(size * 0.5 - Vector2(16, 16), Vector2(32, 32)), Color(1, 1, 1, 0.15))
			return
		var w: float = float(info["w"])
		var h: float = float(info["h"])
		var k: float = scale_k
		# ajusta para que no se salga del cuadro
		k = minf(k, minf(size.x / w, size.y / h) * fit_k)
		var pos := Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.5 + h * k * 0.5 - (h - float(info["ay"])) * k * 0.0 - float(info["ay"]) * k + (float(info["ay"]) * k) * 0.0)
		pos = Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.84 - float(info["ay"]) * k)
		draw_set_transform(Vector2(size.x * 0.5, size.y * 0.84), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, w * k * 0.28, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if tr == null:
			tr = TextureRect.new()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(tr)
		var at := AtlasTexture.new()
		at.atlas = tx
		var rows_n: int = maxi(1, int(round(tx.get_height() / h)))
		at.region = Rect2(float(frame) * w, float(mini(row, rows_n - 1)) * h if walk else 0.0, w, h)
		tr.texture = at
		tr.position = pos
		tr.size = Vector2(w * k, h * k)
		tr.modulate = Color(0, 0, 0, 0.9) if dark else Color.WHITE



# ---------------------------------------------------------------
# Pokemon animado que anda y ataca (como en Mundo Misterioso).
# Hojas: columnas = fotogramas, filas = 8 direcciones (0 abajo, 1 abajo-der, 2 der, 3 arriba-der, 4 arriba, 5 arriba-izq, 6 izq, 7 abajo-izq)
# ---------------------------------------------------------------
class Mon extends Node2D:
	var dex := 25
	var shiny := false
	var k := 3.0
	var bounds := Rect2(0.0, 0.0, 200.0, 40.0)
	var wander := true
	var state := "idle"
	var anim := "Idle"
	var frame := 0
	var t := 0.0
	var dir := 0
	var wait := 0.6
	var target := Vector2.ZERO
	var meta: Dictionary = {}
	var sprite: Sprite2D
	var shadow_w := 24.0
	var fx0 := 0.0
	var fx1 := 1.0
	var ysort := false
	var fixed := false      # quieto en su sitio, de frente, y embiste cada cierto tiempo (como en Mundo Misterioso)
	var home := Vector2.ZERO
	var lunge := 22.0
	var fdir := 0
	var walk_ok: Callable = Callable()   # (desde, hasta) -> bool: el camino esta libre de paredes y agua

	func setup(d: int, kk: float, shn: bool, b: Rect2, wd: bool = true) -> void:
		dex = d
		k = kk
		shiny = shn
		bounds = b
		wander = wd
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		meta = sm.get("a", {})
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		position = Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))
		wait = randf_range(0.2, 1.2)
		if meta.has("Idle"):
			shadow_w = float(meta["Idle"]["w"]) * k * 0.22
		_set_anim("Idle")

	func _set_anim(a: String) -> void:
		if meta.is_empty():
			return
		if not meta.has(a):
			a = "Idle" if meta.has("Idle") else "Walk"
		anim = a
		frame = 0
		t = 0.0
		_apply()

	func _lunge_vec() -> Vector2:
		var a: float = float(fdir) * PI / 4.0
		return Vector2(sin(a), cos(a))

	func _face(v: Vector2) -> void:
		var a: float = v.angle()
		dir = posmod(int(floor((PI / 2.0 - a) / (PI / 4.0) + 0.5)), 8)

	func _apply() -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		var tx: Texture2D = Preview.tex_of(dex, anim, shiny)
		if tx == null:
			sprite.visible = false
			return
		sprite.visible = true
		sprite.texture = tx
		sprite.offset = Vector2(-float(am["ax"]), -float(am["ay"]))
		sprite.scale = Vector2(k, k)
		var rows: int = int(am.get("r", 8))
		var w: float = float(am["w"])
		var h: float = float(am["h"])
		sprite.region_rect = Rect2(float(frame) * w, float(mini(dir, rows - 1)) * h, w, h)

	func _next() -> void:
		if randf() < 0.55:
			var tg := position
			var found := false
			for tr in range(10):
				tg = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
				if tg.distance_to(position) < 24.0:
					continue
				if walk_ok.is_valid() and not bool(walk_ok.call(position, tg)):
					continue
				found = true
				break
			if not found:
				wait = 0.3
				return
			target = tg
			state = "walk"
			_face(tg - position)
			_set_anim("Walk")
		else:
			var a := "Attack"
			if randf() < 0.4:
				var opts: Array = []
				for n in ["Shoot", "Charge"]:
					if meta.has(n):
						opts.append(n)
				if not opts.is_empty():
					a = String(opts[randi() % opts.size()])
			if not meta.has(a):
				wait = 1.0
				return
			state = "attack"
			dir = randi() % 8
			_set_anim(a)

	func _process(delta: float) -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		t += delta * 60.0
		var guard := 0
		while t >= float(am["d"][frame]) and guard < 16:
			guard += 1
			t -= float(am["d"][frame])
			frame += 1
			if frame >= int(am["n"]):
				frame = 0
				if state == "attack":
					state = "idle"
					wait = randf_range(1.4, 2.6) if fixed else randf_range(0.5, 1.4)
					_set_anim("Idle")
					am = meta[anim]
		if fixed:
			dir = fdir
			if state == "idle":
				wait -= delta
				position = home
				if wait <= 0.0:
					if meta.has("Attack"):
						state = "attack"
						_set_anim("Attack")
					else:
						wait = 1.5
			elif state == "attack":
				var ai: Dictionary = meta[anim]
				var prog: float = clampf((float(frame) + t / maxf(1.0, float(ai["d"][frame]))) / float(maxi(1, int(ai["n"]))), 0.0, 1.0)
				position = home + _lunge_vec() * sin(prog * PI) * lunge
		elif state == "idle":
			wait -= delta
			if wait <= 0.0 and wander:
				_next()
		elif state == "walk":
			var v: Vector2 = target - position
			var step: float = 46.0 * delta * (k / 3.0)
			if v.length() <= step:
				position = target
				state = "idle"
				wait = randf_range(0.4, 1.2)
				_set_anim("Idle")
			else:
				position += v.normalized() * step
		if not ysort and not fixed:
			z_index = int(position.y)
		_apply()
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.32))


# Fondo del menu: un trozo del mapa del juego que se desplaza solo, con Pokemon caminando.
class MenuWorld extends Node2D:
	const TW = preload("res://scripts/tileworld.gd")
	const MAINS = preload("res://scripts/main.gd")
	const PERIOD := 30.0   # segundos por ambiente, como en el menu del juego original (bosque -> cueva -> volcan)
	const CAST := [1, 4, 7, 25, 133, 52, 39, 35, 16, 43, 60, 69, 74, 92, 129, 147, 113, 143, 54, 79]
	var cam := Vector2.ZERO
	var t := 0.0
	var tw: Node2D            # el mismo terreno que una partida (lagos, paredes, tierra)
	var gen: Node2D           # instancia de main.gd sin escena: solo genera arboles, rocas, hierba y objetos igual que la partida
	var props: Node2D
	var mons: Array = []
	var vs := Vector2(1280, 720)
	var drift := Vector2(1, 0.3)
	var pool: Array = []
	var amb: Ambient = null
	var cur_chunk := Vector2i(99999, 99999)
	var gen_q: Array = []
	var biome_i := 0

	# Particulas de ambiente en pantalla: luciernagas, motas de cueva y ascuas de volcan.
	class Ambient extends Node2D:
		var t := 0.0
		var vs := Vector2(1280, 720)
		var w := [1.0, 0.0, 0.0]

		static func _h(n: float, k: float) -> float:
			var v: float = sin(n * 12.9898 + k * 78.233) * 43758.5453
			return v - floorf(v)

		func _draw() -> void:
			for k in range(3):
				var wk: float = float(w[k])
				if wk <= 0.01:
					continue
				for n in range(44):
					var fn := float(n)
					var r1: float = _h(fn, 1.0 + float(k))
					var r2: float = _h(fn, 7.0 + float(k))
					var r3: float = _h(fn, 13.0 + float(k))
					var pos: Vector2
					var col: Color
					var sz: float = 3.0
					if k == 0:
						pos = Vector2(r1 * vs.x + sin(t * 0.4 + r2 * 6.0) * 40.0, r3 * vs.y * 0.9 + cos(t * 0.3 + r1 * 6.0) * 30.0)
						col = Color(1.0, 0.95, 0.5, (0.5 + 0.5 * sin(t * 1.5 + r2 * 10.0)) * 0.8 * wk)
					elif k == 1:
						pos = Vector2(r1 * vs.x + sin(t * 0.5 + r3 * 9.0) * 20.0, fmod(r3 * vs.y + t * (10.0 + 20.0 * r2), vs.y))
						col = Color(0.7, 0.88, 1.0, 0.55 * wk)
						sz = 2.0 + floorf(r2 * 2.0)
					else:
						var yy: float = fmod(r3 * vs.y + t * (30.0 + 60.0 * r2), vs.y)
						pos = Vector2(r1 * vs.x + sin(t * 1.2 + r2 * 9.0) * 25.0, vs.y - yy)
						col = Color(1.0, 0.55 + 0.3 * r2, 0.15, 0.9 * (1.0 - yy / vs.y) * wk)
					draw_rect(Rect2(pos.round(), Vector2(sz, sz)), col)

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func start() -> void:
		var SVl = load("res://scripts/save_data.gd")
		SVl.ensure()
		# Los mismos 20 Pokemon que pasean por el menu del juego original
		for d in CAST:
			for p in SVl.dex_list:
				if int(p["dex"]) == d and SVl.smeta.has(str(d)):
					pool.append(p)
					break
		cam = Vector2(randf_range(-3000.0, 3000.0), randf_range(-3000.0, 3000.0))
		var sd: int = randi() % 100000
		tw = TW.new()
		add_child(tw)
		tw.setup(sd)
		props = Node2D.new()
		props.y_sort_enabled = true
		add_child(props)
		gen = MAINS.new()
		gen.ground = tw
		gen.world = props
		gen.world_seed = sd
		gen.menu_mode = true
		MAINS.Prop.tw = tw
		vs = get_viewport_rect().size
		_update_chunks(true)
		tw.flush_bake()
		for i in range(pool.size()):
			_spawn_mon(true)
		amb = Ambient.new()
		get_parent().add_child(amb)
		get_parent().move_child(amb, get_index() + 1)
		tree_exiting.connect(func():
			if is_instance_valid(gen):
				gen.free())

	func _update_chunks(first: bool = false) -> void:
		var c: Vector2i = tw.chunk_of(cam)
		tw.center = cam
		if c != cur_chunk:
			cur_chunk = c
			tw.set_center(c)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var key := Vector2i(c.x + dx, c.y + dy)
					if not gen.chunks.has(key) and not gen_q.has(key):
						gen_q.append(key)
			gen_q.sort_custom(func(a, b): return absi(a.x - c.x) + absi(a.y - c.y) < absi(b.x - c.x) + absi(b.y - c.y))
			for key in gen.chunks.keys():
				if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
					gen._free_chunk(key)
		# los trozos nuevos se crean de uno en uno (sin tirones); al empezar, todos de golpe
		var made := 0
		while not gen_q.is_empty():
			var nk: Vector2i = gen_q.pop_front()
			if not gen.chunks.has(nk):
				gen.chunks[nk] = gen._gen_chunk(nk.x, nk.y)
				made += 1
			# al empezar solo los 9 de alrededor; el resto llega de uno en uno
			if not first or made >= 9:
				break

	# Sitio libre: sin pared, agua ni lava alrededor.
	func _free_spot(pos: Vector2) -> bool:
		if tw.liquid_at(pos) != "":
			return false
		for o in [Vector2.ZERO, Vector2(18, 0), Vector2(-18, 0), Vector2(0, 18), Vector2(0, -18)]:
			if tw.collide(pos + o, 14.0) != pos + o:
				return false
		return true

	func _can_stand(m: Node2D, pos: Vector2) -> bool:
		if tw.collide(pos, 14.0) != pos:
			return false
		var liq: String = tw.liquid_at(pos)
		if liq == "":
			return true
		var ty: Array = m.get_meta("types", [])
		return ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))

	func _path_ok(m: Node2D, a: Vector2, b: Vector2) -> bool:
		for i in range(1, 7):
			if not _can_stand(m, a.lerp(b, float(i) / 6.0)):
				return false
		return true

	func _spawn_mon(anywhere: bool) -> void:
		if pool.is_empty():
			return
		# Uno de los 20 del menu original que ahora no este en pantalla
		var used := {}
		for mm in mons:
			used[mm.dex] = true
		var free: Array = []
		for pp in pool:
			if not used.has(int(pp["dex"])):
				free.append(pp)
		if free.is_empty():
			free = pool
		var p: Dictionary = free[randi() % free.size()]
		var pos: Vector2 = Vector2.ZERO
		var good := false
		for tries in range(40):
			if anywhere:
				pos = cam + Vector2(randf_range(-vs.x * 0.5, vs.x * 0.5), randf_range(-vs.y * 0.5, vs.y * 0.5))
			else:
				var side: Vector2 = drift.normalized()
				var perp := Vector2(-side.y, side.x)
				pos = cam + side * (vs.x * 0.5 + 120.0) + perp * randf_range(-vs.y * 0.5, vs.y * 0.5)
			if _free_spot(pos):
				good = true
				break
		if not good:
			return   # sin sitio razonable: no aparece (mejor que dentro de una pared)
		var m := Mon.new()
		m.ysort = true
		m.setup(int(p["dex"]), 2.4, randf() < 0.03, Rect2(pos - Vector2(170.0, 90.0), Vector2(340.0, 180.0)), true)
		m.position = pos
		m.set_meta("types", p.get("types", []))
		m.walk_ok = func(a: Vector2, b: Vector2) -> bool: return _path_ok(m, a, b)
		m.set_meta("lp", pos)
		props.add_child(m)
		mons.append(m)

	func _process(delta: float) -> void:
		t += delta
		vs = get_viewport_rect().size
		var ang: float = 0.3 + sin(t * 0.05) * 0.9
		drift = Vector2.from_angle(ang)
		cam += drift * 26.0 * delta
		position = vs * 0.5 - cam
		_update_chunks()
		for m in mons.duplicate():
			var pushed: Vector2 = tw.collide(m.position, 12.0)   # no atraviesan paredes (como en el juego original)
			if pushed.distance_to(m.position) > 0.5:
				m.position = pushed
				if m.state == "walk":   # chocó con una pared: se para y elige otro destino
					m.state = "idle"
					m.wait = 0.15
					m._set_anim("Idle")
			# agua: solo tipo agua o volador; lava: solo fuego o volador; el resto da la vuelta
			var liq: String = tw.liquid_at(m.position)
			if liq != "":
				var ty: Array = m.get_meta("types")
				var ok: bool = ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))
				if not ok:
					m.position = m.get_meta("lp")
					m.target = m.position
					m.wait = 0.5
			m.set_meta("lp", m.position)
			if absf(m.position.x - cam.x) > vs.x * 0.5 + 520.0 or absf(m.position.y - cam.y) > vs.y * 0.5 + 420.0:
				mons.erase(m)
				m.queue_free()
				_spawn_mon(false)
		# ambiente: bosque -> cueva de cristal -> volcan, como el original: el mismo mapa con los recursos de cada bioma
		var bi: int = int(floor(t / PERIOD)) % 3
		if bi != biome_i:
			biome_i = bi
			tw.set_biome(bi)
		if amb != null:
			var pv := [0.0, 0.0, 0.0]
			var kf: float = tw.fade_t * tw.fade_t * (3.0 - 2.0 * tw.fade_t)
			pv[tw.prev_biome % 3] += 1.0 - kf
			pv[biome_i] += kf
			amb.t = t
			amb.vs = vs
			amb.w = pv
			amb.queue_redraw()



# Escenario del Gacha: degradado de la region + Pokemon que se mueven.
class Banner extends Control:
	var c1 := Color("#5b2f8f")
	var c2 := Color("#1f6f7a")
	var mons: Array = []

	func _init() -> void:
		clip_contents = true

	func add_mon(d: int, kk: float, f0: float, f1: float) -> void:
		var m := Mon.new()
		m.fx0 = f0
		m.fx1 = f1
		add_child(m)
		m.setup(d, kk, false, Rect2(f0 * 700.0, 250.0, (f1 - f0) * 700.0, 60.0), false)
		m.fixed = true
		m.fdir = 1   # diagonal abajo-derecha
		m.dir = 1
		m.wait = 0.5 + 0.9 * float(mons.size())
		mons.append(m)
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		for m in mons:
			# fila fija: centrada en su tercio, todos a la misma altura
			m.home = Vector2((m.fx0 + m.fx1) * 0.5 * size.x, size.y * 0.80)
			m.position = m.home

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
		var cols := PackedColorArray([c1, c1.lerp(c2, 0.5), c2, c1.lerp(c2, 0.5)])
		draw_polygon(pts, cols)
		draw_circle(Vector2(w * 0.55, h * 0.4), h * 0.6, Color(1, 1, 1, 0.05))
		draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(1.5, 1.5, w - 3.0, h - 3.0), Color(0.7, 0.78, 1.0, 0.75), false, 3.0)


# Retrato del Pokemon (pantalla de mejoras)
class Portrait extends Control:
	var edge := Color("#ff7b3d")
	var mon: Mon = null

	func _init() -> void:
		clip_contents = true

	func setup(d: int, col: Color, k: float = 3.0) -> void:
		edge = col
		if mon != null:
			mon.queue_free()
		mon = Mon.new()
		add_child(mon)
		mon.setup(d, k, false, Rect2(60.0, 120.0, 80.0, 24.0), false)
		mon.dir = 0
		mon.ysort = true   # sin z_index propio: nunca queda por encima de menus y resultados
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		if mon != null:
			# Quieto, centrado y mirando al frente; solo se anima en el sitio.
			mon.position = Vector2(size.x * 0.5, size.y * 0.82)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([Color("#142a5c"), Color("#142a5c"), Color("#0a1230"), Color("#0a1230")]))
		draw_rect(Rect2(2, 2, w - 4.0, h - 4.0), edge, false, 4.0)


# Barras de nivel (pips)
class Pips extends Control:
	var lv := 0
	var mx := 5

	func setup(l: int, m: int) -> void:
		lv = l
		mx = m
		custom_minimum_size = Vector2(float(m) * 18.0, 10.0)
		queue_redraw()

	func _draw() -> void:
		for i in range(mx):
			draw_rect(Rect2(float(i) * 18.0, 1.0, 14.0, 8.0), Color("#ffd23f") if i < lv else Color("#46558a"))


# ---------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------
# Foco de mando: borde negro con halo blanco (se ve sobre dorado, gris y azul).
const TOWER_FLOORS_M := 60

func _sb_focus(col: Color) -> StyleBoxFlat:
	var s := _sb(col, Color.BLACK, 4, 12)
	s.shadow_color = Color.WHITE
	s.shadow_size = 4
	s.shadow_offset = Vector2.ZERO
	return s


func _sb(col: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _apply_ui_theme(i: int) -> void:
	i = clampi(i, 0, UI_THEMES.size() - 1)
	SV.d["ui_theme"] = i
	SV.save()
	var t: Array = UI_THEMES[i]
	C_PANEL = Color(String(t[0]))
	C_PANEL_D = Color(String(t[1]))
	C_BTN = Color(String(t[3]))
	C_BTN_H = Color(String(t[4]))
	_build_theme()


func _build_theme() -> void:
	theme_main.default_font_size = 22
	PXF.apply(theme_main)
	theme_main.set_stylebox("normal", "Button", _sb(C_BTN, Color("#6f8be0"), 2))
	theme_main.set_stylebox("hover", "Button", _sb(C_BTN_H, Color("#9fb4f0"), 2))
	theme_main.set_stylebox("pressed", "Button", _sb(C_PANEL_D, C_GOLD, 2))
	theme_main.set_stylebox("focus", "Button", _sb(C_BTN_H, C_GOLD, 4))
	theme_main.set_stylebox("disabled", "Button", _sb(Color("#222c4a"), Color("#3a456a"), 2))
	theme_main.set_color("font_color", "Button", Color.WHITE)
	theme_main.set_color("font_disabled_color", "Button", Color("#7d86a6"))
	theme_main.set_stylebox("panel", "PanelContainer", _sb(C_PANEL, Color.WHITE, 3, 10))
	theme_main.set_stylebox("fill", "ProgressBar", _sb(Color("#5fe08a"), Color.TRANSPARENT, 0, 4))
	theme_main.set_stylebox("background", "ProgressBar", _sb(Color("#101a3e"), Color.TRANSPARENT, 0, 4))
	theme_main.set_constant("separation", "VBoxContainer", 10)
	theme_main.set_constant("separation", "HBoxContainer", 10)
	theme = theme_main


func _ready() -> void:
	TXS.hook(self)
	get_tree().node_added.connect(_on_node_added)
	SV.ensure()
	var th0: Array = UI_THEMES[clampi(int(SV.d.get("ui_theme", 1)), 0, UI_THEMES.size() - 1)]
	C_PANEL = Color(String(th0[0])); C_PANEL_D = Color(String(th0[1])); C_BTN = Color(String(th0[3])); C_BTN_H = Color(String(th0[4]))
	is_overlay = bool(Engine.get_meta("menu_overlay", false))
	Engine.set_meta("menu_overlay", false)
	L.apply()
	DSP.menu_mode = true
	DSP.apply(get_tree())
	PAD.apply()
	if not is_overlay:
		DSP.apply_window()
		Aud.setup(self)
		Aud.music("village")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	RenderingServer.set_default_clear_color(Color("#16233a"))
	# fondo: un trozo del mapa que se desplaza solo, con Pokemon caminando
	if not is_overlay:
		var world := MenuWorld.new()
		world.z_index = -4000   # el fondo siempre queda detras de toda la interfaz
		add_child(world)
		world.start()
		var upd := UPD.new()
		add_child(upd)
		upd.found.connect(func(info: Dictionary):
			var pop := UPD.UpdatePopup.new()
			add_child(pop)
			pop.build(info))
		upd.start()
	shade = ColorRect.new()
	shade.color = Color(0, 0.05, 0.1, 0.30)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	# barra superior
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var ins: Vector4 = DSP.insets(get_tree())
	top.offset_left = 16 + ins.x
	top.offset_right = -16 - ins.z
	top.offset_top = 10 + ins.y
	top.offset_bottom = 58
	add_child(top)
	back_btn = _btn("◀ Volver", func(): _leave(), Vector2(150, 44))
	top.add_child(back_btn)
	credit_lbl = Label.new()
	credit_lbl.text = L.t("Hecho por JayElDragon")
	credit_lbl.add_theme_font_size_override("font_size", 18)
	credit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit_lbl.custom_minimum_size = Vector2(118, 0)
	credit_lbl.add_theme_color_override("font_color", Color("#ffe9a8"))
	credit_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	credit_lbl.add_theme_constant_override("outline_size", 6)
	credit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box = VBoxContainer.new()
	credit_box.add_theme_constant_override("separation", -4)
	credit_box.alignment = BoxContainer.ALIGNMENT_CENTER
	credit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box.custom_minimum_size = Vector2(118, 0)
	credit_box.add_child(credit_lbl)
	var ver_lbl := Label.new()
	ver_lbl.text = L.t("Versión") + " " + UPD.APP_VERSION
	ver_lbl.add_theme_font_size_override("font_size", 16)
	ver_lbl.add_theme_color_override("font_color", Color("#c8d6ee"))
	ver_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	ver_lbl.add_theme_constant_override("outline_size", 5)
	ver_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box.add_child(ver_lbl)
	# El credito va abajo a la izquierda: asi la barra superior termina antes del menu de la derecha.
	credit_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	credit_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credit_box.offset_left = 24 + ins.x
	credit_box.offset_top = -108 - ins.w
	credit_box.offset_bottom = -54 - ins.w
	credit_box.custom_minimum_size = Vector2(300, 0)
	credit_lbl.custom_minimum_size = Vector2(300, 0)
	credit_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(credit_box)
	# Barra superior como la del original: monedas, tickets, nombre, sonido y ajustes.
	coin_pill = _pill()
	coin_lbl = _pill_item(coin_pill, "coin", C_GOLD)
	tix_pill = _pill()
	ticket_lbl = _pill_item(tix_pill, "ticket", C_GOLD)
	ticket10_lbl = _pill_item(tix_pill, "ticket10", Color("#c47bff"))
	name_pill = _icon_btn("crown", func(): _show("profile"))
	name_pill.custom_minimum_size = Vector2(0, 44)
	name_pill.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_pill.add_theme_font_size_override("font_size", 22)
	name_pill.add_theme_constant_override("h_separation", 10)
	name_lbl = name_pill
	top.add_child(coin_pill)
	top.add_child(_gap(8))
	top.add_child(tix_pill)
	top.add_child(_gap(8))
	top.add_child(name_pill)
	top.add_child(_gap(8))
	news_top = _icon_btn("news", func(): if cur != "news": _show("news"))
	news_top.tooltip_text = L.t("Novedades")   # solo icono: la barra superior debe caber en cualquier pantalla
	news_top.custom_minimum_size = Vector2(52, 44)
	top.add_child(news_top)
	top.add_child(_gap(8))
	support_top = _icon_btn("heart", func(): if cur != "support": _show("support"))
	support_top.tooltip_text = L.t("Apoyar")
	support_top.custom_minimum_size = Vector2(52, 44)
	support_top.add_theme_stylebox_override("normal", _sb(Color("#f4b93a"), Color("#fff1b8"), 2, 12))
	support_top.add_theme_stylebox_override("hover", _sb(Color("#ffd066"), Color.WHITE, 2, 12))
	support_top.add_theme_color_override("font_color", Color("#3a2200"))
	support_top.add_theme_color_override("font_hover_color", Color("#3a2200"))
	support_top.add_theme_color_override("font_focus_color", Color("#3a2200"))
	top.add_child(support_top)
	top.add_child(_gap(8))
	mute_top = _icon_btn("sound", func(): _toggle_mute_top())
	top.add_child(mute_top)
	top.add_child(_gap(8))
	set_top = _icon_btn("gear", func(): if cur != "settings": _show("settings"))
	top.add_child(set_top)
	var sp := Control.new()   # todo queda a la izquierda; el menu principal ocupa la derecha
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	toast_lbl = Label.new()
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.offset_left = -300
	toast_lbl.offset_right = 300
	toast_lbl.offset_top = -80
	toast_lbl.offset_bottom = -30
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 24)
	toast_lbl.add_theme_color_override("font_color", C_GOLD)
	toast_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_lbl.add_theme_constant_override("outline_size", 6)
	toast_lbl.z_index = 50
	add_child(toast_lbl)
	ach_pop = PanelContainer.new()
	ach_pop.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ach_pop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ach_pop.offset_top = 64
	ach_pop.z_index = 60
	ach_pop.visible = false
	ach_pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var apsb := _sb(Color("#25479a"), Color("#ffd23f"), 3, 12)
	apsb.set_expand_margin_all(3)
	apsb.shadow_color = Color("#0b1838")
	apsb.shadow_size = 3
	apsb.content_margin_left = 18
	apsb.content_margin_right = 22
	apsb.content_margin_top = 10
	apsb.content_margin_bottom = 10
	ach_pop.add_theme_stylebox_override("panel", apsb)
	ach_box = HBoxContainer.new()
	ach_box.add_theme_constant_override("separation", 12)
	ach_pop.add_child(ach_box)
	add_child(ach_pop)
	pad_hint = HBoxContainer.new()
	pad_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad_hint.offset_left = 24
	pad_hint.offset_top = -46
	pad_hint.offset_bottom = -6
	pad_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad_hint.add_theme_constant_override("separation", 8)
	pad_hint.z_index = 49
	pad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pad_hint)
	_build_main()
	_build_test()
	_build_dex()
	_build_modes()
	_build_chal()
	_build_up()
	_build_gacha()
	_build_gachapon()
	_build_goals()
	_build_profile()
	_build_lexicon()
	_build_settings()
	_build_news()
	_build_support()
	# El gui elige el control por orden en el arbol (no por z_index): el panel de resultados/tarjetas
	# debe ser el ultimo hijo o los toques lo atraviesan y pulsan los botones de la pantalla de debajo.
	move_child(gacha_result, get_child_count() - 1)
	if is_overlay:
		_show("settings")
		return
	if SV.reopen != "":
		var ro: String = SV.reopen
		SV.reopen = ""
		_show(ro)
	elif SV.owned_count() == 0:
		_show("test")
	else:
		_show("main")
		if PN.should_show():
			_show("news")
		elif not SV.last_run.is_empty():
			_show_run_summary()


func _gap(w: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(w, 0)
	return g


# Capsula oscura con borde claro (pildora de la barra superior del original).
func _pill() -> PanelContainer:
	var pc := PanelContainer.new()
	var sbx := _sb(Color("#0f2268"), Color("#b5cdfb"), 3, 24)
	sbx.content_margin_left = 16
	sbx.content_margin_right = 16
	sbx.content_margin_top = 6
	sbx.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sbx)
	pc.custom_minimum_size = Vector2(0, 44)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(h)
	return pc


func _pill_item(pc: PanelContainer, icon: String, col: Color) -> Label:
	var h: HBoxContainer = pc.get_child(0)
	if h.get_child_count() > 0:
		h.add_child(_gap(6))
	var ic := IC.rect(icon, 26)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := Label.new()
	l.add_theme_color_override("font_color", Color.WHITE if icon == "coin" else col)
	l.add_theme_font_size_override("font_size", 22)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return l


func _icon_btn(icon: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(52, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.icon = IC.tex(icon, IC.scale_for(icon, 26))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_stylebox_override("normal", _sb(Color("#0f2268"), Color("#b5cdfb"), 3, 14))
	b.add_theme_stylebox_override("hover", _sb(Color("#1c3e94"), Color.WHITE, 3, 14))
	b.add_theme_stylebox_override("pressed", _sb(Color("#0b1a55"), Color.WHITE, 3, 14))
	b.add_theme_stylebox_override("focus", _sb(Color(0.12, 0.2, 0.4, 0.8), C_GOLD, 3, 12))
	b.pressed.connect(func():
		Aud.sfx("click")
		cb.call())
	return b


func _toggle_mute_top() -> void:
	SV.d["settings"]["mute"] = not bool(SV.d["settings"].get("mute", false))
	SV.save()
	if Aud.inst != null:
		Aud.inst.apply()
	_update_top()


func _chip(icon: String = "") -> Label:
	var l := Label.new()
	var sbx := _sb(Color(0, 0, 0, 0.55), Color.WHITE, 2, 22)
	sbx.content_margin_left = 46
	l.add_theme_stylebox_override("normal", sbx)
	l.add_theme_color_override("font_color", C_GOLD)
	l.custom_minimum_size = Vector2(150, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if icon != "":
		var ic := IC.rect(icon, 24)
		ic.position = Vector2(12, 10)
		l.add_child(ic)
	return l


# Boton con iconos dentro: [icono] titulo + coste con su propio icono.
func _cost_btn(title: String, cost: String, icon: String, cost_icon: String, cb: Callable, min_size: Vector2, enabled: bool = true, vertical: bool = false, gold: bool = false) -> Button:
	var b := _btn("", cb, min_size)
	b.disabled = not enabled
	var tcol: Color = Color.WHITE
	if gold:
		_gold_btn(b, enabled)
		tcol = Color.WHITE if enabled else Color.BLACK
		if not enabled:
			for st0 in ["normal", "hover", "pressed", "disabled"]:
				b.add_theme_stylebox_override(st0, _sb(Color("#a89c82"), Color("#6b6250"), 3, 12))
			b.add_theme_stylebox_override("focus", _sb_focus(Color("#b8ad94")))
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	if not enabled and not gold:
		hb.modulate = Color(1, 1, 1, 0.5)
	if icon != "":
		hb.add_child(IC.rect(icon, 32))
	var holder: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("separation", 8 if not vertical else 0)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if title != "":
		var tl := _label(title, 22, tcol)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if gold:
			tl.add_theme_constant_override("outline_size", 5 if enabled else 0)
			tl.add_theme_color_override("font_outline_color", Color("#3a2606"))
		holder.add_child(tl)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.add_theme_constant_override("separation", 6)
	cr.add_child(IC.rect(cost_icon, 24))
	var cl := _label(cost, 22, tcol if gold else C_GOLD)
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gold:
		cl.add_theme_constant_override("outline_size", 5 if enabled else 0)
		cl.add_theme_color_override("font_outline_color", Color("#3a2606"))
	cr.add_child(cl)
	holder.add_child(cr)
	hb.add_child(holder)
	b.add_child(hb)
	return b


# Boton dorado (se puede pagar) o marron apagado (no alcanza).
func _gold_btn(b: Button, on: bool) -> void:
	var c := Color("#f7b733") if on else Color("#8c7f66")
	var edge := Color("#fff4d0") if on else Color("#5b5240")
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _sb(c, edge, 3, 12))
	b.add_theme_stylebox_override("focus", _sb_focus(c.lightened(0.15)))


func _card_sb() -> StyleBoxFlat:
	var sb := _sb(Color(0.08, 0.14, 0.36, 0.8), Color("#33498f"), 2, 14)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


# Fila [icono] texto
func _icon_label(icon: String, text: String, size: int = 22, col: Color = Color.WHITE, isz: float = 24.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(IC.rect(icon, isz))
	var l := _label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return h


func _btn(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	return b


# Con mando: el ScrollContainer sigue al control enfocado.
# Si no hay nada enfocable mas abajo (o arriba) pero el menu sigue, el D-pad desplaza la lista.
func _scroll_fallback(down: bool) -> bool:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or not screens.has(cur):
		return false
	var p: Node = f.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p == null:
		return false
	var sc := p as ScrollContainer
	var nb: Control = f.find_valid_focus_neighbor(SIDE_BOTTOM if down else SIDE_TOP)
	if nb != null and sc.is_ancestor_of(nb):
		return false
	if nb != null and not down:
		sc.scroll_vertical = 0   # el foco sale de la lista hacia arriba (pestañas): que el contenido suba del todo
		return false
	var mx: float = maxf(0.0, (sc.get_v_scroll_bar().max_value - sc.size.y))
	var cur_v: float = float(sc.scroll_vertical)
	if down and cur_v >= mx - 1.0:
		return false
	if not down and cur_v <= 0.0:
		return false
	sc.scroll_vertical = int(cur_v + (140.0 if down else -140.0))
	return true


func _follow_focus() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and is_visible_in_tree():
		_follow(f)


func _follow(c: Control) -> void:
	var p: Node = c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).call_deferred("ensure_control_visible", c)
		call_deferred("_follow_top", p as ScrollContainer, c)


# Si el foco llega al primer control de la lista, se sube del todo para ver el título y lo que haya encima.
func _follow_top(sc: ScrollContainer, c: Control) -> void:
	if not is_instance_valid(sc) or not is_instance_valid(c):
		return
	var first: Control = null
	for n in NAVG.focusables(sc):
		var cn := n as Control
		if first == null or cn.get_global_rect().position.y < first.get_global_rect().position.y - 1.0:
			first = cn
	if first != null and (first == c or absf(first.get_global_rect().position.y - c.get_global_rect().position.y) < 2.0):
		sc.scroll_vertical = 0


func _panel(parent: Node) -> VBoxContainer:
	var pc := PanelContainer.new()
	parent.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	return v


func _label(text: String, size: int = 22, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _screen(name: String) -> Control:
	var c := MarginContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ins: Vector4 = DSP.insets(get_tree())
	c.add_theme_constant_override("margin_left", 24 + int(ins.x))
	c.add_theme_constant_override("margin_right", 24 + int(ins.z))
	c.add_theme_constant_override("margin_top", 72 + int(ins.y))
	c.add_theme_constant_override("margin_bottom", 18 + int(ins.w))
	c.visible = false
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	screens[name] = c
	return c


func _leave() -> void:
	if cur == "chal":
		_show("modes")
		return
	if is_overlay:
		closed.emit()
		queue_free()
	else:
		_show("main")


func _show(name: String) -> void:
	if name == "up" and cur != "up":
		up_dex = int(SV.d["selected"])
	_close_up_picker()
	cur = name
	if name != "dex":
		dex_pick_party = false
		dex_pick_team = false
		dex_pick_coop = false
	for k in screens:
		screens[k].visible = k == name
	back_btn.visible = name != "main" and name != "test"
	credit_box.visible = name == "main"
	shade.color.a = 0.30 if name == "main" else 0.62
	for pn in [coin_pill, tix_pill, name_pill, news_top, support_top, mute_top, set_top]:
		pn.visible = name != "test"
	if is_overlay:
		for pn2 in [coin_pill, tix_pill, name_pill, news_top, support_top, mute_top, set_top]:
			pn2.visible = false
		shade.color.a = 0.8
	_update_top()
	focus_first = null
	call("_refresh_" + name)
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)
	if name == "modes":
		_modes_to_top()


# Sube del todo la lista de modos (despues del foco, que a veces la desplaza hacia abajo).
func _modes_to_top() -> void:
	for i in range(3):
		await get_tree().process_frame
		if cur != "modes" or modes_box == null or not is_instance_valid(modes_box):
			return
		var msc: Node = modes_box.get_parent().get_parent()
		if msc is ScrollContainer and modes_sel == String(MODE_LIST[0][0]):
			(msc as ScrollContainer).scroll_vertical = 0


func _gf(c: Control) -> void:
	call_deferred("_do_focus", c)


func _do_focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
		c.grab_focus()


func _update_top() -> void:
	coin_lbl.text = "%d" % int(SV.d["coins"])
	ticket_lbl.text = "%d" % int(SV.d["tickets"])
	ticket10_lbl.text = "%d" % int(SV.d.get("tickets10", 0))
	var tt: String = String(SV.d.get("title", ""))
	name_lbl.text = _nick().left(12)
	var muted: bool = bool(SV.d["settings"].get("mute", false))
	var mn: String = "mute" if muted else "sound"
	mute_top.icon = IC.tex(mn, IC.scale_for(mn, 26))


func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_t = 2.6


# Ayuda de mando abajo a la izquierda: icono del boton + accion (sin texto del boton).
func _build_pad_hint() -> void:
	for c in pad_hint.get_children():
		pad_hint.remove_child(c)
		c.queue_free()
	for pair in [[PAD.confirm_btn(), "Aceptar"], [PAD.cancel_btn(), "Atrás"]]:
		pad_hint.add_child(PADI.rect(int(pair[0]), 36.0))
		var l := _label(L.t(String(pair[1])), 20, Color("#c8d6ee"))
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		pad_hint.add_child(l)
		pad_hint.add_child(_gap(10))


# Todo lo que cuelga de un ScrollContainer deja pasar el gesto del dedo (si no, las tarjetas lo tragan y la lista no se mueve).
func _on_node_added(n: Node) -> void:
	if not (n is Control) or n is BaseButton or n is Range or n is LineEdit or n is TextEdit or n is ScrollContainer:
		return
	if not is_ancestor_of(n):
		return
	var p: Node = n.get_parent()
	while p != null and p != self:
		if p is ScrollContainer:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()


# Las tarjetas (PanelContainer) paran los gestos del dedo y el ScrollContainer no se mueve: las dejamos pasar.
func _touch_pass(node: Node) -> void:
	for c in node.get_children():
		if c is Control and not (c is BaseButton) and not (c is ProgressBar) and not (c is Range):
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_touch_pass(c)


# Stick izquierdo y cruceta (mantenidos): desplazan las listas del Lexico y de Misiones/logros/Cristales Z (el contenido no tiene botones que enfocar).
func _stick_scroll(delta: float) -> void:
	if not (cur == "lexicon" or cur == "goals") or not screens.has(cur):
		return
	if gacha_result != null and gacha_result.visible:
		return
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	# El stick izquierdo ya navega como cruceta (PAD.stick_event): aqui solo la cruceta mantenida.
	var ay := 0.0
	if Input.is_joy_button_pressed(int(pads[0]), JOY_BUTTON_DPAD_DOWN):
		ay = 0.7
	elif Input.is_joy_button_pressed(int(pads[0]), JOY_BUTTON_DPAD_UP):
		ay = -0.7
	if ay == 0.0:
		return
	var sc: ScrollContainer = _first_scroll(screens[cur])
	if sc == null:
		return
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and sc.is_ancestor_of(f):
		return   # el foco esta en la lista: ya la sigue el mando
	if f != null and f.find_valid_focus_neighbor(SIDE_BOTTOM if ay > 0.0 else SIDE_TOP) != null:
		return   # hay un control enfocable en esa dirección: lo gestiona la navegación
	sc.scroll_vertical += int(ay * 900.0 * delta)


func _first_scroll(n: Node) -> ScrollContainer:
	if n is ScrollContainer:
		return n as ScrollContainer
	for c in n.get_children():
		var r: ScrollContainer = _first_scroll(c)
		if r != null:
			return r
	return null


func _process(delta: float) -> void:
	PAD.stick_tick()
	_stick_scroll(delta)
	if pad_hint != null:
		var has_pad := Input.get_connected_joypads().size() > 0
		pad_hint.visible = false   # sin la ayuda "Aceptar / Atrás" de mando: tapaba las listas
		if false and has_pad:
			var hk := "%d_%d_%d_%s" % [PAD.layout(), PAD.confirm_btn(), PAD.cancel_btn(), L.t("Aceptar")]
			if hk != pad_hint_key:
				pad_hint_key = hk
				_build_pad_hint()
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_lbl.text = ""
	if ach_t > 0.0:
		ach_t -= delta
		ach_pop.modulate.a = clampf(minf(ach_t, 2.8 - ach_t + 0.001) * 4.0, 0.0, 1.0)
		ach_pop.position.x = (get_viewport_rect().size.x - ach_pop.size.x) * 0.5
		if ach_t <= 0.0:
			ach_pop.visible = false
	elif not PG.toasts.is_empty() and not is_overlay:
		var tt: Dictionary = PG.toasts.pop_front()
		var msg: String = L.t(String(tt["title"])) % L.t(String(tt["arg"]))
		var sub := ""
		if String(tt["sub"]) != "":
			sub = L.t(String(tt["sub"])) % String(tt["subarg"]) if String(tt["subarg"]) != "" else L.t(String(tt["sub"]))
		_ach_toast(msg, sub, int(tt["tier"]))
		Aud.sfx("legend")
		_update_top()


# Aviso de logro: caja azul con borde dorado y la medalla, como en el juego original.
func _ach_toast(msg: String, sub: String, tier: int) -> void:
	for c in ach_box.get_children():
		c.queue_free()
	var mi := IC.rect("medal%d" % clampi(tier, 1, 3), 36)
	mi.custom_minimum_size.x = 40
	ach_box.add_child(mi)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	ach_box.add_child(col)
	var l := _label(msg, 24, Color("#ffd23f"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(l)
	if sub != "":
		var l2 := _label(sub, 16, Color("#b9cbf0"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(l2)
	ach_pop.reset_size()
	ach_pop.visible = true
	ach_pop.modulate.a = 0.0
	ach_t = 2.8


var back_t := 0.0


func _exit_tree() -> void:
	DSP.menu_mode = false
	if get_tree() != null:
		DSP.apply(get_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


# Atras: cierra el cuadro abierto, sube al menu principal o (en el principal) pide pulsar otra vez para salir.
func _go_back() -> void:
	if listening != "":
		listening = ""
		_refresh_listen()
		return
	if slots_busy:
		slots_ui.fast = true
		return
	if cur == "gachapon" and gp_machine != null and gp_machine.busy():
		gp_machine.speed_up()   # atras/cancelar tambien acelera la animacion (S37)
		return
	if gacha_result != null and gacha_result.visible:
		gacha_result.visible = false
		if cur == "gacha":
			_refresh_gacha()
		elif cur == "gachapon":
			_refresh_gachapon()
		return
	if up_picker != null and is_instance_valid(up_picker):
		_close_up_picker()
		return
	if cur != "main" and cur != "test":
		_leave()
		return
	if cur == "main":
		if Time.get_ticks_msec() / 1000.0 - back_t < 2.0:
			get_tree().quit()
		else:
			back_t = Time.get_ticks_msec() / 1000.0
			toast(L.t("Pulsa atrás otra vez para salir"))


func _popup_open() -> bool:
	for n in find_children("*", "OptionButton", true, false):
		if (n as OptionButton).get_popup().visible:
			return true
	return false


# --- Desplazamiento arrastrando (dedo o raton) tambien ENCIMA de los botones: Godot no lo hace solo y las listas se quedaban fijas.
var _ds_sc: ScrollContainer = null
var _ds_start := Vector2.ZERO
var _ds_move := false
var _ds_acc := 0.0
const DS_THRESHOLD := 12.0


func _scroll_under(n: Node, pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return null
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		var bar: VScrollBar = sc.get_v_scroll_bar()
		if sc.get_global_rect().has_point(pos) and bar.max_value - bar.page > 1.0 and sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			best = sc
	for c in n.get_children():
		var r: ScrollContainer = _scroll_under(c, pos)
		if r != null:
			best = r   # el mas profundo gana
	return best


func _drag_scroll(event: InputEvent) -> bool:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_ds_sc = null
			_ds_move = false
			_ds_acc = 0.0
			var hov: Control = get_viewport().gui_get_hovered_control()
			if hov is Range or hov is LineEdit or hov is TextEdit or hov is OptionButton:
				return false
			var root: Node = screens[cur] if screens.has(cur) else self
			_ds_sc = _scroll_under(root, mb.position)
			_ds_start = mb.position
			return false
		else:
			var was: bool = _ds_move
			_ds_sc = null
			_ds_move = false
			return was   # el soltar tras arrastrar no debe pulsar nada
	if event is InputEventMouseMotion and _ds_sc != null and is_instance_valid(_ds_sc):
		var mm := event as InputEventMouseMotion
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_ds_sc = null
			return false
		if not _ds_move:
			if absf(mm.position.y - _ds_start.y) < DS_THRESHOLD:
				return false
			_ds_move = true
			_ds_sc.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)   # cancela el boton que se estaba pulsando
		_ds_acc -= mm.relative.y
		var step: int = int(_ds_acc)
		if step != 0:
			_ds_sc.scroll_vertical += step
			_ds_acc -= float(step)
		return true
	return false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# v5.2.1: escribiendo en un campo de texto (nombre de entrenador, buscadores) el teclado es del campo:
	# antes Borrar/Retroceso contaba como "atrás", cerraba la pantalla y no se podía borrar ni pegar.
	var typing: Control = get_viewport().gui_get_focus_owner()
	if (typing is LineEdit or typing is TextEdit) and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			typing.release_focus()
			DisplayServer.virtual_keyboard_hide()
			get_viewport().set_input_as_handled()
		return
	# En la lista de modos el stick solo mueve arriba/abajo: un empuje lateral sin querer ya no mete el cursor en los modificadores.
	var sf: Control = get_viewport().gui_get_focus_owner()
	PAD.vertical_only = cur == "modes" and sf != null and mode_tiles.values().has(sf)
	if listening == "" and PAD.stick_event(event):
		get_viewport().set_input_as_handled()   # el stick izquierdo navega como cruceta (un salto por empujon)
		return
	if listening != "":
		if event is InputEventJoypadButton and event.pressed:
			PAD.set_btn(listening, event.button_index)
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
	# L1/R1 (o los botones prev/next): cambian de pestana en el Lexico y en Misiones y logros
	if event is InputEventJoypadButton and event.pressed and (cur == "lexicon" or cur == "goals") and not (gacha_result != null and gacha_result.visible):
		if event.button_index == PAD.btn("prev") or event.button_index == PAD.btn("next"):
			var dd := -1 if event.button_index == PAD.btn("prev") else 1
			if cur == "lexicon":
				var lk: Array = ["m", "f", "i", "s", "a", "z", "k", "n"]
				lex_tab = String(lk[posmod(lk.find(lex_tab) + dd, lk.size())])
				_refresh_lexicon()
			else:
				var gk: Array = ["m", "a", "h", "z", "r"]
				goals_tab = String(gk[posmod(gk.find(goals_tab) + dd, gk.size())])
				_refresh_goals()
			if tab_sel != null and is_instance_valid(tab_sel):
				tab_sel.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton and event.pressed and cur == "gacha" and not (gacha_result != null and gacha_result.visible):
		if event.button_index == PAD.btn("prev") or event.button_index == PAD.btn("next"):
			var d := -1 if event.button_index == PAD.btn("prev") else 1
			gacha_region = posmod(gacha_region - 1 + d, SV.REGIONS.size()) + 1
			_refresh_gacha()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_left") and cur in ["settings", "goals", "gacha", "lexicon"] and tab_sel != null and is_instance_valid(tab_sel) and tab_row != null:
		var f0: Control = get_viewport().gui_get_focus_owner()
		if f0 != null and not tab_row.is_ancestor_of(f0) and screens.has(cur) and screens[cur].is_ancestor_of(f0):
			var nb: Control = f0.find_valid_focus_neighbor(SIDE_LEFT)
			if nb == null or not screens[cur].is_ancestor_of(nb):
				tab_sel.grab_focus()
				get_viewport().set_input_as_handled()
				return
	if cur == "modes" and event.is_action_pressed("ui_left"):
		var lf3: Control = get_viewport().gui_get_focus_owner()
		if lf3 is CheckButton and lf3.get_parent() is GridContainer and mp_opts.is_ancestor_of(lf3):
			var gi: int = lf3.get_parent().get_children().find(lf3)
			if gi % (lf3.get_parent() as GridContainer).columns == 0 and mode_tiles.has(modes_sel):
				(mode_tiles[modes_sel] as Control).grab_focus()
				get_viewport().set_input_as_handled()
				return
	if cur == "modes" and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
		var mf: Control = get_viewport().gui_get_focus_owner()
		var mdn: bool = event.is_action_pressed("ui_down")
		if mf != null and mode_tiles.values().has(mf):
			# la lista de modos nunca salta al panel derecho: solo se entra con Derecha
			var lastb: Control = mode_tiles[String(MODE_LIST[MODE_LIST.size() - 1][0])]
			var firstb: Control = mode_tiles[String(MODE_LIST[0][0])]
			if (mdn and mf == lastb) or (not mdn and mf == firstb):
				(firstb if mdn else lastb).grab_focus()   # da la vuelta: arriba del primero va al último y viceversa
				call_deferred("_follow_focus")
				get_viewport().set_input_as_handled()
				return
		elif mf is CheckButton and mf.get_parent() is GridContainer and mp_opts.is_ancestor_of(mf):
			# Modificadores: al pasar del primero hacia arriba (o del ultimo hacia abajo) da la vuelta
			var cbs: Array = mf.get_parent().get_children()
			var ix: int = cbs.find(mf)
			var cols: int = (mf.get_parent() as GridContainer).columns
			var tgt: Control = null
			if not mdn and ix < cols:
				var want: int = ix + int((cbs.size() - 1 - ix) / cols) * cols
				tgt = cbs[want]
			elif mdn and ix + cols >= cbs.size():
				tgt = cbs[ix % cols]
			if tgt != null:
				tgt.grab_focus()
				get_viewport().set_input_as_handled()
				call_deferred("_follow_focus")
				return
	if cur == "lexicon" and _lex_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if cur == "news" and news_scroll != null and _news_nav(event):
		get_viewport().set_input_as_handled()
		return
	if (cur == "lexicon" or cur == "goals") and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)) and screens.has(cur):
		var lsc: ScrollContainer = _first_scroll(screens[cur])
		var lf: Control = get_viewport().gui_get_focus_owner()
		var lnb: Control = null
		if lf != null:
			lnb = lf.find_valid_focus_neighbor(SIDE_BOTTOM if event.is_action_pressed("ui_down", true) else SIDE_TOP)
		# si hay algo enfocable en esa dirección (p. ej. la pestaña Colección), el D-pad mueve el foco en vez de desplazar
		if lsc != null and not (lf != null and lsc.is_ancestor_of(lf)) and lnb == null:
			lsc.scroll_vertical += 130 if event.is_action_pressed("ui_down", true) else -130
			get_viewport().set_input_as_handled()
			return
	# S18: con el foco dentro de una pantalla con scroll (p. ej. Misiones > Coleccion) y sin mas controles enfocables
	# en esa direccion, el mando desplaza el contenido hasta llegar a todas las entradas; el foco nunca se atasca.
	if (cur == "lexicon" or cur == "goals") and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)) and screens.has(cur):
		var dn2: bool = event.is_action_pressed("ui_down", true)
		var sc2: ScrollContainer = _first_scroll(screens[cur])
		var f2: Control = get_viewport().gui_get_focus_owner()
		if sc2 != null and f2 != null and sc2.is_ancestor_of(f2):
			var nb2: Control = f2.find_valid_focus_neighbor(SIDE_BOTTOM if dn2 else SIDE_TOP)
			if nb2 == null or not sc2.is_ancestor_of(nb2) or nb2 == f2:
				var vb: VScrollBar = sc2.get_v_scroll_bar()
				var can: bool = (sc2.scroll_vertical < int(vb.max_value - vb.page) - 1) if dn2 else (sc2.scroll_vertical > 0)
				if can:
					sc2.scroll_vertical += 130 if dn2 else -130
					get_viewport().set_input_as_handled()
					return
	if _grid_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")) and _scroll_fallback(event.is_action_pressed("ui_down")):
		get_viewport().set_input_as_handled()
		return
	if _nav_event(event):
		call_deferred("_follow_focus")
	if _nav_event(event) and get_viewport().gui_get_focus_owner() == null:
		# Al reconstruir una pantalla se pierde el foco: con mando/teclado lo recuperamos.
		var fc: Control = _first_focusable()
		if fc != null:
			fc.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if PAD.is_cancel(event) or event.is_action_pressed("ui_cancel"):
		if _popup_open():
			return
		_go_back()
		get_viewport().set_input_as_handled()


# Léxico con mando: pestañas (columna izquierda), filtros y rejilla se recorren por separado, sin saltos raros.
func _lex_tiles() -> Array:
	var out: Array = []
	var cols := 1
	for ch in lex_box.get_children():
		if ch is GridContainer:
			cols = (ch as GridContainer).columns
			for b in ch.get_children():
				if b is Button and (b as Button).focus_mode == Control.FOCUS_ALL:
					out.append(b)
		elif ch is Button and (ch as Button).focus_mode == Control.FOCUS_ALL:
			out.append(ch)
	return [out, cols]


func _lex_nav(event: InputEvent) -> bool:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_down", true): dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_up", true): dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_left", true): dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right", true): dir = Vector2i(1, 0)
	else:
		return false
	if _popup_open() or listening != "":
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or f is LineEdit or lex_tabs == null:
		return false
	var tabs: Array = lex_tabs.get_children()
	var info: Array = _lex_tiles()
	var tiles: Array = info[0]
	var cols: int = info[1]
	var chips: Array = []
	if lex_chips != null and lex_chips.visible:
		for c in lex_chips.get_children():
			if c is Button:
				chips.append(c)
	var tgt: Control = null
	var ti: int = tabs.find(f)
	var ci: int = chips.find(f)
	var gi: int = tiles.find(f)
	if ti >= 0:
		if dir.y != 0:
			tgt = tabs[clampi(ti + dir.y, 0, tabs.size() - 1)]
		elif dir.x > 0:
			if not chips.is_empty():
				tgt = chips[0]
			elif not tiles.is_empty():
				tgt = tiles[0]
	elif ci >= 0:
		if dir.x != 0:
			tgt = chips[posmod(ci + dir.x, chips.size())]
		elif dir.y > 0 and not tiles.is_empty():
			tgt = tiles[0]
	elif gi >= 0:
		if dir.x < 0:
			tgt = tab_sel if gi % cols == 0 else tiles[gi - 1]
		elif dir.x > 0:
			if gi % cols < cols - 1 and gi + 1 < tiles.size():
				tgt = tiles[gi + 1]
		elif dir.y < 0:
			if gi - cols >= 0:
				tgt = tiles[gi - cols]
			elif not chips.is_empty():
				tgt = chips[0]
		else:
			if gi + cols < tiles.size():
				tgt = tiles[gi + cols]
			elif gi / cols < (tiles.size() - 1) / cols:
				tgt = tiles[tiles.size() - 1]
	else:
		return false
	if tgt != null and tgt != f:
		tgt.grab_focus()
	return true   # siempre se consume: el foco nunca salta a otra zona por su cuenta


# Navegacion con mando igual de comoda en todas las pantallas (navgrid.gd), como en Mejoras.
func _grid_items() -> Array:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	if up_picker != null and is_instance_valid(up_picker):
		root = up_picker
	var out: Array = []
	for c in NAVG.focusables(root):
		# con una pantalla abierta solo cuentan ella y la barra superior (no las ocultas)
		if root == self and screens.has(cur):
			if not (screens[cur].is_ancestor_of(c) or not _in_any_screen(c)):
				continue
		out.append(c)
	return out


func _in_any_screen(c: Control) -> bool:
	for k in screens:
		if screens[k].is_ancestor_of(c):
			return true
	return false


func _grid_nav(event: InputEvent) -> bool:
	if _popup_open() or listening != "":
		return false
	# Pokemon: ir a la izquierda desde el borde de la rejilla lleva al boton Elegir (companero) del panel izquierdo.
	if cur == "dex" and event.is_action_pressed("ui_left") and dex_detail != null and dex_foot != null:
		var df: Control = get_viewport().gui_get_focus_owner()
		if df != null and not dex_detail.is_ancestor_of(df) and not dex_foot.is_ancestor_of(df) and df.get_global_rect().position.x > 500.0:
			var cy: float = df.get_global_rect().get_center().y
			var cx: float = df.get_global_rect().get_center().x
			var at_left := true
			for it in _grid_items():
				var ic := it as Control
				if ic == df or ic.get_global_rect().position.x <= 500.0:
					continue
				var ir: Rect2 = ic.get_global_rect()
				if absf(ir.get_center().y - cy) <= 10.0 and ir.get_center().x < cx - 4.0:
					at_left = false
					break
			if at_left:
				var tgt: Control = null
				for root in [dex_foot, dex_detail]:
					for c in NAVG.focusables(root):
						tgt = c
						break
					if tgt != null:
						break
				if tgt != null:
					tgt.grab_focus()
					return true
	# v5.2.1: ciclando modos con arriba/abajo solo cuentan los modos. Antes los botones del panel derecho
	# (elegir companero, cambiar tipo, Jugar...) formaban filas intermedias y el cursor saltaba a los modificadores.
	var gf: Control = get_viewport().gui_get_focus_owner()
	if cur == "modes" and gf != null and mode_tiles.values().has(gf) and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)):
		return NAVG.move(get_viewport(), event, mode_tiles.values())
	return NAVG.move(get_viewport(), event, _grid_items())


func _nav_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton and event.pressed:
		return true
	if event is InputEventJoypadMotion:
		return (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y) and absf(event.axis_value) > 0.6
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_ENTER, KEY_SPACE]
	return false


# Primer control con foco visible: dentro del resultado del gacha si esta abierto, si no en la pantalla actual.
func _first_focusable() -> Control:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	elif screens.has(cur):
		root = screens[cur]
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and not (c is Slider) and not (c is LineEdit):
			if c is BaseButton and (c as BaseButton).disabled:
				continue
			return c
	return null


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _name_of(dex: int) -> String:
	return L.t(String(SV.dex_by[dex]["name"]))


func _type_text(dex: int) -> String:
	var out: Array = []
	for t in SV.dex_by[dex]["types"]:
		out.append(L.t(String(MD.TYPE_NAME[String(t)])))
	return " / ".join(out)


# ---------------------------------------------------------------
# Pantalla principal
# ---------------------------------------------------------------
func _build_main() -> void:
	var s: Control = _screen("main")
	s.add_theme_constant_override("margin_top", 58 + int(DSP.insets(get_tree()).y))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	s.add_child(row)
	var orn := SetArt.new(true)
	orn.lift = -6.0
	orn.corners = true
	s.add_child(orn)
	# columna izquierda: titulo + Pokemon
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 4)
	row.add_child(left)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.custom_minimum_size = Vector2(0, 262)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # es arte suave, no pixel art
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(logo)
	# S58.5: frase aleatoria y amable (se elige una sola vez al construir el menu)
	var tags: Array = ["¡Ahora con más hierba que cortar!", "Cuidado: Meowth podría robarte el almuerzo.", "Hoy es un buen día para evolucionar.", "Recomendado por 9 de cada 10 Pikachu.", "¡Sobrevive un minuto más!", "No alimentes a los Snorlax salvajes.", "Kecleon acepta monedas, no cumplidos.", "Las Poké Balls no incluyen puntería.", "Un Charmander nunca duerme: solo parpadea.", "Cada Pokémon es un poco brillante por dentro."]
	var tg := _label(L.t(String(tags[randi() % tags.size()])), 18, Color.WHITE)
	tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tg.add_theme_color_override("font_outline_color", Color("#0b1a55"))
	tg.add_theme_constant_override("outline_size", 6)
	left.add_child(tg)
	var card := PanelContainer.new()
	var cds := _sb(Color("#0f1f60"), Color("#f6c433"), 4, 18)
	cds.content_margin_top = 4
	cds.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", cds)
	card.custom_minimum_size = Vector2(420, 206)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(card)
	card.add_child(MainStage.new())
	main_card = card
	var ipl := PanelContainer.new()
	ipl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ipl.custom_minimum_size = Vector2(420, 0)
	var ips := _sb(Color("#0f2268"), Color("#b5cdfb"), 3, 24)
	ips.content_margin_top = 3
	ips.content_margin_bottom = 3
	ipl.add_theme_stylebox_override("panel", ips)
	left.add_child(ipl)
	var iph := HBoxContainer.new()
	iph.add_theme_constant_override("separation", 10)
	ipl.add_child(iph)
	iph.add_child(IC.rect("ball", 34))
	main_info = _label("", 24)
	main_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	main_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iph.add_child(main_info)
	main_type = HBoxContainer.new()
	main_type.add_theme_constant_override("separation", 4)
	iph.add_child(main_type)
	main_title = PanelContainer.new()
	main_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tts := _sb(Color("#0b1a55"), Color("#f6c433"), 2, 6)
	tts.content_margin_top = 1
	tts.content_margin_bottom = 1
	tts.content_margin_left = 24
	tts.content_margin_right = 24
	main_title.add_theme_stylebox_override("panel", tts)
	left.add_child(main_title)
	var ttl := _label("", 20, Color("#ffd23f"))
	ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
	main_title.add_child(ttl)
	# columna derecha: menu
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(390, 0)
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	var p := PanelContainer.new()
	p.theme = _set_theme()
	var pfs := _sb(Color("#17307f"), SET_LINE, 4, 18)
	pfs.content_margin_left = 10
	pfs.content_margin_right = 10
	pfs.content_margin_top = 10
	pfs.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", pfs)
	right.add_child(p)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 6)
	p.add_child(mv)
	var entries := [["Jugar", "play", "flag"], ["Pokémon", "dex", "ball"], ["Mejoras", "up", "up"], ["Gacha", "gacha", "ballLux"], ["TM Gachapon", "gachapon", "gcoin"], ["Misiones y logros", "goals", "trophy"], ["Léxico", "lexicon", "book"], ["Ajustes", "settings", "gear"]]
	var first := true
	for e in entries:
		var key: String = String(e[1])
		var b := _btn(String(e[0]), func(): _menu_pick(key), Vector2(0, 50))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = IC.btn_tex(String(e[2]), 36)
		b.add_theme_constant_override("icon_max_width", 40)
		b.add_theme_constant_override("h_separation", 14)
		b.add_theme_font_size_override("font_size", 24)
		var bst := SetGlyph.new("stripes_dim", 34.0)
		bst.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		bst.offset_left = -50.0
		bst.offset_right = -16.0
		bst.offset_top = -17.0
		bst.offset_bottom = 17.0
		b.add_child(bst)
		mv.add_child(b)
		if first:
			first = false
			main_play_btn = b
			_set_btn(b, "gold")
		main_btns[key] = b
		if key == "goals":
			goals_btn = b
			b.add_theme_font_size_override("font_size", 20)   # el nombre largo no pisa las franjas
	main_stats = VBoxContainer.new()
	main_stats.add_theme_constant_override("separation", 2)
	var sp2 := PanelContainer.new()
	var sps := _sb(Color("#17307f"), SET_LINE, 4, 16)
	sps.content_margin_top = 6
	sps.content_margin_bottom = 6
	sp2.add_theme_stylebox_override("panel", sps)
	right.add_child(sp2)
	sp2.add_child(main_stats)


# Fondo del Pokemon en la portada: Poke Ball tenue y plataforma iluminada.
class MainStage extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(32):
			var a: float = TAU * float(i) / 32.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var wc := Color(0.4, 0.55, 1.0, 0.16)
		var r: float = size.y * 0.42
		draw_arc(c, r * 0.8, 0.0, TAU, 48, wc, r * 0.38)
		draw_line(c - Vector2(r, 0.0), c - Vector2(r * 0.34, 0.0), wc, r * 0.16)
		draw_line(c + Vector2(r * 0.34, 0.0), c + Vector2(r, 0.0), wc, r * 0.16)
		draw_circle(c, r * 0.16, wc)
		var f := Vector2(c.x, size.y * 0.84)
		_ellipse(f, size.x * 0.34, size.y * 0.1, Color(0.2, 0.45, 1.0, 0.35))
		_ellipse(f, size.x * 0.24, size.y * 0.065, Color(0.35, 0.65, 1.0, 0.5))


var main_type: HBoxContainer
var main_title: PanelContainer
var main_play_btn: Button
var main_btns: Dictionary = {}
var last_pick := "play"


func _menu_pick(key: String) -> void:
	last_pick = key
	if key == "goals" and goals_tab == "p":
		goals_tab = "m"
	if key == "play":
		modes_sel = String(MODE_LIST[0][0])   # v5.2.1: al darle a Jugar siempre se empieza arriba, en el primer modo (Partida normal)
		_show("modes")
	else:
		_show(key)


# ---------------------------------------------------------------
# Modos de juego
# ---------------------------------------------------------------
# Modos de juego (pantalla Jugar): lista a la izquierda; a la derecha, reglas + vista previa + opciones + Jugar del modo enfocado.
# La vista previa es una ilustracion animada (no ejecuta la partida: no gasta recursos ni toca ningun reloj).
var modes_box: VBoxContainer
var mp_title: Label
var mp_icon: TextureRect
var mp_play_ic: Control
var mp_rules: VBoxContainer
var mp_prev: Control
var mp_opts_sc: ScrollContainer
var mp_stat: Label
var mp_opts: VBoxContainer
var mp_play: Button
var modes_sel := "normal"
var mode_tiles: Dictionary = {}
var dex_pick_party := false
var dex_pick_team := false
var dex_pick_coop := false
const TYPE_IDS := ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
const MOD_ICON := {"fast": "boot", "horde": "m_horde", "tank": "shield", "hard": "fist", "frail": "heart", "nohealing": "berry", "slow": "r_heavy", "brainy": "r_scholar", "glass": "r_glass", "rich": "r_l_bag", "plague": "r_swarm"}
const MOD_INFO := {
	"fast": ["Veloces", "Los enemigos corren un 40% más rápido."],
	"horde": ["Horda", "Casi el doble de enemigos."],
	"tank": ["Resistentes", "Los enemigos tienen un 60% más de vida."],
	"hard": ["Golpes duros", "Los enemigos hacen un 50% más de daño."],
	"frail": ["Frágil", "Tu vida máxima se reduce a la mitad."],
	"nohealing": ["Sin curación", "No recuperas vida (solo la que te da subir de Vida)."],
	"slow": ["Pesado", "Te mueves un 20% más lento."],
	"brainy": ["Mente brillante", "Ganas un 50% más de experiencia, pero los enemigos tienen un 25% más de vida."],
	"glass": ["Cañón de cristal", "Haces un 50% más de daño, pero los enemigos hacen el doble."],
	"rich": ["Fiebre del oro", "Las monedas valen el doble, pero los enemigos tienen un 30% más de vida."],
	"plague": ["Plaga", "Aparecen 2,5 veces más enemigos, pero con un 35% menos de vida."],
}
# id, nombre, icono, grupo, reglas
const MODE_LIST := [
	["normal", "Partida normal", "flag", "Clásicos", ["Sobrevive mientras llegan enemigos sin parar.", "Sube de nivel y elige movimientos y objetos.", "Vence a los jefes que aparecen cada pocos minutos.", "Al terminar ganas Pokémonedas y, a veces, tickets.", "Dura 60 minutos: Arceus llega en el minuto 30 y Eternatus en el 60."]],
	["daily", "Desafío diario", "m_daily", "Clásicos", ["El Pokémon y la regla de hoy cambian cada día y son iguales para todos.", "Intenta mejorar tu mejor tiempo del día.", "+25% de monedas."]],
	["rush", "Rush de Jefes", "m_rush", "Clásicos", ["Solo jefes y legendarios, uno tras otro.", "Cada jefe es más fuerte que el anterior.", "Tu récord cuenta cuántos jefes derrotas."]],
	["tower", "La torre", "m_tower", "Clásicos", ["60 pisos, cada uno con un jefe fijo y un jefe grande cada 5.", "Entre pisos eliges descanso o pactos de riesgo.", "Cada 5 pisos ganas una reliquia permanente.", "No hay movimientos Z ni Dynamax."]],
	["rifts", "Contrarreloj de grietas", "m_clock", "Clásicos", ["8 minutos: las grietas se abren sin parar.", "Gana todas las peleas que puedas.", "+25% de monedas."]],
	["type", "Supervivencia por tipo", "m_type", "Variantes", ["Solo aparecen Pokémon del tipo elegido y sus jefes.", "+50% de monedas."]],
	["team", "Modo Equipo", "m_team", "Variantes", ["Lleva hasta 3 Pokémon y cámbialos en plena partida.", "Si uno cae, entra el siguiente; los de banca se recuperan.", "Cada Pokémon conserva sus propios movimientos."]],
	["coop", "Modo Cooperativo", "m_coop", "Variantes", ["Un segundo Pokémon te acompaña y ataca solo.", "Con un segundo mando, el jugador 2 lo mueve con su stick izquierdo.", "Comparte tus mejoras. -20% de monedas."]],
	["party", "Modo Fiesta", "m_party", "Variantes", ["Elige cualquier Pokémon, lo tengas o no.", "No puedes morir.", "No se guarda ningún progreso."]],
	["chal_p", "Retos permanentes", "gcoin", "Retos", ["100 retos de 10 minutos como máximo.", "Cada uno da su premio una sola vez.", "Los más difíciles dan Gachapon Coin Dorada."]],
	["chal_d", "Retos diarios", "gcoin", "Retos", ["3 retos nuevos cada día.", "Cada uno da 1 Gachapon Coin la primera vez."]],
	["chal_w", "Retos semanales", "gcoin_gold", "Retos", ["5 retos nuevos cada semana.", "Uno es de nivel Experto y da Gachapon Coin Dorada."]],
	["mods", "Modificadores", "m_horde", "Ajustes", ["Cambian las reglas de la partida para ganar más monedas.", "+25% de monedas por cada modificador activo.", "No se aplican al Desafío diario ni al Modo Fiesta."]],
]


func _start_mode(mode: String) -> void:
	SV.run_mode = mode
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# Ilustracion animada del modo (sprites + decoracion). No simula la partida.
class ModePrev extends Control:
	var mode := "normal"
	var t := 0.0
	var ents: Array = []     # {n: Preview, k: movimiento, a: punto base (0..1), p: fase}
	var info: Dictionary = {}
	var vp: VideoStreamPlayer = null   # video de gameplay real del modo (assets/previews/<modo>.ogv)
	var has_video := false
	const VID := Vector2(640.0, 360.0)

	func _fit_video() -> void:
		if vp == null:
			return
		var k: float = maxf(size.x / VID.x, size.y / VID.y)   # cubrir el recuadro sin deformar
		vp.size = VID * k
		vp.position = (size - vp.size) * 0.5

	static func sprite_dex(d: int) -> int:
		return d if ResourceLoader.exists("res://assets/pokemon/%d/Idle.png" % d) or ResourceLoader.exists("res://assets/pokemon/%d/Walk.png" % d) else 4

	func setup(m: String, inf: Dictionary) -> void:
		mode = m
		info = inf
		t = 0.0
		for e in ents:
			e["n"].queue_free()
		ents.clear()
		for c in get_children():
			c.queue_free()
		var hero: int = int(inf.get("hero", 4))
		if vp != null:
			vp.queue_free()
			vp = null
		var vpath := "res://assets/previews/%s.ogv" % String(inf.get("vid", m))
		if ResourceLoader.exists(vpath) and not ["type", "mods", "chal"].has(m):
			vp = VideoStreamPlayer.new()
			vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vp.stream = load(vpath)
			vp.expand = true
			vp.loop = true
			add_child(vp)
			vp.play()
			has_video = true
			var tg := Label.new()
			tg.text = String(inf.get("tag", ""))
			tg.add_theme_font_size_override("font_size", 14)
			tg.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
			tg.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			tg.add_theme_constant_override("shadow_offset_x", 1)
			tg.add_theme_constant_override("shadow_offset_y", 1)
			tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
			add_child(tg)
			_fit_video()
			if inf.has("overlay"):
				_add(int(inf["overlay"]), 150.0, "ovl", Vector2(0.5, 0.5), 0.0)
			queue_redraw()
			return
		has_video = false
		match m:
			"normal":
				_add(hero, 150.0, "hero", Vector2(0.5, 0.78), 0.0)
				var foes := [19, 16, 41, 10, 21, 74, 19, 16]
				for i in range(foes.size()):
					_add(int(foes[i]), 70.0, "orbit", Vector2(0.5, 0.78), float(i) / float(foes.size()) * TAU)
			"daily":
				_add(int(inf.get("dex", 25)), 170.0, "bob", Vector2(0.3, 0.8), 0.0)
			"rush":
				_add(hero, 110.0, "bob", Vector2(0.2, 0.84), 0.0)
				_add(int(inf.get("boss", 248)), 220.0, "bob", Vector2(0.7, 0.9), 1.0)
			"tower":
				_add(hero, 90.0, "climb", Vector2(0.3, 0.9), 0.0)
				_add(int(inf.get("boss", 248)), 100.0, "bob", Vector2(0.78, 0.38), 1.0)
			"rifts":
				_add(hero, 120.0, "rhero", Vector2(0.12, 0.82), 0.0)
				for fd in [19, 41, 74]:
					_add(int(fd), 70.0, "rfoe", Vector2(0.7, 0.82), float(fd))
			"type":
				_add(hero, 130.0, "hero", Vector2(0.5, 0.78), 0.0)
				var ids: Array = inf.get("dexes", [])
				for i in range(ids.size()):
					_add(int(ids[i]), 66.0, "orbit", Vector2(0.5, 0.78), float(i) / float(maxi(1, ids.size())) * TAU)
			"team":
				var tl: Array = inf.get("team", [hero])
				for i in range(tl.size()):
					_add(int(tl[i]), 130.0 if i == 0 else 95.0, "bob", Vector2(0.28 + 0.22 * float(i) + (0.0 if tl.size() > 2 else 0.1), 0.82), float(i))
			"coop":
				_add(hero, 150.0, "bob", Vector2(0.32, 0.82), 0.0)
				_add(int(inf.get("coop", 133)), 130.0, "bob", Vector2(0.62, 0.82), 1.0)
			"party":
				_add(int(inf.get("dex", 25)), 170.0, "bob", Vector2(0.5, 0.82), 0.0)
			"chal":
				_add(hero, 130.0, "bob", Vector2(0.2, 0.84), 0.0)
			"mods":
				_add(hero, 150.0, "bob", Vector2(0.16, 0.8), 0.0)
		queue_redraw()

	func _add(d: int, box: float, kind: String, a: Vector2, ph: float) -> void:
		var sc = load("res://scripts/menu.gd")
		var n = sc.Preview.new()
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.custom_minimum_size = Vector2(box, box)
		n.size = Vector2(box, box)
		add_child(n)
		n.setup(sprite_dex(d), false, 8.0, kind == "boss_dark")
		ents.append({"n": n, "k": kind, "a": a, "p": ph, "b": box})

	func _process(delta: float) -> void:
		t += delta
		if has_video:
			_fit_video()
			if mode == "team":   # el video ya muestra al equipo rotando entre sus 3 Pokémon
				for e0 in ents:
					(e0["n"] as Control).visible = false
				return
			var nent: int = ents.size()
			for ei in range(nent):   # el Pokémon del día va encima del video (que se grabó sin jugador)
				var e = ents[ei]
				var bx: float = size.y * (0.5 if nent == 1 else 0.36)
				var nn: Control = e["n"]
				nn.custom_minimum_size = Vector2(bx, bx)
				nn.size = Vector2(bx, bx)
				var spread: float = (float(ei) - float(nent - 1) * 0.5) * size.x * 0.26   # varios Pokémon: no se apilan
				var ctr := Vector2(size.x * 0.5 + spread, size.y * 0.5 + bx * 0.14 - absf(sin(t * 3.0 + float(ei))) * 3.0)
				nn.position = ctr - Vector2(bx * 0.5, bx * 0.84)
				# misma trayectoria que el bot del video: dirección según el tiempo del video
				var vt: float = vp.stream_position if vp != null else t
				var vx: float = cos(vt * 0.9)
				var vy: float = sin(vt * 0.9 * 1.3)
				var ix: int = (1 if vx > 0.25 else -1 if vx < -0.25 else 0)
				var iy: int = (1 if vy > 0.25 else -1 if vy < -0.25 else 0)
				var rmap := {Vector2i(0, 1): 0, Vector2i(1, 1): 1, Vector2i(1, 0): 2, Vector2i(1, -1): 3, Vector2i(0, -1): 4, Vector2i(-1, -1): 5, Vector2i(-1, 0): 6, Vector2i(-1, 1): 7}
				(nn as Control).set("walk", true)
				(nn as Control).set("row", int(rmap.get(Vector2i(ix, iy), 0)))
			return
		for e in ents:
			var n: Control = e["n"]
			var base := Vector2(size.x * float(e["a"].x), size.y * float(e["a"].y))
			var off := Vector2.ZERO
			match String(e["k"]):
				"bob":
					off = Vector2(0.0, -absf(sin(t * 3.0 + float(e["p"]))) * 6.0)
				"hero":
					off = Vector2(sin(t * 1.6) * 6.0, 0.0)
				"climb":
					off = Vector2(0.0, -absf(sin(t * 4.0)) * 8.0)
				"rhero":
					var ph: float = fposmod(t, 8.0)
					var portal := Vector2(size.x * 0.7, size.y * 0.78)
					var sc2 := 1.0
					var pos2 := Vector2(size.x * 0.28, size.y * 0.82)
					var walking := false
					if ph < 2.6:
						pos2 = Vector2(size.x * lerpf(0.1, 0.66, ph / 2.6), size.y * 0.82)
						walking = true
					elif ph < 3.3:
						var f1: float = (ph - 2.6) / 0.7
						pos2 = Vector2(size.x * 0.66, size.y * 0.82).lerp(portal, f1)
						sc2 = 1.0 - f1
						walking = true
					elif ph < 3.9:
						sc2 = (ph - 3.3) / 0.6
					base = pos2
					off = Vector2.ZERO if walking else Vector2(0.0, -absf(sin(t * 3.0)) * 4.0)
					n.pivot_offset = Vector2(float(e["b"]) * 0.5, float(e["b"]) * 0.84)
					n.scale = Vector2(sc2, sc2)
					n.visible = sc2 > 0.03
					(n as Control).set("walk", walking)
					(n as Control).set("row", 2)
				"rfoe":
					var ph2: float = fposmod(t, 8.0)
					var idx: int = [19, 41, 74].find(int(e["p"]))
					var tdie: float = 3.9 + float(idx) * 1.3 + 0.5
					n.visible = ph2 >= 3.3 and ph2 < tdie
					base = Vector2(size.x * (0.58 + 0.12 * float(idx)), size.y * (0.78 + 0.03 * float(idx % 2)))
					off = Vector2(0.0, -absf(sin(t * 3.0 + float(idx))) * 5.0)
				"orbit":
					var r: float = 170.0 + 40.0 * sin(t * 0.9 + float(e["p"]))
					var ang: float = float(e["p"]) + t * 0.5
					off = Vector2(cos(ang) * r * 1.15, sin(ang) * r * 0.42 - 20.0)
			n.position = base + off - Vector2(float(e["b"]) * 0.5, float(e["b"]) * 0.84)
		queue_redraw()

	func _font() -> Font:
		return get_theme_default_font()

	func _txt(p: Vector2, s: String, fs: int, col: Color, w: float = -1.0, al: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
		draw_string(_font(), p, s, al, w, fs, col)

	func _draw() -> void:
		var W: float = size.x
		var H: float = size.y
		if has_video:
			draw_rect(Rect2(0, 0, W, H), Color.BLACK)
			return
		draw_rect(Rect2(0, 0, W, H), Color("#16224a"))
		draw_rect(Rect2(0, H * 0.5, W, H * 0.5), Color("#1d2f63"))
		if mode != "type" and mode != "mods":
			draw_rect(Rect2(0, H * 0.84, W, H * 0.16), Color("#26602f"))
			draw_rect(Rect2(0, H * 0.84, W, 4.0), Color("#3b8a45"))
		match mode:
			"normal":
				for i in 3:
					draw_arc(Vector2(W * 0.5, H * 0.78), 90.0 + float(i) * 70.0, 0.0, TAU, 48, Color(1, 1, 1, 0.05), 2.0)
				draw_rect(Rect2(14, 12, W - 28, 14), Color(0, 0, 0, 0.45))
				draw_rect(Rect2(14, 12, (W - 28) * fposmod(t * 0.12, 1.0), 14), Color("#5fd0ff"))
				_txt(Vector2(14, 46), "Nv %d" % (1 + int(t * 0.12)), 18, Color.WHITE)
			"daily":
				draw_rect(Rect2(W * 0.52, 26, W * 0.4, H * 0.62), Color("#f4f6fb"), true)
				draw_rect(Rect2(W * 0.52, 26, W * 0.4, 34), Color("#e0434f"))
				_txt(Vector2(W * 0.52, 51), String(info.get("month", "")), 22, Color.WHITE, W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.52, 118), String(info.get("day", "")), 56, Color("#243357"), W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.52, 148), String(info.get("rule", "")), 18, Color("#5b6a8a"), W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
			"rush":
				var bx: float = W * 0.7
				draw_rect(Rect2(bx - 90, 14, 180, 14), Color(0, 0, 0, 0.55))
				draw_rect(Rect2(bx - 90, 14, 180.0 * (0.55 + 0.45 * absf(sin(t * 0.7))), 14), Color("#ff5a6a"))
				for i in 4:
					var px: float = fposmod(t * 160.0 + float(i) * 70.0, 330.0) + W * 0.28
					draw_circle(Vector2(px, H * 0.7), 6.0, Color("#ffb347"))
			"tower":
				for i in 6:
					var fy: float = H * 0.88 - float(i) * (H * 0.14)
					draw_rect(Rect2(W * 0.08, fy - H * 0.12, W * 0.4, H * 0.12 - 3.0), Color(0.2, 0.28, 0.5, 0.7))
					_txt(Vector2(W * 0.1, fy - 10.0), str(int(info.get("floor", 1)) + i), 18, Color("#9fb4dc"))
				_txt(Vector2(W * 0.56, 40), "%s %d" % [String(info.get("floor_lbl", "")), int(info.get("floor", 1))], 22, Color("#ffd23f"))
			"rifts":
				var ph3: float = fposmod(t, 8.0)
				var c := Vector2(W * 0.7, H * 0.7)
				if ph3 >= 3.3:
					draw_rect(Rect2(0, 0, W, H), Color(0.22, 0.08, 0.38, 0.55))
					for si in 14:
						draw_circle(Vector2(fposmod(float(si) * 91.0, W), fposmod(float(si) * 53.0, H * 0.7)), 2.0, Color(1, 1, 1, 0.5 + 0.4 * sin(t * 3.0 + float(si))))
				else:
					var grow: float = 1.0 if ph3 < 2.6 else clampf(1.0 - (ph3 - 2.6) / 0.7 * 0.6, 0.3, 1.0)
					for i in 4:
						var r: float = (44.0 + float(i) * 22.0) * grow
						draw_arc(c, r, t * (1.0 + float(i) * 0.3), t * (1.0 + float(i) * 0.3) + 4.2, 32, Color(0.62, 0.42, 1.0, 0.7 - float(i) * 0.12), 5.0)
				if ph3 >= 3.9:
					var hp := Vector2(W * 0.28 + 30.0, H * 0.82 - 40.0)
					for k in 3:
						var ts: float = 3.9 + float(k) * 1.3
						var f2: float = (ph3 - ts) / 0.5
						if f2 >= 0.0 and f2 <= 1.0:
							var tp := Vector2(W * (0.58 + 0.12 * float(k)), H * (0.78 + 0.03 * float(k % 2)) - 40.0)
							var bp: Vector2 = hp.lerp(tp, f2)
							draw_circle(bp, 12.0, Color(1.0, 0.45, 0.1, 0.85))
							draw_circle(bp, 7.0, Color(1.0, 0.85, 0.3))
							draw_line(bp, bp - (tp - hp).normalized() * 30.0, Color(1.0, 0.5, 0.15, 0.6), 8.0)
						elif f2 > 1.0 and f2 < 1.5:
							var ep := Vector2(W * (0.58 + 0.12 * float(k)), H * (0.78 + 0.03 * float(k % 2)) - 40.0)
							draw_arc(ep, 10.0 + (f2 - 1.0) * 60.0, 0.0, TAU, 20, Color(1.0, 0.7, 0.2, 1.5 - f2), 4.0)
				var left: int = maxi(0, 480 - int(t * 8.0))
				_txt(Vector2(0, 38), "%d:%02d" % [left / 60, left % 60], 32, Color.WHITE, W, HORIZONTAL_ALIGNMENT_CENTER)
			"type":
				_txt(Vector2(W * 0.04, 36), String(info.get("type_lbl", "")), 24, Color("#ffd23f"))
			"team":
				var tl: Array = info.get("team", [])
				for i in range(maxi(0, tl.size() - 1)):
					var ax: float = W * (0.28 + 0.22 * float(i) + (0.0 if tl.size() > 2 else 0.1)) + 55.0
					draw_arc(Vector2(ax + 18.0, H * 0.55), 14.0, 0.2 + t * 2.0, 4.4 + t * 2.0, 14, Color(1, 1, 1, 0.8), 4.0)
			"coop":
				var a1 := Vector2(W * 0.32, H * 0.5)
				var a2 := Vector2(W * 0.62, H * 0.5)
				for i in 6:
					var f: float = fposmod(t * 0.8 + float(i) / 6.0, 1.0)
					draw_circle(a1.lerp(a2, f), 3.0 + 3.0 * sin(f * PI), Color(1, 0.85, 0.3, 0.85))
			"party":
				for i in 40:
					var fx: float = fposmod(float(i) * 37.0, W)
					var fy2: float = fposmod(t * (40.0 + float(i % 7) * 12.0) + float(i) * 23.0, H)
					draw_rect(Rect2(fx, fy2, 6, 6), Color.from_hsv(float(i % 9) / 9.0, 0.7, 1.0, 0.9))
				_txt(Vector2(0, 44), "∞", 46, Color("#ffd23f"), W, HORIZONTAL_ALIGNMENT_CENTER)
			"chal":
				var c2 := Vector2(W * 0.66, H * 0.5)
				var fr: float = fposmod(t * 0.15, 1.0)
				draw_arc(c2, 66.0, 0.0, TAU, 48, Color(1, 1, 1, 0.15), 10.0)
				draw_arc(c2, 66.0, -PI * 0.5, -PI * 0.5 + TAU * fr, 48, Color("#ffd23f"), 10.0)
				var rem: int = 600 - int(600.0 * fr)
				_txt(Vector2(c2.x - 70, c2.y + 12), "%d:%02d" % [rem / 60, rem % 60], 38, Color.WHITE, 140.0, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.34, 34), String(info.get("goal1", "")), 18, Color("#d6e2ff"))
			"mods":
				var on: Array = info.get("on", [])
				var k := {"hp": 1.0, "spd": 1.0, "dmg": 1.0, "xp": 1.0, "coin": 1.0 + 0.25 * float(on.size()), "ehp": 1.0, "espd": 1.0, "edmg": 1.0, "ecnt": 1.0}
				var has := func(id: String) -> bool: return on.has(id)
				if has.call("frail"): k["hp"] *= 0.5
				if has.call("slow"): k["spd"] *= 0.8
				if has.call("glass"): k["dmg"] *= 1.5; k["edmg"] *= 2.0
				if has.call("brainy"): k["xp"] *= 1.5; k["ehp"] *= 1.25
				if has.call("rich"): k["coin"] *= 2.0; k["ehp"] *= 1.3
				if has.call("tank"): k["ehp"] *= 1.6
				if has.call("plague"): k["ehp"] *= 0.65; k["ecnt"] *= 2.5
				if has.call("fast"): k["espd"] *= 1.4
				if has.call("hard"): k["edmg"] *= 1.5
				if has.call("horde"): k["ecnt"] *= 1.8
				var rows_p := [["Vida", "hp", true], ["Velocidad", "spd", true], ["Daño", "dmg", true], ["Experiencia", "xp", true], ["Monedas", "coin", true]]
				var rows_e := [["Vida", "ehp", false], ["Velocidad", "espd", false], ["Daño", "edmg", false], ["Cantidad", "ecnt", false]]
				var cols := [[W * 0.33, L.t("Tú"), rows_p], [W * 0.67, L.t("Enemigos"), rows_e]]
				for c in cols:
					var x0: float = float(c[0])
					var cw: float = W * 0.31
					_txt(Vector2(x0, 28), String(c[1]), 20, Color("#ffd23f"))
					var rr: Array = c[2]
					for i in rr.size():
						var y: float = 46.0 + 36.0 * float(i)
						var key: String = String(rr[i][1])
						var v: float = float(k[key])
						var good: bool = (v >= 1.0) == bool(rr[i][2])
						var col: Color = Color("#ffffff") if absf(v - 1.0) < 0.001 else (Color("#5fe08a") if good else Color("#ff6b6b"))
						_txt(Vector2(x0, y + 14), L.t(String(rr[i][0])), 16, Color("#c8d6ee"))
						var bx: float = x0 + cw * 0.46
						var bw: float = cw * 0.54
						draw_rect(Rect2(bx, y + 3, bw, 12), Color(0, 0, 0, 0.4))
						draw_rect(Rect2(bx + bw * 0.5 - 1.0, y, 2, 18), Color(1, 1, 1, 0.5))
						var f: float = clampf(log(v) / log(4.0), -1.0, 1.0) * 0.5
						draw_rect(Rect2(bx + bw * 0.5 + minf(0.0, f) * bw, y + 3, absf(f) * bw, 12), col)
						_txt(Vector2(bx, y + 32), "×%s" % (("%.2f" % v).rstrip("0").rstrip(".")), 14, col, bw, HORIZONTAL_ALIGNMENT_RIGHT)
				if has.call("nohealing"):
					_txt(Vector2(14, 26), L.t("Sin curación"), 16, Color("#ff6b6b"))
		_txt(Vector2(W - 150, H - 8), String(info.get("tag", "")), 14, Color(1, 1, 1, 0.45), 140.0, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_modes() -> void:
	var s: Control = _screen("modes")
	var ins: Vector4 = DSP.insets(get_tree())
	s.add_theme_constant_override("margin_left", 10 + int(ins.x))
	s.add_theme_constant_override("margin_right", 10 + int(ins.z))
	s.add_theme_constant_override("margin_top", 66 + int(ins.y))
	s.add_theme_constant_override("margin_bottom", 10 + int(ins.w))
	var pc := PanelContainer.new()
	pc.theme = _set_theme()
	var fr := _sb(Color("#17307f"), SET_LINE, 4, 20)
	fr.content_margin_left = 14
	fr.content_margin_right = 12
	fr.content_margin_top = 8
	fr.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", fr)
	s.add_child(pc)
	pc.add_child(SetArt.new())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var rib := PanelContainer.new()
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rib.add_theme_stylebox_override("panel", _ribbon_sb(Color("#2a56c4"), Color("#b5cdfb"), 44))
	v.add_child(rib)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	rib.add_child(rh)
	rh.add_child(IC.rect("ball", 38))
	var tt := _label("Elige un modo", 30)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rh.add_child(tt)
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	var orn_gap := Control.new()   # hueco para la Poke Ball del adorno de abajo
	orn_gap.custom_minimum_size = Vector2(0, 40)
	orn_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(orn_gap)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(390, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	hb.add_child(sc)
	var mm := MarginContainer.new()
	mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mm.add_theme_constant_override("margin_right", 22)   # la barra de desplazamiento no tapa los modos
	sc.add_child(mm)
	modes_box = VBoxContainer.new()
	modes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modes_box.add_theme_constant_override("separation", 8)
	mm.add_child(modes_box)
	# panel derecho: reglas arriba, vista previa, datos, opciones y Jugar
	var rp := VBoxContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.add_theme_constant_override("separation", 6)
	hb.add_child(rp)
	var orn := SetArt.new(true)
	orn.lift = 18.0
	pc.add_child(orn)
	# Todo el panel derecho se desplaza de arriba abajo (con rueda, dedo o mando) para que nada quede tapado ni fuera de pantalla.
	var rsc := ScrollContainer.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rsc.follow_focus = true
	rp.add_child(rsc)
	var rm := MarginContainer.new()
	rm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rm.add_theme_constant_override("margin_right", 22)   # la barra de desplazamiento no tapa el contenido
	rsc.add_child(rm)
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 6)
	rm.add_child(rv)
	var tban := PanelContainer.new()
	var tbs := _sb(Color("#1c3e94"), SET_LINE, 3, 22)
	tbs.content_margin_top = 4
	tbs.content_margin_bottom = 4
	tban.add_theme_stylebox_override("panel", tbs)
	rv.add_child(tban)
	var tbr := HBoxContainer.new()
	tbr.add_theme_constant_override("separation", 12)
	tban.add_child(tbr)
	mp_icon = TextureRect.new()
	mp_icon.custom_minimum_size = Vector2(38, 38)
	mp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mp_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tbr.add_child(mp_icon)
	mp_title = _label("", 28)
	mp_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	mp_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbr.add_child(mp_title)
	tbr.add_child(SetGlyph.new("stripes", 38.0))
	var rtab := PanelContainer.new()
	rtab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rtab.add_theme_stylebox_override("panel", _ribbon_sb(Color("#2a56c4"), SET_LINE, 26))
	rv.add_child(rtab)
	var rth := HBoxContainer.new()
	rth.add_theme_constant_override("separation", 8)
	rtab.add_child(rth)
	rth.add_child(SetGlyph.new("clip", 26.0))
	var rtl := _label("Reglas", 20)
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rth.add_child(rtl)
	var rbox := PanelContainer.new()
	var rbs := _sb(Color(0.05, 0.09, 0.32, 0.85), SET_LINE, 2, 12)
	rbs.content_margin_top = 6
	rbs.content_margin_bottom = 6
	rbox.add_theme_stylebox_override("panel", rbs)
	rv.add_child(rbox)
	mp_rules = VBoxContainer.new()
	mp_rules.add_theme_constant_override("separation", 2)
	rbox.add_child(mp_rules)
	var pfr := PanelContainer.new()
	pfr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var pfs := _sb(Color("#0f1f60"), Color("#f6c433"), 3, 12)
	pfs.content_margin_left = 3
	pfs.content_margin_right = 3
	pfs.content_margin_top = 3
	pfs.content_margin_bottom = 3
	pfr.add_theme_stylebox_override("panel", pfs)
	rv.add_child(pfr)
	mp_prev = load("res://scripts/menu.gd").ModePrev.new()
	mp_prev.custom_minimum_size = Vector2(0, 190)
	mp_prev.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mp_prev.clip_contents = true
	pfr.add_child(mp_prev)
	mp_stat = _label("", 18, Color("#cfd9f5"))
	rv.add_child(mp_stat)
	mp_opts_sc = ScrollContainer.new()
	mp_opts_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mp_opts_sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED   # el panel entero ya se desplaza
	rv.add_child(mp_opts_sc)
	mp_opts = VBoxContainer.new()
	mp_opts.add_theme_constant_override("separation", 6)
	mp_opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_opts_sc.add_child(mp_opts)
	mp_play = _btn("Jugar", func(): _modes_play(), Vector2(0, 60))
	mp_play.add_theme_font_size_override("font_size", 30)
	_set_btn(mp_play, "gold")
	mp_play.add_theme_stylebox_override("normal", _sb(Color("#f6c433"), Color("#fff0a8"), 3, 26))
	mp_play.add_theme_stylebox_override("hover", _sb(Color("#ffd44f"), Color("#fff0a8"), 3, 26))
	mp_play.add_theme_stylebox_override("pressed", _sb(Color("#dcae22"), Color("#fff0a8"), 3, 26))
	mp_play.add_theme_stylebox_override("focus", _sb(Color("#ffd44f"), Color.WHITE, 4, 26))
	mp_play.add_theme_stylebox_override("disabled", _sb(Color("#5f6a8c"), Color("#8c96b5"), 3, 26))
	mp_play.add_theme_color_override("font_disabled_color", Color("#d5dbea"))
	mp_play_ic = SetGlyph.new("play", 36.0, Color("#2b1a00"))
	mp_play_ic.anchor_left = 0.5
	mp_play_ic.anchor_right = 0.5
	mp_play_ic.anchor_top = 0.5
	mp_play_ic.anchor_bottom = 0.5
	mp_play_ic.offset_top = -18.0
	mp_play_ic.offset_bottom = 18.0
	mp_play.add_child(mp_play_ic)
	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_right", 22)
	pm.add_child(mp_play)
	rp.add_child(pm)   # siempre visible, fuera de la parte que se desplaza


# Cinta de titulo: esquinas sesgadas como las secciones de Ajustes.
func _ribbon_sb(bg: Color, edge: Color, right: int) -> StyleBoxFlat:
	var sb := _sb(bg, edge, 3, 8)
	sb.corner_radius_top_left = 18
	sb.corner_radius_bottom_right = 24
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.content_margin_left = 10
	sb.content_margin_right = right
	return sb


func _mode_tile(m: Array) -> Button:
	var id: String = String(m[0])
	var b := Button.new()
	b.icon = IC.btn_tex(String(m[2]), 40)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 14)
	b.add_theme_constant_override("icon_max_width", 40)
	b.text = L.t(String(m[1]))
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 22)
	var wm := SetGlyph.new("watermark", 30.0)
	wm.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	wm.offset_left = -44.0
	wm.offset_right = -14.0
	wm.offset_top = -15.0
	wm.offset_bottom = 15.0
	b.add_child(wm)
	b.pressed.connect(func():
		Aud.sfx("click")
		_modes_select(id)
		_gf(mp_play if mp_play.visible else mp_opts.get_child(0) if mp_opts.get_child_count() > 0 else b))
	b.focus_entered.connect(func():
		Aud.sfx("hover")
		_modes_select(id))
	modes_box.add_child(b)
	mode_tiles[id] = b
	return b


var _warmed: Dictionary = {}


# Carga en segundo plano las hojas de sprites que usan las vistas previas, para que al cambiar de modo
# no haya un tirón (y la música no se corte) la primera vez que se ve cada uno.
func _warm_previews() -> void:
	var ds: Array = [int(SV.d["selected"]), SV.daily_dex(SV.daily_seed()), int(SV.d.get("coop_dex", 133)), 133, 248, 19, 16, 41, 10, 21, 74, 25, 150, 144, 145, 146]
	for x in SV.team_list():
		ds.append(int(x))
	for d in ds:
		if d <= 0 or _warmed.has(d):
			continue
		_warmed[d] = true
		for sub in ["s/", ""]:
			for nm in ["Idle", "Walk"]:
				var path := "res://assets/pokemon/%d/%s%s.png" % [d, sub, nm]
				if ResourceLoader.exists(path):
					ResourceLoader.load_threaded_request(path)


func _refresh_modes() -> void:
	_warm_previews()
	_clear(modes_box)
	mode_tiles.clear()
	SV.run_mods = Array(SV.d.get("mods", []))
	var group := ""
	var first: Button = null
	for m in MODE_LIST:
		if String(m[3]) != group:
			group = String(m[3])
			var gr := PanelContainer.new()
			gr.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			gr.add_theme_stylebox_override("panel", _ribbon_sb(Color("#2a56c4"), SET_LINE, 30))
			var gh := HBoxContainer.new()
			gh.add_theme_constant_override("separation", 10)
			gr.add_child(gh)
			gh.add_child(IC.rect("ball", 26))
			var gl := _label(group, 20)
			gl.autowrap_mode = TextServer.AUTOWRAP_OFF
			gh.add_child(gl)
			modes_box.add_child(gr)
		var tb: Button = _mode_tile(m)
		if first == null or String(m[0]) == modes_sel:
			if first == null or String(m[0]) == modes_sel:
				first = tb
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 60)   # margen final: la ultima opcion nunca queda pegada al borde
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modes_box.add_child(tail)
	# v5.2.1: arriba/abajo entre modos solo recorre la lista de modos (antes, a veces, el cursor saltaba al panel de modificadores)
	var tl: Array = []
	for mm in MODE_LIST:
		tl.append(mode_tiles[String(mm[0])])
	for ti in range(tl.size()):
		var tt: Control = tl[ti]
		tt.focus_neighbor_top = tt.get_path_to(tl[maxi(ti - 1, 0)])
		tt.focus_neighbor_bottom = tt.get_path_to(tl[mini(ti + 1, tl.size() - 1)])
	_modes_select(modes_sel)
	focus_first = mode_tiles.get(modes_sel, first)


func _mode_def(id: String) -> Array:
	for m in MODE_LIST:
		if String(m[0]) == id:
			return m
	return MODE_LIST[0]


# Al pulsar un boton del panel derecho (p. ej. "Cambiar tipo") el panel se reconstruye: se devuelve el foco al
# mismo boton para no tener que volver a bajar hasta el con el mando.
func _modes_select(id: String) -> void:
	var fo: Control = get_viewport().gui_get_focus_owner()
	var keep := -1
	if fo != null and mp_opts != null and mp_opts.is_ancestor_of(fo):
		var bl: Array = []
		for c in mp_opts.get_children():
			if c is Button and (c as Button).focus_mode == Control.FOCUS_ALL:
				bl.append(c)
		keep = bl.find(fo)
	_modes_select_impl(id)
	if keep >= 0:
		call_deferred("_restore_opts_focus", keep)


func _restore_opts_focus(idx: int) -> void:
	if mp_opts == null or not is_instance_valid(mp_opts):
		return
	var bl: Array = []
	for c in mp_opts.get_children():
		if c is Button and (c as Button).focus_mode == Control.FOCUS_ALL and not (c as Button).disabled and not c.is_queued_for_deletion():
			bl.append(c)
	if bl.is_empty():
		return
	(bl[clampi(idx, 0, bl.size() - 1)] as Control).grab_focus()


func _modes_select_impl(id: String) -> void:
	modes_sel = id
	var m: Array = _mode_def(id)
	for k in mode_tiles:
		var tb: Button = mode_tiles[k]
		if is_instance_valid(tb):
			if k == id:
				_set_btn(tb, "gold")
			else:
				for st in ["normal", "hover", "pressed", "focus"]:
					tb.remove_theme_stylebox_override(st)
				for fc in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
					tb.remove_theme_color_override(fc)
	mp_title.text = L.t(String(m[1]))
	mp_icon.texture = IC.btn_tex(String(m[2]), 38)
	_clear(mp_rules)
	for r in m[4]:
		var rl := _label(L.t(String(r)), 18)
		var rsb := StyleBoxEmpty.new()
		rsb.content_margin_left = 22
		rl.add_theme_stylebox_override("normal", rsb)
		var dot := SetGlyph.new("dot", 12.0)
		dot.position = Vector2(2, 7)
		dot.size = Vector2(12, 12)
		rl.add_child(dot)
		mp_rules.add_child(rl)
	_clear(mp_opts)
	mp_stat.text = ""
	mp_play.visible = true
	mp_play.text = L.t("Jugar")
	var hero: int = int(SV.d["selected"])
	var info := {"hero": hero, "tag": L.t("Vista previa")}
	var pm := "normal"
	match id:
		"daily":
			var ds: int = SV.daily_seed()
			var dd: Dictionary = SV.d.get("daily", {})
			var best: int = int(dd.get("best", 0)) if int(dd.get("date", 0)) == ds else 0
			var dm: String = SV.daily_mod(ds)
			mp_stat.text = L.t("Hoy: %s con la regla «%s» (misma para todos). +25%% de monedas.") % [_name_of(SV.daily_dex(ds)), L.t(String(MOD_INFO[dm][0]))] + "  " + (L.t("Tu mejor tiempo de hoy: %s") % ("%d:%02d" % [best / 60, best % 60]) if best > 0 else L.t("Aún no lo has jugado hoy."))
			var td: Dictionary = Time.get_date_dict_from_system()
			info["dex"] = SV.daily_dex(ds)
			info["overlay"] = SV.daily_dex(ds)
			var dmv: String = SV.natural_start_of(SV.daily_dex(ds))
			if not ResourceLoader.exists("res://assets/previews/daily_%s.ogv" % dmv):
				dmv = String(MD.START.get(String(SV.dex_by[SV.daily_dex(ds)]["types"][0]), "tackle"))
			info["vid"] = "daily_" + dmv
			info["day"] = str(int(td["day"]))
			info["month"] = ["", "ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"][int(td["month"])]
			info["rule"] = L.t(String(MOD_INFO[dm][0]))
			pm = "daily"
		"rush":
			mp_stat.text = L.t("Récord: %d jefes") % int(SV.d.get("rush_best", 0))
			pm = "rush"
		"tower":
			var tw: Dictionary = SV.d.get("tower", {})
			mp_stat.text = L.t("Mejor piso: %d · Reliquias: %d / %d") % [int(tw.get("best", 0)), SV.tower_relics(), TOWER_FLOORS_M / 5]
			var tstarts: Array = [1]
			var tcl: Dictionary = tw.get("claimed", {})
			for k in range(5, TOWER_FLOORS_M, 5):
				if tcl.has(str(k)):
					tstarts.append(k + 1)
			var tcur: int = int(SV.d.get("tower_start", 1))
			if not tstarts.has(tcur):
				tcur = 1
				SV.d["tower_start"] = 1
			info["floor"] = tcur
			info["floor_lbl"] = L.t("Piso")
			if tstarts.size() > 1:
				mp_opts.add_child(_btn(L.t("Piso inicial: %d") % tcur, func():
					var i: int = tstarts.find(int(SV.d.get("tower_start", 1)))
					SV.d["tower_start"] = int(tstarts[(i + 1) % tstarts.size()])
					SV.save()
					_modes_select("tower"), Vector2(0, 46)))
			pm = "tower"
		"rifts":
			mp_stat.text = L.t("Récord: %d grietas") % int(SV.d.get("rifts_best", 0))
			pm = "rifts"
		"type":
			var ty: String = String(SV.d.get("mode_type", "fire"))
			if not TYPE_IDS.has(ty):
				ty = "fire"
			mp_stat.text = L.t("Tipo: %s") % L.t(String(MD.TYPE_NAME[ty]))
			var ids: Array = []
			for maxr in [2, 3, 9]:
				ids.clear()
				for p in SV.dex_list:
					if ids.size() >= 10:
						break
					if Array(p["types"]).has(ty) and int(p["rarity"]) <= maxr and not bool(p.get("leg", false)):
						ids.append(int(p["dex"]))
				if ids.size() >= 6:
					break
			info["dexes"] = ids
			info["type_lbl"] = L.t(String(MD.TYPE_NAME[ty]))
			mp_opts.add_child(_btn(L.t("Cambiar tipo: %s") % L.t(String(MD.TYPE_NAME[ty])), func():
				SV.d["mode_type"] = String(TYPE_IDS[(TYPE_IDS.find(ty) + 1) % TYPE_IDS.size()])
				SV.save()
				_modes_select("type"), Vector2(0, 46)))
			pm = "type"
		"team":
			var tl: Array = SV.team_list()
			var names: Array = []
			for x in tl:
				names.append(_name_of(int(x)))
			info["team"] = tl
			if SV.owned_count() >= 2:
				mp_stat.text = L.t("Equipo: %s") % ", ".join(names)
				mp_opts.add_child(_btn(L.t("Elegir equipo (hasta 3)"), func():
					dex_pick_team = true
					SV.d["team"] = []
					toast(L.t("Toca hasta 3 Pokémon tuyos para el equipo"))
					_show("dex"), Vector2(0, 46)))
			else:
				mp_stat.text = L.t("Necesitas al menos 2 Pokémon para formar un equipo.")
				mp_play.disabled = true
			pm = "team"
		"coop":
			var cdx: int = int(SV.d.get("coop_dex", 0))
			if cdx <= 0 or not SV.dex_by.has(cdx):
				cdx = 133
				for x in SV.team_list():
					if int(x) != int(SV.d["selected"]):
						cdx = int(x)
						break
			info["coop"] = cdx
			mp_stat.text = L.t("Compañero: %s") % _name_of(cdx)
			mp_opts.add_child(_btn(L.t("Elegir compañero"), func():
				dex_pick_coop = true
				toast(L.t("Toca el Pokémon que será tu compañero"))
				_show("dex"), Vector2(0, 46)))
			pm = "coop"
		"party":
			info["dex"] = SV.party_dex
			mp_stat.text = L.t("Pokémon de la fiesta: %s") % _name_of(SV.party_dex)
			mp_opts.add_child(_btn(L.t("Elegir Pokémon de la fiesta"), func():
				dex_pick_party = true
				toast(L.t("Toca un Pokémon para la fiesta"))
				_show("dex"), Vector2(0, 46)))
			pm = "party"
		"chal_p", "chal_d", "chal_w":
			CH.st()
			var cat: String = id.substr(5)
			var done_n := 0
			for d in CH.all():
				if CH.is_done(CH.key_perm(int(d["id"]))):
					done_n += 1
			if cat == "p":
				mp_stat.text = L.t("Completados: %d / 100") % done_n
			else:
				mp_stat.text = L.t("Se renuevan en %s") % CH.fmt_left(CH.secs_to_reset(cat == "w"))
			info["goal1"] = L.t("Sobrevive %d min") % 3
			mp_play.text = L.t("Ver retos")
			pm = "chal"
		"mods":
			mp_play.visible = false
			info["on"] = SV.run_mods
			var mg := GridContainer.new()
			mg.columns = 2
			mg.add_theme_constant_override("h_separation", 10)
			mg.add_theme_constant_override("v_separation", 4)
			mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mp_opts.add_child(mg)
			mp_stat.text = L.t("Toca un modificador para activarlo. Se suman todos.")
			for mid in SV.MOD_IDS:
				var cb := CheckButton.new()
				cb.text = L.t(String(MOD_INFO[mid][0]))
				cb.focus_mode = Control.FOCUS_ALL
				cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				cb.clip_text = true
				cb.icon = IC.btn_tex(String(MOD_ICON[mid]), 28)
				cb.add_theme_constant_override("icon_max_width", 28)
				cb.add_theme_font_size_override("font_size", 18)
				cb.button_pressed = SV.run_mods.has(mid)
				var minfo: String = L.t(String(MOD_INFO[mid][1]))
				cb.focus_entered.connect(func(): mp_stat.text = minfo)
				cb.mouse_entered.connect(func(): mp_stat.text = minfo)
				cb.toggled.connect(func(on: bool):
					mp_stat.text = minfo
					if on and not SV.run_mods.has(mid):
						SV.run_mods.append(mid)
					elif not on:
						SV.run_mods.erase(mid)
					SV.d["mods"] = SV.run_mods.duplicate()
					SV.save()
					mp_prev.info["on"] = SV.run_mods)
				mg.add_child(cb)
			pm = "mods"
	if id != "daily" and id != "party":
		mp_play.disabled = mp_play.disabled and id == "team"
	else:
		mp_play.disabled = false
	if id != "team":
		mp_play.disabled = false
	if id == "team" and SV.owned_count() < 2:
		mp_play.disabled = true
	(mp_prev.get_parent() as Control).visible = not id.begins_with("chal_")
	mp_opts_sc.custom_minimum_size = Vector2.ZERO
	mp_opts_sc.visible = mp_opts.get_child_count() > 0
	mp_prev.custom_minimum_size = Vector2(0, 150 if id == "mods" else 170)
	(mp_prev as Control).call("setup", pm, info)
	# El triangulo de Jugar va pegado al texto, que cambia de largo segun el modo
	var ptw: float = mp_play.get_theme_font("font").get_string_size(mp_play.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, mp_play.get_theme_font_size("font_size")).x
	mp_play_ic.offset_left = -ptw * 0.5 - 46.0
	mp_play_ic.offset_right = -ptw * 0.5 - 10.0


func _modes_play() -> void:
	var id: String = modes_sel
	if id.begins_with("chal_"):
		chal_cat = id.substr(5)
		_show("chal")
	else:
		_start_mode(id)



# ---------------------------------------------------------------
# Retos de 10 minutos (challenges.gd): pantalla propia, se abre desde Jugar > Retos
# ---------------------------------------------------------------
var chal_box: VBoxContainer
var chal_cat := "p"      # p permanentes, d diarios, w semanales
var chal_diff := ""      # filtro de dificultad de los permanentes ("" = todos)


func _build_chal() -> void:
	var s: Control = _screen("chal")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	chal_box = VBoxContainer.new()
	chal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chal_box.add_theme_constant_override("separation", 8)
	sc.add_child(chal_box)


func _coin_row(n: int, gold: bool, size: float = 26.0) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	r.add_child(IC.rect("gcoin_gold" if gold else "gcoin", size))
	var l := _label("×%d" % n, int(size * 0.85), Color("#ffd23f") if gold else Color("#9fd0ff"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_child(l)
	return r


func _chal_card(d: Dictionary, inst: Dictionary) -> Button:
	var done: bool = CH.is_done(String(inst["key"]))
	var ok: bool = CH.available(d)
	var gold: bool = CH.reward_gold(inst)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.14, 0.36, 0.8) if ok else Color(0.1, 0.1, 0.16, 0.7), Color("#ffd23f") if (gold and ok) else Color("#33498f"), 3 if gold else 2, 14))
	chal_box.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	pc.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	col.add_child(top)
	var num := _label("#%03d" % int(d["id"]), 18, Color("#8fa3d0"))
	num.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(num)
	var nm := _label(CH.name_of(d), 24, Color.WHITE if ok else Color("#8a93a8"))
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(nm)
	var dc := PanelContainer.new()
	dc.add_theme_stylebox_override("panel", _sb(Color(CH.DIFF_COL[String(d["d"])], 0.25), CH.DIFF_COL[String(d["d"])], 2, 8))
	var dl := _label(L.t(String(CH.DIFF_NAME[String(d["d"])])), 16, CH.DIFF_COL[String(d["d"])])
	dl.autowrap_mode = TextServer.AUTOWRAP_OFF
	dc.add_child(dl)
	top.add_child(dc)
	for ln in CH.lines(d, CH.new_metrics()):
		col.add_child(_label("• " + String(ln[0]), 18, Color("#d6e2ff") if ok else Color("#7d869b")))
	for rt in CH.restrictions(d):
		col.add_child(_label("⚠ " + String(rt), 17, Color("#ffb454") if ok else Color("#7d869b")))
	var rc := VBoxContainer.new()
	rc.custom_minimum_size = Vector2(190, 0)
	rc.alignment = BoxContainer.ALIGNMENT_CENTER
	rc.add_theme_constant_override("separation", 8)
	row.add_child(rc)
	var cr := _coin_row(1, gold)
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	rc.add_child(cr)
	var out: Button = null
	var b: Button
	if done:
		b = _btn("Reclamado", func(): pass, Vector2(180, 48))
		b.disabled = true
	elif not ok:
		b = _btn("Próximamente", func(): pass, Vector2(180, 48))
		b.disabled = true
	else:
		var ii: Dictionary = inst
		b = _btn("Jugar", func(): _chal_play(ii), Vector2(180, 48))
		out = b
	rc.add_child(b)
	return out


func _chal_play(inst: Dictionary) -> void:
	SV.run_mode = "chal"
	SV.run_chal = inst.duplicate()
	SV.run_mods = []
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _refresh_chal() -> void:
	_clear(chal_box)
	CH.st()
	var sel_chip: Button = null
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 22)
	var t1 := _label("Retos de 10 minutos", 28, C_GOLD)
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bal.add_child(t1)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 30.0))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 30.0))
	var bsp := Control.new()
	bsp.custom_minimum_size = Vector2(14, 0)
	bal.add_child(bsp)
	chal_box.add_child(bal)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	chal_box.add_child(chips)
	for c in [["p", "Permanentes"], ["d", "Diarios"], ["w", "Semanales"]]:
		var ck: String = String(c[0])
		var cb := _btn(String(c[1]), func(): chal_cat = ck; _refresh_chal(); _gf(tab_sel), Vector2(190, 46))
		_gold_btn(cb, ck == chal_cat)
		chips.add_child(cb)
		if ck == chal_cat:
			sel_chip = cb
			tab_sel = cb
	tab_row = chips
	chal_box.add_child(_label("Cada intento dura 10 minutos como máximo. Si no lo logras, no hay premio y puedes reintentar. Cada reto da su premio una sola vez.", 16, Color("#c8d6ee")))
	var first_card: Button = null
	if chal_cat == "p":
		var dch := HFlowContainer.new()
		dch.add_theme_constant_override("h_separation", 8)
		chal_box.add_child(dch)
		for f in [["", "Todos"], ["e", "Fácil"], ["n", "Normal"], ["h", "Difícil"], ["x", "Nivel experto"]]:
			var fk: String = String(f[0])
			var fb := _btn(String(f[1]), func(): chal_diff = fk; _refresh_chal(), Vector2(130, 40))
			_gold_btn(fb, fk == chal_diff)
			dch.add_child(fb)
		var done_n := 0
		for d in CH.all():
			if CH.is_done(CH.key_perm(int(d["id"]))):
				done_n += 1
		chal_box.add_child(_label(L.t("Completados: %d / 100") % done_n, 20, Color("#cfd9f5")))
		for d in CH.all():
			if chal_diff != "" and String(d["d"]) != chal_diff:
				continue
			var b: Button = _chal_card(d, CH.instance_perm(d))
			if b != null and first_card == null:
				first_card = b
	else:
		var wk: bool = chal_cat == "w"
		var lst: Array = CH.weekly() if wk else CH.daily()
		chal_box.add_child(_label(L.t("Se renuevan en %s") % CH.fmt_left(CH.secs_to_reset(wk)), 20, Color("#ffd23f")))
		for inst in lst:
			var b2: Button = _chal_card(CH.by_id(int(inst["id"])), inst)
			if b2 != null and first_card == null:
				first_card = b2
	focus_first = first_card if first_card != null else sel_chip



func _refresh_main() -> void:
	var dex: int = int(SV.d["selected"])
	if not SV.owns(dex) and SV.owned_count() > 0:
		dex = int(SV.d["owned"].keys()[0])
		SV.d["selected"] = dex
	var shn: bool = bool(SV.d["shiny_on"]) and SV.owns(dex) and bool(SV.d["owned"][str(dex)]["shiny"])
	if is_instance_valid(main_prev):
		main_prev.queue_free()
	main_prev = Preview.new()
	main_prev.custom_minimum_size = Vector2(340, 190)
	main_prev.fit_k = 1.25
	main_card.add_child(main_prev)
	main_prev.setup(dex, shn, 6.0)
	main_info.text = "%s · %s" % [_name_of(dex), _type_text(dex)]
	_clear(main_type)
	for dty in SV.dex_by[dex]["types"]:
		main_type.add_child(IC.rect("type:" + String(dty), 36))
	var ttl: String = String(SV.d.get("title", ""))
	main_title.visible = ttl != ""
	(main_title.get_child(0) as Label).text = L.t(ttl) if ttl != "" else ""
	PG.ensure()
	PG.check()
	var pn: int = PG.pending()
	goals_btn.text = L.t("Misiones y logros") + ("  (%d)" % pn if pn > 0 else "")
	var st: Dictionary = SV.d["stats"]
	var stx: String = L.t("Partidas %d · Mejor tiempo %d:%02d\nMejor nivel %d · Derrotados %d\nPokémon %d / %d") % [int(st["runs"]), int(st["best_time"]) / 60, int(st["best_time"]) % 60, int(st["best_level"]), int(st["kills"]), SV.owned_count(), SV.dex_list.size()]
	_clear(main_stats)
	var sln: PackedStringArray = stx.split("\n")
	for si in range(sln.size()):
		var sr := HBoxContainer.new()
		sr.add_theme_constant_override("separation", 10)
		main_stats.add_child(sr)
		sr.add_child(IC.rect(["clock", "crown", "ball"][mini(si, 2)], 26))
		var sl := _label(sln[si], 17)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sr.add_child(sl)
	var lb = main_btns.get(last_pick, null)
	focus_first = lb if lb != null and is_instance_valid(lb) else main_play_btn


# Pantalla de fin de partida como la del original: titulo, cuadricula de datos,
# monedas con desglose, tickets, movimientos y boton de volver.
func _stat_cell(label: String, value: String, col: Color = Color.WHITE, wide: bool = false) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	v.add_child(_label(label, 16, Color("#9fb4dc")))
	var l := _label(value, 28 if not wide else 24, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l)
	return pc


func _show_run_summary() -> void:
	var r: Dictionary = SV.last_run
	SV.last_run = {}
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 40
	add_child(ov)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(620, 0)
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14))
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Todo el contenido va en un scroll de alto limitado a la pantalla y el boton queda FIJO debajo (antes se salia y no se veia).
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	var sum_sc := ScrollContainer.new()
	sum_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sum_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sum_sc.add_child(v)
	outer.add_child(sum_sc)
	pc.add_child(outer)
	var title := _label("Has caído…" if bool(r.get("dead", true)) else "Partida terminada", 38, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var t: int = int(r["time"])
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	g.add_child(_stat_cell(L.t("Tiempo"), "%02d:%02d" % [t / 60, t % 60]))
	g.add_child(_stat_cell(L.t("Nivel"), str(int(r["level"]))))
	g.add_child(_stat_cell(L.t("Derrotados"), str(int(r["kills"]))))
	g.add_child(_stat_cell(L.t("Jefes"), str(int(r["bosses"]))))
	var jr: Dictionary = r.get("judge", {})
	if not jr.is_empty():
		var jt: int = int(jr["time"])
		var jb: int = int(jr["bosses"])
		var jc := _stat_cell(L.t("Ante Arceus"), "%d:%02d · %d %s" % [jt / 60, jt % 60, jb, L.t("legendario") if jb == 1 else L.t("legendarios")], C_GOLD, true)
		v.add_child(jc)
	# monedas con desglose
	var cc := PanelContainer.new()
	cc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	cc.add_child(cv)
	cv.add_child(_label("Pokémonedas ganadas", 16, Color("#9fb4dc")))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 8)
	gr.add_child(IC.rect("coin", 28))
	var gl := _label("+%d" % int(r["coins"]), 28, Color("#ffd23f"))
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gr.add_child(gl)
	cv.add_child(gr)
	if String(r.get("breakdown", "")) != "":
		var bl := _label(L.t("Recogidas %d · Tiempo +%d · Derrotados +%d") % _bd_nums(String(r["breakdown"])), 13, Color("#9fb4dc"))
		bl.autowrap_mode = TextServer.AUTOWRAP_OFF
		cv.add_child(bl)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(cc)
	v.add_child(mid)
	if int(r["tickets"]) > 0 or int(r.get("tickets10", 0)) > 0:
		var tc := PanelContainer.new()
		tc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 2)
		tc.add_child(tv)
		tv.add_child(_label("Tickets del gacha", 16, Color("#9fb4dc")))
		var tr := HBoxContainer.new()
		tr.add_theme_constant_override("separation", 8)
		if int(r["tickets"]) > 0:
			tr.add_child(IC.rect("ticket", 26))
			var tl1 := _label("+%d" % int(r["tickets"]), 26, Color("#ffd23f"))
			tl1.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl1)
		if int(r.get("tickets10", 0)) > 0:
			tr.add_child(IC.rect("ticket10", 26))
			var tl2 := _label("+%d ×10" % int(r["tickets10"]), 26, Color("#c47bff"))
			tl2.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl2)
		tv.add_child(tr)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(tc)
	# movimientos de la partida
	var mc := PanelContainer.new()
	mc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mc.add_child(mv)
	mv.add_child(_label("Daño y derrotas por movimiento", 16, Color("#9fb4dc")))
	var mlist: Array = r.get("moves", []).duplicate()
	mlist.sort_custom(func(x, y): return int(x.get("dmg", 0)) > int(y.get("dmg", 0)))
	var tot_dmg: int = int(r.get("other_dmg", 0))
	tot_dmg += int(r.get("ally_dmg", 0))
	for m0 in mlist:
		tot_dmg += int(m0.get("dmg", 0))
	var mg := GridContainer.new()
	mg.columns = 3
	mg.add_theme_constant_override("h_separation", 18)
	mg.add_theme_constant_override("v_separation", 3)
	if mlist.size() > 999:
		var msc := ScrollContainer.new()
		msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		msc.custom_minimum_size = Vector2(0, 170)
		mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msc.add_child(mg)
		mv.add_child(msc)
	else:
		mv.add_child(mg)
	if mlist.is_empty():
		mg.add_child(_label("—", 18))
	else:
		var h1 := _label("Movimiento", 13, Color("#7f93c2"))
		h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h1.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h1)
		var h2 := _label("Daño", 13, Color("#7f93c2"))
		h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h2.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h2)
		var h3 := _label("Derrotados", 13, Color("#7f93c2"))
		h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h3.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h3)
	for m in mlist:
		var mr := HBoxContainer.new()
		mr.add_theme_constant_override("separation", 6)
		mr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mr.add_child(IC.rect(("evo:" if bool(m.get("evo", false)) else "move:") + String(m["id"]), 20))
		var mnm: String = String(m["name"])
		var mparts: PackedStringArray = mnm.split(" + ")
		var mtr: Array = []
		for mp in mparts:
			mtr.append(L.t(mp))
		var ml := _label("%s Nv.%d" % [" + ".join(PackedStringArray(mtr)), int(m["lvl"])], 17)
		ml.autowrap_mode = TextServer.AUTOWRAP_OFF
		mr.add_child(ml)
		mg.add_child(mr)
		var md_: int = int(m.get("dmg", 0))
		var pct: int = roundi(100.0 * float(md_) / float(maxi(1, tot_dmg)))
		var dl := _label("%s (%d%%)" % [_fmt_n(md_), pct], 17, Color("#ffd23f"))
		dl.autowrap_mode = TextServer.AUTOWRAP_OFF
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(dl)
		var kl := _label(str(int(m.get("kills", 0))), 17)
		kl.autowrap_mode = TextServer.AUTOWRAP_OFF
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(kl)
	if int(r.get("ally_dmg", 0)) > 0 or int(r.get("ally_kills", 0)) > 0:
		var al := _label("Compañero / equipo", 17, Color("#8fe3b0"))
		al.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(al)
		var ad := _label("%s (%d%%)" % [_fmt_n(int(r.get("ally_dmg", 0))), roundi(100.0 * float(int(r.get("ally_dmg", 0))) / float(maxi(1, tot_dmg)))], 17, Color("#8fe3b0"))
		ad.autowrap_mode = TextServer.AUTOWRAP_OFF
		ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ad)
		var ak := _label(str(int(r.get("ally_kills", 0))), 17, Color("#8fe3b0"))
		ak.autowrap_mode = TextServer.AUTOWRAP_OFF
		ak.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ak)
	if int(r.get("other_dmg", 0)) > 0 or int(r.get("other_kills", 0)) > 0:
		var ol := _label("Otros (estados, trampas, objetos)", 15, Color("#9fb4dc"))
		ol.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(ol)
		var od := _label(_fmt_n(int(r.get("other_dmg", 0))), 15, Color("#9fb4dc"))
		od.autowrap_mode = TextServer.AUTOWRAP_OFF
		od.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(od)
		var ok2 := _label(str(int(r.get("other_kills", 0))), 15, Color("#9fb4dc"))
		ok2.autowrap_mode = TextServer.AUTOWRAP_OFF
		ok2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ok2)
	v.add_child(mc)
	# v5.2: objetos y movimientos de la partida con su descripcion
	var info_items: Array = r.get("items", [])
	var info_moves: Array = r.get("moves", [])
	if not info_items.is_empty() or not info_moves.is_empty():
		var ic2 := PanelContainer.new()
		ic2.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
		var iv := VBoxContainer.new()
		iv.add_theme_constant_override("separation", 5)
		ic2.add_child(iv)
		if not info_items.is_empty():
			iv.add_child(_label("Objetos", 16, Color("#9fb4dc")))
			for iid in info_items:
				for it in TD.ITEMS:
					if String(it["id"]) == String(iid):
						var irow := HBoxContainer.new()
						irow.add_theme_constant_override("separation", 8)
						irow.add_child(IC.rect(String(it["id"]), 30))
						var itx := _label("%s: %s" % [L.t(String(it["name"])), L.t(String(it["desc"]))], 15)
						itx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						irow.add_child(itx)
						iv.add_child(irow)
		if not info_moves.is_empty():
			iv.add_child(_label("Qué hace cada movimiento", 16, Color("#9fb4dc")))
			for m1 in info_moves:
				if String(m1.get("desc", "")) == "":
					continue
				var mrow := HBoxContainer.new()
				mrow.add_theme_constant_override("separation", 8)
				mrow.add_child(IC.rect(("evo:" if bool(m1.get("evo", false)) else "move:") + String(m1["id"]), 26))
				var mtx := _label("%s: %s" % [L.t(String(m1["name"])), L.t(String(m1["desc"]))], 15)
				mtx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				mrow.add_child(mtx)
				iv.add_child(mrow)
		v.add_child(ic2)
	if bool(r.get("record", false)):
		var rl := _label("¡Nuevo récord de tiempo!", 22, C_GOLD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer.add_child(rl)
	var ok := _btn("Volver al menú", func(): ov.queue_free(); _update_top(); focus_first = main_play_btn; main_play_btn.grab_focus(), Vector2(260, 56))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(ok)
	_gf(ok)
	var fit := func():
		var avail: float = get_viewport_rect().size.y - 150.0
		sum_sc.custom_minimum_size = Vector2(0, clampf(v.get_combined_minimum_size().y, 100.0, maxf(100.0, avail)))
	fit.call()
	fit.call_deferred()
	_update_top()


func _fmt_n(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%.1fk" % (float(n) / 1000.0)
	return str(n)


func _bd_nums(bd: String) -> Array:
	var out: Array = []
	for part in bd.split(" · "):
		out.append(int(part.get_slice(" ", part.get_slice_count(" ") - 1).replace("+", "")))
	while out.size() < 3:
		out.append(0)
	return out


# ---------------------------------------------------------------
# Test de personalidad
# ---------------------------------------------------------------
func _build_test() -> void:
	var s: Control = _screen("test")
	var c := CenterContainer.new()
	s.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(820, 0)
	c.add_child(pc)
	test_box = VBoxContainer.new()
	pc.add_child(test_box)


func _refresh_test() -> void:
	test_idx = -1
	test_scores = {}
	_clear(test_box)
	test_box.add_child(_label("¡Bienvenido a Pokémon Survivors!", 36, C_GOLD))
	test_box.add_child(_label("Como en Mundo Misterioso, unas preguntas decidirán tu personalidad y tu compañero.\nPuedes aceptar el resultado o elegir otro Pokémon inicial.", 24))
	var b := _btn("Empezar el test", func(): _test_next(), Vector2(0, 60))
	test_box.add_child(b)
	focus_first = b


func _test_next() -> void:
	test_idx += 1
	_clear(test_box)
	if test_idx >= ST.TEST.size():
		_test_finish()
		return
	var q: Dictionary = ST.TEST[test_idx]
	test_box.add_child(_label(L.t("Pregunta %d / %d") % [test_idx + 1, ST.TEST.size()], 20, Color("#9fb4f0")))
	test_box.add_child(_label(String(q["q"]), 30, Color.WHITE))
	var first: Button = null
	for a in q["a"]:
		var ans: Dictionary = a
		var b := _btn(String(ans["t"]), func(): _test_answer(ans), Vector2(0, 56))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		test_box.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _test_answer(ans: Dictionary) -> void:
	for k in ans["p"]:
		test_scores[k] = int(test_scores.get(k, 0)) + int(ans["p"][k])
	_test_next()


func _test_finish() -> void:
	var trt := ""
	var best := -1
	for k in test_scores:
		if int(test_scores[k]) > best:
			best = int(test_scores[k])
			trt = String(k)
	var cands: Array = []
	var best_s := -1
	for s in ST.STARTERS:
		var v: int = int(test_scores.get(String(s["traits"][0]), 0)) * 2 + int(test_scores.get(String(s["traits"][1]), 0))
		if v > best_s:
			best_s = v
			cands = [s]
		elif v == best_s:
			cands.append(s)
	test_result_dex = int(cands[randi() % cands.size()]["dex"])
	_test_show_result(trt)


func _test_show_result(trt: String) -> void:
	_clear(test_box)
	test_box.add_child(_label(L.t("Tu personalidad: %s") % L.t(trt.capitalize()), 34, C_GOLD))
	test_box.add_child(_label(String(ST.TRAIT_TEXT.get(trt, "")), 22, Color("#c8d6ee")))
	var pv := Preview.new()
	pv.custom_minimum_size = Vector2(0, 220)
	test_box.add_child(pv)
	pv.setup(test_result_dex, false, 5.0)
	var nm := _label(L.t("Tu compañero: %s (%s)") % [_name_of(test_result_dex), _type_text(test_result_dex)], 28)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_box.add_child(nm)
	var row := HBoxContainer.new()
	test_box.add_child(row)
	var ok := _btn("¡Aceptar!", func(): _accept_starter(test_result_dex), Vector2(0, 58))
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	var other := _btn("Elegir otro", func(): _test_pick_other(), Vector2(0, 58))
	other.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(other)
	_gf(ok)


func _test_pick_other() -> void:
	_clear(test_box)
	test_box.add_child(_label("Elige a tu compañero", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 6
	test_box.add_child(grid)
	var first: Button = null
	for s in ST.STARTERS:
		var dx: int = int(s["dex"])
		var b := _btn("", func(): _accept_starter(dx), Vector2(120, 100))
		var tx: Texture2D = _icon_tex(dx, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.text = _name_of(dx)
		b.add_theme_font_size_override("font_size", 14)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		grid.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _accept_starter(dex: int) -> void:
	SV.add_owned(dex)
	SV.d["selected"] = dex
	SV.save()
	toast(L.t("¡%s se une a tu equipo!") % _name_of(dex))
	_show("main")


# ---------------------------------------------------------------
# Iconos
# ---------------------------------------------------------------
func _icon_tex(dex: int, shiny: bool) -> Texture2D:
	var an: Dictionary = Preview.anim_of(dex)
	if an.is_empty():
		return null
	var tx: Texture2D = Preview.tex_of(dex, String(an["name"]), shiny)
	if tx == null:
		return null
	var info: Dictionary = an["info"]
	var at := AtlasTexture.new()
	at.atlas = tx
	at.region = Rect2(0.0, 0.0, float(info["w"]), float(info["h"]))
	return at


# ---------------------------------------------------------------
# Coleccion de Pokemon
# ---------------------------------------------------------------
# Fondo del retrato: paisaje con cielo, montanas y claro (tintado con el tipo del Pokemon).
class DexBack extends Control:
	var tint := Color("#ff7b3d")

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var top := Color("#4f9be0").lerp(tint, 0.14)
		var bot := Color("#d6ecff").lerp(tint, 0.10)
		var n := 22
		for i in n:
			draw_rect(Rect2(0, h * float(i) / n, w, h / n + 1.0), top.lerp(bot, float(i) / float(n - 1)))
		draw_circle(Vector2(w * 0.80, h * 0.20), 38.0, Color(1, 1, 0.85, 0.22))
		draw_circle(Vector2(w * 0.80, h * 0.20), 22.0, Color(1, 1, 0.92, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-10, h * 0.66), Vector2(w * 0.2, h * 0.3), Vector2(w * 0.42, h * 0.66)]), Color("#4673ad").lerp(tint, 0.08))
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.3, h * 0.66), Vector2(w * 0.62, h * 0.38), Vector2(w * 1.05, h * 0.66)]), Color("#5a86bd").lerp(tint, 0.08))
		draw_rect(Rect2(0, h * 0.62, w, h * 0.38), Color("#4a9a46"))
		draw_rect(Rect2(0, h * 0.62, w, 5), Color("#6cc064"))
		draw_set_transform(Vector2(w * 0.5, h * 0.80), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, w * 0.30, Color("#c9b072"))
		draw_circle(Vector2.ZERO, w * 0.24, Color("#dcc58a"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 16:
			var fx: float = fposmod(float(i) * 97.3, w)
			var fy: float = h * (0.7 + 0.28 * fposmod(float(i) * 0.37, 1.0))
			draw_rect(Rect2(fx, fy, 3, 3), Color(1, 0.95, 0.6, 0.8) if i % 3 == 0 else Color("#7ed275"))


var dex_search := ""
var dex_type := ""
var dex_sort := 0
var dex_cards: Dictionary = {}
var dex_hearts: Dictionary = {}
var dex_tabs: Array = []
var dex_pv_box: Control
var dex_namebar: HBoxContainer
var dex_name_heart: Button
var dex_foot: HBoxContainer
var dex_hint: Label
var dex_stat_max: Dictionary = {}
const RAR_COL := ["#b0a99f", "#5fcb6a", "#4b9bff", "#b45ec4", "#ffd33d"]


func _dpanel(col: Color = Color(0.05, 0.1, 0.26, 0.72)) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := _sb(col, Color("#33498f"), 2, 12)
	st.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", st)
	return pc


func _is_fav(dx: int) -> bool:
	return Dictionary(SV.d.get("dex_fav", {})).has(str(dx))


func _heart_btn(dx: int, size: float) -> Button:
	var hb := Button.new()
	hb.flat = true
	hb.focus_mode = Control.FOCUS_NONE
	hb.icon = IC.btn_tex("heart", size)
	hb.add_theme_constant_override("icon_max_width", int(size))
	hb.custom_minimum_size = Vector2(size + 8.0, size + 8.0)
	hb.pressed.connect(func(): _fav_toggle(dx))
	hb.modulate = Color(1, 0.3, 0.42) if _is_fav(dx) else Color(0.25, 0.32, 0.55, 0.9)
	return hb


func _fav_toggle(dx: int) -> void:
	var fv: Dictionary = Dictionary(SV.d.get("dex_fav", {}))
	if fv.has(str(dx)):
		fv.erase(str(dx))
	else:
		fv[str(dx)] = true
	SV.d["dex_fav"] = fv
	SV.save()
	Aud.sfx("click")
	for k in dex_hearts:
		var hb: Button = dex_hearts[k]
		if is_instance_valid(hb):
			hb.modulate = Color(1, 0.3, 0.42) if _is_fav(absi(int(k))) else Color(0.25, 0.32, 0.55, 0.9)


func _build_dex() -> void:
	var s: Control = _screen("dex")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	s.add_child(row)
	# ---- izquierda: retrato + ficha
	var dp := PanelContainer.new()
	dp.custom_minimum_size = Vector2(430, 0)
	var dst := _sb(Color("#0c1a3c"), Color("#c9a34a"), 4, 16)
	dst.set_content_margin_all(8)
	dp.add_theme_stylebox_override("panel", dst)
	row.add_child(dp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	dp.add_child(lv)
	var port := DexBack.new()
	port.custom_minimum_size = Vector2(0, 230)
	port.clip_contents = true
	lv.add_child(port)
	dex_pv_box = Control.new()
	dex_pv_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	dex_pv_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	port.add_child(dex_pv_box)
	for sd in [-1, 1]:
		var ab := Button.new()
		ab.focus_mode = Control.FOCUS_ALL
		ab.text = "◀" if sd < 0 else "▶"
		ab.add_theme_font_size_override("font_size", 26)
		ab.custom_minimum_size = Vector2(54, 54)
		ab.anchor_top = 0.5
		ab.anchor_bottom = 0.5
		ab.anchor_left = 0.0 if sd < 0 else 1.0
		ab.anchor_right = ab.anchor_left
		ab.offset_left = 6.0 if sd < 0 else -60.0
		ab.offset_right = ab.offset_left + 54.0
		ab.offset_top = -27.0
		ab.offset_bottom = 27.0
		var dsd: int = sd
		ab.pressed.connect(func(): Aud.sfx("click"); _dex_step(dsd))
		port.add_child(ab)
	var nbp := _dpanel(Color("#0a1738"))
	lv.add_child(nbp)
	dex_namebar = HBoxContainer.new()
	dex_namebar.add_theme_constant_override("separation", 10)
	nbp.add_child(dex_namebar)
	var dsc := ScrollContainer.new()
	dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dsc.follow_focus = true
	lv.add_child(dsc)
	dex_detail = VBoxContainer.new()
	dex_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_detail.add_theme_constant_override("separation", 8)
	dsc.add_child(dex_detail)
	dex_foot = HBoxContainer.new()
	lv.add_child(dex_foot)
	# ---- derecha: pestanas de region, filtros, cuadricula
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	var rpn := PanelContainer.new()
	rpn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rst := _sb(Color(0.04, 0.09, 0.22, 0.82), Color("#33498f"), 3, 16)
	rst.set_content_margin_all(10)
	rpn.add_theme_stylebox_override("panel", rst)
	row.add_child(rpn)
	rpn.add_child(right)
	dex_hint = _label("", 20, C_GOLD)
	dex_hint.visible = false
	right.add_child(dex_hint)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	right.add_child(tabs)
	dex_tabs.clear()
	var names := ["Todas"]
	for i in range(9):
		names.append(String(SV.REGIONS[i]))
	for i in range(names.size()):
		var gi: int = i
		var tb := _btn(L.t(String(names[i])), func(): dex_gen = gi; dex_page = 0; _refresh_dex(), Vector2(0, 40))
		tb.add_theme_font_size_override("font_size", 16)
		tabs.add_child(tb)
		dex_tabs.append(tb)
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 10)
	right.add_child(frow)
	var own := CheckButton.new()
	own.text = "Solo los míos"
	own.add_theme_font_size_override("font_size", 18)
	own.button_pressed = dex_only_owned
	own.toggled.connect(func(on: bool): dex_only_owned = on; dex_page = 0; _refresh_dex())
	frow.add_child(own)
	var se := LineEdit.new()
	se.placeholder_text = L.t("Buscar Pokémon…")
	se.clear_button_enabled = true
	se.custom_minimum_size = Vector2(0, 44)
	se.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	se.add_theme_font_size_override("font_size", 18)
	var sest := _sb(Color("#0f1f48"), Color("#3a5aa0"), 2, 10)
	se.add_theme_stylebox_override("normal", sest)
	se.add_theme_stylebox_override("focus", _sb(Color("#12265a"), C_GOLD, 3, 10))
	se.text_changed.connect(func(t: String): dex_search = t.strip_edges().to_lower(); dex_page = 0; _refresh_dex())
	frow.add_child(se)
	# v6.1: filtro por tipo, con el icono de cada tipo en la lista
	var tf := OptionButton.new()
	tf.custom_minimum_size = Vector2(112, 44)
	tf.clip_text = true
	tf.fit_to_longest_item = false
	tf.add_theme_font_size_override("font_size", 18)
	tf.add_item(L.t("Tipo"))
	var tkeys: Array = MD.TYPE_NAME.keys()
	for ty in tkeys:
		tf.add_icon_item(IC.btn_tex("type:" + String(ty), 30.0), L.t(String(MD.TYPE_NAME[ty])))
	tf.select(tkeys.find(dex_type) + 1)
	tf.item_selected.connect(func(ix: int):
		dex_type = "" if ix == 0 else String(tkeys[ix - 1])
		dex_page = 0
		_refresh_dex())
	frow.add_child(tf)
	var so := OptionButton.new()
	so.custom_minimum_size = Vector2(170, 44)
	so.clip_text = true
	so.fit_to_longest_item = false
	so.add_theme_font_size_override("font_size", 18)
	for o in ["Número (asc.)", "Número (desc.)", "Nombre (A-Z)", "Rareza", "Favoritos primero"]:
		so.add_item(L.t(String(o)))
	so.select(dex_sort)
	so.item_selected.connect(func(ix: int): dex_sort = ix; dex_page = 0; _refresh_dex())
	frow.add_child(so)
	var gsc := ScrollContainer.new()
	gsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gsc.follow_focus = true
	right.add_child(gsc)
	dex_grid = GridContainer.new()
	dex_grid.columns = 6
	dex_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_grid.add_theme_constant_override("h_separation", 8)
	dex_grid.add_theme_constant_override("v_separation", 8)
	gsc.add_child(dex_grid)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	right.add_child(nav)
	nav.add_child(_btn("◀", func(): dex_page = maxi(0, dex_page - 1); _refresh_dex(), Vector2(90, 44)))
	dex_page_lbl = _label("", 22)
	dex_page_lbl.custom_minimum_size = Vector2(260, 0)
	dex_page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(dex_page_lbl)
	nav.add_child(_btn("▶", func(): dex_page += 1; _refresh_dex(), Vector2(90, 44)))


func _dex_filtered() -> Array:
	var out: Array = []
	var q: String = dex_search
	for p in SV.dex_list:
		if dex_gen != 0 and int(p["gen"]) != dex_gen:
			continue
		var dxo: int = int(p["dex"])
		if (dex_only_owned or dex_pick_team or dex_pick_coop) and not dex_pick_party and not SV.owns(dxo):
			continue
		if not SV.smeta.has(str(dxo)):
			continue
		if dex_type != "" and not (p["types"] as Array).has(dex_type):
			continue
		if q != "":
			var known: bool = SV.owns(dxo) or dex_pick_party
			var hit: bool = str(dxo).contains(q.trim_prefix("#"))
			if known and not hit:
				hit = L.t(String(p["name"])).to_lower().contains(q) or String(p["name"]).to_lower().contains(q)
				if not hit:
					for t in p["types"]:
						if L.t(String(MD.TYPE_NAME[String(t)])).to_lower().contains(q):
							hit = true
			if not hit:
				continue
		out.append(p)
	match dex_sort:
		1:
			out.sort_custom(func(a, b): return int(a["dex"]) > int(b["dex"]))
		2:
			out.sort_custom(func(a, b): return L.t(String(a["name"])) < L.t(String(b["name"])))
		3:
			out.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["dex"]) < int(b["dex"])))
		4:
			out.sort_custom(func(a, b):
				var fa: bool = _is_fav(int(a["dex"]))
				var fb: bool = _is_fav(int(b["dex"]))
				return (fa and not fb) or (fa == fb and int(a["dex"]) < int(b["dex"])))
	return out


func _dex_step(d: int) -> void:
	var list: Array = _dex_filtered()
	if list.is_empty():
		return
	var ix := -1
	for i in range(list.size()):
		if int(list[i]["dex"]) == dex_sel:
			ix = i
			break
	ix = posmod(ix + d, list.size())
	dex_sel = int(list[ix]["dex"])
	dex_page = ix / PER_PAGE
	_refresh_dex()


func _card_style(b: Button, base: Color, edge: Color, bw: int) -> void:
	b.add_theme_stylebox_override("normal", _sb(base, edge, bw, 10))
	b.add_theme_stylebox_override("hover", _sb(base.lightened(0.12), C_GOLD, 2, 10))
	b.add_theme_stylebox_override("pressed", _sb(base.darkened(0.1), C_GOLD, 3, 10))
	b.add_theme_stylebox_override("focus", _sb_focus(base.lightened(0.1)))


func _dex_mark() -> void:
	for k in dex_cards:
		var b: Button = dex_cards[k]
		if not is_instance_valid(b):
			continue
		var base: Color = b.get_meta("base")
		var sel: bool = int(k) == dex_sel
		var team: bool = bool(b.get_meta("team"))
		_card_style(b, base, C_GOLD if sel else (Color("#35d0b0") if team else Color("#3a5aa0")), 4 if sel else 2)


func _dex_card(p: Dictionary, owned: bool) -> Button:
	var dx: int = int(p["dex"])
	var show: bool = owned or dex_pick_party
	var types: Array = p["types"]
	var tcol := Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#b0a99f")))
	var b := Button.new()
	b.custom_minimum_size = Vector2(104, 126)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.clip_contents = true
	var base := Color(0.10, 0.16, 0.34, 0.95).lerp(tcol, 0.28) if show else Color(0.08, 0.11, 0.22, 0.95)
	b.set_meta("base", base)
	b.set_meta("team", dex_pick_team and Array(SV.d.get("team", [])).has(dx))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.offset_top = 4.0
	vb.offset_bottom = -4.0
	b.add_child(vb)
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(0, 58)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shn: bool = owned and bool(SV.d["owned"][str(dx)].get("shiny", false)) and bool(SV.d["shiny_on"])
	tr.texture = _icon_tex(dx, shn)
	if not show:
		tr.modulate = Color(0, 0, 0, 0.85)
	vb.add_child(tr)
	var nl := _label(("#%03d %s" % [dx, L.t(String(p["name"]))]) if show else "#%03d ???" % dx, 13)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.clip_text = true
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(nl)
	if show:
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(cc)
		var tg := PanelContainer.new()
		tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tst := _sb(tcol.darkened(0.25), tcol.lightened(0.25), 1, 6)
		tst.set_content_margin_all(2)
		tst.content_margin_left = 6
		tst.content_margin_right = 8
		tg.add_theme_stylebox_override("panel", tst)
		cc.add_child(tg)
		var th := HBoxContainer.new()
		th.add_theme_constant_override("separation", 4)
		th.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tg.add_child(th)
		var ti: TextureRect = IC.rect("type:" + String(types[0]), 20)
		ti.mouse_filter = Control.MOUSE_FILTER_IGNORE
		th.add_child(ti)
		var tl := _label(L.t(String(MD.TYPE_NAME[String(types[0])])).to_upper(), 12, Color.WHITE)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		th.add_child(tl)
		if types.size() > 1:
			var t2: TextureRect = IC.rect("type:" + String(types[1]), 20)
			t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			th.add_child(t2)
	if owned:
		var hb := _heart_btn(dx, 18.0)
		hb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		hb.offset_left = -34.0
		hb.offset_right = -2.0
		hb.offset_top = 2.0
		hb.offset_bottom = 34.0
		b.add_child(hb)
		dex_hearts[dx] = hb
		if dx == int(SV.d["selected"]):
			var st := IC.rect("star", 18)
			st.position = Vector2(6, 6)
			st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(st)
	return b


func _refresh_dex() -> void:
	var list: Array = _dex_filtered()
	var pages: int = maxi(1, ceili(float(list.size()) / float(PER_PAGE)))
	dex_page = clampi(dex_page, 0, pages - 1)
	_clear(dex_grid)
	dex_cards.clear()
	dex_hearts.clear()
	for i in range(dex_tabs.size()):
		_gold_btn(dex_tabs[i], i == dex_gen)
	dex_hint.visible = dex_pick_team or dex_pick_coop or dex_pick_party
	if dex_pick_team:
		dex_hint.text = L.t("Elige 3 Pokémon para tu equipo (%d / 3)") % Array(SV.d.get("team", [])).size()
	elif dex_pick_coop:
		dex_hint.text = L.t("Elige a tu compañero de cooperativo")
	elif dex_pick_party:
		dex_hint.text = L.t("Elige el Pokémon de la fiesta")
	var first: Button = null
	for i in range(dex_page * PER_PAGE, mini(list.size(), (dex_page + 1) * PER_PAGE)):
		var p: Dictionary = list[i]
		var dx: int = int(p["dex"])
		var owned: bool = SV.owns(dx)
		var b: Button = _dex_card(p, owned)
		if dex_pick_party:
			b.pressed.connect(func():
				SV.party_dex = dx
				dex_pick_party = false
				toast(L.t("Pokémon de la fiesta: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_coop:
			b.pressed.connect(func():
				SV.d["coop_dex"] = dx
				SV.save()
				dex_pick_coop = false
				toast(L.t("Compañero: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_team:
			b.pressed.connect(func():
				var tm: Array = Array(SV.d.get("team", []))
				if tm.has(dx):
					tm.erase(dx)
				elif tm.size() < 3:
					tm.append(dx)
				SV.d["team"] = tm
				SV.save()
				if tm.size() >= 3:
					dex_pick_team = false
					toast(L.t("¡Equipo listo!"))
					_show("modes")
				else:
					toast(L.t("Equipo: %d / 3") % tm.size())
					_refresh_dex())
		else:
			b.pressed.connect(func(): dex_sel = dx; Aud.sfx("click"); _dex_detail())
		b.focus_entered.connect(func(): Aud.sfx("hover"))
		dex_grid.add_child(b)
		dex_cards[dx] = b
		if first == null:
			first = b
	dex_page_lbl.text = L.t("Página %d / %d  (%d)") % [dex_page + 1, pages, list.size()]
	if not SV.dex_by.has(dex_sel):
		dex_sel = int(SV.d["selected"])
	_dex_detail()
	focus_first = first


func _stat_bar(title: String, value: String, frac: float, col: Color, icon: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if icon != "":
		row.add_child(IC.rect(icon, 28))
	var lb := _label(title, 18, Color("#e6eeff"))
	lb.custom_minimum_size = Vector2(96, 0)
	row.add_child(lb)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(frac, 0.0, 1.0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(80, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.1, 0.18, 0.9)
	bg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	var vl := _label(value, 20, Color.WHITE)
	vl.custom_minimum_size = Vector2(62, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(vl)
	return row


func _dex_detail() -> void:
	_clear(dex_detail)
	_clear(dex_pv_box)
	_clear(dex_namebar)
	_clear(dex_foot)
	dex_hearts.erase(-dex_sel)
	var dx: int = dex_sel
	var p: Dictionary = SV.dex_by[dx]
	var owned: bool = SV.owns(dx)
	var tcol := Color.html(String(MD.TYPE_COLOR.get(String(p["types"][0]), "#b0a99f")))
	(dex_pv_box.get_parent() as DexBack).tint = tcol
	dex_pv_box.get_parent().queue_redraw()
	# retrato
	var pv := Preview.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dex_pv_box.add_child(pv)
	var shiny_owned: bool = owned and bool(SV.d["owned"][str(dx)].get("shiny", false))
	pv.setup(dx, shiny_owned and bool(SV.d["shiny_on"]), 6.0, not owned)
	var ball := IC.rect("ball", 52)
	ball.position = Vector2(8, 8)
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dex_pv_box.add_child(ball)
	if owned:
		var bdg := PanelContainer.new()
		bdg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bst := _sb(tcol.darkened(0.3), tcol.lightened(0.3), 2, 12)
		bst.set_content_margin_all(5)
		bdg.add_theme_stylebox_override("panel", bst)
		bdg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		bdg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		bdg.offset_left = -10.0
		bdg.offset_right = -10.0
		bdg.offset_top = 8.0
		var bv := VBoxContainer.new()
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_theme_constant_override("separation", 0)
		bdg.add_child(bv)
		for t in p["types"]:
			var ir := IC.rect("type:" + String(t), 34)
			ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			bv.add_child(ir)
		var tl := _label(L.t(String(MD.TYPE_NAME[String(p["types"][0])])).to_upper(), 14, Color.WHITE)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		bv.add_child(tl)
		dex_pv_box.add_child(bdg)
	# barra de nombre
	dex_namebar.add_child(IC.rect("ball", 36))
	var nm := _label(("#%03d  %s" % [dx, L.t(String(p["name"]))]) if owned else "#%03d  ???" % dx, 26, C_GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	dex_namebar.add_child(nm)
	if owned:
		dex_namebar.add_child(IC.rect("star" if dx == int(SV.d["selected"]) else "starDim", 30))
		dex_name_heart = _heart_btn(dx, 26.0)
		dex_hearts[-dx] = dex_name_heart
		dex_namebar.add_child(dex_name_heart)
	if not owned:
		var nl := _label(L.t("Aún no lo tienes. Consíguelo en el Gacha (región %d · %s).") % [int(p["gen"]), L.t(SV.REGIONS[int(p["gen"]) - 1])], 20, Color("#c8d6ee"))
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dex_detail.add_child(nl)
		_dex_mark()
		return
	# estadisticas reales con barras (relativas al maximo del catalogo)
	if dex_stat_max.is_empty():
		dex_stat_max = {"hp": 1.0, "spd": 1.0, "atk": 1.0}
		for q in SV.dex_list:
			dex_stat_max["hp"] = maxf(dex_stat_max["hp"], float(q["hp"]))
			dex_stat_max["spd"] = maxf(dex_stat_max["spd"], float(q["spd"]))
			dex_stat_max["atk"] = maxf(dex_stat_max["atk"], float(q["atk"]))
	var sp := _dpanel()
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sp.add_child(sv)
	dex_detail.add_child(sp)
	sv.add_child(_stat_bar(L.t("PS"), str(int(p["hp"])), float(p["hp"]) / float(dex_stat_max["hp"]), Color("#ff6b7a"), "heart"))
	sv.add_child(_stat_bar(L.t("Velocidad"), str(int(p["spd"])), float(p["spd"]) / float(dex_stat_max["spd"]), Color("#6bd66b"), "boot"))
	sv.add_child(_stat_bar(L.t("Ataque"), "x%.2f" % float(p["atk"]), float(p["atk"]) / float(dex_stat_max["atk"]), Color("#ffb86b"), "fist"))
	# habilidad
	var abd: Dictionary = AB.FX[AB.of(dx)]
	var ap := _dpanel()
	var av := VBoxContainer.new()
	ap.add_child(av)
	dex_detail.add_child(ap)
	av.add_child(_icon_label("type:" + String(p["types"][0]), L.t("Habilidad: %s") % L.t(String(abd["name"])), 22, Color("#ffd98a"), 30.0))
	var ad := _label(L.t(String(abd["desc"])), 16, Color("#dbe6ff"))
	ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av.add_child(ad)
	# movimiento inicial
	var mv: String = SV.start_move_of(dx)
	var mp := _dpanel()
	var mvv := VBoxContainer.new()
	mp.add_child(mvv)
	dex_detail.add_child(mp)
	mvv.add_child(_label(L.t("Movimiento inicial"), 18, Color("#ffd98a")))
	mvv.add_child(_icon_label("move:" + mv, L.t(String(MD.MOVES[mv]["name"])), 24, Color.WHITE, 40.0))
	# movimiento Z
	var zl: Array = SV.zm_types(dx)
	if zl.is_empty():
		var zt := _label(L.t("Movimiento Z: bloqueado (derrota %d Pokémon de su tipo)") % ZM.NEED, 15, Color("#8a96b0"))
		zt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dex_detail.add_child(zt)
	else:
		var zcur: String = SV.zm_type_for(dx)
		dex_detail.add_child(_icon_label("zc:" + zcur, L.t("Movimiento Z: %s") % L.t(String(ZM.DEF[zcur]["name"])), 18, Color("#ffb86b"), 32.0))
		if zl.size() > 1:
			dex_detail.add_child(_btn(L.t("Cambiar movimiento Z"), func():
				var nx: String = String(zl[(zl.find(zcur) + 1) % zl.size()])
				SV.d["pz"][str(dx)] = nx
				SV.save()
				_dex_detail(), Vector2(0, 46)))
	var bl: Array = SV.bind_list(dx)
	var any_b := false
	for bm in bl:
		if String(bm) != "" and MD.MOVES.has(String(bm)):
			if not any_b:
				any_b = true
				dex_detail.add_child(_label(L.t("Movimientos equipados"), 16, Color("#ffd98a")))
			dex_detail.add_child(_icon_label("move:" + String(bm), L.t(String(MD.MOVES[String(bm)]["name"])), 16, Color("#c8d6ee"), 28.0))
	# rareza y cantidad
	var rr: int = clampi(int(p["rarity"]) - 1, 0, 4)
	var rrow := HBoxContainer.new()
	rrow.add_child(IC.rect("shiny" if rr == 4 else "star", 22))
	var rl := _label(L.t("Rareza: %s") % L.t(SV.RARITY_NAME[rr]), 18, Color.html(RAR_COL[rr]))
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rrow.add_child(rl)
	rrow.add_child(_label(L.t("Tenido: x%d") % int(SV.d["owned"][str(dx)]["n"]), 18, Color("#e6eeff")))
	dex_detail.add_child(rrow)
	if shiny_owned:
		var cb := CheckButton.new()
		cb.text = "Usar versión shiny ✨"
		cb.button_pressed = bool(SV.d["shiny_on"])
		cb.toggled.connect(func(on: bool): SV.d["shiny_on"] = on; SV.save(); _refresh_dex())
		dex_detail.add_child(cb)
	# boton Elegir (fijo abajo)
	if not (dex_pick_party or dex_pick_team or dex_pick_coop):
		var sel_b: Button
		if dx == int(SV.d["selected"]):
			sel_b = _btn("✔ Es tu compañero", func(): pass, Vector2(0, 54))
			sel_b.disabled = true
		else:
			sel_b = _btn("Elegir", func(): SV.d["selected"] = dx; SV.save(); toast(L.t("Compañero: %s") % _name_of(dx)); _refresh_dex(), Vector2(0, 54))
		sel_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sel_b.add_theme_font_size_override("font_size", 24)
		dex_foot.add_child(sel_b)
	_dex_mark()


# ---------------------------------------------------------------
# Mejoras permanentes
# ---------------------------------------------------------------
func _build_up() -> void:
	var s: Control = _screen("up")
	var ins: Vector4 = DSP.insets(get_tree())
	s.add_theme_constant_override("margin_left", 10 + int(ins.x))
	s.add_theme_constant_override("margin_right", 10 + int(ins.z))
	s.add_theme_constant_override("margin_top", 66 + int(ins.y))
	s.add_theme_constant_override("margin_bottom", 10 + int(ins.w))
	var pc := PanelContainer.new()
	pc.theme = _set_theme()
	var fr := _sb(Color("#17307f"), SET_LINE, 4, 20)
	fr.content_margin_left = 14
	fr.content_margin_right = 12
	fr.content_margin_top = 8
	fr.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", fr)
	s.add_child(pc)
	pc.add_child(SetArt.new())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var rib := PanelContainer.new()
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var rs := _sb(Color("#2a56c4"), Color("#b5cdfb"), 3, 8)
	rs.corner_radius_top_left = 20
	rs.corner_radius_bottom_right = 26
	rs.content_margin_top = 2
	rs.content_margin_bottom = 2
	rs.content_margin_left = 10
	rs.content_margin_right = 44
	rib.add_theme_stylebox_override("panel", rs)
	v.add_child(rib)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	rib.add_child(rh)
	rh.add_child(IC.rect("ball", 38))
	var tt := _label("Mejoras permanentes", 30)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rh.add_child(tt)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var um := MarginContainer.new()
	um.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	um.add_theme_constant_override("margin_right", 24)   # la barra de desplazamiento no tapa las tarjetas
	sc.add_child(um)
	up_box = VBoxContainer.new()
	up_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_theme_constant_override("separation", 10)
	um.add_child(up_box)
	var orn_gap := Control.new()   # hueco para la Poke Ball del adorno de abajo
	orn_gap.custom_minimum_size = Vector2(0, 34)
	orn_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(orn_gap)
	var orn := SetArt.new(true)
	orn.lift = 18.0
	pc.add_child(orn)


# Tarjeta azul oscura de la pantalla de mejoras.
func _up_card_sb() -> StyleBoxFlat:
	var sb := _sb(Color(0.05, 0.09, 0.32, 0.92), SET_LINE, 3, 14)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


const UP_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "regen": "sprout", "magnet": "magnet", "xp": "book", "coins": "coin", "moves": "cards", "crit": "star", "size": "size", "reroll": "bond", "ban": "ban", "revive": "revive", "bag": "bag", "bag3": "bag", "tm": "tm", "wslot": "cards"}


# Reconstruye la pantalla de mejoras sin perder la seleccion del mando ni el scroll.
func _refresh_up_keep(key: String) -> void:
	var sc: ScrollContainer = null
	var p: Node = up_box.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		sc = p as ScrollContainer
	var sv: int = sc.scroll_vertical if sc != null else 0
	_refresh_up()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(up_box) or cur != "up":
		return
	if sc != null:
		sc.scroll_vertical = sv
	var cand: Array = []
	for b in up_box.find_children("*", "Control", true, false):
		if b is BaseButton or b is OptionButton:
			cand.append(b)
	var target: Control = null
	var idx_key := -1
	for i in range(cand.size()):
		if String(cand[i].get_meta("fk", "")) == key:
			idx_key = i
			if not cand[i].disabled:
				target = cand[i]
			break
	if target == null and idx_key >= 0:
		# el boton quedo desactivado (maximo / sin monedas): el siguiente activo, o el anterior
		for i in range(idx_key + 1, cand.size()):
			if not cand[i].disabled:
				target = cand[i]
				break
		if target == null:
			for i in range(idx_key - 1, -1, -1):
				if not cand[i].disabled:
					target = cand[i]
					break
	if target != null:
		target.grab_focus()
		if sc != null:
			sc.scroll_vertical = sv
			sc.ensure_control_visible(target)


func _refresh_up() -> void:
	_clear(up_box)
	if not SV.owns(up_dex):
		up_dex = int(SV.d["selected"])
	var first: Button = null
	# --- cabecera: retrato animado + selector de Pokemon
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	up_box.add_child(head)
	var pfr := PanelContainer.new()
	var pfs := _sb(Color("#0f1f60"), Color("#ff9a2e"), 4, 14)
	pfs.content_margin_left = 4
	pfs.content_margin_right = 4
	pfs.content_margin_top = 4
	pfs.content_margin_bottom = 4
	pfr.add_theme_stylebox_override("panel", pfs)
	head.add_child(pfr)
	var por := Portrait.new()
	por.custom_minimum_size = Vector2(170, 136)
	pfr.add_child(por)
	var tcol := Color("#ff7b3d")
	var types: Array = SV.dex_by[up_dex]["types"]
	if not types.is_empty():
		tcol = Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#ff7b3d")))
	por.setup(up_dex, tcol, 4.5)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.add_theme_constant_override("separation", 8)
	head.add_child(hv)
	var inf := PanelContainer.new()
	var ifs := _sb(Color(0.05, 0.09, 0.32, 0.92), SET_LINE, 2, 18)
	ifs.content_margin_top = 4
	ifs.content_margin_bottom = 4
	inf.add_theme_stylebox_override("panel", ifs)
	hv.add_child(inf)
	var irow := HBoxContainer.new()
	irow.add_theme_constant_override("separation", 10)
	inf.add_child(irow)
	irow.add_child(SetGlyph.new("info", 26.0))
	var itx := _label("Cada Pokémon tiene sus propias mejoras: solo cuentan cuando juegas con él.", 18)
	itx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	irow.add_child(itx)
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 8)
	hv.add_child(orow)
	var owned: Array = _up_owned()
	var cur_i: int = maxi(owned.find(up_dex), 0)
	var prev_b := _btn("◀", func(): _up_step(-1), Vector2(64, 56))
	prev_b.set_meta("fk", "upprev")
	orow.add_child(prev_b)
	var par0: String = L.t(" (compañero)") if up_dex == int(SV.d["selected"]) else ""
	var pick_b := _btn(L.t("%s%s · %d niveles") % [_name_of(up_dex), par0, SV.up_total(up_dex)] + "  ▾", _open_up_picker, Vector2(360, 56))
	pick_b.set_meta("fk", "uppick")
	pick_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick_b.add_theme_font_size_override("font_size", 22)
	orow.add_child(pick_b)
	var next_b := _btn("▶", func(): _up_step(1), Vector2(64, 56))
	next_b.set_meta("fk", "upnext")
	orow.add_child(next_b)
	if owned.size() < 2:
		prev_b.disabled = true
		next_b.disabled = true
	if up_dex != int(SV.d["selected"]):
		var pb := _btn("Usar de compañero", func(): SV.d["selected"] = up_dex; SV.save(); toast(L.t("Compañero: %s") % _name_of(up_dex)); _refresh_up(), Vector2(0, 56))
		orow.add_child(pb)
	# S62.3: "Mejorar todo" (solo mejoras permanentes finitas de este Pokemon; compra atomica con confirmacion)
	var all_cost := 0
	for u0 in SV.UPGRADES:
		var l0: int = SV.up_level(String(u0["id"]), up_dex)
		for q in range(l0, int(u0["max"])):
			all_cost += SV.up_cost(String(u0["id"]), q)
	if all_cost > 0:
		var ab_txt: String = L.t("Mejorar todo: %d") % all_cost
		if up_all_ok:
			ab_txt = L.t("Confirmar: %d monedas") % all_cost
		var ab := _btn(ab_txt, func(): _up_all(all_cost), Vector2(0, 52))
		ab.disabled = int(SV.d["coins"]) < all_cost
		ab.set_meta("fk", "upall")
		ab.icon = IC.tex("coin", IC.scale_for("coin", 26))
		ab.custom_minimum_size.y = 46
		ab.add_theme_color_override("font_disabled_color", Color("#dfe8ff"))
		if up_all_ok:
			_set_btn(ab, "gold")
		else:
			for st in ["normal", "disabled"]:
				ab.add_theme_stylebox_override(st, _sb(Color(0.05, 0.09, 0.32, 0.95), Color("#f6c433"), 3, 22))
			ab.add_theme_stylebox_override("hover", _sb(Color("#1c3e94"), Color("#ffe07a"), 3, 22))
			ab.add_theme_stylebox_override("pressed", _sb(Color("#142f75"), Color("#f6c433"), 3, 22))
			ab.add_theme_stylebox_override("focus", _sb(Color("#1c3e94"), Color.WHITE, 4, 22))
		for sd in [0, 1]:
			var bl := IC.rect("ball", 32)
			bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bl.set_anchors_preset(Control.PRESET_CENTER_LEFT if sd == 0 else Control.PRESET_CENTER_RIGHT)
			bl.offset_left = 8.0 if sd == 0 else -40.0
			bl.offset_right = 40.0 if sd == 0 else -8.0
			bl.offset_top = -16.0
			bl.offset_bottom = 16.0
			ab.add_child(bl)
		up_box.add_child(ab)
	# --- tarjetas de mejoras
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x >= 1150.0 else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_child(grid)
	var up_anchors: Array = []
	var up_extra: Array = []
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		var lv: int = SV.up_level(id, up_dex)
		var mx: int = int(u["max"])
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _up_card_sb())
		grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var uic := IC.rect(String(UP_ICON.get(id, "star")), 46)
		uic.custom_minimum_size.x = 52
		row.add_child(uic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_theme_constant_override("separation", 1)
		row.add_child(col)
		col.add_child(_label(String(u["name"]), 21))
		col.add_child(_label(String(u["unit"]), 15, Color("#dfe8ff")))
		var pips := Pips.new()
		pips.setup(lv, mx)
		col.add_child(pips)
		var btn: Button
		if lv >= mx:
			btn = _btn("Máximo", func(): pass, Vector2(120, 52))
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", _sb(Color("#2b3452"), Color("#4a5578"), 3, 12))
		else:
			var cost: int = SV.up_cost(id, lv)
			btn = _cost_btn("", str(cost), "", "coin", func(): _buy(id), Vector2(120, 52), int(SV.d["coins"]) >= cost, false, true)
			btn.set_meta("fk", "u:" + id)
			if first == null and not btn.disabled:
				first = btn
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		up_anchors.append(btn if not btn.disabled else null)
		up_extra.append(null)
		if id == "tm" and lv > 0:
			var tmcol := VBoxContainer.new()
			tmcol.add_theme_constant_override("separation", 6)
			tmcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var et := _btn(L.t("Elegir"), func(): tm_open = not tm_open; _refresh_up_keep("tmelegir"), Vector2(120, 44))
			et.set_meta("fk", "tmelegir")
			up_extra[up_extra.size() - 1] = et
			tmcol.add_child(et)
			tmcol.add_child(btn)
			row.add_child(tmcol)
		elif id == "ban" and lv > 0:
			var bcol := VBoxContainer.new()
			bcol.add_theme_constant_override("separation", 6)
			bcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var nb: int = mini(SV.ban_list(up_dex).size(), lv)
			var eb := _btn(L.t("Elegir (%d/%d)") % [nb, lv], func(): ban_open = not ban_open; _refresh_up_keep("elegir"), Vector2(120, 44))
			eb.set_meta("fk", "elegir")
			up_extra[up_extra.size() - 1] = eb
			bcol.add_child(eb)
			bcol.add_child(btn)
			row.add_child(bcol)
		else:
			row.add_child(btn)
	focus_first = first
	# Izquierda/derecha: cicla dentro de la fila de tarjetas (con vuelta al otro extremo).
	var ncol: int = grid.columns
	var ri := 0
	while ri < up_anchors.size():
		var rowb: Array = []
		var rowx: Array = []
		for ci in range(ncol):
			if ri + ci < up_anchors.size() and up_anchors[ri + ci] != null:
				rowb.append(up_anchors[ri + ci])
				rowx.append(up_extra[ri + ci])
		for k in range(rowb.size()):
			var nxt: Control = rowb[(k + 1) % rowb.size()]
			var prv: Control = rowb[posmod(k - 1, rowb.size())]
			for bb in [rowb[k], rowx[k]]:
				if bb == null:
					continue
				bb.focus_neighbor_right = bb.get_path_to(nxt)
				bb.focus_neighbor_left = bb.get_path_to(prv)
		ri += ncol
	if SV.up_level("tm", up_dex) > 0 and tm_open:
		up_box.add_child(_tm_panel())
	var ban_lv: int = SV.up_level("ban", up_dex)
	if ban_lv > 0 and ban_open:
		up_box.add_child(_ban_panel(ban_lv))
	up_box.add_child(_bind_panel())


# MT: elige el movimiento con el que empiezas cada partida (gratis cambiarlo cuando quieras).
func _tm_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _up_card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var cur: String = SV.start_move_of(up_dex)
	var sub := _label(L.t("Elige el movimiento con el que empiezas cada partida. Puedes cambiarlo gratis cuando quieras."), 18, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.tm_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = String(id) == cur
		var b := _btn(("✔ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			SV.tm_set(up_dex, String(id))
			Aud.sfx("select")
			_refresh_up_keep("tm:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "tm:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a5a14"), Color("#ffd23f"), 3, 10))
		fl.add_child(b)
	return pc


# Veto: toca los movimientos que no quieres que te salgan en las cartas de este Pokemon.
func _ban_panel(max_n: int) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _up_card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var l := SV.ban_list(up_dex)
	var sub := _label(L.t("Toca los movimientos que no quieres que te salgan en las cartas (%d/%d). El movimiento de inicio no se puede vetar.") % [l.size(), max_n], 18, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.move_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = l.has(id)
		var b := _btn(("✕ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			if SV.ban_toggle(up_dex, String(id), max_n):
				Aud.sfx("select")
			else:
				Aud.sfx("error")
				toast(L.t("Ya tienes %d vetados: quita uno primero") % max_n)
			_refresh_up_keep("b:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "b:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a2438"), Color("#ff6b7a"), 3, 10))
		fl.add_child(b)
	return pc


# Atajos: que movimiento va siempre en cada hueco (teclas 1-4 o iconos de abajo).
func _bind_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _up_card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label("Atajos de movimientos", 22))
	var sub := _label("Elige qué movimiento va siempre en cada hueco (teclas 1-4 o los iconos de abajo), para la memoria muscular. Si aún no tienes tantos movimientos, va al hueco más cercano.", 17, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var ids: Array = SV.move_pool(up_dex)
	ids.append(SV.start_move_of(up_dex))
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	var cur: Array = SV.bind_list(up_dex)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for i in range(4):
		var num := _label(str(i + 1), 22, C_GOLD)
		row.add_child(num)
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(150, 46)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.focus_mode = Control.FOCUS_ALL
		ob.add_item(L.t("Libre"), 0)
		var sel := 0
		for k in range(ids.size()):
			ob.add_item(L.t(String(MD.MOVES[ids[k]]["name"])), k + 1)
			if String(cur[i]) == String(ids[k]):
				sel = k + 1
		ob.select(sel)
		var slot: int = i
		ob.item_selected.connect(func(idx: int):
			var pick: String = "" if idx == 0 else String(ids[idx - 1])
			SV.bind_set(up_dex, slot, pick)
			Aud.sfx("select")
			_refresh_up_keep("bind%d" % slot))
		ob.set_meta("fk", "bind%d" % slot)
		row.add_child(ob)
	return pc


func _up_owned() -> Array:
	var owned: Array = []
	for k in SV.d["owned"].keys():
		owned.append(int(k))
	owned.sort()
	return owned


func _up_step(d: int) -> void:
	var owned: Array = _up_owned()
	if owned.is_empty():
		return
	var i: int = posmod(maxi(owned.find(up_dex), 0) + d, owned.size())
	up_dex = int(owned[i])
	Aud.sfx("select")
	_refresh_up_keep("uppick")


func _kb_hide() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f is LineEdit or f is TextEdit:
		f.release_focus()
	DisplayServer.virtual_keyboard_hide()


# Boton de cerrar/cancelar para pantalla tactil: antes baja el teclado virtual, que si no se "come" el primer toque.
func _btn_close(t: String, cb: Callable, sz: Vector2) -> Button:
	var b := _btn(t, func():
		_kb_hide()
		cb.call(), sz)
	return b


func _close_up_picker() -> void:
	if up_picker != null and is_instance_valid(up_picker):
		up_picker.queue_free()
	up_picker = null


# Selector grande y tactil (la lista desplegable normal es dificil de usar en el movil).
func _open_up_picker() -> void:
	pk_gen = 0
	pk_type = ""
	pk_q = ""
	pk_focus = ""
	_build_up_picker()


func _pk_filter_row(parent: Control, items: Array, cur_val, on_pick: Callable, prefix: String) -> void:
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 58)
	sc.get_h_scroll_bar().custom_minimum_size.y = 12
	parent.add_child(sc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	sc.add_child(hb)
	for it in items:
		var key: String = prefix + str(it["v"])
		var b := _btn(String(it["t"]), func():
			pk_focus = key
			on_pick.call(it["v"]), Vector2(0, 44))
		b.add_theme_font_size_override("font_size", 16)
		if it["v"] == cur_val:
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		if it.has("c"):
			b.add_theme_color_override("font_color", Color.html(String(it["c"])))
		hb.add_child(b)
		if key == pk_focus:
			b.call_deferred("grab_focus")


func _build_up_picker() -> void:
	_close_up_picker()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 50
	add_child(root)
	up_picker = root
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.98), Color(0.5, 0.62, 0.9, 0.8), 3, 14))
	pan.anchor_left = 0.06
	pan.anchor_right = 0.94
	pan.anchor_top = 0.05
	pan.anchor_bottom = 0.95
	pan.offset_left = 0
	pan.offset_right = 0
	pan.offset_top = 0
	pan.offset_bottom = 0
	root.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var tl := _label("Elegir Pokémon", 26, C_GOLD)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	top.add_child(_btn_close("Cerrar", _close_up_picker, Vector2(150, 56)))
	var search := LineEdit.new()
	search.text = pk_q
	search.placeholder_text = L.t("Buscar Pokémon por nombre…")
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(0, 52)
	search.add_theme_font_size_override("font_size", 24)
	v.add_child(search)
	var gens: Array = [{"v": 0, "t": L.t("Todas")}]
	for gi in range(SV.REGIONS.size()):
		gens.append({"v": gi + 1, "t": "%d · %s" % [gi + 1, L.t(SV.REGIONS[gi])]})
	_pk_filter_row(v, gens, pk_gen, func(x): pk_gen = int(x); _build_up_picker(), "g")
	var tys: Array = [{"v": "", "t": L.t("Todas")}]
	for tk in MD.TYPE_NAME.keys():
		tys.append({"v": String(tk), "t": L.t(String(MD.TYPE_NAME[tk])), "c": String(MD.TYPE_COLOR.get(tk, "#ffffff"))})
	_pk_filter_row(v, tys, pk_type, func(x): pk_type = String(x); _build_up_picker(), "t")
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = 30
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x >= 1150.0 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var focus_b: Button = null
	var shown := 0
	for dx in _up_owned():
		var d: int = int(dx)
		var info: Dictionary = SV.dex_by[d]
		if pk_gen != 0 and int(info["gen"]) != pk_gen:
			continue
		if pk_type != "" and not Array(info["types"]).has(pk_type):
			continue
		shown += 1
		var par: String = L.t(" (compañero)") if d == int(SV.d["selected"]) else ""
		var mark: String = "✔ " if d == up_dex else ""
		var b := _btn(mark + L.t("%s%s · %d niveles") % [_name_of(d), par, SV.up_total(d)], func():
			up_dex = d
			_close_up_picker()
			Aud.sfx("select")
			_refresh_up_keep("uppick"), Vector2(0, 76))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tx: Texture2D = _icon_tex(d, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("q", (_name_of(d) + " " + String(info["name"]) + " " + str(d)).to_lower())
		grid.add_child(b)
		if d == up_dex and pk_focus == "":
			focus_b = b
	var none_l := _label("Ninguno coincide con el filtro.", 20, Color("#c8d6ee"))
	none_l.visible = shown == 0
	grid.add_child(none_l)
	var apply_q := func(t: String):
		pk_q = t
		var q: String = t.strip_edges().to_lower()
		var vis := 0
		for ch in grid.get_children():
			if ch == none_l:
				continue
			var ok: bool = q == "" or String(ch.get_meta("q", "")).contains(q)
			ch.visible = ok
			if ok:
				vis += 1
		none_l.visible = vis == 0
	search.text_changed.connect(apply_q)
	if pk_q != "":
		apply_q.call(pk_q)
	if focus_b != null and pk_q == "":
		await get_tree().process_frame
		if is_instance_valid(focus_b):
			focus_b.grab_focus()
			sc.ensure_control_visible(focus_b)


var up_all_ok := false


func _up_all(total: int) -> void:
	if int(SV.d["coins"]) < total:
		Aud.sfx("error")
		return
	if not up_all_ok:
		up_all_ok = true
		_refresh_up_keep("upall")
		return
	up_all_ok = false
	# compra atomica: con el total comprobado, cada compra individual es valida
	var ok := true
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		while SV.up_level(id, up_dex) < int(u["max"]) and ok:
			ok = SV.buy_upgrade(id, up_dex)
	Aud.sfx("buy" if ok else "error")
	toast(L.t("¡Mejoras compradas!") if ok else L.t("No se pudo completar la compra."))
	_update_top()
	_refresh_up_keep("upall")


func _buy(id: String) -> void:
	if SV.buy_upgrade(id, up_dex):
		Aud.sfx("buy")
		toast("¡Mejora comprada!")
	else:
		Aud.sfx("error")
	_update_top()
	_refresh_up_keep("u:" + id)


# ---------------------------------------------------------------
# Gacha
# ---------------------------------------------------------------
func _build_gacha() -> void:
	var s: Control = _screen("gacha")
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.add_child(sc)
	gacha_box = VBoxContainer.new()
	gacha_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_box.add_theme_constant_override("separation", 12)
	sc.add_child(gacha_box)
	gacha_result = ColorRect.new()
	gacha_result.color = Color(0, 0, 0, 0.7)
	gacha_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.z_index = 30
	gacha_result.visible = false
	add_child(gacha_result)


# ---------------------------------------------------------------------------
# Maquina Gachapon: una Gachapon Coin = 1 movimiento nuevo; la dorada = 2.
func _build_gachapon() -> void:
	var s: Control = _screen("gachapon")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	s.add_child(row)
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 1.0
	row.add_child(lp)
	gp_machine = GP.Machine.new()
	gp_machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_machine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gp_machine.sfx_cb = func(n: String): Aud.sfx(n)
	gp_machine.finished.connect(_gp_finished)
	lp.add_child(gp_machine)
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.size_flags_stretch_ratio = 1.25
	row.add_child(rp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(sc)
	gp_info = VBoxContainer.new()
	gp_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_info.add_theme_constant_override("separation", 10)
	sc.add_child(gp_info)


var gp_pending: Array = []


func _refresh_gachapon() -> void:
	_clear(gp_info)
	gacha_result.visible = false
	var hd := _label("Máquina TM Gachapon", 36, C_GOLD)
	hd.autowrap_mode = TextServer.AUTOWRAP_OFF
	gp_info.add_child(hd)
	gp_info.add_child(_label("Inserta una Gachapon Coin y gira la palanca: te sale una cápsula con un movimiento nuevo. La moneda dorada da 2 movimientos.", 21, Color("#c8d6ee")))
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 22)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 34.0))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 34.0))
	gp_info.add_child(bal)
	var bb := HFlowContainer.new()
	bb.add_theme_constant_override("h_separation", 10)
	bb.add_theme_constant_override("v_separation", 10)
	gp_info.add_child(bb)
	gp_btn1 = _btn("Usar Gachapon Coin  (1 movimiento)", func(): _gp_insert(false), Vector2(0, 54))
	gp_btn1.icon = IC.tex("gcoin", IC.scale_for("gcoin", 28))
	gp_btn1.add_theme_font_size_override("font_size", 22)
	bb.add_child(gp_btn1)
	gp_btn2 = _btn("Usar Gachapon Coin dorada  (2 movimientos)", func(): _gp_insert(true), Vector2(0, 54))
	gp_btn2.icon = IC.tex("gcoin_gold", IC.scale_for("gcoin_gold", 28))
	gp_btn2.add_theme_font_size_override("font_size", 22)
	bb.add_child(gp_btn2)
	gp_btn1.disabled = int(SV.d.get("gcoins", 0)) <= 0
	gp_btn2.disabled = int(SV.d.get("gold_coins", 0)) <= 0
	gp_msg = _label("", 20, Color("#ff9a8a"))
	gp_info.add_child(gp_msg)
	if gp_btn1.disabled and gp_btn2.disabled:
		gp_msg.text = L.t("No tienes monedas. Consigue Gachapon Coins superando retos.")
	elif GP.locked_ids().is_empty():
		gp_msg.text = L.t("¡Ya desbloqueaste todos los movimientos de la máquina!")
	var tot: int = GP.DATA.MOVES.size()
	gp_info.add_child(_label(L.t("Movimientos desbloqueados: %d / %d") % [GP.unlocked().size(), tot], 24, C_GOLD))
	gp_collection = HFlowContainer.new()
	gp_collection.add_theme_constant_override("h_separation", 8)
	gp_collection.add_theme_constant_override("v_separation", 8)
	gp_info.add_child(gp_collection)
	for m in GP.DATA.MOVES:
		var d = GP.Disc.new(GP.type_color(String(m["type"])), 46.0)
		d.locked = not GP.is_unlocked(String(m["id"]))
		d.tooltip_text = "" if d.locked else String(m["name"])
		gp_collection.add_child(d)
	gp_focus = gp_btn1 if not gp_btn1.disabled else (gp_btn2 if not gp_btn2.disabled else null)
	focus_first = gp_focus


func _gp_insert(gold: bool) -> void:
	if gp_machine.busy():
		return
	var got: Array = GP.spend(gold)
	if got.is_empty():
		gp_msg.text = L.t("No se pudo usar la moneda.")
		return
	gp_pending = got
	var cols: Array = []
	for id in got:
		cols.append(GP.type_color(String(GP.def_of(String(id))["type"])))
	gp_btn1.disabled = true
	gp_btn2.disabled = true
	gp_machine.play(gold, cols)
	_update_top()


func _gp_finished() -> void:
	var rows: Array = gp_pending
	gp_pending = []
	_clear(gacha_result)
	gacha_result.visible = true
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(620, 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pc.add_child(v)
	var tt := _label("¡Movimiento desbloqueado!" if rows.size() == 1 else "¡Movimientos desbloqueados!", 34, C_GOLD)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tt)
	for id in rows:
		var m: Dictionary = GP.def_of(String(id))
		var col: Color = GP.type_color(String(m["type"]))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 16)
		v.add_child(hb)
		hb.add_child(GP.Disc.new(col, 84.0))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		vb.add_child(_label(String(m["name"]), 28, col.lightened(0.25)))
		vb.add_child(_label(L.t("Tipo: %s") % L.t(String(MD.TYPE_NAME[String(m["type"])])), 20, Color("#c8d6ee")))
		vb.add_child(_label(String(m["desc"]), 20))
	var ok := _btn_close("Aceptar", func():
		gacha_result.visible = false
		_refresh_gachapon()
		_gf(gp_focus if gp_focus != null else back_btn), Vector2(220, 54))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	_gf(ok)


# Por region: 2 legendarios a los lados, uno popular en el centro, y colores del escenario.
const BANNERS := [
	{"legs": [150, 151], "star": 6, "c1": "#5b2f8f", "c2": "#1f6f7a"},
	{"legs": [249, 250], "star": 157, "c1": "#b07a1c", "c2": "#27428c"},
	{"legs": [383, 382], "star": 257, "c1": "#9a2f2f", "c2": "#1a4f9a"},
	{"legs": [483, 484], "star": 448, "c1": "#3b2f9a", "c2": "#9a2f78"},
	{"legs": [643, 644], "star": 571, "c1": "#2b2f3b", "c2": "#5f6fa0"},
	{"legs": [716, 717], "star": 658, "c1": "#2f62a8", "c2": "#a8304f"},
	{"legs": [791, 792], "star": 778, "c1": "#c76a2a", "c2": "#2a8f93"},
	{"legs": [888, 889], "star": 815, "c1": "#8f2f8f", "c2": "#2f6fcf"},
	{"legs": [1007, 1005], "star": 908, "c1": "#c0581a", "c2": "#5a2fa0"},
]
const RARITY_COL := ["#c8d6ee", "#5fe08a", "#5fa8ff", "#c47bff", "#ffd33d"]
const RARITY_BALL := ["ball", "ball2", "ball3", "ball4", "ballLux"]


func _region_counts(region: int) -> Vector2i:
	var pool: Array = SV.region_pool(region)
	var n := 0
	for p in pool:
		if SV.owns(int(p["dex"])):
			n += 1
	return Vector2i(n, pool.size())


func _refresh_gacha() -> void:
	_clear(gacha_box)
	var first: Button = null
	# --- pestanas de region
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	gacha_box.add_child(tabs)
	tab_row = tabs
	for i in range(1, 10):
		var r: int = i
		var tb := _btn(L.t(SV.REGIONS[r - 1]) + "\n" + L.t("Gen %d") % r, func(): gacha_region = r; _refresh_gacha(); _gf(tab_sel), Vector2(112, 62))
		tb.add_theme_font_size_override("font_size", 20)
		if r == gacha_region:
			tb.add_theme_stylebox_override("normal", _sb(Color("#2a4aa8"), C_GOLD, 3, 12))
			tb.add_theme_color_override("font_color", C_GOLD)
			first = tb
			tab_sel = tb
		tabs.add_child(tb)
	# --- escenario + probabilidades
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	gacha_box.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	main.add_child(left)
	var bd: Dictionary = BANNERS[gacha_region - 1]
	var banner := Banner.new()
	banner.c1 = Color.html(String(bd["c1"]))
	banner.c2 = Color.html(String(bd["c2"]))
	banner.custom_minimum_size = Vector2(0, 360)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(banner)
	var cnt: Vector2i = _region_counts(gacha_region)
	var tx := VBoxContainer.new()
	tx.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tx.offset_left = 22
	tx.offset_top = 16
	tx.offset_right = -22
	tx.add_theme_constant_override("separation", 6)
	banner.add_child(tx)
	var ttl := _label(L.t("Misterio de %s") % L.t(SV.REGIONS[gacha_region - 1]), 44, C_GOLD)
	ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tx.add_child(ttl)
	tx.add_child(_label(L.t("Los %d Pokémon de la generación %d. ¡Los legendarios te esperan!") % [cnt.y, gacha_region], 22))
	tx.add_child(_label(L.t("Tienes %d de %d") % [cnt.x, cnt.y], 20, Color("#cfd9f5")))
	banner.add_mon(int(bd["legs"][0]), 3.2, 0.0, 0.36)
	banner.add_mon(int(bd["star"]), 3.2, 0.34, 0.66)
	banner.add_mon(int(bd["legs"][1]), 3.2, 0.64, 1.0)
	# --- botones de tirada
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	left.add_child(brow)
	var b1 := _cost_btn(L.t("Tirada ×1"), "1", "", "ticket", func(): _do_pull(1, "t1"), Vector2(0, 64), SV.can_pull(1, "t1"), false, true)
	var b10 := _cost_btn(L.t("Tirada ×10"), "10", "", "ticket", func(): _do_pull(10, "t1"), Vector2(0, 64), SV.can_pull(10, "t1"), false, true)
	var bt := _cost_btn(L.t("Tirada ×10"), "1", "", "ticket10", func(): _do_pull(10, "t10"), Vector2(0, 64), SV.can_pull(10, "t10"), false, true)
	for b in [b1, b10, bt]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(b)
	var have := HBoxContainer.new()
	have.add_theme_constant_override("separation", 8)
	_nw(have, _label(L.t("Tienes"), 20, Color("#c8d6ee")))
	have.add_child(IC.rect("ticket", 24))
	_nw(have, _label(str(int(SV.d["tickets"])), 22, Color("#ffd23f")))
	_nw(have, _label(L.t("tickets y"), 20, Color("#c8d6ee")))
	have.add_child(IC.rect("ticket10", 24))
	_nw(have, _label(str(int(SV.d.get("tickets10", 0))), 22, Color("#c47bff")))
	_nw(have, _label(L.t("tickets ×10"), 20, Color("#c8d6ee")))
	left.add_child(have)
	var pity: int = int(SV.d["pity"].get(str(gacha_region), 0))
	left.add_child(_label(L.t("Tiradas sin legendario en %s: %d / %d") % [L.t(SV.REGIONS[gacha_region - 1]), pity, SV.PITY_5], 18, Color("#c8d6ee")))
	if first == null:
		first = b1
	# --- panel de probabilidades
	var pool: Array = SV.region_pool(gacha_region)
	var counts: Array = [0, 0, 0, 0, 0]
	for p in pool:
		counts[clampi(int(p["rarity"]) - 1, 0, 4)] += 1
	var op := PanelContainer.new()
	op.custom_minimum_size = Vector2(330, 0)
	op.add_theme_stylebox_override("panel", _card_sb())
	main.add_child(op)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 5)
	op.add_child(ov)
	ov.add_child(_label("Probabilidades", 26))
	for j in range(4, -1, -1):
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 8)
		rr.add_child(IC.rect(String(RARITY_BALL[j]), 24))
		var rn := _label(SV.RARITY_NAME[j], 20, Color.html(String(RARITY_COL[j])))
		rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rn.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(rn)
		var pc := _label("%s%% · %d" % [str(SV.PULL_RATES[j]), int(counts[j])], 20, Color("#dfe8ff"))
		pc.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(pc)
		ov.add_child(rr)
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 8)
	sr.add_child(IC.rect("shiny", 24))
	var sn := _label("Shiny", 20)
	sn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(sn)
	var s32 := _label("%d%%" % roundi(SV.shiny_rate(gacha_region) * 100.0), 20, Color("#dfe8ff"))
	s32.autowrap_mode = TextServer.AUTOWRAP_OFF
	sr.add_child(s32)
	ov.add_child(sr)
	# Cristales Z: probabilidad y cuales ya tienes (los desbloqueados brillan, el resto se ve apagado)
	var zr := HBoxContainer.new()
	zr.add_theme_constant_override("separation", 8)
	zr.add_child(IC.rect("zc:" + String(ZM.ORDER[0]), 24))
	var zn := _label("Cristal Z", 20, Color("#7fe0ff"))
	zn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zn.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zn)
	var zp := _label("%d%% · ×10" % roundi(SV.Z_CRYSTAL_P * 100.0), 20, Color("#dfe8ff"))
	zp.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zp)
	ov.add_child(zr)
	var zg := GridContainer.new()
	zg.columns = 9
	zg.add_theme_constant_override("h_separation", 2)
	zg.add_theme_constant_override("v_separation", 2)
	for zt in ZM.ORDER:
		var zi = IC.rect("zc:" + String(zt), 32)
		if not ZM.unlocked(String(zt), SV.d["stats"]):
			zi.modulate = Color(0.35, 0.35, 0.4, 0.45)
		zg.add_child(zi)
	ov.add_child(zg)
	ov.add_child(_label(L.t("· La tirada ×10 garantiza al menos un Pokémon muy raro."), 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· Ticket ×10 morado: la última tirada tiene un %d%% de ser legendaria (si no, Muy raro o mejor) y el cristal Z sube al %d%%.") % [roundi(SV.PURPLE_LEGEND_P * 100.0), roundi(SV.Z_CRYSTAL_P_PURPLE * 100.0)], 16, Color("#d9a8ff")))
	ov.add_child(_label(L.t("· A las %d tiradas sin legendario en un banner, la siguiente lo es.") % SV.PITY_5, 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· Los repetidos dan Pokémonedas. Los shiny no se repiten."), 16, Color("#c8d6ee")))
	if SV.banner_done(gacha_region):
		ov.add_child(_label(L.t("· ¡Banner completado! Shiny al %d%% en lugar del %d%%.") % [roundi(SV.SHINY_PULL_DONE * 100.0), roundi(SV.SHINY_PULL * 100.0)], 16, C_GOLD))
	else:
		ov.add_child(_label(L.t("· Cuanto más completes el banner, más salen los Pokémon que te faltan: ahora %d%% por tirada.") % roundi(SV.missing_chance(gacha_region) * 100.0), 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· Los tickets se consiguen jugando: algunos Pokémon los sueltan al caer, y los jefes y los cofres a veces dan tickets ×10."), 16, Color("#c8d6ee")))
	focus_first = first


func _nw(parent: Node, l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(l)


func _do_pull(n: int, use: String) -> void:
	if not SV.can_pull(n, use):
		toast(L.t("No tienes tickets suficientes: consíguelos jugando"))
		return
	var results: Array = SV.pull(gacha_region, n, use)
	SV.save()
	_update_top()
	_play_slots(results)


# Tragaperras animada (como el original); al terminar muestra la lista de premios.
func _play_slots(results: Array) -> void:
	if slots_ui == null or not is_instance_valid(slots_ui):
		slots_ui = SLOTS.new()
		slots_ui.z_index = 31
		slots_ui.visible = false
		add_child(slots_ui)
	slots_busy = true
	slots_ui.play(results)
	await slots_ui.finished
	slots_busy = false
	slots_ui.visible = false
	var best := 1
	var anyshiny := false
	for r in results:
		best = maxi(best, clampi(int(r.get("rarity", 1)), 1, 5))
		anyshiny = anyshiny or bool(r["shiny"])
	Aud.sfx("burst%d" % best)
	if anyshiny:
		Aud.sfx("shinyGet")
	_show_pulls(results)


func _show_pulls(results: Array) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("¡Resultado!", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 5 if results.size() > 1 else 1
	v.add_child(grid)
	for r in results:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(150, 0)
		grid.add_child(cell)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(150, 110)
		cell.add_child(pv)
		pv.setup(int(r["dex"]), bool(r["shiny"]), 3.0)
		var nm := _label(L.t(String(r["name"])) + (" ✨" if bool(r["shiny"]) else ""), 18)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(nm)
		if bool(r["new"]) or int(r["refund"]) <= 0:
			var tag := "¡NUEVO!" if bool(r["new"]) else "Shiny"
			var tl := _label(tag, 16, Color("#5fe08a") if bool(r["new"]) else Color("#ffd23f"))
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(tl)
		else:
			var rf := _icon_label("coin", "+%d" % int(r["refund"]), 16, Color("#ffd23f"), 24.0)
			rf.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(rf)
		var rar: int = clampi(int(r["rarity"]), 1, 5)
		var rl := _icon_label(String(["ball", "ball2", "ball3", "ball4", "ballLux"][rar - 1]), SV.RARITY_NAME[rar - 1], 14, Color("#9fb4f0"), 24.0)
		rl.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(rl)
	if SV.last_crystal != "":
		var zc: String = SV.last_crystal
		var zrow := _icon_label("zc:" + zc, L.t("¡Cristal Z encontrado! Desbloqueas: %s") % L.t(String(ZM.DEF[zc]["name"])), 20, Color("#ffd23f"), 40.0)
		zrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(zrow)
		Aud.sfx("legend")
	var ok := _btn_close("Aceptar", func(): gacha_result.visible = false; _refresh_gacha(), Vector2(0, 54))
	v.add_child(ok)
	gacha_result.visible = true
	_gf(ok)


# ---------------------------------------------------------------
# Misiones, logros y titulos (progress.gd)
# ---------------------------------------------------------------
var ach_cat := "coleccion"
var goals_btn: Button
var goals_tabs: HBoxContainer


var prof_box: VBoxContainer


func _build_profile() -> void:
	var s: Control = _screen("profile")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	prof_box = VBoxContainer.new()
	prof_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof_box.add_theme_constant_override("separation", 8)
	sc.add_child(prof_box)


func _refresh_profile() -> void:
	PG.ensure()
	_clear(prof_box)
	call_deferred("_touch_pass", prof_box)
	var first: Button = _goals_profile()
	tab_row = null
	focus_first = first
	_update_top()


func _build_goals() -> void:
	var s: Control = _screen("goals")
	var ins: Vector4 = DSP.insets(get_tree())
	s.add_theme_constant_override("margin_left", 10 + int(ins.x))
	s.add_theme_constant_override("margin_right", 10 + int(ins.z))
	s.add_theme_constant_override("margin_top", 66 + int(ins.y))
	s.add_theme_constant_override("margin_bottom", 10 + int(ins.w))
	var pc := PanelContainer.new()
	pc.theme = _set_theme()
	var fr := _sb(Color("#17307f"), SET_LINE, 4, 20)
	fr.content_margin_left = 14
	fr.content_margin_right = 12
	fr.content_margin_top = 10
	fr.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", fr)
	s.add_child(pc)
	pc.add_child(SetArt.new())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	goals_tabs = HBoxContainer.new()
	goals_tabs.add_theme_constant_override("separation", 10)
	v.add_child(goals_tabs)
	for t in [["m", "Misiones", "m_daily"], ["a", "Logros", "medal1"], ["h", "Medallas", "star"], ["z", "Cristales Z", "zc:ice"], ["p", "Perfil", "star"], ["r", "Récords", "trophy"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): goals_tab = k; _refresh_goals(); _gf(tab_sel), Vector2(0, 52))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.icon = IC.btn_tex(String(t[2]), 30)
		tb.expand_icon = false
		tb.add_theme_font_size_override("font_size", 22)
		var ptr := SetGlyph.new("pointer", 1.0)
		ptr.anchor_left = 0.5
		ptr.anchor_right = 0.5
		ptr.anchor_top = 1.0
		ptr.anchor_bottom = 1.0
		ptr.visible = false
		tb.add_child(ptr)
		if k == "p":
			tb.visible = false
		goals_tabs.add_child(tb)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var gm := MarginContainer.new()
	gm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gm.add_theme_constant_override("margin_right", 24)   # la barra de desplazamiento no tapa las filas
	sc.add_child(gm)
	goals_box = VBoxContainer.new()
	goals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_theme_constant_override("separation", 8)
	gm.add_child(goals_box)
	var orn_gap := Control.new()   # hueco para la Poke Ball del adorno de abajo
	orn_gap.custom_minimum_size = Vector2(0, 34)
	orn_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(orn_gap)
	var orn := SetArt.new(true)
	orn.lift = 18.0
	pc.add_child(orn)


# Titulo de seccion de Misiones y logros: cinta con Poke Ball y franjas.
func _goal_sec(title: String, sz: int = 26) -> void:
	var rib := PanelContainer.new()
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rib.add_theme_stylebox_override("panel", _ribbon_sb(Color("#2a56c4"), Color("#b5cdfb"), 14))
	goals_box.add_child(rib)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	rib.add_child(h)
	h.add_child(IC.rect("ball", 34))
	var l := _label(title, sz)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	h.add_child(SetGlyph.new("stripes", 30.0))


# Barra de progreso con el estilo de la pantalla.
func _goal_pb(pb: ProgressBar) -> void:
	var bg := _sb(Color("#0b1a55"), SET_LINE, 2, 7)
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fill := _sb(Color("#3fd45c"), Color.TRANSPARENT, 0, 6)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fill)


# Linea de ayuda con icono de informacion.
func _goal_info(text: String) -> void:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 10)
	goals_box.add_child(r)
	r.add_child(SetGlyph.new("info", 26.0))
	var l := _label(text, 16, Color("#dfe8ff"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)


# ---------------------------------------------------------------
# Lexico: objetos, movimientos y estados alterados
# ---------------------------------------------------------------
var lex_tab := "m"
var lex_tabs: BoxContainer
var lex_box: VBoxContainer
const LEX_NEW := [
	["Altar legendario", "Un altar grande y sólido, con escaleras al frente. Sube por ellas, párate en el círculo central y espera a que la barra \"Invocando\" se llene (4 s). Si te sales, la barra se pausa y baja muy poco. Invoca a un Pokémon legendario que ataca solo con rayos de área y tiene vida visible: no se cura y los enemigos que lo tocan le hacen daño. Solo puede haber uno a la vez.", "tex:altar"],
	["Apuntado manual", "Opcional (Ajustes). Apunta tú mismo con el stick derecho del mando, el ratón o un segundo dedo arrastrando en la mitad derecha de la pantalla. Una flecha indica hacia dónde disparas. Si no apuntas, el juego apunta solo.", "tex:aim"],
	["Trampas más grandes", "Las trampas del mapa son más grandes y avisan del área real en la que actúan. Cada tipo (veneno, pegajosa, hielo, rayo, sueño, confusión y fuego) tiene su propia animación al estar armada y al estallar.", "tex:trap"],
	["Movimientos con patrón único", "Cada movimiento nuevo tiene su propio patrón de ataque, no solo otra animación: zonas, ondas, trampas, rastros, dashes, ráfagas y más. Lee la descripción de cada uno en la pestaña Movimientos.", "tex:pat"],
	["Huecos de arma", "Nueva mejora en la tienda: empiezas con 4 huecos de movimiento y puedes comprar hasta 2 más (máximo 6).", "cards"],
	["Objetos con tiempo de recarga", "Los objetos con recarga (Baya Zidra, Banda Focus, Política Débil...) aparecen en una caja en pantalla con su tiempo restante, o \"Listo\" cuando se pueden usar.", "clock"],
	["Dificultad progresiva", "A partir del minuto 20 los enemigos ganan más vida, daño y velocidad, y aparecen más élites. A los 60 min el reto es máximo.", "r_berserk"],
	["Bonus de terreno", "Si pisas un líquido de tu tipo (agua, lava, pantano, hielo, veneno o chispas), ganas un +12% de velocidad mientras estés en él.", "boot"],
	["Movimientos de vínculo", "Une dos movimientos en un solo hueco y se lanzarán a la vez; cada nuevo vínculo crea otra pareja con los movimientos que te queden libres. Si los dos están evolucionados y al nivel máximo, se fusionan en un Movimiento de Vínculo mucho más potente (una vez por partida); los originales se pierden el resto de la partida.", "bond"],
	["Enamorado", "Los movimientos de tipo Hada pueden enamorar a un enemigo durante 20 s (26 s con Pluma Hada). Un enemigo enamorado pelea de tu lado: ataca a otros enemigos y no te hace daño. Los jefes son inmunes y, al acabarse, el enemigo no puede volver a enamorarse enseguida.", "heart"],
	["Resumen de la partida", "En la pausa, el botón Resumen muestra cada movimiento con su tipo, nivel, daño total, derrotas y DPS de los últimos 20 s, además de tus mejoras y objetos.", "book"],
	["Partida Normal: Sentencia de Arceus", "La partida Normal termina a los 30 min con la Sentencia de Arceus. 00:30 pequeña oleada; 01:00 primera Grieta garantizada; 02:00 un Meowth que huye con monedas; 03:00 el primer jefe; 04:00 cambio único al siguiente mapa (cuando el jefe cae). Entre medias aparecen mini-jefes gigantes raros (Tyranitar, Wailord, Onix, Steelix y más). A los 30:00 llega ARCEUS: una arena enorme, Arceus invencible y un legendario cada 5 s con el doble de vida y daño que el anterior. Esa pelea no tiene límite de tiempo. Los demás modos no cambian.", "tex:eter"],
	["Objetos perdidos y paquetes", "Por el mapa aparecen objetos pequeños que se recogen solos al tocarlos: la Bolsa de Poké Balls (+3 Poké Balls), el Elixir (un potenciador al azar durante 25 s) y el Cristal Prisma (paraliza 2,5 s a los enemigos cercanos: una salida de emergencia). Si no te sirven en ese momento (Poké Balls al máximo, ya tienes un potenciador o no hay enemigos cerca) se quedan en el suelo. Los paquetes misteriosos se abren con el botón de acción (E, A del mando o el botón dorado en pantalla). Dan oro, experiencia, curación, un consumible o, rara vez, un ticket. Desaparecen con el tiempo.", "tex:pack"],
	["Cofres de pago y trampa", "Las huchas Poké Ball cuestan monedas de la partida (cuestan más con cada una que abres y cambian de tipo de bola). Acércate y pulsa el botón de acción: el precio se ve en el botón. Si no te alcanza, no se cobra. Cada hucha da una MEJORA gratis (subes de nivel y eliges una carta) o una Poké Ball; las más caras pueden dar las dos. Otras huchas son trampas: unas lucen sospechosas (ojos rojos) y otras están disfrazadas de hucha normal (fíjate en un colmillo). Si la abres sale una emboscada pequeña, pero puedes huir.", "tex:paid"],
	["Cajas de suministro", "Un aviso anuncia una caja que cae cerca. Llega hasta ella y pulsa el botón de acción antes de que se agote el tiempo (30 s). Hay cuatro tipos: médico y de recursos (sin enemigos extra), raro y excepcional (atraen enemigos, pero no hace falta derrotarlos). Solo hay una caja a la vez.", "tex:crate"],
	["Kecleon, el comerciante", "Un Kecleon de colores visita el mapa por un rato (60-75 s). Acércate y pulsa el botón de acción \"Comerciar\": te ofrece 3 mejoras permanentes para esta partida a cambio de monedas. Solo puedes comprar una por visita y cambiar las ofertas mientras tengas monedas (el precio sube con cada cambio y se reinicia en la siguiente visita). Cada color vende mejoras distintas; el azul shiny es raro y vende las mejores. Solo hay un Kecleon a la vez.", "dex:352"],
	["Menú Pokémon renovado", "En Pokémon ves a tu compañero en un retrato con flechas para pasar al anterior o al siguiente, su tipo, sus barras de PS, Velocidad y Ataque, su habilidad y su movimiento inicial. A la derecha, pestañas por región, «Solo los míos», un buscador (por nombre, tipo o número) y un orden (número, nombre, rareza o favoritos). Toca el corazón de una tarjeta para marcar un favorito; la estrella indica a tu compañero. La misma pantalla sirve para elegir equipo, compañero cooperativo y Pokémon de la fiesta.", "ball"],
	["Rescates de Pokémon", "De vez en cuando aparece un Pokémon salvaje que necesita ayuda (sin entrenadores). Herido: quédate a su lado unos segundos. Amenazado: derrota a los 4 enemigos que lo atacan. Perdido: sigue la flecha, encuéntralo y pulsa el botón de acción. Si lo logras, te da las gracias, te regala un premio (monedas, EXP, ticket, curación u objeto) y se marcha; nunca se une a tu equipo. Si no llegas a tiempo, simplemente se va. Solo hay un rescate a la vez.", "tex:rescue"],
	["Poké Ball y Alfas", "A veces ronda un Alfa: un Pokémon enorme, rojizo y muy resistente. Es opcional. Si lo derrotas, queda aturdido 8 segundos: pulsa el botón de acción para lanzarle UNA Poké Ball (80% de éxito). Si lo logras, se une a ti como aliado el resto de la partida (se recupera poco a poco y ocupa el mismo hueco que el aliado del altar legendario). Con el apuntado manual activado, el lanzamiento debe apuntar al Alfa; si fallas el tiro, no se gasta la bola. Las Poké Balls son raras: salen a veces de cofres, mochilas, cajas de suministro y al cortar hierba. El número que llevas aparece junto a tus monedas.", "tex:ball"],
	["Capturar jefes y gigantes", "Si llevas Poké Balls, al derrotar a un jefe normal (no los de las Grietas) o a un Pokémon gigante (Snorlax, Tyranitar, Onix, Steelix, Gyarados, Metagross y más) queda debilitado 8 segundos: pulsa el botón de acción para lanzarle una Poké Ball (60% de éxito en jefes, 75% en gigantes). Si lo logras, se une a ti como aliado. Puedes capturar como máximo 2 aliados por partida y pueden luchar a la vez.", "tex:ball"],
	["Legendarios salvajes", "Pasado el minuto 30 de la partida Normal, de vez en cuando aparece un legendario salvaje enorme y resistente. Si lo derrotas, recibes un premio especial (monedas, tickets y un objeto). No aparece durante grietas, cuevas, invasiones ni con otro jefe, y deja de aparecer poco antes de Eternatus.", "tex:wildleg"],
	["Regreso de la Grieta", "Al volver al mundo desde una Grieta o una guarida hay una cuenta atrás de 3-2-1: el tiempo de la partida y los enemigos se detienen y eres invulnerable hasta que termina.", "tex:return"],
	["Día y noche", "Cada partida alterna día, atardecer, noche y amanecer (ciclo de 8 minutos). De noche aparecen más Pokémon de tipo Fantasma, Siniestro y Bicho nocturnos; de día, más Pokémon diurnos. Algunos secretos solo se revelan de noche.", "tex:daynight"],
	["Peligros de bioma", "Los biomas extremos tienen peligros señalados antes de golpear: erupciones y quemaduras en volcanes, ráfagas que ralentizan en el hielo, rayos que pueden paralizar y burbujas tóxicas. Los Pokémon del tipo correspondiente son inmunes. Solo hay un aviso a la vez.", "tex:hazard"],
	["Cuevas y altares", "Se abre una cueva de un tipo (14 tipos). Derrota la oleada y pisa el altar: tus efectos de estado de ese tipo mejoran (quemar, veneno, ralentizar, dormir, paralizar…), hasta 3 niveles. Normal, Volador, Roca y Acero aún no tienen cueva.", "tex:cave"],
	["Invasiones", "Tras un aviso de 5 s, una invasión (fantasma, siniestra, eléctrica, estampida, brillante, mixta, Alfa o de pesadilla nocturna) dura 45 s. Sobrevive para ganar el premio; si caes, no hay premio.", "tex:invasion"],
	["Meteorito y Deoxys", "Un meteorito marca una zona: aléjate. Deja botín y, con un 10% de probabilidad, Deoxys emerge. Si lo derrotas antes de que escape, recibes un premio especial.", "tex:meteor"],
	["Proyecto Mewtwo", "Pasados los 13 minutos pueden aparecer 3 estaciones de investigación. Mantente en cada una unos segundos; al completarlas todas despierta Mewtwo, con ataques señalados. Una vez por partida.", "tex:mewtwo"],
	["Secretos", "Claros ocultos, runas que hay que pisar en orden, secretos lunares que se revelan de noche y nidos secretos. Cada uno da un premio modesto una sola vez.", "tex:secret"],
	["Mecanismos elementales", "Antorchas, fuentes, generadores y sellos que solo se activan al golpearlos con un movimiento del tipo correcto (no por acercarte). Son opcionales.", "tex:mech"],
	["Medallas", "Nueva pestaña en Misiones y Logros: medallas por explorar, rescatar, capturar Alfas y vencer eventos. Son cosméticas.", "tex:medals"],
	["Gachapon más ágil", "Toca la pantalla durante la animación para acelerarla, y vuelve atrás sin perder el premio.", "ticket"],
	["Fusiones y Fusion Dex", "Une dos movimientos evolucionados al máximo con Vínculo para crear un movimiento fusionado único (50 recetas). Cada receta descubierta queda en la Fusion Dex para siempre.", "book"],
	["Fusión automática", "Al vincular dos movimientos evolucionados y al nivel máximo se fusionan solos, con un gran aviso «FUSION!». Cada receta tiene su propio ataque especial con animación: tormentas, vórtices, rayos, prisiones, erupciones y más.", "book"],
	["Perfil del jugador", "Toca tu nombre de entrenador para abrir tu perfil: 3 Pokémon favoritos, estadísticas, medallas de tipo, tipo favorito con fondo propio, gorra, mochila y tema de la interfaz.", "tex:medals"],
	["Kecleon se marcha", "Tras tu compra, Kecleon desaparece del mapa (una compra por visita). Su tienda ahora usa el mismo estilo y fuente que el resto del juego, y todos sus objetos están en la pestaña Kecleon del Léxico.", "dex:352"],
	["Evoluciones con animación", "Cada movimiento evolucionado gana una habilidad propia que el base no tiene: ecos, vórtices, marcas que explotan, congelación y rotura, meteoros, saltos relámpago, rayos giratorios, sanguijuelas y más. Se activa sola al atacar (con su propia recarga) y viene con animación única. Respiro y Batido ahora también pueden evolucionar.", "move:inferno_tempest"],
	["Fusion Moves", "Si vinculas dos movimientos evolucionados y los subes al nivel máximo, se fusionan solos en un Fusion Move, con el aviso «FUSION!» y un sonido épico. Solo puedes tener UNO por partida: reemplaza a los dos movimientos originales, que ya no vuelven a salir en las mejoras. Ocupa un solo hueco, es más fuerte que cualquier evolucionado y lanza los dos ataques a la vez, además de un ataque especial único con animación propia cada pocos segundos (hay 50 recetas). Ya no se puede mejorar. Cada receta descubierta queda guardada en la Fusion Dex.", "move:inferno_tempest"],
	["Pantallas anchas", "El juego se adapta a pantallas 16:9 y 16:10 (como la Odin 3 Max): el campo de visión se amplía en lugar de recortarse y los botones se mantienen dentro de la pantalla.", "cards"],
	["Tamaño del texto", "En Ajustes puedes cambiar el tamaño del texto (Normal hasta Muy grande) para leer mejor en pantallas pequeñas.", "cards"],
]
const LEX_STATUS := [
	["freeze", "Congelado", "El enemigo no se mueve ni ataca y recibe un 25% más de daño. Los jefes lo resisten."],
	["para", "Paralizado", "El enemigo va mucho más lento y recibe más daño eléctrico. Los jefes lo resisten."],
	["sleep", "Dormido", "El enemigo no actúa, recibe un 30% más de daño y se despierta con el primer golpe. Darkrai es inmune."],
	["conf", "Confundido", "El enemigo se mueve sin rumbo y ataca a otros enemigos. Los jefes lo resisten."],
	["burn", "Quemado", "Daño continuo y el enemigo hace menos daño."],
	["poison", "Envenenado", "Daño continuo según su vida máxima (menos contra jefes)."],
	["slow", "Ralentizado", "El enemigo se mueve más despacio durante un rato."],
	["charm", "Enamorado", "El enemigo pelea de tu lado 20 s: ataca a otros enemigos y no te hace daño. Los jefes son inmunes y, al acabarse, no puede volver a enamorarse enseguida."],
]


const AB_TYPE := {
	"blaze": "fire", "overgrow": "grass", "torrent": "water", "swarm": "bug", "intimidate": "dark", "levitate": "flying", "static": "electric",
	"flamebody": "fire", "poisonpoint": "poison", "cutecharm": "fairy", "effectspore": "grass", "roughskin": "rock", "thickfat": "ice",
	"waterabsorb": "water", "voltabsorb": "electric", "flashfire": "fire", "sapsipper": "grass", "hugepower": "fighting", "sturdy": "rock",
	"regenerator": "psychic", "speedboost": "fire", "swiftswim": "water", "chlorophyll": "grass", "sandrush": "ground", "slushrush": "ice",
	"sandveil": "ground", "technician": "bug", "ironfist": "fighting", "megalauncher": "water", "adaptability": "normal", "compoundeyes": "bug",
	"luck": "normal", "pickup": "normal", "magnetpull": "steel", "earlybird": "flying", "runaway": "normal", "innerfocus": "fighting",
	"limber": "fighting", "battlearmor": "bug", "solidrock": "rock", "multiscale": "dragon", "furcoat": "normal", "guts": "fighting",
	"moxie": "dark", "prankster": "dark", "tintedlens": "bug", "defiant": "dark", "moldbreaker": "dragon", "wonderguard": "ghost",
	"drought": "fire", "drizzle": "water", "snowwarning": "ice", "sandstream": "rock", "poisonheal": "poison", "rockhead": "rock",
	"pressure": "psychic", "sheerforce": "fighting", "strongjaw": "dark", "steelworker": "steel", "transistor": "electric",
	"dragonsmaw": "dragon", "waterbubble": "water", "lightningrod": "electric", "motordrive": "electric", "dryskin": "water",
	"heatproof": "fire", "purifyingsalt": "ghost", "galewings": "flying", "pixilate": "fairy", "aerilate": "flying", "refrigerate": "ice",
	"protean": "normal",
}


const LEX_CATS := [
	["m", "Movimientos", "move:flamethrower"],
	["f", "Fusion Dex", "move:inferno_tempest"],
	["i", "Objetos", "leftovers"],
	["s", "Estados", "star"],
	["a", "Habilidades", "sprout"],
	["z", "Z y Dynamax", "zc:fire"],
	["k", "Kecleon", "dex:352"],
	["n", "Novedades", "book"],
]
var lex_title: Label
var lex_count: Label
var lex_chips: HFlowContainer
var lex_search: LineEdit
var lex_det: VBoxContainer
var lex_filter := "all"
var lex_entries: Array = []


func _build_lexicon() -> void:
	var s: Control = _screen("lexicon")
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	s.add_child(hb)
	# columna izquierda: categorias
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", _card_sb())
	lp.custom_minimum_size = Vector2(250, 0)
	hb.add_child(lp)
	lex_tabs = VBoxContainer.new()
	lex_tabs.add_theme_constant_override("separation", 6)
	lp.add_child(lex_tabs)
	for t in LEX_CATS:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): lex_tab = k; lex_filter = "all"; lex_search.text = ""; _refresh_lexicon(); _gf(tab_sel), Vector2(0, 54))
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.icon = _lex_tex(String(t[2]), 32)
		tb.expand_icon = true
		tb.add_theme_constant_override("icon_max_width", 34)
		tb.add_theme_constant_override("h_separation", 12)
		tb.add_theme_font_size_override("font_size", 22)
		lex_tabs.add_child(tb)
	# centro: cabecera, filtros, busqueda y rejilla
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", _card_sb())
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(cp)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	cp.add_child(cv)
	var hh := HBoxContainer.new()
	cv.add_child(hh)
	lex_title = _label("Movimientos", 34, C_GOLD)
	lex_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	hh.add_child(lex_title)
	lex_count = _label("", 22, Color("#9fb4d8"))
	lex_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	hh.add_child(lex_count)
	lex_chips = HFlowContainer.new()
	lex_chips.add_theme_constant_override("h_separation", 6)
	lex_chips.add_theme_constant_override("v_separation", 6)
	cv.add_child(lex_chips)
	lex_search = LineEdit.new()
	lex_search.placeholder_text = L.t("Buscar...")
	lex_search.custom_minimum_size = Vector2(0, 40)
	lex_search.add_theme_font_size_override("font_size", 20)
	lex_search.text_changed.connect(func(_t: String): _lex_render())
	cv.add_child(lex_search)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(sc)
	lex_box = VBoxContainer.new()
	lex_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_box.add_theme_constant_override("separation", 8)
	sc.add_child(lex_box)
	# derecha: detalle
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", _card_sb())
	dp.custom_minimum_size = Vector2(340, 0)
	hb.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	lex_det = VBoxContainer.new()
	lex_det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_det.add_theme_constant_override("separation", 8)
	dsc.add_child(lex_det)


# Icono (Texture2D) de una entrada: "tex:x" = imagen del Lexico; otro valor = icono pixel art de icons.gd.
var _dex_crop_cache := {}


# Primer fotograma del Pokemon recortado al contenido (el cuadro original tiene mucho margen transparente).
func _dex_cropped(dex: int) -> Texture2D:
	if _dex_crop_cache.has(dex):
		return _dex_crop_cache[dex]
	var t: Texture2D = _icon_tex(dex, false)
	var out: Texture2D = t
	if t is AtlasTexture and (t as AtlasTexture).atlas != null:
		var at: AtlasTexture = t as AtlasTexture
		var img: Image = at.atlas.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var sub: Image = img.get_region(Rect2i(at.region))
			var ur: Rect2i = sub.get_used_rect()
			if ur.size.x > 0 and ur.size.y > 0:
				out = ImageTexture.create_from_image(sub.get_region(ur))
	_dex_crop_cache[dex] = out
	return out


func _lex_tex(spec: String, size: float) -> Texture2D:
	if spec.begins_with("dex:"):
		return _dex_cropped(int(spec.substr(4)))   # sprite real del Pokemon
	if spec.begins_with("tex:"):
		var t: Texture2D = load("res://assets/world/lexn_%s.png" % spec.substr(4))
		return t
	return IC.btn_tex(spec, size)


func _lex_big(spec: String, size: float) -> Control:
	var tr := TextureRect.new()
	tr.texture = _lex_tex(spec, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(size, size)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _lex_e(k: String, name: String, icon: String, sub: String, col: Color, desc: String, dim: bool = false, stats: Array = [], evo: Array = [], ty: String = "") -> Dictionary:
	return {"k": k, "name": name, "icon": icon, "sub": sub, "col": col, "desc": desc, "dim": dim, "stats": stats, "evo": evo, "ty": ty}


func _lex_build(tab: String) -> Array:
	var out: Array = []
	var cat_cols: Color = Color("#8fa3c4")
	if tab == "m":
		for mid in MD.ORDER:
			if not MD.MOVES.has(mid):
				continue
			var m: Dictionary = MD.MOVES[mid]
			var ty: String = String(m["type"])
			var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#ffffff")))
			var st: Array = []
			if m.has("dmg"):
				st.append([L.t("Daño"), str(int(m["dmg"]))])
			if m.has("cd"):
				st.append([L.t("Recarga"), "%.1f s" % float(m["cd"])])
			if m.has("count"):
				st.append([L.t("Proyectiles"), str(int(m["count"]))])
			if m.has("radius"):
				st.append([L.t("Radio"), str(int(m["radius"]))])
			var evo: Array = []
			var desc: String = L.t(String(m["desc"]))
			if MD.EVO.has(mid):
				evo = [["move:" + String(mid), L.t(String(m["name"]))], ["evo:" + String(mid), L.t(String(MD.EVO[mid][0]))]]
			if MD.EVO_ALT.has(mid):
				if evo.is_empty():
					evo = [["move:" + String(mid), L.t(String(m["name"]))]]
				evo.append(["evo:" + String(mid), L.t(String(MD.EVO_ALT[mid][0]))])
			out.append(_lex_e("mv_" + String(mid), L.t(String(m["name"])), "move:" + String(mid), L.t(String(MD.TYPE_NAME[ty])), tcol, desc, false, st, evo, ty))
	elif tab == "f":
		var fnd: Array = SV.d.get("fusions", [])
		for fr in FUS.R:
			var fok: bool = fnd.has(fr[0])
			var fcol: Color = Color.html(String(fr[5]))
			if fok:
				out.append(_lex_e("fu_" + String(fr[0]), L.t(String(fr[1])), "move:" + String(fr[0]), L.t("Desbloqueada"), fcol, L.t(String(fr[4])), false, [],
					[["move:" + String(fr[2]), _fname(String(fr[2]))], ["move:" + String(fr[3]), _fname(String(fr[3]))], ["move:" + String(fr[0]), L.t(String(fr[1]))]]))
			else:
				out.append(_lex_e("fu_" + String(fr[0]), "???", "", L.t("Bloqueada"), cat_cols, L.t("Fusiona dos movimientos evolucionados para descubrir esta receta."), true))
	elif tab == "i":
		var found: Dictionary = SV.d.get("itemsFound", {})
		for it in TD.ITEMS:
			var id: String = String(it["id"])
			var ok: bool = found.has(id)
			out.append(_lex_e("it_" + id, L.t(String(it["name"])), id, L.t("✔ Encontrado") if ok else L.t("Aún sin encontrar"), Color("#8fe3b0") if ok else cat_cols, L.t(String(it["desc"])), not ok))
		for ie in INF_UP:
			var rows: Array = []
			for lv in [1, 2, 5, 10, 25, 50]:
				rows.append(L.t("Nv. %d: %s") % [lv, _inf_fx(String(ie[0]), lv)])
			rows.append(L.t("Tope: %s") % _inf_fx(String(ie[0]), 100000))
			out.append(_lex_e("up_" + String(ie[0]), L.t(String(ie[1])), String(ie[2]), L.t("Sin nivel máximo"), Color("#8fe3b0"), L.t(String(INF_DESC.get(String(ie[0]), ""))) + "\n\n" + "\n".join(rows)))
	elif tab == "s":
		var sic := {"freeze": "type:ice", "para": "type:electric", "sleep": "type:psychic", "conf": "type:ghost", "burn": "type:fire", "poison": "type:poison", "slow": "type:water", "charm": "st:charm"}
		for st2 in LEX_STATUS:
			out.append(_lex_e("st_" + String(st2[0]), L.t(String(st2[1])), String(sic.get(String(st2[0]), "star")), "", Color.WHITE, L.t(String(st2[2]))))
	elif tab == "a":
		for aid in AB.FX:
			var ad: Dictionary = AB.FX[aid]
			var aty: String = String(AB_TYPE.get(String(aid), "normal"))
			var acol: Color = Color.html(String(MD.TYPE_COLOR.get(aty, "#b0a99f")))
			out.append(_lex_e("ab_" + String(aid), L.t(String(ad["name"])), "type:" + aty, L.t(String(MD.TYPE_NAME[aty])), acol, L.t(String(ad["desc"])), false, [], [], aty))
	elif tab == "z":
		var dn: int = int(SV.d["stats"].get("dens", 0))
		var dok: bool = dn >= 1
		out.append(_lex_e("dyn", "Dynamax", "type:dragon", L.t("Desbloqueado") if dok else L.t("Vence una guarida Dynamax: %d/1") % dn, Color("#ff7a9a"),
			L.t("Cada 4 minutos (desde el minuto 3): tu Pokémon se vuelve gigante %d s con +30%% a todos sus atributos y lanza ondas Max de su tipo. Cada guarida Dynamax vencida lo recarga al instante.") % [int(DYN.DUR)], not dok))
		for zt in ZM.ORDER:
			var zd: Dictionary = ZM.DEF[zt]
			var zn: int = int(SV.d["stats"].get("tk_" + zt, 0))
			var zok: bool = ZM.unlocked(zt, SV.d["stats"])
			var zcol: Color = Color.html(String(MD.TYPE_COLOR.get(zt, "#ffffff")))
			var zsub: String = L.t(String(MD.TYPE_NAME[zt])) + " · " + (L.t("Desbloqueado") if zok else L.t("Derrota %d Pokémon de tipo %s: %d/%d") % [ZM.NEED, L.t(String(MD.TYPE_NAME[zt])), zn, ZM.NEED])
			out.append(_lex_e("z_" + String(zt), L.t(String(zd["name"])), "zc:" + String(zt), zsub, zcol, L.t(String(zd["desc"])), not zok))
	elif tab == "k":
		for kv in KCX.ORDER:
			var kvc: Color = Color.html(String(KCX.VAR[kv]["col"]))
			for kid in KCX.CAT[kv]:
				if not KCX.ITEMS.has(kid):
					continue
				var kit: Array = KCX.ITEMS[kid]
				out.append(_lex_e("kc_" + String(kid), L.t(String(kit[0])), "kec:" + String(kid), L.t(String(KCX.VAR[kv]["name"])), kvc, L.t(String(kit[3])), false,
					[[L.t("Precio"), str(int(kit[1]))], [L.t("Máximo"), str(int(kit[2]))]]))
	else:
		for nw in LEX_NEW:
			var ns: String = String(nw[2])
			out.append(_lex_e("nw_" + String(nw[0]), L.t(String(nw[0])), ns, "", Color.WHITE, L.t(String(nw[1]))))
	return out


func _refresh_lexicon() -> void:
	var tbs: Array = lex_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = String(LEX_CATS[i][0])
		_gold_btn(tbs[i], key == lex_tab)
		if key != lex_tab:
			for stn in ["normal", "hover", "pressed"]:
				(tbs[i] as Button).add_theme_stylebox_override(stn, _sb(Color("#2b4f9e") if stn == "normal" else Color("#3a64bf"), Color("#9fb4ff"), 2, 12))
		if key == lex_tab:
			tab_sel = tbs[i]
			lex_title.text = L.t(String(LEX_CATS[i][1]))
	tab_row = lex_tabs
	lex_entries = _lex_build(lex_tab)
	# filtros por tipo (solo movimientos)
	_clear(lex_chips)
	lex_chips.visible = lex_tab == "m" or lex_tab == "a"
	if lex_tab == "m" or lex_tab == "a":
		var allb := _btn("Todos", func(): lex_filter = "all"; _lex_chips_hl(); _lex_render(), Vector2(70, 36))
		allb.add_theme_font_size_override("font_size", 16)
		allb.set_meta("ty", "all")
		lex_chips.add_child(allb)
		for ty in TYPE_IDS:
			var tyk: String = String(ty)
			var cb := Button.new()
			cb.icon = IC.btn_tex("type:" + tyk, 24)
			cb.custom_minimum_size = Vector2(44, 36)
			cb.tooltip_text = L.t(String(MD.TYPE_NAME[tyk]))
			cb.focus_mode = Control.FOCUS_ALL
			cb.add_theme_stylebox_override("normal", _sb(Color("#1a2c63"), Color("#5a74c8"), 2, 8))
			cb.add_theme_stylebox_override("hover", _sb(Color("#2a4590"), Color.WHITE, 2, 8))
			cb.add_theme_stylebox_override("focus", _sb(Color("#2a4590"), C_GOLD, 3, 8))
			cb.set_meta("ty", tyk)
			cb.pressed.connect(func(): lex_filter = tyk; _lex_chips_hl(); _lex_render())
			lex_chips.add_child(cb)
		_lex_chips_hl()
	_lex_render()
	focus_first = tab_sel
	_update_top()


func _lex_chips_hl() -> void:
	for c in lex_chips.get_children():
		var on: bool = String(c.get_meta("ty", "")) == lex_filter
		c.modulate = Color.WHITE if on else Color(0.8, 0.85, 1.0, 0.75)
		if c is Button and String(c.get_meta("ty", "")) != "all":
			(c as Button).add_theme_stylebox_override("normal", _sb(Color("#1a2c63"), C_GOLD if on else Color("#5a74c8"), 3 if on else 2, 8))


func _lex_render() -> void:
	_clear(lex_box)
	var q: String = lex_search.text.strip_edges().to_lower()
	var shown: Array = []
	for e in lex_entries:
		if (lex_tab == "m" or lex_tab == "a") and lex_filter != "all" and String(e["ty"]) != lex_filter:
			continue
		if q != "" and String(e["name"]).to_lower().find(q) < 0:
			continue
		shown.append(e)
	var tot := 0
	var got := 0
	for e2 in lex_entries:
		tot += 1
		if not bool(e2["dim"]):
			got += 1
	lex_count.text = ("%d / %d" % [got, tot]) if (lex_tab == "i" or lex_tab == "f" or lex_tab == "z") else str(shown.size())
	if lex_tab == "n":
		# las novedades son texto largo: una lista, no una rejilla
		for e3 in shown:
			var bn := Button.new()
			bn.text = String(e3["name"])
			bn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bn.icon = _lex_tex(String(e3["icon"]), 40)
			bn.expand_icon = true
			bn.add_theme_constant_override("icon_max_width", 40)
			bn.add_theme_constant_override("h_separation", 12)
			bn.add_theme_font_size_override("font_size", 20)
			bn.custom_minimum_size = Vector2(0, 52)
			bn.focus_mode = Control.FOCUS_ALL
			bn.clip_text = true
			_lex_style_tile(bn)
			_lex_bind(bn, e3)
			lex_box.add_child(bn)
	else:
		var g := GridContainer.new()
		g.columns = 5
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		if lex_tab == "k":
			var lg := HFlowContainer.new()
			lg.add_theme_constant_override("h_separation", 10)
			lg.add_theme_constant_override("v_separation", 4)
			lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lex_box.add_child(lg)
			var lgt := _label(L.t("Quién lo vende:"), 15, Color("#9fb4d8"))
			lgt.autowrap_mode = TextServer.AUTOWRAP_OFF
			lg.add_child(lgt)
			for kv2 in KCX.ORDER:
				var chip := PanelContainer.new()
				var kc2: Color = Color.html(String(KCX.VAR[kv2]["col"]))
				var cst := _sb(Color("#1a2c63").lerp(kc2, 0.3), kc2, 2, 8)
				cst.set_content_margin_all(4)
				chip.add_theme_stylebox_override("panel", cst)
				var cl := _label(L.t(String(KCX.VAR[kv2]["name"])), 14, Color.WHITE)
				cl.autowrap_mode = TextServer.AUTOWRAP_OFF
				chip.add_child(cl)
				lg.add_child(chip)
		lex_box.add_child(g)
		for e4 in shown:
			var b := Button.new()
			b.text = String(e4["name"])
			b.custom_minimum_size = Vector2(104, 100)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_ALL
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.add_theme_font_size_override("font_size", 13)
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			if String(e4["icon"]) != "":
				b.icon = _lex_tex(String(e4["icon"]), 44)
				b.expand_icon = true
				b.add_theme_constant_override("icon_max_width", 44)
			else:
				b.text = "?\n" + String(e4["name"])
			if bool(e4["dim"]):
				b.modulate = Color(0.62, 0.66, 0.78, 0.85)
			_lex_style_tile(b, e4["col"] if lex_tab == "k" else Color.TRANSPARENT)
			_lex_bind(b, e4)
			g.add_child(b)
	call_deferred("_touch_pass", lex_box)
	if shown.size() > 0:
		_lex_show(shown[0])
	else:
		_clear(lex_det)


func _lex_style_tile(b: Button, edge: Color = Color.TRANSPARENT) -> void:
	if edge.a > 0.0:
		# Kecleon: el borde y el fondo llevan el color de la variante que vende el objeto
		var bg: Color = Color("#1a2c63").lerp(edge, 0.22)
		b.add_theme_stylebox_override("normal", _sb(bg, edge, 4, 8))
		b.add_theme_stylebox_override("hover", _sb(bg.lightened(0.15), Color.WHITE, 3, 8))
		b.add_theme_stylebox_override("pressed", _sb(bg.lightened(0.15), Color.WHITE, 3, 8))
		b.add_theme_stylebox_override("focus", _sb(bg.lightened(0.1), C_GOLD, 5, 8))
		return
	b.add_theme_stylebox_override("normal", _sb(Color("#1a2c63"), Color("#4a64b8"), 2, 8))
	b.add_theme_stylebox_override("hover", _sb(Color("#2a4590"), Color.WHITE, 2, 8))
	b.add_theme_stylebox_override("pressed", _sb(Color("#2a4590"), Color.WHITE, 2, 8))
	b.add_theme_stylebox_override("focus", _sb(Color("#2f4c9e"), C_GOLD, 4, 8))


func _lex_bind(b: Button, e: Dictionary) -> void:
	b.focus_entered.connect(func(): _lex_show(e))
	b.mouse_entered.connect(func(): _lex_show(e))
	b.pressed.connect(func(): _lex_show(e))


func _lex_show(e: Dictionary) -> void:
	_clear(lex_det)
	lex_det.add_child(_label(String(e["name"]), 26, C_GOLD))
	if String(e["sub"]) != "":
		var sl := _label(String(e["sub"]), 17, e["col"])
		lex_det.add_child(sl)
	if String(e["icon"]) != "":
		var ic := _lex_big(String(e["icon"]), 96)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lex_det.add_child(ic)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", _sb(Color("#0d1b3d"), Color("#3a54a8"), 2, 8))
	var dl := _label(String(e["desc"]), 16, Color("#dbe6ff"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(dl)
	lex_det.add_child(dp)
	var stats: Array = e["stats"]
	if not stats.is_empty():
		var gs := GridContainer.new()
		gs.columns = 2
		gs.add_theme_constant_override("h_separation", 6)
		gs.add_theme_constant_override("v_separation", 6)
		for sv in stats:
			var pc := PanelContainer.new()
			pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pc.add_theme_stylebox_override("panel", _sb(Color("#0d1b3d"), Color("#3a54a8"), 2, 8))
			var vb := VBoxContainer.new()
			vb.add_theme_constant_override("separation", 0)
			pc.add_child(vb)
			vb.add_child(_label(String(sv[0]), 13, Color("#9fb4d8")))
			vb.add_child(_label(String(sv[1]), 20, Color.WHITE))
			gs.add_child(pc)
		lex_det.add_child(gs)
	var evo: Array = e["evo"]
	if not evo.is_empty():
		lex_det.add_child(_label(L.t("Evolución") if lex_tab == "m" else L.t("Receta"), 20, C_GOLD))
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 4)
		hr.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in range(evo.size()):
			if i > 0:
				var ar := _label("→" if lex_tab == "m" else ("=" if i == evo.size() - 1 else "+"), 24, C_GOLD)
				ar.autowrap_mode = TextServer.AUTOWRAP_OFF
				hr.add_child(ar)
			var vb2 := VBoxContainer.new()
			vb2.custom_minimum_size = Vector2(88, 0)
			var ib := _lex_big(String(evo[i][0]), 48)
			ib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vb2.add_child(ib)
			var nl := _label(String(evo[i][1]), 13, Color("#c8d6ee"))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vb2.add_child(nl)
			hr.add_child(vb2)
		lex_det.add_child(hr)


func _lex_card(icon: Control, title: String, sub: String, sub_col: Color, desc: String, dim: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_sb())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	if icon != null:
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	var tl := _label(title, 22, Color.WHITE if not dim else Color("#8fa3c4"))
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(tl)
	if sub != "":
		var sl := _label(sub, 15, sub_col)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(sl)
	var dl := _label(desc, 16, Color("#c8d6ee"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(dl)
	return card


func _fname(id: String) -> String:
	return L.t(String(MD.MOVES[id]["name"])) if MD.MOVES.has(id) else id


func _lex_q() -> Control:
	var q := _label("?", 36, Color("#5a6a88"))
	q.custom_minimum_size = Vector2(48, 48)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return q


func _lex_grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	lex_box.add_child(g)
	return g


const INF_DESC := {
	"mult": "+1 proyectil en movimientos de disparo, cono y bumerán (cada nivel rinde menos).",
	"pierce": "+1 perforación en disparos, conos y ondas (cada nivel rinde menos).",
	"amp": "+12% de probabilidad y duración de estados: parálisis, congelación, confusión, quemadura y veneno.",
	"lens": "+3% de probabilidad de crítico (3 niveles: +9%; luego rinde menos, tope 30%).",
	"fang": "Recuperas un 4% del daño que haces (3 niveles: 12%; luego rinde menos, tope 25%).",
	"edge": "+12% de daño crítico (rinde menos con cada nivel, tope x3).",
	"dstrike": "+6% de probabilidad de golpear dos veces (rinde menos, tope 45%).",
	"trs": "+8% de Pokémonedas al acabar la partida (rinde menos con cada nivel).",
}
const INF_UP := [["mult", "Multiplicador", "cards"], ["pierce", "Fuerza Perforante", "quickclaw"], ["amp", "Amplificador", "star"], ["lens", "Lente de Precisión", "scopelens"], ["fang", "Colmillo Vampírico", "lifeorb"], ["edge", "Filo Fatal", "expertbelt"], ["dstrike", "Golpe Doble", "choiceband"], ["trs", "Imán del Tesoro", "amuletcoin"]]


static func _dimf(lv: float, first: float, cap: float) -> float:
	if lv <= 0.0:
		return 0.0
	return cap * (1.0 - exp(-lv * first / cap))


func _inf_fx(id: String, lv: int) -> String:
	var l: float = float(lv)
	match id:
		"mult":
			return "+%d" % int(_dimf(l, 0.6, 5.0) + 0.5)
		"pierce":
			return "+%d" % int(_dimf(l, 0.7, 6.0) + 0.5)
		"amp":
			return "+%d%%" % int(roundf(_dimf(l, 0.12, 0.8) * 100.0))
		"lens":
			return "+%d%%" % int(roundf(3.0 * l if l <= 3.0 else 9.0 + _dimf(l - 3.0, 0.03, 0.21) * 100.0))
		"fang":
			return "%d%%" % int(roundf(4.0 * l if l <= 3.0 else 12.0 + _dimf(l - 3.0, 0.04, 0.13) * 100.0))
		"edge":
			return "x%.2f" % (1.5 + _dimf(l, 0.12, 1.5))
		"dstrike":
			return "%d%%" % int(roundf(_dimf(l, 0.06, 0.45) * 100.0))
		"trs":
			return "+%d%%" % int(roundf(_dimf(l, 0.08, 1.0) * 100.0))
	return ""


func _reward_box(r: Dictionary, w: float = 170.0) -> HBoxContainer:
	var rw := HBoxContainer.new()
	rw.custom_minimum_size = Vector2(w, 0)
	rw.add_theme_constant_override("separation", 6)
	if int(r.get("coins", 0)) > 0:
		rw.add_child(IC.rect("coin", 24))
		var l1 := _label("%d" % int(r["coins"]), 20, C_GOLD)
		l1.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l1)
	if int(r.get("t1", 0)) > 0:
		rw.add_child(IC.rect("ticket", 24))
		var l2 := _label("%d" % int(r["t1"]), 20, Color("#ffd23f"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l2)
	if int(r.get("t10", 0)) > 0:
		rw.add_child(IC.rect("ticket10", 24))
		var l3 := _label("%d ×10" % int(r["t10"]), 20, Color("#c47bff"))
		l3.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l3)
	return rw


func _refresh_goals() -> void:
	if cur == "profile":
		_refresh_profile()
		return
	PG.ensure()
	PG.check()
	_clear(goals_box)
	call_deferred("_touch_pass", goals_box)
	var first: Button = null
	var tbs: Array = goals_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = ["m", "a", "h", "z", "p", "r"][i]
		var on: bool = key == goals_tab
		if on:
			_set_btn(tbs[i], "gold")
			tab_sel = tbs[i]
		else:
			for st in ["normal", "hover", "pressed", "focus"]:
				tbs[i].remove_theme_stylebox_override(st)
			for fc in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				tbs[i].remove_theme_color_override(fc)
		tbs[i].get_child(0).visible = on
	tab_row = goals_tabs
	if goals_tab == "m":
		first = _goals_missions()
	elif goals_tab == "a":
		first = _goals_ach()
	elif goals_tab == "h":
		first = _goals_medals()
	elif goals_tab == "z":
		first = _goals_zcrystals()
	elif goals_tab == "r":
		first = _goals_records()
	else:
		first = _goals_missions()
	focus_first = first if first != null else tbs[0]
	_update_top()


func _mission_row(m: Dictionary, weekly: bool, idx: int) -> Button:
	var def: Dictionary = PG.def_of(String(m["id"]))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _up_card_sb())
	goals_box.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var gic := IC.rect("flag", 36)
	gic.custom_minimum_size.x = 48
	row.add_child(gic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	col.add_child(_label(PG.mission_text(m), 20))
	var pb := ProgressBar.new()
	pb.max_value = float(m["goal"])
	pb.value = minf(float(m["prog"]), float(m["goal"]))
	pb.custom_minimum_size = Vector2(0, 14)
	pb.show_percentage = false
	_goal_pb(pb)
	col.add_child(pb)
	var rwd := _reward_box(def["reward"])
	rwd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rwd)
	var out: Button = null
	var mm: Dictionary = m
	if not weekly and not PG.m_done(m) and not bool(SV.d["missions"].get("rerolled", false)):
		var rb := _btn("Cambiar", func(): _reroll(idx), Vector2(140, 44))
		rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(rb)
		_btn_glyph(rb, "swap", Color.WHITE)   # ya en el arbol, para que tome el estilo azul del tema
		out = rb
	var b: Button
	if bool(m["claimed"]):
		b = _btn("Reclamado", func(): pass, Vector2(140, 44))
		b.disabled = true
	elif PG.m_done(m):
		b = _btn("¡Reclamar!", func(): _claim_mission(mm, weekly), Vector2(140, 44))
		_set_btn(b, "gold")
		out = b
	else:
		b = _btn("%d / %d" % [mini(int(m["prog"]), int(m["goal"])), int(m["goal"])], func(): pass, Vector2(140, 44))
		b.disabled = true
	if b.disabled:
		b.add_theme_stylebox_override("disabled", _sb(Color("#0f2268"), SET_LINE, 2, 10))
		b.add_theme_color_override("font_disabled_color", Color.WHITE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return out


func _goals_missions() -> Button:
	var first: Button = null
	var M: Dictionary = SV.d["missions"]
	_goal_sec("Misiones diarias")
	var i := 0
	for m in M["daily"]:
		var b: Button = _mission_row(m, false, i)
		if first == null and b != null:
			first = b
		i += 1
	_goal_sec("Misiones semanales")
	for m in M["weekly"]:
		var b2: Button = _mission_row(m, true, 0)
		if first == null and b2 != null:
			first = b2
	_goal_info("Cambian a las 00:00 (hora de Puerto Rico). Puedes cambiar una diaria al día.")
	return first


func _reroll(i: int) -> void:
	if PG.reroll(i):
		Aud.sfx("confirm")
	_refresh_goals()


func _claim_mission(m: Dictionary, weekly: bool) -> void:
	if PG.claim(m, weekly):
		Aud.sfx("buy")
		toast(L.t("¡Recompensa reclamada!"))
	_refresh_goals()


func _goals_medals() -> Button:
	const ACHM = preload("res://scripts/ach.gd")
	_goal_sec(L.t("Medallas: %d / %d") % [ACHM.count_got(), ACHM.LIST.size()])
	_goal_sec(L.t("Medallas de tipo"), 22)
	_goal_info(L.t("Derrota %d Pokémon de un tipo para ganar su medalla.") % ZM.NEED)
	var tgp := PanelContainer.new()
	tgp.add_theme_stylebox_override("panel", _up_card_sb())
	goals_box.add_child(tgp)
	var tg := GridContainer.new()
	tg.columns = 9
	tg.add_theme_constant_override("h_separation", 12)
	tg.add_theme_constant_override("v_separation", 10)
	tg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tgp.add_child(tg)
	for ty2 in TYPE_IDS:
		var tcard := VBoxContainer.new()
		tcard.add_child(_medal_icon(String(ty2), 84))
		var tl2 := _label("%d/%d" % [mini(int(SV.d["stats"].get("tk_" + String(ty2), 0)), ZM.NEED), ZM.NEED], 15, Color("#c8d6ee"))
		tl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl2.autowrap_mode = TextServer.AUTOWRAP_OFF
		tcard.add_child(tl2)
		tg.add_child(tcard)
	var first: Button = null
	for c in ACHM.CATS:
		_goal_sec(L.t(String(c[1])), 22)
		var mg := GridContainer.new()
		mg.columns = 2
		mg.add_theme_constant_override("h_separation", 10)
		mg.add_theme_constant_override("v_separation", 8)
		mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goals_box.add_child(mg)
		for a in ACHM.LIST:
			if String(a[1]) != String(c[0]):
				continue
			var e: Dictionary = ACHM.entry(String(a[0]))
			var got: bool = bool(e["got"])
			var prog: int = mini(int(e["prog"]), int(a[4]))
			var mc := PanelContainer.new()
			mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var ms := _up_card_sb()
			if got:
				ms.border_color = Color("#f6c433")
			mc.add_theme_stylebox_override("panel", ms)
			mg.add_child(mc)
			var mr := HBoxContainer.new()
			mr.add_theme_constant_override("separation", 10)
			mc.add_child(mr)
			var mi := IC.rect("medal1" if got else "medalOff", 52)
			mi.custom_minimum_size.x = 56
			mr.add_child(mi)
			var mv := VBoxContainer.new()
			mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			mv.add_theme_constant_override("separation", 2)
			mr.add_child(mv)
			mv.add_child(_label(L.t(String(a[2])), 20, C_GOLD if got else Color.WHITE))
			mv.add_child(_label(L.t(String(a[3])), 15, Color("#dfe8ff")))
			var mpb := _set_pill("%d/%d" % [prog, int(a[4])])
			mpb.get_parent().size_flags_vertical = Control.SIZE_SHRINK_CENTER
			mr.add_child(mpb.get_parent())
	return first


func _goals_ach() -> Button:
	var all: Array = PG.list()
	var ach: Dictionary = SV.d.get("ach", {})
	var total := 0
	for a in all:
		if ach.has(String(a["id"])):
			total += 1
	_goal_sec(L.t("Logros: %d / %d") % [total, all.size()])
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	goals_box.add_child(chips)
	var first: Button = null
	for c in PG.CATS:
		var ck: String = String(c[0])
		var n := 0
		var d := 0
		for a in all:
			if String(a["cat"]) == ck:
				n += 1
				if ach.has(String(a["id"])):
					d += 1
		var cb := _btn("%s  %d/%d" % [L.t(String(c[1])), d, n], func(): ach_cat = ck; _refresh_goals(), Vector2(0, 44))
		if ck == ach_cat:
			_set_btn(cb, "gold")
		chips.add_child(cb)
		if first == null:
			first = cb
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for a in all:
		if String(a["cat"]) != ach_cat or int(a["dex"]) > 0:
			continue
		grid.add_child(_ach_card(a, ach.has(String(a["id"]))))
	if ach_cat == "legendarios":
		var legs: Array = []
		var beaten := 0
		for a in all:
			if int(a["dex"]) > 0:
				legs.append(a)
				if ach.has(String(a["id"])):
					beaten += 1
		_goal_sec(L.t("Legendarios vencidos %d / %d") % [beaten, legs.size()], 22)
		var lg := GridContainer.new()
		lg.columns = 10
		lg.add_theme_constant_override("h_separation", 6)
		lg.add_theme_constant_override("v_separation", 6)
		lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goals_box.add_child(lg)
		for a in legs:
			var ok: bool = ach.has(String(a["id"]))
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.09, 0.32, 0.92), Color("#f6c433") if ok else SET_LINE, 2, 10))
			var cv := VBoxContainer.new()
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(cv)
			var tr := TextureRect.new()
			tr.texture = _icon_tex(int(a["dex"]), false)
			tr.custom_minimum_size = Vector2(0, 56)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if not ok:
				tr.modulate = Color(0.0, 0.0, 0.0, 0.55)
			cv.add_child(tr)
			var nl := _label(String(a["arg"]) if ok else "???", 12, Color("#b9cbf0"))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(nl)
			lg.add_child(cell)
	return first


func _goals_zcrystals() -> Button:
	var zl: Array = PG.zlist()
	var nd := 0
	for zm in zl:
		if PG.zdone(zm):
			nd += 1
	_goal_sec(L.t("Cristales Z: %d / %d") % [nd, zl.size()])
	_goal_info(L.t("Cumple la misión de un tipo para desbloquear su movimiento Z. También se desbloquea derrotando a 250 Pokémon de ese tipo o con un cristal del gacha."))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for zm in zl:
		grid.add_child(_zmis_card(zm, PG.zdone(zm)))
	return null


# Tarjeta de logro o cristal: borde dorado si esta conseguido.
func _goal_card_sb(done: bool) -> StyleBoxFlat:
	var sb := _up_card_sb()
	if done:
		sb.border_color = Color("#f6c433")
	return sb


func _zmis_card(zm: Dictionary, done: bool) -> PanelContainer:
	var t: String = String(zm["type"])
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _goal_card_sb(done))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect("zc:" + t, 64)
	mi.custom_minimum_size.x = 68
	if not done:
		mi.modulate = Color(0.35, 0.35, 0.4, 0.55)
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(L.t(String(ZM.DEF[t]["name"])), 22, Color.WHITE))
	col.add_child(_label(L.t(String(zm["desc"])), 16, Color("#b9cbf0")))
	var v: int = mini(PG.stat(String(zm["stat"])), int(zm["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(zm["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		_goal_pb(pb)
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("¡Conseguido!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(zm["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	fl.add_child(_reward_box({"coins": PG.ZMIS_COINS}, 0.0))
	return card


func _ach_card(a: Dictionary, done: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _goal_card_sb(done))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 60)
	mi.custom_minimum_size.x = 64
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(PG.name_of(a), 24, Color.WHITE))
	var ds: String = PG.desc_of(a)
	if PG.is_multi(a):
		ds += " " + L.t("(Requiere multijugador: no disponible en esta versión)")
	col.add_child(_label(ds, 16, Color("#b9cbf0")))
	var v: int = mini(PG.value(a), int(a["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(a["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		_goal_pb(pb)
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("¡Conseguido!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(a["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	var rb := _reward_box(a["reward"], 0.0)
	fl.add_child(rb)
	if String(a["title"]) != "":
		fl.add_child(_label("·", 18, Color.WHITE))
		var tl := _label(L.t("Título: %s") % L.t(String(a["title"])), 18, C_GOLD)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		fl.add_child(tl)
	return card


# ---------------------------------------------------------------
# Perfil del jugador (sin online): nombre, Pokemon actual, 3 favoritos, titulo y tarjeta
# ---------------------------------------------------------------
func _nick() -> String:
	var n: String = String(SV.d.get("nick", "")).strip_edges()
	return n if n != "" else L.t("Entrenador")


class TrainerFig extends Control:
	var tc := {}
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var CV = load("res://scripts/cave_int.gd")
		var fem: bool = int(tc.get("g", 0)) == 1
		var n: int = 5 if fem else 4
		var body: Texture2D = CV.tex_in("trainer", ("nf" if fem else "nm") + str(clampi(int(tc.get("outfit", 0)), 0, n - 1)))
		if body == null:
			return
		var k: float = minf(size.x / float(body.get_width()), size.y / float(body.get_height() * 1.1))
		var bw: float = body.get_width() * k
		var bh: float = body.get_height() * k
		var bob: float = sin(t * 2.4) * 1.5
		var org := Vector2((size.x - bw) * 0.5, size.y - bh - 2.0 + bob)
		var bag_i: int = int(tc.get("bag", -1))
		if bag_i >= 0:
			var bt: Texture2D = CV.tex_in("trainer", "bag%d" % bag_i)
			if bt != null:
				var bsz: Vector2 = bt.get_size() * (bw * 0.36 / float(bt.get_width()))
				var bx: float = bw * (0.70 if fem else -0.06)
				draw_texture_rect(bt, Rect2(org + Vector2(bx, bh * 0.34), bsz), false)
		draw_texture_rect(body, Rect2(org, Vector2(bw, bh)), false)


func _lnw(t: String, sz: int, col: Color = Color.WHITE) -> Label:
	var l := _label(t, sz, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _pp(title: String, ty: String = "", bgtex: String = "") -> VBoxContainer:
	# Panel del perfil: cabecera con pokeball; si ty != "" el fondo toma el color del tipo.
	var pc := PanelContainer.new()
	var base := Color(0.05, 0.1, 0.28, 0.88)
	var bd := Color("#4a6ed0")
	if ty != "":
		var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#a8a878")))
		base = tcol.darkened(0.72)
		bd = tcol
	pc.add_theme_stylebox_override("panel", _sb(base, bd, 2, 14))
	if ty != "":
		var gt := GradientTexture2D.new()
		var tgr := Gradient.new()
		var tc2: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#a8a878")))
		tgr.colors = PackedColorArray([tc2.darkened(0.2), tc2.darkened(0.75)])
		gt.gradient = tgr
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(1, 1)
		var gbg := TextureRect.new()
		gbg.texture = gt
		gbg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gbg.stretch_mode = TextureRect.STRETCH_SCALE
		gbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gbg.modulate = Color(1, 1, 1, 0.9)
		pc.add_child(gbg)
	if bgtex != "":
		var fb := TextureRect.new()
		fb.texture = load("res://scripts/cave_int.gd").tex_in("ui", bgtex)
		fb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fb.stretch_mode = TextureRect.STRETCH_SCALE
		fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pc.add_child(fb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	pc.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var ic := TextureRect.new()
	ic.texture = IC.btn_tex("ball", 24)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.add_child(ic)
	h.add_child(_lnw(title, 22, C_GOLD))
	if bgtex != "":
		var hp := PanelContainer.new()
		hp.add_theme_stylebox_override("panel", _sb(Color(0.03, 0.07, 0.22, 0.8), Color(0, 0, 0, 0), 0, 10))
		hp.add_child(h)
		v.add_child(hp)
	else:
		v.add_child(h)
	v.set_meta("panel", pc)
	return v


func _goals_profile() -> Button:
	var tc: Dictionary = SV.d.get("tc", {"g": 0, "outfit": 0, "hat": 0, "bag": 0})
	var CVT = load("res://scripts/cave_int.gd")
	var first: Button = null
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	prof_box.add_child(top)
	top.add_child(_lnw("Entrenador", 18, Color("#9fb4dc")))
	var le := LineEdit.new()
	le.text = String(SV.d.get("nick", ""))
	le.placeholder_text = L.t("Entrenador")
	le.max_length = 16
	le.custom_minimum_size = Vector2(240, 40)
	le.add_theme_font_size_override("font_size", 20)
	var save_nick := func(_t = ""):
		SV.d["nick"] = le.text.strip_edges()
		SV.save()
		_update_top()
	le.text_submitted.connect(save_nick)
	le.focus_exited.connect(save_nick)
	top.add_child(le)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(220, 40)
	ob.add_theme_font_size_override("font_size", 18)
	ob.focus_mode = Control.FOCUS_ALL
	ob.add_item(L.t("(sin título)"))
	ob.set_item_metadata(0, "")
	var cur_t: String = String(SV.d.get("title", ""))
	var sel := 0
	for t in PG.titles():
		ob.add_item(L.t(String(t)))
		ob.set_item_metadata(ob.item_count - 1, String(t))
		if String(t) == cur_t:
			sel = ob.item_count - 1
	ob.select(sel)
	ob.item_selected.connect(func(idx: int):
		SV.d["title"] = String(ob.get_item_metadata(idx))
		SV.save()
		Aud.sfx("confirm")
		_update_top())
	top.add_child(ob)
	top.add_child(_btn("Ver mi tarjeta de entrenador", _show_card, Vector2(0, 40)))
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof_box.add_child(root)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 1.1
	mid.add_theme_constant_override("separation", 8)
	root.add_child(mid)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
	right.add_theme_constant_override("separation", 8)
	root.add_child(right)
	var sd: int = int(SV.d.get("selected", 25))
	var sty := "normal"
	if SV.dex_by.has(sd) and not SV.dex_by[sd]["types"].is_empty():
		sty = String(SV.dex_by[sd]["types"][0])
	# ---- favoritos (izquierda) ----
	var fv := _pp("Tus 3 Pokémon Favoritos", "", "forest")
	left.add_child(fv.get_meta("panel"))
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 8)
	fv.add_child(fr)
	fav_btns = []
	for i in range(3):
		var slot: int = i
		var dex: int = int(favs[i]) if i < favs.size() else 0
		var b := _btn("", func(): _fav_picker(slot), Vector2(112, 150))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if dex > 0 and SV.dex_by.has(dex):
			var ft: String = String(SV.dex_by[dex]["types"][0])
			for stn in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(stn, StyleBoxEmpty.new())
			b.add_theme_stylebox_override("focus", _sb(Color(0, 0, 0, 0), C_GOLD, 4, 12))
			var cardt := TextureRect.new()
			cardt.texture = load("res://scripts/cave_int.gd").tex_in("ui", "fcard_" + ft)
			cardt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cardt.stretch_mode = TextureRect.STRETCH_SCALE
			cardt.set_anchors_preset(Control.PRESET_FULL_RECT)
			cardt.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cardt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			b.add_child(cardt)
			var pv := Preview.new()
			pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pv.set_anchors_preset(Control.PRESET_FULL_RECT)
			pv.offset_top = 6
			pv.offset_bottom = -30
			b.add_child(pv)
			pv.setup(dex, false, 2.6)
			var ht := TextureRect.new()
			ht.texture = load("res://scripts/cave_int.gd").tex_in("ui", "heart")
			ht.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ht.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ht.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ht)
			_place(ht, Rect2(0.72, 0.04, 0.22, 0.2), 1.0, 1.0)
			var nl := _lnw("%d %s" % [i + 1, _name_of(dex)], 14)
			nl.set_anchors_preset(Control.PRESET_FULL_RECT)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			nl.offset_bottom = -8
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(nl)
		else:
			b.text = "%d\n%s" % [i + 1, L.t("Elegir")]
		fr.add_child(b)
		fav_btns.append(b)
		if first == null:
			first = b
	var fbadges := HBoxContainer.new()
	fbadges.alignment = BoxContainer.ALIGNMENT_CENTER
	fbadges.add_theme_constant_override("separation", 60)
	fv.add_child(fbadges)
	for i in range(3):
		var dx3: int = int(favs[i]) if i < favs.size() else 0
		if dx3 > 0 and SV.dex_by.has(dx3):
			var bi := _medal_icon(String(SV.dex_by[dx3]["types"][0]), 34)
			bi.modulate = Color.WHITE
			fbadges.add_child(bi)
	# ---- estadisticas (izquierda) ----
	var sbox := Control.new()
	sbox.custom_minimum_size = Vector2(400, 400.0 * 326.0 / 552.0)
	sbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(sbox)
	_tex_bg(sbox, "stats_bg")
	var stt := _lnw(L.t("Estadísticas del perfil"), 22, C_GOLD)
	sbox.add_child(stt)
	_place(stt, Rect2(58, 12, 270, 36), 552, 326)
	stt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var st: Dictionary = SV.d["stats"]
	var tm: int = int(st.get("total_time", 0))
	var rows: Array = [
		["Partidas totales", str(int(st.get("runs", 0)))],
		["Tiempo jugado", "%dh %02dm" % [tm / 3600, (tm % 3600) / 60]],
		["Pokémon desbloqueados", "%d / %d" % [SV.owned_count(), SV.dex_list.size()]],
		["Nivel más alto", L.t("Nv. %d") % int(st.get("best_level", 1))],
		["Enemigos derrotados", str(int(st.get("kills", 0)))],
		["Monedas totales", str(int(st.get("coins_total", 0)))],
		["Jefes derrotados", str(int(st.get("bosses", 0)))],
	]
	var cys: Array = [76, 114, 151, 188, 225, 262, 296]
	for ri in range(rows.size()):
		var cy: float = float(cys[ri])
		var l1 := _lnw(L.t(String(rows[ri][0])), 17, Color("#e6eeff"))
		l1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sbox.add_child(l1)
		_place(l1, Rect2(68, cy - 15, 215, 30), 552, 326)
		var l2 := _lnw(String(rows[ri][1]), 17, Color.WHITE)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sbox.add_child(l2)
		_place(l2, Rect2(448, cy - 16, 82, 32), 552, 326)
	# ---- personalizacion (centro) ----
	var cv := _pp("Personalización del perfil")
	mid.add_child(cv.get_meta("panel"))
	for grp in [["hat", "Gorra", 6], ["bag", "Bolso", 6]]:
		var gk: String = String(grp[0])
		cv.add_child(_lnw(L.t(String(grp[1])), 16, Color("#ffd9a0")))
		var r2 := HBoxContainer.new()
		r2.add_theme_constant_override("separation", 6)
		cv.add_child(r2)
		for ci in range(int(grp[2])):
			var idx2: int = ci
			var sw2 := _btn("", func(): _tc_set(gk, idx2), Vector2(58, 54))
			var ic2 := TextureRect.new()
			ic2.texture = CVT.tex_in("ui", "u" + gk + str(ci))
			ic2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic2.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic2.offset_left = 4; ic2.offset_top = 4; ic2.offset_right = -4; ic2.offset_bottom = -4
			ic2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sw2.add_child(ic2)
			if int(tc.get(gk, 0)) == ci:
				_gold_btn(sw2, true)
			r2.add_child(sw2)
	cv.add_child(_lnw(L.t("Tema de la interfaz"), 16, Color("#ffd9a0")))
	var tr2 := HBoxContainer.new()
	tr2.add_theme_constant_override("separation", 8)
	cv.add_child(tr2)
	var cur_th: int = int(SV.d.get("ui_theme", 1))
	for ti in range(UI_THEMES.size()):
		var tix: int = ti
		var tb := _btn("", func(): _apply_ui_theme(tix); _refresh_goals(), Vector2(0, 62))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sel_t: bool = ti == cur_th
		for stn in ["normal", "hover", "pressed", "focus"]:
			tb.add_theme_stylebox_override(stn, _sb(Color(0, 0, 0, 0), Color("#ffd33d") if (sel_t or stn == "focus") else Color(0, 0, 0, 0), 4 if (sel_t or stn == "focus") else 0, 12))
		var tic := TextureRect.new()
		tic.texture = CVT.tex_in("ui", "theme" + str(ti))
		tic.stretch_mode = TextureRect.STRETCH_SCALE
		tic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tic.set_anchors_preset(Control.PRESET_FULL_RECT)
		tic.offset_left = 2; tic.offset_top = 2; tic.offset_right = -2; tic.offset_bottom = -2
		tic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tb.add_child(tic)
		tr2.add_child(tb)
	# ---- medallas (centro) ----
	var mv := _pp("Medallas")
	mid.add_child(mv.get_meta("panel"))
	var tm_got := 0
	for ty0 in TYPE_IDS:
		if _type_medal_got(String(ty0)):
			tm_got += 1
	(mv.get_child(0).get_child(1) as Label).text = L.t("Medallas: %d / %d") % [tm_got, TYPE_IDS.size()]
	var mg := GridContainer.new()
	mg.columns = 9
	mg.add_theme_constant_override("h_separation", 4)
	mg.add_theme_constant_override("v_separation", 4)
	mv.add_child(mg)
	for ty1 in TYPE_IDS:
		mg.add_child(_medal_icon(String(ty1), 46))
	mv.add_child(_btn("Ver todas las medallas", func(): goals_tab = "h"; _show("goals"), Vector2(0, 40)))
	# ---- Tu Pokemon (derecha) ----
	var rw := 300.0
	var rbox := Control.new()
	rbox.custom_minimum_size = Vector2(rw, rw * 352.0 / 391.0)
	right.add_child(rbox)
	_tex_bg(rbox, "tp_" + sty)
	var tt1 := _lnw(L.t("Tu Pokémon"), 22, C_GOLD)
	rbox.add_child(tt1)
	_place(tt1, Rect2(65, 12, 143, 32), 391, 352)
	tt1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ab1 := _flat_btn(func(): _cycle_sel(-1))
	rbox.add_child(ab1)
	_place(ab1, Rect2(17, 124, 52, 82), 391, 352)
	var ab2 := _flat_btn(func(): _cycle_sel(1))
	rbox.add_child(ab2)
	_place(ab2, Rect2(323, 124, 52, 82), 391, 352)
	var pv2 := Preview.new()
	pv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rbox.add_child(pv2)
	_place(pv2, Rect2(73, 50, 250, 165), 391, 352)
	pv2.setup(sd, bool(SV.d.get("shiny_on", false)), 3.4)
	var nm := _lnw(_name_of(sd) if SV.dex_by.has(sd) else "?", 26)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rbox.add_child(nm)
	_place(nm, Rect2(50, 242, 283, 47), 391, 352)
	var mi1 := _medal_icon(sty, 46)
	mi1.modulate = Color.WHITE
	rbox.add_child(mi1)
	_place(mi1, Rect2(109, 293, 46, 46), 391, 352)
	if SV.dex_by.has(sd):
		var tl := _lnw(L.t(String(MD.TYPE_NAME[sty])), 20, Color("#ffe9c0"))
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rbox.add_child(tl)
		_place(tl, Rect2(172, 298, 100, 38), 391, 352)
	# ---- Tipo favorito (derecha) ----
	var cnt: Dictionary = {}
	for k in SV.d["owned"].keys():
		var dk: int = int(k)
		if SV.dex_by.has(dk):
			for t in SV.dex_by[dk]["types"]:
				cnt[String(t)] = int(cnt.get(String(t), 0)) + 1
	var tkeys: Array = cnt.keys()
	tkeys.sort_custom(func(x, y): return int(cnt[x]) > int(cnt[y]))
	var t0: String = String(tkeys[0]) if not tkeys.is_empty() else sty
	var favt: String = String(SV.d.get("fav_type", ""))
	if TYPE_IDS.has(favt):
		t0 = favt
	var fbox := Control.new()
	fbox.custom_minimum_size = Vector2(rw, rw * 274.0 / 389.0)
	right.add_child(fbox)
	_tex_bg(fbox, "tf_" + t0)
	var tt2 := _lnw(L.t("Tipo Favorito"), 22, C_GOLD)
	fbox.add_child(tt2)
	_place(tt2, Rect2(63, 18, 160, 30), 389, 274)
	tt2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var mi2 := _medal_icon(t0, 90)
	mi2.modulate = Color.WHITE
	fbox.add_child(mi2)
	_place(mi2, Rect2(281, 6, 90, 90), 389, 274)
	var tix0: int = TYPE_IDS.find(t0)
	var fa1 := _btn("<", func(): _set_fav_type(String(TYPE_IDS[posmod(tix0 - 1, TYPE_IDS.size())])), Vector2(0, 0))
	fbox.add_child(fa1)
	_place(fa1, Rect2(40, 86, 34, 46), 389, 274)
	var fa2 := _btn(">", func(): _set_fav_type(String(TYPE_IDS[posmod(tix0 + 1, TYPE_IDS.size())])), Vector2(0, 0))
	fbox.add_child(fa2)
	_place(fa2, Rect2(299, 86, 34, 46), 389, 274)
	var tb2 := _lnw("%s (%d)" % [L.t(String(MD.TYPE_NAME[t0])).to_upper(), int(cnt.get(t0, 0))], 17, Color.html(String(MD.TYPE_COLOR.get(t0, "#ffffff"))))
	tb2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tb2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tb2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fbox.add_child(tb2)
	_place(tb2, Rect2(84, 86, 205, 46), 389, 274)
	var others: Array = []
	for ty3 in tkeys:
		if String(ty3) != t0:
			others.append(String(ty3))
	var chips := GridContainer.new()
	chips.columns = 3
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 8)
	fbox.add_child(chips)
	_place(chips, Rect2(14, 150, 362, 100), 389, 274)
	for i in range(mini(others.size(), 6)):
		var tk: String = String(others[i])
		var cl := _lnw("%s %d" % [L.t(String(MD.TYPE_NAME[tk])), int(cnt[tk])], 16, Color.html(String(MD.TYPE_COLOR.get(tk, "#ffffff"))))
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chips.add_child(cl)
	return first


func _set_fav_type(t: String) -> void:
	SV.d["fav_type"] = t
	SV.save()
	Aud.sfx("confirm")
	_refresh_profile()


func _tex_bg(parent: Control, name: String) -> void:
	var tr := TextureRect.new()
	tr.texture = load("res://scripts/cave_int.gd").tex_in("ui", name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(tr)


func _place(c: Control, r: Rect2, w: float, h: float) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.anchor_left = r.position.x / w
	c.anchor_top = r.position.y / h
	c.anchor_right = (r.position.x + r.size.x) / w
	c.anchor_bottom = (r.position.y + r.size.y) / h
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


func _flat_btn(cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	for stn in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(stn, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", _sb(Color(0, 0, 0, 0), C_GOLD, 3, 8))
	b.pressed.connect(cb)
	return b


func _type_medal_got(ty: String) -> bool:
	return int(SV.d["stats"].get("tk_" + ty, 0)) >= ZM.NEED or int(SV.d["stats"].get("zcr_" + ty, 0)) >= 1


func _medal_icon(ty: String, sz: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = load("res://scripts/cave_int.gd").tex_in("medal", ty)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(sz, sz)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var got: bool = _type_medal_got(ty)
	if not got:
		tr.modulate = Color(0.16, 0.2, 0.32, 0.9)
	var n: int = int(SV.d["stats"].get("tk_" + ty, 0))
	tr.tooltip_text = "%s: %s (%d/%d)" % [L.t("Medalla"), L.t(String(MD.TYPE_NAME[ty])), mini(n, ZM.NEED), ZM.NEED]
	return tr


func _tc_set(key: String, v: int) -> void:
	var t2: Dictionary = SV.d.get("tc", {"g": 0, "outfit": 0, "hat": -1, "bag": -1})
	t2[key] = v
	SV.d["tc"] = t2
	SV.save()
	Aud.sfx("confirm")
	_refresh_goals()


func _cycle_sel(dir: int) -> void:
	var keys: Array = []
	for k in SV.d["owned"].keys():
		keys.append(int(k))
	if keys.is_empty():
		return
	keys.sort()
	var i: int = keys.find(int(SV.d.get("selected", 25)))
	SV.d["selected"] = int(keys[posmod(i + dir, keys.size())])
	SV.save()
	Aud.sfx("confirm")
	_update_top()
	_refresh_goals()


# Elegir uno de tus Pokemon para un hueco de favoritos.
func _fav_picker(slot: int) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	v.add_child(_label("Elige un favorito", 30, C_GOLD))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(760, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var keys: Array = []
	for k in SV.d["owned"].keys():
		keys.append(int(k))
	keys.sort()
	var firstb: Button = null
	for dex in keys:
		var d2: int = int(dex)
		if not SV.dex_by.has(d2):
			continue
		var b := _btn("", func(): _set_fav(slot, d2), Vector2(140, 120))
		var pv := Preview.new()
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(pv)
		pv.setup(d2, false, 2.0)
		var nl := _label(_name_of(d2), 14)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nl.set_anchors_preset(Control.PRESET_FULL_RECT)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nl)
		grid.add_child(b)
		if firstb == null:
			firstb = b
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	hb.add_child(_btn("Quitar", func(): _set_fav(slot, 0), Vector2(180, 52)))
	var cancel := _btn_close("Cancelar", func(): gacha_result.visible = false; _refresh_goals(); _fav_focus(slot), Vector2(180, 52))
	hb.add_child(cancel)
	gacha_result.visible = true
	_gf(firstb if firstb != null else cancel)


func _set_fav(slot: int, dex: int) -> void:
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	while favs.size() < 3:
		favs.append(0)
	favs[slot] = dex
	SV.d["favs"] = favs
	SV.save()
	Aud.sfx("confirm")
	gacha_result.visible = false
	_refresh_goals()
	_fav_focus(slot)


# El foco vuelve al favorito que se acaba de elegir (no al nombre ni al principio de la pantalla).
func _fav_focus(slot: int) -> void:
	if slot >= 0 and slot < fav_btns.size() and is_instance_valid(fav_btns[slot]):
		_gf(fav_btns[slot])


# Tarjeta de entrenador: lo que antes era "ver mi perfil publico", pero sin conexion.
func _show_card() -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(620, 0)
	pc.add_child(v)
	var nm := _label(_nick(), 40, C_GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var tt: String = String(SV.d.get("title", ""))
	var tl := _label(L.t(tt) if tt != "" else L.t("(sin título)"), 24, Color("#c8d6ee"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var pr := HBoxContainer.new()
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_theme_constant_override("separation", 14)
	v.add_child(pr)
	var sd: int = int(SV.d.get("selected", 25))
	var main_pv := Preview.new()
	main_pv.custom_minimum_size = Vector2(180, 150)
	pr.add_child(main_pv)
	main_pv.setup(sd, bool(SV.d.get("shiny_on", false)), 4.0)
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	for i in range(3):
		var dex: int = int(favs[i]) if i < favs.size() else 0
		if dex > 0 and SV.dex_by.has(dex):
			var fp := Preview.new()
			fp.custom_minimum_size = Vector2(100, 90)
			pr.add_child(fp)
			fp.setup(dex, false, 2.0)
	var st: Dictionary = SV.d["stats"]
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	var bt: int = int(st.get("best_time", 0))
	g.add_child(_stat_cell(L.t("Partidas"), str(int(st.get("runs", 0)))))
	g.add_child(_stat_cell(L.t("Mejor tiempo"), "%02d:%02d" % [bt / 60, bt % 60]))
	g.add_child(_stat_cell(L.t("Mejor nivel"), str(int(st.get("best_level", 0)))))
	g.add_child(_stat_cell(L.t("Derrotados"), str(int(st.get("kills", 0)))))
	g.add_child(_stat_cell(L.t("Jefes"), str(int(st.get("bosses", 0)))))
	g.add_child(_stat_cell(L.t("Cofres"), str(int(st.get("chests", 0)))))
	g.add_child(_stat_cell(L.t("Pokémon"), "%d / %d" % [SV.owned_count(), SV.dex_list.size()]))
	g.add_child(_stat_cell(L.t("Logros"), "%d / %d" % [SV.d.get("ach", {}).size(), PG.list().size()]))
	var tm: int = int(st.get("total_time", 0))
	g.add_child(_stat_cell(L.t("Tiempo jugado"), "%dh %02dm" % [tm / 3600, (tm % 3600) / 60]))
	var ok := _btn_close("Cerrar", func(): gacha_result.visible = false; _refresh_goals(), Vector2(220, 52))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(ok)
	v.add_child(hb)
	gacha_result.visible = true
	_gf(ok)


# Ranking local: tus 10 mejores partidas (tiempo aguantado) guardadas en este dispositivo.
func _goals_records() -> Button:
	_goal_sec("Tus mejores partidas")
	var top: Array = SV.d.get("top", [])
	if top.is_empty():
		_goal_info("Aún no hay partidas. ¡Juega una para aparecer aquí!")
		return null
	for i in range(top.size()):
		var e: Dictionary = top[i]
		var rc := PanelContainer.new()
		rc.add_theme_stylebox_override("panel", _goal_card_sb(i == 0))
		goals_box.add_child(rc)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		rc.add_child(row)
		# Puesto: laureles de oro, plata y bronce (con corona el primero); el resto, en una pastilla
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(104, 54)
		row.add_child(badge)
		if i < 3:
			var lau := SetGlyph.new("laurel", 54.0, [Color("#f6c433"), Color("#cfe0f5"), Color("#e39a55")][i])
			lau.crown = i == 0
			lau.set_anchors_preset(Control.PRESET_FULL_RECT)
			badge.add_child(lau)
		else:
			var bp := Panel.new()
			bp.add_theme_stylebox_override("panel", _sb(Color("#1c3e94"), SET_LINE, 2, 18))
			bp.anchor_right = 1.0
			bp.anchor_top = 0.5
			bp.anchor_bottom = 0.5
			bp.offset_left = 6.0
			bp.offset_right = -6.0
			bp.offset_top = -17.0
			bp.offset_bottom = 17.0
			badge.add_child(bp)
		var rk := _label("#%d" % (i + 1), 24, Color.WHITE)
		rk.autowrap_mode = TextServer.AUTOWRAP_OFF
		rk.set_anchors_preset(Control.PRESET_FULL_RECT)
		rk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(rk)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(96, 72)
		row.add_child(pv)
		pv.fit_k = 1.3
		pv.setup(int(e.get("dex", 25)), false, 4.0)
		var sep := ColorRect.new()
		sep.color = Color(1, 1, 1, 0.35)
		sep.custom_minimum_size = Vector2(2, 40)
		sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sep)
		var tm: int = int(e["time"])
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_theme_constant_override("separation", 0)
		row.add_child(col)
		var nm: String = _name_of(int(e.get("dex", 25))) if SV.dex_by.has(int(e.get("dex", 25))) else "?"
		var th := HBoxContainer.new()
		th.add_theme_constant_override("separation", 8)
		col.add_child(th)
		th.add_child(IC.rect("clock", 26))
		var tl := _label("%02d:%02d" % [tm / 60, tm % 60], 24, C_GOLD)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		th.add_child(tl)
		var nl := _label("·  " + nm, 24)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		th.add_child(nl)
		col.add_child(_label(L.t("Nv. %d") % int(e["level"]) + "  ·  " + L.t("Derrotados: %d") % int(e["kills"]) + "  ·  " + String(e.get("date", "")), 16, Color("#dfe8ff")))
		row.add_child(SetGlyph.new("stripes", 34.0))
		row.add_child(SetGlyph.new("watermark", 36.0))
	return null


func _goals_titles() -> Button:
	var cur_t: String = String(SV.d.get("title", ""))
	goals_box.add_child(_label(L.t("Título en uso: %s") % (L.t(cur_t) if cur_t != "" else L.t("ninguno")), 28, C_GOLD))
	var first: Button = null
	var nb := _btn("Sin título", func(): _set_title(""), Vector2(220, 46))
	goals_box.add_child(nb)
	first = nb
	var ach: Dictionary = SV.d.get("ach", {})
	for a in PG.list():
		var t: String = String(a["title"])
		if t == "":
			continue
		var done: bool = ach.has(String(a["id"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		goals_box.add_child(row)
		var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 36)
		mi.custom_minimum_size.x = 48
		row.add_child(mi)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label(L.t(t), 24, C_GOLD if done else Color("#8a94b0")))
		col.add_child(_label(L.t("Logro: %s") % PG.name_of(a), 16, Color("#c8d6ee")))
		var b: Button
		if not done:
			b = _btn("Bloqueado", func(): pass, Vector2(170, 46))
			b.disabled = true
		elif cur_t == t:
			b = _btn("En uso", func(): pass, Vector2(170, 46))
			b.disabled = true
		else:
			b = _btn("Usar", func(): _set_title(t), Vector2(170, 46))
		row.add_child(b)
	return first


func _set_title(t: String) -> void:
	SV.d["title"] = t
	SV.save()
	Aud.sfx("confirm")
	_refresh_goals()


# ---------------------------------------------------------------
# Ajustes
# ---------------------------------------------------------------
var set_tab := 0
var set_tabs_row: HBoxContainer
var listening := ""
var last_act := ""
var import_armed := false
const SET_TABS := ["Sonido", "Gráficos", "Controles", "Cuenta", "Acerca de"]
const REPO_URL := "https://github.com/JayElDragon/poke-survivor"
# Enlace de donaciones (Ko-fi).
const SUPPORT_URL := "https://ko-fi.com/jayeldragon"
const SET_TAB_ICON := ["speaker", "image", "pad", "card", "info"]
const SET_SEC_ICON := {"Sonido": "phones", "Idioma": "globe", "Calidad": "spark", "Pantalla": "monitor", "En móvil o tableta": "monitor", "Mando": "pad", "Cuenta": "card", "Copia de seguridad": "save", "Zona peligrosa": "warn"}
const SET_LINE := Color("#7fa8f5")


# Dibujos vectoriales de la pantalla de Ajustes (iconos que no existen como sprite).
class SetGlyph extends Control:
	var kind := ""
	var col := Color.WHITE
	var crown := false

	func _init(k: String = "", px: float = 28.0, c: Color = Color.WHITE) -> void:
		kind = k
		col = c
		custom_minimum_size = Vector2(px, px)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _p(pts: Array, k: float, o: Vector2, c: Color) -> void:
		var out := PackedVector2Array()
		for q in pts:
			out.append(o + (q as Vector2) * k)
		draw_colored_polygon(out, c)

	func _draw() -> void:
		var k: float = minf(size.x, size.y) / 28.0
		var o: Vector2 = size * 0.5
		match kind:
			"speaker", "mute":
				_p([Vector2(-11, -4), Vector2(-5, -4), Vector2(2, -10), Vector2(2, 10), Vector2(-5, 4), Vector2(-11, 4)], k, o, col)
				if kind == "mute":
					draw_line(o + Vector2(-11, 10) * k, o + Vector2(11, -10) * k, col, 3.0 * k)
				else:
					draw_arc(o + Vector2(2, 0) * k, 5.0 * k, -0.9, 0.9, 10, col, 2.0 * k)
					draw_arc(o + Vector2(2, 0) * k, 9.5 * k, -0.9, 0.9, 12, col, 2.0 * k)
			"music":
				draw_circle(o + Vector2(-7, 8) * k, 4.5 * k, col)
				draw_circle(o + Vector2(7, 5) * k, 4.5 * k, col)
				_p([Vector2(-4, 8), Vector2(-4, -8), Vector2(11, -11), Vector2(11, 5), Vector2(9, 5), Vector2(9, -6), Vector2(-2, -4), Vector2(-2, 8)], k, o, col)
			"spark":
				var y := Color("#ffd23f")
				for st in [[Vector2(-3, 1), 10.0], [Vector2(8, -8), 5.0], [Vector2(9, 9), 4.0]]:
					var c0: Vector2 = st[0]
					var r: float = st[1]
					_p([c0 + Vector2(0, -r), c0 + Vector2(r * 0.25, -r * 0.25), c0 + Vector2(r, 0), c0 + Vector2(r * 0.25, r * 0.25), c0 + Vector2(0, r), c0 + Vector2(-r * 0.25, r * 0.25), c0 + Vector2(-r, 0), c0 + Vector2(-r * 0.25, -r * 0.25)], k, o, y)
			"image":
				draw_rect(Rect2(o + Vector2(-12, -10) * k, Vector2(24, 20) * k), col, false, 2.5 * k)
				_p([Vector2(-10, 8), Vector2(-3, -2), Vector2(2, 4), Vector2(5, 1), Vector2(10, 8)], k, o, col)
				draw_circle(o + Vector2(5, -5) * k, 2.5 * k, col)
			"pad":
				_p([Vector2(-8, -7), Vector2(8, -7), Vector2(13, 3), Vector2(12, 8), Vector2(8, 8), Vector2(4, 3), Vector2(-4, 3), Vector2(-8, 8), Vector2(-12, 8), Vector2(-13, 3)], k, o, col)
				var dk := Color("#17307f")
				draw_rect(Rect2(o + Vector2(-9, -3) * k, Vector2(6, 2) * k), dk)
				draw_rect(Rect2(o + Vector2(-7, -5) * k, Vector2(2, 6) * k), dk)
				draw_circle(o + Vector2(5, -3) * k, 1.5 * k, dk)
				draw_circle(o + Vector2(8, -1) * k, 1.5 * k, dk)
			"card":
				draw_rect(Rect2(o + Vector2(-13, -9) * k, Vector2(26, 18) * k), col)
				var bk := Color("#17307f")
				draw_circle(o + Vector2(-6, -2) * k, 3.0 * k, bk)
				draw_rect(Rect2(o + Vector2(-10, 2) * k, Vector2(8, 4) * k), bk)
				for ly in [-5.0, -1.0, 3.0]:
					draw_rect(Rect2(o + Vector2(1, ly) * k, Vector2(9, 2) * k), bk)
			"info":
				draw_circle(o, 12.0 * k, col)
				var ib := Color("#17307f")
				draw_circle(o + Vector2(0, -6) * k, 2.0 * k, ib)
				draw_rect(Rect2(o + Vector2(-2, -2) * k, Vector2(4, 10) * k), ib)
			"phones":
				var g := Color("#ffc83d")
				draw_arc(o + Vector2(0, 1) * k, 10.0 * k, PI, TAU, 18, g, 3.0 * k)
				draw_rect(Rect2(o + Vector2(-13, 1) * k, Vector2(6, 10) * k), g)
				draw_rect(Rect2(o + Vector2(7, 1) * k, Vector2(6, 10) * k), g)
			"globe":
				draw_arc(o, 11.0 * k, 0.0, TAU, 24, col, 2.5 * k)
				draw_line(o + Vector2(-11, 0) * k, o + Vector2(11, 0) * k, col, 2.0 * k)
				draw_line(o + Vector2(0, -11) * k, o + Vector2(0, 11) * k, col, 2.0 * k)
				draw_arc(o, 5.0 * k, 0.0, TAU, 18, col, 1.5 * k)
			"monitor":
				draw_rect(Rect2(o + Vector2(-13, -10) * k, Vector2(26, 16) * k), col, false, 2.5 * k)
				draw_rect(Rect2(o + Vector2(-2, 6) * k, Vector2(4, 4) * k), col)
				draw_rect(Rect2(o + Vector2(-7, 10) * k, Vector2(14, 2) * k), col)
			"save":
				draw_rect(Rect2(o + Vector2(-11, -11) * k, Vector2(22, 22) * k), col)
				draw_rect(Rect2(o + Vector2(-6, -11) * k, Vector2(12, 8) * k), Color("#17307f"))
				draw_rect(Rect2(o + Vector2(-7, 2) * k, Vector2(14, 9) * k), Color("#17307f"))
			"warn":
				_p([Vector2(0, -12), Vector2(13, 11), Vector2(-13, 11)], k, o, Color("#ffc83d"))
				draw_rect(Rect2(o + Vector2(-1.5, -4) * k, Vector2(3, 8) * k), Color("#2b1a00"))
				draw_circle(o + Vector2(0, 7.5) * k, 1.8 * k, Color("#2b1a00"))
			"x":
				draw_line(o + Vector2(-8, -8) * k, o + Vector2(8, 8) * k, col, 4.0 * k)
				draw_line(o + Vector2(8, -8) * k, o + Vector2(-8, 8) * k, col, 4.0 * k)
			"pointer":
				draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(0, 9)]), Color("#f6c433"))
			"laurel":
				var lc: Vector2 = size * 0.5 + Vector2(0.0, 2.0)
				for sd in [-1.0, 1.0]:
					for li in range(6):
						var la: float = -0.9 + float(li) * 0.36
						var lp: Vector2 = lc + Vector2(sd * cos(la) * 38.0, sin(la) * 20.0)
						var ld: Vector2 = Vector2(-sd * sin(la) * 38.0, cos(la) * 20.0).normalized()
						var ls: Vector2 = ld.orthogonal() * 3.5
						draw_colored_polygon(PackedVector2Array([lp - ld * 6.0, lp + ls, lp + ld * 6.0, lp - ls]), col)
				if crown:
					var cc := Vector2(size.x * 0.5, 7.0)
					draw_colored_polygon(PackedVector2Array([cc + Vector2(-10, 6), cc + Vector2(-11, -5), cc + Vector2(-4, 0), cc + Vector2(0, -7), cc + Vector2(4, 0), cc + Vector2(11, -5), cc + Vector2(10, 6)]), col)
			"stripes_dim":
				for i in range(2):
					var dx: float = -10.0 + float(i) * 11.0
					_p([Vector2(dx, 10), Vector2(dx + 6, 10), Vector2(dx + 14, -10), Vector2(dx + 8, -10)], k, o, Color(1, 1, 1, 0.14))
			"swap":
				draw_arc(o, 9.0 * k, -2.6, 0.2, 14, col, 2.5 * k)
				draw_arc(o, 9.0 * k, 0.55, 3.35, 14, col, 2.5 * k)
				_p([Vector2(5, 1), Vector2(13, 1), Vector2(9, 6)], k, o, col)
				_p([Vector2(-5, -1), Vector2(-13, -1), Vector2(-9, -6)], k, o, col)
			"play":
				_p([Vector2(-8, -12), Vector2(11, 0), Vector2(-8, 12)], k, o, col)
				_p([Vector2(-4, -5), Vector2(4, 0), Vector2(-4, 5)], k, o, Color("#f6c433"))
			"clip":
				draw_rect(Rect2(o + Vector2(-9, -9) * k, Vector2(18, 21) * k), Color("#f4f6fb"))
				draw_rect(Rect2(o + Vector2(-4, -12) * k, Vector2(8, 5) * k), Color("#c9402f"))
				for ly in [-3.0, 2.0, 7.0]:
					draw_rect(Rect2(o + Vector2(-6, ly) * k, Vector2(12, 2) * k), Color("#17307f"))
			"dot":
				draw_circle(o, 5.0 * k * 28.0 / 12.0, Color("#f6c433"))
			"stripes":
				var st := Color("#f6c433")
				for i in range(2):
					var sx: float = -10.0 + float(i) * 11.0
					_p([Vector2(sx, 10), Vector2(sx + 6, 10), Vector2(sx + 14, -10), Vector2(sx + 8, -10)], k, o, st)
			"watermark":
				var wc := Color(1, 1, 1, 0.16)
				draw_arc(o, 11.0 * k, 0.0, TAU, 24, wc, 3.0 * k)
				draw_line(o - Vector2(11, 0) * k, o + Vector2(11, 0) * k, wc, 2.5 * k)
				draw_circle(o, 3.5 * k, wc)


# Fondo de Ajustes: Poke Balls tenues, nubes, montanas, pinos, hojas y el adorno de abajo.
class SetArt extends Control:
	var front := false   # true: solo el adorno de abajo, por encima del contenido
	var lift := 4.0      # altura del adorno sobre el borde inferior
	var corners := false   # rocas y hojas en las esquinas (portada)

	func _init(on_top: bool = false) -> void:
		front = on_top
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _ball(c: Vector2, r: float, col: Color) -> void:
		draw_arc(c, r * 0.8, 0.0, TAU, 40, col, r * 0.4)
		draw_line(c - Vector2(r, 0.0), c - Vector2(r * 0.34, 0.0), col, r * 0.18)
		draw_line(c + Vector2(r * 0.34, 0.0), c + Vector2(r, 0.0), col, r * 0.18)
		draw_circle(c, r * 0.16, col)

	func _cloud(c: Vector2, k: float, col: Color) -> void:
		draw_rect(Rect2(c + Vector2(-60, -8) * k, Vector2(120, 8) * k), col)
		draw_rect(Rect2(c + Vector2(-38, -18) * k, Vector2(70, 10) * k), col)
		draw_rect(Rect2(c + Vector2(-16, -28) * k, Vector2(30, 10) * k), col)

	func _leaf(c: Vector2, ang: float, ln: float, col: Color) -> void:
		var d: Vector2 = Vector2.from_angle(ang)
		var s: Vector2 = d.orthogonal() * ln * 0.22
		draw_colored_polygon(PackedVector2Array([c, c + d * ln * 0.45 + s, c + d * ln, c + d * ln * 0.45 - s]), col)

	func _bush(c: Vector2, ln: float, flip: float) -> void:
		for i in range(7):
			var a: float = -PI * 0.5 + (float(i) - 3.0) * 0.36 * flip
			_leaf(c, a, ln * (0.72 + 0.28 * sin(float(i) * 2.1)), Color("#2f9c3d") if i % 2 == 0 else Color("#58c648"))

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if front:
			if corners:
				for sd in [0.0, 1.0]:
					var cx: float = 40.0 if sd == 0.0 else w - 40.0
					draw_colored_polygon(PackedVector2Array([Vector2(cx - 34.0, h + 8.0), Vector2(cx - 24.0, h - 24.0), Vector2(cx + 2.0, h - 36.0), Vector2(cx + 28.0, h - 22.0), Vector2(cx + 36.0, h + 8.0)]), Color("#6d7680"))
					_bush(Vector2(cx + (44.0 if sd == 0.0 else -44.0), h + 8.0), 46.0, 1.0)
			_ornament(w, h)
			return
		var base: float = h - 18.0
		var band := Color(0.27, 0.4, 0.8, 0.32)
		var x := 60.0
		while x < w:
			_ball(Vector2(x, 84.0), 13.0, Color(1, 1, 1, 0.035))
			x += 130.0
		_ball(Vector2(w - 170.0, h - 170.0), 96.0, Color(0.45, 0.6, 1.0, 0.13))
		_cloud(Vector2(w * 0.3, h - 120.0), 1.0, band)
		_cloud(Vector2(w * 0.62, h - 136.0), 1.1, band)
		_cloud(Vector2(w * 0.45, h - 76.0), 0.7, band)
		var far := PackedVector2Array([Vector2(0, base)])
		for i in range(13):
			var fx: float = w * float(i) / 12.0
			far.append(Vector2(fx, base - (i % 2) * 54.0 - 16.0))
		far.append(Vector2(w, base))
		draw_colored_polygon(far, Color(0.1, 0.17, 0.5, 0.75))
		var pine := Color(0.06, 0.12, 0.38, 0.92)
		x = 8.0
		var n := 0
		while x < w:
			var ph: float = 26.0 + float((n * 7) % 3) * 12.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 12.0, base), Vector2(x, base - ph), Vector2(x + 12.0, base)]), pine)
			x += 44.0
			n += 1
		_bush(Vector2(46.0, base), 62.0, 1.0)
		_bush(Vector2(112.0, base), 42.0, -1.0)
		_bush(Vector2(w - 46.0, base), 66.0, -1.0)
		_bush(Vector2(w - 116.0, base), 44.0, 1.0)

	# Adorno central de abajo
	func _ornament(w: float, h: float) -> void:
		var bc := Vector2(w * 0.5, h - lift)
		for sd in [-1.0, 1.0]:
			for j in range(3):
				var px: float = bc.x + sd * (34.0 + float(j) * 26.0)
				draw_colored_polygon(PackedVector2Array([Vector2(px, bc.y - 10.0), Vector2(px + sd * 16.0, bc.y - 10.0), Vector2(px + sd * 26.0, bc.y + 6.0), Vector2(px + sd * 10.0, bc.y + 6.0)]), Color("#f6c433"))
		draw_circle(bc, 26.0, Color("#dfe9ff"))
		draw_circle(bc, 22.0, Color("#1a1d29"))
		draw_circle(bc, 20.0, Color("#f5f6f8"))
		var top := PackedVector2Array()
		for i in range(17):
			top.append(bc + Vector2.from_angle(PI + PI * float(i) / 16.0) * 20.0)
		draw_colored_polygon(top, Color("#e23b3b"))
		draw_line(bc - Vector2(20.0, 0.0), bc + Vector2(20.0, 0.0), Color("#1a1d29"), 4.0)
		draw_circle(bc, 7.0, Color("#1a1d29"))
		draw_circle(bc, 4.0, Color("#f5f6f8"))


static var _set_grabber: Texture2D = null


# Tirador de los deslizadores: una Poke Ball.
static func _grabber_tex() -> Texture2D:
	if _set_grabber != null:
		return _set_grabber
	var n := 34
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(float(n) * 0.5 - 0.5, float(n) * 0.5 - 0.5)
	for py in range(n):
		for px in range(n):
			var p := Vector2(px, py)
			var d: float = p.distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d <= 16.5:
				col = Color("#e8eefc")
			if d <= 14.5:
				col = Color("#e23b3b") if p.y < c.y else Color("#f5f6f8")
				if absf(p.y - c.y) <= 1.5:
					col = Color("#1a1d29")
			if d <= 6.0:
				col = Color("#1a1d29")
			if d <= 3.5:
				col = Color("#f5f6f8")
			img.set_pixel(px, py, col)
	_set_grabber = ImageTexture.create_from_image(img)
	return _set_grabber


func _set_slider(sl: HSlider) -> void:
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	var track := _sb(Color("#0b1a55"), SET_LINE, 2, 7)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	var fill := _sb(Color("#f6c433"), Color.TRANSPARENT, 0, 6)
	fill.content_margin_top = 5
	fill.content_margin_bottom = 5
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	sl.add_theme_icon_override("grabber", _grabber_tex())
	sl.add_theme_icon_override("grabber_highlight", _grabber_tex())


func _set_pill(txt: String) -> Label:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(84, 0)
	var sb := _sb(Color("#0f2268"), SET_LINE, 2, 8)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	var l := _label(txt, 20)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return l


# Fila con fondo oscuro de la pantalla de Ajustes.
func _set_row_panel() -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(Color(0.03, 0.06, 0.24, 0.62), Color.TRANSPARENT, 0, 10)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	settings_box.add_child(pc)
	return pc


# Boton de Ajustes: "gold" (elegido o principal) o "red"; el azul sale del tema de la pantalla.
func _set_btn(b: Button, kind: String) -> void:
	var c := Color("#f6c433") if kind == "gold" else Color("#c92a44")
	var edge := Color("#fff0a8") if kind == "gold" else Color("#ffd6dc")
	var fc := Color("#2b1a00") if kind == "gold" else Color.WHITE
	b.add_theme_stylebox_override("normal", _sb(c, edge, 3, 12))
	b.add_theme_stylebox_override("hover", _sb(c.lightened(0.1), edge, 3, 12))
	b.add_theme_stylebox_override("pressed", _sb(c.darkened(0.1), edge, 3, 12))
	b.add_theme_stylebox_override("focus", _sb(c.lightened(0.1), Color.WHITE, 4, 12))
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fc)


# Icono a la izquierda del texto de un boton.
func _btn_glyph(b: Button, kind: String, col: Color) -> void:
	var g := SetGlyph.new(kind, 26.0, col)
	g.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	g.offset_left = 14.0
	g.offset_right = 40.0
	g.offset_top = -13.0
	g.offset_bottom = 13.0
	b.add_child(g)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb = b.get_theme_stylebox(st)
		if sb != null:
			var s2: StyleBox = sb.duplicate()
			s2.content_margin_left = 46.0
			b.add_theme_stylebox_override(st, s2)


func _set_theme() -> Theme:
	var th := Theme.new()
	th.set_stylebox("normal", "Button", _sb(Color("#1c3e94"), SET_LINE, 3, 12))
	th.set_stylebox("hover", "Button", _sb(Color("#2a54bc"), Color("#b5cdfb"), 3, 12))
	th.set_stylebox("pressed", "Button", _sb(Color("#142f75"), SET_LINE, 3, 12))
	th.set_stylebox("focus", "Button", _sb(Color("#2a54bc"), Color.WHITE, 4, 12))
	th.set_stylebox("disabled", "Button", _sb(Color("#1c2c5c"), Color("#47598c"), 2, 12))
	th.set_color("font_color", "Button", Color.WHITE)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_stylebox("scroll", "VScrollBar", _sb(Color(0.03, 0.06, 0.24, 0.7), Color.TRANSPARENT, 0, 8))
	th.set_stylebox("grabber", "VScrollBar", _sb(SET_LINE, Color.TRANSPARENT, 0, 8))
	th.set_stylebox("grabber_highlight", "VScrollBar", _sb(Color("#b5cdfb"), Color.TRANSPARENT, 0, 8))
	th.set_stylebox("grabber_pressed", "VScrollBar", _sb(Color("#f6c433"), Color.TRANSPARENT, 0, 8))
	return th


func _build_settings() -> void:
	var s: Control = _screen("settings")
	var ins: Vector4 = DSP.insets(get_tree())
	s.add_theme_constant_override("margin_left", 10 + int(ins.x))
	s.add_theme_constant_override("margin_right", 10 + int(ins.z))
	s.add_theme_constant_override("margin_top", 8 + int(ins.y))
	s.add_theme_constant_override("margin_bottom", 10 + int(ins.w))
	var pc := PanelContainer.new()
	pc.theme = _set_theme()
	var fr := _sb(Color("#17307f"), SET_LINE, 4, 20)
	fr.content_margin_left = 16
	fr.content_margin_right = 16
	fr.content_margin_top = 10
	fr.content_margin_bottom = 22
	pc.add_theme_stylebox_override("panel", fr)
	s.add_child(pc)
	pc.add_child(SetArt.new())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	var hd := HBoxContainer.new()
	v.add_child(hd)
	var rib := PanelContainer.new()
	var rs := _sb(Color("#2a56c4"), Color("#b5cdfb"), 3, 22)
	rs.content_margin_top = 2
	rs.content_margin_bottom = 2
	rs.content_margin_left = 10
	rs.content_margin_right = 16
	rib.add_theme_stylebox_override("panel", rs)
	hd.add_child(rib)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	rib.add_child(rh)
	rh.add_child(IC.rect("gear", 42))
	var tt := _label("Ajustes", 36)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rh.add_child(tt)
	var rb := IC.rect("ball", 24)
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh.add_child(rb)
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(hsp)
	var cl := _btn_close("Cerrar", func(): _leave(), Vector2(160, 48))
	_set_btn(cl, "red")
	_btn_glyph(cl, "x", Color.WHITE)
	hd.add_child(cl)
	set_tabs_row = HBoxContainer.new()
	set_tabs_row.add_theme_constant_override("separation", 10)
	v.add_child(set_tabs_row)
	var body := PanelContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bs := _sb(Color(0.08, 0.15, 0.47, 0.42), SET_LINE, 3, 16)
	bs.content_margin_right = 6
	body.add_theme_stylebox_override("panel", bs)
	v.add_child(body)
	var ssc := ScrollContainer.new()
	ssc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(ssc)
	var bm := MarginContainer.new()
	bm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bm.add_theme_constant_override("margin_right", 26)   # la barra de desplazamiento no tapa las filas
	ssc.add_child(bm)
	settings_box = VBoxContainer.new()
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_theme_constant_override("separation", 8)
	bm.add_child(settings_box)
	pc.add_child(SetArt.new(true))


# Pantalla de novedades: lista de versiones a la izquierda y el detalle de la elegida a la derecha.
func _nsb(bg: Color, border: Color, bw: int = 3, rad: int = 10) -> StyleBoxFlat:
	var sb := _sb(bg, border, bw, rad)
	sb.corner_detail = 2   # esquinas escalonadas, como pixel art
	return sb


func _build_news() -> void:
	var s: Control = _screen("news")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	s.add_child(v)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	v.add_child(hd)
	var ban := PanelContainer.new()
	ban.add_theme_stylebox_override("panel", _nsb(Color("#b52a35"), Color("#ffd23f"), 3, 12))
	hd.add_child(ban)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	ban.add_child(bh)
	bh.add_child(IC.rect("ball", 42))
	var tt := _label("Novedades", 38, C_GOLD)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	bh.add_child(tt)
	var sp := PanelContainer.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#3f6db0")))
	hd.add_child(sp)
	var st := _label("Consulta las últimas actualizaciones, cambios y contenido nuevo.", 19)
	st.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp.add_child(st)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	v.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 240
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	var lp := PanelContainer.new()
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lp.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#3f6db0")))
	left.add_child(lp)
	var lsc := ScrollContainer.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(lsc)
	news_list = VBoxContainer.new()
	news_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_list.add_theme_constant_override("separation", 6)
	lsc.add_child(news_list)
	left.add_child(_btn_close("Cerrar", func(): _leave(), Vector2(0, 52)))
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#3f6db0")))
	body.add_child(rp)
	news_scroll = ScrollContainer.new()
	news_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	news_scroll.focus_mode = Control.FOCUS_ALL
	rp.add_child(news_scroll)
	var nm := MarginContainer.new()
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_constant_override("margin_right", 36)   # la barra de desplazamiento no tapa las tarjetas
	news_scroll.add_child(nm)
	news_box = VBoxContainer.new()
	news_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_box.add_theme_constant_override("separation", 10)
	nm.add_child(news_box)


# Pantalla "Apoyar el proyecto": donacion voluntaria, sin ventajas en el juego. Fondo: la fogata de noche.
func _support_section(b: VBoxContainer, title: String, icon: String, text: String, col: Color) -> void:
	var hd := HBoxContainer.new()
	b.add_child(hd)
	var tab := PanelContainer.new()
	tab.add_theme_stylebox_override("panel", _nsb(Color("#1f4a90"), Color("#3f6db0"), 2, 8))
	hd.add_child(tab)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	tab.add_child(th)
	th.add_child(IC.rect(icon, 26))
	var tl := _label(title, 21, C_GOLD)
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	th.add_child(tl)
	b.add_child(_label(text, 18, col))


func _build_support() -> void:
	var s: Control = _screen("support")
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _nsb(Color("#0e1a33"), Color("#9cc8ff"), 3, 12))
	s.add_child(pc)
	var holder := Control.new()
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(holder)
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/support_art.png")
	art.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	art.offset_left = -606.0
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	pc.add_child(body)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	body.add_child(v)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 400
	body.add_child(right)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(cr)
	cr.add_child(_btn_close("Cerrar", func(): _leave(), Vector2(130, 44)))
	var ban := PanelContainer.new()
	ban.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ban.add_theme_stylebox_override("panel", _nsb(Color("#6b4423"), Color("#3a2410"), 3, 10))
	v.add_child(ban)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	ban.add_child(bh)
	bh.add_child(IC.rect("ball", 40))
	var tt := _label("Apoyar el proyecto", 34, C_GOLD)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	bh.add_child(tt)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var sm := MarginContainer.new()
	sm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sm.add_theme_constant_override("margin_right", 8)
	sc.add_child(sm)
	var b := VBoxContainer.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_constant_override("separation", 8)
	sm.add_child(b)
	b.add_child(_label("Pokémon Survivors es y seguirá siendo gratis, sin anuncios ni compras. Si quieres que haga posible tener modo multijugador o jugar en línea, puedes hacer una donación voluntaria: todo el dinero va a los gastos del proyecto, nada más.", 19))
	var nop := PanelContainer.new()
	nop.add_theme_stylebox_override("panel", _nsb(Color("#16233f"), Color("#9cc8ff"), 2, 8))
	b.add_child(nop)
	var nr := HBoxContainer.new()
	nr.add_theme_constant_override("separation", 10)
	nop.add_child(nr)
	nr.add_child(IC.rect("heart", 26))
	var nl := _label("Donar no da ninguna ventaja en el juego.", 18, Color("#dfe8ff"))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nr.add_child(nl)
	_support_section(b, "Para qué servirían los servidores", "m_coop", "Los servidores ayudarían mucho a subir todo esto a una nube para que los jugadores puedan guardar sus partidas y jugar en línea, y permitirían desarrollar modos multijugador.", Color.WHITE)
	_support_section(b, "Planes a futuro", "contract", "Si apoyan el proyecto, desarrollaré todo eso. Ahora mismo no puedo hacerlo por falta de fondos.", C_GOLD)
	var db := _btn("Donar en Ko-fi", func(): OS.shell_open(SUPPORT_URL), Vector2(420, 64))
	db.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	db.icon = IC.tex("heart", IC.scale_for("heart", 34))
	db.add_theme_font_size_override("font_size", 28)
	for st in ["normal", "hover", "pressed", "focus"]:
		var yc := Color("#e0334f") if st != "hover" else Color("#ff4f6a")
		db.add_theme_stylebox_override(st, _nsb(yc, Color("#ffd6dc") if st != "focus" else Color.WHITE, 4 if st == "focus" else 3, 14))
	for fc in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		db.add_theme_color_override(fc, Color.WHITE)
	v.add_child(db)
	support_focus = db


func _refresh_support() -> void:
	focus_first = support_focus


# Mando y teclado: arriba/abajo cambia de version; a la derecha entras al detalle y ahi arriba/abajo lo desplaza.
func _news_nav(event: InputEvent) -> bool:
	var dn: bool = event.is_action_pressed("ui_down", true)
	var up: bool = event.is_action_pressed("ui_up", true)
	var fo: Control = get_viewport().gui_get_focus_owner()
	if fo == news_scroll:
		if dn or up:
			news_scroll.scroll_vertical += 130 if dn else -130
			return true
		if event.is_action_pressed("ui_left"):
			news_btns[news_sel].grab_focus()
			return true
		return false
	if not news_btns.has(fo):
		return false
	if event.is_action_pressed("ui_right"):
		news_scroll.grab_focus()
		return true
	if dn or up:
		var ni: int = clampi(news_sel + (1 if dn else -1), 0, news_btns.size() - 1)
		_news_select(ni)
		news_btns[ni].grab_focus()
		return true
	return false


func _refresh_news() -> void:
	for c in news_list.get_children():
		news_list.remove_child(c)
		c.queue_free()
	news_btns = []
	for i in range(PN.ENTRIES.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_news_select.bind(i))
		news_list.add_child(b)
		news_btns.append(b)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -8
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var ic := IC.rect("ball", 30)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
		var vt := _label("v" + String(PN.ENTRIES[i]["ver"]), 24)
		vt.autowrap_mode = TextServer.AUTOWRAP_OFF
		vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(vt)
		if i == 0:
			var nw := PanelContainer.new()
			nw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			nw.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nw.add_theme_stylebox_override("panel", _nsb(Color("#d12a3c"), Color("#ff9aa2"), 2, 6))
			var nl := _label("¡NUEVO!", 14)
			nl.autowrap_mode = TextServer.AUTOWRAP_OFF
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nw.add_child(nl)
			row.add_child(nw)
	_news_select(0)
	focus_first = news_btns[0]


func _news_select(idx: int) -> void:
	news_sel = idx
	for i in range(news_btns.size()):
		var on: bool = i == idx
		var b: Button = news_btns[i]
		b.add_theme_stylebox_override("normal", _nsb(Color("#d98a12") if on else Color("#16233f"), Color("#ffe07a") if on else Color("#3f6db0")))
		b.add_theme_stylebox_override("hover", _nsb(Color("#e8a020") if on else Color("#22345c"), Color("#ffe07a")))
		b.add_theme_stylebox_override("pressed", _nsb(Color("#b8740c"), Color("#ffe07a")))
		b.add_theme_stylebox_override("focus", _nsb(Color("#d98a12") if on else Color("#22345c"), Color.WHITE, 4))
	for c in news_box.get_children():
		news_box.remove_child(c)
		c.queue_free()
	var e: Dictionary = PN.ENTRIES[idx]
	news_box.add_child(_news_hero(e))
	for sec in [["new", "Nuevo", Color("#c9404e"), "star"], ["changes", "Cambios", Color("#2f9a5a"), "up"], ["fixes", "Arreglos", Color("#2f7fd0"), "gear"]]:
		var lines: Array = e.get(String(sec[0]), [])
		if not lines.is_empty():
			news_box.add_child(_news_section(String(sec[1]), sec[2], String(sec[3]), lines))
	news_scroll.scroll_vertical = 0
	_news_fit(idx)


# El texto con saltos de linea solo sabe su altura tras colocarse: se ajusta y asi las tarjetas no lo cortan.
func _news_fit(idx: int) -> void:
	for pass_i in range(2):
		await get_tree().process_frame
		if news_sel != idx:
			return
		for l in news_box.find_children("*", "Label", true, false):
			var lb: Label = l
			if lb.autowrap_mode != TextServer.AUTOWRAP_OFF and lb.get_parent() is HBoxContainer:
				lb.custom_minimum_size.y = float(lb.get_line_count()) * float(lb.get_line_height() + lb.get_theme_constant("line_spacing"))


func _news_hero(e: Dictionary) -> Control:
	var hero := Control.new()
	hero.custom_minimum_size = Vector2(0, 150)
	hero.clip_contents = true
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/news_hero.png")
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(art)
	var vt := Label.new()
	vt.text = "Pokémon Survivors V" + String(e["ver"])
	vt.position = Vector2(20, 8)
	vt.add_theme_font_size_override("font_size", 40)
	vt.add_theme_color_override("font_color", C_GOLD)
	vt.add_theme_constant_override("outline_size", 10)
	vt.add_theme_color_override("font_outline_color", Color("#3a1a08"))
	hero.add_child(vt)
	var info := VBoxContainer.new()
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_left = 20
	info.offset_right = -270
	info.offset_top = -74
	info.offset_bottom = -4
	info.alignment = BoxContainer.ALIGNMENT_END
	hero.add_child(info)
	var tl := _label(L.t(String(e["title"])), 18)
	tl.add_theme_constant_override("outline_size", 6)
	tl.add_theme_color_override("font_outline_color", Color("#10243f"))
	info.add_child(tl)
	var dl := _label(PN.fmt_date(String(e["date"]), L.lang()), 16, Color("#fff2d0"))
	dl.add_theme_constant_override("outline_size", 5)
	dl.add_theme_color_override("font_outline_color", Color("#10243f"))
	info.add_child(dl)
	for i in range(3):
		var pv := Preview.new()
		# de pie sobre la hierba del banner, en el mismo sitio que en el arte
		var fx: float = [0.78, 0.88, 0.945][i]
		var fy: float = [0.0, 0.0, -16.0][i]   # Squirtle, un poco mas arriba, sobre su loma
		pv.anchor_left = fx
		pv.anchor_right = fx
		pv.anchor_top = 1.0
		pv.anchor_bottom = 1.0
		pv.offset_left = -45.0
		pv.offset_right = 45.0
		pv.offset_top = -102.0 + fy
		pv.offset_bottom = 8.0 + fy
		hero.add_child(pv)
		pv.setup([4, 1, 7][i], false, 2.4)
		pv.walk = true
		pv.row = 5   # de espaldas, mirando en diagonal hacia las montanas de la izquierda
	return hero


func _news_section(title: String, col: Color, icon: String, lines: Array) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _nsb(col.darkened(0.72), col))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var hd := HBoxContainer.new()
	v.add_child(hd)
	var tab := PanelContainer.new()
	tab.add_theme_stylebox_override("panel", _nsb(col, col.lightened(0.3), 2, 8))
	hd.add_child(tab)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	tab.add_child(th)
	th.add_child(IC.rect(icon, 26))
	var tl := _label(title, 24, Color.WHITE)
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	th.add_child(tl)
	for ln in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var dot := IC.rect("ball", 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(dot)
		var bl := _label(L.t(String(ln)), 20)
		bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bl)
		v.add_child(row)
	return pc


func _slider_row(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_set_row_panel().add_child(row)
	row.add_child(SetGlyph.new({"master": "speaker", "music": "music", "sfx": "spark"}.get(key, "speaker"), 32.0))
	var l := _label(label, 22)
	l.custom_minimum_size = Vector2(230, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = float(SV.d["settings"][key])
	_set_slider(sl)
	row.add_child(sl)
	var pl := _set_pill("%d%%" % int(sl.value))
	row.add_child(pl.get_parent())
	sl.value_changed.connect(func(v: float):
		SV.d["settings"][key] = int(v)
		pl.text = "%d%%" % int(v)
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		if key == "sfx":
			Aud.sfx("coin"))


func _view_row() -> void:
	var box := VBoxContainer.new()
	_set_row_panel().add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(SetGlyph.new("monitor", 32.0))
	var l := _label("Tamaño de pantalla", 22)
	l.custom_minimum_size = Vector2(230, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = DSP.MIN_PCT
	sl.max_value = DSP.MAX_PCT
	sl.step = 5
	sl.value = float(DSP.pct())
	sl.scrollable = false
	_set_slider(sl)
	row.add_child(sl)
	var pl := _set_pill("%d%%" % DSP.pct())
	row.add_child(pl.get_parent())
	var rs := _btn("Restablecer", func(): pass, Vector2(150, 40))
	row.add_child(rs)
	var info := _label("", 16, Color("#c8d6ee"))
	box.add_child(info)
	var upd := func():
		pl.text = "%d%%" % DSP.pct()
		info.text = L.t("Pantalla (px) → vista del juego: ") + DSP.info(get_tree())
	upd.call()
	sl.value_changed.connect(func(v: float):
		DSP.set_pct(get_tree(), int(v))
		upd.call())
	rs.pressed.connect(func():
		sl.value = 100.0)


func _sec(title: String) -> void:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := _sb(Color("#2a56c4"), SET_LINE, 3, 6)
	sb.corner_radius_top_left = 16
	sb.corner_radius_bottom_right = 22
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.content_margin_right = 34
	pc.add_theme_stylebox_override("panel", sb)
	settings_box.add_child(pc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pc.add_child(h)
	h.add_child(SetGlyph.new(String(SET_SEC_ICON.get(title, "spark")), 30.0))
	var l := _label(title, 26)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_constant_override("outline_size", 0)
	h.add_child(l)


# Fila: titulo + descripcion a la izquierda, control a la derecha.
func _srow(title: String, desc: String, ctrl: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_set_row_panel().add_child(row)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	row.add_child(tv)
	tv.add_child(_label(title, 22))
	if desc != "":
		tv.add_child(_label(desc, 16, Color("#c8d6ee")))
	ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ctrl)


# Selector de opciones: la elegida lleva borde dorado.
func _seg(opts: Array, cur_i: int, cb: Callable, translate: bool = true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for i in range(opts.size()):
		var b := _btn(L.t(String(opts[i])) if translate else String(opts[i]), func(): cb.call(i), Vector2(0, 44))
		if i == cur_i:
			_set_btn(b, "gold")
		h.add_child(b)
	return h


func _yesno(on: bool, cb: Callable) -> Button:
	var b := _btn(L.t("Sí") if on else L.t("No"), func(): cb.call(not on), Vector2(90, 46))
	if on:
		_set_btn(b, "gold")
	return b


func _toggle_set(key: String, inverted: bool = false) -> Button:
	var on: bool = bool(SV.d["settings"][key])
	if inverted:
		on = not on
	return _yesno(on, func(v: bool):
		SV.d["settings"][key] = (not v) if inverted else v
		SV.save()
		_refresh_settings())


func _refresh_settings() -> void:
	reset_armed = false
	import_armed = false
	listening = ""
	_clear(set_tabs_row)
	var first_tab: Button = null
	for i in range(SET_TABS.size()):
		var tb := _btn("", func(): set_tab = i; last_act = ""; _refresh_settings(); _gf(tab_sel), Vector2(0, 54))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on: bool = i == set_tab
		var fc: Color = Color("#2b1a00") if on else Color.WHITE
		if on:
			_set_btn(tb, "gold")
			first_tab = tb
			tab_sel = tb
		var trow := HBoxContainer.new()
		trow.set_anchors_preset(Control.PRESET_FULL_RECT)
		trow.alignment = BoxContainer.ALIGNMENT_CENTER
		trow.add_theme_constant_override("separation", 10)
		trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tb.add_child(trow)
		trow.add_child(SetGlyph.new(String(SET_TAB_ICON[i]), 30.0, fc))
		var tl := _label(L.t(SET_TABS[i]), 22, fc)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trow.add_child(tl)
		tb.custom_minimum_size.x = tl.get_minimum_size().x + 70.0
		if on:
			var ptr := SetGlyph.new("pointer", 1.0)
			ptr.anchor_left = 0.5
			ptr.anchor_right = 0.5
			ptr.anchor_top = 1.0
			ptr.anchor_bottom = 1.0
			tb.add_child(ptr)
		set_tabs_row.add_child(tb)
	tab_row = set_tabs_row
	_clear(settings_box)
	focus_first = first_tab
	match set_tab:
		0:
			_set_sound()
		1:
			_set_graphics()
		2:
			_set_controls()
		3:
			_set_account()
		4:
			_set_about()


func _set_sound() -> void:
	_sec("Sonido")
	_slider_row("Volumen general", "master")
	_slider_row("Música", "music")
	_slider_row("Efectos", "sfx")
	var muted: bool = bool(SV.d["settings"]["mute"])
	var mb := _btn(L.t("Activar sonido") if muted else L.t("Silenciar todo"), func():
		SV.d["settings"]["mute"] = not muted
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		_refresh_settings(), Vector2(220, 50))
	_set_btn(mb, "gold")
	_btn_glyph(mb, "speaker" if muted else "mute", Color("#2b1a00"))
	mb.custom_minimum_size.x = 280
	mb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	settings_box.add_child(mb)


func _set_graphics() -> void:
	_sec("Idioma")
	settings_box.add_child(_label("El juego se recarga al cambiarlo.", 18, Color("#c8d6ee")))
	var lg := GridContainer.new()
	lg.columns = 2
	lg.add_theme_constant_override("h_separation", 8)
	lg.add_theme_constant_override("v_separation", 8)
	var cur_lang: String = L.lang()
	for entry in L.LANGS:
		var code: String = entry[0]
		var lb := _btn(String(entry[1]), func():
			if code == L.lang():
				return
			SV.d["settings"]["lang"] = code
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene(), Vector2(0, 46))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.add_theme_font_size_override("font_size", 20)
		if code == cur_lang:
			_set_btn(lb, "gold")
		lg.add_child(lb)
	settings_box.add_child(lg)
	_sec("Calidad")
	_srow("Efectos y partículas", "Cuántos efectos se dibujan. Auto los baja solo si el juego va a tirones.", _seg(["Auto", "Alta", "Media", "Baja"], int(SV.d["settings"]["quality"]), func(i: int):
		SV.d["settings"]["quality"] = i
		SV.save()
		_refresh_settings()))
	_srow("Rendimiento", "Si el juego va a tirones (sobre todo con movimientos fusión): Ahorro y Mínimo quitan efectos, estelas y números de daño sueltos y simplifican los disparos. No cambia el daño ni la dificultad.", _seg(["Normal", "Ahorro", "Mínimo"], clampi(int(SV.d["settings"].get("perf", 0)), 0, 2), func(i: int):
		SV.d["settings"]["perf"] = i
		SV.save()
		_refresh_settings()))
	_srow("Opacidad de los efectos", "Qué tan transparentes se ven los ataques de tus movimientos, para ver mejor a los enemigos. No afecta a los avisos de peligro.", _seg(["100%", "75%", "50%", "30%"], clampi(int(SV.d["settings"].get("fx_op", 1)), 0, 3), func(i: int):
		SV.d["settings"]["fx_op"] = i
		SV.save()
		_refresh_settings()))
	_sec("Pantalla")
	if not DSP.is_desktop():
		_view_row()
	if DSP.is_desktop():
		_srow("Modo de ventana", "Ventana o pantalla completa (solo en PC).", _seg(["Ventana", "Pantalla completa"], DSP.win_mode(), func(i: int):
			DSP.set_window(i, DSP.win_res())
			_refresh_settings()))
		var res_names: Array = []
		for rv in DSP.WIN_RES:
			res_names.append("%d×%d" % [rv.x, rv.y])
		_srow("Resolución de la ventana", "Tamaño de la ventana en PC. Si no cabe en tu pantalla se ajusta solo. No se usa en pantalla completa.", _seg(res_names, DSP.win_res(), func(i: int):
			DSP.set_window(DSP.win_mode(), i)
			_refresh_settings(), false))
	_srow("Tamaño del texto", "Agranda un poco el texto del juego (menús y pantalla de partida).", _seg(["Normal", "Grande", "Muy grande"], TXS.idx(), func(i: int):
		TXS.set_idx(i)
		TXS.scale_tree(self)
		_refresh_settings()))
	_srow("Números de daño", "Los números que salen al golpear o ser golpeado.", _toggle_set("dmg_numbers"))
	_srow("Temblor de pantalla", "Cuánto tiembla la cámara. Reducido y Apagado también suavizan los destellos.", _seg(["Normal", "Reducido", "Apagado"], SV.shake_lv(), func(i: int):
		SV.d["settings"]["shake_lv"] = i
		SV.d["settings"]["shake"] = i == 0
		SV.save()
		_refresh_settings()))
	_srow("Vibración", "Vibra el móvil cuando te golpean.", _toggle_set("vibration"))
	_srow("Mostrar FPS", "Cuadros por segundo, en la esquina.", _toggle_set("fps"))
	_srow("Caja de estadísticas", "Muestra tus estadísticas (daño, velocidad…) arriba a la izquierda.", _toggle_set("stats_box"))
	_srow("Bonus mono-tipo (+20%)", "Experimental: los Pokémon de un solo tipo hacen +20% de daño con movimientos de ese tipo. Desactivado por defecto mientras se revisa el equilibrio.", _toggle_set("mono_bonus"))
	_srow("Dificultad adaptativa", "En la partida normal, el juego empieza fácil y se pone más difícil según tus mejoras: más vida y daño, más enemigos, hordas más seguidas y más experiencia por nivel.", _toggle_set("adaptive"))


func _set_controls() -> void:
	_sec("En móvil o tableta")
	settings_box.add_child(_label("Pon el dedo en cualquier parte y arrástralo para moverte: el joystick aparece donde tocas. Toca un movimiento abajo para cambiar a él y el botón de arriba a la derecha para pausar. Juega en horizontal.", 20, Color("#c8d6ee")))
	_srow("Lado del botón de acción", "Dónde aparece el botón dorado de acción (recoger, comerciar, lanzar Poké Ball…), a media altura.", _seg(["Derecha", "Izquierda"], clampi(int(SV.d["settings"].get("act_side", 0)), 0, 1), func(i: int):
		SV.d["settings"]["act_side"] = i
		SV.save()
		_refresh_settings()))
	_srow("Tamaño del joystick", "Cuánto tienes que arrastrar el dedo.", _seg(["Pequeño", "Mediano", "Grande"], clampi(int(SV.d["settings"]["stick"]), 0, 2), func(i: int):
		SV.d["settings"]["stick"] = i
		SV.save()
		_refresh_settings()))
	_srow("Joystick fijo", "El joystick se queda siempre abajo a la izquierda en vez de aparecer donde tocas.", _toggle_set("stick_fixed"))
	_srow("Apuntado manual", "Apunta tú mismo: stick derecho del mando, el ratón o un segundo dedo arrastrando en la mitad derecha de la pantalla. Si no apuntas, el juego apunta solo.", _toggle_set("manual_aim"))
	_sec("Mando")
	settings_box.add_child(_label("Stick izquierdo o cruceta: moverte y navegar por los menús. Pulsa un botón de la lista y luego el botón del mando que quieras asignarle.", 20, Color("#c8d6ee")))
	_srow("Tipo de mando", "Cambia los nombres de los botones y restablece la asignación.", _seg(PAD.NAMES, PAD.layout(), func(i: int):
		PAD.reset(i)
		_refresh_settings(), false))
	for a in PAD.ACTIONS:
		var act: String = a
		var txt: String = L.t("Pulsa un botón…") if listening == act else ""
		var cb := _btn(txt, func():
			listening = "" if listening == act else act
			last_act = act
			_refresh_listen(), Vector2(190, 46))
		if listening == act:
			_set_btn(cb, "gold")
		else:
			cb.icon = PADI.tex(PAD.btn(act))
			cb.expand_icon = true
			cb.add_theme_constant_override("icon_max_width", 36)
			cb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_srow(PAD.LABELS[act], "", cb)
		if act == last_act:
			focus_first = cb
	var rb := _btn("Restablecer asignación", func(): PAD.reset(); last_act = ""; _refresh_settings(), Vector2(280, 46))
	settings_box.add_child(rb)


# Redibuja la pestana de controles manteniendo el modo "escuchando".
func _refresh_listen() -> void:
	var keep := listening
	_clear(settings_box)
	_set_controls()
	listening = keep
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)


func _set_account() -> void:
	_sec("Cuenta")
	var l1 := _label("Local (este dispositivo)", 22, Color("#dfe8ff"))
	l1.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Tipo de cuenta", "", l1)
	var l2 := _label("En este dispositivo", 22, Color("#dfe8ff"))
	l2.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Guardado", "", l2)
	settings_box.add_child(_label("Tu partida se guarda en este dispositivo. Para tenerla a salvo o pasarla a otro dispositivo: copia el código de guardado, pégalo en una nota de Google Keep, en Google Drive, en un correo o en un mensaje a ti mismo, y en el otro dispositivo usa «Pegar código de guardado».", 18, Color("#c8d6ee")))
	_sec("Copia de seguridad")
	var cb := _btn("Copiar código de guardado", func():
		var js := JSON.stringify(SV.d)
		DisplayServer.clipboard_set(Marshalls.utf8_to_base64(js))
		toast(L.t("Código copiado")), Vector2(0, 50))
	settings_box.add_child(cb)
	focus_first = cb
	var ib := _btn("Pegar código de guardado", func(): pass, Vector2(0, 50))
	ib.pressed.connect(func():
		if not import_armed:
			import_armed = true
			ib.text = L.t("¿Reemplazar tu progreso actual? Pulsa otra vez")
			return
		import_armed = false
		var parsed = JSON.parse_string(Marshalls.base64_to_utf8(DisplayServer.clipboard_get().strip_edges()))
		if parsed is Dictionary and parsed.has("owned") and parsed.has("coins"):
			SV.d = SV._merge(SV.default_data(), parsed)
			SV._migrate_upgrades()
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene()
		else:
			ib.text = L.t("Pegar código de guardado")
			toast(L.t("Código no válido")))
	settings_box.add_child(ib)
	_sec("Zona peligrosa")
	var rb := _btn("Borrar todo el progreso", func(): pass, Vector2(0, 50))
	_danger(rb)
	rb.pressed.connect(func():
		if not reset_armed:
			reset_armed = true
			rb.text = L.t("¿Seguro? Pulsa otra vez para borrar TODO")
		else:
			SV.reset_all()
			_show("test"))
	settings_box.add_child(rb)


func _danger(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _sb(Color("#8a1f2d"), Color("#ff7a85"), 3, 12))
	b.add_theme_stylebox_override("focus", _sb(Color("#a92a3b"), Color.WHITE, 5, 12))


# v6.0: About con el logo sobre el paisaje, tarjeta legal y creditos con siluetas de fondo.
func _set_about() -> void:
	var am := MarginContainer.new()
	am.add_theme_constant_override("margin_right", 36)   # la barra de desplazamiento no tapa las tarjetas
	settings_box.add_child(am)
	var ab := VBoxContainer.new()
	ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ab.add_theme_constant_override("separation", 8)
	am.add_child(ab)
	var hero := TextureRect.new()
	hero.texture = load("res://assets/ui/about_hero.png")
	hero.custom_minimum_size = Vector2(0, 200)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.clip_contents = true
	ab.add_child(hero)
	var hr := HBoxContainer.new()
	hr.alignment = BoxContainer.ALIGNMENT_CENTER
	hr.add_theme_constant_override("separation", 14)
	ab.add_child(hr)
	var by := _label("Port de Android por JayElDragon", 24)
	by.autowrap_mode = TextServer.AUTOWRAP_OFF
	hr.add_child(by)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#9cc8ff"), 2, 10))
	var ver := _label(L.t("Versión") + " " + UPD.APP_VERSION + " · Android", 18)
	ver.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill.add_child(ver)
	hr.add_child(pill)
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#3f6db0")))
	lp.add_child(_label("Juego de fans gratis y sin ánimo de lucro: sin anuncios ni compras. Pokémon y sus personajes pertenecen a Nintendo, Creatures y GAME FREAK; este proyecto no está afiliado con ellos.", 18, Color("#dfe8ff")))
	ab.add_child(lp)
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", _nsb(Color("#101a30"), Color("#3f6db0")))
	ab.add_child(cp)
	var holder := Control.new()
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp.add_child(holder)
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/about_credits.png")
	art.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	art.offset_left = -360.0
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cp.add_child(cv)
	var ch := HBoxContainer.new()
	cv.add_child(ch)
	var tab := PanelContainer.new()
	tab.add_theme_stylebox_override("panel", _nsb(Color("#2f7fd0"), Color("#9cc8ff"), 2, 8))
	ch.add_child(tab)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	tab.add_child(th)
	th.add_child(IC.rect("ball", 26))
	var tl := _label("Créditos", 24, C_GOLD)
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	th.add_child(tl)
	for line in ["• Juego original (web): JPTER78.", "• Port de Android: JayElDragon.", "• Sprites: PMD SpriteCollab y sus artistas (CC BY-NC 4.0).", "• Datos Pokémon: PokéAPI.", "• Fuente: Pixelify Sans (OFL)."]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(IC.rect("ball", 18))
		var ll := _label(L.t(line).trim_prefix("• "), 18)
		ll.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(ll)
		cv.add_child(row)
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 10)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	ab.add_child(hb)
	var dxb := _btn("Pokédex", func(): _show("dex"), Vector2(0, 50))
	hb.add_child(dxb)
	hb.add_child(_btn("Mi repositorio en GitHub", func(): OS.shell_open(REPO_URL), Vector2(0, 50)))
	focus_first = dxb
