extends RefCounted
# S57.5-57.6: Kecleon, el comerciante. Seis variantes con catalogo propio de 6 objetos, una compra por visita,
# un reroll por visita con precio global creciente, un solo Kecleon activo y separacion minima.
# Los efectos se conectan a las funciones de estadisticas ya existentes en main.gd (no hay pipelines paralelos).

const REROLL := [50, 100, 175, 275, 400, 550]
const VISIT_TIME := 75.0
const MIN_SEP := 520.0
const SEAL_FLOOR := 0.6

# variante -> nombre, color de etiqueta, tinte del sprite
const VAR := {
	"green": {"name": "Kecleon verde", "col": "#6bd66b", "tint": Color(1, 1, 1), "w": 40.0},
	"blue": {"name": "Kecleon azul", "col": "#5ab0ff", "tint": Color(0.55, 0.72, 1.0), "w": 20.0},
	"purple": {"name": "Kecleon morado", "col": "#b57bff", "tint": Color(0.82, 0.62, 1.0), "w": 16.0},
	"red": {"name": "Kecleon rojo", "col": "#ff6b6b", "tint": Color(1.0, 0.55, 0.5), "w": 14.0},
	"gold": {"name": "Kecleon dorado", "col": "#ffd23f", "tint": Color(1.0, 0.88, 0.42), "w": 10.0},
	"shiny": {"name": "Kecleon azul shiny", "col": "#7fe8ff", "tint": Color(0.8, 0.95, 1.25), "w": 0.0},
}
const ORDER := ["green", "blue", "purple", "red", "gold", "shiny"]

# id: [nombre, precio, maximo, descripcion]
const ITEMS := {
	"fortune": ["Trébol", 120, 1, "+10% de suerte en cofres y premios normales. Nunca cambia las probabilidades fijas."],
	"sprout": ["Brote Sanador", 100, 2, "Cada 15 derrotas, recuperas el 4% de tu vida máxima (por unidad)."],
	"thornscarf": ["Bufanda de Espinas", 150, 1, "Al recibir daño, hieres a los enemigos pegados a ti. Recarga 4 s."],
	"opener": ["Colmillo Inicial", 130, 1, "El primer golpe a cada enemigo normal hace +40% de daño."],
	"canteen": ["Cantimplora", 120, 1, "Cada 45 s, recuperas el 12% de tu vida máxima."],
	"afterimage": ["Imagen Residual", 280, 1, "Al recibir daño, ráfaga de velocidad (+35%, 2,5 s). Recarga 20 s."],
	"ribbon": ["Cinta Evasiva", 140, 3, "+3% de esquivar un golpe por unidad."],
	"gustback": ["Ráfaga de Retroceso", 170, 1, "Al recibir daño, empujas lejos a los enemigos cercanos. Recarga 8 s."],
	"veil": ["Velo Espectral", 220, 1, "Cada 25 s, 1,2 s de invulnerabilidad."],
	"tailwind": ["Viento de Cola", 180, 1, "Cada derrota te da 0,8 s de +25% de velocidad."],
	"mystic": ["Orbe Místico", 160, 2, "+10% de daño de estados (veneno y quemadura) por unidad."],
	"hexing": ["Campana Maldita", 120, 2, "+8% de duración de los estados negativos por unidad."],
	"echo": ["Eco Resonante", 140, 1, "Cada 12 s, tu siguiente golpe hace +20% de daño."],
	"binding": ["Runa de Atadura", 200, 1, "15% de ralentizar a enemigos normales en cada golpe."],
	"ember": ["Colmillo Brasa", 150, 2, "+8% de daño a enemigos con menos del 40% de vida por unidad."],
	"berserk": ["Banda Rabiosa", 180, 1, "+10% de daño mientras tengas menos del 50% de vida."],
	"shatter": ["Piedra Quebrantadora", 230, 2, "+10% de daño a élites y jefes por unidad."],
	"executioner": ["Marca del Verdugo", 220, 1, "Los enemigos normales con menos del 10% de vida caen al instante."],
	"drum": ["Tambor de Guerra", 280, 1, "10 derrotas en 6 s dan +15% de velocidad de ataque durante 6 s."],
	"dragonfire": ["Núcleo Dragón", 320, 1, "Cada 25 golpes, una pequeña explosión extra."],
	"royal": ["Botín Real", 200, 2, "10% de ganar +1 moneda por derrota, por unidad (máx. 300 por partida)."],
	"tmap": ["Mapa del Tesoro", 240, 1, "+25% de cofres en zonas nuevas."],
	"seal": ["Sello del Mercader", 150, 1, "-10% en objetos futuros de comerciantes (no en los cambios de ofertas)."],
	"dice": ["Dados de la Suerte", 200, 1, "Tu próximo cofre da un premio de mayor calidad. Un solo uso."],
	"crown": ["Corona de la Abundancia", 350, 1, "+160 monedas al derrotar a cada uno de tus 3 primeros jefes."],
	"chrono": ["Reliquia Cronos", 320, 1, "Cada 40 s, ralentiza 5 s a los enemigos normales cercanos."],
	"infinity": ["Fragmento Infinito", 450, 1, "Potencia tu mejora más alta (+15% de niveles, mínimo +1)."],
	"mirror": ["Espejo Doble", 300, 1, "12% de que cada golpe se repita con el 60% de su daño."],
	"starfall": ["Lluvia Estelar", 350, 1, "Cada 30 s, caen estrellas sobre los 5 enemigos más cercanos."],
}
const CAT := {
	"green": ["fortune", "sprout", "thornscarf", "opener", "canteen"],
	"blue": ["afterimage", "ribbon", "gustback", "veil", "tailwind"],
	"purple": ["mystic", "hexing", "echo", "binding"],
	"red": ["ember", "executioner", "berserk", "shatter", "drum", "dragonfire"],
	"gold": ["royal", "tmap", "seal", "dice", "crown"],
	"shiny": ["chrono", "infinity", "mirror", "starfall"],
}

