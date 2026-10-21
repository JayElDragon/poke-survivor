extends RefCounted
# Dynamax: tu Pokemon se hace gigante durante un minuto (+30% a todos sus atributos) y lanza ondas "Max" de su tipo.
# Una vez por partida; se desbloquea al vencer una guarida Dynamax (stat "dens"). Cada guarida vencida lo recarga.
const ZMS = preload("res://scripts/zmove.gd")
const Aud = preload("res://scripts/audio.gd")

const COOLDOWN := 240.0   # 4 minutos desde que acaba
const DUR := 60.0
const MIN_LEVEL := 1
const MIN_TIME := 180.0   # disponible desde el minuto 3
const GROW := 1.6
const STAT_K := 1.3   # +30% a todos los atributos mientras dura
const HP_BONUS := 0.3
const DMG_K := 1.3
const TAKEN := 0.2308   # 1 - 1/1.3: defensa +30%
const PULSE := 1.5
# Efecto de estado de la onda segun el tipo: [cc, veneno, lentitud]
const STATUS := {"fire": ["", 0, 0.0], "water": ["", 0, 0.4], "electric": ["para", 0, 0.0], "ice": ["freeze", 0, 0.0], "poison": ["", 1, 0.0],
	"psychic": ["conf", 0, 0.0], "ghost": ["sleep", 0, 0.0], "fairy": ["conf", 0, 0.0], "bug": ["", 0, 0.35], "grass": ["", 1, 0.0], "ground": ["", 0, 0.3]}

var m
var active := false
var t := 0.0
var total := DUR
var bonus := 0.0
var pulse := 0.0
var n := 0
var type := "normal"
var aura := 0.0
var since := 0.0
var aura_node = null


# Aura roja que envuelve al Pokemon Dynamax (como en Espada y Escudo): niebla roja y violeta que sube en espiral y chispas.
class Aura extends Node2D:
	var t := randf() * 10.0
	var h := 40.0
	var w := 24.0
	var col := Color(0.9, 0.08, 0.25)

	func _init() -> void:
		show_behind_parent = true

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var beat: float = 0.5 + 0.5 * sin(t * 4.0)
		var c := Vector2(0.0, -h * 0.5)
		# charco de luz en el suelo
		var pts := PackedVector2Array()
		for i in range(28):
			var a: float = TAU * float(i) / 28.0
			pts.append(Vector2(cos(a) * w * (1.7 + 0.12 * beat), sin(a) * w * 0.55))
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.38 + 0.10 * beat))
		# resplandor del cuerpo
		for i in range(4):
			var k: float = float(i) / 3.0
			draw_circle(c, maxf(w, h * 0.5) * (1.55 - k * 0.55) + beat * 4.0, Color(col.r, col.g + 0.3 * k, col.b + 0.2 * k, 0.07 + 0.03 * k))
		# niebla que sube en espiral
		for i in range(14):
			var ph: float = fposmod(t * 0.55 + float(i) * 0.0714, 1.0)
			var a2: float = t * 1.6 + float(i) * 0.9
			var rr: float = w * (0.9 + 0.35 * sin(t * 2.0 + float(i)))
			var p := Vector2(cos(a2) * rr, c.y + h * 0.55 - ph * h * 1.25 + sin(a2) * rr * 0.3)
			var al: float = sin(ph * PI) * 0.45
			var cc: Color = col.lerp(Color(0.5, 0.1, 0.7), 0.5 + 0.5 * sin(float(i)))
			draw_circle(p, 4.0 + 6.0 * (1.0 - ph) + 2.0 * beat, Color(cc.r, cc.g, cc.b, al))
		# chispas
		for i in range(9):
			var ph2: float = fposmod(t * 0.9 + float(i) * 0.111, 1.0)
			var xx: float = sin(float(i) * 7.3 + t * 1.7) * w * 1.1
			var yy: float = c.y + h * 0.5 - ph2 * h * 1.5
			var sz: float = 2.0 + 2.0 * (1.0 - ph2)
			draw_rect(Rect2(xx - sz * 0.5, yy - sz * 0.5, sz, sz), Color(1.0, 0.85, 0.9, sin(ph2 * PI) * 0.9))


