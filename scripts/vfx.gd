extends RefCounted
# Sprites pixel art de los ataques: port exacto de js/entities/vfx.js del original.
# Las formas se generan por codigo (letras o d m l w, L = claro semitransparente)
# y se colorean con la paleta del tipo.

const PX := 2.0
const V2 := preload("res://scripts/vfx2.gd")

const PAL := {
	"fire": ["#6b1200", "#b8300a", "#ff6a1f", "#ffb22e", "#fff2a0"],
	"water": ["#0f2f78", "#1f56c4", "#3d8bff", "#8ccaff", "#eaf7ff"],
	"grass": ["#14400f", "#24721e", "#45b23c", "#97e36c", "#eaffd0"],
	"electric": ["#6b4300", "#c48a00", "#ffd21a", "#fff36a", "#ffffff"],
	"psychic": ["#5e0a3a", "#b0246e", "#ff4f9a", "#ff9fcf", "#ffe8f3"],
	"ice": ["#134a60", "#2f8aa8", "#62d2ea", "#bff3ff", "#ffffff"],
	"fighting": ["#561208", "#9a2a16", "#e04a2e", "#ff9c6c", "#ffe2cc"],
	"poison": ["#2e0a3c", "#5e1f7e", "#a043d0", "#d995f2", "#f7e2ff"],
	"ground": ["#3a250c", "#6e4c1e", "#aa7c3c", "#dcb66c", "#f6e6b8"],
	"flying": ["#283c66", "#5672b0", "#93b2ff", "#d2e2ff", "#ffffff"],
	"bug": ["#2e3a06", "#5b7414", "#90b82a", "#cbe86c", "#f4ffd2"],
	"rock": ["#2e2418", "#5a4a34", "#8e7a5a", "#c6b08a", "#f0e4c6"],
	"ghost": ["#160e2c", "#33256a", "#5c48aa", "#9e8aea", "#e8deff"],
	"dragon": ["#160a50", "#2e1ea0", "#5a3cff", "#a490ff", "#e8e2ff"],
	"dark": ["#0e0a0c", "#2a2026", "#463840", "#7c6a74", "#d4c4cc"],
	"steel": ["#232d38", "#56667a", "#8c9caf", "#cad6e2", "#ffffff"],
	"fairy": ["#6a2050", "#b04a8a", "#ff8acb", "#ffc4e6", "#ffffff"],
	"normal": ["#3e3834", "#7a7068", "#c4bcb0", "#ece6dc", "#ffffff"],
	"aura": ["#0c2460", "#1c4cb0", "#3a7cff", "#90d2ff", "#ffffff"],
}
const IDX := {"o": 0, "d": 1, "m": 2, "l": 3, "w": 4}

# w, h, frames, dir, spin
const META := {
	"fire": [15, 11, 3, true, false], "drop": [13, 9, 1, true, false], "bubble": [11, 11, 2, false, false],
	"leaf": [12, 7, 1, false, true], "bolt": [15, 10, 2, true, false], "shard": [13, 7, 1, true, false],
	"rock": [12, 11, 3, false, true], "blob": [12, 11, 2, false, false], "needle": [13, 5, 1, true, false],
	"star": [11, 11, 2, false, true], "streak": [15, 5, 1, true, false], "wind": [13, 11, 2, false, true],
	"web": [11, 11, 1, false, true], "ring": [13, 13, 2, false, false], "crescent": [12, 11, 1, true, false],
	"note": [11, 11, 1, true, false], "impact": [15, 15, 2, false, false], "claw": [13, 13, 1, false, false],
	"jaws": [13, 11, 2, false, false], "arrow": [7, 9, 1, false, false], "ball": [11, 11, 2, false, false],
	"shadow": [13, 13, 3, false, false], "heart": [9, 8, 1, false, false],
}

