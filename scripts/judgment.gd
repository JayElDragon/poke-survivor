extends RefCounted
# La Sentencia de Arceus (judgment.js): al llegar al minuto 30 acaba la partida
# "normal". Animacion -> arena enorme -> Arceus invencible + un legendario cada
# 5 s con el doble de vida y dano que el anterior. Sin limite de tiempo.

const ARC_AT := 1800.0
const ARENA_R := 24.0
const BOSS_EVERY := 5.0
const TOUCH := 0.4
const SCALE := 1.5
const SPD_SOFT := 130.0
const SPD_OVER := 0.25
const T_TITLE := 1.3
const T_FLASH := 4.7
const T_PORT := 5.1
const T_DESC := 5.7
const T_LAND := 7.9
const T_BACK := 9.1
const T_END := 10.1
const GOLD := Color("#ffd25e")
const ARENA = preload("res://scripts/arena.gd")
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

var m                                  # main.gd
var arceus_dex := 493
var phase := ""                        # "" | "cine" | "fight"
var done := false                      # ya se hizo (no repetir)
var ct := 0.0
var q: Array = []
var ported := false
var landed := false
var can_skip := false
var cues := {}
var A = null                           # Enemy usado solo como sprite
var wheel_node: Node2D = null
var lift := 900.0
var arena_t := 0.0
var boss_t := 0.0
var boss_n := 0
var base := 0.0
var downs := 0
var casting := {}
var cd := 2.2
var last_cast := ""
var touch_cd := 0.0
var spin := 0.0
var cam_pos := Vector2.ZERO
var cam_ready := false
var overlay: Node2D = null
var pending_arena: Node2D = null
var flash_a := 0.0
var embers: Array = []
var hits := {}
var hit_t := 0.0
var samples: Array = []
var center := Vector2.ZERO
var won := false                       # Arceus derrotado: cuenta atras para salir de la arena
var win_t := 0.0
const WIN_XP_LEVELS := 15


# Arceus en silueta de luz que llena la rueda del titulo (como en el original).
class Sil extends Node2D:
	const CODE := "shader_type canvas_item;\nvoid fragment() { vec4 t = texture(TEXTURE, UV); COLOR = vec4(mix(vec3(1.0, 0.86, 0.5), vec3(1.0, 0.98, 0.88), UV.y), t.a * COLOR.a); }\n"
	var tex: Texture2D = null
	var meta: Dictionary = {}
	var p: Dictionary = {}

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var sh := Shader.new()
		sh.code = CODE
		var mat := ShaderMaterial.new()
		mat.shader = sh
		material = mat
		var path := "res://assets/pokemon/493/Idle.png"
		if ResourceLoader.exists(path):
			tex = load(path)

	func _draw() -> void:
		if tex == null or p.is_empty() or meta.is_empty():
			return
		var w: float = float(meta["w"])
		var h: float = float(meta["h"])
		var n: int = int(meta["n"])
		var frame: int = int(float(p["t"]) * 5.0) % n
		var px := 2.0
		var body: float = float(meta["ay"]) * px
		var sc: float = maxf(1.0, roundf(float(p["R"]) * 1.7 / body * 2.0) / 2.0)
		var rise: float = (1.0 - clampf((float(p["t"]) - float(p["t_title"]) + 0.3) / 0.8, 0.0, 1.0)) * float(p["R"]) * 0.3
		var feet := Vector2(float(p["cx"]), float(p["cy"]) + body * sc * 0.5 + rise)
		var src := Rect2(float(frame) * w, 0.0, w, h)
		var dst := Rect2(feet - Vector2(float(meta["ax"]) * px * sc, float(meta["ay"]) * px * sc), Vector2(w, h) * px * sc)
		var a: float = float(p["a"]) * 0.5
		for o in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4)]:
			draw_texture_rect_region(tex, Rect2(dst.position + o, dst.size), src, Color(1, 1, 1, a * 0.22))
		draw_texture_rect_region(tex, dst, src, Color(1, 1, 1, a))


