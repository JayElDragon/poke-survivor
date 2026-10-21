extends RefCounted
# S57.11: peligros ambientales con aviso visible segun el bioma (se suman a la lava/pantano/hielo que ya existen en el suelo).
# Volcan/fuego: erupciones (quemadura). Hielo: rafaga fria (ralentiza). Electrico: rayos (paralisis breve). Veneno: burbujas toxicas.
# Un solo aviso a la vez, enfriamiento propio, estados que no se acumulan, inmunidad por tipo; los enemigos tambien los sufren.

const R := 74.0
const WARN := 1.5
const KINDS := {
	"fire": {"col": "#ff7b3d", "imm": ["fire"], "name": "Erupción"},
	"ice": {"col": "#8fe3ff", "imm": ["ice"], "name": "Ráfaga fría"},
	"electric": {"col": "#ffe14d", "imm": ["electric", "ground"], "name": "Rayo"},
	"poison": {"col": "#c86bdc", "imm": ["poison", "steel"], "name": "Burbujas tóxicas"},
}
const BIOME_KIND := {"volcano": "fire", "fire": "fire", "ice": "ice", "electric": "electric", "poison": "poison"}

var m = null
var cd := 14.0
var zone = null
var dot_t := 0.0
var dot_tick := 0.0
var dot_kind := ""
var log: Array = []


class Zone extends Node2D:
	var kind := "fire"
	var col := Color.WHITE
	var t := 0.0
	var warn := 1.5
	var r := 74.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var k: float = clampf(t / warn, 0.0, 1.0)
		draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.10 + 0.20 * k))
		draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(col.r, col.g, col.b, 0.9), 3.0)
		draw_arc(Vector2.ZERO, r * k, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)
		# marca de peligro
		var s: float = 10.0 + 4.0 * sin(t * 12.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s * 0.9, s * 0.7), Vector2(-s * 0.9, s * 0.7)]), Color(1, 0.9, 0.2, 0.9))


func _kind() -> String:
	if m.arena != null or m.mode == "tower":
		return ""
	return String(BIOME_KIND.get(m._biome_key(m.biome_idx), ""))


func _ok() -> bool:
	return not m.player.dead and m.arena == null and not m._boss_alive() and not m.dir_finale and not m.shop_open and (not m.has_method("caves_active") or not m.caves_active())


func immune(types: Array, kind: String) -> bool:
	for t in KINDS[kind]["imm"]:
		if types.has(t):
			return true
	return false


func update(delta: float) -> void:
	# estado persistente en el jugador (quemadura/veneno), sin acumulacion: solo se refresca la duracion
	if dot_t > 0.0:
		dot_t -= delta
		dot_tick -= delta
		if dot_tick <= 0.0 and not m.player.dead:
			dot_tick = 0.8
			m.player.invuln = 0.0
			m._hurt_player(maxf(2.0, m.player.max_hp * 0.015), "")
	if zone != null:
		if not is_instance_valid(zone):
			zone = null
		else:
			zone.warn = zone.warn
			if zone.t >= zone.warn:
				_impact(zone)
				zone.queue_free()
				zone = null
		return
	var kind: String = _kind()
	if kind == "" or not _ok():
		return
	cd -= delta
	if cd > 0.0:
		return
	cd = randf_range(9.0, 15.0)
	var pos: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 260.0)
	if m._blocked(pos, 20.0):
		return
	var z := Zone.new()
	z.kind = kind
	z.col = Color(String(KINDS[kind]["col"]))
	z.warn = WARN
	z.r = R
	z.position = pos
	z.z_index = -1
	m.world.add_child(z)
	zone = z
	log.append(["warn", kind])


func _impact(z) -> void:
	var kind: String = z.kind
	var pos: Vector2 = z.position
	var col: Color = z.col
	m._ring(pos, 6.0, R * 1.2, col, 0.45, 5.0)
	m.pfx.burst(pos + Vector2(0, -10), col, 26, 200.0)
	m.shake = maxf(m.shake, 3.0)
	m.Aud.sfx("judge")
	var hit_p := false
	if not m.player.dead and m.player.position.distance_to(pos) < R:
		if immune(m.player.types, kind):
			m.add_text(m.player.position + Vector2(0, -m.player.body_h - 8.0), m.L.t("¡Inmune!"), Color("#c8d0dc"), 16)
		else:
			hit_p = true
			m.player.invuln = 0.0
			m._hurt_player(maxf(5.0, m.player.max_hp * 0.07 + m.run_time * 0.02), "")
			match kind:
				"fire", "poison":
					dot_t = 3.0       # se refresca, nunca se apila
					dot_kind = kind
					dot_tick = 0.8
				"ice":
					m.trap_slow_t = maxf(m.trap_slow_t, 2.0)
				"electric":
					if randf() < 0.30:
						m.trap_para_t = maxf(m.trap_para_t, 0.8)
	for e in m.enemies.duplicate():
		if is_instance_valid(e) and not e.dead and not e.boss and e.position.distance_to(pos) < R:
			if immune(e.types, kind):
				continue
			m._damage_enemy(e, 30.0 + m.run_time * 0.05, col, (e.position - pos).normalized(), 120.0)
			match kind:
				"fire":
					e.apply_burn(1)
				"poison":
					e.apply_poison(1)
				"ice":
					e.apply_slow(0.5, 2.0)
				"electric":
					if randf() < 0.3:
						m._apply_cc(e, "para", 0.6)
	log.append(["impact", kind, hit_p])
