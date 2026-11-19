extends SceneTree
const SV = preload("res://scripts/save_data.gd")
const CT = preload("res://scripts/content.gd")
const UI = preload("res://scripts/expansion_ui.gd")
const MAIN = preload("res://scripts/main.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

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
	SV.run_mode = "normal"
	SV.run_dex = 6
	SV.d["selected"] = 6
	SV.add_owned(6, false)
	check(SV.dex_list.size() == 1082, "1025 species and 57 regional forms")
	check(SV.dex_by.has(1008) and SV.dex_by.has(500037), "missing species and regional lookups")
	check(SV.smeta.has("100006") and SV.smeta.has("150006"), "mega and Gmax metadata")
	SV.d["tickets"] = 100
	var pulls: Array = SV.pull(1, 100, "t1")
	check(pulls.size() == 100 and int(SV.d["tickets"]) == 0, "100 normal-ticket pulls charged exactly")
	check(int(SV.d.get("egg_pulls", 0)) == 10, "100 pulls count ten batches for eggs")
	for i in range(10):
		check(pulls.slice(i * 10, i * 10 + 10).any(func(x): return int(x["rarity"]) >= 4), "batch %d preserves guaranteed rarity" % i)
	SV.d["tickets10"] = 10
	pulls = SV.pull(1, 100, "t10")
	check(pulls.size() == 100 and int(SV.d["tickets10"]) == 0, "100 purple-ticket pulls charged ten tickets")
	var game = MAIN.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.runx != null and game.player != null, "main scene initialized with expansion")
	game.run_time = 1200.0
	game._spawn_eternatus()
	game.set_process(false)
	check(game.eterf.active() and game.arena != null, "Eternatus arena entered")
	var boss = game.eterf.e
	var initial_hp: float = boss.max_hp
	for i in range(4):
		game._damage_enemy(boss, initial_hp * 1000)
	check(boss.hp >= initial_hp * 0.6599 and not boss.dead, "burst cannot skip first phase")
	game.eterf.update(0.1)
	check(game.eterf.phase == 2 and game.eterf.cores.size() == 4, "four cores spawned")
	var hp: float = boss.hp
	game._damage_enemy(boss, initial_hp * 1000)
	check(boss.hp == hp, "cores protect against every damage source")
	for core in game.eterf.cores:
		core.dead = true
	game.eterf.update(0.1)
	for i in range(4):
		game._damage_enemy(boss, initial_hp * 1000)
	game.eterf.update(0.1)
	check(game.eterf.phase == 3, "third phase reached without skipping")
	for i in range(4):
		game._damage_enemy(boss, initial_hp * 1000)
	game.eterf.update(0.1)
	check(game.eterf.beam_t > 0 and is_instance_valid(game.eterf.eternal), "eternal core and eight-second charge")
	game.eterf.eternal.dead = true
	game.eterf.update(0.1)
	check(game.eterf.stun_t > 0, "breaking eternal core stuns boss")
	game._damage_enemy(boss, initial_hp * 1000)
	await process_frame
	check(game.run_eter and not game.player.dead and not game.timeup, "victory continues run")
	check(game.power_pending and game.arena == null, "victory offers power and returns to world")
	game.runx.card({"cat": "rx_power", "id": "mega"})
	game.runx.card({"cat": "rx_form", "id": "100006"})
	var attack: float = game.base_atk
	game._dyn_start()
	check(game.player.dex == 100006 and game.dyn.total == 40, "real Mega sprite and duration")
	game.dyn.stop()
	check(game.player.dex == 6 and is_equal_approx(game.base_atk, attack), "Mega restores original stats and sprite")
	game.selected_power = "gmax"
	game.selected_form = 150006
	game._dyn_start()
	check(game.player.dex == 150006 and game.dyn.total == 12, "Gmax sprite and duration")
	game.dyn.stop()
	game.selected_power = "tera"
	game.selected_tera = "water"
	game._dyn_start()
	check(game.player.types == ["water"], "Terastal changes type")
	game.dyn.stop()
	check(game.player.types.has("fire"), "Terastal restores original type")
	game.choosing = false
	game.cards.hide_cards()
	check(game.runx.collect("sphere:speed"), "sphere pickup")
	game.runx.use_orb("speed")
	check(game.runx.has_buff("speed") and game.runx.spheres.is_empty(), "sphere consumed once")
	var ui = UI.open(game, "home", game.runx)
	check(game.paused, "expanded menu pauses combat")
	ui.close()
	check(not game.paused, "expanded menu restores pause state")
	await process_frame
	game.queue_free()
	await process_frame
	await create_timer(1.1).timeout
	load("res://scripts/sprites.gd").clear()
	load("res://scripts/profile_art.gd").clear()
	load("res://scripts/vfx.gd").cache.clear()
	load("res://scripts/audio.gd").shutdown()
	await process_frame
	print("REGRESSION FAILURES: ", failures)
	quit(1 if failures > 0 else 0)
