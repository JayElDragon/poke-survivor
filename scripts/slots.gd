extends Control
# Tragaperras pixel art del gacha (slots.js del original). Se dibuja a resolucion de arte
# (176x170) y se amplia con un factor entero. Palanca -> giran los 3 rodillos -> paran uno a
# uno en la bola de la rareza obtenida. Si es Epica, Legendaria o shiny el ultimo rodillo se
# hace esperar y las luces se vuelven locas. La x10 son 10 tiradas rapidas; cada premio cae
# a la bandeja. Un toque / boton acelera la animacion.

const IC = preload("res://scripts/icons.gd")
const Aud = preload("res://scripts/audio.gd")
const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")

signal finished

const W := 176.0
const H := 170.0
const CELL := 30.0
const STRIP := ["ball", "ball2", "ball", "ball3", "ball", "ball2", "ballLux", "ball", "ball4", "ball2", "ball3", "shiny", "ball", "ball2"]
const SYM := ["ball", "ball2", "ball3", "ball4", "ballLux"]
const RCOL := ["#cfd6e6", "#5fe08a", "#6bb6ff", "#c47bff", "#ffd23f"]
const REEL_X := [26.0, 65.0, 104.0]
const REEL_W := 36.0
const REEL_Y := 44.0
const REEL_H := 46.0
const MID := 67.0

const C_BODY := Color("#c8323c")
const C_BODY_D := Color("#8e1f2a")
const C_BODY_L := Color("#ef6464")
const C_TRIM := Color("#ffd23f")
const C_TRIM_D := Color("#c08a10")
const C_DARK := Color("#1b1528")
const C_GLASS := Color("#0d1230")
const C_REEL := Color("#f4efe2")
const C_REEL_D := Color("#c9c1ad")
const C_CHROME := Color("#c9d2de")
const C_CHROME_D := Color("#7d8899")
const C_LED := Color("#2a0f14")
const C_BULB_ON := Color("#ffe9a0")
const C_BULB_OFF := Color("#6b4a20")

var running := false
var fast := false
var k := 3.0
var org := Vector2.ZERO
var t := 0.0
var lever := 0.0
var reels: Array = []
var tray: Array = []
var sparks: Array = []
var ten := false
var led := ""
var led_col: Color = C_BULB_ON
var win_col: Color = Color.WHITE
var win_t := -1.0
var frenzy := false
var tick_acc := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func _gui_input(event: InputEvent) -> void:
	if running and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)):
		fast = true