class Overlay extends Node2D:
	var jd
	var sil: Sil
	var vig: GradientTexture2D

	func _ready() -> void:
		sil = Sil.new()
		add_child(sil)
		vig = GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.47, 0.16, 0.04, 0.0))
		g.set_color(1, Color(0.47, 0.16, 0.04, 0.38))
		g.offsets = PackedFloat32Array([0.55, 1.0])
		vig.gradient = g
		vig.fill = GradientTexture2D.FILL_RADIAL
		vig.fill_from = Vector2(0.5, 0.5)
		vig.fill_to = Vector2(1.0, 0.5)
		vig.width = 128
		vig.height = 128
		z_index = 50

	func _process(_d: float) -> void:
		queue_redraw()

	func _input(ev: InputEvent) -> void:
		if jd.phase != "cine" or not jd.can_skip or jd.ct >= jd.T_BACK:
			return
		var go := false
		if ev is InputEventKey and ev.pressed and not ev.echo:
			go = ev.keycode == KEY_SPACE or ev.keycode == KEY_ENTER or ev.keycode == KEY_ESCAPE
		elif ev is InputEventMouseButton and ev.pressed:
			go = true
		elif ev is InputEventScreenTouch and ev.pressed:
			go = true
		elif ev is InputEventJoypadButton and ev.pressed:
			go = true
		if go:
			jd.skip()
			get_viewport().set_input_as_handled()

	func _gold_text(s: String, pos: Vector2, size: int, w: float, a: float) -> void:
		var f := ThemeDB.fallback_font
		draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, maxi(4, int(size * 0.2)), Color(0.16, 0.08, 0.0, a))
		draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, Color(1.0, 0.85, 0.37, a))

	func _wheel(c: Vector2, R: float, rot: float, a: float) -> void:
		var gold := Color(1.0, 0.82, 0.37, a)
		draw_arc(c, R, 0.0, TAU, 64, gold, maxf(2.0, R * 0.07))
		draw_arc(c, R * 0.82, 0.0, TAU, 64, gold, maxf(1.0, R * 0.025))
		var gems := [Color("#ff6b4d"), Color("#4fa8ff"), Color("#5fe08a"), Color("#ffe14d"), Color("#b37bff"), Color("#c9d2de")]
		for i in range(12):
			var ang: float = rot + float(i) * TAU / 12.0
			var d := Vector2.from_angle(ang)
			var n := Vector2(-d.y, d.x)
			var gc: Color = gems[i % 6]
			gc.a = a
			draw_colored_polygon(PackedVector2Array([c + d * R * 1.02, c + d * R * 0.91 - n * R * 0.07, c + d * R * 0.8, c + d * R * 0.91 + n * R * 0.07]), gc)

	func _title(raw: String, cx: float, y: float, size: int, t0: float, alpha: float) -> void:
		var f := ThemeDB.fallback_font
		var s: String = L.t(raw)
		var total: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
		var x: float = cx - total / 2.0
		for i in range(s.length()):
			var ch: String = s.substr(i, 1)
			var cw: float = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
			var p: float = clampf((jd.ct - t0 - float(i) * 0.055) / 0.28, 0.0, 1.0)
			if p > 0.0 and ch != " ":
				var k: float = 1.0 + (1.0 - p) * 1.8
				draw_set_transform(Vector2(x + cw / 2.0, y), 0.0, Vector2(k, k))
				_gold_text(ch, Vector2(-cw / 2.0 - 20.0, 0.0), size, cw + 40.0, alpha * p)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			x += cw

	func _sky_pillar(vp: Vector2) -> void:
		if jd.A == null or not jd.ported or jd.phase != "cine":
			return
		var ct: float = jd.ct
		var a: float = clampf((ct - jd.T_PORT) / 0.6, 0.0, 1.0) * clampf((jd.T_LAND + 0.6 - ct) / 0.6, 0.0, 1.0)
		if a <= 0.0:
			return
		var sp: Vector2 = get_viewport().get_canvas_transform() * jd.A.global_position
		var near: float = clampf(1.0 - jd.lift / 900.0, 0.0, 1.0)
		var w: float = (40.0 + near * 40.0 + sin(ct * 9.0) * 6.0) * 2.0
		var top: float = -20.0
		var bot: float = sp.y + 6.0
		if bot > top:
			var c0 := Color(1.0, 0.82, 0.37, 0.0)
			var c1 := Color(1.0, 0.97, 0.86, 0.7 * a)
			draw_polygon(PackedVector2Array([Vector2(sp.x - w, top), Vector2(sp.x, top), Vector2(sp.x, bot), Vector2(sp.x - w, bot)]), PackedColorArray([c0, c1, c1, c0]))
			draw_polygon(PackedVector2Array([Vector2(sp.x, top), Vector2(sp.x + w, top), Vector2(sp.x + w, bot), Vector2(sp.x, bot)]), PackedColorArray([c1, c0, c0, c1]))
		draw_set_transform(Vector2(sp.x, sp.y), 0.0, Vector2(1.0, 0.36))
		draw_circle(Vector2.ZERO, w * 0.75, Color(1.0, 0.9, 0.6, a * (0.3 + near * 0.5)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw() -> void:
		var vp: Vector2 = get_viewport_rect().size
		var f := ThemeDB.fallback_font
		if jd.phase == "cine":
			_sky_pillar(vp)
			_draw_cine(vp, f)
		elif jd.phase == "fight":
			_draw_fight(vp, f)
		if jd.flash_a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.97, 0.85, clampf(jd.flash_a, 0.0, 1.0)))

	func _draw_cine(vp: Vector2, f: Font) -> void:
		var t: float = jd.ct
		if sil != null and not sil.p.is_empty():
			sil.p = {}
			sil.queue_redraw()
		if t < jd.T_PORT + 0.1:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.024, 0.008, clampf(t / 1.1, 0.0, 1.0) * 0.86))
		var a: float = clampf((t - jd.T_TITLE + 0.3) / 0.5, 0.0, 1.0) * clampf((jd.T_FLASH + 0.2 - t) / 0.35, 0.0, 1.0)
		if a > 0.0:
			var cx: float = vp.x / 2.0
			var cy: float = vp.y * 0.34
			var R: float = minf(vp.x, vp.y) * 0.24
			var far: float = maxf(vp.x, vp.y)
			for i in range(16):
				var ang: float = t * 0.18 + float(i) * TAU / 16.0
				var d := Vector2.from_angle(ang)
				var n := Vector2(-d.y, d.x)
				var c0 := Color(1.0, 0.84, 0.43, 0.32 * a)
				var c1 := Color(1.0, 0.84, 0.43, 0.0)
				draw_polygon(PackedVector2Array([Vector2(cx, cy), Vector2(cx, cy) + d * far + n * R * 0.16, Vector2(cx, cy) + d * far - n * R * 0.16]), PackedColorArray([c0, c1, c1]))
			_wheel(Vector2(cx, cy - R * 0.05), R, t * 0.35, a * 0.9)
			draw_circle(Vector2(cx, cy), R * 0.55, Color(1.0, 0.93, 0.7, a * 0.25))
			if sil != null:
				if sil.meta.is_empty():
					sil.meta = jd.m._sm(jd.arceus_dex)["a"]["Idle"]
				sil.p = {"t": t, "t_title": jd.T_TITLE, "R": R, "cx": cx, "cy": cy - R * 0.05, "a": a}
				sil.queue_redraw()
			var size: int = int(clampf(minf(vp.x / 13.0, vp.y / 9.0), 24.0, 64.0))
			var ty: float = cy + R + float(size) * 1.15
			_title("LA SENTENCIA", cx, ty, size, jd.T_TITLE, a)
			_title("DE ARCEUS", cx, ty + float(size) * 0.95, int(float(size) * 0.8), jd.T_TITLE + 0.75, a)
			var sa: float = a * clampf((t - jd.T_TITLE - 1.6) / 0.6, 0.0, 1.0)
			draw_string(f, Vector2(0.0, ty + float(size) * 1.7), L.t("El tiempo se ha agotado…"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, int(float(size) * 0.34), Color(0.95, 0.89, 0.69, sa))
		if t > jd.T_PORT:
			var k: float = clampf((t - jd.T_PORT) / 0.5, 0.0, 1.0) * clampf((jd.T_END - t) / 0.6, 0.0, 1.0)
			var bh: float = roundf(vp.y * 0.11 * k)
			draw_rect(Rect2(0.0, 0.0, vp.x, bh), Color.BLACK)
			draw_rect(Rect2(0.0, vp.y - bh, vp.x, bh), Color.BLACK)
		var b: float = clampf((t - jd.T_LAND - 0.15) / 0.3, 0.0, 1.0) * clampf((jd.T_END - t) / 0.5, 0.0, 1.0)
		if b > 0.0:
			var sz: int = int(clampf(vp.x / 20.0, 20.0, 40.0))
			_gold_text(L.t("¡ARCEUS HA DESCENDIDO!"), Vector2(0.0, vp.y * 0.24), sz, vp.x, b)
			var sub: String = L.t("Es invencible: huye y aguanta todo lo que puedas")
			draw_string_outline(f, Vector2(0.0, vp.y * 0.24 + float(sz) * 1.1), sub, HORIZONTAL_ALIGNMENT_CENTER, vp.x, int(float(sz) * 0.5), 4, Color(0, 0, 0, 0.8 * b))
			draw_string(f, Vector2(0.0, vp.y * 0.24 + float(sz) * 1.1), sub, HORIZONTAL_ALIGNMENT_CENTER, vp.x, int(float(sz) * 0.5), Color(1.0, 0.91, 0.69, b))
		if jd.can_skip and t < jd.T_BACK:
			var al: float = 0.55 + sin(t * 4.0) * 0.2
			draw_string(f, Vector2(0.0, vp.y - 16.0), L.t("Toca la pantalla o pulsa un botón para saltar"), HORIZONTAL_ALIGNMENT_RIGHT, vp.x - 16.0, 14, Color(0.95, 0.89, 0.69, al))

	func _draw_fight(vp: Vector2, f: Font) -> void:
		draw_texture_rect(vig, Rect2(Vector2.ZERO, vp), false)
		for e in jd.embers:
			draw_rect(Rect2(roundf(e["x"]), roundf(e["y"]), e["s"], e["s"]), Color(e["c"].r, e["c"].g, e["c"].b, minf(1.0, e["life"]) * e["a"]))
		var txt: String = "%s · %02d:%02d · %s %d" % [L.t("SENTENCIA"), int(jd.arena_t) / 60, int(jd.arena_t) % 60, L.t("JEFES"), jd.downs]
		draw_string(f, Vector2(0.0, 122.0), txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 16, GOLD)
		if jd.A == null:
			return
		var sp: Vector2 = get_viewport().get_canvas_transform() * (jd.A.global_position + Vector2(0.0, -jd.A.body_h * 0.5))
		if sp.x < 0.0 or sp.x > vp.x or sp.y < 0.0 or sp.y > vp.y:
			var M := 46.0
			var ex: float = clampf(sp.x, M, vp.x - M)
			var ey: float = clampf(sp.y, M + 70.0, vp.y - M - 80.0)
			var an: float = atan2(sp.y - ey, sp.x - ex)
			var beat: float = 0.5 + sin(Time.get_ticks_msec() / 120.0) * 0.5
			draw_circle(Vector2(ex, ey), 26.0 + beat * 6.0, Color(1.0, 0.42, 0.24, 0.2 + beat * 0.25))
			var col: Color = Color(1.0, 0.95, 0.78) if beat > 0.5 else GOLD
			draw_colored_polygon(PackedVector2Array([
				Vector2(ex, ey) + Vector2.from_angle(an) * 34.0,
				Vector2(ex, ey) + Vector2.from_angle(an + 2.45) * 17.0,
				Vector2(ex, ey) + Vector2.from_angle(an - 2.45) * 17.0]), col)
			var dist: float = jd.m.player.position.distance_to(jd.A.position) / 32.0
			var lbl: String = "%s · %d m" % [L.t("Arceus").to_upper(), int(dist)]
			var lp := Vector2(ex, ey) - Vector2.from_angle(an) * 30.0 + Vector2(0.0, 4.0)
			draw_string_outline(f, lp - Vector2(80.0, 0.0), lbl, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 14, 4, Color(0, 0, 0, 0.85))
			draw_string(f, lp - Vector2(80.0, 0.0), lbl, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 14, GOLD)


class Wheel extends Node2D:
	var R := 80.0
	var rot := 0.0

	func _process(delta: float) -> void:
		rot += delta * 0.6
		queue_redraw()

	func _draw() -> void:
		var gold := Color(1.0, 0.82, 0.37, 0.55)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 56, gold, maxf(2.0, R * 0.07))
		draw_arc(Vector2.ZERO, R * 0.82, 0.0, TAU, 56, gold, maxf(1.0, R * 0.025))
		var gems := [Color("#ff6b4d"), Color("#4fa8ff"), Color("#5fe08a"), Color("#ffe14d"), Color("#b37bff"), Color("#c9d2de")]
		for i in range(12):
			var ang: float = rot + float(i) * TAU / 12.0
			var d := Vector2.from_angle(ang)
			var n := Vector2(-d.y, d.x)
			var gc: Color = gems[i % 6]
			gc.a = 0.6
			draw_colored_polygon(PackedVector2Array([d * R * 1.02, d * R * 0.91 - n * R * 0.07, d * R * 0.8, d * R * 0.91 + n * R * 0.07]), gc)


