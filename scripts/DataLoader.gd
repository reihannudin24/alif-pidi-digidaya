extends Node

func load_json(path: String, fallback: Variant = {}) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing JSON file: %s" % path)
		return fallback
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_warning("Invalid JSON file: %s" % path)
		return fallback
	return parsed
