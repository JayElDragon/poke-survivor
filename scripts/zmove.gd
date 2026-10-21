extends RefCounted
# Movimientos Z: un ataque final por tipo (se recarga cada 4 minutos, desde el nivel 15). Cada uno tiene su propia coreografia.
# Se desbloquean al derrotar 250 Pokemon de ese tipo (logro "Rastreador de tipo").
const VFX = preload("res://scripts/vfx.gd")

const ORDER := ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
const NEED := 250
const COOLDOWN := 240.0   # 4 minutos desde que acaba el movimiento
const MIN_LEVEL := 1
const MIN_TIME := 180.0   # disponible desde el minuto 3
const CINE_T := 2.2
const DEF := {
	"normal": {"name": "Carrera Estelar", "desc": "Embistes tres veces a toda velocidad contra los enemigos, atravesando todo a tu paso."},
	"fire": {"name": "Hecatombe Pirotécnica", "desc": "Una lluvia de bolas de fuego cae sobre los enemigos."},
	"water": {"name": "Hidrovórtice Abisal", "desc": "Un vórtice gigante arrastra a los enemigos hacia el centro y una ola final los lanza lejos."},
	"electric": {"name": "Tormenta Gigavoltio", "desc": "Tres rayos saltan de enemigo en enemigo en cadena y los paralizan, cada vez más fuertes."},
	"grass": {"name": "Floración Cataclísmica", "desc": "Raíces inmovilizan a los enemigos, los estrangulan y al florecer te curan por cada uno."},
	"ice": {"name": "Cero Absoluto", "desc": "Congela a todos los enemigos de la pantalla y un golpe final los rompe a la vez."},
	"fighting": {"name": "Aplastamiento Total", "desc": "Te lanzas contra el enemigo más fuerte y le das una ráfaga de golpes con un gancho final devastador."},
	"poison": {"name": "Diluvio Ácido", "desc": "Charcos ácidos aparecen entre los enemigos y los envenenan mientras estén dentro."},
	"ground": {"name": "Furia Tectónica", "desc": "Grietas se abren desde ti en todas direcciones y aplastan a los que están sobre ellas."},
	"flying": {"name": "Picado Supersónico", "desc": "Desapareces en el cielo y caes en picado sobre el mayor grupo de enemigos."},
	"psychic": {"name": "Mente Quebrada", "desc": "Los enemigos quedan confundidos y se atacan entre ellos."},
	"bug": {"name": "Plaga Devastadora", "desc": "Un enjambre de insectos persigue por su cuenta a los enemigos, uno por objetivo."},
	"rock": {"name": "Alud Continental", "desc": "Una avalancha de rocas arrasa la pantalla de un lado a otro empujando todo a su paso."},
	"ghost": {"name": "Pesadilla Eterna", "desc": "Drenas las almas de los enemigos: pierden vida según su salud y tú te curas."},
	"dragon": {"name": "Cataclismo Dracónico", "desc": "Cuatro rayos dracónicos giran rapidísimo a tu alrededor mientras eres invencible."},
	"dark": {"name": "Eclipse Abismal", "desc": "La oscuridad se cierra sobre ti en un círculo que se contrae y termina en una implosión."},
	"steel": {"name": "Taladro Metálico", "desc": "Perforas en línea recta a través de todo con un taladro de acero y rematas con una explosión."},
	"fairy": {"name": "Destello Ensueño", "desc": "Duermes a todos los enemigos y te curas; al final devoras sus sueños y recibes más cura por cada uno."},
}

static func unlocked(type: String, stats: Dictionary) -> bool:
	return int(stats.get("tk_" + type, 0)) >= NEED or int(stats.get("zcr_" + type, 0)) >= 1   # 250 derrotados o cristal del gacha



