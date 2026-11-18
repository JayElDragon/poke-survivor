extends RefCounted
# 7.0: evento Munchlax hambriento (del original). Munchlax quiere 3 bayas de una clase. Sacude los arbustos
# de alrededor (se ve que bayas tiene cada uno) y llevaselas: te deja un objeto y un Caramelo Exp.
# Las bayas que no quiere son para ti (curan). Cuidado: en algunos arbustos hay un enjambre de Combee.
# Un solo evento activo, un unico pago, se cancela sin premio si llega un jefe o una escena importante.

const MUNCHLAX := 446
const COMBEE := 415
const FIRST_AT := 330.0
const GAP_MIN := 360.0
const GAP_MAX := 540.0
const TTL := 120.0
const WANT := 3
const BUSHES := 7
const SWARM := 5
# id: [nombre, color]
const BERRIES := {"aranja": ["Baya Aranja", "#4f8fd8"], "meloc": ["Baya Meloc", "#ff8ad8"], "zidra": ["Baya Zidra", "#ffd23f"]}

var m = null
var poi = null
var cur = null           # {id, node, pos, want, have, ttl, state, bushes: [Bush]}
var next_id := 1
var t_next := FIRST_AT
var done := {}
var log: Array = []


class Bush extends Node2D:
	var berries: Array = []   # ids de baya
	var combee := false
	var shaken := false
	var t := 0.0
	var shake_t := 0.0

	func _process(delta: float) -> void:
		t += delta
		shake_t = maxf(0.0, shake_t - delta)
		queue_redraw()

	func _draw() -> void:
		var off := Vector2(sin(t * 50.0) * 4.0 * shake_t, 0.0)
		draw_circle(Vector2(0, 6), 24.0, Color(0, 0, 0, 0.25))
		var g1 := Color("#2f7a3a") if not shaken else Color("#4a6a3a")
		var g2 := Color("#4fae4a") if not shaken else Color("#6a8a5a")
		for p in [Vector2(-14, -6), Vector2(14, -6), Vector2(0, -18), Vector2(0, -2)]:
			draw_circle(p + off, 15.0, g1)
		for p in [Vector2(-10, -10), Vector2(10, -10), Vector2(0, -20)]:
			draw_circle(p + off, 10.0, g2)
		if not shaken:
			var spots := [Vector2(-12, -12), Vector2(8, -18), Vector2(12, -4), Vector2(-4, -2)]
			for i in range(berries.size()):
				var c := Color(String(BERRIES[String(berries[i])][1]))
				draw_circle(spots[i % spots.size()] + off, 5.0, Color("#1a1a1a"))
				draw_circle(spots[i % spots.size()] + off, 4.0, c)
				draw_circle(spots[i % spots.size()] + off + Vector2(-1.5, -1.5), 1.3, Color(1, 1, 1, 0.8))