# Guarida Dynamax (estilo Espada y Escudo): crater rocoso con cristales rojos y, encima, una columna de luz con anillos que suben.
class Den extends Node2D:
	var t := randf() * 10.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	static func sn(v: float) -> float:
		return roundf(v / 3.0) * 3.0

	static func hs(i: int, k: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0)

	func _ring_poly(rx: float, ry: float, jag: float, seed: int, n: int = 26) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n):
			var a: float = TAU * float(i) / float(n)
			var r: float = 1.0 + (hs(i, seed) - 0.5) * jag
			pts.append(Vector2(sn(cos(a) * rx * r), sn(sin(a) * ry * r)))
		return pts

	func _draw() -> void:
		var beat: float = 0.5 + 0.5 * sin(t * 3.0)
		# sombra y borde de roca del crater
		draw_colored_polygon(_ring_poly(86.0, 34.0, 0.0, 1, 30), Color(0.0, 0.0, 0.0, 0.28))
		draw_colored_polygon(_ring_poly(76.0, 30.0, 0.22, 3), Color("#2f2024"))
		draw_colored_polygon(_ring_poly(70.0, 26.0, 0.18, 5), Color("#4a3438"))
		draw_colored_polygon(_ring_poly(60.0, 22.0, 0.12, 7), Color("#17081c"))
		# foso de energia que late
		draw_colored_polygon(_ring_poly(48.0, 17.0, 0.10, 9), Color(0.55, 0.05, 0.22, 0.95))
		draw_colored_polygon(_ring_poly(36.0, 12.0, 0.10, 11), Color(1.0, 0.18, 0.4, 0.75 + 0.2 * beat))
		draw_colored_polygon(_ring_poly(22.0, 7.0, 0.08, 13), Color(1.0, 0.7, 0.8, 0.8 + 0.2 * beat))
		for i in range(3):
			var a0: float = t * 1.8 + TAU * float(i) / 3.0
			draw_arc(Vector2.ZERO, 30.0, a0, a0 + 1.4, 12, Color(1.0, 0.85, 0.9, 0.7), 3.0)
		# rocas sueltas en el borde
		for i in range(9):
			var a1: float = TAU * float(i) / 9.0 + 0.3
			var bp := Vector2(sn(cos(a1) * 72.0), sn(sin(a1) * 28.0))
			var rs: float = 6.0 + hs(i, 21) * 7.0
			draw_colored_polygon(PackedVector2Array([bp + Vector2(-rs, 0.0), bp + Vector2(-rs * 0.4, -rs), bp + Vector2(rs * 0.6, -rs * 0.8), bp + Vector2(rs, 0.0)]), Color("#5d4448"))
			draw_colored_polygon(PackedVector2Array([bp + Vector2(-rs * 0.4, -rs), bp + Vector2(rs * 0.6, -rs * 0.8), bp + Vector2(rs * 0.1, -rs * 0.3)]), Color("#7a5c60"))
		# cristales rojos (los de atras primero)
		var order: Array = [0, 1, 2, 3, 4, 5, 6]
		order.sort_custom(func(x, y): return sin(TAU * float(x) / 7.0 + 0.5) < sin(TAU * float(y) / 7.0 + 0.5))
		for idx in order:
			var a2: float = TAU * float(idx) / 7.0 + 0.5
			var b := Vector2(sn(cos(a2) * 68.0), sn(sin(a2) * 26.0))
			var hh: float = 30.0 + hs(idx, 33) * 26.0
			var wd: float = 9.0 + hs(idx, 35) * 5.0
			var tilt: float = (hs(idx, 37) - 0.5) * 14.0
			var top := b + Vector2(tilt, -hh)
			# halo
			draw_circle(b + Vector2(tilt * 0.5, -hh * 0.5), hh * 0.8, Color(1.0, 0.2, 0.4, 0.05 + 0.04 * beat))
			draw_colored_polygon(PackedVector2Array([b + Vector2(-wd, 0.0), b + Vector2(-wd * 0.8, -hh * 0.65), top, b + Vector2(0.0, 0.0)]), Color("#b3103a"))
			draw_colored_polygon(PackedVector2Array([b + Vector2(0.0, 0.0), top, b + Vector2(wd * 0.8, -hh * 0.65), b + Vector2(wd, 0.0)]), Color("#ff3d6a").lerp(Color("#ff8aa6"), 0.3 * beat))
			draw_colored_polygon(PackedVector2Array([top, b + Vector2(wd * 0.8, -hh * 0.65), b + Vector2(wd * 0.25, -hh * 0.6)]), Color("#ffd0dc"))


