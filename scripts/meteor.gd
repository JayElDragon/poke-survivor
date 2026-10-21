extends RefCounted
# S57.3: evento del meteorito. Con probabilidad RUN_CHANCE (por partida) cae un meteorito cada cierto tiempo: aviso en el suelo,
# meteoro que cae (sprites de la hoja de Deoxys), impacto, banner grande "A meteorite has fallen... will you check it out?" y un
# crater con el meteorito. Al acercarte a revisarlo se abre: botin bueno (monedas, bolsas, cristales, objeto) y, con DEOXYS_CHANCE
# (una sola tirada por evento), Deoxys emerge en UNA de sus 4 formas al azar (no cambia durante el combate); cada forma mejora sus
# stats y tiene ataques propios (no copian a ningun jefe).
# Sprites del evento: assets/world/meteor/*.png. Deoxys usa SOLO el sprite 386 del proyecto (solo existe la forma normal): las otras
# formas cambian de color/tamano/velocidad.

const CVI = preload("res://scripts/cave_int.gd")
const RUN_CHANCE := 0.10      # probabilidad de que una partida NORMAL tenga el evento de meteorito (10%); otros modos y retos: nunca
const FIRST_MIN := 420.0
const FIRST_MAX := 720.0
const GAP_MIN := 480.0
const GAP_MAX := 720.0
const WARN := 4.0
const R := 110.0
const OPEN_R := 80.0
const CRATER_LIFE := 60.0
const DEOXYS := 386
const DEOXYS_CHANCE := 0.75   # por meteorito dentro de una partida con evento (en total ~10-15% de las partidas normales)
const DEOXYS_TTL := 140.0
const FORMS := [
	{"id": "normal", "name": "Forma Normal", "tint": Color(1, 1, 1), "scale": 1.0, "spd": 82.0, "hp": 1.0, "dmg": 1.0, "col": Color("#ff6bd6")},
	{"id": "attack", "name": "Forma Ataque", "tint": Color(1.35, 0.7, 0.7), "scale": 1.05, "spd": 104.0, "hp": 0.8, "dmg": 1.5, "col": Color("#ff5d5d")},
	{"id": "defense", "name": "Forma Defensa", "tint": Color(0.7, 0.9, 1.35), "scale": 1.25, "spd": 62.0, "hp": 1.5, "dmg": 0.9, "col": Color("#5db8ff")},
	{"id": "speed", "name": "Forma Velocidad", "tint": Color(1.35, 1.3, 0.65), "scale": 0.95, "spd": 130.0, "hp": 0.9, "dmg": 1.0, "col": Color("#ffe14d")},
]

var m = null
var poi = null
var t_next := -1.0
var enabled := false
var rolled := false
var zone = null
var zpos := Vector2.ZERO
var fall = null
var crater = null
var deo = null           # {"enemy", "ttl", "id", "done", "form", "acts", "atk_t", "alt", "tele"}
var next_id := 1
var done := {}
var log: Array = []
var _ui: CanvasLayer = null
var _ui_banner: TextureRect = null
var _ui_card: TextureRect = null
var _ui_t := 0.0
var _card_t := 0.0


static func tex(n: String) -> Texture2D:
	return _tex(n)


static var _cache := {}


static func _tex(n: String) -> Texture2D:
	if _cache.has(n):
		return _cache[n]
	var p := "res://assets/world/meteor/%s.png" % n
	var tx: Texture2D = null
	if ResourceLoader.exists(p):
		tx = load(p)
	else:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null and not img.is_empty():
			tx = ImageTexture.create_from_image(img)
	_cache[n] = tx
	return tx


# ---------- nodos de dibujo ----------
class Fall extends Node2D:
	var t := 0.0
	var dur := 0.9
	var target := Vector2.ZERO
	var from := Vector2.ZERO
	func _process(delta: float) -> void:
		t += delta
		var k: float = clampf(t / dur, 0.0, 1.0)
		position = from.lerp(target, k * k)
		queue_redraw()
	func _draw() -> void:
		var tx: Texture2D = CVI.tex_in("meteor", "fall_b")
		if tx == null:
			draw_circle(Vector2.ZERO, 14.0, Color("#ff9a3d"))
			return
		var sz: Vector2 = tx.get_size() * 0.8
		draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.32, -sz.y * 0.86), sz), false)