const MOVE := {
	"quick-attack": {"proj": "streak"},
	"ember": {"proj": "fire", "trail": "ember"}, "heat-wave": {"proj": "fire", "trail": "ember"},
	"fire-spin": {"proj": "fire", "trail": "ember"},
	"flamethrower": {"proj": "fire", "trail": "ember", "beam": "fire"},
	"water-gun": {"proj": "drop", "trail": "drip"}, "bubble": {"proj": "bubble"},
	"hydro-pump": {"beam": "drop"}, "aqua-ring": {"buff": "bubble"},
	"vine-whip": {"melee": "vine"},
	"razor-leaf": {"proj": "leaf"}, "leaf-storm": {"proj": "leaf"},
	"giga-drain": {"aura": "heart", "inward": true},
	"thunder-shock": {"proj": "bolt", "trail": "spark"},
	"discharge": {"aura": "bolt"}, "thunderbolt": {"beam": "lightning"},
	"confusion": {"proj": "ring"}, "hypnosis": {"aura": "ring"}, "dream-eater": {"aura": "heart", "inward": true}, "psybeam": {"beam": "ring"}, "psychic": {"proj": "ring"},
	"sludge": {"proj": "blob", "trail": "bubbles"}, "poison-sting": {"proj": "needle"},
	"toxic": {"aura": "bubble", "rise": true}, "mud-shot": {"proj": "blob", "trail": "dirt"},
	"bulldoze": {"aura": "rock", "rise": true},
	"gust": {"proj": "wind"}, "wing-attack": {"melee": "feather"},
	"tackle": {"melee": "impact"}, "body-slam": {"melee": "impact"},
	"hyper-voice": {"proj": "note"}, "bug-bite": {"melee": "jaws"},
	"string-shot": {"proj": "web"}, "bug-buzz": {"aura": "note"},
	"rock-throw": {"proj": "rock", "trail": "dirt"}, "rock-slide": {"proj": "rock", "trail": "dirt"},
	"ice-beam": {"beam": "shard"}, "powder-snow": {"aura": "star"},
	"karate-chop": {"melee": "impact"},
	"aura-sphere": {"proj": "ball", "pal": "aura", "trail": "spark"},
	"lick": {"melee": "impact"},
	"shadow-ball": {"proj": "shadow", "trail": "wisp"},
	"dragon-rage": {"beam": "fire"}, "dragon-dance": {"buff": "arrow"},
	"fairy-wind": {"proj": "star"}, "dazzling-gleam": {"aura": "star"},
	"metal-claw": {"melee": "claw"}, "flash-cannon": {"beam": "shard"}, "bite": {"melee": "jaws"},
	"dark-pulse": {"proj": "crescent"}, "night-shade": {"aura": "shadow", "rise": true},
	"swords-dance": {"buff": "arrow", "pal": "fighting"}, "agility": {"buff": "arrow", "pal": "flying"},
	"harden": {"buff": "arrow", "pal": "steel"},
	"bonemerang": {"proj": "crescent"}, "psycho-cut": {"proj": "crescent"},
	"spikes": {"proj": "star"}, "toxic-spikes": {"proj": "star"}, "hail": {"proj": "shard"},
	"meteor-mash": {"proj": "rock", "trail": "spark"}, "will-o-wisp": {"proj": "ball", "trail": "ember"},
	"substitute": {"proj": "star"}, "aerial-ace": {"proj": "wind"},
	"flame-wheel": {"proj": "fire", "aura": "fire"}, "bubble-beam": {"proj": "bubble"},
	"hex": {"beam": "shadow", "proj": "shadow"},
}
const TYPE_SHAPE := {
	"fire": "fire", "water": "drop", "grass": "leaf", "electric": "bolt", "psychic": "ring", "ice": "shard",
	"fighting": "ball", "poison": "blob", "ground": "blob", "flying": "wind", "bug": "needle", "rock": "rock",
	"ghost": "shadow", "dragon": "fire", "dark": "crescent", "steel": "shard", "fairy": "star", "normal": "star",
}

static var cache := {}


static func for_move(id: String, type: String) -> Dictionary:
	var v: Dictionary = MOVE.get(id, {})
	if V2.MOVE.has(id):
		v = V2.MOVE[id]
	var out: Dictionary = {"proj": String(TYPE_SHAPE.get(type, "ball")), "pal": type}
	for k in v:
		out[k] = v[k]
	return out


static func for_type(type: String) -> Dictionary:
	return {"proj": String(TYPE_SHAPE.get(type, "ball")), "pal": type if PAL.has(type) else "normal"}


static func is_dir(shape: String) -> bool:
	if V2.META.has(shape):
		return bool(V2.META[shape][3])
	return META.has(shape) and bool(META[shape][3])