var m = null
var kc := {}
var reroll_n := 0
var active = null          # nodo Merchant
var variant := ""
var offers: Array = []
var bought := false
var rerolled := false
var kec_t := 210.0
var seen := {}             # variantes vistas esta partida
var log: Array = []
# estados de objetos
var echo_t := 12.0
var echo_ready := false
var after_t := 0.0
var after_cd := 0.0
var drum_times: Array = []
var drum_t := 0.0
var hit_n := 0
var chrono_t := 40.0
var phoenix_used := false
var tail_t := 0.0
var sprout_n := 0
var scarf_cd := 0.0
var gust_cd := 0.0
var canteen_t := 45.0
var veil_t := 25.0
var star_t := 30.0
var crown_done := false
var crown_n := 0
var royal_got := 0
var dice_ready := false
var infinity_id := ""
var _busy_hit := false
# interfaz
var ui = null
var ui_btns: Array = []
var ui_info = null
var ui_coins = null
var ui_reroll = null


func n(id: String) -> int:
	return int(kc.get(id, 0))


# ------------------------------------------------------------------ catalogo
func valid(id: String) -> bool:
	return ITEMS.has(id)


func eligible(id: String) -> bool:
	if not valid(id):
		return false
	if n(id) >= int(ITEMS[id][2]):
		return false
	match id:
		"dice":
			return not dice_ready
		"crown":
			return not crown_done
		"infinity":
			return _inf_target() != ""
	return true


func _inf_target() -> String:
	var best := ""
	var bl := 0
	for sid in m.STAT_IDS:
		if sid == "hp" or sid == "heal" or sid == "rgn":
			continue
		var lv: int = int(m.stat_lv.get(sid, 0))
		if lv > bl and lv < int(m.STATS[sid]["max"]):
			bl = lv
			best = String(sid)
	return best


func price(id: String) -> int:
	var p: int = int(ITEMS[id][1])
	if n("seal") > 0 and id != "seal":
		p = maxi(int(round(float(ITEMS[id][1]) * SEAL_FLOOR)), int(round(float(p) * 0.9)))
	return p


func reroll_price() -> int:
	if reroll_n < REROLL.size():
		return int(REROLL[reroll_n])
	return int(REROLL[REROLL.size() - 1]) + 150 * (reroll_n - REROLL.size() + 1)


func pool_of(v: String) -> Array:
	var out: Array = []
	for id in CAT[v]:
		if eligible(String(id)):
			out.append(String(id))
	return out


