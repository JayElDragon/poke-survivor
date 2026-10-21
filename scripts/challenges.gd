extends RefCounted
# Retos de 10 minutos (seccion 29): 100 retos permanentes + 3 diarios + 5 semanales.
# Los datos estan en challenges_data.gd (generado). Aqui: disponibilidad, rotacion, progreso, comprobacion y cobro.
# Cada intento dura como maximo CH_TIME segundos. El premio se concede UNA vez por reto/instancia y perfil.

const SV = preload("res://scripts/save_data.gd")
const PG = preload("res://scripts/progress.gd")
const L = preload("res://scripts/lang.gd")
const DATA = preload("res://scripts/challenges_data.gd")

const CH_TIME := 600.0
# Sistemas que ya existen en el juego. Un reto cuya lista "need" tenga algo que NO este aqui sale como "Proximamente".
# (Se van anadiendo conforme se implementan: elite, fusion, gachapon, slots, ...)
const READY: Array = ["gachapon", "upgrade", "infat"]

const DIFF_NAME := {"e": "Fácil", "n": "Normal", "h": "Difícil", "x": "Nivel experto"}
const DIFF_COL := {"e": Color("#7fe08a"), "n": Color("#6fb4ff"), "h": Color("#ffb454"), "x": Color("#ff6b8a")}

# Texto de cada requisito. "%d" = objetivo (los de tiempo se muestran en minutos). Las claves "kills_type:<t>" llevan el tipo.
const LABEL := {
	"survive": "Sobrevive %d min",
	"survive_full": "Sobrevive los 10 minutos completos",
	"nodmg": "%d min seguidos sin recibir daño",
	"kills": "Enemigos derrotados: %d",
	"move_min": "Minutos distintos con movimiento: %d",
	"dodges": "Esquivas con éxito: %d",
	"surround": "Cercos de enemigos esquivados: %d",
	"elites": "Élites derrotados: %d",
	"bosses": "Jefes derrotados: %d",
	"crits": "Golpes críticos: %d",
	"kills_status": "Derrotados con un estado alterado: %d",
	"legend": "Derrota al legendario designado",
	"burn_n": "Enemigos distintos quemados: %d",
	"poison_n": "Enemigos distintos envenenados: %d",
	"freeze_n": "Enemigos distintos congelados: %d",
	"para_n": "Enemigos distintos paralizados: %d",
	"infat_n": "Enemigos distintos enamorados: %d",
	"kinds": "Tipos de estado distintos aplicados: %d",
	"kills_cc": "Derrotados bajo control de masas: %d",
	"multi_status_n": "Enemigos con 2 estados distintos: %d",
	"evolves": "Movimientos evolucionados: %d",
	"bonded": "Movimientos vinculados activos: %d",
	"fusions": "Fusiones realizadas: %d",
	"kills_after_fusion": "Derrotados tras la fusión: %d",
	"kills_proj": "Derrotados con proyectiles: %d",
	"kills_melee": "Derrotados cuerpo a cuerpo: %d",
	"kills_aoe": "Derrotados con ataques de área: %d",
	"moves_20": "Movimientos con 20 derrotas cada uno: %d",
	"types_10": "Tipos con 10 derrotas cada uno: %d",
	"types_20": "Tipos con 20 derrotas cada uno: %d",
	"types_any": "Tipos de movimiento usados: %d",
	"env_kills": "Derrotados con bono de entorno activo: %d",
	"upgrades": "Mejoras compradas: %d",
	"milestones": "Objetos en su siguiente hito: %d",
	"pierce3": "Ataques que golpean a 3 o más enemigos: %d",
	"double": "Golpes dobles: %d",
	"lifesteal": "Vida recuperada con robo de vida: %d",
	"coins": "Pokémonedas recogidas: %d",
	"coins_end": "Terminar con al menos %d Pokémonedas",
	"loot": "Objetos de botín recogidos: %d",
	"equipped": "Movimientos equipados: %d",
	"slot_buys": "Ampliaciones de hueco compradas: %d",
	"slots6": "Alcanza los 6 huecos de movimiento",
	"gacha_unlock": "Movimientos desbloqueados en el Gachapon: %d",
	"new_move": "Movimientos nuevos desbloqueados: %d",
	"compat_kills": "Derrotados con un movimiento compatible: %d",
	"moves_used": "Movimientos distintos usados: %d",
	"waves": "Oleadas superadas: %d",
	"outbreak_kills": "Derrotados en el brote controlado: %d",
	"boss_clean": "Jefes derrotados sin recibir su daño: %d",
}
const RS_LABEL := {
	"no_heal": "Sin curación activa",
	"frail": "Tu vida máxima se reduce a la mitad",
	"max_moves": "Máximo 2 movimientos de ataque",
	"one_move": "Solo puedes tener 1 movimiento de ataque",
	"one_hp": "Tu vida máxima es 1 y no puedes curarte",
	"no_move": "Tu Pokémon no puede caminar",
	"no_evo": "No puedes evolucionar movimientos",
	"no_fusion": "No puedes fusionar movimientos",
	"no_upgrade": "No puedes comprar mejoras",
	"no_status": "Los estados alterados no cuentan",
	"no_crit": "Los golpes críticos no cuentan",
	"coins_max": "Máximo %d Pokémonedas recogidas",
}
# Para claves con objetivo "1" que se muestran como una frase (sin numero).
const NO_NUM := ["survive_full", "legend", "slots6"]