static func spins(shape: String) -> bool:
	if V2.META.has(shape):
		return bool(V2.META[shape][4])
	return META.has(shape) and bool(META[shape][4])


static func hh(a: int, b: int, c: int) -> float:
	var h: int = ((a * 374761393) & 0xFFFFFFFF) ^ ((b * 668265263) & 0xFFFFFFFF) ^ ((c * 2246822519) & 0xFFFFFFFF)
	h = (((h ^ (h >> 13)) & 0xFFFFFFFF) * 1274126177) & 0xFFFFFFFF
	h ^= h >> 16
	return float(h & 0xFFFFFFFF) / 4294967296.0


class Grid:
	var w := 0
	var h := 0
	var g: Array = []

	func _init(ww: int, hh_: int) -> void:
		w = ww
		h = hh_
		for y in range(h):
			var row: Array = []
			row.resize(w)
			row.fill("")
			g.append(row)

	static func rnd(v: float) -> int:
		return int(floorf(v + 0.5))

	func set_px(x: float, y: float, c: String) -> void:
		var xi: int = rnd(x)
		var yi: int = rnd(y)
		if xi >= 0 and yi >= 0 and xi < w and yi < h:
			g[yi][xi] = c

	func get_px(x: int, y: int) -> String:
		if x >= 0 and y >= 0 and x < w and y < h:
			return String(g[y][x])
		return ""

	func outline() -> void:
		var marks: Array = []
		for y in range(h):
			for x in range(w):
				if String(g[y][x]) != "":
					continue
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var c: String = get_px(x + int(d[0]), y + int(d[1]))
					if c != "" and c != "o":
						marks.append([x, y])
						break
		for m in marks:
			g[int(m[1])][int(m[0])] = "o"

	func line(x0: float, y0: float, x1: float, y1: float, c: String, thick: bool = false, side: String = "") -> void:
		var n: int = int(ceil(Vector2(x1 - x0, y1 - y0).length() * 2.0)) + 1
		for i in range(n + 1):
			var x: float = x0 + (x1 - x0) * float(i) / float(n)
			var y: float = y0 + (y1 - y0) * float(i) / float(n)
			if thick:
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					if get_px(rnd(x + float(d[0])), rnd(y + float(d[1]))) == "":
						set_px(x + float(d[0]), y + float(d[1]), side if side != "" else c)
			set_px(x, y, c)

	func arc(cx: float, cy: float, r: float, a0: float, a1: float, c: String) -> void:
		var n: int = int(ceil(r * absf(a1 - a0) * 2.0)) + 2
		for i in range(n + 1):
			var a: float = a0 + (a1 - a0) * float(i) / float(n)
			set_px(cx + cos(a) * r, cy + sin(a) * r, c)