class Boom extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.9:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var tx: Texture2D = CVI.tex_in("meteor", "boom_b" if t < 0.45 else "boom_a")
		if tx == null:
			return
		var a: float = clampf(1.0 - t / 0.9, 0.0, 1.0)
		var sc: float = 0.7 + 0.25 * clampf(t / 0.4, 0.0, 1.0)
		var sz: Vector2 = tx.get_size() * sc
		draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.5, -sz.y * 0.78), sz), false, Color(1, 1, 1, a))


class Crater extends Node2D:
	var state := "meteor"     # meteor -> open
	var t := 0.0
	var life := 60.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var a: float = 1.0 if life > 4.0 else maxf(0.0, life / 4.0)
		var tx: Texture2D = CVI.tex_in("meteor", "crater1" if state == "meteor" else "crater2")
		if state == "meteor":
			var f: float = 0.5 + 0.5 * sin(t * 4.0)
			draw_circle(Vector2(0, -6), 70.0 + 6.0 * f, Color(1.0, 0.4, 0.9, 0.10 * a))
			draw_arc(Vector2(0, -6), 64.0 + 4.0 * f, 0.0, TAU, 40, Color(1.0, 0.5, 0.95, 0.45 * a), 3.0)
		if tx != null:
			var sz: Vector2 = tx.get_size() * 0.62
			draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.5, -sz.y * 0.55), sz), false, Color(1, 1, 1, a))


# ---------- ciclo del evento ----------
func _ok() -> bool:
	return m.mode == "normal" and not poi._busy() and not m.shop_open and m.run_time >= FIRST_MIN \
		and (poi.supply == null or not is_instance_valid(poi.supply)) and m.cave.cur == null and not m.inv.active() \
		and m.alpha.cur == null and m.rescue.cur == null and m.mew.cur == null and deo == null and m.arena == null


func _roll_run() -> void:
	rolled = true
	enabled = randf() < RUN_CHANCE
	t_next = randf_range(FIRST_MIN, FIRST_MAX)
	log.append(["roll", enabled])


func update(delta: float) -> void:
	_ui_tick(delta)
	if deo != null:
		_deo_tick(delta)
	if crater != null:
		_crater_tick(delta)
	if zone != null:
		if not is_instance_valid(zone):
			zone = null
			if fall != null and is_instance_valid(fall):
				fall.queue_free()
			fall = null
		else:
			if fall == null and zone.t >= zone.warn - 0.9:
				_start_fall()
			if zone.t >= zone.warn:
				_impact()
		return
	if not rolled:
		_roll_run()
	if not enabled:
		return
	t_next -= delta
	if t_next > 0.0:
		return
	if not _ok():
		t_next = 15.0
		return
	t_next = randf_range(GAP_MIN, GAP_MAX)
	_warn()


func force_event() -> bool:
	rolled = true
	enabled = true
	return _warn()


func _warn() -> bool:
	if zone != null or crater != null:
		return false
	var HZ = load("res://scripts/hazard.gd")
	for i in range(8):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(230.0, 420.0)
		if not m._blocked(c, 30.0):
			zpos = c
			var z = HZ.Zone.new()
			z.kind = "meteor"
			z.col = Color("#ff9a3d")
			z.warn = WARN
			z.r = R
			z.position = c
			z.z_index = -1
			m.world.add_child(z)
			zone = z
			m._say(m.L.t("¡Un meteorito se aproxima! Aléjate de la zona marcada."), 3.0)
			m.Aud.sfx("rift")
			log.append(["warn"])
			return true
	return false


func _start_fall() -> void:
	var f := Fall.new()
	f.target = zpos
	f.from = zpos + Vector2(380.0, -560.0)
	f.position = f.from
	f.z_index = 20
	m.world.add_child(f)
	fall = f


