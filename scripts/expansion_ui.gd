extends CanvasLayer
# Mochila, Vestidor, Maestria, Perfil, Desafio semanal y Casino.
# Mismo aspecto que el resto de menus del port: fuente pixelada, botones azules, paneles azul marino
# con borde claro, dorado para lo elegido y barra superior con "◀ Volver" y las monedas.
const SP = preload("res://scripts/sprites.gd")
const SV = preload("res://scripts/save_data.gd")
const CT = preload("res://scripts/content.gd")
const ART = preload("res://scripts/profile_art.gd")
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const PXF = preload("res://scripts/pxfont.gd")
const Aud = preload("res://scripts/audio.gd")
const DSP = preload("res://scripts/display.gd")
const C_GOLD := Color("#ffd33d")
const C_SUB := Color("#9fb4dc")
const C_CARD := Color(0.05, 0.1, 0.26, 0.9)
const C_EDGE := Color("#33498f")
const TAB_ICON := {"home": "ball", "bag": "r_l_bag", "dress": "star", "mastery": "crown", "profile": "medal1", "weekly": "m_daily", "casino": "gcoin_gold",
	"ball": "ball", "coin": "coin", "sound": "sound", "egg": "ball", "lock": "ball"}
var C_PANEL := Color("#27449a")
var C_PANEL_D := Color("#18296a")
var C_BTN := Color("#1c3a8c")
var C_BTN_H := Color("#2f58c9")
var host
var runtime = null
var was_paused := false
var panel: VBoxContainer
var body: VBoxContainer
var notice: Label
var navigation: Array = []
var title_label: Label
var subtitle_label: Label
var title_icon: TextureRect
var scroll: ScrollContainer
var hidden_host: Array = []
var cosmetic_tab := "looks"
var frame_page := 0
var profile_tab := "photos"
var selected := 25
var filter := ""
var section := "home"
var casino_busy := false
var casino_stake := 20
var board: Array = []
var found := 0
var cash := 0
var game_over := true
var cards: Array = []
var mastery_page := 0

static func open(parent: Node, page: String = "home", run = null) -> CanvasLayer:
	var existing = parent.get_node_or_null("ExpansionUI")
	if existing != null:
		return existing
	var ui = load("res://scripts/expansion_ui.gd").new()
	ui.name = "ExpansionUI"
	ui.host = parent
	ui.runtime = run
	ui.section = page
	parent.add_child(ui)
	return ui

func _ready() -> void:
	layer = 60
	selected = int(SV.d["selected"])
	# Colores del tema de interfaz elegido en Ajustes (los mismos que usa el menu).
	if host != null and host.get("C_PANEL") is Color:
		C_PANEL = host.C_PANEL; C_PANEL_D = host.C_PANEL_D; C_BTN = host.C_BTN; C_BTN_H = host.C_BTN_H
	if runtime != null:
		was_paused = host.paused
		host.paused = true
	else:
		# En el menu: se esconde la pantalla de debajo y su barra superior; se ve el fondo del mapa como en las demas.
		var screens = host.get("screens")
		var cur = host.get("cur")
		if screens is Dictionary and screens.has(cur):
			hidden_host.append(screens[cur])
		for key in ["back_btn", "credit_box"]:
			var n = host.get(key)
			if n is Control:
				hidden_host.append(n.get_parent() if key == "back_btn" else n)
		for n in hidden_host:
			n.visible = false
	var root := Control.new()
	root.theme = make_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0.05, 0.1, 0.82 if runtime != null else 0.46)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var ins: Vector4 = DSP.insets(get_tree())
	# Barra superior: ◀ Volver + monedas (igual que en el resto de pantallas)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16 + ins.x
	top.offset_right = -16 - ins.z
	top.offset_top = 10 + ins.y
	top.offset_bottom = 58
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var back := button("◀ Volver", close)
	back.custom_minimum_size = Vector2(150, 44)
	top.add_child(back)
	var pill := PanelContainer.new()
	var psb := _sb(Color("#0f2268"), Color("#b5cdfb"), 3, 24)
	psb.content_margin_left = 16
	psb.content_margin_right = 16
	psb.content_margin_top = 6
	psb.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", psb)
	pill.custom_minimum_size = Vector2(0, 44)
	top.add_child(pill)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	pill.add_child(prow)
	var cic := IC.rect("coin", 26)
	cic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(cic)
	notice = Label.new()
	notice.add_theme_font_size_override("font_size", 22)
	notice.add_theme_color_override("font_color", Color.WHITE)
	notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prow.add_child(notice)
	# Contenido
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24 + int(ins.x))
	margin.add_theme_constant_override("margin_right", 24 + int(ins.z))
	margin.add_theme_constant_override("margin_top", 72 + int(ins.y))
	margin.add_theme_constant_override("margin_bottom", 18 + int(ins.w))
	root.add_child(margin)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	margin.add_child(panel)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	panel.add_child(nav)
	for tab in [["Inicio", "home"], ["Mochila", "bag"], ["Vestidor", "dress"], ["Maestría", "mastery"], ["Perfil", "profile"], ["Desafío semanal", "weekly"]]:
		var id: String = tab[1]
		if runtime != null and id != "home":
			continue
		var b := button(String(tab[0]), func(): section = id; refresh())
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon = ico(id)
		b.add_theme_constant_override("h_separation", 8)
		b.set_meta("page", id)
		navigation.append(b)
		nav.add_child(b)
	# Cabecera: cinta azul con el titulo (como las secciones de Misiones/Logros)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	panel.add_child(heading)
	var rib := PanelContainer.new()
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var rsb := _sb(Color("#2a56c4"), Color("#b5cdfb"), 3, 12)
	rsb.content_margin_left = 16
	rsb.content_margin_right = 18
	rib.add_theme_stylebox_override("panel", rsb)
	heading.add_child(rib)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 10)
	rib.add_child(rrow)
	title_icon = TextureRect.new()
	title_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	title_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rrow.add_child(title_icon)
	title_label = txt("", 28, Color.WHITE)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.add_theme_color_override("font_outline_color", Color("#0b1a55"))
	title_label.add_theme_constant_override("outline_size", 6)
	rrow.add_child(title_label)
	subtitle_label = txt("", 18, C_SUB)
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(subtitle_label)
	# Marco principal azul con borde blanco, como el resto de pantallas
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fsb := _sb(C_PANEL, Color.WHITE, 3, 10)
	fsb.set_content_margin_all(12)
	frame.add_theme_stylebox_override("panel", fsb)
	panel.add_child(frame)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	refresh()
	if not navigation.is_empty():
		for b in navigation:
			if b.get_meta("page") == section:
				b.call_deferred("grab_focus")