# Fuego fatuo: bola de fuego flotante con llama que ondula, estela de brasas y nucleo claro (estilo Fuego Fatuo).
class Wisp extends Node2D:
	var life := 0.0
	var sd := randf() * 10.0
	var home: Node2D = null        # el Pokemon alrededor del que orbita
	var ang := 0.0
	var rad := 70.0
	var t_spawn := 0.0
	var t_go := 1.0                # cuando sale disparado
	var dash := 0.5
	var to := Vector2.ZERO
	var from := Vector2.ZERO
	var ctrl := Vector2.ZERO
	var launched := false
	var cb: Callable
	var trail: Array = []
	var sz := 1.0
	var vel := Vector2.ZERO

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		z_index = 30

	func _process(d: float) -> void:
		life += d
		var grow: float = clampf(life / 0.35, 0.0, 1.0)
		sz = grow
		var prev: Vector2 = position
		if life < t_go:
			ang += d * (2.6 + 0.8 * clampf(life / t_go, 0.0, 1.0))
			var hv: float = sin(life * 3.0 + sd) * 8.0
			var rr: float = rad * (0.4 + 0.6 * grow)
			var cpos: Vector2 = home.position if home != null and is_instance_valid(home) else position
			position = cpos + Vector2(cos(ang) * rr, sin(ang) * rr * 0.55 - 46.0 + hv)
		else:
			if not launched:
				launched = true
				from = position
				var mid: Vector2 = (from + to) * 0.5
				var nrm: Vector2 = (to - from).orthogonal().normalized()
				ctrl = mid + nrm * randf_range(-120.0, 120.0) + Vector2(0.0, -90.0)
			var k: float = clampf((life - t_go) / dash, 0.0, 1.0)
			var e: float = k * k
			position = (1.0 - e) * (1.0 - e) * from + 2.0 * (1.0 - e) * e * ctrl + e * e * to
			if k >= 1.0:
				if cb.is_valid():
					cb.call()
				queue_free()
				return
		vel = (position - prev) / maxf(d, 0.0001)
		trail.push_front(position)
		if trail.size() > 14:
			trail.pop_back()
		queue_redraw()

	func _draw() -> void:
		var flick: float = 0.88 + 0.12 * sin(life * 17.0 + sd) + 0.06 * sin(life * 29.0 + sd * 2.0)
		var r: float = 12.0 * sz * flick
		var sp: float = vel.length()
		var back: Vector2 = (-vel.normalized()) if sp > 40.0 else Vector2(0.0, 1.0)
		# estela de brasas
		for i in range(trail.size()):
			var tp: Vector2 = to_local(trail[i])
			var f: float = 1.0 - float(i) / float(trail.size())
			draw_circle(tp, r * (0.25 + 0.6 * f), Color(1.0, 0.45, 0.1, 0.22 * f))
		# resplandor
		draw_circle(Vector2.ZERO, r * 2.4, Color(1.0, 0.3, 0.05, 0.06))
		draw_circle(Vector2.ZERO, r * 1.7, Color(1.0, 0.4, 0.08, 0.10))
		# llama: gota con punta hacia atras (o hacia arriba si flota)
		var up: Vector2 = back if sp > 40.0 else Vector2(0.0, -1.0)
		var side: Vector2 = up.orthogonal()
		var layers: Array = [[1.0, Color(0.9, 0.18, 0.04, 0.6)], [0.78, Color(1.0, 0.45, 0.08, 0.7)], [0.52, Color(1.0, 0.78, 0.3, 0.8)], [0.3, Color(1.0, 0.97, 0.85, 0.95)]]
		for ly in layers:
			var k2: float = float(ly[0])
			var pts := PackedVector2Array()
			for j in range(14):
				var a: float = TAU * float(j) / 14.0
				var base: Vector2 = Vector2.from_angle(a) * r * k2
				pts.append(base)
			draw_colored_polygon(pts, ly[1])
			# lengua de fuego ondulante
			var tip: Vector2 = up * (r * (2.1 + 0.5 * sin(life * 13.0 + sd + k2 * 3.0)) * k2 + (r * 0.8 if sp > 40.0 else 0.0)) + side * sin(life * 9.0 + sd) * r * 0.25
			draw_colored_polygon(PackedVector2Array([side * r * k2 * 0.85, tip, -side * r * k2 * 0.85]), ly[1])
		# chispas
		for i in range(4):
			var ph: float = fposmod(life * 1.4 + float(i) * 0.25 + sd, 1.0)
			draw_circle(up * (r * 1.2 + ph * 40.0) + side * sin(float(i) * 5.0 + life * 4.0) * 10.0, 2.0 * (1.0 - ph), Color(1.0, 0.8, 0.3, 1.0 - ph))

var m
var type := ""
var pal := ""
var t := 0.0
var dur := 3.0
var ev: Array = []
var c := Vector2.ZERO
var dmg := 0.0
var done := false
var acc := 0.0
var acc2 := 0.0
var dim := 0.0
var st := {}


func start(main, ty: String) -> void:
	m = main
	type = ty
	pal = ty
	c = m.player.position
	t = 0.0
	acc = 0.0
	acc2 = 0.0
	dim = 0.0
	st = {}
	ev = []
	done = false
	dmg = (100.0 + 24.0 * float(m.player.level)) * m._atk()
	_plan()


func col(i: int) -> Color:
	return VFX.pc(pal, i)


func at(time: float, f: Callable) -> void:
	ev.append([time, f, false])


func tick(delta: float) -> void:
	t += delta
	m.player.invuln = maxf(m.player.invuln, 0.3)
	for e in ev:
		if not bool(e[2]) and t >= float(e[0]):
			e[2] = true
			(e[1] as Callable).call()
	_cont(delta)
	if t >= dur:
		done = true
		m.player.visible = true


func rpos(rmax: float, rmin: float = 40.0) -> Vector2:
	return c + Vector2.from_angle(randf() * TAU) * randf_range(rmin, rmax)


# Posicion de un enemigo cercano (al azar entre los mas proximos) o un punto al azar.
func tpos(rmax: float = 460.0) -> Vector2:
	var l: Array = []
	for e in m.enemies:
		if not e.dead and e.position.distance_to(c) < rmax:
			l.append(e)
	if l.is_empty():
		return rpos(rmax * 0.7)
	l.sort_custom(func(a, b): return a.position.distance_squared_to(c) < b.position.distance_squared_to(c))
	return (l[randi() % mini(l.size(), 10)]).position


# Tope contra jefes: un Z no puede quitarles mas del BOSS_CAP de su vida maxima en total.
const BOSS_CAP := 0.28