func pick_offers(v: String, avoid: Array = []) -> Array:
	var pool: Array = pool_of(v)
	var fresh: Array = []
	for id in pool:
		if not avoid.has(id):
			fresh.append(id)
	fresh.shuffle()
	var out: Array = fresh.slice(0, 3)
	if out.size() < 3:   # no hay suficientes alternativas: se completan con las anteriores
		var rest: Array = []
		for id in pool:
			if not out.has(id):
				rest.append(id)
		rest.shuffle()
		for id in rest:
			if out.size() < 3:
				out.append(id)
	return out


# ------------------------------------------------------------------ compra
# Devuelve "" si todo fue bien o el motivo del rechazo. Nada se cobra si falla.
func buy(id: String) -> String:
	if bought:
		return "ya"
	if not offers.has(id) or not eligible(id):
		return "invalido"
	var p: int = price(id)
	if m.coins < p:
		return "fondos"
	m.coins -= p
	bought = true
	_apply(id)
	log.append(["buy", variant, id, p])
	return ""


func _apply(id: String) -> void:
	match id:
		"dice":
			dice_ready = true
		"infinity":
			var t: String = _inf_target()
			infinity_id = t
			if t != "":
				var lv: int = int(m.stat_lv.get(t, 0))
				var add: int = maxi(1, int(ceil(float(lv) * 0.15)))
				m.stat_lv[t] = mini(int(m.STATS[t]["max"]), lv + add)
			kc[id] = n(id) + 1
		_:
			kc[id] = n(id) + 1
	m.Aud.sfx("shinyGet")
	m.add_text(m.player.position + Vector2(0, -m.player.body_h - 20.0), m.L.t(String(ITEMS[id][0])), Color(VAR[variant]["col"]), 22)


func try_reroll() -> String:
	if bought or rerolled:
		return "ya"
	var p: int = reroll_price()
	if m.coins < p:
		return "fondos"
	var fresh: Array = pick_offers(variant, offers)
	if fresh.is_empty():
		return "invalido"
	m.coins -= p
	reroll_n += 1
	rerolled = true
	offers = fresh
	log.append(["reroll", p])
	return ""


# ------------------------------------------------------------------ modificadores (se enchufan a main.gd)
func dmg_mul(e) -> float:
	var k := 1.0
	if e != null:
		if e.hp < e.max_hp * 0.4:
			k += 0.08 * float(n("ember"))
		if e.boss or e.has_meta("elite"):
			k += 0.10 * float(n("shatter"))
		if n("opener") > 0 and not e.boss and not e.has_meta("kop"):
			e.set_meta("kop", true)
			k += 0.4
	if n("berserk") > 0 and m.player.hp < m.player.max_hp * 0.5:
		k += 0.10
	return k


func spd_mul() -> float:
	return 1.0 + (0.35 if after_t > 0.0 else 0.0) + (0.25 if tail_t > 0.0 else 0.0)


func cd_mul() -> float:
	return 1.0 / (1.0 + (0.15 if drum_t > 0.0 else 0.0))


func def_add() -> float:
	return 0.0


func xp_mul() -> float:
	return 1.0


func mag_mul() -> float:
	return 1.0


func range_mul() -> float:
	return 1.0


func cc_dur() -> float:
	return 1.0 + 0.08 * float(n("hexing"))


func dot_mul() -> float:
	return 1.0 + 0.10 * float(n("mystic"))


func luck() -> float:
	return 0.10 if n("fortune") > 0 else 0.0


func map_mul() -> float:
	return 1.25 if n("tmap") > 0 else 1.0


func dodge() -> bool:
	var p: float = minf(0.15, 0.03 * float(n("ribbon")))
	return p > 0.0 and randf() < p


# Cofre: la suerte y los Dados mejoran la calidad (r mas alto = mejor premio). Los dados se gastan una vez.
func chest_roll_adjust(r: float) -> float:
	if dice_ready:
		dice_ready = false
		log.append(["dice"])
		return 0.85
	return minf(0.999, r + luck() * 0.8)


