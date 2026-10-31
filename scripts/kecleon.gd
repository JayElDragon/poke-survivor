extends RefCounted
# S57.5-57.6: Kecleon, el comerciante. Seis variantes con catalogo propio de 6 objetos, una compra por visita,
# rerolls sin limite mientras haya monedas (el precio sube en cada visita y se reinicia en la siguiente), un solo Kecleon activo y separacion minima.
# Los efectos se conectan a las funciones de estadisticas ya existentes en main.gd (no hay pipelines paralelos).

const IC = preload("res://scripts/icons.gd")
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
const RECOLOR := {"blue": Color("#4f8cff"), "purple": Color("#a860ff"), "red": Color("#ff4a4a"), "gold": Color("#ffc81f")}
const RECOLOR_SHADER := "shader_type canvas_item;\nuniform vec4 tint;\nuniform float shine = 0.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat l = dot(c.rgb, vec3(0.3, 0.59, 0.11));\n\tvec3 col = tint.rgb * (l * 1.5 + 0.08);\n\tcol = mix(col, vec3(1.0), smoothstep(0.7, 1.0, l) * 0.6);\n\tif (shine > 0.0) {\n\t\tfloat b = pow(0.5 + 0.5 * sin((UV.x + UV.y) * 70.0 - TIME * 4.0), 8.0);\n\t\tcol += vec3(1.0, 0.9, 0.5) * b * 0.55 * shine;\n\t}\n\tCOLOR = vec4(col, COLOR.a);\n}\n"

