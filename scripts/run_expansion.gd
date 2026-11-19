extends RefCounted
const CT = preload("res://scripts/content.gd")
const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")
const AB = preload("res://scripts/abilities.gd")
const MD = preload("res://scripts/moves_data.gd")
const ORBS := ["sleep", "slow", "push", "focus", "light", "speed"]
const ORB_NAMES := {"sleep": "Soporesfera", "slow": "Ralentosfera", "push": "Rafagaesfera", "focus": "Focosfera", "light": "Luminosfera", "speed": "Rapidosfera"}
var m
var trail_node: Node2D
var species := 25
var spheres: Dictionary = {}
var buffs: Dictionary = {}
var berries: Dictionary = {}
var mochi := {"atk": 0.0, "def": 0.0, "spd": 0.0}
var time := 0.0
var form_choice := false
var rocket_done := false
var rocket_roll := false
var streak := 0.0
var last_slot := 0
var mouth_cd := 0.0
var radar_t := 0.0
var ui: CanvasLayer
var row: HBoxContainer
var status: Label
var eter_bar: ProgressBar
var battle_cd := 0.0
var all_picks: Array = []
var page_title := ""
var light_was := false
var selecting_power_form := false
var saved_items: Dictionary = {}
var splash_cd := 0.0

func setup(main) -> void:
	m = main
	species = int(SV.run_dex)
	m.player.skin = CT.skin(species)
	m.player.textures.clear()
	m.player.dirty = true
	m.player._apply()
	last_slot = m.player.slot
	trail_node = load("res://scripts/trails.gd").new()
	trail_node.m = m
	trail_node.z_index = 12
	m.world.add_child(trail_node)
	var visual: int = CT.display_dex(species)
	if visual != species:
		m.player.rebody(visual, m._sm(visual), m.player.shiny)
	ui = CanvasLayer.new()
	ui.layer = 8
	m.add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	row = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.position = Vector2(-220, -155)
	root.add_child(row)
	status = Label.new()
	status.position = Vector2(20, 112)
	status.add_theme_font_size_override("font_size", 16)
	root.add_child(status)
	eter_bar = ProgressBar.new()
	eter_bar.position = Vector2(20, 140)
	eter_bar.size = Vector2(300, 18)
	eter_bar.max_value = 100.0
	eter_bar.show_percentage = false
	eter_bar.visible = false
	root.add_child(eter_bar)
	if m.mode == "weekly":
		var w: Dictionary = CT.weekly()
		m.world_seed = int(w["seed"])
		if String(w["rule"]) == "nohealing":
			m.mods.append("nohealing")
	var loadout: String = String(SV.d.get("start_item", ""))
	if m.mode != "weekly" and m.mode != "party" and loadout != "" and int(SV.d.get("inventory", {}).get(loadout, 0)) > 0:
		m.item = loadout
		SV.d["inventory"][loadout] = int(SV.d["inventory"][loadout]) - 1
		SV.save()

func tick(dt: float) -> void:
	time += dt
	splash_cd = maxf(0.0, splash_cd - dt)
	if light_was and not has_buff("light"):
		m.cam.zoom = Vector2.ONE * m.cam_zoom
	light_was = has_buff("light")
	for key in buffs.keys():
		buffs[key] = maxf(0.0, float(buffs[key]) - dt)
	mouth_cd = maxf(0.0, mouth_cd - dt)
	if last_slot != m.player.slot:
		streak = 0.0
		last_slot = m.player.slot
		if m._has_item("throatspray") and mouth_cd <= 0.0:
			buffs["mouth"] = 8.0
			mouth_cd = 12.0
	else:
		streak += dt
	if m.player.hp < m.player.max_hp * 0.25:
		if berries.has("sitrus"):
			berries.erase("sitrus")
			m._heal_real(m.player.max_hp * 0.3)
		if berries.has("chesto"):
			berries.erase("chesto")
			buffs["berry_atk"] = 10.0
	if berries.has("pecha") and (m.trap_slow_t > 0.0 or m.trap_para_t > 0.0):
		berries.erase("pecha")
		buffs["cleanse"] = 5.0
	if has_buff("cleanse"):
		m.trap_slow_t = 0.0
		m.trap_para_t = 0.0
	if m.arena != null and m.eterf.active():
		m.eterf.update(dt)
	if m._dyn_on() and ["dyna", "gmax"].has(m.dyn.kind):
		radar_t -= dt
		if radar_t <= 0.0:
			radar_t = 0.25
			smash()
	if not form_choice and m.run_rifts >= 3 and not m._dyn_on() and not m.choosing:
		form_choice = true
		var opts: Array = CT.options(CT.base_dex(species), ["stat"])
		if not opts.is_empty():
			offer_forms(opts, "Forma de tu Pokémon")
	battle_cd -= dt
	if battle_cd <= 0.0 and not m._dyn_on():
		battle_cd = 1.0
		battle_form()
	if m.mode == "weekly":
		var w: Dictionary = CT.weekly()
		if w["rule"] == "storm" and m.wx_kind == "" and m.arena == null:
			m._start_weather(["sun", "rain", "sand", "snow", "fog"][int(time / 30.0) % 5], 30.0)
	if not rocket_done and not rocket_roll and m.jd.done and m.arena == null and not m.player.dead and m.mode == "normal":
		rocket_roll = true
		if randf() < 1.0 / 3.0:
			offer_rocket()
	update_hud()