func _impact() -> void:
	var pos: Vector2 = zpos
	zone.queue_free()
	zone = null
	if fall != null and is_instance_valid(fall):
		fall.queue_free()
	fall = null
	var id: int = next_id
	next_id += 1
	m._ring(pos, 8.0, R * 1.4, Color("#ff9a3d"), 0.6, 6.0)
	m.pfx.burst(pos + Vector2(0, -10), Color("#ff9a3d"), 40, 260.0)
	m.pfx.burst(pos + Vector2(0, -10), Color("#ff6bd6"), 24, 180.0)
	m.shake = maxf(m.shake, 12.0)
	m.Aud.sfx("bossDown")
	var bm := Boom.new()
	bm.position = pos
	bm.z_index = 15
	m.world.add_child(bm)
	if not m.player.dead and m.player.position.distance_to(pos) < R:
		m.player.invuln = 0.0
		m._hurt_player(maxf(8.0, m.player.max_hp * 0.10), "")
	for e in m.enemies.duplicate():
		if is_instance_valid(e) and not e.dead and not e.boss and e.position.distance_to(pos) < R:
			m._damage_enemy(e, 120.0 + m.run_time * 0.1, Color("#ff9a3d"), (e.position - pos).normalized(), 200.0)
	# el meteorito queda en un crater, esperando a que lo revises
	var cr := Crater.new()
	cr.position = pos
	cr.life = CRATER_LIFE
	cr.z_index = -1
	m.world.add_child(cr)
	crater = {"node": cr, "id": id, "pos": pos, "open": false}
	_show_banner()
	log.append(["impact", id])


func _crater_tick(delta: float) -> void:
	var cr = crater["node"]
	if not is_instance_valid(cr):
		crater = null
		return
	cr.life -= delta
	if cr.life <= 0.0:
		cr.queue_free()
		crater = null
		log.append(["crater_gone"])
		return
	if not bool(crater["open"]) and not m.player.dead and m.player.position.distance_to(crater["pos"]) < OPEN_R:
		_open_crater()


func _open_crater() -> void:
	crater["open"] = true
	var cr = crater["node"]
	var pos: Vector2 = crater["pos"]
	var id: int = int(crater["id"])
	cr.state = "open"
	cr.life = minf(cr.life, 14.0)
	m.pfx.burst(pos + Vector2(0, -16), Color("#ffe27a"), 36, 220.0)
	m.pfx.burst(pos + Vector2(0, -16), Color("#c88bff"), 24, 160.0)
	m._ring(pos, 6.0, 120.0, Color("#c88bff"), 0.6, 4.0)
	m.Aud.sfx("shinyGet")
	# botin bueno: monedas, experiencia, y a veces objeto / boleto
	for i in range(14):
		m._spawn_orb(pos, "coin", 5.0)
	for i in range(3):
		m._spawn_orb(pos, "xpBig", ceilf(float(m._xp_for(m.player.level)) * 0.06))
	if randf() < 0.5:
		m._spawn_orb(pos + Vector2(10, 0), "item", 0.0)
	if randf() < 0.25:
		m._spawn_orb(pos + Vector2(-10, 0), "ticket", 1.0)
	m._say(m.L.t("¡El meteorito se abre! Botín de otro mundo."), 2.6)
	log.append(["open", id])
	# UNA sola tirada de Deoxys por evento
	if not done.has(id):
		done[id] = true
		if randf() < DEOXYS_CHANCE:
			_spawn_deoxys(pos, id)


func force_deoxys(pos: Vector2) -> void:
	_spawn_deoxys(pos, next_id)
	next_id += 1


