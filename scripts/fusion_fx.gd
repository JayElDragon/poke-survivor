extends Node2D
# Ataques propios de cada Movimiento de Vinculo fusionado (50 recetas). Cada receta combina unos pocos "arquetipos"
# (lluvia de proyectiles, vortice, rayo, tormenta de rayos, prision, erupciones, orbitales, tajos, olas, buscadores,
# ondas, santuario) con su propio color, cantidad y estados. Los dos movimientos originales siguen lanzandose
# como antes; esto es el ataque especial de la fusion, con su animacion.
const V0 := Vector2(0.0, -9.0)
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")
var main = null
var acts: Array = []
var T := 0.0
var tint: Dictionary = {}   # velo de pantalla/escenario (eclipse, luna)
var lite := 0   # Rendimiento: 0 normal, 1 ahorro, 2 minimo (menos particulas y capas dibujadas)
const FRONT := 64.0   # los disparos salen delante del jugador, no desde dentro, para verlo
var under: Node2D = null   # capa del suelo (bajo los Pokemon): charcos, velos y sombras nunca tapan ni oscurecen al jugador

# [arquetipo, parametros, retraso]
# cd = recarga (s), k = potencia respecto al daño medio de los dos movimientos, st = estados que aplica
const SPECS := {
	"inferno_tempest": {"cd": 7.0, "k": 2.2, "st": {"burn": 3}, "steps": [["vortex", {"r": 170, "dur": 4.2, "pull": 90, "style": "fire", "move": 60, "d": 0.5}, 0.0]]},
	"thunder_apocalypse": {"cd": 7.5, "k": 2.4, "st": {"cc": "para", "ccp": 0.25}, "steps": [["bolts", {"n": 16, "dur": 2.6, "chain": 2, "style": "electric", "d": 1.0, "r": 46}, 0.0]]},
	"abyssal_singularity": {"cd": 9.0, "k": 2.4, "steps": [["vortex", {"r": 150, "dur": 3.6, "pull": 170, "style": "dark", "at": "cluster", "d": 0.55, "finale": 1.6}, 0.0]]},
	"absolute_zero": {"cd": 8.0, "k": 2.4, "st": {"cc": "freeze", "ccp": 0.3, "slow": 0.5}, "steps": [["beam", {"len": 520, "w": 64, "dur": 1.8, "wind": 0.5, "sweep": 1.7, "style": "ice", "d": 0.55}, 0.0], ["nova", {"rings": 1, "rmax": 260, "style": "frost", "d": 1.0}, 2.3]]},
	"dragon_cataclysm": {"cd": 8.0, "k": 2.4, "st": {"burn": 3}, "steps": [["drops", {"n": 8, "r": 78, "style": "meteor", "dur": 1.4, "spread": 230, "on": "enemies", "d": 1.2, "pool": 3.0}, 0.0], ["nova", {"rings": 1, "rmax": 240, "style": "fire", "d": 0.8}, 1.8]]},
	"toxic_eden": {"cd": 8.5, "k": 1.8, "st": {"poison": 3}, "steps": [["eruption", {"n": 7, "r": 62, "style": "bloom", "dur": 1.0, "on": "enemies", "d": 1.0, "pool": 5.0}, 0.0]]},
	"heavens_judgment": {"cd": 8.5, "k": 2.4, "steps": [["bolts", {"n": 12, "dur": 2.0, "chain": 0, "style": "holy", "d": 1.2, "r": 58}, 0.0]]},
	"earthbreaker": {"cd": 7.0, "k": 2.2, "steps": [["eruption", {"n": 11, "r": 58, "style": "rock", "dur": 0.9, "line": 1, "d": 1.0, "step": 55}, 0.0]]},
	"phantom_legion": {"cd": 9.0, "k": 1.8, "steps": [["orbit", {"n": 7, "radius": 105, "dur": 4.5, "spd": 2.6, "style": "ghost", "d": 0.45, "launch": 1}, 0.0]]},
	"solar_annihilation": {"cd": 11.0, "k": 3.4, "st": {"burn": 2}, "steps": [["beam", {"len": 640, "w": 120, "dur": 1.6, "wind": 0.9, "style": "solar", "d": 0.7}, 0.0]]},
	"crimson_execution": {"cd": 6.5, "k": 2.4, "steps": [["slashes", {"n": 6, "style": "crimson", "mark": 0.55, "d": 1.4}, 0.0]]},
	"frozen_thunder": {"cd": 7.0, "k": 2.0, "st": {"cc": "freeze", "ccp": 0.3, "slow": 0.4}, "steps": [["bolts", {"n": 12, "dur": 2.2, "chain": 2, "style": "frost", "d": 1.0, "r": 44}, 0.0]]},
	"celestial_meteor": {"cd": 8.0, "k": 2.4, "st": {"burn": 2}, "steps": [["drops", {"n": 13, "r": 84, "style": "meteor", "dur": 2.4, "spread": 300, "on": "mixed", "d": 1.1}, 0.0]]},
	"blood_moon": {"cd": 10.0, "k": 1.6, "st": {"cc": "sleep", "ccp": 0.6}, "steps": [["nova", {"rings": 3, "rmax": 270, "style": "moon", "d": 0.8, "gap": 0.7, "overlay": "moon", "drain": 1}, 0.0]]},
	"magma_cyclone": {"cd": 8.0, "k": 2.0, "st": {"burn": 3}, "steps": [["vortex", {"r": 150, "dur": 4.0, "pull": 70, "style": "lava", "blades": 5, "d": 0.5}, 0.0]]},
	"blazing_comet": {"cd": 8.0, "k": 3.0, "st": {"burn": 3}, "steps": [["drops", {"n": 3, "r": 120, "style": "comet", "dur": 1.2, "spread": 200, "on": "dense", "d": 2.6, "pool": 3.0}, 0.0]]},
	"storm_wing": {"cd": 6.0, "k": 2.0, "st": {"cc": "para", "ccp": 0.2}, "steps": [["waves", {"n": 5, "spread": 1.5, "style": "wing", "d": 1.2, "range": 470, "spd": 460, "w": 34}, 0.0]]},
	"glacier_storm": {"cd": 6.0, "k": 1.6, "st": {"slow": 0.4, "cc": "freeze", "ccp": 0.15}, "steps": [["waves", {"n": 11, "spread": 2.6, "style": "shard", "d": 0.9, "range": 430, "spd": 400, "w": 22}, 0.0]]},
	"venom_nightmare": {"cd": 8.0, "k": 1.8, "st": {"poison": 3}, "steps": [["drops", {"n": 9, "r": 64, "style": "bomb", "dur": 1.6, "spread": 230, "on": "enemies", "d": 1.0, "pool": 3.5}, 0.0]]},
	"tidal_thunder": {"cd": 7.5, "k": 2.0, "st": {"cc": "para", "ccp": 0.2}, "steps": [["waves", {"n": 1, "spread": 0, "style": "tide", "d": 1.4, "range": 520, "spd": 330, "w": 120}, 0.0], ["bolts", {"n": 8, "dur": 1.4, "chain": 2, "style": "electric", "d": 1.0, "r": 44}, 0.6]]},
	"volcanic_armageddon": {"cd": 10.0, "k": 2.2, "st": {"burn": 4}, "steps": [["eruption", {"n": 6, "r": 74, "style": "lava", "dur": 1.2, "ring": 150, "d": 1.3, "pool": 6.0}, 0.0]]},
	"thunder_prison": {"cd": 10.0, "k": 2.2, "st": {"cc": "para", "ccp": 0.2}, "steps": [["prison", {"r": 150, "dur": 3.4, "n": 8, "style": "electric", "d": 0.5, "finale": "blast"}, 0.0]]},
	"eternal_blizzard": {"cd": 9.0, "k": 2.0, "st": {"cc": "freeze", "ccp": 0.25, "slow": 0.45}, "steps": [["beam", {"len": 400, "w": 26, "dur": 3.0, "count": 3, "sweep": 2.0, "style": "ice", "d": 0.4}, 0.0], ["drops", {"n": 9, "r": 52, "style": "ice", "dur": 2.4, "spread": 240, "on": "enemies", "d": 0.9}, 0.6]]},
	"oceanic_devastation": {"cd": 9.0, "k": 2.2, "st": {"slow": 0.4}, "steps": [["vortex", {"r": 160, "dur": 3.0, "pull": 130, "style": "water", "d": 0.5}, 0.0], ["slashes", {"n": 3, "style": "claw", "mark": 0.7, "d": 1.6}, 1.1]]},
	"natures_wrath": {"cd": 9.0, "k": 1.8, "st": {"slow": 0.6}, "steps": [["vortex", {"r": 110, "dur": 1.6, "pull": 40, "style": "leaf", "d": 0.3}, 0.0], ["eruption", {"n": 8, "r": 56, "style": "root", "dur": 1.0, "on": "enemies", "d": 1.0, "drain": 1, "pool": 3.0}, 0.9]]},
	"divine_execution": {"cd": 7.5, "k": 3.0, "steps": [["slashes", {"n": 4, "style": "divine", "mark": 0.6, "d": 1.8}, 0.0]]},
	"meteor_breaker": {"cd": 8.0, "k": 2.2, "steps": [["eruption", {"n": 7, "r": 70, "style": "pillar", "dur": 1.2, "on": "enemies", "d": 1.2, "frag": 1}, 0.0]]},
	"phantom_assassin": {"cd": 7.0, "k": 1.7, "st": {"poison": 3}, "steps": [["seekers", {"n": 7, "style": "bone", "d": 1.0, "r": 60, "cross": 1}, 0.0]]},
	"dragon_overlord": {"cd": 8.0, "k": 2.2, "steps": [["seekers", {"n": 9, "style": "dragon", "d": 1.0, "r": 56, "scale_hp": 1}, 0.0]]},
	"sky_execution": {"cd": 7.0, "k": 2.4, "steps": [["slashes", {"n": 6, "style": "wind", "mark": 0.5, "d": 1.4, "stomp": 1}, 0.0]]},
	"iron_guillotine": {"cd": 10.0, "k": 2.4, "st": {"slow": 0.7}, "steps": [["prison", {"r": 120, "dur": 2.2, "n": 6, "style": "anchor", "d": 0.35, "finale": "axes"}, 0.0]]},
	"piercing_catastrophe": {"cd": 7.5, "k": 2.2, "steps": [["waves", {"n": 1, "spread": 0, "style": "drill", "d": 2.0, "range": 520, "spd": 380, "w": 40, "trail": 1}, 0.0]]},
	"crimson_barrage": {"cd": 7.0, "k": 1.4, "st": {"burn": 2, "cc": "para", "ccp": 0.1}, "steps": [["seekers", {"n": 8, "style": "ram", "d": 0.8, "r": 52, "combo": 1, "spd": 520}, 0.0]]},
	"dragon_cyclone": {"cd": 8.0, "k": 1.8, "steps": [["orbit", {"n": 8, "radius": 120, "dur": 4.0, "spd": 3.6, "style": "dragon", "d": 0.5, "launch": 1}, 0.0], ["vortex", {"r": 100, "dur": 3.0, "pull": 20, "style": "wind", "d": 0.0}, 0.0]]},
	"shattering_glacier": {"cd": 9.0, "k": 2.4, "st": {"cc": "freeze", "ccp": 0.3}, "steps": [["drops", {"n": 3, "r": 100, "style": "iceball", "dur": 1.4, "spread": 200, "on": "dense", "d": 2.2, "frag": 1}, 0.0]]},
	"nightmare_eclipse": {"cd": 11.0, "k": 1.8, "steps": [["nova", {"rings": 3, "rmax": 300, "style": "dark", "d": 0.9, "gap": 0.6, "overlay": "dark", "status_bonus": 1}, 0.0], ["orbit", {"n": 5, "radius": 140, "dur": 4.0, "spd": 2.0, "style": "ghost", "d": 0.5}, 0.5]]},
	"psychic_oblivion": {"cd": 9.0, "k": 2.0, "steps": [["nova", {"rings": 5, "rmax": 280, "style": "psychic", "d": 0.9, "gap": 0.35}, 0.0]]},
	"toxic_apocalypse": {"cd": 9.0, "k": 1.8, "st": {"poison": 4}, "steps": [["waves", {"n": 3, "spread": 0.9, "style": "poison", "d": 0.8, "range": 430, "spd": 360, "w": 60}, 0.0], ["eruption", {"n": 8, "r": 54, "style": "spike", "dur": 1.2, "on": "enemies", "d": 1.1, "pool": 2.5}, 0.8]]},
	"mind_shatter": {"cd": 8.0, "k": 1.7, "steps": [["beam", {"len": 480, "w": 20, "dur": 1.6, "count": 5, "fan": 1.3, "style": "psychic", "d": 0.45}, 0.0], ["seekers", {"n": 5, "style": "mirage", "d": 0.9, "r": 50}, 0.4]]},
	"venom_cataclysm": {"cd": 8.0, "k": 1.8, "st": {"poison": 3}, "steps": [["drops", {"n": 8, "r": 66, "style": "cross", "dur": 1.6, "spread": 230, "on": "enemies", "d": 1.1, "pool": 3.0}, 0.0]]},
	"spectral_inferno": {"cd": 8.0, "k": 1.8, "st": {"burn": 2, "slow": 0.3}, "steps": [["seekers", {"n": 9, "style": "ghostfire", "d": 0.9, "r": 54}, 0.0]]},
	"cosmic_cannon": {"cd": 13.0, "k": 4.5, "steps": [["beam", {"len": 700, "w": 170, "dur": 1.2, "wind": 1.3, "style": "cosmic", "d": 0.8}, 0.0]]},
	"guardians_sanctuary": {"cd": 14.0, "k": 1.0, "steps": [["sanctuary", {"r": 150, "dur": 7.0, "heal": 0.022}, 0.0]]},
	"golden_cataclysm": {"cd": 8.0, "k": 2.2, "steps": [["drops", {"n": 11, "r": 60, "style": "egg", "dur": 2.0, "spread": 240, "on": "mixed", "d": 1.1, "coins": 8}, 0.0]]},
	"crystal_labyrinth": {"cd": 10.0, "k": 1.6, "st": {"slow": 0.7}, "steps": [["prison", {"r": 170, "dur": 5.0, "n": 10, "style": "crystal", "d": 0.4, "finale": "blast"}, 0.0]]},
	"solar_sandstorm": {"cd": 9.0, "k": 1.8, "st": {"burn": 2}, "steps": [["vortex", {"r": 130, "dur": 4.5, "pull": 40, "style": "sand", "move": 150, "d": 0.5, "craters": 1}, 0.0]]},
	"phantom_whirlpool": {"cd": 9.0, "k": 1.8, "st": {"slow": 0.4}, "steps": [["vortex", {"r": 150, "dur": 3.8, "pull": 120, "style": "ghostwater", "blades": 6, "d": 0.5}, 0.0]]},
	"razor_dimension": {"cd": 7.0, "k": 2.2, "steps": [["slashes", {"n": 6, "style": "dimension", "mark": 0.4, "d": 1.2, "crit": 0.3}, 0.0]]},
	"frostfire_cataclysm": {"cd": 9.0, "k": 1.6, "steps": [["nova", {"rings": 4, "rmax": 270, "style": "frostfire", "d": 0.7, "gap": 0.45, "burst": 1.6}, 0.0]]},
	"celestial_barrage": {"cd": 9.0, "k": 2.0, "steps": [["seekers", {"n": 6, "style": "dart", "d": 0.5, "r": 40, "mark": 1}, 0.0], ["bolts", {"n": 6, "dur": 1.2, "chain": 0, "style": "holy", "d": 2.0, "r": 64, "marked": 1}, 1.4]]},
}