func _sb(col: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func txt(value: String, font_size: int = 20, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = L.t(value)
	l.add_theme_font_size_override("font_size", maxi(14, font_size))
	# Los textos oscuros del diseno anterior pasan a claros sobre el azul.
	l.add_theme_color_override("font_color", color if color.get_luminance() > 0.45 else Color("#dbe6ff"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func ico(id: String) -> Texture2D:
	var n: String = String(TAB_ICON.get(id, "ball"))
	return IC.tex(n, IC.scale_for(n, 28))

func button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.custom_minimum_size = Vector2(140, 48)
	b.focus_mode = Control.FOCUS_ALL
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.pressed.connect(action)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	return b

func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 22
	PXF.apply(theme)
	for t in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", t, _sb(C_BTN, Color("#6f8be0"), 2))
		theme.set_stylebox("hover", t, _sb(C_BTN_H, Color("#9fb4f0"), 2))
		theme.set_stylebox("pressed", t, _sb(C_PANEL_D, C_GOLD, 2))
		theme.set_stylebox("focus", t, _sb(C_BTN_H, C_GOLD, 4))
		theme.set_stylebox("disabled", t, _sb(Color("#222c4a"), Color("#3a456a"), 2))
		theme.set_color("font_color", t, Color.WHITE)
		theme.set_color("font_hover_color", t, Color.WHITE)
		theme.set_color("font_focus_color", t, Color.WHITE)
		theme.set_color("font_pressed_color", t, Color.WHITE)
		theme.set_color("font_disabled_color", t, Color("#7d86a6"))
		theme.set_font_size("font_size", t, 20)
	theme.set_stylebox("panel", "PanelContainer", _sb(C_PANEL, Color.WHITE, 3, 10))
	theme.set_stylebox("normal", "LineEdit", _sb(Color("#0f2268"), Color("#6f8be0"), 2, 10))
	theme.set_stylebox("focus", "LineEdit", _sb(Color("#0f2268"), C_GOLD, 3, 10))
	theme.set_color("font_color", "LineEdit", Color.WHITE)
	theme.set_color("font_placeholder_color", "LineEdit", Color("#7d86a6"))
	theme.set_color("font_color", "Label", Color.WHITE)
	var pbg := _sb(Color("#0b1a55"), Color("#6f8be0"), 2, 7)
	pbg.content_margin_top = 0
	pbg.content_margin_bottom = 0
	var pfill := _sb(Color("#3fd45c"), Color.TRANSPARENT, 0, 6)
	pfill.content_margin_top = 0
	pfill.content_margin_bottom = 0
	theme.set_stylebox("background", "ProgressBar", pbg)
	theme.set_stylebox("fill", "ProgressBar", pfill)
	theme.set_stylebox("scroll", "VScrollBar", _sb(Color(0, 0, 0, 0.25), Color.TRANSPARENT, 0, 6))
	theme.set_stylebox("grabber", "VScrollBar", _sb(Color("#6f8be0"), Color.TRANSPARENT, 0, 6))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _sb(Color("#9fb4f0"), Color.TRANSPARENT, 0, 6))
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	return theme

func label(text: String) -> Label:
	var lb := txt(text, 20)
	body.add_child(lb)
	return lb

func close() -> void:
	for n in hidden_host:
		if is_instance_valid(n):
			n.visible = true
	if runtime != null and is_instance_valid(host):
		host.paused = was_paused
	elif is_instance_valid(host) and host.has_method("_refresh_main"):
		host._refresh_main()
	queue_free()

func _input(ev: InputEvent) -> void:
	if (ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		get_viewport().set_input_as_handled()
		close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		close()

func refresh() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for b in navigation:
		selected_style(b, b.get_meta("page") == section, C_GOLD)
	scroll.scroll_vertical = 0
	notice.text = str(int(SV.d["coins"]))
	var titles: Dictionary = {"home": ["Aventura", "Pokémon, premios y un estilo muy tuyo."], "bag": ["Mochila", "Pequeñas ayudas para grandes aventuras."], "dress": ["Vestidor", "Tu compañero. Tu estilo. Tu colección."], "mastery": ["Maestría", "Cada partida cuenta. Cada compañero tiene su historia."], "profile": ["Perfil", "Una identidad tan única como tu equipo."], "weekly": ["Desafío semanal", "Una oportunidad. Un compañero. Tres minutos para brillar."], "casino": ["Casino Rocket", "Minijuegos locales · juega con tus Pokémonedas."]}
	title_label.text = L.t(titles.get(section, titles["home"])[0])
	title_icon.texture = IC.tex(String(TAB_ICON.get(section, "ball")), IC.scale_for(String(TAB_ICON.get(section, "ball")), 32))
	subtitle_label.text = L.t(titles.get(section, titles["home"])[1])
	match section:
		"bag": bag()
		"dress": dress()
		"mastery": mastery()
		"profile": profile()
		"weekly": weekly()
		"casino": casino()
		_: home()
	_fix_layout(body)

# Ajustes comunes tras construir una seccion:
# - un texto junto a un icono (fila horizontal) ocupa el ancho libre; si no, se parte letra a letra;
# - los iconos pixelados de los botones se dibujan a su tamaño (solo los sprites de Pokemon se escalan).
func _fix_layout(n: Node) -> void:
	for c in n.get_children():
		if c is Label and n is HBoxContainer and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
			(c as Label).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif c is Label and n.has_meta("center"):
			(c as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elif c is Button and (c as Button).icon != null and not ((c as Button).icon is AtlasTexture):
			(c as Button).expand_icon = false
		_fix_layout(c)

func choose_pokemon(action: Callable) -> void:
	var select := OptionButton.new()
	select.custom_minimum_size.y = 48
	select.focus_mode = Control.FOCUS_ALL
	var index := 0
	for p in SV.dex_list:
		var dx: int = int(p["dex"])
		if not SV.owns(dx):
			continue
		select.add_item(String(p["name"]), dx)
		if dx == selected:
			index = select.item_count - 1
	select.select(index)
	select.item_selected.connect(func(i: int): selected = select.get_item_id(i); action.call())
	body.add_child(select)

func preview(id: int) -> void:
	# Escenario como el de la ficha del Pokedex: panel azul con el sprite grande.
	var stage := PanelContainer.new()
	var ssb := _sb(Color("#1a2f74"), Color("#5f7fd0"), 3, 12)
	stage.add_theme_stylebox_override("panel", ssb)
	stage.custom_minimum_size = Vector2(0, 190)
	body.add_child(stage)
	var tx := pokemon_texture(id)
	if tx != null:
		var image := TextureRect.new()
		image.texture = tx
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(160, 160)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(image)
	var cry := button("Escuchar grito", func():
		if not bool(SV.setting("mute")): ART.play_cry(self, CT.base_dex(id)))
	cry.icon = ico("sound")
	body.add_child(cry)

func dress() -> void:
	var cols := columns()
	var left := card(cols[0], "TU COMPAÑERO", "Una vista previa de tu estilo", Color("#dbfff5"), "dress")
	var original := body
	body = left
	choose_pokemon(refresh)
	preview(CT.display_dex(selected))
	if SV.owns(selected) and bool(SV.d["owned"][str(selected)].get("shiny", false)):
		body.add_child(button("Normal / Shiny", func(): SV.set_dress(selected, "shiny", 0 if SV.show_shiny(selected) else 1); SV.save(); refresh()))
	body = original
	var right: VBoxContainer = cols[1]
	var tabs := HBoxContainer.new()
	right.add_child(tabs)
	for item in [["Aspectos", "looks"], ["Skins", "skins"], ["Estelas", "trails"]]:
		var key: String = item[1]
		var b := button(item[0], func(): cosmetic_tab = key; refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_style(b, key == cosmetic_tab, Color("#63dfc5"))
		tabs.add_child(b)
	var content := card(right, {"looks":"ELIGE TU ASPECTO", "skins":"TU COLECCIÓN DE SKINS", "trails":"DEJA TU HUELLA"}[cosmetic_tab], {"looks":"Los cambios visuales conservan tus atributos.", "skins":"Consigue 1000 puntos de maestría para desbloquear skins.", "trails":"Una compra, todos tus Pokémon. Equipa una estela diferente a cada uno."}[cosmetic_tab])
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	if cosmetic_tab == "looks":
		var base := button("Aspecto original", func(): SV.set_dress(selected, "form", selected); SV.save(); refresh())
		base.icon = ico("ball")
		base.expand_icon = true
		base.add_theme_constant_override("icon_max_width", 34)
		grid.add_child(base)
		for f in CT.options(CT.base_dex(selected), ["look"]):
			var id: int = int(f["id"])
			var b := button(String(f["fn"]), func(): SV.set_dress(selected, "form", id); SV.save(); refresh())
			b.disabled = not CT.cosmetic_ok(selected, f)
			b.icon = pokemon_texture(id)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 48)
			grid.add_child(b)
		if grid.get_child_count() == 1:
			content.add_child(txt("Este compañero luce su aspecto original. Explora sus skins y estelas para darle tu toque.", 18))
	elif cosmetic_tab == "skins":
		grid.add_child(button("Sin skin", func(): SV.set_dress(selected, "skin", ""); SV.save(); refresh()))
		for id in CT.skins():
			var info: Dictionary = CT.skins()[id]
			if int(info["dex"]) != CT.base_dex(selected): continue
			var key: String = id
			var skin_name := String(info["name"]).replace(String(SV.dex_by[CT.base_dex(selected)]["name"]) + " ", "")
			var b := button(skin_name.capitalize(), func():
				SV.set_dress(selected, "skin", key)
				SV.set_dress(selected, "form", selected)
				SV.save(); refresh())
			b.custom_minimum_size = Vector2(190, 100)
			b.disabled = not CT.skin_unlocked(CT.base_dex(selected), key)
			b.icon = pokemon_texture(CT.base_dex(selected), key)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 64)
			selected_style(b, CT.skin(selected) == key, Color("#64dfc5"))
			if key == "obsidiana-mewtwo": b.tooltip_text = L.t("Premio de Atrapa a Pikachu en el Casino Rocket")
			grid.add_child(b)
		if grid.get_child_count() == 1:
			content.add_child(txt("Todavía no hay skins para este Pokémon. ¡Prueba otro compañero o elige una estela!", 18))
	else:
		var current: String = String(SV.dress(selected).get("trail", ""))
		var none := button("Sin estela", func(): SV.set_dress(selected, "trail", ""); SV.save(); refresh())
		selected_style(none, current == "", Color("#64dfc5"))
		grid.add_child(none)
		for id in SV.TRAILS:
			var key := String(id)
			var data: Array = SV.TRAILS[id]
			var have := SV.has_trail(key)
			var b := button("%s\n%s" % [L.t(String(data[0])), L.t("En tu colección") if have else (L.t("Premio Rocket") if key == "rocket" else L.t("%d monedas") % int(data[3]))], func():
				if SV.has_trail(key) or SV.buy_trail(key):
					SV.set_dress(selected, "trail", key); SV.save(); refresh()
				else: notice.text = L.t("Necesitas más monedas") if key != "rocket" else L.t("Premio del Casino Rocket"))
			b.custom_minimum_size = Vector2(175, 74)
			selected_style(b, key == current, Color("#64dfc5"))
			grid.add_child(b)

func mastery() -> void:
	var cols := columns(315)
	var path := card(cols[0], "EL CAMINO A LA CIMA", "Premios de maestría", Color("#fff3cb"), "mastery")
	path.add_child(icon_rect("mastery", 82))
	for step in [[10000,"Foto de maestría"], [25000,"Título de maestro"], [50000,"Marco especial"], [100000,"Aura de maestría"]]:
		var row := HBoxContainer.new()
		path.add_child(row)
		row.add_child(icon_rect("mastery", 27))
		row.add_child(txt(L.t(String(step[1])) + "\n" + L.t("%s puntos") % format_points(int(step[0])), 17))
	var collection := card(cols[1], "TUS COMPAÑEROS", "La experiencia que habéis ganado juntos", Color("#eff8ff"), "ball")
	var search := LineEdit.new()
	search.placeholder_text = L.t("Buscar Pokémon…")
	search.text = filter
	search.custom_minimum_size.y = 45
	collection.add_child(search)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	collection.add_child(list)
	var pager := HBoxContainer.new()
	collection.add_child(pager)
	var render := func():
		for child in list.get_children():
			list.remove_child(child); child.queue_free()
		var mons: Array = SV.dex_list.filter(func(p): return SV.owns(int(p["dex"])) and (filter.is_empty() or String(p["name"]).to_lower().contains(filter.to_lower())))
		mons.sort_custom(func(a, b): return int(SV.mastery(int(a["dex"]))["pts"]) > int(SV.mastery(int(b["dex"]))["pts"]))
		mastery_page = clampi(mastery_page, 0, maxi(0, ceili(mons.size()/20.0)-1))
		for p in mons.slice(mastery_page * 20, mastery_page * 20 + 20):
			var dx: int = int(p["dex"])
			var ms: Dictionary = SV.mastery(dx)
			var row := HBoxContainer.new()
			row.name = "MasteryRow%d" % dx
			row.add_theme_constant_override("separation", 14)
			list.add_child(row)
			var b := button(String(p["name"]), func(): selected = dx; section = "profile"; refresh())
			b.custom_minimum_size = Vector2(210, 82)
			b.icon = pokemon_texture(dx)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
			row.add_child(b)
			var stats := VBoxContainer.new()
			stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(stats)
			stats.add_child(txt(L.t("%s puntos") % format_points(int(ms["pts"])), 20))
			var next := next_milestone(int(ms["pts"]))
			stats.add_child(progress(int(ms["pts"]), next))
			stats.add_child(txt(L.t("%d partidas · %d derrotados") % [int(ms["runs"]), int(ms["kills"])], 15, C_SUB))
		if mons.is_empty(): list.add_child(txt("No hay compañeros con ese nombre. Prueba otra búsqueda.", 18))
		pager.get_child(0).disabled = mastery_page <= 0
		pager.get_child(1).disabled = (mastery_page+1)*20 >= mons.size()
	search.text_changed.connect(func(text: String): filter = text; mastery_page = 0; render.call())
	pager.add_child(button("← Anterior", func(): mastery_page = maxi(0, mastery_page-1); refresh()))
	pager.add_child(button("Siguiente →", func(): mastery_page += 1; refresh()))
	render.call()

func profile() -> void:
	var cols := columns(340)
	var identity := card(cols[0], "CARNÉ DE ENTRENADOR", String(SV.d.get("nick", "Entrenador")), Color("#eae3ff"), "profile")
	var original := body
	body = identity
	choose_pokemon(refresh)
	var photo := ART.texture(String(SV.d.get("photo", "")))
	var avatar := Control.new()
	avatar.custom_minimum_size = Vector2(180, 135)
	body.add_child(avatar)
	var face := TextureRect.new()
	face.texture = photo if photo != null else pokemon_texture(CT.display_dex(selected))
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.offset_left = 70; face.offset_right = -70
	face.offset_top = 24; face.offset_bottom = -24
	avatar.add_child(face)
	var frame := ART.texture(String(SV.d.get("frame", "")))
	if frame != null:
		var overlay := TextureRect.new()
		overlay.texture = frame
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 62; overlay.offset_right = -62
		avatar.add_child(overlay)
	var pts: int = int(SV.mastery(selected)["pts"])
	label(String(SV.dex_by[selected]["name"]))
	label(String(SV.d.get("title", "")) if String(SV.d.get("title", "")) != "" else "Una nueva historia por escribir")
	body.add_child(progress(pts, next_milestone(pts)))
	label(L.t("%s puntos de maestría") % format_points(pts))
	if pts >= 25000:
		body.add_child(button("Equipar título de maestro", func(): SV.d["title"] = L.t("Maestro de %s") % SV.dex_by[selected]["name"]; SV.save(); refresh()))
	body = original
	var right: VBoxContainer = cols[1]
	var tabs := HBoxContainer.new()
	right.add_child(tabs)
	for entry in [["Expresiones", "photos"], ["Marcos de perfil", "frames"]]:
		var key: String = entry[1]
		var tab := button(entry[0], func(): profile_tab = key; refresh())
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_style(tab, profile_tab == key, Color("#c6b5ff"))
		tabs.add_child(tab)
	var expressions := card(right, "ELIGE TU EXPRESIÓN", "Dale personalidad a tu foto de perfil")
	expressions.get_parent().visible = profile_tab == "photos"
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	expressions.add_child(grid)
	var faces := ["normal", "happy", "determined", "angry", "sad", "surprised", "joyous", "inspired"]
	if pts >= 10000: faces.append_array(["special0", "special1", "special2", "special3"])
	var names := {"normal":"Normal", "happy":"Feliz", "determined":"Decidido", "angry":"Enfadado", "sad":"Triste", "surprised":"Sorpresa", "joyous":"Alegre", "inspired":"Inspirado"}
	for ex in faces:
		var path: String = "res://assets/tienda/fotos-perfil/%d/%s.png" % [selected, ex]
		if not ART.has(path): continue
		var chosen := path
		var b := button(names.get(ex, "Especial"), func(): SV.d["photo"] = chosen; SV.save(); refresh())
		b.icon = ART.texture(path)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 43)
		b.custom_minimum_size = Vector2(155, 65)
		selected_style(b, path == String(SV.d.get("photo", "")), Color("#c6b5ff"))
		grid.add_child(b)
	var frames := card(right, "ENMARCA TU HISTORIA", "Marcos de perfil · vista previa real")
	frames.get_parent().visible = profile_tab == "frames"
	var options: Array = []
	for file in ART.files("assets/tienda/marcos/"):
		if not file.ends_with(".png") or file.ends_with("-anim.png"): continue
		if file.begins_with("maestria_") and pts < 50000: continue
		options.append(file)
	frame_page = clampi(frame_page, 0, maxi(0, ceili(options.size()/6.0)-1))
	var frame_grid := HFlowContainer.new()
	frame_grid.add_theme_constant_override("h_separation", 8)
	frame_grid.add_theme_constant_override("v_separation", 8)
	frames.add_child(frame_grid)
	for file in options.slice(frame_page*6, frame_page*6+6):
		var path: String = "res://assets/tienda/marcos/" + String(file)
		var b := button(String(file).get_basename().replace("_", " ").capitalize(), func(): SV.d["frame"] = path; SV.save(); refresh())
		b.icon = ART.texture(path)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 54)
		b.custom_minimum_size = Vector2(195, 75)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		selected_style(b, path == String(SV.d.get("frame", "")), Color("#c6b5ff"))
		frame_grid.add_child(b)
	var pager := HBoxContainer.new()
	frames.add_child(pager)
	var prev := button("← Anterior", func(): frame_page -= 1; refresh())
	prev.disabled = frame_page == 0
	pager.add_child(prev)
	var nxt := button("Más marcos →", func(): frame_page += 1; refresh())
	nxt.disabled = (frame_page+1)*6 >= options.size()
	pager.add_child(nxt)

func bag() -> void:
	var cols := columns(330)
	var ready := card(cols[0], "LISTO PARA SALIR", "Tu objeto de la próxima partida", Color("#fff2d1"), "ball")
	ready.add_child(icon_rect("bag", 90))
	var inventory: Dictionary = SV.d.get("inventory", {})
	var chosen: String = String(SV.d.get("start_item", ""))
	ready.add_child(txt(item_name(chosen) if chosen != "" else "Sin objeto inicial", 24))
	ready.add_child(txt("Se consume al comenzar una partida normal. Elige con qué quieres salir.", 17))
	var clear := button("No llevar objeto", func(): SV.d["start_item"] = ""; SV.save(); refresh())
	clear.icon = ico("ball")
	clear.icon = ico("ball")
	selected_style(clear, chosen == "", Color("#ffd36a"))
	ready.add_child(clear)
	var right: VBoxContainer = cols[1]
	var supply := card(right, "TUS RESERVAS", "Los jefes y cofres pueden dejar objetos para tu mochila.", Color("#eff8ff"), "bag")
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	supply.add_child(grid)
	for id in inventory:
		if int(inventory[id]) <= 0: continue
		var key: String = id
		var b := button(item_name(key) + "\n" + L.t("×%d disponibles") % int(inventory[key]), func(): SV.d["start_item"] = key; SV.save(); refresh())
		b.custom_minimum_size = Vector2(210, 86)
		b.icon = ico("ball" if key.begins_with("sphere:") else "bag")
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 40)
		selected_style(b, key == chosen, Color("#ffd36a"))
		grid.add_child(b)
	if grid.get_child_count() == 0:
		var empty := HBoxContainer.new()
		supply.add_child(empty)
		empty.add_child(icon_rect("ball", 52))
		empty.add_child(txt("Tu próxima aventura llenará estos bolsillos.\nDerrota jefes y abre cofres para encontrar reservas.", 18))
	var eggs := SV.eggs()
	var hatch := card(right, L.t("La incubadora · %d / %d") % [eggs.size(), SV.EGG_MAX], "Tus huevos avanzan mientras juegas. ¡Pueden salir shiny!", Color("#eff8ff"), "egg")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	hatch.add_child(row)
	for i in range(SV.EGG_MAX):
		var nest := VBoxContainer.new()
		nest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nest)
		var egg := icon_rect("egg" if i < eggs.size() else "ball", 47)
		if i >= eggs.size(): egg.modulate.a = 0.22
		nest.add_child(egg)
		if i < eggs.size():
			var e: Dictionary = eggs[i]
			nest.add_child(progress(float(e["prog"]), float(e["need"])))
			var mins := ceili(maxf(0,float(e["need"])-float(e["prog"]))/60.0)
			nest.add_child(txt(L.t("%d min") % mins, 15))
		else: nest.add_child(txt("Libre", 15, C_SUB))

