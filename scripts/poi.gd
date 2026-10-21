extends RefCounted
# S57: director unico de puntos de interes (POI): objetos perdidos, mochilas, cofres de pago/trampa y cajas de suministro.
# Reutiliza los sistemas de main.gd (orbes, monedas, tickets, objetos). Estado local de la partida: se pierde al terminar.

const SC := 0.6   # los sprites POI son pixel art nativo guardado a x4: 0.6 => 2,4 px de pantalla por px (igual que el resto del mundo)
const CAP_PICK := 8
const CAP_PACK := 2
const SPACING := 110.0
const PAID_STEPS := [20, 35, 55, 80, 110]
const SUPPLY_CLAIM := 30.0
const SUPPLY_TYPES := {
	"medical": {"name": "Suministro médico", "col": "#ff6b81", "enemies": 0},
	"resource": {"name": "Suministro de recursos", "col": "#6bd66b", "enemies": 0},
	"rare": {"name": "Suministro raro", "col": "#5ab0ff", "enemies": 7},
	"golden": {"name": "Suministro excepcional", "col": "#ffd23f", "enemies": 11},
}

static var paid_tier := 0
static var _tc := {}
var m = null
var items: Array = []
var pick_t := 12.0
var pack_t := 60.0
var sup_t := 150.0
var next_id := 1
var paid_n := 0
var supply = null
var log: Array = []     # eventos para pruebas
var claimed := {}       # id -> true (un solo cobro por instancia)
var _act := false


static func tex(n: String) -> Texture2D:
	if not _tc.has(n):
		var pth: String = "res://assets/world/poi_%s.png" % n
		_tc[n] = load(pth) if ResourceLoader.exists(pth) else null
	return _tc[n]


# Dibuja un sprite POI con los pies en el origen; el archivo esta al doble de resolucion (escala 0.5).
static func draw_tex(ci: CanvasItem, n: String, k: float = 0.6, lift: float = 0.0, a: float = 1.0) -> bool:
	var t: Texture2D = tex(n)
	if t == null:
		return false
	var sz: Vector2 = Vector2(t.get_width(), t.get_height()) * k
	ci.draw_texture_rect(t, Rect2(Vector2(-sz.x * 0.5, -sz.y - lift), sz), false, Color(1, 1, 1, a))
	return true