func has_buff(id: String) -> bool:
	return float(buffs.get(id, 0.0)) > 0.0

func damage_splash(target, damage: float, color: Color) -> void:
	if splash_cd > 0.0 or not m._dyn_on() or not ["dyna", "gmax"].has(m.dyn.kind):
		return
	splash_cd = 0.1
	var count := 0
	for enemy in m.enemies.duplicate():
		if enemy != target and not enemy.dead and enemy.position.distance_to(target.position) < 70.0:
			m._damage_enemy(enemy, damage * 0.25, color)
			count += 1
			if count >= 8:
				break

func attack_mul() -> float:
	return (1.0 + float(mochi["atk"])) * (1.3 if has_buff("berry_atk") else 1.0) * (1.25 if has_buff("mouth") else 1.0) * (1.0 + minf(0.48, floorf(streak / 3.0) * 0.06) if m._has_item("metronome") else 1.0) * (0.85 if m._has_item("luckincense") else 1.0)

func speed_mul() -> float:
	return (1.0 + float(mochi["spd"])) * (1.4 if has_buff("speed") else 1.0)

func taken_mul() -> float:
	return maxf(0.2, 1.0 - float(mochi["def"]))

func input(event: InputEvent) -> bool:
	if m.paused or m.choosing or m.player.dead:
		return false
	if event is InputEventKey and event.pressed and not event.echo and event.shift_pressed and event.keycode >= KEY_5 and event.keycode <= KEY_8:
		var keys: Array = spheres.keys()
		var idx: int = event.keycode - KEY_5
		if idx < keys.size():
			use_orb(String(keys[idx]))
			return true
	return false

func update_hud() -> void:
	ui.visible = not m.player.dead and not m.jd.cinematic()
	status.text = " · ".join(berries.keys().map(func(b): return L.t(String(b))))
	eter_bar.visible = m.eterf != null and m.eterf.active()
	if eter_bar.visible and is_instance_valid(m.eterf.e):
		eter_bar.value = m.eterf.e.hp / maxf(1.0, m.eterf.e.max_hp) * 100.0
		status.text = L.t("Eternatus · Fase %d · %d%%") % [m.eterf.phase, ceili(eter_bar.value)]
	var signature: String = str(spheres)
	if String(row.get_meta("sig", "")) == signature:
		return
	row.set_meta("sig", signature)
	for child in row.get_children():
		child.queue_free()
	var idx := 0
	for id in spheres:
		var key := String(id)
		var b := Button.new()
		b.text = "Shift+%d: %s ×%d" % [5 + idx, L.t(String(ORB_NAMES[key])), int(spheres[key])]
		b.custom_minimum_size = Vector2(100, 44)
		b.pressed.connect(func(): use_orb(key))
		row.add_child(b)
		idx += 1

func use_orb(id: String) -> void:
	if m.paused or m.choosing or m.player.dead or not spheres.has(id):
		return
	spheres[id] = int(spheres[id]) - 1
	if int(spheres[id]) <= 0:
		spheres.erase(id)
	for e in m.enemies:
		if e.dead or e.position.distance_to(m.player.position) > 900.0:
			continue
		match id:
			"sleep": m._apply_cc(e, "sleep", 0.25 if e.boss else 1.0)
			"slow": e.apply_slow(0.2 if e.boss else 0.5)
			"push": e.knock += (e.position - m.player.position).normalized() * (250.0 if e.boss else 500.0)
	if ["focus", "light", "speed"].has(id):
		buffs[id] = 10.0 if id == "speed" else 15.0
		if id == "light":
			m.cam.zoom = Vector2.ONE * m.cam_zoom * 0.8
	m._ring(m.player.position, 15, 260, Color("#7fdfff"), 0.5)
	update_hud()