func weekly() -> void:
	var w: Dictionary = CT.weekly()
	var record: Dictionary = SV.d.get("weekly", {})
	if int(record.get("week", -1)) != int(w["week"]):
		record = {"week": w["week"], "used": false, "best": 0, "rewarded": false}
		SV.d["weekly"] = record
		SV.save()
	var cols := columns(380)
	var featured := card(cols[0], "COMPAÑERO DE LA SEMANA", String(SV.dex_by[int(w["dex"])]["name"]), Color("#f9e3ef"), "weekly")
	var original := body
	body = featured
	preview(int(w["dex"]))
	body = original
	featured.add_child(txt("Pokémon prestado\nSin mejoras de tu colección", 17))
	var right: VBoxContainer = cols[1]
	var rules := card(right, "EL RETO", {"storm":"Climas cambiantes", "nohealing":"Sin curaciones", "night":"Noche cerrada", "type":L.t("Todos de tipo %s") % L.t(String(w["type"]))}[w["rule"]], Color("#eff8ff"), "weekly")
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 12)
	rules.add_child(badges)
	for info in [["03:00", "Tu objetivo"], ["1", "Intento semanal"], ["%ds" % int(record.get("best",0)), "Tu récord"]]:
		var tile := card(badges, info[0], info[1], Color("#eef2ff"))
		tile.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_child(txt("Sobrevive tres minutos con las mismas condiciones para todos. Tu récord se guarda en este dispositivo.", 18))
	var prize := card(right, "TU RECOMPENSA", "", Color("#eff8ff"), "mastery")
	var prize_row := HBoxContainer.new()
	prize.add_child(prize_row)
	prize_row.add_child(icon_rect("mastery", 56))
	prize_row.add_child(txt(L.t("1 ticket de 10 tiradas") + "\n" + L.t("Recompensa conseguida" if bool(record.get("rewarded",false)) else "Una recompensa por semana"), 22))
	var b := button("Intento utilizado · vuelve la próxima semana" if bool(record.get("used",false)) else "¡Aceptar el desafío!  →", func():
		SV.d["weekly"]["used"] = true
		SV.run_mode = "weekly"
		SV.run_dex = int(w["dex"])
		SV.run_seed = int(w["seed"])
		SV.run_mods = []
		SV.save()
		host.get_tree().change_scene_to_file("res://scenes/main.tscn"))
	b.custom_minimum_size.y = 58
	b.disabled = bool(record.get("used", false))
	selected_style(b, not b.disabled, Color("#ffd15a"))
	right.add_child(b)