func zhit(e, amount: float, d: Vector2, knock: float = 0.0, poison: int = 0, slow: float = 0.0, cc: String = "") -> void:
	if not e.boss:
		m._hit_enemy(e, amount, col(3), d, knock, type, 0, poison, slow, cc, 1.0 if cc != "" else 0.0)
		return
	var key: String = "bs_" + str(e.get_instance_id())
	var spent: float = float(st.get(key, 0.0))
	var room: float = maxf(0.0, BOSS_CAP * e.max_hp - spent)
	var before: float = e.hp
	m._hit_enemy(e, amount, col(3), d, knock, type, 0, poison, slow, cc, 1.0 if cc != "" else 0.0)
	var lost: float = maxf(0.0, before - e.hp)
	if lost > room:
		e.hp = minf(e.max_hp, e.hp + (lost - room))   # devuelve el exceso: el tope cuenta tras los multiplicadores
		lost = room
	st[key] = spent + lost


func hit(p: Vector2, r: float, k: float = 1.0, knock: float = 0.0, cc: String = "", poison: int = 0, slow: float = 0.0) -> void:
	for e in m.enemies.duplicate():
		if e.dead:
			continue
		if e.position.distance_to(p) <= r + e.radius * 0.5:
			var d: Vector2 = (e.position - p).normalized()
			zhit(e, dmg * k, d, knock, poison, slow, cc)


func boom(p: Vector2, r: float, shake: float = 3.0) -> void:
	m.pfx.ring(p, r * 0.15, r, col(3), 0.38, 4.0)
	m.pfx.burst(p, col(2), 16, 170.0)
	m.pfx.sp("impact", pal, p, {"life": 0.26, "scale": clampf(r / 45.0, 1.2, 4.0), "fr": 12.0, "fade": false})
	m.shake = maxf(m.shake, shake)


# Un objeto cae del cielo hasta p y al llegar ejecuta f.
func fall(shape: String, p: Vector2, h: float, tt: float, scl: float, f: Callable) -> void:
	var off: float = randf_range(-60.0, 60.0)
	m.pfx.sp(shape, pal, p + Vector2(off, -h), {"v": Vector2(-off / tt, h / tt), "life": tt, "scale": scl, "spin": randf_range(-6.0, 6.0) if VFX.spins(shape) else 0.0, "fade": false})
	m.pfx.sp("shadow", "dark", p, {"life": tt, "scale": 0.8})
	at(t + tt, f)


func ring_burst(shape: String, n: int, r0: float, speed: float, life: float, scl: float = 1.4) -> void:
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		m.pfx.sp(shape, pal, c + Vector2.from_angle(a) * r0, {"v": Vector2.from_angle(a) * speed, "life": life, "scale": scl, "angle": a, "spin": 4.0 if VFX.spins(shape) else 0.0})


# ---------------- utilidades de los Z ----------------
func near(p: Vector2, r: float) -> Array:
	var l: Array = []
	for e in m.enemies:
		if not e.dead and e.position.distance_to(p) <= r:
			l.append(e)
	return l


func hit_one(e, k: float, knock: float = 0.0, cc: String = "", poison: int = 0, slow: float = 0.0, from: Vector2 = Vector2.INF) -> void:
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var o: Vector2 = c if from == Vector2.INF else from
	var d: Vector2 = (e.position - o).normalized()
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	zhit(e, dmg * k, d, knock, poison, slow, cc)


func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 0.01:
		return p.distance_to(a)
	var tt: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * tt)


# Golpea a lo que toque el segmento a-b (una vez por enemigo mientras siga en `seen`).
func hit_seg(a: Vector2, b: Vector2, w: float, k: float, knock: float = 0.0, cc: String = "", seen: Dictionary = {}, poison: int = 0, slow: float = 0.0) -> int:
	var n := 0
	for e in m.enemies.duplicate():
		if e.dead:
			continue
		var id: int = e.get_instance_id()
		if seen.has(id):
			continue
		if seg_dist(e.position, a, b) <= w + e.radius * 0.5:
			seen[id] = true
			hit_one(e, k, knock, cc, poison, slow, a)
			n += 1
	return n


# Punto donde hay mas enemigos juntos.
func densest(rmax: float = 520.0) -> Vector2:
	var l: Array = near(c, rmax)
	if l.is_empty():
		return c + Vector2.from_angle(randf() * TAU) * 220.0
	var best: Vector2 = l[0].position
	var bn := -1
	for e in l:
		var n := 0
		for o in l:
			if o.position.distance_squared_to(e.position) < 25600.0:
				n += 1
		if n > bn:
			bn = n
			best = e.position
	return best


func heal(frac: float) -> void:
	m.player.hp = minf(m.player.max_hp, m.player.hp + m.player.max_hp * frac)


func heal_text(total: float) -> void:
	m.add_text(m.player.position + Vector2(0.0, -m.player.body_h - 8.0), "+%d" % roundi(m.player.max_hp * total), Color("#7dffb0"), 22)


func move_to(p: Vector2) -> void:
	m.player.position = m._collide(p, m.player.radius * 0.5)


func chain_from(first, used: Dictionary, maxn: int, reach: float) -> Array:
	var out: Array = []
	var cur = first
	while cur != null and out.size() < maxn:
		out.append(cur)
		used[cur.get_instance_id()] = true
		var best = null
		var bd: float = reach
		for e in m.enemies:
			if e.dead or used.has(e.get_instance_id()):
				continue
			var d: float = e.position.distance_to(cur.position)
			if d < bd:
				bd = d
				best = e
		cur = best
	return out


func start_dash(len_: float, speed: float, target: Vector2) -> void:
	var a: Vector2 = m.player.position
	var d: Vector2 = (target - a).normalized()
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	st["dash"] = {"a": a, "b": a + d * len_, "u": 0.0, "sp": speed / len_, "seen": {}}