class Item extends Node2D:
	var kind := "pouch"
	var sub := ""
	var uid := 0
	var ttl := 40.0
	var t := 0.0
	var done := false
	var tagged: Array = []
	var frames: Array = []
	func _process(delta: float) -> void:
		t += delta
		if kind == "fxopen" or kind == "fxanim":
			ttl -= delta
		queue_redraw()
	func _draw() -> void:
		var f: Font = ThemeDB.fallback_font
		var bob: float = sin(t * 3.0) * 2.0
		var P = load("res://scripts/poi.gd")
		if kind == "fxanim":
			var fi: int = clampi(int((0.4 - ttl) / 0.4 * frames.size()), 0, frames.size() - 1)
			P.draw_tex(self, String(frames[fi]), 0.6, (0.4 - ttl) * 40.0, clampf(ttl / 0.12, 0.0, 1.0))
			return
		if kind == "fxopen":
			var al: float = clampf(ttl / 0.9, 0.0, 1.0)
			P.draw_tex(self, sub, 0.6, (1.0 - al) * 26.0, al)
			return
		draw_circle(Vector2(0, 2), 10.0 if kind != "crate" else 16.0, Color(0, 0, 0, 0.28))
		var tn := ""
		match kind:
			"pouch": tn = "pouch"
			"xp": tn = "xp"
			"potion": tn = "potion"
			"pack": tn = "packr" if sub == "rare" else "pack"
			"crate": tn = {"medical": "sup_med", "resource": "sup_res", "rare": "sup_rare", "golden": "sup_gold"}[sub]
		if tn != "" and P.tex(tn) != null:
			var kk: float = 0.6
			if kind == "crate":
				var col0: Color = Color.html(String(SUPPLY_TYPES[sub]["col"]))
				draw_arc(Vector2(0, -22), 30.0 + 3.0 * sin(t * 5.0), 0, TAU, 32, Color(col0.r, col0.g, col0.b, 0.5), 3.0)
				draw_arc(Vector2(0, -22), 38.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(ttl / 30.0, 0.0, 1.0), 32, Color.WHITE, 3.0)
			P.draw_tex(self, tn, kk, 4.0 + bob if kind != "crate" else 2.0)
			if kind == "pack":
				P.draw_tex(self, "i_qr" if sub == "rare" else "i_q", 0.6, 62.0 + bob * 2.0)
			elif kind == "crate":
				P.draw_tex(self, "i_ex" if (sub == "medical" or sub == "resource") else "i_exr", 0.6, 66.0 + bob * 2.0)
			return
		match kind:
			"pouch":
				draw_circle(Vector2(0, -8 + bob), 8.0, Color("#c9962b"))
				draw_rect(Rect2(-4, -17 + bob, 8, 4), Color("#8a5e12"))
				draw_rect(Rect2(-1, -12 + bob, 2, 8), Color("#fff2b0"))
			"potion":
				draw_circle(Vector2(0, -8 + bob), 7.0, Color("#b44bd6"))
				draw_rect(Rect2(-3, -19 + bob, 6, 7), Color("#d8d8e8"))
				draw_circle(Vector2(-2, -10 + bob), 2.0, Color(1, 1, 1, 0.7))
			"xp":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -20 + bob), Vector2(6, -9 + bob), Vector2(0, 0 + bob), Vector2(-6, -9 + bob)]), Color("#59c8ff"))
			"pack":
				draw_rect(Rect2(-11, -26 + bob, 22, 24), Color("#8b5a2b"))
				draw_rect(Rect2(-11, -26 + bob, 22, 24), Color("#2b1708"), false, 2.0)
				draw_rect(Rect2(-8, -14 + bob, 16, 8), Color("#b8803f"))
				draw_arc(Vector2(0, -26 + bob), 6.0, PI, TAU, 8, Color("#2b1708"), 2.5)
				draw_circle(Vector2(0, -34 + bob), 3.0, Color(1, 0.9, 0.4, 0.5 + 0.4 * sin(t * 4.0)))
			"crate":
				var col: Color = Color.html(String(SUPPLY_TYPES[sub]["col"]))
				draw_arc(Vector2(0, -12), 26.0 + 3.0 * sin(t * 5.0), 0, TAU, 32, Color(col.r, col.g, col.b, 0.5), 3.0)
				draw_rect(Rect2(-16, -28, 32, 26), col.darkened(0.35))
				draw_rect(Rect2(-16, -28, 32, 26), Color("#17120a"), false, 2.0)
				draw_rect(Rect2(-16, -18, 32, 5), col)
				draw_rect(Rect2(-3, -28, 6, 26), col)
				if sub == "medical":
					draw_rect(Rect2(-2, -26, 4, 12), Color.WHITE)
					draw_rect(Rect2(-6, -22, 12, 4), Color.WHITE)
				draw_arc(Vector2(0, -12), 34.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(ttl / 30.0, 0.0, 1.0), 32, Color.WHITE, 3.0)


func _init() -> void:
	paid_tier = 0


func _ok_pos(pos: Vector2) -> bool:
	if m._blocked(pos, 26.0):
		return false
	for it in items:
		if is_instance_valid(it) and it.position.distance_to(pos) < SPACING:
			return false
	return true


func _find_pos() -> Variant:
	for i in range(8):
		var pos: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(260.0, 520.0)
		if _ok_pos(pos):
			return pos
	return null


func _count(kind: String) -> int:
	var n := 0
	for it in items:
		if is_instance_valid(it) and it.kind == kind:
			n += 1
	return n


