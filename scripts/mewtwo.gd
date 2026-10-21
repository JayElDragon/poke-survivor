extends RefCounted
# S57.4: Proyecto Mewtwo. En el 10% de las partidas NORMALES aparecen tres laboratorios abandonados. Cada uno es un area aparte
# (lab_int.gd) a la que solo se entra por su puerta y con colision: dentro hay 2 notas de investigacion (paginas y libros).
# Al reunir las 6 notas, se reactiva un experimento oculto: con MEWTWO_CHANCE la camara del ultimo laboratorio se abre y Mewtwo
# pelea con un patron propio (orbes sombra orbitales, Psicocortes, Premoniciones y Telequinesis con pulso). Premio exclusivo.
# Sprites: assets/world/lab/*.png. Mewtwo usa el sprite 150 del proyecto.

const LI = preload("res://scripts/lab_int.gd")
const CVI = preload("res://scripts/cave_int.gd")
const RUN_CHANCE := 0.10
const FIRST_MIN := 360.0
const FIRST_MAX := 660.0
const MEWTWO := 150
const MEWTWO_CHANCE := 0.7
const BOSS_TTL := 240.0
const ENTER_R := 38.0
const NOTES_PER_LAB := 2
const FOOT_X := 125.0
const FOOT_Y0 := -112.0
const FOOT_Y1 := -26.0

var m = null
var poi = null
var rolled := false
var enabled := false
var t_first := 0.0
var cur = null            # {"labs": [...], "state": "labs"|"chamber"|"boss", "inside": ..., "lab": ...}
var used := false
var next_id := 1
var done := {}
var projs: Array = []
var acts: Array = []
var zones: Array = []     # compat
var atk_t := 3.0
var alt := 0
var pull_t := 0.0
var shield_set := false
var log: Array = []
var try_t := 0.0
var _ui: CanvasLayer = null
var _dlg: TextureRect = null
var _dlg_t := 0.0


# ---------- nodos de dibujo ----------
class LabB extends Node2D:
	var lid := 1
	var state := "idle"      # idle | done | chamber | spent
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var a: float = 1.0 if state != "spent" else 0.6
		var nm: String = ["bld1", "bld2", "bld3"][(lid - 1) % 3]
		var tx: Texture2D = CVI.tex_in("lab", nm)
		if state == "idle" or state == "chamber":
			var f: float = 0.5 + 0.5 * sin(t * 3.0)
			var col := Color(1.0, 0.9, 0.5) if state == "idle" else Color(0.8, 0.4, 1.0)
			draw_circle(Vector2(0, -26), 40.0 + 5.0 * f, Color(col.r, col.g, col.b, 0.14))
			draw_arc(Vector2(0, -26), 36.0 + 4.0 * f, 0.0, TAU, 28, Color(col.r, col.g, col.b, 0.7), 3.0)
		if tx != null:
			var sz: Vector2 = tx.get_size() * 0.7
			var tint := Color(a, a, a, 1.0)
			if state == "chamber":
				tint = Color(1.15, 0.9, 1.3, 1.0)
			draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.5, 14.0 - sz.y), sz), false, tint)


class Proj extends Node2D:
	var kind := "orb"          # orb | cut
	var vel := Vector2.ZERO
	var dmg := 30.0
	var r := 16.0
	var life := 4.0
	var warn := 0.0
	var hit := false
	var t := 0.0
	var orbit_c = null         # Node2D alrededor del que gira antes de salir disparada
	var orbit_a := 0.0
	var orbit_r := 70.0
	var orbit_t := 0.0
	var aim_pos := Vector2.ZERO
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if kind == "orb":
			var tx: Texture2D = CVI.tex_in("lab", "fx_core")
			var f: float = 0.85 + 0.15 * sin(t * 12.0)
			draw_circle(Vector2.ZERO, r * 1.7 * f, Color(0.7, 0.3, 1.0, 0.25))
			if tx != null:
				var sz: Vector2 = tx.get_size() * 0.55
				draw_texture_rect(tx, Rect2(-sz * 0.5, sz), false)
		else:
			if warn > 0.0:
				draw_line(Vector2.ZERO, Vector2(900.0 * signf(vel.x), 0.0), Color(1.0, 0.5, 1.0, 0.35 + 0.3 * sin(t * 18.0)), 4.0)
				return
			var tx2: Texture2D = CVI.tex_in("lab", "fx_crescent")
			if tx2 != null:
				var sz2: Vector2 = tx2.get_size() * 1.0
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(signf(vel.x), 1.0))
				draw_texture_rect(tx2, Rect2(-sz2 * 0.5, sz2), false)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Burst extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.7:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var tx: Texture2D = CVI.tex_in("lab", "fx_burst")
		if tx == null:
			return
		var a: float = clampf(1.0 - t / 0.7, 0.0, 1.0)
		var sc: float = 0.8 + 0.5 * clampf(t / 0.3, 0.0, 1.0)
		var sz: Vector2 = tx.get_size() * sc
		draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.5, -sz.y * 0.8), sz), false, Color(1, 1, 1, a))


