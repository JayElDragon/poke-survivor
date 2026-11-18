extends RefCounted
# 7.0: pelea de Eternatus en tres fases (del original, adaptada al jefe final del port en el minuto 60).
#  Fase 1 (vida > 66%): charcos de Toxico avisados en el suelo y Cañon Dinamax (rayo avisado hacia ti).
#  Fase 2 (66%-33%): cuatro nucleos unidos por una barrera de laseres; mientras quede alguno, Eternatus es invulnerable.
#  Fase 3 (< 33%): Remolino Infinito (te arrastra hacia el y estalla) y, desde el 15%, el Rayo Eternamax.
# El cielo se tiñe de rojo mientras dura. Todo se limpia al vencerle, al caer tu o si desaparece.

const CORE_N := 4
const CORE_R := 230.0
const TOX := Color("#b04ae0")
const RED := Color("#ff2a4a")

var m = null
var e = null              # Eternatus
var phase := 0
var atk_t := 3.0
var alt := 0
var cores: Array = []
var barrier = null
var cores_done := false
var pull_t := 0.0
var beam_done := false
var tint_on := false
var log: Array = []


# Barrera de laseres entre los nucleos (en orden, cerrando el anillo).
class Barrier extends Node2D:
	var pts: Array = []
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var n: int = pts.size()
		if n < 2:
			return
		for i in range(n):
			var a: Vector2 = pts[i] - position
			var b: Vector2 = pts[(i + 1) % n] - position
			var fl: float = 0.6 + 0.4 * sin(t * 18.0 + float(i))
			draw_line(a, b, Color(1.0, 0.15, 0.3, 0.35 * fl), 14.0)
			draw_line(a, b, Color(1.0, 0.5, 0.6, 0.9 * fl), 4.0)
			draw_line(a, b, Color(1, 1, 1, 0.9), 1.5)


func start(main, boss) -> void:
	m = main
	e = boss
	phase = 1
	atk_t = 4.0
	_tint(true)
	log.append(["start"])


func active() -> bool:
	return e != null


func update(delta: float) -> void:
	if e == null:
		return
	if not is_instance_valid(e) or e.dead or m.player.dead or m.timeup:
		stop()
		return
	var fr: float = e.hp / maxf(e.max_hp, 1.0)
	# cambios de fase
	if phase == 1 and fr <= 0.66:
		phase = 2
		_spawn_cores()
		m._say(m.L.t("¡Eternatus se protege con sus núcleos! Destrúyelos"), 3.0)
	elif phase == 2 and cores_done and fr <= 0.33:
		phase = 3
		atk_t = 1.5
		m._say(m.L.t("¡Remolino Infinito!"), 2.4)
	if phase == 2:
		_cores_tick(delta)
	# Remolino Infinito: arrastra al jugador hacia Eternatus y acaba con un estallido
	if pull_t > 0.0:
		pull_t -= delta
		var dv: Vector2 = e.position - m.player.position
		if dv.length() > 60.0:
			m.player.position = m._collide(m.player.position + dv.normalized() * 170.0 * delta, m.player.radius)
		if randf() < 0.5:
			m.pfx.px(m.player.position + Vector2.from_angle(randf() * TAU) * 120.0, RED, dv.normalized() * 220.0, 0.4, 2.0)
		if pull_t <= 0.0:
			m._hazard_zone(e.position, 190.0, 0.25, float(e.dmg) * 1.8, "dragon", RED)
			m._ring(e.position, 10.0, 220.0, RED, 0.5, 6.0)
			m.shake = maxf(m.shake, 9.0)
	# Rayo Eternamax: una vez, desde el 15% de vida
	if phase == 3 and not beam_done and fr <= 0.15 and pull_t <= 0.0:
		beam_done = true
		_eternabeam()
		atk_t = 4.0
	atk_t -= delta
	if atk_t <= 0.0 and pull_t <= 0.0:
		_attack()


func _attack() -> void:
	var pp: Vector2 = m.player.position
	var d: float = float(e.dmg)
	match phase:
		1:
			if alt % 2 == 0:
				_toxic(pp, d)
			else:
				_cannon(pp, d)
			atk_t = 3.4
		2:
			_toxic(pp, d)
			atk_t = 4.2
		_:
			if alt % 3 == 2:
				pull_t = 2.2
				m._say(m.L.t("¡Remolino Infinito! Aléjate del centro"), 1.6)
				m._ring(e.position, 260.0, 30.0, RED, 0.9, 5.0)
				atk_t = 4.6
			elif alt % 3 == 1:
				_cannon(pp, d)
				atk_t = 2.6
			else:
				_toxic(pp, d)
				atk_t = 2.8
	alt += 1


