extends RefCounted
# Habilidad propia de cada movimiento EVOLUCIONADO: algo que el movimiento base NO hace.
# Se dispara al lanzar el ataque (con su propia recarga) y reutiliza las piezas de main.gd
# (zonas, ondas, retardos, balas especiales...). Cada movimiento tiene asignada una en SIG.

const Aud = preload("res://scripts/audio.gd")
var M = null

# id (o id#alt) -> [habilidad, {k: dano x, n: cantidad, r: radio, cd: recarga}]
const SIG := {
	# ---- Electricos
	"electro-ball": ["rain", {"n": 5, "r": 54, "k": 1.2}],
	"electroweb": ["stunzone", {"r": 130, "k": 0.5}],
	"bolt-beak": ["blink", {"k": 2.0}],
	"zap-cannon": ["prism", {"k": 1.1}],
	"thunder-wave": ["recast", {}],
	"thunder-shock": ["arcs", {"n": 4, "k": 1.0}],
	"discharge": ["rotbeams", {"n": 6, "k": 0.7}],
	"discharge#alt": ["cage", {"n": 6, "k": 1.2}],
	"thunderbolt": ["mark", {"n": 4, "r": 70, "k": 1.8}],
	# ---- Dragon
	"dragon-darts": ["swarm", {"n": 7, "k": 0.7}],
	"dragon-breath": ["spiral", {"n": 14, "k": 0.5}],
	"dragon-energy": ["bloom", {"r": 110, "k": 0.4}],
	"outrage": ["spin", {"n": 6, "k": 1.0}],
	"dragon-rage": ["comet", {"k": 2.6}],
	# ---- Hada
	"fleur-cannon": ["pillars", {"n": 6, "r": 44, "k": 1.2}],
	"play-rough": ["yank", {"n": 4, "k": 1.4}],
	"fairy-wind": ["tornado", {"n": 3, "r": 90, "k": 0.8}],
	"dazzling-gleam": ["stasis", {"r": 150, "k": 0.9}],
	# ---- Lucha
	"axe-kick": ["slam", {"r": 110, "k": 2.4}],
	"high-jump-kick": ["blink", {"k": 2.4}],
	"hammer-arm": ["shockchain", {"n": 3, "k": 1.1}],
	"sacred-sword": ["comet", {"k": 2.2}],
	"karate-chop": ["spin", {"n": 4, "k": 1.3}],
	"aura-sphere": ["shatterbomb", {"n": 8, "k": 0.8}],
	# ---- Fuego
	"blaze-kick": ["rift", {"n": 5, "k": 1.2}],
	"eruption": ["starfall", {"n": 6, "r": 56, "k": 1.2}],
	"fire-lash": ["spin", {"n": 5, "k": 1.2}],
	"magma-storm": ["ringfire", {"n": 6, "r": 38, "k": 0.5}],
	"mystical-fire": ["arcing", {"k": 1.2}],
	"ember": ["trailer", {"k": 0.35}],
	"flamethrower": ["burnall", {"r": 170, "k": 0.7}],
	"flamethrower#alt": ["ringfire", {"n": 8, "r": 40, "k": 0.6}],
	"fire-spin": ["tornado", {"n": 3, "r": 70, "k": 0.9}],
	"fire-spin#alt": ["vortex", {"r": 120, "k": 1.5}],
	"heat-wave": ["shockchain", {"n": 3, "k": 0.9}],
	"will-o-wisp": ["wisps", {"n": 4, "k": 0.8}],
	"flame-wheel": ["rift", {"n": 6, "k": 0.9}],
	"flame-wheel#alt": ["trailer", {"k": 0.6}],
	# ---- Volador
	"air-cutter": ["arcing", {"k": 1.0}],
	"air-slash": ["rotbeams", {"n": 5, "k": 0.6}],
	"roost": ["shell", {"r": 80, "k": 0.8}],
	"gust": ["tornado", {"n": 3, "r": 80, "k": 0.7}],
	"gust#alt": ["yank", {"n": 5, "k": 1.0}],
	"wing-attack": ["spin", {"n": 4, "k": 1.1}],
	"aerial-ace": ["blink", {"k": 1.6}],
	# ---- Fantasma
	"infernal-parade": ["wisps", {"n": 5, "k": 0.9}],
	"shadow-bone": ["echo", {"n": 2, "r": 90, "k": 1.0}],
	"lick": ["leech", {"n": 3}],
	"shadow-ball": ["shatterbomb", {"n": 6, "k": 0.9}],
	"hex": ["mark", {"n": 3, "r": 64, "k": 1.9}],
	# ---- Planta
	"leech-seed": ["leech", {"n": 5}],
	"solar-beam": ["rotbeams", {"n": 8, "k": 0.8}],
	"vine-whip": ["yank", {"n": 3, "k": 1.2}],
	"razor-leaf": ["swarm", {"n": 6, "k": 0.6}],
	"razor-leaf#alt": ["spiral", {"n": 18, "k": 0.5}],
	"leaf-storm#alt": ["converge", {"n": 10, "k": 0.9}],
	"leaf-storm": ["tornado", {"n": 4, "r": 85, "k": 0.8}],
	"giga-drain": ["drainpulse", {"r": 140, "k": 1.1}],
	# ---- Veneno
	"sludge-bomb": ["splash", {"n": 5, "r": 44, "k": 0.9}],
	"cross-poison": ["crosscut", {"k": 1.6}],
	"poison-jab": ["jabs", {"n": 4, "k": 0.9}],
	"sludge-wave": ["wall", {"n": 5, "k": 0.9}],
	"sludge": ["splash", {"n": 3, "r": 40, "k": 0.8}],
	"poison-sting": ["swarm", {"n": 8, "k": 0.4}],
	"toxic": ["spore", {"r": 120, "k": 0.4}],
	"toxic#alt": ["bloom", {"r": 150, "k": 0.6}],
	"toxic-spikes": ["crossmines", {"n": 5, "k": 1.0}],
	# ---- Tierra
	"drill-run": ["jabs", {"n": 3, "k": 1.3}],
	"scorching-sands": ["sandtrap", {"r": 100, "k": 0.5}],
	"magnitude": ["shockchain", {"n": 4, "k": 0.9}],
	"mud-shot": ["spore", {"r": 110, "k": 0.5}],
	"bulldoze": ["slam", {"r": 130, "k": 1.6}],
	"bulldoze#alt": ["shockchain", {"n": 4, "k": 1.0}],
	"bonemerang": ["echo", {"n": 3, "r": 80, "k": 0.8}],
	"spikes": ["crossmines", {"n": 6, "k": 0.9}],
	# ---- Hielo
	"aurora-beam": ["prism", {"k": 1.3}],
	"freeze-dry": ["snapfreeze", {"r": 120, "k": 2.0}],
	"ice-ball": ["pinball", {"k": 1.0}],
	"ice-burn": ["implode", {"r": 130, "k": 2.2}],
	"ice-hammer": ["slam", {"r": 100, "k": 2.2}],
	"icicle-spear": ["converge", {"n": 8, "k": 0.8}],
	"ice-beam": ["snapfreeze", {"r": 150, "k": 1.6}],
	"powder-snow": ["stasis", {"r": 170, "k": 0.6}],
	"hail": ["starfall", {"n": 8, "r": 46, "k": 0.9}],
	# ---- Normal
	"egg-bomb": ["splash", {"n": 4, "r": 50, "k": 1.0}],
	"milk-drink": ["bloom", {"r": 120, "k": 0.2}],
	"pay-day": ["coins", {"n": 4, "k": 0.6}],
	"slash": ["crosscut", {"k": 1.8}],
	"hyper-beam": ["comet", {"k": 3.2}],
	"tackle": ["slam", {"r": 90, "k": 1.8}],
	"quick-attack": ["blink", {"k": 1.4}],
	"body-slam": ["slam", {"r": 120, "k": 2.2}],
	"hyper-voice": ["pulses", {"n": 3, "r": 190, "k": 0.7}],
	"substitute": ["clone", {"n": 1}],
	# ---- Oscuro
	"sucker-punch": ["blink", {"k": 1.8}],
	"bite": ["jabs", {"n": 3, "k": 1.4}],
	"dark-pulse": ["pulses", {"n": 3, "r": 170, "k": 0.8}],
	"night-shade": ["stasis", {"r": 160, "k": 0.8}],
	# ---- Psiquico
	"mist-ball": ["spore", {"r": 130, "k": 0.5}],
	"psyshock": ["swarm", {"n": 5, "k": 0.9}],
	"psystrike": ["crossbeam", {"k": 1.4}],
	"confusion": ["arcing", {"k": 0.8}],
	"psybeam": ["prism", {"k": 0.9}],
	"psychic": ["recast", {}],
	"psycho-cut": ["arcing", {"k": 1.1}],
	"swords-dance": ["spin", {"n": 6, "k": 1.0}],
	"agility": ["blink", {"k": 2.2}],
	"harden": ["shell", {"r": 95, "k": 1.1}],
	"aqua-ring": ["bloom", {"r": 140, "k": 0.5}],
	"dragon-dance": ["tornado", {"n": 4, "r": 115, "k": 0.9}],
	"hypnosis": ["stasis", {"r": 170, "k": 0.7}],
	"dream-eater": ["leech", {"n": 5}],
	# ---- Roca
	"stealth-rock": ["crossmines", {"n": 6, "k": 1.1}],
	"stone-axe": ["slam", {"r": 105, "k": 2.3}],
	"stone-edge": ["pillars", {"n": 7, "r": 40, "k": 1.2}],
	"rock-throw": ["shatterbomb", {"n": 5, "k": 0.7}],
	"rock-slide": ["starfall", {"n": 7, "r": 50, "k": 1.0}],
	# ---- Acero
	"anchor-shot": ["yank", {"n": 4, "k": 1.5}],
	"behemoth-blade": ["comet", {"k": 2.8}],
	"metal-claw": ["crosscut", {"k": 1.6}],
	"flash-cannon": ["prism", {"k": 1.0}],
	"meteor-mash": ["implode", {"r": 120, "k": 2.0}],
	# ---- Agua
	"crabhammer": ["slam", {"r": 100, "k": 2.2}],
	"octazooka": ["splash", {"n": 4, "r": 46, "k": 0.9}],
	"whirlpool": ["vortex", {"r": 130, "k": 1.6}],
	"water-gun": ["pinball", {"k": 0.9}],
	"bubble": ["pulses", {"n": 3, "r": 180, "k": 0.6}],
	"hydro-pump": ["comet", {"k": 2.4}],
	"bubble-beam": ["swarm", {"n": 6, "k": 0.5}],
	# ---- Bicho
	"bug-bite": ["crosscut", {"k": 1.5}],
	"string-shot": ["stunzone", {"r": 120, "k": 0.4}],
	"bug-buzz": ["swarm", {"n": 9, "k": 0.4}],
}


