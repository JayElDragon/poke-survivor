extends RefCounted
# Sprites propios de los movimientos nuevos (v5.0). Cada forma es unica: no reutiliza las del juego base.
# w, h, frames, dir, spin
const META := {
	"orbelec": [13, 13, 2, false, true], "mesh": [11, 11, 2, false, true], "drill": [15, 9, 2, true, false],
	"beak": [13, 9, 2, true, false], "cannon": [15, 15, 2, false, false], "dart": [11, 5, 1, true, false],
	"chevron": [15, 11, 3, true, false], "rune": [11, 11, 2, false, true], "axeslash": [15, 13, 1, true, false],
	"blade": [15, 5, 1, true, false], "airx": [13, 13, 2, false, true], "pyre": [11, 13, 3, false, false],
	"bone": [13, 5, 1, false, true], "seed": [9, 9, 2, false, false], "sun": [13, 13, 2, false, true],
	"bomb": [13, 13, 2, false, false], "xmark": [11, 11, 1, false, true], "grain": [9, 9, 2, false, false],
	"iceball": [11, 11, 2, false, true], "icicle": [15, 5, 1, true, false], "flake": [13, 13, 1, false, true],
	"coin": [9, 9, 2, false, false], "mistorb": [11, 11, 2, false, false], "twinring": [13, 13, 2, false, true],
	"pillar": [9, 13, 1, false, false], "rockspike": [11, 11, 1, false, true], "anchor": [11, 13, 1, false, true],
	"swirl": [13, 13, 3, false, true], "ink": [11, 11, 2, false, false], "pincer": [13, 13, 2, false, false],
	"fist": [11, 11, 2, false, false], "hammer": [13, 13, 1, false, true], "feather": [9, 13, 1, false, false],
	"plus": [9, 9, 2, false, false], "fang": [9, 13, 1, false, false], "slashx": [13, 13, 2, false, false],
	"ember2": [9, 9, 2, false, false], "kick": [13, 13, 2, false, false], "lava": [11, 11, 2, false, false],
	"chop": [13, 11, 1, false, false],
}

const MOVE := {
	"electro-ball": {"proj": "orbelec", "trail": "spark"}, "electroweb": {"proj": "mesh"},
	"bolt-beak": {"proj": "beak", "trail": "spark"}, "zap-cannon": {"beam": "cannon", "proj": "cannon"},
	"thunder-wave": {"proj": "twinring"},
	"dragon-darts": {"proj": "dart"}, "dragon-breath": {"proj": "chevron"}, "dragon-energy": {"proj": "rune"},
	"outrage": {"aura": "rune", "rise": true},
	"fleur-cannon": {"beam": "cannon", "proj": "cannon"}, "play-rough": {"melee": "slashx"},
	"axe-kick": {"melee": "kick", "proj": "axeslash"}, "high-jump-kick": {"proj": "kick"},
	"hammer-arm": {"melee": "fist"}, "sacred-sword": {"melee": "slashx", "proj": "blade"},
	"blaze-kick": {"proj": "kick", "trail": "ember"},
	"eruption": {"proj": "lava", "trail": "ember"}, "fire-lash": {"melee": "slashx"},
	"magma-storm": {"aura": "lava", "rise": true},
	"mystical-fire": {"proj": "pyre", "trail": "wisp"},
	"air-cutter": {"proj": "airx"}, "air-slash": {"proj": "airx"}, "roost": {"buff": "feather"},
	"infernal-parade": {"proj": "pyre", "trail": "ember"}, "shadow-bone": {"proj": "bone"},
	"leech-seed": {"proj": "seed"}, "solar-beam": {"beam": "sun", "proj": "sun"},
	"sludge-bomb": {"proj": "bomb", "trail": "bubbles"}, "cross-poison": {"melee": "xmark"},
	"poison-jab": {"proj": "fang"}, "sludge-wave": {"proj": "bomb"},
	"drill-run": {"proj": "drill", "trail": "dirt"}, "scorching-sands": {"proj": "grain", "trail": "ember"},
	"magnitude": {"aura": "grain", "rise": true},
	"aurora-beam": {"beam": "flake", "proj": "flake"}, "freeze-dry": {"proj": "flake"},
	"ice-ball": {"proj": "iceball"}, "ice-burn": {"aura": "flake", "rise": true},
	"ice-hammer": {"melee": "hammer"}, "icicle-spear": {"proj": "icicle"},
	"egg-bomb": {"proj": "bomb"}, "milk-drink": {"buff": "plus"}, "pay-day": {"proj": "coin"},
	"slash": {"melee": "slashx"}, "sucker-punch": {"proj": "fist"}, "mist-ball": {"proj": "mistorb"},
	"psyshock": {"proj": "twinring"}, "psystrike": {"beam": "twinring", "proj": "twinring"},
	"stealth-rock": {"proj": "rockspike"}, "stone-axe": {"melee": "kick", "proj": "axeslash"},
	"stone-edge": {"proj": "pillar"}, "anchor-shot": {"proj": "anchor"},
	"behemoth-blade": {"melee": "slashx", "proj": "blade"}, "hyper-beam": {"beam": "cannon", "proj": "cannon"},
	"crabhammer": {"melee": "pincer"}, "octazooka": {"proj": "ink", "trail": "drip"},
	"whirlpool": {"proj": "swirl"},
}