func casino() -> void:
	# 7.1: el Casino Rocket nuevo, como el del juego original
	var h = host
	var dx: int = int(SV.d.get("selected", 25))
	close()
	load("res://scripts/rocket_casino.gd").open(h, dx)
	return
	label("Casino Rocket · monedas locales · apuesta 20 · puedes salir cuando quieras")
	label("Tragaperras: tres símbolos iguales pagan ×8; pareja paga ×2. La casa tiene ventaja.")
	body.add_child(button("Tragaperras", spin))
	body.add_child(button("Voltorb escondido", voltorb))
	body.add_child(button("Carrera Rocket", race))
	body.add_child(button("¡Atrapa a Pikachu!", catch_game))

func charge() -> bool:
	if casino_busy or int(SV.d["coins"]) < casino_stake:
		notice.text = "No tienes monedas suficientes o ya hay una jugada en curso"
		return false
	SV.d["coins"] = int(SV.d["coins"]) - casino_stake
	SV.save()
	return true

func pay(amount: int) -> void:
	SV.d["coins"] = int(SV.d["coins"]) + amount
	SV.save()
	notice.text = "Premio %d · Saldo %d" % [amount, int(SV.d["coins"])]

func spin() -> void:
	if not charge():
		return
	var symbols: Array = [randi() % 6, randi() % 6, randi() % 6]
	var win: int = casino_stake * 8 if symbols[0] == symbols[1] and symbols[1] == symbols[2] else (casino_stake * 2 if symbols[0] == symbols[1] or symbols[1] == symbols[2] or symbols[0] == symbols[2] else 0)
	pay(win)
	notice.text += " · Rodillos " + str(symbols)
	if win == casino_stake * 8:
		SV.d["rocket_trail"] = true
		SV.save()