# ------------------------------------------------------------------ eventos de combate
func on_hit(e, d: float) -> void:
	if _busy_hit:
		return
	# Cristal Eco: se consume el siguiente golpe (el bonus ya se aplico en dmg_mul_echo)
	if n("executioner") > 0 and not e.boss and not e.dead and e.hp < e.max_hp * 0.10:
		_busy_hit = true
		m._damage_enemy(e, e.hp + 1.0, Color("#ff4a4a"))
		_busy_hit = false
		return
	if n("mirror") > 0 and not e.dead and randf() < 0.12:
		_busy_hit = true
		m._damage_enemy(e, maxf(1.0, d * 0.6), Color("#cfe8ff"))
		_busy_hit = false
	if n("binding") > 0 and not e.boss and randf() < 0.15:
		e.apply_slow(0.3, 2.0)
	if n("dragonfire") > 0:
		hit_n += 1
		if hit_n >= 25:
			hit_n = 0
			_busy_hit = true
			var c: Vector2 = e.position
			m._ring(c, 6.0, 90.0, Color("#ff7b3d"), 0.4, 4.0)
			for o in m.enemies.duplicate():
				if is_instance_valid(o) and not o.dead and o.position.distance_to(c) < 90.0:
					m._damage_enemy(o, maxf(8.0, d * 0.8), Color("#ff7b3d"))
			_busy_hit = false


func echo_take() -> float:
	if n("echo") > 0 and echo_ready:
		echo_ready = false
		echo_t = 12.0
		return 1.2
	return 1.0


func on_kill(e) -> void:
	if n("tailwind") > 0:
		tail_t = 0.8
	if n("sprout") > 0:
		sprout_n += 1
		if sprout_n >= 15:
			sprout_n = 0
			_heal_pct(0.04 * float(n("sprout")))
	if n("royal") > 0 and royal_got < 300 and randf() < 0.10 * float(n("royal")):
		m.coins += 1
		royal_got += 1
	if n("drum") > 0:
		drum_times.append(m.run_time)
		while not drum_times.is_empty() and m.run_time - float(drum_times[0]) > 6.0:
			drum_times.remove_at(0)
		if drum_times.size() >= 10 and drum_t <= 0.0:
			drum_t = 6.0
			drum_times.clear()
			m.add_text(m.player.position + Vector2(0, -m.player.body_h - 24.0), m.L.t("¡Tambor de Guerra!"), Color("#ff6b6b"), 22)
	if n("crown") > 0 and crown_n < 3 and e.boss and not e.judge:
		crown_n += 1
		crown_done = crown_n >= 3
		for i in range(8):
			m._spawn_orb(e.position, "coin", 20.0)
		m.add_text(e.position + Vector2(0, -50), m.L.t("¡Corona de la Abundancia!"), Color("#ffd23f"), 24)


func on_hurt() -> void:
	if n("afterimage") > 0 and after_cd <= 0.0:
		after_cd = 20.0
		after_t = 2.5
	var c: Vector2 = m.player.position
	if n("thornscarf") > 0 and scarf_cd <= 0.0:
		scarf_cd = 4.0
		m._ring(c, 6.0, 80.0, Color("#6bd66b"), 0.35, 3.0)
		for o in m.enemies.duplicate():
			if is_instance_valid(o) and not o.dead and o.position.distance_to(c) < 80.0:
				m._damage_enemy(o, 14.0 + 3.0 * float(m.player.level), Color("#6bd66b"))
	if n("gustback") > 0 and gust_cd <= 0.0:
		gust_cd = 8.0
		m._ring(c, 6.0, 140.0, Color("#9fd8ff"), 0.4, 3.0)
		for o in m.enemies:
			if is_instance_valid(o) and not o.dead and not o.boss and o.position.distance_to(c) < 140.0:
				o.position += (o.position - c).normalized() * 110.0


