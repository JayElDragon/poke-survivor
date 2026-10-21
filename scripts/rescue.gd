extends RefCounted
# S57.9: rescates de Pokémon salvajes perdidos o heridos (sin entrenadores). Un solo rescate activo, instancia con ID unico,
# objetivo real y verificable, un unico pago. El Pokémon nunca ataca ni se une como companero: da una recompensa y se va.

const FIRST_AT := 200.0
const GAP_MIN := 200.0
const GAP_MAX := 320.0
const HELP_TIME := 6.0          # segundos de juego activo cerca del herido
const HELP_RADIUS := 80.0
const THREAT_N := 4
const TTL := {"injured": 70.0, "threat": 70.0, "lost": 90.0}
const NAMES := {"injured": "Pokémon herido", "threat": "Pokémon amenazado", "lost": "Pokémon perdido"}
const COLS := {"injured": "#ff8a8a", "threat": "#ffb347", "lost": "#7fd4ff"}

var m = null
var poi = null
var cur = null
var next_id := 1
var t_next := FIRST_AT
var done := {}
var log: Array = []


class Mon extends Node2D:
	var prog := 0.0
	var col := Color.WHITE
	var t := 0.0
	var thanks := 0.0
	var actor = null

	func _process(delta: float) -> void:
		t += delta
		if thanks > 0.0:
			thanks -= delta
			if actor != null:
				actor.position.y = -absf(sin(t * 9.0)) * 7.0      # saltito de alegria
			modulate.a = clampf(thanks / 0.6, 0.0, 1.0)
			if thanks <= 0.0:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		if thanks > 0.0:
			return
		draw_circle(Vector2(0, 4), 20.0, Color(0, 0, 0, 0.28))
		draw_arc(Vector2(0, -16), 36.0, 0, TAU, 28, Color(col.r, col.g, col.b, 0.35), 2.0)
		if prog > 0.0:
			draw_arc(Vector2(0, -16), 36.0, -PI * 0.5, -PI * 0.5 + TAU * prog, 36, col, 4.0)


func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not poi._busy() and not m.shop_open and m.run_time >= FIRST_AT \
		and (poi.supply == null or not is_instance_valid(poi.supply)) and (m.kec.active == null or not is_instance_valid(m.kec.active))


func _pick_dex() -> int:
	var bag: Array = m._bag_at(m._dt())
	var cand: Array = []
	for d in bag:
		var dx: int = int(d.get("dex", 0))
		if dx > 0 and m._smeta.has(str(dx)) and not bool(d.get("boss", false)):
			cand.append(dx)
	if cand.is_empty():
		return 0
	return int(cand[randi() % cand.size()])


func spawn(force: String = "") -> bool:
	if cur != null:
		return false
	var dex: int = _pick_dex()
	if dex == 0:
		return false
	var ty: String = force
	if ty == "":
		ty = ["injured", "threat", "lost"][randi() % 3]
	var dist: float = randf_range(650.0, 850.0) if ty == "lost" else randf_range(300.0, 460.0)
	var pos: Variant = null
	for i in range(8):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * dist
		if poi._ok_pos(c):
			pos = c
			break
	if pos == null:
		return false
	var mon := Mon.new()
	mon.position = pos
	mon.col = Color(String(COLS[ty]))
	m.world.add_child(mon)
	var a = m.Actor.new()
	a.setup(dex, m._sm(dex), m.flash_shader, 1.0)
	mon.add_child(a)
	mon.actor = a
	if ty == "injured" and a.has_anim("Hurt"):
		a.loop_anim("Hurt", 0.35)
	cur = {"id": next_id, "type": ty, "node": mon, "pos": pos, "ttl": float(TTL[ty]), "prog": 0.0, "tags": [], "dex": dex, "state": "active"}
	next_id += 1
	if ty == "threat":
		for i in range(mini(THREAT_N, m.ENEMY_CAP - m.enemies.size())):
			var e = m._spawn_one(randf() * TAU, true)
			e.position = pos + Vector2.from_angle(TAU * float(i) / float(THREAT_N)) * 120.0
			e.set_meta("enc", "rescue")
			cur["tags"].append(e)
		if (cur["tags"] as Array).is_empty():
			_clear()
			return false
	var msg := {"injured": "Un Pokémon herido pide ayuda: quédate a su lado.", "threat": "¡Un Pokémon está amenazado! Derrota a sus atacantes.", "lost": "Hay un Pokémon perdido por la zona: encuéntralo."}
	m._say(m.L.t(String(msg[ty])), 3.0)
	m.Aud.sfx("rift")
	log.append(["spawn", ty, dex])
	return true


func _clear() -> void:
	if cur != null and is_instance_valid(cur["node"]):
		cur["node"].queue_free()
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)


func _alive_tags() -> int:
	var n := 0
	for e in cur["tags"]:
		if is_instance_valid(e) and not e.dead:
			n += 1
	return n


