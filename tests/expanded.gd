extends SceneTree
const SV = preload("res://scripts/save_data.gd")
const CT = preload("res://scripts/content.gd")
const SP = preload("res://scripts/sprites.gd")
const ART = preload("res://scripts/profile_art.gd")
const UI = preload("res://scripts/expansion_ui.gd")
var failures := 0

func check(ok: bool, text: String) -> void:
	if ok:
		print("PASS: ", text)
	else:
		failures += 1
		push_error("FAIL: " + text)

func _initialize() -> void:
	if ProjectSettings.get_setting("application/config/custom_user_dir_name", "") != "CodexPokeSurvivorReview":
		push_error("Tests require an isolated review save directory.")
		quit(2)
		return
	call_deferred("run")

func run() -> void:
	SV.loaded = true
	SV.load_dex()
	SV.d = SV.default_data()
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.d["selected"] = 6
	SV.add_owned(6, false)
	check(CT.skins().size() == 49, "all 49 community skins available")
	check(SV.TRAILS.size() >= 57, "57 web trails plus preserved legacy trails")
	var missing: Array = []
	for key in SV.smeta:
		var info: Dictionary = SV.smeta[key]["a"]["Idle"]
		if not SP.exists("res://assets/pokemon/%s/%s.png" % [key, String(info.get("f", "Idle"))]):
			missing.append(key)
	check(missing.is_empty(), "all 1538 sprite bodies have a packed Idle atlas")
	check(ART.texture("res://assets/tienda/fotos-perfil/6/normal.png") != null, "portrait decodes from the packaged archive")
	check(ART.texture("res://assets/tienda/marcos/maestria_fire.png") != null, "mastery frame decodes from the packaged archive")
	check(ART.cry(6) != null, "cry audio decodes from the packaged archive")
	check(not CT.skin_unlocked(6, "sombrio-charizard"), "skins require local mastery")
	var ms: Dictionary = SV.mastery(6).duplicate()
	ms["pts"] = 1000
	SV.d["mastery"] = {"6": ms}
	SV.set_dress(6, "skin", "sombrio-charizard")
	check(CT.skin(6) == "sombrio-charizard", "mastery unlocks a selectable skin without a shop")
	check(SP.texture("res://assets/pokemon/6/k-sombrio-charizard/Idle.png") != null, "selected skin atlas decodes")
	var week_a: Dictionary = CT.weekly()
	var week_b: Dictionary = CT.weekly()
	check(week_a == week_b, "weekly map, Pokémon and rule are deterministic")
	SV.d["tickets10"] = 0
	SV.d["weekly"] = {"week": CT.week(), "used": true, "best": 0, "rewarded": false}
	CT.record_weekly(180.0)
	CT.record_weekly(240.0)
	check(int(SV.d["tickets10"]) == 1 and int(SV.d["weekly"]["best"]) == 240, "weekly reward is paid once and best score persists")
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.player.skin == "sombrio-charizard" and game.player._tex_path("Idle", false).contains("/k-"), "equipped skin is actually used in combat")
	for id in ["sleep", "slow", "push", "focus"]:
		game.runx.collect("sphere:" + id)
	check(not game.runx.collect("sphere:light") and game.runx.spheres.size() == 4, "sphere inventory enforces four distinct slots")
	game.runx.collect("sphere:sleep")
	game.runx.collect("sphere:sleep")
	game.runx.collect("sphere:sleep")
	check(int(game.runx.spheres["sleep"]) == 3, "sphere stack caps at three")
	game.jd.arena_t = 0
	game.item = "amuletcoin"
	game.item2 = "expcharm"
	game.item3 = "luckincense"
	game.item4 = "leftovers"
	for t in [120, 240, 360, 480]:
		game.jd.arena_t = t
		game.jd.break_tick()
	check(game.jd.broken.size() == 4 and game.item == "" and game.item4 == "", "Arceus breaks all four item slots on schedule")
	check(game.jd.broken.has("amuletcoin") and game.jd.broken.has("expcharm") and game.jd.broken.has("luckincense"), "broken coin items remain tracked for payout")
	SV.d["coins"] = 1000
	var ui = UI.open(game, "casino", game.runx)
	ui.voltorb()
	check(int(SV.d["coins"]) == 980, "casino stake is charged once")
	var safe := 0
	while ui.board.has(safe):
		safe += 1
	ui.reveal_voltorb(safe)
	ui.reveal_voltorb(safe)
	check(ui.found == 1, "a revealed casino ball cannot be collected twice")
	var cashout: Button = ui.body.get_child(ui.body.get_child_count() - 1)
	cashout.pressed.emit()
	var after: int = int(SV.d["coins"])
	cashout.pressed.emit()
	check(int(SV.d["coins"]) == after and after == 1008, "casino cashout cannot pay twice")
	for page in ["home", "bag", "dress", "mastery", "profile", "weekly", "casino"]:
		ui.section = page
		ui.refresh()
		await process_frame
		check(ui.body.get_child_count() > 0, "expanded page renders: " + page)
	ui.close()
	for td in CT.trails().values():
		game.runx.trail_node.add(String(td["id"]), game.player.position, Vector2.LEFT)
	game.runx.trail_node._process(0.1)
	await process_frame
	check(game.runx.trail_node.parts.size() >= 57, "all trail styles can be emitted")
	game.queue_free()
	await process_frame
	await create_timer(1.1).timeout
	SP.clear()
	ART.clear()
	load("res://scripts/vfx.gd").cache.clear()
	load("res://scripts/audio.gd").shutdown()
	await process_frame
	print("EXPANDED FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