# id: [nombre, precio, maximo, descripcion]
const ITEMS := {
	"fortune": ["Trébol", 120, 1, "Los cofres dan premios mejores con más frecuencia."],
	"sprout": ["Brote Sanador", 100, 2, "Cada 15 enemigos derrotados recuperas un 4% de tu vida máxima. Cada copia suma otro 4%."],
	"thornscarf": ["Bufanda de Espinas", 150, 1, "Cuando te golpean, dañas a los enemigos que tienes muy cerca. Se recarga en 4 s."],
	"opener": ["Colmillo Inicial", 130, 1, "Tu primer golpe contra cada enemigo hace un 40% más de daño (no en jefes)."],
	"canteen": ["Cantimplora", 120, 1, "Cada 45 s, recuperas el 12% de tu vida máxima."],
	"afterimage": ["Imagen Residual", 280, 1, "Cuando te golpean, corres un 35% más rápido durante 2,5 s. Se recarga en 20 s."],
	"ribbon": ["Cinta Evasiva", 140, 3, "Un 3% de probabilidad de esquivar cada golpe. Cada copia suma otro 3%."],
	"gustback": ["Ráfaga de Retroceso", 170, 1, "Cuando te golpean, empujas lejos a los enemigos cercanos (no a jefes). Se recarga en 8 s."],
	"veil": ["Velo Espectral", 220, 1, "Cada 25 s eres invulnerable durante 1,2 s."],
	"tailwind": ["Viento de Cola", 180, 1, "Al derrotar a un enemigo corres un 25% más rápido durante 0,8 s."],
	"mystic": ["Orbe Místico", 160, 2, "El veneno y las quemaduras hacen un 10% más de daño. Cada copia suma otro 10%."],
	"hexing": ["Campana Maldita", 120, 2, "Los estados que causas (sueño, parálisis, congelación…) duran un 8% más. Cada copia suma otro 8%."],
	"echo": ["Eco Resonante", 140, 1, "Cada 12 s, tu siguiente golpe hace +20% de daño."],
	"binding": ["Runa de Atadura", 200, 1, "Cada golpe tiene un 15% de probabilidad de frenar al enemigo 2 s (no a jefes)."],
	"ember": ["Colmillo Brasa", 150, 2, "Un 8% más de daño a enemigos con menos del 40% de vida. Cada copia suma otro 8%."],
	"berserk": ["Banda Rabiosa", 180, 1, "Un 10% más de daño mientras tengas menos de la mitad de tu vida."],
	"shatter": ["Piedra Quebrantadora", 230, 2, "Un 10% más de daño a élites y jefes. Cada copia suma otro 10%."],
	"executioner": ["Marca del Verdugo", 220, 1, "Los enemigos con menos del 10% de vida mueren al golpearlos (no los jefes)."],
	"drum": ["Tambor de Guerra", 280, 1, "Si derrotas a 10 enemigos en 6 s, atacas un 15% más rápido durante 6 s."],
	"dragonfire": ["Núcleo Dragón", 320, 1, "Cada 25 golpes se produce una pequeña explosión en tu objetivo."],
	"royal": ["Botín Real", 200, 2, "Cada derrota tiene un 10% de probabilidad de darte 1 moneda extra. Cada copia suma otro 10% (máx. 300 monedas por partida)."],
	"tmap": ["Mapa del Tesoro", 240, 1, "Aparecen un 25% más de cofres en las zonas que aún no has explorado."],
	"seal": ["Sello del Mercader", 150, 1, "Los objetos de Kecleon te cuestan un 10% menos a partir de ahora (cambiar ofertas cuesta igual)."],
	"dice": ["Dados de la Suerte", 200, 1, "Tu próximo cofre te da un objeto seguro. Un solo uso."],
	"crown": ["Corona de la Abundancia", 350, 1, "Ganas 160 monedas al derrotar a cada uno de tus 3 primeros jefes."],
	"chrono": ["Reliquia Cronos", 320, 1, "Cada 40 s frena durante 5 s a los enemigos cercanos (no a jefes)."],
	"infinity": ["Fragmento Infinito", 450, 1, "Todo tu daño aumenta un 12%."],
	"mirror": ["Espejo Doble", 300, 1, "Cada golpe tiene un 12% de probabilidad de golpear otra vez con el 60% del daño."],
	"starfall": ["Lluvia Estelar", 350, 1, "Cada 30 s caen estrellas sobre los 5 enemigos más cercanos."],
	"magnetite": ["Piedra Imán", 110, 2, "Un 20% más de radio para recoger objetos y experiencia. Cada copia suma otro 20%."],
	"notebook": ["Cuaderno de Notas", 130, 2, "Un 8% más de experiencia. Cada copia suma otro 8%."],
	"shellplate": ["Caparazón Ligero", 170, 2, "Recibes un 5% menos de daño. Cada copia suma otro 5%."],
	"swiftboots": ["Botas Veloces", 190, 1, "Corres un 10% más rápido siempre."],
	"expandlens": ["Lente Expansiva", 190, 2, "Tus proyectiles y áreas son un 10% más grandes. Cada copia suma otro 10%."],
	"sandglass": ["Reloj de Arena", 210, 2, "Tus movimientos se recargan un 6% más rápido. Cada copia suma otro 6%."],
	"warhorn": ["Cuerno de Caza", 240, 1, "Un 8% más de daño a enemigos con más del 70% de vida."],
	"bloodstone": ["Piedra Sangre", 260, 1, "Cada 10 enemigos derrotados recuperas un 2% de tu vida máxima."],
	"coinpurse": ["Bolsa de Monedas", 220, 1, "Cada jefe derrotado suelta 80 monedas extra."],
	"luckycharm": ["Amuleto de la Suerte", 260, 1, "Los cofres dan premios todavía mejores. Se suma al Trébol."],
	"aurora": ["Aura Boreal", 420, 1, "Cada 30 s recuperas un 15% de tu vida máxima y eres invulnerable durante 1 s."],
	"comet": ["Cometa Errante", 400, 1, "Cada 20 s un cometa golpea con fuerza al enemigo más cercano."],
}
const CAT := {
	"green": ["fortune", "sprout", "thornscarf", "opener", "canteen", "magnetite", "notebook"],
	"blue": ["afterimage", "ribbon", "gustback", "veil", "tailwind", "shellplate", "swiftboots"],
	"purple": ["mystic", "hexing", "echo", "binding", "expandlens", "sandglass"],
	"red": ["ember", "executioner", "berserk", "shatter", "drum", "dragonfire", "warhorn", "bloodstone"],
	"gold": ["royal", "tmap", "seal", "dice", "crown", "coinpurse", "luckycharm"],
	"shiny": ["chrono", "infinity", "mirror", "starfall", "aurora", "comet"],
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
var blood_n := 0
var aurora_t := 30.0
var comet_t := 20.0
var crown_done := false
var crown_n := 0
var royal_got := 0
var dice_ready := false
var _busy_hit := false
# interfaz
var ui = null
var ui_btns: Array = []
var ui_info = null
var ui_coins = null
var ui_reroll = null
var ui_cards: Array = []
var ui_owned = null
var ui_close = null


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
	return true


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
		_:
			kc[id] = n(id) + 1
	m.Aud.sfx("shinyGet")
	m.add_text(m.player.position + Vector2(0, -m.player.body_h - 20.0), m.L.t(String(ITEMS[id][0])), Color(VAR[variant]["col"]), 22)


# Sin alternativas en el catalogo, cambiar ofertas costaria monedas y mostraria lo mismo.
func can_reroll() -> bool:
	return pool_of(variant).size() > offers.size()


func try_reroll() -> String:
	if bought:
		return "ya"
	if not can_reroll():
		return "invalido"
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
	var k := 1.0 + 0.12 * float(n("infinity"))
	if e != null:
		if e.hp < e.max_hp * 0.4:
			k += 0.08 * float(n("ember"))
		if e.boss or e.has_meta("elite"):
			k += 0.10 * float(n("shatter"))
		if n("opener") > 0 and not e.boss and not e.has_meta("kop"):
			e.set_meta("kop", true)
			k += 0.4
	if n("warhorn") > 0 and e != null and e.hp > e.max_hp * 0.7:
		k += 0.08
	if n("berserk") > 0 and m.player.hp < m.player.max_hp * 0.5:
		k += 0.10
	return k


func spd_mul() -> float:
	return 1.0 + (0.35 if after_t > 0.0 else 0.0) + (0.25 if tail_t > 0.0 else 0.0) + 0.10 * float(n("swiftboots"))


func cd_mul() -> float:
	return pow(0.94, float(n("sandglass"))) / (1.0 + (0.15 if drum_t > 0.0 else 0.0))


func def_add() -> float:
	return 0.05 * float(n("shellplate"))


func xp_mul() -> float:
	return 1.0 + 0.08 * float(n("notebook"))


func mag_mul() -> float:
	return 1.0 + 0.20 * float(n("magnetite"))


func range_mul() -> float:
	return 1.0 + 0.10 * float(n("expandlens"))


func cc_dur() -> float:
	return 1.0 + 0.08 * float(n("hexing"))


func dot_mul() -> float:
	return 1.0 + 0.10 * float(n("mystic"))


func luck() -> float:
	return (0.10 if n("fortune") > 0 else 0.0) + (0.10 if n("luckycharm") > 0 else 0.0)


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
	if n("bloodstone") > 0:
		blood_n += 1
		if blood_n >= 10:
			blood_n = 0
			_heal_pct(0.02)
	if n("coinpurse") > 0 and e.boss and not e.judge:
		for i in range(8):
			m._spawn_orb(e.position, "coin", 10.0)
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
	if n("aurora") > 0:
		aurora_t -= delta
		if aurora_t <= 0.0:
			aurora_t = 30.0
			_heal_pct(0.15)
			m.player.invuln = maxf(m.player.invuln, 1.0)
			m._ring(m.player.position, 6.0, 110.0, Color("#9fffe0"), 0.6, 4.0)
	if n("comet") > 0:
		comet_t -= delta
		if comet_t <= 0.0:
			comet_t = 20.0
			for o in m._p_targets(1, 520.0):
				m._ring(o.position, 4.0, 90.0, Color("#bfe8ff"), 0.5, 4.0)
				m._damage_enemy(o, 150.0 + 15.0 * float(m.player.level), Color("#bfe8ff"))
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


# Destellos alrededor del Kecleon dorado.
class GoldSparks extends Node2D:
	var t := 0.0

	func _init() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in range(8):
			var ph: float = fposmod(t * 0.7 + float(i) * 0.125, 1.0)
			var a: float = float(i) * 2.4
			var p := Vector2(cos(a) * (18.0 + 14.0 * sin(a * 3.0)), -24.0 + sin(a) * 26.0 - ph * 14.0)
			var s: float = 7.0 * sin(ph * PI)
			var c := Color(1.0, 0.95, 0.55, sin(ph * PI))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.22, -s * 0.22), p + Vector2(s, 0), p + Vector2(s * 0.22, s * 0.22), p + Vector2(0, s), p + Vector2(-s * 0.22, s * 0.22), p + Vector2(-s, 0), p + Vector2(-s * 0.22, -s * 0.22)]), c)


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
	reroll_n = 0
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
	mer.add_child(a)
	mer.actor = a
	# v6.1: cada rareza pinta el sprite entero de su color; el verde y el shiny usan su sprite normal
	if RECOLOR.has(v):
		var sh := Shader.new()
		sh.code = RECOLOR_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("tint", RECOLOR[v])
		mat.set_shader_parameter("shine", 1.0 if v == "gold" else 0.0)
		a.sprite.material = mat
	if v == "gold":
		mer.add_child(GoldSparks.new())