# ---------------------------------------------------------------
func reset() -> void:
	phase = ""
	done = false


func active() -> bool:
	return phase != ""


func cinematic() -> bool:
	return phase == "cine"


func music() -> String:
	if phase == "cine" and ct < T_LAND:
		return ""
	return "judgment"


func summary() -> Dictionary:
	if phase == "fight":
		return {"time": arena_t, "bosses": downs}
	return {}


func note_dmg(amount: float, e) -> void:
	if phase != "":
		return
	var k: int = e.get_instance_id()
	hits[k] = float(hits.get(k, 0.0)) + amount


func sample(delta: float) -> void:
	hit_t += delta
	if hit_t < 1.0:
		return
	var best := 0.0
	for k in hits:
		best = maxf(best, float(hits[k]))
	samples.append(best / hit_t)
	if samples.size() > 30:
		samples.pop_front()
	hits.clear()
	hit_t = 0.0


func single_dps() -> float:
	var s: Array = samples.duplicate()
	s.sort()
	s.reverse()
	var top: Array = s.slice(0, 6)
	if top.is_empty():
		return 0.0
	var tot := 0.0
	for v in top:
		tot += float(v)
	return tot / float(top.size())


# --- arranque ---------------------------------------------------
func begin() -> void:
	if phase != "" or done:
		return
	done = true
	var pool: Array = []
	for p in m._dex_list:
		if bool(p.get("leg", false)) and int(p["dex"]) != arceus_dex and m._smeta.has(str(int(p["dex"]))):
			pool.append(int(p["dex"]))
	q = []
	for i in range(40):
		if pool.is_empty():
			break
		q.append(pool[randi() % pool.size()])
	phase = "cine"
	ct = 0.0
	cues = {}
	ported = false
	landed = false
	var stt: Dictionary = m.SV.d["stats"]
	can_skip = int(stt.get("judged", 0)) > 0
	pending_arena = ARENA.new()
	pending_arena.setup("judgment", randi() % 100000)
	pending_arena.r = ARENA_R
	pending_arena.start_bake()
	overlay = Overlay.new()
	overlay.jd = self
	m.ui_layer.add_child(overlay)
	m.hud.visible = false
	m.stick.visible = false
	m.slots.visible = false
	m.cam.top_level = true
	m.cam.global_position = m.player.position
	cam_pos = m.player.position
	cam_ready = true
	Aud.music("")