func _input(event: InputEvent) -> void:
	if not running or not is_visible_in_tree():
		return
	# Un toque, clic, tecla o boton acelera la animacion. La tirada ya esta hecha antes de empezar (SV.pull), asi que acelerar nunca cobra otra.
	if (event is InputEventJoypadButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		fast = true
		get_viewport().set_input_as_handled()


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _wait(s: float) -> void:
	var end: float = _now() + s * (0.25 if fast else 1.0)
	while running and _now() < end:
		await get_tree().process_frame


func _tween(setter: Callable, a: float, b: float, dur: float) -> void:
	var t0: float = _now()
	var d: float = maxf(0.001, dur * (0.25 if fast else 1.0))
	while running:
		var kk: float = minf(1.0, (_now() - t0) / d)
		setter.call(a + (b - a) * kk)
		if kk >= 1.0:
			break
		await get_tree().process_frame


func _sym_of(r: Dictionary) -> String:
	return "shiny" if bool(r["shiny"]) else String(SYM[clampi(int(r["rarity"]), 1, 5) - 1])


func _col_of(r: Dictionary) -> Color:
	return Color("#9ae6ff") if bool(r["shiny"]) else Color(String(RCOL[clampi(int(r["rarity"]), 1, 5) - 1]))


func _rname(rar: int) -> String:
	return L.t(String(SV.RARITY_NAME[clampi(rar, 1, 5) - 1])).to_upper()


# Anima las tiradas. Al terminar emite "finished".
func play(results: Array) -> void:
	fast = false
	running = true
	t = 0.0
	lever = 0.0
	tray = []
	sparks = []
	frenzy = false
	win_t = -1.0
	ten = results.size() == 10
	led = L.t("TIRADA ×10") if ten else L.t("¡SUERTE!")
	led_col = C_BULB_ON
	reels = []
	for i in range(3):
		reels.append({"off": randf() * 400.0, "spin": false, "sym": "ball", "bounce": 0.0, "speed": 0.0})
	visible = true
	_layout()
	for i in range(results.size()):
		if not running:
			break
		var r: Dictionary = results[i]
		if ten:
			led = L.t("TIRADA %d/10") % (i + 1)
		Aud.sfx("ball")
		await _tween(func(v): lever = v, 0.0, 1.0, 0.12 if ten else 0.22)
		for rl in reels:
			rl["spin"] = true
			rl["speed"] = 520.0
		await _tween(func(v): lever = v, 1.0, 0.0, 0.1 if ten else 0.2)
		win_t = -1.0
		await _wait(0.18 if ten else 0.6)
		var rar: int = clampi(int(r["rarity"]), 1, 5)
		var big: bool = rar >= 4 or bool(r["shiny"])
		for kk in range(3):
			if kk == 2 and big:
				frenzy = true
				led = L.t("¡¿SHINY?!") if bool(r["shiny"]) else (L.t("¡¿LEGENDARIO?!") if rar == 5 else L.t("¡¿ÉPICO?!"))
				led_col = _col_of(r)
				await _tween(func(v): reels[2]["speed"] = v, 520.0, 120.0, 0.5 if ten else 1.1)
			var rl: Dictionary = reels[kk]
			rl["spin"] = false
			rl["sym"] = _sym_of(r)
			rl["bounce"] = 1.0
			rl["speed"] = 0.0
			Aud.sfx("shake")
			await _wait(0.08 if ten else 0.32)
		frenzy = false
		win_col = _col_of(r)
		win_t = 0.0
		led = (L.t("SHINY · %s") % _rname(rar)) if bool(r["shiny"]) else _rname(rar)
		led_col = win_col
		Aud.sfx("reveal%d" % rar)
		if rar == 5:
			Aud.sfx("legend")
		if bool(r["shiny"]):
			Aud.sfx("shiny")
		if big:
			_burst(win_col, 60 if (rar == 5 or bool(r["shiny"])) else 30)
		tray.append({"sym": _sym_of(r), "y": 104.0, "vy": 0.0, "done": false})
		await _wait((0.7 if big else 0.28) if ten else 1.0)
	await _wait(0.4)
	running = false
	finished.emit()


func stop() -> void:
	running = false


func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	k = float(maxi(1, floori(minf((vp.x - 40.0) / W, (vp.y - 110.0) / H))))
	org = Vector2((vp.x - W * k) * 0.5, (vp.y - H * k) * 0.5 - 14.0).round()


func _burst(col: Color, n: int) -> void:
	for i in range(n):
		var a: float = randf() * TAU
		var s: float = 30.0 + randf() * 70.0
		sparks.append({"x": W / 2.0, "y": MID, "vx": cos(a) * s, "vy": sin(a) * s - 30.0, "t": 0.0, "life": 0.6 + randf() * 0.6,
			"col": col if randf() < 0.5 else Color.WHITE})


func _process(delta: float) -> void:
	if not visible:
		return
	_layout()
	if not running:
		queue_redraw()
		return
	var dt: float = minf(0.05, delta) * (2.0 if fast else 1.0)
	t += dt
	var ticked := false
	for rl in reels:
		if bool(rl["spin"]):
			var before: int = floori(float(rl["off"]) / CELL)
			rl["off"] = float(rl["off"]) + float(rl["speed"]) * dt
			if floori(float(rl["off"]) / CELL) != before:
				ticked = true
		if float(rl["bounce"]) > 0.0:
			rl["bounce"] = maxf(0.0, float(rl["bounce"]) - dt * 5.0)
	if ticked and randf() < 0.5:
		Aud.sfx("hover")
	if win_t >= 0.0:
		win_t += dt
	for b in tray:
		if not bool(b["done"]):
			b["vy"] = float(b["vy"]) + 400.0 * dt
			b["y"] = float(b["y"]) + float(b["vy"]) * dt
			if float(b["y"]) >= 132.0:
				b["y"] = 132.0
				b["vy"] = float(b["vy"]) * -0.35
				if absf(float(b["vy"])) < 20.0:
					b["done"] = true
	for p in sparks:
		p["t"] = float(p["t"]) + dt
		p["x"] = float(p["x"]) + float(p["vx"]) * dt
		p["y"] = float(p["y"]) + float(p["vy"]) * dt
		p["vy"] = float(p["vy"]) + 120.0 * dt
	sparks = sparks.filter(func(p): return float(p["t"]) < float(p["life"]))
	queue_redraw()


# ---------------- dibujo ----------------

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(org + Vector2(x, y) * k, Vector2(w, h) * k), c)


