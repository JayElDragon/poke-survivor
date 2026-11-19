extends RefCounted
# Offline catalog and progress; no accounts or shop dependencies.
const SV = preload("res://scripts/save_data.gd")
static var catalog: Dictionary = {}
static var trail_catalog: Dictionary = {}
static var skin_catalog: Dictionary = {}

static func skins() -> Dictionary:
	if skin_catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/skins.json"))
		if parsed is Dictionary:
			skin_catalog = parsed
	return skin_catalog

static func skin_unlocked(dex: int, id: String) -> bool:
	if not skins().has(id) or not SV.owns(dex):
		return false
	if id == "obsidiana-mewtwo":
		return bool(SV.d.get("rocket_skin", false))
	return int(SV.mastery(dex)["pts"]) >= 1000 or (SV.d.get("skins", {}) as Dictionary).has(id)

static func skin(dex: int) -> String:
	var original: int = base_dex(dex)
	var id: String = String(SV.dress(original).get("skin", ""))
	return id if skin_unlocked(original, id) and int(skins()[id]["dex"]) == original else ""

static func trails() -> Dictionary:
	if trail_catalog.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/trails.json"))
		if data is Array:
			for td in data:
				trail_catalog[String(td["id"])] = td
		for old in {"fire": "flame", "flake": "snow", "seed": "leaf", "swirl": "wind", "lava": "magma", "grain": "rock", "plus": "spark", "blob": "miasma", "mist": "ghost", "rune": "psy"}:
			var current: String = {"fire": "flame", "flake": "snow", "seed": "leaf", "swirl": "wind", "lava": "magma", "grain": "rock", "plus": "spark", "blob": "miasma", "mist": "ghost", "rune": "psy"}[old]
			trail_catalog[old] = trail_catalog[current]
	return trail_catalog

static func forms() -> Dictionary:
	if catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/forms.json"))
		if parsed is Dictionary:
			catalog = parsed
	return catalog

static func options(dex: int, kinds: Array) -> Array:
	var out: Array = []
	for value in forms().values():
		if int(value["d"]) == dex and kinds.has(String(value["k"])):
			out.append(value)
	out.sort_custom(func(a, b): return int(a["id"]) < int(b["id"]))
	return out

static func base_dex(dex: int) -> int:
	return int(forms()[str(dex)]["d"]) if forms().has(str(dex)) else dex

static func display_dex(dex: int) -> int:
	var id: int = int(SV.dress(dex).get("form", dex))
	if forms().has(str(id)):
		var f: Dictionary = forms()[str(id)]
		if int(f["d"]) == base_dex(dex) and String(f["k"]) == "look":
			return id
	return dex

static func week() -> int:
	# Monday boundary in the game's UTC-4 timezone; deterministic offline.
	return int(floor((Time.get_unix_time_from_system() - 4.0 * 3600.0 + 3.0 * 86400.0) / 604800.0))

static func weekly() -> Dictionary:
	var wk: int = week()
	var rng := RandomNumberGenerator.new()
	rng.seed = wk * 7919 + 31
	var pool: Array = SV.dex_list.filter(func(p): return not bool(p.get("leg", false)))
	var p: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var rules := ["storm", "nohealing", "night", "type"]
	return {"week": wk, "seed": wk * 7919 + 31, "dex": int(p["dex"]), "rule": rules[posmod(wk, rules.size())], "type": String(p["types"][0])}

static func record_weekly(seconds: float) -> void:
	var data: Dictionary = SV.d.get("weekly", {})
	data["best"] = maxf(float(data.get("best", 0.0)), seconds)
	if seconds >= 180.0 and not bool(data.get("rewarded", false)):
		data["rewarded"] = true
		SV.d["tickets10"] = int(SV.d.get("tickets10", 0)) + 1
	SV.d["weekly"] = data
	SV.save()

static func mastery_reward(dex: int, kind: String) -> bool:
	var pts: int = int(SV.mastery(dex)["pts"])
	return pts >= int({"photo": 10000, "title": 25000, "frame": 50000, "aura": 100000}.get(kind, 100000))

static func cosmetic_ok(dex: int, f: Dictionary) -> bool:
	# All alternate looks can be earned without the excluded shop.
	return SV.owns(dex) and (not String(f.get("fk", "")).begins_with("skin") or int(SV.mastery(dex)["pts"]) >= 1000)