func _heal_pct(p: float) -> void:
	var hl: float = m._heal_real(maxf(1.0, m.player.max_hp * p))
	if hl > 0.0:
		m.add_text(m.player.position + Vector2(randf_range(-10.0, 10.0), -m.player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 16)


# Ya no existe la Pluma Fenix (duplicaba Segunda oportunidad): se mantiene por compatibilidad con main.gd.
func try_phoenix() -> bool:
	return false


func tick(delta: float) -> void:
	echo_t -= delta
	if n("echo") > 0 and echo_t <= 0.0:
		echo_ready = true
		echo_t = 0.0
	tail_t = maxf(0.0, tail_t - delta)
	scarf_cd = maxf(0.0, scarf_cd - delta)
	gust_cd = maxf(0.0, gust_cd - delta)
	if n("canteen") > 0:
		canteen_t -= delta
		if canteen_t <= 0.0:
			canteen_t = 45.0
			_heal_pct(0.12)
	if n("veil") > 0:
		veil_t -= delta
		if veil_t <= 0.0:
			veil_t = 25.0
			m.player.invuln = maxf(m.player.invuln, 1.2)
			m._ring(m.player.position, 6.0, 90.0, Color("#cfc2ff"), 0.5, 3.0)
	if n("starfall") > 0:
		star_t -= delta
		if star_t <= 0.0:
			star_t = 30.0
			var near: Array = m._p_targets(5, 460.0)
			for o in near:
				m._ring(o.position, 4.0, 60.0, Color("#ffe14a"), 0.4, 3.0)
				m._damage_enemy(o, 80.0 + 8.0 * float(m.player.level), Color("#ffe14a"))
	after_t = maxf(0.0, after_t - delta)
	after_cd = maxf(0.0, after_cd - delta)
	drum_t = maxf(0.0, drum_t - delta)
	if n("chrono") > 0:
		chrono_t -= delta
		if chrono_t <= 0.0:
			chrono_t = 40.0
			var c: Vector2 = m.player.position
			m._ring(c, 8.0, 380.0, Color("#9fe8ff"), 0.7)
			for e in m.enemies:
				if is_instance_valid(e) and not e.dead and not e.boss and e.position.distance_to(c) < 380.0:
					e.apply_slow(0.6, 5.0)


# ------------------------------------------------------------------ aparicion del comerciante
class Merchant extends Node2D:
	var variant := "green"
	var ttl := 75.0
	var t := 0.0
	var actor = null
	var uid := 0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var K = load("res://scripts/kecleon.gd")
		var v: Dictionary = K.VAR[variant]
		var col: Color = Color(String(v["col"]))
		draw_circle(Vector2(0, 4), 22.0, Color(0, 0, 0, 0.3))
		draw_arc(Vector2(0, -20), 34.0 + 2.0 * sin(t * 3.0), 0, TAU, 28, Color(col.r, col.g, col.b, 0.5), 2.0)
		if actor != null:
			return
		# Kecleon dibujado (si no hay sprite): cuerpo, franja en zigzag y ojos
		var tint: Color = v["tint"]
		var body: Color = Color("#7bc36a") * tint
		body.a = 1.0
		draw_circle(Vector2(0, -22), 18.0, body)
		draw_circle(Vector2(0, -34), 13.0, body)
		for i in range(5):
			var x: float = -16.0 + 8.0 * float(i)
			draw_colored_polygon(PackedVector2Array([Vector2(x, -14), Vector2(x + 4, -5), Vector2(x + 8, -14)]), Color("#e8594a"))
		draw_circle(Vector2(-6, -36), 3.0, Color.WHITE)
		draw_circle(Vector2(6, -36), 3.0, Color.WHITE)
		draw_circle(Vector2(-6, -36), 1.5, Color.BLACK)
		draw_circle(Vector2(6, -36), 1.5, Color.BLACK)


func shiny_chance(t: float) -> float:
	var pts := [[180.0, 0.01], [300.0, 0.02], [480.0, 0.04], [720.0, 0.07], [960.0, 0.10], [1200.0, 0.12]]
	if t < 180.0:
		return 0.0
	for i in range(pts.size() - 1):
		if t <= float(pts[i + 1][0]):
			var a: Array = pts[i]
			var b: Array = pts[i + 1]
			return lerpf(float(a[1]), float(b[1]), (t - float(a[0])) / (float(b[0]) - float(a[0])))
	return 0.12


func choose_variant() -> String:
	var shiny_ok: bool = not pool_of("shiny").is_empty()
	if shiny_ok and randf() < shiny_chance(m.run_time):   # una sola tirada por oportunidad
		return "shiny"
	var tot := 0.0
	var ok: Array = []
	for v in ORDER:
		if v == "shiny":
			continue
		if not pool_of(v).is_empty():
			ok.append(v)
			tot += float(VAR[v]["w"])
	if ok.is_empty():
		return ""
	var r: float = randf() * tot
	for v in ok:
		r -= float(VAR[v]["w"])
		if r <= 0.0:
			return String(v)
	return String(ok[ok.size() - 1])


# pos_ok(pos) lo da el director de POI (muros, separacion con otros puntos).
func spawn(pos_ok: Callable, force: String = "") -> bool:
	if active != null and is_instance_valid(active):
		return false      # un solo Kecleon activo
	var v: String = force if force != "" else choose_variant()
	if v == "" or pool_of(v).is_empty():
		return false
	m.ach_event("kec", {"variant": v})
	var pos: Variant = null
	for i in range(8):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 480.0)
		if pos_ok.call(c):
			pos = c
			break
	if pos == null:
		return false
	var mer := Merchant.new()
	mer.variant = v
	mer.ttl = VISIT_TIME
	mer.position = pos
	m.world.add_child(mer)
	_attach_sprite(mer, v)
	active = mer
	variant = v
	offers = pick_offers(v)
	bought = false
	rerolled = false
	seen[v] = true
	m.Aud.sfx("rift")
	m._say(m.L.t("¡Ha llegado un %s!") % m.L.t(String(VAR[v]["name"])), 3.0)
	m._ring(pos, 6.0, 90.0, Color(String(VAR[v]["col"])), 0.6, 4.0)
	log.append(["spawn", v])
	return true


