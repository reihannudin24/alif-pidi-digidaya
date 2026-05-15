extends Node

const SAVE_PATH := "user://alif_save.json"

func save_game() -> bool:
	var data := {
		"time": TimeManager.current_minutes,
		"game_state": GameState.to_save_dict()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No save file found.")
		return false
	var data: Dictionary = DataLoader.load_json(SAVE_PATH, {})
	if data.is_empty():
		return false
	TimeManager.current_minutes = int(data.get("time", TimeManager.START_MINUTES))
	TimeManager.time_changed.emit(TimeManager.current_minutes)
	GameState.from_save_dict(data.get("game_state", {}))
	return true