func _mk(kind: String, sub: String, pos: Vector2, ttl: float) -> Item:
	var it := Item.new()
	it.kind = kind
	it.sub = sub
	it.ttl = ttl
	it.uid = next_id
	next_id += 1
	it.position = pos
	m.world.add_child(it)
	items.append(it)
	return it


func _busy() -> bool:
	return m.arena != null or m._boss_alive() or m._legend_busy() or m.dir_finale or m.player.dead or m.timeup


func spawn_pickup() -> Item:
	if _count("pouch") + _count("potion") + _count("xp") >= CAP_PICK:
		return null
	var pos = _find_pos()
	if pos == null:
		return null
	var r: float = randf()
	var kind := "pouch" if r < 0.45 else ("xp" if r < 0.75 else "potion")
	return _mk(kind, "", pos, 45.0)


func spawn_pack() -> Item:
	if _count("pack") >= CAP_PACK:
		return null
	var pos = _find_pos()
	if pos == null:
		return null
	return _mk("pack", "rare" if randf() < 0.25 else "", pos, 150.0)


func spawn_supply(force: String = "") -> Item:
	if supply != null and is_instance_valid(supply):
		return null    # maximo UNA caja global
	var pos = _find_pos()
	if pos == null:
		return null
	var ty: String = force
	if ty == "":
		var r: float = randf()
		ty = "medical" if r < 0.3 else ("resource" if r < 0.6 else ("rare" if r < 0.88 else "golden"))
	supply = _mk("crate", ty, pos, SUPPLY_CLAIM)
	m._say(m.L.t("¡SUMINISTRO EN CAMINO!"), 2.4)
	m.pfx.burst(pos + Vector2(0, -20), Color.html(String(SUPPLY_TYPES[ty]["col"])), 24, 160.0)
	var n: int = int(SUPPLY_TYPES[ty]["enemies"])
	for i in range(mini(n, m.ENEMY_CAP - m.enemies.size())):
		var e = m._spawn_one(randf() * TAU, true)
		e.set_meta("enc", "supply")
		supply.tagged.append(e)
	log.append(["supply", ty])
	return supply


func claim(it: Item) -> bool:
	if it.done or claimed.has(it.uid):
		return false
	it.done = true            # primero el estado, luego el premio
	claimed[it.uid] = true
	var p: Vector2 = it.position
	match it.kind:
		"pouch":
			if m.balls >= m.BALL_CAP:
				it.done = false
				claimed.erase(it.uid)
				return false      # Poké Balls al maximo: la bolsa se queda en el suelo
			m._collect("ball", 3.0)
		"xp":
			if _prism_targets(p).is_empty():
				it.done = false
				claimed.erase(it.uid)
				return false      # sin enemigos cerca no se gasta
			_prism(p)
		"potion":
			if m.power_t > 0.0:
				it.done = false
				claimed.erase(it.uid)
				return false      # ya tienes un potenciador activo
			_elixir()
		"pack":
			_pack_reward(p, it.sub == "rare")
		"crate":
			_crate_reward(it)
	if it.kind == "pouch":
		_fx_anim(p, ["fx_c1", "fx_c2", "fx_c3", "fx_c4", "fx_c5"])
	elif it.kind == "xp":
		_fx_anim(p, ["fx_x0", "fx_x1", "fx_x2", "fx_x3"])
	elif it.kind == "potion":
		_fx_anim(p, ["fx_p0", "fx_p1", "fx_p2", "fx_p3"])
	if it.kind == "pack":
		_fx_open(p, "packr_o" if it.sub == "rare" else "pack_o")
	elif it.kind == "crate":
		_fx_open(p, {"medical": "sup_med_o", "resource": "sup_res_o", "rare": "sup_rare_o", "golden": "sup_gold_o"}[it.sub])
	m.Aud.sfx("shinyGet" if it.kind == "pouch" else "chest")
	m.pfx.burst(p + Vector2(0, -14), Color("#ffd23f"), 14, 120.0)
	log.append(["claim", it.kind, it.sub])
	_remove(it)
	return true


