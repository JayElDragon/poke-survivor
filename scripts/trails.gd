extends Node2D
const VFX = preload("res://scripts/vfx.gd")
const CT = preload("res://scripts/content.gd")
var m
var parts: Array = []

func add(id: String, point: Vector2, velocity: Vector2) -> void:
	var td: Dictionary = CT.trails().get(id, {})
	if td.is_empty() or parts.size() >= 120:
		return
	var colors: Array = td.get("c", ["#ffffff"])
	parts.append({"p": point, "v": velocity * 0.08 + Vector2(randf_range(-10, 10), -18), "life": 0.8, "t": 0.0, "shape": String(td["s"]), "color": Color(String(colors[randi() % colors.size()])), "angle": randf() * TAU})

func _process(dt: float) -> void:
	if m == null or m.paused or m.choosing:
		return
	for i in range(parts.size() - 1, -1, -1):
		var p: Dictionary = parts[i]
		p["t"] = float(p["t"]) + dt
		p["p"] += (p["v"] as Vector2) * dt
		p["angle"] = float(p["angle"]) + dt
		if float(p["t"]) >= float(p["life"]):
			parts.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in parts:
		var color: Color = p["color"]
		color.a = 1.0 - float(p["t"]) / float(p["life"])
		var pos: Vector2 = p["p"]
		var shape: String = p["shape"]
		draw_set_transform(pos, float(p["angle"]), Vector2.ONE)
		match shape:
			"rocket", "code", "zzz":
				draw_string(ThemeDB.fallback_font, Vector2(-6, 0), {"rocket": "R", "code": "01", "zzz": "z"}[shape], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
			"rainbow", "aurora":
				for i in range(5):
					draw_arc(Vector2.ZERO, 5.0 + i * 1.5, 0, PI, 12, Color.from_hsv(float(i) / 5.0, 0.8, 1.0, color.a), 2)
			"moon", "gold", "psy", "puddle", "wind":
				draw_arc(Vector2.ZERO, 7, 0, TAU * (0.65 if shape == "moon" else 1.0), 16, color, 2)
			"gem", "tera", "sword", "arrow", "bolt", "rock":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -10), Vector2(5, 0), Vector2(0, 10), Vector2(-5, 0)]), color)
			"crown":
				draw_colored_polygon(PackedVector2Array([Vector2(-8, -5), Vector2(-3, -1), Vector2(0, -9), Vector2(3, -1), Vector2(8, -5), Vector2(6, 5), Vector2(-6, 5)]), color)
			"paw":
				draw_circle(Vector2(0, 3), 4, color)
				for i in range(3):
					draw_circle(Vector2(-5 + i * 5, -4), 2, color)
			"dice", "gift", "pixel":
				draw_rect(Rect2(-6, -6, 12, 12), color)
				draw_circle(Vector2.ZERO, 1, Color.WHITE * color.a)
			_:
				var alias: String = {"ghost": "mistorb", "rain": "seed", "snow": "flake", "ember": "fire", "flame": "fire", "smoke": "mistorb", "magma": "lava", "spark": "plus", "frost": "flake", "petal": "leaf", "miasma": "blob", "metal": "plus", "comet": "star", "cell": "bubble"}.get(shape, shape)
				if VFX.META.has(alias) or VFX.V2.META.has(alias):
					var tex: Texture2D = VFX.sprite(alias, "normal", int(float(p["t"]) * 8.0))
					draw_texture_rect(tex, Rect2(-8, -8, 16, 16), false, color)
				else:
					draw_circle(Vector2.ZERO, 5, color)
					draw_line(Vector2(-7, 0), Vector2(7, 0), color, 2)
		draw_set_transform(Vector2.ZERO)