static func hh(a: int, b: int, c: int) -> float:
	var h: int = ((a * 374761393) & 0xFFFFFFFF) ^ ((b * 668265263) & 0xFFFFFFFF) ^ ((c * 2246822519) & 0xFFFFFFFF)
	h = (((h ^ (h >> 13)) & 0xFFFFFFFF) * 1274126177) & 0xFFFFFFFF
	h ^= h >> 16
	return float(h & 0xFFFFFFFF) / 4294967296.0


static func _disc(P, cx: float, cy: float, r: float, c: String) -> void:
	for y in range(P.h):
		for x in range(P.w):
			if Vector2(float(x) - cx, float(y) - cy).length() <= r:
				P.g[y][x] = c


static func gen(shape: String, P, f: int) -> void:
	match shape:
		"orbelec":
			for k in range(6):
				var a: float = float(k) * PI / 3.0 + float(f) * 0.5
				var p0 := Vector2(6.0 + cos(a) * 4.6, 6.0 + sin(a) * 4.6)
				var pm := Vector2(6.0 + cos(a + 0.35) * 5.6, 6.0 + sin(a + 0.35) * 5.6)
				var p1 := Vector2(6.0 + cos(a) * 6.3, 6.0 + sin(a) * 6.3)
				P.line(p0.x, p0.y, pm.x, pm.y, "l")
				P.line(pm.x, pm.y, p1.x, p1.y, "w")
			_disc(P, 6, 6, 4.2, "m")
			_disc(P, 6, 6, 2.9, "l")
			_disc(P, 6, 6, 1.4, "w")
			P.outline()
		"mesh":
			for k in range(6):
				var a0: float = float(k) * PI / 3.0
				var a1: float = float(k + 1) * PI / 3.0
				P.line(5, 5, 5.0 + cos(a0) * 4.6, 5.0 + sin(a0) * 4.6, "m")
				P.line(5.0 + cos(a0) * 4.6, 5.0 + sin(a0) * 4.6, 5.0 + cos(a1) * 4.6, 5.0 + sin(a1) * 4.6, "l")
				P.line(5.0 + cos(a0) * 2.4, 5.0 + sin(a0) * 2.4, 5.0 + cos(a1) * 2.4, 5.0 + sin(a1) * 2.4, "w")
			if f == 1:
				for k in range(3):
					var a2: float = float(k) * 2.1 + 0.4
					P.set_px(5.0 + cos(a2) * 4.9, 5.0 + sin(a2) * 4.9, "w")
		"drill":
			for x in range(1, 15):
				var hgt: float = (14.0 - float(x)) / 13.0 * 3.6 + 0.4
				for y in range(P.h):
					if absf(float(y) - 4.0) <= hgt:
						P.set_px(x, y, "w" if (x + y + f * 2) % 4 < 2 else "m")
			P.set_px(14, 4, "w")
			for y in range(1, 8):
				P.set_px(1, y, "d")
			P.outline()
		"beak":
			for x in range(3, 13):
				var hh2: float = (12.0 - float(x)) / 9.0 * 3.4
				for y in range(P.h):
					if absf(float(y) - 4.0) <= hh2:
						P.set_px(x, y, "l" if absf(float(y) - 4.0) < hh2 * 0.5 else "m")
			P.set_px(12, 4, "w")
			var z: Array = [[0, 1], [1, 2], [2, 3], [1, 4], [2, 5], [0, 7]] if f == 0 else [[0, 2], [1, 3], [2, 4], [1, 5], [2, 6], [0, 8]]
			for p in z:
				P.set_px(int(p[0]), int(p[1]), "w")
			P.outline()
		"cannon":
			_disc(P, 7, 7, 5.2, "m")
			_disc(P, 7, 7, 3.6, "l")
			_disc(P, 7, 7, 2.0, "w")
			P.arc(7, 7, 6.8 + float(f) * 0.4, -1.2, 1.2, "l")
			P.arc(7, 7, 6.8 + float(f) * 0.4, PI - 1.2, PI + 1.2, "l")
			P.outline()
		"dart":
			P.line(2, 2, 8, 2, "m")
			for y in range(1, 4):
				P.set_px(8, y, "l")
			P.set_px(9, 2, "w")
			P.set_px(10, 2, "w")
			P.line(0, 0, 3, 2, "l")
			P.line(0, 4, 3, 2, "l")
			P.outline()
		"chevron":
			for i in range(3):
				var x0: float = 1.0 + float(i) * 4.0 + float(f)
				var c: String = ["m", "l", "w"][i]
				P.line(x0, 1, x0 + 3.0, 5, c, true, "m" if i == 2 else "d")
				P.line(x0, 9, x0 + 3.0, 5, c, true, "m" if i == 2 else "d")
		"rune":
			for y in range(11):
				for x in range(11):
					var d: float = absf(float(x) - 5.0) + absf(float(y) - 5.0)
					if absf(d - 5.0) < 0.6:
						P.g[y][x] = "m"
					elif absf(d - 2.6) < 0.6:
						P.g[y][x] = "l"
			P.set_px(5, 5, "w")
			if f == 1:
				for p in [[0, 0], [10, 0], [0, 10], [10, 10]]:
					P.set_px(int(p[0]), int(p[1]), "l")
		"axeslash":
			for y in range(P.h):
				for x in range(P.w):
					var aa: float = Vector2(float(x) - 8.0, float(y) - 6.0).length()
					var bb: float = Vector2(float(x) - 5.0, float(y) - 6.0).length()
					if aa <= 6.0 and bb >= 5.0:
						P.g[y][x] = "w" if aa > 5.0 else "m"
			P.line(0, 6, 5, 6, "d", true, "d")
			P.outline()
		"blade":
			for x in range(3, 14):
				var t: float = float(x - 3) / 10.0
				P.set_px(x, 2, "w")
				if t < 0.8:
					P.set_px(x, 1, "l")
					P.set_px(x, 3, "m")
			P.set_px(14, 2, "w")
			for y in range(5):
				P.set_px(2, y, "m")
			P.set_px(0, 2, "d")
			P.set_px(1, 2, "d")
			P.outline()
		"airx":
			var o: float = float(f) * 0.3
			P.arc(2, 6, 5.5, -0.9 + o, 0.9 + o, "l")
			P.arc(2, 6, 4.5, -0.8 + o, 0.8 + o, "w")
			P.arc(10, 6, 5.5, PI - 0.9 + o, PI + 0.9 + o, "l")
			P.arc(10, 6, 4.5, PI - 0.8 + o, PI + 0.8 + o, "w")
			P.line(1, 1, 11, 11, "m")
			P.line(11, 1, 1, 11, "m")
		"pyre":
			var prof: Array = [0.0, 0.8, 1.2, 2.0, 2.8, 3.6, 4.2, 4.6, 4.6, 4.2, 3.4, 2.2, 1.0]
			for y in range(13):
				var wd: float = float(prof[y]) + (hh(y, f, 2) - 0.5) * 0.8
				for x in range(11):
					var d: float = absf(float(x) - 5.0)
					if d <= wd:
						P.set_px(x, y, "w" if (y > 8 and d < wd * 0.4) else ("l" if d < wd * 0.65 else "m"))
			P.set_px(5.0 + float(f - 1), 0, "m")
			P.outline()
		"bone":
			P.line(2, 2, 10, 2, "w", true, "l")
			for p in [[0, 0], [0, 4], [12, 0], [12, 4], [1, 0], [1, 4], [11, 0], [11, 4]]:
				P.set_px(int(p[0]), int(p[1]), "w")
			P.outline()
		"seed":
			_disc(P, 4, 4, 2.7, "m")
			_disc(P, 4, 4, 1.5, "l")
			P.set_px(3, 3, "w")
			for k in range(4):
				var a: float = float(k) * PI / 2.0 + 0.8 + float(f) * 0.4
				P.line(4.0 + cos(a) * 2.7, 4.0 + sin(a) * 2.7, 4.0 + cos(a + 0.5) * 4.2, 4.0 + sin(a + 0.5) * 4.2, "l")
			P.outline()
		"sun":
			_disc(P, 6, 6, 3.2, "l")
			_disc(P, 6, 6, 1.8, "w")
			for k in range(8):
				var a2: float = float(k) * PI / 4.0
				var L: float = 6.0 if (k + f) % 2 == 0 else 4.7
				P.line(6.0 + cos(a2) * 3.6, 6.0 + sin(a2) * 3.6, 6.0 + cos(a2) * L, 6.0 + sin(a2) * L, "m")
		"bomb":
			for c in [[6.0, 7.0, 4.2], [3.8, 5.0, 3.0], [8.4, 5.4, 3.0], [6.0, 4.0, 2.6]]:
				_disc(P, float(c[0]), float(c[1]), float(c[2]), "m")
			_disc(P, 6, 6, 2.6, "l")
			for i in range(3):
				P.set_px(3.0 + hh(i, f, 7) * 7.0, 3.0 + hh(i, f, 8) * 7.0, "w")
			P.outline()
		"xmark":
			P.line(1, 1, 9, 9, "l", true, "m")
			P.line(9, 1, 1, 9, "l", true, "m")
			P.set_px(5, 5, "w")
			P.line(2, 2, 8, 8, "w")
			P.line(8, 2, 2, 8, "w")
			P.outline()
		"grain":
			for i in range(14):
				P.set_px(hh(i, f, 1) * 8.0, hh(i, f, 2) * 8.0, ["d", "m", "m", "l", "w"][int(hh(i, f, 3) * 5.0) % 5])
		"iceball":
			_disc(P, 5, 5, 3.6, "m")
			for k in range(6):
				var a3: float = float(k) * PI / 3.0 + float(f) * 0.5
				P.line(5.0 + cos(a3) * 3.3, 5.0 + sin(a3) * 3.3, 5.0 + cos(a3) * 5.2, 5.0 + sin(a3) * 5.2, "w")
			P.line(3, 3, 6, 3, "l")
			P.line(3, 4, 4, 4, "l")
			P.set_px(3, 3, "w")
		"icicle":
			for x in range(1, 15):
				var half: float = clampf((14.0 - float(x)) / 6.0, 0.0, 1.0) * 1.4
				for y in range(5):
					if absf(float(y) - 2.0) <= half:
						P.set_px(x, y, "w" if y == 2 else ("l" if absf(float(y) - 2.0) < 1.0 else "m"))
			P.set_px(0, 0, "m")
			P.set_px(0, 4, "m")
			P.set_px(1, 1, "m")
			P.outline()
		"flake":
			for k in range(6):
				var a4: float = float(k) * PI / 3.0
				var ex: float = 6.0 + cos(a4) * 5.6
				var ey: float = 6.0 + sin(a4) * 5.6
				P.line(6, 6, ex, ey, "w")
				var bx: float = 6.0 + cos(a4) * 3.4
				var by: float = 6.0 + sin(a4) * 3.4
				P.line(bx, by, 6.0 + cos(a4 + 0.6) * 4.6, 6.0 + sin(a4 + 0.6) * 4.6, "l")
				P.line(bx, by, 6.0 + cos(a4 - 0.6) * 4.6, 6.0 + sin(a4 - 0.6) * 4.6, "l")
			P.set_px(6, 6, "m")
		"coin":
			var rx: float = 3.8 if f == 0 else 1.6
			for y in range(9):
				for x in range(9):
					var e: float = pow((float(x) - 4.0) / rx, 2.0) + pow((float(y) - 4.0) / 3.8, 2.0)
					if e <= 1.0:
						P.g[y][x] = "l" if e > 0.55 else "m"
			if f == 0:
				P.line(4, 2, 4, 6, "w")
				P.set_px(3, 2, "w")
			else:
				P.line(4, 1, 4, 7, "w")
			P.outline()
		"mistorb":
			_disc(P, 5, 5, 2.0, "l")
			P.set_px(5, 5, "w")
			for k in range(8):
				var a5: float = float(k) * PI / 4.0 + float(f) * 0.4
				var r5: float = 3.6 + hh(k, f, 9) * 1.4
				P.set_px(5.0 + cos(a5) * r5, 5.0 + sin(a5) * r5, "w" if k % 2 == 0 else "m")
		"twinring":
			for y in range(13):
				for x in range(13):
					var d1: float = Vector2(float(x) - 4.6, float(y) - 6.0).length()
					var d2: float = Vector2(float(x) - 8.4, float(y) - 6.0).length()
					var in1: bool = absf(d1 - 3.6) < 0.7
					var in2: bool = absf(d2 - 3.6) < 0.7
					if in1 and in2:
						P.g[y][x] = "w"
					elif in1 or in2:
						P.g[y][x] = "m" if f == 0 else "l"
			P.set_px(6.5, 6, "w")
		"pillar":
			var wp: Array = [0.5, 1.2, 2.0, 2.6, 3.0, 3.2, 3.2, 3.2, 3.2, 3.0, 2.6, 2.0, 1.2]
			for y in range(13):
				var w2: float = float(wp[y])
				for x in range(9):
					var d: float = float(x) - 4.0
					if absf(d) <= w2:
						P.set_px(x, y, "w" if (y < 3 and d <= 0.0) else ("l" if d < -0.5 else ("d" if d > 1.0 else "m")))
			P.outline()
		"rockspike":
			_disc(P, 5, 5, 2.8, "m")
			_disc(P, 4, 4, 1.4, "l")
			for k in range(6):
				var a6: float = float(k) * PI / 3.0 + 0.3
				P.line(5.0 + cos(a6) * 2.5, 5.0 + sin(a6) * 2.5, 5.0 + cos(a6) * 5.0, 5.0 + sin(a6) * 5.0, "l", true, "m")
			P.set_px(4, 4, "w")
			P.outline()
		"anchor":
			P.arc(5, 1.6, 1.4, 0.0, TAU, "w")
			P.line(5, 3, 5, 10, "l", true, "m")
			P.line(3, 4, 7, 4, "w", false)
			P.arc(5, 7, 4.2, 0.4, PI - 0.4, "l")
			P.set_px(1, 7, "w")
			P.set_px(9, 7, "w")
			P.outline()
		"swirl":
			for i in range(60):
				var t: float = float(i) * 0.16
				var r: float = 0.5 + t * 0.55
				if r > 6.0:
					break
				var a7: float = t * 1.5 + float(f) * 2.1
				P.set_px(6.0 + cos(a7) * r, 6.0 + sin(a7) * r, "w" if r < 2.3 else ("l" if r < 4.2 else "m"))
			P.set_px(6, 6, "w")
		"ink":
			_disc(P, 5, 5, 3.0, "m")
			_disc(P, 5, 5, 1.7, "d")
			P.set_px(4, 4, "w")
			for k in range(5):
				var a8: float = float(k) * 1.26 + float(f) * 0.6
				P.set_px(5.0 + cos(a8) * 4.6, 5.0 + sin(a8) * 4.6, "l")
			P.outline()
		"pincer":
			var op: float = 0.35 + float(f) * 0.25
			P.arc(6, 6, 4.6, op, TAU - op, "m")
			P.arc(6, 6, 3.6, op + 0.2, TAU - op - 0.2, "l")
			P.line(6.0 + cos(op) * 4.6, 6.0 + sin(op) * 4.6, 12, 3.0 + float(f) * -1.0 + 1.0, "w")
			P.line(6.0 + cos(op) * 4.6, 6.0 - sin(op) * 4.6, 12, 9.0 + float(f) * 1.0 - 1.0, "w")
			P.outline()
		"fist":
			for y in range(2, 9):
				for x in range(2, 9):
					P.g[y][x] = "m"
			for x in range(2, 9):
				P.g[2][x] = "l"
			for k in range(4):
				P.set_px(2.0 + float(k) * 2.0 + 0.5, 3, "w")
				P.set_px(2.0 + float(k) * 2.0 + 0.5, 5, "d")
			P.line(8, 6, 10, 6, "d")
			if f == 1:
				for p in [[0, 0], [10, 0], [0, 10], [10, 10]]:
					P.set_px(int(p[0]), int(p[1]), "l")
			P.outline()
		"hammer":
			P.line(2, 11, 8, 5, "d", true, "d")
			for y in range(1, 6):
				for x in range(6, 12):
					P.g[y][x] = "m"
			for x in range(6, 12):
				P.g[1][x] = "w"
			P.set_px(7, 2, "l")
			P.set_px(8, 2, "l")
			P.outline()
		"feather":
			P.line(4, 0, 4, 12, "w")
			for y in range(1, 11):
				var bl: float = minf(float(y), 11.0 - float(y)) * 0.55 + 0.6
				P.line(4, y, 4.0 - minf(bl, 3.6), y + 1.5, "l")
				P.line(4, y, 4.0 + minf(bl, 3.6), y + 1.5, "m")
			P.outline()
		"plus":
			for y in range(9):
				for x in range(9):
					if (absi(x - 4) <= 1 or absi(y - 4) <= 1) and (absi(x - 4) + absi(y - 4)) <= 5:
						P.g[y][x] = "l"
			P.set_px(4, 4, "w")
			P.set_px(4, 3, "w")
			P.set_px(3, 4, "w")
			if f == 1:
				P.set_px(0, 0, "m")
				P.set_px(8, 8, "m")
			P.outline()
		"fang":
			for y in range(1, 12):
				var wd2: float = (1.0 - float(y) / 12.0) * 3.0 + 0.4
				for x in range(9):
					if absf(float(x) - 4.0) <= wd2:
						P.set_px(x, y, "w" if absf(float(x) - 4.0) < 0.8 else "m")
			P.set_px(4, 12, "w")
			P.outline()
		"slashx":
			for k in range(3):
				var o2: float = float(k) * 2.0 - 2.0
				P.line(1.0 + o2 + 2.0, 1, 11.0 + o2 - 2.0, 11, "w" if k == 1 else "l")
			if f == 1:
				P.line(11, 1, 1, 11, "m")
			P.outline()
		"ember2":
			_disc(P, 4, 4, 2.5, "m")
			_disc(P, 4, 4, 1.2, "w")
		"kick":
			# bota/estela de patada: dos arcos de impacto y una pisada
			P.arc(4, 6, 5.0, -0.8 + float(f) * 0.2, 0.8, "l")
			P.arc(4, 6, 3.4, -0.7, 0.7 + float(f) * 0.2, "w")
			for y in range(4, 9):
				for x in range(6, 12):
					P.g[y][x] = "m"
			P.set_px(7, 5, "w")
			P.set_px(8, 5, "w")
			P.line(6, 8, 11, 8, "d")
			P.outline()
		"lava":
			_disc(P, 5, 5, 3.4, "m")
			_disc(P, 5, 5, 2.0, "l")
			for i in range(4):
				P.set_px(3.0 + hh(i, f, 4) * 5.0, 3.0 + hh(i, f, 5) * 5.0, "w")
			for k in range(3):
				P.set_px(2.0 + float(k) * 3.0, 0.0 + float(f), "m")
			P.outline()