# Toxico: cinco charcos avisados, uno sobre ti
func _toxic(pp: Vector2, d: float) -> void:
	for i in range(5):
		var c: Vector2 = pp if i == 0 else m._free_spot(pp + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 230.0), 14.0)
		m._hazard_zone(c, 72.0, 1.3 + 0.1 * float(i), d * 1.0, "poison", TOX)
	m._say(m.L.t("¡Tóxico!"), 1.0)


# Cañon Dinamax: rayo avisado desde Eternatus hacia ti
func _cannon(pp: Vector2, d: float) -> void:
	var a: float = (pp - e.position).angle()
	m._hazard_beam(e.position + Vector2(0, -40), a, 900.0, 60.0, 1.1, d * 1.4, "dragon", RED)
	m._say(m.L.t("¡Cañón Dinamax!"), 1.0)


func _eternabeam() -> void:
	var a: float = (m.player.position - e.position).angle()
	m._hazard_beam(e.position + Vector2(0, -40), a, 1400.0, 190.0, 2.0, m.player.max_hp * 0.35, "dragon", RED)
	m._say(m.L.t("¡RAYO ETERNAMAX! ¡Sal de su línea!"), 2.4)
	m.shake = maxf(m.shake, 12.0)
	log.append(["eternabeam"])


func _spawn_cores() -> void:
	cores.clear()
	for i in range(CORE_N):
		var p: Vector2 = m._free_spot(e.position + Vector2.from_angle(TAU * float(i) / float(CORE_N) + 0.4) * CORE_R, 14.0)
		var c = m._spawn_dex_at(int(m.ETERNATUS_DEX), p)
		c.max_hp = roundf(e.max_hp * 0.06)
		c.hp = c.max_hp
		c.spd = 0.0
		c.dmg *= 0.5
		c.scale = Vector2(0.55, 0.55)
		c.modulate = Color(1.0, 0.55, 0.75)
		c.xp_val = 0.0
		c.set_meta("enc", "eter_core")
		cores.append(c)
	barrier = Barrier.new()
	barrier.z_index = 11
	m.world.add_child(barrier)
	cores_done = false
	log.append(["cores", cores.size()])


func _cores_tick(delta: float) -> void:
	var alive: Array = []
	for c in cores:
		if is_instance_valid(c) and not c.dead:
			c.spd = 0.0
			alive.append(c)
	if alive.is_empty():
		if not cores_done:
			cores_done = true
			e.shield = 0.0
			e.shield_t = 0.0
			if barrier != null and is_instance_valid(barrier):
				barrier.queue_free()
			barrier = null
			m._say(m.L.t("¡Núcleos destruidos! Eternatus es vulnerable"), 2.6)
			m.shake = maxf(m.shake, 8.0)
		return
	# invulnerable mientras quede un nucleo
	e.shield = 1.0e9
	e.shield_t = 1.0
	# barrera: segmentos entre los nucleos vivos; tocarla hace daño
	if barrier != null and is_instance_valid(barrier):
		var pts: Array = alive.map(func(c): return (c as Node2D).position + Vector2(0, -20))
		barrier.pts = pts
		if pts.size() >= 2:
			var pp: Vector2 = m.player.position + Vector2(0, -16)
			for i in range(pts.size()):
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % pts.size()]
				var ab: Vector2 = b - a
				var tt: float = clampf((pp - a).dot(ab) / maxf(1.0, ab.length_squared()), 0.0, 1.0)
				if (a + ab * tt).distance_to(pp) < 16.0 + m.player.radius * 0.5:
					m._hurt_player(float(e.dmg) * 0.6, "dragon")
					break


func _tint(on: bool) -> void:
	if on == tint_on:
		return
	tint_on = on
	m.ground.modulate = Color(1.0, 0.62, 0.62) if on else Color.WHITE   # cielo rojo de Eternamax


func stop() -> void:
	for c in cores:
		if is_instance_valid(c) and not c.dead:
			c.dead = true
			c.queue_free()
			m.enemies.erase(c)
	cores.clear()
	if barrier != null and is_instance_valid(barrier):
		barrier.queue_free()
	barrier = null
	pull_t = 0.0
	_tint(false)
	e = null
	log.append(["stop"])
