extends RefCounted
# S57.17: medallas de aventura (perfil persistente SV.d["medals"]). Solo cosmeticas; independientes de Desafios y Logros.
const SV = preload("res://scripts/save_data.gd")

const CATS := [["explore", "Exploración"], ["pokemon", "Pokémon"], ["events", "Eventos"], ["merch", "Comerciantes"], ["mastery", "Maestría"]]
const CAVE_TYPES := ["fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground", "psychic", "bug", "ghost", "dragon", "dark", "fairy"]
const KEC_VARS := ["green", "blue", "red", "purple", "gold", "shiny"]
# id, categoria, nombre, descripcion, objetivo
const LIST := [
	["cave1", "explore", "Espeleólogo", "Completa una cueva elemental.", 1],
	["cave_master", "mastery", "Maestro elemental", "Completa una cueva de cada uno de los 14 tipos disponibles.", 14],
	["secret1", "explore", "Ojo de halcón", "Descubre un secreto.", 1],
	["secret_hunter", "explore", "Cazador de secretos", "Descubre 25 secretos.", 25],
	["night", "events", "Superviviente nocturno", "Sobrevive a una noche entera.", 1],
	["inv1", "events", "Frente común", "Sobrevive a una invasión.", 1],
	["inv_night", "events", "Pesadilla superada", "Sobrevive a una invasión nocturna.", 1],
	["deoxys", "events", "Visitante del espacio", "Derrota a Deoxys.", 1],
	["mewtwo", "events", "Proyecto completado", "Derrota a Mewtwo.", 1],
	["kec_col", "merch", "Coleccionista de Kecleon", "Encuentra las 6 variantes de Kecleon.", 6],
	["alpha", "pokemon", "Domador de Alfas", "Captura un Pokémon Alfa.", 1],
	["alpha10", "pokemon", "Maestro de Alfas", "Captura 10 Pokémon Alfa.", 10],
	["rescue1", "pokemon", "Buen samaritano", "Rescata a un Pokémon herido.", 1],
	["guardian", "pokemon", "Guardián de Pokémon", "Rescata a 25 Pokémon.", 25],
]
static var pending: Array = []


static func _d() -> Dictionary:
	if not SV.d.has("medals") or typeof(SV.d["medals"]) != TYPE_DICTIONARY:
		SV.d["medals"] = {}
	return SV.d["medals"]


static func entry(id: String) -> Dictionary:
	var d: Dictionary = _d()
	if not d.has(id):
		d[id] = {"prog": 0, "got": false, "claimed": false, "set": []}
	return d[id]


static func def_of(id: String) -> Array:
	for a in LIST:
		if String(a[0]) == id:
			return a
	return []


static func _add(id: String, n: int = 1) -> void:
	var e: Dictionary = entry(id)
	if e["got"]:
		return
	e["prog"] = int(e["prog"]) + n
	_chk(id, e)


static func _add_set(id: String, key: String) -> void:
	var e: Dictionary = entry(id)
	if e["got"]:
		return
	var s: Array = e["set"]
	if not s.has(key):
		s.append(key)
	e["prog"] = s.size()
	_chk(id, e)


static func _chk(id: String, e: Dictionary) -> void:
	var df: Array = def_of(id)
	if not df.is_empty() and not e["got"] and int(e["prog"]) >= int(df[4]):
		e["got"] = true            # primero el estado: idempotente
		pending.append(id)


# Punto unico de entrada desde la partida.
static func event(name: String, data: Dictionary) -> void:
	match name:
		"cave":
			_add("cave1")
			_add_set("cave_master", String(data.get("type", "")))
		"secret":
			_add("secret1")
			_add("secret_hunter")
		"night":
			_add("night")
		"invasion":
			_add("inv1")
			if bool(data.get("night", false)) and String(data.get("kind", "")) == "nightmare":
				_add("inv_night")
		"deoxys":
			_add("deoxys")
		"mewtwo":
			_add("mewtwo")
		"kec":
			_add_set("kec_col", String(data.get("variant", "")))
		"alpha":
			_add("alpha")
			_add("alpha10")
		"rescue":
			_add("rescue1")
			_add("guardian")


static func count_got() -> int:
	var n := 0
	for a in LIST:
		if bool(entry(String(a[0]))["got"]):
			n += 1
	return n
