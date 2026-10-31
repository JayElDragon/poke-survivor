extends Node2D
# main.gd - Etapa 6: tabla de tipos, clima, objetos y estados (sobre la etapa 5: 64 movimientos).
# Teclado (WASD / flechas), mando (stick izquierdo / cruceta) o joystick tactil.
# Movimientos: teclas 1-4 / Q / E, LB / RB del mando, o toca el icono abajo a la derecha.
# Provisional: F1 / F2 (o boton Back del mando) cambian de Pokemon y reinician.
# Al caer: cualquier tecla, boton del mando o toque de pantalla reinicia.
# Cartas de nivel: tocalas, o 1/2/3, o izquierda/derecha + A en el mando.

const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")
const SV = preload("res://scripts/save_data.gd")
const AB = preload("res://scripts/abilities.gd")
const ZM = preload("res://scripts/zmove.gd")
const DYN = preload("res://scripts/dynamax.gd")
const POI = preload("res://scripts/poi.gd")
const KC = preload("res://scripts/kecleon.gd")
const RSC = preload("res://scripts/rescue.gd")
const ALP = preload("res://scripts/alpha.gd")
const DNC = preload("res://scripts/daynight.gd")
const HZD = preload("res://scripts/hazard.gd")
const CVE = preload("res://scripts/cave.gd")
const INV = preload("res://scripts/invasion.gd")
const MET = preload("res://scripts/meteor.gd")
const MEW = preload("res://scripts/mewtwo.gd")
const ACH = preload("res://scripts/ach.gd")
const SEC = preload("res://scripts/secret.gd")
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const ARENA = preload("res://scripts/arena.gd")
const FUS = preload("res://scripts/fusions.gd")
const FFX = preload("res://scripts/fusion_fx.gd")
const EVFX = preload("res://scripts/evo_fx.gd")
const EVAB = preload("res://scripts/evo_abil.gd")
const TXS = preload("res://scripts/textscale.gd")
const TW = preload("res://scripts/tileworld.gd")
const JDM = preload("res://scripts/judgment.gd")
const PG = preload("res://scripts/progress.gd")
const CH = preload("res://scripts/challenges.gd")
const VFX = preload("res://scripts/vfx.gd")
const PFX = preload("res://scripts/pfx.gd")
const PAUSEUI = preload("res://scripts/pause_ui.gd")


const ENEMY_CAP := 64
const AIM_REACH := 520.0
# S35: apuntado manual (opcional, desactivado por defecto)
var aim_touch := -1
var aim_o := Vector2.ZERO
var aim_c := Vector2.ZERO
var aim_touch_dir := Vector2.ZERO
var aim_mouse_t := -99.0
var aim_manual := false
var aim_ang := 0.0
const MAX_MOVES := 4
const ORB_CAP := 300
const BASE_MAGNET := 78.0
const XP_ENEMY := 20.0
const CHUNK := 768.0
const SAFE_R := 260.0
const POWERS := [
	{"id": "fury", "name": "Furia", "desc": "+50% de daño", "color": "#ff6b4a"},
	{"id": "haste", "name": "Impulso", "desc": "+40% de velocidad", "color": "#ffd33d"},
	{"id": "aegis", "name": "Égida", "desc": "-40% de daño recibido", "color": "#7fc8ff"},
	{"id": "frenzy", "name": "Frenesí", "desc": "-35% de recarga", "color": "#c47bff"},
]
const LIFT := 18.0
# Paredes de tierra: tamano del sprite (px nativos) y rectangulos solidos (px nativos desde la esquina sup. izq.)
const WALLS := {
	"wall_a": [Vector2i(39, 53), [Rect2(15, 0, 24, 16), Rect2(0, 16, 39, 37)]],
	"wall_af": [Vector2i(39, 53), [Rect2(0, 0, 24, 16), Rect2(0, 16, 39, 37)]],
	"wall_b": [Vector2i(39, 40), [Rect2(0, 0, 39, 40)]],
	"wall_c": [Vector2i(25, 53), [Rect2(0, 0, 25, 53)]],
	"wall_cf": [Vector2i(25, 53), [Rect2(0, 0, 25, 53)]],
}
const WALL_NAMES := ["wall_a", "wall_af", "wall_b", "wall_c", "wall_cf"]

const MULT_KEYS := ["dmg", "cd", "speed", "radius", "dur", "amount", "arc", "width", "spread", "life", "size", "rate"]
const ADD_KEYS := ["count", "pierce", "stacks"]
const TARGETED := ["melee", "beam", "projectile", "boomerang", "chain", "meteor", "dash", "cone"]

const FLASH_SHADER := "shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 m = COLOR;\n\tvec4 c = texture(TEXTURE, UV);\n\tCOLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a) * m;\n}\n"

# Animaciones de cada Pokemon (sprites.js) y la que se usa al lanzar cada tipo de movimiento.
const ANIMS := ["Idle", "Walk", "Attack", "Shoot", "Charge", "Hurt", "Faint"]
const ANIM_FOR := {
	"melee": "Attack", "beam": "Shoot", "projectile": "Shoot", "nova": "Attack", "aura": "Charge",
	"buff": "Charge", "orbit": "Charge", "boomerang": "Shoot", "chain": "Shoot", "mine": "Charge",
	"meteor": "Charge", "turret": "Charge", "dash": "Attack", "trail": "Walk", "cone": "Shoot",
}

# Tramos de enemigos (enemies.js): minuto de entrada (en segundos), rango de stats base y plantilla.
const TIERS := [
	{"from": 0, "bst": [180, 330], "hp": 17, "spd": 56, "dmg": 6.0, "xp": 3.5, "cast": 7},
	{"from": 70, "bst": [300, 405], "hp": 32, "spd": 62, "dmg": 8.5, "xp": 5.0, "cast": 7},
	{"from": 160, "bst": [385, 465], "hp": 52, "spd": 60, "dmg": 11.0, "xp": 8.0, "cast": 7},
	{"from": 260, "bst": [445, 515], "hp": 88, "spd": 70, "dmg": 14.0, "xp": 13.0, "cast": 7},
	{"from": 380, "bst": [495, 560], "hp": 150, "spd": 66, "dmg": 22.0, "xp": 24.0, "cast": 7},
	{"from": 500, "bst": [530, 620], "hp": 250, "spd": 72, "dmg": 28.0, "xp": 38.0, "cast": 7},
]
# Franjas de jefe: segundo en que salen, PV base, dano, experiencia y rango de stats base.
const GPM := preload("res://scripts/gachapon.gd")
const BOSS_SLOTS := [
	{"at": 180, "hp": 1400, "dmg": 34, "xp": 220, "bst": [490, 545]},
	{"at": 360, "hp": 3200, "dmg": 42, "xp": 420, "bst": [520, 580]},
	{"at": 540, "hp": 5600, "dmg": 48, "xp": 680, "bst": [540, 600]},
	{"at": 720, "hp": 9000, "dmg": 56, "xp": 1000, "bst": [580, 700]},
	{"at": 900, "hp": 16000, "dmg": 68, "xp": 1800, "bst": [600, 700]},
]
# Tipos de Pokemon que "pertenecen" a cada bioma: salen mas a menudo en el (ademas del reparto normal de la run).
const BIOME_TYPES := {
	"forest": ["bug", "grass"],
	"cave": ["rock", "ground"],
	"volcano": ["fire"],
	"beach": ["water", "ground"],
	"sky": ["flying", "dragon"],
}
# Ademas de los tipos, Pokemon concretos que encajan con el bioma (murcielagos en la cueva, castillos de arena en la playa...)
const BIOME_DEX := {
	"cave": [41, 42, 169, 527, 528, 714, 715],   # Zubat, Golbat, Crobat, Woobat, Swoobat, Noibat, Noivern
	# Playa: Sandygast, Palossand y los de costa (Shellder, Cloyster, Krabby, Kingler, Staryu, Starmie, Tentacool, Tentacruel, Wingull,
	# Pelipper, Corphish, Crawdaunt, Mantine, Remoraid, Octillery, Shellos, Gastrodon, Dwebble, Crustle, Binacle, Barbaracle,
	# Crabrawler, Crabominable, Wishiwashi, Mareanie, Toxapex)
	"beach": [769, 770, 90, 91, 98, 99, 120, 121, 72, 73, 278, 279, 341, 342, 226, 223, 224, 422, 423, 557, 558, 688, 689, 739, 740, 746, 747, 748],
}
const BIOME_EXTRA := 2        # Pokemon extra por tramo propios del bioma
const BIOME_W_MUL := 1.6      # peso de los extras (y de los del reparto que ya son del tipo) respecto a los demas
const HEAL_SET := [35, 36, 113, 173, 183, 184, 242, 301, 440, 531, 594, 700, 764, 858]
const SHIELD_SET := [95, 122, 208, 213, 227, 306, 375, 410, 411, 436, 437, 439, 476, 703]
const BOMB_SET := [74, 75, 76, 100, 101, 102, 109, 110, 337, 338, 343, 344]
# Invocador -> Pokemon de su manada.
const SUMMON_MAP := {15: 13, 18: 16, 24: 23, 28: 27, 31: 29, 34: 32, 42: 41, 51: 50, 53: 52, 57: 56, 59: 58,
	62: 60, 68: 66, 73: 72, 78: 77, 82: 81, 85: 84, 91: 90, 117: 116, 130: 129, 168: 167, 169: 41,
	199: 79, 230: 116, 262: 261, 334: 333, 405: 403, 416: 415, 462: 81, 466: 239, 553: 551, 637: 636}
const PLAIN_B := ["chase", "charger", "ranged", "tank"]
const SUPPORT_B := ["healer", "shielder", "summoner"]
const KEEP_DIST := ["ranged", "fan", "beamer", "zoner", "healer", "summoner"]
const DMG_K := 2.4
const XP_K := 5.6
# Torre: un poco mas dificil (vida, dano y ritmo de aparicion de los enemigos; mas vida en los jefes)
# Ajuste de equilibrio: recargas un 10% mas cortas y experiencia ganada un 20% menor
const CD_K := 0.9
const XP_GAIN := 0.8
const TOWER_HP_K := 1.15
const TOWER_DMG_K := 1.12
const TOWER_SPAWN_K := 1.12
const TOWER_BOSS_HP_K := 1.2
# Torre adaptativa: los enemigos ganan vida y dano segun las mejoras de la partida y las permanentes del Pokemon
const TOWER_ADAPT_HP := 0.010      # +1% de vida por mejora de la partida
const TOWER_ADAPT_HP_P := 0.004    # +0,4% por mejora permanente
const TOWER_ADAPT_DMG := 0.004
const TOWER_ADAPT_DMG_P := 0.002
const TOWER_ADAPT_MAX_HP := 1.0    # tope: hasta el doble de vida
const TOWER_ADAPT_MAX_DMG := 0.4   # tope: hasta +40% de dano
var tw_adapt_hp := 1.0
const TOWER_ADAPT_MAX_BOSS := 1.5   # tope del factor de vida para los jefes
var tw_boss_t0 := -1.0
var tw_fight_dmg := 0.0
var tw_log: Array = []   # por jefe vencido: piso, segundos, vida perdida %, nivel
var tw_adapt_dmg := 1.0
var tw_adapt_t := 0.0
const TOWER_XP_K := 0.65   # en la Torre se sube de nivel mas despacio
const SHINY_RATE := 1.0 / 4096.0

# Mejoras de estadistica (levelup.js). "w" = peso al sortear la carta.
const STAT_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "rgn": "sprout", "mag": "magnet", "xp": "book", "size": "size", "heal": "berry", "mult": "cards", "pierce": "quickclaw", "amp": "star", "lens": "scopelens", "trs": "amuletcoin", "fang": "lifeorb", "edge": "expertbelt", "dstrike": "choiceband"}
const STAT_IDS := ["hp", "atk", "spd", "cd", "def", "rgn", "mag", "xp", "size", "heal", "mult", "pierce", "amp", "lens", "trs", "fang", "edge", "dstrike"]
const STATS := {
	"hp": {"title": "Vigor", "desc": "+20 de vida máxima (y la recupera).", "max": 9999},
	"atk": {"title": "Potencia", "desc": "+10% de daño con todos los movimientos.", "max": 40},
	"spd": {"title": "Carrera", "desc": "+7% de velocidad de movimiento.", "max": 8},
	"cd": {"title": "Reflejos", "desc": "-8% de recarga en todos los movimientos.", "max": 10},
	"def": {"title": "Coraza", "desc": "+6% de reducción de daño recibido.", "max": 12},
	"rgn": {"title": "Síntesis", "desc": "+0.9 de vida regenerada por segundo.", "max": 9999},
	"mag": {"title": "Imán", "desc": "+30% de radio de recogida de experiencia.", "max": 6},
	"xp": {"title": "Aprendizaje", "desc": "+12% de experiencia ganada.", "max": 8},
	"size": {"title": "Calibre", "desc": "+12% de tamaño de proyectiles, orbes y áreas.", "max": 6},
	"heal": {"title": "Baya Zidra", "desc": "Recupera el 45% de tu vida ahora mismo.", "max": 99999},
	"mult": {"title": "Multiplicador", "desc": "+1 proyectil en movimientos de disparo, cono y bumerán (cada nivel rinde menos).", "max": 99999},
	"pierce": {"title": "Fuerza Perforante", "desc": "+1 perforación en disparos, conos y ondas (cada nivel rinde menos).", "max": 99999},
	"amp": {"title": "Amplificador", "desc": "+12% de probabilidad y duración de estados: parálisis, congelación, confusión, quemadura y veneno.", "max": 99999},
	"lens": {"title": "Lente de Precisión", "desc": "+3% de probabilidad de crítico (3 niveles: +9%; luego rinde menos, tope 30%).", "max": 99999},
	"trs": {"title": "Imán del Tesoro", "desc": "+8% de Pokémonedas al acabar la partida (rinde menos con cada nivel).", "max": 99999},
	"fang": {"title": "Colmillo Vampírico", "desc": "Recuperas un 4% del daño que haces (3 niveles: 12%; luego rinde menos, tope 25%).", "max": 99999},
	"edge": {"title": "Filo Fatal", "desc": "+12% de daño crítico (rinde menos con cada nivel, tope x3).", "max": 99999},
	"dstrike": {"title": "Golpe Doble", "desc": "+6% de probabilidad de golpear dos veces (rinde menos, tope 45%).", "max": 99999},
}

var flash_shader: Shader
var ground: Node2D
var biome_idx := 0
var biome_off := 0
var partner: Player = null       # Cooperativo: segundo Pokemon (IA o segundo mando)
var partner_cd := 0.0
var partner_move: Dictionary = {}
var partner_lvl := 0
var partner_pad := -1
var partner_dir := Vector2.ZERO
# Habilidades pasivas por Pokemon (scripts/abilities.gd)
var ab_fx: Dictionary = {}
# Movimiento Z: uno por partida desde el nivel 15 (ver scripts/zmove.gd)
var z_type := ""
var z_used := false
var adapt_k := 1.0          # dificultad adaptativa: multiplica vida y cantidad de enemigos (0.75 a 1.25)
var adapt_taken := 0.0
var adapt_next := 45.0
var adapt_adj := 0.0
var adapt_prev_hp := -1.0
var z_cd := 0.0   # enfriamiento del Z (se cuenta cuando termina el movimiento)
var z_state := ""     # "" | "cine" | "fx"
var z_t := 0.0
var join_t := -1.0   # cartel "se une a ti" al capturar un Alfa/jefe (segundos desde que empezo; -1 = oculto)
var join_name := ""
var join_col := Color.WHITE
var zfx = null
var z_req := false
var dyn = null
var dyn_used := false
var dyn_cd := 0.0
var dyn_req := false
var dyn_lt_down := false
var dyn_flash := 0.0
var run_dens := 0
var z_rt_down := false
var ab_first_t := -999.0
var ab_sturdy_t := -999.0
var defiant_t := 0.0
var cur_kind := ""
# Espectador (cooperativo): al caer, tu cuerpo pasa a ser el de tu companero, que tiene vida propia, y revives a los DOWN_REVIVE_T s.
const DOWN_REVIVE_T := 20.0
var down := false
var down_t := 0.0
var partner_hp := 1.0
var partner_max := 1.0
var partner_inv := 0.0
var partner_last := Vector2.ZERO
const TOWER_FLOORS := 60
const TOWER_BOSS_AT := 50.0     # segundos de piso hasta que sale el jefe
var tw_floor := 1
var tw_t := 0.0                 # tiempo dentro del piso
var tw_boss = null
var tw_rest := 0.0
var tw_phase := 0               # 0 = combate, 1 = piso de descanso (elige cura/mejora/escudo), 2 = cartas de riesgo
# veneno contra jefes: 20% del porcentaje de vida máxima
const POISON_BOSS_MUL := 0.2
# Estados de control: duracion base (s) y texto. Los jefes resisten (ver _apply_cc).
const CC_DUR := {"freeze": 1.8, "para": 3.0, "sleep": 4.0, "conf": 3.0, "charm": 20.0}
const CC_TEXT := {"freeze": "¡Congelado!", "para": "¡Paralizado!", "sleep": "¡Dormido!", "conf": "¡Confundido!", "charm": "¡Enamorado!"}
const CC_COL := {"freeze": "#8fe3ff", "para": "#ffe14d", "sleep": "#b9b6ff", "conf": "#ff7ad9", "charm": "#ff6fa8"}
const CC_SUFFIX := {"freeze": "Puede congelar (%d%%).", "para": "Puede paralizar (%d%%).", "sleep": "Puede dormir (%d%%).", "conf": "Puede confundir (%d%%).", "charm": "Puede enamorar (%d%%)."}
var tw_final := 0               # jefe final del piso 60: Arceus (493)
var tw_boss2 = null             # segundo jefe (piso 30)
var tw_init := false
var tw_shield := 0.0            # escudo para el siguiente piso (se gana en el descanso)
var tw_risk: Array = []         # cartas de riesgo tomadas en esta run
var tw_surge := 40.0
const TOWER_RISKS := [
	{"id": "frenzy", "name": "Frenesí", "icon": "r_frenzy", "desc": "Atacas un 25% más rápido, pero recibes un 20% más de daño.", "fx": {"cd": 0.8, "taken": 1.2}},
	{"id": "glass", "name": "Cañón de cristal", "icon": "r_glass", "desc": "+20% de daño, pero tu vida máxima baja un 15%.", "fx": {"atk": 1.2, "maxhp": 0.85}},
	{"id": "swift", "name": "Pies ligeros", "icon": "r_swift", "desc": "Te mueves un 20% más rápido, pero los enemigos también son un 10% más rápidos.", "fx": {"spd": 1.2, "espd": 1.1}},
	{"id": "blood", "name": "Pacto de sangre", "icon": "r_blood", "desc": "Recuperas 2 PS por cada Pokémon derrotado, pero los jefes pegan un 20% más fuerte.", "fx": {"killheal": 2.0, "bossdmg": 1.2}},
	{"id": "scholar", "name": "Saber prohibido", "icon": "r_scholar", "desc": "+50% de experiencia, pero los enemigos tienen un 20% más de vida.", "fx": {"xp": 1.5, "ehp": 1.2}},
	{"id": "stone", "name": "Piel de piedra", "icon": "r_stone", "desc": "Recibes un 25% menos de daño, pero te mueves un 15% más lento.", "fx": {"taken": 0.75, "spd": 0.85}},
	{"id": "contract", "name": "Contrato del jefe", "icon": "contract", "paper": true, "desc": "+50% de monedas por piso, pero los jefes tienen un 25% más de vida.", "fx": {"coins": 1.5, "bossHp": 1.25}},
	{"id": "fast", "name": "Ayuno", "icon": "r_fast", "desc": "+15% de daño, pero las bayas y la cura del descanso curan un 45% menos.", "fx": {"atk": 1.15, "healmul": 0.55}},
	{"id": "swarm", "name": "Llamada de la horda", "icon": "r_swarm", "desc": "+12% de daño y +20% de experiencia, pero aparecen un 30% más de enemigos.", "fx": {"atk": 1.12, "xp": 1.2, "spawn": 1.3}},
	{"id": "quick", "name": "Manos veloces", "icon": "r_quick", "desc": "Tu enfriamiento baja un 30%, pero tu daño baja un 10%.", "fx": {"cd": 0.7, "atk": 0.9}},
	{"id": "heavy", "name": "Golpes cargados", "icon": "r_heavy", "desc": "+22% de daño, pero tu enfriamiento sube un 20%.", "fx": {"atk": 1.22, "cd": 1.2}},
	{"id": "overclock", "name": "Sobrecarga", "icon": "r_overclock", "desc": "Tu enfriamiento baja un 25%, pero tu vida máxima baja un 10%.", "fx": {"cd": 0.75, "maxhp": 0.9}},
	{"id": "metronome", "name": "Ritmo frenético", "icon": "r_metronome", "desc": "Tu enfriamiento baja un 20%, pero aparecen un 15% más de enemigos.", "fx": {"cd": 0.8, "spawn": 1.15}},
	{"id": "slowburn", "name": "Brasa lenta", "icon": "r_slowburn", "desc": "Tu enfriamiento sube un 15%, pero recibes un 25% menos de daño y regeneras 1 PS por segundo.", "fx": {"cd": 1.15, "taken": 0.75, "regen": 1.0}},
	{"id": "berserk", "name": "Furia ciega", "icon": "r_berserk", "desc": "Atacas un 15% más rápido y +10% de daño, pero recibes un 10% más de daño.", "fx": {"cd": 0.85, "atk": 1.1, "taken": 1.1}},
]
const TOWER_MAX_RISKS := 6
const LEGEND_CHANCE := 0.01      # probabilidad (por pantalla de pactos) de que una carta sea legendaria
const TOWER_LEGENDS := [
	{"id": "l_time", "name": "Maestría del tiempo", "icon": "r_l_time", "desc": "Tu enfriamiento baja un 70%. Sin ningún coste.", "fx": {"cd": 0.3}},
	{"id": "l_bag", "name": "Doble equipaje", "icon": "r_l_bag", "desc": "Puedes llevar 2 objetos a la vez (por ejemplo Restos y Cascabel Concha) y recibes uno ahora mismo. Sin ningún coste.", "fx": {"carry": 1.0}},
	{"id": "l_reap", "name": "Sed de victoria", "icon": "r_l_reap", "desc": "Cada Pokémon que derrotes aumenta tu daño permanentemente un 0,30%. Sin ningún coste.", "fx": {"reap": 1.0}},
	{"id": "l_armor", "name": "Coraza legendaria", "icon": "r_l_armor", "desc": "Tu defensa sube un 60%. Sin ningún coste.", "fx": {"def": 0.6}},
]
var tw_force_legend := ""


func _all_risks() -> Array:
	return TOWER_RISKS + TOWER_LEGENDS


func _risk_count() -> int:
	var n := 0
	for rid in tw_risk:
		if not String(rid).begins_with("l"):
			n += 1
	return n
var tw_clears := 0
const RIFTS_LIMIT := 480.0   # Contrarreloj de grietas: 8 minutos
var run_rifts := 0
var timeup := false
# --- Retos de 10 minutos (modo "chal") ---
var ch_inst: Dictionary = {}
var ch_def: Dictionary = {}
var ch_m: Dictionary = {}
var ch_over := false
var ch_sets: Dictionary = {}      # estado -> {id de enemigo: true}
var ch_multi: Dictionary = {}     # id de enemigo -> {estado: true}
var ch_hits: Dictionary = {}      # movimiento -> [fotograma, golpes, contado]
var ch_src_kills: Dictionary = {}
var ch_moved_min: Dictionary = {}
var ch_last_hurt := 0.0
var ch_check_t := 0.0
var ch_prev_pos := Vector2.ZERO
var team: Array = []
var team_cur := 0
var team_bonus := 0.0
var swap_cd := 0.0
var swap_req := -2          # -2 nada, -1 siguiente, >=0 ranura concreta
var gen_q: Array = []
var gfx: Node2D
var world: Node2D
var fx: Node2D
var pfx: Node2D
var player: Player
var cam: Camera2D
var jd = null
var poi = null
var kec = null
var rescue = null
var alpha = null
var hz = null
var cave = null
var inv = null
var meteor = null
var mew = null
var sec = null
var dn = null
var balls := 0
const NORMAL_MOVE_W := 0.15
const BALL_CAP := 6
var shop_open := false
var act_req := false
var ui_layer: CanvasLayer
var hud: Hud
var stick: Stick
var slots: Slots
var cards: Cards
var enemies: Array = []
var bullets: Array = []
var orbs: Array = []
var fields: Array = []
var target: Node2D = null
var run_time := 0.0
var kills := 0
var spawn_acc := 0.0
var shake := 0.0
var death_t := 0.0
var arena_down := false   # caido dentro de una arena de grieta (desmayo, sin Game Over)
var death_done_t := -1.0   # segundos desde que termino la animacion de muerte (-1: aun no)
const DEATH_SLOW := 0.3      # camara lenta al desmayarse
const DEATH_SLOW_T := 0.6    # segundos de juego en camara lenta (0,6 / 0,3 = 2 s reales)
var choosing := false
var pending_levels := 0
var pending_items := 0   # objetos recogidos durante un Movimiento Z: se ofrecen al terminar
var stat_lv := {}
var base_spd := 100.0
var base_atk := 1.0
var item := ""
var reap_kills := 0       # Sed de victoria: derrotas acumuladas (+0,3% de dano cada una)
var item3 := ""          # tercer objeto (mejora permanente Mochila grande)
var item2 := ""          # segundo objeto (carta legendaria Doble equipaje)
var sash_t := -999.0
var bell_heal := 0.0
var wx_kind := ""
var wx_t := 0.0
var wx_dur := 0.0
var wx_check := 60.0
var wx_chip := 0.0
var wx_banner := 0.0
var wx: WeatherFx
var cast_run: Array = []
var boss_run: Array = []
var boss_idx := 0
# S63: director de hitos de la Normal Run (un solo dueño, banderas de un disparo, cola de pendientes)
const DIR_MS := [["wave", 30.0], ["rift", 60.0], ["meowth", 120.0], ["boss", 180.0], ["map", 240.0]]
const ETERNATUS_DEX := 890
const MINI_DEXES := [248, 321, 95, 208, 143, 130, 464, 306, 376, 76, 131, 149]   # Tyranitar, Wailord, Onix, Steelix + v5.3: Snorlax, Gyarados, Rhyperior, Aggron, Metagross, Golem, Lapras, Dragonite
var dir_done := {}
var dir_gap := 0.0
var dir_warned := false
var dir_finale := false
var late_warned := false
var dir_map := false
var dir_blocked := ""
var dir_log: Array = []
var dir_eter = null
var mini_last := {}
var mini_chk := 40.0
var surge_t := 90.0
var preload_t := 0.0
var banner_text := ""
var ffx = null
var evfx = null
var evab = null
var fusion_t := 0.0
var fusion_name := ""
var banner_t := 0.0
var event_id := ""
var event_t := 0.0
var horde_defs: Array = []
var last_event := ""
var next_event_t := 270.0
var thief_t := 180.0
var thieves := 0
var hazards: Array = []
var ebullets: Array = []
var player_vel := Vector2.ZERO
var coins := 0
var paused := false
var choose_idle := 0.0
var ret_cd := 0.0
var ret_last := 0
var unfreeze_count := 0
var pause_ui: CanvasLayer
var mini: Node2D
var cam_zoom := 1.65  # campo de vision: ajustable en la pausa (100-200 %), se guarda en Ajustes
var settings_open := false
var run_saved := false
var run_bosses := 0
# --- modos de juego (menu "Jugar"): normal | daily | rush | party ---
var mode := "normal"
var mods: Array = []
var rush_i := 0
var rush_rest := 5.0
var nh_last := 0.0
var nh_max := 0.0
var run_chests := 0
var perks: Dictionary = {}
var rerolls := 0
var revives := 0
var has_bag3 := false
var has_bag := false   # mejora permanente Mochila: llevas 2 objetos
var run_dmg := {}
var sitrus_t := -999.0
var wp_t := 0.0
var run_kills_by := {}
var dmg_src := ""
var bans := 0
var banned := {}
var dmg_on := true
var shake_on := true
var shake_k := 1.0
var quality := 0
var perf_lv := 0   # Rendimiento (Ajustes/Pausa): 0 normal, 1 ahorro, 2 minimo
var q_auto := 1.0
var q_bad_t := 0.0
var fx_load := 1.0   # 1 = efectos completos; baja sola si el FPS cae (aligera evolucionados y fusiones)
var world_seed := 0
var menu_mode := false   # fondo del menu: solo trampas, sin cofres, altares ni fuentes (como el juego original)
var chunks := {}
var player_chunk := Vector2i(99999, 99999)
var power_kind := ""
var power_t := 0.0
var player_lava_t := 0.0
var trap_slow_t := 0.0
var trap_freeze_t := 0.0
var trap_para_t := 0.0
var trap_sleep_t := 0.0
var trap_conf_t := 0.0
var tickets := 0
var tickets10 := 0
var gold_gcoins_run := 0
var gcoins_run := 0   # Gachapon Coins de la partida (las suelta Poltchageist)
# --- grietas y arenas legendarias ---
const ARENA_POS := Vector2(60000.0, 60000.0)
const RIFT_START := 75.0
const RIFT_EVERY := 30.0
const RIFT_END := 1680.0
const ARENA_LIMIT := 120.0
const DEN_RATE := 0.05    # probabilidad de guarida Dynamax por chequeo
const DEN_TTL := 30.0     # segundos que dura abierta
const DEN_FROM := 120.0   # no aparecen antes de este tiempo de partida
var rift: Node2D = null
var rift_info := {}
var rift_check := RIFT_START
var rift_miss := 0
var arena: Node2D = null
var cave_type := ""   # mientras se genera la oleada de una cueva: solo Pokemon de ese tipo
var ainfo := {}
var bonds := 0
var bond_pairs: Array = []   # v6.0: cada vinculo es una pareja [id, id] con su propio hueco
var bond_first := ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#16233a"))
	randomize()
	L.apply()
	PXF.apply()
	DSP.menu_mode = false
	DSP.apply(get_tree())
	DisplayServer.screen_set_keep_on(true)   # que el movil no se apague en plena partida
	PAD.apply()
	Aud.setup(self)
	Aud.music("forest")
	_add_input_actions()
	_bind_move_devices(-1)
	flash_shader = Shader.new()
	flash_shader.code = FLASH_SHADER

	ground = TW.new()
	add_child(ground)
	gfx = Node2D.new()
	add_child(gfx)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	fx = Node2D.new()
	add_child(fx)
	pfx = PFX.new()
	pfx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.add_child(pfx)
	ffx = FFX.new()
	ffx.main = self
	fx.add_child(ffx)
	evfx = EVFX.new()
	evfx.main = self
	fx.add_child(evfx)
	evab = EVAB.new(self)

	_load_data()
	mode = SV.run_mode
	mods = SV.run_mods.duplicate()
	PG.off = mode == "party"
	if mode == "daily":
		SV.run_seed = SV.daily_seed()
		mods = [SV.daily_mod(SV.run_seed)]
		SV.run_dex = SV.daily_dex(SV.run_seed)
		seed(SV.run_seed)   # mismo mundo y mismos sorteos iniciales para todos hoy
	elif mode == "party":
		SV.run_dex = SV.party_dex
		mods = []
	elif mode == "team":
		SV.team_dex = SV.team_list()
		SV.run_dex = int(SV.team_dex[0])
	elif mode == "coop":
		pass
	elif mode == "rush":
		# Rush de Jefes: cada partida empieza en un bioma distinto y rota mas rapido
		biome_off = randi() % ground.count()
		biome_idx = biome_off
		ground.set_biome(biome_off, true)
	if mode != "daily" and mode != "party" and mode != "rush" and mode != "chal" and not SV.run_mods.is_empty():
		mods = SV.run_mods.duplicate()
	if mode == "chal":
		_ch_setup()
	_cand_cache = {}
	if mode == "rifts":
		rift_check = 20.0
	if mode == "tower":
		var st: int = int(SV.d.get("tower_start", 1))
		var cl0: Dictionary = (SV.d.get("tower", {}) as Dictionary).get("claimed", {})
		if st > 1 and st <= TOWER_FLOORS and cl0.has(str(st - 1)):
			tw_floor = st
		tw_final = 493
	_roll_run()
	surge_t = 90.0
	next_event_t = randf_range(240.0, 300.0)
	thief_t = randf_range(120.0, 240.0)
	perks = SV.perks()
	if mode == "tower":
		var rn: int = SV.tower_relics()
		perks["hp"] = float(perks["hp"]) + 6.0 * float(rn)
		perks["atk"] = float(perks["atk"]) * (1.0 + 0.02 * float(rn))
	rerolls = int(perks["rerolls"])
	revives = SV.up_level("revive")
	ab_fx = AB.fx_of(_pdex())
	z_type = SV.zm_type_for(_pdex())
	SV.d.erase("item_block")   # v6.1: limpia los objetos que versiones anteriores vetaban para siempre
	has_bag = SV.up_level("bag") > 0
	has_bag3 = has_bag and SV.up_level("bag3") > 0
	# Veto como en el original: los movimientos vetados se eligen en Mejoras (por Pokemon).
	bans = 0
	var _bl: Array = SV.ban_list(SV.run_dex)
	for _bi in range(mini(_bl.size(), int(perks["bans"]))):
		banned[String(_bl[_bi])] = true
	dmg_on = bool(SV.setting("dmg_numbers"))
	_apply_shake()
	quality = int(SV.setting("quality"))
	apply_perf()
	var sel_dex: int = SV.run_dex
	var st: Dictionary = _dex_by[sel_dex]
	player = Player.new()
	player.z_index = 13   # siempre por encima de los efectos (fusiones z 12): el jugador nunca pierde de vista a su Pokemon
	player.setup(sel_dex, _sm(sel_dex), flash_shader)
	var sh_aura := ShieldAura.new()
	sh_aura.m = self
	sh_aura.z_index = 2
	player.add_child(sh_aura)
	if SV.owns(sel_dex) and bool(SV.d["owned"][str(sel_dex)]["shiny"]) and bool(SV.d["shiny_on"]):
		player.set_shiny()
	player.max_hp = float(st["hp"]) + float(perks["hp"])
	if _has_mod("frail"):
		player.max_hp = roundf(player.max_hp * 0.5)
	if mode == "chal" and _ch_rs("one_hp"):
		player.max_hp = 1.0
	player.hp = player.max_hp
	nh_last = player.hp
	nh_max = player.max_hp
	player.spd = float(st["spd"])
	player.atk = float(st["atk"])
	player.types = st["types"]
	base_spd = player.spd * float(perks["spd"])
	base_atk = player.atk * float(perks["atk"])
	if mode == "team":
		_setup_team()
	for sid in STAT_IDS:
		stat_lv[sid] = 0
	player.xp_next = _xp_need(1)
	player.moves = _start_moves(sel_dex, player.types)
	player.slot = 0
	_arrange()
	world.add_child(player)
	if mode == "coop":
		_setup_partner()
	world_seed = randi() % 100000
	ground.setup(world_seed)
	Prop.tw = ground
	_update_world(0.0)
	ground.flush_bake()
	cam = Camera2D.new()
	player.add_child(cam)
	_apply_fov()
	cam.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	ui_layer = ui
	jd = JDM.new()
	poi = POI.new()
	poi.m = self
	kec = KC.new()
	kec.m = self
	rescue = RSC.new()
	rescue.m = self
	rescue.poi = poi
	alpha = ALP.new()
	alpha.m = self
	alpha.poi = poi
	hz = HZD.new()
	hz.m = self
	cave = CVE.new()
	cave.m = self
	cave.poi = poi
	inv = INV.new()
	inv.m = self
	inv.poi = poi
	meteor = MET.new()
	meteor.m = self
	meteor.poi = poi
	mew = MEW.new()
	mew.m = self
	mew.poi = poi
	sec = SEC.new()
	sec.m = self
	sec.poi = poi
	jd.m = self
	dn = DNC.new()
	dn.m = self
	dn.setup()
	wx = WeatherFx.new()
	ui.add_child(wx)
	hud = Hud.new()
	hud.show_fps = bool(SV.setting("fps"))
	hud.poke_name = L.t(String(st["name"]))
	ui.add_child(hud)
	mini = Minimap.new()
	mini.m = self
	mini.position = Vector2(8.0 + DSP.insets(get_tree()).x, 84.0)
	ui.add_child(mini)
	pause_ui = PAUSEUI.new()
	add_child(pause_ui)
	pause_ui.build()
	pause_ui.resume.connect(func(): paused = false)
	pause_ui.fov_changed.connect(func(_p: int): _apply_fov())
	pause_ui.perf_changed.connect(func(_l: int): apply_perf())
	pause_ui.stick_fixed_changed.connect(func(on: bool): stick.fixed = on; stick.queue_redraw())
	pause_ui.quit_run.connect(_abandon)
	pause_ui.summary_requested.connect(func(): pause_ui.show_summary(pause_summary()))
	pause_ui.open_settings.connect(_open_settings)
	stick = Stick.new()
	stick.radius = [70.0, 90.0, 120.0][clampi(int(SV.setting("stick")), 0, 2)]
	stick.fixed = bool(SV.d["settings"].get("stick_fixed", false))
	ui.add_child(stick)
	var amk := AimMark.new()
	amk.m = self
	amk.visible = false
	amk.z_index = 50
	world.add_child(amk)
	slots = Slots.new()
	ui.add_child(slots)
	if mode == "team":
		var tu := TeamUi.new()
		tu.m = self
		ui.add_child(tu)
	slots.picked.connect(_set_active)
	cards = Cards.new()
	ui.add_child(cards)
	cards.chosen.connect(_on_card_chosen)
	cards.reroll_pressed.connect(_on_reroll)
	cards.ban_picked.connect(_on_ban)
	cards.block_pressed.connect(_on_block_pressed)
	cards.skip_pressed.connect(_on_skip_pressed)

	# Unos pocos al empezar, para que no se vea vacio al probar.
	for i in range(3):
		if mode != "rush" and mode != "tower":
			_spawn_one(randf() * TAU, true)


func _add_input_actions() -> void:
	if InputMap.has_action("move_left"):
		return
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
	}
	var dpad := {
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN,
	}
	var sticks := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in keys:
		InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		var b := InputEventJoypadButton.new()
		b.device = -1   # cualquier mando (en Android TV el mando no siempre es el indice 0)
		b.button_index = dpad[action]
		InputMap.action_add_event(action, b)
		var m := InputEventJoypadMotion.new()
		m.device = -1
		m.axis = sticks[action][0]
		m.axis_value = sticks[action][1]
		InputMap.action_add_event(action, m)


# Con dos mandos (cooperativo) el jugador 1 solo escucha al primero; si no, a cualquiera.
func _bind_move_devices(dev: int) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(action):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				ev.device = dev


func _manual_aim_vec() -> Vector2:
	# Prioridad: stick derecho del mando > dedo en la mitad derecha > raton (si se movio hace poco)
	var pads: Array = Input.get_connected_joypads()
	if not pads.is_empty():
		var rv := Vector2(Input.get_joy_axis(int(pads[0]), JOY_AXIS_RIGHT_X), Input.get_joy_axis(int(pads[0]), JOY_AXIS_RIGHT_Y))
		if rv.length() > 0.35:
			return rv.normalized()
	if aim_touch != -1 and aim_touch_dir != Vector2.ZERO:
		return aim_touch_dir
	if aim_touch == -1 and run_time - aim_mouse_t < 3.0 and not DisplayServer.is_touchscreen_available():
		var sp: Vector2 = player.get_global_transform_with_canvas().origin + Vector2(0.0, -player.body_h * 0.5)
		var d: Vector2 = get_viewport().get_mouse_position() - sp
		if d.length() > 18.0:
			return d.normalized()
	return Vector2.ZERO


func _aim_input(event: InputEvent) -> void:
	if not bool(SV.d["settings"].get("manual_aim", false)):
		aim_touch = -1
		return
	var half: float = get_viewport().get_visible_rect().size.x * 0.5
	if event is InputEventMouseMotion:
		aim_mouse_t = run_time
	elif event is InputEventScreenTouch:
		if event.pressed and aim_touch == -1 and event.position.x > half:
			aim_touch = event.index
			aim_o = event.position
			aim_c = event.position
			aim_touch_dir = Vector2.ZERO
		elif not event.pressed and event.index == aim_touch:
			aim_touch = -1
			aim_touch_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == aim_touch:
		aim_c = event.position
		var dd: Vector2 = aim_c - aim_o
		if dd.length() > 70.0:
			aim_o = aim_c - dd.normalized() * 70.0   # el origen sigue al dedo para girar rapido
			dd = aim_c - aim_o
		if dd.length() > 14.0:
			aim_touch_dir = dd.normalized()


func _input(event: InputEvent) -> void:
	_aim_input(event)


func _pad_slot(bi: int) -> int:
	for i in range(6):
		if PAD.btn("slot%d" % (i + 1)) == bi:
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if settings_open:
		return
	if shop_open:
		kec.ui_input(event)
		return
	if _zoom_input(event):
		return
	var slot := -1
	var cyc := 0
	var go := false
	var toggle_pause := false
	var confirm := false
	var cancel := false
	var tpos := Vector2(-1.0, -1.0)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				slot = 0
			KEY_2:
				slot = 1
			KEY_3:
				slot = 2
			KEY_4:
				slot = 3
			KEY_5:
				slot = 4
			KEY_6:
				slot = 5
			KEY_Q:
				cyc = -1
			KEY_E:
				cyc = 1
			KEY_TAB:
				swap_req = -1
			KEY_Z:
				z_req = true
			KEY_C:
				dyn_req = true
			KEY_ESCAPE, KEY_P:
				toggle_pause = true
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				confirm = true
			KEY_BACKSPACE, KEY_X:
				cancel = true
			_:
				go = true
	elif event is InputEventJoypadButton and event.pressed:
		var bi: int = event.button_index
		if bi == PAD.btn("confirm"):
			confirm = true
		elif bi == PAD.btn("cancel"):
			cancel = true
		elif bi == PAD.btn("prev"):
			cyc = -1
		elif bi == PAD.btn("next"):
			cyc = 1
		elif bi == PAD.btn("pause") or (bi == JOY_BUTTON_BACK and not PAD.is_mapped(JOY_BUTTON_BACK)):
			toggle_pause = true
		elif bi == PAD.btn("swap"):
			swap_req = -1
		elif bi == PAD.btn("zmove"):
			z_req = true
		elif bi == PAD.btn("dynamax"):
			dyn_req = true
		elif _pad_slot(bi) >= 0:
			slot = _pad_slot(bi)
		elif bi == JOY_BUTTON_Y:   # en partida: Y / Triángulo = Movimiento Z (con cartas en pantalla sigue siendo relanzar)
			z_req = true
			go = true
		elif bi == JOY_BUTTON_X:   # en partida: X / Cuadrado = Dynamax (con cartas en pantalla sigue siendo vetar)
			dyn_req = true
			go = true
		else:
			go = true
	elif event is InputEventScreenTouch and event.pressed:
		go = true
		tpos = event.position

	var sreq: int = swap_req
	swap_req = -2
	if player.dead:
		if (go or confirm or cancel or toggle_pause or slot >= 0) and _death_clock() > 1.3:
			_go_menu()
	elif paused:
		if toggle_pause or cancel:
			paused = false
	elif z_state != "":
		pass
	elif not choosing and not shop_open:   # v5.2.1: con la tienda abierta, tocar "Comprar" ya no activa Dynamax/Z debajo
		if confirm or cyc == 1 or (tpos.x >= 0.0 and hud.act_txt != "" and hud.act_rect().has_point(tpos)):
			act_req = true
		if (z_req or (tpos.x >= 0.0 and hud.z_rect().has_point(tpos))) and _z_can():
			_z_start()
			z_req = false
			return
		if (dyn_req or (tpos.x >= 0.0 and hud.dyn_rect().has_point(tpos))) and _dyn_can():
			_dyn_start()
			dyn_req = false
			return
		if sreq > -2 and mode == "team":
			_swap_team(_team_next() if sreq == -1 else sreq)
		if toggle_pause:
			paused = true
		elif tpos.x >= 0.0 and hud.pause_rects()[0].has_point(tpos):
			paused = true
		elif slot >= 0:
			_set_active(slot)
		elif cyc != 0:
			_set_active(posmod(player.slot + cyc, _slot_list().size()))
	z_req = false
	dyn_req = false


# Reloj de la pantalla final: empieza cuando acaba la animacion de muerte (0 mientras se esta cayendo)
func _death_clock() -> float:
	return 0.0 if death_done_t < 0.0 else death_done_t + 0.3


# Boton atras de Android: pausa / reanuda; en la pantalla final vuelve al menu.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and player != null:
		if player.dead:
			if _death_clock() > 1.3:
				_go_menu()
		elif paused:
			paused = false
		elif not choosing:
			paused = true


# Ajustes dentro de la partida: la misma pantalla del menu, encima de la pausa.
func _open_settings() -> void:
	settings_open = true
	pause_ui.close()
	Engine.set_meta("menu_overlay", true)
	var cl := CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	var m: Control = load("res://scenes/menu.tscn").instantiate()
	cl.add_child(m)
	m.closed.connect(func():
		cl.queue_free()
		settings_open = false
		_apply_shake()
		if paused:
			pause_ui.open())


# v5.8: Temblor de pantalla: Normal, Reducido o Apagado.
func _apply_shake() -> void:
	var lv: int = SV.shake_lv()
	shake_k = [1.0, 0.35, 0.0][lv]
	shake_on = lv == 0
	Actor.flash_k = 1.0 if shake_on else 0.35


func _go_menu() -> void:
	PG.off = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _finish_run() -> void:
	if run_saved:
		return
	run_saved = true
	var js: Dictionary = jd.summary()
	if not js.is_empty():
		var stt: Dictionary = SV.d["stats"]
		stt["judgeTime"] = maxi(int(stt.get("judgeTime", 0)), int(js["time"]))
		stt["judgeBosses"] = maxi(int(stt.get("judgeBosses", 0)), int(js["bosses"]))
	var own_ids := {}
	for mv0 in player.moves:
		own_ids[String(mv0["id"])] = true
	var ally_dmg := 0.0
	var ally_kills := 0
	for k0 in run_dmg:
		if k0 != "_other" and not own_ids.has(k0):
			ally_dmg += float(run_dmg[k0])
	for k1 in run_kills_by:
		if k1 != "_other" and not own_ids.has(k1):
			ally_kills += int(run_kills_by[k1])
	var mv_list: Array = []
	for mv in player.moves:
		mv_list.append({"id": String(mv["id"]), "name": String(mv["name"]), "lvl": int(mv["lvl"]), "evo": bool(mv["evolved"]),
			"dmg": int(run_dmg.get(String(mv["id"]), 0.0)), "kills": int(run_kills_by.get(String(mv["id"]), 0)),
			"desc": String(mv.get("desc", ""))})
	var item_list: Array = []
	for iid in [item, item2, item3]:
		if String(iid) != "":
			item_list.append(String(iid))
	if mode == "party":
		SV.last_run = {}
		PG.off = false
		return
	var extra := ""
	if mode == "daily":
		var dd: Dictionary = SV.d.get("daily", {})
		if int(dd.get("date", 0)) != SV.run_seed:
			dd = {"date": SV.run_seed, "best": 0}
		var prev_best: int = int(dd["best"])
		dd["best"] = maxi(prev_best, int(run_time))
		SV.d["daily"] = dd
		extra = " · " + L.t("Desafío diario") + ((" · " + L.t("¡Mejor marca de hoy!")) if int(run_time) > prev_best else "")
	elif mode == "rush":
		var rb: int = int(SV.d.get("rush_best", 0))
		SV.d["rush_best"] = maxi(rb, run_bosses)
		extra = " · " + L.t("Rush de Jefes: %d jefes") % run_bosses + ((" · " + L.t("¡Récord!")) if run_bosses > rb else "")
	var mul: float = 1.0 + 0.25 * float(mods.size()) if mode != "daily" else 1.25
	if _has_item("amuletcoin"):
		mul *= 1.5   # Moneda Amuleto: +50% de Pokemonedas al acabar la run
	mul *= 1.0 + _abn("coin")
	mul *= _treasure_k()   # Iman del Tesoro: solo el botin normal de fin de partida (no los premios unicos de los retos)
	if mode == "type":
		mul += 0.5
		extra = " · " + L.t("Supervivencia: %s") % L.t(String(MD.TYPE_NAME.get(SV.run_type, SV.run_type)))
	elif mode == "team":
		extra = " · " + L.t("Modo Equipo")
	elif mode == "tower":
		extra = " · " + L.t("Torre: piso %d") % tw_floor
		if not tw_log.is_empty():
			var bits: Array = []
			for en in tw_log.slice(maxi(0, tw_log.size() - 3)):
				bits.append("%d: %d s, -%d%%" % [int(en["f"]), int(en["s"]), int(en["p"])])
			extra += " · " + L.t("Jefes (piso: tiempo, vida perdida)") + " " + " | ".join(bits)
	elif mode == "coop":
		mul *= 0.8
		extra = " · " + L.t("Modo Cooperativo")
	elif mode == "rifts":
		mul += 0.25
		var rbest: int = int(SV.d.get("rifts_best", 0))
		SV.d["rifts_best"] = maxi(rbest, run_rifts)
		extra = " · " + L.t("Contrarreloj de grietas: %d") % run_rifts + ((" · " + L.t("¡Récord!")) if run_rifts > rbest else "")
	var st2: Dictionary = SV.d["stats"]
	var rmin: int = int(run_time / 60.0)
	if mode == "daily":
		st2["dailyPlays"] = int(st2.get("dailyPlays", 0)) + 1
		st2["dailyBestMin"] = maxi(int(st2.get("dailyBestMin", 0)), rmin)
	elif mode == "rifts":
		st2["riftsRuns"] = int(st2.get("riftsRuns", 0)) + 1
		st2["riftsBest"] = maxi(int(st2.get("riftsBest", 0)), run_rifts)
	elif mode == "type":
		st2["typeRuns"] = int(st2.get("typeRuns", 0)) + 1
		if rmin >= 10:
			var td: Dictionary = SV.d.get("type_done", {})
			td[SV.run_type] = true
			SV.d["type_done"] = td
		st2["typeBestMin"] = maxi(int(st2.get("typeBestMin", 0)), rmin)
	elif mode == "coop":
		st2["coopRuns"] = int(st2.get("coopRuns", 0)) + 1
		if run_time >= 60.0:
			st2["groupRuns"] = int(st2.get("groupRuns", 0)) + 1
	elif mode == "tower":
		st2["towerRuns"] = int(st2.get("towerRuns", 0)) + 1
	elif mode == "team":
		st2["teamRuns"] = int(st2.get("teamRuns", 0)) + 1
		st2["teamBestMin"] = maxi(int(st2.get("teamBestMin", 0)), rmin)
	elif mode == "rush":
		st2["rushRuns"] = int(st2.get("rushRuns", 0)) + 1
		st2["rushBest"] = maxi(int(st2.get("rushBest", 0)), run_bosses)
	if mode != "daily" and mode != "party":
		for k in range(1, mods.size() + 1):
			st2["mn%d" % k] = maxi(int(st2.get("mn%d" % k, 0)), rmin)
		for md_id in mods:
			st2["mb_" + String(md_id)] = maxi(int(st2.get("mb_" + String(md_id), 0)), rmin)
	SV.finish_run({"judge": js, "time": run_time, "kills": kills, "level": player.level, "bosses": run_bosses,
		"chests": run_chests, "coins": coins, "tickets": tickets, "tickets10": tickets10, "gcoins": gcoins_run, "gold_gcoins": gold_gcoins_run, "dex": SV.run_dex,
		"dead": player.dead and not timeup, "moves": mv_list, "items": item_list, "mul": mul, "extra": extra,
		"other_dmg": int(run_dmg.get("_other", 0.0)), "other_kills": int(run_kills_by.get("_other", 0)),
		"ally_dmg": int(ally_dmg), "ally_kills": ally_kills})
	PG.event("runEnd", {"time": run_time, "level": player.level, "coins": coins, "types": player.types, "group": false, "mode": mode, "nmods": (0 if mode == "daily" else mods.size()), "bosses": run_bosses, "rifts": run_rifts, "floor": tw_clears})
	PG.check()


func _abandon() -> void:
	_finish_run()
	_go_menu()


func _on_reroll() -> void:
	if rerolls <= 0:
		return
	var picks: Array = _offer()
	if picks.is_empty():
		return
	rerolls -= 1
	var heading: String = cards.title
	var head: String = cards.headline
	cards.show_cards(picks, heading, head, true)
	cards.age = cards.GRACE   # un cambio o un veto deliberado no vuelve a bloquear las cartas
	cards.rerolls = rerolls
	cards.bans = bans


func _on_ban(idx: int) -> void:
	if bans <= 0 or idx < 0 or idx >= cards.items.size():
		return
	banned[String(cards.items[idx]["id"])] = true
	bans -= 1
	var picks: Array = _offer()
	if picks.is_empty():
		return
	var heading: String = cards.title
	var head: String = cards.headline
	cards.show_cards(picks, heading, head, true)
	cards.age = cards.GRACE   # un cambio o un veto deliberado no vuelve a bloquear las cartas
	cards.rerolls = rerolls
	cards.bans = bans


# Rendimiento: reduce efectos visuales sin tocar el dano ni la jugabilidad. Se llama al empezar y al cambiarlo en vivo.
func apply_perf() -> void:
	perf_lv = clampi(int(SV.d["settings"].get("perf", 0)), 0, 2)
	quality = int(SV.setting("quality"))
	var qd: float = [1.0, 1.0, 0.65, 0.35][clampi(quality, 0, 3)] * [1.0, 0.6, 0.3][perf_lv]
	pfx.setup(qd)
	if ffx != null:
		ffx.lite = perf_lv
	if evfx != null:
		evfx.lite = perf_lv


func _fx_cap() -> int:
	if perf_lv > 0:
		return 60 if perf_lv == 1 else 24
	match quality:
		1:
			return 200
		2:
			return 60
		3:
			return 20
	return int(200.0 * q_auto) if q_auto > 0.2 else 20


func _process(delta: float) -> void:
	hud.paused = paused
	if not settings_open:
		var want_ui: bool = paused and not player.dead
		if want_ui != pause_ui.visible:
			if want_ui:
				pause_ui.open()
			else:
				pause_ui.close()
	if hud.toast_t > 0.0:
		hud.toast_t -= delta
	elif not PG.toasts.is_empty():
		var tt: Dictionary = PG.toasts.pop_front()
		hud.toast = {"text": L.t(String(tt["title"])) % L.t(String(tt["arg"])), "tier": int(tt["tier"]),
			"sub": (L.t(String(tt["sub"])) % String(tt["subarg"]) if String(tt["subarg"]) != "" else L.t(String(tt["sub"]))) if String(tt["sub"]) != "" else ""}
		hud.toast_t = 2.8
		Aud.sfx(String(tt.get("snd", "legend")))
	if quality == 0:
		# Auto: baja los efectos si el juego va a tirones.
		if Engine.get_frames_per_second() < 40 and run_time > 5.0:
			q_bad_t += delta
			if q_bad_t > 2.0:
				q_auto = maxf(0.1, q_auto * 0.6)
				q_bad_t = 0.0
		else:
			q_bad_t = 0.0
	# Carga de efectos (cualquier calidad): en partidas largas, si el FPS cae, evolucionados y fusiones se aligeran solos.
	var fps_now: float = Engine.get_frames_per_second()
	if fps_now < 45.0 and run_time > 5.0:
		fx_load = maxf(0.25, fx_load - delta * 0.6)
	elif fps_now > 55.0:
		fx_load = minf(1.0, fx_load + delta * 0.1)
	var fcap := _fx_cap()
	if fx.get_child_count() > fcap:
		var over: int = fx.get_child_count() - fcap
		for i in range(fx.get_child_count()):
			if over <= 0:
				break
			var ch: Node = fx.get_child(i)
			if ch is Fx and not ch.is_queued_for_deletion():
				ch.queue_free()
				over -= 1
	# S62.7: cuenta atras 3-2-1 al volver de una grieta (el mundo hostil queda en pausa, sin dejar time_scale alterado)
	if ret_cd > 0.0 and not paused and not player.dead:
		ret_cd -= delta
		player.invuln = maxf(player.invuln, 0.3)
		var rn: int = ceili(maxf(ret_cd, 0.0))
		if rn != ret_last and rn >= 1:
			ret_last = rn
			add_text(player.position + Vector2(0.0, -player.body_h - 34.0), str(rn), Color("#ffd23f"), 40)
			Aud.sfx("select")
	elif player.dead:
		ret_cd = 0.0
	# S59: redes de seguridad contra el "mundo congelado" (choosing/time_scale atascados sin que haya nada en pantalla).
	if choosing and not cards.open:
		choose_idle += delta
		if choose_idle > 1.0:
			choosing = false
			choose_idle = 0.0
			unfreeze_count += 1
			push_warning("S59 watchdog: choosing sin cartas visibles; liberado (%d)" % unfreeze_count)
	else:
		choose_idle = 0.0
	if not player.dead and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
		unfreeze_count += 1
		push_warning("S59 watchdog: time_scale restaurado (%d)" % unfreeze_count)
	if player.dead:
		death_t += delta
		# Game Over solo cuando la animacion de muerte termina completa (con tope de seguridad)
		if death_done_t < 0.0:
			var fa: bool = player.anim == "Faint" and player.frame >= (player._am("Faint")["d"] as Array).size() - 1
			if player.anim != "Faint" or fa or death_t > 6.0:
				death_done_t = 0.0
		else:
			death_done_t += delta
		if death_t >= DEATH_SLOW_T and Engine.time_scale != 1.0:
			Engine.time_scale = 1.0
		if not run_saved:
			_finish_run()
			Aud.music("")
			Aud.sfx("gameover")
	elif z_state == "cine" and not paused:
		_z_cine(delta)
	elif jd.cinematic() and not paused:
		jd.cine_tick(delta)
	elif not choosing and not paused and not shop_open and ret_cd <= 0.0:
		run_time += delta
		if mode == "chal":
			_ch_tick(delta)
		if mode == "rifts" and run_time >= RIFTS_LIMIT and arena == null and not timeup:
			timeup = true
			hud.timeup = true
			hud.rifts_n = run_rifts
			player.dead = true
			player.active = false
			_clear_orbit_orbs()
			for e in enemies:
				e.active = false
			Aud.sfx("bossDown")
		if _has_mod("nohealing"):
			if player.max_hp > nh_max:
				nh_last += player.max_hp - nh_max
				nh_max = player.max_hp
			if player.hp > nh_last:
				player.hp = nh_last
			else:
				nh_last = player.hp
		Aud.music(jd.music() if jd.active() else "rift" if arena != null else ("boss" if _boss_alive() else ["forest", "cave", "volcano"][biome_idx % 3]))
		if down:
			_update_down(delta)
		else:
			_update_player(delta)
		_update_partner(delta)
		_z_poll()
		_cooldowns(delta)
		_adapt(delta)
		if z_state == "fx":
			_z_fx(delta)
		if dyn != null:
			dyn_flash += delta
			if player.dead or down:
				dyn.stop()
			elif dyn.active:
				dyn.tick(delta)
		if arena == null:
			_update_world(delta)
			_update_biome()
			_update_spawner(delta)
			_update_rift(delta)
			poi.update(delta)
			kec.update(delta)
			rescue.update(delta)
			alpha.update(delta)
			hz.update(delta)
			cave.update(delta)
			inv.update(delta)
			meteor.update(delta)
			mew.update(delta)
			sec.update(delta)
			jd.update(delta)
			if run_time >= JDM.ARC_AT and not jd.done and pending_levels == 0 and mode != "rush" and mode != "tower":
				jd.begin()
		else:
			_update_arena(delta)
			if bool(ainfo.get("cave", false)):
				if String(ainfo.get("owner", "cave")) == "lab":
					mew.update_inside(delta)
				else:
					cave.update_inside(delta)
			if jd.active():
				jd.update(delta)
		dn.update(delta)
		_update_weather(delta)
		_update_enemies(delta)
		_update_hazards(delta)
		_update_ebullets(delta)
		_update_fields(delta)
		ffx.step(delta)
		evfx.step(delta)
		_upd_pats(delta)
		_upd_legend(delta)
		_sample_dmg(delta)
		_update_bullets(delta)
		_update_orbs(delta)
		_cleanup_enemies()
		# v6.1: ninguna eleccion interrumpe un Movimiento Z: las subidas de nivel y objetos esperan a que termine
		if z_state != "":
			pass
		elif pending_levels > 0 and not choosing:
			_open_cards()
		elif pending_items > 0 and not choosing:
			pending_items -= 1
			_offer_item()
		elif _fuse_ready() and not choosing:
			_do_fuse()
		elif bonds > 0 and not choosing and (arena == null or _arena_bond_ready()):
			_offer_bond(true)
	ground.center = player.position
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * shake_k
	shake = maxf(0.0, shake - 30.0 * delta)
	hud.hp = player.hp
	hud.revives = revives
	hud.z_dim = _z_dim()
	hud.z_state = z_state
	hud.z_t = z_t
	hud.join_t = join_t
	hud.join_name = join_name
	hud.join_col = join_col
	hud.z_name = L.t(String(ZM.DEF[z_type]["name"])) if z_type != "" else ""
	hud.z_type = z_type
	hud.z_btn = 0 if (mode == "tower" or z_type == "" or z_state != "") else (3 if z_used else (2 if run_time >= ZM.MIN_TIME else 0))
	hud.z_cd = z_cd
	hud.adapt_pct = roundi(adapt_k * 100.0) if _adapt_on() else 0
	hud.dyn_left = maxf(0.0, dyn.t) if _dyn_on() else -1.0
	hud.dyn_flash = dyn_flash if dyn != null else 99.0
	hud.dyn_type = String(player.types[0])
	hud.dyn_btn = 0 if (mode == "tower" or not DYN.unlocked(SV.d["stats"]) or _dyn_on()) else (3 if dyn_used else (2 if run_time >= DYN.MIN_TIME else 0))
	hud.dyn_cd = dyn_cd
	hud.ab_name = L.t(String(AB.FX[AB.of(_pdex())]["name"]))
	hud.show_stats = bool(SV.setting("stats_box"))
	if hud.show_stats:
		hud.stats = [
			[L.t("Daño"), "%d%%" % roundi(_atk() / maxf(0.001, base_atk) * 100.0)],
			[L.t("Velocidad"), "%d" % roundi(_spd())],
			[L.t("Recarga"), "%d%%" % roundi(100.0 / maxf(0.05, _cd_mul_raw()))],
			[L.t("Defensa"), "%d%%" % roundi(_reduction() * 100.0)],
			[L.t("Regeneración"), "%.1f/s" % _regen()],
			[L.t("Imán"), "%d" % roundi(_magnet())],
		]
	hud.max_hp = player.max_hp
	if mode == "team" and not paused:
		_team_tick(delta)
	hud.run_time = run_time
	hud.kills = kills
	hud.dead = player.dead
	hud.down = down
	hud.down_left = maxf(0.0, DOWN_REVIVE_T - down_t)
	hud.pbar = clampf(partner_hp / maxf(1.0, partner_max), 0.0, 1.0)
	hud.limit = RIFTS_LIMIT if mode == "rifts" else (CH.CH_TIME if mode == "chal" else 0.0)
	hud.ch_mode = mode == "chal"
	hud.tower_floor = tw_floor if mode == "tower" else 0
	hud.tower_risk = tw_risk.size()
	hud.reap_pct = 0.3 * float(reap_kills) if tw_risk.has("l_reap") else -1.0
	hud.tower_t = (TOWER_BOSS_AT - tw_t) if (mode == "tower" and tw_boss == null) else -1.0
	hud.rifts_n = run_rifts
	hud.death_t = _death_clock()
	hud.show_end = player.dead and _death_clock() > 1.3
	hud.level = player.level
	hud.xp = player.xp
	hud.xp_next = player.xp_next
	hud.buff_text = (_buff_text() + "  " + _power_text()).strip_edges()
	hud.power_id = power_kind
	_items_hud_t -= delta
	if _items_hud_t <= 0.0:
		_items_hud_t = 0.2
		hud.items_hud = _build_items_hud()
		hud.portrait = _sum_sprite()
	hud.item_name = _item_name()
	hud.item_id = item
	hud.item2_name = _item_name_of(item2)
	hud.item2_id = item2
	hud.item3_name = _item_name_of(item3)
	hud.item3_id = item3
	hud.weather_text = _weather_text()
	hud.banner = banner_text if banner_t > 0.0 else _weather_banner()
	hud.fusion_t = fusion_t
	hud.fusion_name = fusion_name
	hud.coins = coins
	hud.balls = balls
	hud.tickets = tickets
	hud.tickets10 = tickets10
	_update_rift_hud()
	_update_thief_hud()
	wx.kind = wx_kind
	wx.level = _wx_level()
	_refresh_slots()


func _refresh_slots() -> void:
	VFX.shiny_on = bool(player.shiny)   # v5.8: los ataques de un Pokemon shiny usan otra paleta
	var info: Array = []
	var sl: Array = _slot_list()
	for g in sl:
		var m: Dictionary = g[0]
		var cdm: float = maxf(0.05, _f(m, "cd") * _cd_mul())
		info.append({
			"name": String(m["name"]),
			"color": _col(m),
			"lvl": int(m["lvl"]),
			"max": _max_lvl(m),
			"frac": clampf(1.0 - maxf(0.0, _f(m, "t")) / cdm, 0.0, 1.0),
			"evo": bool(m["evolved"]),
			"icon": ("evo:" if bool(m["evolved"]) else "move:") + String(m.get("recipe", m["id"])),
			"n": g.size(),
		})
	slots.info = info
	slots.active = player.slot
	slots.enabled = not choosing and not player.dead and not down


# ---------------------------------------------------------------
# Estadisticas de la run (levelup.js / player.js)
# ---------------------------------------------------------------
func _lv(id: String) -> int:
	return int(stat_lv.get(id, 0))


func _buff_mul(stat: String) -> float:
	var b: Dictionary = player.buffs[stat]
	return float(b["n"]) * float(b["amount"])


func _has_item(id: String) -> bool:
	return item == id or (item2 != "" and item2 == id) or (item3 != "" and item3 == id)


var _items_hud_t := 0.0


# Cooldown real de los objetos activos (Seccion 41): [restante, total]; null si el objeto no tiene recarga.
func _item_cd(id: String) -> Variant:
	if id == "sitrusberry":
		return [maxf(0.0, 90.0 - (run_time - sitrus_t)), 90.0, false]
	if id == "focussash":
		return [maxf(0.0, 60.0 - (run_time - sash_t)), 60.0, false]
	if id == "weaknesspolicy":
		return [wp_t, 8.0, true]   # efecto activo: muestra el tiempo que le queda
	return null


# Caja compacta del HUD (Seccion 39): objetos equipados y mejoras con nivel; si hay mas de 4 se pagina sola.
func _build_items_hud() -> Array:
	var out: Array = []
	for id in [item, item2, item3]:
		if String(id) == "":
			continue
		var e := {"icon": String(id), "name": _item_name_of(String(id)), "lv": 0, "cd": -1.0, "cdmax": 0.0}
		var c = _item_cd(String(id))
		if c != null:
			e["cd"] = float(c[0])
			e["cdmax"] = float(c[1])
			e["act"] = bool(c[2])
		out.append(e)
	var ups: Array = []
	for sid in STAT_IDS:
		var lv: int = int(stat_lv.get(sid, 0))
		if lv > 0:
			ups.append({"icon": String(STAT_ICON[sid]), "name": String(STATS[sid]["title"]), "lv": lv, "cd": -1.0, "cdmax": 0.0})
	ups.sort_custom(func(a, b): return int(a["lv"]) > int(b["lv"]))
	out.append_array(ups)
	return out


func _item_name_of(id: String) -> String:
	if id == "":
		return ""
	for it in TD.ITEMS:
		if String(it["id"]) == id:
			return String(it["name"])
	return ""


func _item_name() -> String:
	return _item_name_of(item)


# Producto del efecto `key` de todas las cartas de riesgo tomadas (1.0 si no hay).
func _rk(key: String) -> float:
	var v := 1.0
	for rid in tw_risk:
		for r in _all_risks():
			if String(r["id"]) == String(rid) and (r["fx"] as Dictionary).has(key):
				v *= float(r["fx"][key])
	return v


func _rk_add(key: String) -> float:
	var v := 0.0
	for rid in tw_risk:
		for r in _all_risks():
			if String(r["id"]) == String(rid) and (r["fx"] as Dictionary).has(key):
				v += float(r["fx"][key])
	return v


# ---- Movimiento Z ----
# Dificultad adaptativa (solo partida normal): empieza facil (mas aun para jugadores nuevos) y sube con tus mejoras.
# Mide tu poder (mejoras de la partida + nivel + mejoras permanentes) y mueve vida, dano, spawn, hordas y experiencia necesaria.
func _adapt_on() -> bool:
	return mode == "normal" and bool(SV.d["settings"].get("adaptive", true)) and arena == null


func _power() -> float:
	var ru := 0.0
	for k in stat_lv:
		ru += float(stat_lv[k])
	for mv in player.moves:
		ru += float(mv["lvl"]) + (3.0 if bool(mv["evolved"]) else 0.0)
	return ru + float(player.level) * 0.5


# Base segun las mejoras permanentes del Pokemon elegido (uno nuevo = facil) + empuje por lo que mejoras en la partida.
func _adapt_target() -> float:
	var perm: float = float(SV.up_total(SV.run_dex))
	var pb: float = clampf(perm / 40.0, 0.0, 1.0)
	pb = pb * pb * (3.0 - 2.0 * pb)
	var x: float = clampf(_power() / 70.0, 0.0, 1.0)
	x = x * x * (3.0 - 2.0 * x)
	var k: float = 0.62 + 0.38 * pb + (0.2 + 0.3 * pb) * x
	var runs: int = int(SV.d["stats"].get("runs", 0))
	if runs < 8:
		k *= lerpf(0.9, 1.0, float(runs) / 8.0)
	return clampf(k + adapt_adj, 0.55, 1.5)


func _adapt(delta: float) -> void:
	if not _adapt_on():
		adapt_k = 1.0
		return
	if adapt_prev_hp >= 0.0 and player.hp < adapt_prev_hp:
		adapt_taken += adapt_prev_hp - player.hp
	adapt_prev_hp = player.hp
	if run_time >= adapt_next:
		adapt_next = run_time + 45.0
		if _boss_alive():
			adapt_taken = 0.0
		else:
			var frac: float = adapt_taken / maxf(1.0, player.max_hp)
			var low: bool = player.hp < player.max_hp * 0.3
			adapt_taken = 0.0
			if frac > 0.5 or low:
				adapt_adj -= 0.05     # sufres demasiado: un respiro
			elif frac < 0.08:
				adapt_adj += 0.03
			adapt_adj = clampf(adapt_adj, -0.2, 0.1)
	var tk: float = _adapt_target()
	if delta <= 0.0:
		adapt_k = tk
	else:
		adapt_k = move_toward(adapt_k, tk, 0.03 * delta)


func _adapt_k() -> float:
	return adapt_k if _adapt_on() else 1.0


func _xp_need(level: int) -> float:
	return float(_xp_for(level)) * pow(_adapt_k(), 0.8)


# Enfriamiento de Z y Dynamax: cuenta desde que terminan; las guaridas Dynamax recargan el Dynamax al instante.
func _cooldowns(delta: float) -> void:
	if z_used and z_state == "" and z_cd > 0.0:
		z_cd -= delta
		if z_cd <= 0.0:
			z_cd = 0.0
			z_used = false
			add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("¡Movimiento Z listo!"), Color("#ffd23f"), 18)
	if dyn_used and not _dyn_on() and dyn_cd > 0.0:
		dyn_cd -= delta
		if dyn_cd <= 0.0:
			dyn_cd = 0.0
			dyn_used = false
			add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("¡Dynamax listo!"), Color("#ff5a8a"), 18)


func _z_can() -> bool:
	return mode != "tower" and z_type != "" and not z_used and z_state == "" and run_time >= ZM.MIN_TIME and not player.dead and not down and not paused and not choosing and arena == null and not jd.active() and not timeup


# Gatillo derecho del mando (ademas del boton configurable).
func _z_poll() -> void:
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	var on: bool = Input.get_joy_axis(int(pads[0]), JOY_AXIS_TRIGGER_RIGHT) > 0.7
	if on and not z_rt_down and _z_can():
		_z_start()
	z_rt_down = on
	var lt: bool = Input.get_joy_axis(int(pads[0]), JOY_AXIS_TRIGGER_LEFT) > 0.7
	if lt and not dyn_lt_down and _dyn_can():
		_dyn_start()
	dyn_lt_down = lt


# ---- Dynamax ----
func _dyn_on() -> bool:
	return dyn != null and bool(dyn.active)


func _dyn_can() -> bool:
	return mode != "tower" and DYN.unlocked(SV.d["stats"]) and not dyn_used and not _dyn_on() and z_state != "cine" and run_time >= DYN.MIN_TIME and not player.dead and not down and not paused and not choosing and not jd.active() and not timeup


func _dyn_start() -> void:
	dyn_used = true
	dyn = DYN.new()
	dyn.start(self)
	dyn_flash = 0.0
	Aud.sfx("legend")


func _dyn_stop() -> void:
	if dyn != null:
		dyn.stop()


func _z_start() -> void:
	z_used = true
	z_state = "cine"
	z_t = 0.0
	player.invuln = 5.0
	Aud.sfx("legend")
	_ring(player.position, 10.0, 220.0, Color.html(String(MD.TYPE_COLOR.get(z_type, "#ffffff"))), 0.8)
	player.attack_face = 1.5


func _z_cine(delta: float) -> void:
	z_t += delta
	player.invuln = 5.0
	if z_t < 0.7:
		shake = maxf(shake, 3.0)
	if z_t >= ZM.CINE_T:
		z_state = "fx"
		z_t = 0.0
		zfx = ZM.new()
		zfx.start(self, z_type)
		Aud.sfx("bossDown")


func _z_fx(delta: float) -> void:
	z_t += delta
	if zfx == null or bool(zfx.done):
		z_state = ""
		zfx = null
		z_cd = ZM.COOLDOWN
		return
	zfx.tick(delta)


func _z_dim() -> float:
	if z_state == "cine":
		return clampf(z_t / 0.3, 0.0, 1.0) * 0.62
	if z_state == "fx":
		var base: float = clampf(1.0 - z_t / 0.9, 0.0, 1.0) * 0.62
		return maxf(base, float(zfx.dim)) if zfx != null else base
	return 0.0


func _abn(key: String) -> float:
	return float(ab_fx.get(key, 0.0))


func _moxie() -> float:
	var st: float = _abn("moxie")
	if st <= 0.0:
		return 0.0
	return minf(_abn("moxie_cap"), floorf(float(kills) / 40.0) * st)


func _ab_wspd() -> float:
	if ab_fx.has("wspd") and wx_kind == String(ab_fx["wspd"]) and _wx_level() > 0.5:
		return _abn("wspd_k")
	return 0.0


func _atk() -> float:
	var k: float = 1.0
	if _has_item("choiceband"):
		k *= 1.4
	if _has_item("lifeorb"):
		k *= 1.3   # antes, con las dos a la vez (Doble equipaje) la Vidasfera no sumaba daño pero seguía quitando vida
	return base_atk * pow(1.10, float(_lv("atk"))) * (1.0 + _buff_mul("atk")) * k * (1.5 if _pw("fury") else 1.0) * (1.5 if wp_t > 0.0 else 1.0) * _rk("atk") * (1.0 + 0.003 * float(reap_kills)) * (1.0 + _abn("dmg") + _moxie() + (_abn("defiant") if defiant_t > 0.0 else 0.0)) * (DYN.DMG_K if _dyn_on() else 1.0)


func _spd() -> float:
	if mode == "chal" and _ch_rs("no_move"):
		return 0.0
	var k: float = (1.35 if _has_item("choicescarf") else 1.0) * (1.1 if _has_item("ti_flying") else 1.0)
	return base_spd * pow(1.07, float(_lv("spd"))) * (1.0 + _buff_mul("spd")) * k * (1.4 if _pw("haste") else 1.0) * (0.8 if _has_mod("slow") else 1.0) * _rk("spd") * (1.0 + _abn("spd") + _ab_wspd()) * (DYN.STAT_K if _dyn_on() else 1.0) * (kec.spd_mul() if kec != null else 1.0)


func _cd_mul() -> float:
	return CD_K * _cd_mul_raw()


func _cd_mul_raw() -> float:
	var k: float = 0.8 if _has_item("quickclaw") else 1.0
	return pow(0.92, float(_lv("cd"))) * k * float(perks["cd"]) * (0.65 if _pw("frenzy") else 1.0) * _rk("cd") * (1.0 - _abn("cd")) / (DYN.STAT_K if _dyn_on() else 1.0) * (kec.cd_mul() if kec != null else 1.0)


func _reduction() -> float:
	var vest: float = (0.2 if _has_item("assaultvest") else 0.0) + (0.08 if _has_item("ti_rock") else 0.0)
	return minf(0.8, minf(0.7, 0.06 * float(_lv("def"))) + vest + float(perks["def"]) + _buff_mul("def") + _rk_add("def") + _abn("taken") + (kec.def_add() if kec != null else 0.0) + (0.4 if _pw("aegis") else 0.0) + (DYN.TAKEN if _dyn_on() else 0.0))


func _regen() -> float:
	var left: float = player.max_hp * 0.015 if _has_item("leftovers") else 0.0
	return 0.9 * float(_lv("rgn")) + float(perks["regen"]) + _buff_mul("regen") + left + (1.0 if _has_item("ti_grass") else 0.0) + player.max_hp * _abn("regen") + _rk_add("regen")


func _magnet() -> float:
	return BASE_MAGNET * pow(1.30, float(_lv("mag"))) * float(perks["magnet"]) * (1.0 + _abn("magnet")) * (kec.mag_mul() if kec != null else 1.0)


func _xp_mul() -> float:
	var k: float = 1.3 if _has_item("luckyegg") else 1.0
	return pow(1.12, float(_lv("xp"))) * k * (1.5 if _has_mod("brainy") else 1.0) * float(perks["xp"]) * _rk("xp") * (1.0 + _abn("xp")) * (kec.xp_mul() if kec != null else 1.0)


func _buff_text() -> String:
	var parts: Array = []
	var names := {"atk": "ATQ", "spd": "VEL", "def": "DEF", "regen": "REG"}
	for k in names:
		var b: Dictionary = player.buffs[k]
		if int(b["n"]) > 0:
			parts.append("%s x%d" % [L.t(String(names[k])), int(b["n"])])
	return "  ".join(parts)


# ---------------------------------------------------------------
# Movimientos: instancias, mejoras y evolucion (moves.js)
# ---------------------------------------------------------------
# Multiplicador de tamano: mejora permanente Calibre x carta Calibre x objeto Esfera Colosal.
func _size_k() -> float:
	return float(perks.get("size", 1.0)) * pow(1.12, float(_lv("size"))) * (1.3 if _has_item("bigorb") else 1.0) * (kec.range_mul() if kec != null else 1.0)


const SIZE_AREA := ["aura", "melee", "mine", "meteor", "cone", "chain", "trail", "beam", "boomerang", "dash"]


func _f(m: Dictionary, key: String, def: float = 0.0) -> float:
	var v: float = float(m.get(key, def))
	if key == "burn" and v > 0.0 and m.has("burnp") and randf() >= float(m["burnp"]):
		return 0.0   # quemadura con probabilidad (p. ej. Escaldar, como en los juegos)
	if key == "knock" and MD.KNOCK_LV.has(String(m.get("id", ""))):
		var kl: int = int(m.get("lvl", 1))
		var kv: float = float(MD.KNOCK_BASE.get(String(m["id"]), 0.0)) if kl < 2 else float(MD.KNOCK_LV[String(m["id"])]) * (1.0 + 0.5 * float(kl - 2)) + v
		return kv * (1.5 if bool(m.get("evolved", false)) else 1.0)   # la evolucion empuja un 50% mas
	if key == "radius":
		if item == "widelens" or item2 == "widelens" or item3 == "widelens":
			v *= 1.2   # Lente Amplia
		if String(m.get("type", "")) == "ground" and _has_item("ti_ground"):
			v *= 1.2   # Arena Fina
		# El tamano tambien agranda las areas: escudos y auras, golpes, minas, meteoros y conos (los orbes, la mitad)
		var kd: String = String(m.get("kind", ""))
		if SIZE_AREA.has(kd):
			v *= _size_k()
		elif kd == "orbit":
			v *= 1.0 + (_size_k() - 1.0) * 0.5
	elif key == "size" or key == "width":
		v *= _size_k()   # proyectiles, orbes, bumeranes y rayos
	elif key == "count":
		var kc: String = String(m.get("kind", ""))
		if kc == "projectile" or kc == "cone" or kc == "boomerang":
			v = minf(v + float(_mult_extra()), 16.0)   # Multiplicador (con tope por rendimiento)
	elif key == "pierce":
		var kp: String = String(m.get("kind", ""))
		if kp == "projectile" or kp == "cone" or kp == "nova":
			v += float(_pierce_extra())   # Fuerza Perforante
	return v


# ---------------------------------------------------------------
# Objetos mejorables nuevos (Secciones 42-49): rendimientos decrecientes, sin tope de nivel.
# dim(lv, primero, tope) = tope * (1 - e^(-lv * primero / tope)): el primer nivel da ~"primero" y nunca pasa de "tope".
# ---------------------------------------------------------------
static func _dim(lv: int, first: float, cap: float) -> float:
	if lv <= 0:
		return 0.0
	return cap * (1.0 - exp(-float(lv) * first / cap))


func _mult_extra() -> int:
	return int(_dim(_lv("mult"), 0.6, 5.0) + 0.5)


func _pierce_extra() -> int:
	return int(_dim(_lv("pierce"), 0.7, 6.0) + 0.5)


func _amp_k() -> float:
	return 1.0 + _dim(_lv("amp"), 0.12, 0.8)


func _lens_add() -> float:
	var lv: int = _lv("lens")
	if lv <= 3:
		return 0.03 * float(lv)
	return 0.09 + _dim(lv - 3, 0.03, 0.21)   # tope total 30 %


func _fang_pct() -> float:
	var lv: int = _lv("fang")
	if lv <= 3:
		return 0.04 * float(lv)
	return 0.12 + _dim(lv - 3, 0.04, 0.13)   # tope total 25 %


func _edge_mul() -> float:
	return 1.5 + _dim(_lv("edge"), 0.12, 1.5)   # critico base x1,5; tope x3


func _dstrike_p() -> float:
	return _dim(_lv("dstrike"), 0.06, 0.45)


func _treasure_k() -> float:
	return 1.0 + _dim(_lv("trs"), 0.08, 1.0)


# Cura real (sin sobrecuracion). Devuelve lo recuperado.
func _heal_real(amount: float) -> float:
	if amount <= 0.0 or player.dead:
		return 0.0
	var before: float = player.hp
	player.hp = minf(player.max_hp, player.hp + amount)
	return player.hp - before


# Pokemon que lleva el jugador ahora (en Modo Equipo cambia al cambiar de Pokemon).
func _pdex() -> int:
	if mode == "team" and not team.is_empty():
		return int(team[team_cur]["dex"])
	return int(SV.run_dex)


# Los objetos exclusivos de especie solo salen a quien puede usarlos.
func _item_ok_for(id: String) -> bool:
	var dx: int = _pdex()
	if id == "lightball":
		return [172, 25, 26].has(dx)
	if id == "thickclub":
		return [104, 105].has(dx)
	for it in TD.ITEMS:
		if String(it["id"]) == id and it.has("tp"):
			return (player.types as Array).has(String(it["tp"]))   # objetos de tipo: solo para Pokemon de ese tipo
	return true


func _col(m: Dictionary) -> Color:
	var c := Color.html(String(MD.TYPE_COLOR[String(m["type"])]))
	return VFX.shiny_col(String(m["type"]), c) if VFX.shiny_on else c


func _apply_mods(m: Dictionary, mods: Dictionary) -> void:
	for k in mods:
		if MULT_KEYS.has(k) and m.has(k):
			m[k] = float(m[k]) * float(mods[k])
		elif ADD_KEYS.has(k):
			m[k] = float(m.get(k, 0)) + float(mods[k])
		else:
			m[k] = mods[k]


func _new_move(id: String, lvl: int) -> Dictionary:
	var def: Dictionary = MD.MOVES[id]
	var m: Dictionary = def.duplicate(true)
	m["lvl"] = 1
	m["t"] = 0.0
	m["evolved"] = false
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	for i in range(lvl - 1):
		_apply_mods(m, ladder[i]["m"])
		m["lvl"] = int(m["lvl"]) + 1
	return m


func _max_lvl(m: Dictionary) -> int:
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	return ladder.size() + 1


func _level_up_move(m: Dictionary) -> void:
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	var lv: int = int(m["lvl"])
	if lv >= _max_lvl(m):
		return
	_apply_mods(m, ladder[lv - 1]["m"])
	m["lvl"] = lv + 1


# Devuelve {} si no puede evolucionar todavia.
func _evo_info(m: Dictionary) -> Dictionary:
	var l: Array = _evo_infos(m)
	if l.is_empty():
		return {}
	for e in l:
		if bool(e["ready"]):
			return e
	return l[0]


# Todas las evoluciones posibles del movimiento (la normal y, si la tiene, la alternativa de EVO_ALT).
# v5.8: evoluciones que cambian del todo la forma de atacar
const EVO_TEXT := {"dragon-rage": "Cae una lluvia de 3 meteoros dracónicos enormes que explotan en área.", "toxic-spikes": "Escopetazo de ácido: dispara en abanico una ráfaga de perdigones venenosos.", "powder-snow": "Viento helado constante hacia donde apuntas: daña, frena y congela sin parar.", "karate-chop": "Ráfaga constante de puños y palmas de kárate que solo golpea lo que tienes delante."}


func _evo_infos(m: Dictionary) -> Array:
	var id: String = String(m["id"])
	var kind: String = String(m["kind"])
	var out: Array = []
	if bool(m["evolved"]) or int(m["lvl"]) < _max_lvl(m):
		return out
	if MD.EVO.has(id) and MD.EVO_MODS.has(kind):
		var e: Array = MD.EVO[id]
		var needs: String = String(e[1])
		out.append({"name": String(e[0]), "needs": needs, "need_name": String(MD.NEED_NAME[needs]), "text": String(MD.EVO_MODS[kind]["t"]) + (L.t(" · %d%% de probabilidad de quemar") % roundi(float(MD.EVO_EXTRA[id]["burnp"]) * 100.0) if MD.EVO_EXTRA.has(id) and MD.EVO_EXTRA[id].has("burnp") else ""),
			"ready": true, "alt": false})
		if EVO_TEXT.has(id):
			out[-1]["text"] = L.t(String(EVO_TEXT[id]))
	if MD.EVO_ALT.has(id):
		var a: Array = MD.EVO_ALT[id]
		var n2: String = String(a[1])
		out.append({"name": String(a[0]), "needs": n2, "need_name": String(MD.NEED_NAME[n2]), "text": String(a[2]), "ready": true, "alt": true})
	return out


func _evolve(m: Dictionary, alt: bool = false) -> void:
	var id: String = String(m["id"])
	if bool(m["evolved"]):
		return
	if _ch_on():
		ch_m["evolves"] = int(ch_m["evolves"]) + 1
	if alt and MD.EVO_ALT.has(id):
		var a: Array = MD.EVO_ALT[id]
		_apply_mods(m, a[3])
		m["name"] = String(a[0])
		m["alt"] = true
	else:
		if not MD.EVO.has(id):
			return
		var e: Array = MD.EVO[id]
		_apply_mods(m, MD.EVO_MODS[String(m["kind"])]["m"])
		if MD.EVO_EXTRA.has(id):
			_apply_mods(m, MD.EVO_EXTRA[id])
		m["name"] = String(e[0])
	m["evolved"] = true
	PG.event("evolve", {"move": String(m["id"])})
	_ring(player.position, 8.0, 120.0, Color("#ffd23f"), 0.8)
	evfx.evolve_burst(m)
	shake = 6.0


func _set_active(i: int) -> void:
	var sl: Array = _slot_list()
	if i < 0 or i >= sl.size() or i == player.slot:
		return
	if _has_item("choiceband"):
		add_text(player.position + Vector2(0.0, -player.body_h - 8.0), L.t("Cinta Elección"), Color("#ff8ad8"))
		return
	_clear_orbit_orbs()
	player.slot = i
	for m in sl[i]:
		m["t"] = minf(_f(m, "t"), _f(m, "cd") * 0.35)
	_ring(player.position, 6.0, player.radius * 3.4, _col(sl[i][0]), 0.3)


func _clear_orbit_orbs() -> void:
	for i in range(bullets.size() - 1, -1, -1):
		if bullets[i].orb:
			bullets[i].queue_free()
			bullets.remove_at(i)


# ---------------------------------------------------------------
# Jugador
# ---------------------------------------------------------------
func _update_player(delta: float) -> void:
	if arena_down:
		return
	var v: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v == Vector2.ZERO and stick.axis.length() > 0.15:
		v = stick.axis
	if v.length() > 1.0:
		v = v.normalized()
	var moving: bool = v.length() > 0.05
	var spd: float = (JDM.cap_spd(_spd()) if jd.phase == "fight" else _spd()) * _player_terrain(delta) * (0.55 if trap_slow_t > 0.0 else 1.0)
	if root_t > 0.0:
		root_t -= delta
		spd = 0.0
	if trap_freeze_t > 0.0:
		spd = 0.0
	elif trap_para_t > 0.0:
		spd *= 0.4
	elif trap_sleep_t > 0.0:
		spd *= 0.5
	if trap_conf_t > 0.0:
		v = -v
	var old_pos: Vector2 = player.position
	player.position += v * spd * delta
	player.position = _collide(player.position, player.radius * 0.55)
	player_vel = (player.position - old_pos) / maxf(delta, 0.0001)
	player.invuln = maxf(0.0, player.invuln - delta)
	defiant_t = maxf(0.0, defiant_t - delta)
	if bell_heal > 0.0:
		var bh: float = minf(bell_heal, 4.0 * delta)
		player.hp = minf(player.max_hp, player.hp + bh)
		bell_heal -= bh
	var reg: float = _regen()
	if reg > 0.0:
		player.hp = minf(player.max_hp, player.hp + reg * delta)
	player.attack_face = maxf(0.0, player.attack_face - delta)
	# Los potenciadores caducan.
	# Cada acumulacion tiene su propio temporizador: caducan de una en una, no todas a la vez.
	for k in player.buffs:
		var b: Dictionary = player.buffs[k]
		var ts: Array = b["ts"]
		if not ts.is_empty():
			for i in range(ts.size() - 1, -1, -1):
				ts[i] = float(ts[i]) - delta
				if float(ts[i]) <= 0.0:
					ts.remove_at(i)
			b["n"] = ts.size()

	target = _nearest_enemy(player.position, AIM_REACH)
	if target != null:
		player.aim = (target.position - player.position).angle()
	elif moving:
		player.aim = v.angle()
	aim_manual = false
	if bool(SV.d["settings"].get("manual_aim", false)) and not player.dead:
		var ma: Vector2 = _manual_aim_vec()
		if ma != Vector2.ZERO:
			aim_manual = true
			aim_ang = ma.angle()
			player.aim = aim_ang

	var face: float = player.aim
	if moving and player.attack_face <= 0.0:
		face = v.angle()
	player.face_angle(face)
	if moving:
		player.loop_anim("Walk", spd / 110.0)
	else:
		player.loop_anim("Idle", 1.0)

	for m in _active_group():
		if moving and String(m["id"]) == "flame-wheel":
			# Rastro de fuego de Rueda Fuego: llamas y chispas tras el jugador mientras corre.
			for k in range(2):
				pfx.trail("flame", "fire", player.position + Vector2(randf_range(-6.0, 6.0), -8.0), v)
			pfx.trail("ember", "fire", player.position + Vector2(0.0, -14.0), v)
		_tick_move(m, delta)


func coop_dex() -> int:
	var d: int = int(SV.d.get("coop_dex", 0))
	if d > 0 and _dex_by.has(d):
		return d
	for x in SV.team_list():
		if int(x) != SV.run_dex:
			return int(x)
	return 133 if SV.run_dex != 133 else 25


func _partner_move_for(dex: int, lvl: int) -> Dictionary:
	var ty: String = String((_dex_by[dex]["types"] as Array)[0]) if not (_dex_by[dex]["types"] as Array).is_empty() else "normal"
	var pick := ""
	for mid in MD.ORDER:
		var md: Dictionary = MD.MOVES[mid]
		if String(md["kind"]) == "projectile" and String(md["type"]) == ty:
			pick = mid
			break
	if pick == "":
		for mid in MD.ORDER:
			var md2: Dictionary = MD.MOVES[mid]
			if String(md2["kind"]) == "projectile" and String(md2["type"]) == "normal":
				pick = mid
				break
	if pick == "":
		pick = "ember"
	return _new_move(pick, lvl)


func _setup_partner() -> void:
	var dx: int = coop_dex()
	partner = Player.new()
	partner.setup(dx, _sm(dx), flash_shader)
	partner.modulate = Color(0.85, 0.95, 1.0)
	partner.types = (_dex_by[dx]["types"] as Array).duplicate()
	partner.position = player.position + Vector2(60.0, 20.0)
	world.add_child(partner)
	partner_lvl = 0
	var pads: Array = Input.get_connected_joypads()
	partner_pad = int(pads[1]) if pads.size() >= 2 else -1
	_bind_move_devices(int(pads[0]) if pads.size() >= 2 else -1)


func _update_partner(delta: float) -> void:
	if partner == null:
		return
	partner.visible = arena == null and not player.dead
	if arena != null or player.dead:
		return
	var pads: Array = Input.get_connected_joypads()
	var np: int = int(pads[1]) if pads.size() >= 2 else -1
	if np != partner_pad:
		_bind_move_devices(int(pads[0]) if pads.size() >= 2 else -1)
	partner_pad = np
	var v := Vector2.ZERO
	if partner_pad >= 0:
		v = Vector2(Input.get_joy_axis(partner_pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(partner_pad, JOY_AXIS_LEFT_Y))
		if v.length() < 0.22:
			v = Vector2.ZERO
	else:
		# IA: te sigue a distancia y se acerca un poco a los enemigos
		var to_p: Vector2 = player.position - partner.position
		var want: Vector2 = Vector2.ZERO
		var near: Node2D = _nearest_enemy(partner.position, 240.0)
		if down:
			# Sin ti cerca: huye de los enemigos mientras dispara
			var close: Node2D = _nearest_enemy(partner.position, 190.0)
			if close != null:
				want = (partner.position - close.position).normalized()
		elif to_p.length() > 150.0:
			want = to_p.normalized()
		elif near != null and to_p.length() < 120.0:
			want = (near.position - partner.position).normalized() * 0.5
		partner_dir = partner_dir.lerp(want, minf(1.0, delta * 5.0))
		v = partner_dir
	if v.length() > 1.0:
		v = v.normalized()
	var moving: bool = v.length() > 0.05
	var sp: float = 118.0
	partner.position += v * sp * delta
	partner.position = _collide(partner.position, partner.radius * 0.55)
	if not down and partner.position.distance_to(player.position) > 520.0:
		partner.position = _free_spot(player.position + Vector2.from_angle(randf() * TAU) * 70.0, 14.0)
		_ring(partner.position, 6.0, 80.0, Color("#9ad0ff"), 0.5)
	# ataque automatico
	var lvl: int = clampi(1 + player.level / 6, 1, 6)
	if lvl != partner_lvl or partner_move.is_empty():
		partner_lvl = lvl
		partner_move = _partner_move_for(partner.dex, lvl)
	var tgt: Node2D = _nearest_enemy(partner.position, AIM_REACH)
	if tgt != null:
		partner.aim = (tgt.position - partner.position).angle()
	elif moving:
		partner.aim = v.angle()
	partner.face_angle(partner.aim if tgt != null else (v.angle() if moving else partner.aim))
	if moving:
		partner.loop_anim("Walk", sp / 110.0)
	else:
		partner.loop_anim("Idle", 1.0)
	partner_cd -= delta
	if partner_cd <= 0.0 and tgt != null:
		var m: Dictionary = partner_move
		partner_cd = _f(m, "cd") * 1.15
		var n: int = maxi(1, int(_f(m, "count", 1.0)))
		for i in range(n):
			var off: float = 0.0
			if n > 1:
				off = (float(i) / float(n - 1) - 0.5) * _f(m, "spread") * float(n)
			var d: Vector2 = Vector2.from_angle(partner.aim + off + randf_range(-0.03, 0.03))
			var b: Bullet = _make_bullet(m, partner.position + d * 3.0, d * _f(m, "speed"), _f(m, "life", 1.4), int(_f(m, "pierce")))
			b.dmg *= 0.8
		pfx.spark(partner.position + Vector2(0.0, -18.0) + Vector2.from_angle(partner.aim) * partner.radius, _col(m), Vector2.from_angle(partner.aim), 3)


# Movimientos con los que empieza un Pokemon: su movimiento inicial y, con la mejora Repertorio, un segundo al azar de sus tipos.
func _start_moves(dex: int, types: Array) -> Array:
	var first_move: String = SV.start_move_of(dex)
	var out: Array = [_new_move(first_move, 1)]
	if int(perks["moves"]) >= 2:
		var cands: Array = []
		for mid in MD.ORDER:
			var md: Dictionary = MD.MOVES[mid]
			var ty: String = String(md["type"])
			if mid != first_move and String(md["kind"]) != "buff" and GPM.playable(String(mid)) and (ty == "normal" or types.has(ty)):
				cands.append(mid)
		if not cands.is_empty():
			var okc: Array = []
			for cid in cands:
				if not banned.has(cid):
					okc.append(cid)
			if okc.is_empty():
				okc = cands
			out.append(_new_move(String(okc[randi() % okc.size()]), 1))
	return out


func _setup_team() -> void:
	team = []
	team_cur = 0
	for dx in SV.team_dex:
		var d: int = int(dx)
		var st2: Dictionary = _dex_by[d]
		var b: float = float(st2["hp"]) + float(perks["hp"])
		if _has_mod("frail"):
			b = roundf(b * 0.5)
		# Cada Pokemon del equipo guarda SUS movimientos, hueco activo y vinculo (el primero usa los del jugador en vivo).
		var tm: Array = []
		if team.size() > 0:
			tm = _start_moves(d, st2["types"])
		team.append({"dex": d, "name": L.t(String(st2["name"])), "base": b, "hp": b, "types": st2["types"], "spd": float(st2["spd"]), "atk": float(st2["atk"]),
			"moves": tm, "slot": 0, "bond_pairs": [], "bond_first": ""})
	team_bonus = 0.0


func arena_ok_for_ui() -> bool:
	return true


func _team_next() -> int:
	for k in range(1, team.size()):
		var i: int = (team_cur + k) % team.size()
		if float(team[i]["hp"]) > 0.0:
			return i
	return -1


func _swap_team(i: int, auto: bool = false) -> void:
	if mode != "team" or i == team_cur or i < 0 or i >= team.size():
		return
	_dyn_stop()
	if float(team[i]["hp"]) <= 0.0 or (not auto and swap_cd > 0.0):
		return
	var cur: Dictionary = team[team_cur]
	cur["hp"] = maxf(0.0, player.hp)
	cur["moves"] = player.moves
	cur["slot"] = player.slot
	cur["bond_pairs"] = bond_pairs
	cur["bond_first"] = bond_first
	team_bonus = maxf(0.0, player.max_hp - float(cur["base"]))
	var nx: Dictionary = team[i]
	team_cur = i
	ab_fx = AB.fx_of(_pdex())
	var dx: int = int(nx["dex"])
	var shn: bool = SV.owns(dx) and bool(SV.d["owned"][str(dx)]["shiny"]) and bool(SV.d["shiny_on"])
	player.rebody(dx, _sm(dx), shn)
	player.max_hp = float(nx["base"]) + team_bonus
	player.hp = minf(player.max_hp, float(nx["hp"]))
	player.types = nx["types"]
	# Los movimientos son los del Pokemon que entra, no los del que sale.
	_clear_orbit_orbs()
	player.moves = nx["moves"] if not (nx["moves"] as Array).is_empty() else _start_moves(dx, nx["types"])
	player.slot = clampi(int(nx["slot"]), 0, maxi(0, _slot_list_of(player.moves, nx["bond_pairs"]).size() - 1))
	bond_pairs = nx["bond_pairs"]
	bond_first = String(nx["bond_first"])
	for mv in player.moves:
		mv["t"] = minf(_f(mv, "t"), _f(mv, "cd") * 0.35)
	player.spd = float(nx["spd"])
	player.atk = float(nx["atk"])
	base_spd = player.spd * float(perks["spd"])
	base_atk = player.atk * float(perks["atk"])
	player.invuln = maxf(player.invuln, 1.5 if auto else 1.0)
	player.flash = 0.5
	swap_cd = 3.0
	nh_max = player.max_hp
	nh_last = player.hp
	hud.poke_name = String(nx["name"])
	Aud.sfx("biome")
	_ring(player.position, 8.0, 150.0, Color("#ffd23f"), 0.5)
	_say(L.t("¡Adelante, %s!") % String(nx["name"]), 1.6)


func _team_tick(delta: float) -> void:
	swap_cd = maxf(0.0, swap_cd - delta)
	for i in range(team.size()):
		if i == team_cur:
			continue
		var t: Dictionary = team[i]
		if float(t["hp"]) > 0.0:
			t["hp"] = minf(float(t["base"]), float(t["hp"]) + float(t["base"]) * 0.012 * delta)
	var arr: Array = []
	for i in range(team.size()):
		var t2: Dictionary = team[i]
		arr.append({"name": String(t2["name"]), "frac": (player.hp / maxf(player.max_hp, 1.0)) if i == team_cur else float(t2["hp"]) / maxf(float(t2["base"]), 1.0), "cur": i == team_cur, "dead": float(t2["hp"]) <= 0.0 and i != team_cur})
	hud.team = arr
	hud.swap_cd = swap_cd


func _hurt_player(amount: float, atk_type: String = "", pure: bool = false) -> void:
	if player.dead:
		return
	if down:
		_hurt_partner(amount, atk_type, pure)
		return
	if player.invuln > 0.0:
		return
	if kec.dodge():
		player.invuln = 0.3
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("¡Esquivado!"), Color("#7fe0ff"), 18)
		return
	var eff: String = ""
	if atk_type != "":
		var tk: float = _types_mult(atk_type, player.types, true)
		amount *= tk * _weather_mult(atk_type)
		eff = _eff_label(tk)
	if not ab_fx.is_empty():
		if atk_type != "" and ab_fx.has("resist") and (ab_fx["resist"] as Array).has(atk_type):
			amount *= float(ab_fx.get("resist_k", 1.0))
		if eff == "super":
			amount *= 1.0 - _abn("se_taken")
		if ab_fx.has("first_hit") and run_time - ab_first_t > _abn("first_hit"):
			ab_first_t = run_time
			amount *= 0.5
		if ab_fx.has("defiant"):
			defiant_t = 4.0
	var close: float = 1.0
	for gm in _active_group():
		if String(gm["kind"]) == "melee":
			close = 0.75        # cuerpo a cuerpo: recibes un 25% menos
	var d: float = maxf(1.0, amount * (1.0 - _reduction()) * close * _rk("taken"))
	if pure:
		d = maxf(1.0, amount)
	if tw_shield > 0.0:
		var ab: float = minf(tw_shield, d)
		tw_shield -= ab
		d -= ab
		if d <= 0.0:
			player.invuln = 0.45
			Aud.sfx("hit")
			add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("Escudo"), Color("#7fe0ff"), 18)
			return
	player.hp -= d
	kec.on_hurt()
	ch_last_hurt = run_time
	if mode == "tower" and (tw_boss != null or tw_boss2 != null):
		tw_fight_dmg += d
	player.invuln = 0.45
	Aud.sfx("hurt")
	if bool(SV.setting("vibration")):
		Input.vibrate_handheld(40)
	player.flash = 0.6
	shake = 5.0
	var tcol := Color("#ff6b7a")
	if eff == "super":
		tcol = Color("#ff3048")
	elif eff == "weak":
		tcol = Color("#c9a0a8")
	add_text(player.position + Vector2(0.0, -player.body_h - 4.0), "-" + str(roundi(d)), tcol, 24 if eff == "super" else 18)
	if mode == "party":
		player.hp = maxf(player.hp, 1.0)   # Modo Fiesta: no se puede morir
	if eff == "super" and _has_item("weaknesspolicy") and player.hp > 0.0:
		wp_t = 8.0
		add_text(player.position + Vector2(0.0, -player.body_h - 22.0), L.t("¡Seguro Debilidad!"), Color("#ff8a5b"), 20)
	if player.hp > 0.0 and player.hp < player.max_hp * 0.5 and _has_item("sitrusberry") and run_time - sitrus_t > 90.0:
		sitrus_t = run_time
		player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.3)
		add_text(player.position + Vector2(0.0, -player.body_h - 22.0), L.t("¡Baya Zidra!"), Color("#ffd83d"), 22)
		_ring(player.position, 6.0, 80.0, Color("#ffd83d"), 0.5)
	# Banda Focus: aguanta el golpe con 1 de vida (una vez cada 60 s).
	if player.hp <= 0.0 and _has_item("focussash") and run_time - sash_t > 60.0:
		sash_t = run_time
		player.hp = 1.0
		player.invuln = 1.2
		add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("¡Banda Focus!"), Color("#ff9a3d"), 24)
		_ring(player.position, 6.0, 70.0, Color("#ff9a3d"), 0.5)
	# Habilidad Robustez: aguanta un golpe mortal con 1 de vida.
	if player.hp <= 0.0 and ab_fx.has("sturdy") and run_time - ab_sturdy_t > _abn("sturdy"):
		ab_sturdy_t = run_time
		player.hp = 1.0
		player.invuln = 1.2
		add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("¡Robustez!"), Color("#c9b27a"), 24)
		_ring(player.position, 6.0, 70.0, Color("#c9b27a"), 0.5)
	if player.hp <= 0.0 and kec.try_phoenix():
		return
	# Segunda oportunidad: un corazon se gasta y revives con la vida completa.
	if player.hp <= 0.0 and revives > 0:
		revives -= 1
		player.hp = player.max_hp
		player.invuln = 2.5
		Aud.sfx("legend")
		add_text(player.position + Vector2(0.0, -player.body_h - 22.0), L.t("¡Segunda oportunidad!"), Color("#ff8ad8"), 26)
		_ring(player.position, 8.0, 260.0, Color("#ff8ad8"), 0.8)
		shake = 6.0
		for e in enemies:
			if not e.dead and e.position.distance_to(player.position) < 260.0:
				e.knock = (e.position - player.position).normalized() * 500.0
		return
	if player.hp <= 0.0 and mode == "team":
		team[team_cur]["hp"] = 0.0
		var nxt: int = _team_next()
		if nxt >= 0:
			_swap_team(nxt, true)
			return
	if player.hp <= 0.0 and arena != null and String(ainfo.get("phase", "")) != "fight":
		# Fuera de la pelea (intro, caida, expulsion, victoria): nunca hay Game Over dentro de una grieta
		if String(ainfo.get("phase", "")) != "down":
			player.hp = 1.0
			player.invuln = maxf(player.invuln, 2.0)
		return
	if player.hp <= 0.0 and arena != null and String(ainfo.get("phase", "")) == "fight":
		# En la grieta no hay Game Over: el jugador cae (animacion de desmayo) y la grieta lo expulsa
		player.hp = 0.0
		player.invuln = 99.0
		player.flash = 0.0
		player.active = false
		player.play("Faint", 1.0, true)
		arena_down = true
		ainfo["phase"] = "down"
		ainfo["down_t"] = 0.0
		ainfo["fainted"] = 0.0
		_clear_orbit_orbs()
		return
	if player.hp <= 0.0 and mode == "coop" and partner != null and arena == null and not down:
		_enter_down()
		return
	if player.hp <= 0.0:
		_player_final_death()


func _player_final_death() -> void:
	_dyn_stop()
	if mode == "chal" and not ch_over:
		ch_m["dead"] = true
	down = false
	player.visible = true
	player.hp = 0.0
	player.dead = true
	player.play("Faint", 1.0, true)   # desmayo en camara lenta antes de la pantalla final
	player.flash = 0.0
	Engine.time_scale = DEATH_SLOW
	player.active = false
	_clear_orbit_orbs()
	for e in enemies:
		e.active = false


# Cooperativo: caes, pero no se acaba. Miras (camara) a tu companero hasta que te revive.
func _enter_down() -> void:
	_dyn_stop()
	down = true
	down_t = 0.0
	player.hp = 0.0
	player.invuln = 0.0
	player.flash = 0.0
	player.visible = false
	partner_max = maxf(1.0, player.max_hp)
	partner_hp = partner_max
	partner_inv = 0.0
	partner_last = partner.position
	player.position = partner.position
	_clear_orbit_orbs()
	Aud.sfx("hurt")
	shake = 6.0
	_ring(partner.position, 8.0, 160.0, Color("#9ad0ff"), 0.7)
	add_text(partner.position + Vector2(0.0, -partner.body_h - 14.0), L.t("¡Has caído! Mira a tu compañero"), Color("#ff8a9a"), 22)


func _update_down(delta: float) -> void:
	down_t += delta
	partner_inv = maxf(0.0, partner_inv - delta)
	player.position = partner.position
	player_vel = (partner.position - partner_last) / maxf(delta, 0.0001)
	partner_last = partner.position
	if down_t >= DOWN_REVIVE_T:
		_revive_from_down()


func _revive_from_down() -> void:
	down = false
	player.visible = true
	player.position = _free_spot(partner.position + Vector2(-50.0, 10.0), 14.0)
	player.hp = player.max_hp * 0.5
	player.invuln = 2.5
	player.active = true
	player.flash = 0.0
	Aud.sfx("legend")
	shake = 4.0
	_ring(player.position, 8.0, 240.0, Color("#7dffb0"), 0.8)
	add_text(player.position + Vector2(0.0, -player.body_h - 22.0), L.t("¡Tu compañero te ha revivido!"), Color("#7dffb0"), 24)
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) < 220.0:
			e.knock = (e.position - player.position).normalized() * 450.0


# Mientras espectas, los golpes que recibe tu "cuerpo" los recibe el companero.
func _hurt_partner(amount: float, atk_type: String, pure: bool) -> void:
	if partner_inv > 0.0:
		return
	var eff: String = ""
	if atk_type != "":
		var tk: float = _types_mult(atk_type, partner.types, true)
		amount *= tk * _weather_mult(atk_type)
		eff = _eff_label(tk)
	var d: float = maxf(1.0, amount * 0.8)
	if pure:
		d = maxf(1.0, amount)
	partner_hp -= d
	partner_inv = 0.45
	partner.flash = 0.6
	shake = 4.0
	Aud.sfx("hurt")
	add_text(partner.position + Vector2(0.0, -partner.body_h - 4.0), "-" + str(roundi(d)), Color("#ff3048") if eff == "super" else Color("#ff6b7a"), 20)
	if partner_hp <= 0.0:
		partner_hp = 0.0
		if arena != null:
			partner_hp = 1.0   # dentro de una grieta no hay Game Over
			return
		_player_final_death()


# ---------------------------------------------------------------
# Ejecucion de movimientos (combat.js)
# ---------------------------------------------------------------
func _reach(m: Dictionary) -> float:
	var k: String = String(m["kind"])
	if k == "melee":
		return _f(m, "radius") + 30.0
	if k == "beam":
		return _f(m, "radius") + 20.0
	if k == "boomerang":
		return _f(m, "radius") + 40.0
	if k == "chain":
		return 280.0
	if k == "meteor":
		return 340.0
	if k == "dash":
		return _f(m, "radius") + 60.0
	if k == "cone":
		return _f(m, "speed") * _f(m, "life") + 30.0
	return 520.0


# S62.1: opacidad de los efectos de los movimientos del jugador (Ajustes > Graficos). No afecta a avisos ni a enemigos.
func _fx_alpha() -> float:
	var a: Array = [1.0, 0.75, 0.5, 0.3]
	return float(a[clampi(int(SV.d["settings"].get("fx_op", 1)), 0, 3)])


func caves_active() -> bool:
	return cave != null and cave.active()


func ach_event(ev: String, data: Dictionary = {}) -> void:
	ACH.event(ev, data)
	while not ACH.pending.is_empty():
		var id: String = String(ACH.pending.pop_front())
		var df: Array = ACH.def_of(id)
		if not df.is_empty():
			_say(L.t("¡Medalla!") + " " + L.t(String(df[2])), 3.0)
			Aud.sfx("shinyGet")
		SV.save()


func _cut_by_move(m: Dictionary, kind: String) -> void:
	if arena == null and sec != null and ["melee", "aura", "nova", "dash", "buff"].has(kind):
		sec.hit(player.position, minf(220.0, maxf(40.0, _f(m, "radius"))), String(m.get("type", "")))
	if arena != null:
		return
	if ["melee", "aura", "nova", "dash", "buff"].has(kind):
		_cut_grass(player.position, minf(150.0, maxf(40.0, _f(m, "radius") * 0.85)))
		return
	var dirv: Vector2 = Vector2.from_angle(player.aim)
	var reach: float = minf(260.0, _reach(m))
	var t := 20.0
	while t <= reach:
		_cut_grass(player.position + dirv * t, 38.0)
		t += 44.0


func _tick_move(m: Dictionary, delta: float) -> void:
	if m.has("parts"):
		for pm in m["parts"]:
			pm["lite"] = true       # las mitades solo golpean base: el efecto es el ataque unico de la fusion
			_tick_move(pm, delta)
		ffx.tick(m, delta)      # ...y ademas su ataque especial con animacion propia
		return
	var kind: String = String(m["kind"])
	if kind == "orbit":
		_orbit(m, delta)
		if bool(m.get("evolved", false)) and not bool(m.get("lite", false)):
			evab.cast(m)
		return
	m["t"] = _f(m, "t") - delta
	if _f(m, "t") > 0.0:
		return
	# Los ataques con blanco esperan a tenerlo a tiro.
	if TARGETED.has(kind) and not aim_manual:   # con apuntado manual el Pokémon ataca hacia donde apuntas aunque no haya blanco
		if target == null or player.position.distance_to(target.position) > _reach(m):
			m["t"] = 0.05
			return
	var cd: float = maxf(0.05, _f(m, "cd") * _cd_mul() * (0.92 if (String(m["type"]) == "steel" and _has_item("ti_steel")) else 1.0))
	var evolved_now: bool = bool(m.get("evolved", false))
	var icy: bool = evolved_now and String(m["id"]) == "powder-snow"
	var cc: bool = evolved_now and String(m["id"]) == "karate-chop"
	if (icy or cc) and not bool(m.get("lite", false)):
		var chan_r: float = ICY_LEN if icy else CC_LEN
		if not aim_manual and (target == null or player.position.distance_to(target.position) > chan_r):
			m["t"] = 0.05
			return
		var tick: float = ICY_TICK if icy else CC_TICK
		m["t"] = tick   # ataque continuo: mismo dano por segundo, repartido en golpes cortos
		if icy:
			_icy_wind(m, tick / cd)
		else:
			_close_combat_tick(m, tick / cd)
		player.attack_face = 0.35
		m["_snd"] = int(m.get("_snd", 0)) + 1
		if int(m["_snd"]) % 3 == 1:
			player.play_attack(String(ANIM_FOR.get(kind, "Shoot")), tick * 3.0)
			Aud.shot(kind, String(m.get("type", "normal")))
		return
	m["t"] = cd
	if _has_item("lifeorb") and kind != "trail":
		player.hp = maxf(1.0, player.hp - maxf(1.0, player.max_hp * 0.01))
	if m.has("iframes"):
		player.invuln = maxf(player.invuln, float(m["iframes"]))
	if kind != "trail":
		player.attack_face = 0.35
		player.play_attack(String(ANIM_FOR.get(kind, "Shoot")), maxf(0.12, cd))
	Aud.shot(kind, String(m.get("type", "normal")))
	_cut_by_move(m, kind)
	if bool(m.get("evolved", false)) and not bool(m.get("lite", false)):
		evfx.cast(m)
		evab.cast(m)
	if m.has("pat"):
		_pat(String(m["pat"]), m)
		return
	if String(m["id"]) == "dragon-rage" and bool(m.get("evolved", false)):
		_draco_meteors(m)   # v5.8: Cometa Draco deja de ser un rayo
		return
	if String(m["id"]) == "toxic-spikes" and bool(m.get("evolved", false)):
		_gunk_shot(m)   # v5.8: Lanza Mugre es un escopetazo, no minas
		return
	match kind:
		"projectile":
			_fire_projectiles(m)
		"melee":
			_melee(m)
			if String(m["id"]) == "body-slam":   # v5.8: el golpe hace temblar el suelo
				_ring(player.position, 10.0, _f(m, "radius") * 1.5, _col(m), 0.35, 5.0)
				pfx.burst(player.position, _col(m), 10, 150.0)
				shake = maxf(shake, 5.0)
		"beam":
			_beam(m)
			if String(m["id"]) == "flash-cannon":   # v5.8: fogonazo de luz al disparar
				_ring(player.position + Vector2(0.0, -LIFT), 6.0, 70.0, Color.WHITE, 0.25, 4.0)
		"nova":
			_nova(m)
		"aura":
			_aura(m)
		"buff":
			_buff(m)
		"boomerang":
			_boomerang(m)
		"chain":
			_chain(m)
		"mine":
			_mines(m)
		"meteor":
			_meteors(m)
		"turret":
			_turret(m)
		"dash":
			_dash(m)
		"trail":
			_trail_patch(m)
		"cone":
			_cone(m)


# Tope de disparos del jugador en pantalla (evita tirones): al pasarlo, se descarta el disparo mas viejo que no sea un orbe.
func _bullet_room() -> void:
	var cap: int = [90, 60, 36][perf_lv]
	if bullets.size() < cap:
		return
	for i in range(bullets.size()):
		var ob = bullets[i]
		if not ob.orb:
			ob.queue_free()
			bullets.remove_at(i)
			return


func _make_bullet(m: Dictionary, pos: Vector2, vel: Vector2, life: float, pierce: int) -> Bullet:
	_bullet_room()
	var b := Bullet.new()
	b.modulate.a = _fx_alpha()
	b.position = pos
	b.ppos = pos
	b.vel = vel
	b.dmg = _f(m, "dmg") * _atk()
	b.r = _f(m, "size", 6.0)
	b.life = life
	b.pierce = pierce
	b.color = _col(m)
	b.homing = _f(m, "homing")
	b.burn = int(_f(m, "burn"))
	b.poison = int(_f(m, "poison"))
	b.slow = _f(m, "slow")
	b.cc = String(m.get("cc", ""))
	b.ccp = _f(m, "ccp")
	b.knock = _f(m, "knock")
	b.mtype = String(m["type"])
	b.src = String(m["id"])
	var vv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	b.shape = String(vv["proj"])
	b.pal = String(vv["pal"])
	b.trail = String(vv.get("trail", ""))
	fx.add_child(b)
	bullets.append(b)
	if bool(m.get("evolved", false)):
		evfx.track(b, m)
	return b


func _fire_projectiles(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var spread: float = _f(m, "spread")
	for i in range(n):
		var off: float = 0.0
		if n > 1:
			off = (float(i) / float(n - 1) - 0.5) * spread * float(n)
		var a: float = player.aim + off + randf_range(-0.03, 0.03)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 3.0, d * _f(m, "speed"), _f(m, "life", 1.4), int(_f(m, "pierce")))
	pfx.spark(player.position + Vector2(0.0, -LIFT) + Vector2.from_angle(player.aim) * player.radius, _col(m), Vector2.from_angle(player.aim), 3)


func _nova(m: Dictionary) -> void:
	var n: int = maxi(3, int(_f(m, "count", 8.0)))
	for i in range(n):
		var a: float = float(i) / float(n) * TAU + randf_range(-0.06, 0.06)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 3.0, d * _f(m, "speed"), _f(m, "life", 1.2), int(_f(m, "pierce")))
	_ring(player.position, player.radius, player.radius * 4.0, _col(m), 0.3)


func _cone(m: Dictionary) -> void:
	var n: int = maxi(2, int(_f(m, "count", 5.0)))
	var arc: float = _f(m, "arc", 0.9)
	for i in range(n):
		var a: float = player.aim + (float(i) / float(n - 1) - 0.5) * arc + randf_range(-0.05, 0.05)
		var sp: float = _f(m, "speed") * randf_range(0.85, 1.1)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 4.0, d * sp, _f(m, "life", 0.5) * randf_range(0.85, 1.05), int(_f(m, "pierce")))


func _boomerang(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var spread: float = _f(m, "spread", 0.5)
	var out: float = _f(m, "radius") / maxf(1.0, _f(m, "speed"))
	for i in range(n):
		var off: float = 0.0
		if n > 1:
			off = (float(i) / float(n - 1) - 0.5) * spread * float(minf(float(n), 3.0))
		var d: Vector2 = Vector2.from_angle(player.aim + off)
		var b: Bullet = _make_bullet(m, player.position, d * _f(m, "speed"), out * 4.0 + 1.5, 999)
		b.boom = out
		b.bsp = _f(m, "speed") * 1.1


# ---------------------------------------------------------------
# Patrones de ataque propios de los movimientos nuevos (v5.0).
# Cada movimiento nuevo tiene un "pat" distinto: ninguno repite el patron de otro.
# ---------------------------------------------------------------
var _sched: Array = []
var _zones: Array = []
var _waves: Array = []
var _leeches: Array = []
var root_t := 0.0


func _later(t: float, f: Callable) -> void:
	_sched.append({"t": t, "f": f})


func _pk(m: Dictionary, k: float = 1.0) -> float:
	return _f(m, "dmg") * _atk() * k


func _vis(m: Dictionary) -> Dictionary:
	return VFX.for_move(String(m["id"]), String(m["type"]))


func _p_targets(n: int, reach: float) -> Array:
	var arr: Array = []
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) <= reach:
			arr.append(e)
	arr.sort_custom(func(a, b): return a.position.distance_squared_to(player.position) < b.position.distance_squared_to(player.position))
	return arr.slice(0, n)


func _p_target_pos(reach: float, fallback: Vector2) -> Vector2:
	var ts: Array = _p_targets(1, reach)
	if ts.size() > 0:
		return ts[0].position
	return fallback


func _p_hit_circle(c: Vector2, r: float, m: Dictionary, k: float = 1.0, fx_on: bool = true) -> int:
	var n := 0
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(c) <= r + e.radius * 0.5:
			_hit_move(e, _pk(m, k), e.position - c, m)
			n += 1
	if fx_on:
		_ring(c, r * 0.3, r, _col(m), 0.28)
		pfx.burst(c + Vector2(0.0, -6.0), _col(m), 8, 130.0)
	return n


func _p_hit_line(a: Vector2, ang: float, ln: float, w: float, m: Dictionary, k: float = 1.0) -> void:
	var d: Vector2 = Vector2.from_angle(ang)
	var b: Vector2 = a + d * ln
	for e in enemies:
		if e.dead:
			continue
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, a, b)
		var rr: float = w * 0.5 + e.radius
		if cp.distance_squared_to(e.position) <= rr * rr:
			_hit_move(e, _pk(m, k), d, m)


func _p_hit_arc(ang: float, rad: float, arc: float, m: Dictionary, k: float = 1.0) -> void:
	pfx.slash(player.position + Vector2(0.0, -LIFT * 0.5), ang, rad, arc, _vis(m))
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(player.position) > rad + e.radius * 0.5:
			continue
		if not _in_arc(player.position, e.position, ang, minf(arc, TAU) * 0.5):
			continue
		_hit_move(e, _pk(m, k), e.position - player.position, m)


func _p_beam(m: Dictionary, ang: float, ln: float, w: float, k: float = 1.0) -> void:
	var d: Vector2 = Vector2.from_angle(ang)
	pfx.beam(player.position + Vector2(0.0, -LIFT), ang, ln, w, _vis(m))
	shake = maxf(shake, 1.5)
	for e in enemies:
		if e.dead:
			continue
		var rel: Vector2 = e.position - player.position
		var along: float = rel.dot(d)
		if along < -e.radius or along > ln + e.radius:
			continue
		if absf(-rel.x * d.y + rel.y * d.x) <= w * 0.5 + e.radius:
			_hit_move(e, _pk(m, k), d, m)


func _p_warn(a: Vector2, ang: float, ln: float, m: Dictionary) -> void:
	pfx.beam(a + Vector2(0.0, -LIFT), ang, ln, 4.0, {"pal": String(_vis(m)["pal"]), "beam": "streak"})


func _p_bullet(m: Dictionary, ang: float, speed: float, life: float, pierce: int, size: float, k: float = 1.0, pos: Vector2 = Vector2.INF) -> Bullet:
	var p0: Vector2 = player.position if pos == Vector2.INF else pos
	var d: Vector2 = Vector2.from_angle(ang)
	var b: Bullet = _make_bullet(m, p0 + d * 3.0, d * speed, life, pierce)
	b.dmg = _pk(m, k)
	b.r = size
	b.bm = m
	return b


func _p_radial(m: Dictionary, c: Vector2, n: int, speed: float, life: float, k: float) -> void:
	var a0: float = randf() * TAU
	for i in range(n):
		_p_bullet(m, a0 + float(i) / float(n) * TAU, speed, life, 1, 5.0, k, c)


func _p_zone(c: Vector2, r: float, life: float, tick: float, m: Dictionary, k: float, pull: float = 0.0) -> void:
	if _zones.size() > 26:
		_zones.remove_at(0)
	_zones.append({"c": c, "r": r, "life": life, "t": 0.0, "tick": tick, "tt": 0.05, "m": m, "k": k, "pull": pull, "fx": 0.0})
	_ring(c, r * 0.4, r, _col(m), 0.3)


func _p_wave(m: Dictionary, r0: float, r1: float, dur: float, th: float, k: float, follow: bool = true) -> void:
	_waves.append({"c": player.position, "follow": follow, "r0": r0, "r1": r1, "dur": dur, "t": 0.0, "th": th, "k": k, "m": m, "hit": {}})


func _p_tele(c: Vector2, r: float, m: Dictionary, dur: float) -> void:
	_ring(c, r, r * 0.35, _col(m), dur, 2.0)


func _p_dash_path(m: Dictionary, pts: Array, w: float, k: float, drag: float = 0.0) -> void:
	var vis: Dictionary = _vis(m)
	var seen := {}
	for s in range(pts.size() - 1):
		var a: Vector2 = pts[s]
		var b: Vector2 = pts[s + 1]
		var ang: float = (b - a).angle()
		for q in range(0, int(a.distance_to(b)) + 1, 22):
			pfx.sp(String(vis.get("proj", "streak")), String(vis["pal"]), a + Vector2.from_angle(ang) * float(q) + Vector2(0.0, -LIFT * 0.6), {"life": 0.24, "angle": ang})
		for e in enemies:
			if e.dead or seen.has(e):
				continue
			var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, a, b)
			var rr: float = w * 0.5 + e.radius
			if cp.distance_squared_to(e.position) <= rr * rr:
				seen[e] = true
				_hit_move(e, _pk(m, k), Vector2.from_angle(ang), m)
				if drag > 0.0 and not e.boss:
					e.position += Vector2.from_angle(ang) * drag
	player.position = pts[pts.size() - 1]
	player.invuln = maxf(player.invuln, _f(m, "iframes", 0.3))
	pfx.slash(player.position + Vector2(0.0, -LIFT * 0.5), (pts[pts.size() - 1] - pts[pts.size() - 2]).angle(), 34.0, 2.2, vis)
	shake = maxf(shake, 3.0)


func _upd_pats(delta: float) -> void:
	for i in range(_sched.size() - 1, -1, -1):
		_sched[i]["t"] = float(_sched[i]["t"]) - delta
		if float(_sched[i]["t"]) <= 0.0:
			var f: Callable = _sched[i]["f"]
			_sched.remove_at(i)
			f.call()
	for i in range(_zones.size() - 1, -1, -1):
		var z: Dictionary = _zones[i]
		z["t"] = float(z["t"]) + delta
		if float(z["t"]) >= float(z["life"]):
			_zones.remove_at(i)
			continue
		var zm: Dictionary = z["m"]
		var c: Vector2 = z["c"]
		var zr: float = float(z["r"])
		if float(z["pull"]) > 0.0:
			for e in enemies:
				if e.dead or e.boss:
					continue
				var dd: float = e.position.distance_to(c)
				if dd < zr * 1.5 and dd > 6.0:
					e.position += (c - e.position).normalized() * float(z["pull"]) * delta
		z["tt"] = float(z["tt"]) - delta
		if float(z["tt"]) <= 0.0:
			z["tt"] = float(z["tick"])
			_p_hit_circle(c, zr, zm, float(z["k"]), false)
		z["fx"] = float(z["fx"]) - delta
		if float(z["fx"]) <= 0.0:
			z["fx"] = 0.35
			_ring(c, zr * 0.75, zr, _col(zm), 0.35, 2.0)
			var v: Dictionary = _vis(zm)
			pfx.sp(String(v["proj"]), String(v["pal"]), c + Vector2(randf_range(-zr, zr) * 0.6, randf_range(-zr, zr) * 0.3), {"v": Vector2(0.0, -34.0), "life": 0.5})
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		w["t"] = float(w["t"]) + delta
		var kk: float = float(w["t"]) / float(w["dur"])
		if kk >= 1.0:
			_waves.remove_at(i)
			continue
		if bool(w["follow"]):
			w["c"] = player.position
		var rad: float = lerpf(float(w["r0"]), float(w["r1"]), kk)
		var wc: Vector2 = w["c"]
		var wm: Dictionary = w["m"]
		# antes: un anillo nuevo CADA fotograma por onda (miles de cuadritos en pantalla = lag); ahora uno cada 0.07 s
		w["rf"] = float(w.get("rf", 0.0)) - delta
		if float(w["rf"]) <= 0.0:
			w["rf"] = 0.07 / maxf(0.25, fx_load)
			_ring(wc, rad * 0.94, rad, _col(wm), 0.1, 3.0)
		for e in enemies:
			if e.dead or (w["hit"] as Dictionary).has(e.get_instance_id()):
				continue
			if absf(e.position.distance_to(wc) - rad) <= float(w["th"]) + e.radius * 0.5:
				(w["hit"] as Dictionary)[e.get_instance_id()] = true
				_hit_move(e, _pk(wm, float(w["k"])), e.position - wc, wm)
	for i in range(_leeches.size() - 1, -1, -1):
		var lc: Dictionary = _leeches[i]
		var le = lc["e"]
		lc["t"] = float(lc["t"]) - delta
		if not is_instance_valid(le) or le.dead or float(lc["t"]) <= 0.0:
			_leeches.remove_at(i)
			continue
		lc["tk"] = float(lc["tk"]) - delta
		if float(lc["tk"]) <= 0.0:
			lc["tk"] = 0.5
			var lm: Dictionary = lc["m"]
			_hit_move(le, _pk(lm, 0.5), le.position - player.position, lm)
			if not player.dead:
				var hl: float = _heal_real(maxf(1.0, player.max_hp * 0.012))
				if hl > 0.0:
					add_text(player.position + Vector2(randf_range(-10.0, 10.0), -player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 14)
			var v2: Dictionary = _vis(lm)
			pfx.sp("seed", String(v2["pal"]), le.position + Vector2(0.0, -le.body_h * 0.6), {"v": Vector2(0.0, -30.0), "life": 0.4})
			pfx.beam(le.position + Vector2(0.0, -LIFT), (player.position - le.position).angle(), le.position.distance_to(player.position), 3.0, {"pal": String(v2["pal"]), "beam": ""})


func _pat(p: String, m: Dictionary) -> void:
	var aim: float = player.aim
	var d: Vector2 = Vector2.from_angle(aim)
	var pos: Vector2 = player.position
	var col: Color = _col(m)
	var vis: Dictionary = _vis(m)
	var rad: float = _f(m, "radius")
	var arc: float = _f(m, "arc", 1.6)
	match p:
		"splitorb":   # Bola Voltio: orbe lento que al chocar se parte en chispas
			var b: Bullet = _p_bullet(m, aim, _f(m, "speed"), _f(m, "life", 1.6), 0, _f(m, "size", 11.0))
			b.burst = 5
		"ringmines":   # Electrotela: anillo de 6 minas alrededor
			for i in range(6):
				var a: float = aim + float(i) / 6.0 * TAU
				var f: Field = _new_field("mine", m, pos + Vector2(cos(a) * 72.0, sin(a) * 58.0))
				f.arm = 0.35
				f.life = _f(m, "dur", 7.0)
				f.r = rad
			_trim_fields("mine", 14)
			_ring(pos, 10.0, 80.0, col, 0.35)
		"zigzag":   # Pico Trueno: embestida en zigzag
			var p1: Vector2 = pos + Vector2.from_angle(aim + 0.7) * rad * 0.5
			var p2: Vector2 = p1 + Vector2.from_angle(aim - 0.7) * rad * 0.5
			_p_dash_path(m, [pos, p1, p2], _f(m, "width", 30.0), 1.0)
		"charged":   # Canon Zap: avisa y dispara tras cargar
			for i in range(3):
				_later(0.05 + 0.22 * float(i), func(): _p_warn(player.position, aim, rad, m))
			_later(0.75, func(): _p_beam(m, aim, rad, _f(m, "width", 36.0), 1.0))
		"pulsewave":   # Onda Trueno: tres ondas expansivas seguidas
			for i in range(3):
				_later(0.22 * float(i), func(): _p_wave(m, 8.0, rad, 0.42, 14.0, 1.0))
		"volley":   # Dracoflechas: dardos secuenciales a blancos distintos
			var n: int = maxi(2, int(_f(m, "count", 4.0)))
			for i in range(n):
				_later(0.07 * float(i), func():
					if player.dead:
						return
					var ts: Array = _p_targets(n, 340.0)
					var a: float = player.aim
					if ts.size() > 0:
						a = (ts[i % ts.size()].position - player.position).angle()
					var bb: Bullet = _p_bullet(m, a + randf_range(-0.04, 0.04), _f(m, "speed"), _f(m, "life", 0.7), int(_f(m, "pierce")), _f(m, "size", 5.0))
					bb.homing = 3.0)
		"sweep":   # Dragoaliento: chorro continuo que barre de lado a lado
			var s: float = 1.0 if randf() < 0.5 else -1.0
			for i in range(8):
				var a2: float = aim + s * (float(i) / 7.0 - 0.5) * arc * 1.6
				_later(0.06 * float(i), func(): _p_bullet(m, a2, _f(m, "speed"), _f(m, "life", 0.5), int(_f(m, "pierce")), _f(m, "size", 7.0), 0.8, player.position))
		"spiral":   # Dracoenergia: espiral que sale en 0.7 s
			for i in range(14):
				var a3: float = aim + float(i) * 0.9
				_later(0.05 * float(i), func(): _p_bullet(m, a3, _f(m, "speed"), _f(m, "life", 1.0), int(_f(m, "pierce")), 6.0, 0.8, player.position))
			_ring(pos, 6.0, 50.0, col, 0.7)
		"rampage":   # Enfado: tres golpes furiosos en puntos al azar a tu alrededor
			if m.has("recoil") and not player.dead:
				player.hp = maxf(1.0, player.hp - player.max_hp * float(m["recoil"]))
			for i in range(3):
				_later(0.28 * float(i), func():
					var c: Vector2 = player.position + Vector2.from_angle(randf() * TAU) * randf_range(10.0, rad * 0.65)
					_p_hit_circle(c, rad * 0.5, m, 1.0)
					shake = maxf(shake, 2.5))
		"trio":   # Canon Floral: tres rayos en abanico tras cargar
			var angs: Array = [aim, aim - 0.5, aim + 0.5]
			for an in angs:
				_later(0.05, func(): _p_warn(player.position, an, rad, m))
				_later(0.3, func(): _p_warn(player.position, an, rad, m))
				_later(0.6, func(): _p_beam(m, an, rad, _f(m, "width", 38.0) * 0.7, 0.55))
		"flurry":   # Carantona: tres zarpazos seguidos en zig
			var seq: Array = [aim - 0.55, aim + 0.55, aim]
			for i in range(3):
				_later(0.11 * float(i), func(): _p_hit_arc(seq[i], rad, 1.4, m, 0.55))
		"slam":   # Pata Hacha: patada descendente con aviso, area delante
			var c2: Vector2 = pos + d * 58.0
			_p_tele(c2, 52.0, m, 0.3)
			_later(0.3, func():
				_p_hit_circle(c2, 52.0, m, 1.0)
				shake = maxf(shake, 4.0))
		"leap":   # Patada Salto Alta: saltas lejos y aterrizas con onda
			var dest: Vector2 = pos + d * rad
			for q in range(0, int(rad) + 1, 26):
				pfx.sp("kick", String(vis["pal"]), pos + d * float(q) + Vector2(0.0, -LIFT - 14.0 * sin(PI * float(q) / maxf(rad, 1.0))), {"life": 0.3, "angle": aim})
			player.position = dest
			player.invuln = maxf(player.invuln, 0.6)
			_later(0.25, func():
				_p_hit_circle(dest, 62.0, m, 1.0)
				shake = maxf(shake, 5.0))
		"doublesmash":   # Machada: dos martillazos, el segundo mas fuerte
			_p_hit_arc(aim, rad, arc, m, 0.5)
			_later(0.3, func():
				_p_hit_arc(player.aim, rad + 10.0, arc, m, 1.0)
				shake = maxf(shake, 5.0))
		"thrust":   # Espada Santa: estocada larguisima y fina
			_p_hit_line(pos, aim, rad, 22.0, m, 1.0)
			pfx.beam(pos + Vector2(0.0, -LIFT), aim, rad, 22.0, {"pal": String(vis["pal"]), "beam": "blade"})
			shake = maxf(shake, 2.0)
		"flamepath":   # Patada Ignea: embestida que deja un camino de brasas
			var ln: float = rad
			_p_dash_path(m, [pos, pos + d * ln], _f(m, "width", 36.0), 1.0)
			for q in range(40, int(ln) + 1, 38):
				_p_zone(pos + d * float(q), 28.0, 2.2, 0.5, m, 0.3)
		"volcano":   # Estallido: erupcion con aviso, sobre el enemigo mas cercano
			var c3: Vector2 = _p_target_pos(300.0, pos + d * 110.0)
			var r3: float = rad
			_p_tele(c3, r3, m, 0.55)
			_later(0.55, func():
				_p_hit_circle(c3, r3, m, 1.0)
				_p_radial(m, c3, 6, 220.0, 0.5, 0.4)
				_p_zone(c3, r3 * 0.8, 2.0, 0.5, m, 0.25)
				shake = maxf(shake, 5.0))
		"lashspin":   # Latigazo Igneo: el latigo gira 360 grados
			for i in range(4):
				_later(0.09 * float(i), func(): _p_hit_arc(aim + float(i) * 1.6, rad, 1.6, m, 0.5))
		"pools":   # Lluvia Ignea: 3 charcos de magma a tu alrededor
			var a0: float = randf() * TAU
			for i in range(3):
				var c4: Vector2 = pos + Vector2.from_angle(a0 + float(i) * TAU / 3.0) * randf_range(rad * 0.45, rad * 0.95)
				_p_zone(c4, 36.0, 3.4, 0.4, m, 1.0)
		"curve":   # Fuego Mistico: 3 llamas que se curvan hacia el centro
			for s2 in [-1.0, 0.0, 1.0]:
				var bc: Bullet = _p_bullet(m, aim + s2 * 0.9, _f(m, "speed"), _f(m, "life", 1.5), int(_f(m, "pierce")), _f(m, "size", 8.0))
				bc.turn = -s2 * 1.7
		"loops":   # Aire Afilado: cuchillas que dibujan bucles
			for s3 in [-1.0, 1.0]:
				var bl: Bullet = _p_bullet(m, aim, _f(m, "speed"), 2.1, 9999, _f(m, "size", 7.0))
				bl.turn = s3 * 3.0
		"lanes":   # Tajo Aereo: 5 carriles paralelos
			var o: Vector2 = d.orthogonal()
			for i in range(5):
				_p_bullet(m, aim, _f(m, "speed"), _f(m, "life", 0.55), int(_f(m, "pierce")), _f(m, "size", 6.0), 1.0, pos + o * (float(i) - 2.0) * 20.0)
		"regen":   # Batido: curacion gradual en 5 pulsos
			for i in range(5):
				_later(0.9 * float(i), func():
					if player.dead:
						return
					var hl: float = _heal_real(player.max_hp * _f(m, "amount", 0.18) / 5.0)
					if hl > 0.0:
						add_text(player.position + Vector2(randf_range(-10.0, 10.0), -player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 14)
					pfx.sp("plus", String(vis["pal"]), player.position + Vector2(randf_range(-14.0, 14.0), -player.body_h * 0.6), {"v": Vector2(0.0, -50.0), "life": 0.6}))
		"bonezone":   # Hueso Sombrio: huesos que caen y giran sobre el suelo
			var tg: Array = _p_targets(2, 320.0)
			var spots: Array = []
			for q in tg:
				spots.append(q.position)
			while spots.size() < 2:
				spots.append(pos + d * (90.0 + 70.0 * float(spots.size())))
			for sp in spots:
				_p_tele(sp, 36.0, m, 0.4)
				_later(0.4, func():
					_p_hit_circle(sp, 36.0, m, 0.6)
					_p_zone(sp, 36.0, 2.6, 0.35, m, 0.4))
		"leech":   # Drenadoras: semilla que se agarra a un enemigo y te cura
			var cap: int = maxi(1, int(_f(m, "count", 1.0)))
			if _leeches.size() < cap:
				for q in _p_targets(4, 280.0):
					var used := false
					for lc in _leeches:
						if lc["e"] == q:
							used = true
					if not used:
						_leeches.append({"e": q, "t": _f(m, "dur", 6.0), "tk": 0.1, "m": m})
						pfx.sp("seed", String(vis["pal"]), q.position + Vector2(0.0, -q.body_h * 0.6), {"life": 0.5})
						break
		"sweepbeam":   # Rayo Solar: carga y barre un arco con el rayo
			_ring(pos, 40.0, 8.0, col, 0.5, 3.0)
			var s4: float = 1.0 if randf() < 0.5 else -1.0
			for i in range(7):
				var a4: float = aim - s4 * 0.75 + s4 * 1.5 * float(i) / 6.0
				_later(0.5 + 0.07 * float(i), func(): _p_beam(m, a4, rad, _f(m, "width", 40.0) * 0.55, 0.45))
		"lobpuddle":   # Bomba Acida: bombas que dejan un charco venenoso
			var ts: Array = _p_targets(maxi(1, int(_f(m, "count", 3.0))), 300.0)
			var spots2: Array = []
			for q in ts:
				spots2.append(q.position)
			if spots2.is_empty():
				spots2.append(pos + d * 110.0)
			for i in range(spots2.size()):
				var sp2: Vector2 = spots2[i]
				_p_tele(sp2, rad, m, 0.55 + 0.1 * float(i))
				_later(0.55 + 0.1 * float(i), func():
					_p_hit_circle(sp2, rad, m, 1.0)
					_p_zone(sp2, rad * 0.9, 3.0, 0.5, m, 0.25))
		"xcut":   # Veneno X: dos cortes en cruz delante de ti
			var cc: Vector2 = pos + d * 70.0
			for sg in [0.78, -0.78]:
				var dd: Vector2 = Vector2.from_angle(aim + sg)
				_p_hit_line(cc - dd * 75.0, aim + sg, 150.0, 18.0, m, 1.0)
				pfx.beam(cc - dd * 75.0 + Vector2(0.0, -LIFT), aim + sg, 150.0, 10.0, {"pal": String(vis["pal"]), "beam": "blade"})
			pfx.sp("xmark", String(vis["pal"]), cc + Vector2(0.0, -LIFT), {"life": 0.3, "scale": 2.4, "fade": true})
		"jabs":   # Garra Venenosa: tres pinchazos rapidisimos
			for i in range(3):
				_later(0.1 * float(i), func():
					_p_hit_line(player.position, player.aim, rad, 16.0, m, 0.5)
					pfx.beam(player.position + Vector2(0.0, -LIFT), player.aim, rad, 8.0, {"pal": String(vis["pal"]), "beam": "dart"}))
		"wall":   # Onda Toxica: muro de lodo que avanza
			var o2: Vector2 = d.orthogonal()
			for i in range(7):
				_p_bullet(m, aim, _f(m, "speed", 190.0), 1.4, 3, 9.0, 0.8, pos + o2 * (float(i) - 3.0) * 17.0)
		"drilldash":   # Taladradora: embestida que arrastra enemigos y taladra 3 veces
			var ln2: float = rad
			_p_dash_path(m, [pos, pos + d * ln2], _f(m, "width", 32.0), 0.6, 55.0)
			for i in range(2):
				_later(0.1 * float(i + 1), func(): _p_hit_line(pos, aim, ln2, _f(m, "width", 32.0), m, 0.6))
		"sandmound":   # Arenas Ardientes: montones de arena ardiente sobre los enemigos
			var ts3: Array = _p_targets(3, 300.0)
			if ts3.is_empty():
				_p_zone(pos + d * 90.0, rad, 3.4, 0.4, m, 0.6)
			for q in ts3:
				_p_zone(q.position, rad, 3.4, 0.4, m, 0.6)
		"magwave":   # Magnitud: onda de potencia variable (4 a 10)
			var mg: int = [4, 5, 5, 6, 6, 7, 7, 8, 9, 10][randi() % 10]
			var kk: float = lerpf(0.5, 2.6, float(mg - 4) / 6.0)
			_p_wave(m, 10.0, rad * (0.6 + 0.1 * float(mg - 4)), 0.38, 18.0, kk)
			shake = maxf(shake, 1.0 + float(mg) * 0.5)
			add_text(pos + Vector2(0.0, -player.body_h - 22.0), "%d" % mg, col, 16)
		"track":   # Rayo Aurora: 5 pulsos que siguen al enemigo
			for i in range(5):
				_later(0.13 * float(i), func():
					var a5: float = player.aim
					var tt: Array = _p_targets(1, rad)
					if tt.size() > 0:
						a5 = (tt[0].position - player.position).angle()
					_p_beam(m, a5, rad, _f(m, "width", 30.0) * 0.6, 0.35))
		"shatter":   # Liofilizacion: cristal que se clava y estalla en esquirlas
			var tg2: Array = _p_targets(1, 320.0)
			if tg2.is_empty():
				return
			var en = tg2[0]
			var last: Vector2 = en.position
			pfx.sp("flake", String(vis["pal"]), en.position + Vector2(0.0, -en.body_h * 0.6), {"life": 0.9, "scale": 1.6, "spin": 4.0, "fade": false})
			_later(0.9, func():
				var c5: Vector2 = en.position if (is_instance_valid(en) and not en.dead) else last
				_p_hit_circle(c5, 44.0, m, 0.6)
				_p_radial(m, c5, 6, 270.0, 0.45, 0.5))
		"ricochet":   # Bola Hielo: rebota de enemigo en enemigo
			var br: Bullet = _p_bullet(m, aim, _f(m, "speed"), _f(m, "life", 1.6), 0, _f(m, "size", 9.0))
			br.ric = 4
		"collapse":   # Llama Gelida: la onda se cierra hacia ti
			_p_wave(m, rad, 12.0, 0.5, 20.0, 1.0)
		"slamring":   # Martillo Hielo: golpe y onda helada
			_p_hit_arc(aim, rad, arc, m, 0.9)
			_later(0.1, func(): _p_wave(m, 14.0, rad * 1.7, 0.3, 16.0, 0.5))
		"converge":   # Lanza Carambano: carambanos que convergen sobre el enemigo
			var c6: Vector2 = _p_target_pos(300.0, pos + d * 130.0)
			var a6: float = randf() * TAU
			for i in range(5):
				var an2: float = a6 + float(i) / 5.0 * TAU
				var st: Vector2 = c6 + Vector2.from_angle(an2) * 90.0
				_later(0.06 * float(i), func(): _p_bullet(m, an2 + PI, 330.0, 0.32, int(_f(m, "pierce")), _f(m, "size", 6.0), 1.0, st))
		"bouncepath":   # Bomba Huevo: huevo que bota tres veces y crece
			var dist: Array = [60.0, 115.0, 175.0]
			var rs: Array = [0.6, 0.8, 1.0]
			var ks: Array = [0.7, 0.9, 1.2]
			for i in range(3):
				var c7: Vector2 = pos + d * float(dist[i])
				var r7: float = rad * float(rs[i])
				_later(0.2 + 0.25 * float(i), func():
					_p_hit_circle(c7, r7, m, float(ks[i]))
					pfx.sp("bomb", String(vis["pal"]), c7 + Vector2(0.0, -10.0), {"v": Vector2(0.0, -80.0), "life": 0.3, "grav": 400.0}))
				_p_tele(c7, r7, m, 0.2 + 0.25 * float(i))
		"scatter":   # Dia de Pago: lluvia de monedas desordenada
			for i in range(8):
				_p_bullet(m, aim + randf_range(-0.65, 0.65), _f(m, "speed") * randf_range(0.6, 1.1), 0.5, 0, 5.0, 0.55)
		"claws":   # Cuchillada: tres tajos en abanico
			var offs: Array = [-0.35, 0.0, 0.35]
			for i in range(3):
				_later(0.06 * float(i), func():
					var ca: float = player.aim + float(offs[i])
					_p_hit_line(player.position, ca, rad, 12.0, m, 0.7)
					pfx.beam(player.position + Vector2(0.0, -LIFT), ca, rad, 8.0, {"pal": String(vis["pal"]), "beam": "blade"}))
		"blink":   # Golpe Bajo: te teletransportas detras del enemigo y golpeas
			var tt2: Array = _p_targets(1, _reach(m))
			if tt2.is_empty():
				_p_dash_path(m, [pos, pos + d * 80.0], 40.0, 1.0)
			else:
				var en2 = tt2[0]
				var behind: Vector2 = en2.position + (en2.position - pos).normalized() * 36.0
				for q in range(0, 5):
					pfx.sp("fist", String(vis["pal"]), pos.lerp(behind, float(q) / 4.0) + Vector2(0.0, -LIFT), {"life": 0.25, "alpha": 0.6})
				player.position = behind
				player.invuln = maxf(player.invuln, 0.5)
				_p_hit_circle(behind, 56.0, m, 1.0)
				shake = maxf(shake, 3.0)
		"mistcloud":   # Bola Neblina: nube que ralentiza y confunde
			var c8: Vector2 = _p_target_pos(300.0, pos + d * 100.0)
			_p_tele(c8, 56.0, m, 0.4)
			_later(0.4, func(): _p_zone(c8, 56.0, 3.2, 0.5, m, 0.5))
		"lockon":   # Psicochoque: fija hasta 3 blancos y no falla
			for q in _p_targets(3, _reach(m)):
				var en3 = q
				pfx.sp("twinring", String(vis["pal"]), en3.position + Vector2(0.0, -en3.body_h * 0.6), {"life": 0.4, "scale": 1.8, "spin": 6.0, "fade": false})
				_later(0.4, func():
					if is_instance_valid(en3) and not en3.dead:
						_hit_move(en3, _pk(m, 1.0), en3.position - player.position, m)
						_ring(en3.position, 4.0, 34.0, col, 0.25))
		"crossbeam":   # Psicoataque: 4 rayos en cruz alrededor
			var base: float = aim
			for i in range(4):
				var a7: float = base + float(i) * PI / 2.0
				_later(0.05, func(): _p_warn(player.position, a7, rad * 0.85, m))
				_later(0.45, func(): _p_beam(m, a7, rad * 0.85, _f(m, "width", 34.0) * 0.8, 0.6))
		"stealthmine":   # Trampa Rocosa: minas en tu rastro que sueltan esquirlas
			var n2: int = maxi(1, int(_f(m, "count", 3.0)))
			for i in range(n2):
				var f2: Field = _new_field("mine", m, pos - d * (10.0 + 34.0 * float(i)))
				f2.arm = 0.35
				f2.life = _f(m, "dur", 9.0)
				f2.r = rad
				f2.shards = 5
			_trim_fields("mine", 10)
		"cleave":   # Hachazo Petreo: tajo y esquirlas hacia delante
			_p_hit_arc(aim, rad, arc, m, 1.0)
			_later(0.12, func():
				for s5 in [-0.25, 0.0, 0.25]:
					_p_bullet(m, aim + s5, 380.0, 0.5, 2, 5.0, 0.45, player.position + d * rad * 0.6))
		"pillarring":   # Lanzas Petreas: columnas en espiral alrededor del enemigo
			var c9: Vector2 = _p_target_pos(300.0, pos + d * 120.0)
			var a8: float = randf() * TAU
			for i in range(6):
				var pp: Vector2 = c9 + Vector2.from_angle(a8 + float(i) / 6.0 * TAU) * 54.0
				_later(0.09 * float(i), func():
					_p_tele(pp, 28.0, m, 0.25)
					pfx.sp("pillar", String(vis["pal"]), pp + Vector2(0.0, -6.0), {"v": Vector2(0.0, -20.0), "life": 0.4, "scale": 1.4}))
				_later(0.09 * float(i) + 0.25, func(): _p_hit_circle(pp, 30.0, m, 0.6))
			_later(0.9, func(): _p_hit_circle(c9, 40.0, m, 1.0))
		"chainpull":   # Anclaje: cadena que arrastra al enemigo hacia ti
			var tt3: Array = _p_targets(1, _reach(m))
			if tt3.is_empty():
				return
			var en4 = tt3[0]
			pfx.beam(pos + Vector2(0.0, -LIFT), (en4.position - pos).angle(), pos.distance_to(en4.position), 6.0, {"pal": String(vis["pal"]), "beam": "anchor"})
			if not en4.boss:
				for s6 in range(1, 6):
					_later(0.05 * float(s6), func():
						if is_instance_valid(en4) and not en4.dead:
							en4.position = en4.position.lerp(player.position + (en4.position - player.position).normalized() * 30.0, 0.4))
			_later(0.3, func():
				if is_instance_valid(en4) and not en4.dead:
					_hit_move(en4, _pk(m, 1.2), en4.position - player.position, m)
					_p_hit_circle(en4.position, 44.0, m, 0.5)
					shake = maxf(shake, 4.0))
		"rooted":   # Hiperrayo: rayo colosal y quedas inmovil un momento
			_p_beam(m, aim, rad, _f(m, "width", 44.0), 1.0)
			root_t = 0.7
			shake = maxf(shake, 6.0)
		"pinch":   # Martillazo: pinza que cierra por los flancos
			_p_hit_arc(aim + 1.5, rad, 1.2, m, 0.7)
			_p_hit_arc(aim - 1.5, rad, 1.2, m, 0.7)
			_later(0.14, func(): _p_hit_arc(player.aim, rad, 1.3, m, 0.6))
		"inktrail":   # Pulpocanon: tinta que deja un reguero que ralentiza
			var bk: Bullet = _p_bullet(m, aim, _f(m, "speed"), _f(m, "life", 1.3), int(_f(m, "pierce")), _f(m, "size", 8.0))
			bk.leave = "ink"
		"vortex":   # Torbellino: remolino que arrastra a los enemigos
			var c10: Vector2 = _p_target_pos(300.0, pos + d * 90.0)
			_p_zone(c10, rad, _f(m, "dur", 3.0), 0.3, m, 0.35, 150.0)
		"windup":   # Mandoble Titanico: gran golpe tras preparar
			_ring(pos, rad * 1.3, rad * 0.4, col, 0.4, 3.0)
			_later(0.4, func():
				_p_hit_arc(player.aim, rad, arc, m, 1.0)
				_p_wave(m, 20.0, rad * 1.3, 0.25, 14.0, 0.4)
				shake = maxf(shake, 6.0))
		_:
			_melee(m)


func _in_arc(from: Vector2, p: Vector2, aim: float, half: float) -> bool:
	var a: float = (p - from).angle()
	return absf(fposmod(a - aim + PI * 3.0, TAU) - PI) <= half


const SHADOW_ARC := 2.2


func _melee(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	var arc: float = _f(m, "arc", 1.6)
	if String(m["id"]) == "lick" and bool(m.get("evolved", false)):
		arc = SHADOW_ARC   # v5.8: Puno Sombra golpea en arco al frente, nunca alrededor
	var half: float = minf(arc, TAU) * 0.5
	var mvis: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	if String(m["id"]) == "lick" and bool(m.get("evolved", false)):
		mvis["melee"] = "fist"   # v5.8: Puno Sombra, un puno de sombras con gas
		var sp0: Vector2 = player.position + Vector2.from_angle(player.aim) * rad * 0.7 + Vector2(0.0, -LIFT * 0.5)
		pfx.sp("fist", String(mvis["pal"]), sp0, {"life": 0.3, "scale": 2.0, "fade": false})
		pfx.burst(sp0, _col(m), 8, 110.0)
		for i in range([6, 3, 0][perf_lv]):
			pfx.sp("shadow", String(mvis["pal"]), sp0 + Vector2(randf_range(-30.0, 30.0), randf_range(-22.0, 22.0)), {"v": Vector2(randf_range(-20.0, 20.0), randf_range(-70.0, -35.0)), "life": randf_range(0.35, 0.6), "scale": randf_range(0.8, 1.3)})
	pfx.slash(player.position + Vector2(0.0, -LIFT * 0.5), player.aim, rad, arc, mvis)
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(player.position) > rad + e.radius * 0.5:
			continue
		if not _in_arc(player.position, e.position, player.aim, half):
			continue
		_hit_move(e, _f(m, "dmg") * _atk(), e.position - player.position, m)


func _beam(m: Dictionary) -> void:
	var ln: float = _f(m, "radius")
	var w: float = _f(m, "width", 30.0)
	var d: Vector2 = Vector2.from_angle(player.aim)
	pfx.beam(player.position + Vector2(0.0, -LIFT), player.aim, ln, w, VFX.for_move(String(m["id"]), String(m["type"])))
	shake = maxf(shake, 1.5)
	for e in enemies:
		if e.dead:
			continue
		var rel: Vector2 = e.position - player.position
		var along: float = rel.dot(d)
		if along < -e.radius or along > ln + e.radius:
			continue
		var side: float = absf(-rel.x * d.y + rel.y * d.x)
		if side <= w * 0.5 + e.radius:
			_hit_move(e, _f(m, "dmg") * _atk(), d, m)


func _aura(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	_ring(player.position, rad * 0.5, rad, _col(m), 0.28, 2.0)
	var vis: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	if vis.has("aura"):
		for i in range(5):
			var a: float = randf() * TAU
			var r: float = rad * randf_range(0.45, 1.0)
			var pos: Vector2 = player.position + Vector2(cos(a) * r, sin(a) * r * 0.8 - LIFT * 0.5)
			var v := Vector2(-sin(a) * 70.0, cos(a) * 55.0)
			if vis.has("inward"):
				v = Vector2(-cos(a) * r * 2.2, -sin(a) * r * 1.8)
			elif vis.has("rise"):
				v = Vector2(randf_range(-10.0, 10.0), -55.0)
			pfx.sp(String(vis["aura"]), String(vis["pal"]), pos, {"v": v, "life": 0.42, "spin": randf_range(-6.0, 6.0) if VFX.spins(String(vis["aura"])) else 0.0})
	var mag_k: float = 1.0
	if m.has("var"):
		mag_k = [0.5, 0.8, 1.0, 1.4, 1.9, 2.6][randi() % 6]   # Magnitud: potencia variable
	if m.has("recoil") and not player.dead:
		player.hp = maxf(1.0, player.hp - player.max_hp * float(m["recoil"]))
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(player.position) <= rad + e.radius * 0.5:
			if m.has("dream") and e.sleep_t <= 0.0:
				continue   # Come Sueños: solo afecta a enemigos dormidos
			_hit_move(e, _f(m, "dmg") * _atk() * mag_k, e.position - player.position, m)
			if m.has("heal") and not player.dead:
				var hl: float = player.max_hp * _f(m, "heal")
				player.hp = minf(player.max_hp, player.hp + hl)
				add_text(player.position + Vector2(randf_range(-10.0, 10.0), -player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 14)


func _buff(m: Dictionary) -> void:
	var stat: String = String(m["stat"])
	if stat == "heal":
		var hv: float = player.max_hp * _f(m, "amount") * _rk("healmul")
		player.hp = minf(player.max_hp, player.hp + hv)
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), "+%d" % maxi(1, roundi(hv)), Color("#7dffb0"), 16)
		Aud.sfx("heal")
		_ring(player.position, player.radius * 2.4, player.radius * 1.1, _col(m), 0.35, 2.5)
		return
	if player.buffs.has(stat):
		var b: Dictionary = player.buffs[stat]
		b["amount"] = _f(m, "amount")
		var ts: Array = b["ts"]
		var dur: float = _f(m, "dur")
		if ts.size() < int(_f(m, "stacks")):
			ts.append(dur)
		else:
			# Con el maximo de acumulaciones se renueva la que esta a punto de caducar.
			var mi := 0
			for i in range(ts.size()):
				if float(ts[i]) < float(ts[mi]):
					mi = i
			ts[mi] = dur
		b["n"] = ts.size()
		b["t"] = dur
	_ring(player.position, player.radius * 2.4, player.radius * 1.1, _col(m), 0.35, 2.5)
	var bv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	for i in range(3):
		pfx.sp(String(bv.get("buff", "arrow")), String(bv["pal"]), player.position + Vector2(randf_range(-player.radius * 1.4, player.radius * 1.4), -randf_range(0.0, player.body_h * 0.8)), {"v": Vector2(0.0, -70.0), "life": 0.6})


func _chain(m: Dictionary) -> void:
	var cur: Node2D = null
	if target != null and not target.dead and player.position.distance_to(target.position) <= _reach(m):
		cur = target
	else:
		cur = _nearest_enemy(player.position, _reach(m))
	if cur == null:
		return
	var from: Vector2 = player.position + Vector2(0.0, -LIFT)
	var k: float = 1.0
	var done := {}
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var jump: float = _f(m, "radius", 140.0)
	for i in range(n):
		if cur == null:
			break
		done[cur.get_instance_id()] = true
		var to: Vector2 = cur.position + Vector2(0.0, -cur.body_h * 0.5)
		pfx.beam(from, (to - from).angle(), (to - from).length(), 10.0, VFX.for_move(String(m["id"]), String(m["type"])))
		var hex: float = 1.0
		if m.has("hex") and (cur.burn > 0 or cur.poison > 0 or cur.slow > 0.0 or cur.para_t > 0.0 or cur.sleep_t > 0.0 or cur.frozen_t > 0.0 or cur.conf_t > 0.0):
			hex = _f(m, "hex")
		_hit_move(cur, _f(m, "dmg") * _atk() * k * hex, to - from, m)
		k *= 0.85
		from = to
		var best: Node2D = null
		var bd: float = jump * jump
		for e in enemies:
			if e.dead or done.has(e.get_instance_id()):
				continue
			var d2: float = cur.position.distance_squared_to(e.position)
			if d2 < bd:
				bd = d2
				best = e
		cur = best
	shake = maxf(shake, 1.0)


func _new_field(kind: String, m: Dictionary, pos: Vector2) -> Field:
	var f := Field.new()
	f.modulate.a = _fx_alpha()
	f.kind = kind
	f.move = m
	f.color = _col(m)
	f.vis = VFX.for_move(String(m["id"]), String(m["type"]))
	f.position = pos
	f.dmg = _f(m, "dmg") * _atk()
	if kind == "turret":
		world.add_child(f)
	else:
		gfx.add_child(f)
	fields.append(f)
	return f


func _trim_fields(kind: String, keep: int) -> void:
	var mine: Array = []
	for f in fields:
		if f.kind == kind and not f.gone:
			mine.append(f)
	var extra: int = mine.size() - keep
	for i in range(maxi(0, extra)):
		mine[i].gone = true


func _mines(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	for i in range(n):
		var a: float = randf() * TAU
		var d: float = 0.0
		if n > 1:
			d = randf_range(18.0, 46.0)
		var f: Field = _new_field("mine", m, player.position + Vector2(cos(a) * d, sin(a) * d * 0.8))
		f.arm = 0.35
		f.life = _f(m, "dur", 7.0)
		f.r = _f(m, "radius")
	_trim_fields("mine", 4 + n * 2)


func _meteors(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var near: Array = []
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) <= _reach(m):
			near.append(e)
	near.shuffle()
	for i in range(n):
		var pos: Vector2
		if i < near.size():
			pos = near[i].position + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
		else:
			pos = player.position + Vector2(randf_range(-140.0, 140.0), randf_range(-110.0, 110.0))
		var f: Field = _new_field("meteor", m, pos)
		f.t = -float(i) * 0.09
		f.fall = 0.5
		f.r = _f(m, "radius")


# v5.8: Lanza Mugre: perdigones de acido en abanico.
func _gunk_shot(m: Dictionary) -> void:
	var from: Vector2 = player.position + Vector2.from_angle(player.aim) * 20.0
	for i in range(9):
		var a: float = player.aim + randf_range(-0.42, 0.42)
		var b: Bullet = _make_bullet(m, from, Vector2.from_angle(a) * randf_range(400.0, 580.0), randf_range(0.34, 0.52), 0)
		b.dmg *= 0.6
		b.r = 8.0
		b.shape = "blob"
		b.trail = "bubbles"
	pfx.burst(from + Vector2(0.0, -LIFT * 0.5), _col(m), 10, 200.0)
	shake = maxf(shake, 5.0)


const CC_TICK := 0.06
const CC_LEN := 135.0
const CC_HALF := 0.55
const ICY_TICK := 0.16
const ICY_LEN := 250.0
const ICY_ARC := 0.95


# v5.8: Viento Hielo: rafaga continua en cono hacia donde apuntas.
func _icy_wind(m: Dictionary, k: float) -> void:
	var pal: String = String(_vis(m)["pal"])
	var d: Vector2 = Vector2.from_angle(player.aim)
	var base: Vector2 = player.position + Vector2(0.0, -LIFT * 0.6)
	for i in range([6, 4, 2][perf_lv]):
		var a: float = player.aim + randf_range(-ICY_ARC * 0.5, ICY_ARC * 0.5)
		var shape: String = "wind" if i % 2 == 0 else "grain"
		pfx.sp(shape, pal, base + Vector2.from_angle(a) * randf_range(10.0, 60.0), {"v": Vector2.from_angle(a) * randf_range(420.0, 560.0), "life": 0.42, "angle": a})
	for e in enemies:
		if e.dead or e.position.distance_to(player.position) > ICY_LEN + e.radius * 0.5:
			continue
		if _in_arc(player.position, e.position, player.aim, ICY_ARC * 0.5):
			_hit_move(e, _f(m, "dmg") * _atk() * k, d, m)


# v5.8: A Bocajarro: flurry de punos y palmas con abanico de energia, chispas, impactos y ondas, solo hacia donde apuntas.
func _close_combat_tick(m: Dictionary, k: float) -> void:
	var pal: String = String(_vis(m)["pal"])
	var col: Color = _col(m)
	var n: int = int(m.get("_cc", 0)) + 1
	m["_cc"] = n
	var base: Vector2 = player.position + Vector2(0.0, -LIFT * 0.5)
	var fwd: Vector2 = Vector2.from_angle(player.aim)
	for i in range([6, 3, 1][perf_lv]):
		var a: float = player.aim + randf_range(-CC_HALF * 0.8, CC_HALF * 0.8)
		var d: Vector2 = Vector2.from_angle(a)
		var shape: String = "chop" if (n + i) % 2 == 0 else "fist"
		var fp: Vector2 = base + d * CC_LEN * randf_range(0.15, 0.8)
		var fs: float = randf_range(420.0, 620.0) * 0.65
		var fk: float = randf_range(1.1, 1.7)
		# cada golpe sale con destello, imagen residual y chispas
		if perf_lv == 0:
			pfx.sp("impact", pal, fp - d * 8.0, {"life": 0.09, "scale": 0.9, "fr": 20.0})
			pfx.sp(shape, pal, fp - d * 18.0, {"v": d * fs * 0.6, "life": 0.11, "scale": fk * 0.85})
			pfx.spark(fp - d * 6.0, Color("#ffd86a"), d, 2)
		pfx.sp(shape, pal, fp, {"v": d * fs, "life": randf_range(0.16, 0.26), "scale": fk, "fade": false})
	if perf_lv < 2:
		if n % 2 == 0:
			pfx.slash(base, player.aim + randf_range(-0.12, 0.12), CC_LEN * 1.05, CC_HALF * 2.0, {"pal": pal})
		pfx.spark(base + fwd * 26.0, col, fwd, 3)
		var tip_a: float = player.aim + randf_range(-CC_HALF * 0.7, CC_HALF * 0.7)
		pfx.sp("impact", pal, base + Vector2.from_angle(tip_a) * CC_LEN * randf_range(0.7, 1.05), {"life": 0.16, "scale": randf_range(1.0, 1.6), "fr": 16.0, "fade": false})
		if n % 7 == 0:
			_ring(player.position + fwd * CC_LEN * 0.85, 8.0, 62.0, Color("#ffd86a"), 0.22, 4.0)
	shake = maxf(shake, 2.0)
	if n % 3 != 0:
		return
	# el dano se aplica cada tres golpes visibles para no llenar la pantalla de numeros
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) <= CC_LEN + e.radius * 0.5 and _in_arc(player.position, e.position, player.aim, CC_HALF):
			_hit_move(e, _f(m, "dmg") * _atk() * k * 3.0, fwd, m)
			var hp: Vector2 = e.position + Vector2(0.0, -e.body_h * 0.5)
			pfx.sp("impact", pal, hp, {"life": 0.18, "scale": 1.8, "fr": 14.0, "fade": false})
			pfx.burst(hp, Color("#ffd86a"), 5, 190.0)


# v5.8: Cometa Draco: meteoros grandes con estela que caen sobre los enemigos cercanos.
func _draco_meteors(m: Dictionary) -> void:
	var near: Array = []
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) <= _reach(m):
			near.append(e)
	near.shuffle()
	var vis: Dictionary = _vis(m).duplicate()
	vis["proj"] = "lava"
	vis["big"] = 3.5
	for i in range(3):
		var pos: Vector2 = player.position + Vector2(randf_range(-170.0, 170.0), randf_range(-120.0, 120.0))
		if i < near.size():
			pos = near[i].position
		var f: Field = _new_field("meteor", m, pos)
		f.vis = vis
		f.t = -float(i) * 0.2
		f.fall = 0.7
		f.r = maxf(90.0, _f(m, "radius") * 0.4)
		f.dmg *= 1.4


func _turret(m: Dictionary) -> void:
	var a: float = player.aim + PI + randf_range(-0.6, 0.6)
	var f: Field = _new_field("turret", m, player.position + Vector2(cos(a) * 26.0, sin(a) * 20.0))
	f.life = _f(m, "dur", 6.0)
	f.shot_t = 0.3
	_trim_fields("turret", maxi(1, int(_f(m, "count", 1.0))))
	_ring(player.position, 4.0, 30.0, _col(m), 0.3)


func _dash(m: Dictionary) -> void:
	var d: Vector2 = Vector2.from_angle(player.aim)
	var start: Vector2 = player.position
	var ln: float = _f(m, "radius")
	var w: float = _f(m, "width", 34.0)
	var dest: Vector2 = start + d * ln
	var dv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	for s in range(0, int(ln) + 1, 22):
		pfx.sp(String(dv.get("proj", "streak")), String(dv["pal"]), start + d * float(s) + Vector2(0.0, -LIFT * 0.6), {"life": 0.22, "angle": player.aim})
	pfx.slash(dest + Vector2(0.0, -LIFT * 0.5), player.aim, 34.0, 2.2, dv)
	player.position = dest
	player.invuln = maxf(player.invuln, _f(m, "iframes", 0.3))
	for e in enemies:
		if e.dead:
			continue
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, start, dest)
		var rr: float = w * 0.5 + e.radius
		if cp.distance_squared_to(e.position) <= rr * rr:
			_hit_move(e, _f(m, "dmg") * _atk(), d, m)
	shake = maxf(shake, 3.0)


func _trail_patch(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	# Parado no deja uno nuevo encima del anterior.
	if player.last_patch != null and is_instance_valid(player.last_patch):
		var last: Field = player.last_patch
		if last.position.distance_squared_to(player.position) < pow(rad * 0.9, 2.0) and last.t < 1.0:
			return
	var f: Field = _new_field("patch", m, player.position)
	f.life = _f(m, "dur", 3.0)
	f.r = rad
	f.tick = 0.0
	player.last_patch = f
	_trim_fields("patch", 18)


func _orbit(m: Dictionary, delta: float) -> void:
	var want: int = maxi(1, int(_f(m, "count", 1.0)))
	var mid: String = String(m["id"])
	var mine: Array = []
	for ob in bullets:
		if ob.orb and ob.mid == mid:
			mine.append(ob)
	var relayout: bool = mine.size() != want
	var base_a: float = run_time * _f(m, "speed")
	if mine.size() > 0:
		base_a = mine[0].oa
	while mine.size() > want:
		var ex = mine.pop_back()
		ex.queue_free()
		bullets.erase(ex)
	for i in range(mine.size(), want):
		var nb := Bullet.new()
		nb.modulate.a = _fx_alpha()
		nb.orb = true
		nb.mid = mid
		if bool(m.get("evolved", false)):
			evfx.track(nb, m)
		var ov: Dictionary = VFX.for_move(mid, String(m["type"]))
		nb.shape = String(ov["proj"])
		nb.pal = String(ov["pal"])
		nb.oa = float(i) / float(want) * TAU
		nb.life = 1.0e9
		nb.pierce = 999999
		nb.position = player.position
		fx.add_child(nb)
		bullets.append(nb)
		mine.append(nb)
	for i in range(mine.size()):
		var ob = mine[i]
		ob.dmg = _f(m, "dmg") * _atk()
		ob.orad = _f(m, "radius")
		if m.has("pulse"):
			ob.orad *= 1.0 + float(m["pulse"]) * sin(run_time * 1.8 + float(i) * 2.1)
		ob.ospeed = _f(m, "speed")
		ob.r = _f(m, "size", 8.0)
		ob.color = _col(m)
		ob.rehit = maxf(0.12, _f(m, "cd"))
		ob.knock = _f(m, "knock") * (1.0 if MD.KNOCK_LV.has(String(m["id"])) else 1.0 + 0.5 * float(int(m.get("lvl", 1)) - 1))   # el empuje sube con el nivel del movimiento
		ob.burn = int(_f(m, "burn"))
		ob.poison = int(_f(m, "poison"))
		ob.slow = _f(m, "slow")
		ob.cc = String(m.get("cc", ""))
		ob.ccp = _f(m, "ccp")
		ob.mtype = String(m["type"])
		ob.src = String(m["id"])
		if relayout:
			ob.oa = base_a + float(i) / float(mine.size()) * TAU
	player.orb_cast_t -= delta
	if player.orb_cast_t <= 0.0:
		player.orb_cast_t = 1.6
		player.play_attack("Shoot", 1.6)


# Tabla de tipos suavizada (types.js): x1.6 / x0.6 / x0.3, tope [0.3, 2.4]. Al jugador: debilidad x1.3 (tope 1.6).
func _types_mult(atk: String, defs: Array, for_player: bool = false) -> float:
	if not TD.CHART.has(atk):
		return 1.0
	var row: Dictionary = TD.CHART[atk]
	var m: float = 1.0
	for t in defs:
		if row.has(t):
			var v: float = float(row[t])
			if v > 1.0:
				m *= 1.3 if for_player else 1.6   # el jugador no es castigado por su tipo favorito
			elif v > 0.0:
				m *= 0.6
			else:
				m *= 0.3
	return clampf(m, 0.3, 1.6 if for_player else 2.4)


func _eff_label(k: float) -> String:
	if k > 1.05:
		return "super"
	if k < 0.95:
		return "weak"
	return ""


func _type_mult(mtype: String, e) -> float:
	return _types_mult(mtype, e.types) * _weather_mult(mtype)


func _hit_move(e, dmg: float, dir: Vector2, m: Dictionary) -> void:
	dmg_src = String(m["id"])
	cur_kind = String(m["kind"])
	_hit_enemy(e, dmg, _col(m), dir, _f(m, "knock"), String(m["type"]),
		int(_f(m, "burn")), int(_f(m, "poison")), _f(m, "slow"), String(m.get("cc", "")), _f(m, "ccp"))
	dmg_src = ""
	cur_kind = ""


var _ds_busy := false


func _hit_enemy(e, dmg: float, col: Color, dir: Vector2, knock: float, mtype: String, burn: int, poison: int, slow: float, cc: String = "", ccp: float = 0.0) -> void:
	ccp += cave.ccp_add(cc)
	slow *= cave.slow_mul()
	# Un enemigo dormido recibe un 30 % mas y se despierta (salvo si el golpe es de un movimiento que duerme).
	var was_asleep: bool = e.sleep_t > 0.0 and cc != "sleep"
	if was_asleep:
		dmg *= 1.3
	_ch_pierce(e)
	var eff: String = _eff_label(_types_mult(mtype, e.types))
	var d_final: float = dmg * _type_mult(mtype, e) * (1.5 if _has_mod("glass") else 1.0)
	if mtype == "electric" and e.para_t > 0.0:
		d_final *= 1.35   # un enemigo paralizado recibe mas daño electrico
	if eff == "super" and _has_item("expertbelt"):
		d_final *= 1.25
	if player.types.has(mtype) and _has_item("typegem"):
		d_final *= 1.2
	if mtype == "electric" and _has_item("lightball") and [172, 25, 26].has(_pdex()):
		d_final *= 2.0
	if mtype == "ground" and _has_item("thickclub") and [104, 105].has(_pdex()):
		d_final *= 1.5
	if mtype == "bug" and _has_item("silverpowder"):
		d_final *= 1.2
	elif _has_item("ti_" + mtype):
		d_final *= 1.15   # objeto de tipo: +15% y un efecto propio
		match mtype:
			"fire":
				if e.burn > 0:
					d_final *= 1.15
			"poison":
				if e.poison > 0:
					d_final *= 1.2
			"dragon":
				if e.boss:
					d_final *= 1.2
			"dark":
				if e.burn > 0 or e.poison > 0 or e.slow > 0.0 or e.para_t > 0.0 or e.sleep_t > 0.0 or e.frozen_t > 0.0 or e.conf_t > 0.0:
					d_final *= 1.2
	# S58.6 (PENDIENTE DE APROBACION, desactivado por defecto): Pokemon de un solo tipo +20% con movimientos de ese tipo, una vez por golpe.
	if bool(SV.d["settings"].get("mono_bonus", false)) and player.types.size() == 1 and String(player.types[0]) == mtype and not ab_fx.has("owntype"):
		d_final *= 1.2
	if not ab_fx.is_empty():
		if String(ab_fx.get("pinch", "")) == mtype and player.hp < player.max_hp * 0.4:
			d_final *= 1.0 + _abn("pinch_k")
		if player.types.has(mtype):
			d_final *= 1.0 + _abn("owntype")
		if ab_fx.has("typedmg"):
			d_final *= 1.0 + float((ab_fx["typedmg"] as Dictionary).get(mtype, 0.0))
		if ab_fx.has("kind_dmg") and (ab_fx["kind_dmg"] as Array).has(cur_kind):
			d_final *= 1.0 + _abn("kind_k")
		if e.boss:
			d_final *= 1.0 + _abn("boss_dmg")
		if eff == "weak":
			d_final *= 1.0 + _abn("tinted")
	var crit_p: float = minf(0.95, float(perks["crit"]) + (0.15 if _has_item("scopelens") else 0.0) + (0.05 if _has_item("ti_normal") else 0.0) + _lens_add() + _abn("crit"))
	if crit_p > 0.0 and randf() < crit_p:
		d_final *= _edge_mul()
		if _ch_on() and not _ch_rs("no_crit"):
			ch_m["crits"] = int(ch_m["crits"]) + 1
		add_text(e.position + Vector2(0.0, -e.body_h - 26.0), L.t("¡Crítico!"), Color("#ffb347"), 16)
	if _has_item("shellbell"):
		bell_heal = minf(4.0, bell_heal + d_final * 0.04)
	if mtype == "fighting" and _has_item("ti_fighting"):
		knock *= 1.4
	if mtype == "water" and _has_item("ti_water"):
		slow = maxf(slow, 0.25)
	if mtype == "poison" and _has_item("ti_poison") and poison > 0:
		poison += 1
	var amp: float = _amp_k()
	if amp > 1.0:
		ccp = minf(0.95, ccp * amp)
		if burn > 0 and randf() < amp - 1.0:
			burn += 1
		if poison > 0 and randf() < amp - 1.0:
			poison += 1
	d_final *= kec.dmg_mul(e) * kec.echo_take()
	_damage_enemy(e, d_final, col, dir, knock, eff)
	kec.on_hit(e, d_final)
	# Colmillo Vampirico (y Hechizo): solo cuenta la vida realmente recuperada; la cura no dispara nada mas.
	var fang: float = _fang_pct() + (0.03 if (mtype == "ghost" and _has_item("ti_ghost")) else 0.0)
	if fang > 0.0:
		var got: float = _heal_real(d_final * fang)
		if got >= 1.0 and randf() < 0.25:
			add_text(player.position + Vector2(randf_range(-8.0, 8.0), -player.body_h - 8.0), "+%d" % roundi(got), Color("#7dffb0"), 13)
	if e.dead:
		return
	# Golpe Doble: un segundo golpe (con critico, robo de vida y estados); nunca encadena otro Golpe Doble.
	if not _ds_busy and randf() < _dstrike_p():
		_ds_busy = true
		_hit_enemy(e, dmg, col, dir, knock, mtype, burn, poison, slow, cc, ccp)
		_ds_busy = false
		if e.dead:
			return
	if was_asleep:
		e.sleep_t = 0.0
		add_text(e.position + Vector2(0.0, -e.body_h - 18.0), "¡Despertó!", Color("#ffe9a8"), 16)
	if cc != "" and randf() < ccp:
		_apply_cc(e, cc, amp)
	if mtype == "electric" and _has_item("ti_electric") and randf() < 0.08 * amp:
		_apply_cc(e, "para", amp)
	elif mtype == "ice" and _has_item("ti_ice") and randf() < 0.06 * amp:
		_apply_cc(e, "freeze", amp)
	elif mtype == "psychic" and _has_item("ti_psychic") and randf() < 0.08 * amp:
		_apply_cc(e, "conf", amp)
	elif mtype == "fairy" and _has_item("ti_fairy") and randf() < 0.06 * amp:
		_apply_cc(e, "conf", amp * 1.3)
	if burn > 0:
		e.apply_burn(burn)
		_ch_status(e, "burn")
	if poison > 0:
		e.apply_poison(poison)
		_ch_status(e, "poison")
	if slow > 0.0:
		e.apply_slow(slow)


func _move_desc(nd: Dictionary) -> String:
	var d: String = L.t(String(nd["desc"]))
	var cc: String = String(nd.get("cc", ""))
	if cc != "" and CC_SUFFIX.has(cc) and float(nd.get("ccp", 0.0)) > 0.0:
		d += " " + L.t(String(CC_SUFFIX[cc])) % int(roundf(float(nd.get("ccp", 0.0)) * 100.0))
	return d


# Aplica un estado de control. Los jefes lo resisten: duracion mucho menor y luego quedan inmunes unos segundos.
func _apply_cc(e, kind: String, dur_k: float = 1.0) -> void:
	dur_k *= kec.cc_dur() * cave.dur_mul(kind)
	if e.dead or e.cc_imm > 0.0 or not CC_DUR.has(kind):
		return
	if kind == "sleep" and int(e.dex) == 491:
		# Darkrai (Mal Sueño): inmune al sueño.
		var now: int = Time.get_ticks_msec()
		if now - int(e.get_meta("imm_ms", -9999)) > 1500:
			e.set_meta("imm_ms", now)
			add_text(e.position + Vector2(0.0, -e.body_h - 18.0), "¡Inmune!", Color("#c8d0dc"), 16)
		return
	if kind == "charm":
		# Enamorado: los jefes son inmunes y, tras acabarse, hay un respiro para que no se encadene sin fin
		if e.boss or e.charm_t > 0.0 or e.charm_imm > 0.0:
			if e.boss and run_time - float(e.get_meta("imm_t", -99.0)) > 1.5:
				e.set_meta("imm_t", run_time)
				add_text(e.position + Vector2(0.0, -e.body_h - 18.0), L.t("¡Inmune!"), Color("#c8d0dc"), 16)
			return
		dur_k = minf(dur_k, 1.6) * (1.3 if _has_item("ti_fairy") else 1.0)
	if (e.frozen_t > 0.0 or e.sleep_t > 0.0) and (kind == "conf" or kind == "para"):
		return
	var dur: float = float(CC_DUR[kind]) * dur_k
	if e.boss:
		dur *= 0.35 if (kind == "freeze" or kind == "sleep") else 0.5
		e.cc_imm = dur + 4.0
	var fresh: bool = false
	match kind:
		"freeze":
			fresh = e.frozen_t <= 0.0
			e.frozen_t = maxf(e.frozen_t, dur)
			e.sleep_t = 0.0
			e.conf_t = 0.0
		"sleep":
			fresh = e.sleep_t <= 0.0
			e.sleep_t = maxf(e.sleep_t, dur)
			e.conf_t = 0.0
		"para":
			fresh = e.para_t <= 0.0
			e.para_t = maxf(e.para_t, dur)
		"conf":
			fresh = e.conf_t <= 0.0
			e.conf_t = maxf(e.conf_t, dur)
		"charm":
			fresh = true
			e.charm_t = dur
			e.frozen_t = 0.0
			e.sleep_t = 0.0
			e.conf_t = 0.0
	if fresh:
		_ch_status(e, kind)
		var cc_col := Color.html(String(CC_COL[kind]))
		add_text(e.position + Vector2(0.0, -e.body_h - 18.0), String(CC_TEXT[kind]), cc_col, 16)
		_ring(e.position, 4.0, e.radius * 2.2, cc_col, 0.35, 2.5)


# Humo, hielo, chispas y estrellitas segun el estado.
func _cc_fx(e, delta: float) -> void:
	if e.frozen_t <= 0.0 and e.sleep_t <= 0.0 and e.para_t <= 0.0 and e.conf_t <= 0.0 and e.charm_t <= 0.0:
		return
	e.cc_fx -= delta
	if e.cc_fx > 0.0 or not e.visible:
		return
	e.cc_fx = 0.22
	var base: Vector2 = e.position + Vector2(randf_range(-e.radius, e.radius), -randf_range(2.0, maxf(8.0, e.body_h * 0.9)))
	if e.frozen_t > 0.0:
		pfx.px(base, Color("#d8f6ff"), Vector2(randf_range(-8.0, 8.0), -10.0), 0.6, 1.6, 40.0)
	elif e.sleep_t > 0.0:
		add_text(e.position + Vector2(e.radius * 0.6, -e.body_h - 6.0), "Z", Color("#b9b6ff"), 14)
	elif e.charm_t > 0.0:
		add_text(e.position + Vector2(randf_range(-6.0, 6.0), -e.body_h - 6.0), "♥", Color("#ff6fa8"), 15)
	elif e.conf_t > 0.0:
		pfx.px(e.position + Vector2(cos(e.bob * 2.0) * e.radius, -e.body_h - 4.0 + sin(e.bob * 2.0) * 3.0), Color("#ff7ad9"), Vector2(0.0, -6.0), 0.5, 2.0)
	elif e.para_t > 0.0:
		pfx.px(base, Color("#ffe14d"), Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 10.0)), 0.25, 1.6, 0.0)


# Enemigo enamorado: lucha de tu lado. Persigue a otro enemigo y le pega; sin rivales, se queda cerca de ti. Nunca te ataca.
func _charmed_step(e: Enemy, delta: float, kn_decay: float, spd: float) -> void:
	e.conf_cd = maxf(0.0, e.conf_cd - delta)
	var tgt = null
	var best: float = 420.0
	for o in enemies:
		if o == e or o.dead or o.charm_t > 0.0:
			continue
		var dd: float = o.position.distance_to(e.position)
		if dd < best:
			best = dd
			tgt = o
	var ang: float
	var mv := 1.0
	if tgt != null:
		ang = (tgt.position - e.position).angle()
	else:
		var tp: Vector2 = player.position - e.position
		ang = tp.angle()
		if tp.length() < 90.0:
			mv = 0.0
	e.position += (Vector2.from_angle(ang) * spd * 1.1 * mv + e.knock) * delta
	if not e.flying:
		e.position = _collide(e.position, e.radius * 0.5)
	e.knock *= kn_decay
	e.face_angle(ang)
	e.loop_anim("Walk" if mv > 0.0 else "Idle", 1.2)
	if tgt != null and e.conf_cd <= 0.0 and best <= e.radius + tgt.radius + 6.0:
		e.conf_cd = 0.6
		e.strike((tgt.position - e.position).angle())
		var pct: float = 0.012 if tgt.boss else 0.03
		_damage_enemy(tgt, e.dmg * 2.0 + tgt.max_hp * pct, Color("#ff6fa8"), (tgt.position - e.position).normalized(), 140.0)


# Enemigo confundido: vaga sin rumbo, persigue a otro enemigo y le pega (ya no te ataca).
func _confused_step(e: Enemy, delta: float, kn_decay: float, spd: float) -> void:
	e.conf_cd = maxf(0.0, e.conf_cd - delta)
	var tgt = null
	var best: float = 380.0
	for o in enemies:
		if o == e or o.dead:
			continue
		var dd: float = o.position.distance_to(e.position)
		if dd < best:
			best = dd
			tgt = o
	var ang: float
	e.zig += delta
	if tgt != null:
		ang = (tgt.position - e.position).angle() + sin(e.zig * 5.0) * 0.5
	else:
		ang = e.bob + e.zig * 1.3
	var v: Vector2 = Vector2.from_angle(ang) * spd * 0.9
	e.position += (v + e.knock) * delta
	if not e.flying:
		e.position = _collide(e.position, e.radius * 0.5)
	e.knock *= kn_decay
	e.face_angle(ang)
	e.loop_anim("Walk", 1.2)
	if tgt != null and e.conf_cd <= 0.0 and best <= e.radius + tgt.radius + 6.0:
		e.conf_cd = 0.6
		e.strike((tgt.position - e.position).angle())
		var pct: float = 0.012 if tgt.boss else 0.03
		var hit: float = e.dmg * 1.8 + tgt.max_hp * pct
		_damage_enemy(tgt, hit, Color("#ff7ad9"), (tgt.position - e.position).normalized(), 140.0)
		if tgt.sleep_t > 0.0:
			tgt.sleep_t = 0.0


func _ring(pos: Vector2, r0: float, r1: float, color: Color, life: float, width: float = 3.0) -> void:
	pfx.ring(pos + Vector2(0.0, -LIFT * 0.5), r0, r1, color, life, width)


# ---------------------------------------------------------------
# Campos persistentes: minas, meteoros, torretas, charcos
# ---------------------------------------------------------------
func _blast(f: Field, r: float, k: float) -> void:
	var m: Dictionary = f.move
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(f.position) <= r + e.radius * 0.5:
			_hit_move(e, f.dmg * k, e.position - f.position, m)


func _update_fields(delta: float) -> void:
	for i in range(fields.size() - 1, -1, -1):
		var f: Field = fields[i]
		f.t += delta
		if f.gone or (f.life > 0.0 and f.t >= f.life and f.kind != "mine"):
			f.queue_free()
			fields.remove_at(i)
			continue
		var m: Dictionary = f.move
		if f.kind == "mine":
			var trig: bool = false
			if f.t >= f.arm:
				for e in enemies:
					if not e.dead and e.position.distance_to(f.position) <= 14.0 + e.radius * 0.5:
						trig = true
						break
			if trig or f.t >= f.life:
				_ring(f.position, 4.0, f.r, f.color, 0.3)
				pfx.burst(f.position + Vector2(0.0, -6.0), f.color, 10, 150.0)
				shake = maxf(shake, 2.0)
				_blast(f, f.r, 1.0 if trig else 0.5)
				if f.shards > 0:
					_p_radial(m, f.position, f.shards, 250.0, 0.45, 0.5)
				f.queue_free()
				fields.remove_at(i)
		elif f.kind == "meteor":
			if f.t >= f.fall:
				_ring(f.position, 4.0, f.r, f.color, 0.35)
				pfx.burst(f.position + Vector2(0.0, -6.0), f.color, 12, 170.0)
				shake = maxf(shake, 4.0)
				if f.vis.has("big"):
					_ring(f.position, 8.0, f.r * 1.3, Color.WHITE, 0.3, 4.0)
					pfx.burst(f.position + Vector2(0.0, -10.0), Color.WHITE, 10, 240.0)
					shake = maxf(shake, 9.0)
				_blast(f, f.r, 1.0)
				f.queue_free()
				fields.remove_at(i)
		elif f.kind == "turret":
			f.shot_t -= delta
			if f.shot_t <= 0.0:
				var tg: Node2D = _nearest_enemy(f.position, _f(m, "range", 300.0))
				f.shot_t = 0.15
				if tg != null:
					f.shot_t = _f(m, "rate", 0.6)
					var d: Vector2 = (tg.position - f.position).normalized()
					var b: Bullet = _make_bullet(m, f.position, d * _f(m, "speed", 300.0), 1.4, int(_f(m, "pierce")))
					b.dmg = f.dmg
					b.r = _f(m, "size", 6.0)
					f.kick = 0.12
			if f.kick > 0.0:
				f.kick -= delta
		elif f.kind == "patch":
			f.tick -= delta
			if f.tick <= 0.0:
				f.tick = 0.5
				_blast(f, f.r, 1.0)
			if f.vis.has("aura") and randf() < delta * 3.0:
				var ap: Vector2 = f.position + Vector2(randf_range(-f.r, f.r) * 0.6, -4.0)
				pfx.sp(String(f.vis["aura"]), String(f.vis["pal"]), ap, {"v": Vector2(0.0, -40.0), "life": 0.4})


# Enemigos: datos, reparto de la run, oleadas, jefes, eventos y comportamientos
# (enemies.js, spawner.js, enemy.js, hazards.js, events.js)
# ---------------------------------------------------------------
static var _dex_list: Array = []
static var _dex_by: Dictionary = {}
static var _smeta: Dictionary = {}


func _load_data() -> void:
	SV.ensure()
	_dex_list = SV.dex_list
	_dex_by = SV.dex_by
	_smeta = SV.smeta


func _sm(dex: int) -> Dictionary:
	return _smeta[str(dex)]


# Hash determinista (util.js) con enteros de 32 bits.
func _hash(x: int, y: int, seed_v: int) -> float:
	var h: int = ((x & 0xFFFFFFFF) * 374761393) & 0xFFFFFFFF
	h = h ^ (((y & 0xFFFFFFFF) * 668265263) & 0xFFFFFFFF)
	h = h ^ (((seed_v & 0xFFFFFFFF) * 2246822519) & 0xFFFFFFFF)
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFFFF) / 4294967296.0


func _pick_n(arr: Array, n: int) -> Array:
	var c: Array = arr.duplicate()
	c.shuffle()
	return c.slice(0, mini(n, c.size()))


func _has_t(types: Array, xs: Array) -> bool:
	for x in xs:
		if types.has(x):
			return true
	return false


func _base_hp(p: Dictionary) -> float:
	return (float(p["hp"]) - 70.0) / 0.45


func _base_spd(p: Dictionary) -> float:
	return (float(p["spd"]) - 78.0) / 0.42


static var _beh_cache: Dictionary = {}


func _behavior_of(p: Dictionary) -> String:
	var dex: int = int(p["dex"])
	if _beh_cache.has(dex):
		return String(_beh_cache[dex])
	var r: String = _behavior_calc(p)
	_beh_cache[dex] = r
	return r


func _behavior_calc(p: Dictionary) -> String:
	var dex: int = int(p["dex"])
	var t: Array = p["types"]
	var h: float = _hash(dex, 7, 11)
	if HEAL_SET.has(dex):
		return "healer"
	if SHIELD_SET.has(dex):
		return "shielder"
	if BOMB_SET.has(dex):
		return "bomber"
	if SUMMON_MAP.has(dex) and _smeta.has(str(SUMMON_MAP[dex])):
		return "summoner"
	if _has_t(t, ["bug"]) and h >= 0.6 and h < 0.78:
		return "summoner"
	if _has_t(t, ["electric", "psychic", "dragon", "ice"]) and h < 0.18:
		return "beamer"
	if _has_t(t, ["fire", "ground", "poison"]) and h < 0.18:
		return "zoner"
	if _has_t(t, ["water", "grass", "bug", "fairy"]) and h >= 0.18 and h < 0.32:
		return "fan"
	if _has_t(t, ["fighting", "ground", "normal", "rock"]) and h >= 0.42 and h < 0.56:
		return "jumper"
	if _has_t(t, ["psychic", "electric", "ghost", "fairy"]) and h < 0.4:
		return "ranged"
	if _has_t(t, ["fire", "water", "poison", "ice"]) and h < 0.22:
		return "ranged"
	if _has_t(t, ["fighting", "normal", "ground", "rock", "dragon", "steel", "dark"]) and h < 0.4:
		return "charger"
	if _base_hp(p) > 95.0 and _base_spd(p) < 50.0:
		return "tank"
	return "chase"


func _def_for(p: Dictionary, tier: Dictionary, ti: int) -> Dictionary:
	var hp_k: float = clampf(_base_hp(p) / 65.0, 0.7, 1.6)
	var spd_k: float = clampf(0.75 + _base_spd(p) / 260.0, 0.75, 1.3)
	var b: String = _behavior_of(p)
	var tank: bool = b == "tank"
	var d := {
		"dex": int(p["dex"]), "name": String(p["name"]), "behavior": b,
		"hp": roundf(float(tier["hp"]) * hp_k * (1.5 if tank else 1.0)),
		"spd": roundf(float(tier["spd"]) * spd_k * (0.7 if tank else 1.0)),
		"dmg": roundf(float(tier["dmg"]) * (1.2 if tank else 1.0)),
		"xp": maxf(3.0, roundf(float(tier["xp"]) * (1.3 if tank else 1.0))),
	}
	var cds := {"ranged": 2.2 - float(ti) * 0.15, "fan": 3.2 - float(ti) * 0.15, "beamer": 4.4 - float(ti) * 0.2,
		"zoner": 4.6 - float(ti) * 0.2, "healer": 3.5, "summoner": 7.0}
	if cds.has(b):
		d["shotDmg"] = roundf(float(tier["dmg"]) * (0.7 if b == "fan" else 0.8))
		d["shotCd"] = snappedf(float(cds[b]), 0.01)
		var rg: float = 190.0
		if b == "beamer":
			rg = 260.0
		elif b == "healer" or b == "summoner":
			rg = 230.0
		d["range"] = rg + float(ti) * 6.0
	if b == "summoner":
		d["minion"] = int(SUMMON_MAP.get(int(p["dex"]), int(p["dex"])))
	if b == "fan":
		d["fanN"] = 3 if ti < 2 else 5
	if b == "zoner":
		d["zones"] = 1 if ti < 2 else (2 if ti < 4 else 3)
	if b == "bomber":
		d["spd"] = roundf(float(d["spd"]) * 1.25)
		d["hp"] = roundf(float(d["hp"]) * 0.8)
	return d


static var _cand_cache: Dictionary = {}


func _candidates(ti: int) -> Array:
	if _cand_cache.has(ti):
		return _cand_cache[ti]
	var tier: Dictionary = TIERS[ti]
	var lo: float = float(tier["bst"][0])
	var hi: float = float(tier["bst"][1])
	var out: Array = []
	for p in _dex_list:
		if int(p["rarity"]) < 5 and float(p["bst"]) >= lo and float(p["bst"]) <= hi and _smeta.has(str(int(p["dex"]))):
			out.append(p)
	if mode == "type":
		var only: Array = []
		for p in out:
			if (p["types"] as Array).has(SV.run_type):
				only.append(p)
		if not only.is_empty():
			out = only
	_cand_cache[ti] = out
	return out


func _cast_for(ti: int) -> Array:
	var tier: Dictionary = TIERS[ti]
	var all: Array = _candidates(ti)
	var kinds: Array = []
	for k in SUPPORT_B:
		for p in all:
			if _behavior_of(p) == k:
				kinds.append(k)
				break
	var pick: Array = []
	if not kinds.is_empty():
		var sk: String = String(kinds[randi() % kinds.size()])
		var pool_s: Array = []
		for p in all:
			if _behavior_of(p) == sk:
				pool_s.append(p)
		pick = _pick_n(pool_s, 1)
	var need: int = int(tier["cast"])
	if int(tier["from"]) > 0:
		var pool_x: Array = []
		for p in all:
			var bb: String = _behavior_of(p)
			if not PLAIN_B.has(bb) and not SUPPORT_B.has(bb):
				pool_x.append(p)
		pick.append_array(_pick_n(pool_x, 1))
	var rest: Array = []
	for p in all:
		if pick.has(p):
			continue
		if int(tier["from"]) == 0 and not PLAIN_B.has(_behavior_of(p)):
			continue
		rest.append(p)
	pick.append_array(_pick_n(rest, need - pick.size()))
	return pick


func _has_mod(id: String) -> bool:
	return mods.has(id)


# ---------------------------------------------------------------
# Retos de 10 minutos: contadores de objetivos, restricciones y resultado
# ---------------------------------------------------------------
func _ch_setup() -> void:
	ch_inst = SV.run_chal.duplicate()
	ch_def = CH.by_id(int(ch_inst.get("id", 0)))
	ch_m = CH.new_metrics()
	ch_m["boss_clean"] = 0
	ch_sets = {"burn": {}, "poison": {}, "freeze": {}, "para": {}, "sleep": {}, "conf": {}, "charm": {}}
	mods = []
	if ch_def.is_empty():
		return
	var rs: Dictionary = ch_def["rs"]
	if rs.has("frail"):
		mods.append("frail")
	if rs.has("no_heal") or rs.has("one_hp"):
		mods.append("nohealing")


func _ch_on() -> bool:
	return mode == "chal" and not ch_def.is_empty() and not ch_over


func _ch_rs(k: String) -> bool:
	return (ch_def.get("rs", {}) as Dictionary).has(k)


func _max_moves() -> int:
	if mode == "chal" and _ch_rs("one_move"):
		return 1
	if mode == "chal" and _ch_rs("max_moves"):
		return 2
	return MAX_MOVES + clampi(int(perks.get("wslots", 0)), 0, 2)   # 4 base + hasta 2 comprados (Seccion 50)


# Un enemigo recibe un estado (burn, poison, freeze, para, sleep, conf).
func _ch_status(e, kind: String) -> void:
	if not _ch_on() or _ch_rs("no_status") or not ch_sets.has(kind):
		return
	var id: int = e.get_instance_id()
	(ch_sets[kind] as Dictionary)[id] = true
	var ms: Dictionary = ch_multi.get(id, {})
	ms[kind] = true
	ch_multi[id] = ms
	var kinds := 0
	var multi := 0
	for k in ch_sets:
		if not (ch_sets[k] as Dictionary).is_empty():
			kinds += 1
	for eid in ch_multi:
		if (ch_multi[eid] as Dictionary).size() >= 2:
			multi += 1
	ch_m["kinds"] = kinds
	ch_m["multi_status_n"] = multi
	ch_m["burn_n"] = (ch_sets["burn"] as Dictionary).size()
	ch_m["poison_n"] = (ch_sets["poison"] as Dictionary).size()
	ch_m["freeze_n"] = (ch_sets["freeze"] as Dictionary).size()
	ch_m["para_n"] = (ch_sets["para"] as Dictionary).size()
	ch_m["infat_n"] = (ch_sets["charm"] as Dictionary).size()


# Cada golpe: cuenta los ataques que alcanzan a 3 o mas enemigos a la vez.
func _ch_pierce(e) -> void:
	if not _ch_on() or dmg_src == "":
		return
	e.set_meta("ch_src", dmg_src)   # los estados (quemadura, veneno) rematan: la derrota cuenta para el último movimiento que lo golpeó
	var f: int = Engine.get_physics_frames()
	var h: Array = ch_hits.get(dmg_src, [-1, 0, false])
	if int(h[0]) != f:
		h = [f, 0, false]
	h[1] = int(h[1]) + 1
	if int(h[1]) >= 3 and not bool(h[2]):
		h[2] = true
		ch_m["pierce3"] = int(ch_m["pierce3"]) + 1
	ch_hits[dmg_src] = h


func _ch_kill(e, src: String) -> void:
	if not _ch_on():
		return
	ch_m["kills"] = kills
	if e.boss and not e.judge:
		ch_m["bosses"] = int(ch_m["bosses"]) + 1
		if e.has_meta("ch_t") and ch_last_hurt < float(e.get_meta("ch_t")):
			ch_m["boss_clean"] = int(ch_m["boss_clean"]) + 1   # jefe derrotado sin recibir ningún daño mientras estuvo en pantalla
	if not _ch_rs("no_status"):
		var cc_any: bool = e.frozen_t > 0.0 or e.sleep_t > 0.0 or e.para_t > 0.0 or e.conf_t > 0.0 or e.charm_t > 0.0
		if cc_any or e.burn > 0 or e.poison > 0:
			ch_m["kills_status"] = int(ch_m["kills_status"]) + 1
		if cc_any:
			ch_m["kills_cc"] = int(ch_m["kills_cc"]) + 1
	if src == "_other" and e.has_meta("ch_src"):
		src = String(e.get_meta("ch_src"))
	if src != "" and MD.MOVES.has(src):
		var md: Dictionary = MD.MOVES[src]
		var ty: String = String(md["type"])
		ch_m["kt_" + ty] = int(ch_m.get("kt_" + ty, 0)) + 1
		ch_src_kills[src] = int(ch_src_kills.get(src, 0)) + 1
		var kd: String = String(md["kind"])
		if ["projectile", "boomerang", "turret", "chain", "beam"].has(kd):
			ch_m["kills_proj"] = int(ch_m["kills_proj"]) + 1
		elif ["melee", "dash", "orbit"].has(kd):
			ch_m["kills_melee"] = int(ch_m["kills_melee"]) + 1
		elif ["aura", "nova", "meteor", "mine", "cone", "trail"].has(kd):
			ch_m["kills_aoe"] = int(ch_m["kills_aoe"]) + 1
		var m20 := 0
		for k in ch_src_kills:
			if int(ch_src_kills[k]) >= 20:
				m20 += 1
		ch_m["moves_20"] = m20
		var t10 := 0
		for k2 in ch_m:
			if String(k2).begins_with("kt_") and int(ch_m[k2]) >= 10:
				t10 += 1
		ch_m["types_10"] = t10
		var t20 := 0
		for k3 in ch_m:
			if String(k3).begins_with("kt_") and int(ch_m[k3]) >= 20:
				t20 += 1
		ch_m["types_20"] = t20


func _ch_tick(delta: float) -> void:
	if not _ch_on():
		return
	if _ch_rs("one_hp") and player != null:
		player.max_hp = 1.0
		player.hp = minf(player.hp, 1.0)
	ch_m["time"] = run_time
	ch_m["kills"] = kills
	ch_m["coins"] = coins
	ch_m["equipped"] = maxi(int(ch_m["equipped"]), _slot_list().size())
	ch_m["gacha_unlock"] = GPM.unlocked().size()
	ch_m["new_move"] = GPM.unlocked().size()
	ch_m["bonded"] = maxi(int(ch_m["bonded"]), bond_pairs.size() * 2)
	var cur: float = run_time - ch_last_hurt
	ch_m["nodmg_cur"] = cur
	ch_m["nodmg"] = maxf(float(ch_m["nodmg"]), cur)
	if player.position.distance_to(ch_prev_pos) > 0.05:
		ch_moved_min[int(run_time / 60.0)] = true
	ch_prev_pos = player.position
	ch_m["move_min"] = ch_moved_min.size()
	ch_m["loot"] = run_chests
	ch_check_t -= delta
	if ch_check_t > 0.0:
		return
	ch_check_t = 0.4
	hud.ch_lines = CH.lines(ch_def, ch_m)
	for e in enemies:
		if e.boss and not e.has_meta("ch_t"):
			e.set_meta("ch_t", run_time)
	if run_time >= CH.CH_TIME:
		ch_m["survive_full"] = 1
		_ch_finish(CH.succeeded(ch_def, ch_m))
	elif CH.succeeded(ch_def, ch_m):
		_ch_finish(true)


func _ch_finish(ok: bool) -> void:
	if ch_over:
		return
	ch_over = true
	timeup = true
	hud.timeup = true
	if ok:
		var got: String = CH.grant(ch_inst)
		hud.end_big = L.t("¡RETO SUPERADO!")
		if got == "gold":
			hud.end_l1 = L.t("Premio: 1 Gachapon Coin Dorada")
		elif got == "coin":
			hud.end_l1 = L.t("Premio: 1 Gachapon Coin")
		else:
			hud.end_l1 = L.t("Premio ya reclamado antes")
		Aud.sfx("bossDown")
	else:
		hud.end_big = L.t("¡TIEMPO!")
		hud.end_l1 = L.t("Has fallado el reto...")
	hud.end_l2 = CH.name_of(ch_def)
	player.dead = true
	player.active = false
	_clear_orbit_orbs()
	for e in enemies:
		e.active = false


func _mode_label() -> String:
	match mode:
		"daily":
			return L.t("Desafío diario")
		"rush":
			return L.t("Rush de Jefes")
		"party":
			return L.t("Modo Fiesta")
		"type":
			return L.t("Supervivencia por tipo")
		"team":
			return L.t("Modo Equipo")
		"rifts":
			return L.t("Contrarreloj de grietas")
		"tower":
			return L.t("La torre")
		"coop":
			return L.t("Modo Cooperativo")
		"chal":
			return CH.name_of(ch_def) if not ch_def.is_empty() else L.t("Retos de 10 minutos")
	return ""


# Jefe numero i del Rush: sube de dificultad; cada tercero es un legendario.
func _rush_def(i: int) -> Dictionary:
	var leg: bool = i % 3 == 2
	var lo: float = minf(640.0, 490.0 + float(i) * 14.0)
	var pool: Array = []
	for p in _dex_list:
		var dx: int = int(p["dex"])
		if not _smeta.has(str(dx)) or bool(p.get("leg", false)) != leg:
			continue
		if leg or (float(p["bst"]) >= lo and float(p["bst"]) <= lo + 110.0):
			pool.append(p)
	if pool.is_empty():
		for p in _dex_list:
			if not bool(p.get("leg", false)) and _smeta.has(str(int(p["dex"]))) and float(p["bst"]) >= 480.0:
				pool.append(p)
	var bp: Dictionary = pool[randi() % pool.size()]
	var bb: String = "chase"
	if _behavior_of(bp) == "ranged":
		bb = "ranged"
	elif _base_spd(bp) > 90.0:
		bb = "charger"
	var hp: float = 1400.0 * pow(1.27, float(i))
	var dm: float = minf(150.0, 34.0 + 5.0 * float(i))
	return {"at": 0.0, "dex": int(bp["dex"]), "name": String(bp["name"]), "hp": roundf(hp * 1.35),
		"spd": roundf(clampf(40.0 + _base_spd(bp) * 0.5, 40.0, 100.0)), "dmg": roundf(dm * 1.2),
		"xp": float(_xp_for(player.level)) * 1.25, "behavior": bb, "shotDmg": roundf(dm * 0.55), "shotCd": 1.1, "range": 260.0}


func _roll_run() -> void:
	cast_run = []
	for ti in range(TIERS.size()):
		var list: Array = []
		for p in _cast_for(ti):
			list.append(_def_for(p, TIERS[ti], ti))
		cast_run.append({"from": int(TIERS[ti]["from"]), "list": list})
	# En cada tramo, el mas rapido de los normales pasa a ser el corredor.
	for tier in cast_run:
		var best: Dictionary = {}
		for d in tier["list"]:
			var bb: String = String(d["behavior"])
			if bb == "chase" or bb == "charger" or bb == "tank":
				if best.is_empty() or float(d["spd"]) > float(best["spd"]):
					best = d
		if not best.is_empty():
			best["behavior"] = "runner"
			best["spd"] = roundf(float(best["spd"]) * 1.6)
			best["hp"] = roundf(float(best["hp"]) * 0.7)
	boss_run = []
	var used := {}
	for slot in BOSS_SLOTS:
		var pool: Array = []
		for p in _dex_list:
			var dx: int = int(p["dex"])
			if bool(p.get("leg", false)) or not _smeta.has(str(dx)) or used.has(dx):
				continue
			if mode == "type" and not (p["types"] as Array).has(SV.run_type):
				continue
			if float(p["bst"]) >= float(slot["bst"][0]) and float(p["bst"]) <= float(slot["bst"][1]):
				pool.append(p)
		if pool.is_empty():
			for p in _dex_list:
				var dx2: int = int(p["dex"])
				if not bool(p.get("leg", false)) and _smeta.has(str(dx2)) and not used.has(dx2) and float(p["bst"]) >= 580.0 and (mode != "type" or (p["types"] as Array).has(SV.run_type)):
					pool.append(p)
		if pool.is_empty() and mode == "type":
			for p in _dex_list:
				var dx4: int = int(p["dex"])
				if not bool(p.get("leg", false)) and _smeta.has(str(dx4)) and not used.has(dx4) and (p["types"] as Array).has(SV.run_type):
					pool.append(p)
		if pool.is_empty():
			for p in _dex_list:
				var dx3: int = int(p["dex"])
				if not bool(p.get("leg", false)) and _smeta.has(str(dx3)) and not used.has(dx3) and float(p["bst"]) >= 480.0:
					pool.append(p)
		var bp: Dictionary = pool[randi() % pool.size()]
		used[int(bp["dex"])] = true
		var bb2: String = "chase"
		if _behavior_of(bp) == "ranged":
			bb2 = "ranged"
		elif _base_spd(bp) > 90.0:
			bb2 = "charger"
		boss_run.append({
			"at": float(slot["at"]), "dex": int(bp["dex"]), "name": String(bp["name"]),
			"hp": roundf(float(slot["hp"]) * 1.35), "spd": roundf(clampf(40.0 + _base_spd(bp) * 0.5, 40.0, 100.0)),
			"dmg": roundf(float(slot["dmg"]) * 1.2), "xp": float(slot["xp"]), "behavior": bb2,
			"shotDmg": roundf(float(slot["dmg"]) * 0.55), "shotCd": 1.1, "range": 260.0,
		})


func _tier_at(t: float) -> int:
	var ti: int = 0
	for i in range(TIERS.size()):
		if t >= float(TIERS[i]["from"]):
			ti = i
	return ti


func _biome_key(b: int) -> String:
	b = posmod(b, ground.count())
	if b < 3:
		return ["forest", "cave", "volcano"][b]
	return String(ground.theme_keys[b - 3])


func _biome_types(key: String) -> Array:
	return BIOME_TYPES.get(key, [key])


# Pokemon extra de un tramo, propios de un bioma (se eligen al necesitarlos y se guardan para toda la run)
func _bio_extra(ti: int, key: String) -> Array:
	var tier_run: Dictionary = cast_run[ti]
	if not tier_run.has("bio"):
		tier_run["bio"] = {}
	var bio: Dictionary = tier_run["bio"]
	if bio.has(key):
		return bio[key]
	var tier: Dictionary = TIERS[ti]
	var have := {}
	for d in tier_run["list"]:
		have[int(d["dex"])] = true
	var pool: Array = []
	for p in _candidates(ti):
		if have.has(int(p["dex"])) or not _fits_biome(p, key):
			continue
		var bb: String = _behavior_of(p)
		if SUPPORT_B.has(bb) or (int(tier["from"]) == 0 and not PLAIN_B.has(bb)):
			continue
		pool.append(p)
	# primero los Pokemon propios del bioma (murcielagos, castillos de arena...), luego el resto de tipos
	var special: Array = []
	var by_type: Array = []
	var dl: Array = BIOME_DEX.get(key, [])
	for p in pool:
		if dl.has(int(p["dex"])):
			special.append(p)
		else:
			by_type.append(p)
	var chosen: Array = _pick_n(special, BIOME_EXTRA)
	chosen.append_array(_pick_n(by_type, BIOME_EXTRA - chosen.size()))
	var out: Array = []
	for p in chosen:
		out.append(_def_for(p, tier, ti))
	bio[key] = out
	return out


func _fits_biome(p: Dictionary, key: String) -> bool:
	return _has_t(p["types"], _biome_types(key)) or (BIOME_DEX.get(key, []) as Array).has(int(p["dex"]))


func _bag_at(t: float) -> Array:
	if event_id == "horde" and not horde_defs.is_empty():
		return horde_defs
	var bag: Array = []
	var key: String = _biome_key(biome_idx) if arena == null and mode != "type" else ""
	for ti in range(cast_run.size()):
		var tier: Dictionary = cast_run[ti]
		if t < float(tier["from"]):
			continue
		var w: int = 3 if t - float(tier["from"]) > 260.0 else 10
		for d in tier["list"]:
			var wd: int = w
			if key != "" and _fits_biome(_dex_by[int(d["dex"])], key):
				wd = roundi(float(w) * BIOME_W_MUL)
			if dn != null:
				wd = roundi(float(wd) * dn.weight_mul(int(d["dex"])))
			for i in range(wd):
				bag.append(d)
		if key != "":
			for d in _bio_extra(ti, key):
				for i in range(roundi(float(w) * BIOME_W_MUL)):
					bag.append(d)
	if bag.is_empty():
		return cast_run[0]["list"]
	return bag


func _hp_k(t: float) -> float:
	return 3.3 + minf(1.7, t / 210.0)


func _scale_at(t: float) -> Dictionary:
	return {"hp": (1.0 + t / 150.0) * _adapt_k(), "dmg": (1.0 + t / 650.0) * pow(_adapt_k(), 0.7), "spd": 1.0 + minf(0.35, t / 1400.0)}


func _boss_scale_k(dex: int) -> float:
	var idle: Dictionary = _sm(dex)["a"]["Idle"] if _sm(dex)["a"].has("Idle") else _sm(dex)["a"]["Walk"]
	var h: float = float(idle["ay"]) * 2.0
	return clampf(roundf(110.0 / h * 2.0) / 2.0, 1.0, 2.0)


func _say(text: String, secs: float = 2.6) -> void:
	banner_text = L.t(text)
	banner_t = secs


func _make_enemy(def: Dictionary, pos: Vector2, sc: Dictionary, boss: bool = false) -> Enemy:
	var dex: int = int(def["dex"])
	var p: Dictionary = _dex_by[dex]
	var sm: Dictionary = _sm(dex)
	var e := Enemy.new()
	var scl: float = _boss_scale_k(dex) if boss else 1.0
	e.setup(dex, sm, flash_shader, scl, false)
	e.def = def
	e.boss = boss
	e.behavior = String(def["behavior"])
	e.enemy_name = L.t(String(p["name"]))
	var ty: Array = p["types"]
	e.types = ty if not ty.is_empty() else ["normal"]
	e.atk_type = String(e.types[0])
	e.flying = boss or bool(sm.get("hv", 0))
	e.max_hp = roundf(float(def["hp"]) * float(sc["hp"]))
	e.hp = e.max_hp
	e.spd = float(def["spd"]) * float(sc["spd"])
	e.dmg = float(def["dmg"]) * float(sc["dmg"])
	e.xp_val = float(def["xp"])
	e.sc = sc
	if not mods.is_empty():
		if _has_mod("fast"):
			e.spd *= 1.15 if boss else 1.4
		if _has_mod("tank"):
			e.max_hp = roundf(e.max_hp * 1.6)
			e.hp = e.max_hp
		if _has_mod("hard"):
			e.dmg *= 1.5
		if _has_mod("glass"):
			e.dmg *= 2.0
		var hpk: float = 1.0
		if _has_mod("brainy"):
			hpk *= 1.25
		if _has_mod("rich"):
			hpk *= 1.3
		if _has_mod("plague"):
			hpk *= 0.65
		if hpk != 1.0:
			e.max_hp = roundf(e.max_hp * hpk)
			e.hp = e.max_hp
	if mode == "tower":
		var ek: float = _rk("ehp") * TOWER_HP_K
		var es: float = _rk("espd") * (1.0 + 0.02 * float(maxi(0, tw_floor - 10)))
		e.dmg *= TOWER_DMG_K * tw_adapt_dmg
		ek *= tw_adapt_hp
		if boss:
			ek = _rk("bossHp") * TOWER_BOSS_HP_K * minf(tw_adapt_hp, TOWER_ADAPT_MAX_BOSS)
			e.dmg *= _rk("bossdmg")
			es = 1.0 + (es - 1.0) * 0.5
		e.max_hp = roundf(e.max_hp * ek)
		e.hp = e.max_hp
		e.spd *= es
	if def.has("shotCd"):
		e.shot_cd = randf_range(0.3, float(def["shotCd"]))
	e.skill_cd = randf_range(1.0, 4.0)
	e.bob = randf() * TAU
	e.position = pos
	world.add_child(e)
	enemies.append(e)
	return e


func _apply_fov() -> void:
	var pct: int = clampi(int(SV.d["settings"].get("fov", 165)), 100, 200)
	cam_zoom = float(pct) / 100.0
	if cam != null:
		cam.zoom = Vector2(cam_zoom, cam_zoom)


# v5.8: en PC, rueda del raton o teclas +/- cambian la vision durante la partida.
func _zoom_input(event: InputEvent) -> bool:
	if not DSP.is_desktop() or paused or choosing or pause_ui.visible:
		return false
	var d := 0
	if event is InputEventMouseButton and event.pressed:
		d = 5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else (-5 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 0)
	elif event is InputEventKey and event.pressed:
		d = 5 if event.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD] else (-5 if event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT] else 0)
	if d == 0:
		return false
	SV.d["settings"]["fov"] = clampi(int(SV.d["settings"].get("fov", 165)) + d, 100, 200)
	SV.save()
	_apply_fov()
	pause_ui.sync_fov()
	return true


func _ring_point(angle: float) -> Vector2:
	var d: float = get_viewport_rect().size.length() * 0.5 / cam_zoom + randf_range(10.0, 70.0)
	return player.position + Vector2(cos(angle) * d, sin(angle) * d * 0.9)


func _dt() -> float:
	# tiempo de dificultad: en la Torre sube piso a piso
	if mode == "tower":
		return 20.0 + float(tw_floor - 1) * 42.0 + float(maxi(0, tw_floor - 10)) * 14.0 + tw_t
	return run_time


# Dificultad de tramo final (Seccion 52): 0 hasta el minuto 20 y 1 en el 60. Servicio unico: lo usan el spawner y la Normal Run.
# Mas vida, dano y velocidad por enemigo, elites ocasionales y menos cantidad: la dificultad no depende solo de "mas bichos".
func _late_x(t: float) -> float:
	if mode == "tower" or mode == "rush" or mode == "chal":
		return 0.0
	return clampf((t - 1200.0) / 600.0, 0.0, 1.0)   # del minuto 20 al 30: el juego se vuelve MUY dificil hasta la Sentencia de Arceus


func _spawn_one(angle: float = -999.0, near: bool = false) -> Enemy:
	var bag: Array = _bag_at(_dt())
	if cave_type != "":
		var tb: Array = bag.filter(func(d): return _has_t(_dex_by[int(d["dex"])]["types"], [cave_type]))
		if tb.is_empty():
			tb = _cave_type_pool(cave_type)
		if not tb.is_empty():
			bag = tb
	var def: Dictionary = bag[randi() % bag.size()]
	var a: float = angle if angle > -900.0 else randf() * TAU
	var pos: Vector2 = _ring_point(a)
	if near:
		pos = player.position + Vector2.from_angle(a) * randf_range(380.0, 520.0)
	pos = _free_spot(pos, 14.0)
	var base: Dictionary = _scale_at(_dt())
	var lx: float = _late_x(_dt())
	var sc := {"hp": float(base["hp"]) * _hp_k(_dt()) * (1.0 + 2.0 * lx), "dmg": float(base["dmg"]) * (1.0 + 1.0 * lx), "spd": float(base["spd"]) * (1.0 + 0.15 * lx)}
	var e: Enemy = _make_enemy(def, pos, sc)
	e.dmg *= DMG_K
	if lx > 0.0 and randf() < 0.04 + 0.30 * lx:   # elite de tramo final: mas duro, mas dano y mas experiencia
		e.max_hp = roundf(e.max_hp * 2.2)
		e.hp = e.max_hp
		e.dmg *= 1.3
		e.xp_val = roundf(e.xp_val * 2.0)
		e.modulate = Color(1.0, 0.72, 0.72)
	e.xp_val = roundf(e.xp_val * XP_K)
	if enemies.size() >= int(ENEMY_CAP * 0.85):
		e.max_hp = roundf(e.max_hp * 1.6)
		e.hp = e.max_hp
		e.dmg *= 1.25
		e.xp_val = roundf(e.xp_val * 1.6)
	if _has_item("pureincense"):
		e.max_hp = roundf(e.max_hp * 1.3)
		e.hp = e.max_hp
		e.xp_val = roundf(e.xp_val * 1.5)
	if bool(_sm(e.dex).get("sh", 0)) and randf() < SHINY_RATE:
		e.make_shiny()
		Aud.sfx("shiny")
		_say(L.t("¡Un %s shiny anda cerca!") % e.enemy_name, 3.4)
	if event_id == "gold":
		e.make_golden()
	return e


func _spawn_boss(b: Dictionary, t_v: float = -1.0):
	var t: float = run_time if t_v < 0.0 else t_v
	var sc := {"hp": (1.0 + t / 600.0) * _adapt_k(), "dmg": (1.0 + t / 600.0) * pow(_adapt_k(), 0.7), "spd": 1.0}
	var e: Enemy = _make_enemy(b, _ring_point(randf() * TAU), sc, true)
	if bool(_sm(e.dex).get("sh", 0)) and randf() < SHINY_RATE:
		e.make_shiny()
	Aud.sfx("boss")
	_say(L.t("¡%s%s salvaje apareció!") % [e.enemy_name, " shiny" if e.shiny else ""], 3.2)
	shake = 14.0
	return e


func _boss_alive() -> bool:
	for e in enemies:
		if e.boss and not e.dead:
			return true
	return false


func _update_spawner(delta: float) -> void:
	# Enemigos por segundo (spawner.js): sube con el tiempo de la run.
	var t: float = run_time
	banner_t = maxf(0.0, banner_t - delta)
	if join_t >= 0.0:
		join_t += delta
		if join_t > 3.2:
			join_t = -1.0
	fusion_t = maxf(0.0, fusion_t - delta)
	if mode == "rush":
		_update_rush(delta)
		return
	if mode == "tower":
		_update_tower(delta)
		return
	# Jefes
	if mode == "normal":
		_update_director(delta)
		_update_mini(delta)
		_update_wildleg(delta)
	if boss_idx < boss_run.size() and t >= float(boss_run[boss_idx]["at"]) and (mode != "normal" or (boss_idx > 0 and arena == null and not dir_finale)):
		_spawn_boss(boss_run[boss_idx])
		boss_idx += 1
	if t >= 1200.0 and not late_warned and _late_x(t) > 0.0 and arena == null:
		late_warned = true
		_say(L.t("¡Minuto 20! Los Pokémon se vuelven mucho más peligrosos…"), 4.0)
		shake = 10.0
		Aud.sfx("boss")
	var fight: bool = _boss_alive()
	if enemies.size() < ENEMY_CAP:
		var rate: float = (1.6 + t * 0.028 + pow(t / 60.0, 1.6) * 0.4) * 0.15 * (1.0 + 0.7 * clampf(1.0 - t / 240.0, 0.0, 1.0)) * (1.8 if _has_mod("horde") else 1.0) * (2.5 if _has_mod("plague") else 1.0) * (0.75 if _has_item("pureincense") else 1.0)
		spawn_acc += rate * (1.0 + 1.5 * _late_x(t)) * _adapt_k() * (0.25 if fight else 1.0) * delta
		while spawn_acc >= 1.0:
			spawn_acc -= 1.0
			if enemies.size() < ENEMY_CAP:
				_spawn_one()
	# Marea: una avalancha desde un lado concreto.
	if not fight:
		surge_t -= delta
	if surge_t <= 0.0:
		surge_t = randf_range(38.0, 56.0)
		var base_a: float = randf() * TAU
		var n: int = mini(ENEMY_CAP - enemies.size(), roundi(float(14 + int(t / 22.0)) * 0.28))
		for i in range(maxi(0, n)):
			_spawn_one(base_a + randf_range(-0.55, 0.55))
		Aud.sfx("surge")
		_say(L.t("¡Marea de Pokémon!"), 2.2)
	_update_events(delta)
	# Precarga de lo que va a salir en el proximo minuto.
	preload_t -= delta
	if preload_t <= 0.0:
		preload_t = 10.0
		_preload_upcoming(t + 60.0)


# ---------------------------------------------------------------
# S63: Normal Run hasta Eternatus. Un solo director: 00:30 oleada, 01:00 Grieta, 02:00 Meowth, 03:00 jefe,
# 04:00 siguiente mapa (tras el jefe), 60:00 Eternatus. Cada hito se dispara una vez; si hay un encuentro critico
# (Grieta dentro, jefe vivo, altar) queda en cola y sale en cuanto se libere, en orden cronologico.
# ---------------------------------------------------------------
# El aliado Alfa dura toda la partida: no debe bloquear eventos como si fuera un altar legendario en curso.
func _legend_busy() -> bool:
	return legend != null and not (is_instance_valid(legend) and legend.alpha)


func _dir_crit() -> bool:
	return arena != null or _boss_alive() or _legend_busy()


func _update_director(delta: float) -> void:
	if player.dead or timeup:
		return
	dir_gap = maxf(0.0, dir_gap - delta)
	for ms in DIR_MS:
		var id: String = ms[0]
		if dir_done.has(id):
			continue
		if run_time < float(ms[1]):
			break
		if id == "wave" and run_time - float(ms[1]) > 150.0:
			dir_done[id] = true   # una oleada de apertura que llega muy tarde ya no tiene sentido
			continue
		if dir_gap > 0.0:
			return
		if _dir_try(id):
			dir_done[id] = true
			dir_gap = 4.0
			dir_log.append([id, run_time])
			return
	return


func _dir_try(id: String) -> bool:
	match id:
		"wave":
			if _dir_crit():
				return false
			var base_a: float = randf() * TAU
			var n: int = mini(10, ENEMY_CAP - enemies.size())
			for i in range(maxi(0, n)):
				var e: Enemy = _spawn_one(base_a + randf_range(-0.5, 0.5))
				e.set_meta("enc", "wave")
			Aud.sfx("surge")
			_say(L.t("¡Pequeña oleada!"), 2.4)
			return true
		"rift":
			if arena != null or _boss_alive():
				return false
			if rift != null:
				rift_info["guaranteed"] = true   # ya habia una programada: se marca, no se duplica
				return true
			_open_rift()
			rift_check = RIFT_EVERY
			if rift != null:
				rift_info["guaranteed"] = true
			return true
		"meowth":
			if arena != null or _boss_alive():
				return false
			_spawn_thief(true)
			return true
		"boss":
			if arena != null or _boss_alive() or boss_run.is_empty():
				return false
			var b = _spawn_boss(boss_run[0])
			b.set_meta("enc", "open_boss")
			boss_idx = maxi(boss_idx, 1)
			return true
		"map":
			if not dir_done.has("boss") or _boss_alive() or arena != null:
				return false
			dir_map = true
			_update_biome()
			return true
		"eter":
			if _dir_crit():
				if not dir_warned:
					dir_warned = true
					_say(L.t("Algo enorme se acerca… termina lo que tienes entre manos."), 3.2)
				return false
			if not (_dex_by.has(ETERNATUS_DEX) and _smeta.has(str(ETERNATUS_DEX))):
				dir_blocked = "eternatus_assets"
				push_warning("S63: faltan los assets de Eternatus (890); jefe final bloqueado")
				return true
			_spawn_eternatus()
			return true
	return true


func _spawn_eternatus() -> void:
	dir_finale = true
	var p: Dictionary = _dex_by[ETERNATUS_DEX]
	var bb := "ranged" if _behavior_of(p) == "ranged" else "chase"
	var def := {"at": 3600.0, "dex": ETERNATUS_DEX, "name": String(p["name"]), "hp": 7000.0, "spd": 58.0, "dmg": 40.0, "xp": 6000.0,
		"behavior": bb, "shotDmg": 28.0, "shotCd": 1.0, "range": 300.0}
	_preload_dex(ETERNATUS_DEX)
	var e = _spawn_boss(def, 3600.0)
	e.set_meta("enc", "eternatus")
	dir_eter = e
	_say(L.t("¡ETERNATUS ha despertado!"), 4.0)
	shake = 20.0


func _eternatus_win() -> void:
	if timeup or player.dead:
		return
	var st: Dictionary = SV.d["stats"]
	st["eternatusKills"] = int(st.get("eternatusKills", 0)) + 1
	timeup = true
	hud.timeup = true
	hud.end_big = L.t("¡ETERNATUS DERROTADO!")
	hud.end_l1 = L.t("Tiempo: %d min") % int(run_time / 60.0)
	hud.end_l2 = L.t("Derrotaste %d Pokémon") % kills
	player.dead = true
	player.active = false
	_clear_orbit_orbs()
	for en in enemies:
		en.active = false


# S63.3: mini-jefes grandes y raros (Tyranitar, Wailord, Onix, Steelix)
func _update_mini(delta: float) -> void:
	if player.dead or timeup or dir_finale or not dir_done.has("map") or arena != null:
		return
	mini_chk -= delta
	if mini_chk > 0.0:
		return
	mini_chk = 20.0
	if _boss_alive() or _legend_busy() or randf() > 0.18:
		return
	if run_time - float(mini_last.get(biome_idx, -9999.0)) < 300.0:
		return
	_spawn_mini()


# S62.8: legendarios salvajes raros entre el minuto 30 y el final (solo con sprites reales; un unico premio por derrota)
const WILD_LEG := [144, 145, 146, 243, 244, 245, 249, 250, 377, 378, 379, 380, 381, 382, 383, 384]
var wl_t := 600.0
var wl_cd := 0.0


func _update_wildleg(delta: float) -> void:
	if run_time < 1800.0 or run_time > 3480.0 or player.dead or timeup or dir_finale or arena != null or not dir_done.has("map"):
		return
	wl_cd -= delta
	if wl_cd > 0.0:
		return
	wl_cd = 20.0
	if _boss_alive() or _legend_busy() or caves_active() or inv.active() or meteor.deo != null or mew.cur != null or alpha.cur != null:
		return
	if run_time < wl_t or randf() > 0.25:
		return
	var pool: Array = []
	for dx in WILD_LEG:
		if _dex_by.has(dx) and _smeta.has(str(dx)):
			pool.append(dx)
	if pool.is_empty():
		return
	var dex: int = int(pool[randi() % pool.size()])
	var p: Dictionary = _dex_by[dex]
	var lx: float = _late_x(run_time)
	var def := {"dex": dex, "name": String(p["name"]), "hp": roundf(1800.0 * (1.0 + run_time / 600.0)), "spd": 52.0, "dmg": 48.0, "xp": 1200.0, "behavior": "chase"}
	var e: Enemy = _make_enemy(def, _ring_point(randf() * TAU), {"hp": 1.0 + lx, "spd": 1.0, "dmg": 1.0 + 0.4 * lx}, true)
	e.set_meta("enc", "wildleg")
	wl_t = run_time + randf_range(480.0, 720.0)
	Aud.sfx("boss")
	_say(L.t("¡Un %s legendario salvaje apareció!") % e.enemy_name, 3.4)
	shake = 10.0


func _spawn_mini(force_dex: int = -1) -> Enemy:
	var pool: Array = []
	for dx in MINI_DEXES:
		if _dex_by.has(dx) and _smeta.has(str(dx)):
			pool.append(dx)
	if pool.is_empty():
		return null
	var dex: int = force_dex if force_dex > 0 else int(pool[randi() % pool.size()])
	if not (_dex_by.has(dex) and _smeta.has(str(dex))):
		return null
	var p: Dictionary = _dex_by[dex]
	var lx: float = _late_x(run_time)
	var def := {"dex": dex, "name": String(p["name"]), "hp": roundf(1500.0 * (1.0 + run_time / 600.0)), "spd": 46.0, "dmg": 46.0, "xp": 900.0,
		"behavior": "chase"}
	var pos: Vector2 = Vector2.ZERO
	var ok := false
	for i in range(10):
		pos = player.position + Vector2.from_angle(randf() * TAU) * randf_range(420.0, 560.0)
		if not _blocked(pos, 60.0):
			ok = true
			break
	if not ok:
		return null   # el mapa no tiene hueco para un bicho tan grande
	var e: Enemy = _make_enemy(def, pos, {"hp": 1.0 + lx, "spd": 1.0, "dmg": 1.0 + 0.4 * lx}, true)
	_grow(e, 1.5)
	e.set_meta("enc", "mini")
	mini_last[biome_idx] = run_time
	Aud.sfx("boss")
	_say(L.t("¡Un %s gigante apareció!") % e.enemy_name, 3.0)
	return e


func _grow(e: Enemy, k: float) -> void:
	e.scl *= k
	e.sprite.scale *= k
	e.radius *= k
	e.body_h *= k
	e.shadow_rx *= k



# Jefe fijo de cada piso (siempre el mismo): cada 5 pisos, un legendario.
func _tower_def(f: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * f + 31
	var leg: bool = f % 5 == 0
	var lo: float = minf(640.0, 380.0 + float(f) * 11.0)
	var pool: Array = []
	for p in _dex_list:
		var dx: int = int(p["dex"])
		if not _smeta.has(str(dx)) or bool(p.get("leg", false)) != leg:
			continue
		if leg or (float(p["bst"]) >= lo and float(p["bst"]) <= lo + 110.0):
			pool.append(p)
	if pool.is_empty():
		for p in _dex_list:
			if not bool(p.get("leg", false)) and _smeta.has(str(int(p["dex"]))) and float(p["bst"]) >= 480.0:
				pool.append(p)
	var bp: Dictionary = pool[rng.randi() % pool.size()]
	if f == 25 and _dex_by.has(890):
		bp = _dex_by[890]       # piso 25: Eternatus
	var fin: int = tw_final if tw_final > 0 else 493
	if f == TOWER_FLOORS and _dex_by.has(fin):
		bp = _dex_by[fin]       # el jefe final de la Torre: Arceus
	var bb: String = "chase"
	if _behavior_of(bp) == "ranged":
		bb = "ranged"
	elif _base_spd(bp) > 90.0:
		bb = "charger"
	var hp: float = 900.0 * pow(1.2, float(mini(f, 15) - 1)) * pow(1.07, float(clampi(f - 15, 0, 15))) * pow(1.035, float(maxi(0, f - 30)))
	var dm: float = minf(120.0, 26.0 + 4.5 * float(f))
	hp *= 1.8 + 3.2 * clampf(float(f - 5) / 25.0, 0.0, 1.0)
	if f == TOWER_FLOORS:
		hp = (hp + float(_tower_def(25)["hp"]) / 1.35) * 1.25   # el jefe final lleva la vida de dos jefes, +25%
	return {"at": 0.0, "dex": int(bp["dex"]), "name": String(bp["name"]), "hp": roundf(hp * 1.35),
		"spd": roundf(clampf(40.0 + _base_spd(bp) * 0.5, 40.0, 100.0)), "dmg": roundf(dm * 1.2),
		"final": f == TOWER_FLOORS, "xp": float(_xp_for(player.level)) * 1.25, "behavior": bb, "shotDmg": roundf(dm * 0.55), "shotCd": 1.1, "range": 260.0}


func _tower_reward(f: int) -> Dictionary:
	var r: Dictionary = {"coins": 120 + 40 * f, "t1": 1 + f / 5}
	if f % 5 == 0:
		r["t10"] = f / 5
	return r


func _tw_cap() -> int:
	return ENEMY_CAP + clampi((tw_floor - 20) * 2, 0, 20)


func _update_tower(delta: float) -> void:
	if not tw_init:
		tw_init = true
		# Salida desde un checkpoint: niveles gratis (una mejora por piso saltado)
		var n: int = tw_floor - 1
		if n > 0:
			player.level += n
			player.xp_next = _xp_need(player.level)
			pending_levels += n
			_say(L.t("Piso %d") % tw_floor, 2.0)
	tw_adapt_t -= delta
	if tw_adapt_t <= 0.0:
		tw_adapt_t = 2.0
		_tower_adapt()
	if tw_phase > 0:
		return
	var f: int = tw_floor
	if tw_boss != null or tw_boss2 != null:
		var a_ok: bool = tw_boss == null or not is_instance_valid(tw_boss) or tw_boss.dead
		var b_ok: bool = tw_boss2 == null or not is_instance_valid(tw_boss2) or tw_boss2.dead
		if a_ok and b_ok:
			tw_boss = null
			tw_boss2 = null
			_tower_clear()
			return
	else:
		tw_t += delta
		if tw_t >= TOWER_BOSS_AT:
			var d: Dictionary = _tower_def(f)
			_preload_dex(int(d["dex"]))
			tw_boss = _spawn_boss(d, 15.0 * float(f))
			tw_boss_t0 = run_time
			tw_fight_dmg = 0.0
			_say(L.t("Piso %d: %s") % [f, L.t(String(d["name"]))], 3.0)
			# escoltas: del piso 11 en adelante el jefe llega acompañado
			if f > 10:
				var esc: int = mini(ENEMY_CAP, 3 + (mini(f, 30) - 10) / 2)
				var base_a: float = randf() * TAU
				for i in range(esc):
					if enemies.size() < _tw_cap():
						_spawn_one(base_a + float(i) * 0.5)
	var t: float = _dt()
	var fight: bool = tw_boss != null or tw_boss2 != null
	var cap: int = _tw_cap()
	if enemies.size() < cap:
		var chaos: float = 1.0 + 0.06 * float(clampi(f - 10, 0, 20))
		var rate: float = (1.6 + t * 0.028 + pow(t / 60.0, 1.6) * 0.5) * 0.17 * (1.8 if _has_mod("horde") else 1.0) * (2.5 if _has_mod("plague") else 1.0) * chaos * TOWER_SPAWN_K * _rk("spawn") * (0.75 if _has_item("pureincense") else 1.0)
		spawn_acc += rate * ((0.25 if f <= 20 else 0.5) if fight else 1.0) * delta
		while spawn_acc >= 1.0:
			spawn_acc -= 1.0
			if enemies.size() < cap:
				_spawn_one()
	# Mareas: del piso 11 en adelante, cada vez mas seguidas y grandes (tambien durante el jefe en el caos)
	if f > 10 and (not fight or f > 20):
		tw_surge -= delta
		if tw_surge <= 0.0:
			tw_surge = maxf(16.0, 46.0 - 1.5 * float(mini(f, 30) - 10))
			var base_s: float = randf() * TAU
			var n2: int = mini(cap - enemies.size(), 8 + (mini(f, 30) - 10))
			for i in range(maxi(0, n2)):
				_spawn_one(base_s + randf_range(-0.6, 0.6))
			Aud.sfx("surge")
			_say(L.t("¡Marea de Pokémon!"), 2.2)
	preload_t -= delta
	if preload_t <= 0.0:
		preload_t = 10.0
		_preload_upcoming(t + 60.0)


# Cuenta las mejoras del jugador y ajusta la vida y el dano de los enemigos nuevos de la Torre.
func _tower_adapt() -> void:
	var ru := 0
	for k in stat_lv:
		ru += int(stat_lv[k])
	for mv in player.moves:
		ru += int(mv["lvl"])
	var pu := SV.up_total(SV.run_dex)
	tw_adapt_hp = minf(1.0 + TOWER_ADAPT_MAX_HP, 1.0 + TOWER_ADAPT_HP * float(ru) + TOWER_ADAPT_HP_P * float(pu))
	tw_adapt_dmg = minf(1.0 + TOWER_ADAPT_MAX_DMG, 1.0 + TOWER_ADAPT_DMG * float(ru) + TOWER_ADAPT_DMG_P * float(pu))


func _tower_clear() -> void:
	var f: int = tw_floor
	if tw_boss_t0 >= 0.0:
		var ent := {"f": f, "s": roundi(run_time - tw_boss_t0), "p": roundi(100.0 * tw_fight_dmg / maxf(1.0, player.max_hp)), "lv": player.level, "ahp": snappedf(tw_adapt_hp, 0.01)}
		tw_log.append(ent)
		var twl: Dictionary = SV.d.get("tower", {})
		var lg: Array = twl.get("log", [])
		lg.append(ent)
		while lg.size() > 80:
			lg.pop_front()
		twl["log"] = lg
		SV.d["tower"] = twl
		tw_boss_t0 = -1.0
	tw_clears += 1
	var tw: Dictionary = SV.d.get("tower", {})
	var cl: Dictionary = tw.get("claimed", {})
	var first: bool = not cl.has(str(f))
	var r: Dictionary = _tower_reward(f)
	r["coins"] = roundi(float(r["coins"]) * _rk("coins"))
	if first:
		cl[str(f)] = int(Time.get_unix_time_from_system())
		PG.grant(r)
	else:
		PG.grant({"coins": roundi(float(40 + 10 * f) * _rk("coins"))})
	tw["claimed"] = cl
	tw["best"] = maxi(int(tw.get("best", 0)), f)
	SV.d["tower"] = tw
	var st3: Dictionary = SV.d["stats"]
	st3["towerBest"] = maxi(int(st3.get("towerBest", 0)), f)
	if f >= TOWER_FLOORS:
		st3["arceus"] = int(st3.get("arceus", 0)) + 1   # vencer al jefe final
	SV.save()
	Aud.sfx("bossDown")
	var txt: String = L.t("¡Piso %d superado!") % f
	if first:
		txt += "  +%d " % int(r["coins"]) + L.t("monedas")
		if f % 5 == 0:
			txt += " · " + L.t("¡Reliquia de la Torre!")
	_say(txt, 3.6)
	PG.check()
	# limpia el piso y cura un poco
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_ring(player.position, 8.0, 200.0, Color("#ffd23f"), 0.7)
	if f >= TOWER_FLOORS:
		_tower_win()
		return
	# Vinculos de ataque de la Torre: uno al superar cada piso 10, 20, 30, 40 y 50
	if f == 10 or f == 20 or f == 30 or f == 40 or f == 50:
		bonds += 1
		add_text(player.position + Vector2(0.0, -player.body_h - 10.0), L.t("¡Vínculo!"), Color("#ff8ad8"), 26)
		_ring(player.position, 8.0, 90.0, Color("#ff8ad8"), 0.7)
		_say(L.t("¡Piso %d superado! Obtienes un vínculo de ataque") % f, 3.6)
	tw_floor += 1
	tw_t = 0.0
	tw_shield = 0.0
	tw_surge = 30.0
	_tower_rest_open()


# ---------------------------------------------------------------
# Piso de descanso: 1) cura / mejora extra / escudo   2) carta de riesgo (opcional)
# ---------------------------------------------------------------
func _rest_heal_frac() -> float:
	return (0.40 if tw_floor <= 21 else 0.25) * _rk("healmul")


func _tower_rest_open() -> void:
	tw_phase = 1
	choosing = true
	var hf: int = roundi(_rest_heal_frac() * 100.0)
	var picks: Array = []
	picks.append({"cat": "trest", "id": "heal", "key": "tr:heal", "w": 1.0, "title": "Descanso", "icon": "r_rest",
		"desc": L.t("Recuperas el %d%% de tu vida.") % hf, "tag": "Cura", "color": Color("#5fe08a")})
	picks.append({"cat": "trest", "id": "up", "key": "tr:up", "w": 1.0, "title": "Entrenamiento", "icon": "r_train",
		"desc": L.t("Obtienes una mejora extra ahora mismo."), "tag": "Mejora", "color": Color("#ffd23f")})
	picks.append({"cat": "trest", "id": "shield", "key": "tr:shield", "w": 1.0, "title": "Escudo", "icon": "r_shield",
		"desc": L.t("Un escudo del 35% de tu vida absorbe el daño del siguiente piso."), "tag": "Defensa", "color": Color("#7fe0ff")})
	cards.show_cards(picks, L.t("Elige cómo descansar"), L.t("Piso %d superado") % (tw_floor - 1), false)


func _tower_risk_open() -> void:
	tw_phase = 2
	var pool: Array = []
	for r in TOWER_RISKS:
		if not tw_risk.has(String(r["id"])):
			pool.append(r)
	pool.shuffle()
	var picks: Array = []
	if _risk_count() < TOWER_MAX_RISKS:
		for i in range(mini(3, pool.size())):
			var r: Dictionary = pool[i]
			picks.append({"cat": "trisk", "id": String(r["id"]), "key": "rk:" + String(r["id"]), "w": 1.0, "title": String(r["name"]),
				"desc": String(r["desc"]), "icon": String(r["icon"]), "tag": "Riesgo", "color": Color("#ff5b8a"), "paper": bool(r.get("paper", false))})
	var lpool: Array = []
	for lg in TOWER_LEGENDS:
		if not tw_risk.has(String(lg["id"])):
			lpool.append(lg)
	if not lpool.is_empty() and (tw_force_legend != "" or randf() < LEGEND_CHANCE):
		var lg2: Dictionary = lpool[randi() % lpool.size()]
		for lg3 in lpool:
			if String(lg3["id"]) == tw_force_legend:
				lg2 = lg3
		var lcard := {"cat": "trisk", "id": String(lg2["id"]), "key": "rk:" + String(lg2["id"]), "w": 1.0, "title": String(lg2["name"]),
			"desc": String(lg2["desc"]), "icon": String(lg2["icon"]), "tag": "Legendaria", "color": Color("#ffd23f"), "legend": true}
		if picks.is_empty():
			picks.append(lcard)
		else:
			picks[randi() % picks.size()] = lcard
	if picks.is_empty():
		_tower_rest_done()
		return
	picks.append({"cat": "trisk", "id": "skip", "key": "rk:skip", "w": 1.0, "title": "Sin riesgos",
		"desc": L.t("Sigues sin tomar ningún pacto. Dura toda la partida."), "icon": "r_skip", "tag": "Seguir", "color": Color("#8fa3c4")})
	cards.show_cards(picks, L.t("Un pacto: gran poder, a cambio de un coste"), L.t("Cartas de riesgo"), false)


func _tower_rest_done() -> void:
	tw_phase = 0
	cards.hide_cards()
	choosing = false
	_say(L.t("Piso %d") % tw_floor, 2.0)


func _tower_rest_pick(cat: String, id: String) -> void:
	Aud.sfx("confirm")
	if cat == "trest":
		if id == "heal":
			var hh: float = player.max_hp * _rest_heal_frac()
			player.hp = minf(player.max_hp, player.hp + hh)
			add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+PS"), Color("#5fe08a"))
		elif id == "up":
			pending_levels += 1
		elif id == "shield":
			tw_shield = player.max_hp * 0.35
		_tower_risk_open()
		return
	# trisk
	if id != "skip":
		tw_risk.append(id)
		var mh: float = _rk("maxhp")
		if mh != 1.0:
			# la vida maxima se recalcula sobre la base: guardamos la proporcion actual
			var frac: float = player.hp / maxf(1.0, player.max_hp)
			var last: float = 1.0
			for r in _all_risks():
				if String(r["id"]) == id and (r["fx"] as Dictionary).has("maxhp"):
					last = float(r["fx"]["maxhp"])
			player.max_hp = roundf(player.max_hp * last)
			player.hp = minf(player.max_hp, frac * player.max_hp)
		_say(L.t("Pacto sellado: %s") % L.t(_risk_name(id)), 2.4)
		if id == "l_bag":
			_tower_rest_done()
			_offer_item()
			return
	_tower_rest_done()


func _risk_name(id: String) -> String:
	for r in _all_risks():
		if String(r["id"]) == id:
			return String(r["name"])
	return id




func _tower_win() -> void:
	timeup = true
	hud.timeup = true
	hud.end_big = L.t("¡TORRE COMPLETA!")
	hud.end_l1 = L.t("Pisos superados: %d") % tw_clears
	hud.end_l2 = L.t("Derrotaste %d Pokémon") % kills
	player.dead = true
	player.active = false
	_clear_orbit_orbs()
	for e in enemies:
		e.active = false


func _update_rush(delta: float) -> void:
	if _boss_alive():
		return
	rush_rest -= delta
	if rush_rest > 0.0:
		if rush_i == 0 and rush_rest < 4.0 and banner_t <= 0.0:
			_say(L.t("¡Rush de Jefes! Prepárate…"), 2.4)
		return
	var d: Dictionary = _rush_def(rush_i)
	_preload_dex(int(d["dex"]))
	_spawn_boss(d, 60.0 * float(rush_i))
	_say(L.t("Jefe %d: %s") % [rush_i + 1, L.t(String(d["name"]))], 3.0)
	rush_i += 1
	rush_rest = 8.0


func _preload_upcoming(until: float) -> void:
	for tier in cast_run:
		if float(tier["from"]) <= until:
			for d in tier["list"]:
				_preload_dex(int(d["dex"]))
	for ti in range(cast_run.size()):
		if float(cast_run[ti]["from"]) <= until:
			for off in range(2):   # el bioma actual y el siguiente
				for d in _bio_extra(ti, _biome_key(biome_idx + off)):
					_preload_dex(int(d["dex"]))
	for b in boss_run:
		if float(b["at"]) <= until:
			_preload_dex(int(b["dex"]))


func _preload_dex(dex: int) -> void:
	for a in ANIMS:
		var path: String = "res://assets/pokemon/%d/%s.png" % [dex, a]
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path):
			ResourceLoader.load_threaded_request(path)


# ---------------------------------------------------------------
# Eventos (events.js): hordas de un tipo, hora dorada, duendes del tesoro
# ---------------------------------------------------------------
func _update_events(delta: float) -> void:
	if event_id != "":
		event_t += delta
		if event_t >= 30.0:
			event_id = ""
			horde_defs = []
	# Igual que events.js: los temporizadores corren siempre (menos en el Juicio); si hay un jefe vivo al
	# vencer, el duende espera 8 s y el evento 10 s.
	if run_time > 0.0 and not jd.active() and not dir_finale:
		if thieves < 2:
			thief_t -= delta
			if thief_t <= 0.0:
				if _boss_alive():
					thief_t = 8.0
				else:
					_spawn_thief()
					thieves += 1
					thief_t = randf_range(240.0, 360.0)
		if event_id == "":
			next_event_t -= delta
			if next_event_t <= 0.0:
				if _boss_alive():
					next_event_t = 10.0
				else:
					next_event_t = randf_range(240.0, 300.0) / _adapt_k()
					var ids: Array = ["horde", "gold"]
					ids.erase(last_event)
					_start_event(String(ids[randi() % ids.size()]))


func _start_event(id: String) -> void:
	last_event = id
	if id == "horde":
		var ti: int = _tier_at(run_time)
		var no_horde := ["bomber", "healer", "shielder", "summoner"]
		var by_type := {}
		for p in _candidates(ti):
			if no_horde.has(_behavior_of(p)):
				continue
			for ty in p["types"]:
				if not by_type.has(ty):
					by_type[ty] = []
				by_type[ty].append(p)
		var ok: Array = []
		for ty in by_type:
			if by_type[ty].size() >= 3:
				ok.append(ty)
		if ok.is_empty():
			_start_event("gold")
			return
		var type: String = String(ok[randi() % ok.size()])
		horde_defs = []
		for p in _pick_n(by_type[type], 4):
			horde_defs.append(_def_for(p, TIERS[ti], ti))
		event_id = "horde"
		event_t = 0.0
		for i in range(6):
			_spawn_one(randf() * TAU)
		_say(L.t("¡Horda de tipo %s!") % L.t(String(MD.TYPE_NAME[type])), 3.0)
	else:
		event_id = "gold"
		event_t = 0.0
		for e in enemies:
			e.make_golden()
		_say(L.t("¡Hora dorada! Doble de experiencia"), 3.0)


var thief_cycle := -1   # v5.2.1: los ladrones rotan Meowth > Gholdengo > Poltchageist (antes salia casi siempre Meowth)


func _spawn_thief(force_coins: bool = false) -> void:
	if thief_cycle < 0:
		thief_cycle = randi() % 3
	var kinds := [52, 1000, 1012]   # Meowth: monedas | Gholdengo: solo tickets | Poltchageist: Gachapon Coins
	var dex: int = 52
	if not force_coins:
		for k in range(3):
			var cand: int = int(kinds[(thief_cycle + k) % 3])
			if _dex_by.has(cand) and _smeta.has(str(cand)):
				dex = cand
				thief_cycle = (thief_cycle + k + 1) % 3
				break
	var gold: bool = dex == 1000
	var gimmi: bool = dex == 1012
	var def := {"dex": dex, "name": String(_dex_by[dex]["name"]), "behavior": "thief",
		"hp": roundf(60.0 * (1.0 + run_time / 95.0) * (1.5 if gold else 1.0)), "spd": 92.0, "dmg": 0.0, "xp": 10.0,
		"loot": "ticket10" if gold else ("gimmi" if gimmi else "coins")}
	var a: float = randf() * TAU
	var pos: Vector2 = player.position + Vector2(cos(a) * randf_range(230.0, 300.0), sin(a) * randf_range(230.0, 300.0) * 0.8)
	var e: Enemy = _make_enemy(def, pos, {"hp": 1.0, "spd": 1.0, "dmg": 1.0})
	e.life = 15.0
	e.golden = true
	hud.thief_notice = 0.0
	hud.thief_name = e.enemy_name
	hud.thief_gold = gold
	_ring(pos, 4.0, 40.0, Color("#ffd23f"), 0.5)
	if gold:
		_say(L.t("¡Un %s con un ticket ×10! ¡Atrápalo antes de que huya!") % e.enemy_name, 3.2)
	elif gimmi:
		_say(L.t("¡Un %s con una Gachapon Coin! ¡Atrápalo antes de que huya!") % e.enemy_name, 3.2)
	else:
		_say(L.t("¡Un %s cargado de monedas! ¡Atrápalo antes de que huya!") % e.enemy_name, 3.2)


# ---------------------------------------------------------------
# Comportamiento de los enemigos (enemy.js)
# ---------------------------------------------------------------
func _update_enemies(delta: float) -> void:
	var kn_decay: float = pow(0.0015, delta)
	for e in enemies:
		if e.dead:
			continue
		e.touch_cd = maxf(0.0, e.touch_cd - delta * (0.4 if e.para_t > 0.0 else 1.0))
		# Estados de control: congelar, paralizar, dormir y confundir.
		if e.cc_imm > 0.0:
			e.cc_imm -= delta
		if e.frozen_t > 0.0:
			e.frozen_t -= delta
		if e.sleep_t > 0.0:
			e.sleep_t -= delta
		if e.para_t > 0.0:
			e.para_t -= delta
		if e.conf_t > 0.0:
			e.conf_t -= delta
		if e.charm_imm > 0.0:
			e.charm_imm -= delta
		if e.charm_t > 0.0:
			e.charm_t -= delta
			if e.charm_t <= 0.0:
				e.charm_imm = 8.0
		_cc_fx(e, delta)
		# Estados alterados.
		if e.slow_t > 0.0:
			e.slow_t -= delta
			if e.slow_t <= 0.0:
				e.slow = 0.0
		if e.burn > 0:
			e.burn_t -= delta
			e.burn_tick -= delta
			if e.burn_tick <= 0.0:
				e.burn_tick = 0.5
				_damage_enemy(e, 1.6 * float(e.burn) * (1.0 + float(player.level) * 0.06) * kec.dot_mul() * cave.dot_mul("burn"), Color("#ff9a4d"))
			if e.burn_t <= 0.0:
				e.burn = 0
				if e.burn_k > 0.0:
					e.dmg /= e.burn_k
					e.burn_k = 0.0
		if e.dead:
			continue
		if e.poison > 0:
			e.poison_t -= delta
			e.poison_tick -= delta
			if e.poison_tick <= 0.0:
				e.poison_tick = 0.6
				# Contra jefes el veneno hace el 20% del porcentaje normal: si no, un Pokémon venenoso los derrite solo.
				var pmul: float = POISON_BOSS_MUL if e.boss else 1.0
				_damage_enemy(e, (e.max_hp * 0.008 * pmul * float(e.poison) + 1.0) * kec.dot_mul() * cave.dot_mul("poison"), Color("#d47cf0"))
			if e.poison_t <= 0.0:
				e.poison = 0
			# Burbujas y gotas moradas mientras dure el veneno
			e.poison_fx -= delta
			if e.poison_fx <= 0.0 and e.visible:
				e.poison_fx = 0.2
				var fxp: Vector2 = e.position + Vector2(randf_range(-e.radius, e.radius), -randf_range(2.0, maxf(8.0, e.body_h * 0.9)))
				pfx.sp("bubble", "poison", fxp, {"v": Vector2(randf_range(-10.0, 10.0), -44.0), "life": 0.7, "scale": randf_range(0.7, 1.0)})
				if randf() < 0.7:
					# gota que se desprende del cuerpo y cae
					var dp: Vector2 = e.position + Vector2(randf_range(-e.radius, e.radius) * 0.8, -randf_range(3.0, maxf(8.0, e.body_h * 0.6)))
					pfx.px(dp, Color("#b44fe0"), Vector2(randf_range(-6.0, 6.0), 6.0), 0.55, 1.5, 220.0)
		if e.dead:
			continue
		var tint := Color.WHITE
		if e.frozen_t > 0.0:
			tint = Color(0.55, 0.85, 1.3)
		elif e.sleep_t > 0.0:
			tint = Color(0.6, 0.62, 0.95)
		elif e.charm_t > 0.0:
			tint = Color(1.3, 0.75, 0.95)
		elif e.conf_t > 0.0:
			tint = Color(1.0, 0.7, 1.0).lerp(Color(0.8, 0.55, 1.0), 0.5 + 0.5 * sin(e.bob * 1.4))
		elif e.para_t > 0.0 and int(e.bob * 2.0) % 2 == 0:
			tint = Color(1.25, 1.2, 0.55)
		elif e.burn > 0:
			tint = Color(1.0, 0.75, 0.55)
		elif e.poison > 0:
			# Sprite morado (con un pulso suave) hasta que se acaba el veneno
			var pu: float = 0.5 + 0.5 * sin(e.bob * 0.9)
			tint = Color(0.72, 0.38, 1.0).lerp(Color(0.55, 0.24, 0.9), pu)
		elif e.slow > 0.0:
			tint = Color(0.7, 0.85, 1.0)
		e.sprite.modulate = tint
		_enemy_step(e, delta, kn_decay)
	# Separacion suave para que no se apilen en un solo punto.
	var n: int = enemies.size()
	for i in range(n):
		var a = enemies[i]
		if a.dead or a.jump != null:
			continue
		for j in range(i + 1, n):
			var b = enemies[j]
			if b.dead or b.jump != null:
				continue
			var diff: Vector2 = b.position - a.position
			var min_d: float = (a.radius + b.radius) * 0.7
			var dd: float = diff.length()
			if dd < min_d and dd > 0.001:
				var push: Vector2 = diff / dd * (min_d - dd) * 0.5
				a.position -= push
				b.position += push


func _enemy_step(e: Enemy, delta: float, kn_decay: float) -> void:
	if bool(e.def.get("scripted", false)):
		return   # Arceus en la Sentencia: lo mueve judgment.gd
	var to: Vector2 = player.position - e.position
	var dist: float = to.length()
	var dirv: Vector2 = Vector2.ZERO
	if dist > 0.001:
		dirv = to / dist
	var spd: float = e.spd * (1.0 - e.slow) * _weather_speed(e.types)
	if not e.flying:
		spd *= _enemy_terrain(e, delta)
	if e.frozen_t > 0.0 or e.sleep_t > 0.0:
		# Congelado o dormido: no se mueve ni ataca (solo lo empujan los golpes).
		e.position += e.knock * delta
		if not e.flying:
			e.position = _collide(e.position, e.radius * 0.5)
		e.knock *= kn_decay
		e.loop_anim("Idle", 0.05)
		return
	if e.charm_t > 0.0:
		_charmed_step(e, delta, kn_decay, spd)
		return
	if e.conf_t > 0.0:
		_confused_step(e, delta, kn_decay, spd)
		return
	if e.para_t > 0.0:
		spd *= 0.4
	if e.life > 0.0 and e.behavior == "thief":
		e.life -= delta
		if e.life <= 0.0:
			_ring(e.position, 4.0, 30.0, Color("#ffd23f"), 0.3)
			e.dead = true
			e.fade = 0.2
			return
	# Duende del tesoro: huye de ti en zigzag.
	if e.behavior == "thief":
		e.zig += delta
		var ang: float = (-dirv).angle() + sin(e.zig * 2.2) * 0.7
		var kk: float = 1.0 if dist < 300.0 else 0.35
		e.position += (Vector2.from_angle(ang) * spd * kk + e.knock) * delta
		e.position = _collide(e.position, e.radius * 0.5)
		e.knock *= kn_decay
		e.face_angle(ang)
		e.loop_anim("Walk", 1.4)
		return
	if e.behavior == "runner":
		# Va a donde vas a estar.
		var lead: float = clampf(dist / maxf(60.0, spd), 0.0, 1.4)
		var tgt: Vector2 = player.position + player_vel * lead
		var d2: Vector2 = tgt - e.position
		if d2.length() > 0.001:
			dirv = d2.normalized()
	# Personalidades: escudo, salto, explosion.
	if e.shield_lock > 0.0:
		e.shield_lock -= delta
	if e.shield_t > 0.0:
		e.shield_t -= delta
		if e.shield_t <= 0.0:
			e.shield = 0.0
	if e.jump != null:
		_update_jump(e, delta)
		return
	if e.behavior == "bomber" and e.phase == "fuse":
		e.pt -= delta
		e.flash = 0.05 if int(e.pt * 10.0) % 2 == 1 else 0.0
		if e.pt <= 0.0:
			_kill_enemy(e)
		e.loop_anim("Idle", 1.0)
		return
	if e.behavior == "bomber" and dist < e.radius + player.radius + 26.0:
		e.phase = "fuse"
		e.pt = 1.0
		_hazard_zone(e.position, 62.0, 1.0, e.dmg * 1.4, e.atk_type, Color("#ff7b3d"))
		return
	if e.behavior == "shielder" or e.behavior == "jumper":
		e.skill_cd -= delta
		if e.skill_cd <= 0.0:
			if e.behavior == "shielder":
				e.skill_cd = 8.0
				_cast_shields(e)
			elif dist < 250.0:
				e.skill_cd = randf_range(5.0, 7.0)
				_start_jump(e)
				return
			else:
				e.skill_cd = 0.5
	var v: Vector2 = dirv * spd
	var abase: String = "Walk"
	if e.boss:
		var r: Array = _boss_move(e, delta, dist, dirv, spd)
		v = r[0]
		abase = String(r[1])
	elif e.behavior == "charger":
		e.pt -= delta
		if e.phase == "walk":
			if dist < 200.0 and e.pt <= 0.0:
				e.phase = "aim"
				e.pt = 0.55
				e.play("Charge", 1.6)
		elif e.phase == "aim":
			v = Vector2.ZERO
			abase = "Idle"
			if e.pt <= 0.0:
				e.phase = "dash"
				e.pt = 0.42
				e.dash_dir = dirv
				e.play("Attack", 1.4)
				_ring(e.position, e.radius, e.radius * 2.4, Color("#ff6b6b"), 0.25)
		elif e.phase == "dash":
			v = e.dash_dir * spd * 3.4
			if e.pt <= 0.0:
				e.phase = "walk"
				e.pt = 1.1
	elif KEEP_DIST.has(e.behavior):
		var rng: float = float(e.def.get("range", 200.0))
		var keep: float = rng * 0.82
		if dist < keep * 0.75:
			v = -dirv * spd * 0.8
		elif dist < keep:
			v *= 0.1
			abase = "Idle"
		e.shot_cd -= delta * (0.4 if e.para_t > 0.0 else 1.0)
		if e.shot_cd <= 0.0 and dist < rng:
			e.shot_cd = float(e.def.get("shotCd", 2.0))
			_enemy_special(e, dirv)
	e.position += (v + e.knock) * delta
	# Solo los voladores pasan por encima de las paredes
	if not e.flying:
		e.position = _collide(e.position, e.radius * 0.5)
		e.position = _spring_push(e.position)
	e.knock *= kn_decay
	var moving: bool = v.length() > 2.0
	var face: float = to.angle()
	if e.phase == "dash":
		face = e.dash_dir.angle()
	elif moving:
		face = v.angle()
	e.face_angle(face)
	e.loop_anim(abase if moving else "Idle", maxf(0.6, spd / 70.0) if moving else 1.0)
	# Contacto con el jugador (combat.js): cada 0,55 s por enemigo.
	var rr: float = e.radius + player.radius
	if dist <= rr and e.touch_cd <= 0.0 and e.behavior != "thief":
		e.touch_cd = 0.55
		e.strike(to.angle())
		_hurt_player(e.dmg, e.atk_type)
		e.knock = -dirv * 150.0
		if _has_item("rockyhelmet"):
			_damage_enemy(e, 15.0 + float(player.level) * 4.0, Color("#9aa6b5"), -dirv, 80.0)
		if _has_item("eternalice"):
			e.apply_slow(0.3, 2.0)
		if not ab_fx.is_empty():
			if ab_fx.has("thorns"):
				_damage_enemy(e, 12.0 + float(player.level) * 3.0, Color("#9aa6b5"), -dirv, 60.0)
			if ab_fx.has("contact") and not e.dead and randf() < _abn("contact_p"):
				var ck: String = String(ab_fx["contact"])
				if ck == "burn":
					e.apply_burn(1)
				elif ck == "poison":
					e.apply_poison(1)
				else:
					_apply_cc(e, ck)


func _shot_dmg(e: Enemy) -> float:
	var base_dmg: float = maxf(0.001, float(e.def.get("dmg", 1.0)))
	return float(e.def.get("shotDmg", 10.0)) * (e.dmg / base_dmg)


func _enemy_shoot(e: Enemy, ang: float, spread: float, n: int, k: float) -> void:
	for i in range(n):
		var a: float = ang
		if n > 1:
			a = ang + (float(i) / float(n - 1) - 0.5) * spread
		var b := EBullet.new()
		b.position = e.position
		b.vel = Vector2.from_angle(a) * 190.0
		b.dmg = _shot_dmg(e) * k
		b.mtype = e.atk_type
		b.color = Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e")))
		fx.add_child(b)
		ebullets.append(b)
	e.play("Shoot", 1.0)
	_ring(e.position + Vector2(0.0, -LIFT), 4.0, 14.0, Color("#ff7a9e"), 0.2)


func _enemy_special(e: Enemy, dirv: Vector2) -> void:
	var col := Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e")))
	var ang: float = dirv.angle()
	var b: String = e.behavior
	if b == "fan":
		var n: int = int(e.def.get("fanN", 5))
		_enemy_shoot(e, ang, 0.6 if n == 3 else 0.9, n, 0.65)
	elif b == "beamer":
		_hazard_beam(e.position, ang, 360.0, 22.0, 1.0, _shot_dmg(e) * 1.05, e.atk_type, col)
		e.play("Charge", 1.2)
	elif b == "zoner":
		var n2: int = randi_range(1, int(e.def.get("zones", 3)))
		for i in range(n2):
			var off := Vector2.ZERO
			if i > 0:
				off = Vector2(randf_range(-70.0, 70.0), randf_range(-55.0, 55.0))
			_hazard_zone(player.position + off, 44.0, 1.2, _shot_dmg(e) * 0.95, e.atk_type, col)
		e.play("Shoot", 1.0)
	elif b == "healer":
		_heal_around(e)
	elif b == "summoner":
		_summon(e)
	else:
		_enemy_shoot(e, ang, 0.0, 1, 1.0)


func _heal_around(e: Enemy) -> void:
	# 7% de la vida, mas cuanto mas fuerte pegas (con tope x2,5).
	var pw: float = maxf(1.0, _atk() / maxf(0.001, base_atk))
	var k: float = 0.07 * minf(2.5, pow(pw, 0.35))
	# Balance: con mas de 4 curanderos vivos la curacion baja un 10 %.
	var healers := 0
	for h in enemies:
		if not h.dead and h.behavior == "healer":
			healers += 1
	if healers > 4:
		k *= 0.9
	for o in enemies:
		if o.dead or o.hp >= o.max_hp:
			continue
		if o.position.distance_to(e.position) <= 150.0:
			o.hp = minf(o.max_hp, o.hp + o.max_hp * k)
			o.queue_redraw()
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 150.0, Color("#5fe08a"), 0.5)


func _cast_shields(e: Enemy) -> void:
	var near: Array = []
	for o in enemies:
		if not o.dead and o.position.distance_to(e.position) <= 160.0:
			near.append(o)
	near.sort_custom(func(a, b): return a.position.distance_squared_to(e.position) < b.position.distance_squared_to(e.position))
	# Balance: escudo del 30 % (antes 35 %) durante 7 s, y un mismo Pokemon no recibe otro
	# hasta 14 s despues (nada de escudos infinitos). Maximo 5 por lanzamiento.
	var given := 0
	for i in range(near.size()):
		if given >= 5:
			break
		var o2 = near[i]
		if o2.shield > 0.0 or o2.shield_lock > 0.0:
			continue
		o2.shield = o2.max_hp * 0.30
		o2.shield_t = 7.0
		o2.shield_lock = 14.0
		given += 1
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 160.0, Color("#7fc8ff"), 0.5)


func _summon(e: Enemy) -> void:
	var alive: Array = []
	for m in e.minions:
		if is_instance_valid(m) and not m.dead:
			alive.append(m)
	e.minions = alive
	# Balance: cada invocacion saca 4, con un maximo de 20 subditos vivos en todo el mapa
	# (y 8 por invocador).
	var total_minions := 0
	for q in enemies:
		if q.is_minion and not q.dead:
			total_minions += 1
	if e.minions.size() >= 8 or total_minions >= 20 or enemies.size() > ENEMY_CAP + 15:
		return
	var dex: int = int(e.def.get("minion", e.dex))
	if not _dex_by.has(dex) or not _smeta.has(str(dex)):
		dex = e.dex
	var def := {"dex": dex, "name": String(_dex_by[dex]["name"]), "hp": roundf(float(e.def["hp"]) * 0.35),
		"spd": roundf(float(e.def["spd"]) * 1.1), "dmg": roundf(float(e.def["dmg"]) * 0.6),
		"xp": maxf(1.0, roundf(float(e.def["xp"]) * 0.25)), "behavior": "chase"}
	for i in range(mini(4, 20 - total_minions)):
		var a: float = randf() * TAU
		var m2: Enemy = _make_enemy(def, e.position + Vector2(cos(a) * 30.0, sin(a) * 22.0), e.sc)
		m2.is_minion = true
		e.minions.append(m2)
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 50.0, Color("#c47bff"), 0.4)


func _start_jump(e: Enemy) -> void:
	e.jump = {"sx": e.position.x, "sy": e.position.y, "tx": player.position.x, "ty": player.position.y, "t": -0.45, "dur": 0.6}
	e.play("Charge", 1.4)
	_hazard_zone(player.position, 50.0, 1.05, e.dmg * 1.2, e.atk_type, Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e"))))


func _update_jump(e: Enemy, delta: float) -> void:
	var j: Dictionary = e.jump
	j["t"] = float(j["t"]) + delta
	if float(j["t"]) < 0.0:
		e.loop_anim("Idle", 1.0)
		return
	var k: float = minf(1.0, float(j["t"]) / float(j["dur"]))
	var s := Vector2(float(j["sx"]), float(j["sy"]))
	var tg := Vector2(float(j["tx"]), float(j["ty"]))
	e.position = s.lerp(tg, k)
	if not e.flying:
		e.position = _collide(e.position, e.radius * 0.5)   # el salto no cruza paredes
	e.lift_extra = sin(k * PI) * 46.0
	e.face_angle((tg - s).angle())
	if k >= 1.0:
		e.jump = null
		e.lift_extra = 0.0
		e.play("Attack", 1.4)


func _kill_enemy(e: Enemy) -> void:
	if e.dead:
		return
	e.hp = 1.0
	_damage_enemy(e, 1.0, Color.WHITE)


# --- jefes: 4 ataques (Pisoton + Embestida o Salto, y 2 de lejos segun tipo) ---
func _boss_init(e: Enemy) -> void:
	var t: Array = e.types
	var melee := ["slam", "dash" if _hash(e.dex, 3, 7) < 0.5 else "leap"]
	var pref: String = "volley"
	if _has_t(t, ["fire", "ground", "poison", "rock", "grass"]):
		pref = "rain"
	elif _has_t(t, ["electric", "psychic", "dragon", "ice", "steel"]):
		pref = "beam"
	elif _has_t(t, ["fairy", "ghost", "water", "flying"]):
		pref = "nova"
	var others: Array = ["rain", "beam", "nova", "volley"]
	others.erase(pref)
	var ranged: Array = [pref, others[int(_hash(e.dex, 5, 9) * 3.0) % 3]]
	var far: bool = e.behavior == "ranged"
	e.ai = {"melee": melee, "ranged": ranged, "far_like": 0.65 if far else 0.35, "mode": "far" if far else "close",
		"mode_t": randf_range(6.0, 8.0), "cd": 1.6, "cast": null, "fury": false, "side": 1.0 if randf() < 0.5 else -1.0}


func _boss_enrage(e: Enemy) -> void:
	e.ai["fury"] = true
	e.spd *= 1.15
	if not e.judge:
		_say(L.t("¡%s se ha enfurecido!") % e.enemy_name, 2.4)
	_ring(e.position, e.radius, e.radius * 5.0, Color("#ff4a4a"), 0.6)
	shake = 8.0


func _boss_move(e: Enemy, delta: float, dist: float, dirv: Vector2, spd: float) -> Array:
	if e.ai.is_empty():
		_boss_init(e)
	var ai: Dictionary = e.ai
	if not bool(ai["fury"]) and e.hp < e.max_hp * 0.5:
		_boss_enrage(e)
	# Jefe final de la Torre: ultimo aliento al 25% de vida (mas rapido y llama a una oleada)
	if bool(e.def.get("final", false)) and not bool(ai.get("last", false)) and e.hp < e.max_hp * 0.25:
		ai["last"] = true
		e.spd *= 1.1
		_say(L.t("¡%s lo da todo!") % e.enemy_name, 2.6)
		_ring(e.position, e.radius, e.radius * 6.0, Color("#ffffff"), 0.8)
		shake = 12.0
		var ba: float = randf() * TAU
		for i in range(maxi(0, mini(14, _tw_cap() - enemies.size()))):
			_spawn_one(ba + randf_range(-0.9, 0.9))
	var k: float = 1.25 if bool(ai["fury"]) else 1.0
	if ai["cast"] != null:
		return _boss_cast(e, delta)
	ai["mode_t"] = float(ai["mode_t"]) - delta
	ai["cd"] = float(ai["cd"]) - delta * k
	if float(ai["mode_t"]) <= 0.0:
		ai["mode"] = "close" if String(ai["mode"]) == "far" else "far"
		var fav: bool = (String(ai["mode"]) == "far") == (float(ai["far_like"]) > 0.5)
		ai["mode_t"] = randf_range(7.0, 9.0) if fav else randf_range(4.0, 5.0)
		ai["side"] = -float(ai["side"])
	var v: Vector2 = dirv * spd * k * 1.1
	if String(ai["mode"]) == "far":
		if dist < 170.0:
			v = -dirv * spd
		elif dist < 300.0:
			v = Vector2(-dirv.y, dirv.x) * spd * 0.55 * float(ai["side"])
	if float(ai["cd"]) <= 0.0:
		var id: String = ""
		if String(ai["mode"]) == "close":
			var ok: Array = []
			for m in ai["melee"]:
				if (m == "slam" and dist < 125.0) or (m != "slam" and dist < 320.0):
					ok.append(m)
			if not ok.is_empty() and randf() < 0.8:
				id = String(ok[randi() % ok.size()])
			elif dist < 480.0:
				id = String(ai["ranged"][randi() % 2])
		else:
			if dist < 115.0:
				id = "slam"
			elif dist < 430.0:
				id = String(ai["ranged"][randi() % 2])
		if id != "" and bool(e.def.get("dyna", false)) and dist < 520.0 and randf() < 0.28:
			id = "maxmove"
		if id != "":
			_boss_start(e, id)
	return [v, "Walk"]


func _boss_start(e: Enemy, id: String) -> void:
	var ai: Dictionary = e.ai
	var f: float = 0.8 if bool(ai["fury"]) else 1.0
	var type: String = e.atk_type
	var col := Color.html(String(MD.TYPE_COLOR.get(type, "#ff7a9e")))
	var ang: float = (player.position - e.position).angle()
	var c := {"id": id, "t": 0.0, "wind": 0.6 * f, "after": 0.35, "ang": ang, "go": false, "fired": false, "len": 0.0, "dur": 0.0}
	ai["cast"] = c
	if id == "slam":
		c["wind"] = 0.85 * f
		_hazard_zone(e.position, 96.0 + e.radius, float(c["wind"]), e.dmg * 1.3, type, col)
		e.play("Charge", 1.2)
	elif id == "dash":
		c["wind"] = 0.75 * f
		c["len"] = 330.0
		c["dur"] = 0.32
		_hazard_beam(e.position, ang, 330.0 + e.radius, e.radius * 2.0 + 16.0, float(c["wind"]) + 0.32, e.dmg * 1.2, type, col)
		e.play("Charge", 1.3)
	elif id == "leap":
		e.jump = {"sx": e.position.x, "sy": e.position.y, "tx": player.position.x, "ty": player.position.y, "t": -0.5 * f, "dur": 0.65}
		_hazard_zone(player.position, 82.0, 0.5 * f + 0.65, e.dmg * 1.25, type, col)
		e.play("Charge", 1.4)
		ai["cast"] = null
		ai["cd"] = randf_range(1.4, 2.0) + 0.6
	elif id == "rain":
		var n: int = 6 if bool(ai["fury"]) else 4
		for i in range(n):
			var a: float = randf() * TAU if i > 0 else 0.0
			var d: float = randf_range(40.0, 120.0) if i > 0 else 0.0
			_hazard_zone(player.position + Vector2(cos(a) * d, sin(a) * d * 0.8), 50.0, 1.05 + float(i) * 0.12, _shot_dmg(e) * 1.15, type, col)
		c["wind"] = 0.5
		e.play("Shoot", 1.0)
	elif id == "beam":
		var nb: int = 5 if bool(ai["fury"]) else 3
		var sp: float = 0.42 if bool(ai["fury"]) else 0.5
		for i in range(nb):
			_hazard_beam(e.position, ang + (float(i) - float(nb - 1) / 2.0) * sp, 400.0, 26.0, 1.0, _shot_dmg(e) * 1.2, type, col)
		c["wind"] = 1.0
		c["after"] = 0.25
		e.play("Charge", 1.1)
	elif id == "maxmove":
		# Movimiento Max: dos anillos de explosiones alrededor del jefe (hay huecos entre ellas)
		c["wind"] = 1.5 * f
		c["after"] = 0.6
		e.play("Charge", 0.9)
		_ring(e.position, e.radius, e.radius * 4.0, col, float(c["wind"]))
		var md: float = _shot_dmg(e) * 1.4
		_hazard_zone(e.position, 110.0 + e.radius, 1.3 * f, md, type, col)
		var a0: float = randf() * TAU
		for i in range(6):
			var a1: float = a0 + TAU * float(i) / 6.0
			_hazard_zone(e.position + Vector2(cos(a1), sin(a1) * 0.85) * 190.0, 62.0, 1.4 * f, md, type, col)
		for i in range(9):
			var a2: float = a0 + 0.3 + TAU * float(i) / 9.0
			_hazard_zone(e.position + Vector2(cos(a2), sin(a2) * 0.85) * 330.0, 56.0, 1.7 * f, md, type, col)
		shake = maxf(shake, 5.0)
	elif id == "volley" or id == "nova":
		c["wind"] = (0.7 if id == "nova" else 0.5) * f
		e.play("Charge", 1.4)
		_ring(e.position, e.radius, e.radius * 2.4, col, float(c["wind"]))


func _boss_cast(e: Enemy, delta: float) -> Array:
	var ai: Dictionary = e.ai
	var c: Dictionary = ai["cast"]
	c["t"] = float(c["t"]) + delta
	var id: String = String(c["id"])
	if id == "dash" and float(c["t"]) >= float(c["wind"]):
		if not bool(c["go"]):
			c["go"] = true
			e.play("Attack", 1.6)
		if float(c["t"]) >= float(c["wind"]) + float(c["dur"]):
			return _boss_end(e)
		var sp: float = float(c["len"]) / float(c["dur"])
		return [Vector2.from_angle(float(c["ang"])) * sp, "Walk"]
	if float(c["t"]) >= float(c["wind"]) and not bool(c["fired"]):
		c["fired"] = true
		var a0: float = (player.position - e.position).angle()
		var fury: bool = bool(ai["fury"])
		if id == "volley":
			_enemy_shoot(e, a0, 1.1, 9 if fury else 7, 0.8)
		elif id == "nova":
			var n: int = 18 if fury else 14
			_enemy_shoot(e, a0, TAU * float(n - 1) / float(n), n, 0.7)
		elif id == "slam":
			e.play("Attack", 1.4)
	if float(c["t"]) >= float(c["wind"]) + float(c["after"]):
		return _boss_end(e)
	return [Vector2.ZERO, "Idle"]


func _boss_end(e: Enemy) -> Array:
	var ai: Dictionary = e.ai
	ai["cast"] = null
	ai["cd"] = randf_range(1.3, 2.0)
	if bool(ai["fury"]) and randf() < 0.35:
		ai["cd"] = 0.3
	return [Vector2.ZERO, "Idle"]


# --- ataques con aviso en el suelo (hazards.js) y disparos enemigos ---
func _hazard_zone(pos: Vector2, r: float, delay: float, dmg: float, type: String, col: Color) -> Hazard:
	var h := Hazard.new()
	h.kind = "zone"
	h.position = pos
	h.r = r
	h.delay = delay
	h.dmg = dmg
	h.mtype = type
	h.color = col
	gfx.add_child(h)
	hazards.append(h)
	return h


func _hazard_beam(pos: Vector2, angle: float, length: float, width: float, delay: float, dmg: float, type: String, col: Color) -> Hazard:
	var h := Hazard.new()
	h.kind = "beam"
	h.position = pos
	h.angle = angle
	h.length = length
	h.width = width
	h.delay = delay
	h.dmg = dmg
	h.mtype = type
	h.color = col
	gfx.add_child(h)
	hazards.append(h)
	return h


func _hazard_inside(h: Hazard) -> bool:
	var pr: float = player.radius
	if h.kind == "zone":
		return player.position.distance_squared_to(h.position) < pow(h.r + pr * 0.6, 2.0)
	var d: Vector2 = Vector2.from_angle(h.angle)
	var rel: Vector2 = player.position - h.position
	var along: float = rel.dot(d)
	if along < -pr or along > h.length + pr:
		return false
	return absf(-rel.x * d.y + rel.y * d.x) <= h.width * 0.5 + pr * 0.6


func _hazard_hits_enemy(h: Hazard, en) -> bool:
	var er: float = en.radius
	if h.kind == "zone":
		return en.position.distance_squared_to(h.position) < pow(h.r + er * 0.6, 2.0)
	var d: Vector2 = Vector2.from_angle(h.angle)
	var rel: Vector2 = en.position - h.position
	var along: float = rel.dot(d)
	if along < -er or along > h.length + er:
		return false
	return absf(-rel.x * d.y + rel.y * d.x) <= h.width * 0.5 + er * 0.6


# Ataques de jefe del aliado capturado: los mismos de los jefes (pisoton, embestida, salto, lluvia, rayos, onda, salvas), pero contra los enemigos.
func _ally_boss_attack(lg, tg) -> void:
	if lg.boss_moves.is_empty():
		var t: Array = [lg.ltype]
		var pref := "volley"
		if _has_t(t, ["fire", "ground", "poison", "rock", "grass"]):
			pref = "rain"
		elif _has_t(t, ["electric", "psychic", "dragon", "ice", "steel"]):
			pref = "beam"
		elif _has_t(t, ["fairy", "ghost", "water", "flying"]):
			pref = "nova"
		var others: Array = ["rain", "beam", "nova", "volley"]
		others.erase(pref)
		lg.boss_moves = ["slam", "dash" if _hash(lg.dex, 3, 7) < 0.5 else "leap", pref, others[int(_hash(lg.dex, 5, 9) * 3.0) % 3]]
	var id: String = String(lg.boss_moves[randi() % lg.boss_moves.size()])
	var d: float = lg.position.distance_to(tg.position)
	if id == "slam" and d > 150.0:
		id = "leap"
	var col: Color = lg.col
	var ang: float = (tg.position - lg.position).angle()
	var dm: float = lg.dmg
	if id == "slam":
		_ally_hz(_hazard_zone(lg.position, 96.0 + lg.radius, 0.55, 0.0, lg.ltype, col), dm * 1.8)
		lg.play("Charge", 1.2)
	elif id == "dash":
		_ally_hz(_hazard_beam(lg.position, ang, 330.0 + lg.radius, lg.radius * 2.0 + 16.0, 0.55, 0.0, lg.ltype, col), dm * 1.6)
		lg.play("Charge", 1.3)
	elif id == "leap":
		_ally_hz(_hazard_zone(tg.position, 82.0, 0.65, 0.0, lg.ltype, col), dm * 1.7)
		lg.play("Charge", 1.4)
	elif id == "rain":
		for i in range(4):
			var a: float = randf() * TAU if i > 0 else 0.0
			var dd: float = randf_range(40.0, 120.0) if i > 0 else 0.0
			_ally_hz(_hazard_zone(tg.position + Vector2(cos(a) * dd, sin(a) * dd * 0.8), 50.0, 0.6 + float(i) * 0.12, 0.0, lg.ltype, col), dm * 1.1)
		lg.play("Shoot", 1.0)
	elif id == "beam":
		for i in range(3):
			_ally_hz(_hazard_beam(lg.position, ang + (float(i) - 1.0) * 0.5, 400.0, 26.0, 0.8, 0.0, lg.ltype, col), dm * 1.3)
		lg.play("Charge", 1.1)
	elif id == "nova":
		_ally_hz(_hazard_zone(lg.position, 250.0, 0.7, 0.0, lg.ltype, col), dm * 1.2)
		_ring(lg.position, lg.radius, 250.0, col, 0.7)
		lg.play("Charge", 1.4)
	else:   # volley: abanico de rayos finos
		for i in range(5):
			_ally_hz(_hazard_beam(lg.position, ang + (float(i) - 2.0) * 0.27, 420.0, 14.0, 0.5, 0.0, lg.ltype, col), dm * 0.9)
		lg.play("Charge", 1.4)
	Aud.sfx("boss")


func _ally_hz(h: Hazard, dm: float) -> void:
	h.ally_dmg = dm


func _update_hazards(delta: float) -> void:
	trap_slow_t = maxf(0.0, trap_slow_t - delta)
	wp_t = maxf(0.0, wp_t - delta)
	trap_freeze_t = maxf(0.0, trap_freeze_t - delta)
	trap_para_t = maxf(0.0, trap_para_t - delta)
	trap_sleep_t = maxf(0.0, trap_sleep_t - delta)
	trap_conf_t = maxf(0.0, trap_conf_t - delta)
	if ab_fx.has("stimm"):
		var si: Array = ab_fx["stimm"]
		if si.has("freeze"):
			trap_freeze_t = 0.0
		if si.has("para"):
			trap_para_t = 0.0
		if si.has("sleep"):
			trap_sleep_t = 0.0
		if si.has("conf"):
			trap_conf_t = 0.0
	for i in range(hazards.size() - 1, -1, -1):
		var h: Hazard = hazards[i]
		h.t += delta
		if not h.hit and h.t >= h.delay:
			h.hit = true
			if h.vis == "pillar":
				var pf := Fx.new()
				pf.kind = "beam"
				pf.color = h.color
				pf.position = h.position
				pf.ang = -PI / 2.0
				pf.length = 420.0
				pf.width = h.r * 1.1
				pf.life = 0.4
				fx.add_child(pf)
				_ring(h.position, 4.0, h.r * 1.3, Color("#fff3c8"), 0.4)
				Aud.sfx("judge")
				shake = maxf(shake, 3.0)
			elif h.kind == "zone":
				_ring(h.position, 4.0, h.r, h.color, 0.35)
				if h.r > 60.0:
					shake = maxf(shake, 4.0)
			else:
				var f := Fx.new()
				f.kind = "beam"
				f.color = h.color
				f.position = h.position
				f.ang = h.angle
				f.length = h.length
				f.width = h.width
				f.life = 0.3
				fx.add_child(f)
			if h.ally_dmg > 0.0:
				for en in enemies.duplicate():
					if en.dead or bool(en.def.get("scripted", false)):
						continue
					if _hazard_hits_enemy(h, en):
						_damage_enemy(en, h.ally_dmg, h.color, (en.position - h.position).normalized(), 140.0)
			elif not player.dead and _hazard_inside(h):
				player.invuln = 0.0
				if h.pct > 0.0:
					_hurt_player(maxf(h.dmg, player.max_hp * h.pct), "", h.pure)
				else:
					_hurt_player(h.dmg, h.mtype)
				if h.slows:
					trap_slow_t = 2.0
		if h.hit and h.t >= h.delay + 0.3:
			h.queue_free()
			hazards.remove_at(i)


func _update_ebullets(delta: float) -> void:
	for i in range(ebullets.size() - 1, -1, -1):
		var b: EBullet = ebullets[i]
		b.age += delta
		var eprev: Vector2 = b.position
		b.position += b.vel * delta
		var remove: bool = b.age >= 2.4 or _wall_hit(eprev, b.position)
		if not remove:
			var rr: float = 7.0 + player.radius
			if b.position.distance_squared_to(player.position) < rr * rr:
				_hurt_player(b.dmg, b.mtype)
				remove = true
		if remove:
			b.queue_free()
			ebullets.remove_at(i)


func _nearest_enemy(from: Vector2, reach: float) -> Node2D:
	var best: Node2D = null
	var best_d2: float = reach * reach
	for e in enemies:
		if e.dead:
			continue
		var d2: float = from.distance_squared_to(e.position)
		if d2 <= best_d2:
			best_d2 = d2
			best = e
	return best


func _damage_enemy(e, amount: float, col: Color = Color.WHITE, dir: Vector2 = Vector2.ZERO, knock: float = 0.0, eff: String = "") -> void:
	if e.dead:
		return
	if e.frozen_t > 0.0:
		amount *= 1.25
	var d: float = maxf(1.0, roundf(amount))
	jd.note_dmg(d, e)
	_cut_grass(e.position, 34.0)
	# Escudo: absorbe primero.
	if e.shield > 0.0:
		var ab: float = minf(e.shield, d)
		e.shield -= ab
		if ab >= d:
			add_text(e.position + Vector2(0.0, -e.body_h - 4.0), str(roundi(d)), Color("#9fd8ff"))
			e.flash = 0.5
			return
		d -= ab
	var tc: Color = col.lerp(Color.WHITE, 0.55)
	var ts: int = 18
	if e.boss:
		ts = 24
	if eff == "super":
		tc = Color("#ffe14d")
		ts = 26
	elif eff == "weak":
		tc = Color("#a3abb8")
	var src_k: String = dmg_src if dmg_src != "" else "_other"
	run_dmg[src_k] = float(run_dmg.get(src_k, 0.0)) + minf(d, maxf(0.0, e.hp))
	add_text(e.position + Vector2(0.0, -e.body_h - 4.0), str(roundi(d)), tc, ts)
	if knock > 0.0 and dir != Vector2.ZERO and not e.boss:
		e.knock += dir.normalized() * knock
	Aud.sfx("hit")
	if e.hurt_by(d):
		kills += 1
		run_kills_by[src_k] = int(run_kills_by.get(src_k, 0)) + 1
		if tw_risk.has("l_reap"):
			reap_kills += 1
		if not tw_risk.is_empty() and not player.dead:
			var kh: float = _rk_add("killheal")
			if kh > 0.0:
				player.hp = minf(player.max_hp, player.hp + kh)
		var lg: int = e.dex if (e.legend and not e.judge and not bool(e.def.get("dyna", false))) else 0
		_ch_kill(e, src_k)
		PG.event("kill", {"types": e.types, "boss": e.boss and not e.judge, "legend": lg})
		Aud.sfx("bossDown" if e.boss else "faint")
		_drop(e)


# ---------------------------------------------------------------
# Mundo: trozos infinitos con arboles, rocas, charcos, cofres, altares,
# fuentes y trampas (generados al vuelo, siempre igual para una misma partida)
# ---------------------------------------------------------------
func _chunk_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK), floori(pos.y / CHUNK))


func _gen_chunk(cx: int, cy: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi((cx * 73856093) ^ (cy * 19349663) ^ (world_seed * 83492791)) + 1
	var props: Array = []
	var placed: Array = []
	var grass_items: Array = []
	# Objetos de los trozos vecinos ya generados: evita arboles/rocas/cofres encima de otros en los bordes
	for ddy in range(-1, 2):
		for ddx in range(-1, 2):
			var nk := Vector2i(cx + ddx, cy + ddy)
			if (ddx != 0 or ddy != 0) and chunks.has(nk):
				for np in chunks[nk]["props"]:
					if is_instance_valid(np):
						placed.append([np.position, np.r, np.kind])
	var bx: int = cx * 16
	var by: int = cy * 16
	for j in range(16):
		for i in range(16):
			var tx: int = bx + i
			var ty: int = by + j
			# Lo barato primero: casi ninguna casilla es candidata a arbol o roca
			var h: float = ARENA.hsh(tx, ty, world_seed + 404)
			if h >= 0.045 and h <= 0.994:
				continue
			if ground.terrain(tx, ty) != 0:
				continue
			var dist0: float = Vector2(float(tx) + 0.5, float(ty) + 0.5).length()
			if dist0 < 8.0:
				continue
			var grove: bool = h < 0.045 and ARENA.fbm(float(tx) / 10.0, float(ty) / 10.0, world_seed + 505) > 0.62
			var is_tree: bool = h < (0.045 if grove else 0.004)
			if not is_tree and h <= 0.994:
				continue
			if not ground.open_at(tx, ty):
				continue
			var wp := Vector2((float(tx) + 0.5) * ground.TS + rng.randf_range(-8.0, 8.0), (float(ty) + 0.5) * ground.TS + rng.randf_range(-6.0, 6.0))
			if is_tree and ground.tree_clear(tx, ty):
				_add_prop(props, placed, "tree", wp, 15.0, rng)
			elif h > 0.994:
				_add_prop(props, placed, "rock", wp, 18.0, rng)
	# Especiales (en sitios abiertos, lejos del inicio y de cualquier otro objeto)
	if rng.randf() < 0.22 * (kec.map_mul() if kec != null else 1.0) and not menu_mode:
		_place_special("chest", 16.0, 7.0, props, placed, rng, cx, cy)
	if rng.randf() < 0.08 and not menu_mode:
		_place_special("spring", 40.0, 10.0, props, placed, rng, cx, cy)
	if rng.randf() < 0.08 and not menu_mode:
		_alt_legend = rng.randf() < 0.25 and not _lg_pool().is_empty()
		_place_special("altar", 100.0 if _alt_legend else 18.0, 10.0, props, placed, rng, cx, cy)
		_alt_legend = false
	if rng.randf() < 0.3:
		_place_special("trap", 16.0, 13.0, props, placed, rng, cx, cy)
	# Hierba en parches: matas a media casilla, con las filas alternadas, para que se unan y no queden una por casilla
	var half: float = ground.TS * 0.5
	# Terreno del trozo y 3 casillas de margen, calculado una sola vez (antes se pedia 25 veces por mata)
	var tg := PackedByteArray()
	tg.resize(22 * 22)
	for tj in range(22):
		for ti in range(22):
			tg[tj * 22 + ti] = 1 if ground.terrain(bx - 3 + ti, by - 3 + tj) != 0 else 0
	var gnear := PackedByteArray()   # 1 = hay agua o pared a menos de 2 casillas
	gnear.resize(22 * 22)
	for tj in range(2, 20):
		for ti in range(2, 20):
			var bad: int = 0
			for oy in range(-2, 3):
				for ox in range(-2, 3):
					bad |= tg[(tj + oy) * 22 + ti + ox]
			gnear[tj * 22 + ti] = bad
	var tile_px: float = ground.TS
	var sq8: float = 8.0 * tile_px
	for sj in range(32):
		for si in range(32):
			var gx: float = float(bx) * tile_px + float(si) * half + half * 0.5 + (half * 0.5 if sj % 2 == 1 else 0.0)
			var gy: float = float(by) * tile_px + float(sj) * half + half * 0.5
			# primero lo barato (casi todas se descartan aqui)
			if ARENA.hsh(si + bx * 2, sj + by * 2, world_seed + 808) > 0.38:
				continue
			var gtx: int = floori(gx / tile_px)
			var gty: int = floori(gy / tile_px)
			var li: int = gtx - bx + 3
			var lj: int = gty - by + 3
			if li < 2 or li > 19 or lj < 2 or lj > 19:
				continue
			if gnear[lj * 22 + li] != 0 or tg[lj * 22 + li] != 0:
				continue
			if Vector2(gx, gy).length() < sq8:
				continue
			var gf: float = ARENA.fbm(gx / (tile_px * 5.0), gy / (tile_px * 5.0), world_seed + 707)
			if gf < 0.66:
				continue
			var gp := Vector2(gx + ARENA.hsh(si, sj + bx, world_seed + 909) * 6.0 - 3.0, gy + ARENA.hsh(sj, si + by, world_seed + 919) * 4.0 - 2.0)
			var blocked := false
			for pl in placed:
				var pk: String = String(pl[2]) if pl.size() > 2 else ""
				var margin: float = 40.0 if (pk == "rock" or pk == "altar" or pk == "chest" or pk == "spring" or pk == "trap") else 22.0
				if gp.distance_to(pl[0]) < float(pl[1]) + margin:
					blocked = true
					break
			if not blocked:
				grass_items.append(Vector3(gp.x, gp.y + 14.0, rng.randf() * TAU))
	grass_items.sort_custom(func(u: Vector3, v: Vector3) -> bool: return u.y < v.y)
	ground.add_grass(Vector2i(cx, cy), grass_items)
	return {"props": props}


func _place_special(kind: String, r: float, min_tiles: float, props: Array, placed: Array, rng: RandomNumberGenerator, cx: int, cy: int) -> void:
	for attempt in range(10):
		var tx: int = cx * 16 + rng.randi_range(1, 14)
		var ty: int = cy * 16 + rng.randi_range(1, 14)
		if Vector2(float(tx) + 0.5, float(ty) + 0.5).length() < min_tiles:
			continue
		if not ground.open_at(tx, ty):
			continue
		var pos := Vector2((float(tx) + 0.5) * ground.TS, (float(ty) + 0.5) * ground.TS + 10.0)
		if _add_prop(props, placed, kind, pos, r, rng):
			return


# La copa de un arbol tapa lo que queda detras o debajo: cofres, altares, fuentes y trampas no van ahi (ni al reves)
func _hidden_by_tree(pa: Vector2, ka: String, ra: float, pb: Vector2, kb: String, rb: float) -> bool:
	var tree_p: Vector2
	var other_p: Vector2
	var other_r: float
	if ka == "tree" and (kb == "chest" or kb == "spring" or kb == "altar" or kb == "trap"):
		tree_p = pa
		other_p = pb
		other_r = rb
	elif kb == "tree" and (ka == "chest" or ka == "spring" or ka == "altar" or ka == "trap"):
		tree_p = pb
		other_p = pa
		other_r = ra
	else:
		return false
	var dy: float = other_p.y - tree_p.y
	return absf(other_p.x - tree_p.x) < 38.0 + other_r * 0.9 and dy > -110.0 and dy < 50.0 + other_r


func _grass_near(pos: Vector2, rad: float) -> bool:
	var c: Vector2i = _chunk_of(pos)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var arr = ground.grass.get(Vector2i(c.x + dx, c.y + dy))
			if arr == null:
				continue
			for g in arr:
				if Vector2(g.x, g.y - 14.0).distance_to(pos) < rad:
					return true
	return false


func _add_prop(props: Array, placed: Array, kind: String, pos: Vector2, r: float, rng: RandomNumberGenerator) -> bool:
	# Radio visual (copa del arbol / roca): evita que los dibujos se solapen aunque las colisiones sean mas pequenas
	var vis: float = {"tree": 28.0, "rock": 24.0}.get(kind, r)
	for pl in placed:
		if pos.distance_to(pl[0]) < float(pl[1]) + vis + 6.0:
			return false
		if pl.size() > 2 and _hidden_by_tree(pos, kind, r, pl[0], String(pl[2]), float(pl[1])):
			return false
	if (kind == "tree" or kind == "rock") and _grass_near(pos, 30.0):
		return false
	if (kind == "chest" or kind == "spring" or kind == "altar" or kind == "trap") and _grass_near(pos, r + 34.0):
		return false
	var p := Prop.new()
	p.kind = kind
	p.r = r
	p.solid = kind == "tree" or kind == "rock"
	p.v = rng.randf()
	p.position = pos
	if kind == "spring" or kind == "trap":
		p.z_index = -1   # al ras del suelo: todo lo demas se dibuja por encima
	if kind == "chest":
		var cr: float = rng.randf()
		if cr < 0.2:
			p.sub = "big"
			p.r = 22.0
		elif cr < 0.32:
			p.sub = "paid"
		elif cr < 0.42:
			p.sub = "trap" if rng.randf() < 0.5 else "trapv"   # trap = disfrazado, trapv = sospechoso
	if kind == "trap":
		p.sub = ["poison", "ice", "fire", "freeze", "shock", "sleep", "confuse"][rng.randi() % 7]
	if kind == "altar":
		var pw: Dictionary = POWERS[rng.randi() % POWERS.size()]
		p.power = String(pw["id"])
		p.color = Color.html(String(pw["color"]))
		if _alt_legend:
			p.sub = "legend"   # S53: altar legendario
			p.color = Color("#ffd23f")
	world.add_child(p)
	props.append(p)
	placed.append([pos, maxf(p.r, vis), kind])
	return true


func _free_chunk(key: Vector2i) -> void:
	var ch: Dictionary = chunks[key]
	for p in ch["props"]:
		if is_instance_valid(p):
			p.queue_free()
	chunks.erase(key)


func _update_biome() -> void:
	var b: int = int(run_time / (150.0 if mode == "rush" else 240.0)) + biome_off
	if mode == "tower":
		b = tw_floor - 1
	if mode == "normal":
		b = biome_off + (1 if dir_map else 0)   # S63: una sola transicion (04:00, tras el jefe)
	if b == biome_idx:
		return
	biome_idx = b
	ground.set_biome(b)
	Aud.sfx("biome")
	_say("— " + L.t(ground.biome_name(ground.biome)) + " —", 3.0)
	_ring(player.position, 10.0, 520.0, Color.WHITE, 0.7)
	player_lava_t = 1.5
	for key in chunks:
		for p in chunks[key]["props"]:
			if is_instance_valid(p):
				p.queue_redraw()


func _cut_grass(pos: Vector2, r: float) -> void:
	var cut: Array = ground.cut_grass(pos, r)
	if cut.is_empty():
		return
	Aud.sfx("grass")
	var pal: Dictionary = ground.pal(ground.biome)
	var gcol: Color = (pal["grass"] as Array)[1]
	for i in range(mini(cut.size(), [6, 2, 0][perf_lv])):
		var f := Fx.new()
		f.kind = "burst"
		f.color = gcol
		f.position = cut[i] + Vector2(0.0, -6.0)
		f.r1 = 16.0
		f.life = 0.25
		fx.add_child(f)
	for gp in cut:
		var rr: float = randf()
		# ~2 matas por casilla (el original: 1): la mitad de probabilidad por mata para soltar lo mismo
		if rr < 0.03:
			_spawn_orb(gp, "heal", 0.0)
		elif rr < 0.07:
			_spawn_orb(gp, "coin", 1.0)
		elif rr < 0.0715:
			try_ball(gp, 1.0)


func _update_world(delta: float) -> void:
	power_t = maxf(0.0, power_t - delta)
	if power_t <= 0.0:
		power_kind = ""
	var c: Vector2i = _chunk_of(player.position)
	ground.center = player.position
	if c != player_chunk:
		player_chunk = c
		ground.set_center(c)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var key := Vector2i(c.x + dx, c.y + dy)
				if not chunks.has(key) and not gen_q.has(key):
					gen_q.append(key)
		gen_q.sort_custom(func(a, b): return absi(a.x - c.x) + absi(a.y - c.y) < absi(b.x - c.x) + absi(b.y - c.y))
		for key in chunks.keys():
			if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
				_free_chunk(key)
	# Los trozos nuevos se crean de uno en uno (sin tirones); al empezar, todos de golpe.
	var made := 0
	while not gen_q.is_empty():
		var nk: Vector2i = gen_q[0]
		if chunks.has(nk):
			gen_q.pop_front()
			continue
		# El terreno (lagos, paredes, orillas) es lo caro: se calcula por tandas de ~2 ms, de fotograma en fotograma
		if delta > 0.0 and not _warm_terrain(nk):
			break
		gen_q.pop_front()
		chunks[nk] = _gen_chunk(nk.x, nk.y)
		made += 1
		# Al empezar solo los 9 de alrededor (lo que se ve); el resto llega de uno en uno en los siguientes fotogramas
		if delta > 0.0 or made >= 9:
			break
	_update_props(delta)


var warm_key := Vector2i(99999, 99999)
var warm_i := 0


# Calcula (y deja en cache) el terreno de un trozo y su margen, con un presupuesto de tiempo por fotograma.
# Devuelve true cuando ya esta todo listo.
func _warm_terrain(k: Vector2i) -> bool:
	if warm_key != k:
		warm_key = k
		warm_i = 0
	var side: int = 24
	var total: int = side * side
	var t0: int = Time.get_ticks_usec()
	var bx: int = k.x * 16 - 4
	var by: int = k.y * 16 - 4
	while warm_i < total:
		ground.terrain(bx + warm_i % side, by + warm_i / side)
		warm_i += 1
		if (warm_i & 7) == 0 and Time.get_ticks_usec() - t0 > 2200:
			break
	return warm_i >= total


func _props_near(pos: Vector2) -> Array:
	var out: Array = []
	var c: Vector2i = _chunk_of(pos)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ch = chunks.get(Vector2i(c.x + dx, c.y + dy))
			if ch != null:
				out.append_array(ch["props"])
	return out


# Los enemigos que no vuelan no pisan las fuentes de curacion (solo las usas tu)
func _spring_push(pos: Vector2) -> Vector2:
	for p in _props_near(pos):
		if not is_instance_valid(p) or p.kind != "spring" or p.used:
			continue
		var d: Vector2 = pos - p.position
		var q := Vector2(d.x / 30.0, d.y / 19.0)
		var l: float = q.length()
		if l < 1.0:
			if l < 0.001:
				q = Vector2(1.0, 0.0)
				l = 1.0
			q /= l
			pos = p.position + Vector2(q.x * 30.0, q.y * 19.0)
	return pos


# Altar legendario solido: un anillo de piedra con un hueco al frente (las escaleras). Solo se llega al circulo subiendo por ellas.
func _legend_walls(p: Prop, pos: Vector2, rad: float) -> Vector2:
	var l: Vector2 = pos - p.position
	if absf(l.x) > 150.0 or l.y < -150.0 or l.y > 170.0:
		return pos
	for i in range(26):
		var an: float = TAU * float(i) / 26.0
		var sn: float = sin(an)
		var cs: float = cos(an)
		if sn > 0.0 and absf(cs) < 0.45:
			continue   # hueco de las escaleras (abajo)
		var wp := Vector2(cs * 94.0, sn * 62.0 - 4.0)
		var d: Vector2 = l - wp
		var md: float = 18.0 + rad
		var dd: float = d.length_squared()
		if dd < md * md:
			if dd < 0.0001:
				d = Vector2(0.0, 1.0)
			l = wp + d.normalized() * md
	return p.position + l


func _collide(pos: Vector2, rad: float) -> Vector2:
	if arena != null:
		return arena.collide(pos, rad)
	pos = ground.collide(pos, rad)
	if mew != null:
		pos = mew.collide(pos, rad)
	var c: Vector2i = _chunk_of(pos)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ch = chunks.get(Vector2i(c.x + dx, c.y + dy))
			if ch == null:
				continue
			for p in ch["props"]:
				if p.kind == "altar" and p.sub == "legend":
					pos = _legend_walls(p, pos, rad)
					continue
				if not p.solid:
					continue
				var d: Vector2 = pos - p.position
				var md: float = p.r + rad
				var dd: float = d.length_squared()
				if dd < md * md:
					if dd < 0.0001:
						d = Vector2(1.0, 0.0)
						dd = 1.0
					pos = p.position + d.normalized() * md
	return pos


# Las paredes (tierra/roca del mapa y de las arenas) detienen los proyectiles.
func _wall_hit(a: Vector2, b: Vector2) -> bool:
	for t in [0.0, 0.5, 1.0]:
		var p: Vector2 = a.lerp(b, t)
		var q: Vector2 = arena.collide(p, 2.0) if arena != null else ground.collide(p, 2.0)
		if q.distance_squared_to(p) > 0.01:
			return true
	return false


func _liquid_at(pos: Vector2) -> String:
	if arena != null:
		return arena.liquid_at(pos)
	return ground.liquid_at(pos)


func _blocked(pos: Vector2, rad: float) -> bool:
	if _collide(pos, rad) != pos:
		return true
	return _liquid_at(pos) == "lava"


func _free_spot(pos: Vector2, rad: float) -> Vector2:
	if not _blocked(pos, rad):
		return pos
	for i in range(10):
		var q: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 170.0)
		if not _blocked(q, rad):
			return q
	return pos


const TERRAIN_HOME := {"water": ["water"], "lava": ["fire"], "swamp": ["poison", "water"], "ice": ["ice"], "poison": ["poison"], "spark": ["electric"]}
var _terr_bonus_on := false


# Seccion 40: +12% de velocidad solo mientras pisas un entorno de tu tipo (se quita al salir, sin acumularse).
func _player_terrain(delta: float) -> float:
	var base: float = _player_terrain_base(delta)
	var liq: String = _liquid_at(player.position)
	var home: bool = TERRAIN_HOME.has(liq) and _has_t(player.types, TERRAIN_HOME[liq])
	if home and not _terr_bonus_on:
		add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("+Velocidad"), Color("#8fe0ff"), 16)
	_terr_bonus_on = home
	return base * (1.12 if home else 1.0)


func _player_terrain_base(delta: float) -> float:
	var liq: String = _liquid_at(player.position)
	if liq == "water":
		if _has_t(player.types, ["water", "flying"]):
			return 1.0
		return 0.72
	if liq == "lava":
		if _has_t(player.types, ["fire", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.5
			player.invuln = 0.0
			_hurt_player(maxf(3.0, player.max_hp * 0.035), "")
		return 0.85
	if liq == "swamp":
		return 1.0 if _has_t(player.types, ["poison", "water", "flying"]) else 0.7
	if liq == "ice":
		return 1.0 if _has_t(player.types, ["ice", "flying"]) else 0.85
	if liq == "poison":
		if _has_t(player.types, ["poison", "steel", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.6
			player.invuln = 0.0
			_hurt_player(maxf(2.0, player.max_hp * 0.025), "")
		return 0.8
	if liq == "spark":
		if _has_t(player.types, ["electric", "ground", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.8
			player.invuln = 0.0
			_hurt_player(maxf(3.0, player.max_hp * 0.03), "")
		return 0.9
	return 1.0


func _enemy_terrain(e: Enemy, delta: float) -> float:
	if e.legend:
		return 1.0
	if _liquid_at(e.position) == "swamp":
		return 1.0 if _has_t(e.types, ["poison", "water"]) else 0.55
	var liq: String = _liquid_at(e.position)
	if liq == "water":
		if _has_t(e.types, ["water", "flying"]):
			return 1.0
		return 0.55
	if liq == "lava":
		if _has_t(e.types, ["fire"]):
			return 1.0
		e.lava_t -= delta
		if e.lava_t <= 0.0:
			e.lava_t = 0.6
			_damage_enemy(e, 6.0 + e.max_hp * 0.04, Color("#ff7b3d"))
		return 0.8
	return 1.0


func _pw(id: String) -> bool:
	return power_kind == id


func _power_text() -> String:
	if power_kind == "":
		return ""
	for p in POWERS:
		if String(p["id"]) == power_kind:
			return "%s %ds" % [L.t(String(p["name"])), ceili(power_t)]
	return ""


func _update_props(delta: float) -> void:
	var pp: Vector2 = player.position
	for p in _props_near(pp):
		if not is_instance_valid(p):
			continue
		var d: float = p.position.distance_to(pp)
		if p.kind == "chest" and not p.used:
			if p.sub == "paid":
				pass   # lo gestiona el director de POI (precio + boton de interaccion)
			elif p.sub == "trap" or p.sub == "trapv":
				if d < p.r + player.radius + 14.0:
					poi.trigger_trap_chest(p)
			elif p.sub == "big":
				# Cofre grande: hay que quedarse pegado a el unos segundos
				if d < p.r + player.radius + 22.0:
					p.charge += delta
					if p.charge >= CHEST_HOLD:
						p.used = true
						_open_chest(p)
				else:
					p.charge = maxf(0.0, p.charge - delta * 1.5)
			elif d < p.r + player.radius + 14.0:
				p.used = true
				_open_chest(p)
		elif p.kind == "spring" and not p.used and d < 52.0:
			var amt: float = minf(player.max_hp * 0.07 * delta, p.charge)
			if player.hp < player.max_hp and amt > 0.0:
				player.hp = minf(player.max_hp, player.hp + amt)
				p.charge -= amt
				p.queue_redraw()
				if p.charge <= 0.0:
					p.used = true
					# La fuente se seca y desaparece
					var st: Tween = p.create_tween()
					st.tween_interval(0.6)
					st.tween_property(p, "modulate:a", 0.0, 1.2)
					st.tween_callback(p.queue_free)
					_forget_prop(p)
		elif p.kind == "altar" and p.sub == "legend" and not p.used:
			# S53: te paras en el centro y la barra "Invocando" se llena. Salirte la pausa (con un desgaste minimo).
			if is_instance_valid(legend):
				if d < 60.0 and run_time - legend_msg_t > 3.0:
					legend_msg_t = run_time
					_say(L.t("Ya tienes un legendario a tu lado"), 2.0)
			else:
				if d < LEG_ZONE and not player.dead:
					p.charge += delta
					if p.charge >= LEG_TIME:
						p.used = true
						_summon_legend(p)
				else:
					p.charge = maxf(0.0, p.charge - delta * 0.12)
				if p.charge != p.lastc:
					p.lastc = p.charge
		elif p.kind == "altar" and not p.used and p.sub != "legend" and d < 50.0:
			p.used = true
			_use_altar(p)
		elif p.kind == "trap":
			p.cd = maxf(0.0, p.cd - delta)
			# Como en el original, la trampa salta tambien si la pisa un enemigo que no vuele
			var stepped: bool = d < 38.0
			if not stepped and p.cd <= 0.0 and d < 400.0:
				for te in enemies:
					if not te.dead and not te.flying and te.position.distance_to(p.position) < te.radius + 14.0:
						stepped = true
						break
			if p.cd <= 0.0 and stepped:
				p.cd = 999.0
				_trigger_trap(p)
				var tt: Tween = p.create_tween()
				tt.tween_property(p, "modulate:a", 0.0, 0.35)
				tt.tween_callback(p.queue_free)
				_forget_prop(p)


const TRAP_R := 112.0


func _trap_fx(sub: String, pos: Vector2, col: Color) -> void:
	# Cada trampa estalla con su propia animacion
	shake = maxf(shake, 2.0)
	match sub:
		"poison":
			_ring(pos, 6.0, TRAP_R, col, 0.55)
			for i in range(14):
				var q: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(10.0, TRAP_R * 0.8)
				pfx.burst(q, Color("#d47cf0"), 3, 60.0)
			_ring(pos, 4.0, TRAP_R * 0.5, Color("#6b2c8f"), 0.8, 3.0)
		"ice":
			_ring(pos, 6.0, TRAP_R, col, 0.7, 6.0)
			pfx.burst(pos, Color("#b8f06a"), 26, 130.0)
		"freeze":
			for i in range(8):
				var d: Vector2 = Vector2.from_angle(float(i) * TAU / 8.0)
				pfx.burst(pos + d * TRAP_R * 0.55, Color("#d8f6ff"), 6, 90.0)
			_ring(pos, 6.0, TRAP_R, col, 0.45)
			_ring(pos, 6.0, TRAP_R * 0.6, Color.WHITE, 0.3, 2.0)
		"shock":
			for i in range(6):
				var d2: Vector2 = Vector2.from_angle(randf() * TAU)
				for k in range(5):
					pfx.burst(pos + d2 * (14.0 + k * 18.0) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), Color("#ffe14d"), 3, 70.0)
			_ring(pos, 6.0, TRAP_R, col, 0.25, 3.0)
			shake = maxf(shake, 4.0)
		"sleep":
			_ring(pos, 6.0, TRAP_R, col, 1.0, 3.0)
			for i in range(4):
				add_text(pos + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 10.0)), "Z", Color("#cfd8ff"), 22 + i * 3)
		"confuse":
			for i in range(3):
				_ring(pos, 6.0 + i * 10.0, TRAP_R * (0.5 + 0.25 * i), col, 0.5 + 0.2 * i, 3.0)
			for i in range(10):
				var an: float = float(i) * 0.7
				pfx.burst(pos + Vector2.from_angle(an) * (8.0 + i * 9.0), Color("#ff7ad9"), 3, 50.0)
		_:
			_ring(pos, 6.0, TRAP_R, col, 0.4, 7.0)
			_ring(pos, 6.0, TRAP_R * 0.6, Color("#ffe27a"), 0.3, 4.0)
			pfx.burst(pos, Color("#ff7b3d"), 36, 240.0)
			shake = maxf(shake, 5.0)


func _trigger_trap(p: Prop) -> void:
	# Igual que interact.js: 3 tipos (veneno / pegajosa / fuego), radio 74.
	var pos: Vector2 = p.position
	var lvl: int = player.level
	var col: Color = Color("#c86bdc")
	if p.sub == "ice":
		col = Color("#8bd94a")
	elif p.sub == "fire":
		col = Color("#ff7b3d")
	elif p.sub == "freeze":
		col = Color("#8fe3ff")
	elif p.sub == "shock":
		col = Color("#ffe14d")
	elif p.sub == "sleep":
		col = Color("#b9b6ff")
	elif p.sub == "confuse":
		col = Color("#ff7ad9")
	_trap_fx(p.sub, pos, col)
	for e in enemies:
		if e.dead or e.position.distance_to(pos) > TRAP_R:
			continue
		if p.sub == "poison":
			e.apply_poison(5)
			_damage_enemy(e, 14.0 + lvl * 3.0, Color("#d47cf0"))
		elif p.sub == "ice":
			e.apply_slow(0.65, 4.5)
			_damage_enemy(e, 4.0, Color("#8bd94a"))
		elif p.sub == "freeze":
			_damage_enemy(e, 8.0 + lvl * 2.0, col)
			_apply_cc(e, "freeze", 1.3)
		elif p.sub == "shock":
			_damage_enemy(e, 8.0 + lvl * 2.0, col)
			_apply_cc(e, "para", 1.5)
		elif p.sub == "sleep":
			_apply_cc(e, "sleep", 1.4)
		elif p.sub == "confuse":
			_apply_cc(e, "conf", 1.5)
		else:
			_damage_enemy(e, 90.0 + lvl * 18.0, col, (e.position - pos).normalized(), 220.0)
	if not player.dead and player.position.distance_to(pos) < TRAP_R * 0.7 and not _has_item("heavyboots") and _abn("trapimm") == 0.0:
		player.invuln = 0.0
		if p.sub == "poison":
			_hurt_player(player.max_hp * 0.1, "poison")
		elif p.sub == "ice":
			trap_slow_t = 3.5
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Pegajoso!"), Color("#8bd94a"), 20)
		elif p.sub == "freeze":
			trap_freeze_t = 1.0
			_hurt_player(player.max_hp * 0.05, "ice")
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Congelado!"), col, 20)
		elif p.sub == "shock":
			trap_para_t = 2.5
			_hurt_player(player.max_hp * 0.06, "electric")
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Paralizado!"), col, 20)
		elif p.sub == "sleep":
			trap_sleep_t = 3.0
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Somnoliento!"), col, 20)
		elif p.sub == "confuse":
			trap_conf_t = 2.5
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Confundido!"), col, 20)
		else:
			_hurt_player(player.max_hp * 0.2, "fire")


func _forget_prop(p: Prop) -> void:
	for key in chunks:
		(chunks[key]["props"] as Array).erase(p)


const CHEST_HOLD := 3.5


func _open_chest(p: Prop) -> void:
	run_chests += 1
	PG.event("chest")
	Aud.sfx("chest")
	p.queue_redraw()
	var pos: Vector2 = p.position
	var big: bool = p.sub == "big"
	# Como el original: el cofre estalla en particulas doradas, onda y sacudida
	pfx.burst(pos + Vector2(0.0, -14.0), Color("#f2c443"), 34 if big else 22, 220.0 if big else 180.0)
	_ring(pos, 6.0, 80.0 if big else 46.0, Color("#f2c443"), 0.6 if big else 0.45, 5.0 if big else 4.0)
	shake = maxf(shake, 4.0 if big else 2.5)
	if big:
		# Botin grande: monedas, tickets, objeto y experiencia para subir un nivel
		for i in range(9):
			_spawn_orb(pos + Vector2(randf_range(-22.0, 22.0), randf_range(-14.0, 14.0)), "coin", 4.0)
		for i in range(1 + (1 if randf() < 0.35 else 0)):
			_spawn_orb(pos + Vector2(randf_range(-16.0, 16.0), randf_range(-10.0, 10.0)), "ticket", 1.0)
		if randf() < 0.08:
			_spawn_orb(pos + Vector2(0.0, -10.0), "ticket10", 1.0)
		if randf() < 0.5:
			_spawn_orb(pos + Vector2(14.0, -14.0), "item", 0.0)
		_spawn_orb(pos, "xpBig", float(_xp_for(player.level)))
		add_text(pos + Vector2(0.0, -40.0), L.t("¡Cofre de experiencia!"), Color("#ffd23f"), 24)
	else:
		_chest_roll(pos, Vector2.ZERO)
	p.queue_free()
	_forget_prop(p)


# Mejora gratis (cofres de compra): sube un nivel y abre la eleccion de carta.
func free_upgrade() -> void:
	player.xp = player.xp_next
	_gain_xp(0.0)


# Las Poké Balls son escasas: como mucho una cada 90 s de partida y nunca si ya llevas 3 o hay una en el suelo.
var ball_last := -999.0
func try_ball(pos: Vector2, chance: float, force: bool = false) -> bool:
	if not force:
		if balls >= 3 or run_time - ball_last < 90.0 or randf() > chance:
			return false
		for o in orbs:
			if is_instance_valid(o) and o.kind == "ball":
				return false
	ball_last = run_time
	_spawn_orb(pos, "ball", 1.0)
	return true


func _chest_roll(pos: Vector2, off: Vector2) -> void:
	pos += off
	try_ball(pos + Vector2(14.0, 0.0), 0.12)
	# v5.8: los objetos ciclan: si llevas ITEM_EVERY cofres sin ninguno, este lo da seguro
	chests_no_item += 1
	if chests_no_item >= ITEM_EVERY:
		chests_no_item = 0
		_spawn_orb(pos, "item", 0.0)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Un objeto!"), Color("#ff8ad8"), 22)
		return
	var r: float = kec.chest_roll_adjust(randf())
	if r < 0.40:
		for i in range(10):
			_spawn_orb(pos, "coin", 5.0)
		if randf() < 0.07:
			_spawn_orb(pos, "ticket", float(1 + randi() % 2))
			if randf() < 0.08:
				_spawn_orb(pos, "ticket10", 1.0)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Monedas!"), Color("#ffd23f"), 22)
	elif r < 0.72:
		_spawn_orb(pos, "heal", 0.0)
		var per: float = ceilf(float(_xp_for(player.level)) * 0.12 / 5.0)
		for i in range(5):
			_spawn_orb(pos, "xpBig", per)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Cofre de experiencia!"), Color("#7fe0ff"), 22)
	elif item == "" or r < 0.88:
		chests_no_item = 0
		_spawn_orb(pos, "item", 0.0)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Un objeto!"), Color("#ff8ad8"), 22)
	else:
		_spawn_orb(pos, "magnet", 0.0)
		_spawn_orb(pos, "bomb", 0.0)


# ---------------------------------------------------------------
# S53: altar legendario -> aliado que ataca solo, con vida visible y sin curacion
# ---------------------------------------------------------------
const LEG_TIME := 4.0
const LEG_ZONE := 46.0
var legend = null
var allies_extra: Array = []   # v5.3: segundo aliado capturado
var _alt_legend := false
var legend_msg_t := -99.0


func _lg_pool() -> Array:
	var out: Array = []
	for p in _dex_list:
		if bool(p.get("leg", false)) and _smeta.has(str(int(p["dex"]))):
			out.append(p)
	return out


func _summon_legend(p: Prop) -> void:
	if is_instance_valid(legend):
		return
	var pool: Array = _lg_pool()
	if pool.is_empty():
		return
	var pd: Dictionary = pool[randi() % pool.size()]
	var dx: int = int(pd["dex"])
	var lg := Legend.new()
	lg.setup(dx, _sm(dx), flash_shader, 1.0, false)
	lg.m = self
	var ty: Array = pd["types"]
	lg.ltype = String(ty[0]) if not ty.is_empty() else "normal"
	lg.col = Color.html(String(MD.TYPE_COLOR.get(lg.ltype, "#ffd23f")))
	lg.lname = L.t(String(pd["name"]))
	var tm: float = run_time / 60.0
	lg.max_hp = roundf(500.0 + float(player.level) * 70.0 + tm * 45.0)
	lg.hp = lg.max_hp
	lg.dmg = 26.0 + float(player.level) * 4.5 + tm * 2.0
	lg.position = p.position + Vector2(0.0, 10.0)
	lg.z_index = 1
	world.add_child(lg)
	legend = lg
	lg.modulate.a = 0.0
	var tw: Tween = lg.create_tween()
	tw.tween_property(lg, "modulate:a", 1.0, 0.8)
	# animacion de invocacion: columna de luz, tres anillos y una lluvia de particulas
	for i in range(3):
		_ring(p.position, 8.0, 90.0 + 50.0 * i, lg.col, 0.7 + 0.2 * i, 5.0 - i)
	pfx.burst(p.position + Vector2(0.0, -30.0), lg.col, 40, 260.0)
	pfx.burst(p.position + Vector2(0.0, -30.0), Color("#ffd23f"), 24, 160.0)
	shake = maxf(shake, 6.0)
	Aud.sfx("legend")
	_say(L.t("¡%s responde al llamado!") % lg.lname, 3.0)
	p.queue_redraw()


func _upd_legend(delta: float) -> void:
	for lx in allies_extra.duplicate():
		if not is_instance_valid(lx) or lx.dead:
			allies_extra.erase(lx)
		else:
			_upd_ally(lx, delta)
	if not is_instance_valid(legend):
		legend = null
		return
	_upd_ally(legend, delta)


func _upd_ally(lg, delta: float) -> void:
	if lg.dead:
		return
	lg.atk_t -= delta
	lg.hit_t -= delta
	# los enemigos que lo tocan le hacen dano (nunca se cura)
	if lg.hit_t <= 0.0:
		var taken := 0.0
		for e in enemies:
			if e.dead:
				continue
			if e.position.distance_to(lg.position) < e.radius + lg.radius + 6.0:
				taken += e.dmg * 0.55
		if taken > 0.0:
			lg.hit_t = 0.6
			lg.hurt(taken)
	if lg.dead:
		_legend_die(lg)
		return
	var tg: Node2D = _nearest_enemy(lg.position, 380.0)
	var want: Vector2 = player.position + Vector2(-70.0, 30.0)
	var spd := 150.0
	if tg != null and lg.position.distance_to(tg.position) > 170.0 and lg.position.distance_to(player.position) < 420.0:
		want = tg.position
		spd = 190.0
	var to: Vector2 = want - lg.position
	# histeresis: evita que el sprite alterne Walk/Idle (parpadeo) cuando esta justo en el limite
	var dist_w: float = to.length()
	if lg.moving and dist_w < 28.0:
		lg.moving = false
	elif not lg.moving and dist_w > 52.0:
		lg.moving = true
	var moving: bool = lg.moving
	if moving:
		lg.position += to.normalized() * spd * delta
		lg.face_angle(to.angle())
	elif tg != null:
		lg.face_angle((tg.position - lg.position).angle())
	lg.loop_anim("Walk" if moving and lg.has_anim("Walk") else "Idle", 1.0)
	if tg != null and lg.atk_t <= 0.0 and lg.position.distance_to(tg.position) < 240.0:
		if lg.alpha:
			lg.atk_t = 1.7
			_ally_boss_attack(lg, tg)
		else:
			lg.atk_t = 1.25
			if lg.has_anim("Attack"):
				lg.play_attack("Attack", 1.25)
			_legend_strike(lg, tg)


func _legend_strike(lg, tg) -> void:
	# Ataque propio: un rayo cae del cielo sobre el objetivo y estalla en area; cada 3er golpe es una onda mayor
	lg.n_hits += 1
	var big: bool = lg.n_hits % 3 == 0
	var rad: float = 120.0 if big else 78.0
	var pos: Vector2 = tg.position
	lg.fx_line(pos)
	_ring(pos, 6.0, rad, lg.col, 0.4, 5.0 if big else 3.0)
	pfx.burst(pos, lg.col, 22 if big else 12, 200.0)
	pfx.burst(pos, Color.WHITE, 6, 120.0)
	if big:
		shake = maxf(shake, 3.0)
		_ring(lg.position, 6.0, 90.0, lg.col, 0.5, 3.0)
	for e in enemies:
		if e.dead or e.position.distance_to(pos) > rad:
			continue
		_damage_enemy(e, lg.dmg * (2.2 if big else 1.0), lg.col, (e.position - pos).normalized(), 160.0 if big else 90.0)


func _legend_die(lg) -> void:
	_ring(lg.position, 8.0, 110.0, lg.col, 0.6, 4.0)
	pfx.burst(lg.position + Vector2(0.0, -20.0), lg.col, 30, 220.0)
	add_text(lg.position + Vector2(0.0, -50.0), L.t("%s se retira") % lg.lname, Color("#ffd23f"), 20)
	if lg == legend:
		legend = null
	else:
		allies_extra.erase(lg)
	lg.dead = true
	lg.fade = 0.6


func _use_altar(p: Prop) -> void:
	for pw in POWERS:
		if String(pw["id"]) == p.power:
			power_kind = p.power
			power_t = 25.0
			_say(L.t("Altar: %s. %s (25 s)") % [L.t(String(pw["name"])), L.t(String(pw["desc"]))], 3.0)
			Aud.sfx("legend")
	_ring(p.position, 6.0, 90.0, p.color, 0.6)
	p.queue_redraw()


func _cleanup_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].dead:
			enemies.remove_at(i)


# ---------------------------------------------------------------
# Proyectiles y orbes giratorios
# ---------------------------------------------------------------
func _bullet_hit(b, e) -> void:
	var dir: Vector2 = b.vel
	if dir == Vector2.ZERO or b.orb:
		dir = e.position - player.position   # los orbes empujan hacia fuera, lejos de ti
	dmg_src = b.src
	_hit_enemy(e, b.dmg, b.color, dir, b.knock, b.mtype, b.burn, b.poison, b.slow, b.cc, b.ccp)
	if MD.MOVES.has(b.src) and MD.MOVES[b.src].has("coin") and randf() < 0.5:
		coins += 1   # Día de Pago: solo moneda normal
		Aud.sfx("coin")
	dmg_src = ""


func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		b.age += delta
		if arena == null:
			_cut_grass(b.position, 20.0)
			if sec != null:
				sec.hit(b.position, b.r + 6.0, String(b.mtype))
		if b.orb:
			b.oa += b.ospeed * delta
			b.position = player.position + Vector2(cos(b.oa) * b.orad, sin(b.oa) * b.orad * 0.7)
			for e in enemies:
				if e.dead:
					continue
				var rr: float = e.radius + b.r
				if e.position.distance_squared_to(b.position) > rr * rr:
					continue
				var key: int = e.get_instance_id()
				var last: float = float(b.hit_log.get(key, -99.0))
				if run_time - last < b.rehit:
					continue
				b.hit_log[key] = run_time
				_bullet_hit(b, e)
			if b.hit_log.size() > 300:
				b.hit_log.clear()
			continue
		var remove: bool = b.age >= b.life
		if not remove and b.boom > 0.0:
			if not b.back and b.age >= b.boom:
				b.back = true
				b.hits.clear()
			if b.back:
				var to: Vector2 = player.position - b.position
				var dd: float = to.length()
				b.vel = b.vel.lerp(to / maxf(dd, 0.001) * b.bsp, 1.0 - exp(-7.0 * delta))
				if dd < player.radius + 8.0:
					remove = true
		if not remove and b.homing > 0.0:
			var tg: Node2D = _nearest_enemy(b.position, 340.0)
			if tg != null:
				var sp: float = b.vel.length()
				var want: Vector2 = (tg.position + Vector2(0.0, -tg.body_h * 0.5) - b.position).normalized() * sp
				b.vel = b.vel.lerp(want, 1.0 - exp(-b.homing * delta))
		if b.turn != 0.0:
			b.vel = b.vel.rotated(b.turn * delta)
		if b.leave != "":
			b.leave_t -= delta
			if b.leave_t <= 0.0:
				b.leave_t = 0.13
				_p_zone(b.position, 24.0, 1.8, 0.4, b.bm, 0.3)
		if b.trail != "" and perf_lv == 0:
			b.trail_t -= delta
			if b.trail_t <= 0.0:
				b.trail_t = 0.14
				pfx.trail(b.trail, b.pal, b.position + Vector2(0.0, -18.0), b.vel)
		if not remove:
			b.ppos = b.position
			b.position += b.vel * delta
			if b.position.distance_squared_to(player.position) > 2000.0 * 2000.0:
				remove = true
			elif _wall_hit(b.ppos, b.position):
				if b.boom > 0.0 and not b.back:
					b.back = true
					b.hits.clear()
					b.position = b.ppos
				else:
					remove = true
		if not remove:
			for e in enemies:
				if e.dead or b.hits.has(e):
					continue
				var rr2: float = e.radius + b.r
				var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, b.ppos, b.position)
				if cp.distance_squared_to(e.position) > rr2 * rr2:
					continue
				b.hits.append(e)
				_bullet_hit(b, e)
				if b.ric > 0:
					b.ric -= 1
					var nx: Node2D = null
					var bd: float = 280.0 * 280.0
					for e2 in enemies:
						if e2.dead or b.hits.has(e2):
							continue
						var d2: float = b.position.distance_squared_to(e2.position)
						if d2 < bd:
							bd = d2
							nx = e2
					if nx != null:
						b.vel = (nx.position - b.position).normalized() * b.vel.length()
					else:
						remove = true
					break
				if b.pierce > 0:
					b.pierce -= 1
				else:
					remove = true
					break
		if remove:
			if b.burst > 0:
				_p_radial(b.bm, b.position, b.burst, 250.0, 0.5, 0.5)
			b.queue_free()
			bullets.remove_at(i)


# ---------------------------------------------------------------
# Experiencia, orbes y cartas de nivel
# ---------------------------------------------------------------
func _xp_for(level: int) -> int:
	var l: float = float(level)
	# v5.3: los primeros niveles piden menos experiencia (-15% al inicio, normal desde el nivel 20)
	var early: float = lerpf(0.85, 1.0, clampf((l - 1.0) / 19.0, 0.0, 1.0))
	return int(floor((8.0 + l * 6.0 + pow(l, 1.75) * 1.6) * 4.0 * early))


func _gain_xp(amount: float) -> void:
	player.xp += amount * _xp_mul() * XP_GAIN * (TOWER_XP_K if mode == "tower" else 1.0)
	if is_nan(player.xp) or is_inf(player.xp):
		player.xp = 0.0
	var guard := 0
	while player.xp >= player.xp_next and guard < 200:   # tope de seguridad: nunca un bucle infinito (congelamiento)
		guard += 1
		player.xp -= player.xp_next
		player.level += 1
		player.xp_next = maxf(1.0, _xp_need(player.level))
		pending_levels += 1


func _spawn_orb(pos: Vector2, kind: String, value: float):
	var o := Orb.new()
	o.kind = kind
	o.value = value
	o.position = pos
	o.vel = Vector2.from_angle(randf() * TAU) * randf_range(10.0, 46.0)
	fx.add_child(o)
	orbs.append(o)
	if orbs.size() > ORB_CAP:
		# Demasiados: el orbe de XP mas viejo se cobra al instante.
		for i in range(orbs.size()):
			var old = orbs[i]
			if old.kind == "xp" or old.kind == "xpBig":
				_gain_xp(old.value)
				old.queue_free()
				orbs.remove_at(i)
				break
	return o


func _drop(e) -> void:
	if e.has_meta("jd_arceus"):
		jd.arceus_down(e)
		return
	if e.has_meta("enc") and String(e.get_meta("enc")) == "eternatus":
		call_deferred("_eternatus_win")
	if e.has_meta("enc") and String(e.get_meta("enc")) == "alpha":
		alpha.on_down(e)
	elif e.has_meta("enc") and (String(e.get_meta("enc")) == "open_boss" or String(e.get_meta("enc")) == "mini"):
		alpha.on_big_down(e, String(e.get_meta("enc")))
	if e.has_meta("enc") and String(e.get_meta("enc")) == "wildleg" and not e.has_meta("wl_paid"):
		e.set_meta("wl_paid", true)
		for k in range(2):
			_spawn_orb(e.position, "ticket", 1.0)
		for k in range(20):
			_spawn_orb(e.position, "coin", 10.0)
		_spawn_orb(e.position + Vector2(20.0, 0.0), "item", 0.0)
		_say(L.t("¡Legendario derrotado! Premio especial."), 2.6)
	if e.has_meta("enc") and String(e.get_meta("enc")) == "deoxys":
		meteor.on_deoxys_down(e)
	if e.has_meta("enc") and String(e.get_meta("enc")) == "mewtwo":
		mew.on_down(e)
	if e.legend:
		_legend_down(e)
		return
	kec.on_kill(e)
	if e.boss and not e.judge:
		run_bosses += 1
	if e.judge:
		jd.boss_down()
		progress_event("judgeKill")
	if e.behavior == "thief":
		if String(e.def.get("loot", "coins")) == "gimmi":
			if not e.has_meta("paid"):
				e.set_meta("paid", true)   # una sola tirada por encuentro
				# Poltchageist: solo Gachapon Coins; muy rara vez (3%) la dorada
				if randf() < 0.03:
					_spawn_orb(e.position + Vector2(0.0, -14.0), "gcoin_gold", 1.0)
				else:
					_spawn_orb(e.position + Vector2(0.0, -14.0), "gcoin", 1.0)
		elif String(e.def.get("loot", "coins")) == "ticket10":
			# Gholdengo: solo tickets (nada de monedas)
			_spawn_orb(e.position, "ticket10", 1.0)
			_spawn_orb(e.position + Vector2(12.0, 0.0), "ticket", 1.0)
		else:
			for k in range(20):
				_spawn_orb(e.position, "coin", 5.0)
		_say(L.t("¡Botín recuperado!"), 1.6)
		return
	if e.boss:
		var n: int = 14
		var per: float = ceilf(e.xp_val / float(n))
		for k in range(n):
			var ang: float = randf() * TAU
			_spawn_orb(e.position + Vector2.from_angle(ang) * randf_range(10.0, 70.0), "xpBig", per)
		if not e.judge:
			_spawn_orb(e.position + Vector2(24.0, 0.0), "heal", 0.0)
			_spawn_orb(e.position + Vector2(-24.0, 0.0), "magnet", 0.0)
			if randf() < 0.2:
				_spawn_orb(e.position + Vector2(0.0, -20.0), "ticket10", 1.0)
			for k in range(10):
				_spawn_orb(e.position + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 30.0)), "coin", 5.0)
			_spawn_orb(e.position + Vector2(-26.0, -10.0), "item", 0.0)
		_say(L.t("¡%s derrotado!") % e.enemy_name, 2.6)
		shake = 10.0
		return
	var kind := "xp"
	if e.xp_val >= XP_ENEMY:
		kind = "xpBig"
	_spawn_orb(e.position, kind, e.xp_val)
	if randf() < 1.0 / 600.0:
		_spawn_orb(e.position + Vector2(10.0, 0.0), "ticket", 1.0)
	var r: float = randf()
	var off: Vector2 = Vector2.from_angle(randf() * TAU) * 14.0
	if r < 0.012:
		_spawn_orb(e.position + off, "heal", 0.0)
	elif r < 0.020:
		_spawn_orb(e.position + off, "magnet", 0.0)
	elif r < 0.026:
		_spawn_orb(e.position + off, "bomb", 0.0)
	elif r < 0.041:
		_spawn_orb(e.position + off, "item", 0.0)


func _update_orbs(delta: float) -> void:
	var mag_r: float = _magnet()
	var pr: Vector2 = player.position
	for i in range(orbs.size() - 1, -1, -1):
		var o = orbs[i]
		var to: Vector2 = pr - o.position
		var d: float = to.length()
		if d < 15.0:
			var kind: String = o.kind
			var val: float = o.value
			o.queue_free()
			orbs.remove_at(i)
			_collect(kind, val)
			continue
		if o.pulled or d < mag_r:
			var pull: float = 240.0 + 1400.0 / maxf(d, 1.0)
			var tv: Vector2 = to / maxf(d, 0.001) * pull
			o.vel = o.vel.lerp(tv, 1.0 - exp(-7.0 * delta))
		else:
			o.vel *= pow(0.02, delta)
		o.position += o.vel * delta


func _collect(kind: String, value: float) -> void:
	if kind == "xp" or kind == "xpBig":
		_gain_xp(value)
		Aud.xp()
	elif kind == "heal":
		Aud.sfx("heal")
		player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.3 * _rk("healmul"))
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+PS"), Color("#5fe08a"))
	elif kind == "magnet":
		for o in orbs:
			if o.kind == "xp" or o.kind == "xpBig":
				o.pulled = true
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("IMAN!"), Color("#7fe0ff"))
	elif kind == "coin":
		coins += int(value * (1.25 if _has_item("pureincense") else 1.0) * (2.0 if _has_mod("rich") else 1.0) + randf())
		Aud.sfx("coin")
	elif kind == "ticket10":
		tickets10 += int(value)
		Aud.sfx("shinyGet")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d ×10 tickets") % int(value), Color("#c47bff"))
	elif kind == "gcoin_gold":
		gold_gcoins_run += int(value)
		Aud.sfx("legend")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d Gachapon Coin Dorada") % int(value), Color("#ffd23f"), 22)
	elif kind == "gcoin":
		gcoins_run += int(value)
		Aud.sfx("shinyGet")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d Gachapon Coin") % int(value), Color("#ff8ad8"), 20)
	elif kind == "ticket":
		tickets += int(value)
		Aud.sfx("shinyGet")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d tickets") % int(value), Color("#ffd23f"))
	elif kind == "ball":
		if balls < BALL_CAP:
			balls += maxi(1, int(value))
			balls = mini(balls, BALL_CAP)
			Aud.sfx("shinyGet")
			add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d Poké Ball") % maxi(1, int(value)), Color("#ff6b6b"))
		else:
			add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("Mochila de Poké Balls llena"), Color("#c8d0dc"), 16)
	elif kind == "item":
		if z_state != "":
			pending_items += 1
		else:
			_offer_item()
	elif kind == "bomb":
		Aud.sfx("ball")
		shake = 12.0
		# La bomba aniquila de un golpe a todo lo que esta en pantalla; los jefes pierden el 30% de su vida.
		_ring(player.position, 10.0, 620.0, Color("#ff7b3d"), 0.5, 6.0)
		pfx.burst(player.position, Color("#ffb347"), 40, 320.0)
		var killed := 0
		for e in enemies.duplicate():
			if e.dead or e.position.distance_to(player.position) > 760.0 or bool(e.def.get("scripted", false)):
				continue
			if e.boss or e.legend or bool(e.def.get("final", false)) or e.judge:
				_damage_enemy(e, maxf(80.0, e.max_hp * 0.3), Color("#ff7b3d"))
			else:
				_damage_enemy(e, e.hp + e.shield + 1.0, Color("#ff7b3d"))
				killed += 1
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("BOOM!"), Color("#ff7b3d"))


# Construye las cartas candidatas (levelup.js) y devuelve tres.
func _offer() -> Array:
	var pool: Array = []
	var waiting := {}

	# --- movimientos nuevos ---
	if _slot_list().size() < _max_moves():
		var owned := {}
		var buffs := 0
		for m in player.moves:
			owned[String(m["id"])] = true
			if String(m["kind"]) == "buff":
				buffs += 1
		var cand: Array = []
		for id in MD.ORDER:
			var d: Dictionary = MD.MOVES[id]
			var ty: String = String(d["type"])
			if ty != "normal" and not player.types.has(ty):
				continue
			if not GPM.playable(String(id)):
				continue
			if owned.has(id) or banned.has(id) or fused_away.has(String(id)):
				continue
			if buffs >= 2 and String(d["kind"]) == "buff":
				continue
			cand.append(id)
		# Los movimientos de tipo Normal salen menos (peso 0.15) para que los de tu propio tipo no queden opacados.
		var keyed: Array = []
		for id in cand:
			var wgt: float = NORMAL_MOVE_W if String(MD.MOVES[id]["type"]) == "normal" else 1.0
			keyed.append([pow(maxf(0.0001, randf()), 1.0 / wgt), id])
		keyed.sort_custom(func(a, b): return a[0] > b[0])
		cand = keyed.map(func(x): return x[1])
		for i in range(mini(6, cand.size())):
			var nid: String = String(cand[i])
			var nd: Dictionary = MD.MOVES[nid]
			pool.append({"cat": "new", "id": nid, "key": "new:" + nid, "w": 10.0, "title": String(nd["name"]),
				"desc": _move_desc(nd), "icon": "move:" + nid, "tag": String(MD.TYPE_NAME[String(nd["type"])]),
				"color": Color.html(String(MD.TYPE_COLOR[String(nd["type"])]))})

	# --- evoluciones: movimiento al maximo + su condicion cumplida ---
	for m in player.moves:
		if mode == "chal" and _ch_rs("no_evo"):
			break
		if m.has("parts"):
			continue   # un movimiento fusionado ya no se puede mejorar ni evolucionar
		for ev in _evo_infos(m):
			if not bool(ev["ready"]):
				if STATS.has(String(ev["needs"])):
					waiting[String(ev["needs"])] = m
				continue
			pool.append({"cat": "evo", "id": String(m["id"]), "alt": bool(ev["alt"]), "key": "evo:" + String(m["id"]) + (":alt" if bool(ev["alt"]) else ""), "w": 40.0,
				"title": "%s > %s" % [L.t(String(m["name"])), L.t(String(ev["name"]))], "desc": String(ev["text"]),
				"icon": "evo:" + String(m["id"]), "tag": "EVOLUCIÓN", "color": Color("#ffd23f")})

	# --- mejoras de movimientos que ya tienes ---
	for m in player.moves:
		if m.has("parts") or int(m["lvl"]) >= _max_lvl(m):
			continue
		var ladder: Array = MD.LADDERS[String(m["kind"])]
		pool.append({"cat": "up", "id": String(m["id"]), "key": "up:" + String(m["id"]), "w": 8.0,
			"title": String(m["name"]), "icon": "move:" + String(m["id"]), "desc": String(ladder[int(m["lvl"]) - 1]["t"]),
			"tag": L.t("Nv.%d > %d") % [int(m["lvl"]), int(m["lvl"]) + 1], "color": _col(m)})

	# --- estadisticas (las que desbloquean una evolucion salen siempre) ---
	var cand_s: Array = []
	for sid in STAT_IDS:
		if waiting.has(sid):
			continue
		if _lv(sid) >= int(STATS[sid]["max"]):
			continue
		cand_s.append(sid)
	cand_s.shuffle()
	var picks_s: Array = cand_s.slice(0, 5)
	for sid in waiting:
		picks_s.append(sid)
	for sid in picks_s:
		var sd: Dictionary = STATS[sid]
		var evo_for: bool = waiting.has(sid)
		var w: float = 7.0
		if evo_for:
			w = 14.0
		elif _slot_list().size() < _max_moves():
			w = 4.0
		var tag := "Mejora"
		var colr := Color("#8fa3c4")
		if evo_for:
			tag = L.t("Evoluciona ") + L.t(String(waiting[sid]["name"]))
			colr = Color("#ffd23f")
		pool.append({"cat": "stat", "id": String(sid), "key": "stat:" + String(sid), "w": w,
			"title": String(sd["title"]), "desc": String(sd["desc"]), "icon": String(STAT_ICON.get(sid, "star")), "tag": tag, "color": colr})

	# --- reto "sin mejoras": solo movimientos nuevos, objetos y curacion ---
	if mode == "chal" and _ch_rs("no_upgrade"):
		var keep: Array = []
		for c in pool:
			var cc: String = String(c["cat"])
			if not (cc == "evo" or cc == "up" or (cc == "stat" and String(c["id"]) != "heal")):
				keep.append(c)
		if keep.is_empty():
			# Sin nada mas que ofrecer: solo curacion (nunca una mejora, ni siquiera como ultimo recurso)
			for c in pool:
				if String(c["cat"]) == "stat" and String(c["id"]) == "heal":
					keep.append(c)
		pool = keep
	# --- elegir tres ---
	var picked: Array = []
	for i in range(pool.size()):
		if String(pool[i]["cat"]) == "evo":
			picked.append(pool[i])
			pool.remove_at(i)
			break
	while picked.size() < 3 and not pool.is_empty():
		var total := 0.0
		for c in pool:
			total += float(c["w"])
		var roll: float = randf() * total
		var idx := pool.size() - 1
		for k in range(pool.size()):
			roll -= float(pool[k]["w"])
			if roll <= 0.0:
				idx = k
				break
		picked.append(pool[idx])
		pool.remove_at(idx)
	return picked


# ---------------------------------------------------------------
# Vinculos: une movimientos por parejas, cada pareja en un solo hueco (player.js)
# ---------------------------------------------------------------


# Atajos de Mejoras: cada movimiento con hueco fijo se coloca en ese numero; si aun
# no hay tantos, va al mas cercano y el resto rellena los libres en orden de aprendizaje.
func _arrange(keep: Dictionary = {}) -> void:
	var bl: Array = SV.bind_list(SV.run_dex)
	var want_of := {}
	for i in range(4):
		if String(bl[i]) != "":
			want_of[String(bl[i])] = i
	var sl: Array = _slot_list()
	var n: int = sl.size()
	if want_of.is_empty() or n < 2:
		return
	var cur_m: Dictionary = keep
	if cur_m.is_empty() and player.slot < n:
		cur_m = sl[player.slot][0]
	var wants: Array = []
	for g in sl:
		var k := 99
		for m in g:
			if want_of.has(String(m["id"])):
				k = mini(k, int(want_of[String(m["id"])]))
		wants.append(k)
	var order: Array = []
	for gi in range(n):
		if int(wants[gi]) < 99:
			order.append(gi)
	order.sort_custom(func(a, b): return int(wants[a]) < int(wants[b]))
	var out: Array = []
	out.resize(n)
	out.fill(-1)
	for gi in order:
		var p: int = mini(int(wants[gi]), n - 1)
		while p >= 0 and int(out[p]) != -1:
			p -= 1
		if p < 0:
			p = 0
			while int(out[p]) != -1:
				p += 1
		out[p] = gi
	for gi in range(n):
		if not out.has(gi):
			out[out.find(-1)] = gi
	var flat: Array = []
	var new_slot := 0
	for pos in range(n):
		var g: Array = sl[int(out[pos])]
		if not cur_m.is_empty() and g.has(cur_m):
			new_slot = pos
		for m in g:
			flat.append(m)
	player.moves = flat
	player.slot = new_slot


func _slot_list() -> Array:
	return _slot_list_of(player.moves, bond_pairs)


func _slot_list_of(moves: Array, pairs: Array) -> Array:
	var out: Array = []
	var grp_of := {}
	for m in moves:
		var pi: int = _pair_index(pairs, String(m["id"]))
		if pi < 0:
			out.append([m])
			continue
		if not grp_of.has(pi):
			grp_of[pi] = []
			out.append(grp_of[pi])
		grp_of[pi].append(m)
	return out


func _pair_index(pairs: Array, id: String) -> int:
	for i in range(pairs.size()):
		if (pairs[i] as Array).has(id):
			return i
	return -1


func _active_group() -> Array:
	var sl: Array = _slot_list()
	return sl[clampi(player.slot, 0, sl.size() - 1)]


func _bond_options() -> Dictionary:
	var loose: Array = []
	for m in player.moves:
		if _pair_index(bond_pairs, String(m["id"])) < 0:
			loose.append(m)
	# v6.0: maximo 2 por vinculo, pero se pueden formar parejas nuevas mientras queden movimientos libres
	if loose.size() >= 2:
		return {"loose": loose}
	return {}


func _offer_bond(quiet: bool = false) -> void:
	if bonds <= 0 or player.dead or choosing or (arena != null and not _arena_bond_ready()):
		return
	var opt: Dictionary = _bond_options()
	if opt.is_empty():
		if not quiet:
			_say(L.t("Guardas el vínculo: aprende otro movimiento para usarlo"), 3.0)
		return
	var picks: Array = []
	for m in opt["loose"]:
		if bond_first != "" and String(m["id"]) == bond_first:
			continue
		var d: String = String(m["desc"])
		if bond_first != "":
			d = L.t("Se lanzará a la vez que %s. Queda un hueco libre.") % _move_name(bond_first)
		picks.append({"cat": "bond", "id": String(m["id"]), "key": "bond:" + String(m["id"]), "w": 1.0,
			"title": String(m["name"]), "desc": d, "icon": "move:" + String(m.get("recipe", m["id"])),
			"tag": L.t("Nv.%d") % int(m["lvl"]), "color": _col(m)})
	var heading: String = L.t("Elige el primer movimiento que vas a unir")
	if bond_first != "":
		heading = L.t("¿Con cuál unes %s?") % _move_name(bond_first)
	choosing = true
	Aud.sfx("levelup")
	cards.show_cards(picks, heading, L.t("¡Vínculo!"), false)


# ---------------------------------------------------------------
# S54: fusion de dos movimientos vinculados (evolucionados y al maximo) en un Movimiento de Vinculo
# ---------------------------------------------------------------
const FUSE_DMG := 2.2   # cada mitad pega mucho mas que un evolucionado normal (x1,8)
var fuse_asked := ""
var fused_once := false   # solo una fusion por partida
var fused_away: Array = []   # movimientos consumidos: ya no se ofrecen en las mejoras


func _fuse_pair() -> Array:
	if fused_once:
		return []
	# v6.0: se fusiona la primera pareja con los dos evolucionados y al maximo
	for pair in bond_pairs:
		var out: Array = []
		for id in pair:
			for m in player.moves:
				if String(m["id"]) == String(id) and not m.has("parts") and bool(m["evolved"]) and int(m["lvl"]) >= _max_lvl(m):
					out.append(m)
		if out.size() >= 2:
			return out
	return []


func _fuse_ready() -> bool:
	if player.dead or mode == "tower" or _ch_rs("no_fusion"):
		return false
	return not _fuse_pair().is_empty()


func _offer_fuse() -> void:
	var pr: Array = _fuse_pair()
	if pr.is_empty():
		return
	fuse_asked = "%s+%s" % [String(pr[0]["id"]), String(pr[1]["id"])]   # se ofrece una sola vez por pareja
	var nm := "%s + %s" % [L.t(String(pr[0]["name"])), L.t(String(pr[1]["name"]))]
	var picks: Array = [
		{"cat": "fuse", "id": "yes", "key": "fuse:yes", "w": 1.0, "title": L.t("Fusionar"),
		 "desc": L.t("Los dos movimientos originales se perderán el resto de la partida y se unirán en uno mucho más potente: %s.") % nm,
		 "icon": "evo:" + String(pr[0]["id"]), "tag": L.t("Vínculo"), "color": Color("#ff8ad8")},
		{"cat": "fuse", "id": "no", "key": "fuse:no", "w": 1.0, "title": L.t("Cancelar"),
		 "desc": L.t("Conservas los dos movimientos tal como están."),
		 "icon": "evo:" + String(pr[1]["id"]), "tag": "", "color": Color("#8fa3c4")}]
	choosing = true
	Aud.sfx("levelup")
	cards.show_cards(picks, L.t("¿Fusionar los movimientos vinculados?"), L.t("¡Vínculo!"), false)


func _do_fuse() -> void:
	var pr: Array = _fuse_pair()
	if pr.is_empty():
		return
	var a: Dictionary = pr[0]
	var b: Dictionary = pr[1]
	var fm: Dictionary = a.duplicate(true)
	fm["parts"] = [a, b]
	for pm in fm["parts"]:
		if pm.has("dmg"):
			pm["dmg"] = float(pm["dmg"]) * FUSE_DMG
		if pm.has("cd"):
			pm["cd"] = float(pm["cd"]) * 0.8
	fm["name"] = "%s + %s" % [String(a["name"]), String(b["name"])]
	fm["fused"] = true
	fused_once = true
	fused_away.append(String(a["id"]))
	fused_away.append(String(b["id"]))
	var rec: Dictionary = FUS.find(String(a["id"]), String(b["id"]))
	if not rec.is_empty():
		fm["name"] = String(rec["name"])
		fm["recipe"] = String(rec["id"])
		if not SV.d["fusions"].has(rec["id"]):
			SV.d["fusions"].append(rec["id"])
			SV.save()
			_say(L.t("¡Receta descubierta: %s!") % L.t(String(rec["name"])), 3.5)
	fm["lvl"] = _max_lvl(a)
	fm["evolved"] = true
	var out: Array = []
	var placed := false
	for m in player.moves:
		if m == a or m == b:
			if not placed:
				placed = true
				out.append(fm)
			continue
		out.append(m)
	player.moves = out
	# v6.0: la pareja fusionada deja de ser vinculo; las demas parejas siguen igual
	bond_pairs.remove_at(_pair_index(bond_pairs, String(a["id"])))
	bond_first = ""
	fuse_asked = ""
	player.slot = clampi(player.slot, 0, maxi(0, _slot_list().size() - 1))
	_clear_orbit_orbs()
	Aud.sfx("legend")
	Aud.sfx("fusion")
	var fcol := Color("#ff8ad8")
	if not rec.is_empty():
		fcol = Color.html(String(rec["col"]))
	_ring(player.position, 8.0, 160.0, fcol, 0.9, 5.0)
	_ring(player.position, 8.0, 280.0, Color.WHITE, 1.2, 3.0)
	pfx.burst(player.position + Vector2(0.0, -20.0), fcol, 60, 300.0)
	pfx.burst(player.position + Vector2(0.0, -20.0), Color.WHITE, 24, 180.0)
	shake = maxf(shake, 14.0)
	fusion_t = 2.8
	fusion_name = L.t(String(fm["name"]))
	fm["sig_t"] = 0.8
	PG.event("fuse")


# ---------------------------------------------------------------
# S23: resumen vivo de la partida (pausa). DPS = dano registrado en los ultimos 20 s / 20 s (o el tiempo jugado si es menos).
# ---------------------------------------------------------------
const DPS_WIN := 20
var dmg_hist: Array = []
var dmg_hist_t := 0.0


func _sample_dmg(delta: float) -> void:
	dmg_hist_t += delta
	if dmg_hist_t < 1.0:
		return
	dmg_hist_t -= 1.0
	dmg_hist.append(run_dmg.duplicate())
	if dmg_hist.size() > DPS_WIN + 1:
		dmg_hist.pop_front()


func _move_dmg_of(mv: Dictionary, src: Dictionary) -> float:
	if mv.has("parts"):
		var t := 0.0
		for pm in mv["parts"]:
			t += float(src.get(String(pm["id"]), 0.0))
		return t
	return float(src.get(String(mv["id"]), 0.0))


func _ptypes_text() -> Array:
	var out: Array = []
	for t in player.types:
		out.append(L.t(String(MD.TYPE_NAME.get(String(t), String(t)))))
	return out


func pause_summary() -> Dictionary:
	var crit_p: float = minf(0.95, float(perks["crit"]) + (0.15 if _has_item("scopelens") else 0.0) + (0.05 if _has_item("ti_normal") else 0.0) + _lens_add() + _abn("crit"))
	var all_stats: Array = [
		[L.t("Vida"), "%d / %d" % [int(player.hp), int(player.max_hp)], "heart"],
		[L.t("Daño"), "%d%%" % roundi(_atk() / maxf(0.001, base_atk) * 100.0), "fist"],
		[L.t("Velocidad"), "%d" % roundi(_spd()), "boot"],
		[L.t("Recarga"), "%d%%" % roundi(100.0 / maxf(0.05, _cd_mul_raw())), "clock"],
		[L.t("Defensa"), "%d%%" % roundi(_reduction() * 100.0), "shield"],
		[L.t("Regeneración"), "%.1f/s" % _regen(), "sprout"],
		[L.t("Imán"), "%d" % roundi(_magnet()), "magnet"],
		[L.t("Experiencia"), "x%.2f" % _xp_mul(), "book"],
		[L.t("Tamaño"), "%d%%" % roundi(_size_k() * 100.0), "size"],
		[L.t("Prob. de crítico"), "%d%%" % roundi(crit_p * 100.0), "scopelens"],
		[L.t("Daño crítico"), "x%.2f" % _edge_mul(), "expertbelt"],
		[L.t("Robo de vida"), "%d%%" % roundi(_fang_pct() * 100.0), "lifeorb"],
		[L.t("Golpe doble"), "%d%%" % roundi(_dstrike_p() * 100.0), "choiceband"],
		[L.t("Proyectiles extra"), "+%d" % _mult_extra(), "cards"],
		[L.t("Perforación extra"), "+%d" % _pierce_extra(), "quickclaw"],
		[L.t("Potencia de estados"), "x%.2f" % _amp_k(), "star"],
		[L.t("Pokémonedas finales"), "x%.2f" % _treasure_k(), "amuletcoin"],
		[L.t("Nivel"), "%d" % player.level, "star"],
		[L.t("Derrotas"), "%d" % kills, "fist"],
		[L.t("Tipos"), "/".join(PackedStringArray(_ptypes_text())), "star"],
		[L.t("Habilidad"), L.t(String(AB.FX[AB.of(_pdex())]["name"])), "star"],
	]
	var out := {"moves": [], "stats": [], "items": [], "all": all_stats, "time": run_time, "level": player.level,
		"hp": "%d / %d" % [int(player.hp), int(player.max_hp)], "window": DPS_WIN, "kills": kills, "pname": L.t(String(_dex_by[_pdex()]["name"])), "dex": _pdex(), "ab_name": L.t(String(AB.FX[AB.of(_pdex())]["name"])), "ab_desc": L.t(String(AB.FX[AB.of(_pdex())]["desc"])), "types": _ptypes_text(), "hp_ratio": clampf(float(player.hp) / maxf(1.0, float(player.max_hp)), 0.0, 1.0), "sprite": _sum_sprite()}
	var old: Dictionary = dmg_hist[0] if not dmg_hist.is_empty() else {}
	var span: float = float(maxi(1, dmg_hist.size() - 1)) if not dmg_hist.is_empty() else 1.0
	for mv in player.moves:
		var tot: float = _move_dmg_of(mv, run_dmg)
		var dps: float = maxf(0.0, tot - _move_dmg_of(mv, old)) / span
		var ids: Array = []
		if mv.has("parts"):
			for pm in mv["parts"]:
				ids.append(String(pm["id"]))
		else:
			ids.append(String(mv["id"]))
		var kills := 0
		for i in ids:
			kills += int(run_kills_by.get(i, 0))
		out["moves"].append({"name": L.t(String(mv["name"])), "type": L.t(String(MD.TYPE_NAME.get(String(mv["type"]), ""))), "lvl": int(mv["lvl"]),
			"dmg": int(tot), "dps": dps, "kills": kills, "icon": "move:" + ids[0], "col": String(MD.TYPE_COLOR.get(String(mv["type"]), "#ffffff"))})
	for sid in STATS:
		var lv: int = _lv(String(sid))
		if lv > 0 and String(sid) != "heal":
			out["stats"].append({"name": L.t(String(STATS[sid]["title"])), "lv": lv, "icon": String(STAT_ICON.get(sid, "star"))})
	for it in [item, item2, item3]:
		if String(it) != "":
			var idesc := ""
			for td in TD.ITEMS:
				if String(td["id"]) == String(it):
					idesc = L.t(String(td["desc"]))
			out["items"].append({"id": String(it), "name": _item_name_of(String(it)), "desc": idesc})
	return out


func _sum_sprite() -> Texture2D:
	if player.sprite == null or player.sprite.texture == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = player.sprite.texture
	at.region = player.sprite.region_rect if player.sprite.region_enabled else Rect2(Vector2.ZERO, player.sprite.texture.get_size())
	return at


func _move_name(id: String) -> String:
	for m in player.moves:
		if String(m["id"]) == id:
			return L.t(String(m["name"]))
	return id


func _bond_pick(id: String) -> void:
	var opt: Dictionary = _bond_options()
	cards.hide_cards()
	choosing = false
	if opt.is_empty():
		bond_first = ""
		return
	if bond_first == "":
		bond_first = id
		Aud.sfx("select")
		_offer_bond(true)
		return
	var cur_m: Dictionary = _active_group()[0]
	var pair: Array = [bond_first, id]
	bond_pairs.append(pair)
	bond_first = ""
	bonds = maxi(0, bonds - 1)
	var sl: Array = _slot_list()
	var target := 0
	for i in range(sl.size()):
		for m in sl[i]:
			if String(m["id"]) == id:
				target = i
	if _has_item("choiceband"):
		for i in range(sl.size()):
			for m in sl[i]:
				if String(m["id"]) == String(cur_m["id"]):
					target = i
	_clear_orbit_orbs()
	player.slot = target
	Aud.sfx("legend")
	_ring(player.position, 8.0, 130.0, Color("#ff8ad8"), 0.8)
	_say(L.t("¡Vínculo! %d movimientos a la vez") % pair.size(), 2.6)
	_fuse_hint(pair)


# v5.2: si la pareja vinculada no se puede fusionar, dice por que (antes no pasaba nada y no se sabia el motivo).
func _fuse_hint(pair: Array) -> void:
	if mode == "tower":
		return
	var why := ""
	if fused_once:
		why = L.t("Solo se puede fusionar una vez por partida")
	else:
		for id in pair:
			for m in player.moves:
				if String(m["id"]) == String(id) and not why != "":
					if m.has("parts"):
						why = L.t("%s ya es una fusión") % L.t(String(m["name"]))
					elif not bool(m["evolved"]):
						why = L.t("Para fusionar, %s debe estar evolucionado") % L.t(String(m["name"]))
	if why != "":
		get_tree().create_timer(2.8).timeout.connect(func(): _say(why, 3.4))


func _open_cards() -> void:
	var picks: Array = _offer()
	if picks.is_empty():
		pending_levels = 0
		return
	choosing = true
	Aud.sfx("levelup")
	cards.rerolls = rerolls
	cards.bans = bans
	cards.show_cards(picks, L.t("Nivel %d - elige una mejora") % player.level)


func _on_card_chosen(idx: int) -> void:
	var opts: Array = cards.items
	if idx < 0 or idx >= opts.size():
		return
	var c: Dictionary = opts[idx]
	var id: String = String(c["id"])
	var cat: String = String(c["cat"])
	if cat == "trest" or cat == "trisk":
		_tower_rest_pick(cat, id)
		return
	if cat == "itemtake" or cat == "itemkeep":
		if cat == "itemtake" and id == "rarecandy":
			player.level += 1
			player.xp_next = _xp_need(player.level)
			pending_levels += 1
			PG.event("item", {"id": id})
			Aud.sfx("levelup")
			_ring(player.position, 8.0, 140.0, Color("#4f9cf0"), 0.7)
			add_text(player.position + Vector2(0.0, -player.body_h - 8.0), L.t("¡Caramelo Raro! +1 nivel"), Color("#4f9cf0"), 22)
			# v5.2.2: pasa directo a la pantalla de mejora, sin cerrar las cartas un fotograma (eso hacia parpadear la pantalla)
			cards.hide_cards()
			choosing = false
			_open_cards()
			return
		elif cat == "itemtake":
			if int(c.get("slot", 1)) == 3:
				item3 = id
			elif int(c.get("slot", 1)) == 2:
				item2 = id
			else:
				item = id
			PG.event("item", {"id": id})
			add_text(player.position + Vector2(0.0, -player.body_h - 8.0), _item_name(), Color("#ff8ad8"), 22)
		cards.hide_cards()
		choosing = false
		return
	if cat == "bond":
		_bond_pick(id)
		return
	if cat == "fuse":
		cards.hide_cards()
		choosing = false
		if id == "yes":
			_do_fuse()
		return
	if cat == "new":
		var nm: Dictionary = _new_move(id, 1)
		var cur_g: Array = _active_group()
		var cur_first: Dictionary = cur_g[0]
		player.moves.append(nm)
		_arrange(cur_first)
		# S58.7: aprender un movimiento NO cambia el movimiento activo elegido por el jugador.
		for gi in range(_slot_list().size()):
			if String(_slot_list()[gi][0]["id"]) == String(cur_first["id"]):
				player.slot = gi
	elif cat == "evo" or cat == "up":
		for m in player.moves:
			if String(m["id"]) == id:
				if cat == "evo":
					_evolve(m, bool(c.get("alt", false)))
				else:
					_level_up_move(m)
				break
	else:
		stat_lv[id] = _lv(id) + 1
		if id == "hp":
			player.max_hp += 20.0
			player.hp = minf(player.max_hp, player.hp + 20.0)
		elif id == "heal":
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.45)
	if mode == "chal" and (cat == "evo" or cat == "up" or (cat == "stat" and id != "heal")):
		ch_m["upgrades"] = int(ch_m.get("upgrades", 0)) + 1   # las mejoras de las cartas cuentan como mejoras compradas
	Aud.sfx("confirm")
	pending_levels = maxi(0, pending_levels - 1)
	cards.hide_cards()
	choosing = false


# ---------------------------------------------------------------
# Objetos (items.js): uno por run
# ---------------------------------------------------------------
const ITEM_EVERY := 3
var chests_no_item := 0
var item_bag: Array = []
var run_item_block: Array = []   # v6.1: objetos descartados: solo durante esta partida


# v5.8: bolsa barajada: salen todos los objetos disponibles antes de repetir uno.
func _next_item(pool: Array) -> Dictionary:
	for round_i in range(2):
		for i in range(item_bag.size()):
			for it in pool:
				if String(it["id"]) == String(item_bag[i]):
					item_bag.remove_at(i)
					return it
		item_bag = pool.map(func(it): return String(it["id"]))
		item_bag.shuffle()
	return pool[0]


func _offer_item() -> void:
	var two: bool = tw_risk.has("l_bag") or has_bag
	var three: bool = has_bag3
	var pool: Array = []
	for it in TD.ITEMS:
		if String(it["id"]) != item and not (two and String(it["id"]) == item2) and not (three and String(it["id"]) == item3) and _item_ok_for(String(it["id"])):
			pool.append(it)
	var blocked: Array = run_item_block
	var pool2: Array = []
	for it2 in pool:
		if not blocked.has(String(it2["id"])) or String(it2["id"]) == "rarecandy":
			pool2.append(it2)
	if not pool2.is_empty():
		pool = pool2
	if pool.is_empty():
		return
	var nw: Dictionary = _next_item(pool)
	var picks: Array = []
	if not two:
		picks.append({"cat": "itemtake", "id": String(nw["id"]), "key": "it:" + String(nw["id"]), "w": 1.0,
			"title": String(nw["name"]), "desc": String(nw["desc"]), "icon": String(nw["id"]), "tag": "Objeto nuevo", "color": Color("#ff8ad8")})
		if item != "":
			var cur_desc: String = ""
			for it in TD.ITEMS:
				if String(it["id"]) == item:
					cur_desc = String(it["desc"])
			picks.append({"cat": "itemkeep", "id": item, "key": "keep", "w": 1.0,
				"title": _item_name(), "desc": cur_desc, "icon": item, "tag": "Quedarte con el tuyo", "color": Color("#8fa3c4")})
		choosing = true
		cards.show_cards(picks, L.t("Solo puedes llevar uno: elige con cuál quedarte"), L.t("Has encontrado un objeto"), false)
		_item_ui(String(nw["id"]))
		return
	# Doble equipaje: dos huecos. Si hay uno libre se rellena; si no, eliges a cuál sustituye.
	var slots: Array = []
	if item == "":
		slots.append(1)
	elif item2 == "":
		slots.append(2)
	elif three and item3 == "":
		slots.append(3)
	else:
		slots = [1, 2, 3] if three else [1, 2]
	if String(nw["id"]) == "rarecandy":
		slots = [1]   # el Caramelo Raro no ocupa hueco: una sola carta
	for sl in slots:
		var tg: String = "Objeto nuevo"
		if slots.size() >= 2:
			tg = L.t("Sustituye: %s") % L.t(_item_name_of(item if int(sl) == 1 else (item2 if int(sl) == 2 else item3)))
		picks.append({"cat": "itemtake", "slot": int(sl), "id": String(nw["id"]), "key": "it:%s:%d" % [String(nw["id"]), int(sl)], "w": 1.0,
			"title": String(nw["name"]), "desc": String(nw["desc"]), "icon": String(nw["id"]), "tag": tg, "color": Color("#ff8ad8")})
	if item != "":
		picks.append({"cat": "itemkeep", "id": item, "key": "keep", "w": 1.0, "title": "Quedarte con los tuyos",
			"desc": L.t("Sigues con tus objetos actuales."), "icon": item, "tag": "Sin cambios", "color": Color("#8fa3c4")})
	choosing = true
	cards.show_cards(picks, L.t("Puedes llevar tres objetos") if three else L.t("Puedes llevar dos objetos"), L.t("Has encontrado un objeto"), false)
	_item_ui(String(nw["id"]))


func _item_ui(new_id: String) -> void:
	cards.item_mode = true
	cards.block_name = "" if new_id == "rarecandy" else new_id
	cards.queue_redraw()


# Skip: ignora el objeto recogido sin cambiar nada (puede volver a salir mas adelante).
func _on_skip_pressed() -> void:
	Aud.sfx("select")
	cards.hide_cards()
	choosing = false


func _on_block_pressed() -> void:
	if not run_item_block.has(cards.block_name):
		run_item_block.append(cards.block_name)
	# El objeto ofrecido se descarta: nos quedamos con lo que ya llevamos.
	for i in range(cards.items.size()):
		if String(cards.items[i]["cat"]) == "itemkeep":
			cards.chosen.emit(i)
			return
	cards.hide_cards()
	choosing = false


# ---------------------------------------------------------------
# Clima (weather.js): evento raro, cambia el dano segun el tipo
# ---------------------------------------------------------------
func _wx_level() -> float:
	if wx_kind == "":
		return 0.0
	return clampf(minf(wx_t / 3.0, (wx_dur - wx_t) / 3.0), 0.0, 1.0)


func _weather_mult(type: String) -> float:
	if wx_kind == "":
		return 1.0
	var d: Dictionary = TD.WEATHER[wx_kind]
	var mm: Dictionary = d["mult"]
	if mm.has(type):
		return 1.0 + (float(mm[type]) - 1.0) * _wx_level()
	return 1.0


func _weather_hurts(types: Array) -> bool:
	if wx_kind == "":
		return false
	var safe: Array = TD.WEATHER[wx_kind]["safe"]
	if safe.is_empty():
		return false
	for t in types:
		if safe.has(t):
			return false
	return true


func _weather_speed(types: Array) -> float:
	if wx_kind != "" and bool(TD.WEATHER[wx_kind]["slow"]) and not types.has("ice"):
		return 1.0 - 0.1 * _wx_level()
	return 1.0


func _weather_text() -> String:
	if wx_kind == "" or _wx_level() <= 0.0:
		return ""
	return "%s  %ds" % [L.t(String(TD.WEATHER[wx_kind]["name"])), ceili(wx_dur - wx_t)]


func _weather_banner() -> String:
	if wx_kind == "" or wx_banner <= 0.0:
		return ""
	var d: Dictionary = TD.WEATHER[wx_kind]
	return "%s: %s" % [L.t(String(d["name"])), L.t(String(d["hint"]))]


# ---------------------------------------------------------------
# Grietas y arenas legendarias (rift.js)
# ---------------------------------------------------------------
func _update_rift(delta: float) -> void:
	if rift != null:
		if not is_instance_valid(rift) or rift.ttl <= 0.0:
			if is_instance_valid(rift):
				rift.queue_free()
			rift = null
			_rift_drop_arena()
		elif rift.t > 1.0 and player.position.distance_to(rift.position) < 42.0 and not player.dead:
			_arena_begin()
			return
	rift_check -= delta
	if rift_check > 0.0:
		return
	rift_check = 8.0 if mode == "rifts" else RIFT_EVERY
	if rift != null or run_time >= RIFT_END or _boss_alive() or mode == "rush" or mode == "tower":
		return
	if mode == "normal" and (dir_finale or not dir_done.has("rift")):
		return   # S63: la primera Grieta la abre el director; en el final no hay Grietas
	if mode == "rifts" and run_time > RIFTS_LIMIT - 40.0:
		return   # ya no da tiempo a una pelea nueva
	# Guarida Dynamax: 5% por chequeo (cada RIFT_EVERY s), no en la contrarreloj de grietas
	if mode != "rifts" and run_time >= DEN_FROM and randf() < DEN_RATE:
		_open_rift(-1, true)
		return
	var chance: float = 1.0 if mode == "rifts" else minf(1.0, 0.2 + 0.2 * float(rift_miss))
	if randf() < chance:
		rift_miss = 0
		_open_rift(-1, false)
	else:
		rift_miss += 1


func _legend_pool() -> Array:
	var out: Array = []
	for p in _dex_list:
		if bool(p.get("leg", false)) and _smeta.has(str(int(p["dex"]))):
			out.append(p)
	return out


func _pick_legend() -> Dictionary:
	var pool: Array = _legend_pool()
	if pool.is_empty():
		return {}
	var seen: Dictionary = SV.d.get("legends", {})
	var tot := 0.0
	for p in pool:
		tot += 1.0 if seen.has(str(int(p["dex"]))) else 4.0
	var roll: float = randf() * tot
	for p in pool:
		roll -= 1.0 if seen.has(str(int(p["dex"]))) else 4.0
		if roll <= 0.0:
			return p
	return pool[pool.size() - 1]


func _open_rift(force_dex: int = -1, den: bool = false) -> void:
	var p: Dictionary = {}
	if den:
		var cl: Array = _candidates(_tier_at(run_time))
		if not cl.is_empty():
			p = cl[randi() % cl.size()]
	else:
		p = _dex_by[force_dex] if force_dex > 0 else _pick_legend()
	if p.is_empty():
		return
	var pos: Vector2 = player.position + Vector2.from_angle(randf() * TAU) * randf_range(380.0, 560.0)
	for i in range(14):
		if not _blocked(pos, 30.0):
			break
		pos = player.position + Vector2.from_angle(randf() * TAU) * randf_range(380.0, 560.0)
	var tys: Array = p["types"]
	var ty: String = String(tys[randi() % tys.size()])
	if not ARENA.THEMES.has(ty):
		ty = "normal"
	var dex: int = int(p["dex"])
	rift = ARENA.Portal.new()
	rift.position = pos
	if den:
		rift.self_modulate = Color(1, 1, 1, 0)   # no se dibuja el torbellino de la grieta: la guarida tiene su propio aspecto
		rift.ttl = DEN_TTL
		rift.add_child(DYN.Den.new())
		rift.add_child(DYN.Pillar.new())
	world.add_child(rift)
	var ar: Node2D = ARENA.new()
	ar.setup(ty, randi() % 100000)
	ar.start_bake()
	rift_info = {"dex": dex, "type": ty, "shiny": (not den) and bool(_sm(dex).get("sh", 0)) and randf() < 1.0 / 512.0, "arena": ar, "den": den}
	Aud.sfx("rift")
	hud.rift_notice = 0.0   # cartel grande como en el original (4,5 s)


func _rift_drop_arena() -> void:
	var ar = rift_info.get("arena")
	if ar != null and is_instance_valid(ar):
		ar.dispose()
	rift_info = {}


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	_rift_drop_arena()


func _update_thief_hud() -> void:
	var lst: Array = []
	if arena == null:
		var ct: Transform2D = get_viewport().get_canvas_transform()
		for e in enemies:
			if is_instance_valid(e) and not e.dead and e.behavior == "thief":
				lst.append({"sp": ct * (e.position + Vector2(0.0, -e.body_h * 0.5)), "name": e.enemy_name,
					"m": roundi((e.position - player.position).length() / ground.TS), "life": maxf(0.0, e.life)})
	hud.thieves_hud = lst


func _update_rift_hud() -> void:
	hud.rift_ttl = -1.0
	hud.legend_frac = -1.0
	if arena != null:
		hud.arena_left = maxf(0.0, ARENA_LIMIT - float(ainfo.get("t", 0.0))) if String(ainfo.get("phase", "")) == "fight" and not bool(ainfo.get("cave", false)) else -1.0
		var b = ainfo.get("boss")
		if b != null and is_instance_valid(b):
			hud.legend_name = b.enemy_name
			hud.legend_frac = clampf(b.hp / maxf(b.max_hp, 1.0), 0.0, 1.0)
		return
	if rift != null and is_instance_valid(rift):
		var to: Vector2 = rift.position - player.position
		var vp: Vector2 = get_viewport_rect().size
		hud.rift_den = bool(rift_info.get("den", false))
		hud.rift_ttl = rift.ttl
		hud.rift_dir = to.normalized()
		hud.rift_scr = get_viewport().get_canvas_transform() * (rift.position + Vector2(0.0, -40.0))
		hud.rift_m = roundi(to.length() / ground.TS)
		hud.rift_off = hud.rift_scr.x < 0.0 or hud.rift_scr.x > vp.x or hud.rift_scr.y < 0.0 or hud.rift_scr.y > vp.y


func _free_list(arr: Array) -> void:
	for x in arr:
		if is_instance_valid(x):
			x.queue_free()
	arr.clear()


func _den_def(dex: int) -> Dictionary:
	var d: Dictionary = _legend_def(dex)
	d["hp"] = 2400.0 + 8.0 * run_time
	d["xp"] = 380.0 + run_time
	d["dyna"] = true
	return d


func _legend_def(dex: int) -> Dictionary:
	var p: Dictionary = _dex_by[dex]
	var t: float = run_time
	var ranged: bool = _has_t(p["types"], ["psychic", "electric", "ghost", "fairy", "fire", "water", "ice", "dragon"])
	return {"dex": dex, "name": String(p["name"]), "hp": 3200.0 + 9.0 * t,
		"spd": clampf(48.0 + (float(p["spd"]) - 78.0) * 0.6, 48.0, 105.0),
		"dmg": 36.0 + t / 20.0, "xp": 500.0 + 1.2 * t,
		"behavior": "ranged" if ranged else "charger", "shotDmg": 18.0 + t / 40.0, "shotCd": 0.9, "range": 300.0}


func _arena_begin() -> void:
	var dex: int = int(rift_info["dex"])
	var ty: String = String(rift_info["type"])
	var new_arena: Node2D = rift_info["arena"]
	ainfo = {"phase": "fight", "t": 0.0, "back": player.position, "dex": dex, "type": ty,
		"shiny": bool(rift_info["shiny"]), "stash_e": enemies.duplicate(), "stash_o": orbs.duplicate(), "end": 0.0, "boss": null, "den": bool(rift_info.get("den", false))}
	for e in enemies:
		e.visible = false
	for o in orbs:
		if is_instance_valid(o):
			o.visible = false
	enemies.clear()
	orbs.clear()
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	if is_instance_valid(rift):
		rift.queue_free()
	rift = null
	rift_info = {}
	ground.visible = false
	arena = new_arena
	arena.position = ARENA_POS
	arena.z_index = -2
	add_child(arena)
	arena.build(world)
	player.position = ARENA_POS + Vector2(0.0, 3.0 * ARENA.TS)
	player_vel = Vector2.ZERO
	var is_den: bool = bool(ainfo.get("den", false))
	var def: Dictionary = _den_def(dex) if is_den else _legend_def(dex)
	var e: Enemy = _make_enemy(def, ARENA_POS + Vector2(0.0, -3.5 * ARENA.TS), {"hp": 1.0, "dmg": 1.0, "spd": 1.0}, true)
	e.legend = true
	e.flying = false
	if is_den:
		e.sprite.scale *= 1.5
		e.body_h *= 1.5
		e.modulate = Color(1.25, 0.8, 0.95)
		var au = DYN.Aura.new()
		au.h = e.body_h
		au.w = e.radius * 1.8
		au.col = Color(0.9, 0.08, 0.25)
		e.add_child(au)
		_ring(e.position, e.radius, e.radius * 6.0, Color("#ff3d6e"), 0.9)
	if bool(ainfo["shiny"]):
		e.make_shiny()
	ainfo["boss"] = e
	var wk: String = String(arena.th.get("weather", ""))
	if wk != "" and TD.WEATHER.has(wk):
		_start_weather(wk, 135.0)
	else:
		wx_kind = ""
		wx.clear()
	Aud.sfx("legend")
	_say((L.t("¡%s Dynamax te desafía!") if is_den else L.t("¡%s te desafía!")) % e.enemy_name, 3.0)
	shake = 10.0


# Entrada a una cueva elemental (cave.gd / cave_int.gd): igual que entrar a una grieta, sin jefe ni limite de tiempo.
func _cave_begin(ci: Node2D, ty: String, owner: String = "cave") -> void:
	ainfo = {"phase": "fight", "t": 0.0, "back": player.position, "dex": 0, "type": ty, "shiny": false,
		"stash_e": enemies.duplicate(), "stash_o": orbs.duplicate(), "end": 0.0, "boss": null, "den": false, "cave": true, "owner": owner}
	for e in enemies:
		e.visible = false
	for o in orbs:
		if is_instance_valid(o):
			o.visible = false
	enemies.clear()
	orbs.clear()
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	ground.visible = false
	arena = ci
	arena.position = ARENA_POS
	arena.z_index = -2
	add_child(arena)
	arena.build(world)
	player.position = ARENA_POS + (Vector2(0.0, 220.0) if owner == "lab" else CVE.CVI.SPAWN)
	player_vel = Vector2.ZERO
	player.invuln = 1.5
	wx_kind = ""
	wx.clear()
	shake = 3.0


# Si no hay enemigos del tipo en la lista actual, usa cualquiera de ese tipo de las primeras etapas
func _cave_type_pool(ty: String) -> Array:
	var out: Array = []
	for ti in range(mini(cast_run.size(), 3)):
		for d in cast_run[ti]["list"]:
			if _has_t(_dex_by[int(d["dex"])]["types"], [ty]):
				out.append(d)
	return out


# El vinculo se elige dentro de la grieta, ya vencido el legendario y recogido el premio, justo antes de salir
func _arena_bond_ready() -> bool:
	return arena != null and not bool(ainfo.get("cave", false)) and String(ainfo.get("phase", "")) == "won"


func _arena_expel() -> void:
	ainfo["phase"] = "lost"
	ainfo["end"] = 1.2
	_say(L.t("La cueva os ha expulsado…") if bool(ainfo.get("cave", false)) else L.t("La grieta os ha expulsado…"), 2.6)
	Aud.sfx("back")


func _update_arena(delta: float) -> void:
	var ph: String = String(ainfo.get("phase", ""))
	if ph == "fight":
		ainfo["t"] = float(ainfo["t"]) + delta
		var b = ainfo["boss"]
		if b == null or not is_instance_valid(b) or b.dead:
			return
		if float(ainfo["t"]) >= ARENA_LIMIT:
			_arena_expel()
	elif ph == "down":
		ainfo["down_t"] = float(ainfo["down_t"]) + delta
		var fa: bool = player.anim == "Faint" and player.frame >= (player._am("Faint")["d"] as Array).size() - 1
		if fa or player.anim != "Faint" or float(ainfo["down_t"]) > 4.0:
			ainfo["fainted"] = float(ainfo["fainted"]) + delta
		# como en el original: un poco despues de caer, la grieta os expulsa
		if float(ainfo["fainted"]) > 1.0:
			_arena_expel()
	elif ph == "lost":
		ainfo["end"] = float(ainfo["end"]) - delta
		if float(ainfo["end"]) <= 0.0:
			_arena_end(false)
	elif ph == "won":
		# v5.2: no se sale de la grieta hasta elegir el vínculo pendiente
		if bonds > 0 and not choosing and not bool(ainfo.get("cave", false)) and _bond_options().is_empty() and not bool(ainfo.get("bond_drop", false)):
			# Sin movimientos que vincular, el vínculo ganado en la grieta se quita en vez de quedarse guardado
			ainfo["bond_drop"] = true
			bonds -= 1
			_say(L.t("No quedan movimientos que vincular: el vínculo se descarta"), 3.0)
		var bond_wait: bool = not bool(ainfo.get("cave", false)) and (choosing or (bonds > 0 and not _bond_options().is_empty()))
		if not bond_wait or float(ainfo["end"]) > 2.0:
			ainfo["end"] = float(ainfo["end"]) - delta
		if float(ainfo["end"]) <= 0.0:
			_arena_end(true)


func progress_event(ev: String, _d = null) -> void:
	if ev == "judge":
		PG.check()


# Viaje a la arena de la Sentencia (judgment.gd): igual que entrar a una grieta.
func _jd_port(new_arena: Node2D) -> void:
	ainfo = {"phase": "cine", "back": player.position, "stash_e": enemies.duplicate(), "stash_o": orbs.duplicate()}
	for e in enemies:
		e.visible = false
	for o in orbs:
		if is_instance_valid(o):
			o.visible = false
	enemies.clear()
	orbs.clear()
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	if is_instance_valid(rift):
		rift.queue_free()
	rift = null
	_rift_drop_arena()
	ground.visible = false
	arena = new_arena
	arena.position = ARENA_POS
	arena.z_index = -2
	add_child(arena)
	arena.build(world)
	wx_kind = ""
	wx.clear()


func _legend_down(e) -> void:
	if arena == null or String(ainfo.get("phase", "")) != "fight":
		return
	if bool(ainfo.get("den", false)):
		_den_down(e)
		return
	ainfo["phase"] = "won"
	ainfo["end"] = 5.0
	var pos: Vector2 = e.position
	var dex: int = int(ainfo["dex"])
	var lg: Dictionary = SV.d.get("legends", {})
	lg[str(dex)] = int(lg.get(str(dex), 0)) + 1
	SV.d["legends"] = lg
	var ar: Dictionary = SV.d.get("arenas", {})
	ar[String(ainfo["type"])] = int(ar.get(String(ainfo["type"]), 0)) + 1
	SV.d["arenas"] = ar
	if bool(ainfo["shiny"]):
		var ls: Dictionary = SV.d.get("lshiny", {})
		ls[str(dex)] = true
		SV.d["lshiny"] = ls
		Aud.sfx("shiny")
	var st: Dictionary = SV.d["stats"]
	st["rifts"] = int(st.get("rifts", 0)) + 1
	run_rifts += 1
	SV.save()
	PG.event("rift", {"type": String(ainfo["type"])})
	var n := 14
	var per: float = ceilf(e.xp_val / float(n))
	var made: Array = []
	for k in range(n):
		made.append(_spawn_orb(pos, "xpBig", per))
	made.append(_spawn_orb(pos + Vector2(24.0, 0.0), "item", 0.0))
	made.append(_spawn_orb(pos + Vector2(-24.0, 0.0), "ticket", 2.0))
	if randf() < 0.3:
		made.append(_spawn_orb(pos + Vector2(0.0, 24.0), "ticket10", 1.0))
	for k in range(10):
		made.append(_spawn_orb(pos, "coin", 10.0))
	made.append(_spawn_orb(pos + Vector2(0.0, -24.0), "heal", 0.0))
	for o in made:
		if o != null and is_instance_valid(o):
			o.pulled = true
	bonds += 1
	Aud.sfx("bossDown")
	# Como el original: aviso de victoria y "¡Vínculo!" sobre el jugador (la eleccion llega al volver de la grieta)
	_say(L.t("¡Has vencido a {x}! Recoge el premio…").replace("{x}", String(e.enemy_name)), 3.4)
	add_text(player.position + Vector2(0.0, -player.body_h - 10.0), L.t("¡Vínculo!"), Color("#ff8ad8"), 26)
	_ring(player.position, 8.0, 90.0, Color("#ff8ad8"), 0.7)
	shake = 12.0


# Victoria en una guarida Dynamax: premio, Caramelo Dynamax (recarga el Dynamax) y, la primera vez, lo desbloquea.
func _den_down(e) -> void:
	ainfo["phase"] = "won"
	ainfo["end"] = 5.0
	var pos: Vector2 = e.position
	var st: Dictionary = SV.d["stats"]
	var first: bool = int(st.get("dens", 0)) == 0
	st["dens"] = int(st.get("dens", 0)) + 1
	run_dens += 1
	SV.save()
	var n := 12
	var per: float = ceilf(e.xp_val / float(n))
	var made: Array = []
	for k in range(n):
		made.append(_spawn_orb(pos, "xpBig", per))
	made.append(_spawn_orb(pos + Vector2(24.0, 0.0), "item", 0.0))
	made.append(_spawn_orb(pos + Vector2(-24.0, 0.0), "item", 0.0))
	made.append(_spawn_orb(pos + Vector2(0.0, 24.0), "ticket", 1.0))
	for k in range(12):
		made.append(_spawn_orb(pos, "coin", 10.0))
	made.append(_spawn_orb(pos + Vector2(0.0, -24.0), "heal", 0.0))
	for o in made:
		if o != null and is_instance_valid(o):
			o.pulled = true
	dyn_used = false
	dyn_cd = 0.0
	Aud.sfx("bossDown")
	if first:
		_say(L.t("¡Has desbloqueado el Dynamax! Botón MAX, tecla C o gatillo izquierdo (desde el minuto 3)"), 4.2)
	else:
		_say(L.t("¡Guarida superada! Caramelo Dynamax: puedes usar el Dynamax otra vez"), 3.6)
	add_text(player.position + Vector2(0.0, -player.body_h - 10.0), "DYNAMAX", Color("#ff3d6e"), 26)
	_ring(player.position, 8.0, 110.0, Color("#ff3d6e"), 0.7)
	shake = 12.0


func _arena_end(won: bool, timeout: bool = false) -> void:
	if arena == null:
		return
	var back: Vector2 = ainfo["back"]
	var was_cave: bool = bool(ainfo.get("cave", false))
	var was_owner: String = String(ainfo.get("owner", "cave"))
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_free_list(orbs)
	arena.clear_props()
	arena.queue_free()
	arena = null
	ground.visible = true
	wx_kind = ""
	wx.clear()
	for e in ainfo["stash_e"]:
		if is_instance_valid(e) and not e.dead:
			e.visible = true
			enemies.append(e)
	for o in ainfo["stash_o"]:
		if is_instance_valid(o):
			o.visible = true
			orbs.append(o)
	player.position = _free_spot(back, 14.0)
	player_vel = Vector2.ZERO
	player.invuln = 1.5
	if arena_down:
		arena_down = false
		player.active = true
		player.hold = false
		player.once = false
		player.play("Idle", 1.0)
	if not won:
		player.hp = maxf(player.hp, player.max_hp * 0.3)
		_ring(player.position, 8.0, 90.0, Color("#c9a6ff"), 0.8)
	ainfo = {}
	if was_cave:
		if was_owner == "lab":
			mew.on_leave(won)
		else:
			cave.on_leave(won)
	if won and not was_cave and bonds > 0 and _bond_options().is_empty():
		_say(L.t("Guardas el vínculo: aprende otro movimiento para usarlo"), 3.0)
	rift_check = 6.0 if mode == "rifts" else RIFT_EVERY
	rift_miss = 0
	_update_world(0.0)
	shake = 0.0
	if mode != "rifts":
		ret_cd = 3.0
		ret_last = 4


func _start_weather(kind: String, dur: float) -> void:
	wx_kind = kind
	wx_t = 0.0
	wx_dur = dur
	wx_banner = 3.4
	wx.setup(TD.WEATHER[kind])


func _update_weather(delta: float) -> void:
	wx_banner = maxf(0.0, wx_banner - delta)
	if wx_kind != "":
		wx_t += delta
		if wx_t >= wx_dur:
			wx_kind = ""
			wx.clear()
	elif run_time > 120.0 and arena == null:
		wx_check -= delta
		if wx_check <= 0.0:
			wx_check = 60.0
			if randf() < 0.18:
				var w: Dictionary = TD.BIOME_W[mini(biome_idx, 2)]
				var total: float = 0.0
				for k in w:
					total += float(w[k])
				var roll: float = randf() * total
				var pick: String = "rain"
				for k in w:
					roll -= float(w[k])
					if roll <= 0.0:
						pick = String(k)
						break
				_start_weather(pick, roundf(randf_range(55.0, 75.0)))
	# Arena y nieve: te van quitando un poco de vida (nunca te dejan KO).
	wx_chip -= delta
	if wx_chip <= 0.0:
		wx_chip = 2.0
		if wx_kind != "" and _wx_level() > 0.5:
			var wc := Color.html(String(TD.WEATHER[wx_kind]["color"]))
			if _weather_hurts(player.types) and not _has_item("safetygoggles") and _abn("wximm") == 0.0:
				var d: float = maxf(1.0, player.max_hp * 0.012)
				if player.hp > d + 1.0:
					player.hp -= d
					add_text(player.position + Vector2(0.0, -player.body_h - 4.0), "-" + str(roundi(d)), wc)
			for e in enemies:
				if e.dead or not _weather_hurts(e.types):
					continue
				if e.hurt_by(e.max_hp * 0.02 + 1.0):
					kills += 1
					if tw_risk.has("l_reap"):
						reap_kills += 1
					_drop(e)


func add_text(pos: Vector2, text: String, color: Color, size: int = 18) -> void:
	if not dmg_on and (text.is_valid_int() or (text.begins_with("-") and text.substr(1).is_valid_int())):
		return
	var cap: int = [80, 28, 10][perf_lv]
	if Floater.alive >= cap and size < 24:
		return   # demasiados numeros a la vez: se omiten los pequenos
	var f := Floater.new()
	f.text = L.t(text)
	f.size = size
	f.color = color
	f.position = pos
	f.plain = perf_lv > 0
	fx.add_child(f)


# ---------------------------------------------------------------
# Actor: sprite + animacion + sombra + destello (jugador y enemigos)
# ---------------------------------------------------------------
class Actor extends Node2D:
	const SPR_K := 1.12   # jugador y Pokemon salvajes un 12 % mas grandes (solo el dibujo; el area de choque no cambia)
	const PX := 2.0               # unidades de mundo por pixel de arte

	var dex := 0
	var smeta: Dictionary = {}
	var meta: Dictionary = {}     # animacion -> geometria
	var shiny := false
	var scl := 1.0
	var sprite := Sprite2D.new()
	var mat := ShaderMaterial.new()
	var textures := {}
	var anim := "Idle"
	var base := "Idle"
	var once := false
	var hold := false
	var frame := 0
	var t := 0.0
	var anim_speed := 1.0
	var dir := 0                  # fila: 0 Down,1 DownRight,2 Right,3 UpRight,4 Up,5 UpLeft,6 Left,7 DownLeft
	var radius := 12.0
	var body_h := 40.0
	var shadow_rx := 16.0
	static var flash_k := 1.0
	var flash := 0.0
	var fade := -1.0
	var active := true
	var hover := false
	var bob := 0.0
	var lift_extra := 0.0
	var dirty := true

	func setup(d: int, sm: Dictionary, shader: Shader, s: float = 1.0, shn: bool = false) -> void:
		dex = d
		smeta = sm
		meta = sm["a"]
		scl = s
		shiny = shn
		hover = bool(sm.get("hv", 0))
		mat.shader = shader
		sprite.material = mat
		sprite.centered = false
		sprite.region_enabled = true
		sprite.scale = Vector2(PX * scl * SPR_K, PX * scl * SPR_K)
		add_child(sprite)
		var idle: Dictionary = meta["Idle"] if meta.has("Idle") else meta["Walk"]
		radius = clampf(float(idle["w"]) * 0.22, 5.0, 26.0) * PX * scl
		body_h = float(idle["ay"]) * PX * scl * SPR_K
		var sizes := [5.0, 8.0, 12.0]
		shadow_rx = float(sizes[clampi(int(sm.get("s", 1)), 0, 2)]) * PX * scl * SPR_K
		if not meta.has("Idle"):
			anim = "Walk"
			base = "Walk"
		_apply()
		queue_redraw()

	# Cambia el cuerpo (sprite y medidas) por otro Pokemon sin recrear el nodo (Modo Equipo).
	func rebody(d: int, sm: Dictionary, shn: bool = false) -> void:
		dex = d
		smeta = sm
		meta = sm["a"]
		shiny = shn
		hover = bool(sm.get("hv", 0))
		textures.clear()
		once = false
		hold = false
		frame = 0
		t = 0.0
		anim = "Idle"
		base = "Idle"
		var idle: Dictionary = meta["Idle"] if meta.has("Idle") else meta["Walk"]
		radius = clampf(float(idle["w"]) * 0.22, 5.0, 26.0) * PX * scl
		body_h = float(idle["ay"]) * PX * scl * SPR_K
		var sizes := [5.0, 8.0, 12.0]
		shadow_rx = float(sizes[clampi(int(sm.get("s", 1)), 0, 2)]) * PX * scl * SPR_K
		if not meta.has("Idle"):
			anim = "Walk"
			base = "Walk"
		dirty = true
		_apply()
		queue_redraw()

	func set_shiny() -> void:
		shiny = true
		textures.clear()
		dirty = true
		_apply()

	func _am(a: String) -> Dictionary:
		if shiny and smeta.has("sa") and (smeta["sa"] as Dictionary).has(a):
			return smeta["sa"][a]
		return meta[a]

	func _tex_path(a: String, shn: bool) -> String:
		if shn:
			return "res://assets/pokemon/%d/s/%s.png" % [dex, a]
		return "res://assets/pokemon/%d/%s.png" % [dex, a]

	func _tex(a: String) -> Texture2D:
		if not textures.has(a):
			var tx: Texture2D = null
			if shiny:
				var ps: String = _tex_path(a, true)
				if ResourceLoader.exists(ps):
					tx = load(ps)
			if tx == null:
				var p: String = _tex_path(a, false)
				if ResourceLoader.exists(p):
					tx = load(p)
			textures[a] = tx
		return textures[a]

	func has_anim(a: String) -> bool:
		return meta.has(a) and _tex(a) != null

	func face_angle(a: float) -> void:
		var nd: int = posmod(int(floor((PI / 2.0 - a) / (PI / 4.0) + 0.5)), 8)
		if nd != dir:
			dir = nd
			dirty = true

	func _start(a: String) -> void:
		anim = a
		frame = 0
		t = 0.0
		dirty = true

	func loop_anim(a: String, spd: float) -> void:
		if not has_anim(a):
			a = "Idle" if has_anim("Idle") else "Walk"
		base = a
		if not once and anim != a:
			_start(a)
		if not once:
			anim_speed = spd

	func progress() -> float:
		var am: Dictionary = _am(anim)
		var total := 0.0
		var before := 0.0
		var i := 0
		for dd in am["d"]:
			if i < frame:
				before += float(dd)
			total += float(dd)
			i += 1
		if total <= 0.0:
			return 1.0
		return (before + t) / total

	# Reproduce una animacion una vez y vuelve a la base (hold: se queda en el ultimo fotograma).
	func play(a: String, spd: float = 1.0, hld: bool = false) -> void:
		if not has_anim(a):
			return
		if once and not hold and progress() < 0.65 and not hld:
			return
		_start(a)
		once = true
		hold = hld
		anim_speed = spd

	func play_attack(a: String, cd: float) -> void:
		if not has_anim(a):
			return
		if once and progress() < 0.65:
			return
		var am: Dictionary = _am(a)
		var total := 0.0
		for dd in am["d"]:
			total += float(dd)
		var dur: float = total / 60.0
		_start(a)
		once = true
		hold = false
		anim_speed = maxf(1.0, dur / (maxf(0.12, cd) * 0.9))

	func tick_anim(delta: float) -> void:
		var am: Dictionary = _am(anim)
		var before_f: int = frame
		t += delta * 60.0 * anim_speed
		var guard := 0
		while t >= float(am["d"][frame]) and guard < 16:
			guard += 1
			t -= float(am["d"][frame])
			frame += 1
			if frame >= int(am["n"]):
				if hold:
					frame = int(am["n"]) - 1
					t = 0.0
					break
				elif once:
					once = false
					anim = base
					frame = 0
					t = 0.0
					anim_speed = 1.0
					am = _am(anim)
				else:
					frame = 0
		if frame != before_f or guard > 0:
			dirty = true
		_apply()

	func _apply() -> void:
		var py: float = -(lift_extra + (sin(bob) * 3.0 if hover else 0.0) + (6.0 if hover else 0.0))
		sprite.position.y = py
		if not dirty:
			return
		dirty = false
		var am: Dictionary = _am(anim)
		var tx: Texture2D = _tex(anim)
		if tx == null:
			tx = _tex(base) if _tex(base) != null else null
			if tx == null and meta.has("Idle"):
				tx = _tex("Idle")
		sprite.texture = tx
		sprite.visible = tx != null
		sprite.offset = Vector2(-float(am["ax"]), -float(am["ay"]))
		sprite.region_rect = Rect2(frame * float(am["w"]), minf(dir, float(am.get("r", 8)) - 1.0) * float(am["h"]), float(am["w"]), float(am["h"]))

	func _process(delta: float) -> void:
		bob += delta * 6.0
		if fade >= 0.0:
			fade -= delta
			modulate.a = clampf(fade / 0.5, 0.0, 1.0)
			if once or hold:
				tick_anim(delta)
			if fade <= 0.0:
				queue_free()
			return
		if flash > 0.0:
			flash = maxf(0.0, flash - delta * 8.0)
			mat.set_shader_parameter("flash", flash * flash_k)
		if (active or hold) and not meta.is_empty():   # hold: la animacion de muerte sigue aunque el actor este inactivo
			tick_anim(delta)
		elif hover or lift_extra != 0.0:
			_apply()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, shadow_rx, Color(0, 0, 0, 0.34))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Player extends Actor:
	var hp := 1.0
	var max_hp := 1.0
	var spd := 100.0
	var atk := 1.0
	var types: Array = []
	var invuln := 0.0
	var dead := false
	var aim := PI / 2.0
	var attack_face := 0.0
	var level := 1
	var xp := 0.0
	var xp_next := 62.0
	var moves: Array = []
	var slot := 0
	var orb_cast_t := 0.0
	var last_patch = null
	var buffs := {
		"atk": {"n": 0, "amount": 0.0, "t": 0.0, "ts": []},
		"spd": {"n": 0, "amount": 0.0, "t": 0.0, "ts": []},
		"def": {"n": 0, "amount": 0.0, "t": 0.0, "ts": []},
		"regen": {"n": 0, "amount": 0.0, "t": 0.0, "ts": []},
	}


class AimMark extends Node2D:
	var m = null

	func _process(_d: float) -> void:
		var on: bool = m != null and m.aim_manual and not m.player.dead
		if on != visible:
			visible = on
		if on:
			position = m.player.position
			queue_redraw()

	func _draw() -> void:
		var d := Vector2.from_angle(m.aim_ang)
		var c := Vector2(0.0, -14.0)
		var p0: Vector2 = c + d * 64.0
		var p1: Vector2 = c + d * 84.0
		var n := Vector2(-d.y, d.x)
		draw_line(c + d * 40.0, p0, Color(1, 1, 1, 0.35), 2.0)
		draw_colored_polygon(PackedVector2Array([p1, p0 + n * 8.0, p0 - n * 8.0]), Color(1, 0.95, 0.5, 0.85))


class Legend extends Actor:
	var m = null
	var alpha := false
	var hp := 1.0
	var max_hp := 1.0
	var dmg := 20.0
	var ltype := "normal"
	var col := Color("#ffd23f")
	var lname := ""
	var boss_moves: Array = []
	var moving := false
	var dead := false
	var atk_t := 1.0
	var hit_t := 0.0
	var n_hits := 0
	var bolt_pos := Vector2.ZERO
	var bolt_t := 0.0
	var tt := 0.0

	func hurt(a: float) -> void:
		hp -= a   # sin curacion: solo baja
		flash = 1.0
		if hp <= 0.0:
			hp = 0.0
			dead = true

	func fx_line(p: Vector2) -> void:
		bolt_pos = p
		bolt_t = 0.3

	func _process(delta: float) -> void:
		super._process(delta)
		tt += delta
		if bolt_t > 0.0:
			bolt_t -= delta
		queue_redraw()

	func _draw() -> void:
		super._draw()
		# aura giratoria de runas doradas
		for i in range(6):
			var an: float = tt * 1.4 + float(i) * TAU / 6.0
			var pt := Vector2(cos(an) * (radius + 16.0), sin(an) * (radius + 16.0) * 0.45 - 4.0)
			draw_rect(Rect2(pt - Vector2(2, 2), Vector2(4, 4)), Color(col.r, col.g, col.b, 0.85))
		# rayo del ataque (cae del cielo sobre el objetivo)
		if bolt_t > 0.0:
			var l: Vector2 = bolt_pos - position
			var k: float = bolt_t / 0.3
			draw_line(l + Vector2(0.0, -420.0), l, Color(col.r, col.g, col.b, k), 6.0 * k + 1.0)
			draw_line(l + Vector2(0.0, -420.0), l, Color(1, 1, 1, k), 2.0)
		# barra de vida y nombre
		var w := 56.0
		var y: float = -body_h - 14.0
		draw_rect(Rect2(-w * 0.5 - 1.0, y - 1.0, w + 2.0, 8.0), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 6.0), Color("#ffd23f"))
		draw_string(ThemeDB.fallback_font, Vector2(-w * 0.5, y - 5.0), lname, HORIZONTAL_ALIGNMENT_LEFT, 120, 11, Color.WHITE)


# Aura azul circular del escudo del jugador (escudo del descanso de la Torre). Sigue al valor real del escudo
# y desaparece sola al agotarse, al morir o al reiniciar (el nodo es hijo del jugador).
class ShieldAura extends Node2D:
	var m = null
	var t := 0.0

	func _process(d: float) -> void:
		var on: bool = m != null and m.tw_shield > 0.0 and not m.player.dead
		if on != visible:
			visible = on
		if on:
			t += d
			queue_redraw()

	func _draw() -> void:
		var r: float = maxf(m.player.radius, m.player.body_h * 0.5) + 12.0
		var f: float = clampf(m.tw_shield / maxf(1.0, m.player.max_hp * 0.35), 0.0, 1.0)
		bubble(self, Vector2(0.0, -m.player.body_h * 0.5), r, t, f)

	# Burbuja brillante: interior en degradado (mas opaco hacia el borde), borde irisado, reflejos y destellos.
	# f (0..1) = cuanto escudo queda: con poco, parpadea para avisar de que se rompe.
	static func bubble(ci: CanvasItem, c: Vector2, r: float, t: float, f: float = 1.0) -> void:
		var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
		var warn: float = 1.0
		if f < 0.3:
			warn = 0.55 + 0.45 * absf(sin(t * 9.0))
		var rr: float = r * (1.0 + 0.015 * pulse)
		# relleno: capas concentricas, el centro casi transparente y el borde lleno de color
		for i in 7:
			var k: float = float(i) / 6.0
			var rad: float = rr * (1.0 - k * 0.55)
			ci.draw_circle(c, rad, Color(0.30 + 0.25 * k, 0.62 + 0.2 * k, 1.0, (0.035 + 0.02 * pulse) * warn))
		# borde irisado: segmentos con tono que rota (azul, cian, violeta suave)
		var seg := 36
		for i in seg:
			var a0: float = TAU * float(i) / float(seg) + t * 0.6
			var a1: float = TAU * float(i + 1) / float(seg) + t * 0.6 + 0.02
			var hue: float = 0.56 + 0.11 * sin(a0 * 2.0 + t * 1.5)
			var col := Color.from_hsv(hue, 0.55, 1.0, (0.62 + 0.25 * sin(a0 * 3.0 - t * 2.0) * 0.5 + 0.1) * warn)
			ci.draw_arc(c, rr, a0, a1, 3, col, 3.2)
		ci.draw_arc(c, rr - 3.5, 0.0, TAU, 40, Color(0.7, 0.9, 1.0, 0.22 * warn), 2.0)
		ci.draw_arc(c, rr + 2.5, 0.0, TAU, 40, Color(0.4, 0.7, 1.0, 0.18 * warn), 2.0)
		# reflejos de luz (arriba-izquierda) y rebote (abajo-derecha)
		ci.draw_arc(c, rr * 0.78, PI * 1.08, PI * 1.42, 10, Color(1, 1, 1, 0.85 * warn), 4.0)
		ci.draw_arc(c, rr * 0.78, PI * 1.5, PI * 1.58, 4, Color(1, 1, 1, 0.7 * warn), 4.0)
		ci.draw_arc(c, rr * 0.8, PI * 0.12, PI * 0.3, 6, Color(0.85, 0.95, 1.0, 0.45 * warn), 3.0)
		ci.draw_circle(c + Vector2(-rr * 0.52, -rr * 0.58), maxf(2.0, rr * 0.07), Color(1, 1, 1, 0.9 * warn))
		# destellos que orbitan el borde
		for j in 3:
			var ang: float = t * 1.3 + TAU * float(j) / 3.0
			var p: Vector2 = c + Vector2.from_angle(ang) * rr
			var tw: float = 0.5 + 0.5 * sin(t * 5.0 + float(j) * 2.0)
			var sz: float = 2.0 + 2.5 * tw
			ci.draw_line(p - Vector2(sz, 0), p + Vector2(sz, 0), Color(1, 1, 1, 0.9 * tw * warn), 1.5)
			ci.draw_line(p - Vector2(0, sz), p + Vector2(0, sz), Color(1, 1, 1, 0.9 * tw * warn), 1.5)


# Gotas de veneno que "sudan" por el cuerpo del enemigo envenenado y resbalan hacia abajo
class PoisonSweat extends Node2D:
	var e = null

	func _process(_d: float) -> void:
		var on: bool = e != null and not e.dead and e.poison > 0
		if on != visible:
			visible = on
		if on:
			queue_redraw()

	func _draw() -> void:
		if e == null:
			return
		var n: int = 4 + mini(4, int(e.poison))
		var t: float = e.bob
		for i in range(n):
			var u: float = float(i) * 2.399
			var bx: float = sin(u) * e.radius * 0.85
			var slide: float = fmod(t * 2.2 + float(i) * 1.7, 5.0) / 5.0   # 0..1: nace en el cuerpo y resbala
			var by: float = -e.body_h * (0.22 + 0.62 * fposmod(sin(u * 1.7) * 0.5 + 0.5, 1.0)) + slide * 11.0
			var a: float = clampf(1.0 - slide * slide, 0.0, 1.0) * 0.95
			var r: float = 2.0 + 1.3 * (1.0 - slide)
			draw_circle(Vector2(bx, by), r + 1.0, Color(0.25, 0.05, 0.35, a * 0.7))
			draw_circle(Vector2(bx, by), r, Color(0.72, 0.3, 0.95, a))
			draw_circle(Vector2(bx - 0.7, by - 0.8), r * 0.4, Color(0.97, 0.85, 1.0, a))
			# cola de la gota al resbalar
			if slide > 0.15:
				draw_line(Vector2(bx, by - r), Vector2(bx, by - r - slide * 5.0), Color(0.6, 0.22, 0.85, a * 0.55), 1.5)


class Enemy extends Actor:
	var judge := false
	var hp := 10.0
	var max_hp := 10.0
	var spd := 50.0
	var dmg := 5.0
	var touch_cd := 0.0
	var dead := false
	var knock := Vector2.ZERO
	var enemy_name := ""
	var xp_val := 20.0
	var types: Array = ["normal"]
	var atk_type := "normal"
	var burn := 0
	var burn_t := 0.0
	var burn_tick := 0.0
	var poison := 0
	var poison_t := 0.0
	var poison_tick := 0.0
	var poison_fx := 0.0
	var slow := 0.0
	var slow_t := 0.0
	var def: Dictionary = {}
	var boss := false
	var legend := false
	var behavior := "chase"
	var flying := false
	var sc: Dictionary = {}
	var shot_cd := 1.0
	var skill_cd := 2.0
	var shield := 0.0
	var shield_t := 0.0
	var shield_lock := 0.0   # tras un escudo no se le puede poner otro hasta que pase
	var is_minion := false
	var minions: Array = []
	var jump = null
	var phase := "walk"
	var pt := 0.0
	var dash_dir := Vector2.RIGHT
	var zig := 0.0
	var life := -1.0
	var golden := false
	var ai: Dictionary = {}
	var lava_t := 0.0
	var frozen_t := 0.0
	var para_t := 0.0
	var sleep_t := 0.0
	var conf_t := 0.0
	var charm_t := 0.0
	var charm_imm := 0.0
	var conf_cd := 0.0
	var cc_imm := 0.0
	var cc_fx := 0.0

	var burn_k := 0.0

	func apply_burn(n: int) -> void:
		if burn <= 0 and burn_k <= 0.0:
			# Quemado: el enemigo hace menos daño (menos contra jefes).
			burn_k = 0.85 if boss else 0.75
			dmg *= burn_k
		burn = mini(8, burn + n)
		burn_t = 3.0

	var sweat: Node2D = null

	func apply_poison(n: int) -> void:
		poison = mini(6, poison + n)
		poison_t = 4.0
		if sweat == null:
			sweat = PoisonSweat.new()
			sweat.e = self
			add_child(sweat)   # va despues del sprite: se dibuja encima

	func apply_slow(f: float, dur: float = 1.2) -> void:
		slow = maxf(slow, f)
		slow_t = maxf(slow_t, dur)

	func make_shiny() -> void:
		set_shiny()
		max_hp *= 2.0
		hp = max_hp
		xp_val *= 5.0

	func make_golden() -> void:
		if golden:
			return
		golden = true
		xp_val *= 2.0
		queue_redraw()

	# Duende del tesoro (Meowth / Gholdengo): halo dorado que late, charco de luz en el suelo y destellos.
	func _draw_treasure_glow() -> void:
		var t: float = float(Time.get_ticks_msec()) * 0.001
		var beat: float = 0.5 + 0.5 * sin(t * 6.0 + bob)
		var c := Vector2(0.0, -body_h * 0.5)
		var rr: float = maxf(radius, body_h * 0.5) + 6.0
		for i in range(4):
			var k: float = float(i) / 3.0
			draw_circle(c, rr * (1.9 - k * 0.9) + beat * 4.0, Color(1.0, 0.85, 0.3, 0.05 + 0.05 * k + 0.04 * beat))
		var pts := PackedVector2Array()
		for i in range(24):
			var a: float = TAU * float(i) / 24.0
			pts.append(Vector2(cos(a) * radius * 1.8, sin(a) * radius * 0.65))
		draw_colored_polygon(pts, Color(1.0, 0.82, 0.25, 0.30 + 0.12 * beat))
		draw_arc(c, rr, 0.0, TAU, 28, Color(1.0, 0.9, 0.4, 0.55 + 0.35 * beat), 2.0)
		for i in range(5):
			var a2: float = t * 1.6 + TAU * float(i) / 5.0
			var sp: Vector2 = c + Vector2(cos(a2), sin(a2) * 0.8) * (rr + 6.0 + 5.0 * sin(t * 4.0 + float(i)))
			var sz: float = 2.0 + 2.0 * (0.5 + 0.5 * sin(t * 7.0 + float(i) * 1.7))
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -sz * 1.6), sp + Vector2(sz * 0.5, 0), sp + Vector2(0, sz * 1.6), sp + Vector2(-sz * 0.5, 0)]), Color(1.0, 0.97, 0.7, 0.95))
			draw_colored_polygon(PackedVector2Array([sp + Vector2(-sz * 1.6, 0), sp + Vector2(0, sz * 0.5), sp + Vector2(sz * 1.6, 0), sp + Vector2(0, -sz * 0.5)]), Color(1.0, 0.97, 0.7, 0.95))
		queue_redraw()

	func strike(angle: float) -> void:
		face_angle(angle)
		play("Attack", 1.3)

	# Devuelve true si este golpe lo derrota.
	func hurt_by(amount: float) -> bool:
		hp -= amount
		flash = 1.0
		queue_redraw()
		if hp <= 0.0:
			hp = 0.0
			dead = true
			fade = 0.9
			play("Faint", 1.0, true)
			return true
		return false

	func _draw() -> void:
		super._draw()
		if dead:
			return
		if behavior == "thief":
			_draw_treasure_glow()
		elif golden:
			draw_arc(Vector2(0.0, -body_h * 0.5), radius + 4.0, 0.0, TAU, 20, Color(1.0, 0.82, 0.25, 0.7), 2.0)
		if shield > 0.0:
			var sr: float = maxf(radius, body_h * 0.5) + 6.0
			ShieldAura.bubble(self, Vector2(0.0, -body_h * 0.5), sr, bob * 2.0 + float(get_instance_id() % 7), clampf(shield_t / 3.0, 0.0, 1.0))
		if boss:
			# S62.2: contorno discreto para que los jefes no se pierdan bajo los efectos amigos
			draw_arc(Vector2(0.0, -body_h * 0.5), maxf(radius, body_h * 0.5) + 4.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.3, 0.55), 2.0)
			var bw := 90.0
			var by: float = -body_h - 14.0
			draw_rect(Rect2(-bw * 0.5, by, bw, 6.0), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(-bw * 0.5, by, bw * clampf(hp / max_hp, 0.0, 1.0), 6.0), Color("#ffd23f"))
		elif hp < max_hp:
			var w := 30.0
			var y := -body_h - 12.0
			draw_rect(Rect2(-w * 0.5, y, w, 4.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color("#ff6b7a"))
		if behavior == "healer" or behavior == "shielder":
			# Icono sobre la cabeza: corazon = cura, escudo = da escudo
			var ip := Vector2(0.0, -body_h - (30.0 if boss else 28.0))
			draw_circle(ip, 10.0, Color(0.05, 0.08, 0.16, 0.65))
			IC.draw_in(self, "heart" if behavior == "healer" else "shield", ip, 17.0)
		elif behavior == "summoner":
			draw_circle(Vector2(0.0, -body_h - (22.0 if boss else 20.0)), 4.0, Color("#c47bff"))


# Aviso en el suelo (hazards.js): zona circular o rayo; hace dano al cumplirse el retraso.
class Hazard extends Node2D:
	var kind := "zone"
	var r := 40.0
	var angle := 0.0
	var length := 300.0
	var width := 20.0
	var delay := 1.0
	var dmg := 10.0
	var mtype := "normal"
	var color := Color("#ff7a9e")
	var t := 0.0
	var hit := false
	var slows := false
	var pct := 0.0
	var pure := false
	var vis := ""
	var ally_dmg := 0.0   # >0: ataque de un aliado capturado; daña a los enemigos en vez de al jugador

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if hit:
			return
		var k: float = clampf(t / maxf(0.01, delay), 0.0, 1.0)
		var warn := Color(color.r, color.g, color.b, 0.16 + 0.22 * k)
		var edge := Color(color.r, color.g, color.b, 0.75)
		if kind == "zone":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.8))
			draw_circle(Vector2.ZERO, r, warn)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, edge, 2.0)
			draw_circle(Vector2.ZERO, r * k, Color(color.r, color.g, color.b, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var d := Vector2.from_angle(angle)
			var n := Vector2(-d.y, d.x) * width * 0.5
			var p1: Vector2 = d * length
			draw_colored_polygon(PackedVector2Array([n, p1 + n, p1 - n, -n]), warn)
			draw_line(n, p1 + n, edge, 2.0)
			draw_line(-n, p1 - n, edge, 2.0)
			var q: Vector2 = d * length * k
			draw_colored_polygon(PackedVector2Array([n, q + n, q - n, -n]), Color(color.r, color.g, color.b, 0.3))


# Disparo enemigo
class EBullet extends Node2D:
	var vel := Vector2.ZERO
	var dmg := 5.0
	var mtype := "normal"
	var color := Color("#ff7a9e")
	var age := 0.0

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.235, 0.314, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var v: Dictionary = VFX.for_type(mtype)
		var sh: String = String(v["proj"])
		var ang := 0.0
		if VFX.is_dir(sh):
			ang = vel.angle()
		elif VFX.spins(sh):
			ang = age * 9.0
		VFX.draw(self, sh, String(v["pal"]), Vector2(0.0, -18.0), ang, 1.0, int(age * 12.0), 1.0)
		return
		draw_circle(Vector2(0.0, -18.0), 8.0, Color(color.r, color.g, color.b, 0.35))
		draw_circle(Vector2(0.0, -18.0), 5.0, color)
		draw_circle(Vector2(-1.0, -19.0), 2.0, Color(1, 1, 1, 0.85))


# --- dibujo ---
class WTex:
	const SC := 2.4   # objetos del mundo (cofres, altares, fuentes...) un 20 % mas pequenos
	static var cache := {}

	static func get_t(n: String) -> Texture2D:
		if not cache.has(n):
			var p: String = "res://assets/world/%s.png" % n
			cache[n] = load(p) if ResourceLoader.exists(p) else null
		return cache[n]


class Decor extends Node2D:
	var items: Array = []
	var done := false

	func _process(_d: float) -> void:
		if not done:
			done = true
			queue_redraw()
		set_process(false)

	func _draw() -> void:
		for it in items:
			var tx: Texture2D = WTex.get_t(String(it[0]))
			if tx == null:
				continue
			var p: Vector2 = it[1]
			var sz := Vector2(tx.get_width(), tx.get_height()) * WTex.SC
			draw_texture_rect(tx, Rect2(p - sz * 0.5, sz), false)


class Pool extends Node2D:
	var kind := "water"
	var variant := 0
	var tex: Texture2D = null
	var img: Image = null
	var r := 100.0
	var tw := 0
	var th := 0

	func setup(k: String, v: int) -> void:
		kind = k
		variant = v
		tex = WTex.get_t("pool_%s_%d" % [k, v])
		if tex != null:
			img = tex.get_image()
			tw = tex.get_width()
			th = tex.get_height()
			r = float(maxi(tw, th)) * WTex.SC * 0.5
		else:
			r = 100.0

	func contains(p: Vector2) -> bool:
		var d: Vector2 = p - position
		if tex == null or img == null:
			var kx: float = d.x / r
			var ky: float = d.y / (r * 0.8)
			return kx * kx + ky * ky < 1.0
		var x: int = int(floor(d.x / WTex.SC + float(tw) * 0.5))
		var y: int = int(floor(d.y / WTex.SC + float(th) * 0.5))
		if x < 0 or y < 0 or x >= tw or y >= th:
			return false
		return img.get_pixel(x, y).a > 0.5

	func _draw() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(-Vector2(tw, th) * WTex.SC * 0.5, Vector2(tw, th) * WTex.SC), false)
			return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.8))
		draw_circle(Vector2.ZERO, r, Color("#d9531e") if kind == "lava" else Color("#2e7bbf"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Prop extends Node2D:
	static var tw: Node2D
	var kind := "tree"
	var r := 15.0
	var solid := false
	var used := false
	var v := 0.5
	var power := ""
	var sub := ""
	var color := Color.WHITE
	var charge := 0.0
	var lastc := 0.0
	var cd := 0.0
	var t := 0.0

	func _ready() -> void:
		t = v * 10.0
		if kind == "spring":
			charge = 120.0
		set_process(true)

	var _trap_off := false

	var _fading := false

	func _process(delta: float) -> void:
		if kind == "tree" or kind == "rock":
			# solo se redibujan mientras dura el cambio de bioma
			var fd: bool = tw != null and tw.fade_t < 1.0
			if fd or _fading:
				queue_redraw()
			_fading = fd
			return
		if kind != "spring" and kind != "altar" and kind != "chest" and kind != "trap":
			return
		t += delta
		if kind == "trap":
			# las trampas se quedan quietas: solo se redibujan al activarse o recargarse
			if (cd > 0.0) != _trap_off:
				_trap_off = cd > 0.0
				queue_redraw()
			elif cd <= 0.0 and Engine.get_process_frames() % 2 == 0:
				queue_redraw()   # animacion de la trampa armada
			return
		queue_redraw()

	func _spr(n: String, anchor: String = "feet", lift: float = 0.0, a: float = 1.0) -> bool:
		var tx: Texture2D = WTex.get_t(n)
		if tx == null:
			return false
		var sz := Vector2(tx.get_width(), tx.get_height()) * WTex.SC
		var off := Vector2(-sz.x * 0.5, -sz.y + WTex.SC)
		if anchor == "center":
			off = -sz * 0.5
		off.y -= lift
		draw_texture_rect(tx, Rect2(off, sz), false, Color(1, 1, 1, a))
		return true

	func _draw() -> void:
		var shadow := true
		if kind == "trap" or kind == "spring" or kind == "pebble" or kind == "tuft" or kind == "wall":
			shadow = false
		if shadow:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, r * 1.35, Color(0, 0, 0, 0.28))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if kind == "tree" or kind == "rock":
			var key: String = ("tree%d" % mini(2, int(v * 3.0))) if kind == "tree" else ("rock%d" % (1 if v > 0.8 else 0))
			var tx: Texture2D = tw.prop_tex(key) if tw != null else null
			if tx != null:
				var sz := Vector2(tx.get_width(), tx.get_height()) * 2.4
				var rc := Rect2(Vector2(-sz.x * 0.5, -sz.y + 5.0), sz)
				if tw.fade_t < 1.0 and tw.prev_biome != tw.biome:
					# cambio de bioma: el dibujo viejo se desvanece mientras aparece el nuevo
					var k: float = tw.fade_t * tw.fade_t * (3.0 - 2.0 * tw.fade_t)
					var old: Texture2D = tw.prop_tex(key, tw.prev_biome)
					if old != null:
						var osz := Vector2(old.get_width(), old.get_height()) * 2.4
						draw_texture_rect(old, Rect2(Vector2(-osz.x * 0.5, -osz.y + 5.0), osz), false, Color(1, 1, 1, 1.0 - k))
					draw_texture_rect(tx, rc, false, Color(1, 1, 1, k))
				else:
					draw_texture_rect(tx, rc, false)
				return
		elif kind == "chest":
			var big: bool = sub == "big"
			if big:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.5, 1.5))
			if (sub == "paid" or sub == "trap" or sub == "trapv") and not used:
				var tnm: String = "ch%d" % POI.paid_tier if sub == "paid" else ("trapv" if sub == "trapv" else "trapd")
				if POI.draw_tex(self, tnm, POI.SC, 0.0):
					return
			var okc: bool = _spr("chest_open" if used else "chest_closed")
			if big:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if okc:
				if not used:
					draw_circle(Vector2(0.0, (-88.0 if big else -58.0) - 3.0 * sin(t * 3.0)), 3.0, Color(1.0, 0.9, 0.4, 0.8))
					if sub == "paid":
						draw_arc(Vector2(0.0, -26.0), 30.0, 0.0, TAU, 32, Color(0.4, 0.85, 1.0, 0.55 + 0.25 * sin(t * 4.0)), 3.0)
						draw_circle(Vector2(0.0, -62.0), 5.0, Color("#7fe0ff"))
					elif sub == "trapv":
						draw_arc(Vector2(0.0, -26.0), 28.0, 0.0, TAU, 32, Color(1.0, 0.25, 0.25, 0.45 + 0.25 * sin(t * 6.0)), 2.0)
						draw_circle(Vector2(-6.0, -30.0), 2.0, Color(1.0, 0.2, 0.2))
						draw_circle(Vector2(6.0, -30.0), 2.0, Color(1.0, 0.2, 0.2))
					if big:
						draw_rect(Rect2(-7.0, -34.0, 14.0, 11.0), Color("#f2c443"))
						draw_rect(Rect2(-7.0, -34.0, 14.0, 11.0), Color("#1e0f06"), false, 2.0)
						draw_arc(Vector2(0.0, -34.0), 5.0, PI, TAU, 10, Color("#9aa6b5"), 2.5)
						draw_arc(Vector2(0.0, -40.0), 34.0, 0.0, TAU, 40, Color(1, 0.82, 0.25, 0.25), 2.0)
						if charge > 0.0:
							draw_arc(Vector2(0.0, -40.0), 34.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(charge / 3.5, 0.0, 1.0), 40, Color(1, 0.85, 0.25, 0.95), 4.0)
							var kf: float = clampf(charge / 3.5, 0.0, 1.0)
							draw_rect(Rect2(-24.0, -96.0, 48.0, 8.0), Color(0, 0, 0, 0.7))
							draw_rect(Rect2(-23.0, -95.0, 46.0 * kf, 6.0), Color(1.0, 0.85, 0.25).lerp(Color("#fff6c8"), kf))
				return
		elif kind == "altar":
			if used:
				# Estatua gastada: la misma estatua, apagada y derretida (oscura, achatada, con charco).
				var mt: Texture2D = WTex.get_t("altar_" + power)
				if mt != null:
					draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
					draw_circle(Vector2(0.0, 2.0), r * 1.9, Color(0.05, 0.04, 0.05, 0.55))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					var msz := Vector2(mt.get_width(), mt.get_height()) * WTex.SC
					var mrect := Rect2(Vector2(-msz.x * 0.58, -msz.y * 0.74 + WTex.SC), Vector2(msz.x * 1.16, msz.y * 0.74))
					draw_texture_rect(mt, mrect, false, Color(0.30, 0.28, 0.30, 1.0))
					# gotas fundidas
					draw_circle(Vector2(-msz.x * 0.22, -msz.y * 0.30), 3.0, Color(0.12, 0.10, 0.12, 0.9))
					draw_circle(Vector2(msz.x * 0.18, -msz.y * 0.18), 2.5, Color(0.12, 0.10, 0.12, 0.9))
					return
			var nm: String = "used" if used else power
			if sub == "legend":
				_draw_legend_altar()
				return
			if _spr("altar_" + nm):
				if not used:
					var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
					draw_circle(Vector2(0.0, -58.0), 14.0 + 3.0 * pulse, Color(color.r, color.g, color.b, 0.16 + 0.12 * pulse))
				return
		elif kind == "spring":
			if _spr("spring_off" if used else "spring_on", "center"):
				if not used:
					for i in range(3):
						var yy: float = -fposmod(t * 22.0 + float(i) * 14.0, 40.0)
						draw_circle(Vector2(float(i - 1) * 12.0, yy), 2.4, Color(0.8, 1.0, 0.9, 0.75))
				return
		elif kind == "trap":
			_draw_trap_tile()
			return
		_old_draw()

	# Trampa como una baldosa plana pegada al suelo; cada tipo con su color y dibujo.
	func _draw_trap_tile() -> void:
		var u := 7.4   # 1 "pixel" de arte; la baldosa son 8x8 pixeles (~59 px)
		var off: bool = cd > 0.0
		var base: Color
		var edge: Color
		var hi: Color
		match sub:
			"poison":
				base = Color("#3b2152")
				edge = Color("#241033")
				hi = Color("#b06bff")
			"ice":
				base = Color("#86cfe8")
				edge = Color("#4f9cc0")
				hi = Color("#f2fcff")
			"freeze":
				base = Color("#16466e")
				edge = Color("#0a2038")
				hi = Color("#d8f6ff")
			"shock":
				base = Color("#5a4a0a")
				edge = Color("#2b2203")
				hi = Color("#ffe14d")
			"sleep":
				base = Color("#3a4a6e")
				edge = Color("#1b2438")
				hi = Color("#cfd8ff")
			"confuse":
				base = Color("#5a1f4a")
				edge = Color("#2a0c24")
				hi = Color("#ff7ad9")
			_:
				base = Color("#5c1f0d")
				edge = Color("#2a0c05")
				hi = Color("#ff9a2e")
		if off:
			base = base.lerp(Color(0.25, 0.25, 0.25), 0.7)
			edge = edge.lerp(Color(0.2, 0.2, 0.2), 0.7)
			hi = hi.lerp(Color(0.45, 0.45, 0.45), 0.8)
		var tm: float = float(Time.get_ticks_msec()) * 0.001
		if not off:
			# Aviso del area real (radio 112) con animacion propia de cada tipo
			var pul: float = 0.5 + 0.5 * sin(tm * 3.0)
			var ac := Color(hi.r, hi.g, hi.b, 0.10 + 0.08 * pul)
			draw_arc(Vector2.ZERO, 112.0, 0.0, TAU, 56, Color(hi.r, hi.g, hi.b, 0.22 + 0.15 * pul), 2.0)
			match sub:
				"poison":
					for i in range(4):
						var f: float = fposmod(tm * 0.6 + float(i) * 0.25, 1.0)
						draw_circle(Vector2(sin(float(i) * 2.0) * 34.0, -f * 40.0), 3.0 + 3.0 * f, Color(hi.r, hi.g, hi.b, 0.7 * (1.0 - f)))
				"ice":
					draw_circle(Vector2.ZERO, 40.0 + 6.0 * pul, ac)
				"freeze":
					for i in range(6):
						var an: float = tm * 0.5 + float(i) * TAU / 6.0
						draw_rect(Rect2(Vector2.from_angle(an) * 50.0 - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.8))
				"shock":
					if fmod(tm, 1.2) < 0.15:
						var q: Vector2 = Vector2.from_angle(tm * 9.0) * 52.0
						draw_line(Vector2.ZERO, q, Color("#fff6a0"), 2.0)
				"sleep":
					var zf: float = fposmod(tm * 0.5, 1.0)
					draw_string(ThemeDB.fallback_font, Vector2(14.0, -20.0 - zf * 30.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(hi.r, hi.g, hi.b, 1.0 - zf))
				"confuse":
					for i in range(10):
						var aa: float = tm * 2.0 + float(i) * 0.6
						draw_circle(Vector2.from_angle(aa) * (6.0 + float(i) * 4.5), 2.0, Color(hi.r, hi.g, hi.b, 0.7))
				_:
					for i in range(5):
						var ff: float = fposmod(tm * 0.8 + float(i) * 0.2, 1.0)
						draw_circle(Vector2(sin(float(i) * 3.0) * 26.0, -ff * 34.0), 3.5 * (1.0 - ff), Color("#ffb23a", 0.8))
		var o := Vector2(-4.0 * u, -4.0 * u)
		draw_rect(Rect2(o, Vector2(8.0 * u, 8.0 * u)), edge)
		draw_rect(Rect2(o + Vector2(u, u), Vector2(6.0 * u, 6.0 * u)), base)
		var cells: Array
		match sub:
			"poison":   # burbujas
				cells = [Vector2(2, 2), Vector2(5, 3), Vector2(3, 5), Vector2(5, 6), Vector2(2, 4)]
			"ice":      # cristal en cruz diagonal
				cells = [Vector2(2, 2), Vector2(3, 3), Vector2(4, 4), Vector2(5, 5), Vector2(5, 2), Vector2(4, 3), Vector2(3, 4), Vector2(2, 5)]
			"freeze":   # copo de nieve
				cells = [Vector2(3, 1), Vector2(4, 1), Vector2(3, 2), Vector2(4, 2), Vector2(1, 3), Vector2(2, 3), Vector2(3, 3), Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(1, 4), Vector2(2, 4), Vector2(3, 4), Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(3, 5), Vector2(4, 5), Vector2(3, 6), Vector2(4, 6)]
			"shock":    # rayo
				cells = [Vector2(4, 1), Vector2(5, 1), Vector2(3, 2), Vector2(4, 2), Vector2(2, 3), Vector2(3, 3), Vector2(4, 3), Vector2(5, 3), Vector2(3, 4), Vector2(4, 4), Vector2(3, 5), Vector2(2, 6)]
			"sleep":    # una Z
				cells = [Vector2(2, 2), Vector2(3, 2), Vector2(4, 2), Vector2(5, 2), Vector2(4, 3), Vector2(3, 4), Vector2(2, 5), Vector2(3, 5), Vector2(4, 5), Vector2(5, 5)]
			"confuse":  # espiral
				cells = [Vector2(2, 2), Vector2(3, 2), Vector2(4, 2), Vector2(5, 2), Vector2(5, 3), Vector2(5, 4), Vector2(5, 5), Vector2(4, 5), Vector2(3, 5), Vector2(3, 4), Vector2(3, 3), Vector2(4, 3)]
			_:          # grietas de lava
				cells = [Vector2(2, 3), Vector2(3, 3), Vector2(3, 4), Vector2(4, 4), Vector2(4, 5), Vector2(5, 5), Vector2(5, 2), Vector2(4, 2)]
		for c in cells:
			var sz: float = u * (0.9 if sub == "poison" else 1.0)
			draw_rect(Rect2(o + (c as Vector2) * u, Vector2(sz, sz)), hi)
		if sub == "fire" and not off:
			draw_rect(Rect2(o + Vector2(3.0 * u, 3.0 * u), Vector2(2.0 * u, 2.0 * u)), Color("#ffe27a"))

	# Altar legendario (arte nuevo): 4 estados que se funden segun avanza la invocacion.
	# El origen del nodo es el centro del circulo (donde te paras).
	func _draw_legend_altar() -> void:
		var k := 1.25
		var org := Vector2(-85.0 * k, -160.0 * k)
		var sz := Vector2(170.0, 230.0) * k
		var ck: float = clampf(charge / 4.0, 0.0, 1.0)
		var lp: float = 0.5 + 0.5 * sin(t * 2.5)
		var t0: Texture2D = WTex.get_t("altar_leg_0")
		var t1: Texture2D = WTex.get_t("altar_leg_1")
		var t2: Texture2D = WTex.get_t("altar_leg_2")
		var t3: Texture2D = WTex.get_t("altar_leg_3")
		if t0 == null or t1 == null:
			return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2(0.0, 40.0), 120.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if used:
			draw_texture_rect(t0, Rect2(org, sz), false)
			return
		draw_texture_rect(t1, Rect2(org, sz), false, Color(1, 1, 1, 1.0 if charge > 0.0 else 0.88 + 0.12 * lp))
		if t2 != null and ck > 0.0:
			draw_texture_rect(t2, Rect2(org, sz), false, Color(1, 1, 1, clampf(ck * 2.5, 0.0, 1.0)))
		if t3 != null and ck > 0.55:
			draw_texture_rect(t3, Rect2(org, sz), false, Color(1, 1, 1, clampf((ck - 0.55) / 0.35, 0.0, 1.0)))
		if charge > 0.0:
			var w := 96.0
			var y := -org.y * 0.0 - 196.0
			var gold := Color(1.0, 0.82, 0.25)
			draw_rect(Rect2(-w * 0.5 - 2.0, y - 2.0, w + 4.0, 16.0), Color(0, 0, 0, 0.8))
			draw_rect(Rect2(-w * 0.5, y, w * ck, 12.0), gold)
			draw_string(ThemeDB.fallback_font, Vector2(-w * 0.5, y - 6.0), L.t("Invocando"), HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color.WHITE)

	func _old_draw() -> void:
		if kind == "tree":
			var g: Color = Color("#2f7a3e").lerp(Color("#3f9a4c"), v)
			draw_rect(Rect2(-4.0, -22.0, 8.0, 22.0), Color("#6b4a2e"))
			draw_circle(Vector2(0.0, -40.0), 19.0, g)
		elif kind == "rock":
			draw_circle(Vector2(0.0, -10.0), r, Color("#7d8591"))
		elif kind == "chest":
			draw_rect(Rect2(-14.0, -22.0, 28.0, 22.0), Color("#8a5a2b"))
		elif kind == "spring":
			draw_circle(Vector2.ZERO, 25.0, Color("#5fe0a8"))
		elif kind == "altar":
			draw_rect(Rect2(-12.0, -30.0, 24.0, 30.0), Color("#8a8c94"))
		elif kind == "trap":
			draw_circle(Vector2.ZERO, 16.0, Color("#6a6a6a"))


# ---------------------------------------------------------------
# Proyectil / orbe giratorio / bumeran: vuela en el plano del suelo y se
# dibuja elevado con sombra
# ---------------------------------------------------------------
class Bullet extends Node2D:
	const LIFT := 18.0
	var src := ""
	var vel := Vector2.ZERO
	var ppos := Vector2.ZERO
	var dmg := 10.0
	var r := 6.0
	var life := 1.4
	var age := 0.0
	var pierce := 0
	var color := Color.WHITE
	var hits: Array = []
	var homing := 0.0
	var burn := 0
	var poison := 0
	var slow := 0.0
	var cc := ""
	var ccp := 0.0
	var knock := 0.0
	var mtype := "normal"
	var boom := 0.0
	var bsp := 0.0
	var back := false
	var orb := false
	var mid := ""
	var oa := 0.0
	var orad := 60.0
	var ospeed := 2.0
	var rehit := 0.3
	var hit_log := {}
	var shape := ""
	var pal := "normal"
	var trail := ""
	var trail_t := 0.0
	var turn := 0.0
	var leave := ""
	var leave_t := 0.0
	var ric := 0
	var burst := 0
	var bm: Dictionary = {}

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, r * 0.9, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if shape != "":
			var ang := 0.0
			if VFX.is_dir(shape):
				ang = (oa + PI / 2.0) if orb else vel.angle()
			elif VFX.spins(shape):
				ang = age * 9.0
			var al: float = 1.0 if orb else minf(1.0, (life - age) * 4.0)
			VFX.draw(self, shape, pal, Vector2(0.0, -LIFT), ang, (1.5 if r >= 8.0 else 1.0) * maxf(1.0, r / 8.0), int(age * 12.0), al)
			return
		draw_circle(Vector2(0.0, -LIFT), r * 1.4, Color(color.r, color.g, color.b, 0.35))
		draw_circle(Vector2(0.0, -LIFT), r, color)
		draw_circle(Vector2(0.0, -LIFT), r * 0.5, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------
# Efectos breves: anillos, arcos de golpe, rayos, lineas, destellos
# ---------------------------------------------------------------
class Fx extends Node2D:
	var kind := "ring"
	var color := Color.WHITE
	var age := 0.0
	var life := 0.25
	var r0 := 0.0
	var r1 := 40.0
	var ang := 0.0
	var arc := 1.0
	var length := 0.0
	var width := 10.0
	var p2 := Vector2.ZERO

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var k: float = clampf(age / life, 0.0, 1.0)
		var a: float = 1.0 - k
		var c := Color(color.r, color.g, color.b, a * 0.85)
		var up := Vector2(0.0, -LIFT * 0.5)
		if kind == "ring":
			draw_set_transform(up, 0.0, Vector2(1.0, 0.7))
			draw_arc(Vector2.ZERO, lerpf(r0, r1, k), 0.0, TAU, 40, c, 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "arc":
			var pts := PackedVector2Array()
			pts.append(up)
			var n := 14
			for i in range(n + 1):
				var t: float = float(i) / float(n)
				var aa: float = ang + (t - 0.5) * arc
				pts.append(up + Vector2.from_angle(aa) * r1 * (0.55 + 0.45 * minf(1.0, k * 3.0 + 0.3)))
			if arc >= TAU - 0.05:
				draw_circle(up, r1 * (0.55 + 0.45 * minf(1.0, k * 3.0 + 0.3)), Color(color.r, color.g, color.b, a * 0.45))
				draw_arc(up, r1, 0.0, TAU, 36, c, 4.0)
			else:
				draw_colored_polygon(pts, Color(color.r, color.g, color.b, a * 0.45))
				draw_arc(up, r1, ang - arc * 0.5, ang + arc * 0.5, 18, c, 4.0)
		elif kind == "beam":
			var d: Vector2 = Vector2.from_angle(ang)
			var start: Vector2 = Vector2(0.0, -LIFT)
			draw_line(start, start + d * length, Color(color.r, color.g, color.b, a * 0.5), width * (1.0 - k * 0.5))
			draw_line(start, start + d * length, Color(1, 1, 1, a * 0.9), width * 0.35 * (1.0 - k * 0.5))
		elif kind == "line":
			draw_line(Vector2.ZERO, p2, Color(color.r, color.g, color.b, a * 0.8), width)
			draw_line(Vector2.ZERO, p2, Color(1, 1, 1, a), width * 0.4)
		elif kind == "burst":
			draw_circle(up, r1 * (1.0 - k * 0.6), Color(color.r, color.g, color.b, a * 0.5))


# ---------------------------------------------------------------
# Campos persistentes: minas, meteoros, torretas, charcos
# ---------------------------------------------------------------
class Field extends Node2D:
	var kind := "mine"
	var color := Color.WHITE
	var move: Dictionary = {}
	var vis: Dictionary = {}
	var t := 0.0
	var life := 3.0
	var arm := 0.35
	var fall := 0.5
	var r := 40.0
	var dmg := 0.0
	var shot_t := 0.3
	var tick := 0.0
	var kick := 0.0
	var gone := false
	var shards := 0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _spr(pos: Vector2, ang: float, scl: float, frame: int, al: float) -> void:
		if vis.is_empty():
			return
		VFX.draw(self, String(vis["proj"]), String(vis["pal"]), pos, ang, scl, frame, al)

	func _dashed(rx: float, ry: float, col: Color) -> void:
		var n := 24
		for i in range(n):
			if i % 2 == 0:
				var a0: float = TAU * float(i) / float(n)
				var a1: float = TAU * float(i + 1) / float(n)
				draw_line(Vector2(cos(a0) * rx, sin(a0) * ry), Vector2(cos(a1) * rx, sin(a1) * ry), col, 1.5)

	func _draw() -> void:
		var now: float = Time.get_ticks_msec() / 1000.0
		if kind == "patch":
			var a: float = clampf(minf((life - t) * 2.0, t * 6.0), 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.32 * a))
			draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.5 * a), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "mine":
			var armed: bool = t >= arm
			var blink: bool = armed and sin(now * 8.0 + position.x) > 0.3
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, r * 0.45, Color(color.r, color.g, color.b, 0.18))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_spr(Vector2(0.0, -4.0), PI if vis.has("flip") else 0.0, 1.0, 0, 1.0 if blink else 0.75)
		elif kind == "meteor":
			var k: float = clampf(t / fall, 0.0, 1.0)
			var sc: float = 0.3 + k * 0.7
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r * sc, Color(0, 0, 0, 0.2 + k * 0.3))
			_dashed(r, r, Color(color.r, color.g, color.b, 0.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if t > 0.0 and vis.has("big"):
				var head := Vector2((1.0 - k) * 150.0, -(1.0 - k) * 330.0 - 10.0)
				var back: Vector2 = Vector2(150.0, -330.0).normalized()
				for q in range(1, 8):
					var fq: float = float(q) / 8.0
					draw_circle(head + back * float(q) * 20.0, 26.0 * (1.0 - fq * 0.8), color.lerp(Color.WHITE, 0.35 * (1.0 - fq)) * Color(1, 1, 1, 0.95 * (1.0 - fq)))
				_spr(head, 0.0, float(vis["big"]), int(now * 12.0), 1.0)
			elif t > 0.0:
				_spr(Vector2((1.0 - k) * 40.0, -(1.0 - k) * 170.0 - 6.0), atan2(170.0, -40.0), 1.5, int(now * 12.0), 1.0)
		elif kind == "turret":
			var fade: float = clampf(minf((life - t) * 2.0, t * 5.0), 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var bob: float = sin(now * 4.0 + position.x) * 2.0 - (2.0 if kick > 0.0 else 0.0)
			_spr(Vector2(0.0, -16.0 + bob), 0.0, 1.5, int(now * 8.0), fade)


# ---------------------------------------------------------------
# Barra de movimientos (abajo a la derecha): tocalos para cambiar
# ---------------------------------------------------------------
class Slots extends Node2D:
	signal picked(idx: int)
	const SZ := 76.0
	var info: Array = []
	var active := 0
	var enabled := true

	func _rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var n: int = info.size()
		var total: float = SZ * float(n) + 8.0 * float(maxi(0, n - 1))
		var x0: float = (vp.x - total) * 0.5
		var y0: float = vp.y - SZ - 12.0 - DSP.insets(get_tree()).w
		var out: Array = []
		for i in range(n):
			out.append(Rect2(x0 + float(i) * (SZ + 8.0), y0, SZ, SZ))
		return out

	func _process(_delta: float) -> void:
		queue_redraw()

	func _input(event: InputEvent) -> void:
		if not enabled:
			return
		if event is InputEventScreenTouch and event.pressed:
			var rs: Array = _rects()
			for i in range(rs.size()):
				if rs[i].has_point(event.position):
					get_viewport().set_input_as_handled()
					picked.emit(i)
					return

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var rs: Array = _rects()
		for i in range(rs.size()):
			var r: Rect2 = rs[i]
			var it: Dictionary = info[i]
			var col: Color = it["color"]
			var is_act: bool = i == active
			var border: Color = Color("#e8c94f") if is_act else Color(col.r, col.g, col.b, 0.6)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.05, 0.11, 0.18, 0.93)
			sb.border_color = border
			sb.set_border_width_all(3 if is_act else 2)
			sb.set_corner_radius_all(10)
			draw_style_box(sb, r.grow(2.0))
			IC.draw_in(self, String(it.get("icon", "star")), r.position + Vector2(SZ * 0.5, 29.0), 32.0)
			if bool(it["evo"]):
				IC.draw_in(self, "star", r.position + Vector2(SZ - 12.0, 12.0), 12.0)
			if int(it.get("n", 1)) > 1:
				draw_rect(Rect2(r.position.x + SZ - 30.0, r.position.y + 2.0, 28.0, 14.0), Color("#ff8ad8"))
				draw_string(font, r.position + Vector2(SZ - 30.0, 13.0), "x%d" % int(it["n"]), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 12, Color("#2a0f24"))
			draw_string(font, r.position + Vector2(5.0, 15.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8fa8cc"))
			var nm_t: String = L.t(String(it["name"]))
			var nm_fs: int = 11
			while nm_fs > 7 and font.get_string_size(nm_t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, nm_fs).x > SZ - 4.0:
				nm_fs -= 1
			draw_string(font, r.position + Vector2(2.0, 55.0), nm_t, HORIZONTAL_ALIGNMENT_CENTER, SZ - 4.0, nm_fs, Color.WHITE)
			var mx: int = int(it["max"])
			var lv: int = int(it["lvl"])
			var pw: float = (SZ - 12.0) / float(maxi(1, mx))
			for p in range(mx):
				var pc := Color(1, 1, 1, 0.2)
				if p < lv:
					pc = Color("#ffd33d")
				draw_rect(Rect2(r.position.x + 6.0 + float(p) * pw, r.position.y + 60.0, pw - 1.5, 4.0), pc)
			draw_rect(Rect2(r.position.x, r.position.y + SZ - 6.0, SZ * float(it["frac"]), 6.0), Color(col.r, col.g, col.b, 0.8))


# ---------------------------------------------------------------
# Orbe de experiencia / objeto que suelta un enemigo
# ---------------------------------------------------------------
class Orb extends Node2D:
	var kind := "xp"
	var value := 20.0
	var vel := Vector2.ZERO
	var pulled := false

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var c := Vector2(0.0, -9.0)
		if kind == "xp":
			var xk: float = 1.0 if value < 30.0 else 1.7
			draw_circle(c, 11.0 * xk, Color(0.16, 0.56, 0.82, 0.4))
			draw_circle(c, 6.5 * xk, Color("#7fe0ff"))
			draw_arc(c, 6.5 * xk, 0.0, TAU, 14, Color("#e8fbff"), 1.5)
			draw_circle(c + Vector2(-1.6, -1.9) * xk, 2.2 * xk, Color(1, 1, 1, 0.95))
		elif kind == "xpBig":
			draw_circle(c + Vector2(0.0, -4.0), 22.0, Color(1.0, 0.82, 0.25, 0.28))
			var ctx: Texture2D = WTex.get_t("xp_big")
			if ctx != null:
				var csz := Vector2(ctx.get_width(), ctx.get_height()) * 3.4
				draw_texture_rect(ctx, Rect2(c + Vector2(-csz.x * 0.5, -csz.y * 0.5 - 4.0), csz), false)
			else:
				draw_circle(c, 7.0, Color("#ffd95e"))
		else:
			var icn := "coin"
			var glow := Color("#ffd23f")
			if kind == "ticket":
				icn = "ticket"
				glow = Color("#ffd23f")
			elif kind == "ticket10":
				icn = "ticket10"
				glow = Color("#c47bff")
			elif kind == "gcoin" or kind == "gcoin_gold":
				icn = kind
				glow = Color("#ffd23f") if kind == "gcoin_gold" else Color("#ff8ad8")
			elif kind == "magnet":
				icn = "magnet"
				glow = Color("#7fe0ff")
			elif kind == "bomb":
				icn = "bomb"
				glow = Color("#ff7b3d")
			elif kind == "item":
				icn = "star"
				glow = Color("#ff8ad8")
			elif kind == "ball":
				icn = "ball"
				glow = Color("#ff6b6b")
			elif kind != "coin":
				icn = "berry"
				glow = Color("#5fe08a")
			draw_circle(c + Vector2(0.0, -4.0), 15.0, Color(glow.r, glow.g, glow.b, 0.22))
			if icn == "ball":
				var bt: Texture2D = ALP.ball_tex()
				if bt != null:
					var bsz := Vector2(bt.get_width(), bt.get_height()) * 0.36
					draw_texture_rect(bt, Rect2(c + Vector2(-bsz.x * 0.5, -bsz.y * 0.5 - 4.0), bsz), false)
				else:
					draw_circle(c, 7.0, Color("#e04040"))
			else:
				IC.draw_in(self, icn, c + Vector2(0.0, -4.0), 20.0)



# ---------------------------------------------------------------
# Cartas de subida de nivel (tactil, mando y teclado)
# ---------------------------------------------------------------
class Cards extends Node2D:
	signal chosen(idx: int)
	var items: Array = []
	var sel := 0
	var open := false
	var age := 0.0
	var title := ""
	var headline := L.t("¡Subes de nivel!")
	var _axis_free := true
	signal reroll_pressed
	signal ban_picked(idx: int)
	var rerolls := 0
	var bans := 0
	var ban_mode := false
	var extras := true
	# v5.2: pantalla de objeto -> bloquear (no volver a ofrecer objetos) y descartar el objeto ofrecido para siempre.
	signal block_pressed
	signal skip_pressed
	var item_mode := false
	var block_name := ""
	# Proteccion contra pulsaciones del combate: al abrirse cartas nuevas no se acepta ninguna entrada durante GRACE segundos.
	const GRACE := 0.7

	func _btn_rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		return [Rect2(vp.x * 0.5 - 250.0, vp.y - 100.0, 230.0, 50.0), Rect2(vp.x * 0.5 + 20.0, vp.y - 100.0, 230.0, 50.0)]

	func _skip_rect() -> Rect2:
		var vp: Vector2 = get_viewport_rect().size
		return Rect2(vp.x * 0.5 - 55.0, vp.y - 140.0, 110.0, 34.0)

	func _do_reroll() -> void:
		if extras and rerolls > 0 and not ban_mode:
			reroll_pressed.emit()

	func _do_block() -> void:
		if item_mode and block_name != "":
			block_pressed.emit()

	func _toggle_ban() -> void:
		if extras and bans > 0:
			ban_mode = not ban_mode
			queue_redraw()

	func show_cards(list: Array, heading: String, head: String = "¡Subes de nivel!", ex: bool = true) -> void:
		block_name = ""
		items = list
		title = heading
		headline = head
		extras = ex
		item_mode = false
		ban_mode = false
		sel = 0
		open = true
		age = 0.0
		_axis_free = false
		queue_redraw()

	func hide_cards() -> void:
		open = false
		queue_redraw()

	func _rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var n: int = items.size()
		var gap := 20.0
		var w: float = minf(300.0, (vp.x - 80.0 - gap * float(n - 1)) / float(maxi(n, 1)))
		var h := 294.0
		var total: float = w * float(n) + gap * float(n - 1)
		var x0: float = (vp.x - total) * 0.5
		var y0: float = vp.y * 0.5 - 106.0
		var out: Array = []
		for i in range(n):
			out.append(Rect2(x0 + float(i) * (w + gap), y0, w, h))
		return out

	func _process(delta: float) -> void:
		if open:
			age += delta
			queue_redraw()

	func _move(step: int) -> void:
		if items.is_empty():
			return
		sel = posmod(sel + step, items.size())
		queue_redraw()

	func _pick(i: int) -> void:
		if i >= 0 and i < items.size():
			sel = i
			if ban_mode:
				if String(items[i]["cat"]) == "new":
					ban_picked.emit(i)
				return
			chosen.emit(i)

	func _input(event: InputEvent) -> void:
		if not open:
			return
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
			if absf(event.axis_value) < 0.3:
				_axis_free = true
			elif absf(event.axis_value) > 0.6 and _axis_free and age > GRACE:
				_axis_free = false
				_move(1 if event.axis_value > 0.0 else -1)
			return
		var pressed := false
		if event is InputEventScreenTouch:
			pressed = event.pressed
		elif event is InputEventJoypadButton:
			pressed = event.pressed
		elif event is InputEventKey:
			pressed = event.pressed and not event.echo
		if not pressed:
			return
		# Tragamos las pulsaciones (no las sueltas) mientras hay cartas.
		get_viewport().set_input_as_handled()
		if age < GRACE:
			return
		if event is InputEventScreenTouch:
			var brs: Array = _btn_rects()
			if item_mode:
				if _skip_rect().has_point(event.position):
					skip_pressed.emit()
					return
				if brs[0].has_point(event.position):
					_do_block()
					return
			if brs[0].has_point(event.position):
				_do_reroll()
				return
			if brs[1].has_point(event.position):
				_toggle_ban()
				return
			var rs: Array = _rects()
			for i in range(rs.size()):
				if rs[i].has_point(event.position):
					_pick(i)
					return
		elif event is InputEventKey:
			match event.keycode:
				KEY_1:
					_pick(0)
				KEY_2:
					_pick(1)
				KEY_3:
					_pick(2)
				KEY_LEFT, KEY_A:
					_move(-1)
				KEY_RIGHT, KEY_D:
					_move(1)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
					_pick(sel)
				KEY_X:
					if item_mode:
						skip_pressed.emit()
				KEY_R:
					_do_reroll()
					_do_block()
				KEY_B:
					_toggle_ban()
		elif event is InputEventJoypadButton:
			var bi: int = event.button_index
			if bi == JOY_BUTTON_DPAD_LEFT or bi == PAD.btn("prev"):
				_move(-1)
			elif bi == JOY_BUTTON_DPAD_RIGHT or bi == PAD.btn("next"):
				_move(1)
			elif bi == PAD.btn("confirm"):
				_pick(sel)
			elif bi == JOY_BUTTON_BACK and item_mode:
				skip_pressed.emit()
			elif bi == PAD.btn("reroll"):
				_do_reroll()
				_do_block()
			elif bi == PAD.btn("ban"):
				_toggle_ban()

	func _draw() -> void:
		if not open:
			return
		var font := ThemeDB.fallback_font
		var vp: Vector2 = get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(0.0, vp.y * 0.5 - 150.0), L.t(headline), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color("#ffd33d"))
		draw_string(font, Vector2(0.0, vp.y * 0.5 - 118.0), L.t(title), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color.WHITE)
		var rs: Array = _rects()
		for i in range(rs.size()):
			var r: Rect2 = rs[i]
			var it: Dictionary = items[i]
			var tag_col: Color = it["color"]
			var chosen_now: bool = i == sel
			var border: Color = tag_col
			if chosen_now:
				border = Color("#ffd33d")
			var paper: bool = bool(it.get("paper", false))
			draw_rect(r.grow(4.0 if chosen_now else 1.5), border)
			draw_rect(r, Color("#1b2a44"))
			var legend: bool = bool(it.get("legend", false))
			if legend:
				_draw_legend_bg(r)
			if paper:
				draw_rect(r, Color("#ecd9a6"))
				draw_rect(r.grow(-6.0), Color("#8a6a3a"), false, 2.0)
				draw_line(Vector2(r.position.x + 24.0, r.end.y - 22.0), Vector2(r.position.x + r.size.x * 0.55, r.end.y - 22.0), Color("#6b4a2b"), 2.0)
				draw_circle(Vector2(r.end.x - 40.0, r.end.y - 34.0), 15.0, Color("#a8281c"))
				draw_circle(Vector2(r.end.x - 40.0, r.end.y - 34.0), 9.0, Color("#c0392b"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 32.0)), Color(tag_col.r, tag_col.g, tag_col.b, 0.35))
			draw_string(font, r.position + Vector2(10.0, 22.0), L.t(String(it["tag"])), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40.0, 16, Color("#2b1a00") if legend else Color.WHITE)
			draw_string(font, r.position + Vector2(r.size.x - 24.0, 22.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#8fa8cc"))
			var ic_c: Vector2 = r.position + Vector2(r.size.x * 0.5, 72.0)
			var ic_bg := Rect2(ic_c - Vector2(34.0, 34.0), Vector2(68.0, 68.0))
			draw_rect(ic_bg, Color(0.1, 0.06, 0.0, 0.82) if legend else Color(tag_col.r, tag_col.g, tag_col.b, 0.22))
			draw_rect(ic_bg, Color(tag_col.r, tag_col.g, tag_col.b, 0.7), false, 2.0)
			IC.draw_in(self, String(it.get("icon", "star")), ic_c, 52.0)
			draw_multiline_string(font, r.position + Vector2(12.0, 134.0), L.t(String(it["title"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 24.0, 24, 2, Color("#4a2f12") if paper else (Color("#2b1a00") if legend else Color.WHITE))
			draw_multiline_string(font, r.position + Vector2(16.0, 196.0), L.t(String(it["desc"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 32.0, 18, 5, Color("#5a3d1c") if paper else (Color("#3a2600") if legend else Color("#c8d6ee")))
		if age < GRACE:
			# Estado "aun no": cartas atenuadas y una barra que se llena hasta poder elegir.
			for r2 in rs:
				draw_rect(r2, Color(0.0, 0.0, 0.0, 0.5))
			var bw := 220.0
			var bx: float = (vp.x - bw) * 0.5
			var by: float = vp.y * 0.5 + 226.0
			draw_rect(Rect2(bx, by, bw, 10.0), Color("#1b2a44"))
			draw_rect(Rect2(bx, by, bw * clampf(age / GRACE, 0.0, 1.0), 10.0), Color("#ffd33d"))
			draw_rect(Rect2(bx, by, bw, 10.0), Color("#8fa8cc"), false, 2.0)
			draw_string(font, Vector2(0.0, by - 8.0), L.t("Un momento…"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#c8d6ee"))
		if extras:
			var brs: Array = _btn_rects()
			if rerolls > 0:
				draw_rect(brs[0], Color("#1b2a44"))
				draw_rect(brs[0], Color("#7fe0ff"), false, 2.0)
				_draw_key_label(brs[0], L.t("Cambiar (%d)  [R]") % rerolls, "reroll")
			if bans > 0:
				draw_rect(brs[1], Color("#5a1f2a") if ban_mode else Color("#1b2a44"))
				draw_rect(brs[1], Color("#ff6b7a"), false, 2.0)
				_draw_key_label(brs[1], L.t("Vetar (%d)  [B]") % bans, "ban")
			if ban_mode:
				draw_string(font, Vector2(0.0, vp.y * 0.5 + 214.0), L.t("Elige un movimiento nuevo para vetarlo"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color("#ff9aa5"))
		if item_mode:
			var ibr: Array = _btn_rects()
			if block_name != "":   # el Caramelo Raro no se puede descartar para siempre
				draw_rect(ibr[0], Color("#5a1f2a"))
				draw_rect(ibr[0], Color("#ff6b7a"), false, 2.0)
				_draw_key_label(ibr[0], L.t("Descartar en esta partida  [R]"), "reroll")
			var skr: Rect2 = _skip_rect()
			draw_rect(skr, Color("#1b2a44"))
			draw_rect(skr, Color("#8fa8cc"), false, 2.0)
			draw_string(font, skr.position + Vector2(0.0, 23.0), "Skip", HORIZONTAL_ALIGNMENT_CENTER, skr.size.x, 18, Color.WHITE)
		_draw_footer(vp)


	# Carta legendaria: fondo de oro con brillo diagonal que recorre la carta y destellos.
	func _draw_legend_bg(r: Rect2) -> void:
		var beat: float = 0.5 + 0.5 * sin(age * 4.0)
		draw_rect(r.grow(5.0), Color(1.0, 0.82, 0.25, 0.25 + 0.2 * beat))
		draw_rect(r.grow(2.5), Color("#ffd23f"))
		draw_rect(r, Color("#a87a12"))
		draw_rect(Rect2(r.position + Vector2(0.0, 32.0), Vector2(r.size.x, r.size.y - 32.0)), Color("#c9951c"))
		draw_rect(Rect2(r.position + Vector2(0.0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), Color("#e3b52e"))
		draw_rect(r.grow(-6.0), Color("#ffe27a"), false, 2.0)
		var sx: float = fposmod(age * 120.0, r.size.x + 160.0) - 80.0
		var sheen := PackedVector2Array([r.position + Vector2(sx, 0.0), r.position + Vector2(sx + 40.0, 0.0), r.position + Vector2(sx + 10.0, r.size.y), r.position + Vector2(sx - 30.0, r.size.y)])
		var clipped := Geometry2D.intersect_polygons(sheen, PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0.0), r.end, r.position + Vector2(0.0, r.size.y)]))
		for poly in clipped:
			draw_colored_polygon(poly, Color(1.0, 0.97, 0.7, 0.22))
		for i in range(7):
			var ph: float = age * 1.3 + float(i) * 0.9
			var sp := Vector2(r.position.x + fposmod(float(i) * 47.0 + 20.0, r.size.x - 20.0) + 10.0, r.position.y + 40.0 + fposmod(float(i) * 83.0 + ph * 18.0, r.size.y - 60.0))
			var sz: float = 2.0 + 2.5 * (0.5 + 0.5 * sin(age * 6.0 + float(i) * 2.1))
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -sz * 1.6), sp + Vector2(sz * 0.5, 0), sp + Vector2(0, sz * 1.6), sp + Vector2(-sz * 0.5, 0)]), Color(1.0, 0.98, 0.8, 0.9))
			draw_colored_polygon(PackedVector2Array([sp + Vector2(-sz * 1.6, 0), sp + Vector2(0, sz * 0.5), sp + Vector2(sz * 1.6, 0), sp + Vector2(0, -sz * 0.5)]), Color(1.0, 0.98, 0.8, 0.9))

	# Texto de un boton de la pantalla; con mando conectado cambia "[R]" por el icono del boton asignado.
	func _draw_key_label(r: Rect2, txt: String, action: String) -> void:
		var font := ThemeDB.fallback_font
		var pad: bool = Input.get_connected_joypads().size() > 0
		if not pad:
			draw_string(font, r.position + Vector2(0.0, 32.0), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color.WHITE)
			return
		var rx := RegEx.new()
		rx.compile("\\s*\\[[^\\]]*\\]")
		var clean: String = rx.sub(txt, "", true)
		var tw: float = font.get_string_size(clean, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
		var isz := 30.0
		var x0: float = r.position.x + (r.size.x - (tw + 8.0 + isz)) * 0.5
		draw_string(font, Vector2(x0, r.position.y + 32.0), clean, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color.WHITE)
		draw_texture_rect(PADI.tex(PAD.btn(action)), Rect2(Vector2(x0 + tw + 8.0, r.position.y + (r.size.y - isz) * 0.5), Vector2(isz, isz)), false)


	# Pie: "Toca una carta | Mando: [cruceta] [aceptar] | Teclado: 1 2 3" con los iconos del mando elegido.
	func _draw_footer(vp: Vector2) -> void:
		var font := ThemeDB.fallback_font
		var col := Color("#8fa8cc")
		var parts: Array = [{"t": L.t("Toca una carta") + "  |  "}]
		if Input.get_connected_joypads().size() > 0:
			parts.append({"t": L.t("Mando") + ": "})
			parts.append({"i": PADI.named("dpad_lr")})
			parts.append({"t": " + "})
			parts.append({"i": PADI.tex(PAD.btn("confirm"))})
			parts.append({"t": "  |  "})
		parts.append({"t": L.t("Teclado: 1 2 3")})
		var isz := 28.0
		var total := 0.0
		for p in parts:
			total += isz if p.has("i") else font.get_string_size(String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var x: float = (vp.x - total) * 0.5
		var y: float = vp.y - 24.0
		for p in parts:
			if p.has("i"):
				draw_texture_rect(p["i"], Rect2(Vector2(x, y - 21.0), Vector2(isz, isz)), false)
				x += isz
			else:
				draw_string(font, Vector2(x, y), String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, col)
				x += font.get_string_size(String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x


# ---------------------------------------------------------------
# Numero de dano flotante
# ---------------------------------------------------------------
class Floater extends Node2D:
	static var alive := 0
	var plain := false
	var text := ""
	var color := Color.WHITE
	var life := 0.7
	var age := 0.0
	var size := 18

	func _enter_tree() -> void:
		alive += 1

	func _exit_tree() -> void:
		alive = maxi(0, alive - 1)

	func _process(delta: float) -> void:
		age += delta
		position.y -= 38.0 * delta
		if age >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(age / life, 0.0, 1.0)
		var a: float = clampf(1.0 - k * k, 0.0, 1.0)
		var font := ThemeDB.fallback_font
		if not plain:
			draw_string_outline(font, Vector2(-30.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, size, 4, Color(0, 0, 0, a))
		draw_string(font, Vector2(-30.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, size, Color(color.r, color.g, color.b, a))



# ---------------------------------------------------------------
# Suelo: cuadricula que sigue a la camara (provisional, hasta tener mapa)
# ---------------------------------------------------------------
class Ground extends Node2D:
	const TILE := 192.0
	var center := Vector2.ZERO

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var half: Vector2 = get_viewport_rect().size * 0.5 + Vector2(TILE, TILE)
		var x0: int = int(floor((center.x - half.x) / TILE))
		var x1: int = int(ceil((center.x + half.x) / TILE))
		var y0: int = int(floor((center.y - half.y) / TILE))
		var y1: int = int(ceil((center.y + half.y) / TILE))
		var tx: Texture2D = WTex.get_t("ground_grass")
		for ix in range(x0, x1 + 1):
			for iy in range(y0, y1 + 1):
				if tx != null:
					draw_texture_rect(tx, Rect2(ix * TILE, iy * TILE, TILE, TILE), false)
				else:
					var c := Color("#1f3d2e")
					if posmod(ix + iy, 2) == 1:
						c = Color("#244632")
					draw_rect(Rect2(ix * TILE, iy * TILE, TILE, TILE), c)



# ---------------------------------------------------------------
# HUD: vida, tiempo, derrotados, pantalla de derrota
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# Minimapa circular (exclusivo del port Android). Terreno detallado que se desplaza
# con el jugador y niebla de exploracion: lo que ya recorriste queda dibujado (mas
# apagado), lo que no, oculto. Iconos: cofres/altares/fuentes cercanos o ya vistos,
# trampas ocultas solo muy cerca, enemigos solo a corta distancia; grietas y jefes
# siempre, como flecha en el borde.
# ---------------------------------------------------------------
# Marcas del minimapa de los eventos y NPC nuevos: [posicion de mundo, color, forma]
func _mm_events() -> Array:
	var out: Array = []
	if kec != null and kec.active != null and is_instance_valid(kec.active):
		out.append([kec.active.position, Color(String(kec.VAR[kec.variant]["col"])), "npc"])
	if rescue != null and rescue.cur != null and String(rescue.cur["state"]) == "active":
		out.append([rescue.cur["pos"], Color("#ff9ad0"), "npc"])
	if alpha != null and alpha.cur != null:
		out.append([alpha.cur["pos"], Color("#ffd23f"), "star"])
	if cave != null and cave.cur != null:
		out.append([cave.cur["pos"], Color("#c8a26a"), "cave"])
	if meteor != null and meteor.crater != null and is_instance_valid(meteor.crater["node"]):
		out.append([meteor.crater["pos"], Color("#ff9a3d"), "star"])
	if mew != null and mew.cur != null and mew.cur.has("labs"):
		for lb in mew.cur["labs"]:
			if is_instance_valid(lb["node"]):
				out.append([lb["node"].position, Color("#c58cff"), "lab"])
	if poi != null and poi.supply != null and is_instance_valid(poi.supply):
		out.append([poi.supply.position, Color("#4fc3ff"), "box"])
	if sec != null:
		for s in sec.sites:
			if is_instance_valid(s):
				out.append([s.position, Color("#d59bff"), "star"])
	return out


class Minimap extends Node2D:
	const N := 50          # tiles guardados en la imagen
	const VIEW := 48       # tiles visibles (diametro)
	const S := 4.0         # pixeles por tile
	const BOX := 192.0     # VIEW * S
	const CT := Vector2(100.0, 100.0)
	const RAD := 96.0
	const SIGHT := 14      # radio (tiles) que se descubre y se ve a pleno color
	const RADAR := 20.0    # radio (tiles) en el que se detectan cofres, altares y fuentes
	const TRAP_R := 9.0    # radio (tiles) en el que se revelan las trampas
	const FOE_R := 12.0    # radio (tiles) en el que se ven enemigos
	const CODE := "shader_type canvas_item;\nuniform vec2 ctr = vec2(100.0, 100.0);\nuniform float rad = 97.0;\nvarying vec2 lp;\nvoid vertex() { lp = VERTEX; }\nvoid fragment() { COLOR.a *= 1.0 - smoothstep(rad - 1.0, rad, distance(lp, ctr)); }\n"
	var m
	var img: Image
	var tex: ImageTexture
	var fog: Image
	var fog_tex: ImageTexture
	var explored := {}
	var ti := Vector2i(99999, 99999)
	var bio := -1
	var sd := -1
	var t := 0.0
	var ring: Node2D

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img = Image.create(N, N, false, Image.FORMAT_RGBA8)
		tex = ImageTexture.create_from_image(img)
		fog = Image.create(N, N, false, Image.FORMAT_RGBA8)
		fog_tex = ImageTexture.create_from_image(fog)
		var sh := Shader.new()
		sh.code = CODE
		var mat := ShaderMaterial.new()
		mat.shader = sh
		material = mat
		ring = MiniRing.new()
		add_child(ring)

	class MiniRing extends Node2D:
		func _draw() -> void:
			var c := Vector2(100.0, 100.0)
			draw_arc(c, 97.0, 0.0, TAU, 96, Color(0.05, 0.11, 0.18, 1.0), 7.0, true)
			draw_arc(c, 93.5, 0.0, TAU, 96, Color("#5fb7e8"), 2.0, true)
			draw_string(ThemeDB.fallback_font, Vector2(c.x - 6.0, 22.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color.WHITE)

	func _tile_color(g, pal: Dictionary, tx: int, ty: int) -> Color:
		var h: float = ARENA.hsh(tx, ty, 31)
		var tt: int = g.terrain(tx, ty)
		var c: Color
		if tt == 1:
			var south: int = g.terrain(tx, ty + 1)
			var north: int = g.terrain(tx, ty - 1)
			if south != 1:
				c = pal["wallFace"][0]
			elif north != 1:
				c = pal["wallLight"]
			else:
				c = pal["wallTop"][int(h * 3.0) % 3]
		elif tt == 2:
			var inner: bool = g.terrain(tx - 1, ty) == 2 and g.terrain(tx + 1, ty) == 2 and g.terrain(tx, ty - 1) == 2 and g.terrain(tx, ty + 1) == 2
			c = pal["liqDeep"] if inner else pal["liq"]
			if h > 0.92:
				c = c.lerp(pal["foam"], 0.55)
		else:
			if g.is_dirt(tx, ty):
				c = pal["dirt"][int(h * 3.0) % 3]
			else:
				c = pal["floor"][int(h * 3.0) % 3]
				if h > 0.965:
					c = pal["flowers"][int(h * 1000.0) % 3]
				elif h < 0.07:
					c = c.lerp(pal["grass"][2], 0.5)
			if g.terrain(tx, ty + 1) == 1:
				c = c.darkened(0.25)
			elif g.terrain(tx + 1, ty) == 2 or g.terrain(tx - 1, ty) == 2 or g.terrain(tx, ty + 1) == 2 or g.terrain(tx, ty - 1) == 2:
				c = c.lerp(pal["shore"], 0.35)
		return c

	func _refresh(i0: Vector2i, full: bool) -> void:
		var g = m.ground
		var pal: Dictionary = g.pal(g.biome)
		var dx: int = i0.x - ti.x
		var dy: int = i0.y - ti.y
		var half: int = N / 2
		if full or absi(dx) >= N or absi(dy) >= N:
			for r in range(N):
				for c in range(N):
					img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
		else:
			var old: Image = img.duplicate()
			img.fill(Color(0, 0, 0, 0))
			img.blit_rect(old, Rect2i(maxi(dx, 0), maxi(dy, 0), N - absi(dx), N - absi(dy)), Vector2i(maxi(-dx, 0), maxi(-dy, 0)))
			var cols: Array = []
			var rows: Array = []
			if dx > 0:
				for c in range(N - dx, N):
					cols.append(c)
			elif dx < 0:
				for c in range(0, -dx):
					cols.append(c)
			if dy > 0:
				for r in range(N - dy, N):
					rows.append(r)
			elif dy < 0:
				for r in range(0, -dy):
					rows.append(r)
			for c in cols:
				for r in range(N):
					img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
			for r in rows:
				for c in range(N):
					img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
		tex.update(img)
		ti = i0

	# Descubre el area alrededor del jugador y repinta la niebla.
	func _fog_update(i0: Vector2i) -> void:
		for oy in range(-SIGHT, SIGHT + 1):
			for ox in range(-SIGHT, SIGHT + 1):
				if ox * ox + oy * oy <= SIGHT * SIGHT:
					explored[Vector2i(i0.x + ox, i0.y + oy)] = true
		var half: int = N / 2
		for r in range(N):
			for c in range(N):
				var tx: int = i0.x - half + c
				var ty: int = i0.y - half + r
				var ox: int = tx - i0.x
				var oy: int = ty - i0.y
				var a := 0.94
				if ox * ox + oy * oy <= SIGHT * SIGHT:
					a = 0.0
				elif explored.has(Vector2i(tx, ty)):
					a = 0.5
				fog.set_pixel(c, r, Color(0.03, 0.05, 0.11, a))
		fog_tex.update(fog)

	var _acc := 0.0

	func _on() -> bool:
		return m.arena == null and not m.jd.active() and not m.hud.dead

	func _process(delta: float) -> void:
		t += delta
		visible = _on()
		if not visible:
			return
		var g = m.ground
		var i0 := Vector2i(floori(m.player.position.x / g.TS), floori(m.player.position.y / g.TS))
		if i0 != ti or bio != g.biome or sd != g.seed_v:
			var full: bool = bio != g.biome or sd != g.seed_v
			bio = g.biome
			sd = g.seed_v
			_refresh(i0, full)
			_fog_update(i0)
			_acc = 1.0
		_acc += delta
		if _acc >= 0.04:   # 25 veces por segundo bastan para el minimapa
			_acc = 0.0
			queue_redraw()

	func _pt(wp: Vector2) -> Vector2:
		var d: Vector2 = (wp - m.player.position) / m.ground.TS
		return Vector2((d.x + float(VIEW) * 0.5) * S + 4.0, (d.y + float(VIEW) * 0.5) * S + 4.0)

	func _inside(q: Vector2, pad: float = 0.0) -> bool:
		return q.distance_to(CT) <= RAD - pad

	func _edge(q: Vector2) -> Vector2:
		var c := CT
		var d: Vector2 = q - c
		var lim: float = RAD - 12.0
		if d.length() > lim:
			return c + d.normalized() * lim
		return q

	# Sprites del mundo reducidos una sola vez (suavizados) para el minimapa.
	static var icons := {}

	static func _icon(n: String, w: int) -> Texture2D:
		var k: String = "%s_%d" % [n, w]
		if not icons.has(k):
			var tx: Texture2D = WTex.get_t(n)
			if tx == null:
				icons[k] = null
			else:
				var im: Image = tx.get_image()
				var h: int = maxi(1, int(round(float(im.get_height()) * float(w) / float(im.get_width()))))
				im.resize(w, h, Image.INTERPOLATE_LANCZOS)
				icons[k] = ImageTexture.create_from_image(im)
		return icons[k]

	func _spr_at(n: String, w: int, q: Vector2) -> bool:
		var tx: Texture2D = _icon(n, w)
		if tx == null:
			return false
		var sz := Vector2(tx.get_width(), tx.get_height())
		draw_texture(tx, (q - sz * 0.5).round())
		return true

	# Sprite de un Pokemon (fotograma actual) a tamano maximo mx px.
	func _pk_at(a, mx: float, q: Vector2) -> bool:
		if a == null or not is_instance_valid(a) or a.sprite.texture == null:
			return false
		var rr: Rect2 = a.sprite.region_rect
		var k: float = mx / maxf(rr.size.x, rr.size.y)
		var sz: Vector2 = rr.size * k
		var anc: Vector2 = Vector2(-a.sprite.offset.x, -a.sprite.offset.y) * k
		draw_texture_rect_region(a.sprite.texture, Rect2((q - anc + Vector2(0, sz.y * 0.25)).round(), sz), rr)
		return true

	func _tile_of(wp: Vector2) -> Vector2i:
		return Vector2i(floori(wp.x / m.ground.TS), floori(wp.y / m.ground.TS))

	func _draw() -> void:
		var sz: float = BOX
		var c := CT
		draw_circle(c, 97.0, Color(0.03, 0.05, 0.11, 1.0))
		var ppos: Vector2 = m.player.position
		var px: float = ppos.x / m.ground.TS
		var py: float = ppos.y / m.ground.TS
		var fx: float = px - floorf(px)
		var fy: float = py - floorf(py)
		var half: float = float(N) * 0.5
		var src := Rect2(half + fx - float(VIEW) * 0.5, half + fy - float(VIEW) * 0.5, float(VIEW), float(VIEW))
		var dst := Rect2(4.0, 4.0, sz, sz)
		draw_texture_rect_region(tex, dst, src)
		draw_texture_rect_region(fog_tex, dst, src)
		var pul: float = 0.6 + 0.4 * sin(t * 6.0)
		var radar: float = RADAR * m.ground.TS
		# eventos especiales y trampas ocultas
		for key in m.chunks:
			for p in m.chunks[key]["props"]:
				if not is_instance_valid(p) or p.used:
					continue
				var k: String = p.kind
				if k != "chest" and k != "altar" and k != "spring" and k != "trap":
					continue
				var d: float = p.position.distance_to(ppos)
				var q: Vector2 = _pt(p.position)
				if not _inside(q, 6.0):
					continue
				if k == "trap":
					if p.cd > 900.0:
						continue
					var tc := Color("#ff8a2b")
					match String(p.sub):
						"poison":
							tc = Color("#a35cff")
						"ice":
							tc = Color("#5fd8ff")
						"freeze":
							tc = Color("#2f8fe0")
						"shock":
							tc = Color("#ffe14d")
						"sleep":
							tc = Color("#b9b6ff")
						"confuse":
							tc = Color("#ff7ad9")
					draw_circle(q, 10.5, Color(tc.r, tc.g, tc.b, 0.35))
					if not _spr_at("trap_" + String(p.sub), 18, q):
						draw_circle(q, 4.0, tc)
					continue
				var near: bool = d <= radar
				if k == "chest":
					if near:
						draw_arc(q, 11.0 + 2.0 * pul, 0.0, TAU, 20, Color(1.0, 0.85, 0.2, 0.75 * pul), 1.5)
					if not _spr_at("chest_closed", 20, q):
						draw_rect(Rect2(q - Vector2(5, 4), Vector2(10, 8)), Color("#ffd23f"))
				elif k == "altar":
					if near:
						draw_arc(q, 13.0 + 2.0 * pul, 0.0, TAU, 20, Color(p.color.r, p.color.g, p.color.b, 0.8 * pul), 1.5)
					if not _spr_at("altar_" + String(p.power), 16, q):
						draw_circle(q, 5.0, p.color)
				elif k == "spring":
					if not _spr_at("spring_on", 22, q):
						draw_circle(q, 5.0, Color("#2fc6e8"))
		# objetos del suelo: todo menos la experiencia, que llenaria el mapa
		for o in m.orbs:
			if not is_instance_valid(o) or o.kind == "xp" or o.kind == "xpBig":
				continue
			var oq: Vector2 = _pt(o.position)
			if not _inside(oq, 4.0):
				continue
			if o.kind == "coin":
				draw_rect(Rect2(oq - Vector2(1, 1), Vector2(2.5, 2.5)), Color("#ffd23f"))
			else:
				var oi: String = {"item": "star", "heal": "berry"}.get(o.kind, String(o.kind))
				draw_circle(oq, 8.0, Color(0.03, 0.05, 0.11, 0.55))
				if o.kind == "ball":
					draw_circle(oq, 5.0, Color("#e23b3b"))
					draw_circle(oq, 2.0, Color.WHITE)
				else:
					IC.draw_in(self, oi, oq, 14.0)
		# recogidas del mapa (bolsas, pociones, experiencia y paquetes)
		for it in m.poi.items:
			if not is_instance_valid(it) or it.kind == "crate":
				continue
			var iq: Vector2 = _pt(it.position)
			if _inside(iq, 4.0):
				draw_circle(iq, 8.0, Color(0.03, 0.05, 0.11, 0.55))
				IC.draw_in(self, {"pouch": "coin", "potion": "berry", "xp": "book", "pack": "bag"}.get(it.kind, "star"), iq, 14.0)
		# avisos de peligro: erupciones y meteorito
		for hzz in [m.hz.zone, m.meteor.zone]:
			if hzz != null and is_instance_valid(hzz):
				var zq: Vector2 = _pt(hzz.position)
				if _inside(zq, 4.0):
					draw_arc(zq, 7.0 + 2.0 * pul, 0.0, TAU, 16, Color(1.0, 0.35, 0.2, 0.9), 2.0)
					draw_string(ThemeDB.fallback_font, zq + Vector2(-3.0, 5.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#ffd0c0"))
		# enemigos (los ladrones, en dorado y siempre visibles en el borde)
		for e in m.enemies:
			if e.dead or e.boss:
				continue
			if e.behavior == "thief":
				var tq: Vector2 = _edge(_pt(e.position))
				draw_circle(tq, 8.0, Color(1.0, 0.82, 0.25, 0.45 + 0.2 * pul))
				if not _pk_at(e, 16.0, tq):
					draw_circle(tq, 4.0, Color("#ffd23f"))
				continue
			var q: Vector2 = _pt(e.position)
			if _inside(q, 2.0):
				draw_rect(Rect2(q - Vector2(1, 1), Vector2(2.5, 2.5)), Color(1.0, 0.25, 0.3, 0.95))
		# aliados: compañero y legendarios capturados
		for al in [m.partner, m.legend] + m.allies_extra:
			if al != null and is_instance_valid(al):
				var aq: Vector2 = _edge(_pt(al.position))
				draw_circle(aq, 8.0, Color(0.3, 0.75, 1.0, 0.45))
				if not ("sprite" in al) or not _pk_at(al, 16.0, aq):
					draw_circle(aq, 4.0, Color("#4fc3ff"))
		# jefes (siempre, en el borde si estan lejos)
		for e in m.enemies:
			if e.dead or not e.boss:
				continue
			var q: Vector2 = _edge(_pt(e.position))
			draw_circle(q, 11.0, Color(0.88, 0.14, 0.23, 0.45 + 0.2 * pul))
			draw_arc(q, 11.0, 0.0, TAU, 20, Color.WHITE, 1.5)
			if not _pk_at(e, 22.0, q):
				draw_circle(q, 5.0, Color("#e0243a"))
		# grieta (siempre)
		if m.rift != null and is_instance_valid(m.rift):
			var q: Vector2 = _edge(_pt(m.rift.position))
			draw_circle(q, 7.5 + 1.5 * pul, Color(0.7, 0.4, 1.0, 0.35))
			draw_circle(q, 6.0, Color.WHITE)
			draw_circle(q, 4.8, Color("#9b4dff"))
			draw_arc(q, 3.0, 0.0, TAU * 0.75, 12, Color.WHITE, 1.4)
			# brujula: si queda fuera del radio, una puntita apunta hacia ella
			var rq: Vector2 = _pt(m.rift.position)
			if rq.distance_to(CT) > RAD - 12.0:
				var ad: Vector2 = (rq - CT).normalized()
				var base: Vector2 = CT + ad * (RAD - 2.0)
				var perp := Vector2(-ad.y, ad.x)
				draw_colored_polygon(PackedVector2Array([base + ad * 7.0, base - ad * 2.0 + perp * 6.0, base - ad * 2.0 - perp * 6.0]), Color(0.9, 0.82, 1.0, 0.8 + 0.2 * pul))
		# NPC y eventos nuevos (Kecleon, rescates, alfas, cuevas, meteorito, laboratorios, cajas)
		for ev in m._mm_events():
			var eq: Vector2 = _edge(_pt(ev[0]))
			var ec: Color = ev[1]
			var shp: String = String(ev[2])
			draw_circle(eq, 7.0 + 1.0 * pul, Color(ec.r, ec.g, ec.b, 0.4))
			match shp:
				"star":
					draw_colored_polygon(PackedVector2Array([eq + Vector2(0, -6.5), eq + Vector2(2, -2), eq + Vector2(6.5, -1.5), eq + Vector2(2.5, 1.5), eq + Vector2(4, 6), eq + Vector2(0, 3), eq + Vector2(-4, 6), eq + Vector2(-2.5, 1.5), eq + Vector2(-6.5, -1.5), eq + Vector2(-2, -2)]), ec)
				"cave":
					draw_colored_polygon(PackedVector2Array([eq + Vector2(-6, 5), eq + Vector2(-4, -2), eq + Vector2(0, -6), eq + Vector2(4, -2), eq + Vector2(6, 5)]), ec)
					draw_rect(Rect2(eq + Vector2(-2, 0), Vector2(4, 5)), Color(0.1, 0.08, 0.14))
				"lab":
					draw_rect(Rect2(eq + Vector2(-5, -5), Vector2(10, 10)), ec)
					draw_rect(Rect2(eq + Vector2(-2, -2), Vector2(4, 4)), Color(0.15, 0.05, 0.25))
				"box":
					draw_rect(Rect2(eq + Vector2(-5, -4), Vector2(10, 8)), ec)
					draw_line(eq + Vector2(-5, 0), eq + Vector2(5, 0), Color.WHITE, 1.2)
				_:
					draw_circle(eq, 4.5, ec)
					draw_circle(eq + Vector2(0, -1.5), 1.6, Color.WHITE)
			draw_arc(eq, 7.5, 0.0, TAU, 14, Color.WHITE, 1.2)
		# jugador
		draw_circle(c, 9.0, Color(1, 1, 1, 0.35))
		draw_arc(c, 9.0, 0.0, TAU, 20, Color("#ffd23f"), 1.5)
		if not _pk_at(m.player, 20.0, c):
			draw_circle(c, 3.0, Color("#ffd23f"))


class Hud extends Node2D:
	func _ds(f: Font, p: Vector2, t: String, a: int, w: float, sz: int, c: Color) -> void:
		draw_string(f, p, t, a, w, roundi(float(sz) * TXS.k()), c)

	func _dso(f: Font, p: Vector2, t: String, a: int, w: float, sz: int, o: int, c: Color) -> void:
		draw_string_outline(f, p, t, a, w, roundi(float(sz) * TXS.k()), o, c)

	var hp := 1.0
	var max_hp := 1.0
	var run_time := 0.0
	var kills := 0
	var dead := false
	var z_dim := 0.0
	var z_state := ""
	var z_t := 0.0
	var join_t := -1.0
	var join_name := ""
	var join_col := Color.WHITE
	var z_name := ""
	var z_type := ""
	var z_btn := 0
	var z_cd := 0.0
	var dyn_cd := 0.0
	var adapt_pct := 0
	var dyn_left := -1.0
	var dyn_flash := 99.0
	var dyn_type := "normal"
	var dyn_btn := 0
	var act_txt := ""
	var act_sp := Vector2(-9999.0, -9999.0)
	var poi_marks: Array = []
	var rift_den := false
	var ab_name := ""
	var down := false
	var down_left := 0.0
	var pbar := 1.0
	var show_end := false
	var poke_name := ""
	var portrait: Texture2D = null
	var level := 1
	var xp := 0.0
	var xp_next := 1.0
	var buff_text := ""
	var power_id := ""
	var items_hud: Array = []
	var _page_t := 0.0
	var item_name := ""
	var item_id := ""
	var item2_name := ""
	var item2_id := ""
	var item3_name := ""
	var item3_id := ""
	var weather_text := ""
	var banner := ""
	var fusion_t := 0.0
	var fusion_name := ""
	var coins := 0
	var balls := 0
	var tickets := 0
	var tickets10 := 0
	var paused := false
	var show_fps := false
	var show_stats := false
	var revives := 0
	var stats: Array = []
	var rift_dir := Vector2.ZERO
	var rift_ttl := -1.0
	var rift_off := false
	var rift_scr := Vector2.ZERO
	var rift_m := 0
	var arena_left := -1.0
	var legend_name := ""
	var legend_frac := -1.0
	var arena_won := false
	var toast: Dictionary = {}
	var toast_t := 0.0

	var _acc := 0.0

	var rift_notice := -1.0
	var thieves_hud: Array = []
	var thief_notice := -1.0
	var thief_name := ""
	var thief_gold := false
	var death_t := 0.0

	func _process(delta: float) -> void:
		if rift_notice >= 0.0:
			rift_notice += delta
			if rift_notice >= 4.5:
				rift_notice = -1.0
		if thief_notice >= 0.0:
			thief_notice += delta
			if thief_notice >= 4.0:
				thief_notice = -1.0
		_page_t += delta
		_acc += delta
		if _acc >= 0.033:   # el HUD se redibuja 30 veces por segundo (texto y barras)
			_acc = 0.0
			queue_redraw()

	# Poderes activos (mejoras de altar, buffs) y objeto: a la derecha, bajo el boton de pausa.
	func _chip(font: Font, rx: float, y: float, txt: String, col: Color, icon: Texture2D, icon_name: String) -> void:
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
		var iw: float = 34.0 if (icon != null or icon_name != "") else 0.0
		var w: float = tw + iw + 26.0
		var x0: float = rx - w
		_panel(Rect2(x0, y - 24.0, w, 38.0), PANEL_BG, col, 2, 8)
		var tx: float = x0 + 13.0
		if icon != null:
			var h: float = 30.0
			var sw: float = float(icon.get_width()) * h / float(icon.get_height())
			draw_texture_rect(icon, Rect2(Vector2(tx + 14.0 - sw * 0.5, y - 20.0), Vector2(sw, h)), false)
			tx += iw
		elif icon_name != "":
			IC.draw_in(self, icon_name, Vector2(tx + 14.0, y - 5.0), 26.0)
			tx += iw
		_ds(font, Vector2(tx, y + 2.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col)

	# ---- Piezas del HUD: paneles redondeados, Poke Ball y hojas ----
	const PANEL_BG := Color(0.05, 0.11, 0.18, 0.93)
	const PANEL_GOLD := Color("#e8c94f")
	const ROW_BG := Color(0.08, 0.15, 0.24, 0.96)
	const ROW_COLS := [Color("#ff6fd0"), Color("#ffc83d"), Color("#4fd0ff")]

	func _panel(r: Rect2, bg: Color, border: Color, bw: int, rad: int) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.set_border_width_all(bw)
		sb.set_corner_radius_all(rad)
		draw_style_box(sb, r)

	func _ball(c: Vector2, r: float) -> void:
		draw_circle(c, r, Color("#14181f"))
		draw_circle(c, r - 1.5, Color("#f4f6f8"))
		var top := PackedVector2Array()
		for i in range(13):
			top.append(c + Vector2.from_angle(PI + PI * float(i) / 12.0) * (r - 1.5))
		draw_colored_polygon(top, Color("#e23b3b"))
		draw_line(c - Vector2(r, 0.0), c + Vector2(r, 0.0), Color("#14181f"), maxf(1.5, r * 0.2))
		draw_circle(c, r * 0.36, Color("#14181f"))
		draw_circle(c, r * 0.2, Color("#f4f6f8"))

	func _leaf(c: Vector2, ang: float, ln: float, col: Color) -> void:
		var d: Vector2 = Vector2.from_angle(ang)
		var s: Vector2 = d.orthogonal() * ln * 0.3
		draw_colored_polygon(PackedVector2Array([c, c + d * ln * 0.45 + s, c + d * ln, c + d * ln * 0.45 - s]), col)
		draw_line(c, c + d * ln * 0.85, col.darkened(0.3), 1.0)

	func _sprig(c: Vector2, ang: float, ln: float) -> void:
		_leaf(c, ang - 0.6, ln * 0.8, Color("#3f9e3a"))
		_leaf(c, ang + 0.6, ln * 0.8, Color("#3f9e3a"))
		_leaf(c, ang, ln, Color("#6cc548"))

	func _rock(c: Vector2, w: float) -> void:
		var h: float = w * 0.62
		draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.5, 0.0), c + Vector2(-w * 0.34, -h * 0.7), c + Vector2(0.0, -h), c + Vector2(w * 0.38, -h * 0.68), c + Vector2(w * 0.5, 0.0)]), Color("#747c84"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.34, -h * 0.7), c + Vector2(0.0, -h), c + Vector2(w * 0.1, -h * 0.5), c + Vector2(-w * 0.2, -h * 0.42)]), Color("#a2a9b0"))

	# Hojas y rocas en las esquinas de abajo y alrededor del minimapa
	func draw_corners(vp: Vector2) -> void:
		_rock(Vector2(46.0, vp.y), 44.0)
		_sprig(Vector2(92.0, vp.y), -PI * 0.5, 36.0)
		_sprig(Vector2(12.0, vp.y - 26.0), -PI * 0.35, 34.0)
		_rock(Vector2(vp.x - 50.0, vp.y), 58.0)
		_sprig(Vector2(vp.x - 98.0, vp.y), -PI * 0.5, 36.0)
		_sprig(Vector2(vp.x - 12.0, vp.y - 30.0), -PI * 0.65, 34.0)

	func _sub_pill(font: Font, vp: Vector2, txt: String, col: Color) -> void:
		var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x + 34.0
		_panel(Rect2((vp.x - w) * 0.5, 47.0, w, 25.0), PANEL_BG, Color("#6d7f91"), 2, 12)
		_ds(font, Vector2(0.0, 65.0), txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 15, col)

	func draw_player(font: Font, ins: Vector4, frac: float, col: Color) -> void:
		var o := Vector2(12.0 + ins.x, 8.0 + ins.y)
		_panel(Rect2(o, Vector2(306.0, 68.0)), PANEL_BG, Color("#dfe9f2"), 2, 16)
		if portrait != null:
			# El fotograma trae margen transparente: se dibuja mas grande para que el Pokemon llene el hueco
			var h: float = 72.0
			var sw: float = float(portrait.get_width()) * h / maxf(1.0, float(portrait.get_height()))
			draw_texture_rect(portrait, Rect2(o + Vector2(32.0 - sw * 0.5, -12.0), Vector2(sw, h)), false)
		_ds(font, o + Vector2(62.0, 22.0), L.t("%s  PS %d/%d") % [poke_name, ceili(hp), ceili(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, 234.0, 16, Color.WHITE)
		_panel(Rect2(o + Vector2(62.0, 28.0), Vector2(232.0, 13.0)), Color(0.0, 0.0, 0.0, 0.65), Color("#aeb9c4"), 1, 6)
		if frac > 0.0:
			_panel(Rect2(o + Vector2(64.0, 30.0), Vector2(228.0 * frac, 9.0)), col, col, 0, 4)
		_panel(Rect2(o + Vector2(6.0, 46.0), Vector2(58.0, 20.0)), Color("#1a58ab"), Color("#7fb2ee"), 1, 10)
		_ds(font, o + Vector2(6.0, 61.0), L.t("Nv. %d") % level, HORIZONTAL_ALIGNMENT_CENTER, 58.0, 14, Color.WHITE)
		_ds(font, o + Vector2(76.0, 61.0), "EXP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PANEL_GOLD)
		_panel(Rect2(o + Vector2(114.0, 50.0), Vector2(180.0, 11.0)), Color(0.0, 0.0, 0.0, 0.65), Color("#aeb9c4"), 1, 5)
		var xf: float = clampf(xp / xp_next, 0.0, 1.0)
		if xf > 0.0:
			_panel(Rect2(o + Vector2(116.0, 52.0), Vector2(176.0 * xf, 7.0)), Color("#7fe0ff"), Color("#7fe0ff"), 0, 3)
		for ri in range(revives):
			IC.draw_in(self, "revive", o + Vector2(286.0 - float(ri) * 20.0, 13.0), 16.0)
		_sprig(Vector2(18.0 + ins.x, 104.0 + ins.y), -PI * 0.8, 26.0)
		_sprig(Vector2(198.0 + ins.x, 104.0 + ins.y), -PI * 0.2, 26.0)
		_sprig(Vector2(18.0 + ins.x, 264.0 + ins.y), PI * 0.8, 26.0)
		_sprig(Vector2(198.0 + ins.x, 264.0 + ins.y), PI * 0.2, 26.0)

	# Marco comun: cuerpo con borde dorado y cabecera en pastilla que sobresale por arriba
	func _titled_panel(font: Font, x: float, y: float, w: float, body_h: float, title: String, up_icon: bool) -> void:
		_panel(Rect2(x, y + 14.0, w, body_h), PANEL_BG, PANEL_GOLD, 2, 16)
		var hr := Rect2(x + 8.0, y, w - 16.0, 30.0)
		if up_icon:
			_panel(hr, PANEL_BG, PANEL_GOLD, 2, 14)
			var a: Vector2 = hr.position + Vector2(19.0, 15.0)
			draw_colored_polygon(PackedVector2Array([a + Vector2(0.0, -10.0), a + Vector2(9.0, 0.0), a + Vector2(4.0, 0.0), a + Vector2(4.0, 9.0), a + Vector2(-4.0, 9.0), a + Vector2(-4.0, 0.0), a + Vector2(-9.0, 0.0)]), PANEL_GOLD)
		else:
			_panel(hr, Color("#174a86"), Color("#9fd0ff"), 2, 14)
			_ball(hr.position + Vector2(19.0, 15.0), 10.0)
		var fs: int = 15
		while fs > 10 and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x > hr.size.x - 42.0:
			fs -= 1
		_ds(font, hr.position + Vector2(34.0, 21.0), title, HORIZONTAL_ALIGNMENT_CENTER, hr.size.x - 40.0, fs, Color.WHITE)

	# Izquierda: objetos equipados (con su recarga). Derecha: mejoras con su nivel; con muchas cambia de pagina cada 4 s.
	func draw_items(font: Font, ins: Vector4) -> void:
		var held: Array = []
		for e in items_hud:
			if int(e["lv"]) <= 0:
				held.append(e)
		if held.is_empty():
			return
		var x0: float = 12.0 + ins.x
		var y0: float = 288.0 + ins.y + ((18.0 * stats.size() + 14.0) if (show_stats and not stats.is_empty()) else 0.0)
		_titled_panel(font, x0, y0, 196.0, 26.0 + 38.0 * float(held.size()), L.t("Objetos equipados"), false)
		for i in range(held.size()):
			var e: Dictionary = held[i]
			var r := Rect2(x0 + 10.0, y0 + 36.0 + float(i) * 38.0, 176.0, 34.0)
			_panel(r, ROW_BG, Color("#55687c"), 1, 8)
			IC.draw_in(self, String(e["icon"]), r.position + Vector2(18.0, 17.0), 24.0)
			var right := ""
			var rcol := Color("#ffe58a")
			if float(e["cd"]) >= 0.0:
				if float(e["cd"]) <= 0.0:
					right = L.t("Listo")
					rcol = Color("#7dffb0")
				else:
					right = "%ds" % ceili(float(e["cd"]))
					var act: bool = bool(e.get("act", false))
					rcol = Color("#8fe0ff") if act else Color("#ff9a7a")
					var k: float = clampf(float(e["cd"]) / maxf(1.0, float(e["cdmax"])), 0.0, 1.0)
					draw_rect(Rect2(r.position.x + 34.0, r.end.y - 6.0, 134.0, 3.0), Color(0, 0, 0, 0.5))
					draw_rect(Rect2(r.position.x + 34.0, r.end.y - 6.0, 134.0 * (k if act else 1.0 - k), 3.0), rcol)
			_ds(font, r.position + Vector2(34.0, 22.0), L.t(String(e["name"])), HORIZONTAL_ALIGNMENT_LEFT, 134.0 - (34.0 if right != "" else 0.0), 14, Color.WHITE)
			if right != "":
				_ds(font, r.position + Vector2(34.0, 22.0), right, HORIZONTAL_ALIGNMENT_RIGHT, 134.0, 13, rcol)
		_ball(Vector2(x0 + 98.0, y0 + 40.0 + 38.0 * float(held.size())), 6.0)

	func draw_powers(font: Font, vp: Vector2, ins: Vector4) -> void:
		var rx: float = vp.x - 16.0 - ins.z
		var y: float = 100.0
		# Sin pisar lo que ya hay a la derecha: los botones de equipo y los objetivos del reto
		if not team.is_empty():
			rx -= 184.0
		if ch_mode:
			y = 134.0 + 20.0 * float(ch_lines.size()) + 24.0
		if buff_text != "":
			_chip(font, rx, y, L.t(buff_text), PANEL_GOLD, WTex.get_t("altar_" + power_id) if power_id != "" else null, "")
			y += 22.0
		else:
			y -= 24.0
		var ups: Array = []
		for e in items_hud:
			if int(e["lv"]) > 0:
				ups.append(e)
		if ups.is_empty():
			return
		# Termina antes del boton Dynamax (y = alto - 442)
		var per: int = clampi(int((vp.y - 442.0 - ins.w - 12.0 - y - 36.0) / 36.0), 1, 3)
		var pages: int = (ups.size() + per - 1) / per
		var page: int = int(_page_t / 4.0) % pages
		var rows: int = mini(per, ups.size() - page * per)
		var x0: float = rx - 190.0
		_titled_panel(font, x0, y, 190.0, 24.0 + 36.0 * float(rows), L.t("Mejoras"), true)
		for i in range(rows):
			var e: Dictionary = ups[page * per + i]
			var pc: Color = ROW_COLS[i % ROW_COLS.size()]
			var r := Rect2(x0 + 8.0, y + 34.0 + float(i) * 36.0, 174.0, 33.0)
			_panel(r, ROW_BG, pc if i == 0 else Color("#55687c"), 2 if i == 0 else 1, 8)
			IC.draw_in(self, String(e["icon"]), r.position + Vector2(18.0, 16.0), 24.0)
			_ds(font, r.position + Vector2(36.0, 14.0), L.t(String(e["name"])), HORIZONTAL_ALIGNMENT_LEFT, 134.0, 13, Color.WHITE)
			var lv: int = int(e["lv"])
			for p in range(5):
				draw_rect(Rect2(r.position.x + 36.0 + float(p) * 15.0, r.position.y + 19.0, 13.0, 8.0), pc if p < lv else Color(1, 1, 1, 0.18))
			if lv > 5:
				_ds(font, r.position + Vector2(36.0, 28.0), "%d" % lv, HORIZONTAL_ALIGNMENT_RIGHT, 130.0, 13, pc)
		if pages > 1:
			_ds(font, Vector2(x0, y + 34.0 + 36.0 * float(rows) + 2.0), "%d/%d" % [page + 1, pages], HORIZONTAL_ALIGNMENT_RIGHT, 182.0, 11, Color(1, 1, 1, 0.7))

	func draw_thief_notice(font: Font, vp: Vector2) -> void:
		if thief_notice < 0.0:
			return
		var a: float = minf(1.0, minf(thief_notice * 4.0, (4.0 - thief_notice) * 2.0))
		var pop: float = 1.0 + maxf(0.0, 0.25 - thief_notice) * 1.6
		var t1: String = L.t("¡%s merodea cerca!") % thief_name
		var t2: String = L.t("Sigue la flecha dorada: ¡trae un ticket ×10!") if thief_gold else L.t("Sigue la flecha dorada: ¡va cargado de monedas!")
		var w1: float = font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26).x
		var w2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		var bw: float = minf(vp.x - 24.0, maxf(w1, w2) + 48.0)
		draw_set_transform(Vector2(vp.x * 0.5, vp.y * 0.2), 0.0, Vector2(pop, pop))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.14, 0.02, 0.88 * a)
		sb.border_color = Color(1.0, 0.82, 0.25, a)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		draw_style_box(sb, Rect2(-bw * 0.5, -34.0, bw, 68.0))
		_ds(font, Vector2(-bw * 0.5, -4.0), t1, HORIZONTAL_ALIGNMENT_CENTER, bw, 26, Color(1.0, 0.92, 0.55, a))
		_ds(font, Vector2(-bw * 0.5, 22.0), t2, HORIZONTAL_ALIGNMENT_CENTER, bw, 16, Color(1.0, 0.85, 0.45, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Brujula hacia los duendes del tesoro: flecha en el borde (o sobre su cabeza si ya los ves) con distancia y tiempo.
	func draw_thieves(font: Font, vp: Vector2) -> void:
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 7.0)
		var gcol: Color = Color("#ffd23f") if beat > 0.5 else Color("#fff0a0")
		for th in thieves_hud:
			var sp: Vector2 = th["sp"]
			var off: bool = sp.x < 0.0 or sp.x > vp.x or sp.y < 0.0 or sp.y > vp.y
			var label: String = "%s · %d m · %d s" % [String(th["name"]), int(th["m"]), ceili(float(th["life"]))]
			if off:
				var M := 52.0
				var e := Vector2(clampf(sp.x, M, vp.x - M), clampf(sp.y, M + 70.0, vp.y - M - 80.0))
				if e.x > vp.x - 150.0 and e.y < 150.0:
					e.y = 150.0
				var a: float = (sp - e).angle()
				draw_circle(e, 30.0 + beat * 8.0, Color(1.0, 0.82, 0.25, 0.16 + beat * 0.22))
				draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 45.0, e + Vector2.from_angle(a + 2.45) * 22.0, e + Vector2.from_angle(a - 2.45) * 22.0]), Color("#3a2606"))
				draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 40.0, e + Vector2.from_angle(a + 2.45) * 20.0, e + Vector2.from_angle(a - 2.45) * 20.0]), gcol)
				var ca: float = cos(a)
				var ha := HORIZONTAL_ALIGNMENT_RIGHT if ca > 0.3 else (HORIZONTAL_ALIGNMENT_LEFT if ca < -0.3 else HORIZONTAL_ALIGNMENT_CENTER)
				var lp: Vector2 = e + Vector2(-ca * 34.0, -sin(a) * 30.0 + 4.0)
				var lw: float = 260.0
				var lx: float = lp.x - (lw if ha == HORIZONTAL_ALIGNMENT_RIGHT else (0.0 if ha == HORIZONTAL_ALIGNMENT_LEFT else lw * 0.5))
				_dso(font, Vector2(lx, lp.y), label, ha, lw, 16, 5, Color(0, 0, 0, 0.85))
				_ds(font, Vector2(lx, lp.y), label, ha, lw, 16, Color("#ffe27a"))
			else:
				var by: float = sp.y - 60.0 - absf(sin(Time.get_ticks_msec() * 0.001 * 4.0)) * 10.0
				var p := Vector2(sp.x, by)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-17.0, -14.0), p + Vector2(17.0, -14.0), p + Vector2(0.0, 11.0)]), Color("#3a2606"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(14.0, -12.0), p + Vector2(0.0, 8.0)]), gcol)
				_dso(font, p + Vector2(-110.0, -22.0), label, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 15, 5, Color(0, 0, 0, 0.85))
				_ds(font, p + Vector2(-110.0, -22.0), label, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 15, Color("#ffe27a"))

	func draw_rift_notice(font: Font, vp: Vector2) -> void:
		if rift_notice < 0.0:
			return
		var a: float = minf(1.0, minf(rift_notice * 4.0, (4.5 - rift_notice) * 2.0))
		var pop: float = 1.0 + maxf(0.0, 0.25 - rift_notice) * 1.6
		var t1: String = L.t("¡SE HA ABIERTO UNA GRIETA!")
		var t2: String = L.t("Sigue la flecha morada: dentro te espera un legendario")
		if rift_den:
			t1 = L.t("¡SE HA ABIERTO UNA GUARIDA DYNAMAX!")
			t2 = L.t("Sigue la flecha roja: dentro te espera un Pokémon gigante")
		var w1: float = font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26).x
		var w2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		var bw: float = minf(vp.x - 24.0, maxf(w1, w2) + 48.0)
		draw_set_transform(Vector2(vp.x * 0.5, vp.y * 0.2), 0.0, Vector2(pop, pop))
		var r := Rect2(-bw * 0.5, -34.0, bw, 68.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.102, 0.043, 0.2, 0.88 * a)
		sb.border_color = Color(1.0, 0.24, 0.43, a) if rift_den else Color(0.706, 0.541, 1.0, a)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		draw_style_box(sb, r)
		_ds(font, Vector2(-bw * 0.5, -4.0), t1, HORIZONTAL_ALIGNMENT_CENTER, bw, 26, Color(0.886, 0.816, 1.0, a))
		_ds(font, Vector2(-bw * 0.5, 22.0), t2, HORIZONTAL_ALIGNMENT_CENTER, bw, 16, Color(0.788, 0.69, 1.0, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Cartel de captura: mismo estilo que el del Movimiento Z (franja, rayos y letras que caen).
	func draw_join(font: Font, vp: Vector2) -> void:
		if join_t < 0.0:
			return
		var t: float = join_t
		var cy: float = vp.y * 0.36
		var tcol: Color = join_col
		var open: float = _ease_out(clampf(t / 0.25, 0.0, 1.0))
		var out: float = clampf((3.2 - t) / 0.4, 0.0, 1.0)
		var al: float = open * out
		var hh: float = 54.0 * open
		var hi := Color(minf(1.0, tcol.r + 0.3), minf(1.0, tcol.g + 0.3), minf(1.0, tcol.b + 0.3), al)
		draw_rect(Rect2(0.0, cy - hh, vp.x, hh * 2.0), Color(tcol.r * 0.22, tcol.g * 0.22, tcol.b * 0.22, 0.8 * al))
		draw_rect(Rect2(0.0, cy - hh - 3.0, vp.x, 5.0), hi)
		draw_rect(Rect2(0.0, cy + hh - 2.0, vp.x, 5.0), hi)
		for i in range(14):
			var ra: float = float(i) * TAU / 14.0 + t * 0.5
			var rl: float = vp.x * 0.9
			var c0 := Vector2(vp.x * 0.5, cy)
			draw_colored_polygon(PackedVector2Array([c0, c0 + Vector2.from_angle(ra - 0.07) * rl, c0 + Vector2.from_angle(ra + 0.07) * rl]), Color(tcol.r, tcol.g, tcol.b, 0.14 * al))
		# subtitulo con letras que se separan
		var sub: String = L.t("¡FELICIDADES!")
		var sp: float = lerpf(1.0, 12.0, _ease_out(clampf((t - 0.05) / 0.6, 0.0, 1.0)))
		var sx: float = vp.x * 0.5 - (font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + sp * float(sub.length() - 1)) * 0.5
		for i in range(sub.length()):
			var chs: String = sub.substr(i, 1)
			_ds(font, Vector2(sx, cy - 20.0), chs, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.85 * al))
			sx += font.get_string_size(chs, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + sp
		# nombre: cada letra cae con un golpe y rebote
		var txt: String = join_name
		var fs: int = 44 if vp.x >= 900.0 else 30
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cx: float = vp.x * 0.5 - tw * 0.5
		var n: int = txt.length()
		for i in range(n):
			var ch: String = txt.substr(i, 1)
			var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var ts: float = 0.2 + float(i) * (0.45 / float(maxi(n, 1)))
			var pr: float = clampf((t - ts) / 0.26, 0.0, 1.0)
			if pr > 0.0:
				var scl: float = lerpf(3.0, 1.0, _ease_back(pr))
				var ca: float = clampf(pr * 5.0, 0.0, 1.0) * out
				var shk: Vector2 = Vector2.ZERO
				if t < ts + 0.4:
					shk = Vector2(sin(t * 90.0 + float(i)) * 3.0, cos(t * 70.0 + float(i) * 2.0) * 3.0) * clampf(1.0 - (t - ts) / 0.4, 0.0, 1.0)
				draw_set_transform(Vector2(cx + cw * 0.5, cy + 24.0) + shk, 0.0, Vector2(scl, scl))
				var base := Color(minf(1.0, tcol.r * 0.45 + 0.55), minf(1.0, tcol.g * 0.45 + 0.55), minf(1.0, tcol.b * 0.45 + 0.55), ca)
				for o in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
					_ds(font, Vector2(-cw * 0.5, 0.0) + o, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tcol.r, tcol.g, tcol.b, 0.55 * ca))
				_ds(font, Vector2(-cw * 0.5 + 3.0, 4.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7 * ca))
				_ds(font, Vector2(-cw * 0.5, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, base)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			cx += cw


	func draw_fusion(f: Font, vp: Vector2) -> void:
		if fusion_t <= 0.0:
			return
		var tt: float = 2.8 - fusion_t
		var fin: float = clampf(tt / 0.35, 0.0, 1.0)
		var fout: float = clampf(fusion_t / 0.6, 0.0, 1.0)
		var al: float = fin * fout
		var cy: float = vp.y * 0.38
		# franja oscura y destellos que cruzan la pantalla
		draw_rect(Rect2(0.0, cy - 70.0 * fin, vp.x, 140.0 * fin), Color(0.05, 0.0, 0.1, 0.55 * al))
		draw_rect(Rect2(0.0, cy - 72.0 * fin, vp.x, 3.0), Color(1.0, 0.85, 1.0, 0.9 * al))
		draw_rect(Rect2(0.0, cy + 70.0 * fin, vp.x, 3.0), Color(1.0, 0.85, 1.0, 0.9 * al))
		var sx: float = fmod(tt * 1400.0, vp.x + 400.0) - 200.0
		draw_rect(Rect2(sx, cy - 70.0, 90.0, 140.0), Color(1.0, 1.0, 1.0, 0.18 * al))
		# texto largo: las letras se abren y se asientan
		var txt := "F U S I O N !"
		var sz: int = roundi(clampf(vp.x / 11.0, 34.0, 96.0) * (1.0 + 0.25 * (1.0 - fin)) * TXS.k())
		var wob: float = 1.0 + 0.04 * sin(tt * 14.0)
		var fs: int = roundi(float(sz) * wob)
		var pos := Vector2(0.0, cy + float(fs) * 0.33)
		draw_string_outline(f, pos + Vector2(0.0, 5.0), txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, 14, Color(0.25, 0.0, 0.35, al))
		draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, 10, Color(1.0, 0.45, 0.85, al))
		draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, Color(1.0, 0.97, 0.8, al))
		if fusion_name != "":
			draw_string_outline(f, Vector2(0.0, cy + 62.0), fusion_name, HORIZONTAL_ALIGNMENT_CENTER, vp.x, roundi(26.0 * TXS.k()), 6, Color(0.1, 0.0, 0.2, al))
			draw_string(f, Vector2(0.0, cy + 62.0), fusion_name, HORIZONTAL_ALIGNMENT_CENTER, vp.x, roundi(26.0 * TXS.k()), Color(1.0, 0.9, 0.5, al))

	func draw_rift(font: Font, vp: Vector2) -> void:
		if rift_ttl >= 0.0:
			var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 7.0)
			var tcol: Color = Color("#e2d0ff")
			var fcol: Color = Color("#e2d0ff") if beat > 0.5 else Color("#a06bff")
			var lbl: String = L.t("GRIETA ·")
			if rift_den:
				tcol = Color("#ffd0d6")
				fcol = Color("#ffd0d6") if beat > 0.5 else Color("#ff3d6e")
				lbl = L.t("GUARIDA ·")
			if rift_off:
				# Borde de pantalla: halo que late + flecha grande + "GRIETA · N m · S s"
				var M := 52.0
				var e := Vector2(clampf(rift_scr.x, M, vp.x - M), clampf(rift_scr.y, M + 70.0, vp.y - M - 80.0))
				if e.x > vp.x - 150.0 and e.y < 150.0:
					e.y = 150.0   # no tapar el boton de pausa
				var a: float = (rift_scr - e).angle()
				draw_circle(e, 30.0 + beat * 8.0, Color(0.706, 0.541, 1.0, 0.18 + beat * 0.22))
				var big := PackedVector2Array([e + Vector2.from_angle(a) * 45.0, e + Vector2.from_angle(a + 2.45) * 22.0, e + Vector2.from_angle(a - 2.45) * 22.0])
				draw_colored_polygon(big, Color("#1a0b33"))
				draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 40.0, e + Vector2.from_angle(a + 2.45) * 20.0, e + Vector2.from_angle(a - 2.45) * 20.0]), fcol)
				var label: String = "%s %d m · %d s" % [lbl, rift_m, ceili(rift_ttl)]
				var ca: float = cos(a)
				var ha := HORIZONTAL_ALIGNMENT_RIGHT if ca > 0.3 else (HORIZONTAL_ALIGNMENT_LEFT if ca < -0.3 else HORIZONTAL_ALIGNMENT_CENTER)
				var lp: Vector2 = e + Vector2(-ca * 34.0, -sin(a) * 30.0 + 4.0)
				var lw: float = 240.0
				var lx: float = lp.x - (lw if ha == HORIZONTAL_ALIGNMENT_RIGHT else (0.0 if ha == HORIZONTAL_ALIGNMENT_LEFT else lw * 0.5))
				_dso(font, Vector2(lx, lp.y), label, ha, lw, 16, 5, Color(0, 0, 0, 0.85))
				_ds(font, Vector2(lx, lp.y), label, ha, lw, 16, tcol)
			else:
				# Encima de la grieta: flecha que bota con la cuenta atras
				var by: float = rift_scr.y - 46.0 - absf(sin(Time.get_ticks_msec() * 0.001 * 4.0)) * 10.0
				var p := Vector2(rift_scr.x, by)
				var tri := PackedVector2Array([p + Vector2(-17.0, -14.0), p + Vector2(17.0, -14.0), p + Vector2(0.0, 11.0)])
				draw_colored_polygon(tri, Color("#1a0b33"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(14.0, -12.0), p + Vector2(0.0, 8.0)]), fcol)
				var l2: String = "%s %d s" % [lbl, ceili(rift_ttl)]
				_dso(font, p + Vector2(-100.0, -22.0), l2, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, 5, Color(0, 0, 0, 0.85))
				_ds(font, p + Vector2(-100.0, -22.0), l2, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, tcol)
		if legend_frac >= 0.0:
			var w: float = minf(440.0, vp.x - 360.0)
			var x0: float = vp.x * 0.5 - w * 0.5
			draw_rect(Rect2(x0 - 2.0, vp.y - 148.0, w + 4.0, 22.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(x0, vp.y - 146.0, w * clampf(legend_frac, 0.0, 1.0), 18.0), Color("#b06bff"))
			_ds(font, Vector2(x0, vp.y - 154.0), legend_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#e6d4ff"))
			if arena_left >= 0.0:
				_ds(font, Vector2(x0, vp.y - 154.0), "%02d:%02d" % [int(arena_left) / 60, int(arena_left) % 60], HORIZONTAL_ALIGNMENT_RIGHT, w, 18, Color("#ffd33d") if arena_left > 20.0 else Color("#ff6b7a"))

	var team: Array = []
	var swap_cd := 0.0
	var limit := 0.0
	var ch_lines: Array = []
	var ch_mode := false
	var rifts_n := 0
	var timeup := false
	var end_big := ""
	var end_l1 := ""
	var end_l2 := ""
	var tower_floor := 0
	var tower_t := 0.0
	var tower_risk := 0
	var reap_pct := -1.0

	func team_rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		var out: Array = []
		for i in range(team.size()):
			out.append(Rect2(vp.x - 190.0 - ins.z, 126.0 + float(i) * 52.0, 174.0, 46.0))
		return out

	func draw_team(font: Font) -> void:
		var rs: Array = team_rects()
		for i in range(team.size()):
			var t: Dictionary = team[i]
			var r: Rect2 = rs[i]
			var cur: bool = bool(t["cur"])
			draw_rect(r, Color(0.08, 0.12, 0.25, 0.72) if not cur else Color(0.2, 0.32, 0.62, 0.85))
			draw_rect(r, Color("#ffd23f") if cur else Color(1, 1, 1, 0.45), false, 2.0)
			var dead: bool = bool(t["dead"])
			_ds(font, r.position + Vector2(8.0, 20.0), String(t["name"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, 16, Color(0.6, 0.6, 0.65) if dead else Color.WHITE)
			var f: float = clampf(float(t["frac"]), 0.0, 1.0)
			draw_rect(Rect2(r.position + Vector2(8.0, 29.0), Vector2(r.size.x - 16.0, 9.0)), Color(0, 0, 0, 0.6))
			var c2 := Color("#5fe08a") if f > 0.5 else (Color("#ffd33d") if f > 0.25 else Color("#ff6b7a"))
			draw_rect(Rect2(r.position + Vector2(9.0, 30.0), Vector2((r.size.x - 18.0) * f, 7.0)), c2)
			if not cur and swap_cd > 0.0 and not dead:
				draw_rect(r, Color(0, 0, 0, 0.35))

	func _ease_out(x: float) -> float:
		return 1.0 - pow(1.0 - x, 3.0)

	func _ease_back(x: float) -> float:
		var c1: float = 1.70158
		var c3: float = c1 + 1.0
		return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)

	func _bounce(x: float) -> float:
		var n1 := 7.5625
		var d1 := 2.75
		if x < 1.0 / d1:
			return n1 * x * x
		elif x < 2.0 / d1:
			x -= 1.5 / d1
			return n1 * x * x + 0.75
		elif x < 2.5 / d1:
			x -= 2.25 / d1
			return n1 * x * x + 0.9375
		x -= 2.625 / d1
		return n1 * x * x + 0.984375

	func z_rect() -> Rect2:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return Rect2(vp.x - 126.0 - ins.z, vp.y - 330.0 - ins.w, 100.0, 100.0)

	func act_rect() -> Rect2:
		var vp: Vector2 = get_viewport_rect().size
		if act_sp.x > -9000.0:   # v5.2: el botón de abrir se dibuja en el centro del cofre / caja
			return Rect2(act_sp - Vector2(50.0, 50.0), Vector2(100.0, 100.0))
		var ins: Vector4 = DSP.insets(get_tree())
		# S22: boton de accion a media altura (derecha por defecto; izquierda segun Ajustes > Controles)
		var left: bool = int(SV.d["settings"].get("act_side", 0)) == 1
		var ax: float = (26.0 + ins.x) if left else (vp.x - 126.0 - ins.z)
		# v5.2.2: encima del boton Dynamax (antes caia justo debajo y se solapaban)
		var ay: float = vp.y * 0.5 - 50.0
		if not left:
			var dy: float = vp.y - 442.0 - ins.w
			ay = minf(ay, dy - 114.0)
			if ay < 150.0:   # pantalla baja: al costado del boton Dynamax en vez de encima
				return Rect2(ax - 114.0, dy, 100.0, 100.0)
		return Rect2(ax, ay, 100.0, 100.0)

	func draw_poi(font: Font, vp: Vector2) -> void:
		for mk in poi_marks:
			var sp: Vector2 = mk["sp"]
			var col: Color = mk["col"]
			var on: bool = Rect2(Vector2(30, 70), vp - Vector2(60, 140)).has_point(sp)
			if on:
				_ds(font, sp + Vector2(-120, -28), String(mk["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 240.0, 18, col)
			else:
				var c: Vector2 = vp * 0.5
				var dir: Vector2 = (sp - c).normalized()
				var q: Vector2 = Vector2(clampf(sp.x, 40.0, vp.x - 40.0), clampf(sp.y, 90.0, vp.y - 90.0))
				draw_circle(q, 18.0, Color(0, 0, 0, 0.6))
				draw_colored_polygon(PackedVector2Array([q + dir * 14.0, q + dir.rotated(2.5) * 12.0, q + dir.rotated(-2.5) * 12.0]), col)
		if act_txt != "":
			var r: Rect2 = act_rect()
			var c2: Vector2 = r.position + r.size * 0.5
			var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			draw_circle(c2, 52.0 + beat * 5.0, Color(1, 0.85, 0.3, 0.22 + 0.2 * beat))
			draw_circle(c2, 46.0, Color(0.1, 0.07, 0.02, 0.9))
			draw_arc(c2, 46.0, 0.0, TAU, 40, Color("#ffd23f"), 4.0)
			_ds(font, Vector2(c2.x - 44.0, c2.y + 8.0), act_txt, HORIZONTAL_ALIGNMENT_CENTER, 88.0, _fit_size(font, act_txt, 84.0, 26), Color.WHITE)

	# Mayor tamano de letra (hasta mx) con el que el texto cabe en w pixeles.
	func _fit_size(font: Font, txt: String, w: float, mx: int) -> int:
		var sz: int = mx
		while sz > 11 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, sz).x > w:
			sz -= 1
		return sz

	func dyn_rect() -> Rect2:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return Rect2(vp.x - 126.0 - ins.z, vp.y - 442.0 - ins.w, 100.0, 100.0)

	# Dynamax: boton (listo / bloqueado por nivel), barra de tiempo, borde rojo y cartel "DYNAMAX" al activarse.
	func draw_dyn(font: Font, vp: Vector2) -> void:
		var tcol: Color = Color("#ff3d6e")
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 6.0)
		if dyn_left >= 0.0:
			var a: float = 0.10 + 0.06 * beat
			var th: float = 26.0
			draw_rect(Rect2(0, 0, vp.x, th), Color(1.0, 0.1, 0.3, a))
			draw_rect(Rect2(0, vp.y - th, vp.x, th), Color(1.0, 0.1, 0.3, a))
			draw_rect(Rect2(0, 0, th, vp.y), Color(1.0, 0.1, 0.3, a))
			draw_rect(Rect2(vp.x - th, 0, th, vp.y), Color(1.0, 0.1, 0.3, a))
			var w: float = minf(360.0, vp.x - 380.0)
			var x0: float = vp.x * 0.5 - w * 0.5
			var fr: float = clampf(dyn_left / DYN.DUR, 0.0, 1.0)
			draw_rect(Rect2(x0 - 2.0, 62.0, w + 4.0, 20.0), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(x0, 64.0, w * fr, 16.0), tcol if fr > 0.25 else Color("#ffb347"))
			_ds(font, Vector2(x0, 58.0), "DYNAMAX  %d s" % ceili(dyn_left), HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color.WHITE)
		if dyn_flash < 2.7:
			var fl: float = clampf(1.0 - dyn_flash / 0.25, 0.0, 1.0)
			if fl > 0.0:
				draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.6, 0.7, 0.45 * fl))
			var al: float = clampf((2.7 - dyn_flash) / 0.5, 0.0, 1.0)
			var fs: int = 84
			var word := "DYNAMAX"
			var widths: Array = []
			var tw: float = 0.0
			for ch in word:
				var cw: float = font.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x + 3.0
				widths.append(cw)
				tw += cw
			var x0: float = vp.x * 0.5 - tw * 0.5
			var by: float = vp.y * 0.30
			var shine: float = (dyn_flash - 0.9) / 0.9 * (tw + 160.0) - 80.0
			var cx: float = x0
			for i in range(word.length()):
				var loc: float = dyn_flash - 0.35 - float(i) * 0.08
				var cwid: float = float(widths[i])
				if loc >= 0.0:
					var k: float = clampf(loc / 0.55, 0.0, 1.0)
					var drop: float = (1.0 - _bounce(k)) * 190.0
					var sc: float = 1.0 + 0.35 * maxf(0.0, 1.0 - loc / 0.25)
					var wave: float = sin(dyn_flash * 5.0 - float(i) * 0.7) * 5.0 * clampf((dyn_flash - 1.2) / 0.3, 0.0, 1.0)
					var ox: float = cx + cwid * 0.5
					var oy: float = by - drop + wave
					draw_set_transform(Vector2(ox, oy), 0.0, Vector2(sc, sc))
					var base: Color = Color("#ff2f63").lerp(Color("#ffd6e0"), clampf(float(i) / 6.0 + 0.15 * sin(dyn_flash * 6.0 - float(i)), 0.0, 1.0))
					var pos := Vector2(-cwid * 0.5, 0.0)
					_dso(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, 16, Color(0.22, 0.0, 0.1, 0.92 * al))
					_ds(font, pos + Vector2(3.0, 9.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.55, 0.0, 0.2, 0.9 * al))
					_ds(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(base.r, base.g, base.b, al))
					var sh: float = clampf(1.0 - absf(cx + cwid * 0.5 - shine) / 55.0, 0.0, 1.0)
					if sh > 0.0:
						_ds(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1.0, 1.0, 1.0, sh * 0.9 * al))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					# chispas al aterrizar
					if loc < 0.45:
						var burst: float = 1.0 - loc / 0.45
						for q in range(5):
							var ang: float = float(q) * 1.256 + float(i)
							draw_circle(Vector2(ox, by - 28.0) + Vector2.from_angle(ang) * (loc * 260.0), 3.0 * burst + 1.0, Color(1.0, 0.85, 0.9, burst * al))
				cx += cwid
		draw_poi(font, vp)
		if dyn_btn > 0:
			var r: Rect2 = dyn_rect()
			var c: Vector2 = r.position + r.size * 0.5
			var ready: bool = dyn_btn == 2
			if ready:
				draw_circle(c, 52.0 + beat * 6.0, Color(tcol.r, tcol.g, tcol.b, 0.25 + beat * 0.25))
			draw_circle(c, 46.0, Color(0.14, 0.03, 0.07, 0.88))
			draw_arc(c, 46.0, 0.0, TAU, 40, tcol if ready else Color(0.5, 0.52, 0.58), 4.0)
			_ds(font, Vector2(c.x - 44.0, c.y + (2.0 if dyn_btn == 3 else 11.0)), "MAX", HORIZONTAL_ALIGNMENT_CENTER, 88.0, 28 if dyn_btn == 3 else 32, Color.WHITE if ready else Color(0.6, 0.62, 0.68))
			if dyn_btn == 3:
				_ds(font, Vector2(c.x - 44.0, c.y + 26.0), "%d:%02d" % [int(dyn_cd) / 60, int(dyn_cd) % 60], HORIZONTAL_ALIGNMENT_CENTER, 88.0, 18, Color(0.85, 0.88, 0.95))
			elif not ready:
				_ds(font, Vector2(c.x - 50.0, c.y + 70.0), L.t("Min 3"), HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))

	func draw_z(font: Font, vp: Vector2) -> void:
		var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(z_type, "#ffffff")))
		if z_dim > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.04, z_dim))
		if z_state == "cine":
			var T: float = ZM.CINE_T
			var cy: float = vp.y * 0.42
			var open: float = _ease_out(clampf((z_t - 0.05) / 0.3, 0.0, 1.0))
			var fade: float = clampf((T - z_t) / 0.3, 0.0, 1.0)
			var al: float = open * fade
			# Rayos giratorios detras del cartel
			var rl: float = vp.x * 0.9
			for i in range(16):
				var ra: float = float(i) * TAU / 16.0 + z_t * 0.5
				var w: float = 0.075
				draw_colored_polygon(PackedVector2Array([Vector2(vp.x * 0.5, cy), Vector2(vp.x * 0.5, cy) + Vector2.from_angle(ra - w) * rl, Vector2(vp.x * 0.5, cy) + Vector2.from_angle(ra + w) * rl]), Color(tcol.r, tcol.g, tcol.b, 0.16 * al))
			# Cartel que se abre
			var hh: float = 66.0 * open
			draw_rect(Rect2(0.0, cy - hh, vp.x, hh * 2.0), Color(tcol.r * 0.22, tcol.g * 0.22, tcol.b * 0.22, 0.8 * fade))
			draw_rect(Rect2(0.0, cy - hh - 3.0, vp.x, 5.0), Color(minf(1.0, tcol.r + 0.3), minf(1.0, tcol.g + 0.3), minf(1.0, tcol.b + 0.3), fade))
			draw_rect(Rect2(0.0, cy + hh - 2.0, vp.x, 5.0), Color(minf(1.0, tcol.r + 0.3), minf(1.0, tcol.g + 0.3), minf(1.0, tcol.b + 0.3), fade))
			# Lineas de velocidad
			for i in range(22):
				var h1: float = fmod(float(i) * 0.6180339 + 0.13, 1.0)
				var h2: float = fmod(float(i) * 0.7548776 + 0.29, 1.0)
				var yy: float = cy - 120.0 + h1 * 240.0
				var xx: float = fposmod(h2 * vp.x - z_t * (900.0 + h1 * 700.0), vp.x + 300.0) - 150.0
				draw_rect(Rect2(xx, yy, 90.0 + h2 * 120.0, 2.0), Color(1, 1, 1, 0.28 * al))
			# Cristal Z que aparece sobre el cartel y late
			var cr_p: float = 1.0 + 0.08 * sin(z_t * 9.0)
			var cr_c := Vector2(vp.x * 0.5, cy - 112.0 * open)
			draw_circle(cr_c, 58.0 * cr_p, Color(tcol.r, tcol.g, tcol.b, 0.22 * al))
			draw_circle(cr_c, 38.0 * cr_p, Color(1, 1, 1, 0.16 * al))
			IC.draw_in(self, "zc:" + z_type, cr_c, 24.0 * 5.0 * cr_p * open, Color(1, 1, 1, al))
			# Subtitulo con letras que se separan
			var sub: String = L.t("MOVIMIENTO Z")
			var sp: float = lerpf(1.0, 14.0, _ease_out(clampf((z_t - 0.1) / 0.6, 0.0, 1.0)))
			var sx: float = vp.x * 0.5 - (font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + sp * float(sub.length() - 1)) * 0.5
			for i in range(sub.length()):
				var ch: String = sub.substr(i, 1)
				_ds(font, Vector2(sx, cy - 28.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85 * al))
				sx += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + sp
			# Nombre: cada letra cae con un golpe y rebote
			var fs: int = 60 if vp.x >= 900.0 else 40
			var tw: float = font.get_string_size(z_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var x0: float = vp.x * 0.5 - tw * 0.5
			var sweep: float = vp.x * clampf((z_t - 1.0) / 0.75, 0.0, 1.0) * 1.3 - vp.x * 0.15
			var cx: float = x0
			var n: int = z_name.length()
			for i in range(n):
				var ch: String = z_name.substr(i, 1)
				var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var ts: float = 0.35 + float(i) * (0.5 / float(maxi(n, 1)))
				var pr: float = clampf((z_t - ts) / 0.26, 0.0, 1.0)
				if pr > 0.0:
					var scl: float = lerpf(3.4, 1.0, _ease_back(pr))
					var ca: float = clampf(pr * 5.0, 0.0, 1.0) * fade
					var shk: Vector2 = Vector2.ZERO
					if pr < 1.0 or z_t < ts + 0.4:
						shk = Vector2(sin(z_t * 90.0 + float(i)) * 3.0, cos(z_t * 70.0 + float(i) * 2.0) * 3.0) * clampf(1.0 - (z_t - ts) / 0.4, 0.0, 1.0)
					var pos: Vector2 = Vector2(cx + cw * 0.5, cy + 22.0) + shk
					draw_set_transform(pos, 0.0, Vector2(scl, scl))
					var shine: float = clampf(1.0 - absf((cx + cw * 0.5) - sweep) / 110.0, 0.0, 1.0)
					var base: Color = Color(minf(1.0, tcol.r * 0.45 + 0.55), minf(1.0, tcol.g * 0.45 + 0.55), minf(1.0, tcol.b * 0.45 + 0.55), ca)
					var fc: Color = base.lerp(Color(1, 1, 1, ca), shine)
					for o in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
						_ds(font, Vector2(-cw * 0.5, 0.0) + o, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tcol.r, tcol.g, tcol.b, 0.55 * ca))
					_ds(font, Vector2(-cw * 0.5 + 3.0, 4.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7 * ca))
					_ds(font, Vector2(-cw * 0.5, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fc)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				cx += cw
			# Destello blanco con el primer golpe
			var fl: float = clampf(1.0 - absf(z_t - 0.38) / 0.12, 0.0, 1.0)
			if fl > 0.0:
				draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, 0.5 * fl))
		if z_btn > 0:
			var r: Rect2 = z_rect()
			var c: Vector2 = r.position + r.size * 0.5
			var ready: bool = z_btn == 2
			var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 6.0)
			if ready:
				draw_circle(c, 52.0 + beat * 6.0, Color(tcol.r, tcol.g, tcol.b, 0.25 + beat * 0.25))
			draw_circle(c, 46.0, Color(0.05, 0.07, 0.14, 0.85))
			draw_arc(c, 46.0, 0.0, TAU, 40, tcol if ready else Color(0.5, 0.52, 0.58), 4.0)
			var zc: Color = Color.WHITE if ready else Color(0.6, 0.62, 0.68)
			IC.draw_in(self, "zc:" + z_type, c + Vector2(0.0, -2.0 - (beat * 2.0 if ready else 0.0)), 64.0, zc)
			if z_btn == 3:
				_ds(font, Vector2(c.x - 50.0, c.y + 70.0), "%d:%02d" % [int(z_cd) / 60, int(z_cd) % 60], HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))
			elif not ready:
				_ds(font, Vector2(c.x - 50.0, c.y + 70.0), L.t("Min 3"), HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))

	func pause_rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return [Rect2(vp.x - 62.0 - ins.z, 8.0, 48.0, 52.0), Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5, 320.0, 58.0), Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5 + 76.0, 320.0, 58.0)]

	func draw_toast(font: Font, vp: Vector2) -> void:
		if toast_t <= 0.0 or toast.is_empty():
			return
		var a: float = clampf(minf(toast_t, 2.8 - toast_t + 0.001) * 4.0, 0.0, 1.0)
		var txt: String = String(toast["text"])
		var sub: String = String(toast.get("sub", ""))
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		if sub != "":
			tw = maxf(tw, font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
		var w: float = minf(tw + 100.0, vp.x - 40.0)
		var h: float = 64.0 if sub == "" else 82.0
		var x0: float = vp.x * 0.5 - w * 0.5
		var y0: float = 64.0
		var out := StyleBoxFlat.new()
		out.bg_color = Color(0.043, 0.094, 0.22, a)
		out.set_corner_radius_all(15)
		draw_style_box(out, Rect2(x0 - 3.0, y0 - 3.0, w + 6.0, h + 6.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.145, 0.28, 0.6, a)
		sb.border_color = Color(1.0, 0.82, 0.25, a)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		draw_style_box(sb, Rect2(x0, y0, w, h))
		var ic: String = "medal%d" % clampi(int(toast.get("tier", 2)), 1, 3)
		IC.draw_in(self, ic, Vector2(x0 + 36.0, y0 + h * 0.5), 36.0, Color(1, 1, 1, a))
		var ty: float = y0 + (h * 0.5 + 8.0 if sub == "" else 34.0)
		_ds(font, Vector2(x0 + 66.0, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 22, Color(1.0, 0.82, 0.25, a))
		if sub != "":
			_ds(font, Vector2(x0 + 66.0, y0 + 60.0), sub, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 16, Color(0.72, 0.8, 0.94, a))

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		draw_z(font, vp)
		draw_dyn(font, vp)
		draw_toast(font, vp)
		if show_fps:
			_ds(font, Vector2(vp.x - 130.0 - ins.z, vp.y - 12.0 - ins.w), "%d FPS" % int(Engine.get_frames_per_second()), HORIZONTAL_ALIGNMENT_RIGHT, 118.0, 20, Color(1, 1, 1, 0.85))
		var frac: float = clampf(hp / max_hp, 0.0, 1.0)
		var col := Color("#5fe08a")
		if frac <= 0.25:
			col = Color("#ff6b7a")
		elif frac <= 0.5:
			col = Color("#ffd33d")
		draw_corners(vp)
		draw_player(font, ins, frac, col)
		if down:
			var bw: float = 300.0
			var bx: float = vp.x * 0.5 - bw * 0.5
			var by: float = 92.0 + ins.y
			draw_rect(Rect2(bx - 4.0, by - 4.0, bw + 8.0, 70.0), Color(0, 0, 0, 0.5))
			_ds(font, Vector2(bx, by + 16.0), L.t("Espectando: reviveras en %d s") % ceili(down_left), HORIZONTAL_ALIGNMENT_CENTER, bw, 20, Color("#ffd2d8"))
			draw_rect(Rect2(bx, by + 28.0, bw, 14.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(bx + 1.0, by + 29.0, (bw - 2.0) * pbar, 12.0), Color("#9ad0ff"))
			_ds(font, Vector2(bx, by + 60.0), L.t("Vida de tu compañero"), HORIZONTAL_ALIGNMENT_CENTER, bw, 16, Color("#cfe6ff"))
		if show_stats and not stats.is_empty():
			var sy: float = 288.0 + ins.y
			var sx: float = 16.0 + ins.x
			draw_rect(Rect2(sx - 4.0, sy - 2.0, 150.0, 18.0 * stats.size() + 6.0), Color(0, 0, 0, 0.32))
			for row in stats:
				_ds(font, Vector2(sx, sy + 13.0), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, 90.0, 14, Color(1, 1, 1, 0.75))
				_ds(font, Vector2(sx + 40.0, sy + 13.0), String(row[1]), HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 14, Color("#ffe58a"))
				sy += 18.0
		draw_powers(font, vp, ins)
		draw_items(font, ins)
		if not team.is_empty():
			draw_team(font)
		if weather_text != "":
			_ds(font, Vector2(0.0, 92.0), L.t(weather_text), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 18, Color("#cfe2ff"))
		if banner != "":
			_ds(font, Vector2(0.0, 116.0), L.t(banner), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#ffffff"))
		draw_join(font, vp)
		draw_fusion(font, vp)
		draw_rift(font, vp)
		draw_rift_notice(font, vp)
		draw_thief_notice(font, vp)
		draw_thieves(font, vp)
		var tw: float = font.get_string_size(str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var t10w: float = font.get_string_size(str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var cw: float = font.get_string_size(str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var blw: float = font.get_string_size("x%d" % balls, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		# Panel de contadores: se ensancha con las cifras; la pausa queda a su derecha
		var pr_right: float = vp.x - 72.0 - ins.z
		var rx: float = pr_right - 14.0
		var pw: float = maxf(240.0, 28.0 + t10w + tw + cw + 80.0 + 30.0 + (blw + 40.0 if balls > 0 else 0.0))
		var top_r := Rect2(pr_right - pw, 8.0, pw, 60.0)
		_panel(top_r, PANEL_BG, Color("#dfe9f2"), 2, 16)
		_ds(font, Vector2(top_r.position.x, 30.0), L.t("Derrotados: %d") % kills, HORIZONTAL_ALIGNMENT_CENTER, pw, 18, Color.WHITE)
		_ds(font, Vector2(rx - t10w, 58.0), str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#c47bff"))
		IC.draw_in(self, "ticket10", Vector2(rx - t10w - 16.0, 52.0), 24.0)
		rx -= t10w + 40.0
		_ds(font, Vector2(rx - tw, 58.0), str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
		IC.draw_in(self, "ticket", Vector2(rx - tw - 16.0, 52.0), 24.0)
		rx -= tw + 40.0
		_ds(font, Vector2(rx - cw, 58.0), str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
		IC.draw_in(self, "coin", Vector2(rx - cw - 16.0, 52.0), 24.0)
		if balls > 0:
			rx -= cw + 40.0
			_ds(font, Vector2(rx - blw, 58.0), "x%d" % balls, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ff8a8a"))
			var bt2: Texture2D = ALP.ball_tex()
			if bt2 != null:
				draw_texture_rect(bt2, Rect2(Vector2(rx - blw - 30.0, 40.0), Vector2(22.0, 22.0)), false)
		var pr: Array = pause_rects()
		_panel(pr[0], PANEL_BG, Color("#dfe9f2"), 2, 12)
		draw_rect(Rect2(pr[0].position + Vector2(14.0, 15.0), Vector2(7.0, 22.0)), Color.WHITE)
		draw_rect(Rect2(pr[0].position + Vector2(26.0, 15.0), Vector2(7.0, 22.0)), Color.WHITE)
		# Reloj en una pastilla con borde dorado y una Poke Ball a cada lado
		var clk_r := Rect2(vp.x * 0.5 - 110.0, 6.0, 220.0, 42.0)
		_panel(clk_r, PANEL_BG, PANEL_GOLD, 3, 21)
		_ball(Vector2(clk_r.position.x + 26.0, clk_r.get_center().y), 10.0)
		_ball(Vector2(clk_r.end.x - 26.0, clk_r.get_center().y), 10.0)
		var clock: String = "%02d:%02d" % [floori(run_time / 60.0), int(run_time) % 60]
		if limit > 0.0:
			var left: float = maxf(0.0, limit - run_time)
			var lc: String = "%02d:%02d" % [floori(left / 60.0), int(left) % 60]
			_ds(font, Vector2(0.0, 37.0), lc, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 28, Color("#ff6b7a") if left < 30.0 else Color.WHITE)
			if ch_mode:
				var cy := 134.0
				for ln in ch_lines:
					var okc: bool = bool(ln[3])
					var txt: String = String(ln[0])
					if okc:
						txt += "  ✓"
					elif bool(ln[4]):
						var cs: int = int(minf(float(ln[1]), float(ln[2])))
						txt += "  %d:%02d/%d:%02d" % [cs / 60, cs % 60, int(ln[2]) / 60, int(ln[2]) % 60]
					elif float(ln[2]) > 1.0 and float(ln[2]) <= 100000.0:
						txt += "  %d/%d" % [int(minf(float(ln[1]), float(ln[2]))), int(ln[2])]
					var tw2: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
					var px: float = vp.x - 16.0 - ins.z - tw2
					_dso(font, Vector2(px, cy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, 5, Color(0, 0, 0, 0.85))
					_ds(font, Vector2(px, cy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#8fe39b") if okc else Color.WHITE)
					cy += 20.0
			else:
				_sub_pill(font, vp, L.t("Grietas ganadas: %d") % rifts_n, Color("#c9a6ff"))
		else:
			_ds(font, Vector2(0.0, 37.0), L.t(clock), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 28, Color.WHITE)
		if adapt_pct > 0 and tower_floor <= 0 and limit <= 0.0:
			var ac: Color = Color("#8fe39b") if adapt_pct < 100 else (Color("#ffd23f") if adapt_pct == 100 else Color("#ff9a5a"))
			_sub_pill(font, vp, L.t("Reto: %d%%") % adapt_pct, ac)
		if tower_floor > 0:
			var sub: String = L.t("Piso %d / %d") % [tower_floor, TOWER_FLOORS]
			if tower_t >= 0.0:
				sub += "  ·  " + L.t("Jefe en %ds") % int(ceil(tower_t))
			else:
				sub += "  ·  " + L.t("¡Jefe!")
			if tower_risk > 0:
				sub += "  ·  " + L.t("Pactos: %d") % tower_risk
			if reap_pct >= 0.0:
				sub += "  ·  " + L.t("Sed de victoria +%s%%") % ("%.1f" % reap_pct)
			_sub_pill(font, vp, sub, Color("#ffd23f"))
		if dead:
			# Camara lenta: primero se ve caer al Pokemon; despues oscurece y aparece GAME OVER.
			var fade: float = clampf((death_t - 0.3) / 0.35, 0.0, 1.0)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55 * fade))
			if fade > 0.0:
				var ga: float = fade
				var big: String = (end_big if end_big != "" else L.t("¡TIEMPO!")) if timeup else L.t("GAME OVER")
				var bigc: Color = Color(1.0, 0.82, 0.25, ga) if timeup else Color(1.0, 0.36, 0.42, ga)
				_dso(font, Vector2(0.0, vp.y * 0.36), big, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, 10, Color(0, 0, 0, ga))
				_ds(font, Vector2(0.0, vp.y * 0.36), big, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, bigc)
				if timeup:
					_ds(font, Vector2(0.0, vp.y * 0.45 + 10.0), end_l1 if end_l1 != "" else L.t("Grietas ganadas: %d") % rifts_n, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color(1, 1, 1, ga))
					_ds(font, Vector2(0.0, vp.y * 0.45 + 50.0), end_l2 if end_l2 != "" else L.t("Derrotaste %d Pokémon") % kills, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(1, 1, 1, ga))
				else:
					_ds(font, Vector2(0.0, vp.y * 0.45 + 10.0), L.t("Has fallado el reto...") if ch_mode else L.t("Has caído..."), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color(1, 1, 1, ga))
					_ds(font, Vector2(0.0, vp.y * 0.45 + 50.0), L.t("Aguantaste %s y derrotaste %d") % [clock, kills], HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(1, 1, 1, ga))
		if dead:
			if show_end:
				_ds(font, Vector2(0.0, vp.y * 0.45 + 96.0), L.t("Pulsa una tecla, un botón o toca la pantalla para volver al menú"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#ffd33d"))


# ---------------------------------------------------------------
# Clima: tinte suave y pocas particulas (weather.js)
# ---------------------------------------------------------------
class WeatherFx extends Node2D:
	var kind := ""
	var level := 0.0
	var def: Dictionary = {}
	var parts: Array = []

	func setup(d: Dictionary) -> void:
		def = d
		parts.clear()

	func clear() -> void:
		def = {}
		parts.clear()
		queue_redraw()

	func _new_part(vp: Vector2, anywhere: bool) -> Dictionary:
		var y: float = randf() * vp.y if anywhere else -10.0
		if kind == "rain":
			return {"x": randf() * (vp.x + 200.0), "y": y, "vx": -120.0, "vy": 720.0, "t": 0.0, "life": 9.0}
		if kind == "snow":
			return {"x": randf() * vp.x, "y": y, "vx": randf_range(-20.0, 20.0), "vy": randf_range(40.0, 80.0), "t": 0.0, "life": 20.0}
		if kind == "sand":
			return {"x": randf() * vp.x if anywhere else vp.x + 20.0, "y": randf() * vp.y, "vx": randf_range(-520.0, -380.0), "vy": randf_range(20.0, 60.0), "t": 0.0, "life": 9.0}
		return {"x": randf() * vp.x, "y": randf() * vp.y if anywhere else vp.y + 5.0, "vx": randf_range(-8.0, 8.0), "vy": -randf_range(15.0, 30.0), "t": 0.0, "life": 12.0}

	func _process(delta: float) -> void:
		if kind == "" or level <= 0.0 or def.is_empty():
			if not parts.is_empty():
				parts.clear()
				queue_redraw()
			return
		var vp: Vector2 = get_viewport_rect().size
		var want: int = int(float(def["parts"]) * level * (vp.x / 1280.0))
		while parts.size() < want:
			parts.append(_new_part(vp, true))
		if parts.size() > want + 4:
			parts.resize(want)
		for i in range(parts.size()):
			var p: Dictionary = parts[i]
			p["x"] = float(p["x"]) + float(p["vx"]) * delta
			p["y"] = float(p["y"]) + float(p["vy"]) * delta
			p["t"] = float(p["t"]) + delta
			if float(p["y"]) > vp.y + 20.0 or float(p["x"]) < -40.0 or float(p["x"]) > vp.x + 40.0 or float(p["y"]) < -40.0 or float(p["t"]) > float(p["life"]):
				parts[i] = _new_part(vp, false)
		queue_redraw()

	func _draw() -> void:
		if kind == "" or level <= 0.0 or def.is_empty():
			return
		var vp: Vector2 = get_viewport_rect().size
		var t: Array = def["tint"]
		draw_rect(Rect2(Vector2.ZERO, vp), Color(float(t[0]), float(t[1]), float(t[2]), float(t[3]) * level))
		var s: float = maxf(2.0, roundf(vp.x / 640.0))
		for p in parts:
			var pos := Vector2(float(p["x"]), float(p["y"]))
			if kind == "rain":
				draw_line(pos, pos + Vector2(-s * 1.2, -s * 5.0), Color(0.81, 0.89, 1.0, 0.5 * level), s * 0.5)
			elif kind == "snow":
				draw_rect(Rect2(pos, Vector2(s, s)), Color(1, 1, 1, 0.7 * level))
			elif kind == "sand":
				draw_rect(Rect2(pos, Vector2(s * 3.0, s * 0.5)), Color(0.91, 0.81, 0.56, 0.4 * level))
			else:
				draw_rect(Rect2(pos, Vector2(s, s)), Color(1.0, 0.95, 0.69, 0.45 * level))


# ---------------------------------------------------------------
# Joystick tactil flotante: aparece donde pones el dedo
# ---------------------------------------------------------------
# Cambio de Pokemon del Modo Equipo con la pantalla tactil: boton grande + fichas del equipo.
class TeamUi extends Node2D:
	var m: Node = null

	func _btn_rect() -> Rect2:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return Rect2(vp.x - 150.0 - ins.z, vp.y - 214.0 - ins.w, 120.0, 120.0)

	func _live() -> bool:
		return m != null and not m.player.dead and not m.paused and not m.choosing and m.arena_ok_for_ui()

	func _input(event: InputEvent) -> void:
		if not (event is InputEventScreenTouch and event.pressed) or not _live():
			return
		var p: Vector2 = event.position
		var trs: Array = m.hud.team_rects()
		for i in range(trs.size()):
			if (trs[i] as Rect2).has_point(p):
				get_viewport().set_input_as_handled()
				m._swap_team(i)
				return
		if _btn_rect().has_point(p):
			get_viewport().set_input_as_handled()
			m._swap_team(m._team_next())

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if m == null or m.team.size() < 2 or m.player.dead:
			return
		var r: Rect2 = _btn_rect()
		var c: Vector2 = r.get_center()
		var ready: bool = m.swap_cd <= 0.0 and m._team_next() >= 0
		var a: float = 0.85 if ready else 0.4
		draw_circle(c, 52.0, Color(0.08, 0.12, 0.25, 0.6 * a))
		draw_arc(c, 52.0, 0.0, TAU, 48, Color(1.0, 0.82, 0.25, a), 4.0)
		# dos flechas circulares
		draw_arc(c, 24.0, -2.6, 0.2, 20, Color(1, 1, 1, a), 5.0)
		draw_arc(c, 24.0, 0.54, 3.34, 20, Color(1, 1, 1, a), 5.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(30.0, -6.0), c + Vector2(18.0, -6.0), c + Vector2(24.0, 6.0)]), Color(1, 1, 1, a))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-30.0, 6.0), c + Vector2(-18.0, 6.0), c + Vector2(-24.0, -6.0)]), Color(1, 1, 1, a))
		var nx: int = m._team_next()
		if nx >= 0:
			var font := ThemeDB.fallback_font
			draw_string(font, c + Vector2(-70.0, 74.0), String(m.team[nx]["name"]), HORIZONTAL_ALIGNMENT_CENTER, 140.0, 16, Color(1, 1, 1, a))
		if m.swap_cd > 0.0:
			draw_arc(c, 60.0, -PI / 2.0, -PI / 2.0 + TAU * (m.swap_cd / 3.0), 32, Color(1, 0.4, 0.4, 0.9), 4.0)


class Stick extends Node2D:
	var radius := 90.0
	var axis := Vector2.ZERO
	var fixed := false          # joystick fijo (siempre visible abajo a la izquierda)
	var _id := -1
	var _origin := Vector2.ZERO
	var _pos := Vector2.ZERO

	func _home() -> Vector2:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return Vector2(radius + 56.0 + ins.x, vp.y - radius - 56.0 - ins.w)

	func _process(_d: float) -> void:
		if fixed:
			queue_redraw()
		elif _id == -1 and visible:
			pass

	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _id == -1:
				if not fixed and bool(SV.d["settings"].get("manual_aim", false)) and event.position.x > get_viewport_rect().size.x * 0.5:
					return   # con apuntado manual, la mitad derecha es para apuntar
				if fixed:
					var h: Vector2 = _home()
					if event.position.distance_to(h) > radius * 1.8:
						return
					_id = event.index
					_origin = h
					var v0: Vector2 = event.position - h
					if v0.length() > radius:
						v0 = v0.normalized() * radius
					_pos = h + v0
					axis = v0 / radius
				else:
					_id = event.index
					_origin = event.position
					_pos = event.position
			elif not event.pressed and event.index == _id:
				_id = -1
				axis = Vector2.ZERO
			queue_redraw()
		elif event is InputEventScreenDrag and event.index == _id:
			var v: Vector2 = event.position - _origin
			if v.length() > radius:
				v = v.normalized() * radius
			_pos = _origin + v
			axis = v / radius
			queue_redraw()

	func _draw() -> void:
		if _id == -1:
			if fixed:
				var h: Vector2 = _home()
				draw_arc(h, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.2), 3.0)
				draw_circle(h, 28.0, Color(1, 1, 1, 0.18))
			return
		draw_arc(_origin, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(_pos, 28.0, Color(1, 1, 1, 0.45))