static func all() -> Array:
	return DATA.ALL


static func by_id(id: int) -> Dictionary:
	for d in DATA.ALL:
		if int(d["id"]) == id:
			return d
	return {}


static func available(d: Dictionary) -> bool:
	for n in d["need"]:
		if not READY.has(String(n)):
			return false
	return true


static func name_of(d: Dictionary) -> String:
	return L.t(String(d["n"]))


# ---- persistencia: SV.d["chal"] = {"done": {clave: marca de tiempo}, "best": {id: segundos}} ----
static func st() -> Dictionary:
	if not SV.d.has("chal") or not (SV.d["chal"] is Dictionary):
		SV.d["chal"] = {}
	var s: Dictionary = SV.d["chal"]
	if not s.has("done"):
		s["done"] = {}
	if not SV.d.has("gcoins"):
		SV.d["gcoins"] = 0
	if not SV.d.has("gold_coins"):
		SV.d["gold_coins"] = 0
	return s


static func key_perm(id: int) -> String:
	return "p%03d" % id


static func is_done(key: String) -> bool:
	return st()["done"].has(key)


# ---- rotacion diaria/semanal ----
# Usa el mismo reloj que las misiones (PG.period_ids): el mismo cambio de dia para todo el juego.
static func _pool(kinds: String) -> Array:
	var out: Array = []
	for d in DATA.ALL:
		if available(d) and kinds.contains(String(d["d"])) and not (d["gold"] and kinds != "x"):
			out.append(d)
	return out


static func _pick(pool: Array, n: int, st_rng: Array) -> Array:
	var p: Array = pool.duplicate()
	var out: Array = []
	while out.size() < n and not p.is_empty():
		var i: int = int(PG._rand(st_rng) * p.size())
		out.append(p[i])
		p.remove_at(i)
	return out


# 3 diarios: 1 facil, 1 normal y 1 dificil (si hay). Cada uno da 1 Gachapon Coin normal.
static func daily() -> Array:
	var ids: Dictionary = PG.period_ids()
	var key: String = String(ids["d"])
	var rng: Array = [PG._rng_state("chal-d-" + key)]
	var out: Array = []
	var i := 0
	for tier in ["e", "n", "h"]:
		var got: Array = _pick(_pool(tier), 1, rng)
		if got.is_empty():
			got = _pick(_pool("nh"), 1, rng)
		if not got.is_empty():
			out.append({"key": "d:%s:%d" % [key, i], "id": int(got[0]["id"]), "kind": "d", "gold": false})
		i += 1
	return out


# 5 semanales: 2 normales, 2 dificiles y 1 experto. Solo el experto (si lo hay) da la Gachapon Coin Dorada.
static func weekly() -> Array:
	var ids: Dictionary = PG.period_ids()
	var key: String = String(ids["w"])
	var rng: Array = [PG._rng_state("chal-w-" + key)]
	var out: Array = []
	var picks: Array = []
	var seen: Array = []
	for tier in [["n", 2], ["h", 2], ["x", 1]]:
		var pool: Array = []
		for d in _pool(String(tier[0])):
			if not seen.has(int(d["id"])):
				pool.append(d)
		for d in _pick(pool, int(tier[1]), rng):
			picks.append([d, String(tier[0])])
			seen.append(int(d["id"]))
	var i := 0
	for pk in picks:
		out.append({"key": "w:%s:%d" % [key, i], "id": int(pk[0]["id"]), "kind": "w", "gold": String(pk[1]) == "x"})
		i += 1
	return out


# Tiempo que falta para el siguiente cambio (segundos), con el mismo reloj de las misiones.
static func secs_to_reset(weekly_reset: bool) -> int:
	var t: int = PG.madrid_now()
	var dd: Dictionary = Time.get_datetime_dict_from_unix_time(t)
	var into_day: int = int(dd["hour"]) * 3600 + int(dd["minute"]) * 60 + int(dd["second"])
	var left: int = 86400 - into_day
	if weekly_reset:
		var wd: int = (int(dd["weekday"]) + 6) % 7
		left += (6 - wd) * 86400
	return left


static func fmt_left(s: int) -> String:
	var dd: int = s / 86400
	var hh: int = (s % 86400) / 3600
	var mm: int = (s % 3600) / 60
	if dd > 0:
		return "%dd %02dh" % [dd, hh]
	return "%dh %02dm" % [hh, mm]