static func _gen(shape: String, P: Grid, f: int) -> void:
	match shape:
		"fire":
			var cx := 10.5
			var cy := 5.0
			for x in range(1, 10):
				var t: float = float(x - 1) / 8.0
				var th: float = 0.5 + t * 2.6 + (hh(x, f, 3) - 0.5) * 1.3
				var yc: float = cy + sin(float(x) * 1.4 + float(f) * 2.1) * 0.8 * (1.0 - t)
				for y in range(P.h):
					var d: float = absf(float(y) - yc)
					if d > th or (t < 0.3 and hh(x, y + f * 7, 5) < 0.4):
						continue
					P.set_px(x, y, "l" if (d < th * 0.4 and t > 0.3) else "m")
			for y in range(P.h):
				for x in range(P.w):
					var d2: float = Vector2(float(x) - cx, (float(y) - cy) * 1.1).length()
					if d2 < 1.3:
						P.g[y][x] = "w"
					elif d2 < 2.4:
						P.g[y][x] = "l"
					elif d2 < 3.5:
						P.g[y][x] = "m"
			P.outline()
		"drop":
			for x in range(2, 8):
				var th2: float = float(x - 2) / 5.0 * 2.6
				for y in range(P.h):
					var d3: float = absf(float(y) - 4.0)
					if d3 <= th2:
						P.set_px(x, y, "l" if d3 < th2 * 0.5 else "m")
			for y in range(P.h):
				for x in range(P.w):
					var d4: float = Vector2(float(x) - 8.5, float(y) - 4.0).length()
					if d4 < 1.6:
						P.g[y][x] = "l"
					elif d4 < 3.3:
						P.g[y][x] = "m"
			P.set_px(9, 2, "w")
			P.set_px(10, 3, "w")
			P.outline()
		"bubble":
			var rx: float = 4.3 + float(f) * 0.3
			var ry: float = 4.3 - float(f) * 0.3
			for y in range(P.h):
				for x in range(P.w):
					var e: float = Vector2((float(x) - 5.0) / rx, (float(y) - 5.0) / ry).length()
					if e <= 1.0:
						P.g[y][x] = "m" if e > 0.76 else "L"
			P.set_px(3, 3, "w")
			P.set_px(4, 3, "w")
			P.set_px(3, 4, "w")
			P.set_px(7, 7, "l")
			P.outline()
		"leaf":
			for y in range(P.h):
				for x in range(P.w):
					var dx: float = absf(float(x) - 5.5) / 5.6
					var dy: float = (float(y) - 3.0) / 2.7
					if dx + dy * dy <= 1.0:
						P.g[y][x] = "l" if y < 3 else "m"
			for x in range(2, 10):
				P.set_px(x, 3, "d")
			P.set_px(4, 2, "w")
			P.outline()
		"bolt":
			var pts: Array = [[0, 3], [4, 7], [7, 2], [10, 7], [14, 4]] if f == 1 else [[0, 6], [4, 2], [7, 7], [10, 2], [14, 5]]
			for i in range(pts.size() - 1):
				P.line(float(pts[i][0]), float(pts[i][1]), float(pts[i + 1][0]), float(pts[i + 1][1]), "w", true, "l")
			P.outline()
		"shard":
			for y in range(P.h):
				for x in range(P.w):
					if absf(float(x) - 6.0) / 6.2 + absf(float(y) - 3.0) / 3.4 <= 1.0:
						P.g[y][x] = "l" if y < 3 else "m"
			for x in range(6, 12):
				P.set_px(x, 3, "w")
			P.set_px(4, 2, "w")
			P.outline()
		"rock":
			var r: Array = []
			for i in range(7):
				r.append(3.6 + hh(i, f, 9) * 1.4)
			for y in range(P.h):
				for x in range(P.w):
					var dx2: float = float(x) - 5.5
					var dy2: float = float(y) - 5.0
					var a: float = (atan2(dy2, dx2) + PI) / TAU * 6.0
					var i2: int = int(floorf(a))
					var t2: float = a - float(i2)
					var R: float = float(r[i2]) * (1.0 - t2) + float(r[(i2 + 1) % 6]) * t2
					var d5: float = Vector2(dx2, dy2).length()
					if d5 > R:
						continue
					var lit: float = (-dx2 * 0.6 - dy2 * 0.8) / R
					P.g[y][x] = "l" if lit > 0.35 else ("m" if lit > -0.3 else "d")
			P.set_px(6, 5, "d")
			P.set_px(7, 6, "d")
			P.set_px(4, 3, "w")
			P.outline()
		"blob":
			for y in range(P.h):
				for x in range(P.w):
					var dx3: float = float(x) - 5.5
					var dy3: float = float(y) - 4.8
					var a3: float = atan2(dy3, dx3)
					var R3: float = 3.9 + sin(a3 * 3.0 + float(f) * 2.0) * 0.5
					var d6: float = Vector2(dx3, dy3).length()
					if d6 > R3:
						continue
					var lit3: float = (-dx3 * 0.6 - dy3 * 0.8) / R3
					P.g[y][x] = "l" if lit3 > 0.4 else ("m" if lit3 > -0.35 else "d")
			P.set_px(4, 3, "w")
			P.set_px(3, 3, "w")
			P.set_px(6, 9, "m")
			if f == 1:
				P.set_px(6, 10, "m")
			P.outline()
		"needle":
			for x in range(1, 10):
				P.set_px(x, 2, "m")
			for x in range(3, 9):
				P.set_px(x, 1, "l")
			P.set_px(10, 2, "w")
			P.set_px(11, 2, "w")
			P.set_px(1, 1, "d")
			P.set_px(1, 3, "d")
			P.outline()
		"star":
			var L: int = 3 if f == 1 else 4
			for i in range(-L, L + 1):
				P.set_px(5 + i, 5, "m" if absi(i) == L else "l")
				P.set_px(5, 5 + i, "m" if absi(i) == L else "l")
			var D: int = 2 if f == 1 else 1
			for i in range(1, D + 1):
				for ab in [[1, 1], [-1, 1], [1, -1], [-1, -1]]:
					P.set_px(5 + int(ab[0]) * i, 5 + int(ab[1]) * i, "l")
			for p in [[5, 5], [4, 5], [6, 5], [5, 4], [5, 6]]:
				P.set_px(int(p[0]), int(p[1]), "w")
		"streak":
			for x in range(15):
				P.set_px(x, 2, "d" if x < 4 else ("m" if x < 8 else ("l" if x < 12 else "w")))
			for x in range(7, 13):
				P.set_px(x, 1, "l")
				P.set_px(x, 3, "m")
			P.set_px(13, 1, "w")
			P.set_px(13, 3, "w")
		"wind":
			P.arc(6, 5, 4.6, -0.6 + float(f) * 0.7, 2.9 + float(f) * 0.7, "l")
			P.arc(6, 5, 3.6, -0.3 + float(f) * 0.7, 2.2 + float(f) * 0.7, "w")
			P.arc(6, 5, 2.2, 1.8 + float(f), 4.6 + float(f), "l")
		"web":
			for k in range(8):
				var a4: float = float(k) * PI / 4.0
				P.line(5, 5, 5.0 + cos(a4) * 5.0, 5.0 + sin(a4) * 5.0, "l")
			for rr in [2.4, 4.4]:
				for k in range(8):
					var a0: float = float(k) * PI / 4.0
					var a1: float = float(k + 1) * PI / 4.0
					P.line(5.0 + cos(a0) * rr, 5.0 + sin(a0) * rr, 5.0 + cos(a1) * rr, 5.0 + sin(a1) * rr, "w")
		"ring":
			for y in range(P.h):
				for x in range(P.w):
					var d7: float = Vector2(float(x) - 6.0, float(y) - 6.0).length()
					if absf(d7 - (5.0 + float(f) * 0.6)) < 0.75:
						P.g[y][x] = "m"
					elif absf(d7 - (3.0 + float(f) * 0.5)) < 0.7:
						P.g[y][x] = "l"
			P.set_px(6, 6, "w")
		"crescent":
			for y in range(P.h):
				for x in range(P.w):
					var aa: float = Vector2(float(x) - 6.5, float(y) - 5.0).length()
					var bb: float = Vector2(float(x) - 3.8, float(y) - 5.0).length()
					if aa > 4.8 or bb < 4.2:
						continue
					P.g[y][x] = "l" if bb < 5.1 else "m"
			P.outline()
		"note":
			P.arc(1, 5, 2.2, -0.7, 0.7, "w")
			P.arc(1, 5, 4.6, -0.6, 0.6, "l")
			P.arc(1, 5, 7.2, -0.5, 0.5, "m")
		"impact":
			for k in range(8):
				var a5: float = float(k) * PI / 4.0 + (PI / 8.0 if f == 1 else 0.0)
				var Ln: float = (3.5 if k % 2 == 1 else 6.0) * (1.0 if f == 1 else 0.75)
				P.line(7, 7, 7.0 + cos(a5) * Ln, 7.0 + sin(a5) * Ln, "l")
				P.set_px(7.0 + cos(a5) * Ln, 7.0 + sin(a5) * Ln, "m")
			for y in range(P.h):
				for x in range(P.w):
					if Vector2(float(x) - 7.0, float(y) - 7.0).length() < 1.8:
						P.g[y][x] = "w"
		"claw":
			for i in range(3):
				P.line(1.0 + float(i) * 3.5, 11, 6.0 + float(i) * 3.5, 1, "w", true, "l")
			P.outline()
		"jaws":
			var gap: bool = f == 0
			for x in range(1, 12):
				P.set_px(x, 1, "m")
				P.set_px(x, 9, "m")
			for t3 in range(4):
				var x2: int = 2 + t3 * 3
				P.set_px(x2, 2, "w")
				P.set_px(x2 + 1, 2, "w")
				P.set_px(x2, 3, "w")
				P.set_px(x2 + 1, 3, "l")
				if not gap:
					P.set_px(x2, 4, "w")
				P.set_px(x2 + 1, 8, "w")
				P.set_px(x2 + 2, 8, "w")
				P.set_px(x2 + 1, 7, "w")
				P.set_px(x2 + 2, 7, "l")
				if not gap:
					P.set_px(x2 + 1, 6, "w")
			P.outline()
		"arrow":
			for y in range(4):
				for x in range(3 - y, 3 + y + 1):
					P.set_px(x, y, "w" if x == 3 - y else "l")
			for y in range(4, 9):
				for x in range(2, 5):
					P.set_px(x, y, "w" if x == 2 else "m")
			P.outline()
		"ball":
			for y in range(P.h):
				for x in range(P.w):
					var d8: float = Vector2(float(x) - 5.0, float(y) - 5.0).length()
					if d8 < 1.5:
						P.g[y][x] = "w"
					elif d8 < 2.9:
						P.g[y][x] = "l"
					elif d8 < 4.2 + float(f) * 0.3:
						P.g[y][x] = "m"
			P.set_px(3, 3, "w")
			P.outline()
		"shadow":
			for y in range(P.h):
				for x in range(P.w):
					var d9: float = Vector2(float(x) - 6.0, float(y) - 6.0).length()
					if d9 < 1.6:
						P.g[y][x] = "l"
					elif d9 < 3.0:
						P.g[y][x] = "m"
					elif d9 < 4.4:
						P.g[y][x] = "d"
			for k in range(6):
				var a6: float = float(k) * 1.05 + float(f) * 0.7
				var r6: float = 4.8 + hh(k, f, 4) * 1.4
				P.set_px(6.0 + cos(a6) * r6, 6.0 + sin(a6) * r6, "m")
			P.set_px(5, 5, "w")
			P.outline()
		"heart":
			var rows: Array = [".ll...ll.", "lwll.llll", "lllllllll", "lllllllll", ".lllllll.", "..lllll..", "...lll...", "....l...."]
			for y in range(rows.size()):
				var row: String = rows[y]
				for x in range(row.length()):
					var ch: String = row[x]
					if ch != ".":
						P.set_px(x, y, "w" if ch == "w" else "l")
			P.outline()