func _init(main = null) -> void:
	M = main


func _p() -> Vector2:
	return M.player.position


func _aim() -> float:
	return M.player.aim


func _tpos(m: Dictionary, reach: float = 340.0) -> Vector2:
	return M._p_target_pos(reach, _p() + Vector2.from_angle(_aim()) * 150.0)


func _puff(pos: Vector2, m: Dictionary, n: int = 12) -> void:
	M.evfx.puff(pos, m, n)


# ------------------------------------------------------------------ disparo
func cast(m: Dictionary) -> void:
	var key: String = String(m["id"]) + ("#alt" if bool(m.get("alt", false)) else "")
	if not SIG.has(key):
		return
	if M.run_time < float(m.get("_evn", 0.0)):
		return
	if M._nearest_enemy(_p(), 380.0) == null:
		return   # sin enemigos cerca no gasta la recarga
	var s: Array = SIG[key]
	var p: Dictionary = s[1]
	m["_evn"] = M.run_time + float(p.get("cd", 2.4))
	call("a_" + String(s[0]), m, p)


# ------------------------------------------------------------------ habilidades
# Eco: el ataque se repite dos veces en el mismo sitio, como un fantasma
func a_echo(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var n: int = int(p.get("n", 2))
	for i in range(n):
		M._later(0.5 * float(i + 1), func():
			M._p_hit_circle(pos, float(p.get("r", 90)), m, float(p.get("k", 1.0)))
			_puff(pos, m, 14))


# Vortice: pozo de gravedad en el blanco que implosiona al final
func a_vortex(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	var r: float = float(p.get("r", 120))
	M._p_zone(t, r, 2.2, 0.3, m, float(p.get("k", 1.5)) * 0.25, 140.0)
	M._later(2.2, func():
		M._p_hit_circle(t, r * 1.2, m, float(p.get("k", 1.5)) * 1.8)
		_puff(t, m, 22)
		M.shake = maxf(M.shake, 4.0))


# Marca: señala enemigos y explotan en cadena un instante despues
func a_mark(m: Dictionary, p: Dictionary) -> void:
	var ts: Array = M._p_targets(int(p.get("n", 4)), 360.0)
	var i := 0
	for e in ts:
		M._p_tele(e.position, 46.0, m, 0.9)
		M._later(0.9 + 0.12 * float(i), func():
			if is_instance_valid(e) and not e.dead:
				M._p_hit_circle(e.position, float(p.get("r", 70)), m, float(p.get("k", 1.8)))
				_puff(e.position, m, 12))
		i += 1


# Pilares: columnas que brotan en fila hacia delante
func a_pillars(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var d: Vector2 = Vector2.from_angle(_aim())
	var n: int = int(p.get("n", 6))
	for i in range(n):
		var at: Vector2 = pos + d * (50.0 + 34.0 * float(i))
		M._later(0.07 * float(i), func():
			M._p_hit_circle(at, float(p.get("r", 44)), m, float(p.get("k", 1.2)))
			_puff(at, m, 10))


# Espiral: tres brazos de proyectiles que giran
func a_spiral(m: Dictionary, p: Dictionary) -> void:
	var n: int = int(p.get("n", 14))
	var a0: float = _aim()
	for i in range(n):
		M._later(0.045 * float(i), func():
			if M.player.dead:
				return
			for arm in range(3):
				M._p_bullet(m, a0 + float(i) * 0.5 + float(arm) * TAU / 3.0, 250.0, 0.75, 1, 5.0, float(p.get("k", 0.5))))


# Lluvia: rayos que caen sobre enemigos al azar
func a_rain(m: Dictionary, p: Dictionary) -> void:
	var n: int = int(p.get("n", 5))
	var ts: Array = M._p_targets(10, 360.0)
	ts.shuffle()
	for i in range(mini(n, ts.size())):
		var e = ts[i]
		M._p_tele(e.position, 34.0, m, 0.35)
		M._later(0.35 + 0.1 * float(i), func():
			if is_instance_valid(e) and not e.dead:
				M._p_hit_circle(e.position, float(p.get("r", 54)), m, float(p.get("k", 1.2)))
				_puff(e.position, m, 10))


# Grieta: linea que parte el suelo y deja zonas que frenan
func a_rift(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var a: float = _aim()
	var d: Vector2 = Vector2.from_angle(a)
	M._p_hit_line(pos, a, 330.0, 40.0, m, float(p.get("k", 1.2)))
	for i in range(int(p.get("n", 5))):
		var at: Vector2 = pos + d * (50.0 + 56.0 * float(i))
		M._later(0.05 * float(i), func():
			M._p_zone(at, 36.0, 2.6, 0.4, m, 0.3)
			_puff(at, m, 8))


# Tiro de espaldas: dispara tambien hacia atras
func a_backshot(m: Dictionary, p: Dictionary) -> void:
	for off in [-0.35, 0.0, 0.35]:
		M._p_bullet(m, _aim() + PI + off, 320.0, 0.9, 2, 7.0, float(p.get("k", 1.0)))


# Pulsos: ondas expansivas sucesivas
func a_pulses(m: Dictionary, p: Dictionary) -> void:
	for i in range(int(p.get("n", 3))):
		M._later(0.3 * float(i), func():
			M._p_wave(m, 10.0, float(p.get("r", 180)), 0.5, 16.0, float(p.get("k", 0.8))))


# Congelacion instantanea y rotura
func a_snapfreeze(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 120))
	for e in M.enemies:
		if not e.dead and e.position.distance_to(pos) <= r:
			e.frozen_t = maxf(e.frozen_t, 1.2)
	M._ring(pos, 10.0, r, M._col(m), 0.4)
	M._later(1.2, func():
		M._p_hit_circle(pos, r, m, float(p.get("k", 2.0)))
		_puff(pos, m, 26)
		M.shake = maxf(M.shake, 4.0))


# Lluvia de meteoros alrededor del blanco
func a_starfall(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	var n: int = int(p.get("n", 6))
	for i in range(n):
		var at: Vector2 = t + Vector2.from_angle(float(i) / float(n) * TAU) * (30.0 + 60.0 * float(i % 2))
		var f = M._new_field("meteor", m, at)
		f.t = -0.1 * float(i)
		f.fall = 0.5
		f.r = float(p.get("r", 56))
		f.dmg = M._pk(m, float(p.get("k", 1.0)))


# Salto relampago al enemigo mas cercano y golpe en area
func a_blink(m: Dictionary, p: Dictionary) -> void:
	var ts: Array = M._p_targets(1, 300.0)
	if ts.size() == 0:
		return
	var e = ts[0]
	var dir: Vector2 = (e.position - _p()).normalized()
	M._ring(_p(), 4.0, 40.0, M._col(m), 0.25)
	M.player.position = e.position - dir * 26.0
	M.player.invuln = maxf(M.player.invuln, 0.35)
	M._p_hit_circle(e.position, 80.0, m, float(p.get("k", 2.0)))
	_puff(e.position, m, 16)
	M.shake = maxf(M.shake, 3.0)


# Arcos: salta entre varios enemigos
func a_arcs(m: Dictionary, p: Dictionary) -> void:
	var cur = M._nearest_enemy(_p(), 340.0)
	var done := {}
	var from: Vector2 = _p() + Vector2(0.0, -18.0)
	for i in range(int(p.get("n", 4))):
		if cur == null:
			break
		done[cur.get_instance_id()] = true
		var to: Vector2 = cur.position + Vector2(0.0, -cur.body_h * 0.5)
		M.pfx.beam(from, (to - from).angle(), (to - from).length(), 8.0, M._vis(m))
		M._hit_move(cur, M._pk(m, float(p.get("k", 1.0))), to - from, m)
		from = to
		var best = null
		var bd: float = 170.0 * 170.0
		for e in M.enemies:
			if e.dead or done.has(e.get_instance_id()):
				continue
			var d2: float = cur.position.distance_squared_to(e.position)
			if d2 < bd:
				bd = d2
				best = e
		cur = best


# Nube: zona que confunde y frena
func a_spore(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	var r: float = float(p.get("r", 120))
	M._p_zone(t, r, 3.0, 0.5, m, float(p.get("k", 0.4)))
	for i in range(5):
		M._later(0.5 * float(i), func():
			for e in M.enemies:
				if not e.dead and e.position.distance_to(t) <= r:
					e.conf_t = maxf(e.conf_t, 1.0)
			_puff(t + Vector2(randf_range(-r, r) * 0.6, randf_range(-r, r) * 0.3), m, 6))


# Aturdir en area
func a_stunzone(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 130))
	M._p_zone(pos, r, 2.5, 0.5, m, float(p.get("k", 0.5)))
	for e in M.enemies:
		if not e.dead and e.position.distance_to(pos) <= r:
			e.para_t = maxf(e.para_t, 1.4)
	_puff(pos, m, 18)


# Minas en cruz alrededor
func a_crossmines(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var n: int = int(p.get("n", 5))
	var a0: float = randf() * TAU
	for i in range(n):
		var at: Vector2 = pos + Vector2.from_angle(a0 + float(i) / float(n) * TAU) * 78.0
		var f = M._new_field("mine", m, at)
		f.arm = 0.3
		f.life = 7.0
		f.r = maxf(46.0, M._f(m, "radius", 50.0))
		f.dmg = M._pk(m, float(p.get("k", 1.0)))
	M._trim_fields("mine", 16)
	M._ring(pos, 10.0, 80.0, M._col(m), 0.3)


# Enjambre: proyectiles pequeños que persiguen
func a_swarm(m: Dictionary, p: Dictionary) -> void:
	var n: int = int(p.get("n", 6))
	var a0: float = _aim()
	for i in range(n):
		M._later(0.06 * float(i), func():
			if M.player.dead:
				return
			var b = M._p_bullet(m, a0 + randf_range(-1.2, 1.2), 210.0, 1.6, 1, 4.5, float(p.get("k", 0.6)))
			b.homing = 7.0)


# Arcos curvos: dos proyectiles que trazan una media luna
func a_arcing(m: Dictionary, p: Dictionary) -> void:
	for sgn in [-1.0, 1.0]:
		var b = M._p_bullet(m, _aim() + sgn * 0.7, 250.0, 1.5, 3, 8.0, float(p.get("k", 1.0)))
		b.turn = -sgn * 2.0


# Rebote: la bola rebota entre enemigos
func a_pinball(m: Dictionary, p: Dictionary) -> void:
	var b = M._p_bullet(m, _aim(), 340.0, 2.0, 0, 9.0, float(p.get("k", 1.0)))
	b.ric = 5


# Bomba de esquirlas: estalla en fragmentos al impactar
func a_shatterbomb(m: Dictionary, p: Dictionary) -> void:
	var b = M._p_bullet(m, _aim(), 260.0, 1.6, 0, 10.0, float(p.get("k", 0.8)) * 1.6)
	b.burst = int(p.get("n", 6))


# Estela: el proyectil deja zonas ardientes a su paso
func a_trailer(m: Dictionary, p: Dictionary) -> void:
	var b = M._p_bullet(m, _aim(), 190.0, 1.8, 99, 10.0, float(p.get("k", 0.5)))
	b.leave = "x"
	b.bm = m


# Golpe sismico: salto y aplastamiento con onda
func a_slam(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	M._p_tele(pos, float(p.get("r", 110)), m, 0.3)
	M._later(0.3, func():
		M._p_hit_circle(pos, float(p.get("r", 110)), m, float(p.get("k", 2.0)))
		M._p_wave(m, 10.0, float(p.get("r", 110)) * 1.7, 0.45, 16.0, float(p.get("k", 2.0)) * 0.4, false)
		_puff(pos, m, 24)
		M.shake = maxf(M.shake, 6.0))


# Ondas sismicas en cadena: anillos de impactos que se alejan
func a_shockchain(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	for j in range(int(p.get("n", 3))):
		M._later(0.22 * float(j), func():
			var rr: float = 70.0 + 55.0 * float(j)
			var cnt: int = 6 + 3 * j
			for i in range(cnt):
				var at: Vector2 = pos + Vector2.from_angle(float(i) / float(cnt) * TAU + float(j)) * rr
				M._p_hit_circle(at, 34.0, m, float(p.get("k", 1.0)), false)
				_puff(at, m, 3)
			M._ring(pos, rr * 0.8, rr, M._col(m), 0.3, 3.0))


# Flor: zona que cura al jugador
func a_bloom(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 110))
	M._p_zone(pos, r, 3.0, 0.5, m, float(p.get("k", 0.4)))
	for i in range(6):
		M._later(0.5 * float(i), func():
			if M.player.dead:
				return
			if M.player.position.distance_to(pos) <= r:
				var hl: float = M._heal_real(maxf(1.0, M.player.max_hp * 0.018))
				if hl > 0.0:
					M.add_text(M.player.position + Vector2(0.0, -M.player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 14)
			_puff(pos + Vector2(randf_range(-r, r) * 0.6, randf_range(-r, r) * 0.3), m, 5))


# Rayos cruzados
func a_crossbeam(m: Dictionary, p: Dictionary) -> void:
	for i in range(4):
		M._later(0.1 * float(i), func():
			M._p_beam(m, _aim() + float(i) * PI * 0.5, 300.0, 30.0, float(p.get("k", 1.4))))


# Rayos que giran como aspas
func a_rotbeams(m: Dictionary, p: Dictionary) -> void:
	var a0: float = _aim()
	for i in range(int(p.get("n", 6))):
		M._later(0.11 * float(i), func():
			if M.player.dead:
				return
			M._p_beam(m, a0 + float(i) * 0.6, 260.0, 20.0, float(p.get("k", 0.7))))


# Prisma: el rayo se abre en dos rayos laterales
func a_prism(m: Dictionary, p: Dictionary) -> void:
	var a0: float = _aim()
	M._later(0.15, func():
		for off in [-0.5, 0.5]:
			M._p_beam(m, a0 + off, 280.0, 22.0, float(p.get("k", 1.0)) * 0.7))


# Estasis: duerme a los enemigos cercanos (reciben mas daño)
func a_stasis(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 150))
	for e in M.enemies:
		if not e.dead and e.position.distance_to(pos) <= r and not e.boss:
			e.sleep_t = maxf(e.sleep_t, 1.5)
	M._p_wave(m, 10.0, r, 0.5, 18.0, float(p.get("k", 0.8)))
	_puff(pos, m, 18)


# Doble turno: el ataque se recarga casi al instante
func a_recast(m: Dictionary, p: Dictionary) -> void:
	m["t"] = 0.1
	M._ring(_p(), 6.0, 70.0, Color("#ffd23f"), 0.3)
	_puff(_p(), m, 14)


# Sanguijuelas: engancha enemigos y roba vida
func a_leech(m: Dictionary, p: Dictionary) -> void:
	for e in M._p_targets(int(p.get("n", 3)), 340.0):
		M._leeches.append({"e": e, "t": 4.0, "tk": 0.2, "m": m})


# Anillo de fuego: zonas en circulo alrededor
func a_ringfire(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var n: int = int(p.get("n", 6))
	for i in range(n):
		M._p_zone(pos + Vector2.from_angle(float(i) / float(n) * TAU) * 95.0, float(p.get("r", 38)), 2.5, 0.4, m, float(p.get("k", 0.5)))
	_puff(pos, m, 20)


# Caparazon: invulnerable un instante y repele
func a_shell(m: Dictionary, p: Dictionary) -> void:
	M.player.invuln = maxf(M.player.invuln, 0.8)
	M._p_wave(m, 10.0, float(p.get("r", 80)), 0.4, 18.0, float(p.get("k", 0.8)))
	M._p_wave(m, 10.0, float(p.get("r", 80)) * 1.5, 0.6, 18.0, float(p.get("k", 0.8)))
	_puff(_p(), m, 16)


# Tiron: arrastra enemigos hacia ti y los golpea
func a_yank(m: Dictionary, p: Dictionary) -> void:
	for e in M._p_targets(int(p.get("n", 4)), 340.0):
		if not e.boss:
			e.position = _p() + (e.position - _p()).normalized() * 46.0
		M._hit_move(e, M._pk(m, float(p.get("k", 1.4))), e.position - _p(), m)
		_puff(e.position, m, 8)


# Quemar a todos: aplica estado a todo el area
func a_burnall(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 170))
	for e in M.enemies:
		if not e.dead and e.position.distance_to(pos) <= r:
			M._hit_enemy(e, M._pk(m, float(p.get("k", 0.7))), M._col(m), e.position - pos, 0.0, String(m["type"]), 4, 0, 0.0)
	M._p_wave(m, 10.0, r, 0.45, 16.0, 0.1)
	_puff(pos, m, 22)


# Cometa: aviso y rayo gigante desde lejos
func a_comet(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var a: float = _aim()
	for i in range(3):
		M._later(0.12 * float(i), func(): M._p_warn(pos, a, 420.0, m))
	M._later(0.7, func():
		M._p_hit_line(pos, a, 430.0, 46.0, m, float(p.get("k", 2.6)))
		M.pfx.beam(pos + Vector2(0.0, -18.0), a, 430.0, 36.0, M._vis(m))
		M.shake = maxf(M.shake, 5.0))


# Torbellino: aros giratorios que protegen
func a_tornado(m: Dictionary, p: Dictionary) -> void:
	for i in range(int(p.get("n", 3))):
		M._later(0.25 * float(i), func():
			M._p_wave(m, 20.0, float(p.get("r", 90)), 0.6, 14.0, float(p.get("k", 0.8))))


# Jaula de rayos: haz alrededor
func a_cage(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var n: int = int(p.get("n", 6))
	for i in range(n):
		M._later(0.08 * float(i), func():
			var at: Vector2 = pos + Vector2.from_angle(float(i) / float(n) * TAU) * 100.0
			M.pfx.beam(pos + Vector2(0.0, -18.0), (at - pos).angle(), 100.0, 6.0, M._vis(m))
			M._p_hit_circle(at, 44.0, m, float(p.get("k", 1.2)), false)
			_puff(at, m, 6))


# Giro: cuchillada en cuatro direcciones con invulnerabilidad
func a_spin(m: Dictionary, p: Dictionary) -> void:
	M.player.invuln = maxf(M.player.invuln, 0.5)
	var a0: float = _aim()
	var n: int = int(p.get("n", 4))
	for i in range(n):
		M._later(0.08 * float(i), func():
			M._p_hit_arc(a0 + float(i) * TAU / float(n), 100.0, 1.4, m, float(p.get("k", 1.0))))


# Estocadas: serie de golpes hacia delante
func a_jabs(m: Dictionary, p: Dictionary) -> void:
	var a0: float = _aim()
	for i in range(int(p.get("n", 4))):
		M._later(0.09 * float(i), func():
			if M.player.dead:
				return
			M._p_hit_line(_p(), a0, 120.0 + 20.0 * float(i), 30.0, m, float(p.get("k", 1.0)))
			M.pfx.slash(_p() + Vector2(0.0, -10.0), a0 + randf_range(-0.2, 0.2), 90.0 + 20.0 * float(i), 1.0, M._vis(m)))


# Corte en X
func a_crosscut(m: Dictionary, p: Dictionary) -> void:
	var a0: float = _aim()
	for s in [-1.0, 1.0]:
		M._later(0.0 if s < 0.0 else 0.12, func():
			M.pfx.slash(_p() + Vector2(0.0, -10.0), a0 + s * 0.8, 130.0, 1.0, M._vis(m))
			M._p_hit_line(_p(), a0 + s * 0.7, 150.0, 40.0, m, float(p.get("k", 1.6))))


# Chapoteo: charcos que quedan en el suelo
func a_splash(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	for i in range(int(p.get("n", 4))):
		var at: Vector2 = t + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 80.0)
		M._later(0.1 * float(i), func():
			M._p_zone(at, float(p.get("r", 44)), 3.0, 0.45, m, float(p.get("k", 0.9)) * 0.4)
			_puff(at, m, 8))


# Muro: pared de zonas que avanza
func a_wall(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var d: Vector2 = Vector2.from_angle(_aim())
	var nrm: Vector2 = Vector2(-d.y, d.x)
	for i in range(int(p.get("n", 5))):
		var at: Vector2 = pos + d * 110.0 + nrm * (float(i) - 2.0) * 44.0
		M._p_zone(at, 40.0, 3.0, 0.4, m, float(p.get("k", 0.9)) * 0.5)
	_puff(pos + d * 110.0, m, 14)


# Arenas movedizas: zona que frena mucho y atrae
func a_sandtrap(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	M._p_zone(t, float(p.get("r", 100)), 3.5, 0.4, m, float(p.get("k", 0.5)), 70.0)
	_puff(t, m, 16)


# Implosion: se llevan a los enemigos al centro y estalla
func a_implode(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var r: float = float(p.get("r", 130))
	M._p_zone(pos, r, 0.9, 0.3, m, 0.1, 260.0)
	M._later(0.9, func():
		M._p_hit_circle(pos, r * 0.7, m, float(p.get("k", 2.0)))
		_puff(pos, m, 24)
		M.shake = maxf(M.shake, 5.0))


# Convergencia: proyectiles desde todos los lados al blanco
func a_converge(m: Dictionary, p: Dictionary) -> void:
	var t: Vector2 = _tpos(m)
	var n: int = int(p.get("n", 8))
	for i in range(n):
		var a: float = float(i) / float(n) * TAU
		var from: Vector2 = t + Vector2.from_angle(a) * 150.0
		M._later(0.05 * float(i), func():
			M._p_bullet(m, a + PI, 330.0, 0.5, 2, 5.5, float(p.get("k", 0.8)), from))


# Monedas: lluvia de dinero que ademas golpea
func a_coins(m: Dictionary, p: Dictionary) -> void:
	M.coins += int(p.get("n", 4))
	Aud.sfx("coin")
	M._p_radial(m, _p(), 10, 220.0, 0.6, float(p.get("k", 0.6)))
	_puff(_p(), m, 18)


# Doble: un señuelo dispara por ti
func a_clone(m: Dictionary, p: Dictionary) -> void:
	var f = M._new_field("turret", m, _p() + Vector2.from_angle(_aim() + PI * 0.5) * 40.0)
	f.life = 5.0
	f.shot_t = 0.2
	M._trim_fields("turret", 3)
	_puff(f.position, m, 14)


# Fuegos fatuos: bolas que orbitan y persiguen
func a_wisps(m: Dictionary, p: Dictionary) -> void:
	var n: int = int(p.get("n", 4))
	for i in range(n):
		var a: float = float(i) / float(n) * TAU
		var b = M._p_bullet(m, a, 120.0, 2.4, 2, 7.0, float(p.get("k", 0.8)))
		b.homing = 4.0
		b.turn = 2.2 if i % 2 == 0 else -2.2


# Pulso que cura por cada enemigo golpeado
func a_drainpulse(m: Dictionary, p: Dictionary) -> void:
	var pos: Vector2 = _p()
	var hits: int = M._p_hit_circle(pos, float(p.get("r", 140)), m, float(p.get("k", 1.1)))
	if hits > 0:
		var hl: float = M._heal_real(maxf(1.0, M.player.max_hp * 0.012 * float(mini(hits, 8))))
		if hl > 0.0:
			M.add_text(M.player.position + Vector2(0.0, -M.player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 16)
	M._p_wave(m, 10.0, float(p.get("r", 140)), 0.4, 14.0, 0.1)