# ---------- ciclo ----------
func _ok() -> bool:
	return m.mode == "normal" and cur == null and not used and not m.poi._busy() and not m.shop_open \
		and m.cave.cur == null and not m.inv.active() and m.alpha.cur == null and m.rescue.cur == null \
		and m.meteor.deo == null and m.meteor.zone == null and m.meteor.crater == null and m.arena == null


func update(delta: float) -> void:
	_dlg_tick(delta)
	if cur == null:
		if used or m.mode != "normal":
			return
		if not rolled:
			rolled = true
			enabled = randf() < RUN_CHANCE
			t_first = randf_range(FIRST_MIN, FIRST_MAX)
			log.append(["roll", enabled])
		if not enabled or m.run_time < t_first:
			return
		try_t -= delta
		if try_t <= 0.0:
			try_t = 15.0
			if _ok():
				spawn()
		return
	if m.arena != null:
		return        # dentro de un laboratorio: update_inside
	_proj_tick(delta)
	if m.player.dead:
		return
	match String(cur["state"]):
		"labs", "chamber":
			for L in cur["labs"]:
				var n = L["node"]
				if not is_instance_valid(n) or n.state == "done" or n.state == "spent":
					continue
				if n.position.distance_to(m.player.position + Vector2(0, 34)) < ENTER_R + 18.0 and not m._boss_alive():
					_enter(L)
					return
		"boss":
			pass


func force_event() -> bool:
	rolled = true
	enabled = true
	t_first = 0.0
	return spawn()


func spawn() -> bool:
	if cur != null or m.arena != null:
		return false
	var placed: Array = []
	var labs: Array = []
	for i in range(3):
		var pos: Variant = null
		for k in range(24):
			var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(420.0, 820.0)
			var far := true
			for q in placed:
				if (q as Vector2).distance_to(c) < 320.0:
					far = false
			if far and poi._ok_pos(c) and not m._blocked(c, 60.0):
				pos = c
				break
		if pos == null:
			for L in labs:
				L["node"].queue_free()
			return false
		placed.append(pos)
		var n := LabB.new()
		n.lid = i + 1
		n.position = pos
		m.world.add_child(n)
		labs.append({"node": n, "id": i + 1, "found": 0})
	cur = {"labs": labs, "state": "labs", "id": next_id, "fought": false}
	next_id += 1
	used = true
	m._say(m.L.t("¡Laboratorios abandonados detectados! Busca las notas de investigación."), 3.6)
	m.Aud.sfx("rift")
	log.append(["spawn"])
	return true


func notes_total() -> int:
	var n := 0
	if cur != null:
		for L in cur["labs"]:
			n += int(L["found"])
	return n


# colision de los edificios en el mapa: macizos salvo la puerta (por delante)
func collide(pos: Vector2, rad: float) -> Vector2:
	if cur == null:
		return pos
	for L in cur["labs"]:
		var n = L["node"]
		if not is_instance_valid(n):
			continue
		var lp: Vector2 = pos - n.position
		if lp.x > -FOOT_X - rad and lp.x < FOOT_X + rad and lp.y > FOOT_Y0 - rad and lp.y < FOOT_Y1 + rad:
			var dl: float = lp.x + FOOT_X + rad
			var dr: float = FOOT_X + rad - lp.x
			var dt: float = lp.y - (FOOT_Y0 - rad)
			var db: float = (FOOT_Y1 + rad) - lp.y
			var mn: float = minf(minf(dl, dr), minf(dt, db))
			if mn == db:
				lp.y = FOOT_Y1 + rad
			elif mn == dt:
				lp.y = FOOT_Y0 - rad
			elif mn == dl:
				lp.x = -FOOT_X - rad
			else:
				lp.x = FOOT_X + rad
			pos = n.position + lp
	return pos


