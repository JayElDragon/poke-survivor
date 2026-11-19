extends CanvasLayer
# 7.1: Casino Rocket, como el del juego original: Tragaperras, Voltorb escondido, Carrera Rocket y Atrapa a Pikachu.
# Reglas copiadas del original (apuestas 1.000 / 5.000 / 10.000; 3 partidas por juego y visita, Pikachu una).
const SP = preload("res://scripts/sprites.gd")
const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")
const PXF = preload("res://scripts/pxfont.gd")
const Aud = preload("res://scripts/audio.gd")
const DSP = preload("res://scripts/display.gd")

const BETS := [1000, 5000, 10000]
const LIMITS := {"slots": 3, "voltorb": 3, "race": 3, "pika": 1}
const SYM_W := {"ball": 7, "ball2": 5, "ball3": 4, "ballLux": 2, "ball4": 2, "R": 6}
const PAY3 := {"ball": 3, "ball2": 5, "ball3": 8, "ballLux": 12, "ball4": 18, "R": 20}
const VOLT_MULT := [1.1, 1.5, 2.0, 3.0, 5.0, 10.0, 20.0]
const RUNNERS := [[53, 2], [19, 3], [23, 5], [109, 10]]   # Persian, Rattata, Ekans, Koffing: [dex, paga]
const PIKA_COST := 10000
const SKIN_PRIZE := "obsidiana-mewtwo"
const GOLD := Color("#ffd23f")
const C_TXT := Color("#f3ecff")
const C_SUB := Color("#cfc2ee")

var host = null          # main.gd (en partida) o el menu
var player_dex := 25
var bet_i := 0
var plays := {}
var screen := "lobby"
var root: Control
var body: VBoxContainer
var coin_lbl: Label
var say_lbl: Label
var on_close: Callable = Callable()


static func open(parent: Node, dex: int, closed: Callable = Callable()) -> CanvasLayer:
	var c = load("res://scripts/rocket_casino.gd").new()
	c.name = "RocketCasino"
	c.host = parent
	c.player_dex = dex
	c.on_close = closed
	parent.add_child(c)
	return c


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = _theme()
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("#14081f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ins: Vector4 = DSP.insets(get_tree())
	v.offset_left = ins.x
	v.offset_right = -ins.z
	v.add_theme_constant_override("separation", 0)
	root.add_child(v)
	var scene := Hall.new()
	scene.custom_minimum_size = Vector2(0, 236)
	scene.casino = self
	v.add_child(scene)
	var low := MarginContainer.new()
	low.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for s in ["left", "right"]:
		low.add_theme_constant_override("margin_" + s, 18)
	low.add_theme_constant_override("margin_top", 0)
	low.add_theme_constant_override("margin_bottom", 12 + int(ins.w))
	v.add_child(low)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	low.add_child(body)
	show_lobby()


# ---------------------------------------------------------------
# Estilo
# ---------------------------------------------------------------
func _sb(col: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 14, pad: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


func _theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	PXF.apply(t)
	t.set_color("font_color", "Label", C_TXT)
	return t


func txt(s: String, size: int = 18, col: Color = C_TXT, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = L.t(s)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color("#1b0d2b"))
		l.add_theme_constant_override("outline_size", outline)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# Boton dorado (Jugar) o de pastilla (apuestas, salir).
func gold_btn(text: String, cb: Callable, big: bool = false) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(150 if big else 120, 52 if big else 44)
	b.add_theme_font_size_override("font_size", 24 if big else 20)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var c := Color("#ffc928")
		var e := Color("#fff1a8")
		if st == "hover" or st == "focus":
			c = Color("#ffd95a")
			e = Color.WHITE
		elif st == "pressed":
			c = Color("#e0a812")
		elif st == "disabled":
			c = Color("#6b5a7a")
			e = Color("#8d7da0")
		var s := _sb(c, e, 3, 16, 8)
		s.shadow_color = Color(0.35, 0.2, 0.0, 0.6)
		s.shadow_size = 0
		s.shadow_offset = Vector2(0, 4)
		s.border_width_bottom = 6
		s.border_color = e if st != "normal" else Color("#c98a00")
		b.add_theme_stylebox_override(st, s)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color("#3a2200"))
	b.add_theme_color_override("font_disabled_color", Color("#c9bcd8"))
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	return b


func pill_btn(text: String, cb: Callable, on: bool) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 20)
	var c := Color("#2a1650") if not on else Color("#4a2a00")
	var e := Color("#7b5fc0") if not on else GOLD
	for st in ["normal", "hover", "pressed", "focus"]:
		var s := _sb(c.lightened(0.12) if st == "hover" else c, Color.WHITE if st == "focus" else e, 3, 20, 6)
		s.content_margin_left = 16
		s.content_margin_right = 16
		b.add_theme_stylebox_override(st, s)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, GOLD if on else C_TXT)
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	return b


func coins() -> int:
	return int(SV.d.get("coins", 0))


func left(game: String) -> int:
	return maxi(0, int(LIMITS[game]) - int(plays.get(game, 0)))


func clear_body() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()


# Cabecera morada: Poke Ball, titulo, mensaje de Meowth, monedas y salir.
func header(msg: String) -> void:
	var hp := PanelContainer.new()
	var hs := _sb(Color("#2b1757"), Color("#9b7cff"), 3, 18, 10)
	hs.content_margin_left = 12
	hs.content_margin_right = 14
	hp.add_theme_stylebox_override("panel", hs)
	body.add_child(hp)
	var deco := HeaderDeco.new()
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp.add_child(deco)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	hp.add_child(h)
	var ball := BallIcon.new()
	ball.kind = "ball"
	ball.custom_minimum_size = Vector2(56, 56)
	ball.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ball)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(txt("Casino Rocket", 30, Color.WHITE, 5))
	say_lbl = txt(msg, 18, C_SUB)
	tv.add_child(say_lbl)
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", _sb(Color("#1a0e33"), Color("#7b5fc0"), 3, 22, 6))
	cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cp)
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 8)
	cp.add_child(ch)
	var ci := BallIcon.new()
	ci.kind = "coin"
	ci.custom_minimum_size = Vector2(30, 30)
	ch.add_child(ci)
	coin_lbl = txt(_fmt(coins()), 24, GOLD, 4)
	coin_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	ch.add_child(coin_lbl)
	var ex := pill_btn("Salir del casino  ➜", close, false)
	ex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ex)


func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func say(msg: String) -> void:
	if say_lbl != null and is_instance_valid(say_lbl):
		say_lbl.text = L.t(msg)
	if coin_lbl != null and is_instance_valid(coin_lbl):
		coin_lbl.text = _fmt(coins())


# ---------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------
func show_lobby(msg: String = "") -> void:
	screen = "lobby"
	clear_body()
	header(msg if msg != "" else ("¡Bienvenido, miau! Cada juego se puede jugar 3 veces; atrapar a Pikachu, solo una." if coins() >= BETS[0] else "Sin monedas no hay juego, miau. La salida está por ahí."))
	# Tu apuesta
	var bp := PanelContainer.new()
	bp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bp.add_theme_stylebox_override("panel", _sb(Color("#1e1040"), Color("#7b5fc0"), 3, 24, 6))
	body.add_child(bp)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	bp.add_child(bh)
	var bl := txt("Tu apuesta:", 20, Color.WHITE)
	bl.autowrap_mode = TextServer.AUTOWRAP_OFF
	bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bh.add_child(bl)
	for i in BETS.size():
		var idx: int = i
		var b := pill_btn("● " + _fmt(int(BETS[i])), func(): bet_i = idx; show_lobby(), i == bet_i)
		b.disabled = coins() < int(BETS[i])
		bh.add_child(b)
	# Tres juegos
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	row.add_child(game_card("slots", "Tragaperras Rocket", "Tres iguales ganan. Tres R: el premio gordo y una estela que no se vende.", Color("#3a1a6e"), Color("#b98cff"), "ball4"))
	row.add_child(game_card("voltorb", "Voltorb escondido", "Abre Poké Balls y el premio sube. Hay 2 Voltorb: plántate antes de que explote uno.", Color("#14306e"), Color("#5fb0ff"), "voltorb"))
	row.add_child(game_card("race", "Carrera Rocket", "Elige corredor: cuanto más lento, más paga.", Color("#13452c"), Color("#5fe08a"), "race"))
	body.add_child(pika_banner())


func game_card(id: String, title: String, desc: String, col: Color, edge: Color, icon: String) -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := _sb(col, edge, 3, 18, 12)
	pc.add_theme_stylebox_override("panel", s)
	var deco := CardDeco.new()
	deco.kind = id
	deco.edge = edge
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(deco)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var ic: Control
	if icon == "voltorb":
		ic = sprite_rect(100, 64)
	elif icon == "race":
		ic = sprite_rect(53, 64)
	else:
		var bi := BallIcon.new()
		bi.kind = icon
		ic = bi
	ic.custom_minimum_size = Vector2(64, 64)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(ic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	tv.add_child(txt(title, 24, Color.WHITE, 5))
	tv.add_child(txt(desc, 16, C_SUB))
	var bot := HBoxContainer.new()
	v.add_child(bot)
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.15), 2, 14, 4))
	lp.size_flags_vertical = Control.SIZE_SHRINK_END
	bot.add_child(lp)
	var ll := txt(L.t("%d restantes") % left(id), 16, GOLD)
	ll.autowrap_mode = TextServer.AUTOWRAP_OFF
	lp.add_child(ll)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(sp)
	var b := gold_btn("▶ Jugar", func(): start_game(id))
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	b.disabled = left(id) <= 0 or coins() < int(BETS[bet_i])
	bot.add_child(b)
	return pc


func pika_banner() -> Control:
	var pc := PanelContainer.new()
	var s := _sb(Color("#2a1046"), GOLD, 4, 18, 12)
	pc.add_theme_stylebox_override("panel", s)
	var deco := PikaDeco.new()
	deco.casino = self
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(deco)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	pc.add_child(h)
	var pk := sprite_rect(25, 84)
	pk.custom_minimum_size = Vector2(96, 84)
	h.add_child(pk)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 2)
	h.add_child(tv)
	tv.add_child(txt("¡Atrapa a Pikachu!", 30, GOLD, 5))
	tv.add_child(txt("Por una vez estás del lado del Team Rocket: tres planes seguidos para atraparlo. Si falla uno, sales volando. Solo tienes un intento. Premio: la skin exclusiva Mewtwo Obsidiana.", 16, C_TXT))
	var b := gold_btn(L.t("Jugar") + " · " + _fmt(PIKA_COST), func(): start_game("pika"), true)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = left("pika") <= 0 or coins() < PIKA_COST
	h.add_child(b)
	return pc