func _plan() -> void:
	match type:
		"normal":
			# Tres embestidas a toda velocidad contra grupos distintos, atravesando todo
			dur = 2.9
			for i in range(3):
				at(0.15 + float(i) * 0.8, func():
					var tgt: Vector2 = tpos(520.0)
					start_dash(470.0, 1250.0, tgt))
			at(2.5, func():
				var p: Vector2 = m.player.position
				boom(p, 260.0, 8.0)
				m.pfx.ring(p, 30.0, 300.0, Color.WHITE, 0.4, 5.0)
				hit(p, 260.0, 1.4, 450.0))
		"fire":

			# Fuego fatuo: una corona de bolas de fuego flota alrededor del Pokemon y despues cada una se lanza contra un enemigo
			dur = 4.2
			var nw := 24
			for i in range(nw):
				at(0.08 + float(i) * 0.05, func():
					var w := Wisp.new()
					w.home = m.player
					w.ang = float(i) * 2.4
					w.rad = 120.0 + float(i % 3) * 38.0
					w.t_go = 1.5 + float(i) * 0.09 - (0.08 + float(i) * 0.05)
					w.position = m.player.position
					var p: Vector2 = tpos()
					w.to = p
					w.cb = func():
						boom(p, 95.0, 2.0)
						m.pfx.burst(p, col(3), 12, 200.0)
						hit(p, 100.0, 1.15, 160.0, "", 0)
					m.fx.add_child(w)
					)
		"water":
			# Un vortice que arrastra a todos hacia el centro y una ola final que los lanza
			dur = 3.6
			at(0.1, func():
				st["vortex"] = true
				m.pfx.ring(c, 520.0, 60.0, col(3), 0.7, 6.0))
			at(2.9, func():
				st["vortex"] = false
				m.pfx.ring(c, 30.0, 520.0, col(3), 0.7, 9.0)
				ring_burst("drop", 30, 30.0, 620.0, 0.7, 1.8)
				boom(c, 360.0, 10.0)
				hit(c, 400.0, 2.2, 700.0))
		"electric":
			# Tres cadenas de rayos que saltan de enemigo en enemigo y paralizan
			dur = 3.6
			var used := {}
			for ci in range(3):
				at(0.2 + float(ci) * 0.25, func():
					var pool: Array = near(c, 560.0)
					pool = pool.filter(func(e): return not used.has(e.get_instance_id()))
					if pool.is_empty():
						return
					pool.sort_custom(func(a, b): return a.position.distance_squared_to(c) < b.position.distance_squared_to(c))
					var first = pool[mini(ci * 3, pool.size() - 1)]
					var chain: Array = chain_from(first, used, 14, 300.0)
					var vis: Dictionary = VFX.for_move("thunderbolt", "electric")
					for j in range(chain.size()):
						at(t + float(j) * 0.1, func():
							var e = chain[j]
							if not is_instance_valid(e) or e.dead:
								return
							var to: Vector2 = e.position
							var from: Vector2 = to + Vector2(0.0, -520.0)
							if j > 0 and is_instance_valid(chain[j - 1]):
								from = chain[j - 1].position
							var dv: Vector2 = to - from
							m.pfx.beam(from, dv.angle(), dv.length(), 20.0, vis)
							boom(to, 70.0, 3.0)
							hit_one(e, 1.1 + 0.1 * float(j), 150.0, "para", 0, 0.0, from)))
		"grass":
			# Raices inmovilizan, estrangulan y al florecer curan por cada enemigo atrapado
			dur = 3.6
			at(0.2, func():
				st["roots"] = near(c, 600.0)
				m.pfx.ring(c, 20.0, 600.0, col(3), 0.6, 5.0)
				for e in st["roots"]:
					for j in range(5):
						m.pfx.slash(e.position, TAU * float(j) / 5.0, 44.0, 0.5, VFX.for_move("vine-whip", "grass")))
			for k in range(3):
				at(0.9 + float(k) * 0.6, func():
					for e in st.get("roots", []):
						if is_instance_valid(e) and not e.dead:
							hit_one(e, 0.5, 0.0)
							m.pfx.sp("leaf", pal, e.position, {"v": Vector2(randf_range(-60.0, 60.0), -80.0), "life": 0.6, "scale": 1.6, "spin": 6.0}))
			at(2.9, func():
				var n := 0
				for e in st.get("roots", []):
					if is_instance_valid(e) and not e.dead:
						n += 1
						if n <= 30:
							boom(e.position, 80.0, 1.5)
							m.pfx.burst(e.position, col(3), 10, 180.0)
						hit_one(e, 1.8, 120.0)
				var h: float = minf(0.25, 0.02 * float(n))
				heal(h)
				heal_text(h))
		"ice":
			# Congela a todos los enemigos y un golpe final los rompe a la vez
			dur = 3.8
			at(0.2, func():
				m.pfx.ring(c, 20.0, 760.0, col(4), 0.7, 10.0)
				ring_burst("star", 30, 30.0, 700.0, 0.8, 1.5)
				for e in near(c, 760.0):
					m._apply_cc(e, "freeze", 2.4))
			at(2.9, func():
				m.pfx.ring(c, 20.0, 800.0, Color.WHITE, 0.5, 10.0)
				var n := 0
				for e in near(c, 800.0):
					if e.frozen_t > 0.0:
						n += 1
						e.frozen_t = 0.0
						if n <= 30:
							boom(e.position, 70.0, 1.0)
							for j in range(3):
								m.pfx.sp("shard", pal, e.position, {"v": Vector2.from_angle(randf() * TAU) * 220.0, "life": 0.5, "scale": 2.0, "spin": 6.0})
						hit_one(e, 2.6, 120.0)
				m.shake = maxf(m.shake, 10.0))
		"fighting":
			# Duelo: saltas sobre el enemigo mas fuerte y le das una ronda de golpes con gancho final
			dur = 3.2
			at(0.05, func():
				var best = null
				var bh: float = -1.0
				for e in near(c, 560.0):
					var sc: float = e.max_hp * (10.0 if e.boss else 1.0)
					if sc > bh:
						bh = sc
						best = e
				st["tgt"] = best
				if best != null:
					m.pfx.ring(best.position, 200.0, 30.0, col(3), 0.4, 5.0))
			for i in range(22):
				at(0.35 + float(i) * 0.085, func():
					var e = st.get("tgt")
					if e == null or not is_instance_valid(e) or e.dead:
						var l: Array = near(m.player.position, 400.0)
						e = l[0] if not l.is_empty() else null
						st["tgt"] = e
					var p: Vector2 = e.position if e != null else tpos(300.0)
					m.pfx.sp("impact", pal, p + Vector2.from_angle(randf() * TAU) * 22.0, {"life": 0.18, "scale": 2.6, "fr": 12.0, "fade": false})
					m.pfx.burst(p, col(3), 6, 160.0)
					m.shake = maxf(m.shake, 3.0)
					if e != null:
						hit_one(e, 0.4, 40.0, "", 0, 0.0, m.player.position))
			at(2.5, func():
				var e = st.get("tgt")
				var p: Vector2 = e.position if (e != null and is_instance_valid(e) and not e.dead) else m.player.position
				m.pfx.sp("impact", pal, p, {"life": 0.5, "scale": 6.5, "fr": 12.0, "fade": false})
				boom(p, 220.0, 12.0)
				if e != null:
					hit_one(e, 4.0, 650.0, "", 0, 0.0, m.player.position)
				hit(p, 190.0, 1.0, 500.0))
		"poison":
			# Charcos acidos entre los enemigos: envenenan mientras estas dentro
			dur = 4.2
			st["pools"] = []
			for i in range(9):
				at(0.2 + float(i) * 0.28, func():
					var p: Vector2 = tpos(520.0)
					st["pools"].append({"p": p, "end": t + 2.5, "next": 0.0})
					m.pfx.ring(p, 10.0, 115.0, col(3), 0.5, 5.0)
					m.pfx.burst(p, col(3), 12, 150.0))
		"ground":
			# Grietas que salen de ti en todas direcciones y aplastan lo que hay sobre ellas
			dur = 3.4
			for w in range(3):
				at(0.2 + float(w) * 0.85, func():
					var base: float = randf() * TAU
					var seen := {}
					for j in range(5):
						var a: float = base + TAU * float(j) / 5.0
						m.pfx.beam(c, a, 600.0, 26.0, {"pal": "ground", "beam": ""})
						for q in range(9):
							var pp: Vector2 = c + Vector2.from_angle(a) * (50.0 + float(q) * 62.0)
							m.pfx.sp("rock", pal, pp, {"v": Vector2(randf_range(-30.0, 30.0), randf_range(-230.0, -120.0)), "life": 0.8, "scale": randf_range(1.4, 2.4), "grav": 520.0, "spin": randf_range(-6.0, 6.0)})
						hit_seg(c, c + Vector2.from_angle(a) * 600.0, 60.0, 2.6, 0.0, "", seen, 0, 0.6)
					m.shake = maxf(m.shake, 9.0)
					m.pfx.ring(c, 20.0, 300.0, col(3), 0.4, 6.0))
		"flying":
			# Desapareces en el cielo y caes en picado sobre el mayor grupo de enemigos
			dur = 2.8
			at(0.1, func():
				m.player.visible = false
				m.pfx.ring(c, 10.0, 90.0, col(4), 0.4, 5.0)
				ring_burst("wind", 12, 20.0, 380.0, 0.5, 1.6)
				st["air"] = true
				st["tp"] = densest(560.0))
			at(1.5, func():
				var tp: Vector2 = st["tp"]
				st["air"] = false
				move_to(tp)
				m.player.visible = true
				var p: Vector2 = m.player.position
				m.pfx.ring(p, 20.0, 380.0, col(4), 0.6, 9.0)
				ring_burst("wind", 24, 30.0, 620.0, 0.6, 2.0)
				boom(p, 320.0, 14.0)
				hit(p, 320.0, 4.2, 760.0))
		"psychic":
			# Enemigos confundidos que se atacan entre si
			dur = 3.6
			for k in range(6):
				at(0.2 + float(k) * 0.4, func():
					var r: float = 560.0
					m.pfx.ring(c, 20.0, r, col(2 + (k % 2)), 0.6, 5.0)
					for e in near(c, r):
						m._apply_cc(e, "conf", 1.6)
						hit_one(e, 0.28, 0.0))
			at(2.9, func():
				boom(c, 330.0, 6.0)
				for e in near(c, 560.0):
					hit_one(e, 0.9, 0.0, "conf"))
		"bug":
			# Un enjambre: cada insecto persigue a un enemigo distinto por su cuenta
			dur = 3.9
			st["bugs"] = []
			at(0.2, func():
				for j in range(16):
					var a: float = TAU * float(j) / 16.0
					st["bugs"].append({"p": c + Vector2.from_angle(a) * 40.0, "tgt": null, "ang": a, "seed": randf() * 10.0})
				for j in range(24):
					var a2: float = TAU * float(j) / 24.0
					m.pfx.sp("web", pal, c + Vector2.from_angle(a2) * 50.0, {"v": Vector2.from_angle(a2) * 220.0, "life": 0.7, "scale": 1.4, "spin": 3.0}))
		"rock":
			# Dos avalanchas que cruzan toda la pantalla, una en cada sentido
			dur = 4.0
			st["rolls"] = []
			for r in range(2):
				at(0.2 + float(r) * 1.9, func():
					var tgt: Vector2 = densest(560.0)
					var dv: Vector2 = (tgt - c).normalized()
					if dv == Vector2.ZERO:
						dv = Vector2.RIGHT
					if r == 1 and st.has("dir0"):
						dv = -st["dir0"]
					st["dir0"] = dv
					var perp := Vector2(-dv.y, dv.x)
					st["rolls"].append({"dir": dv, "perp": perp, "start": c - dv * 520.0, "t0": t, "seen": {}})
					m.pfx.ring(c, 10.0, 200.0, col(3), 0.5, 5.0))
		"ghost":
			# Drenaje de almas: dano segun la salud del enemigo y curacion para ti
			dur = 3.8
			st["heal"] = 0.0
			for k in range(8):
				at(0.3 + float(k) * 0.35, func():
					var p: Vector2 = m.player.position
					m.pfx.ring(p, 560.0, 40.0, col(3), 0.5, 5.0)
					var n := 0
					for e in near(c, 560.0):
						n += 1
						var extra: float = e.hp * 0.07
						zhit(e, dmg * 0.22 + extra, (p - e.position).normalized(), 0.0)
						if n <= 14:
							m.pfx.sp("shadow", pal, e.position, {"v": (p - e.position).normalized() * 520.0, "life": 0.5, "scale": 1.6})
						if st["heal"] < 0.18:
							st["heal"] += 0.006
							heal(0.006))
			at(3.2, func():
				heal_text(float(st["heal"]))
				boom(c, 360.0, 8.0)
				hit(c, 560.0, 1.1, 0.0))
		"dragon":
			# Cuatro rayos dracónicos giratorios mientras eres invencible
			dur = 3.8
		"dark":
			# La oscuridad se cierra: un circulo que se contrae y termina en una implosion
			dur = 3.6
			at(0.2, func(): st["ring"] = 580.0)
			at(2.8, func():
				st["ring"] = -1.0
				var p: Vector2 = m.player.position
				m.pfx.ring(p, 400.0, 10.0, col(4), 0.5, 12.0)
				boom(p, 300.0, 12.0)
				hit(p, 330.0, 3.0, 450.0))
		"steel":
			# Un taladro que perfora en linea recta, cada vez mas fuerte
			dur = 3.0
			at(0.2, func():
				var tgt: Vector2 = densest(560.0)
				start_dash(900.0, 640.0, tgt))
			at(2.2, func():
				var p: Vector2 = m.player.position
				ring_burst("shard", 24, 30.0, 560.0, 0.5, 2.0)
				boom(p, 260.0, 10.0)
				hit(p, 260.0, 2.4, 520.0))
		"fairy":
			# Duermes a todos, te curas y al final devoras sus sueños
			dur = 3.6
			st["heal"] = 0.0
			at(0.2, func():
				m.pfx.ring(c, 20.0, 620.0, col(3), 0.7, 7.0)
				for e in near(c, 620.0):
					m._apply_cc(e, "sleep", 1.5))
			at(2.9, func():
				var n := 0
				for e in near(c, 640.0):
					if e.sleep_t > 0.0:
						n += 1
						if n <= 26:
							m.pfx.sp("heart", pal, e.position, {"v": (m.player.position - e.position).normalized() * 380.0, "life": 0.6, "scale": 1.8})
						hit_one(e, 2.0, 80.0)
				var h: float = minf(0.2, 0.012 * float(n))
				heal(h)
				heal_text(h)
				boom(c, 380.0, 6.0))


