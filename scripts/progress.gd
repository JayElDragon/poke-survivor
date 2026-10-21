extends RefCounted
# Misiones, logros y titulos (progress.js + achievements.js + missions.js).
# Datos en SV.d: ach{id: t}, missions{...}, evoMoves{}, itemsFound{}, title, stats.*

const SV = preload("res://scripts/save_data.gd")
const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")

const CATS := [["coleccion", "Colección"], ["supervivencia", "Supervivencia"], ["combate", "Combate"], ["tipos", "Por tipo"],
	["grietas", "Grietas"], ["legendarios", "Legendarios"], ["modos", "Modos de juego"], ["otros", "Misiones y más"]]

static var toasts: Array = []
static var _list: Array = []
static var _by: Dictionary = {}
static var ach_t := 0.0


# ---------------- logros ----------------
static func _a(id: String, cat: String, tier: int, name: String, desc: String, stat: String, goal: int, reward: Dictionary, title: String = "", arg = null) -> Dictionary:
	return {"id": id, "cat": cat, "tier": tier, "name": name, "desc": desc, "stat": stat, "goal": goal, "reward": reward, "title": title, "dex": 0, "arg": arg}


static func name_of(a: Dictionary) -> String:
	var n: String = L_t(String(a["name"]))
	if a["arg"] != null and String(a["name"]).contains("%"):
		return n % (L_t(a["arg"]) if a["arg"] is String else a["arg"])
	return n


static func desc_of(a: Dictionary) -> String:
	var n: String = L_t(String(a["desc"]))
	if a["arg"] != null and String(a["desc"]).contains("%"):
		return n % (L_t(a["arg"]) if a["arg"] is String else a["arg"])
	return n


