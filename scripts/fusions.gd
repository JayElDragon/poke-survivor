extends RefCounted
# Recetas de Move Fusion: dos movimientos evolucionados al maximo y vinculados se funden en uno solo.
# [id, nombre, movA, movB, descripcion, color]
const R := [
	["inferno_tempest", "Inferno Tempest", "heat-wave", "gust", "Un huracán de fuego que barre todo a su paso.", "#ff6a2a"],
	["thunder_apocalypse", "Thunder Apocalypse", "thunderbolt", "zap-cannon", "Tormenta de rayos devastadora sobre los enemigos.", "#ffe14a"],
	["abyssal_singularity", "Abyssal Singularity", "shadow-ball", "psychic", "Un agujero oscuro que atrae y aplasta.", "#7a4ad8"],
	["absolute_zero", "Absolute Zero", "ice-beam", "hydro-pump", "Congela el agua misma: un rayo de frío absoluto.", "#8fe8ff"],
	["dragon_cataclysm", "Dragon Cataclysm", "dragon-breath", "eruption", "Aliento de dragón y magma en una explosión cataclísmica.", "#d84a3a"],
	["toxic_eden", "Toxic Eden", "solar-beam", "sludge-bomb", "Un jardín venenoso que florece y envenena el área.", "#8ad84a"],
	["heavens_judgment", "Heaven's Judgment", "fleur-cannon", "dazzling-gleam", "Luz divina que juzga a todos los enemigos.", "#ffc8f0"],
	["earthbreaker", "Earthbreaker", "bulldoze", "stone-edge", "Rompe el suelo y lanza rocas afiladas.", "#b8975a"],
	["phantom_legion", "Phantom Legion", "shadow-bone", "infernal-parade", "Una legión de espectros desfila a tu lado.", "#a070e0"],
	["solar_annihilation", "Solar Annihilation", "solar-beam", "hyper-beam", "Un rayo solar de aniquilación total.", "#fff08a"],
	["crimson_execution", "Crimson Execution", "high-jump-kick", "sacred-sword", "Salto y tajo carmesí que ejecuta al objetivo.", "#e0304a"],
	["frozen_thunder", "Frozen Thunder", "thunderbolt", "ice-beam", "Rayos helados que paralizan y congelan.", "#b8f0ff"],
	["celestial_meteor", "Celestial Meteor", "dragon-rage", "meteor-mash", "Lluvia de meteoros dracónicos desde el cielo.", "#ff9a3a"],
	["blood_moon", "Blood Moon", "dream-eater", "hypnosis", "Una luna roja que duerme y devora los sueños.", "#c02050"],
	# extras
	["magma_cyclone", "Magma Cyclone", "magma-storm", "air-slash", "Ciclón de lava cortante.", "#ff7a3a"],
	["blazing_comet", "Blazing Comet", "flamethrower", "meteor-mash", "Un cometa en llamas que cae sobre el grupo.", "#ff8a2a"],
	["storm_wing", "Storm Wing", "thunderbolt", "wing-attack", "Alas cargadas de electricidad que cruzan el mapa.", "#ffe86a"],
	["glacier_storm", "Glacier Storm", "ice-beam", "air-cutter", "Ráfagas de cuchillas de hielo.", "#a8e8ff"],
	["venom_nightmare", "Venom Nightmare", "sludge-bomb", "shadow-ball", "Bombas tóxicas envueltas en sombras.", "#9a5ad0"],
	["tidal_thunder", "Tidal Thunder", "hydro-pump", "thunderbolt", "Ola eléctrica que arrasa al mojado.", "#5ac8ff"],
	# lista 2 (combate y destruccion)
	["volcanic_armageddon", "Volcanic Armageddon", "eruption", "magma-storm", "Invoca volcanes alrededor del jugador que expulsan lava y generan ríos de magma. Los enemigos atrapados reciben quemaduras continuas.", "#ff5a1a"],
	["thunder_prison", "Thunder Prison", "electroweb", "zap-cannon", "Crea una prisión eléctrica alrededor de grupos de enemigos. Los atrapados reciben descargas encadenadas y un cañonazo eléctrico final.", "#4ab8ff"],
	["eternal_blizzard", "Eternal Blizzard", "aurora-beam", "icicle-spear", "Dispara rayos helados giratorios que generan lanzas de hielo. Las lanzas rebotan entre enemigos congelados.", "#7ae8ff"],
	["oceanic_devastation", "Oceanic Devastation", "whirlpool", "crabhammer", "Un remolino arrastra enemigos y crea enormes pinzas de agua que golpean desde lados opuestos.", "#3a8ae8"],
	["natures_wrath", "Nature's Wrath", "leaf-storm", "leech-seed", "Una tormenta de hojas implanta semillas en los enemigos. Las semillas crecen hasta convertirse en raíces que inmovilizan y drenan vida.", "#5ad84a"],
	["divine_execution", "Divine Execution", "sacred-sword", "behemoth-blade", "Una espada celestial atraviesa enemigos, ignora parte de su defensa y deja cortes luminosos.", "#ffe8a0"],
	["meteor_breaker", "Meteor Breaker", "stone-edge", "hammer-arm", "Golpe al suelo que hace emerger enormes columnas de roca y las destruye en fragmentos.", "#c8a060"],
	["phantom_assassin", "Phantom Assassin", "shadow-bone", "cross-poison", "Huesos espectrales envenenados persiguen enemigos y explotan en cruces tóxicas.", "#9a60d8"],
	["dragon_overlord", "Dragon Overlord", "dragon-darts", "dragon-energy", "Dragones de energía buscan objetivos independientes; su potencia depende de la vida actual del jugador.", "#7a5ae8"],
	["sky_execution", "Sky Execution", "air-slash", "axe-kick", "Lanza cuchillas de viento que marcan enemigos y después ejecuta patadas aéreas sobre ellos.", "#a8d8ff"],
	["iron_guillotine", "Iron Guillotine", "anchor-shot", "stone-axe", "Anclas encadenadas inmovilizan enemigos mientras hachas gigantes caen sobre ellos.", "#9aa8b8"],
	["piercing_catastrophe", "Piercing Catastrophe", "drill-run", "stone-edge", "Una perforadora de roca atraviesa hordas y deja púas en el suelo.", "#b89a68"],
	["crimson_barrage", "Crimson Barrage", "blaze-kick", "bolt-beak", "Embestidas ígneas electrificadas que aumentan su daño al conectar rápidamente.", "#ff6a3a"],
	["dragon_cyclone", "Dragon Cyclone", "dragon-breath", "air-cutter", "Un ciclón dracónico gira alrededor del jugador lanzando cuchillas en múltiples direcciones.", "#6a8aff"],
	["shattering_glacier", "Shattering Glacier", "ice-hammer", "ice-ball", "Martillazos de hielo crean enormes bolas congeladas que crecen al golpear y terminan fragmentándose.", "#9ae0ff"],
	# lista 3 (oscuras, psiquicas, venenosas, estrategicas)
	["nightmare_eclipse", "Nightmare Eclipse", "infernal-parade", "night-shade", "Una oscuridad cubre el escenario y libera espectros que causan más daño a enemigos con estados alterados.", "#6a3aa8"],
	["psychic_oblivion", "Psychic Oblivion", "psystrike", "psyshock", "Una explosión mental afecta las defensas enemigas y libera ondas psíquicas sucesivas.", "#e84ab8"],
	["toxic_apocalypse", "Toxic Apocalypse", "sludge-wave", "poison-jab", "Olas venenosas marcan enemigos; después aparecen púas tóxicas debajo de los marcados.", "#a83ad8"],
	["mind_shatter", "Mind Shatter", "psybeam", "mist-ball", "Rayos psíquicos refractados generan ilusiones que atacan a distintos enemigos.", "#f08ae8"],
	["venom_cataclysm", "Venom Cataclysm", "cross-poison", "sludge-bomb", "Cruces venenosas explotan en bombas tóxicas que dejan pequeñas zonas de contaminación.", "#8a3ac8"],
	["spectral_inferno", "Spectral Inferno", "infernal-parade", "mystical-fire", "Llamas fantasmales persiguen enemigos afectados por estados y reducen temporalmente su poder ofensivo.", "#9a5aff"],
	["cosmic_cannon", "Cosmic Cannon", "fleur-cannon", "psystrike", "Un enorme cañón de energía psíquica y hada dispara una explosión concentrada con gran tiempo de recarga.", "#ff9af0"],
	["guardians_sanctuary", "Guardian's Sanctuary", "roost", "milk-drink", "Crea una zona de recuperación que cura gradualmente y concede protección temporal.", "#8affb8"],
	["golden_cataclysm", "Golden Cataclysm", "pay-day", "egg-bomb", "Lanza huevos explosivos dorados. Algunos impactos generan pequeñas cantidades de monedas normales, con límite por activación.", "#ffd84a"],
	["crystal_labyrinth", "Crystal Labyrinth", "stealth-rock", "freeze-dry", "Genera un laberinto temporal de cristales helados que dañan y ralentizan enemigos.", "#8adaff"],
	["solar_sandstorm", "Solar Sandstorm", "scorching-sands", "eruption", "Tormentas de arena ardiente avanzan por el mapa y dejan pequeños cráteres.", "#ffa83a"],
	["phantom_whirlpool", "Phantom Whirlpool", "whirlpool", "shadow-bone", "Un remolino oscuro atrae enemigos mientras huesos espectrales giran en su interior.", "#5a6ad8"],
	["razor_dimension", "Razor Dimension", "slash", "air-slash", "Cortes dimensionales atraviesan la pantalla, con mayor probabilidad de golpes críticos.", "#d8e8ff"],
	["frostfire_cataclysm", "Frostfire Cataclysm", "ice-burn", "magma-storm", "Alterna zonas de calor y frío; los enemigos afectados por ambos elementos sufren una explosión térmica.", "#ff8a9a"],
	["celestial_barrage", "Celestial Barrage", "dragon-darts", "fleur-cannon", "Proyectiles dracónicos marcan objetivos y un cañón de luz golpea las marcas simultáneamente.", "#ffc8ff"],
]


static func find(a: String, b: String) -> Dictionary:
	for r in R:
		if (r[2] == a and r[3] == b) or (r[2] == b and r[3] == a):
			return {"id": r[0], "name": r[1], "a": r[2], "b": r[3], "desc": r[4], "col": r[5]}
	return {}