func voltorb() -> void:
	if not charge():
		return
	refresh()
	cards.clear()
	game_over = false
	board = range(9)
	board.shuffle()
	board = board.slice(0, 2)
	found = 0
	cash = 0
	var grid := GridContainer.new()
	grid.columns = 3
	body.add_child(grid)
	for i in range(9):
		var idx := i
		var b := button("Poké Ball", func(): reveal_voltorb(idx))
		grid.add_child(b)
		cards.append(b)
	body.add_child(button("Retirarse y cobrar", func():
		if not game_over:
			game_over = true
			pay(cash)
			cards.clear()))

func reveal_voltorb(i: int) -> void:
	if game_over or i >= cards.size() or not is_instance_valid(cards[i]) or cards[i].disabled:
		return
	cards[i].disabled = true
	if board.has(i):
		cards[i].text = "Voltorb"
		game_over = true
		notice.text = "¡Voltorb! Pierdes la apuesta"
		cards.clear()
	else:
		found += 1
		cash = casino_stake + found * 8
		cards[i].text = str(cash)
		notice.text = "Puedes retirarte con %d" % cash
		if found == 7:
			game_over = true
			pay(cash)
			cards.clear()

func race() -> void:
	label("Elige a tu corredor. Si gana, cobras ×2.")
	for i in range(3):
		var runner := i
		var b := button(["Pikachu", "Meowth", "Eevee"][i], func():
			if not charge():
				return
			casino_busy = true
			race_run(runner))
		body.add_child(b)