static func sprite(shape: String, pal: String, frame: int) -> Texture2D:
	if not META.has(shape) and not V2.META.has(shape):
		shape = "ball"
	var m: Array = V2.META[shape] if V2.META.has(shape) else META[shape]
	var f: int = frame % int(m[2])
	var k: String = "%s|%s|%d" % [shape, pal, f]
	if cache.has(k):
		return cache[k]
	var P := Grid.new(int(m[0]), int(m[1]))
	if V2.META.has(shape):
		V2.gen(shape, P, f)
	else:
		_gen(shape, P, f)
	var img := Image.create(P.w, P.h, false, Image.FORMAT_RGBA8)
	var colors: Array = PAL.get(pal, PAL["normal"])
	for y in range(P.h):
		for x in range(P.w):
			var ch: String = String(P.g[y][x])
			if ch == "":
				continue
			var c: Color
			if ch == "L":
				c = Color.html(String(colors[3]))
				c.a = 0.5
			else:
				c = Color.html(String(colors[int(IDX[ch])]))
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	cache[k] = tex
	return tex


# Dibuja centrado en pos. angle=0 si no es direccional.
static func draw(ci: CanvasItem, shape: String, pal: String, pos: Vector2, angle: float, scl: float, frame: int, alpha: float, snap_ang: bool = true) -> void:
	var tex: Texture2D = sprite(shape, pal, frame)
	var k: float = PX * scl
	var a: float = angle
	if a != 0.0 and snap_ang:
		a = roundf(a / (PI / 8.0)) * (PI / 8.0)
	ci.draw_set_transform(pos, a, Vector2(k, k))
	ci.draw_texture(tex, -tex.get_size() / 2.0, Color(1, 1, 1, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func pc(pal: String, i: int) -> Color:
	var cols: Array = PAL.get(pal, PAL["normal"])
	return Color.html(String(cols[i]))