# ---------- Deoxys ----------
func _spawn_deoxys(pos: Vector2, id: int) -> void:
	if deo != null or not m._dex_by.has(DEOXYS) or not m._smeta.has(str(DEOXYS)):
		return
	var p: Dictionary = m._dex_by[DEOXYS]
	var def := {"at": 0.0, "dex": DEOXYS, "name": String(p["name"]), "hp": 4200.0, "spd": 82.0, "dmg": 30.0, "xp": 1800.0,
		"behavior": "ranged", "shotDmg": 20.0, "shotCd": 1.5, "range": 280.0}
	m._preload_dex(DEOXYS)
	var e = m._spawn_boss(def)
	e.position = pos + Vector2(0, -20)
	e.set_meta("enc", "deoxys")
	e.set_meta("base_scale", e.sprite.scale)
	e.set_meta("base_h", e.body_h)
	deo = {"enemy": e, "ttl": DEOXYS_TTL, "id": id, "done": false, "form": -1, "acts": [], "atk_t": 2.4, "alt": 0, "hidden": 0.0}
	var fi: int = randi() % 4
	_set_form(fi)
	var f: Dictionary = FORMS[fi]
	e.max_hp = roundf(e.max_hp * float(f["hp"]))
	e.hp = e.max_hp
	e.dmg *= float(f["dmg"])
	m._say(m.L.t("¡Deoxys emerge del meteorito!") + " " + m.L.t(String(f["name"])), 3.6)
	log.append(["deoxys", id, String(f["id"])])


func _form() -> Dictionary:
	return FORMS[clampi(int(deo["form"]), 0, 3)]


func _set_form(i: int) -> void:
	var e = deo["enemy"]
	deo["form"] = i
	deo["acts"] = []
	deo["alt"] = 0
	deo["atk_t"] = 1.8
	var f: Dictionary = FORMS[i]
	var bs: Vector2 = e.get_meta("base_scale")
	e.sprite.scale = bs * float(f["scale"])
	e.body_h = float(e.get_meta("base_h")) * float(f["scale"])
	e.modulate = f["tint"]
	e.spd = float(f["spd"])
	if i == 2:
		e.shield = 650.0
	m._ring(e.position, 10.0, 130.0, f["col"], 0.7, 6.0)
	m.pfx.burst(e.position + Vector2(0, -20), f["col"], 30, 220.0)
	m.Aud.sfx("legend")
	m.shake = maxf(m.shake, 6.0)
	log.append(["form", String(f["id"])])


func _deo_tick(delta: float) -> void:
	var e = deo["enemy"]
	if bool(deo["done"]):
		deo = null
		return
	if not is_instance_valid(e) or e.dead:
		return        # la muerte la gestiona on_deoxys_down desde _drop
	deo["ttl"] = float(deo["ttl"]) - delta
	if float(deo["ttl"]) <= 0.0 or m.player.dead:
		m.enemies.erase(e)
		e.queue_free()
		m._say(m.L.t("¡Deoxys escapó!"), 2.6)
		log.append(["escaped"])
		deo = null
		return
	# aparicion tras un teletransporte
	if float(deo["hidden"]) > 0.0:
		deo["hidden"] = float(deo["hidden"]) - delta
		e.modulate.a = 0.0 if float(deo["hidden"]) > 0.15 else 0.6
		if float(deo["hidden"]) <= 0.0:
			e.modulate.a = 1.0
	# acciones programadas (secuencias de ataque)
	var acts: Array = deo["acts"]
	for i in range(acts.size() - 1, -1, -1):
		acts[i]["t"] = float(acts[i]["t"]) - delta
		if float(acts[i]["t"]) <= 0.0:
			var f: Callable = acts[i]["f"]
			acts.remove_at(i)
			if is_instance_valid(e) and not e.dead:
				f.call()
	deo["atk_t"] = float(deo["atk_t"]) - delta
	if float(deo["atk_t"]) <= 0.0 and acts.is_empty():
		_attack(e)


func _later(t: float, f: Callable) -> void:
	(deo["acts"] as Array).append({"t": t, "f": f})


func _dk() -> float:
	return 1.0 + m.run_time / 900.0