func depart() -> void:
	if active != null and is_instance_valid(active):
		m._ring(active.position, 6.0, 70.0, Color(String(VAR[variant]["col"])), 0.4, 3.0)
		active.queue_free()
	active = null
	close_ui()
	log.append(["depart", variant])


# ------------------------------------------------------------------ interfaz de la tienda
# v5.8: tienda segun el arte del puesto (assets/kecleon_shop): fondo y Kecleon pintados; cartas y botones los dibuja el juego.
const STAGE := Vector2(1280.0, 720.0)
const KIND_COL := {"dmg": "#e0434f", "def": "#3f8fe8", "heal": "#44b85a", "status": "#a05fe0", "gold": "#e8a820", "special": "#2fc0d8"}
const KIND := {"fortune": "gold", "sprout": "heal", "thornscarf": "def", "opener": "dmg", "canteen": "heal",
	"afterimage": "def", "ribbon": "def", "gustback": "def", "veil": "def", "tailwind": "def",
	"mystic": "status", "hexing": "status", "echo": "dmg", "binding": "status",
	"ember": "dmg", "berserk": "dmg", "shatter": "dmg", "executioner": "dmg", "drum": "dmg", "dragonfire": "dmg",
	"royal": "gold", "tmap": "gold", "seal": "gold", "dice": "gold", "crown": "gold",
	"chrono": "special", "infinity": "special", "mirror": "special", "starfall": "special"}