func can_interact(pp: Vector2) -> bool:
	return cur != null and cur["type"] == "lost" and cur["state"] == "active" and (cur["pos"] as Vector2).distance_to(pp) < 62.0


func interact() -> void:
	if can_interact(m.player.position):
		_success()


func update(delta: float) -> void:
	if cur == null:
		t_next -= delta
		if t_next <= 0.0:
			if _spawn_ok() and spawn():
				pass
			else:
				t_next = 20.0
		return
	if cur["state"] != "active":
		return
	if poi._busy() or m.player.dead:
		_expire(true)       # los jefes y escenas importantes tienen prioridad: se cancela sin premio ni castigo
		return
	cur["ttl"] = float(cur["ttl"]) - delta
	if float(cur["ttl"]) <= 0.0:
		_expire(false)
		return
	var pp: Vector2 = m.player.position
	var mon = cur["node"]
	match String(cur["type"]):
		"injured":
			if (cur["pos"] as Vector2).distance_to(pp) < HELP_RADIUS:
				cur["prog"] = minf(1.0, float(cur["prog"]) + delta / HELP_TIME)
			mon.prog = float(cur["prog"])
			if float(cur["prog"]) >= 1.0:
				_success()
		"threat":
			var total: int = (cur["tags"] as Array).size()
			var left: int = _alive_tags()
			cur["prog"] = 1.0 - float(left) / float(maxi(1, total))
			mon.prog = float(cur["prog"])
			if left == 0:
				_success()


func _expire(silent: bool) -> void:
	if cur == null or cur["state"] != "active":
		return
	cur["state"] = "expired"
	for e in cur["tags"]:
		if is_instance_valid(e) and e.has_meta("enc"):
			e.remove_meta("enc")
	if not silent:
		m._say(m.L.t("¡El Pokémon se ha ido!"), 2.0)
	log.append(["expired", cur["type"], silent])
	_clear()


func _success() -> void:
	if cur == null or cur["state"] != "active" or done.has(cur["id"]):
		return
	cur["state"] = "thanks"          # primero el estado, luego el unico premio
	done[cur["id"]] = true
	var pos: Vector2 = cur["pos"]
	var reward: String = _reward(pos)
	m.ach_event("rescue", {})
	m._say(m.L.t("¡Rescate completado!"), 2.0)
	m.pfx.burst(pos + Vector2(0, -24), Color("#ff8ad8"), 26, 150.0)
	m.Aud.sfx("shinyGet")
	var mon = cur["node"]
	if is_instance_valid(mon):
		mon.thanks = 2.4
		if mon.actor != null:
			mon.actor.loop_anim("Idle", 1.0)      # se levanta
		_bubble(mon)
	log.append(["success", cur["type"], reward])
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)


# Globo de dialogo sobre el Pokémon (nodo Label real, no draw_string)
func _bubble(mon) -> void:
	var lb := Label.new()
	lb.text = m.L.t("¡Gracias!")
	lb.add_theme_font_size_override("font_size", 20)
	lb.add_theme_color_override("font_color", Color("#3a2236"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.96, 0.98, 0.96)
	sb.border_color = Color("#ff8ad8")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	lb.add_theme_stylebox_override("normal", sb)
	lb.position = Vector2(-44, -(mon.actor.body_h if mon.actor != null else 40.0) - 52.0)
	mon.add_child(lb)


func _reward(pos: Vector2) -> String:
	var opts: Array = [["coin", 35.0], ["xp", 25.0], ["ticket", 12.0]]
	if m.player.hp < m.player.max_hp * 0.85:
		opts.append(["heal", 20.0])
	if m.item == "":
		opts.append(["item", 10.0])
	var tot := 0.0
	for o in opts:
		tot += float(o[1])
	var r: float = randf() * tot
	var pick: String = String(opts[0][0])
	for o in opts:
		r -= float(o[1])
		if r <= 0.0:
			pick = String(o[0])
			break
	match pick:
		"coin":
			for i in range(10):
				m._spawn_orb(pos, "coin", 5.0)
		"xp":
			var per: float = ceilf(float(m._xp_for(m.player.level)) * 0.10 / 5.0)
			for i in range(5):
				m._spawn_orb(pos, "xpBig", per)
		"ticket":
			m._spawn_orb(pos, "ticket", 1.0)
		"heal":
			m._spawn_orb(pos, "heal", 0.0)
		"item":
			m._spawn_orb(pos, "item", 0.0)
	return pick


func mark() -> Variant:
	if cur == null or cur["state"] != "active":
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	var ty: String = String(cur["type"])
	var extra := ""
	if ty == "injured" or ty == "threat":
		extra = "  %d%%" % roundi(float(cur["prog"]) * 100.0)
	return {"sp": ct * ((cur["pos"] as Vector2) + Vector2(0, -50)), "txt": m.L.t(String(NAMES[ty])) + extra + "  %ds" % ceili(float(cur["ttl"])),
		"col": Color(String(COLS[ty]))}