func _attack(e) -> void:
	var form: String = String(_form()["id"])
	var alt: int = int(deo["alt"])
	deo["alt"] = 1 - alt
	var pc: Color = _form()["col"]
	var d: float = float(e.dmg) * _dk()
	var pp: Vector2 = m.player.position
	match form:
		"normal":
			if alt == 0:
				# Psicoimpulso: tres rayos en abanico hacia el jugador
				var base: float = (pp - e.position).angle()
				for k in [-0.38, 0.0, 0.38]:
					m._hazard_beam(e.position, base + float(k), 540.0, 44.0, 1.1, d * 1.2, "psychic", pc)
				m._say(m.L.t("¡Psicoimpulso!"), 1.2)
				deo["atk_t"] = 3.4
			else:
				# Teletransporte: desaparece y cae con un pulso sobre ti
				_teleport_pulse(e, 110.0, d, pc)
				deo["atk_t"] = 3.0
		"attack":
			if alt == 0:
				# Tajo Zen en X sobre el jugador
				var a0: float = randf() * PI
				for k in [0.0, PI * 0.5]:
					var dir := Vector2.from_angle(a0 + float(k))
					m._hazard_beam(pp - dir * 320.0, a0 + float(k), 640.0, 40.0, 0.95, d * 1.5, "psychic", pc)
				m._say(m.L.t("¡Tajo Zen!"), 1.2)
				deo["atk_t"] = 3.0
			else:
				# Embestida triple: avisa la linea y se lanza por ella
				for n in range(3):
					_later(0.9 * n, func():
						var tgt: Vector2 = m.player.position
						var ang: float = (tgt - e.position).angle()
						var ln: float = minf(e.position.distance_to(tgt) + 120.0, 520.0)
						m._hazard_beam(e.position, ang, ln, 46.0, 0.55, d * 1.3, "psychic", pc)
						var dest: Vector2 = m._free_spot(e.position + Vector2.from_angle(ang) * ln, 14.0)
						_later(0.55, func(): _dash_to(e, dest)))
				deo["atk_t"] = 4.6
		"defense":
			if alt == 0:
				# Barrera Cosmica: anillo de explosiones alrededor y escudo renovado
				for k in range(10):
					var a: float = TAU * float(k) / 10.0
					m._hazard_zone(e.position + Vector2.from_angle(a) * 150.0, 52.0, 1.0 + 0.04 * k, d * 1.1, "psychic", pc)
				m._hazard_zone(e.position, 70.0, 1.0, d * 1.1, "psychic", pc)
				e.shield = maxf(e.shield, 450.0)
				m._say(m.L.t("¡Barrera Cósmica!"), 1.2)
				deo["atk_t"] = 3.6
			else:
				# Pulso gravitatorio: zona enorme que frena
				var hz = m._hazard_zone(pp, 175.0, 1.3, d, "psychic", pc)
				hz.slows = true
				hz.pct = 0.4
				deo["atk_t"] = 3.4
		"speed":
			if alt == 0:
				# Imagenes residuales: rastro de minas psiquicas hacia el jugador y salto
				var dirv: Vector2 = (pp - e.position)
				var dist: float = minf(dirv.length(), 420.0)
				var dn: Vector2 = dirv.normalized() if dirv.length() > 1.0 else Vector2.RIGHT
				for k in range(6):
					m._hazard_zone(e.position + dn * dist * float(k + 1) / 6.0, 54.0, 0.8 + 0.16 * k, d, "psychic", pc)
				_dash_to(e, m._free_spot(e.position + dn * dist, 14.0))
				deo["atk_t"] = 2.8
			else:
				# Parpadeo relampago: tres saltos con pulsos
				for n in range(3):
					_later(0.6 * n, func(): _teleport_pulse(e, 80.0, d, pc, 0.55))
				deo["atk_t"] = 3.4


func _dash_to(e, dest: Vector2) -> void:
	if not is_instance_valid(e) or e.dead:
		return
	var tw: Tween = e.create_tween()
	tw.tween_property(e, "position", dest, 0.22)


