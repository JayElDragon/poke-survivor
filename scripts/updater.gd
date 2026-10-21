extends Node
# Aviso de actualizacion: al abrir el juego pregunta a GitHub cual es la ultima release y, si es mas nueva
# que esta version, muestra un aviso con un boton para descargarla. Si no hay internet, no hace nada.
# La version instalada sale de Proyecto > Ajustes del proyecto > Aplicacion > Config > Version (application/config/version),
# que tambien usa el export de Android si dejas vacio su "Nombre de version". Un solo sitio que subir en cada release,
# y el tag de GitHub debe ser ese mismo numero con una v (p. ej. v3.0.1). Si ese ajuste esta vacio se usa FALLBACK_VERSION.

const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")
const PAD = preload("res://scripts/pad.gd")

const REPO := "JayElDragon/poke-survivor"
const FALLBACK_VERSION := "5.4"
static var APP_VERSION: String = _current()


static func _current() -> String:
	var v: String = String(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	return v if v != "" else FALLBACK_VERSION

signal found(info: Dictionary)

var req: HTTPRequest


func start() -> void:
	req = HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)
	req.request_completed.connect(_done)
	var err: int = req.request("https://api.github.com/repos/%s/releases/latest" % REPO, ["User-Agent: PokeSurvivorMobile", "Accept: application/vnd.github+json"])
	if err != OK:
		queue_free()


static func ver_parts(s: String) -> Array:
	var rx := RegEx.new()
	rx.compile("\\d+(?:\\.\\d+)*")
	var m := rx.search(s)
	var out: Array = []
	if m == null:
		return out
	for p in m.get_string().split("."):
		out.append(int(p))
	return out


static func is_newer(tag: String, current: String) -> bool:
	var a: Array = ver_parts(tag)
	var b: Array = ver_parts(current)
	if a.is_empty():
		return false
	for i in range(maxi(a.size(), b.size())):
		var x: int = int(a[i]) if i < a.size() else 0
		var y: int = int(b[i]) if i < b.size() else 0
		if x != y:
			return x > y
	return false


func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		queue_free()
		return
	var j = JSON.parse_string(body.get_string_from_utf8())
	if not (j is Dictionary):
		queue_free()
		return
	var tag: String = String(j.get("tag_name", ""))
	if not is_newer(tag, APP_VERSION) or String(SV.d.get("update_seen", "")) == tag:
		queue_free()
		return
	var page: String = String(j.get("html_url", "https://github.com/%s/releases" % REPO))
	var url: String = page
	for a in j.get("assets", []):
		if a is Dictionary and String(a.get("name", "")).to_lower().ends_with(".apk"):
			url = String(a.get("browser_download_url", page))
			break
	found.emit({"cur": APP_VERSION, "tag": tag, "name": String(j.get("name", tag)), "url": url, "page": page})
	queue_free()


# Aviso encima del menu. Funciona con toque, mando (izq/der + A / B) y teclado.
class UpdatePopup extends Control:
	var info: Dictionary
	var btns: Array = []
	var sel := 0
	var msg: Label

	func build(inf: Dictionary) -> void:
		info = inf
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		z_index = 4000
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.62)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var cc := CenterContainer.new()
		cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(cc)
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(620, 0)
		cc.add_child(pc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 14)
		pc.add_child(v)
		var t1 := Label.new()
		t1.text = L.t("¡Nueva actualización disponible!")
		t1.add_theme_font_size_override("font_size", 34)
		t1.add_theme_color_override("font_color", Color("#ffd33d"))
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t1)
		var t2 := Label.new()
		t2.text = L.t("Versión %s (tienes la %s).") % [String(info["tag"]), String(info.get("cur", "?"))]
		t2.add_theme_font_size_override("font_size", 24)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t2)
		var t3 := Label.new()
		t3.text = L.t("Descarga el APK nuevo e instálalo encima del actual: tu progreso se conserva.")
		t3.add_theme_font_size_override("font_size", 20)
		msg = t3
		t3.modulate = Color(1, 1, 1, 0.8)
		t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t3)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 20)
		v.add_child(row)
		for pair in [[L.t("Descargar actualización"), "go"], [L.t("Más tarde"), "no"]]:
			var b := Button.new()
			b.text = String(pair[0])
			b.custom_minimum_size = Vector2(300, 56)
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_press.bind(String(pair[1])))
			row.add_child(b)
			btns.append(b)
		(btns[0] as Button).grab_focus.call_deferred()
		SV.d["update_seen"] = String(info["tag"])
		SV.save()

	func _press(what: String) -> void:
		if what == "go":
			# Siempre en el navegador externo del telefono (no dentro del juego), para evitar errores de descarga.
			OS.shell_open(String(info["url"]))
		queue_free()

	func _process(_d: float) -> void:
		PAD.stick_tick()

	func _input(event: InputEvent) -> void:
		if not is_visible_in_tree():
			return
		if PAD.stick_event(event):
			get_viewport().set_input_as_handled()
			return
		var pressed: bool = (event is InputEventJoypadButton or event is InputEventKey) and event.pressed
		if event is InputEventKey and event.echo:
			return
		if PAD.is_cancel(event):
			queue_free()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			sel = 1 - sel
			(btns[sel] as Button).grab_focus()
		elif pressed and (event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.button_index == PAD.confirm_btn())):
			(btns[sel] as Button).pressed.emit()
		else:
			if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
				return
		if not (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):
			get_viewport().set_input_as_handled()