# Efectos continuos (por fotograma) segun el tipo.
func _cont(delta: float) -> void:
	acc += delta
	acc2 += delta
	var p: Vector2 = m.player.position
	match type:
		"normal", "steel":
			var d = st.get("dash")
			if d != null:
				d["u"] = float(d["u"]) + delta * float(d["sp"])
				var u: float = minf(float(d["u"]), 1.0)
				var prev: Vector2 = m.player.position
				move_to((d["a"] as Vector2).lerp(d["b"], u))
				var now: Vector2 = m.player.position
				var kk: float = 1.5
				if type == "steel":
					kk = 0.7 + 1.3 * u
				if acc2 >= 0.0:
					# varias pasadas por segundo: cada enemigo puede volver a recibir
					if type == "steel":
						if acc >= 0.12:
							acc = 0.0
							(d["seen"] as Dictionary).clear()
						hit_seg(prev, now, 62.0, kk * 0.5, 160.0, "", d["seen"])
					else:
						hit_seg(prev, now, 78.0, kk, 280.0, "", d["seen"])
				var ang: float = ((d["b"] as Vector2) - (d["a"] as Vector2)).angle()
				if type == "normal":
					m.pfx.sp("streak", pal, now, {"life": 0.3, "scale": 2.4, "angle": ang, "fade": true})
					m.pfx.sp("star", pal, now + Vector2.from_angle(randf() * TAU) * 24.0, {"v": Vector2.from_angle(ang + PI) * 120.0, "life": 0.4, "scale": 1.4, "spin": 5.0})
				else:
					for j in range(3):
						var a: float = t * 14.0 + float(j) * TAU / 3.0
						m.pfx.beam(now, a, 120.0, 22.0, VFX.for_move("flash-cannon", "steel"))
					m.pfx.burst(now + Vector2.from_angle(ang) * 40.0, col(3), 4, 200.0)
					m.shake = maxf(m.shake, 3.0)
				if u >= 1.0:
					st.erase("dash")
		"water":
			if bool(st.get("vortex", false)):
				for e in near(c, 540.0):
					var dv: Vector2 = c - e.position
					var dist: float = dv.length()
					var tang := Vector2(-dv.y, dv.x).normalized()
					e.position += (dv.normalized() * 210.0 + tang * 90.0) * delta
				for i in range(3):
					var a: float = t * 6.0 + float(i) * TAU / 3.0
					var r: float = 80.0 + fposmod(t * 160.0 + float(i) * 140.0, 440.0)
					m.pfx.sp("drop", pal, c + Vector2.from_angle(a - r * 0.004) * r, {"v": Vector2.from_angle(a + PI / 2.0) * 160.0, "life": 0.35, "scale": 1.7})
				if acc2 >= 0.22:
					acc2 = 0.0
					m.pfx.ring(c, 20.0, 130.0, col(3), 0.3, 4.0)
					hit(c, 140.0, 0.38, 0.0)
					m.shake = maxf(m.shake, 3.0)
		"ice":
			if t < 2.9:
				for i in range(4):
					var q: Vector2 = p + Vector2(randf_range(-560.0, 560.0), randf_range(-380.0, 300.0))
					m.pfx.sp("star", pal, q, {"v": Vector2(randf_range(-40.0, 40.0), randf_range(90.0, 170.0)), "life": 0.9, "scale": randf_range(0.8, 1.6), "spin": 3.0})
		"grass":
			if t > 0.2 and t < 2.9:
				for e in st.get("roots", []):
					if is_instance_valid(e) and not e.dead:
						e.apply_slow(0.97, 0.25)
						if randf() < 0.05:
							m.pfx.sp("leaf", pal, e.position + Vector2(randf_range(-16.0, 16.0), 6.0), {"v": Vector2(0.0, -70.0), "life": 0.5, "scale": 1.4, "spin": 4.0})
		"fighting":
			var e = st.get("tgt")
			if e != null and is_instance_valid(e) and not e.dead and t > 0.1 and t < 2.9:
				move_to(e.position + Vector2(-48.0, 8.0))
				e.knock *= 0.5
		"poison":
			var pools: Array = st.get("pools", [])
			for pl in pools:
				if t > float(pl["end"]):
					continue
				var pp: Vector2 = pl["p"]
				if randf() < 0.6:
					m.pfx.sp("bubble", pal, pp + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 100.0), {"v": Vector2(0.0, randf_range(-80.0, -40.0)), "life": 0.7, "scale": randf_range(1.2, 2.4)})
				pl["next"] = float(pl["next"]) - delta
				if float(pl["next"]) <= 0.0:
					pl["next"] = 0.35
					m.pfx.ring(pp, 20.0, 110.0, col(3), 0.35, 3.0)
					hit(pp, 110.0, 0.38, 0.0, "", 2, 0.3)
			if t < 3.4:
				for i in range(2):
					m.pfx.sp("drop", pal, p + Vector2(randf_range(-520.0, 520.0), -360.0), {"v": Vector2(0.0, 560.0), "life": 0.65, "scale": 1.2, "fade": false})
		"ground":
			if t < 3.0:
				m.shake = maxf(m.shake, 4.0)
		"flying":
			if bool(st.get("air", false)):
				var tp: Vector2 = st.get("tp", c)
				m.pfx.sp("shadow", "dark", tp, {"life": 0.08, "scale": 1.0 + minf(2.0, (t - 0.1) * 1.6)})
				if t > 0.4 and acc2 >= 0.15:
					acc2 = 0.0
					m.pfx.ring(tp, 150.0, 40.0, col(4), 0.3, 3.0)
				for i in range(2):
					var a: float = t * 9.0 + float(i) * PI
					m.pfx.sp("wind", pal, c + Vector2.from_angle(a) * 50.0 + Vector2(0.0, -t * 120.0), {"v": Vector2(0.0, -200.0), "life": 0.4, "scale": 1.6, "spin": 6.0})
		"psychic":
			if t < 3.0:
				for i in range(2):
					var a: float = t * 3.0 + float(i) * PI
					var r: float = 60.0 + fposmod(t * 120.0 + float(i) * 200.0, 460.0)
					m.pfx.sp("ring", pal, c + Vector2.from_angle(a + r * 0.01) * r, {"life": 0.5, "scale": 1.6, "spin": 2.0})
		"bug":
			var bugs: Array = st.get("bugs", [])
			if t < 3.5:
				for b in bugs:
					var tg = b["tgt"]
					if tg == null or not is_instance_valid(tg) or tg.dead:
						var l: Array = near(b["p"], 800.0)
						if l.is_empty():
							b["tgt"] = null
							b["ang"] = float(b["ang"]) + 3.0 * delta
							b["p"] = (b["p"] as Vector2) + Vector2.from_angle(float(b["ang"])) * 200.0 * delta
							continue
						l.sort_custom(func(x, y): return x.position.distance_squared_to(b["p"]) < y.position.distance_squared_to(b["p"]))
						tg = l[randi() % mini(3, l.size())]
						b["tgt"] = tg
					var bp: Vector2 = b["p"]
					var dv: Vector2 = tg.position - bp
					var dist: float = dv.length()
					var wob := Vector2(-dv.y, dv.x).normalized() * sin(t * 18.0 + float(b["seed"])) * 120.0
					b["p"] = bp + (dv.normalized() * 600.0 + wob) * delta
					m.pfx.sp("needle", pal, b["p"], {"life": 0.22, "scale": 1.3, "angle": dv.angle()})
					if dist < 34.0:
						m.pfx.burst(tg.position, col(3), 6, 150.0)
						hit_one(tg, 0.7, 90.0, "", 1, 0.4, bp)
						b["tgt"] = null
		"rock":
			var rolls: Array = st.get("rolls", [])
			for ro in rolls:
				var u: float = (t - float(ro["t0"])) / 1.7
				if u < 0.0 or u > 1.0:
					continue
				var dv: Vector2 = ro["dir"]
				var perp: Vector2 = ro["perp"]
				var front: Vector2 = (ro["start"] as Vector2) + dv * (1040.0 * u)
				for i in range(-5, 6):
					var bp: Vector2 = front + perp * float(i) * 78.0 + dv * sin(float(i) * 1.7) * 18.0
					m.pfx.sp("rock", pal, bp, {"life": 0.09, "scale": 3.8, "spin": 4.0, "fade": false})
					if randf() < 0.15:
						m.pfx.sp("rock", pal, bp, {"v": -dv * 100.0 + Vector2(0.0, -120.0), "life": 0.5, "scale": 1.5, "grav": 420.0, "spin": 5.0})
					for e in near(bp, 80.0):
						var id: int = e.get_instance_id()
						if t - float((ro["seen"] as Dictionary).get(id, -9.0)) > 0.45:
							(ro["seen"] as Dictionary)[id] = t
							hit_one(e, 1.3, 380.0, "", 0, 0.0, bp - dv * 60.0)
				m.shake = maxf(m.shake, 5.0)
		"ghost":
			if t < 3.3:
				for i in range(3):
					var a: float = randf() * TAU
					var d: Vector2 = Vector2.from_angle(a)
					m.pfx.sp("shadow", pal, p + d * 420.0, {"v": -d * 330.0, "life": 1.05, "scale": randf_range(1.2, 2.2)})
		"dragon":
			if t < 3.6:
				for j in range(4):
					var a: float = t * 3.4 + float(j) * PI / 2.0
					if acc2 >= 0.1:
						m.pfx.beam(p, a, 540.0, 30.0, VFX.for_move("dragon-rage", "dragon"))
				if acc2 >= 0.1:
					acc2 = 0.0
					var seen := {}
					for j in range(4):
						var a2: float = t * 3.4 + float(j) * PI / 2.0
						hit_seg(p, p + Vector2.from_angle(a2) * 540.0, 46.0, 0.75, 140.0, "", seen)
					m.shake = maxf(m.shake, 3.0)
		"dark":
			var rr: float = float(st.get("ring", -1.0))
			if rr > 0.0:
				var k: float = clampf((t - 0.2) / 2.6, 0.0, 1.0)
				var R: float = lerpf(580.0, 90.0, k)
				st["R"] = R
				dim = 0.5 * minf(1.0, (t - 0.2) / 0.4)
				for i in range(5):
					var a: float = randf() * TAU
					m.pfx.sp("crescent", pal, c + Vector2.from_angle(a) * R, {"v": Vector2.from_angle(a + PI * 0.5) * 120.0, "life": 0.35, "scale": 1.8, "angle": a + PI})
				for e in near(c, R + 80.0):
					var dd: float = e.position.distance_to(c)
					if dd > R - 60.0:
						e.position += (c - e.position).normalized() * 230.0 * delta
						e.apply_slow(0.5, 0.3)
				if acc2 >= 0.3:
					acc2 = 0.0
					m.pfx.ring(c, R, R - 24.0, col(3), 0.3, 6.0)
					for e in near(c, R + 70.0):
						if e.position.distance_to(c) > R - 70.0:
							hit_one(e, 0.5, 0.0)
			elif t > 2.8:
				dim = maxf(0.0, dim - delta * 1.2)
		"fairy":
			if t < 3.0:
				for i in range(3):
					var q: Vector2 = c + Vector2(randf_range(-420.0, 420.0), randf_range(-320.0, 320.0))
					m.pfx.sp("star", pal, q + Vector2(0.0, -200.0), {"v": Vector2(0.0, 340.0), "life": 0.6, "scale": randf_range(1.2, 2.2), "spin": 5.0})
				if t > 0.3 and t < 2.8 and acc2 >= 0.25:
					acc2 = 0.0
					heal(0.012)
					st["heal"] = float(st.get("heal", 0.0)) + 0.012
					m.pfx.sp("heart", pal, p + Vector2(randf_range(-60.0, 60.0), 0.0), {"v": Vector2(0.0, -80.0), "life": 0.8, "scale": 1.8})