func _disc(cx: float, cy: float, rad: float, col: Color) -> void:
	var y := -rad
	while y <= rad:
		var w: float = roundf(sqrt(maxf(0.0, rad * rad - y * y)))
		_r(cx - w, cy + y, w * 2.0, 1.0, col)
		y += 1.0


# Icono (12x12 de arte) de `size` px de arte, recortado en vertical por [cy0, cy1].
func _icon(name: String, x: float, y: float, size: float, cy0: float = -1e9, cy1: float = 1e9, mod: Color = Color.WHITE) -> void:
	var tx: Texture2D = IC.tex(name, 1)
	var top: float = maxf(y, cy0)
	var bot: float = minf(y + size, cy1)
	if bot <= top:
		return
	var th: float = float(tx.get_height())
	var src := Rect2(0.0, (top - y) / size * th, float(tx.get_width()), (bot - top) / size * th)
	var dst := Rect2(org + Vector2(x, top) * k, Vector2(size, bot - top) * k)
	draw_texture_rect_region(tx, dst, src, mod)


func _txt(s: String, cx: float, base_y: float, size: float, col: Color) -> void:
	var f: Font = ThemeDB.fallback_font
	var px: int = int(roundf(size * k))
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	draw_string(f, org + Vector2(cx * k - w * 0.5, base_y * k), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, col)


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.04, 0.1, 0.94))
	# mueble
	_r(10, 30, 142, 132, C_DARK)
	_r(11, 31, 140, 130, C_BODY)
	_r(11, 31, 6, 130, C_BODY_L)
	_r(145, 31, 6, 130, C_BODY_D)
	_r(11, 155, 140, 6, C_BODY_D)
	_r(10, 162, 142, 3, C_DARK)
	# cartel con bombillas
	_r(14, 4, 134, 28, C_DARK)
	_r(15, 5, 132, 26, C_TRIM_D)
	_r(18, 8, 126, 20, C_LED)
	var wc: Color = win_col if (win_t >= 0.0 and int(floor(win_t * 8.0)) % 2 == 0) else Color(0, 0, 0, 0)
	var i := 0
	var x := 16.0
	while x < 146.0:
		_bulb(x, 5.0, i, wc)
		i += 1
		_bulb(x, 29.0, i, wc)
		i += 1
		x += 7.0
	var y := 12.0
	while y < 28.0:
		_bulb(15.0, y, i, wc)
		i += 1
		_bulb(146.0, y, i, wc)
		i += 1
		y += 7.0
	_txt("POKé SLOTS", W / 2.0 + 1.0, 23.0, 12.0, C_DARK)
	_txt("POKé SLOTS", W / 2.0, 22.0, 12.0, C_TRIM)
	# ventana de rodillos
	_r(20, 38, 122, 58, C_DARK)
	_r(21, 39, 120, 56, C_TRIM_D)
	_r(23, 41, 116, 52, C_GLASS)
	for n in range(reels.size()):
		_draw_reel(reels[n], REEL_X[n])
	var lc: Color = win_col if win_t >= 0.0 else Color("#ff5f6d")
	_r(22, MID - 1.0, 3, 2, lc)
	_r(137, MID - 1.0, 3, 2, lc)
	if win_t >= 0.0 and win_t < 1.2 and int(floor(win_t * 10.0)) % 2 == 0:
		var fc := Color(win_col.r, win_col.g, win_col.b, 0.5)
		draw_rect(Rect2(org + Vector2(22, 40) * k, Vector2(118, 54) * k), fc, false, 2.0 * k)
	# marcador
	_r(36, 100, 90, 16, C_DARK)
	_r(37, 101, 88, 14, C_LED)
	if not frenzy or int(floor(t * 10.0)) % 2 == 0:
		_txt(led, 81.0, 111.0, 8.0, led_col)
	_r(132, 102, 8, 6, C_TRIM)
	_r(132, 108, 8, 2, C_TRIM_D)
	_r(22, 102, 8, 6, Color("#5fe08a"))
	_r(22, 108, 8, 2, Color("#2f9a52"))
	# bandeja
	_r(26, 122, 110, 26, C_DARK)
	_r(28, 124, 106, 22, Color("#0a0712"))
	_r(28, 144, 106, 2, C_CHROME_D)
	var n_total: int = 10 if ten else 1
	for j in range(tray.size()):
		var b: Dictionary = tray[j]
		var bx: float = (81.0 - 12.0) if n_total == 1 else (30.0 + float(j) * 10.0)
		var sz: float = 24.0 if n_total == 1 else 12.0
		_icon(String(b["sym"]), bx, roundf(float(b["y"]) - (10.0 if n_total == 1 else 0.0)), sz)
	# palanca
	_r(152, 74, 14, 24, C_DARK)
	_r(153, 75, 12, 22, C_CHROME)
	_r(160, 75, 5, 22, C_CHROME_D)
	var knob: float = roundf(34.0 + lever * 48.0)
	var top: float = minf(knob, 82.0)
	var bot: float = maxf(knob, 82.0)
	_r(157, top, 4, bot - top, C_CHROME_D)
	_r(157, top, 2, bot - top, C_CHROME)
	_disc(159.0, knob, 6.0, C_DARK)
	_disc(159.0, knob, 5.0, Color("#ff4d4d"))
	_r(156, knob - 3.0, 2, 2, Color("#ffd0d0"))
	# chispas
	for p in sparks:
		_r(roundf(float(p["x"])), roundf(float(p["y"])), 2, 2, p["col"])
	# ayuda
	var f: Font = ThemeDB.fallback_font
	var hint: String = L.t("Toca o pulsa un botón para acelerar")
	var hw: float = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	draw_string(f, Vector2((vp.x - hw) * 0.5, org.y + H * k + 30.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.72, 0.8, 0.94, 0.8))