func collect(kind: String) -> bool:
	if kind.begins_with("sphere:"):
		var id: String = kind.substr(7)
		if not spheres.has(id) and spheres.size() >= 4:
			return false
		spheres[id] = mini(3, int(spheres.get(id, 0)) + 1)
		m._say(String(ORB_NAMES[id]), 1.2)
		return true
	if kind.begins_with("berry:"):
		berries[kind.substr(6)] = true
		return true
	if kind.begins_with("mochi:"):
		var id: String = kind.substr(6)
		if id == "hp":
			var extra: float = ceilf(m.player.max_hp * 0.05)
			m.player.max_hp += extra
			m.player.hp += extra
		else:
			mochi[id] = float(mochi.get(id, 0.0)) + 0.05
		return true
	return false

func on_drop(e) -> void:
	if e.judge or e.has_meta("jd_arceus"):
		return
	if e.boss and randf() < 0.35:
		var reserve: String = String(m.TD.ITEMS[randi() % m.TD.ITEMS.size()]["id"])
		if reserve != "rarecandy":
			saved_items[reserve] = int(saved_items.get(reserve, 0)) + 1
	var roll: float = randf()
	if roll < (0.5 if e.boss else 0.018):
		m._spawn_orb(e.position, "sphere:" + ORBS[randi() % ORBS.size()], 0.0)
	elif roll < (0.65 if e.boss else 0.022):
		m._spawn_orb(e.position, "mochi:" + ["hp", "atk", "spd", "def"][randi() % 4], 0.0)
	elif e.boss and roll < 0.85:
		m._spawn_orb(e.position, "berry:" + ["sitrus", "chesto", "pecha"][randi() % 3], 0.0)

func pick(cat: String, id: String, title: String, desc: String) -> Dictionary:
	return {"cat": cat, "id": id, "key": cat + ":" + id, "w": 1.0, "title": title, "desc": desc, "icon": "star", "tag": "Poder", "color": Color("#8fdfff")}

func show(picks: Array, title: String, page: int = 0) -> void:
	all_picks = picks
	page_title = title
	var visible_picks: Array = picks.slice(page * 4, page * 4 + 4) if picks.size() > 6 else picks
	if picks.size() > 6:
		visible_picks.append(pick("rx_page", str((page + 1) % int(ceilf(float(picks.size()) / 4.0))), "Más opciones", L.t("Página %d") % (page + 1)))
	m.choosing = true
	m.cards.show_cards(visible_picks, title, title, false)

func offer_power() -> void:
	m.power_pending = false
	var picks: Array = []
	if not CT.options(CT.base_dex(species), ["mega", "power"]).is_empty():
		picks.append(pick("rx_power", "mega", "Megaevolución / Fusión", "Cambia de forma, tipos y atributos. 40 s; recarga 90 s."))
	var giga: Array = CT.options(CT.base_dex(species), ["gmax"])
	picks.append(pick("rx_power", "gmax" if not giga.is_empty() else "dyna", "Gigamax" if not giga.is_empty() else "Dinamax", "12 s: doble de vida, +40% de daño y golpes que salpican. Recarga 80 s."))
	picks.append(pick("rx_power", "z", "Pulsera Z", "15 s de ondas Z y un movimiento final. Recarga 60 s."))
	picks.append(pick("rx_power", "tera", "Teracristal", "Elige un tipo o Astral. 30 s; recarga 75 s."))
	show(picks, "Premio de Eternatus: elige un poder")

func offer_forms(opts: Array, title: String) -> void:
	var picks: Array = []
	for f in opts:
		picks.append(pick("rx_form", str(f["id"]), String(f["n"]), "Tipos: " + " / ".join(f["t"])))
	picks.append(pick("rx_form", "keep", "Mantener", "Conserva tu forma actual."))
	show(picks, title)

