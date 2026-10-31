extends RefCounted
# Novedades de cada version, como la pestaña "What's new" del original: lista de versiones (la mas nueva arriba) con
# titulo, fecha y secciones Nuevo / Cambios / Arreglos. Van dentro del juego (sin internet) y traducidas con L.t.
# PARA CADA ACTUALIZACION: anade una entrada NUEVA ARRIBA del todo en ENTRIES (ver = mismo numero que
# application/config/version), escribe sus lineas en espanol y anade sus traducciones a los 9 idiomas.

const SV = preload("res://scripts/save_data.gd")
const UPD = preload("res://scripts/updater.gd")

const ENTRIES := [
	{
		"ver": "6.1",
		"date": "2026-10-31",
		"title": "Poke Survivors 6.1: nueva tienda de Kecleon, más vínculos y gacha más justo",
		"new": [
			"Tienda de Kecleon rediseñada: un puesto de mercado con cartas de colores, icono, precio y botón de comprar.",
			"Nuevo botón Skip en la pantalla de objetos: ignora el objeto recogido sin cambiar nada.",
			"En PC, la rueda del ratón o las teclas + y - cambian la Visión durante la partida.",
		],
		"changes": [
			"Los objetos ahora ciclan: salen todos antes de repetirse y, tras 2 cofres sin objeto, el siguiente da uno seguro.",
			"Las cuevas solo aparecen de los tipos del Pokémon que estás usando.",
			"Los vínculos son siempre de 2 movimientos, pero puedes crear más parejas mientras te queden movimientos libres.",
			"Si encuentras otro objeto en el suelo, siempre puedes cambiarlo por el que llevas: se ha quitado el bloqueo de objetos.",
			"Interfaz de partida rediseñada: paneles más limpios, con los objetos equipados a la izquierda y las mejoras a la derecha.",
			"El minimapa ahora lo muestra todo: cofres, altares, fuentes, trampas, objetos, secretos, ladrones, aliados, enemigos y peligros.",
			"Pantalla de Ajustes rediseñada en todas sus pestañas.",
			"Pantalla de Mejoras permanentes rediseñada.",
			"Pantalla de Jugar rediseñada.",
			"Menú principal rediseñado.",
			"Iconos nuevos para todos los tipos.",
			"12 objetos nuevos en la tienda de Kecleon, 2 por cada rareza.",
			"Cada Kecleon del mapa tiene el color de su rareza; el dorado brilla con destellos.",
			"Pantalla de Misiones y logros rediseñada en todas sus pestañas.",
			"Nuevo filtro por tipo en el menú de Pokémon.",
			"Descartar un objeto ahora solo dura la partida actual; los objetos descartados en versiones anteriores vuelven a salir.",
			"Las subidas de nivel y los objetos recogidos durante un Movimiento Z se eligen cuando termina, para no congelar la partida.",
			"Menos parpadeo de la interfaz cuando hay muchos enemigos y proyectiles en pantalla.",
			"Los Pokémon shiny lanzan sus ataques con colores propios.",
			"Gacha: cuanto más completes un banner, más salen los Pokémon que te faltan.",
			"Gacha: con el banner completado, la probabilidad de shiny sube del 1% al 5%.",
			"Las mejoras de Kecleon tienen textos más claros.",
			"Nuevos dibujos de puño y palma en Golpe Kárate, A Bocajarro y Puño Sombra.",
			"A Bocajarro es una ráfaga constante de puños y palmas que solo golpea al frente; Viento Hielo es un viento constante.",
			"Pantalla de novedades rediseñada: lista de versiones, banner con paisaje y secciones de colores.",
			"Pantallas de Acerca de y Apoyar el proyecto rediseñadas.",
			"Las Púas Tóxicas van invertidas y Lanza Mugre ahora es un escopetazo de ácido.",
			"Nueva opción Temblor de pantalla en Ajustes: Normal, Reducido o Apagado.",
			"Cometa Draco ahora es de verdad una lluvia de meteoros dracónicos.",
			"Una docena de movimientos que se parecían demasiado ahora se ven distintos.",
			"Fragmento Infinito ya no depende de tus mejoras normales: ahora aumenta todo tu daño un 12%.",
			"Tienda de Kecleon: puedes cambiar las ofertas sin límite mientras tengas monedas; el precio sube con cada cambio y se reinicia en la siguiente visita.",
		],
		"fixes": [
			"Arreglado el zoom en PC: el Tamaño de pantalla ya no recorta la vista y la rueda del ratón no cambia los ajustes sin querer.",
		],
	},
	{
		"ver": "5.7",
		"date": "2026-10-27",
		"title": "Poke Survivors 5.7: adiós al lag de los movimientos evolucionados y fusión",
		"changes": [
			"Mucho menos lag en partidas largas: los movimientos evolucionados y fusión usan muchas menos partículas y efectos más ligeros.",
			"Si el juego empieza a ir a tirones, los efectos de los movimientos evolucionados y fusión se reducen solos y vuelven cuando todo va fluido. El daño no cambia.",
			"Los movimientos evolucionados y fusión salen delante de tu Pokémon, y tu Pokémon siempre se ve por encima de los efectos.",
			"Las ondas de las habilidades evolucionadas (pulsos, torbellinos, estasis…) ya no provocan tirones.",
			"Los rayos, tajos y olas de los movimientos fusión son más finos y translúcidos para que veas la pantalla.",
			"Los modos de Rendimiento Ahorro y Mínimo ahora también aligeran los movimientos evolucionados.",
		],
		"fixes": [
			"Arreglado: tu Pokémon ya no se oscurece con el eclipse, la luna sangrienta ni los vórtices oscuros de los movimientos fusión.",
		],
	},
	{
		"ver": "5.6",
		"date": "2026-10-22",
		"title": "Poke Survivors 5.6: menos lag y mejor rendimiento",
		"new": [
			"Nueva opción Rendimiento (en Pausa > Opciones y en Ajustes): Normal, Ahorro o Mínimo. Quita estelas y partículas y simplifica los efectos de los movimientos fusión sin cambiar el daño.",
		],
		"changes": [
			"Menos lag en partidas largas: hay un tope de disparos del jugador en pantalla y los números de daño se limitan cuando hay demasiados.",
			"Los movimientos fusión ahora se disparan delante del jugador (no desde dentro) para que veas a tu Pokémon.",
			"Mando: desde la rejilla de Pokémon, al ir a la izquierda llegas directo al botón Elegir (compañero).",
			"Mando: al cambiar el tipo en el modo Tipo (y botones parecidos) el cursor se queda en el mismo botón en vez de volver arriba.",
			"Mando: el stick izquierdo en los menús es más lento al mantenerlo (ya no va «a turbo»).",
		],
	},
	{
		"ver": "5.5",
		"date": "2026-10-22",
		"title": "Poke Survivors 5.5: gran parche de balance y mejoras",
		"new": [
			"Bloqueo de objetos: con el interruptor activo, los objetos nuevos se ignoran cuando ya llevas los que quieres (salvo el Caramelo Raro).",
			"Nuevo botón «Descartar siempre» en la pantalla de objetos: ese objeto no vuelve a aparecer.",
		],
		"changes": [
			"El botón de abrir cofres y cajas aparece en el centro del cofre.",
			"En las grietas puedes seguir vinculando movimientos tras vencer al jefe y no sales hasta elegir. Si no quedan movimientos que vincular, el vínculo se descarta.",
			"El resumen de la partida muestra los objetos y lo que hace cada movimiento.",
			"Gacha: la protección de mala suerte llega a las 90 tiradas (antes 70) y el ticket morado da legendario con menos probabilidad.",
			"Las barras de desplazamiento son más gruesas para tocarlas mejor.",
			"Kecleon: el botón de comerciar aparece sobre su cabeza (también con el botón de aceptar) y la tienda ya no activa Dynamax por error.",
			"Poltchageist ahora suelta Gachapon Coins (y, muy rara vez, una dorada). Gholdengo solo da tickets y Meowth solo monedas; los tres aparecen por turnos.",
			"Escaldar (Pistola Agua evolucionada) ahora tiene un 30% de probabilidad de quemar.",
			"Ajustes en PC: nuevo modo de ventana y resolución de la ventana.",
			"Lanzallamas: más dispersión (abanico más ancho, +1 llama) y un pequeño empuje desde el nivel 1.",
			"Poké Balls: ahora también puedes capturar jefes normales (no los de grieta) y Pokémon gigantes cuando caen, con un máximo de 2 aliados por partida. Las Poké Balls son menos abundantes (máximo 6).",
			"Nuevos Pokémon gigantes: Snorlax, Gyarados, Rhyperior, Aggron, Metagross, Golem, Lapras y Dragonite.",
			"Enamorar: los movimientos Hada ahora tienen un 40% de probabilidad de enamorar y hacen más daño.",
			"Descripciones de objetos reescritas con sus valores reales (Cinta Elección, Vidasfera, Cascabel Concha, Casco Dentado, Incienso Puro, Gafas Protectoras).",
			"Al capturar un jefe o gigante, entra en la Poké Ball y sale de ella al unirse. Ahora ataca con sus ataques de jefe (pisotón, embestida, salto, lluvia, rayos, onda y salvas) y se corrigió el parpadeo de su sprite.",
			"A partir del minuto 20 el juego se vuelve mucho más difícil (más enemigos, más fuertes y más élites) hasta la Sentencia de Arceus en el minuto 30.",
			"En la Sentencia de Arceus no se puede huir para siempre: la velocidad tiene un tope suave, Arceus acelera, su toque quita cada vez más vida a partir de los 7 min y los legendarios corren al menos al 80% de tu velocidad.",
			"Arceus ahora tiene 5.000.000 de vida en la Sentencia: es posible derrotarlo, pero hace falta un build fuerte.",
			"La partida Normal vuelve a terminar a los 30 min con la Sentencia de Arceus (se quita el jefe final Eternatus a los 60 min, que hacía fallar el juego).",
			"Los movimientos ahora evolucionan solo con subirlos al nivel máximo, sin necesitar mejoras de estadísticas ni objetos.",
			"Más enemigos al principio de la partida para subir de nivel más rápido.",
			"Dificultad aún más suave: aparecen menos enemigos y crecen más despacio, para llegar a los 20 minutos con mucha más facilidad.",
			"Dificultad más suave: los enemigos ganan vida y daño más despacio con el tiempo y los primeros niveles piden menos experiencia.",
			"Capturar un jefe o gigante muestra un cartel de celebración al unirse como aliado.",
			"Las mejoras permanentes cuestan un 40% menos.",
			"El menú de pausa tiene el botón Abandonar partida también en la pestaña Resumen.",
			"Los movimientos de tipo Normal aparecen menos en las cartas, para que veas más movimientos de tu propio tipo.",
			"Movimiento Z y Dynamax disponibles desde el minuto 3 (antes nivel 15 y 20).",
			"Esfera Aural: más daño (24) y atraviesa a un enemigo.",
			"Mando: ahora puedes elegir cada movimiento directamente (cruceta para los 1-4, gatillos para el 5 y 6) y reasignar los botones en Ajustes. En teclado, teclas 1 a 6.",
			"El botón de lanzar la Poké Ball aparece dentro del Pokémon caído.",
			"Menos partículas y efectos en todo el juego para evitar lag (-50% más).",
			"Veto: ahora puedes mejorar los slots de veto hasta 6 (antes 3), con un coste por nivel más suave.",
			"Nueva pantalla de pausa: se abre primero el Resumen de la partida con un diseño renovado (estadísticas con iconos y movimientos con daño y derrotas); las opciones están en la pestaña de al lado (LB/RB).",
			"Economía: los tickets normales y morados son algo más difíciles de conseguir (cofres, jefes, grietas y premios dan menos).",
		],
		"fixes": [
			"Mando en Android TV (Nvidia Shield): ahora se aceptan mandos que no son el índice 0. Pendiente de confirmar en un dispositivo real.",
			"Aviso con el motivo cuando dos movimientos vinculados no se pueden fusionar.",
			"Arreglo: al cambiar de modo con arriba/abajo el cursor ya no salta a los modificadores del panel derecho.",
			"Al pulsar Jugar, la lista de modos empieza siempre arriba, en la Partida normal.",
			"Arreglo: el botón de acción (Comerciar, Rescatar, Lanzar Poké Ball…) ya no se solapa con el botón Dynamax.",
			"Arreglo: parpadeo de la pantalla al elegir un Caramelo Raro; ahora pasa directo a la mejora. Con mochila sale una sola carta y no se puede descartar para siempre.",
			"Arreglo: la tecla Retroceso/Borrar ya no te saca de los menús en PC (solo Esc vuelve atrás).",
			"Arreglo: al escribir el nombre de entrenador (o en los buscadores) Borrar ya no cierra la pantalla y se puede borrar, copiar y pegar. Vale en PC y en Android.",
		],
	},
	{
		"ver": "5.1",
		"date": "2026-10-21",
		"title": "Poke Survivors 5.1: hotfix de fusiones, Arceus y rendimiento",
		"new": [
			"La torre ahora tiene 60 pisos, con un jefe grande cada 5. Arceus espera en el piso 60 y ganas un vínculo de ataque cada 10 pisos.",
			"Arceus ahora puede ser derrotado en la Sentencia (minuto 30): da una gran recompensa y al salir ganas muchos niveles de experiencia.",
			"Las bombas ahora eliminan de un golpe a todo lo que hay en pantalla (los jefes pierden el 30% de su vida).",
		],
		"changes": [
			"Fusiones: el movimiento fusionado es único y deja de lanzar los efectos de los dos originales; muchas menos partículas para evitar tirones.",
			"Los nombres de las 50 fusiones están traducidos a todos los idiomas.",
		],
		"fixes": [
			"Arreglo: ya no se puede atravesar el muro de la arena de Arceus.",
			"Arreglo: los cofres grandes muestran una barra de progreso clara al abrirse.",
		],
	},
	{
		"ver": "5.0",
		"date": "2026-10-20",
		"title": "Poke Survivors 5.0: nuevo menú de Jugar, retos y modificadores",
		"new": [
			"Menú Jugar rediseñado: lista de modos de juego con reglas y una vista previa en video de cómo se juega cada uno.",
			"Nuevos retos de 10 minutos: 100 retos permanentes, diarios y semanales, dentro del menú Jugar. Dan Gachapon Coins.",
			"5 modificadores nuevos: Pesado, Mente brillante, Cañón de cristal, Fiebre del oro y Plaga. La vista previa de Modificadores muestra cómo cambian tus estadísticas y las de los enemigos.",
			"Nueva pestaña Gachapon: una máquina donde las Gachapon Coins (la dorada da 2) desbloquean movimientos nuevos, con animación de moneda, cápsula y discos MT del color del tipo.",
			"Nuevo botón Apoyar en el menú principal, para apoyar el proyecto de forma voluntaria.",
			"Nueva burbuja de escudo, más bonita.",
			"Ticket ×10 morado: la última tirada tiene más probabilidad de ser legendaria.",
			"Nuevo perfil del jugador (toca tu nombre): Pokémon favoritos, estadísticas, 18 medallas de tipo, tipo favorito, gorra, mochila y temas de interfaz.",
			"Las fusiones ahora son automáticas al vincular dos movimientos evolucionados al máximo, con un gran aviso «FUSION!» y un ataque especial con animación propia para cada receta.",
			"Fusiones: 50 recetas de movimientos fusionados y una Fusion Dex que guarda las que descubras.",
			"Cuevas con altares, laboratorios abandonados con Mewtwo, meteoritos con Deoxys e invasiones nuevas.",
			"Opción de tamaño de texto en Ajustes.",
			"Cada movimiento evolucionado tiene ahora un efecto visual y una habilidad propios (125 en total). Los movimientos de apoyo también evolucionan: Danza Espada, Agilidad, Fortaleza, Acua Aro, Danza Dragón, Respiro, Batido, Hipnosis y Come Sueños.",
			"Menú Pokémon rediseñado: retrato con flechas, ficha con barras e iconos, tarjetas con tipo, favoritos (corazón), buscador y orden. También sirve para elegir compañero, equipo y Pokémon de la fiesta.",
			"Kecleon vende 29 objetos nuevos, con iconos de pixel art y su propia entrada en el Léxico.",
			"Los objetos perdidos del mapa tienen usos nuevos: la Bolsa de Poké Balls da Poké Balls, el Elixir da un potenciador al azar y el Cristal Prisma paraliza a los enemigos cercanos.",
			"Las huchas Poké Ball (cofres de compra) dan una mejora gratis o una Poké Ball, y los paquetes misteriosos reemplazan a las mochilas del mapa.",
		],
		"changes": [
			"La Torre de pisos ahora se llama «La torre».",
			"El veneno hace menos daño por segundo y se acumula hasta 6 veces.",
			"Al volver de una pantalla, el menú recuerda el botón que habías elegido (mando y táctil).",
			"Fusiones: solo puedes tener una por partida, es más fuerte que los evolucionados y reemplaza a los dos movimientos que la forman, que ya no vuelven a ofrecerse.",
			"Nuevo pixel art para los cofres, cajas de suministro, paquetes y objetos del mapa, para que combinen con el resto del juego.",
			"La mejora de perfil «Mochila» ahora se llama «Bolso» para no confundirla con la mochila de objetos.",
		],
		"fixes": [
			"Arreglo: tocar el gacha ya no se queda atascado.",
			"Arreglo táctil: el botón Cerrar ya no abre otro menú y el botón Aceptar del Gachapon funciona.",
			"Arreglo: las cartas de mejora tienen un margen de 0,7 s para evitar tocarlas sin querer.",
			"Arreglo: Hipnosis y Come Sueños ahora pueden evolucionar, y la Luna de Sangre se puede conseguir.",
		],
	},
	{
		"ver": "4.0",
		"date": "2026-10-15",
		"title": "Poke Survivors 4.0: movimientos Z, Dynamax y dificultad adaptativa",
		"new": [
			"Nuevos estados: congelar, paralizar, dormir y confundir. Los enemigos confundidos se atacan entre sí; los jefes los resisten.",
			"Nuevos movimientos psíquicos: Hipnosis (puede dormir) y Come Sueños (solo golpea a enemigos dormidos y te cura). ¡Únelos con un vínculo!",
			"Nuevas trampas en el mapa: congelación, descarga, sueño y confusión (también te afectan a ti).",
			"Nueva mejora permanente: Segunda oportunidad (hasta 2 corazones). Al caer, revives una vez con la vida completa por cada corazón.",
			"Nueva mejora permanente: Calibre. Tus proyectiles, orbes y áreas de ataque (escudos, auras, golpes...) son un 8% más grandes por nivel (hasta 6 niveles), así que alcanzan a más enemigos.",
			"Nueva carta de mejora en partida: Calibre (+12% de tamaño de proyectiles, orbes y áreas, hasta 6 veces). Con ella, Tornado evoluciona también a Ciclón Colosal (además de Vendaval con Carrera).",
			"Empuje al mejorar: al subir de nivel (desde el 2) varios movimientos empujan a los enemigos hacia atrás, y más cuanto más nivel: Onda Ígnea, Burbuja, Psíquico, Disparo Lodo, Vozarrón, Viento Feérico, Pulso Umbrío, Terratemblor, Zumbido, Hidrobomba, Lanzallamas, Rayo Burbuja, Pistola Agua, Bola Sombra, Esfera Aural, Puño Meteoro y Granizo.",
			"Hoja Afilada, Giro Fuego y Tormenta Floral también empujan a los enemigos al mejorarlos.",
			"Calibre ahora también agranda el alcance de cadenas, estelas, rayos, bumeranes y embestidas, y los movimientos evolucionados empujan un 50% más que los normales.",
			"Nuevas evoluciones con la Esfera Colosal: si llevas el objeto y un movimiento está al máximo, Giro Fuego pasa a Vórtice Ígneo, Tormenta Floral a Huracán Floral, Terratemblor a Sismo Colosal, Chispazo a Descarga Titánica, Lanzallamas a Llamarada Colosal y Hoja Afilada a Hoja Colosal.",
			"Rueda Fuego también evoluciona con la Esfera Colosal: Rueda Colosal, con un rastro de llamas enorme y duradero.",
			"Dificultad adaptativa (solo partida normal): el juego empieza fácil, sobre todo si usas un Pokémon nuevo sin mejoras permanentes, y se vuelve más difícil a medida que mejoras a tu Pokémon (movimientos, estadísticas, nivel y mejoras permanentes). Sube la vida y el daño de enemigos y jefes, la frecuencia de aparición, la frecuencia de hordas y la experiencia necesaria para subir de nivel. Se ve bajo el reloj como \"Reto\" y se desactiva en Ajustes. Si sufres demasiado, baja un poco. No cambia monedas ni récords.",
			"Nueva pestaña \"Cristales Z\" en Misiones y logros: 18 misiones (una por tipo, de dificultad media) que desbloquean su movimiento Z y dan 500 monedas. También puedes seguir desbloqueándolos derrotando a 250 Pokémon de ese tipo o con el gacha.",
			"Cristales Z en el gacha: cada tirada de 10 tiene un 3% de dar el cristal de un tipo que aún no tengas desbloqueado, sin necesidad de derrotar 250 Pokémon de ese tipo.",
			"Los movimientos Z ahora tienen un tope: un solo Z no puede quitar más del 28% de la vida de un jefe.",
			"Tóxico también evoluciona con la Esfera Colosal: Ciénaga Colosal, con charcos enormes y mucho más duraderos.",
			"Nueva mejora permanente: Mochila. Llevas 2 objetos a la vez en cada partida.",
			"Nueva mejora permanente: MT. Por 2.000 monedas eliges con qué movimiento (de tus tipos) empieza ese Pokémon, y puedes cambiarlo gratis.",
			"Nuevas habilidades: cada Pokémon tiene una habilidad pasiva como en los juegos (Mar Llamas, Intimidación, Levitación, Sebo...). Mira la tuya en la partida, en el Pokédex y en el Léxico.",
			"Cooperativo: si caes, ahora espectas a tu compañero (que tiene vida propia) y te revive a los 20 s con la mitad de la vida. Si caéis los dos, se acaba la partida.",
			"Movimientos Z: 18 ataques finales (uno por tipo) con animaciones únicas. Se desbloquean derrotando 250 Pokémon de cada tipo y se usan desde el nivel 15 (botón en pantalla, tecla Z, L3 o Y/Triángulo). Después de usarlos tardan 4 minutos en recargarse.",
			"Dynamax y guaridas Dynamax: de vez en cuando aparece una guarida roja con un jefe gigante. Véncela para desbloquear el Dynamax: desde el nivel 20, tu Pokémon se vuelve gigante durante 1 minuto con +30% a todos sus atributos (botón MAX, tecla C, gatillo izquierdo o X/Cuadrado). Tarda 4 minutos en recargarse, y cada guarida vencida lo recarga al instante. El Dynamax y los movimientos Z no están disponibles en la Torre.",
			"Nuevo Léxico en el menú: consulta todos los objetos, movimientos y estados del juego.",
			"Nuevos objetos: Periscopio, Cinta Experto, Lente Amplia, Gema de tipo, Baya Zidra, Botas Gruesas, Gafas Protectoras, Seguro Debilidad, Caramelo Raro, Incienso Puro y, para algunos Pokémon, Bola Luminosa, Hueso Grueso y Polvo Plata.",
			"Nueva tabla al final de la partida: daño y derrotas de cada movimiento.",
			"Nuevos logros: por jefes derrotados (hasta 1.000) y por Pokémon derrotados de cada tipo (250, 1.000 y 5.000), en la nueva categoría «Por tipo».",
			"Nuevo objeto: Esfera Colosal. Tus proyectiles, orbes y áreas son un 30% más grandes.",
			"Nuevo objeto: Hielo Eterno. Los enemigos que te golpean van un 30% más lentos durante 2 s.",
			"Nueva caja de estadísticas opcional en partida (Ajustes): daño, velocidad, recarga, defensa, regeneración e imán.",
		],
		"changes": [
			"Sinergias: la parálisis frena y hace que los enemigos reciban más daño eléctrico, la quemadura reduce su daño e Infortunio aprovecha todos los estados.",
			"Equilibrio: Confusión, Pistola Agua, Lanzarrocas, Tornado, Impactrueno y Furia Dragón ahora pegan más fuerte.",
			"Mejoras: el selector de Pokémon ahora es grande y táctil, con sprites y filtros por generación y tipo, y siempre abre con tu compañero.",
			"Nuevo buscador por nombre en el selector de Pokémon de Mejoras permanentes.",
			"Equilibrio: la Torre es algo más difícil (enemigos con más vida y daño, aparecen más rápido y los jefes aguantan más).",
			"Equilibrio: Danza Espada y Danza Dragón dan menos ataque por acumulación, las recargas de los movimientos son un 10% más cortas y la experiencia ganada baja un 20%.",
			"Torre: los pactos de daño suben menos (Cañón de cristal, Ayuno, Llamada de la horda, Golpes cargados, Furia ciega y Sed de victoria) y se gana experiencia más despacio.",
			"Torre adaptativa: los enemigos ganan vida (hasta el doble) y daño (hasta +40%) según las mejoras que lleves en la partida y las mejoras permanentes de tu Pokémon.",
			"Torre: al superar el piso 10 y el piso 20 ganas un vínculo de ataque (une dos de tus movimientos).",
			"Darkrai es inmune al sueño.",
			"Equilibrio: los movimientos Z se rediseñaron y se reajustaron: cada tipo tiene su propia mecánica y ninguno es un simple \"limpia pantalla\"; el daño y la duración de cada uno se ajustaron para que estén más equilibrados entre sí.",
			"Equilibrio: el veneno hace menos daño contra jefes (antes los derretía en segundos).",
		],
		"fixes": [
			"Arreglo: la Moneda Amuleto ahora sí da +50% de Pokémonedas al acabar la partida.",
			"Arreglo: la Cinta Elección y la Vidasfera ahora suman su daño cuando llevas las dos a la vez.",
		],
	},
	{
		"ver": "2.0.0",
		"date": "2026-10-15",
		"title": "Poke Survivors 2.0: la Torre",
		"new": [
			"La torre: sube 30 pisos con un jefe cada 5. Puedes elegir el piso inicial desde el menú.",
			"Pisos de descanso: elige cartas de riesgo, un gran poder a cambio de un coste.",
			"Cartas legendarias doradas: súper raras y sin ningún coste (70% de enfriamiento, 2 objetos, 60% de defensa y daño extra por cada derrota).",
			"Nuevos jefes: Eternatus en el piso 25 y Arceus en el piso 30. Vence a Arceus para un logro y un título exclusivos.",
			"Meowth y Gholdengo ahora brillan, y un aviso con brújula te lleva hasta ellos.",
			"Pestaña de Novedades: aquí verás lo que trae cada actualización.",
			"Aviso de actualización dentro del juego: descarga el APK nuevo sin salir y conserva tu progreso.",
		],
		"changes": [
			"Mando: el botón de atrás sale de todas las pantallas y ya se llega a todos los controles de Mejoras.",
		],
		"fixes": [
			"Los Pokémon del menú de inicio ya no se quedan atascados en las paredes.",
		],
	},
]