# Lo que sobra a los lados en pantallas que no son 16:9: madera y toldo, a juego con el arte.
class ShopBg extends Control:
	var col := Color.WHITE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#24150e"))
		var x := 0.0
		var i := 0
		while x < size.x:
			draw_rect(Rect2(x, 0.0, 74.0, 34.0), Color("#a82a35") if i % 2 == 0 else Color("#e8c060"))
			i += 1
			x += 74.0


# Adorno de la carta: esquinas y linea sobre el precio.
class CardDeco extends Control:
	var col := Color.WHITE

	func _draw() -> void:
		var c := Color(col.r, col.g, col.b, 0.55)
		for q in [Vector2(14, 14), Vector2(size.x - 14, 14)]:
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -6), q + Vector2(6, 0), q + Vector2(0, 6), q + Vector2(-6, 0)]), c)
		draw_line(Vector2(14, size.y - 106), Vector2(size.x - 14, size.y - 106), Color(col.r, col.g, col.b, 0.35), 2.0)


# Emblema de la carta: circulo del color de la categoria, icono del objeto y dos destellos dorados.
class CardIcon extends Control:
	var col := Color.WHITE
	var icon := ""

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		draw_circle(c, 62.0, Color(col.r, col.g, col.b, 0.14))
		draw_circle(c, 50.0, col.darkened(0.3))
		draw_circle(c, 40.0, col.darkened(0.1))
		draw_arc(c, 50.0, 0.0, TAU, 40, Color("#2a1020"), 4.0)
		for sx in [-72.0, 72.0]:
			var q: Vector2 = c + Vector2(sx, 0.0)
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -13), q + Vector2(4, -4), q + Vector2(13, 0), q + Vector2(4, 4), q + Vector2(0, 13), q + Vector2(-4, 4), q + Vector2(-13, 0), q + Vector2(-4, -4)]), Color("#ffd86a"))
		if icon != "":
			IC.draw_in(self, icon, c, 72.0)