func _enter(L: Dictionary) -> void:
	var n = L["node"]
	var ci = LI.new()
	ci.kind = "chamber" if n.state == "chamber" else "lab"
	ci.lab_id = int(L["id"])
	if ci.kind == "lab":
		ci.note_count = maxi(0, NOTES_PER_LAB - int(L["found"]))
	cur["inside"] = ci
	cur["lab"] = L
	cur["cstate"] = "wait"
	cur["ct"] = 2.0
	cur["got"] = 0
	log.append(["enter", ci.kind, ci.lab_id])
	m._cave_begin(ci, "lab", "lab")
	if ci.kind == "chamber":
		m._say(m.L.t("La cámara secreta… la cápsula se agrieta."), 3.0)
	else:
		m._say(m.L.t("Laboratorio abandonado: busca las notas de investigación."), 3.0)
	m.Aud.sfx("rift")


func update_inside(delta: float) -> void:
	if cur == null or not cur.has("inside") or not is_instance_valid(cur["inside"]):
		return
	var ci = cur["inside"]
	var pp: Vector2 = m.player.position
	_dlg_tick(0.0)
	_proj_tick(delta)
	if ci.kind == "lab":
		for q in ci.notes:
			if not bool(q["got"]) and (ci.position + (q["pos"] as Vector2)).distance_to(pp) < 36.0 and not m.player.dead:
				q["got"] = true
				cur["got"] = int(cur["got"]) + 1
				var tot: int = notes_total() + int(cur["got"])
				m.pfx.burst(ci.position + (q["pos"] as Vector2), Color("#ffe9a8"), 18, 140.0)
				m.Aud.sfx("shinyGet")
				m._say(m.L.t("Nota de investigación %d/6") % tot, 2.4)
				log.append(["note", tot])
		if ci.notes_left() == 0 and not ci.door_lit:
			ci.door_lit = true
			m._say(m.L.t("Laboratorio explorado. Sal por la puerta."), 2.6)
	else:
		_chamber_tick(delta, ci)
	if String(m.ainfo.get("phase", "")) == "fight" and ci.on_exit(pp) and not m.player.dead \
			and (ci.kind == "lab" or String(cur["cstate"]) != "boss"):
		m.ainfo["phase"] = "won"
		m.ainfo["end"] = 0.4


func _chamber_tick(delta: float, ci) -> void:
	match String(cur["cstate"]):
		"wait":
			cur["ct"] = float(cur["ct"]) - delta
			if float(cur["ct"]) <= 0.0:
				ci.cap_broken = true
				m.shake = 12.0
				m.Aud.sfx("boss")
				m.pfx.burst(ci.position + ci.cap_pos + Vector2(0, -60), Color("#c88bff"), 40, 260.0)
				_spawn_boss(ci)
				cur["cstate"] = "boss"
		"boss":
			_boss_tick(delta, ci)
		"won":
			ci.door_lit = true


func _spawn_boss(ci) -> void:
	if not m._dex_by.has(MEWTWO) or not m._smeta.has(str(MEWTWO)):
		cur["cstate"] = "won"
		return
	var p: Dictionary = m._dex_by[MEWTWO]
	var def := {"at": 0.0, "dex": MEWTWO, "name": String(p["name"]), "hp": 9000.0, "spd": 70.0, "dmg": 42.0, "xp": 4000.0,
		"behavior": "ranged", "shotDmg": 22.0, "shotCd": 2.2, "range": 300.0}
	m._preload_dex(MEWTWO)
	var e = m._spawn_boss(def)
	e.position = ci.position + ci.cap_pos + Vector2(0, 70)
	e.set_meta("enc", "mewtwo")
	e.modulate = Color(1.0, 0.92, 1.15)
	cur["enemy"] = e
	cur["ttl"] = BOSS_TTL
	cur["won"] = false
	atk_t = 2.4
	alt = 0
	pull_t = 0.0
	shield_set = false
	m._say(m.L.t("¡Mewtwo despierta!"), 3.4)
	log.append(["boss"])


