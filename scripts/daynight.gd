extends RefCounted
# S57.12: ciclo dia/noche usando SOLO el reloj de juego activo (run_time). La pausa lo congela; no toca los temporizadores de desafios.
# Ciclo de 8 min: 0-3 dia, 3-4 ocaso, 4-7 noche, 7-8 alba. Solo modifica color y los pesos de NUEVAS apariciones.

const CYCLE := 480.0
const P_DAY := 180.0
const P_DUSK := 240.0
const P_NIGHT := 420.0
const NIGHT_DEX := [92, 93, 94, 41, 42, 169, 198, 200, 163, 164, 197, 430, 355, 354, 442, 609, 610, 593, 592]
const DAY_DEX := [191, 192, 187, 188, 189, 43, 44, 45, 182, 546, 547, 549, 548, 193, 12]
const COLS := {
	"day": Color(1, 1, 1, 0.0),
	"dusk": Color(0.95, 0.5, 0.25, 0.20),
	"night": Color(0.06, 0.09, 0.28, 0.40),
	"dawn": Color(1.0, 0.72, 0.62, 0.14),
}
var m = null
var rect: ColorRect = null
var last_phase := ""


func phase_at(t: float) -> String:
	var c: float = fposmod(t, CYCLE)
	if c < P_DAY:
		return "day"
	if c < P_DUSK:
		return "dusk"
	if c < P_NIGHT:
		return "night"
	return "dawn"


func phase() -> String:
	return phase_at(m.run_time)


func is_night() -> bool:
	return phase() == "night"


func color_at(t: float) -> Color:
	var c: float = fposmod(t, CYCLE)
	var keys: Array = [[0.0, "day"], [P_DAY - 20.0, "day"], [P_DAY + 20.0, "dusk"], [P_DUSK - 10.0, "dusk"], [P_DUSK + 25.0, "night"], [P_NIGHT - 10.0, "night"], [P_NIGHT + 20.0, "dawn"], [CYCLE - 20.0, "dawn"], [CYCLE, "day"]]
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if c >= float(a[0]) and c <= float(b[0]):
			var k: float = (c - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			return (COLS[a[1]] as Color).lerp(COLS[b[1]], k)
	return COLS["day"]


func setup() -> void:
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 0.0)
	m.ui_layer.add_child(rect)
	m.ui_layer.move_child(rect, 0)


func update(_delta: float) -> void:
	if rect == null:
		return
	# dentro de grietas el escenario usa su propia iluminacion
	if m.arena != null or m.mode == "tower":
		rect.visible = false
		return
	rect.visible = true
	rect.color = color_at(m.run_time)
	var ph: String = phase()
	if ph != last_phase:
		if last_phase == "night" and ph == "dawn" and m.player != null and not m.player.dead:
			m.ach_event("night", {})
		if last_phase != "":
			var msg := {"day": "Amanece: es de día.", "dusk": "Atardece…", "night": "Cae la noche.", "dawn": "Se acerca el amanecer."}
			m._say(m.L.t(String(msg[ph])), 2.2)
		last_phase = ph


# Peso extra para NUEVAS apariciones (solo especies que ya estan en el catalogo del mapa).
func weight_mul(dex: int) -> float:
	if m.arena != null or m.mode == "tower":
		return 1.0
	var ph: String = phase()
	if (ph == "night" or ph == "dusk") and NIGHT_DEX.has(dex):
		return 2.2 if ph == "night" else 1.4
	if (ph == "day" or ph == "dawn") and DAY_DEX.has(dex):
		return 2.0 if ph == "day" else 1.4
	return 1.0