const DEFAULT_SPEC := {"cd": 8.0, "k": 1.8, "steps": [["nova", {"rings": 2, "rmax": 230, "style": "frost", "d": 0.9, "gap": 0.4}, 0.0], ["drops", {"n": 6, "r": 64, "style": "meteor", "dur": 1.4, "spread": 230, "on": "enemies", "d": 1.0}, 0.3]]}


func _ready() -> void:
	z_index = 12
	process_mode = Node.PROCESS_MODE_PAUSABLE
	under = Node2D.new()
	under.draw.connect(_draw_under)
	main.gfx.add_child(under)


# fraccion de efectos que se dibujan: baja sola cuando el FPS cae (main.fx_load)
func _ld() -> float:
	return float(main.fx_load)


# ---------------------------------------------------------------
# Entrada: cada fotograma, por cada movimiento fusionado
# ---------------------------------------------------------------
func tick(m: Dictionary, delta: float) -> void:
	m["sig_t"] = float(m.get("sig_t", 1.0)) - delta
	if float(m["sig_t"]) > 0.0:
		return
	var rid: String = String(m.get("recipe", ""))
	var spec: Dictionary = SPECS.get(rid, DEFAULT_SPEC)
	var needs_foe: bool = rid != "guardians_sanctuary"
	if needs_foe and main._nearest_enemy(main.player.position, 460.0) == null:
		m["sig_t"] = 0.25
		return
	m["sig_t"] = float(spec["cd"]) * main._cd_mul()
	cast(m, spec)


func cast(m: Dictionary, spec: Dictionary) -> void:
	if acts.size() > int(float(40 if lite == 0 else (24 if lite == 1 else 14)) * maxf(0.5, _ld())):
		return   # demasiados efectos a la vez: se salta este lanzamiento (evita tirones)
	var parts: Array = m["parts"]
	var d0: float = float(parts[0].get("dmg", 10.0))
	var d1: float = float(parts[1].get("dmg", 10.0))
	var ty: String = String(parts[0].get("type", "normal"))
	var rid: String = String(m.get("recipe", ""))
	var col: Color = Color.html(String(_rec_col(rid, ty)))
	if main.VFX.shiny_on:
		col = main.VFX.shiny_col(ty, col)
	var sm: Dictionary = {"id": String(m["id"]), "kind": "nova", "type": ty, "lvl": 10, "evolved": true, "knock": 70.0}
	var st: Dictionary = spec.get("st", {})
	for k in st:
		sm[k] = st[k]
	var ctx: Dictionary = {"sm": sm, "base": (d0 + d1) * 0.5 * main._atk() * float(spec["k"]) * 1.3, "col": col,
		"col2": col.lightened(0.45), "dark": col.darkened(0.35), "id": rid, "coins": 0, "marked": [], "ty": ty}
	if parts.size() > 1 and String(parts[1].get("type", ty)) != ty:
		var c2: Color = Color.html(String(main.MD.TYPE_COLOR.get(String(parts[1]["type"]), "#ffffff")))
		if main.VFX.shiny_on:
			c2 = main.VFX.shiny_col(String(parts[1]["type"]), c2)
		ctx["col2"] = c2.lerp(Color.WHITE, 0.25)
	for s in spec["steps"]:
		acts.append({"k": String(s[0]), "p": s[1], "ctx": ctx, "wait": float(s[2]), "t": 0.0, "init": false})
	main.shake = maxf(main.shake, 4.0)
	Aud.sfx("legend")


func _rec_col(rid: String, ty: String) -> String:
	var rows: Array = main.FUS.R
	for r in rows:
		if String(r[0]) == rid:
			return String(r[5])
	return String(main.MD.TYPE_COLOR.get(ty, "#ffffff"))


func clear() -> void:
	acts.clear()
	tint = {}
	queue_redraw()
	under.queue_redraw()


func step(delta: float) -> void:
	T += delta
	if acts.is_empty() and tint.is_empty():
		return
	for i in range(acts.size() - 1, -1, -1):
		var a: Dictionary = acts[i]
		if float(a["wait"]) > 0.0:
			a["wait"] = float(a["wait"]) - delta
			continue
		if not bool(a["init"]):
			a["init"] = true
			_start(a)
		a["t"] = float(a["t"]) + delta
		if _upd(a, delta):
			_end(a)
			acts.remove_at(i)
	if not tint.is_empty():
		tint["t"] = float(tint["t"]) + delta
		if float(tint["t"]) >= float(tint["dur"]):
			tint = {}
	queue_redraw()
	under.queue_redraw()


# ---------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------
func _pp() -> Vector2:
	return main.player.position


# Punto de salida de los disparos: delante del jugador (hacia el enemigo mas cercano).
func _org() -> Vector2:
	return main.player.position + _aim_dir() * FRONT


func _foes(reach: float) -> Array:
	var out: Array = []
	var pp: Vector2 = _pp()
	for e in main.enemies:
		if not e.dead and e.position.distance_to(pp) <= reach:
			out.append(e)
	return out


func _hit(a: Dictionary, e, frac: float, from: Vector2, extra_mul: float = 1.0) -> void:
	var ctx: Dictionary = a["ctx"]
	var dmg: float = float(ctx["base"]) * frac * extra_mul
	if bool(a["p"].get("status_bonus", 0)) and (e.burn_t > 0.0 or e.poison_t > 0.0 or e.frozen_t > 0.0 or e.para_t > 0.0 or e.sleep_t > 0.0 or e.conf_t > 0.0 or e.slow_t > 0.0):
		dmg *= 1.5
	var dir: Vector2 = (e.position - from)
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	main._hit_move(e, dmg, dir, ctx["sm"])


func _area(a: Dictionary, c: Vector2, r: float, frac: float, mul: float = 1.0) -> int:
	var n := 0
	for e in main.enemies:
		if e.dead:
			continue
		if e.position.distance_to(c) <= r + e.radius * 0.5:
			_hit(a, e, frac, c, mul)
			n += 1
	return n


func _drain(a: Dictionary, n: int) -> void:
	if n > 0 and bool(a["p"].get("drain", 0)):
		main._heal_real(main.player.max_hp * 0.004 * minf(float(n), 6.0))


func _aim_dir() -> Vector2:
	var t = main._nearest_enemy(_pp(), 520.0)
	if t != null:
		return (t.position - _pp()).normalized()
	return Vector2.from_angle(main.player.aim)


func _pick_targets(a: Dictionary, n: int, mode: String, reach: float = 480.0) -> Array:
	var f: Array = _foes(reach)
	f.shuffle()
	var out: Array = []
	if mode == "dense":
		var best = null
		var bn := -1
		var cand: Array = f.slice(0, 40)   # con cientos de enemigos, comparar todos con todos daba tirones
		for e in cand:
			var c := 0
			for o in f:
				if o.position.distance_squared_to(e.position) < 110.0 * 110.0:
					c += 1
			if c > bn:
				bn = c
				best = e
		if best != null:
			for i in n:
				out.append(best.position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 70.0))
		return out
	for i in n:
		if f.is_empty():
			break
		out.append(f[i % f.size()].position + Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 8.0)))
	return out


func _px(pos: Vector2, col: Color, vel: Vector2, life: float, size: float = 1.0, grav: float = 0.0) -> void:
	if randf() < (0.6 if lite == 0 else (0.8 if lite == 1 else 0.95)) or randf() > _ld():
		return
	main.pfx.px(pos + V0, col, vel, life, size, grav, 0.92)


