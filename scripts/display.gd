extends RefCounted
# Tamano de pantalla (zoom de la vista) y boton "atras" de Android.

const SV = preload("res://scripts/save_data.gd")
const MIN_PCT := 60
const MAX_PCT := 140


static func pct() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("view", 100)), MIN_PCT, MAX_PCT)


# En el menu la vista siempre es 100% (esta disenado para 1280x720): el zoom de "Tamano de pantalla" solo afecta a la partida.
static var menu_mode := false


static func apply(tree: SceneTree) -> void:
	SV.ensure()
	# Migracion unica: valores de zoom guardados antes (a veces por error con el mando) recortaban la pantalla.
	if int(SV.d["settings"].get("view_v", 0)) < 2:
		SV.d["settings"]["view_v"] = 2
		SV.d["settings"]["view"] = 100
		SV.save()
	tree.root.content_scale_factor = 1.0 if menu_mode else float(pct()) / 100.0
	# El boton atras de Android lo gestiona el juego (no cierra la app).
	tree.quit_on_go_back = false


static func set_pct(tree: SceneTree, v: int) -> void:
	SV.ensure()
	SV.d["settings"]["view"] = clampi(v, MIN_PCT, MAX_PCT)
	SV.save()
	apply(tree)


static func info(tree: SceneTree) -> String:
	var win: Vector2i = DisplayServer.window_get_size()
	var vp: Vector2 = tree.root.get_visible_rect().size
	return "%d×%d  →  %d×%d" % [win.x, win.y, int(vp.x), int(vp.y)]


# Margenes seguros (notch, esquinas redondeadas, barra de gestos) en unidades de la vista:
# x = izquierda, y = arriba, z = derecha, w = abajo. En escritorio/ventana valen 0.
static var force := Vector4.ZERO   # solo para pruebas


static func insets(tree: SceneTree) -> Vector4:
	if force != Vector4.ZERO:
		return force
	var win: Vector2i = DisplayServer.window_get_size()
	var scr: Vector2i = DisplayServer.screen_get_size()
	if win.x <= 0 or win.y <= 0 or absi(win.x - scr.x) > 8 or absi(win.y - scr.y) > 8:
		return Vector4.ZERO
	var sa: Rect2i = DisplayServer.get_display_safe_area()
	if sa.size.x <= 0 or sa.size.y <= 0:
		return Vector4.ZERO
	var vp: Vector2 = tree.root.get_visible_rect().size
	var k: float = vp.x / float(win.x)
	var l: float = clampf(float(sa.position.x) * k, 0.0, 120.0)
	var t: float = clampf(float(sa.position.y) * k, 0.0, 80.0)
	var r: float = clampf(float(scr.x - sa.end.x) * k, 0.0, 120.0)
	var b: float = clampf(float(scr.y - sa.end.y) * k, 0.0, 60.0)
	return Vector4(l, t, r, b)


# ---------------------------------------------------------------
# Ventana en PC (v5.2.1): modo (ventana / pantalla completa) y resolucion de la ventana.
# ---------------------------------------------------------------
const WIN_RES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]


static func is_desktop() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("android")


static func win_mode() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("win_mode", 0)), 0, 1)


static func win_res() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("win_res", 0)), 0, WIN_RES.size() - 1)


static func apply_window() -> void:
	if not is_desktop():
		return
	if win_mode() == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var want: Vector2i = WIN_RES[win_res()]
	var scr: Rect2i = DisplayServer.screen_get_usable_rect()
	# Si la resolucion no cabe en la pantalla, se ajusta para que la ventana no se salga
	var sz := Vector2i(mini(want.x, scr.size.x), mini(want.y, scr.size.y))
	DisplayServer.window_set_size(sz)
	DisplayServer.window_set_position(scr.position + (scr.size - sz) / 2)


static func set_window(mode: int, res: int) -> void:
	SV.ensure()
	SV.d["settings"]["win_mode"] = clampi(mode, 0, 1)
	SV.d["settings"]["win_res"] = clampi(res, 0, WIN_RES.size() - 1)
	SV.save()
	apply_window()