class Mon extends Node2D:
	var actor = null
	var want := "aranja"
	var have := 0
	var t := 0.0
	var thanks := 0.0

	func _process(delta: float) -> void:
		t += delta
		if thanks > 0.0:
			thanks -= delta
			if actor != null:
				actor.position.y = -absf(sin(t * 9.0)) * 7.0
			modulate.a = clampf(thanks / 0.6, 0.0, 1.0)
			if thanks <= 0.0:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		if thanks > 0.0:
			return
		draw_circle(Vector2(0, 4), 22.0, Color(0, 0, 0, 0.28))
		# bocadillo con la baya que quiere y cuantas lleva
		var bp := Vector2(0, -78 + sin(t * 3.0) * 3.0)
		draw_circle(bp, 22.0, Color(1, 1, 1, 0.95))
		draw_circle(bp + Vector2(-10, 22), 5.0, Color(1, 1, 1, 0.95))
		draw_circle(bp + Vector2(-16, 31), 3.0, Color(1, 1, 1, 0.95))
		var c := Color(String(BERRIES[want][1]))
		draw_circle(bp + Vector2(-6, -2), 8.0, Color("#1a1a1a"))
		draw_circle(bp + Vector2(-6, -2), 7.0, c)
		draw_circle(bp + Vector2(-8, -4), 2.0, Color(1, 1, 1, 0.8))
		draw_string(ThemeDB.fallback_font, bp + Vector2(4, 4), "%d/%d" % [have, WANT], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#3a2236"))


func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not poi._busy() and not m.shop_open and m.run_time >= FIRST_AT \
		and m.arena == null and m._smeta.has(str(MUNCHLAX)) and (m.rescue == null or m.rescue.cur == null)


func spawn() -> bool:
	if cur != null:
		return false
	var pos: Variant = null
	for i in range(10):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(320.0, 460.0)
		if poi._ok_pos(c):
			pos = c
			break
	if pos == null:
		return false
	var mon := Mon.new()
	mon.position = pos
	mon.want = String(BERRIES.keys()[randi() % BERRIES.size()])
	m.world.add_child(mon)
	var a = m.Actor.new()
	a.setup(MUNCHLAX, m._sm(MUNCHLAX), m.flash_shader, 1.0)
	mon.add_child(a)
	mon.actor = a
	# arbustos alrededor: siempre hay al menos WANT bayas de la que quiere, y dos esconden Combee
	var bushes: Array = []
	var kinds: Array = BERRIES.keys()
	var swarm_left := 2
	for i in range(BUSHES):
		var bpos: Variant = null
		for k in range(8):
			var c2: Vector2 = pos + Vector2.from_angle(TAU * float(i) / float(BUSHES) + randf_range(-0.3, 0.3)) * randf_range(170.0, 330.0)
			if poi._ok_pos(c2):
				bpos = c2
				break
		if bpos == null:
			continue
		var b := Bush.new()
		b.position = bpos
		var n: int = 1 + randi() % 2
		for j in range(n):
			b.berries.append(String(kinds[randi() % kinds.size()]))
		if swarm_left > 0 and randf() < 0.35:
			b.combee = true
			swarm_left -= 1
		m.world.add_child(b)
		bushes.append(b)
	if bushes.size() < 3:
		for b in bushes:
			b.queue_free()
		mon.queue_free()
		return false
	var have_want := 0
	for b in bushes:
		have_want += (b.berries as Array).count(mon.want)
	var bi := 0
	while have_want < WANT + 1:   # una de margen
		var b2: Bush = bushes[bi % bushes.size()]
		b2.berries.append(mon.want)
		have_want += 1
		bi += 1
	cur = {"id": next_id, "node": mon, "pos": pos, "ttl": TTL, "state": "active", "bushes": bushes, "bag": 0}
	next_id += 1
	m._say(m.L.t("¡Un Munchlax hambriento quiere 3 %s! Sacude los arbustos.") % m.L.t(String(BERRIES[mon.want][0])), 3.4)
	m.Aud.sfx("rift")
	log.append(["spawn", mon.want])
	return true


func _clear() -> void:
	if cur != null:
		if is_instance_valid(cur["node"]) and float(cur["node"].thanks) <= 0.0:
			cur["node"].queue_free()
		for b in cur["bushes"]:
			if is_instance_valid(b):
				b.queue_free()
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)


func _near_bush(pp: Vector2):
	if cur == null:
		return null
	for b in cur["bushes"]:
		if is_instance_valid(b) and not b.shaken and b.position.distance_to(pp) < 58.0:
			return b
	return null


func can_interact(pp: Vector2) -> bool:
	if cur == null or cur["state"] != "active":
		return false
	if _near_bush(pp) != null:
		return true
	return int(cur["bag"]) > 0 and (cur["pos"] as Vector2).distance_to(pp) < 70.0


func act_text(pp: Vector2) -> String:
	if _near_bush(pp) != null:
		return m.L.t("Sacudir")
	return m.L.t("Dar bayas")


func interact() -> void:
	var pp: Vector2 = m.player.position
	if not can_interact(pp):
		return
	var b = _near_bush(pp)
	if b != null:
		_shake(b)
	else:
		_give()