func _burst(pos: Vector2, col: Color, n: int = 10, power: float = 140.0) -> void:
	main.pfx.burst(pos + V0, col, maxi(2, int(float(n) * (0.35 if lite == 0 else (0.2 if lite == 1 else 0.1)) * _ld())), power)


func _ringfx(pos: Vector2, r1: float, col: Color, life: float = 0.4, w: float = 4.0) -> void:
	main._ring(pos, r1 * 0.2, r1, col, life, w)


func _a(c: Color, al: float) -> Color:
	return Color(c.r, c.g, c.b, al)


# ---------------------------------------------------------------
# Inicio de cada arquetipo
# ---------------------------------------------------------------
func _start(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var k: String = String(a["k"])
	var pp: Vector2 = _pp()
	match k:
		"drops":
			var n: int = int(p["n"])
			var pts: Array = []
			var on: String = String(p.get("on", "enemies"))
			if on == "dense":
				pts = _pick_targets(a, n, "dense")
			elif on == "mixed":
				pts = _pick_targets(a, int(ceil(n * 0.6)), "rand")
			else:
				pts = _pick_targets(a, n, "rand")
			var sp: float = float(p.get("spread", 220.0))
			while pts.size() < n:
				var aim: Vector2 = _aim_dir()
				pts.append(pp + aim * sp * 0.5 + Vector2.from_angle(randf() * TAU) * randf_range(20.0, sp))
			var dr: Array = []
			var dur: float = float(p.get("dur", 1.2))
			for i in pts.size():
				dr.append({"pos": pts[i], "at": dur * float(i) / maxf(1.0, float(pts.size())) + randf_range(0.0, 0.1), "fall": 0.5, "done": false, "rot": randf() * TAU})
			a["drops"] = dr
		"pool":
			pass
		"vortex":
			var c: Vector2 = _org()   # delante del Pokemon, no encima
			if String(p.get("at", "")) == "cluster":
				var d: Array = _pick_targets(a, 1, "dense")
				if not d.is_empty():
					c = d[0]
				else:
					c = pp + _aim_dir() * 140.0
			a["c"] = c
			a["dir"] = _aim_dir()
			a["tk"] = 0.0
			a["ang"] = randf() * TAU
		"beam":
			var dv: Vector2 = _aim_dir()
			a["ang0"] = dv.angle()
			a["tk"] = 0.0
		"bolts":
			a["tk"] = 0.0
			a["fired"] = 0
			a["vis"] = []
		"prison":
			var cc: Vector2 = pp + _aim_dir() * 100.0
			var dn: Array = _pick_targets(a, 1, "dense")
			if not dn.is_empty():
				cc = dn[0]
			a["c"] = cc
			a["tk"] = 0.0
			Aud.sfx("legend")
		"eruption":
			var n2: int = int(p["n"])
			var spots: Array = []
			if bool(p.get("line", 0)):
				var dv2: Vector2 = _aim_dir()
				for i in n2:
					spots.append(pp + dv2 * (50.0 + float(p.get("step", 50.0)) * float(i)) + dv2.orthogonal() * randf_range(-14.0, 14.0))
			elif float(p.get("ring", 0.0)) > 0.0:
				var ao: float = randf() * TAU
				for i in n2:
					spots.append(pp + Vector2.from_angle(ao + TAU * float(i) / float(n2)) * float(p["ring"]))
			else:
				spots = _pick_targets(a, n2, "rand")
				while spots.size() < n2:
					spots.append(pp + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 220.0))
			var dur2: float = float(p.get("dur", 1.0))
			var cl: Array = []
			for i in spots.size():
				cl.append({"pos": spots[i], "at": dur2 * float(i) / float(spots.size()), "state": 0, "t": 0.0, "seed": randf() * 10.0})
			a["cols"] = cl
		"orbit":
			var n3: int = int(p["n"])
			var ol: Array = []
			for i in n3:
				ol.append({"ang": TAU * float(i) / float(n3), "cd": {}, "x": 0.0, "launched": false, "pos": pp, "vel": Vector2.ZERO, "life": 0.0, "hit": {}})
			a["orbs"] = ol
		"slashes":
			var n4: int = int(p["n"])
			var tg: Array = _pick_targets(a, n4, "rand")
			var sl: Array = []
			for i in tg.size():
				sl.append({"pos": tg[i], "at": 0.12 * float(i), "state": 0, "t": 0.0, "ang": randf_range(-0.6, 0.6)})
			a["sl"] = sl
		"waves":
			var base: Vector2 = _aim_dir()
			var n5: int = int(p["n"])
			var wl: Array = []
			var spr: float = float(p.get("spread", 1.0))
			for i in n5:
				var off: float = 0.0 if n5 == 1 else (float(i) / float(n5 - 1) - 0.5) * spr
				var dvv: Vector2 = base.rotated(off)
				wl.append({"pos": _org() + dvv * 8.0, "dir": dvv, "hit": {}, "dist": 0.0, "tr": 0.0})
			a["waves"] = wl
		"seekers":
			var n6: int = int(p["n"])
			var fs: Array = _foes(520.0)
			fs.shuffle()
			var sk: Array = []
			var base2: float = randf() * TAU
			for i in n6:
				var tgt = null
				if not fs.is_empty():
					tgt = fs[i % fs.size()]
				var ang: float = base2 + TAU * float(i) / float(n6)
				sk.append({"pos": _org(), "vel": Vector2.from_angle(ang) * 160.0, "tgt": tgt, "life": 0.0, "at": 0.08 * float(i), "done": false, "trail": []})
			a["sk"] = sk
			a["combo"] = 0
		"nova":
			a["ring_i"] = 0
			a["rings"] = []
			a["hit_hot"] = {}
			a["hit_cold"] = {}
			a["boomed"] = {}
			a["rt"] = 0.0
			if String(p.get("overlay", "")) != "":
				tint = {"kind": String(p["overlay"]), "t": 0.0, "dur": float(p.get("gap", 0.5)) * float(p["rings"]) + 1.4, "c": _pp()}
		"sanctuary":
			a["c"] = pp
			a["tk"] = 0.0
			main.player.invuln = maxf(main.player.invuln, 0.8)
			main._say(L.t("Santuario"), 1.6)


func _end(a: Dictionary) -> void:
	var k: String = String(a["k"])
	var p: Dictionary = a["p"]
	if k == "vortex":
		var fin: float = float(p.get("finale", 0.0))
		if fin > 0.0:
			var c: Vector2 = a["c"]
			_area(a, c, float(p["r"]) * 1.1, fin)
			_ringfx(c, float(p["r"]) * 1.4, a["ctx"]["col"], 0.5, 8.0)
			_burst(c, a["ctx"]["col2"], 36, 260.0)
			main.shake = maxf(main.shake, 8.0)
		if bool(p.get("craters", 0)):
			acts.append({"k": "pool", "p": {"r": 60, "dur": 3.0, "style": "sand", "d": 0.35}, "ctx": a["ctx"], "wait": 0.0, "t": 0.0, "init": true, "c": a["c"]})


# ---------------------------------------------------------------
# Actualizacion: devuelve true al terminar
# ---------------------------------------------------------------
func _upd(a: Dictionary, dt: float) -> bool:
	match String(a["k"]):
		"drops":
			return _u_drops(a, dt)
		"pool":
			return _u_pool(a, dt)
		"vortex":
			return _u_vortex(a, dt)
		"beam":
			return _u_beam(a, dt)
		"bolts":
			return _u_bolts(a, dt)
		"prison":
			return _u_prison(a, dt)
		"eruption":
			return _u_eruption(a, dt)
		"orbit":
			return _u_orbit(a, dt)
		"slashes":
			return _u_slashes(a, dt)
		"waves":
			return _u_waves(a, dt)
		"seekers":
			return _u_seekers(a, dt)
		"nova":
			return _u_nova(a, dt)
		"sanctuary":
			return _u_sanct(a, dt)
	return true