func _attach_sprite(mer, v: String) -> void:
	if not (m._dex_by.has(352) and m._smeta.has("352")):
		return
	var a = m.Actor.new()
	a.setup(352, m._sm(352), m.flash_shader, 1.0, v == "shiny")
	a.modulate = VAR[v]["tint"]
	mer.add_child(a)
	mer.actor = a


func depart() -> void:
	if active != null and is_instance_valid(active):
		m._ring(active.position, 6.0, 70.0, Color(String(VAR[variant]["col"])), 0.4, 3.0)
		active.queue_free()
	active = null
	close_ui()
	log.append(["depart", variant])


# ------------------------------------------------------------------ interfaz de la tienda
func open_ui() -> void:
	if ui != null or active == null:
		return
	m.shop_open = true
	var layer := CanvasLayer.new()
	layer.layer = 70
	m.add_child(layer)
	ui = layer
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var kth := Theme.new()
	kth.default_font_size = 20
	load("res://scripts/pxfont.gd").apply(kth)   # misma fuente pixelada que el resto del juego
	root.theme = kth
	layer.add_child(root)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var col := Color(String(VAR[variant]["col"]))
	sb.bg_color = Color("#27489a")
	sb.border_color = Color("#f4f8ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color("#0b1838")
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = m.L.t(String(VAR[variant]["name"]))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", col)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	ui_coins = Label.new()
	ui_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_coins.add_theme_font_size_override("font_size", 22)
	vb.add_child(ui_coins)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	ui_btns = []
	for i in range(3):
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 190)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 20)
		_style_btn(b, false)
		b.pressed.connect(_on_buy.bind(i))
		row.add_child(b)
		ui_btns.append(b)
	ui_info = Label.new()
	ui_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_info.add_theme_font_size_override("font_size", 18)
	vb.add_child(ui_info)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row2)
	ui_reroll = Button.new()
	ui_reroll.custom_minimum_size = Vector2(250, 64)
	ui_reroll.add_theme_font_size_override("font_size", 24)
	_style_btn(ui_reroll, true)
	ui_reroll.pressed.connect(_on_reroll)
	row2.add_child(ui_reroll)
	var close := Button.new()
	close.text = m.L.t("Cerrar")
	close.custom_minimum_size = Vector2(200, 64)
	close.add_theme_font_size_override("font_size", 24)
	_style_btn(close, false)
	close.pressed.connect(close_ui)
	row2.add_child(close)
	_refresh_ui()
	if not ui_btns.is_empty():
		(ui_btns[0] as Button).grab_focus()


func _refresh_ui() -> void:
	if ui == null:
		return
	ui_coins.text = "%s: %d" % [m.L.t("Monedas"), m.coins]
	for i in range(3):
		var b: Button = ui_btns[i]
		if i < offers.size():
			var id: String = String(offers[i])
			var it: Array = ITEMS[id]
			b.visible = true
			b.text = "%s\n\n%s\n\n%d  (%d/%d)" % [m.L.t(String(it[0])), m.L.t(String(it[3])), price(id), n(id), int(it[2])]
			b.disabled = bought or m.coins < price(id)
		else:
			b.visible = false
	ui_reroll.text = "%s  (%d)" % [m.L.t("Cambiar ofertas"), reroll_price()]
	ui_reroll.disabled = bought or rerolled or m.coins < reroll_price()
	if bought:
		ui_info.text = m.L.t("¡Gracias por tu compra!")
	elif rerolled:
		ui_info.text = m.L.t("Solo una recarga por visita")
	else:
		ui_info.text = m.L.t("Solo puedes comprar un objeto por visita")