# Cristal Prisma: paraliza un momento a los enemigos cercanos (salida de emergencia, no da experiencia).
func _prism_targets(p: Vector2) -> Array:
	var out: Array = []
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead and not e.boss and e.position.distance_to(p) <= 320.0:
			out.append(e)
	return out


func _prism(p: Vector2) -> void:
	for e in _prism_targets(p):
		e.sleep_t = maxf(e.sleep_t, 2.5)
	m._ring(p, 8.0, 320.0, Color("#7ff0ff"), 0.5, 5.0)
	m._ring(p, 6.0, 200.0, Color("#ff9aff"), 0.4, 3.0)
	m.pfx.burst(p + Vector2(0, -14), Color("#7ff0ff"), 22, 200.0)
	m.add_text(p + Vector2(0, -44), m.L.t("¡Prisma!"), Color("#7ff0ff"), 22)
	m.Aud.sfx("legend")


# Elixir: un potenciador al azar durante 25 s (los mismos que dan los altares).
func _elixir() -> void:
	var pw: Dictionary = m.POWERS[randi() % m.POWERS.size()]
	m.power_kind = String(pw["id"])
	m.power_t = 25.0
	m._say(m.L.t("Elixir: %s. %s (25 s)") % [m.L.t(String(pw["name"])), m.L.t(String(pw["desc"]))], 3.0)
	m.Aud.sfx("legend")


func _pack_reward(p: Vector2, rare: bool = false) -> void:
	var opts: Array = [["gold", 40.0], ["xp", 20.0], ["cons", 10.0], ["ticket", 3.0]]
	if rare:
		opts = [["gold", 30.0], ["xp", 25.0], ["cons", 20.0], ["ticket", 10.0]]
	if m.player.hp < m.player.max_hp:
		opts.append(["heal", 25.0 if not rare else 15.0])
	var tot := 0.0
	for o in opts:
		tot += float(o[1])
	var r: float = randf() * tot
	var pick := "gold"
	for o in opts:
		r -= float(o[1])
		if r <= 0.0:
			pick = String(o[0])
			break
	match pick:
		"gold":
			for i in range(8):
				m._spawn_orb(p, "coin", 5.0)
		"xp":
			m._collect("xpBig", float(m._xp_for(m.player.level)) * 0.2)
		"heal":
			m._collect("heal", 0.0)
		"cons":
			m._spawn_orb(p, "magnet" if randf() < 0.5 else "bomb", 0.0)
		"ticket":
			m._spawn_orb(p, "ticket", 1.0)
	m.try_ball(p + Vector2(16, 0), 0.10 if rare else 0.06)
	m.add_text(p + Vector2(0, -40), m.L.t("¡Paquete abierto!"), Color("#ffd23f"), 22)
	log.append(["pack", pick])


func _crate_reward(it: Item) -> void:
	var p: Vector2 = it.position
	match it.sub:
		"medical":
			m._spawn_orb(p, "heal", 0.0)
			m._spawn_orb(p + Vector2(18, 0), "heal", 0.0)
		"resource":
			for i in range(12):
				m._spawn_orb(p, "coin", 5.0)
			m._collect("xpBig", float(m._xp_for(m.player.level)) * 0.25)
		"rare":
			m._spawn_orb(p, "ticket", 1.0)
			for i in range(8):
				m._spawn_orb(p, "coin", 5.0)
			m._spawn_orb(p, "item", 0.0)
		"golden":
			m._spawn_orb(p, "item", 0.0)
			m._spawn_orb(p + Vector2(14, 0), "ticket", 1.0)
			for i in range(14):
				m._spawn_orb(p, "coin", 5.0)
			m._collect("xpBig", float(m._xp_for(m.player.level)) * 0.4)
	if it.sub == "golden":
		m.try_ball(p + Vector2(20, 0), 1.0, true)
	elif it.sub == "rare":
		m.try_ball(p + Vector2(20, 0), 0.25)
	m._say(m.L.t("¡SUMINISTRO RECLAMADO!"), 2.2)
	_release(it)