func skip() -> void:
	if phase != "cine" or not can_skip or ct >= T_BACK:
		return
	if not ported:
		port()
	do_land(true)
	ct = T_BACK


func port() -> void:
	ported = true
	var ts: float = ARENA.TS
	m._jd_port(pending_arena)
	pending_arena = null
	center = m.ARENA_POS
	m.player.position = center + Vector2(0.0, ts * 3.0)
	m.player_vel = Vector2.ZERO
	cam_pos = m.player.position
	var def := {"dex": arceus_dex, "name": "Arceus", "hp": 1.0e9, "spd": 1.0, "dmg": 0.0, "xp": 0.0, "behavior": "chase"}
	A = m._make_enemy(def, center + Vector2(0.0, -ts * 5.0), {"hp": 1.0, "dmg": 1.0, "spd": 1.0}, false)
	m.enemies.erase(A)
	var ratio: float = SCALE / A.scl
	A.sprite.scale *= ratio
	A.radius *= ratio * 0.9
	A.body_h *= ratio
	A.shadow_rx *= ratio
	A.scl = SCALE
	A.hover = false
	A.lift_extra = lift
	A.dir = 0
	A.dirty = true
	wheel_node = Wheel.new()
	wheel_node.R = A.body_h * 0.62
	wheel_node.position = Vector2(0.0, -A.body_h * 0.55 - lift)
	wheel_node.show_behind_parent = true
	A.add_child(wheel_node)
	cd = 2.2
	casting = {}
	lift = 900.0