func close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()


func _input(ev: InputEvent) -> void:
	if (ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		get_viewport().set_input_as_handled()
		if screen == "lobby":
			close()
		else:
			show_lobby()


# ---------------------------------------------------------------
# Sprites de Pokemon (primer fotograma de Idle)
# ---------------------------------------------------------------
static func idle_tex(dex: int) -> AtlasTexture:
	var sm: Dictionary = SV.smeta.get(str(dex), {})
	if sm.is_empty():
		return null
	var info: Dictionary = sm["a"]["Idle"]
	var path: String = "res://assets/pokemon/%d/%s.png" % [dex, String(info.get("f", "Idle"))]
	if not SP.exists(path):
		return null
	var at := AtlasTexture.new()
	at.atlas = SP.texture(path)
	# Se recorta el margen transparente del fotograma (el Pokemon ocupa el centro).
	var fw: float = float(info["w"])
	var fh: float = float(info["h"])
	at.region = Rect2(fw * 0.18, fh * 0.12, fw * 0.64, fh * 0.76)
	return at


func sprite_rect(dex: int, h: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = idle_tex(dex)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


# ---------------------------------------------------------------
# Dibujos
# ---------------------------------------------------------------
static func draw_ball(ci: CanvasItem, c: Vector2, r: float, kind: String) -> void:
	var top := Color("#e8333f")
	var band := Color.TRANSPARENT
	match kind:
		"ball2":
			top = Color("#3b7de0")
			band = Color("#e8333f")
		"ball3":
			top = Color("#2b2b33")
			band = Color("#ffd23f")
		"ballLux":
			top = Color("#22232b")
			band = Color("#e8333f")
		"ball4":
			top = Color("#7b3fd0")
			band = Color("#ff7ad9")
	ci.draw_circle(c + Vector2(0, r * 0.12), r * 1.02, Color(0, 0, 0, 0.35))
	ci.draw_circle(c, r, Color("#1b1528"))
	ci.draw_circle(c, r * 0.88, Color("#f4f4f8"))
	var pts := PackedVector2Array()
	for i in range(25):
		var a: float = PI + PI * float(i) / 24.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * 0.88)
	ci.draw_colored_polygon(pts, top)
	if band.a > 0.0:
		ci.draw_circle(c + Vector2(-r * 0.45, -r * 0.35), r * 0.16, band)
		ci.draw_circle(c + Vector2(r * 0.45, -r * 0.35), r * 0.16, band)
	ci.draw_line(c - Vector2(r * 0.88, 0), c + Vector2(r * 0.88, 0), Color("#1b1528"), maxf(2.0, r * 0.14))
	ci.draw_circle(c, r * 0.3, Color("#1b1528"))
	ci.draw_circle(c, r * 0.19, Color.WHITE)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.5), r * 0.12, Color(1, 1, 1, 0.7))


static func draw_coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, Color("#b8860b"))
	ci.draw_circle(c, r * 0.86, Color("#ffd23f"))
	ci.draw_circle(c, r * 0.55, Color("#f2b81f"))
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.16, Color(1, 1, 1, 0.8))


class BallIcon extends Control:
	var kind := "ball"
	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.46
		if kind == "coin":
			load("res://scripts/rocket_casino.gd").draw_coin(self, size * 0.5, r)
		elif kind == "R":
			draw_rect(Rect2(Vector2.ZERO, size), Color("#f4f0e8"))
			var f: Font = load("res://scripts/pxfont.gd").get_font()
			draw_string_outline(f, Vector2(size.x * 0.22, size.y * 0.8), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y * 0.8), 6, Color("#5a0a12"))
			draw_string(f, Vector2(size.x * 0.22, size.y * 0.8), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y * 0.8), Color("#e8333f"))
		else:
			load("res://scripts/rocket_casino.gd").draw_ball(self, size * 0.5, r, kind)


# Decoracion de la cabecera: silueta de ciudad con la R del Team Rocket.
class HeaderDeco extends Control:
	func _draw() -> void:
		var x0: float = size.x * 0.48
		var base: float = size.y
		var col := Color(0.45, 0.3, 0.8, 0.28)
		var hs := [30, 52, 38, 64, 44, 80, 46, 58, 34, 48]
		var x: float = x0
		for i in hs.size():
			var w: float = 22.0 + float(i % 3) * 6.0
			draw_rect(Rect2(x, base - float(hs[i]), w, float(hs[i])), col)
			x += w + 2.0
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		draw_string(f, Vector2(x0 + 120.0, base - 18.0), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(1.0, 0.2, 0.35, 0.55))


# Marca de agua de cada tarjeta (maquina R, Poke Balls, bandera a cuadros).
class CardDeco extends Control:
	var kind := ""
	var edge := Color.WHITE
	func _draw() -> void:
		var c := Color(edge.r, edge.g, edge.b, 0.16)
		var p := Vector2(size.x - 70.0, 46.0)
		if kind == "slots":
			draw_rect(Rect2(p + Vector2(-34, -30), Vector2(64, 80)), c)
			draw_rect(Rect2(p + Vector2(-22, -18), Vector2(40, 26)), Color(0, 0, 0, 0.18))
			var f: Font = load("res://scripts/pxfont.gd").get_font()
			draw_string(f, p + Vector2(-12, 44), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, c.lightened(0.2))
		elif kind == "voltorb":
			draw_arc(p, 26.0, 0.0, TAU, 32, c, 7.0)
			draw_line(p - Vector2(26, 0), p + Vector2(26, 0), c, 5.0)
			draw_arc(p + Vector2(30, 34), 18.0, 0.0, TAU, 28, c, 5.0)
		else:
			for i in range(5):
				for j in range(4):
					if (i + j) % 2 == 0:
						draw_rect(Rect2(p + Vector2(-30 + i * 13, -24 + j * 12 + i * 2), Vector2(13, 12)), c)
			draw_line(p + Vector2(-32, -26), p + Vector2(-32, 50), c, 4.0)


# Fondo del banner de Pikachu: destellos y la silueta de Mewtwo.
class PikaDeco extends Control:
	var casino
	var t := 0.0
	func _process(dt: float) -> void:
		t += dt
		queue_redraw()
	func _draw() -> void:
		var mt: Texture2D = casino.idle_tex(150) if casino != null else null
		if mt != null:
			var h: float = size.y * 1.05
			var w: float = h * float(mt.get_width()) / float(mt.get_height())
			draw_texture_rect(mt, Rect2(Vector2(size.x * 0.66 - w * 0.5, size.y - h), Vector2(w, h)), false, Color(0.45, 0.25, 0.75, 0.35))
		for i in range(9):
			var px: float = fposmod(float(i) * 137.0, size.x * 0.9) + 20.0
			var py: float = fposmod(float(i) * 53.0, size.y - 20.0) + 10.0
			var k: float = 0.5 + 0.5 * sin(t * 2.4 + float(i))
			var s: float = 3.0 + 4.0 * k
			var col := Color(1.0, 0.85, 0.4, 0.25 + 0.5 * k)
			draw_line(Vector2(px - s, py), Vector2(px + s, py), col, 2.0)
			draw_line(Vector2(px, py - s), Vector2(px, py + s), col, 2.0)


