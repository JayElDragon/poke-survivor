extends RefCounted
# Shared lazy texture cache. Sprite atlases are packed once instead of imported twice.
static var archive: ZIPReader = null
static var skin_archive: ZIPReader = null
static var index: Dictionary = {}
static var skin_index: Dictionary = {}
static var cache: Dictionary = {}

static func ready_archive() -> bool:
	if archive == null:
		archive = ZIPReader.new()
		if archive.open("res://data/sprites.zip") != OK:
			archive = null
			return false
		for file in archive.get_files():
			index[file] = true
	return true

static func exists(path: String) -> bool:
	if path.contains("/k-"):
		if skin_archive == null:
			if not FileAccess.file_exists("res://data/skins.zip"):
				return false
			skin_archive = ZIPReader.new()
			if skin_archive.open("res://data/skins.zip") != OK:
				skin_archive = null
				return false
			for file in skin_archive.get_files():
				skin_index[file] = true
		return skin_index.has(path.trim_prefix("res://"))
	return ready_archive() and index.has(path.trim_prefix("res://"))

static func texture(path: String) -> Texture2D:
	if cache.has(path):
		return cache[path]
	if not exists(path):
		return null
	var img := Image.new()
	var reader: ZIPReader = skin_archive if path.contains("/k-") else archive
	if img.load_png_from_buffer(reader.read_file(path.trim_prefix("res://"))) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	if cache.size() >= 64:
		cache.erase(cache.keys()[0])
	cache[path] = tex
	return tex

static func clear() -> void:
	cache.clear()
	index.clear()
	skin_index.clear()
	if archive != null:
		archive.close()
	archive = null
	if skin_archive != null:
		skin_archive.close()
	skin_archive = null
