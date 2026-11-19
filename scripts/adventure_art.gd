extends RefCounted
# Native UI artwork: scalable controls, separate from the landscape illustration.
const COLORS := {"home": "#ffc52d", "bag": "#ffbc42", "dress": "#5fe4d1", "mastery": "#ffcf47", "profile": "#bdabff", "weekly": "#ff8caa", "casino": "#e499ff"}

static func accent(page: String) -> Color:
	return Color(COLORS.get(page, "#6cddff"))

static func icon(id: String) -> Texture2D:
	return load("res://assets/ui/adventure/%s.svg" % id)

static func box(color: Color, border: Color = Color("#a7dbf4"), radius: int = 18, pad: int = 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.01, 0.08, 0.2, 0.35)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 5)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s

static func text(value: String, font_size: int = 20, color: Color = Color("#173c61")) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

class Backdrop extends Control:
	var page := "home"
	var texture: Texture2D
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture = load("res://assets/ui/adventure/landscape.png")
		resized.connect(queue_redraw)
	func ball(c: Vector2, r: float, color: Color, width: float) -> void:
		draw_arc(c, r, 0, TAU, 64, color, width, true)
		draw_line(c - Vector2(r, 0), c + Vector2(r, 0), color, width, true)
		draw_circle(c, r * 0.3, Color("#165ea0"))
		draw_arc(c, r * 0.3, 0, TAU, 32, color, width * 0.75, true)
	func _draw() -> void:
		if texture != null:
			draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color("#056ec2"))
		if page != "home":
			var wash: Color = {"bag": Color(0.04, 0.14, 0.23, 0.38), "dress": Color(0.01, 0.2, 0.23, 0.32), "mastery": Color(0.14, 0.12, 0.3, 0.55), "profile": Color(0.14, 0.09, 0.34, 0.5), "weekly": Color(0.14, 0.05, 0.3, 0.57)}.get(page, Color(0.12, 0.04, 0.2, 0.55))
			draw_rect(Rect2(Vector2.ZERO, size), wash)
		draw_rect(Rect2(0, 0, size.x, 119), Color(0.01, 0.06, 0.24, 0.68))
		draw_line(Vector2(25, 117), Vector2(size.x - 25, 117), Color(0.5, 0.92, 1, 0.6), 2, true)
		ball(Vector2(size.x * 0.85, size.y * 0.37), 103, Color(0.75, 0.94, 1, 0.13), 24)
		var frame := Rect2(9, 9, size.x - 18, size.y - 18)
		draw_style_box(load("res://scripts/adventure_art.gd").box(Color.TRANSPARENT, Color("#d0f5ff"), 22, 0), frame)
		for c in [Vector2(18, 18), Vector2(size.x-18, 18), Vector2(18, size.y-18), size-Vector2(18,18)]:
			draw_circle(c, 15, Color("#09245c"))
			draw_circle(c, 10, Color("#e9faff"))
			draw_line(c-Vector2(11,0), c+Vector2(11,0), Color("#09245c"), 4, true)
			draw_circle(c, 4, Color("#09245c"))

class Tab extends Button:
	var active := false
	var symbol: Texture2D
	var caption := ""
	func _ready() -> void:
		custom_minimum_size = Vector2(110, 88)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		resized.connect(queue_redraw)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_top = 5
		v.offset_bottom = -6
		v.add_theme_constant_override("separation", 0)
		add_child(v)
		var tx := TextureRect.new()
		tx.texture = symbol
		tx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tx.custom_minimum_size = Vector2(36, 36)
		tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tx)
		var lb := Label.new()
		lb.text = caption
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_font_size_override("font_size", 16)
		lb.add_theme_color_override("font_color", Color.WHITE)
		lb.add_theme_color_override("font_outline_color", Color("#092442"))
		lb.add_theme_constant_override("outline_size", 5)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(lb)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
	func _draw() -> void:
		var inset := 11.0
		var poly := PackedVector2Array([Vector2(inset,0),Vector2(size.x-6,0),Vector2(size.x,10),Vector2(size.x-inset,size.y-5),Vector2(6,size.y-5),Vector2(0,size.y-15)])
		var shadow := poly.duplicate()
		for i in shadow.size():
			shadow[i] += Vector2(0,5)
		draw_colored_polygon(shadow, Color("#052755"))
		var col := Color("#f9b813") if active else Color("#075fae")
		if is_hovered() or has_focus():
			col = col.lightened(0.17)
		draw_colored_polygon(poly, col)
		var gloss := PackedVector2Array([Vector2(13,5),Vector2(size.x-8,5),Vector2(size.x-13,size.y*0.48),Vector2(5,size.y*0.48)])
		draw_colored_polygon(gloss, Color(1,1,1,0.12))
		poly.append(poly[0])
		draw_polyline(poly, Color("#fff3b1") if active else Color("#63ddff"), 3, true)

class Stage extends Control:
	var color := Color("#74ead9")
	func _ready() -> void:
		custom_minimum_size = Vector2(200, 175)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var c := size * Vector2(0.5, 0.61)
		draw_circle(c - Vector2(0,22), 75, Color(color, 0.14))
		draw_arc(c - Vector2(0,22), 73, 0, TAU, 64, Color(color, 0.4), 2, true)
		draw_set_transform(c+Vector2(0,52), 0, Vector2(1,0.2))
		draw_circle(Vector2.ZERO, 103, Color(color, 0.32))
		draw_arc(Vector2.ZERO, 103, 0, TAU, 64, Color(color,0.9), 3, true)
		draw_set_transform(Vector2.ZERO)
		for pos in [Vector2(0.18,0.25), Vector2(0.8,0.35), Vector2(0.75,0.1)]:
			var p: Vector2 = size * pos
			draw_line(p-Vector2(5,0),p+Vector2(5,0),color,2,true)
			draw_line(p-Vector2(0,5),p+Vector2(0,5),color,2,true)