func race_run(chosen: int) -> void:
	var bars: Array = []
	for i in range(3):
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 36
		body.add_child(bar)
		bars.append(bar)
	var winner := -1
	while winner < 0 and is_inside_tree():
		await get_tree().create_timer(0.1).timeout
		for i in range(3):
			if not is_instance_valid(bars[i]):
				casino_busy = false
				return
			bars[i].value += randf_range(1.0, 6.0)
			if bars[i].value >= 100.0 and winner < 0:
				winner = i
	casino_busy = false
	pay(casino_stake * 2 if winner == chosen else 0)

func catch_game() -> void:
	if not charge():
		return
	casino_busy = true
	var area := Control.new()
	area.custom_minimum_size = Vector2(600, 220)
	body.add_child(area)
	var target := Button.new()
	target.text = "Pikachu"
	target.size = Vector2(100, 50)
	area.add_child(target)
	var state := {"hits": 0, "done": false}
	target.pressed.connect(func():
		if state["done"]:
			return
		state["hits"] = int(state["hits"]) + 1
		target.position = Vector2(randf_range(0, maxf(1, area.size.x - 110)), randf_range(0, 160))
		if int(state["hits"]) >= 9:
			state["done"] = true)
	var remaining := 15.0
	while remaining > 0.0 and not bool(state["done"]) and is_inside_tree():
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(target):
			casino_busy = false
			return
		remaining -= 0.1
		target.position.x = fposmod(target.position.x + 12.0 + float(int(state["hits"]) / 3) * 8.0, maxf(1.0, area.size.x - 110))
		notice.text = "Plan %d/3 · atrapadas %d/9 · %d s" % [mini(3, 1 + int(state["hits"]) / 3), int(state["hits"]), ceili(remaining)]
	casino_busy = false
	state["done"] = true
	target.disabled = true
	pay(casino_stake * 4 if int(state["hits"]) >= 9 else 0)
	if int(state["hits"]) >= 9:
		SV.d["rocket_skin"] = true
		SV.save()