# La sala del casino: telon, estandartes R, letrero luminoso, tragaperras, Meowth en su podio, Pokemon y suelo.
class Hall extends Control:
	var casino
	var t := 0.0
	var tex := {}
	func _ready() -> void:
		for dx in [52, 202, 109, casino.player_dex]:
			tex[dx] = casino.idle_tex(int(dx))
	func _process(dt: float) -> void:
		t += dt
		queue_redraw()
	func _poly(pts: Array, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array(pts), col)
	func _mon(dx: int, pos: Vector2, h: float, flip: bool = false, bob: float = 0.0) -> void:
		var tx: Texture2D = tex.get(dx)
		if tx == null:
			return
		h *= 1.15
		var w: float = h * float(tx.get_width()) / float(tx.get_height())
		var y: float = pos.y - h * 0.78 + sin(t * 3.0 + bob) * 2.0
		draw_set_transform(Vector2(pos.x, 0), 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(tx, Rect2(Vector2(-w * 0.5, y), Vector2(w, h)), false)
		draw_set_transform(Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	func _draw() -> void:
		var W: float = size.x
		var H: float = size.y
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		var RC = load("res://scripts/rocket_casino.gd")
		# pared
		draw_rect(Rect2(0, 0, W, H), Color("#2a0f2e"))
		for i in range(int(W / 40.0) + 1):
			draw_rect(Rect2(float(i) * 40.0, 0, 20.0, H * 0.62), Color("#321335"))
		# suelo a cuadros en perspectiva
		var fy: float = H * 0.66
		draw_rect(Rect2(0, fy, W, H - fy), Color("#3a1030"))
		for r in range(4):
			var y0: float = fy + float(r) * (H - fy) / 4.0
			var hh: float = (H - fy) / 4.0
			for c in range(-2, int(W / 60.0) + 3):
				if (r + c) % 2 == 0:
					var sk: float = (float(c) * 60.0 - W * 0.5) * (0.06 * float(r))
					draw_rect(Rect2(float(c) * 60.0 + sk, y0, 60.0 + float(r) * 4.0, hh), Color("#52163f"))
		draw_set_transform(Vector2(W * 0.5, H - 14.0), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 120.0, Color("#6a1c38"))
		draw_arc(Vector2.ZERO, 120.0, 0.0, TAU, 48, Color("#ff5d6e"), 6.0)
		draw_line(Vector2(-120, 0), Vector2(120, 0), Color("#2a0f2e"), 10.0)
		draw_circle(Vector2.ZERO, 34.0, Color("#2a0f2e"))
		draw_circle(Vector2.ZERO, 22.0, Color("#ff5d6e"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(0, fy), Vector2(W, fy), Color("#ffd23f", 0.5), 2.0)
		# tragaperras
		var mw: float = 62.0
		var my: float = fy - 92.0
		var x: float = 50.0
		var idx := 0
		while x < W - 40.0:
			if absf(x + mw * 0.5 - W * 0.5) > 80.0:
				draw_rect(Rect2(x, my, mw, 92.0), Color("#c4223a"))
				draw_rect(Rect2(x, my, mw, 10.0), Color("#ff5d6e"))
				draw_rect(Rect2(x + 8, my + 18, mw - 16, 26.0), Color("#1b0d1e"))
				for k in range(3):
					var lit: bool = int(t * 3.0 + float(idx + k)) % 4 != 0
					draw_rect(Rect2(x + 11 + float(k) * 14.0, my + 21, 11.0, 20.0), Color("#fff6d8") if lit else Color("#c9b9a0"))
				draw_rect(Rect2(x + 8, my + 52, mw - 16, 8.0), Color("#8a1428"))
				draw_rect(Rect2(x + mw, my + 20, 6.0, 30.0), Color("#c9c9d6"))
				draw_circle(Vector2(x + mw + 3, my + 18), 6.0, Color("#e8333f"))
			x += mw + 30.0
			idx += 1
		# cordones dorados
		var post_y: float = fy - 6.0
		for px in [W * 0.5 - 140.0, W * 0.5 + 140.0, 30.0, W - 30.0]:
			draw_rect(Rect2(float(px) - 3.0, post_y - 44.0, 6.0, 44.0), Color("#e0b030"))
			draw_circle(Vector2(float(px), post_y - 46.0), 7.0, Color("#ffd23f"))
		for pair in [[30.0, W * 0.5 - 140.0], [W * 0.5 + 140.0, W - 30.0]]:
			var a := Vector2(float(pair[0]), post_y - 38.0)
			var b := Vector2(float(pair[1]), post_y - 38.0)
			var pts := PackedVector2Array()
			for i in range(21):
				var u: float = float(i) / 20.0
				pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI * 6.0) * 8.0 + 8.0))
			draw_polyline(pts, Color("#c4223a"), 4.0)
		# podio de Meowth
		var cx: float = W * 0.5
		draw_rect(Rect2(cx - 60, fy - 20, 120, 24), Color("#b8860b"))
		draw_rect(Rect2(cx - 52, fy - 30, 104, 12), Color("#ffd23f"))
		# Pokemon
		_mon(casino.player_dex, Vector2(W * 0.2, fy + 10), 64.0)
		_mon(202, Vector2(W * 0.68, fy + 10), 64.0, false, 1.3)
		_mon(109, Vector2(W * 0.82, fy - 10 + sin(t * 2.0) * 6.0), 62.0, false, 2.1)
		# plantas
		for side in [0.0, 1.0]:
			var px2: float = 22.0 if side == 0.0 else W - 22.0
			draw_rect(Rect2(px2 - 14, fy - 34, 28, 30), Color("#d8d8e0"))
			for k in range(5):
				var a2: float = -PI * 0.5 + (float(k) - 2.0) * 0.45
				var tip := Vector2(px2, fy - 34) + Vector2.from_angle(a2) * 46.0
				_poly([Vector2(px2 - 4, fy - 34), tip, Vector2(px2 + 4, fy - 34)], Color("#2f9a4a"))
		# telon
		for side in [0.0, 1.0]:
			var pts2: Array = []
			var sx: float = 0.0 if side == 0.0 else W
			var dir: float = 1.0 if side == 0.0 else -1.0
			pts2.append(Vector2(sx, 0))
			pts2.append(Vector2(sx + dir * 230.0, 0))
			for i in range(8):
				var u2: float = float(i) / 7.0
				pts2.append(Vector2(sx + dir * (230.0 - u2 * 200.0), 30.0 + u2 * 70.0 + sin(u2 * 9.0) * 6.0))
			pts2.append(Vector2(sx, 130.0))
			_poly(pts2, Color("#9a1424"))
			for k in range(5):
				var lx: float = sx + dir * (20.0 + float(k) * 40.0)
				draw_line(Vector2(lx, 0), Vector2(lx - dir * 10.0, 90.0 - float(k) * 12.0), Color("#6a0c18"), 4.0)
			draw_rect(Rect2(minf(sx, sx + dir * 240.0), 0, 240.0, 12.0), Color("#ffd23f"))
		# estandartes R
		for bx in [W * 0.1, W * 0.9]:
			var x0b: float = float(bx) - 30.0
			_poly([Vector2(x0b, 8), Vector2(x0b + 60, 8), Vector2(x0b + 60, 78), Vector2(x0b + 30, 96), Vector2(x0b, 78)], Color("#1b1028"))
			_poly([Vector2(x0b + 4, 12), Vector2(x0b + 56, 12), Vector2(x0b + 56, 75), Vector2(x0b + 30, 90), Vector2(x0b + 4, 75)], Color("#2a1838"))
			draw_string(f, Vector2(x0b + 14, 66), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("#e8333f"))
		# letrero luminoso
		var sw: float = minf(W * 0.56, 620.0)
		var sr := Rect2(cx - sw * 0.5, 12.0, sw, 70.0)
		var so := StyleBoxFlat.new()
		so.bg_color = Color("#1b0d1e")
		so.border_color = Color("#ffd23f")
		so.set_border_width_all(4)
		so.set_corner_radius_all(30)
		so.shadow_color = Color(1.0, 0.75, 0.2, 0.35)
		so.shadow_size = 10
		draw_style_box(so, sr)
		var nb: int = int(sw / 22.0)
		for i in range(nb):
			var lit2: bool = (i + int(t * 6.0)) % 3 != 0
			var bc := Color("#fff3b0") if lit2 else Color("#a07a20")
			draw_circle(Vector2(sr.position.x + 16.0 + float(i) * (sw - 32.0) / float(nb - 1), sr.position.y + 6.0), 3.0, bc)
			draw_circle(Vector2(sr.position.x + 16.0 + float(i) * (sw - 32.0) / float(nb - 1), sr.end.y - 6.0), 3.0, bc)
		RC.draw_ball(self, Vector2(sr.position.x - 4, sr.position.y + 35), 22.0, "ball")
		RC.draw_ball(self, Vector2(sr.end.x + 4, sr.position.y + 35), 22.0, "ball")
		var fs := 40
		var w1: float = f.get_string_size("CASINO", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var w2: float = f.get_string_size("ROCKET", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var gap := 54.0
		var sx2: float = cx - (w1 + gap + w2) * 0.5
		var by: float = sr.position.y + 50.0
		draw_string_outline(f, Vector2(sx2, by), "CASINO", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color("#6a3a00"))
		draw_string(f, Vector2(sx2, by), "CASINO", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffe066"))
		var shc := Vector2(sx2 + w1 + gap * 0.5, sr.position.y + 35.0)
		_poly([shc + Vector2(-20, -24), shc + Vector2(20, -24), shc + Vector2(20, 8), shc + Vector2(0, 26), shc + Vector2(-20, 8)], Color("#ffd23f"))
		_poly([shc + Vector2(-16, -20), shc + Vector2(16, -20), shc + Vector2(16, 6), shc + Vector2(0, 21), shc + Vector2(-16, 6)], Color("#e8333f"))
		draw_string(f, shc + Vector2(-10, 10), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		draw_string_outline(f, Vector2(sx2 + w1 + gap, by), "ROCKET", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color("#5a0a12"))
		draw_string(f, Vector2(sx2 + w1 + gap, by), "ROCKET", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ff5d6e"))
		_mon(52, Vector2(cx, fy - 24), 66.0)   # Meowth en su podio, delante del letrero


func start_game(id: String) -> void:
	if id == "pika":
		if left("pika") <= 0 or coins() < PIKA_COST:
			show_lobby("Sin monedas no hay juego, miau. La salida está por ahí.")
			return
	elif left(id) <= 0 or coins() < int(BETS[bet_i]):
		show_lobby("Sin monedas no hay juego, miau. La salida está por ahí.")
		return
	screen = id
	g = {}
	clear_body()
	var msgs := {"slots": "Apuestas %s por tirada, miau.", "voltorb": "Apuestas %s por partida, miau. Si sale un Voltorb, lo pierdes todo.", "race": "Apuestas %s por carrera, miau. ¿Por quién?", "pika": "Tres planes del Team Rocket. Si falla uno, Pikachu os manda volando."}
	header(L.t(String(msgs[id])) % _fmt(int(BETS[bet_i])) if id != "pika" else String(msgs[id]))
	var fp := PanelContainer.new()
	var cols := {"slots": [Color("#2a1046"), Color("#b98cff")], "voltorb": [Color("#0f2a52"), Color("#5fb0ff")], "race": [Color("#10331f"), Color("#5fe08a")], "pika": [Color("#2a1046"), GOLD]}
	var fs := _sb(cols[id][0], cols[id][1], 3, 16, 4)
	fp.add_theme_stylebox_override("panel", fs)
	fp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(fp)
	field = Field.new()
	field.casino = self
	field.mode = id
	field.custom_minimum_size = Vector2(0, 250)
	fp.add_child(field)
	ctrl = HBoxContainer.new()
	ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl.add_theme_constant_override("separation", 14)
	body.add_child(ctrl)
	msg_lbl = txt("", 20, GOLD, 5)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match id:
		"slots":
			g = {"reels": ["ball", "ball2", "ball"], "spin_t": -1.0}
			set_ctrl([[L.t("Tirar") + " · " + _fmt(int(BETS[bet_i])), slot_spin, left("slots") > 0]])
		"voltorb":
			g = {"board": [], "open": {}, "safe": 0, "live": false, "boom": -1}
			set_ctrl([[L.t("Empezar") + " · " + _fmt(int(BETS[bet_i])), volt_begin, left("voltorb") > 0]])
		"race":
			g = {"pick": -1, "t": -1.0, "win": -1}
			race_menu()
		"pika":
			g = {"st": "ready", "plan": -1, "t": 0.0}
			set_ctrl([[L.t("Empezar") + " · " + _fmt(PIKA_COST), pika_begin, left("pika") > 0]])


var g := {}
var field: Control = null
var ctrl: HBoxContainer = null
var msg_lbl: Label = null


# Botones de abajo: [texto, accion, activo]; siempre con "Otros juegos".
func set_ctrl(btns: Array) -> void:
	for c in ctrl.get_children():
		ctrl.remove_child(c)
		c.queue_free()
	for b in btns:
		var bb := gold_btn(String(b[0]), b[1])
		bb.disabled = not bool(b[2])
		ctrl.add_child(bb)
	ctrl.add_child(pill_btn("Otros juegos", func(): show_lobby(), false))
	var ll := txt(L.t("%d restantes") % left(screen), 16, C_SUB)
	ll.autowrap_mode = TextServer.AUTOWRAP_OFF
	ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ctrl.add_child(ll)


func charge(amount: int, game: String) -> bool:
	if left(game) <= 0 or coins() < amount:
		say("Sin monedas no hay juego, miau. La salida está por ahí.")
		return false
	SV.d["coins"] = coins() - amount
	plays[game] = int(plays.get(game, 0)) + 1
	SV.save()
	say("")
	return true


func pay(amount: int) -> void:
	if amount > 0:
		SV.d["coins"] = coins() + amount
		SV.save()
		Aud.sfx("coin")
	say("")


func result(text: String, good: bool) -> void:
	say(text)
	if say_lbl != null:
		say_lbl.add_theme_color_override("font_color", Color("#7dffb0") if good else Color("#ff8a96"))


# --- Tragaperras ---
func slot_pick() -> String:
	var tot := 0
	for k in SYM_W:
		tot += int(SYM_W[k])
	var r: int = randi() % tot
	for k in SYM_W:
		r -= int(SYM_W[k])
		if r < 0:
			return String(k)
	return "ball"


func slot_spin() -> void:
	if float(g.get("spin_t", -1.0)) >= 0.0:
		return
	var bet: int = int(BETS[bet_i])
	if not charge(bet, "slots"):
		return
	g["reels"] = [slot_pick(), slot_pick(), slot_pick()]
	g["spin_t"] = 0.0
	Aud.sfx("select")
	set_ctrl([[L.t("Tirar") + " · " + _fmt(bet), slot_spin, false]])


func slot_done() -> void:
	var r: Array = g["reels"]
	var bet: int = int(BETS[bet_i])
	var k := 0
	if r[0] == r[1] and r[1] == r[2]:
		k = int(PAY3[r[0]])
	elif r[0] == r[1] or r[1] == r[2] or r[0] == r[2]:
		k = 1
	pay(bet * k)
	if k >= 3 and r[0] == "R":
		var new_trail: bool = not bool(SV.d.get("rocket_trail", false))
		SV.d["rocket_trail"] = true
		SV.save()
		result(L.t("¡¡PREMIO GORDO!! +%s") % _fmt(bet * k) + (L.t(" y la estela Team Rocket") if new_trail else ""), true)
		Aud.sfx("legend")
	elif k >= 3:
		result(L.t("¡Tres iguales! +%s") % _fmt(bet * k), true)
	elif k == 1:
		result("Pareja: recuperas tu apuesta, miau.", true)
	else:
		result("La casa gana, miau.", false)
	set_ctrl([[L.t("Tirar") + " · " + _fmt(bet), slot_spin, left("slots") > 0 and coins() >= bet]])


# --- Voltorb escondido ---
func volt_begin() -> void:
	var bet: int = int(BETS[bet_i])
	if not charge(bet, "voltorb"):
		return
	var b: Array = []
	for i in range(9):
		b.append(i < 2)
	b.shuffle()
	g = {"board": b, "open": {}, "safe": 0, "live": true, "boom": -1}
	say("Elige una Poké Ball")
	set_ctrl([[L.t("Plantarse y cobrar"), volt_cash, false]])


func volt_pick(i: int) -> void:
	if not bool(g.get("live", false)) or (g["open"] as Dictionary).has(i):
		return
	if bool((g["board"] as Array)[i]):
		g["live"] = false
		g["boom"] = i
		field.boom(i)
		Aud.sfx("break")
		result("¡Voltorb! Pierdes la apuesta, miau.", false)
		set_ctrl([[L.t("Empezar") + " · " + _fmt(int(BETS[bet_i])), volt_begin, left("voltorb") > 0 and coins() >= int(BETS[bet_i])]])
		return
	g["safe"] = int(g["safe"]) + 1
	(g["open"] as Dictionary)[i] = float(VOLT_MULT[int(g["safe"]) - 1])
	Aud.sfx("coin")
	if int(g["safe"]) >= VOLT_MULT.size():
		volt_cash()
		return
	say(L.t("Premio: %s") % _fmt(int(floor(float(BETS[bet_i]) * float(VOLT_MULT[int(g["safe"]) - 1])))))
	set_ctrl([[L.t("Plantarse y cobrar"), volt_cash, true]])


func volt_cash() -> void:
	if not bool(g.get("live", false)) or int(g["safe"]) <= 0:
		return
	var prize: int = int(floor(float(BETS[bet_i]) * float(VOLT_MULT[int(g["safe"]) - 1])))
	g["live"] = false
	g["boom"] = -2   # se ensenan los Voltorb sin explotar
	pay(prize)
	result(L.t("¡Cobras %s, miau!") % _fmt(prize), true)
	set_ctrl([[L.t("Empezar") + " · " + _fmt(int(BETS[bet_i])), volt_begin, left("voltorb") > 0 and coins() >= int(BETS[bet_i])]])


# --- Carrera Rocket ---
func race_menu() -> void:
	for c in ctrl.get_children():
		ctrl.remove_child(c)
		c.queue_free()
	for i in RUNNERS.size():
		var idx: int = i
		var dex: int = int(RUNNERS[i][0])
		var p: Dictionary = SV.dex_by.get(dex, {})
		var b := gold_btn(L.t(String(p.get("name", "?"))) + " ×" + str(int(RUNNERS[i][1])), func(): race_go(idx))
		b.icon = idle_tex(dex)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
		b.disabled = left("race") <= 0 or coins() < int(BETS[bet_i]) or float(g.get("t", -1.0)) >= 0.0
		ctrl.add_child(b)
	ctrl.add_child(pill_btn("Otros juegos", func(): show_lobby(), false))


func race_go(i: int) -> void:
	if not charge(int(BETS[bet_i]), "race"):
		return
	var v := 0.0
	for r in RUNNERS:
		v += 1.0 / float(r[1])
	v = 1.0 / v
	var roll: float = randf()
	var win := 0
	for k in RUNNERS.size():
		roll -= v / float(RUNNERS[k][1])
		if roll < 0.0:
			win = k
			break
	var fin: Array = []
	for k in RUNNERS.size():
		fin.append(5.0 if k == win else randf_range(5.3, 6.4))
	g = {"pick": i, "t": -3.4, "win": win, "fin": fin, "done": false, "seed": randf() * 10.0}
	say(L.t("Tu corredor: %s") % L.t(String(SV.dex_by.get(int(RUNNERS[i][0]), {}).get("name", "?"))))
	race_menu()


func race_done() -> void:
	g["done"] = true
	var win: int = int(g["win"])
	var nm: String = L.t(String(SV.dex_by.get(int(RUNNERS[win][0]), {}).get("name", "?")))
	if win == int(g["pick"]):
		var prize: int = int(BETS[bet_i]) * int(RUNNERS[win][1])
		pay(prize)
		result(L.t("¡Gana %s! Te llevas %s.") % [nm, _fmt(prize)], true)
	else:
		result(L.t("¡Gana %s! La casa gana, miau.") % nm, false)
	g["t"] = -1.0
	race_menu()


# --- Atrapa a Pikachu ---
const PK_W := 480.0
const PK_H := 220.0
const LOOK := [172, 26, 311, 312, 417, 587, 702, 777, 877, 921]
const FINDS := [[6, 5.0, 30.0], [8, 4.0, 50.0], [10, 3.5, 70.0]]
const PLANS := [["PLAN A: la trampa del agujero", "Abre la trampilla justo cuando pise las hojas. Ni antes ni después."], ["PLAN B: ¿cuál es Pikachu?", "Toca al Pikachu de verdad entre los que se le parecen. ¡Ojo con Mimikyu!"], ["PLAN C: la red a prueba de rayos", "Dispara por delante de él: la red tarda en llegar. Tienes 3."]]


func pika_begin() -> void:
	if not charge(PIKA_COST, "pika"):
		return
	pika_plan(0)


func pika_plan(p: int) -> void:
	g = {"st": "card", "plan": p, "t": 0.0, "fx": []}
	Aud.sfx("select")
	say(String(PLANS[p][0]))
	set_ctrl([[L.t("¡Abrir!") if p == 0 else L.t("Toca la pantalla"), pika_open, false]])


func trap_path() -> Array:
	var pts: Array = [[0.0, -24.0, "stop"]]
	var st := {"t": 0.0, "x": -24.0}
	var walk := func(x: float, sp: float, mode: String):
		st["t"] = float(st["t"]) + absf(x - float(st["x"])) / sp
		st["x"] = x
		pts.append([float(st["t"]), x, mode])
	var stop := func(d: float):
		st["t"] = float(st["t"]) + d
		pts.append([float(st["t"]), float(st["x"]), "stop"])
	walk.call(110.0 + 40.0 * randf(), 80.0, "walk")
	stop.call(0.4 + 0.5 * randf())
	for i in range(1 + randi() % 2):
		walk.call(230.0 - 25.0 * randf(), 104.0, "walk")
		stop.call(0.3 + 0.6 * randf())
		walk.call(float(st["x"]) - 25.0 - 50.0 * randf(), 88.0, "back")
		stop.call(0.2 + 0.4 * randf())
	walk.call(230.0 - 15.0 * randf(), 104.0, "walk")
	stop.call(0.35 + randf())
	walk.call(510.0, 175.0, "dash")
	return pts


func trap_at(path: Array, t: float) -> Array:
	var last: Array = path[path.size() - 1]
	if t >= float(last[0]):
		return [float(last[1]), String(last[2]), true]
	var z := 1
	while float(path[z][0]) < t:
		z += 1
	var a: Array = path[z - 1]
	var b: Array = path[z]
	var u: float = (t - float(a[0])) / (float(b[0]) - float(a[0])) if float(b[0]) > float(a[0]) else 1.0
	return [lerpf(float(a[1]), float(b[1]), u), String(b[2]), false]


func crowd(round_i: int) -> Array:
	var f: Array = FINDS[round_i]
	var pool: Array = LOOK.duplicate()
	pool.shuffle()
	if round_i > 0:
		pool.push_front(778)   # Mimikyu disfrazado
	var list: Array = [25]
	list.append_array(pool.slice(0, int(f[0]) - 1))
	list.shuffle()
	var cols: int = ceili(sqrt(2.0 * float(list.size())))
	var rows: int = ceili(float(list.size()) / float(cols))
	var cw: float = (446.0 - 34.0) / float(cols)
	var ch: float = (208.0 - 82.0) / float(rows)
	var out: Array = []
	for i in list.size():
		var a: float = randf() * TAU
		out.append({"dex": int(list[i]), "x": 34.0 + cw * (float(i % cols) + 0.2 + 0.6 * randf()), "y": 82.0 + ch * (float(i / cols) + 0.2 + 0.6 * randf()),
			"vx": cos(a) * float(f[2]), "vy": sin(a) * float(f[2]), "turn": 0.4 + 1.2 * randf()})
	return out


func pika_fail(text: String) -> void:
	g["st"] = "fail"
	g["t"] = 0.0
	result(text, false)
	Aud.sfx("error")
	set_ctrl([[L.t("Sin más intentos"), pika_open, false]])


func pika_fx(x: float, y: float, col: Color, n: int = 14) -> void:
	for i in range(n):
		var a: float = randf() * TAU
		var s: float = randf_range(50.0, 170.0)
		(g["fx"] as Array).append({"x": x, "y": y, "vx": cos(a) * s, "vy": sin(a) * s, "t": 0.0, "life": randf_range(0.4, 0.8), "col": col})


# Boton "Abrir" (plan A) y toques en la pantalla (planes B y C), en coordenadas del campo (480x220).
func pika_open() -> void:
	pika_tap(-1.0, -1.0)


func pika_tap(x: float, y: float) -> void:
	if String(g.get("st", "")) != "play":
		return
	var p: int = int(g["plan"])
	if p == 0:
		if x >= 0.0:
			return
		var at: Array = trap_at(g["path"], float(g["t"]))
		if absf(float(at[0]) - 300.0) <= 16.0:
			g["st"] = "caught"
			g["t"] = 0.0
			g["x"] = float(at[0])
			result("¡Ha caído!...", true)
			Aud.sfx("hit")
			pika_fx(300.0, 170.0, Color("#c8a875"), 18)
		else:
			pika_fail("¡Demasiado pronto! Pikachu ha visto la trampa." if float(at[0]) < 300.0 else "¡Demasiado tarde!")
	elif p == 1 and x >= 0.0:
		var best = null
		var bd := 28.0
		for c in g["list"]:
			var d: float = Vector2(float(c["x"]) - x, float(c["y"]) - 14.0 - y).length()
			if d < bd:
				bd = d
				best = c
		if best == null:
			return
		if int(best["dex"]) != 25:
			pika_fail("¡Era Mimikyu, disfrazado! Y Pikachu lo ha visto todo." if int(best["dex"]) == 778 else L.t("¡Era %s! Y Pikachu lo ha visto todo.") % L.t(String(SV.dex_by.get(int(best["dex"]), {}).get("name", "?"))))
			return
		Aud.sfx("coin")
		pika_fx(float(best["x"]), float(best["y"]) - 14.0, GOLD, 16)
		g["round"] = int(g["round"]) + 1
		if int(g["round"]) >= FINDS.size():
			g["st"] = "found"
			g["t"] = 0.0
			result("¡Lo tienes! Pero echa a correr...", true)
			return
		g["t"] = 0.0
		g["list"] = crowd(int(g["round"]))
		say(L.t("¿Cuál es Pikachu? %d de %d") % [int(g["round"]) + 1, FINDS.size()])
	elif p == 2 and x >= 0.0:
		if g.get("net") != null or int(g["shots"]) <= 0:
			return
		g["shots"] = int(g["shots"]) - 1
		g["net"] = {"x": x, "y": y, "t": 0.0}
		Aud.sfx("select")
		say(L.t("Redes: %d") % int(g["shots"]))


func pika_tick(dt: float) -> void:
	if g.is_empty() or screen != "pika":
		return
	g["t"] = float(g.get("t", 0.0)) + dt
	var fx: Array = g.get("fx", [])
	for i in range(fx.size() - 1, -1, -1):
		var q: Dictionary = fx[i]
		q["t"] = float(q["t"]) + dt
		q["x"] = float(q["x"]) + float(q["vx"]) * dt
		q["y"] = float(q["y"]) + float(q["vy"]) * dt
		q["vy"] = float(q["vy"]) + 200.0 * dt
		if float(q["t"]) > float(q["life"]):
			fx.remove_at(i)
	var st: String = String(g.get("st", ""))
	var p: int = int(g.get("plan", -1))
	if st == "card" and float(g["t"]) >= 2.4:
		g["st"] = "play"
		g["t"] = 0.0
		if p == 0:
			g["path"] = trap_path()
			say("Espera...")
			set_ctrl([[L.t("¡Abrir!"), pika_open, true]])
		elif p == 1:
			g["round"] = 0
			g["list"] = crowd(0)
			say(L.t("¿Cuál es Pikachu? %d de %d") % [1, FINDS.size()])
			set_ctrl([[L.t("¡Toca a Pikachu!"), pika_open, false]])
		else:
			var a: float = randf() * TAU
			g["run"] = {"x": 240.0, "y": 160.0, "a": a, "speed": 170.0, "turn": randf_range(0.55, 1.1), "pause": 0.0}
			g["shots"] = 3
			g["net"] = null
			say(L.t("Redes: %d") % 3)
			set_ctrl([[L.t("Toca para disparar"), pika_open, false]])
	elif st == "caught" and float(g["t"]) >= 1.5:
		var keep: Array = g["fx"]
		pika_plan(1)
		g["fx"] = keep
	elif st == "found" and float(g["t"]) >= 0.9:
		pika_plan(2)
	elif st == "netted" and float(g["t"]) >= 1.0:
		g["st"] = "won"
		g["t"] = 0.0
		var stt: Dictionary = SV.d["stats"]
		stt["pikaWins"] = int(stt.get("pikaWins", 0)) + 1
		var fresh: bool = not bool(SV.d.get("rocket_skin", false))
		SV.d["rocket_skin"] = true
		SV.save()
		Aud.sfx("legend")
		result("¡¡POR FIN!! ¡Hemos atrapado a Pikachu! " + (L.t("La skin Mewtwo Obsidiana es tuya.") if fresh else ""), true)
		set_ctrl([[L.t("Sin más intentos"), pika_open, false]])
	elif st == "fail" and float(g["t"]) >= 2.1 and not bool(g.get("ended", false)):
		g["ended"] = true
		result("¡El Team Rocket sale volando otra vez!", false)
	elif st == "play":
		if p == 0:
			var at: Array = trap_at(g["path"], float(g["t"]))
			g["x"] = float(at[0])
			g["walk"] = String(at[1]) != "stop"
			g["back"] = String(at[1]) == "back"
			if String(at[1]) == "dash" and not bool(g.get("dashed", false)):
				g["dashed"] = true
				say("¡Ahora o nunca!")
			if bool(at[2]):
				pika_fail("Ha pasado de largo...")
		elif p == 1:
			var sp: float = float(FINDS[int(g["round"])][2])
			for c in g["list"]:
				c["x"] = float(c["x"]) + float(c["vx"]) * dt
				c["y"] = float(c["y"]) + float(c["vy"]) * dt * 0.7
				if float(c["x"]) < 34.0 or float(c["x"]) > 446.0:
					c["vx"] = -float(c["vx"])
					c["x"] = clampf(float(c["x"]), 34.0, 446.0)
				if float(c["y"]) < 82.0 or float(c["y"]) > 208.0:
					c["vy"] = -float(c["vy"])
					c["y"] = clampf(float(c["y"]), 82.0, 208.0)
				c["turn"] = float(c["turn"]) - dt
				if float(c["turn"]) <= 0.0:
					var a2: float = randf() * TAU
					c["vx"] = cos(a2) * sp
					c["vy"] = sin(a2) * sp
					c["turn"] = 0.4 + 1.2 * randf()
			if float(g["t"]) >= float(FINDS[int(g["round"])][1]):
				pika_fail("¡Se acabó el tiempo! Pikachu se ha dado cuenta.")
		else:
			var r: Dictionary = g["run"]
			if float(r["pause"]) > 0.0:
				r["pause"] = float(r["pause"]) - dt
				if float(r["pause"]) <= 0.0:
					r["a"] = randf() * TAU
					r["turn"] = randf_range(0.55, 1.1)
			else:
				r["x"] = float(r["x"]) + cos(float(r["a"])) * float(r["speed"]) * dt
				r["y"] = float(r["y"]) + sin(float(r["a"])) * float(r["speed"]) * dt * 0.7
				if float(r["x"]) < 40.0 or float(r["x"]) > 440.0:
					r["x"] = clampf(float(r["x"]), 40.0, 440.0)
					r["a"] = PI - float(r["a"])
				if float(r["y"]) < 100.0 or float(r["y"]) > 208.0:
					r["y"] = clampf(float(r["y"]), 100.0, 208.0)
					r["a"] = -float(r["a"])
				r["turn"] = float(r["turn"]) - dt
				if float(r["turn"]) <= 0.0:
					r["pause"] = 0.12
			var net = g.get("net")
			if net != null:
				net["t"] = float(net["t"]) + dt
				if float(net["t"]) >= 0.4:
					if Vector2(float(r["x"]) - float(net["x"]), float(r["y"]) - 14.0 - float(net["y"])).length() <= 22.0:
						g["st"] = "netted"
						g["t"] = 0.0
						Aud.sfx("hit")
						pika_fx(float(r["x"]), float(r["y"]) - 14.0, Color.WHITE, 16)
						result("¡Dentro de la red!", true)
						return
					pika_fx(float(net["x"]), float(net["y"]), Color("#dfe6f0"), 10)
					g["net"] = null
					r["speed"] = float(r["speed"]) * 1.2
					Aud.sfx("error")
					if int(g["shots"]) <= 0:
						pika_fail("¡Sin redes! Y Pikachu ya está cargando...")
						return
			if float(g["t"]) >= 10.0 and g.get("net") == null:
				pika_fail("¡Se acabó el tiempo! Pikachu se ha escapado.")


func _process(dt: float) -> void:
	if screen == "slots" and float(g.get("spin_t", -1.0)) >= 0.0:
		g["spin_t"] = float(g["spin_t"]) + dt
		if float(g["spin_t"]) >= 1.6:
			g["spin_t"] = -1.0
			slot_done()
	elif screen == "race" and g.has("fin") and not bool(g.get("done", false)):
		g["t"] = float(g["t"]) + dt
		if float(g["t"]) >= float(g["fin"][int(g["win"])]) + 0.3:
			race_done()
	elif screen == "pika":
		pika_tick(dt)


# ---------------------------------------------------------------
# Campo de juego (dibujado)
# ---------------------------------------------------------------
class Field extends Control:
	var casino
	var mode := ""
	var t := 0.0
	var boom_i := -1
	var boom_t := 0.0
	var tex := {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true

	func boom(i: int) -> void:
		boom_i = i
		boom_t = 0.0

	func _process(dt: float) -> void:
		t += dt
		boom_t += dt
		queue_redraw()

	func _tx(dex: int) -> Texture2D:
		if not tex.has(dex):
			tex[dex] = casino.idle_tex(dex)
		return tex[dex]

	func _mon(dex: int, p: Vector2, h: float, flip: bool = false, tint: Color = Color.WHITE) -> void:
		var tx: Texture2D = _tx(dex)
		if tx == null:
			return
		var w: float = h * float(tx.get_width()) / float(tx.get_height())
		draw_set_transform(p, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(tx, Rect2(Vector2(-w * 0.5, -h), Vector2(w, h)), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Escala del campo de Pikachu (480x220) dentro del panel.
	func _k() -> float:
		return minf(size.x / 480.0, size.y / 220.0)
	func _o() -> Vector2:
		var k: float = _k()
		return (size - Vector2(480.0, 220.0) * k) * 0.5
	func _fp(x: float, y: float) -> Vector2:
		return _o() + Vector2(x, y) * _k()

	func _gui_input(ev: InputEvent) -> void:
		var pos = null
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			pos = ev.position
		elif ev is InputEventScreenTouch and ev.pressed:
			pos = ev.position
		if pos == null:
			return
		if mode == "voltorb":
			var cells: Array = _volt_cells()
			for i in cells.size():
				if (cells[i] as Rect2).has_point(pos):
					casino.volt_pick(i)
					return
		elif mode == "pika":
			var q: Vector2 = (pos - _o()) / _k()
			casino.pika_tap(q.x, q.y)

	func _draw() -> void:
		match mode:
			"slots":
				_draw_slots()
			"voltorb":
				_draw_volt()
			"race":
				_draw_race()
			"pika":
				_draw_pika()

	# ---------- Tragaperras: una maquina grande con luces, rodillos y palanca ----------
	func _draw_slots() -> void:
		var RC = load("res://scripts/rocket_casino.gd")
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		var W: float = size.x
		var H: float = size.y
		draw_rect(Rect2(0, 0, W, H), Color("#1e0b2c"))
		for i in range(14):
			var a: float = float(i) / 14.0 * TAU + t * 0.15
			draw_line(Vector2(W * 0.5, H * 0.45), Vector2(W * 0.5, H * 0.45) + Vector2.from_angle(a) * W, Color(0.6, 0.3, 0.9, 0.06), 30.0)
		var mw: float = minf(W * 0.62, 560.0)
		var mr := Rect2(W * 0.5 - mw * 0.5, 14.0, mw, H - 28.0)
		var cab := StyleBoxFlat.new()
		cab.bg_color = Color("#c4223a")
		cab.border_color = Color("#ffd23f")
		cab.set_border_width_all(5)
		cab.set_corner_radius_all(22)
		cab.shadow_color = Color(0, 0, 0, 0.5)
		cab.shadow_size = 8
		draw_style_box(cab, mr)
		# luces del marco
		var n: int = 18
		for i in range(n):
			var u: float = float(i) / float(n - 1)
			var on: bool = (i + int(t * 8.0)) % 2 == 0
			var bc := Color("#fff3b0") if on else Color("#a07a20")
			draw_circle(Vector2(mr.position.x + 14.0 + u * (mw - 28.0), mr.position.y + 10.0), 4.0, bc)
			draw_circle(Vector2(mr.position.x + 14.0 + u * (mw - 28.0), mr.end.y - 10.0), 4.0, bc)
		draw_string_outline(f, Vector2(mr.position.x, mr.position.y + 44.0), "ROCKET SLOTS", HORIZONTAL_ALIGNMENT_CENTER, mw, 28, 6, Color("#5a0a12"))
		draw_string(f, Vector2(mr.position.x, mr.position.y + 44.0), "ROCKET SLOTS", HORIZONTAL_ALIGNMENT_CENTER, mw, 28, Color("#ffe066"))
		# ventana de rodillos
		var rw: float = mw * 0.24
		var rh: float = minf(H * 0.5, 120.0)
		var ry: float = mr.position.y + 60.0
		var win := Rect2(W * 0.5 - rw * 1.6, ry - 8.0, rw * 3.2, rh + 16.0)
		draw_rect(win, Color("#1b0d1e"))
		draw_rect(win, Color("#ffd23f"), false, 4.0)
		var syms: Array = ["ball", "ball2", "ball3", "ballLux", "ball4", "R"]
		var reels: Array = casino.g.get("reels", ["ball", "ball", "ball"])
		var st: float = float(casino.g.get("spin_t", -1.0))
		for i in range(3):
			var rr := Rect2(W * 0.5 - rw * 1.5 + float(i) * rw * 1.0 + 4.0, ry, rw - 8.0, rh)
			draw_rect(rr, Color("#fbf6ec"))
			var stop_at: float = 0.7 + 0.35 * float(i)
			var c: Vector2 = rr.get_center()
			if st >= 0.0 and st < stop_at:
				var off: float = fmod(st * 900.0 + float(i) * 37.0, rh)
				for k in range(-1, 2):
					var sy: float = c.y + float(k) * rh * 0.62 + off - rh * 0.31
					if sy > rr.position.y - 10.0 and sy < rr.end.y + 10.0:
						_sym(String(syms[(int(st * 14.0) + k + i * 2 + 9) % syms.size()]), Vector2(c.x, sy), rh * 0.24, f)
				draw_rect(Rect2(rr.position, Vector2(rr.size.x, 10)), Color(0.85, 0.8, 0.75, 0.8))
				draw_rect(Rect2(Vector2(rr.position.x, rr.end.y - 10), Vector2(rr.size.x, 10)), Color(0.85, 0.8, 0.75, 0.8))
			else:
				_sym(String(reels[i]), c, rh * 0.3, f)
			draw_rect(rr, Color("#8a1428"), false, 3.0)
		draw_line(Vector2(win.position.x + 6, ry + rh * 0.5), Vector2(win.end.x - 6, ry + rh * 0.5), Color(1.0, 0.3, 0.35, 0.5), 2.0)
		# palanca
		var lx: float = mr.end.x + 18.0
		var pull: float = clampf(1.0 - absf(st - 0.25) * 4.0, 0.0, 1.0) if st >= 0.0 else 0.0
		draw_rect(Rect2(lx - 6, ry + 20, 14, 46), Color("#9aa3b5"))
		var top := Vector2(lx + 1, ry + 20 - 50.0 + pull * 70.0)
		draw_line(Vector2(lx + 1, ry + 40), top, Color("#c9d0dc"), 7.0)
		draw_circle(top, 14.0, Color("#e8333f"))
		draw_circle(top + Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.7))
		# tabla de premios
		var py: float = mr.end.y - 34.0
		var items: Array = [["R", 20], ["ball4", 18], ["ballLux", 12], ["ball3", 8], ["ball2", 5], ["ball", 3]]
		var step: float = (mw - 40.0) / float(items.size())
		for i in items.size():
			var px: float = mr.position.x + 20.0 + step * (float(i) + 0.5)
			_sym(String(items[i][0]), Vector2(px - 16.0, py), 11.0, f)
			draw_string(f, Vector2(px - 2.0, py + 7.0), "×" + str(int(items[i][1])), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff3b0"))

	func _sym(k: String, c: Vector2, r: float, f: Font) -> void:
		if k == "R":
			var fs: int = int(r * 2.2)
			draw_string_outline(f, c + Vector2(-r * 0.62, r * 0.72), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color("#5a0a12"))
			draw_string(f, c + Vector2(-r * 0.62, r * 0.72), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#e8333f"))
		else:
			load("res://scripts/rocket_casino.gd").draw_ball(self, c, r, k)

	# ---------- Voltorb escondido: mesa de fieltro con 9 Poke Balls ----------
	func _volt_cells() -> Array:
		var cs: float = minf((size.y - 30.0) / 3.0, 78.0)
		var gw: float = cs * 3.0 + 16.0
		var o := Vector2(size.x * 0.5 - gw * 0.5, (size.y - gw) * 0.5)
		var out: Array = []
		for i in range(9):
			out.append(Rect2(o + Vector2(float(i % 3) * (cs + 8.0), float(i / 3) * (cs + 8.0)), Vector2(cs, cs)))
		return out

	func _draw_volt() -> void:
		var RC = load("res://scripts/rocket_casino.gd")
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		var W: float = size.x
		var H: float = size.y
		draw_rect(Rect2(0, 0, W, H), Color("#0c2246"))
		# mesa
		var tw: float = minf(W * 0.5, 420.0)
		var tr := Rect2(W * 0.5 - tw * 0.5, 6.0, tw, H - 12.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#1c6b3e")
		sb.border_color = Color("#8a5a2a")
		sb.set_border_width_all(10)
		sb.set_corner_radius_all(28)
		draw_style_box(sb, tr)
		for i in range(40):
			var px: float = tr.position.x + 16.0 + fmod(float(i) * 97.0, tw - 32.0)
			var py: float = tr.position.y + 16.0 + fmod(float(i) * 61.0, tr.size.y - 32.0)
			draw_rect(Rect2(px, py, 2, 2), Color(1, 1, 1, 0.06))
		var g: Dictionary = casino.g
		var board: Array = g.get("board", [])
		var opened: Dictionary = g.get("open", {})
		var b: int = int(g.get("boom", -1))
		var cells: Array = _volt_cells()
		for i in cells.size():
			var r: Rect2 = cells[i]
			var c: Vector2 = r.get_center()
			var shown_volt: bool = board.size() == 9 and bool(board[i]) and b != -1
			if opened.has(i):
				var chip := StyleBoxFlat.new()
				chip.bg_color = Color("#ffd23f")
				chip.border_color = Color("#fff6c8")
				chip.set_border_width_all(3)
				chip.set_corner_radius_all(14)
				draw_style_box(chip, r.grow(-6))
				draw_string(f, Vector2(r.position.x, c.y + 9.0), "×" + str(opened[i]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color("#5a3a00"))
			elif shown_volt:
				var k: float = 1.0 + (0.25 * sin(boom_t * 30.0) if i == b and boom_t < 0.6 else 0.0)
				if i == b and boom_t < 0.8:
					draw_circle(c, r.size.x * 0.55 * (1.0 + boom_t), Color(1.0, 0.75, 0.2, maxf(0.0, 0.7 - boom_t)))
				_mon(100, c + Vector2(0, r.size.y * 0.42), r.size.y * 0.95 * k)
			else:
				var hov: float = 0.06 * sin(t * 3.0 + float(i))
				draw_circle(c + Vector2(0, 5), r.size.x * 0.36, Color(0, 0, 0, 0.25))
				RC.draw_ball(self, c, r.size.x * (0.36 + hov * 0.1), "ball")
		# multiplicadores a la derecha
		var mx: float = tr.end.x + 24.0
		var safe: int = int(g.get("safe", 0))
		for i in range(7):
			var y: float = 18.0 + float(i) * (H - 36.0) / 7.0
			var lit: bool = i < safe
			var cr := Rect2(mx, y, 90.0, (H - 36.0) / 7.0 - 6.0)
			var s2 := StyleBoxFlat.new()
			s2.bg_color = Color("#ffd23f") if lit else Color(1, 1, 1, 0.06)
			s2.set_corner_radius_all(10)
			draw_style_box(s2, cr)
			draw_string(f, Vector2(cr.position.x, cr.get_center().y + 7.0), "×" + str(casino.VOLT_MULT[i]), HORIZONTAL_ALIGNMENT_CENTER, 90.0, 20, Color("#5a3a00") if lit else Color("#9fb4dc"))
		_mon(100, Vector2(tr.position.x - 70.0, H - 20.0), 110.0)
		draw_string(f, Vector2(tr.position.x - 130.0, 40.0), "× 2", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 28, Color("#ff8a96"))

	# ---------- Carrera Rocket: grada, pista de tierra y meta a cuadros ----------
	func _draw_race() -> void:
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		var W: float = size.x
		var H: float = size.y
		# cielo y grada
		_sky(Color("#5ab8f0"), Color("#bfe8ff"), H * 0.3)
		draw_rect(Rect2(0, H * 0.14, W, H * 0.18), Color("#6a4a8a"))
		for i in range(int(W / 18.0)):
			var cc: Array = [Color("#ffd23f"), Color("#ff6b7a"), Color("#7fd0ff"), Color("#9ef28c"), Color("#f4f0e8")]
			var bob: float = absf(sin(t * 6.0 + float(i))) * 3.0
			draw_circle(Vector2(float(i) * 18.0 + 9.0, H * 0.2 - bob), 6.0, cc[i % cc.size()])
			draw_circle(Vector2(float(i) * 18.0 + 9.0 + 6.0, H * 0.28 - bob * 0.5), 6.0, cc[(i + 2) % cc.size()])
		draw_rect(Rect2(0, H * 0.3, W, 6.0), Color("#ffffff"))
		for i in range(int(W / 24.0)):
			draw_rect(Rect2(float(i) * 24.0, H * 0.3, 12.0, 6.0), Color("#e8333f"))
		_grass(Rect2(0, H * 0.32, W, H * 0.68))
		# pista
		var lanes: int = 4
		var top: float = H * 0.38
		var lh: float = (H * 0.95 - top) / float(lanes)
		draw_rect(Rect2(0, top, W, lh * float(lanes)), Color("#c49a5e"))
		for l in range(lanes + 1):
			draw_rect(Rect2(0, top + float(l) * lh - 2.0, W, 4.0), Color("#f4f0e8"))
		for i in range(60):
			draw_rect(Rect2(fmod(float(i) * 83.0, W), top + fmod(float(i) * 37.0, lh * float(lanes)), 4, 3), Color("#a8804a"))
		var fx: float = W * 0.86
		for j in range(int(lh * float(lanes) / 10.0)):
			for k in range(2):
				if (j + k) % 2 == 0:
					draw_rect(Rect2(fx + float(k) * 10.0, top + float(j) * 10.0, 10, 10), Color("#20242c"))
				else:
					draw_rect(Rect2(fx + float(k) * 10.0, top + float(j) * 10.0, 10, 10), Color.WHITE)
		var g: Dictionary = casino.g
		var tt: float = float(g.get("t", -1.0))
		var fin: Array = g.get("fin", [])
		var x0: float = 40.0
		for l in range(lanes):
			var dex: int = int(casino.RUNNERS[l][0])
			var x: float = x0
			if fin.size() == 4 and tt > 0.0:
				var u: float = clampf(tt / float(fin[l]), 0.0, 1.0)
				u = u + sin(tt * 3.0 + float(l) * 1.7 + float(g.get("seed", 0.0))) * 0.03 * (1.0 - u) * u * 4.0
				x = lerpf(x0, fx + 20.0, clampf(u, 0.0, 1.0))
			var y: float = top + float(l + 1) * lh - 6.0
			if l == int(g.get("pick", -1)):
				draw_rect(Rect2(x - 4, y - lh + 8, 8, 8), Color("#ffd23f"))
			var hop: float = absf(sin(t * 14.0 + float(l))) * 4.0 if tt > 0.0 else 0.0
			_mon(dex, Vector2(x, y - hop), lh * 1.25)
		if tt < 0.0 and fin.size() == 4:
			draw_string_outline(f, Vector2(0, H * 0.62), str(ceili(-tt)), HORIZONTAL_ALIGNMENT_CENTER, W, 64, 10, Color("#1b1528"))
			draw_string(f, Vector2(0, H * 0.62), str(ceili(-tt)), HORIZONTAL_ALIGNMENT_CENTER, W, 64, Color.WHITE)

	# ---------- utilidades de paisaje ----------
	func _sky(c0: Color, c1: Color, h: float) -> void:
		var steps := 12
		for i in range(steps):
			draw_rect(Rect2(0, h * float(i) / float(steps), size.x, h / float(steps) + 1.0), c0.lerp(c1, float(i) / float(steps - 1)))

	func _cloud(p: Vector2, s: float, a: float = 0.95) -> void:
		var c := Color(1, 1, 1, a)
		draw_circle(p, 14.0 * s, c)
		draw_circle(p + Vector2(16, 4) * s, 11.0 * s, c)
		draw_circle(p + Vector2(-15, 5) * s, 10.0 * s, c)
		draw_rect(Rect2(p + Vector2(-24, 4) * s, Vector2(50, 10) * s), c)

	# Cesped bonito: degradado, matas de hierba y flores.
	func _grass(r: Rect2, dark: Color = Color("#3f8a3c"), light: Color = Color("#6cc35a")) -> void:
		var steps := 6
		for i in range(steps):
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * float(i) / float(steps), r.size.x, r.size.y / float(steps) + 1.0), light.lerp(dark, float(i) / float(steps - 1)))
		for i in range(int(r.size.x * r.size.y / 900.0)):
			var x: float = r.position.x + fmod(float(i) * 97.3, r.size.x)
			var y: float = r.position.y + 6.0 + fmod(float(i) * 61.7, r.size.y - 6.0)
			var sway: float = sin(t * 2.0 + float(i)) * 1.5
			var gc: Color = dark.darkened(0.15) if i % 2 == 0 else light.lightened(0.12)
			draw_line(Vector2(x, y), Vector2(x - 3 + sway, y - 7), gc, 2.0)
			draw_line(Vector2(x + 3, y), Vector2(x + 4 + sway, y - 9), gc, 2.0)
		var fl: Array = [Color("#ffffff"), Color("#ffd23f"), Color("#ff8ad8"), Color("#ff6b6b")]
		for i in range(int(r.size.x / 40.0)):
			var x2: float = r.position.x + fmod(float(i) * 173.0 + 30.0, r.size.x)
			var y2: float = r.position.y + 10.0 + fmod(float(i) * 79.0, r.size.y - 14.0)
			var fc: Color = fl[i % fl.size()]
			for k in range(4):
				draw_circle(Vector2(x2, y2) + Vector2.from_angle(float(k) * PI * 0.5) * 3.0, 2.5, fc)
			draw_circle(Vector2(x2, y2), 2.0, Color("#ffb020"))

	func _tree(p: Vector2, s: float, col: Color = Color("#2f7a3a")) -> void:
		draw_rect(Rect2(p + Vector2(-5, -18) * s, Vector2(10, 22) * s), Color("#6b4423"))
		draw_circle(p + Vector2(0, -34) * s, 22.0 * s, col.darkened(0.2))
		draw_circle(p + Vector2(-12, -26) * s, 15.0 * s, col)
		draw_circle(p + Vector2(12, -28) * s, 15.0 * s, col)
		draw_circle(p + Vector2(-5, -42) * s, 12.0 * s, col.lightened(0.15))

	func _pine(p: Vector2, s: float, col: Color) -> void:
		for k in range(3):
			var w: float = (26.0 - float(k) * 6.0) * s
			var y: float = p.y - float(k) * 16.0 * s
			draw_colored_polygon(PackedVector2Array([Vector2(p.x - w, y), Vector2(p.x + w, y), Vector2(p.x, y - 26.0 * s)]), col.lightened(float(k) * 0.06))
		draw_rect(Rect2(p + Vector2(-4, 0) * s, Vector2(8, 10) * s), Color("#4a3018"))

	func _balloon(p: Vector2, s: float) -> void:
		# globo con cara de Meowth y cesta
		draw_line(p + Vector2(-14, 26) * s, p + Vector2(-10, 46) * s, Color("#6b4423"), 2.0)
		draw_line(p + Vector2(14, 26) * s, p + Vector2(10, 46) * s, Color("#6b4423"), 2.0)
		draw_rect(Rect2(p + Vector2(-14, 44) * s, Vector2(28, 14) * s), Color("#a8683a"))
		draw_circle(p, 30.0 * s, Color("#f4dfa8"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-26, -14) * s, p + Vector2(-20, -40) * s, p + Vector2(-8, -24) * s]), Color("#f4dfa8"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(26, -14) * s, p + Vector2(20, -40) * s, p + Vector2(8, -24) * s]), Color("#f4dfa8"))
		draw_circle(p + Vector2(0, -20) * s, 6.0 * s, Color("#ffd23f"))
		draw_circle(p + Vector2(-10, -2) * s, 5.0 * s, Color("#1b1528"))
		draw_circle(p + Vector2(10, -2) * s, 5.0 * s, Color("#1b1528"))
		draw_line(p + Vector2(-6, 12) * s, p + Vector2(6, 12) * s, Color("#1b1528"), 2.0)
		for k in range(3):
			draw_line(p + Vector2(-14, 6 + k * 4) * s, p + Vector2(-34, 2 + k * 6) * s, Color("#1b1528"), 1.5)
			draw_line(p + Vector2(14, 6 + k * 4) * s, p + Vector2(34, 2 + k * 6) * s, Color("#1b1528"), 1.5)

	# ---------- Atrapa a Pikachu: tres escenarios ----------
	func _draw_pika() -> void:
		var f: Font = load("res://scripts/pxfont.gd").get_font()
		var g: Dictionary = casino.g
		var plan: int = int(g.get("plan", 0))
		var W: float = size.x
		var H: float = size.y
		var k: float = _k()
		if plan <= 0:
			# Plan A: pradera de dia con camino y el monton de hojas
			_sky(Color("#5ab8f0"), Color("#d4f0ff"), H * 0.45)
			draw_circle(Vector2(W * 0.85, H * 0.14), 22.0, Color("#fff3b0"))
			draw_circle(Vector2(W * 0.85, H * 0.14), 30.0, Color(1.0, 0.95, 0.6, 0.25))
			_cloud(Vector2(fmod(W * 0.2 + t * 8.0, W + 80.0) - 40.0, H * 0.12), 1.1)
			_cloud(Vector2(fmod(W * 0.6 + t * 5.0, W + 80.0) - 40.0, H * 0.2), 0.8)
			for i in range(6):
				draw_circle(Vector2(float(i) * W / 5.0, H * 0.48), W * 0.13, Color("#7cc06a"))
			_grass(Rect2(0, H * 0.42, W, H * 0.58))
			for i in range(int(W / 26.0) + 1):
				draw_rect(Rect2(float(i) * 26.0, H * 0.4, 6, 28), Color("#c9a26a"))
			draw_rect(Rect2(0, H * 0.43, W, 5), Color("#a8804a"))
			draw_rect(Rect2(0, H * 0.5, W, 5), Color("#a8804a"))
			_tree(Vector2(W * 0.08, H * 0.62), 1.6)
			_tree(Vector2(W * 0.94, H * 0.6), 1.4)
			var road := _fp(0, 150)
			draw_rect(Rect2(0, road.y, W, 46.0 * k), Color("#d6ad6e"))
			draw_rect(Rect2(0, road.y, W, 4), Color("#b88a4e"))
			draw_rect(Rect2(0, road.y + 42.0 * k, W, 4), Color("#b88a4e"))
			var lp := _fp(300, 172)
			var opened: bool = String(g.get("st", "")) == "caught"
			if opened:
				draw_set_transform(lp, 0.0, Vector2(1.0, 0.45))
				draw_circle(Vector2.ZERO, 26.0 * k, Color("#2a1a10"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				for i in range(22):
					var a: float = float(i) * 2.4
					var rr: float = fmod(float(i) * 7.0, 22.0) * k
					draw_circle(lp + Vector2(cos(a) * rr, sin(a) * rr * 0.4), 6.0 * k, [Color("#4c8a3a"), Color("#6aa84a"), Color("#a8803a")][i % 3])
			_balloon(_fp(70, 40 + sin(t * 1.5) * 4.0), 0.9 * k)
			if String(g.get("st", "")) == "play" or opened:
				var px: float = float(g.get("x", -24.0))
				var pp := _fp(px, 172 + (18.0 if opened else 0.0))
				var hop: float = absf(sin(t * 12.0)) * 3.0 if bool(g.get("walk", false)) else 0.0
				_mon(25, pp - Vector2(0, hop), 46.0 * k, bool(g.get("back", false)), Color.WHITE if not opened else Color(1, 1, 1, maxf(0.0, 1.0 - float(g.get("t", 0.0)))))
		elif plan == 1:
			# Plan B: parque al atardecer con farolas
			_sky(Color("#ff8a5a"), Color("#ffd7a0"), H * 0.42)
			draw_circle(Vector2(W * 0.5, H * 0.36), 34.0, Color("#ffef9a"))
			for i in range(14):
				var bw: float = 30.0 + fmod(float(i) * 13.0, 30.0)
				var bh: float = 30.0 + fmod(float(i) * 29.0, 50.0)
				draw_rect(Rect2(float(i) * W / 13.0 - 10.0, H * 0.4 - bh, bw, bh), Color("#8a4a6a"))
			_grass(Rect2(0, H * 0.38, W, H * 0.62), Color("#3a7a3a"), Color("#6aaa4a"))
			for i in range(4):
				var lx: float = W * (0.12 + 0.25 * float(i))
				draw_rect(Rect2(lx - 2, H * 0.18, 4, H * 0.22), Color("#3a3a4a"))
				draw_circle(Vector2(lx, H * 0.18), 7.0, Color("#fff3b0"))
				draw_circle(Vector2(lx, H * 0.18), 14.0, Color(1.0, 0.95, 0.6, 0.25))
			for i in range(5):
				_tree(Vector2(W * (0.05 + 0.23 * float(i)), H * 0.42), 0.9, Color("#3a8a3a"))
			var list: Array = g.get("list", [])
			for c in list:
				var cp := _fp(float(c["x"]), float(c["y"]))
				draw_set_transform(cp, 0.0, Vector2(1.0, 0.35))
				draw_circle(Vector2.ZERO, 12.0 * k, Color(0, 0, 0, 0.25))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				_mon(int(c["dex"]), cp, 40.0 * k, float(c["vx"]) < 0.0)
			if String(g.get("st", "")) == "play" and g.has("round"):
				var left_t: float = maxf(0.0, float(casino.FINDS[int(g["round"])][1]) - float(g["t"]))
				draw_rect(Rect2(10, 10, (W - 20.0) * left_t / float(casino.FINDS[int(g["round"])][1]), 8), Color("#ffd23f"))
		else:
			# Plan C: claro del bosque al anochecer
			_sky(Color("#2a2a6a"), Color("#c87ab0"), H * 0.45)
			for i in range(18):
				var sx: float = fmod(float(i) * 131.0, W)
				var sy: float = fmod(float(i) * 47.0, H * 0.3)
				draw_circle(Vector2(sx, sy), 1.5 + 0.8 * sin(t * 3.0 + float(i)), Color(1, 1, 0.9, 0.8))
			draw_circle(Vector2(W * 0.15, H * 0.14), 18.0, Color("#f4f0e0"))
			for i in range(12):
				_pine(Vector2(float(i) * W / 11.0, H * 0.46), 1.4, Color("#1f4a3a"))
			_grass(Rect2(0, H * 0.42, W, H * 0.58), Color("#2a5a3a"), Color("#4a8a4a"))
			for i in range(8):
				var fx: float = fmod(float(i) * 97.0 + t * 20.0, W)
				var fy: float = H * 0.5 + fmod(float(i) * 41.0, H * 0.4) + sin(t * 2.0 + float(i)) * 6.0
				draw_circle(Vector2(fx, fy), 2.5, Color(1.0, 1.0, 0.5, 0.5 + 0.4 * sin(t * 4.0 + float(i))))
			if g.has("run"):
				var r: Dictionary = g["run"]
				var rp := _fp(float(r["x"]), float(r["y"]))
				draw_set_transform(rp, 0.0, Vector2(1.0, 0.35))
				draw_circle(Vector2.ZERO, 14.0 * k, Color(0, 0, 0, 0.3))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if String(g.get("st", "")) != "netted" and String(g.get("st", "")) != "won":
					for q in range(3):
						var a: float = t * 9.0 + float(q) * 2.1
						draw_line(rp + Vector2(cos(a), sin(a) - 1.4) * 22.0 * k, rp + Vector2(cos(a + 0.3), sin(a + 0.3) - 1.4) * 30.0 * k, Color("#fff36a"), 2.0)
				_mon(25, rp, 46.0 * k, cos(float(r["a"])) < 0.0)
				if String(g.get("st", "")) == "netted" or String(g.get("st", "")) == "won":
					_net(rp + Vector2(0, -14.0 * k), 24.0 * k)
			var net = g.get("net")
			if net != null:
				var from := _fp(52, 92)
				var to := _fp(float(net["x"]), float(net["y"]))
				var u: float = clampf(float(net["t"]) / 0.4, 0.0, 1.0)
				_net(from.lerp(to, u) + Vector2(0, -sin(u * PI) * 30.0 * k), 22.0 * k * (0.5 + 0.5 * u))
			_balloon(_fp(52, 60 + sin(t * 1.5) * 4.0), 0.8 * k)
			draw_string(f, Vector2(W - 120, 30), "🕸 " + str(int(g.get("shots", 0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		# efectos
		for q in g.get("fx", []):
			var a2: float = 1.0 - float(q["t"]) / float(q["life"])
			draw_circle(_fp(float(q["x"]), float(q["y"])), 3.0 * k, Color(q["col"], a2))
		# tarjeta del plan
		var st: String = String(g.get("st", ""))
		if st == "card" or st == "ready":
			draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.02, 0.1, 0.65))
			var title: String = load("res://scripts/lang.gd").t(String(casino.PLANS[plan][0])) if st == "card" else load("res://scripts/lang.gd").t("Pulsa Empezar")
			draw_string_outline(f, Vector2(0, H * 0.42), title, HORIZONTAL_ALIGNMENT_CENTER, W, 34, 8, Color("#3a0a12"))
			draw_string(f, Vector2(0, H * 0.42), title, HORIZONTAL_ALIGNMENT_CENTER, W, 34, Color("#ffe066"))
			if st == "card":
				draw_string(f, Vector2(40, H * 0.58), load("res://scripts/lang.gd").t(String(casino.PLANS[plan][1])), HORIZONTAL_ALIGNMENT_CENTER, W - 80.0, 20, Color.WHITE)
		elif st == "fail" and float(g.get("t", 0.0)) < 2.0:
			var tt: float = float(g["t"])
			var p := Vector2(W * 0.5 + tt * 220.0, H * 0.6 - tt * 260.0)
			draw_circle(p, 10.0 + tt * 6.0, Color("#fff36a", maxf(0.0, 1.0 - tt * 0.5)))
		elif st == "won":
			for i in range(16):
				var a3: float = float(i) / 16.0 * TAU + t
				draw_line(Vector2(W, H) * 0.5, Vector2(W, H) * 0.5 + Vector2.from_angle(a3) * W, Color(1.0, 0.9, 0.4, 0.12), 18.0)

	func _net(c: Vector2, r: float) -> void:
		draw_arc(c, r, 0.0, TAU, 24, Color(0.95, 0.96, 1.0, 0.95), 2.0)
		for v in range(-3, 4):
			var w: float = float(v) / 3.4 * r
			var hh: float = sqrt(maxf(0.0, r * r - w * w))
			draw_line(c + Vector2(w, -hh), c + Vector2(w, hh), Color(0.95, 0.96, 1.0, 0.8), 1.0)
			draw_line(c + Vector2(-hh, w), c + Vector2(hh, w), Color(0.95, 0.96, 1.0, 0.8), 1.0)