func do_land(quiet: bool) -> void:
	if landed or A == null:
		return
	landed = true
	lift = 0.0
	A.lift_extra = 0.0
	wheel_node.position = Vector2(0.0, -A.body_h * 0.55)
	A.play("Attack", 0.8)
	if quiet:
		return
	m.shake = 18.0
	flash_a = 0.7
	Aud.sfx("land")
	for i in range(4):
		m._ring(A.position, 10.0 + float(i) * 20.0, 260.0 + float(i) * 140.0, GOLD if i % 2 == 0 else Color("#fff3c8"), 0.5 + float(i) * 0.25)


func fight() -> void:
	phase = "fight"
	if not ported:
		port()
	do_land(true)
	cam_ready = false
	m.cam.top_level = false
	m.cam.position = Vector2.ZERO
	m.hud.visible = true
	m.stick.visible = true
	m.slots.visible = true
	arena_t = 0.0
	boss_t = 1.2
	boss_n = 0
	downs = 0
	var stt: Dictionary = m.SV.d["stats"]
	stt["judged"] = int(stt.get("judged", 0)) + 1
	m.SV.save()
	m.progress_event("judge")
	var floor_hp: float = (3200.0 + m.run_time * 9.0) * 0.35
	base = maxf(floor_hp, single_dps() * 3.0)
	m._say(L.t("¡Arceus puede ser derrotado! Aguanta y acaba con él"), 3.4)
	won = false
	win_t = 0.0
	A.max_hp = 5000000.0   # 5 millones fijos (pedido del dueño)
	A.hp = A.max_hp
	A.def["scripted"] = true
	A.set_meta("jd_arceus", true)
	m.enemies.append(A)
	m.ainfo = {"phase": "jd", "back": m.player.position, "stash_e": m.ainfo.get("stash_e", []), "stash_o": m.ainfo.get("stash_o", []), "boss": A}