func icon_rect(id: String, height: int) -> Control:
	if id == "egg":
		var eg = load("res://scripts/menu.gd").EggIcon.new()   # el mismo huevo que la mochila de huevos del menu
		eg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return eg
	var n: String = String(TAB_ICON.get(id, "ball"))
	var tx := IC.rect(n, float(height))
	tx.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return tx

func columns(left_width: int = 340) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	body.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = left_width
	left.add_theme_constant_override("separation", 16)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	row.add_child(right)
	return [left, right]

func card(parent: Node, title: String, caption: String = "", color: Color = Color("#eff8ff"), icon_id: String = "") -> VBoxContainer:
	# Panel azul marino con borde azul (como los de la ficha y el Vestidor del menu) y una Poke Ball tenue
	# en la esquina; los paneles destacados (columna izquierda) llevan borde dorado y el texto centrado.
	var pan := Card.new()
	var featured: bool = color != Color("#eff8ff")
	var st := _sb(C_CARD, Color("#d9b04a") if featured else C_EDGE, 3 if featured else 2, 14)
	st.set_content_margin_all(12)
	pan.add_theme_stylebox_override("panel", st)
	parent.add_child(pan)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	if featured:
		content.set_meta("center", true)
	pan.add_child(content)
	if title != "":
		var key := title.substr(0, 1) + title.substr(1).to_lower() if title == title.to_upper() and title.length() > 3 else title
		var tl := txt(key, 24, C_GOLD)
		tl.add_theme_color_override("font_outline_color", Color("#1b1528"))
		tl.add_theme_constant_override("outline_size", 4)
		if icon_id != "":
			var hrow := HBoxContainer.new()
			hrow.add_theme_constant_override("separation", 10)
			if featured:
				hrow.alignment = BoxContainer.ALIGNMENT_CENTER
			var ic := icon_rect(icon_id, 30)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hrow.add_child(ic)
			tl.autowrap_mode = TextServer.AUTOWRAP_OFF
			hrow.add_child(tl)
			content.add_child(hrow)
		else:
			content.add_child(tl)
	if caption != "": content.add_child(txt(caption, 17, C_SUB))
	return content

# Elegido = dorado (como "Todos" o la estela equipada en el menu); el resto, boton azul normal.
func selected_style(b: Button, active: bool, _color: Color) -> void:
	if not active:
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.remove_theme_stylebox_override(st)
		b.remove_theme_color_override("font_color")
		b.remove_theme_constant_override("outline_size")
		return
	var c := Color("#f7b733")
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _sb(c, Color("#fff4d0"), 3, 12))
	var f := _sb(c.lightened(0.15), Color.BLACK, 4, 12)
	f.shadow_color = Color.WHITE
	f.shadow_size = 4
	b.add_theme_stylebox_override("focus", f)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color("#3a2606"))
	b.add_theme_constant_override("outline_size", 5)

