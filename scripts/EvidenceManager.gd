extends Node

signal evidence_loaded

var evidence: Dictionary = {}

func _ready() -> void:
	load_evidence()

func load_evidence() -> void:
	evidence.clear()
	var list: Array = DataLoader.load_json("res://data/evidence.json", [])
	for item in list:
		var id := String(item.get("id", ""))
		if id.is_empty():
			continue
		evidence[id] = item
		if not GameState.evidence_states.has(id):
			GameState.evidence_states[id] = String(item.get("initial_state", "hidden"))
	evidence_loaded.emit()

func get_evidence(evidence_id: String) -> Dictionary:
	return evidence.get(evidence_id, {})

func get_all_evidence() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for id in evidence.keys():
		items.append(evidence[id])
	return items

func get_evidence_at_location(location_id: String, include_collected: bool = false) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for id in evidence.keys():
		var item: Dictionary = evidence[id]
		var state := GameState.get_evidence_state(String(id))
		if item.get("location", "") == location_id and (state == "visible" or (include_collected and state == "collected")):
			items.append(item)
	return items

func reveal_evidence(evidence_id: String) -> void:
	if GameState.get_evidence_state(evidence_id) == "hidden":
		GameState.set_evidence_state(evidence_id, "visible")

func collect_evidence(evidence_id: String) -> void:
	GameState.collect_evidence(evidence_id)
	RiskScoreManager.apply_evidence(evidence_id)
	ShariaComplianceManager.apply_evidence(evidence_id)

func count_collected_with_tag(tag: String) -> int:
	var count := 0
	for id in evidence.keys():
		if GameState.has_evidence(String(id)) and Array(evidence[id].get("tags", [])).has(tag):
			count += 1
	return count

func count_risk_evidence() -> int:
	var count := 0
	for id in evidence.keys():
		if GameState.has_evidence(String(id)) and int(evidence[id].get("risk_weight", 0)) > 0:
			count += 1
	return count