func _fx_open(pos: Vector2, tn: String) -> void:
	var f := Item.new()
	f.kind = "fxopen"
	f.sub = tn
	f.ttl = 0.9
	f.position = pos
	m.world.add_child(f)
	var tw: Tween = f.create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(f.queue_free)


func _fx_anim(pos: Vector2, frames: Array) -> void:
	var f := Item.new()
	f.kind = "fxanim"
	f.frames = frames
	f.ttl = 0.4
	f.position = pos
	m.world.add_child(f)
	var tw: Tween = f.create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(f.queue_free)


func _release(it: Item) -> void:
	for e in it.tagged:
		if is_instance_valid(e):
			e.remove_meta("enc")     # los enemigos quedan como normales; nada se borra


func _remove(it: Item) -> void:
	items.erase(it)
	if supply == it:
		supply = null
	if is_instance_valid(it):
		it.queue_free()


func paid_cost() -> int:
	if paid_n < PAID_STEPS.size():
		return int(PAID_STEPS[paid_n])
	return int(PAID_STEPS[PAID_STEPS.size() - 1]) + 35 * (paid_n - PAID_STEPS.size() + 1)


# Cofre de pago: cobrar -> marcar abierto -> UN premio. Sin fondos o cancelado: no cobra ni sube el precio.
func buy_chest(p) -> bool:
	if p.used:
		return false
	var cost: int = paid_cost()
	if m.coins < cost:
		m.add_text(p.position + Vector2(0, -50), m.L.t("Faltan monedas"), Color("#ff8a8a"), 20)
		return false
	m.coins -= cost
	paid_n += 1
	paid_tier = mini(paid_n, 5)
	p.used = true
	m.run_chests += 1
	var pos: Vector2 = p.position
	# Premio de la hucha: una MEJORA gratis (subes de nivel y eliges carta) o una Poké Ball; las de mas valor pueden dar las dos.
	var tier: int = clampi(paid_n - 1, 0, 5)
	var give_up: bool = randf() < 0.70
	var give_ball: bool = not give_up
	if tier >= 3 and randf() < 0.3:
		give_up = true
		give_ball = true
	if give_ball and m.balls >= m.BALL_CAP:
		give_ball = false
		give_up = true
	if give_up:
		m.free_upgrade()
		m.add_text(pos + Vector2(0, -68), m.L.t("¡Mejora gratis!"), Color("#ffd23f"), 24)
	if give_ball:
		m._spawn_orb(pos + Vector2(16, 0), "ball", 1.0)
	_fx_open(pos, "cho%d" % clampi(paid_n - 1, 0, 5))
	m.Aud.sfx("chest")
	m.pfx.burst(pos + Vector2(0, -14), Color("#7fe0ff"), 26, 190.0)
	m.add_text(pos + Vector2(0, -44), m.L.t("¡Cofre abierto!"), Color("#7fe0ff"), 22)
	log.append(["paid", cost])
	p.queue_free()
	m._forget_prop(p)
	return true


# Cofre trampa: emboscada acotada (sin oleadas infinitas) con salida libre.
func trigger_trap_chest(p) -> void:
	if p.used:
		return
	p.used = true
	var pos: Vector2 = p.position
	m.Aud.sfx("boss")
	m.shake = maxf(m.shake, 6.0)
	m._say(m.L.t("¡Era una trampa!"), 2.2)
	var n: int = mini(6, m.ENEMY_CAP - m.enemies.size())
	for i in range(maxi(0, n)):
		var a: float = TAU * float(i) / 6.0
		var e = m._spawn_one(a, true)
		e.position = pos + Vector2.from_angle(a) * 150.0
		e.set_meta("enc", "trap")
	for i in range(6):
		m._spawn_orb(pos, "coin", 5.0)
	_fx_open(pos, "trapv_o" if p.sub == "trapv" else "trapd_o")
	log.append(["trap", n])
	p.queue_free()
	m._forget_prop(p)