# Columna de luz roja de la guarida: haz vertical con nucleo claro, anillos que suben, polvo de cristal y chispas.
class Pillar extends Node2D:
	var t := randf() * 10.0

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		z_index = 3

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var beat: float = 0.5 + 0.5 * sin(t * 3.0)
		var hgt: float = 1100.0
		var layers: Array = [[70.0, 0.14, Color(1.0, 0.15, 0.3)], [46.0, 0.22, Color(1.0, 0.25, 0.4)], [28.0, 0.34, Color(1.0, 0.45, 0.58)], [14.0, 0.55, Color(1.0, 0.85, 0.9)]]
		for ly in layers:
			var w: float = float(ly[0]) + beat * 5.0
			var c: Color = ly[2]
			var al: float = float(ly[1])
			draw_polygon(PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0), Vector2(w * 0.3, -hgt), Vector2(-w * 0.3, -hgt)]),
				PackedColorArray([Color(c.r, c.g, c.b, al), Color(c.r, c.g, c.b, al), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.0)]))
		# anillos que suben por la columna
		for i in range(6):
			var ph: float = fposmod(t * 0.35 + float(i) / 6.0, 1.0)
			var y: float = -ph * 520.0
			var rx: float = 26.0 + 14.0 * ph
			draw_set_transform(Vector2(0.0, y), 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, rx, 0.0, TAU, 28, Color(1.0, 0.7, 0.8, (1.0 - ph) * 0.55), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# resplandor en la base
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 58.0 + beat * 6.0, Color(1.0, 0.3, 0.45, 0.22))
		draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.7, 0.8, 0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# chispas y esquirlas que suben
		for i in range(26):
			var ph2: float = fposmod(t * 0.45 + float(i) * 0.0385, 1.0)
			var xx: float = sin(float(i) * 5.1 + t * 1.3) * (16.0 + 12.0 * ph2)
			var sz: float = 4.0 if i % 3 == 0 else 3.0
			draw_rect(Rect2(roundf(xx / 3.0) * 3.0, roundf(-ph2 * 760.0 / 3.0) * 3.0, sz, sz), Color(1.0, 0.9, 0.93, (1.0 - ph2) * 0.9))


static func unlocked(stats: Dictionary) -> bool:
	return int(stats.get("dens", 0)) >= 1