# --- cada fotograma ---------------------------------------------
func cine_tick(dt: float) -> void:
	var prev: float = ct
	ct += dt
	flash_a = maxf(0.0, flash_a - dt * 1.1)
	if prev < 0.01 and ct >= 0.01:
		Aud.sfx("quake")
		m.shake = 14.0
	if ct < T_FLASH and randf() < dt * 3.0:
		m.shake = maxf(m.shake, 3.0)
	if prev < T_TITLE and ct >= T_TITLE:
		Aud.sfx("toll")
	if prev < T_TITLE + 1.7 and ct >= T_TITLE + 1.7:
		Aud.sfx("toll")
	if prev < T_FLASH and ct >= T_FLASH:
		flash_a = 1.0
	if prev < T_PORT and ct >= T_PORT and not ported:
		port()
	if prev < T_DESC and ct >= T_DESC:
		Aud.sfx("descend")
	if A != null and not landed:
		var k: float = clampf((ct - T_DESC) / (T_LAND - T_DESC), 0.0, 1.0)
		lift = 900.0 * pow(1.0 - k, 2.2)
		A.lift_extra = lift
		wheel_node.position = Vector2(0.0, -A.body_h * 0.55 - lift)
		A.loop_anim("Idle", 1.0)
		if prev < T_LAND and ct >= T_LAND:
			do_land(false)
	spin += dt
	var tgt: Vector2 = m.player.position
	if ported and A != null and ct < T_BACK:
		tgt = A.position + Vector2(0.0, -60.0)
	var kd: float = 1.0 - exp(-2.2 * dt)
	cam_pos = cam_pos.lerp(tgt, kd)
	m.cam.global_position = cam_pos
	if ct >= T_END:
		fight()


func update(dt: float) -> void:
	if phase == "":
		sample(dt)
		return
	if phase != "fight":
		return
	flash_a = maxf(0.0, flash_a - dt * 1.1)
	if won:
		win_t -= dt
		if win_t <= 0.0:
			leave()
		return
	arena_t += dt
	touch_cd -= dt
	spin += dt
	arceus_tick(dt)
	keep_inside()
	boss_t -= dt
	if boss_t <= 0.0:
		boss_t = BOSS_EVERY
		spawn_boss()
	touch()
	ember(dt)


func target_pos() -> Vector2:
	return m.player.position


func arceus_tick(dt: float) -> void:
	if A == null or A.dead:
		return
	if not casting.is_empty():
		cast_tick(dt)
		return
	var tg: Vector2 = m.player.position
	var dv: Vector2 = tg - A.position
	var dist: float = dv.length()
	var k: float = minf(1.22, 0.74 + arena_t * 0.013) + maxf(0.0, arena_t - 300.0) * 0.0015
	var spd: float = maxf(70.0, cap_spd(m._spd()) * k)
	var dn: Vector2 = dv / maxf(dist, 0.001)
	A.position += dn * spd * dt
	A.face_angle(dn.angle())
	A.loop_anim("Walk", maxf(0.8, spd / 90.0))
	cd -= dt
	if cd <= 0.0:
		var id: String = "nova" if (dist < 210.0 and randf() < 0.6) else ("cross" if last_cast == "rain" else "rain")
		cast(id)


func hz(kind: String, pos: Vector2, r: float, delay: float, pct: float, col: Color, vis: String = "") -> void:
	var h
	if kind == "zone":
		h = m._hazard_zone(pos, r, delay, 1.0, "", col)
	else:
		h = m._hazard_beam(pos, 0.0, 1700.0, 34.0, delay, 1.0, "", col)
	h.pct = pct
	h.pure = true
	h.vis = vis
	hz_last = h


