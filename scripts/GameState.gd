extends Node

signal state_changed
signal location_changed(location_id: String)
signal evidence_changed(evidence_id: String)
signal scores_changed

var flags: Dictionary = {}
var scores: Dictionary = {
	"literacy_score": 0,
	"risk_awareness_score": 0,
	"sharia_compliance_score": 0
}
var npc_trust: Dictionary = {
	"raka": 1,
	"naya": 0,
	"ustadz_farid": 1,
	"dimas": 0
}
var dimas_pressure := 0
var current_location := "home"
var evidence_states: Dictionary = {}
var dialogue_history: Array[String] = []
var final_recommendation := ""
var final_recommendation_made := false

func reset_state() -> void:
	flags.clear()
	scores = {"literacy_score": 0, "risk_awareness_score": 0, "sharia_compliance_score": 0}
	npc_trust = {"raka": 1, "naya": 0, "ustadz_farid": 1, "dimas": 0}
	dimas_pressure = 0
	current_location = "home"
	evidence_states.clear()
	dialogue_history.clear()
	final_recommendation = ""
	final_recommendation_made = false
	state_changed.emit()
	location_changed.emit(current_location)
	scores_changed.emit()

func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	state_changed.emit()

func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))

func add_score(score_name: String, amount: int) -> void:
	scores[score_name] = int(scores.get(score_name, 0)) + amount
	scores_changed.emit()
	state_changed.emit()

func get_score(score_name: String) -> int:
	return int(scores.get(score_name, 0))

func add_trust(npc_id: String, amount: int) -> void:
	npc_trust[npc_id] = int(npc_trust.get(npc_id, 0)) + amount
	state_changed.emit()

func get_trust(npc_id: String) -> int:
	return int(npc_trust.get(npc_id, 0))

func add_dimas_pressure(amount: int) -> void:
	dimas_pressure += amount
	state_changed.emit()

func set_location(location_id: String) -> void:
	current_location = location_id
	location_changed.emit(location_id)
	state_changed.emit()

func set_evidence_state(evidence_id: String, state: String) -> void:
	evidence_states[evidence_id] = state
	evidence_changed.emit(evidence_id)
	state_changed.emit()

func get_evidence_state(evidence_id: String) -> String:
	return String(evidence_states.get(evidence_id, "hidden"))

func collect_evidence(evidence_id: String) -> void:
	set_evidence_state(evidence_id, "collected")

func has_evidence(evidence_id: String) -> bool:
	return get_evidence_state(evidence_id) == "collected"

func remember_dialogue(node_id: String) -> void:
	if not dialogue_history.has(node_id):
		dialogue_history.append(node_id)
		state_changed.emit()

func set_final_recommendation(recommendation_id: String) -> void:
	final_recommendation = recommendation_id
	final_recommendation_made = true
	set_flag("final_recommendation_made", true)
	state_changed.emit()

func to_save_dict() -> Dictionary:
	return {
		"flags": flags,
		"scores": scores,
		"npc_trust": npc_trust,
		"dimas_pressure": dimas_pressure,
		"current_location": current_location,
		"evidence_states": evidence_states,
		"dialogue_history": dialogue_history,
		"final_recommendation": final_recommendation,
		"final_recommendation_made": final_recommendation_made
	}

func from_save_dict(data: Dictionary) -> void:
	flags = data.get("flags", {})
	scores = data.get("scores", scores)
	npc_trust = data.get("npc_trust", npc_trust)
	dimas_pressure = int(data.get("dimas_pressure", 0))
	current_location = String(data.get("current_location", "home"))
	evidence_states = data.get("evidence_states", {})
	dialogue_history.assign(data.get("dialogue_history", []))
	final_recommendation = String(data.get("final_recommendation", ""))
	final_recommendation_made = bool(data.get("final_recommendation_made", false))
	state_changed.emit()
	location_changed.emit(current_location)
	scores_changed.emit()