func start(main) -> void:
	m = main
	active = true
	t = DUR
	total = DUR
	n = 0
	pulse = 0.6
	since = 0.0
	type = String(m.player.types[0])
	bonus = roundf(m.player.max_hp * HP_BONUS)
	m.player.max_hp += bonus
	m.player.hp += bonus
	m.player.scale = Vector2.ONE
	# Crecimiento por pasos, como la seta gigante de Super Mario Bros DS: crece, se encoge un poco y vuelve a crecer, cada vez mas.
	var tw = m.create_tween()
	var steps: Array = [[1.22, 1.0, 0.14], [1.04, 1.04, 0.10], [1.42, 1.3, 0.16], [1.16, 1.2, 0.10], [GROW * 1.12, GROW * 1.12, 0.22], [GROW, GROW, 0.18]]
	for stp in steps:
		tw.tween_property(m.player, "scale", Vector2(float(stp[0]), float(stp[1])), float(stp[2])).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	m.get_tree().create_timer(0.14).timeout.connect(func(): _grow_fx(0.4))
	m.get_tree().create_timer(0.40).timeout.connect(func(): _grow_fx(0.7))
	m.get_tree().create_timer(0.72).timeout.connect(func(): _grow_fx(1.0))
	aura_node = Aura.new()
	aura_node.h = m.player.body_h
	aura_node.w = m.player.radius * 1.8
	aura_node.col = Color(0.9, 0.08, 0.25)
	m.player.add_child(aura_node)
	m.player.invuln = maxf(m.player.invuln, 1.2)
	m.shake = maxf(m.shake, 9.0)
	var col: Color = Color.html(String(m.MD.TYPE_COLOR.get(type, "#ff2a6d")))
	m.pfx.ring(m.player.position, 10.0, 360.0, col, 0.7, 6.0)
	m.pfx.ring(m.player.position, 10.0, 240.0, Color.WHITE, 0.5, 4.0)
	m.pfx.burst(m.player.position, col, 28, 260.0)


# Destello y sonido de cada paso del crecimiento.
func _grow_fx(k: float) -> void:
	if not active or m == null:
		return
	m.player.flash = 1.0
	m.shake = maxf(m.shake, 4.0 + 5.0 * k)
	Aud.sfx("levelup")
	var col: Color = Color(1.0, 0.3, 0.45)
	m.pfx.ring(m.player.position, 8.0, 90.0 + 110.0 * k, col.lerp(Color.WHITE, 0.4), 0.45, 4.0)
	m.pfx.burst(m.player.position + Vector2(0.0, -m.player.body_h * 0.5), col, int(10.0 + 14.0 * k), 220.0)


func stop() -> void:
	if not active:
		return
	active = false
	m.dyn_cd = COOLDOWN
	var mx: float = m.player.max_hp
	var nm: float = maxf(1.0, mx - bonus)
	m.player.hp = maxf(1.0, roundf(m.player.hp * nm / maxf(mx, 1.0))) if m.player.hp > 0.0 else m.player.hp
	m.player.max_hp = nm
	if aura_node != null and is_instance_valid(aura_node):
		aura_node.queue_free()
	aura_node = null
	var tw2 = m.create_tween()
	tw2.tween_property(m.player, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bonus = 0.0
	var col: Color = Color.html(String(m.MD.TYPE_COLOR.get(type, "#ff2a6d")))
	m.pfx.ring(m.player.position, 10.0, 200.0, col, 0.5, 4.0)
	m.pfx.burst(m.player.position, col, 14, 160.0)


func tick(delta: float) -> void:
	if not active:
		return
	t -= delta
	since += delta
	var col: Color = Color.html(String(m.MD.TYPE_COLOR.get(type, "#ff2a6d")))
	aura -= delta
	if aura <= 0.0:
		aura = 0.18
		m.pfx.burst(m.player.position + Vector2(randf_range(-26.0, 26.0), -20.0), col, 2, 70.0)
	pulse -= delta
	if pulse <= 0.0:
		pulse = PULSE
		n += 1
		_pulse(n % 3 == 0, col)
	if t <= 0.0:
		stop()


# Onda Max: golpea a los enemigos cercanos con el tipo del Pokemon; cada tercera es mas grande.
func _pulse(big: bool, col: Color) -> void:
	var z = ZMS.new()
	z.m = m
	z.type = type
	z.pal = type
	z.c = m.player.position
	z.dmg = (30.0 + 8.0 * float(m.player.level)) * m._atk() * (1.9 if big else 1.0)
	var r: float = 420.0 if big else 280.0
	z.boom(z.c, r, 6.0 if big else 3.0)
	var st: Array = STATUS.get(type, ["", 0, 0.0])
	z.hit(z.c, r, 1.0, 260.0 if big else 140.0, String(st[0]), int(st[1]), float(st[2]))
	if big:
		z.ring_burst("star", 14, 40.0, 520.0, 0.5, 1.6)