func _shake(b) -> void:
	b.shaken = true
	b.shake_t = 0.5
	m.Aud.sfx("select")
	var mon = cur["node"]
	var got := 0
	var heal := 0
	for id in b.berries:
		var col := Color(String(BERRIES[String(id)][1]))
		m.pfx.burst(b.position + Vector2(0, -14), col, 6, 90.0)
		if String(id) == String(mon.want):
			got += 1
		else:
			heal += 1   # las que no quiere Munchlax son para ti
	cur["bag"] = int(cur["bag"]) + got
	if heal > 0:
		var hl: float = m._heal_real(m.player.max_hp * 0.06 * float(heal))
		if hl > 0.0:
			m.add_text(m.player.position + Vector2(0.0, -m.player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 16)
	if got > 0:
		m.add_text(b.position + Vector2(0, -40), "+%d %s" % [got, m.L.t(String(BERRIES[String(mon.want)][0]))], Color(String(BERRIES[String(mon.want)][1])), 18)
	if b.combee:
		m._say(m.L.t("¡Un enjambre de Combee!"), 2.0)
		m.shake = maxf(m.shake, 4.0)
		for i in range(mini(SWARM, m.ENEMY_CAP - m.enemies.size())):
			var e = m._spawn_dex_at(COMBEE, b.position + Vector2.from_angle(TAU * float(i) / float(SWARM)) * 60.0)
			e.set_meta("enc", "munchlax")
	b.berries = []
	log.append(["shake", got, heal, b.combee])


func _give() -> void:
	var mon = cur["node"]
	var give: int = mini(int(cur["bag"]), WANT - int(mon.have))
	mon.have = int(mon.have) + give
	cur["bag"] = int(cur["bag"]) - give
	m.Aud.sfx("confirm")
	m.add_text(cur["pos"] + Vector2(0, -60), "%d/%d" % [int(mon.have), WANT], Color(String(BERRIES[String(mon.want)][1])), 20)
	if int(mon.have) >= WANT:
		_success()


func update(delta: float) -> void:
	if cur == null:
		t_next -= delta
		if t_next <= 0.0:
			if not (_spawn_ok() and spawn()):
				t_next = 25.0
		return
	if cur["state"] != "active":
		return
	if poi._busy() or m.player.dead or m.arena != null:
		_expire(true)
		return
	cur["ttl"] = float(cur["ttl"]) - delta
	if float(cur["ttl"]) <= 0.0:
		_expire(false)


func _expire(silent: bool) -> void:
	if cur == null or cur["state"] != "active":
		return
	cur["state"] = "expired"
	if not silent:
		m._say(m.L.t("Munchlax se ha ido a buscar comida a otra parte"), 2.2)
	log.append(["expired", silent])
	_clear()


func _success() -> void:
	if cur == null or cur["state"] != "active" or done.has(cur["id"]):
		return
	cur["state"] = "thanks"          # primero el estado, luego el unico premio
	done[cur["id"]] = true
	var pos: Vector2 = cur["pos"]
	m._spawn_orb(pos + Vector2(-20, 0), "item", 0.0)
	var per: float = ceilf(float(m._xp_for(m.player.level)) * 0.35 / 5.0)   # Caramelo Exp: ~35% de un nivel
	for i in range(5):
		m._spawn_orb(pos + Vector2(20, 0), "xpBig", per)
	m._say(m.L.t("¡Munchlax está lleno! Te deja un objeto y un Caramelo Exp"), 2.8)
	m.pfx.burst(pos + Vector2(0, -24), Color("#ffd23f"), 26, 150.0)
	m.Aud.sfx("shinyGet")
	var mon = cur["node"]
	if is_instance_valid(mon):
		mon.thanks = 2.4
	log.append(["success"])
	for b in cur["bushes"]:
		if is_instance_valid(b):
			b.queue_free()
	cur = null
	t_next = randf_range(GAP_MIN, GAP_MAX)


func mark() -> Variant:
	if cur == null or cur["state"] != "active":
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	var mon = cur["node"]
	var txt: String = m.L.t("Munchlax hambriento") + "  %d/%d" % [int(mon.have) + int(cur["bag"]), WANT] + "  %ds" % ceili(float(cur["ttl"]))
	return {"sp": ct * ((cur["pos"] as Vector2) + Vector2(0, -100)), "txt": txt, "col": Color(String(BERRIES[String(mon.want)][1]))}
