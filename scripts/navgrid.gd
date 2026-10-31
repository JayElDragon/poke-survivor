extends RefCounted
# Navegacion con mando por filas, igual en todos los menus: izquierda/derecha cicla dentro de la fila y
# arriba/abajo salta a la fila contigua recordando la columna (abajo y luego arriba vuelve al mismo control).

static var sticky_x := 0.0
static var sticky_for: Control = null


static func focusables(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode != Control.FOCUS_ALL or not c.is_visible_in_tree():
			continue
		if c is BaseButton and (c as BaseButton).disabled:
			continue
		if c is LineEdit:
			continue
		out.append(c)
	return out


# Devuelve true si movio el foco (y hay que tragarse el evento).
static func move(vp: Viewport, event: InputEvent, items: Array) -> bool:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_down", true):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_up", true):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_left", true):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right", true):
		dir = Vector2i(1, 0)
	else:
		return false
	var f: Control = vp.gui_get_focus_owner()
	if f == null or f is LineEdit:
		return false
	if dir.x != 0 and (f is Slider or f is OptionButton):
		return false   # el deslizador / selector usa izquierda-derecha para si mismo
	if items.size() < 2 or not items.has(f):
		return false
	items = items.duplicate()
	items.sort_custom(func(a: Control, b: Control) -> bool:
		var ac: Vector2 = a.get_global_rect().get_center()
		var bc: Vector2 = b.get_global_rect().get_center()
		if absf(ac.y - bc.y) > 1.0:
			return ac.y < bc.y
		return ac.x < bc.x)
	var rows: Array = []
	for c in items:
		var cc: Vector2 = (c as Control).get_global_rect().get_center()
		var placed := false
		if not rows.is_empty():
			var last: Array = rows[rows.size() - 1]
			var lc: Control = last[0]
			var tol: float = maxf(10.0, 0.45 * minf(lc.size.y, (c as Control).size.y))
			if absf(cc.y - lc.get_global_rect().get_center().y) <= tol:
				last.append(c)
				placed = true
		if not placed:
			rows.append([c])
	var ri := -1
	var ci := -1
	for i in range(rows.size()):
		var idx: int = (rows[i] as Array).find(f)
		if idx >= 0:
			ri = i
			ci = idx
			break
	if ri < 0:
		return false
	if sticky_for != f:
		sticky_x = f.get_global_rect().get_center().x
	var target: Control = null
	if dir.x != 0:
		var row: Array = rows[ri]
		# En el borde de la fila (o fila de un solo control) se salta a la zona vecina en esa direccion
		# (p. ej. de la rejilla de Pokemon al panel de la izquierda) en vez de dar la vuelta.
		var at_edge: bool = row.size() < 2 or (dir.x < 0 and ci == 0) or (dir.x > 0 and ci == row.size() - 1)
		if at_edge:
			target = _side_jump(f, items, row, dir.x)
		if target == null:
			if row.size() < 2:
				return false
			target = row[posmod(ci + dir.x, row.size())]
		sticky_x = target.get_global_rect().get_center().x
	else:
		var nr: int = ri + dir.y
		if nr < 0 or nr >= rows.size():
			return false
		var best := INF
		for c in rows[nr]:
			var dx: float = absf((c as Control).get_global_rect().get_center().x - sticky_x)
			if dx < best:
				best = dx
				target = c
	if target == null or target == f:
		return false
	target.grab_focus()
	sticky_for = target
	return true


# Control mas cercano (en vertical) que queda del todo a un lado de la fila actual; null si no hay.
static func _side_jump(f: Control, items: Array, row: Array, dx: int) -> Control:
	var fc: Vector2 = f.get_global_rect().get_center()
	var best: Control = null
	var best_d := INF
	for c in items:
		var cc := c as Control
		if row.has(cc) or cc == f:
			continue
		var cr: Vector2 = cc.get_global_rect().get_center()
		var side: float = (cr.x - fc.x) * float(dx)
		if side < 24.0:
			continue
		var d: float = absf(cr.y - fc.y) * 3.0 + side * 0.2
		if d < best_d:
			best_d = d
			best = cc
	return best