var hz_last = null


func cast(id: String) -> void:
	last_cast = id
	var wind := 0.7
	if id == "rain":
		# La Sentencia: pilares de luz sobre ti (mas cuanto mas dura).
		var n: int = 4 + mini(6, int(arena_t / 10.0))
		var p: Vector2 = m.player.position
		for i in range(n):
			var a: float = randf() * TAU
			var d: float = randf_range(40.0, 150.0) if i > 0 else 0.0
			hz("zone", p + Vector2(cos(a) * d, sin(a) * d * 0.8), 44.0, 1.25 + float(i) * 0.09, 0.3, GOLD, "pillar")
		A.play("Shoot", 0.9)
	elif id == "cross":
		# Rayos en cruz que barren la arena.
		var a0: float = (m.player.position - A.position).angle() + (0.0 if randf() < 0.5 else PI / 4.0)
		var n2: int = 8 if arena_t > 30.0 else 4
		for i in range(n2):
			hz("beam", A.position, 0.0, 1.1, 0.35, Color("#fff3b0"))
			hz_last.angle = a0 + float(i) * TAU / float(n2)
		wind = 1.1
		A.play("Charge", 0.9)
	else:
		# Onda alrededor de el (si estas demasiado cerca).
		hz("zone", A.position, 170.0, 0.85, 0.4, GOLD)
		wind = 0.85
		A.play("Charge", 1.2)
	m._ring(A.position, A.radius, A.radius * 3.0, GOLD, wind)
	casting = {"id": id, "t": 0.0, "wind": wind, "done": false}


func cast_tick(dt: float) -> void:
	casting["t"] = float(casting["t"]) + dt
	var dv: Vector2 = m.player.position - A.position
	A.face_angle(dv.angle())
	if float(casting["t"]) >= float(casting["wind"]) and not bool(casting["done"]):
		casting["done"] = true
		A.play("Attack" if String(casting["id"]) == "nova" else "Shoot", 1.2)
	if float(casting["t"]) >= float(casting["wind"]) + 0.35:
		casting = {}
		cd = maxf(1.4, 3.2 - arena_t * 0.025)


# Tope suave de velocidad del jugador durante la Sentencia (anti-huida sin fin).
static func cap_spd(s: float) -> float:
	return s if s <= SPD_SOFT else SPD_SOFT + (s - SPD_SOFT) * SPD_OVER


# Daño del toque: 40% al inicio; sube del min 7 al 10 de Sentencia hasta 100%.
func touch_pct() -> float:
	return minf(1.0, TOUCH + maxf(0.0, arena_t - 420.0) / 180.0 * (1.0 - TOUCH))


func touch() -> void:
	var pl = m.player
	if pl.dead or touch_cd > 0.0:
		return
	var rr: float = A.radius + pl.radius
	if A.position.distance_squared_to(pl.position) > rr * rr:
		return
	touch_cd = 0.9
	pl.invuln = 0.0
	m._hurt_player(pl.max_hp * touch_pct(), "", true)
	m.shake = 9.0
	m._ring(pl.position, 6.0, 70.0, GOLD, 0.4)
	A.play("Attack", 1.4)


func keep_inside() -> void:
	var mx: float = (ARENA_R - 1.4) * ARENA.TS
	var clamp_in := func(o):
		var d: Vector2 = o.position - center
		if d.length() > mx:
			o.position = center + d.normalized() * mx
	if A != null and is_instance_valid(A):
		clamp_in.call(A)
	# El jugador tampoco puede salir de la arena (antes podia atravesar el muro y quedar fuera).
	var pd: Vector2 = m.player.position - center
	var pmx: float = (ARENA_R - 2.2) * ARENA.TS
	if pd.length() > pmx or m.player.position.distance_to(center) > 99999.0:
		m.player.position = center + pd.normalized() * pmx
		m.player_vel = Vector2.ZERO
	for e in m.enemies:
		if not e.dead:
			clamp_in.call(e)


