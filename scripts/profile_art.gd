extends RefCounted
# Lazy loading keeps thousands of optional portraits out of the import/startup path.
static var zip: ZIPReader = null
static var names: PackedStringArray = []
static var cache: Dictionary = {}

static func ready_zip() -> bool:
	if zip == null:
		zip = ZIPReader.new()
		if zip.open("res://data/extra_art.zip") != OK:
			zip = null
			return false
		names = zip.get_files()
	return true

static func has(path: String) -> bool:
	return ready_zip() and zip.file_exists(path.trim_prefix("res://"))

static func files(prefix: String) -> PackedStringArray:
	var out := PackedStringArray()
	if ready_zip():
		for file in names:
			if file.begins_with(prefix):
				out.append(file.trim_prefix(prefix))
	return out

static func texture(path: String) -> Texture2D:
	if cache.has(path):
		return cache[path]
	if not has(path):
		return null
	var image := Image.new()
	if image.load_png_from_buffer(zip.read_file(path.trim_prefix("res://"))) != OK:
		return null
	var tex := ImageTexture.create_from_image(image)
	if cache.size() >= 32:
		cache.erase(cache.keys()[0])
	cache[path] = tex
	return tex

static func cry(dex: int) -> AudioStreamMP3:
	var path := "assets/cries/%d.mp3" % dex
	if not has(path):
		return null
	var stream := AudioStreamMP3.new()
	stream.data = zip.read_file(path)
	return stream

static func play_cry(parent: Node, dex: int) -> void:
	var stream: AudioStreamMP3 = cry(dex)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -12.0
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func clear() -> void:
	cache.clear()
	names = PackedStringArray()
	if zip != null:
		zip.close()
	zip = null