# Primera vez con esta version (y ya habia partidas jugadas): el menu abre la pantalla de novedades.
static func should_show() -> bool:
	var v: String = UPD.APP_VERSION
	if String(SV.d.get("notes_seen", "")) == v:
		return false
	SV.d["notes_seen"] = v
	SV.save()
	var has := false
	for e in ENTRIES:
		if String(e["ver"]) == v:
			has = true
	if not has:
		return false
	var st: Dictionary = SV.d.get("stats", {})
	return int(st.get("runs", 0)) > 0   # instalacion nueva: no hay nada que "haya cambiado" para esta persona


const MONTHS := {
	"es": ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
	"en": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
	"fr": ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
	"it": ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"],
	"pt": ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
	"ru": ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"],
}


# "2026-10-15" -> "15 October 2026" / "15 de octubre de 2026" / "2026年10月15日", segun el idioma.
static func fmt_date(iso: String, code: String) -> String:
	var p: PackedStringArray = iso.split("-")
	if p.size() != 3:
		return iso
	var y: int = int(p[0])
	var m: int = clampi(int(p[1]), 1, 12)
	var d: int = int(p[2])
	if code == "ja" or code.begins_with("zh"):
		return "%d年%d月%d日" % [y, m, d]
	if code == "vi":
		return "%d tháng %d, %d" % [d, m, y]
	var key: String = code
	if code.begins_with("es"):
		key = "es"
	elif code.begins_with("pt"):
		key = "pt"
	if not MONTHS.has(key):
		key = "en"
	var mn: String = String(MONTHS[key][m - 1])
	if key == "es" or key == "pt":
		return "%d de %s de %d" % [d, mn, y]
	return "%d %s %d" % [d, mn, y]