# ---- recompensa ----
# Que moneda da cada reto: los 10 permanentes marcados "gold" y, como mucho, 1 semanal experto dan la Dorada.
static func reward_gold(inst: Dictionary) -> bool:
	if String(inst["kind"]) == "p":
		return bool(by_id(int(inst["id"])).get("gold", false))
	return bool(inst.get("gold", false))


static func instance_perm(d: Dictionary) -> Dictionary:
	return {"key": key_perm(int(d["id"])), "id": int(d["id"]), "kind": "p", "gold": bool(d["gold"])}


# Concede el premio UNA sola vez (clave guardada antes de entregar la moneda). Devuelve "" si ya estaba cobrado.
static func grant(inst: Dictionary) -> String:
	var s: Dictionary = st()
	var key: String = String(inst["key"])
	if s["done"].has(key):
		return ""
	s["done"][key] = int(Time.get_unix_time_from_system())
	var gold: bool = reward_gold(inst)
	if gold:
		SV.d["gold_coins"] = int(SV.d["gold_coins"]) + 1
	else:
		SV.d["gcoins"] = int(SV.d["gcoins"]) + 1
	SV.save()
	return "gold" if gold else "coin"


# ---- progreso ----
# Metricas de un intento (las rellena main.gd): ver new_metrics().
static func new_metrics() -> Dictionary:
	return {"time": 0.0, "survive_full": 0, "nodmg": 0.0, "nodmg_cur": 0.0, "kills": 0, "elites": 0, "bosses": 0, "crits": 0,
		"coins": 0, "loot": 0, "evolves": 0, "equipped": 0, "bonded": 0, "kills_status": 0, "kills_cc": 0,
		"kills_proj": 0, "kills_melee": 0, "kills_aoe": 0, "burn_n": 0, "poison_n": 0, "freeze_n": 0, "para_n": 0,
		"kinds": 0, "multi_status_n": 0, "pierce3": 0, "move_min": 0, "moves_20": 0, "types_10": 0, "types_20": 0, "types_any": 0,
		"moves_used": 0, "boss_clean": 0, "upgrades": 0, "dead": false, "heals": 0}


static func _val(m: Dictionary, key: String) -> float:
	if key.begins_with("kills_type:"):
		return float(m.get("kt_" + key.substr(11), 0))
	if key == "survive":
		return float(m.get("time", 0.0))
	if key == "nodmg":
		return float(m.get("nodmg", 0.0))
	return float(m.get(key, 0))


static func target_of(key: String, v) -> float:
	return float(v)


# Lineas de objetivo: [texto, valor actual, objetivo, cumplido, es_tiempo]
static func lines(d: Dictionary, m: Dictionary) -> Array:
	var out: Array = []
	var req: Dictionary = d["req"]
	for k in req:
		var key := String(k)
		var tg: float = float(req[k])
		var cur: float = _val(m, key)
		var txt := ""
		if key.begins_with("kills_type:"):
			var tn: String = L.t(String(preload("res://scripts/moves_data.gd").TYPE_NAME.get(key.substr(11), key.substr(11))))
			txt = L.t("Derrotados con movimientos de tipo %s: %d") % [tn, int(tg)]
		elif key == "survive" or key == "nodmg":
			txt = L.t(String(LABEL[key])) % int(tg / 60.0)
		elif NO_NUM.has(key):
			txt = L.t(String(LABEL[key]))
		elif key == "coins_end":
			txt = L.t(String(LABEL[key])) % int(tg)
		else:
			txt = L.t(String(LABEL.get(key, key))) % int(tg)
		var ok: bool = cur >= tg
		if key == "coins_end":
			ok = float(m.get("coins_now", 0)) >= tg
			cur = float(m.get("coins_now", 0))
		if key == "survive_full":
			ok = float(m.get("time", 0.0)) >= CH_TIME and not bool(m.get("dead", false))
			cur = minf(float(m.get("time", 0.0)), CH_TIME)
			tg = CH_TIME
		out.append([txt, cur, tg, ok, ["survive", "nodmg", "survive_full"].has(key)])
	return out


static func restrictions(d: Dictionary) -> Array:
	var out: Array = []
	var rs: Dictionary = d["rs"]
	for k in rs:
		var key := String(k)
		if key == "coins_max":
			out.append(L.t(String(RS_LABEL[key])) % int(rs[k]))
		elif RS_LABEL.has(key):
			out.append(L.t(String(RS_LABEL[key])))
	return out


# true si se cumplen TODOS los objetivos y ninguna restriccion se ha roto.
static func succeeded(d: Dictionary, m: Dictionary) -> bool:
	if bool(m.get("dead", false)):
		return false
	for ln in lines(d, m):
		if not bool(ln[3]):
			return false
	var rs: Dictionary = d["rs"]
	if rs.has("coins_max") and int(m.get("coins", 0)) > int(rs["coins_max"]):
		return false
	if (rs.has("no_heal") or rs.has("one_hp")) and int(m.get("heals", 0)) > 0:
		return false
	return true