func card(c: Dictionary) -> bool:
	var cat: String = String(c["cat"])
	if not cat.begins_with("rx_"):
		return false
	m.cards.hide_cards()
	m.choosing = false
	var id: String = String(c["id"])
	match cat:
		"rx_page":
			show(all_picks, page_title, int(id))
		"rx_power":
			m.selected_power = id
			if id == "mega":
				selecting_power_form = true
				offer_forms(CT.options(CT.base_dex(species), ["mega", "power"]), "Elige la forma de poder")
			elif id == "gmax":
				m.selected_form = int(CT.options(CT.base_dex(species), ["gmax"])[0]["id"])
				if CT.base_dex(species) == 892 and m.player.types.has("water"):
					m.selected_form = 160892
			elif id == "tera" or id == "z":
				var picks: Array = []
				for ty in MD.TYPE_NAME:
					picks.append(pick("rx_type", String(ty), String(MD.TYPE_NAME[ty]), "Tipo de tu poder"))
				if id == "tera":
					picks.append(pick("rx_type", "stellar", "Astral", "Conserva tus tipos y potencia todos tus ataques."))
				show(picks, "Elige el tipo")
		"rx_type": m.selected_tera = id
		"rx_form":
			if id != "keep":
				if selecting_power_form:
					selecting_power_form = false
					m.selected_form = int(id)
				else:
					transform(int(id), true)
			elif selecting_power_form:
				selecting_power_form = false
				m.selected_power = ""
				m.power_pending = true
		"rx_rocket":
			rocket_done = true
			if id == "enter":
				load("res://scripts/expansion_ui.gd").open(m, "casino", self)
	return true

func transform(id: int, stats: bool) -> void:
	if not SV.dex_by.has(id) or not m._smeta.has(str(id)):
		return
	var f: Dictionary = SV.dex_by[id]
	if stats:
		var old: Dictionary = SV.dex_by.get(species, f)
		m.base_atk *= float(f["atk"]) / maxf(0.01, float(old["atk"]))
		m.base_spd *= float(f["spd"]) / maxf(1.0, float(old["spd"]))
		m.player.types = f["types"].duplicate()
		m.ab_fx = AB.fx_of(id)
	m.player.rebody(id, m._sm(id), m.player.shiny)
	m.hud.poke_name = String(f["name"])

func battle_form() -> void:
	var base: int = CT.base_dex(species)
	var key := ""
	match base:
		681: key = "blade" if m.player.once else "shield"
		746: key = "school" if m.player.hp > m.player.max_hp * 0.25 else "solo"
		555: key = "zen" if m.player.hp < m.player.max_hp * 0.5 else "standard"
		875: key = "noice" if m.player.hp < m.player.max_hp * 0.5 else "ice"
		351: key = {"sun": "sunny", "rain": "rainy", "snow": "snowy"}.get(m.wx_kind, "normal")
		877: key = "hangry" if int(time / 10.0) % 2 == 1 else "full-belly"
		964: key = "hero" if m.run_time > 120.0 else "zero"
	if key == "":
		return
	var target: int = species
	for f in CT.options(base, ["battle"]):
		if String(f.get("fk", "")).contains(key):
			target = int(f["id"])
	if m.player.dex != target:
		# Temporary battle forms never stack base stat multipliers.
		var old: Dictionary = SV.dex_by.get(m.player.dex, SV.dex_by[species])
		var next: Dictionary = SV.dex_by[target]
		m.base_atk *= float(next["atk"]) / maxf(0.01, float(old["atk"]))
		m.base_spd *= float(next["spd"]) / maxf(1.0, float(old["spd"]))
		m.player.rebody(target, m._sm(target), m.player.shiny)
		m.player.types = SV.dex_by[target]["types"].duplicate()
		m.ab_fx = AB.fx_of(target)

func smash() -> void:
	m._cut_grass(m.player.position, m.player.radius * 2.0)
	if m.arena == null:
		for p in m._props_near(m.player.position).duplicate():
			if is_instance_valid(p) and p.position.distance_to(m.player.position) < m.player.radius * 2.2 and ["tree", "rock", "wall", "chest"].has(p.kind):
				if p.kind == "chest":
					m._open_chest(p)
				m._forget_prop(p)
				p.queue_free()

# 7.1: como el original, el Team Rocket se lleva a tu Pokemon a su casino (1 de cada 3 partidas que llegan a la Sentencia).
# El reloj se para; al salir, el Team Rocket sale volando y sigues la partida.
func offer_rocket() -> void:
	rocket_done = true
	var was: bool = m.paused
	m.paused = true
	m._say("¡Al Casino Rocket, miau!", 2.0)
	load("res://scripts/rocket_casino.gd").open(m, int(m.player.dex), func():
		m.paused = was
		m._say("¡El Team Rocket sale volando otra vez!", 3.0))