func _u_drops(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var all_done := true
	for d in a["drops"]:
		if bool(d["done"]):
			continue
		all_done = false
		var lt: float = float(a["t"]) - float(d["at"])
		if lt >= float(d["fall"]):
			d["done"] = true
			var pos: Vector2 = d["pos"]
			var r: float = float(p["r"])
			var n: int = _area(a, pos, r, float(p["d"]))
			_ringfx(pos, r * 1.15, ctx["col"], 0.4, 5.0)
			_burst(pos, ctx["col"], 14, 170.0)
			_burst(pos, ctx["col2"], 8, 110.0)
			main.shake = maxf(main.shake, 3.0)
			if int(p.get("coins", 0)) > 0 and n > 0 and int(ctx["coins"]) < int(p["coins"]):
				ctx["coins"] = int(ctx["coins"]) + 1
				main._spawn_orb(pos, "coin", 1.0)
			if float(p.get("pool", 0.0)) > 0.0:
				acts.append({"k": "pool", "p": {"r": r * 0.8, "dur": float(p["pool"]), "style": String(p["style"]), "d": 0.25 * float(p["d"])}, "ctx": ctx, "wait": 0.0, "t": 0.0, "init": true, "c": pos})
			if bool(p.get("frag", 0)):
				for i in 8:
					var an: float = TAU * float(i) / 8.0
					_px(pos, ctx["col2"], Vector2.from_angle(an) * 200.0, 0.5, 2.0)
				_area(a, pos, r * 1.7, float(p["d"]) * 0.4)
				_ringfx(pos, r * 1.8, ctx["col2"], 0.5, 3.0)
	return all_done


func _u_pool(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	a["tk"] = float(a.get("tk", 0.0)) - dt
	var c: Vector2 = a["c"]
	if float(a["tk"]) <= 0.0:
		a["tk"] = 0.5
		_area(a, c, float(p["r"]), float(p["d"]))
	if randf() < 0.25:
		_px(c + Vector2.from_angle(randf() * TAU) * randf_range(0.0, float(p["r"])), a["ctx"]["col2"], Vector2(0.0, -26.0), 0.6, 1.5)
	return float(a["t"]) >= float(p["dur"])


func _u_vortex(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var c: Vector2 = a["c"]
	var r: float = float(p["r"])
	if String(p.get("at", "")) == "":
		c = c.lerp(_org(), minf(1.0, dt * 8.0))   # sigue al jugador, siempre por delante de el
	if float(p.get("move", 0.0)) > 0.0:
		var sp: float = float(p["move"])
		if a.has("pos_f"):
			c = a["pos_f"]
		else:
			c = _org()
		c += a["dir"] * sp * dt
		a["pos_f"] = c
	a["c"] = c
	a["ang"] = float(a["ang"]) + dt * 4.2
	var pull: float = float(p.get("pull", 0.0))
	a["tk"] = float(a["tk"]) - dt
	var tick := false
	if float(a["tk"]) <= 0.0:
		a["tk"] = 0.3
		tick = true
	var n := 0
	var reach2: float = r * 1.25 * r * 1.25
	for e in main.enemies:
		if e.dead:
			continue
		var d2: float = e.position.distance_squared_to(c)
		if d2 > reach2:
			continue
		var dd: float = sqrt(d2)
		if pull > 0.0 and dd > 12.0:
			var k: float = 0.35 if e.boss else 1.0
			e.position += (c - e.position).normalized() * pull * dt * k
		if tick and dd <= r + e.radius * 0.5:
			_hit(a, e, float(p["d"]), c)
			n += 1
	_drain(a, n)
	var col: Color = a["ctx"]["col"]
	for i in 3:
		var an: float = float(a["ang"]) + TAU * float(i) / 3.0 + randf() * 0.3
		var rr: float = randf_range(0.2, 1.0) * r
		_px(c + Vector2.from_angle(an + rr * 0.012) * rr, col if randf() < 0.6 else a["ctx"]["col2"], Vector2.from_angle(an + 1.57) * 90.0 + Vector2(0.0, -30.0), 0.45, 2.0)
	return float(a["t"]) >= float(p["dur"])


func _u_beam(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var wind: float = float(p.get("wind", 0.0))
	var t: float = float(a["t"])
	var dur: float = float(p["dur"])
	if t < wind:
		a["ang0"] = lerp_angle(float(a["ang0"]), _aim_dir().angle(), minf(1.0, dt * 6.0))
		if randf() < 0.7:
			_px(_org() + Vector2.from_angle(randf() * TAU) * 60.0, a["ctx"]["col2"], Vector2.ZERO, 0.4, 2.0)
		return false
	var bt: float = t - wind
	a["tk"] = float(a["tk"]) - dt
	if float(a["tk"]) <= 0.0:
		a["tk"] = 0.14
		var cnt: int = int(p.get("count", 1))
		for bi in cnt:
			var ang: float = _beam_ang(a, bi, bt)
			var o: Vector2 = _org()
			var dv: Vector2 = Vector2.from_angle(ang)
			var len: float = float(p["len"])
			var hw: float = float(p["w"]) * 0.5
			for e in main.enemies:
				if e.dead:
					continue
				var rel: Vector2 = e.position - o
				var al: float = rel.dot(dv)
				if al < 0.0 or al > len:
					continue
				if absf(rel.cross(dv)) <= hw + e.radius * 0.5:
					_hit(a, e, float(p["d"]) * (0.55 if cnt > 1 else 1.0), o)
	if randf() < 0.8:
		var ang2: float = _beam_ang(a, 0, bt)
		var dd: float = randf() * float(p["len"])
		_px(_org() + Vector2.from_angle(ang2) * dd, a["ctx"]["col2"], Vector2.from_angle(ang2 + randf_range(-1.5, 1.5)) * 70.0, 0.4, 2.0)
	main.shake = maxf(main.shake, 2.0)
	return bt >= dur


func _beam_ang(a: Dictionary, bi: int, bt: float) -> float:
	var p: Dictionary = a["p"]
	var cnt: int = int(p.get("count", 1))
	var fan: float = float(p.get("fan", 0.0))
	var base: float = float(a["ang0"])
	if fan > 0.0 and cnt > 1:
		base += (float(bi) / float(cnt - 1) - 0.5) * fan * (0.6 + 0.4 * sin(bt * 5.0))
	elif cnt > 1:
		base += TAU * float(bi) / float(cnt)
	return base + float(p.get("sweep", 0.0)) * bt


func _u_bolts(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var n: int = int(p["n"])
	var dur: float = float(p["dur"])
	var ctx: Dictionary = a["ctx"]
	while int(a["fired"]) < n and float(a["t"]) >= dur * float(a["fired"]) / float(n):
		a["fired"] = int(a["fired"]) + 1
		var pos := Vector2.ZERO
		var found := false
		if bool(p.get("marked", 0)) and not (ctx["marked"] as Array).is_empty():
			var mk: Array = ctx["marked"]
			var tg = mk[(int(a["fired"]) - 1) % mk.size()]
			if is_instance_valid(tg) and not tg.dead:
				pos = tg.position
				found = true
		if not found:
			var f: Array = _foes(500.0)
			if f.is_empty():
				continue
			pos = f[randi() % f.size()].position
		_strike(a, pos)
	var vis: Array = a["vis"]
	for i in range(vis.size() - 1, -1, -1):
		vis[i]["t"] = float(vis[i]["t"]) + dt
		if float(vis[i]["t"]) >= float(vis[i]["life"]):
			vis.remove_at(i)
	return int(a["fired"]) >= n and vis.is_empty()


func _strike(a: Dictionary, pos: Vector2) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var r: float = float(p.get("r", 44.0))
	_area(a, pos, r, float(p["d"]))
	_ringfx(pos, r * 1.3, ctx["col"], 0.35, 4.0)
	_burst(pos, ctx["col2"], 12, 160.0)
	main.shake = maxf(main.shake, 2.5)
	var style: String = String(p["style"])
	var pts: Array = []
	if style == "holy":
		pts = [pos + Vector2(0.0, -520.0), pos]
	else:
		var top: Vector2 = pos + Vector2(randf_range(-40.0, 40.0), -480.0)
		var segs := 9
		for i in segs + 1:
			var tt: float = float(i) / float(segs)
			var q: Vector2 = top.lerp(pos, tt)
			if i > 0 and i < segs:
				q.x += randf_range(-26.0, 26.0)
			pts.append(q)
	a["vis"].append({"pts": pts, "t": 0.0, "life": 0.38 if style != "holy" else 0.6, "r": r})
	var ch: int = int(p.get("chain", 0))
	if ch > 0:
		var cur: Vector2 = pos
		var used: Array = []
		for j in ch:
			var best = null
			var bd := 150.0
			for e in main.enemies:
				if e.dead or used.has(e):
					continue
				var dd: float = e.position.distance_to(cur)
				if dd < bd and dd > 8.0:
					bd = dd
					best = e
			if best == null:
				break
			used.append(best)
			_hit(a, best, float(p["d"]) * 0.5, cur)
			a["vis"].append({"pts": [cur, best.position], "t": 0.0, "life": 0.3, "r": 0.0, "arc": true})
			cur = best.position


func _u_prison(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var c: Vector2 = a["c"]
	var r: float = float(p["r"])
	var dur: float = float(p["dur"])
	a["tk"] = float(a["tk"]) - dt
	if float(a["tk"]) <= 0.0 and float(a["t"]) > 0.4:
		a["tk"] = 0.4
		_area(a, c, r, float(p["d"]))
		for i in 3:
			_px(c + Vector2.from_angle(randf() * TAU) * r * randf(), a["ctx"]["col2"], Vector2(0.0, -40.0), 0.4, 2.0)
	# los enemigos no salen del cerco (los jefes, solo frenados)
	var lo2: float = (r - 6.0) * (r - 6.0)
	var hi2: float = (r + 40.0) * (r + 40.0)
	for e in main.enemies:
		if e.dead:
			continue
		var dd2: float = e.position.distance_squared_to(c)
		if dd2 > lo2 and dd2 < hi2:
			var inward: Vector2 = (c - e.position).normalized()
			e.position += inward * 70.0 * dt * (0.4 if e.boss else 1.0)
	if float(a["t"]) >= dur:
		var fin: String = String(p.get("finale", "blast"))
		if fin == "axes":
			var dr: Array = []
			var pts: Array = []
			for i in 5:
				pts.append(c + Vector2.from_angle(TAU * float(i) / 5.0) * 60.0 * (0.0 if i == 0 else 1.0))
			for i in pts.size():
				dr.append({"pos": pts[i], "at": 0.12 * float(i), "fall": 0.45, "done": false, "rot": 0.0})
			acts.append({"k": "drops", "p": {"r": 78, "style": "axe", "dur": 0.6, "d": 2.6, "n": 5}, "ctx": a["ctx"], "wait": 0.0, "t": 0.0, "init": true, "drops": dr})
		_area(a, c, r * 1.1, 2.0 if fin == "blast" else 0.8)
		_ringfx(c, r * 1.5, a["ctx"]["col"], 0.5, 8.0)
		_burst(c, a["ctx"]["col2"], 40, 280.0)
		main.shake = maxf(main.shake, 9.0)
		return true
	return false


func _u_eruption(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var all := true
	for cl in a["cols"]:
		if int(cl["state"]) == 2:
			continue
		all = false
		var lt: float = float(a["t"]) - float(cl["at"])
		if lt < 0.0:
			continue
		cl["t"] = lt
		if int(cl["state"]) == 0 and lt >= 0.4:
			cl["state"] = 1
			var pos: Vector2 = cl["pos"]
			var n: int = _area(a, pos, float(p["r"]), float(p["d"]))
			_drain(a, n)
			_ringfx(pos, float(p["r"]) * 1.2, ctx["col"], 0.4, 5.0)
			_burst(pos, ctx["col"], 16, 190.0)
			_burst(pos, ctx["col2"], 8, 120.0)
			main.shake = maxf(main.shake, 3.0)
			if float(p.get("pool", 0.0)) > 0.0:
				acts.append({"k": "pool", "p": {"r": float(p["r"]) * 0.85, "dur": float(p["pool"]), "style": String(p["style"]), "d": 0.22 * float(p["d"])}, "ctx": ctx, "wait": 0.0, "t": 0.0, "init": true, "c": pos})
			if bool(p.get("frag", 0)):
				for i in 8:
					var an: float = TAU * float(i) / 8.0
					_px(pos, ctx["col2"], Vector2.from_angle(an) * 210.0, 0.55, 2.0, 120.0)
				_area(a, pos, float(p["r"]) * 1.7, float(p["d"]) * 0.45)
		if int(cl["state"]) == 1 and lt >= 1.0:
			cl["state"] = 2
	return all


func _u_orbit(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var pp: Vector2 = _pp()
	var dur: float = float(p["dur"])
	var t: float = float(a["t"])
	var launch_at: float = dur - 0.8 if bool(p.get("launch", 0)) else dur + 1.0
	var live := false
	for o in a["orbs"]:
		if not bool(o["launched"]):
			o["ang"] = float(o["ang"]) + float(p["spd"]) * dt
			var rr: float = float(p["radius"]) * minf(1.0, t * 3.0)
			o["pos"] = pp + Vector2.from_angle(float(o["ang"])) * rr
			if t >= launch_at:
				o["launched"] = true
				o["vel"] = Vector2.from_angle(float(o["ang"])) * 440.0
				o["life"] = 0.8
			else:
				live = true
		else:
			o["pos"] = (o["pos"] as Vector2) + (o["vel"] as Vector2) * dt
			o["life"] = float(o["life"]) - dt
			if float(o["life"]) > 0.0:
				live = true
		var op: Vector2 = o["pos"]
		for e in main.enemies:
			if e.dead:
				continue
			var hr: float = 22.0 + e.radius * 0.5
			if e.position.distance_squared_to(op) <= hr * hr:
				var key: int = e.get_instance_id()
				var last: float = float((o["hit"] as Dictionary).get(key, -9.0))
				if t - last > (0.45 if not bool(o["launched"]) else 5.0):
					o["hit"][key] = t
					_hit(a, e, float(p["d"]) * (1.8 if bool(o["launched"]) else 1.0), pp)
					_burst(e.position, a["ctx"]["col"], 5, 90.0)
		if randf() < 0.5:
			_px(o["pos"], a["ctx"]["col"], Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), 0.35, 1.5)
	return not live and t > 0.3


func _u_slashes(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var all := true
	var mark: float = float(p.get("mark", 0.5))
	for s in a["sl"]:
		if int(s["state"]) == 2:
			continue
		all = false
		var lt: float = float(a["t"]) - float(s["at"])
		if lt < 0.0:
			continue
		s["t"] = lt
		if int(s["state"]) == 0 and lt >= mark:
			s["state"] = 1
			s["t"] = 0.0
			s["at"] = float(a["t"])
			var pos: Vector2 = s["pos"]
			var style: String = String(p["style"])
			var crit: float = float(p.get("crit", 0.0))
			var mul := 1.0
			if crit > 0.0 and randf() < crit:
				mul = 1.8
			_slash_dmg(a, s, mul)
			_ringfx(pos, 70.0, ctx["col"], 0.35, 4.0)
			_burst(pos, ctx["col"], 14, 200.0)
			_burst(pos, Color.WHITE, 6, 130.0)
			main.shake = maxf(main.shake, 3.5)
		elif int(s["state"]) == 1 and lt >= 0.45:
			s["state"] = 2
	return all


func _slash_dmg(a: Dictionary, s: Dictionary, mul: float) -> void:
	var p: Dictionary = a["p"]
	var pos: Vector2 = s["pos"]
	var style: String = String(p["style"])
	var segs: Array = _slash_lines(style, pos, float(s["ang"]))
	s["segs"] = segs
	var hit: Dictionary = {}
	for sg in segs:
		var v0: Vector2 = sg[0]
		var v1: Vector2 = sg[1]
		var dv: Vector2 = v1 - v0
		var l2: float = maxf(1.0, dv.length_squared())
		for e in main.enemies:
			if e.dead or hit.has(e):
				continue
			var tt: float = clampf((e.position - v0).dot(dv) / l2, 0.0, 1.0)
			var cp: Vector2 = v0 + dv * tt
			if cp.distance_to(e.position) <= 30.0 + e.radius * 0.5:
				hit[e] = true
				_hit(a, e, float(p["d"]) * 0.7, pos, mul)
	if style == "divine" or bool(p.get("stomp", 0)) or style == "claw" or style == "crimson":
		_area(a, pos, 62.0, float(p["d"]) * 0.5, mul)


func _slash_lines(style: String, pos: Vector2, ang: float) -> Array:
	var out: Array = []
	match style:
		"dimension":
			var dv: Vector2 = Vector2.from_angle(ang * 1.8 + randf_range(-0.2, 0.2))
			out.append([pos - dv * 340.0, pos + dv * 340.0])
			var dv2: Vector2 = dv.rotated(1.5)
			out.append([pos - dv2 * 140.0, pos + dv2 * 140.0])
		"divine":
			out.append([pos + Vector2(0.0, -300.0), pos + Vector2(0.0, 20.0)])
		"wind":
			var dv3: Vector2 = Vector2.from_angle(ang - 0.5)
			out.append([pos - dv3 * 90.0, pos + dv3 * 90.0])
		"claw":
			out.append([pos + Vector2(-110.0, -30.0), pos + Vector2(10.0, 0.0)])
			out.append([pos + Vector2(110.0, -30.0), pos + Vector2(-10.0, 0.0)])
		_:
			var d1: Vector2 = Vector2.from_angle(0.8 + ang * 0.3)
			var d2: Vector2 = Vector2.from_angle(-0.8 + ang * 0.3)
			out.append([pos - d1 * 100.0, pos + d1 * 100.0])
			out.append([pos - d2 * 100.0, pos + d2 * 100.0])
	return out


func _u_waves(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var spd: float = float(p["spd"])
	var rng: float = float(p["range"])
	var alive := false
	for w in a["waves"]:
		if float(w["dist"]) >= rng:
			continue
		alive = true
		var step: Vector2 = (w["dir"] as Vector2) * spd * dt
		w["pos"] = (w["pos"] as Vector2) + step
		w["dist"] = float(w["dist"]) + step.length()
		var pos: Vector2 = w["pos"]
		for e in main.enemies:
			if e.dead or (w["hit"] as Dictionary).has(e):
				continue
			if e.position.distance_to(pos) <= float(p["w"]) + e.radius * 0.5:
				w["hit"][e] = true
				_hit(a, e, float(p["d"]), pos - w["dir"])
				_burst(e.position, ctx["col"], 6, 110.0)
		w["tr"] = float(w["tr"]) + dt
		if randf() < 0.9:
			_px(pos + (w["dir"] as Vector2).orthogonal() * randf_range(-1.0, 1.0) * float(p["w"]) * 0.8, ctx["col"] if randf() < 0.5 else ctx["col2"], -(w["dir"] as Vector2) * 40.0, 0.4, 2.0)
		if bool(p.get("trail", 0)) and float(w["tr"]) >= 0.16:
			w["tr"] = 0.0
			acts.append({"k": "eruption", "p": {"n": 1, "r": 40, "style": "spike", "dur": 0.0, "d": 0.55}, "ctx": ctx, "wait": 0.0, "t": 0.0, "init": true, "cols": [{"pos": pos, "at": 0.0, "state": 0, "t": 0.0, "seed": randf() * 10.0}]})
	return not alive


func _u_seekers(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var all := true
	var spd: float = float(p.get("spd", 380.0))
	for s in a["sk"]:
		if bool(s["done"]):
			continue
		all = false
		if float(a["t"]) < float(s["at"]):
			continue
		s["life"] = float(s["life"]) + dt
		var tg = s["tgt"]
		if tg == null or not is_instance_valid(tg) or tg.dead:
			tg = main._nearest_enemy(s["pos"], 420.0)
			s["tgt"] = tg
		var vel: Vector2 = s["vel"]
		if tg != null:
			var want: Vector2 = (tg.position - (s["pos"] as Vector2)).normalized() * spd
			vel = vel.lerp(want, minf(1.0, dt * 5.0))
		s["vel"] = vel
		s["pos"] = (s["pos"] as Vector2) + vel * dt
		var tr: Array = s["trail"]
		tr.append(s["pos"])
		if tr.size() > 9:
			tr.remove_at(0)
		var boom := false
		if tg != null and (s["pos"] as Vector2).distance_to(tg.position) <= 14.0 + tg.radius * 0.5:
			boom = true
		if float(s["life"]) > 2.4:
			boom = true
		if boom:
			s["done"] = true
			var pos: Vector2 = s["pos"]
			var mul := 1.0
			if bool(p.get("scale_hp", 0)):
				mul = 0.6 + 0.9 * clampf(main.player.hp / maxf(1.0, main.player.max_hp), 0.0, 1.0)
			if bool(p.get("combo", 0)):
				a["combo"] = int(a["combo"]) + 1
				mul = 1.0 + 0.18 * float(int(a["combo"]) - 1)
			if bool(p.get("mark", 0)) and tg != null:
				(ctx["marked"] as Array).append(tg)
			_area(a, pos, float(p["r"]), float(p["d"]), mul)
			_ringfx(pos, float(p["r"]) * 1.3, ctx["col"], 0.35, 4.0)
			_burst(pos, ctx["col"], 12, 160.0)
			if bool(p.get("cross", 0)):
				s["cross"] = 0.4
				a["crosses"] = (a.get("crosses", []) as Array) + [[pos, 0.0]]
			main.shake = maxf(main.shake, 2.0)
	var cr: Array = a.get("crosses", [])
	for c in cr:
		c[1] = float(c[1]) + dt
	return all and (cr.is_empty() or float((cr[cr.size() - 1] as Array)[1]) > 0.45)


func _u_nova(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var n: int = int(p["rings"])
	var gap: float = float(p.get("gap", 0.4))
	var pp: Vector2 = _org()   # las ondas nacen delante del Pokemon, no sobre el
	while int(a["ring_i"]) < n and float(a["t"]) >= gap * float(a["ring_i"]):
		var ri: int = int(a["ring_i"])
		var col: Color = ctx["col"]
		var hot := true
		if String(p["style"]) == "frostfire":
			hot = ri % 2 == 0
			col = Color("#ff7a3a") if hot else Color("#7ae0ff")
		elif String(p["style"]) == "moon":
			col = Color("#e03050")
		(a["rings"] as Array).append({"c": pp, "t": 0.0, "col": col, "hot": hot, "prev": 0.0, "hit": {}})
		a["ring_i"] = ri + 1
		Aud.sfx("legend")
	var rmax: float = float(p["rmax"])
	var life := 0.7
	var alive := false
	for rg in a["rings"]:
		rg["t"] = float(rg["t"]) + dt
		var f: float = clampf(float(rg["t"]) / life, 0.0, 1.0)
		if f >= 1.0:
			continue
		alive = true
		var r: float = rmax * (1.0 - pow(1.0 - f, 2.0))
		var c: Vector2 = rg["c"]
		var cnt := 0
		var out2: float = (r + 120.0) * (r + 120.0)   # margen para jefes grandes
		for e in main.enemies:
			if e.dead:
				continue
			var dd2: float = e.position.distance_squared_to(c)
			if dd2 > out2:
				continue
			var dd: float = sqrt(dd2)
			if dd <= r + e.radius * 0.5 and dd >= float(rg["prev"]) - 30.0 - e.radius * 0.5 and not (rg["hit"] as Dictionary).has(e):
				rg["hit"][e] = true
				cnt += 1
				_hit(a, e, float(p["d"]), c)
				if String(p["style"]) == "frostfire":
					var tk: String = "hit_hot" if bool(rg["hot"]) else "hit_cold"
					a[tk][e] = true
					if a["hit_hot"].has(e) and a["hit_cold"].has(e) and not a["boomed"].has(e):
						a["boomed"][e] = true
						_area(a, e.position, 70.0, float(p.get("burst", 1.0)))
						_ringfx(e.position, 80.0, Color("#ffffff"), 0.35, 4.0)
						_burst(e.position, Color("#ffd0a0"), 14, 180.0)
		_drain(a, cnt)
		rg["prev"] = r
		if randf() < 0.9:
			var an: float = randf() * TAU
			_px(c + Vector2.from_angle(an) * r, rg["col"], Vector2.from_angle(an) * 30.0, 0.4, 2.0)
	return int(a["ring_i"]) >= n and not alive


func _u_sanct(a: Dictionary, dt: float) -> bool:
	var p: Dictionary = a["p"]
	var c: Vector2 = a["c"]
	a["tk"] = float(a["tk"]) - dt
	if float(a["tk"]) <= 0.0:
		a["tk"] = 0.5
		if _pp().distance_to(c) <= float(p["r"]):
			main._heal_real(main.player.max_hp * float(p["heal"]) * 0.5)
			main.player.invuln = maxf(main.player.invuln, 0.12)
			_px(_pp(), a["ctx"]["col"], Vector2(0.0, -50.0), 0.6, 2.0)
		for e in main.enemies:
			if not e.dead and e.position.distance_to(c) <= float(p["r"]) * 0.9:
				e.position += (e.position - c).normalized() * 40.0 * dt * 8.0
	if randf() < 0.7:
		var an: float = randf() * TAU
		_px(c + Vector2.from_angle(an) * float(p["r"]) * randf_range(0.2, 1.0), a["ctx"]["col"], Vector2(0.0, -34.0), 0.8, 2.0)
	return float(a["t"]) >= float(p["dur"])


# ---------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------
func _draw() -> void:
	for a in acts:
		if float(a["wait"]) > 0.0 or not bool(a["init"]):
			continue
		match String(a["k"]):
			"drops":
				_d_drops(a)
			"vortex":
				_d_vortex(a)
			"beam":
				_d_beam(a)
			"bolts":
				_d_bolts(a)
			"prison":
				_d_prison(a)
			"eruption":
				_d_eruption(a)
			"orbit":
				_d_orbit(a)
			"slashes":
				_d_slashes(a)
			"waves":
				_d_waves(a)
			"seekers":
				_d_seekers(a)
			"nova":
				_d_nova(a)


# Capa del suelo (bajo los Pokemon): velos, charcos, sombras, santuario y marcas de impacto.
# Asi ningun efecto oscuro queda encima del jugador.
func _draw_under() -> void:
	if not tint.is_empty():
		_draw_tint()
	for a in acts:
		if float(a["wait"]) > 0.0 or not bool(a["init"]):
			continue
		match String(a["k"]):
			"pool":
				_d_pool(a)
			"sanctuary":
				_d_sanct(a)
			"vortex":
				_g_vortex(a)
			"prison":
				_g_prison(a)
			"drops":
				_g_drops(a)
			"eruption":
				_g_eruption(a)


func _g_vortex(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var c: Vector2 = _gp(a["c"])
	var r: float = float(p["r"])
	var style: String = String(p["style"])
	var k: float = clampf(float(a["t"]) / 0.35, 0.0, 1.0) * clampf((float(p["dur"]) - float(a["t"])) / 0.4, 0.0, 1.0)
	if k <= 0.01:
		return
	if style == "dark" or style == "ghostwater":
		under.draw_colored_polygon(_poly_circle(c, r * 0.9 * k, r * 0.55 * k, 20), _a(Color("#08040e"), 0.45 * k))
	else:
		under.draw_colored_polygon(_poly_circle(c, r * k, r * 0.6 * k, 20), _a(ctx["dark"], 0.22 * k))
	if style == "dark":
		under.draw_circle(c, 18.0 * k, Color("#000000"))


func _g_prison(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var r: float = float(p["r"])
	var k: float = clampf(float(a["t"]) / 0.45, 0.0, 1.0) * clampf((float(p["dur"]) - float(a["t"])) / 0.4, 0.0, 1.0)
	under.draw_colored_polygon(_poly_circle(_gp(a["c"]), r, r * 0.62, 20), _a(a["ctx"]["dark"], 0.18 * k))


func _g_drops(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var col: Color = a["ctx"]["col"]
	var r: float = float(p["r"])
	for d in a["drops"]:
		var lt: float = float(a["t"]) - float(d["at"])
		if lt < 0.0 or bool(d["done"]):
			continue
		var f: float = clampf(lt / float(d["fall"]), 0.0, 1.0)
		var pos: Vector2 = _gp(d["pos"])
		under.draw_arc(pos, r * (0.55 + 0.45 * f), 0.0, TAU, 20, _a(col, 0.25 + 0.5 * f), 2.0)
		under.draw_circle(pos, r * 0.55 * f, _a(col, 0.12 * f))


func _g_eruption(a: Dictionary) -> void:
	var r: float = float(a["p"]["r"])
	var col: Color = a["ctx"]["col"]
	for cl in a["cols"]:
		var lt: float = float(a["t"]) - float(cl["at"])
		if lt < 0.0 or int(cl["state"]) != 0:
			continue
		var pos: Vector2 = _gp(cl["pos"])
		var f: float = clampf(lt / 0.4, 0.0, 1.0)
		under.draw_arc(pos, r * (1.1 - 0.3 * f), 0.0, TAU, 20, _a(col, 0.3 + 0.5 * f), 2.0)
		if f > 0.01:
			under.draw_colored_polygon(_poly_circle(pos, r * f, r * 0.62 * f, 14), _a(col, 0.18))


func _gp(v: Vector2) -> Vector2:
	return v + V0


func _poly_circle(c: Vector2, rx: float, ry: float, n: int = 14) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var an: float = TAU * float(i) / float(n)
		out.append(c + Vector2(cos(an) * rx, sin(an) * ry))
	return out


func _missile(style: String, pos: Vector2, dir: Vector2, sz: float, col: Color, col2: Color, prog: float, rot: float) -> void:
	var nd: Vector2 = dir.normalized()
	var perp: Vector2 = nd.orthogonal()
	match style:
		"meteor", "comet":
			draw_line(pos - nd * sz * 6.0, pos, _a(col, 0.45), sz * 1.5)
			draw_line(pos - nd * sz * 3.5, pos, _a(col2, 0.7), sz * 0.9)
			draw_circle(pos, sz, col)
			draw_circle(pos, sz * 0.62, col2)
			draw_circle(pos + nd * 1.0, sz * 0.3, Color.WHITE)
		"rock":
			var q := PackedVector2Array()
			for i in 6:
				var an: float = rot + TAU * float(i) / 6.0
				q.append(pos + Vector2.from_angle(an) * sz * (0.8 + 0.25 * float(i % 2)))
			draw_colored_polygon(q, Color("#8a6a3a"))
			draw_polyline(q, Color("#d8b878"), 2.0)
		"egg":
			draw_colored_polygon(_poly_circle(pos, sz * 0.75, sz, 12), Color("#ffd84a"))
			draw_colored_polygon(_poly_circle(pos + Vector2(-sz * 0.2, -sz * 0.3), sz * 0.25, sz * 0.35, 8), Color("#fff6b0"))
			draw_line(pos - nd * sz * 3.0, pos, _a(col, 0.4), sz * 0.8)
		"dart":
			draw_line(pos - nd * sz * 4.0, pos, _a(col, 0.55), sz * 0.7)
			draw_colored_polygon(PackedVector2Array([pos + nd * sz * 1.6, pos + perp * sz * 0.6, pos - perp * sz * 0.6]), col2)
		"ice", "iceball":
			if style == "iceball":
				var sc: float = 0.6 + prog * 0.7
				draw_circle(pos, sz * sc, Color("#bfeeff"))
				draw_circle(pos + Vector2(-sz * 0.2, -sz * 0.2), sz * sc * 0.55, Color.WHITE)
				draw_arc(pos, sz * sc, 0.0, TAU, 20, Color("#58b8e8"), 3.0)
			else:
				draw_line(pos - nd * sz * 4.0, pos, _a(col, 0.4), sz)
				draw_colored_polygon(PackedVector2Array([pos + nd * sz * 1.6, pos + perp * sz * 0.6, pos - nd * sz * 1.2, pos - perp * sz * 0.6]), Color("#d8f6ff"))
		"bomb", "cross":
			draw_circle(pos, sz, Color("#2a1840") if style == "bomb" else Color("#3a1a58"))
			draw_circle(pos, sz * 0.62, col)
			draw_circle(pos + Vector2(-sz * 0.3, -sz * 0.3), sz * 0.2, Color.WHITE)
			draw_line(pos + Vector2(0.0, -sz), pos + Vector2(3.0, -sz - 6.0), col2, 2.0)
		"axe":
			var hd: Vector2 = Vector2.from_angle(rot + prog * 14.0)
			draw_line(pos - hd * sz * 1.4, pos + hd * sz * 1.4, Color("#6a5238"), 4.0)
			var pr: Vector2 = hd.orthogonal()
			draw_colored_polygon(PackedVector2Array([pos + hd * sz * 1.4, pos + hd * sz * 0.6 + pr * sz * 1.4, pos + hd * sz * 0.2 - pr * sz * 0.2, pos + hd * sz * 0.6 - pr * sz * 1.4]), Color("#c8d0dc"))
		_:
			draw_circle(pos, sz, col)


func _d_drops(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	var sz: float = 11.0 if style == "comet" else 7.0
	if style == "iceball":
		sz = 16.0
	for d in a["drops"]:
		var lt: float = float(a["t"]) - float(d["at"])
		var pos: Vector2 = _gp(d["pos"])
		if lt < 0.0:
			# aviso en el suelo
			if lt > -0.6:
				pass
			continue
		if bool(d["done"]):
			continue
		var f: float = clampf(lt / float(d["fall"]), 0.0, 1.0)
		# (la marca de impacto se dibuja en el suelo: _g_drops)
		var r: float = float(p["r"])
		var from: Vector2 = pos + Vector2(-r * 0.6, -460.0)
		var hp: Vector2 = from.lerp(pos, f * f)
		_missile(style, hp, (pos - from).normalized(), sz, ctx["col"], ctx["col2"], f, float(d["rot"]))


func _d_pool(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var c: Vector2 = _gp(a["c"])
	var f: float = clampf(float(a["t"]) / maxf(0.01, float(p["dur"])), 0.0, 1.0)
	var al: float = (1.0 - f) * 0.9 if f > 0.7 else 1.0
	var r: float = float(p["r"])
	var pulse: float = 1.0 + 0.04 * sin(T * 6.0)
	under.draw_colored_polygon(_poly_circle(c, r * pulse, r * 0.62 * pulse, 16), _a(ctx["dark"], 0.38 * al))
	under.draw_colored_polygon(_poly_circle(c, r * 0.7, r * 0.43, 12), _a(ctx["col"], 0.3 * al))
	under.draw_polyline(_poly_circle(c, r * pulse, r * 0.62 * pulse, 24) + PackedVector2Array([c + Vector2(r * pulse, 0.0)]), _a(ctx["col2"], 0.7 * al), 2.0)


func _d_vortex(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var c: Vector2 = _gp(a["c"])
	var r: float = float(p["r"])
	var style: String = String(p["style"])
	var tf: float = clampf(float(a["t"]) / 0.35, 0.0, 1.0)
	var out: float = clampf((float(p["dur"]) - float(a["t"])) / 0.4, 0.0, 1.0)
	var k: float = tf * out
	var col: Color = ctx["col"]
	# (la sombra del vortice va en el suelo: _g_vortex)
	var arms := 3 if lite == 0 and _ld() > 0.6 else 2
	for ai in arms:
		var pts := PackedVector2Array()
		for i in 22:
			var tt: float = float(i) / 21.0
			var an: float = float(a["ang"]) + TAU * float(ai) / float(arms) + tt * 5.0
			var rr: float = r * tt * k
			pts.append(c + Vector2(cos(an) * rr, sin(an) * rr * 0.62) + Vector2(0.0, -tt * tt * 55.0 * k))
		draw_polyline(pts, _a(col, 0.55 * k), 7.0)
		draw_polyline(pts, _a(ctx["col2"], 0.8 * k), 3.0)
	if style == "dark":
		draw_arc(c, 22.0 * k, 0.0, TAU, 20, ctx["col2"], 3.0)
	var nb: int = int(p.get("blades", 0))
	for bi in nb:
		var an2: float = -float(a["ang"]) * 1.4 + TAU * float(bi) / float(nb)
		var bp: Vector2 = c + Vector2(cos(an2) * r * 0.8, sin(an2) * r * 0.5)
		draw_colored_polygon(PackedVector2Array([bp + Vector2.from_angle(an2 + 1.57) * 12.0, bp + Vector2.from_angle(an2) * 5.0, bp - Vector2.from_angle(an2 + 1.57) * 12.0]), _a(ctx["col2"], 0.9))


func _d_beam(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var o: Vector2 = _gp(_org())
	var wind: float = float(p.get("wind", 0.0))
	var t: float = float(a["t"])
	var w: float = float(p["w"])
	if t < wind:
		var f: float = t / wind
		draw_circle(o, w * 0.28 * f, _a(ctx["col"], 0.35))
		draw_circle(o, w * 0.1 * f, Color.WHITE)
		var dv: Vector2 = Vector2.from_angle(float(a["ang0"]))
		draw_line(o, o + dv * float(p["len"]), _a(ctx["col"], 0.18 + 0.3 * f), 2.0)
		return
	var bt: float = t - wind
	var fade: float = clampf((float(p["dur"]) - bt) / 0.3, 0.0, 1.0) * clampf(bt / 0.1, 0.0, 1.0)
	var cnt: int = int(p.get("count", 1))
	for bi in cnt:
		var ang: float = _beam_ang(a, bi, bt)
		var dv2: Vector2 = Vector2.from_angle(ang)
		var tip: Vector2 = o + dv2 * float(p["len"])
		var fl: float = 1.0 + 0.1 * sin(T * 40.0 + float(bi))
		# rayo mas fino y translucido que su zona de daño: se ve el campo (y al Pokemon) a traves
		if lite == 0 and _ld() > 0.6:
			draw_line(o, tip, _a(ctx["col"], 0.18 * fade), w * 0.8 * fl)
		draw_line(o, tip, _a(ctx["col2"], 0.6 * fade), w * 0.38 * fl)
		draw_line(o, tip, _a(Color.WHITE, 0.8 * fade), w * 0.14 * fl)
		if lite == 0 and _ld() > 0.6:
			draw_circle(tip, w * 0.25 * fade, _a(ctx["col"], 0.4 * fade))


func _d_bolts(a: Dictionary) -> void:
	var ctx: Dictionary = a["ctx"]
	var p: Dictionary = a["p"]
	for v in a["vis"]:
		var f: float = clampf(float(v["t"]) / float(v["life"]), 0.0, 1.0)
		var al: float = 1.0 - f
		var pts := PackedVector2Array()
		for q in v["pts"]:
			pts.append(_gp(q))
		if String(p["style"]) == "holy" and not v.has("arc"):
			var top: Vector2 = pts[0]
			var bot: Vector2 = pts[pts.size() - 1]
			var wd: float = float(v["r"]) * (0.7 - 0.3 * f)
			draw_line(top, bot, _a(ctx["col2"], 0.45 * al), wd * 0.8)
			draw_line(top, bot, _a(Color.WHITE, 0.8 * al), wd * 0.3)
			draw_circle(bot, wd * 0.6, _a(Color.WHITE, 0.4 * al))
		else:
			if lite == 0 and _ld() > 0.6:
				draw_polyline(pts, _a(ctx["col"], 0.45 * al), 6.0)
			draw_polyline(pts, _a(ctx["col2"], 0.9 * al), 3.0)
			draw_polyline(pts, _a(Color.WHITE, al), 1.5)


func _d_prison(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var c: Vector2 = _gp(a["c"])
	var r: float = float(p["r"])
	var n: int = int(p["n"])
	var style: String = String(p["style"])
	var up: float = clampf(float(a["t"]) / 0.45, 0.0, 1.0)
	var fadeo: float = clampf((float(p["dur"]) - float(a["t"])) / 0.4, 0.0, 1.0)
	var k: float = up * fadeo
	var tops: Array = []
	for i in n:
		var an: float = TAU * float(i) / float(n) + (0.0 if style != "crystal" else float(a["t"]) * 0.3)
		var b: Vector2 = c + Vector2(cos(an) * r, sin(an) * r * 0.62)
		var h: float = 78.0 * up
		var tp: Vector2 = b + Vector2(0.0, -h)
		tops.append(tp)
		match style:
			"electric":
				draw_line(b, tp, _a(ctx["col"], 0.9 * fadeo), 7.0)
				draw_line(b, tp, _a(Color.WHITE, 0.9 * fadeo), 2.0)
				draw_circle(tp, 7.0, ctx["col2"])
			"crystal":
				draw_colored_polygon(PackedVector2Array([b + Vector2(-9.0, 0.0), tp + Vector2(0.0, -10.0), b + Vector2(9.0, 0.0)]), _a(Color("#bff0ff"), 0.95 * fadeo))
				draw_polyline(PackedVector2Array([b + Vector2(-9.0, 0.0), tp + Vector2(0.0, -10.0), b + Vector2(9.0, 0.0)]), _a(Color.WHITE, fadeo), 2.0)
			_:
				draw_line(b, tp, _a(Color("#9aa8b8"), fadeo), 6.0)
				draw_circle(tp, 8.0, _a(Color("#c8d0dc"), fadeo))
				draw_arc(tp, 8.0, 0.0, TAU, 12, _a(Color("#606878"), fadeo), 3.0)
	for i in n:
		var t0: Vector2 = tops[i]
		var t1: Vector2 = tops[(i + 1) % n]
		if style == "electric":
			var seg := PackedVector2Array()
			for j in 7:
				var tt: float = float(j) / 6.0
				var q: Vector2 = t0.lerp(t1, tt)
				if j > 0 and j < 6:
					q.y += randf_range(-9.0, 9.0)
				seg.append(q)
			draw_polyline(seg, _a(ctx["col2"], 0.9 * k), 3.0)
		elif style == "crystal":
			if i % 3 != 0:
				draw_line(t0, t1, _a(Color("#bff0ff"), 0.8 * k), 6.0)
		else:
			draw_line(t0, t1, _a(Color("#9aa8b8"), 0.9 * k), 3.0)
	if float(a["t"]) > float(p["dur"]) - 0.5:
		var f: float = (float(a["t"]) - (float(p["dur"]) - 0.5)) / 0.5
		draw_arc(c, r * (1.0 + f * 0.4), 0.0, TAU, 28, _a(Color.WHITE, 0.8 * (1.0 - f)), 5.0)


func _d_eruption(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	var r: float = float(p["r"])
	for cl in a["cols"]:
		var lt: float = float(a["t"]) - float(cl["at"])
		if lt < 0.0 or int(cl["state"]) == 2:
			continue
		var pos: Vector2 = _gp(cl["pos"])
		if int(cl["state"]) == 0:
			continue   # el aviso se dibuja en el suelo: _g_eruption
		var tt: float = lt - 0.4
		var rise: float = clampf(tt / 0.18, 0.0, 1.0)
		var fade: float = clampf((1.0 - tt) / 0.35, 0.0, 1.0)
		var h: float = (150.0 if style in ["pillar", "lava", "rock"] else 100.0) * rise
		match style:
			"rock", "pillar":
				var pts := PackedVector2Array([pos + Vector2(-r * 0.45, 0.0), pos + Vector2(-r * 0.3, -h * 0.8), pos + Vector2(0.0, -h), pos + Vector2(r * 0.32, -h * 0.75), pos + Vector2(r * 0.45, 0.0)])
				draw_colored_polygon(pts, _a(Color("#7a5c34"), fade))
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0.0, -h), pos + Vector2(r * 0.32, -h * 0.75), pos + Vector2(r * 0.45, 0.0), pos]), _a(Color("#a98650"), fade))
				draw_polyline(pts, _a(Color("#e0c890"), fade), 2.0)
			"lava":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-r * 0.5, 0.0), pos + Vector2(-r * 0.25, -h), pos + Vector2(r * 0.25, -h), pos + Vector2(r * 0.5, 0.0)]), _a(Color("#3a2018"), fade))
				draw_line(pos + Vector2(0.0, -h * 0.4), pos + Vector2(0.0, -h * 1.3), _a(Color("#ff7a2a"), fade), r * 0.5)
				draw_line(pos + Vector2(0.0, -h * 0.4), pos + Vector2(0.0, -h * 1.15), _a(Color("#ffd84a"), fade), r * 0.22)
			"spike":
				for si in 3:
					var ox: float = (float(si) - 1.0) * r * 0.45
					draw_colored_polygon(PackedVector2Array([pos + Vector2(ox - 9.0, 0.0), pos + Vector2(ox, -h * (0.7 + 0.3 * float(si % 2))), pos + Vector2(ox + 9.0, 0.0)]), _a(ctx["col"], fade))
					draw_polyline(PackedVector2Array([pos + Vector2(ox - 9.0, 0.0), pos + Vector2(ox, -h * (0.7 + 0.3 * float(si % 2))), pos + Vector2(ox + 9.0, 0.0)]), _a(ctx["col2"], fade), 2.0)
			"bloom":
				draw_line(pos, pos + Vector2(0.0, -h * 0.8), _a(Color("#3a7a2a"), fade), 5.0)
				for pi in 6:
					var an: float = TAU * float(pi) / 6.0 + float(cl["seed"])
					draw_colored_polygon(_poly_circle(pos + Vector2(0.0, -h * 0.8) + Vector2.from_angle(an) * r * 0.32, r * 0.2, r * 0.13, 6), _a(ctx["col"], fade))
				draw_circle(pos + Vector2(0.0, -h * 0.8), r * 0.16, _a(Color("#f0e060"), fade))
			"root":
				for ri in 4:
					var ox2: float = (float(ri) - 1.5) * r * 0.3
					var rp := PackedVector2Array()
					for j in 6:
						var q: float = float(j) / 5.0
						rp.append(pos + Vector2(ox2 + sin(q * 5.0 + float(cl["seed"]) + float(ri)) * 9.0, -q * h * 0.9))
					draw_polyline(rp, _a(Color("#4a6a2a"), fade), 6.0)
					draw_polyline(rp, _a(ctx["col"], fade), 3.0)
			_:
				draw_colored_polygon(PackedVector2Array([pos + Vector2(-r * 0.4, 0.0), pos + Vector2(0.0, -h), pos + Vector2(r * 0.4, 0.0)]), _a(ctx["col"], fade))
		draw_arc(pos, r * (0.9 + 0.5 * rise), 0.0, TAU, 24, _a(ctx["col2"], 0.7 * fade), 3.0)


func _d_orbit(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	for o in a["orbs"]:
		var pos: Vector2 = _gp(o["pos"])
		if bool(o["launched"]) and float(o["life"]) <= 0.0:
			continue
		var ang: float = float(o["ang"])
		match style:
			"ghost":
				var bob: float = sin(T * 6.0 + ang * 3.0) * 3.0
				var gp: Vector2 = pos + Vector2(0.0, bob)
				var body := PackedVector2Array([gp + Vector2(-11.0, 12.0), gp + Vector2(-13.0, -4.0), gp + Vector2(-6.0, -14.0), gp + Vector2(6.0, -14.0), gp + Vector2(13.0, -4.0), gp + Vector2(11.0, 12.0), gp + Vector2(5.0, 8.0), gp + Vector2(0.0, 13.0), gp + Vector2(-5.0, 8.0)])
				draw_colored_polygon(body, _a(ctx["col"], 0.85))
				draw_circle(gp + Vector2(-4.5, -3.0), 2.4, Color.WHITE)
				draw_circle(gp + Vector2(4.5, -3.0), 2.4, Color.WHITE)
				draw_circle(gp + Vector2(-4.5, -3.0), 1.0, Color("#201030"))
				draw_circle(gp + Vector2(4.5, -3.0), 1.0, Color("#201030"))
			"dragon":
				var dv: Vector2 = Vector2.from_angle(ang + 1.57)
				draw_line(pos - dv * 22.0, pos, _a(ctx["col"], 0.5), 8.0)
				draw_colored_polygon(PackedVector2Array([pos + dv * 14.0, pos + dv.orthogonal() * 7.0, pos - dv * 4.0, pos - dv.orthogonal() * 7.0]), ctx["col2"])
				draw_circle(pos + dv * 6.0, 2.0, Color.WHITE)
			_:
				draw_circle(pos, 9.0, ctx["col"])
				draw_circle(pos, 5.0, ctx["col2"])


func _d_slashes(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	for s in a["sl"]:
		var lt: float = float(a["t"]) - float(s["at"])
		if int(s["state"]) == 2:
			continue
		var pos: Vector2 = _gp(s["pos"])
		if int(s["state"]) == 0:
			if lt < 0.0:
				continue
			var f: float = clampf(lt / float(p.get("mark", 0.5)), 0.0, 1.0)
			var rr: float = 46.0 * (1.5 - 0.5 * f)
			draw_arc(pos, rr, 0.0, TAU, 20, _a(ctx["col"], 0.4 + 0.5 * f), 2.0)
			draw_line(pos + Vector2(-rr - 6.0, 0.0), pos + Vector2(-rr + 8.0, 0.0), _a(ctx["col2"], 0.9), 2.0)
			draw_line(pos + Vector2(rr + 6.0, 0.0), pos + Vector2(rr - 8.0, 0.0), _a(ctx["col2"], 0.9), 2.0)
			draw_line(pos + Vector2(0.0, -rr - 6.0), pos + Vector2(0.0, -rr + 8.0), _a(ctx["col2"], 0.9), 2.0)
			draw_line(pos + Vector2(0.0, rr + 6.0), pos + Vector2(0.0, rr - 8.0), _a(ctx["col2"], 0.9), 2.0)
			if style == "divine":
				var sy: float = -300.0 + 280.0 * f * f
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0.0, sy + 40.0), pos + Vector2(-8.0, sy), pos + Vector2(0.0, sy - 60.0), pos + Vector2(8.0, sy)]), _a(Color("#fff0b0"), 0.9 * f))
			continue
		var f2: float = clampf(lt / 0.45, 0.0, 1.0)
		var al: float = 1.0 - f2
		for sg in (s.get("segs", []) as Array):
			var v0: Vector2 = _gp(sg[0])
			var v1: Vector2 = _gp(sg[1])
			var reveal: float = clampf(f2 * 4.0, 0.0, 1.0)
			var ve: Vector2 = v0.lerp(v1, reveal)
			if lite == 0 and _ld() > 0.6:
				draw_line(v0, ve, _a(ctx["col"], 0.4 * al), 10.0 * (1.0 - f2 * 0.5))
			draw_line(v0, ve, _a(ctx["col2"], 0.9 * al), 5.0 * (1.0 - f2 * 0.5))
			draw_line(v0, ve, _a(Color.WHITE, al), 2.0)
		if style == "divine":
			draw_line(pos + Vector2(0.0, -300.0), pos, _a(Color("#fff0b0"), 0.3 * al), 22.0 * al)


func _d_waves(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	for w in a["waves"]:
		if float(w["dist"]) >= float(p["range"]):
			continue
		var pos: Vector2 = _gp(w["pos"])
		var dv: Vector2 = w["dir"]
		var ang: float = dv.angle()
		var wd: float = float(p["w"])
		var fade: float = clampf((float(p["range"]) - float(w["dist"])) / 80.0, 0.0, 1.0)
		match style:
			"wing", "tide", "poison":
				var pts := PackedVector2Array()
				var sweep: float = 1.0 if style != "tide" else 1.1
				for i in 16:
					var tt: float = float(i) / 15.0
					var an: float = ang - sweep + tt * sweep * 2.0
					var rr: float = wd * (1.0 + (0.0 if style == "tide" else 0.25))
					pts.append(pos - dv * wd * 0.8 + Vector2.from_angle(an) * rr)
				if lite == 0 and _ld() > 0.6:
					draw_polyline(pts, _a(ctx["col"], 0.35 * fade), 12.0)
				draw_polyline(pts, _a(ctx["col2"], 0.8 * fade), 6.0)
				draw_polyline(pts, _a(Color.WHITE, 0.9 * fade), 2.0)
				if style == "wing":
					for fi in 4:
						var tt2: float = 0.15 + 0.23 * float(fi)
						var an2: float = ang - 1.0 + tt2 * 2.0 * 1.0
						draw_line(pos - dv * wd * 0.8 + Vector2.from_angle(an2) * wd * 1.2, pos - dv * wd * 1.5 + Vector2.from_angle(an2) * wd * 1.0, _a(ctx["col2"], 0.6 * fade), 3.0)
			"shard":
				var perp: Vector2 = dv.orthogonal()
				draw_colored_polygon(PackedVector2Array([pos + dv * wd * 1.3, pos + perp * wd * 0.4, pos - dv * wd * 0.8, pos - perp * wd * 0.4]), _a(Color("#d8f6ff"), fade))
				draw_polyline(PackedVector2Array([pos + dv * wd * 1.3, pos + perp * wd * 0.4, pos - dv * wd * 0.8, pos - perp * wd * 0.4, pos + dv * wd * 1.3]), _a(ctx["col"], fade), 2.0)
			"drill":
				var perp2: Vector2 = dv.orthogonal()
				var spin: float = T * 30.0
				draw_colored_polygon(PackedVector2Array([pos + dv * wd * 2.0, pos + perp2 * wd * 0.9, pos - dv * wd * 1.2, pos - perp2 * wd * 0.9]), _a(Color("#8a7048"), fade))
				for gi in 4:
					var gt: float = fposmod(spin + float(gi) * 0.9, 3.6) / 3.6
					var gp: Vector2 = pos + dv * wd * (1.8 - gt * 3.0)
					draw_line(gp - perp2 * wd * 0.8 * (1.0 - gt * 0.4), gp + perp2 * wd * 0.8 * (1.0 - gt * 0.4), _a(Color("#e0c890"), fade), 3.0)


func _d_seekers(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var style: String = String(p["style"])
	for s in a["sk"]:
		if bool(s["done"]) or float(a["t"]) < float(s["at"]):
			continue
		var pos: Vector2 = _gp(s["pos"])
		var tr: Array = s["trail"]
		for i in range(1, tr.size()):
			var f: float = float(i) / float(tr.size())
			draw_line(_gp(tr[i - 1]), _gp(tr[i]), _a(ctx["col"], 0.6 * f), 2.0 + 6.0 * f)
		var dv: Vector2 = (s["vel"] as Vector2).normalized()
		match style:
			"bone":
				draw_line(pos - dv * 10.0, pos + dv * 10.0, Color("#efe9d8"), 5.0)
				draw_circle(pos + dv * 10.0, 4.0, Color("#efe9d8"))
				draw_circle(pos - dv * 10.0, 4.0, Color("#efe9d8"))
			"dragon":
				draw_colored_polygon(PackedVector2Array([pos + dv * 16.0, pos + dv.orthogonal() * 8.0, pos - dv * 10.0, pos - dv.orthogonal() * 8.0]), ctx["col"])
				draw_circle(pos + dv * 4.0, 3.0, ctx["col2"])
			"ram":
				draw_circle(pos, 11.0, ctx["col"])
				draw_circle(pos, 6.0, Color("#fff0a0"))
				draw_line(pos, pos - dv * 18.0, Color("#6ad8ff"), 3.0)
			"mirage":
				draw_circle(pos, 10.0, _a(ctx["col"], 0.5))
				draw_arc(pos, 10.0, 0.0, TAU, 14, ctx["col2"], 2.0)
			"ghostfire":
				draw_colored_polygon(PackedVector2Array([pos + dv * 14.0, pos + dv.orthogonal() * 8.0, pos - dv * 12.0, pos - dv.orthogonal() * 8.0]), _a(ctx["col"], 0.9))
				draw_circle(pos, 4.0, Color.WHITE)
			_:
				draw_colored_polygon(PackedVector2Array([pos + dv * 12.0, pos + dv.orthogonal() * 4.0, pos - dv * 8.0, pos - dv.orthogonal() * 4.0]), ctx["col2"])
	for c in (a.get("crosses", []) as Array):
		var f2: float = clampf(float(c[1]) / 0.45, 0.0, 1.0)
		var cp: Vector2 = _gp(c[0])
		var ln: float = 44.0 * (0.5 + f2)
		draw_line(cp + Vector2(-ln, 0.0), cp + Vector2(ln, 0.0), _a(ctx["col"], 1.0 - f2), 8.0)
		draw_line(cp + Vector2(0.0, -ln), cp + Vector2(0.0, ln), _a(ctx["col"], 1.0 - f2), 8.0)
		draw_line(cp + Vector2(-ln, 0.0), cp + Vector2(ln, 0.0), _a(ctx["col2"], 1.0 - f2), 3.0)
		draw_line(cp + Vector2(0.0, -ln), cp + Vector2(0.0, ln), _a(ctx["col2"], 1.0 - f2), 3.0)
	if bool(p.get("mark", 0)):
		for e in (ctx["marked"] as Array):
			if is_instance_valid(e) and not e.dead:
				var mp: Vector2 = _gp(e.position)
				draw_arc(mp, 26.0, 0.0, TAU, 16, _a(ctx["col2"], 0.9), 2.0)
				draw_line(mp + Vector2(-34.0, 0.0), mp + Vector2(-20.0, 0.0), ctx["col2"], 2.0)
				draw_line(mp + Vector2(34.0, 0.0), mp + Vector2(20.0, 0.0), ctx["col2"], 2.0)


func _d_nova(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var rmax: float = float(p["rmax"])
	for rg in a["rings"]:
		var f: float = clampf(float(rg["t"]) / 0.7, 0.0, 1.0)
		if f >= 1.0:
			continue
		var r: float = rmax * (1.0 - pow(1.0 - f, 2.0))
		var c: Vector2 = _gp(rg["c"])
		var al: float = 1.0 - f
		var col: Color = rg["col"]
		if lite == 0 and _ld() > 0.6:
			draw_arc(c, r, 0.0, TAU, 36, _a(col, 0.3 * al), 22.0)
		draw_arc(c, r, 0.0, TAU, 36, _a(col, 0.9 * al), 9.0)
		draw_arc(c, r, 0.0, TAU, 36, _a(Color.WHITE, 0.9 * al), 3.0)
		if String(p["style"]) == "psychic":
			for i in 8:
				var an: float = TAU * float(i) / 8.0 + f * 2.0
				draw_circle(c + Vector2.from_angle(an) * r, 5.0, _a(Color.WHITE, al))


func _d_sanct(a: Dictionary) -> void:
	var p: Dictionary = a["p"]
	var ctx: Dictionary = a["ctx"]
	var c: Vector2 = _gp(a["c"])
	var r: float = float(p["r"])
	var f: float = clampf(float(a["t"]) / 0.5, 0.0, 1.0) * clampf((float(p["dur"]) - float(a["t"])) / 0.6, 0.0, 1.0)
	if f <= 0.01:
		return
	under.draw_colored_polygon(_poly_circle(c, r * f, r * 0.62 * f, 20), _a(ctx["col"], 0.2))
	under.draw_polyline(_poly_circle(c, r * f, r * 0.62 * f, 24) + PackedVector2Array([c + Vector2(r * f, 0.0)]), _a(ctx["col2"], 0.9 * f), 3.0)
	under.draw_polyline(_poly_circle(c, r * 0.6 * f, r * 0.37 * f, 18) + PackedVector2Array([c + Vector2(r * 0.6 * f, 0.0)]), _a(ctx["col2"], 0.7 * f), 2.0)
	for i in 6:
		var an: float = float(a["t"]) * 0.7 + TAU * float(i) / 6.0
		under.draw_line(c, c + Vector2(cos(an) * r * 0.6 * f, sin(an) * r * 0.37 * f), _a(ctx["col2"], 0.45 * f), 2.0)
	# cupula
	under.draw_arc(c + Vector2(0.0, -4.0), r * 0.5 * f, PI, TAU, 16, _a(Color.WHITE, 0.35 * f), 3.0)


# Velo de eclipse / luna: va en la capa del suelo (bajo los Pokemon) y mas suave, para no oscurecer al jugador.
func _draw_tint() -> void:
	if lite >= 2 or _ld() < 0.5:
		return
	var k: String = String(tint["kind"])
	var f: float = clampf(float(tint["t"]) / float(tint["dur"]), 0.0, 1.0)
	var al: float = sin(f * PI)
	var c: Vector2 = _gp(tint["c"])
	if k == "dark":
		under.draw_colored_polygon(_poly_circle(c, 620.0, 380.0, 24), Color(0.03, 0.0, 0.08, 0.32 * al))
		under.draw_circle(c + Vector2(0.0, -250.0), 56.0, Color(0.0, 0.0, 0.0, 0.9 * al))
		under.draw_arc(c + Vector2(0.0, -250.0), 60.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.4, 0.7 * al), 5.0)
	else:
		under.draw_colored_polygon(_poly_circle(c, 620.0, 380.0, 24), Color(0.25, 0.0, 0.05, 0.26 * al))
		under.draw_circle(c + Vector2(0.0, -260.0), 70.0, Color(0.85, 0.12, 0.2, 0.9 * al))
		under.draw_circle(c + Vector2(-14.0, -272.0), 62.0, Color(1.0, 0.35, 0.4, 0.5 * al))