# Iconos de los botones de abajo.
class BtnGlyph extends Control:
	var kind := "reroll"
	var col := Color.WHITE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		if kind == "reroll":
			draw_arc(c, 16.0, 0.3, 2.7, 16, col, 5.0)
			draw_arc(c, 16.0, 3.44, 5.84, 16, col, 5.0)
			var a := c + Vector2.from_angle(0.3) * 16.0
			var b := c + Vector2.from_angle(3.44) * 16.0
			draw_colored_polygon(PackedVector2Array([a + Vector2(-9, -2), a + Vector2(9, -2), a + Vector2(0, -12)]), col)
			draw_colored_polygon(PackedVector2Array([b + Vector2(-9, 2), b + Vector2(9, 2), b + Vector2(0, 12)]), col)
		else:
			draw_rect(Rect2(c + Vector2(-16, -18), Vector2(20, 36)), col, false, 4.0)
			draw_line(c + Vector2(-4, 0), c + Vector2(14, 0), col, 5.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(12, -9), c + Vector2(24, 0), c + Vector2(12, 9)]), col)


func open_ui() -> void:
	if ui != null or active == null:
		return
	m.shop_open = true
	var layer := CanvasLayer.new()
	layer.layer = 70
	m.add_child(layer)
	ui = layer
	var col := Color(String(VAR[variant]["col"]))
	var bg := ShopBg.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var kth := Theme.new()
	kth.default_font_size = 20
	load("res://scripts/pxfont.gd").apply(kth)   # misma fuente pixelada que el resto del juego
	var st := Control.new()
	st.size = STAGE
	st.theme = kth
	layer.add_child(st)
	# El escenario se centra y encoge si la vista es mas pequena que el arte
	var fit := func():
		var vs: Vector2 = st.get_viewport_rect().size
		var k: float = minf(1.0, minf(vs.x / STAGE.x, vs.y / STAGE.y))
		st.scale = Vector2(k, k)
		st.position = (vs - STAGE * k) * 0.5
	bg.resized.connect(fit)
	fit.call()
	var art := TextureRect.new()
	art.texture = load("res://assets/kecleon_shop/bg.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.size = STAGE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	st.add_child(art)
	_build_keeper(st)
	_build_bubble(st, col)
	_build_coins(st)
	ui_btns = []
	ui_cards = []
	for i in range(3):
		_build_card(st, i)
	ui_owned = Label.new()
	ui_owned.position = Vector2(20.0, 640.0)
	ui_owned.size = Vector2(350.0, 70.0)
	ui_owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_owned.add_theme_font_size_override("font_size", 16)
	ui_owned.add_theme_color_override("font_color", Color("#fff2d0"))
	ui_owned.add_theme_constant_override("outline_size", 5)
	ui_owned.add_theme_color_override("font_outline_color", Color("#1a0f08"))
	st.add_child(ui_owned)
	ui_reroll = Button.new()
	ui_reroll.position = Vector2(390.0, 611.0)
	ui_reroll.size = Vector2(469.0, 69.0)
	ui_reroll.add_theme_font_size_override("font_size", 22)
	_style_btn(ui_reroll, true)
	ui_reroll.pressed.connect(_on_reroll)
	st.add_child(ui_reroll)
	_add_glyph(ui_reroll, "reroll", Color("#3d2a00"))
	var close := Button.new()
	close.text = m.L.t("Salir de la tienda")
	close.position = Vector2(879.0, 611.0)
	close.size = Vector2(352.0, 69.0)
	close.add_theme_font_size_override("font_size", 24)
	_style_btn(close, false)
	close.pressed.connect(close_ui)
	st.add_child(close)
	_add_glyph(close, "leave", Color.WHITE)
	ui_close = close
	_refresh_ui()
	_focus_first()


# El Kecleon va pintado en el fondo (verde); las demas variantes tinen encima solo su piel.
func _build_keeper(st: Control) -> void:
	if variant == "green":
		return
	var skin := TextureRect.new()
	skin.texture = load("res://assets/kecleon_shop/keeper.png")
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.size = STAGE
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skin.modulate = Color(String(VAR[variant]["col"]))
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(skin)


func _add_glyph(b: Button, kind: String, col: Color) -> void:
	var g := BtnGlyph.new()
	g.kind = kind
	g.col = col
	g.position = Vector2(26.0, 14.0)
	g.size = Vector2(40.0, 40.0)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)