func _bulb(x: float, y: float, i: int, wc: Color) -> void:
	var on: bool
	if frenzy:
		on = int(floor(t * 14.0 + float(i))) % 2 == 0
	else:
		on = int(floor(t * 4.0 + float(i))) % 3 != 0
	var col: Color = wc if wc.a > 0.0 else (C_BULB_ON if on else C_BULB_OFF)
	_r(x, y, 3, 3, col)


func _draw_reel(rl: Dictionary, x: float) -> void:
	var y0: float = REEL_Y
	var y1: float = REEL_Y + REEL_H
	_r(x, y0, REEL_W, REEL_H, C_REEL)
	if bool(rl["spin"]):
		var off: float = float(rl["off"])
		var base: float = fmod(off, CELL)
		var i0: int = floori(off / CELL)
		var blur: bool = float(rl["speed"]) > 300.0
		for kk in range(-2, 3):
			var name: String = STRIP[posmod(i0 - kk, STRIP.size())]
			var yy: float = roundf(MID - 12.0 + float(kk) * CELL + base)
			_icon(name, x + 6.0, yy, 24.0, y0, y1, Color(1, 1, 1, 0.75 if blur else 1.0))
			if blur:
				_icon(name, x + 6.0, yy - 6.0, 24.0, y0, y1, Color(1, 1, 1, 0.25))
	else:
		var by: float = roundf(sin(float(rl["bounce"]) * PI) * 5.0)
		var n: int = STRIP.find(String(rl["sym"]))
		_icon(STRIP[(n + 3) % STRIP.size()], x + 6.0, MID - 12.0 - CELL + by, 24.0, y0, y1, Color(1, 1, 1, 0.35))
		_icon(STRIP[(n + 5) % STRIP.size()], x + 6.0, MID - 12.0 + CELL + by, 24.0, y0, y1, Color(1, 1, 1, 0.35))
		_icon(String(rl["sym"]), x + 6.0, MID - 12.0 + by, 24.0, y0, y1)
	# sombra curva del rodillo
	_r(x, y0, REEL_W, 6, Color(C_REEL_D.r, C_REEL_D.g, C_REEL_D.b, 0.28))
	_r(x, y1 - 6.0, REEL_W, 6, Color(C_REEL_D.r, C_REEL_D.g, C_REEL_D.b, 0.28))
	_r(x, y0, REEL_W, 3, Color(0, 0, 0, 0.18))
	_r(x, y1 - 3.0, REEL_W, 3, Color(0, 0, 0, 0.18))
	_r(x - 1.0, y0, 1, REEL_H, C_DARK)
	_r(x + REEL_W, y0, 1, REEL_H, C_DARK)