func _later(t: float, f: Callable) -> void:
	acts.append({"t": t, "f": f})


func _boss_tick(delta: float, ci) -> void:
	var e = cur["enemy"]
	if bool(cur["won"]):
		cur["cstate"] = "won"
		ci.door_lit = true
		return
	if not is_instance_valid(e) or e.dead:
		return        # la muerte la gestiona on_down desde _drop
	cur["ttl"] = float(cur["ttl"]) - delta
	if float(cur["ttl"]) <= 0.0 or m.player.dead:
		m.enemies.erase(e)
		e.queue_free()
		m._say(m.L.t("¡Mewtwo se desvaneció!"), 2.6)
		cur["cstate"] = "won"
		ci.door_lit = true
		log.append(["left"])
		return
	for i in range(acts.size() - 1, -1, -1):
		acts[i]["t"] = float(acts[i]["t"]) - delta
		if float(acts[i]["t"]) <= 0.0:
			var f: Callable = acts[i]["f"]
			acts.remove_at(i)
			if is_instance_valid(e) and not e.dead:
				f.call()
	# Telequinesis: arrastra al jugador hacia Mewtwo y termina con un pulso
	if pull_t > 0.0:
		pull_t -= delta
		var dv: Vector2 = e.position - m.player.position
		if dv.length() > 40.0:
			m.player.position = m._collide(m.player.position + dv.normalized() * 200.0 * delta, m.player.radius)
		if pull_t <= 0.0:
			var hz = m._hazard_zone(e.position, 150.0, 0.35, float(e.dmg) * 1.6, "psychic", Color("#ff6bd6"))
			m._ring(e.position, 8.0, 170.0, Color("#ff6bd6"), 0.5, 6.0)
			m.shake = maxf(m.shake, 8.0)
	var fr: float = e.hp / maxf(e.max_hp, 1.0)
	if fr < 0.33 and not shield_set:
		shield_set = true
		e.shield = 700.0
		m._say(m.L.t("¡Mewtwo se rodea de una barrera psíquica!"), 2.4)
		m._ring(e.position, 10.0, 140.0, Color("#9fd8ff"), 0.7, 6.0)
	atk_t -= delta
	if atk_t <= 0.0 and pull_t <= 0.0 and acts.is_empty():
		_attack(e, ci)


func _proj(kind: String, pos: Vector2) -> Proj:
	var p := Proj.new()
	p.kind = kind
	p.position = pos
	p.z_index = 10
	m.world.add_child(p)
	projs.append(p)
	return p


func _attack(e, ci) -> void:
	var fr: float = e.hp / maxf(e.max_hp, 1.0)
	var phase: int = 0 if fr > 0.66 else (1 if fr > 0.33 else 2)
	var opts: Array = ["orbs", "cut"]
	if phase >= 1:
		opts.append("future")
	if phase >= 2:
		opts.append("pull")
	var k: String = String(opts[alt % opts.size()])
	alt += 1
	var d: float = float(e.dmg) * (1.0 + m.run_time / 900.0)
	var pc := Color("#ff6bd6")
	var pp: Vector2 = m.player.position
	match k:
		"orbs":
			# Orbes sombra: seis orbes giran alrededor de Mewtwo y salen disparados uno a uno hacia ti
			for i in range(6):
				var o := _proj("orb", e.position)
				o.dmg = d
				o.r = 15.0
				o.orbit_c = e
				o.orbit_a = TAU * float(i) / 6.0
				o.orbit_t = 1.4 + 0.3 * float(i)
				o.life = 6.0
			m._say(m.L.t("¡Orbes sombra!"), 1.2)
			atk_t = 4.2 - 0.5 * phase
		"cut":
			# Psicocorte: dos medias lunas barren la sala por la altura del jugador, avisadas con una linea
			for sgn in [-1.0, 1.0]:
				var c := _proj("cut", ci.position + Vector2(-sgn * (LI.HW + 40.0), clampf(pp.y - ci.position.y, -LI.HH + 70.0, LI.HH - 40.0) + (24.0 * sgn)))
				c.vel = Vector2(sgn * 400.0, 0.0)
				c.warn = 0.9 + (0.0 if sgn < 0.0 else 0.35)
				c.dmg = d * 1.1
				c.r = 34.0
				c.life = 5.0
			m._say(m.L.t("¡Psicocorte!"), 1.2)
			atk_t = 3.6 - 0.4 * phase
		"future":
			# Premonicion: cinco puntos marcados que estallan tras un instante
			for i in range(5):
				var bp: Vector2 = pp if i == 0 else m._free_spot(pp + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 220.0), 14.0)
				m._hazard_zone(bp, 70.0, 1.6 + 0.12 * i, d * 1.2, "psychic", pc)
				_later(1.6 + 0.12 * i, func():
					var bst := Burst.new()
					bst.position = bp
					bst.z_index = 9
					m.world.add_child(bst))
			m._say(m.L.t("¡Premonición!"), 1.2)
			atk_t = 3.8 - 0.4 * phase
		"pull":
			pull_t = 1.4
			m._say(m.L.t("¡Telequinesis! Huye del pulso."), 1.6)
			m._ring(pp, 120.0, 20.0, pc, 0.8, 5.0)
			atk_t = 4.4