func _on_buy(i: int) -> void:
	if i >= offers.size():
		return
	var r: String = buy(String(offers[i]))
	if r == "":
		_refresh_ui()
		close_ui_later()
	elif r == "fondos":
		m.Aud.sfx("hit")
	_refresh_ui()


func _on_reroll() -> void:
	var r: String = try_reroll()
	if r == "":
		m.Aud.sfx("coin")
	_refresh_ui()
	if not ui_btns.is_empty() and (ui_btns[0] as Button).visible:
		(ui_btns[0] as Button).grab_focus()


static func _sbx(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(12)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color("#0b1838")
	s.shadow_size = 3
	return s


# Mismo estilo de boton que el menu de pausa (azul / dorado)
func _style_btn(b: Button, gold: bool) -> void:
	var bg: Color = Color("#f6b52b") if gold else Color("#2b4f9e")
	var bgh: Color = Color("#ffcf55") if gold else Color("#3a64bf")
	var fc: Color = Color("#3d2a00") if gold else Color.WHITE
	b.add_theme_stylebox_override("normal", _sbx(bg, Color.WHITE, 3))
	b.add_theme_stylebox_override("hover", _sbx(bgh, Color.WHITE, 3))
	b.add_theme_stylebox_override("pressed", _sbx(bg.darkened(0.2), Color.WHITE, 3))
	b.add_theme_stylebox_override("focus", _sbx(bgh, Color("#fff2a0") if gold else Color("#ffd23f"), 5))
	b.add_theme_stylebox_override("disabled", _sbx(Color("#1c2c5c"), Color("#6f7fae"), 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)
	b.add_theme_color_override("font_disabled_color", Color("#8d9bc7"))


func close_ui_later() -> void:
	# tras comprar, la tienda se cierra un instante despues para que se vea el mensaje
	if ui == null:
		return
	var tw: Tween = ui.create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(_leave_after_buy)


# Tras comprar, Kecleon se marcha de verdad (una compra por visita)
func _leave_after_buy() -> void:
	depart()
	kec_t = randf_range(150.0, 240.0)


func close_ui() -> void:
	if ui != null and is_instance_valid(ui):
		ui.queue_free()
	ui = null
	ui_btns = []
	m.shop_open = false


# Atajos de teclado / mando mientras la tienda esta abierta (los llama main._input)
func ui_input(event: InputEvent) -> bool:
	if ui == null:
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				_on_buy(int(event.keycode) - KEY_1)
				return true
			KEY_R:
				_on_reroll()
				return true
			KEY_ESCAPE, KEY_BACKSPACE:
				close_ui()
				return true
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B:
			close_ui()
			return true
		if event.button_index == JOY_BUTTON_X:
			_on_reroll()
			return true
	return false


# ------------------------------------------------------------------ ciclo de vida (lo llama main cada frame de juego)
func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not m.poi._busy() and not m.shop_open \
		and (m.poi.supply == null or not is_instance_valid(m.poi.supply)) and m.run_time > 150.0


func update(delta: float) -> void:
	tick(delta)
	if active != null and not is_instance_valid(active):
		active = null
	if active != null:
		active.ttl -= delta
		if bought and ui == null:
			_leave_after_buy()
			return
		if active.ttl <= 0.0 or m.player.dead or m.poi._busy():
			depart()
			kec_t = randf_range(150.0, 240.0)
		return
	kec_t -= delta
	if kec_t <= 0.0:
		if _spawn_ok() and spawn(Callable(m.poi, "_ok_pos")):
			kec_t = 9999.0
		else:
			kec_t = 20.0   # reintento acotado; no bloquea nada


func near(pp: Vector2) -> bool:
	return active != null and is_instance_valid(active) and active.position.distance_to(pp) < 64.0 and not bought_done()


func bought_done() -> bool:
	return false


func mark() -> Variant:
	if active == null or not is_instance_valid(active):
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	return {"sp": ct * (active.position + Vector2(0, -50)), "txt": m.L.t(String(VAR[variant]["name"])) + "  %ds" % ceili(active.ttl),
		"col": Color(String(VAR[variant]["col"]))}