func spawn_boss() -> void:
	if q.is_empty():
		return
	var dex: int = int(q[boss_n % q.size()])
	var mon: Dictionary = m._dex_by[dex]
	var t: float = m.run_time
	var ts: float = ARENA.TS
	var pos: Vector2 = center
	for i in range(16):
		var a: float = randf() * TAU
		var d: float = (ARENA_R - randf_range(3.0, 6.0)) * ts
		pos = center + Vector2(cos(a), sin(a)) * d
		if pos.distance_to(m.player.position) > 280.0:
			break
	var k: float = pow(2.0, float(boss_n))
	var ranged: bool = m._has_t(mon["types"], ["psychic", "electric", "ghost", "fairy", "fire", "water", "ice", "dragon"])
	var def := {"dex": dex, "name": String(mon["name"]), "hp": roundf(base * k),
		"spd": roundf(maxf(clampf(48.0 + (float(mon["spd"]) - 78.0) * 0.6, 48.0, 105.0), cap_spd(m._spd()) * 0.8)),
		"dmg": roundf((36.0 + t / 20.0) * k), "xp": roundf(500.0 + t * 1.2),
		"behavior": "ranged" if ranged else "charger",
		"shotDmg": roundf((18.0 + t / 40.0) * k), "shotCd": 0.9, "range": 300.0}
	var e = m._make_enemy(def, pos, {"hp": 1.0, "dmg": 1.0, "spd": 1.0}, true)
	e.judge = true
	e.flying = false
	boss_n += 1
	m._ring(pos, 8.0, 120.0, GOLD, 0.6)
	m._say(L.t("¡%s acude a la Sentencia!") % e.enemy_name, 1.8)
	Aud.sfx("rift")


func arceus_down(e) -> void:
	if won or phase != "fight":
		return
	won = true
	win_t = 4.5
	var stt: Dictionary = m.SV.d["stats"]
	stt["arceusJudge"] = int(stt.get("arceusJudge", 0)) + 1
	m.PG.grant({"coins": 20000, "t1": 8, "t10": 6})
	m.SV.save()
	for k in range(30):
		m._spawn_orb(e.position, "coin", 10.0)
	for k in range(4):
		m._spawn_orb(e.position, "ticket", 1.0)
	m._spawn_orb(e.position + Vector2(24.0, 0.0), "item", 0.0)
	m._say(L.t("¡ARCEUS HA SIDO DERROTADO! Recompensa legendaria"), 4.0)
	Aud.sfx("bossDown")
	m.shake = 16.0
	flash_a = 0.8
	for i in range(4):
		m._ring(e.position, 10.0 + float(i) * 20.0, 260.0 + float(i) * 140.0, GOLD if i % 2 == 0 else Color("#fff3c8"), 0.5 + float(i) * 0.25)
	# fuera los legendarios que quedaban
	for o in m.enemies:
		if o != e and not o.dead:
			o.dead = true
			o.fade = 0.4


func leave() -> void:
	# Salida de la arena: vuelves a la partida con MUCHA experiencia.
	var stt: Dictionary = m.SV.d["stats"]
	stt["judgeTime"] = maxi(int(stt.get("judgeTime", 0)), int(arena_t))
	stt["judgeBosses"] = maxi(int(stt.get("judgeBosses", 0)), downs)
	won = false
	phase = ""
	var pl = m.player
	m._arena_end(true)
	for i in range(WIN_XP_LEVELS):
		pl.level += 1
		m.pending_levels += 1
	pl.xp = 0.0
	pl.xp_next = maxf(1.0, m._xp_need(pl.level))
	m._say(L.t("¡Sales de la Sentencia con mucha experiencia! +%d niveles") % WIN_XP_LEVELS, 3.6)
	Aud.sfx("levelup")
	if A != null and is_instance_valid(A):
		A.queue_free()
	A = null


func boss_down() -> void:
	if phase == "fight":
		downs += 1


func ember(dt: float) -> void:
	var vp: Vector2 = m.get_viewport_rect().size
	if embers.size() < 70 and randf() < dt * 40.0:
		var spark: bool = randf() < 0.3
		embers.append({"x": randf() * vp.x, "y": -6.0, "vx": randf_range(-25.0, 10.0), "vy": randf_range(20.0, 55.0),
			"life": randf_range(5.0, 10.0), "s": 2.0 if spark else 3.0, "a": 0.9 if spark else 0.45,
			"c": Color("#ffb347") if spark else Color("#8a8078")})
	for i in range(embers.size() - 1, -1, -1):
		var e: Dictionary = embers[i]
		e["x"] = float(e["x"]) + float(e["vx"]) * dt
		e["y"] = float(e["y"]) + float(e["vy"]) * dt
		e["life"] = float(e["life"]) - dt
		if float(e["life"]) <= 0.0 or float(e["y"]) > vp.y + 10.0:
			embers.remove_at(i)