func _proj_tick(delta: float) -> void:
	var pp: Vector2 = m.player.position
	for i in range(projs.size() - 1, -1, -1):
		var p = projs[i]
		if not is_instance_valid(p):
			projs.remove_at(i)
			continue
		p.life -= delta
		if p.life <= 0.0 or (m.arena == null and cur != null and not cur.has("inside") and String(cur["state"]) != "boss" and false):
			p.queue_free()
			projs.remove_at(i)
			continue
		if p.kind == "orb":
			if p.orbit_t > 0.0 and p.orbit_c != null and is_instance_valid(p.orbit_c):
				p.orbit_t -= delta
				p.orbit_a += 2.6 * delta
				p.position = (p.orbit_c as Node2D).position + Vector2.from_angle(p.orbit_a) * Vector2(p.orbit_r, p.orbit_r * 0.7) + Vector2(0, -30)
				if p.orbit_t <= 0.0:
					p.vel = (pp - p.position).normalized() * 270.0
					p.orbit_c = null
			else:
				p.position += p.vel * delta
		else:
			if p.warn > 0.0:
				p.warn -= delta
			else:
				p.position += p.vel * delta
		var live: bool = (p.kind == "cut" and p.warn <= 0.0) or (p.kind == "orb" and p.orbit_c == null)
		if live and not p.hit and not m.player.dead and p.position.distance_to(pp) < p.r + m.player.radius * 0.6:
			p.hit = true
			m.player.invuln = 0.0
			m._hurt_player(p.dmg, "psychic")
			m.pfx.burst(p.position, Color("#ff6bd6"), 10, 120.0)
			if p.kind == "orb":
				p.queue_free()
				projs.remove_at(i)


func _cleanup() -> void:
	for p in projs:
		if is_instance_valid(p):
			p.queue_free()
	projs.clear()
	acts.clear()
	pull_t = 0.0


# main llama aqui al salir de un laboratorio (_arena_end)
func on_leave(_won: bool) -> void:
	if cur == null or not cur.has("inside"):
		return
	var ci = cur["inside"]
	var L: Dictionary = cur["lab"]
	var n = L["node"]
	cur.erase("inside")
	_cleanup()
	if ci.kind == "lab":
		L["found"] = int(L["found"]) + int(cur["got"])
		if int(L["found"]) >= NOTES_PER_LAB and is_instance_valid(n):
			n.state = "done"
		if _all_labs_done():
			_all_done()
	else:
		if bool(cur.get("won", false)) or String(cur.get("cstate", "")) == "won":
			if is_instance_valid(n):
				n.state = "spent"
			_finish()
		else:
			if is_instance_valid(n):
				n.state = "chamber"      # se puede volver a intentar (la capsula ya esta rota)
			cur["cstate"] = "wait"


func _all_labs_done() -> bool:
	for L in cur["labs"]:
		if int(L["found"]) < NOTES_PER_LAB:
			return false
	return true