func _teleport_pulse(e, r: float, d: float, pc: Color, delay: float = 0.8) -> void:
	if not is_instance_valid(e) or e.dead:
		return
	m.pfx.burst(e.position + Vector2(0, -20), pc, 18, 160.0)
	var np: Vector2 = m._free_spot(m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(120.0, 190.0), 14.0)
	e.position = np
	deo["hidden"] = 0.45
	m._hazard_zone(np, r, delay, d, "psychic", pc)
	m._ring(np, 6.0, r * 1.2, pc, 0.5, 4.0)


# La llama main._drop() al morir el enemigo marcado "deoxys". Un solo premio por encuentro.
func on_deoxys_down(e) -> void:
	if deo == null or deo["enemy"] != e or bool(deo["done"]):
		return
	deo["done"] = true
	var pos: Vector2 = e.position
	m._spawn_orb(pos, "ticket", 3.0)
	m._spawn_orb(pos + Vector2(14, 0), "item", 0.0)
	m._spawn_orb(pos + Vector2(-14, 0), "item", 0.0)
	for i in range(30):
		m._spawn_orb(pos, "coin", 5.0)
	m._say(m.L.t("¡Deoxys derrotado! Premio especial."), 3.4)
	var st: Dictionary = m.SV.d["stats"]
	st["deoxysKills"] = int(st.get("deoxysKills", 0)) + 1
	log.append(["deoxys_win"])
	if m.has_method("ach_event"):
		m.ach_event("deoxys", {})


func mark() -> Variant:
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	if deo != null:
		var e = deo["enemy"]
		if is_instance_valid(e) and not e.dead:
			return {"sp": ct * (e.position + Vector2(0, -70)), "txt": "Deoxys  %ds" % ceili(float(deo["ttl"])), "col": Color("#ff6b6b")}
	if crater != null and is_instance_valid(crater["node"]) and not bool(crater["open"]):
		return {"sp": ct * ((crater["pos"] as Vector2) + Vector2(0, -60)), "txt": m.L.t("Meteorito") + "  %ds" % ceili(float(crater["node"].life)), "col": Color("#ff9a3d")}
	return null


# ---------- banner y tarjetas (capa de interfaz) ----------
func _ensure_ui() -> void:
	if _ui != null and is_instance_valid(_ui):
		return
	_ui = CanvasLayer.new()
	_ui.layer = 70
	m.add_child(_ui)
	_ui_banner = TextureRect.new()
	_ui_banner.texture = _tex("banner")
	_ui_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ui_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ui_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_banner.modulate.a = 0.0
	_ui.add_child(_ui_banner)
	_ui_card = TextureRect.new()
	_ui_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ui_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ui_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_card.modulate.a = 0.0
	_ui.add_child(_ui_card)


func _show_banner() -> void:
	_ensure_ui()
	_ui_t = 4.2


func _show_card(name: String) -> void:
	_ensure_ui()
	_ui_card.texture = _tex(name)
	_card_t = 3.0


func _ui_tick(delta: float) -> void:
	if _ui == null or not is_instance_valid(_ui):
		return
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	if _ui_t > 0.0:
		_ui_t -= delta
	var a: float = clampf(minf((4.2 - _ui_t) / 0.35, _ui_t / 0.6), 0.0, 1.0) if _ui_t > 0.0 else 0.0
	var bw: float = minf(vp.x * 0.86, 780.0)
	var bh: float = bw * 228.0 / 785.0
	_ui_banner.size = Vector2(bw, bh)
	_ui_banner.position = Vector2((vp.x - bw) * 0.5, vp.y * 0.12 + (1.0 - a) * -24.0)
	_ui_banner.modulate.a = a
	if _card_t > 0.0:
		_card_t -= delta
	var ca: float = clampf(minf((3.0 - _card_t) / 0.3, _card_t / 0.5), 0.0, 1.0) if _card_t > 0.0 else 0.0
	var ch: float = minf(vp.y * 0.34, 250.0)
	_ui_card.size = Vector2(ch * 1.1, ch)
	_ui_card.position = Vector2((vp.x - ch * 1.1) * 0.5, vp.y * 0.10)
	_ui_card.modulate.a = ca