func _build_bubble(st: Control, col: Color) -> void:
	var pn := Panel.new()
	pn.position = Vector2(390.0, 44.0)
	pn.size = Vector2(690.0, 96.0)
	pn.add_theme_stylebox_override("panel", _sbx(Color("#101a30"), Color("#f4f8ff"), 3))
	st.add_child(pn)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(0, 66), Vector2(-26, 96), Vector2(0, 84)])
	tail.color = Color("#f4f8ff")
	pn.add_child(tail)
	var tag := Label.new()
	tag.text = m.L.t(String(VAR[variant]["name"]))
	tag.position = Vector2(406.0, 22.0)
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", col)
	tag.add_theme_constant_override("outline_size", 6)
	tag.add_theme_color_override("font_outline_color", Color("#101a30"))
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color("#101a30")
	tsb.border_color = col
	tsb.set_border_width_all(2)
	tsb.set_corner_radius_all(6)
	tsb.corner_detail = 2
	tsb.content_margin_left = 12
	tsb.content_margin_right = 12
	tag.add_theme_stylebox_override("normal", tsb)
	st.add_child(tag)
	ui_info = Label.new()
	ui_info.position = Vector2(16.0, 14.0)
	ui_info.size = Vector2(658.0, 76.0)
	ui_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_info.add_theme_font_size_override("font_size", 20)
	pn.add_child(ui_info)


func _build_coins(st: Control) -> void:
	var pn := Panel.new()
	pn.position = Vector2(1096.0, 44.0)
	pn.size = Vector2(150.0, 56.0)
	pn.add_theme_stylebox_override("panel", _sbx(Color("#101a30"), Color("#e8c060"), 3))
	st.add_child(pn)
	var ic := IC.rect("coin", 30)
	ic.position = Vector2(10.0, 13.0)
	pn.add_child(ic)
	ui_coins = Label.new()
	ui_coins.position = Vector2(44.0, 0.0)
	ui_coins.size = Vector2(98.0, 56.0)
	ui_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_coins.add_theme_font_size_override("font_size", 24)
	pn.add_child(ui_coins)