func _all_done() -> void:
	if String(cur["state"]) != "labs":
		return
	_show_dialog()
	log.append(["all_notes"])
	if randf() < MEWTWO_CHANCE:
		cur["state"] = "chamber"
		var L: Dictionary = cur["labs"][2]
		if is_instance_valid(L["node"]):
			L["node"].state = "chamber"
		m._say(m.L.t("¡Un experimento oculto se ha reactivado! Vuelve al último laboratorio."), 4.0)
		log.append(["chamber"])
	else:
		m._say(m.L.t("Los laboratorios estaban vacíos… esta vez no había nada más."), 3.4)
		var pos: Vector2 = m.player.position
		m._spawn_orb(pos, "ticket", 1.0)
		for i in range(30):
			m._spawn_orb(pos, "coin", 5.0)
		log.append(["empty"])
		_finish()


func _finish() -> void:
	for L in cur["labs"]:
		if is_instance_valid(L["node"]):
			var n = L["node"]
			if n.state != "spent":
				n.state = "spent"
			n.get_tree().create_timer(8.0).timeout.connect(n.queue_free)
	cur = null


# La llama main._drop() al morir el enemigo marcado "mewtwo". Un solo premio por encuentro.
func on_down(e) -> void:
	if cur == null or cur.get("enemy") != e or bool(cur.get("won", false)):
		return
	cur["won"] = true
	var pos: Vector2 = e.position
	m._spawn_orb(pos, "ticket", 4.0)
	m._spawn_orb(pos + Vector2(0, 14), "ticket10", 1.0)
	m._spawn_orb(pos + Vector2(16, 0), "item", 0.0)
	m._spawn_orb(pos + Vector2(-16, 0), "item", 0.0)
	for i in range(50):
		m._spawn_orb(pos, "coin", 5.0)
	m._say(m.L.t("¡Mewtwo derrotado! Recompensa exclusiva."), 3.6)
	var st: Dictionary = m.SV.d["stats"]
	st["mewtwoKills"] = int(st.get("mewtwoKills", 0)) + 1
	log.append(["win"])
	if m.has_method("ach_event"):
		m.ach_event("mewtwo", {})
	_cleanup()


func mark() -> Variant:
	if cur == null or m.arena != null:
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	var best = null
	var bd := 1e9
	for L in cur["labs"]:
		var n = L["node"]
		if not is_instance_valid(n) or n.state == "done" or n.state == "spent":
			continue
		var d: float = n.position.distance_to(m.player.position)
		if d < bd:
			bd = d
			best = L
	if best == null:
		return null
	var n2 = best["node"]
	var txt: String = m.L.t("Laboratorio") + " %d/3  %d/6" % [int(best["id"]), notes_total()]
	var col := Color("#ffe9a8")
	if n2.state == "chamber":
		txt = m.L.t("Cámara reactivada")
		col = Color("#c26bff")
	return {"sp": ct * (n2.position + Vector2(0, -150)), "txt": txt, "col": col}


# ---------- dialogo (sprite de la hoja) ----------
func _show_dialog() -> void:
	if _ui == null or not is_instance_valid(_ui):
		_ui = CanvasLayer.new()
		_ui.layer = 70
		m.add_child(_ui)
		_dlg = TextureRect.new()
		_dlg.texture = CVI.tex_in("lab", "dialog")
		_dlg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_dlg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dlg.modulate.a = 0.0
		_ui.add_child(_dlg)
	_dlg_t = 5.5


func _dlg_tick(delta: float) -> void:
	if _ui == null or not is_instance_valid(_ui):
		return
	if _dlg_t > 0.0:
		_dlg_t -= delta
	var a: float = clampf(minf((5.5 - _dlg_t) / 0.35, _dlg_t / 0.6), 0.0, 1.0) if _dlg_t > 0.0 else 0.0
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var bw: float = minf(vp.x * 0.9, 760.0)
	var bh: float = bw * 130.0 / 586.0
	_dlg.size = Vector2(bw, bh)
	_dlg.position = Vector2((vp.x - bw) * 0.5, vp.y * 0.12 + (1.0 - a) * -22.0)
	_dlg.modulate.a = a
