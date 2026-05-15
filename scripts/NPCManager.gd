extends Node

var schedules: Dictionary = {}
var npc_names: Dictionary = {
	"raka": "Raka",
	"naya": "Naya",
	"ustadz_farid": "Ustadz Farid",
	"dimas": "Dimas"
}

func _ready() -> void:
	load_schedules()

func load_schedules() -> void:
	schedules = DataLoader.load_json("res://data/npc_schedules.json", {})

func get_npc_location(npc_id: String, minutes: int = TimeManager.current_minutes) -> String:
	for slot in schedules.get(npc_id, []):
		var from_min := TimeManager.hhmm_to_minutes(String(slot.get("from", "08:00")))
		var to_min := TimeManager.hhmm_to_minutes(String(slot.get("to", "16:00")))
		if minutes >= from_min and minutes < to_min:
			return String(slot.get("location", ""))
	return ""

func get_available_npcs(location_id: String) -> Array[String]:
	var available: Array[String] = []
	for npc_id in schedules.keys():
		if get_npc_location(String(npc_id)) == location_id:
			available.append(String(npc_id))
	return available

func get_display_name(npc_id: String) -> String:
	return String(npc_names.get(npc_id, npc_id.capitalize()))