func _build_card(st: Control, i: int) -> void:
	var b := Button.new()
	b.position = Vector2(390.0 + float(i) * 288.0, 157.0)
	b.size = Vector2(276.0, 440.0)
	b.pressed.connect(_on_buy.bind(i))
	st.add_child(b)
	ui_btns.append(b)
	var deco := CardDeco.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(deco)
	var cv := VBoxContainer.new()
	cv.position = Vector2(12.0, 8.0)
	cv.size = Vector2(252.0, 424.0)
	cv.add_theme_constant_override("separation", 6)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cv)
	var icon := CardIcon.new()
	icon.custom_minimum_size = Vector2(0.0, 124.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(icon)
	var lname := _card_label(22, Color.WHITE)
	lname.custom_minimum_size = Vector2(0.0, 50.0)
	lname.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cv.add_child(lname)
	var ldesc := _card_label(18, Color.WHITE)
	ldesc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ldesc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cv.add_child(ldesc)
	var lcopies := _card_label(15, Color("#c8d6ee"))
	cv.add_child(lcopies)
	var pr := HBoxContainer.new()
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_theme_constant_override("separation", 8)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := IC.rect("coin", 26)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pr.add_child(pic)
	var lprice := Label.new()
	lprice.add_theme_font_size_override("font_size", 26)
	pr.add_child(lprice)
	cv.add_child(pr)
	var lbuy := _card_label(22, Color.WHITE)
	lbuy.custom_minimum_size = Vector2(0.0, 48.0)
	lbuy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cv.add_child(lbuy)
	ui_cards.append({"box": cv, "deco": deco, "icon": icon, "name": lname, "desc": ldesc, "copies": lcopies, "price": lprice, "buy": lbuy})


func _style_card(b: Button, c: Color) -> void:
	b.add_theme_stylebox_override("normal", _sbx(Color("#101a30"), c, 4))
	b.add_theme_stylebox_override("hover", _sbx(c.darkened(0.62), c.lightened(0.25), 5))
	b.add_theme_stylebox_override("pressed", _sbx(c.darkened(0.72), c, 5))
	b.add_theme_stylebox_override("focus", _sbx(c.darkened(0.62), Color("#ffc23f"), 6))
	b.add_theme_stylebox_override("disabled", _sbx(Color("#141a28"), c.darkened(0.55), 4))


# El primer objeto que se pueda pagar; si no hay ninguno, Salir (el mando no se queda sin foco).
func _focus_first() -> void:
	for b in ui_btns:
		if (b as Button).visible and not (b as Button).disabled:
			(b as Button).grab_focus()
			return
	if ui_close != null:
		ui_close.grab_focus()


func _band(l: Label, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(6)
	sb.corner_detail = 2
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	l.add_theme_stylebox_override("normal", sb)


func _card_label(sz: int, col: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _refresh_ui() -> void:
	if ui == null:
		return
	ui_coins.text = str(m.coins)
	for i in range(3):
		var b: Button = ui_btns[i]
		if i < offers.size():
			var id: String = String(offers[i])
			var it: Array = ITEMS[id]
			var p: int = price(id)
			var c := Color(String(KIND_COL[KIND[id]]))
			var ls: Dictionary = ui_cards[i]
			b.visible = true
			_style_card(b, c)
			ls["deco"].col = c
			ls["deco"].queue_redraw()
			ls["icon"].col = c
			ls["icon"].icon = "kec:" + id
			ls["icon"].queue_redraw()
			ls["name"].text = m.L.t(String(it[0]))
			_band(ls["name"], c.darkened(0.25))
			ls["desc"].text = m.L.t(String(it[3]))
			ls["copies"].text = m.L.t("Copias: %d de %d") % [n(id), int(it[2])] if int(it[2]) > 1 else ""
			ls["price"].text = str(p)
			b.disabled = bought or m.coins < p
			ls["box"].modulate = Color(0.65, 0.65, 0.7) if b.disabled else Color.WHITE
			_band(ls["buy"], Color("#3a4560") if b.disabled else c)
			if bought:
				ls["buy"].text = ""
			elif m.coins < p:
				ls["buy"].text = m.L.t("Te faltan %d") % (p - m.coins)
			else:
				ls["buy"].text = m.L.t("Comprar")
		else:
			b.visible = false
	var have: Array = []
	for id in kc:
		if n(String(id)) > 0:
			have.append(m.L.t(String(ITEMS[id][0])) + (" x%d" % n(String(id)) if n(String(id)) > 1 else ""))
	ui_owned.text = (m.L.t("Ya tienes: ") + ", ".join(have)) if not have.is_empty() else ""
	ui_reroll.text = m.L.t("Cambiar ofertas (%d monedas)") % reroll_price()
	ui_reroll.disabled = bought or not can_reroll() or m.coins < reroll_price()
	if bought:
		ui_info.text = m.L.t("¡Gracias por tu compra!")
	elif rerolled:
		ui_info.text = m.L.t("¡Ofertas nuevas! Puedes seguir cambiándolas mientras tengas monedas. Al comprar, me marcho.")
	else:
		ui_info.text = m.L.t("¡Echa un vistazo! Puedes comprar una mejora permanente para esta partida y cambiar las ofertas mientras tengas monedas. Al comprar, me marcho.")


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
	_focus_first()


static func _sbx(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(8)
	s.corner_detail = 2   # esquinas escalonadas, como pixel art
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color("#0b1838")
	s.shadow_size = 0
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