static func list() -> Array:
	if not _list.is_empty():
		return _list
	SV.load_dex()
	var L2: Array = []
	var ndex: int = SV.dex_list.size()
	# colección
	L2.append(_a("own1", "coleccion", 1, "Primer compañero", "Ten 1 Pokémon.", "own", 1, {"coins": 100}))
	L2.append(_a("own10", "coleccion", 1, "Pequeño equipo", "Ten 10 Pokémon.", "own", 10, {"t1": 2}))
	L2.append(_a("own50", "coleccion", 2, "Coleccionista", "Ten 50 Pokémon.", "own", 50, {"t1": 5}, "Coleccionista"))
	L2.append(_a("own100", "coleccion", 2, "Cien amigos", "Ten 100 Pokémon.", "own", 100, {"t10": 1}))
	L2.append(_a("own250", "coleccion", 3, "Maestro Pokémon", "Ten 250 Pokémon.", "own", 250, {"t10": 2}, "Maestro Pokémon"))
	L2.append(_a("own500", "coleccion", 3, "Enciclopedia", "Ten 500 Pokémon.", "own", 500, {"t10": 3}))
	L2.append(_a("ownAll", "coleccion", 3, "Profesor Pokémon", "Ten los %d Pokémon del juego.", "own", ndex, {"t10": 10}, "Profesor Pokémon", ndex))
	L2.append(_a("shiny1", "coleccion", 1, "Algo brilla", "Consigue 1 shiny.", "shinies", 1, {"t1": 3}, "Brillante"))
	L2.append(_a("shiny5", "coleccion", 2, "Ojo para el brillo", "Consigue 5 shinies.", "shinies", 5, {"t10": 1}))
	L2.append(_a("shiny20", "coleccion", 3, "Cazashinies", "Consigue 20 shinies.", "shinies", 20, {"t10": 2}, "Cazashinies"))
	L2.append(_a("pulls100", "coleccion", 2, "Tragaperras", "Haz 100 tiradas en el gacha.", "pulls", 100, {"t10": 1}, "Afortunado"))
	# supervivencia
	L2.append(_a("time5", "supervivencia", 1, "Calentando", "Aguanta 5 minutos.", "bestMin", 5, {"coins": 200}))
	L2.append(_a("time10", "supervivencia", 2, "Duro de pelar", "Aguanta 10 minutos.", "bestMin", 10, {"t1": 4}))
	L2.append(_a("time15", "supervivencia", 2, "Resistente", "Aguanta 15 minutos.", "bestMin", 15, {"t10": 1}))
	L2.append(_a("time20", "supervivencia", 3, "Superviviente", "Aguanta 20 minutos.", "bestMin", 20, {"t10": 2}, "Superviviente"))
	L2.append(_a("lvl20", "supervivencia", 1, "Creciendo", "Llega al nivel 15 en una run.", "bestLevel", 15, {"t1": 2}))
	L2.append(_a("lvl40", "supervivencia", 3, "Imparable", "Llega al nivel 30 en una run.", "bestLevel", 30, {"t10": 1}, "Imparable"))
	L2.append(_a("judge", "supervivencia", 2, "La Sentencia", "Llega a la Sentencia de Arceus (minuto 30).", "judged", 1, {"t10": 1}, "Juzgado"))
	L2.append(_a("judge60", "supervivencia", 3, "Ante el Creador", "Aguanta 1 minuto ante Arceus.", "judgeTime", 60, {"t10": 2}, "Elegido de Arceus"))
	L2.append(_a("judgeBoss", "supervivencia", 3, "Desafío divino", "Derrota a 3 legendarios ante Arceus en una partida.", "judgeBosses", 3, {"t10": 2}))
	L2.append(_a("runs50", "supervivencia", 2, "Explorador", "Juega 50 runs.", "runs", 50, {"t10": 1}, "Explorador"))
	# combate
	L2.append(_a("kills1k", "combate", 1, "Primeros combates", "Derrota a 1.000 Pokémon.", "totalKills", 1000, {"t1": 2}))
	L2.append(_a("kills10k", "combate", 2, "Veterano", "Derrota a 10.000 Pokémon.", "totalKills", 10000, {"t10": 1}, "Veterano"))
	L2.append(_a("kills100k", "combate", 3, "Leyenda viva", "Derrota a 100.000 Pokémon.", "totalKills", 100000, {"t10": 3}, "Leyenda viva"))
	L2.append(_a("boss1", "combate", 1, "Matagigantes", "Derrota a un jefe.", "bossesTotal", 1, {"t1": 2}))
	L2.append(_a("boss25", "combate", 2, "Cazajefes", "Derrota a 25 jefes.", "bossesTotal", 25, {"t10": 1}, "Cazajefes"))
	L2.append(_a("boss10", "combate", 1, "Aprendiz de cazajefes", "Derrota a 10 jefes.", "bossesTotal", 10, {"t1": 3}))
	L2.append(_a("boss100", "combate", 3, "Terror de los jefes", "Derrota a 100 jefes.", "bossesTotal", 100, {"t10": 2}))
	L2.append(_a("boss250", "combate", 3, "Azote de jefes", "Derrota a 250 jefes.", "bossesTotal", 250, {"t10": 3}))
	L2.append(_a("boss500", "combate", 3, "Verdugo de jefes", "Derrota a 500 jefes.", "bossesTotal", 500, {"t10": 5}, "Verdugo de jefes"))
	L2.append(_a("boss1000", "combate", 3, "Rey de los jefes", "Derrota a 1.000 jefes.", "bossesTotal", 1000, {"t10": 10}, "Rey de los jefes"))
	L2.append(_a("evo1", "combate", 1, "Evolución", "Evoluciona un movimiento.", "evolutions", 1, {"t1": 3}))
	L2.append(_a("evo25", "combate", 2, "Evolucionista", "Evoluciona 25 movimientos.", "evolutions", 25, {"t10": 1}, "Evolucionista"))
	var evo_total: int = MD.EVO.size()
	L2.append(_a("evoAll", "combate", 3, "Maestro de movimientos", "Evoluciona los %d movimientos distintos.", "evoMoves", evo_total, {"t10": 3}, "Maestro de movimientos", evo_total))
	L2.append(_a("items5", "combate", 1, "Bolsa llena", "Encuentra 5 objetos distintos.", "itemsFound", 5, {"t1": 3}))
	L2.append(_a("itemsAll", "combate", 2, "Coleccionista de objetos", "Encuentra los %d objetos.", "itemsFound", TD.ITEMS.size(), {"t10": 1}, "Anticuario", TD.ITEMS.size()))
	# por tipo: Pokemon derrotados de cada tipo (los de doble tipo cuentan para los dos)
	for tk in MD.TYPE_NAME.keys():
		var tn: String = String(MD.TYPE_NAME[tk])
		L2.append(_a("tk250_" + String(tk), "tipos", 1, "Rastreador de tipo %s", "Derrota a 250 Pokémon de tipo %s.", "tk_" + String(tk), 250, {"coins": 300, "t1": 2}, "", tn))
		L2.append(_a("tk1000_" + String(tk), "tipos", 2, "Cazador de tipo %s", "Derrota a 1.000 Pokémon de tipo %s.", "tk_" + String(tk), 1000, {"coins": 1000, "t1": 3, "t10": 1}, "", tn))
		L2.append(_a("tk5000_" + String(tk), "tipos", 3, "Maestro de tipo %s", "Derrota a 5.000 Pokémon de tipo %s.", "tk_" + String(tk), 5000, {"coins": 3000, "t10": 3}, "", tn))
	# grietas
	L2.append(_a("rift1", "grietas", 1, "Al otro lado", "Gana tu primera pelea en una grieta.", "riftWins", 1, {"t1": 3}, "Valiente"))
	L2.append(_a("rift10", "grietas", 2, "Saltagrietas", "Gana 10 peleas en grietas.", "riftWins", 10, {"t10": 1}))
	L2.append(_a("arenas", "grietas", 3, "Viajero de grietas", "Gana en las 18 arenas (una por tipo).", "arenas", 18, {"t10": 2}, "Viajero de grietas"))
	# legendarios (contadores)
	var legs: Array = []
	for p in SV.dex_list:
		if bool(p.get("leg", false)) and SV.smeta.has(str(int(p["dex"]))):
			legs.append(p)
	L2.append(_a("leg10", "legendarios", 2, "Cazalegendarios", "Vence a 10 legendarios distintos.", "legends", 10, {"t10": 1}, "Cazalegendarios"))
	L2.append(_a("leg30", "legendarios", 3, "Domador de mitos", "Vence a 30 legendarios distintos.", "legends", 30, {"t10": 2}))
	L2.append(_a("legAll", "legendarios", 3, "Leyenda", "Vence a los %d legendarios.", "legends", legs.size(), {"t10": 5}, "Leyenda", legs.size()))
	# misiones y mas
	L2.append(_a("mis10", "otros", 1, "Cumplidor", "Completa 10 misiones.", "missionsDone", 10, {"t1": 3}))
	L2.append(_a("mis50", "otros", 2, "Constante", "Completa 50 misiones.", "missionsDone", 50, {"t10": 1}, "Constante"))
	L2.append(_a("mis200", "otros", 3, "Incansable", "Completa 200 misiones.", "missionsDone", 200, {"t10": 3}))
	L2.append(_a("group1", "otros", 1, "En compañía", "Juega una partida en grupo.", "groupRuns", 1, {"t1": 2}))
	L2.append(_a("group10", "otros", 2, "Compañero fiel", "Juega 10 partidas en grupo.", "groupRuns", 10, {"t10": 1}, "Compañero fiel"))
	# modos de juego (premios segun dificultad)
	L2.append(_a("daily1", "modos", 1, "Reto del día", "Juega un Desafío diario.", "dailyPlays", 1, {"coins": 150, "t1": 2}))
	L2.append(_a("daily7", "modos", 2, "Rutina diaria", "Juega 7 Desafíos diarios.", "dailyPlays", 7, {"coins": 500, "t1": 5}))
	L2.append(_a("daily30", "modos", 3, "Fiel al reto", "Juega 30 Desafíos diarios.", "dailyPlays", 30, {"coins": 2000, "t1": 3, "t10": 2}, "Fiel al reto"))
	L2.append(_a("dailyMin10", "modos", 2, "Reto superado", "Aguanta 10 minutos en un Desafío diario.", "dailyBestMin", 10, {"coins": 1000, "t10": 1}))
	L2.append(_a("dailyMin20", "modos", 3, "Campeón del día", "Aguanta 20 minutos en un Desafío diario.", "dailyBestMin", 20, {"coins": 2500, "t10": 2}, "Campeón del día"))
	L2.append(_a("rush3", "modos", 1, "Calentamiento de jefes", "Derrota a 3 jefes en el Rush de Jefes.", "rushBest", 3, {"coins": 400, "t1": 3}))
	L2.append(_a("rush6", "modos", 2, "Ráfaga de jefes", "Derrota a 6 jefes en el Rush de Jefes.", "rushBest", 6, {"coins": 1200, "t10": 1}))
	L2.append(_a("rush10", "modos", 3, "Aplastajefes", "Derrota a 10 jefes en el Rush de Jefes.", "rushBest", 10, {"coins": 3000, "t1": 2, "t10": 2}))
	L2.append(_a("rush15", "modos", 3, "Rey del Rush", "Derrota a 15 jefes en el Rush de Jefes.", "rushBest", 15, {"coins": 6000, "t1": 3, "t10": 4}, "Rey del Rush"))
	L2.append(_a("rushRuns25", "modos", 2, "Cazador de récords", "Juega 25 Rush de Jefes.", "rushRuns", 25, {"coins": 1500, "t10": 1}))
	L2.append(_a("mod1", "modos", 1, "Con un extra", "Aguanta 5 minutos con un modificador activo.", "mn1", 5, {"coins": 300, "t1": 3}))
	L2.append(_a("mod3", "modos", 2, "Doble dificultad", "Aguanta 8 minutos con 3 modificadores.", "mn3", 8, {"coins": 1200, "t10": 1}))
	L2.append(_a("mod4", "modos", 3, "Sin red", "Aguanta 10 minutos con 4 modificadores.", "mn4", 10, {"coins": 3000, "t1": 2, "t10": 2}, "Sin red"))
	L2.append(_a("modAll", "modos", 3, "Masoquista", "Aguanta 5 minutos con los 6 modificadores.", "mn6", 5, {"coins": 6000, "t1": 3, "t10": 4}, "Masoquista"))
	L2.append(_a("noheal10", "modos", 2, "Sin curas", "Aguanta 10 minutos con «Sin curación».", "mb_nohealing", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("frail10", "modos", 2, "Cristal", "Aguanta 10 minutos con «Frágil».", "mb_frail", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("horde10", "modos", 2, "Entre la multitud", "Aguanta 10 minutos con «Horda».", "mb_horde", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("type1", "modos", 1, "Especialista", "Aguanta 5 minutos en Supervivencia por tipo.", "typeBestMin", 5, {"coins": 300, "t1": 3}))
	L2.append(_a("type10", "modos", 2, "Experto en tipo", "Aguanta 10 minutos en Supervivencia por tipo.", "typeBestMin", 10, {"coins": 1200, "t10": 1}))
	L2.append(_a("typeVar9", "modos", 3, "Todoterreno", "Aguanta 10 minutos en 9 tipos distintos de Supervivencia por tipo.", "typeVar", 9, {"coins": 3000, "t1": 3, "t10": 2}))
	L2.append(_a("typeAll", "modos", 3, "Maestro de tipos", "Aguanta 10 minutos en los 18 tipos de Supervivencia por tipo.", "typeVar", 18, {"coins": 8000, "t1": 5, "t10": 5}, "Maestro de tipos"))
	L2.append(_a("team1", "modos", 1, "Mejor en equipo", "Juega una partida en Modo Equipo.", "teamRuns", 1, {"coins": 150, "t1": 2}))
	L2.append(_a("team10", "modos", 2, "Relevo perfecto", "Aguanta 10 minutos en Modo Equipo.", "teamBestMin", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("team20", "modos", 3, "Líder de equipo", "Aguanta 20 minutos en Modo Equipo.", "teamBestMin", 20, {"coins": 3500, "t1": 2, "t10": 2}, "Líder de equipo"))
	L2.append(_a("rifts3", "modos", 1, "Contrarreloj", "Gana 3 grietas en una Contrarreloj de grietas.", "riftsBest", 3, {"coins": 500, "t1": 3}))
	L2.append(_a("rifts5", "modos", 2, "Pasillo de grietas", "Gana 5 grietas en una Contrarreloj de grietas.", "riftsBest", 5, {"coins": 1500, "t10": 1}))
	L2.append(_a("rifts8", "modos", 3, "Cazador contrarreloj", "Gana 8 grietas en una Contrarreloj de grietas.", "riftsBest", 8, {"coins": 3500, "t1": 3, "t10": 2}, "Cazador contrarreloj"))
	L2.append(_a("riftsRuns10", "modos", 2, "Siempre con prisa", "Juega 10 Contrarrelojes de grietas.", "riftsRuns", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("tower5", "modos", 1, "Primeros pisos", "Supera el piso 5 de la Torre.", "towerBest", 5, {"coins": 800, "t1": 3, "t10": 1}))
	L2.append(_a("tower10", "modos", 2, "Escalando", "Supera el piso 10 de la Torre.", "towerBest", 10, {"coins": 2000, "t1": 4, "t10": 2}))
	L2.append(_a("tower15", "modos", 3, "Casi en la cima", "Supera el piso 15 de la Torre.", "towerBest", 15, {"coins": 4000, "t1": 5, "t10": 3}))
	L2.append(_a("tower20", "modos", 3, "Escalador", "Supera el piso 20 de la Torre.", "towerBest", 20, {"coins": 7000, "t1": 6, "t10": 4}, "Escalador"))
	L2.append(_a("tower30", "modos", 3, "Dueño de la Torre", "Llega al piso 30 de la Torre.", "towerBest", 29, {"coins": 15000, "t1": 10, "t10": 8}, "Dueño de la Torre"))
	L2.append(_a("tower60", "modos", 3, "Cima de la Torre", "Llega al piso 60 de la Torre.", "towerBest", 59, {"coins": 30000, "t1": 15, "t10": 12}, "Cima de la Torre"))
	L2.append(_a("towerArceus", "modos", 3, "Vencedor de Arceus", "Derrota a Arceus, el jefe final del piso 60 de la Torre.", "arceus", 1, {"coins": 30000, "t1": 15, "t10": 15}, "Vencedor de Arceus"))
	L2.append(_a("towerRuns10", "modos", 2, "Aprendiz de la Torre", "Juega 10 veces la Torre.", "towerRuns", 10, {"coins": 1200, "t10": 1}))
	# uno por legendario
	for p in legs:
		var a: Dictionary = _a("leg_%d" % int(p["dex"]), "legendarios", 2, "Vence a %s", "Derrota a %s en una grieta.", "leg", 1, {"t1": 1}, "", String(p["name"]))
		a["dex"] = int(p["dex"])
		L2.append(a)
	_list = L2
	for a in _list:
		_by[String(a["id"])] = a
	return _list


static func is_multi(a: Dictionary) -> bool:
	return false   # el Modo Cooperativo ya cuenta como partida en grupo


static func stat(name: String) -> int:
	var s: Dictionary = SV.d["stats"]
	match name:
		"own":
			return SV.owned_count()
		"shinies":
			return int(s.get("shinies", 0))
		"pulls":
			return int(s.get("pulls", 0))
		"bestMin":
			return int(s.get("best_time", 0)) / 60
		"bestLevel":
			return int(s.get("best_level", 0))
		"runs":
			return int(s.get("runs", 0))
		"totalKills":
			return int(s.get("kills", 0))
		"bossesTotal":
			return int(s.get("bosses", 0))
		"riftWins":
			return int(s.get("rifts", 0))
		"evoMoves":
			return (SV.d.get("evoMoves", {}) as Dictionary).size()
		"itemsFound":
			return (SV.d.get("itemsFound", {}) as Dictionary).size()
		"arenas":
			return (SV.d.get("arenas", {}) as Dictionary).size()
		"typeVar":
			return (SV.d.get("type_done", {}) as Dictionary).size()
		"legends":
			return (SV.d.get("legends", {}) as Dictionary).size()
	return int(s.get(name, 0))


static func value(a: Dictionary) -> int:
	if String(a["stat"]) == "leg":
		return 1 if (SV.d.get("legends", {}) as Dictionary).has(str(int(a["dex"]))) else 0
	return stat(String(a["stat"]))


static func done(a: Dictionary) -> bool:
	return (SV.d.get("ach", {}) as Dictionary).has(String(a["id"]))


static func grant(r: Dictionary) -> void:
	SV.d["coins"] = int(SV.d["coins"]) + int(r.get("coins", 0))
	SV.d["tickets"] = int(SV.d["tickets"]) + int(r.get("t1", 0))
	SV.d["tickets10"] = int(SV.d.get("tickets10", 0)) + int(r.get("t10", 0))


static var off := false   # Modo Fiesta: no cuenta para logros ni estadisticas


static func check() -> Array:
	var got: Array = []
	if off:
		return got
	if not SV.d.has("ach"):
		SV.d["ach"] = {}
	var ach: Dictionary = SV.d["ach"]
	for a in list():
		if ach.has(String(a["id"])):
			continue
		if value(a) < int(a["goal"]):
			continue
		ach[String(a["id"])] = int(Time.get_unix_time_from_system())
		grant(a["reward"])
		got.append(a)
		toasts.append({"title": "¡Logro: %s!", "arg": name_of(a), "sub": "Nuevo título: %s" if String(a["title"]) != "" else "", "subarg": L_t(String(a["title"])), "tier": int(a["tier"]), "dex": int(a["dex"])})
	zcheck()
	if not got.is_empty():
		SV.save()
	return got


# ---------------- misiones de Cristales Z ----------------
# Una mision por tipo: al completarla se desbloquea el movimiento Z de ese tipo (igual que el cristal del gacha).
const ZMIS := [
	["normal", "Derrota a 1.500 Pokémon en total.", "totalKills", 1500],
	["fire", "Aguanta 8 minutos en una partida.", "bestMin", 8],
	["water", "Juega 15 partidas.", "runs", 15],
	["electric", "Llega al nivel 25 en una partida.", "bestLevel", 25],
	["grass", "Abre 25 cofres.", "chests", 25],
	["ice", "Haz 30 tiradas en el gacha.", "pulls", 30],
	["fighting", "Derrota a 10 jefes.", "bossesTotal", 10],
	["poison", "Evoluciona 10 movimientos.", "evolutions", 10],
	["ground", "Consigue 30 Pokémon.", "own", 30],
	["flying", "Juega 5 Desafíos diarios.", "dailyPlays", 5],
	["psychic", "Encuentra 10 objetos distintos.", "itemsFound", 10],
	["bug", "Derrota a 4 jefes en el Rush de Jefes.", "rushBest", 4],
	["rock", "Supera el piso 8 de la Torre.", "towerBest", 8],
	["ghost", "Gana 5 peleas en grietas.", "riftWins", 5],
	["dragon", "Aguanta 12 minutos en una partida.", "bestMin", 12],
	["dark", "Vence a 3 legendarios distintos.", "legends", 3],
	["steel", "Aguanta 8 minutos en Supervivencia por tipo.", "typeBestMin", 8],
	["fairy", "Aguanta 8 minutos en Modo Equipo.", "teamBestMin", 8],
]
const ZMIS_COINS := 500


static func zlist() -> Array:
	var out: Array = []
	for z in ZMIS:
		out.append({"id": "zc_" + String(z[0]), "type": String(z[0]), "desc": String(z[1]), "stat": String(z[2]), "goal": int(z[3])})
	return out


static func zdone(zm: Dictionary) -> bool:
	return (SV.d.get("zmis", {}) as Dictionary).has(String(zm["id"])) or int((SV.d["stats"] as Dictionary).get("zcr_" + String(zm["type"]), 0)) >= 1


static func zcheck() -> void:
	if off:
		return
	if not SV.d.has("zmis"):
		SV.d["zmis"] = {}
	var ZM = load("res://scripts/zmove.gd")
	var any := false
	for zm in zlist():
		if (SV.d["zmis"] as Dictionary).has(String(zm["id"])):
			continue
		if stat(String(zm["stat"])) < int(zm["goal"]):
			continue
		var t: String = String(zm["type"])
		SV.d["zmis"][String(zm["id"])] = int(Time.get_unix_time_from_system())
		SV.d["stats"]["zcr_" + t] = 1
		SV.d["coins"] = int(SV.d["coins"]) + ZMIS_COINS
		toasts.append({"title": "¡Cristal Z: %s!", "arg": String(ZM.DEF[t]["name"]), "sub": "", "subarg": "", "tier": 3, "dex": 0})
		any = true
	if any:
		SV.save()


static func titles() -> Array:
	var out: Array = []
	var ach: Dictionary = SV.d.get("ach", {})
	for a in list():
		if String(a["title"]) != "" and ach.has(String(a["id"])):
			out.append(String(a["title"]))
	return out


# ---------------- misiones ----------------
const DAILY := [
	{"id": "kill", "ev": "kill", "goals": [300, 500, 800], "reward": {"t1": 2, "coins": 150}},
	{"id": "killType", "ev": "kill", "param": "type", "goals": [30, 50, 80], "reward": {"t1": 2, "coins": 200}},
	{"id": "survive", "ev": "runEnd", "mode": "max", "val": "min", "goals": [5, 7, 9], "reward": {"t1": 3, "coins": 200}},
	{"id": "level", "ev": "runEnd", "mode": "max", "val": "level", "goals": [8, 12, 15], "reward": {"t1": 2, "coins": 200}},
	{"id": "boss", "ev": "kill", "match": "boss", "goals": [1, 2], "reward": {"t1": 3, "coins": 250}},
	{"id": "chest", "ev": "chest", "goals": [1, 2], "reward": {"t1": 2, "coins": 200}},
	{"id": "coins", "ev": "runEnd", "val": "coins", "goals": [100, 200, 300], "reward": {"t1": 2, "coins": 150}},
	{"id": "playType", "ev": "runEnd", "param": "type", "mode": "max", "val": "min", "goals": [3], "reward": {"t1": 3, "coins": 200}},
	{"id": "item", "ev": "item", "goals": [1], "reward": {"t1": 2, "coins": 150}},
	{"id": "evolve", "ev": "evolve", "goals": [1], "reward": {"t1": 3, "coins": 250}},
	{"id": "mDaily", "ev": "runEnd", "req": "daily", "goals": [1], "reward": {"t1": 3, "coins": 250}},
	{"id": "mRush", "ev": "runEnd", "req": "rush", "mode": "max", "val": "bosses", "goals": [2, 4], "reward": {"t1": 3, "coins": 300}},
	{"id": "mMods", "ev": "runEnd", "req": "mods1", "mode": "max", "val": "min", "goals": [4, 6], "reward": {"t1": 3, "coins": 300}},
	{"id": "mType", "ev": "runEnd", "req": "type", "mode": "max", "val": "min", "goals": [4, 6], "reward": {"t1": 3, "coins": 300}},
	{"id": "mTeam", "ev": "runEnd", "req": "team", "mode": "max", "val": "min", "goals": [5, 8], "reward": {"t1": 3, "coins": 300}},
	{"id": "mTower", "ev": "runEnd", "req": "tower", "mode": "max", "val": "floor", "goals": [2, 3], "reward": {"t1": 3, "coins": 350}},
	{"id": "mRifts", "ev": "runEnd", "req": "rifts", "mode": "max", "val": "rifts", "goals": [2, 3], "reward": {"t1": 3, "coins": 350}},
]
const WEEKLY := [
	{"id": "wkill", "ev": "kill", "goals": [4000, 6000], "reward": {"t10": 1, "coins": 800}},
	{"id": "wrift", "ev": "rift", "goals": [1, 2], "reward": {"t10": 1, "coins": 1000}},
	{"id": "wboss", "ev": "kill", "match": "boss", "goals": [4, 6], "reward": {"t10": 1, "coins": 900}},
	{"id": "wsurvive", "ev": "runEnd", "mode": "max", "val": "min", "goals": [12, 15], "reward": {"t10": 1, "coins": 1000}},
	{"id": "wevolve", "ev": "evolve", "goals": [3, 5], "reward": {"t10": 1, "coins": 900}},
	{"id": "wdaily", "ev": "missionDone", "match": "daily", "goals": [8, 12], "reward": {"t10": 1, "coins": 800}},
	{"id": "wDailyCh", "ev": "runEnd", "req": "daily", "goals": [3, 5], "reward": {"t1": 3, "t10": 1, "coins": 1000}},
	{"id": "wRush", "ev": "runEnd", "req": "rush", "mode": "max", "val": "bosses", "goals": [6, 9], "reward": {"t1": 3, "t10": 1, "coins": 1100}},
	{"id": "wType", "ev": "runEnd", "req": "type", "mode": "max", "val": "min", "goals": [8, 12], "reward": {"t1": 3, "t10": 1, "coins": 1100}},
	{"id": "wTeam", "ev": "runEnd", "req": "team", "mode": "max", "val": "min", "goals": [10, 15], "reward": {"t1": 3, "t10": 1, "coins": 1200}},
	{"id": "wTower", "ev": "runEnd", "req": "tower", "mode": "max", "val": "floor", "goals": [6, 9], "reward": {"t1": 4, "t10": 1, "coins": 1300}},
	{"id": "wRifts", "ev": "runEnd", "req": "rifts", "mode": "max", "val": "rifts", "goals": [5, 7], "reward": {"t1": 4, "t10": 1, "coins": 1300}},
	{"id": "wMods", "ev": "runEnd", "req": "mods3", "mode": "max", "val": "min", "goals": [6, 8], "reward": {"t1": 3, "t10": 1, "coins": 1200}},
]


static func def_of(id: String) -> Dictionary:
	for d in DAILY:
		if String(d["id"]) == id:
			return d
	for d in WEEKLY:
		if String(d["id"]) == id:
			return d
	return {}


static func mission_text(m: Dictionary) -> String:
	var n: int = int(m["goal"])
	var tn: String = String(MD.TYPE_NAME.get(String(m.get("param", "")), ""))
	var nn: String = _thousands(n)
	match String(m["id"]):
		"kill", "wkill":
			return L_t("Derrota a %s Pokémon") % nn
		"killType":
			return L_t("Derrota a %s Pokémon de tipo %s") % [nn, L_t(tn)]
		"survive", "wsurvive":
			return L_t("Aguanta %s minutos en una run") % nn
		"level":
			return L_t("Llega al nivel %s en una run") % nn
		"boss":
			return L_t("Derrota a un jefe") if n == 1 else L_t("Derrota a %s jefes") % nn
		"wboss":
			return L_t("Derrota a %s jefes") % nn
		"chest":
			return L_t("Abre un cofre con candado") if n == 1 else L_t("Abre %s cofres con candado") % nn
		"coins":
			return L_t("Recoge %s monedas en tus runs") % nn
		"playType":
			return L_t("Aguanta %s minutos con un Pokémon de tipo %s") % [nn, L_t(tn)]
		"item":
			return L_t("Encuentra un objeto equipable")
		"evolve":
			return L_t("Evoluciona un movimiento")
		"wrift":
			return L_t("Gana una pelea en una grieta") if n == 1 else L_t("Gana %s peleas en grietas") % nn
		"wevolve":
			return L_t("Evoluciona %s movimientos") % nn
		"wdaily":
			return L_t("Completa %s misiones diarias") % nn
		"mDaily":
			return L_t("Juega el Desafío diario")
		"mRush":
			return L_t("Derrota a %s jefes en el Rush de Jefes") % nn
		"mMods":
			return L_t("Aguanta %s minutos con algún modificador activo") % nn
		"wDailyCh":
			return L_t("Juega %s Desafíos diarios") % nn
		"wRush":
			return L_t("Derrota a %s jefes en una sola partida de Rush de Jefes") % nn
		"mType":
			return L_t("Aguanta %s minutos en Supervivencia por tipo") % nn
		"mTeam":
			return L_t("Aguanta %s minutos en Modo Equipo") % nn
		"mTower":
			return L_t("Supera %s pisos de la Torre") % nn
		"wTower":
			return L_t("Supera %s pisos de la Torre en una sola partida") % nn
		"mRifts":
			return L_t("Gana %s grietas en la Contrarreloj de grietas") % nn
		"wType":
			return L_t("Aguanta %s minutos en Supervivencia por tipo") % nn
		"wTeam":
			return L_t("Aguanta %s minutos en Modo Equipo") % nn
		"wRifts":
			return L_t("Gana %s grietas en una Contrarreloj de grietas") % nn
		"wMods":
			return L_t("Aguanta %s minutos con 3 o más modificadores") % nn
	return String(m["id"])


static func L_t(s: String) -> String:
	var L = load("res://scripts/lang.gd")
	return L.t(s)


static func _thousands(n: int) -> String:
	var s: String = str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out


# Fecha en Espana (UTC+1, +2 en verano).
static func _last_sunday(year: int, month: int) -> int:
	var d: int = 31 if month != 4 and month != 6 and month != 9 and month != 11 else 30
	while true:
		var t: int = int(Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": d, "hour": 1, "minute": 0, "second": 0}))
		var wd: int = int(Time.get_datetime_dict_from_unix_time(t)["weekday"])
		if wd == 0:
			return t
		d -= 1
	return 0


# Reloj unico del juego: hora de Puerto Rico (UTC-4 todo el ano, sin horario de verano).
static func pr_now() -> int:
	return int(Time.get_unix_time_from_system()) - 4 * 3600


static func madrid_now() -> int:
	return pr_now()


static func period_ids() -> Dictionary:
	var t: int = madrid_now()
	var dd: Dictionary = Time.get_datetime_dict_from_unix_time(t)
	var day: String = "%04d-%02d-%02d" % [int(dd["year"]), int(dd["month"]), int(dd["day"])]
	var wd: int = (int(dd["weekday"]) + 6) % 7      # lunes = 0
	var mon: Dictionary = Time.get_datetime_dict_from_unix_time(t - wd * 86400)
	var week: String = "%04d-%02d-%02d" % [int(mon["year"]), int(mon["month"]), int(mon["day"])]
	return {"d": day, "w": week}


static func _rng_state(seed_str: String) -> int:
	var h: int = 2166136261
	for i in range(seed_str.length()):
		h = (h ^ seed_str.unicode_at(i)) & 0xFFFFFFFF
		h = (h * 16777619) & 0xFFFFFFFF
	return h


static func _rand(st: Array) -> float:
	st[0] = (int(st[0]) + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = int(st[0])
	t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
	t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF)) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


static func _make(def: Dictionary, st: Array) -> Dictionary:
	var goals: Array = def["goals"]
	var goal: int = int(goals[int(_rand(st) * goals.size())])
	var param := ""
	if String(def.get("param", "")) == "type":
		var keys: Array = MD.TYPE_NAME.keys()
		param = String(keys[int(_rand(st) * keys.size())])
	return {"id": String(def["id"]), "goal": goal, "param": param, "prog": 0, "claimed": false, "told": false}


static func _pick_set(defs: Array, n: int, st: Array, avoid: Array = []) -> Array:
	var pool: Array = []
	for d in defs:
		if not avoid.has(String(d["id"])):
			pool.append(d)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var i: int = int(_rand(st) * pool.size())
		var d: Dictionary = pool[i]
		pool.remove_at(i)
		out.append(_make(d, st))
	return out


static var ens_t := -100.0


static func ensure() -> void:
	var nowt: float = Time.get_ticks_msec() / 1000.0
	if nowt - ens_t < 5.0 and SV.d.has("missions"):
		return
	ens_t = nowt
	if not SV.d.has("missions"):
		SV.d["missions"] = {}
	var M: Dictionary = SV.d["missions"]
	var ids: Dictionary = period_ids()
	var key: String = str(int(SV.d.get("created", 0)))
	if String(M.get("day", "")) != String(ids["d"]):
		M["day"] = ids["d"]
		M["rerolled"] = false
		M["daily"] = _pick_set(DAILY, 3, [_rng_state(String(ids["d"]) + key)])
	if String(M.get("week", "")) != String(ids["w"]):
		M["week"] = ids["w"]
		M["weekly"] = _pick_set(WEEKLY, 2, [_rng_state(String(ids["w"]) + key)])


static func m_done(m: Dictionary) -> bool:
	return int(m["prog"]) >= int(m["goal"])


static func _advance(lst: Array, kind: String, d: Dictionary) -> void:
	for m in lst:
		if bool(m["claimed"]) or m_done(m):
			continue
		var def: Dictionary = def_of(String(m["id"]))
		if def.is_empty() or String(def["ev"]) != kind:
			continue
		var mt: String = String(def.get("match", ""))
		if mt == "boss" and not bool(d.get("boss", false)):
			continue
		if mt == "daily" and not bool(d.get("daily", false)):
			continue
		var rq: String = String(def.get("req", ""))
		if rq != "":
			var md: String = String(d.get("mode", "normal"))
			var nm: int = int(d.get("nmods", 0))
			if (rq in ["daily", "rush", "type", "team", "rifts", "tower"] and md != rq) or (rq == "mods1" and nm < 1) or (rq == "mods3" and nm < 3):
				continue
		if String(def.get("param", "")) == "type":
			var types: Array = d.get("types", [])
			if not types.has(String(m["param"])):
				continue
		var v: int = 1
		match String(def.get("val", "")):
			"min":
				v = int(float(d.get("time", 0.0)) / 60.0)
			"level":
				v = int(d.get("level", 0))
			"coins":
				v = int(d.get("coins", 0))
			"bosses":
				v = int(d.get("bosses", 0))
			"rifts":
				v = int(d.get("rifts", 0))
			"floor":
				v = int(d.get("floor", 0))
		if String(def.get("mode", "")) == "max":
			m["prog"] = maxi(int(m["prog"]), v)
		else:
			m["prog"] = int(m["prog"]) + v
		if m_done(m) and not bool(m["told"]):
			m["told"] = true
			toasts.append({"title": "Misión completada: %s", "arg": mission_text(m), "sub": "Recoge el premio en Misiones", "subarg": "", "tier": 2, "dex": 0})
			SV.save()


static func claim(m: Dictionary, weekly: bool) -> bool:
	if bool(m["claimed"]) or not m_done(m):
		return false
	m["claimed"] = true
	grant(def_of(String(m["id"]))["reward"])
	var s: Dictionary = SV.d["stats"]
	s["missionsDone"] = int(s.get("missionsDone", 0)) + 1
	SV.save()
	event("missionDone", {"daily": not weekly})
	return true


static func reroll(i: int) -> bool:
	ensure()
	var M: Dictionary = SV.d["missions"]
	var dl: Array = M["daily"]
	if i < 0 or i >= dl.size() or bool(M.get("rerolled", false)) or bool(dl[i]["claimed"]):
		return false
	var avoid: Array = []
	for x in dl:
		avoid.append(String(x["id"]))
	var st: Array = [_rng_state(String(M["day"]) + "cambio" + str(Time.get_ticks_usec()))]
	var n: Array = _pick_set(DAILY, 1, st, avoid)
	if n.is_empty():
		return false
	dl[i] = n[0]
	M["rerolled"] = true
	SV.save()
	return true


static func pending() -> int:
	ensure()
	var M: Dictionary = SV.d["missions"]
	var c := 0
	for m in (M["daily"] as Array) + (M["weekly"] as Array):
		if m_done(m) and not bool(m["claimed"]):
			c += 1
	return c


static func event(kind: String, d: Dictionary = {}) -> void:
	if off:
		return
	ensure()
	var s: Dictionary = SV.d["stats"]
	match kind:
		"evolve":
			s["evolutions"] = int(s.get("evolutions", 0)) + 1
			var em: Dictionary = SV.d.get("evoMoves", {})
			if not em.has(String(d.get("move", ""))):
				em[String(d.get("move", ""))] = int(Time.get_unix_time_from_system())
			SV.d["evoMoves"] = em
		"kill":
			for tkt in d.get("types", []):
				var tkk: String = "tk_" + String(tkt)
				s[tkk] = int(s.get(tkk, 0)) + 1
		"item":
			var it: Dictionary = SV.d.get("itemsFound", {})
			if not it.has(String(d.get("id", ""))):
				it[String(d.get("id", ""))] = int(Time.get_unix_time_from_system())
			SV.d["itemsFound"] = it
	var M: Dictionary = SV.d["missions"]
	_advance(M["daily"], kind, d)
	_advance(M["weekly"], kind, d)
	if kind != "kill" or bool(d.get("boss", false)) or int(d.get("legend", 0)) > 0:
		check()
	elif Time.get_ticks_msec() / 1000.0 - ach_t > 1.0:
		ach_t = Time.get_ticks_msec() / 1000.0
		check()