func update(delta: float) -> void:
	var pressed: bool = m.act_req
	m.act_req = false
	m.hud.act_txt = ""
	m.hud.act_sp = Vector2(-9999.0, -9999.0)
	m.hud.poi_marks = []
	if _busy():
		return
	# generacion
	pick_t -= delta
	if pick_t <= 0.0:
		pick_t = randf_range(14.0, 26.0)
		spawn_pickup()
	pack_t -= delta
	if pack_t <= 0.0:
		pack_t = randf_range(70.0, 110.0)
		spawn_pack()
	sup_t -= delta
	if sup_t <= 0.0:
		sup_t = randf_range(150.0, 210.0)
		spawn_supply()
	# vida, recogida e interaccion
	var pp: Vector2 = m.player.position
	var target = null
	for it in items.duplicate():
		if not is_instance_valid(it):
			items.erase(it)
			continue
		it.ttl -= delta
		if it.ttl <= 0.0 and not it.done:
			if it.kind == "crate":
				m._say(m.L.t("¡SUMINISTRO EXPIRADO!"), 2.0)
				_release(it)
				log.append(["expired", it.sub])
			_remove(it)
			continue
		var d: float = it.position.distance_to(pp)
		if it.kind == "pouch" or it.kind == "xp" or it.kind == "potion":
			if d < 34.0:
				claim(it)
		elif d < 52.0 and (it.kind == "pack" or it.kind == "crate"):
			target = it
	var ct = null
	if target == null:
		for pr in m._props_near(pp):
			if is_instance_valid(pr) and pr.kind == "chest" and pr.sub == "paid" and not pr.used and pr.position.distance_to(pp) < 62.0:
				ct = pr
				break
	if m.alpha.window_ok(pp):
		m.hud.act_txt = m.L.t("Lanzar Poké Ball")
		m.hud.act_sp = m.get_viewport().get_canvas_transform() * ((m.alpha.cur["pos"] as Vector2) + Vector2(0.0, -34.0))   # el botón va dentro del Pokémon caído
		if pressed:
			m.alpha.throw()
	elif target != null:
		m.hud.act_txt = m.L.t("Abrir")
		m.hud.act_sp = m.get_viewport().get_canvas_transform() * (target.position + Vector2(0.0, -14.0))
		if pressed:
			claim(target)
	elif ct != null:
		m.hud.act_txt = "%d" % paid_cost()
		m.hud.act_sp = m.get_viewport().get_canvas_transform() * (ct.position + Vector2(0.0, -10.0))
		if pressed:
			buy_chest(ct)
	elif m.rescue.can_interact(pp):
		m.hud.act_txt = m.L.t("Rescatar")
		if pressed:
			m.rescue.interact()
	elif m.kec.near(pp):
		m.hud.act_txt = m.L.t("Comerciar")
		m.hud.act_sp = m.get_viewport().get_canvas_transform() * (m.kec.active.position + Vector2(0.0, -128.0))   # sobre la cabeza de Kecleon
		if pressed:
			m.kec.open_ui()
	# marcador de la caja de suministro
	if supply != null and is_instance_valid(supply):
		var ct2: Transform2D = m.get_viewport().get_canvas_transform()
		m.hud.poi_marks = [{"sp": ct2 * (supply.position + Vector2(0, -20)), "txt": m.L.t(String(SUPPLY_TYPES[supply.sub]["name"])) + "  %ds" % ceili(supply.ttl),
			"col": Color.html(String(SUPPLY_TYPES[supply.sub]["col"]))}]
	var km = m.kec.mark()
	if km != null:
		m.hud.poi_marks.append(km)
	var rm = m.rescue.mark()
	if rm != null:
		m.hud.poi_marks.append(rm)
	var am = m.alpha.mark()
	if am != null:
		m.hud.poi_marks.append(am)
	for mod in [m.cave, m.inv, m.meteor, m.mew]:
		var mk = mod.mark()
		if mk != null:
			m.hud.poi_marks.append(mk)