func progress(value: float, maximum: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 10
	bar.show_percentage = false
	bar.max_value = maxf(1, maximum)
	bar.value = value
	return bar

func next_milestone(points: int) -> int:
	for n in [1000, 10000, 25000, 50000, 100000]:
		if points < n: return n
	return 100000

func format_points(points: int) -> String:
	if points >= 1000: return "%d %03d" % [points/1000, points%1000]
	return str(points)

func pokemon_texture(id: int, skin_id: String = "") -> Texture2D:
	var sm: Dictionary = SV.smeta.get(str(id), {})
	if sm.is_empty(): return null
	var info: Dictionary = sm["a"]["Idle"]
	var path: String = "res://assets/pokemon/%d/%s.png" % [id, String(info.get("f", "Idle"))]
	var chosen := skin_id if skin_id != "" else CT.skin(id)
	if chosen != "":
		var skin_path: String = "res://assets/pokemon/%d/k-%s/%s.png" % [id, chosen, String(info.get("f", "Idle"))]
		if SP.exists(skin_path): path = skin_path
	if not SP.exists(path): return null
	var at := AtlasTexture.new()
	at.atlas = SP.texture(path)
	at.region = Rect2(0, 0, float(info["w"]), float(info["h"]))
	return at

func item_name(id: String) -> String:
	var names := {"berry:oran":"Baya Aranja", "berry:sitrus":"Baya Zidra", "berry:lum":"Baya Ziuela", "berry:chesto":"Baya Atania", "berry:pecha":"Baya Meloc", "sphere:speed":"Rapidosfera", "sphere:sleep":"Soporesfera", "sphere:slow":"Ralentosfera", "sphere:push":"Ráfagaesfera", "sphere:focus":"Focosfera", "sphere:light":"Luminosfera", "mochi:atk":"Mochi de ataque", "mochi:def":"Mochi de defensa", "mochi:spd":"Mochi de velocidad"}
	return L.t(String(names.get(id, id.replace("_", " ").replace(":", " · ").capitalize())))


# Boton grande de dos lineas: icono + titulo + descripcion (como las tarjetas de modos del menu).
func big_button(title: String, sub: String, icon_id: String, action: Callable) -> Button:
	var b := button("", action)
	b.custom_minimum_size = Vector2(0, 78)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16
	h.offset_right = -12
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ic := icon_rect(icon_id, 44)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var t := txt(title, 24, Color.WHITE)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.add_theme_color_override("font_outline_color", Color("#0b1a55"))
	t.add_theme_constant_override("outline_size", 4)
	v.add_child(t)
	var s := txt(sub, 17, Color("#dbe6ff"))
	s.autowrap_mode = TextServer.AUTOWRAP_OFF
	s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(s)
	for n in [t, s]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func home() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	body.add_child(row)
	var links := VBoxContainer.new()
	links.custom_minimum_size.x = 470
	links.add_theme_constant_override("separation", 10)
	row.add_child(links)
	var entries := [["Mochila", "bag", "Prepara objetos e incuba tus huevos"], ["Vestidor", "dress", "Aspectos, skins y estelas"], ["Maestría", "mastery", "Progreso y premios de tus compañeros"], ["Perfil", "profile", "Expresa tu personalidad"], ["Desafío semanal", "weekly", "Supera un reto diferente cada semana"]]
	if runtime != null: entries = [["Casino Rocket", "casino", "Un descanso entre aventuras"]]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var key: String = entry[1]
		var b := big_button(String(entry[0]), String(entry[2]), key, func(): section = key; refresh())
		if i == 0: selected_style(b, true, C_GOLD)
		links.add_child(b)
	if runtime == null and int(SV.d["stats"].get("judged", 0)) > 0:
		links.add_child(big_button("Casino Rocket", "Un descanso entre aventuras", "casino", func(): section = "casino"; refresh()))
	var feature := VBoxContainer.new()
	feature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feature.add_theme_constant_override("separation", 12)
	row.add_child(feature)
	# Ilustracion con marco azul claro (la del paisaje que trajo la 7.1)
	var art := PanelContainer.new()
	var asb := _sb(Color("#0b1a55"), Color("#8fb0ff"), 3, 12)
	asb.set_content_margin_all(4)
	art.add_theme_stylebox_override("panel", asb)
	feature.add_child(art)
	var pic := TextureRect.new()
	pic.texture = load("res://assets/ui/adventure/landscape.png")
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = Vector2(0, 200)
	pic.clip_contents = true
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(pic)
	var spotlight := card(feature, "TU AVENTURA CONTINÚA", "El siguiente gran recuerdo empieza contigo.", Color(0.9,0.98,1,0.93), "ball")
	var tiny := HBoxContainer.new()
	tiny.add_theme_constant_override("separation", 20)
	spotlight.add_child(tiny)
	var tx := TextureRect.new()
	tx.texture = pokemon_texture(CT.display_dex(selected))
	tx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tx.custom_minimum_size = Vector2(90, 90)
	tiny.add_child(tx)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	tiny.add_child(info)
	info.add_child(txt(String(SV.dex_by[selected]["name"]), 26, Color.WHITE))
	info.add_child(txt(L.t("%s puntos de maestría") % format_points(int(SV.mastery(selected)["pts"])), 20, C_GOLD))


# Panel con una Poke Ball tenue dibujada en la esquina (marca de agua, como en los paneles del original).
class Card extends PanelContainer:
	func _draw() -> void:
		var r: float = minf(size.y * 0.30, 44.0)
		if r < 14.0 or size.y < 120.0:
			return
		var c := Vector2(size.x - r - 16.0, r + 14.0)
		var col := Color(0.55, 0.7, 1.0, 0.10)
		draw_arc(c, r * 0.8, 0.0, TAU, 40, col, r * 0.36)
		draw_line(c - Vector2(r, 0.0), c - Vector2(r * 0.34, 0.0), col, r * 0.16)
		draw_line(c + Vector2(r * 0.34, 0.0), c + Vector2(r, 0.0), col, r * 0.16)
		draw_circle(c, r * 0.16, col)
