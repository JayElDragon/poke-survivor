extends RefCounted
# Tamano del texto (Ajustes y pausa): Normal / Grande / Muy grande. Se aplica a los menus (Label, Button, LineEdit,
# RichTextLabel) guardando el tamano base de cada nodo, y al HUD de la partida con k().

const SV = preload("res://scripts/save_data.gd")
const K := [1.0, 1.15, 1.3]
const NAMES := ["Normal", "Grande", "Muy grande"]


static func idx() -> int:
	return clampi(int(SV.d["settings"].get("text_sz", 0)), 0, 2)


static func k() -> float:
	return float(K[idx()])


static func set_idx(i: int) -> void:
	SV.d["settings"]["text_sz"] = clampi(i, 0, 2)
	SV.save()


static func scale_node(n: Node) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	var key := ""
	if n is RichTextLabel:
		key = "normal_font_size"
	elif n is Label or n is Button or n is LineEdit:
		key = "font_size"
	else:
		return
	var c: Control = n
	if not c.has_meta("bfs"):
		c.set_meta("bfs", c.get_theme_font_size(key))
	c.add_theme_font_size_override(key, roundi(float(c.get_meta("bfs")) * k()))


static func scale_tree(root: Node) -> void:
	scale_node(root)
	for ch in root.get_children():
		scale_tree(ch)


# Escala tambien los nodos que se crean despues (pantallas que se reconstruyen).
# 7.0: se desengancha al salir la escena; antes quedaba conectado para siempre (una conexion mas en cada
# visita al menu) y, ya borrado el menu, cada nodo nuevo de la partida daba "Lambda capture ... was freed".
static func hook(root: Node) -> void:
	var tree: SceneTree = root.get_tree()
	var cb := func(n: Node):
		if is_instance_valid(root) and k() > 1.0 and root.is_ancestor_of(n):
			scale_node.call_deferred(n)
	tree.node_added.connect(cb)
	root.tree_exiting.connect(func():
		if tree.node_added.is_connected(cb):
			tree.node_added.disconnect(cb), CONNECT_ONE_SHOT)
