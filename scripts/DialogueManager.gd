extends Node

var dialogue_nodes: Dictionary = {}

func _ready() -> void:
	load_dialogue()

func load_dialogue() -> void:
	dialogue_nodes.clear()
	var data: Dictionary = DataLoader.load_json("res://data/dialogue/case_01.json", {"nodes": []})
	for node in data.get("nodes", []):
		var id := String(node.get("id", ""))
		if not id.is_empty():
			dialogue_nodes[id] = node

func get_dialogue_node(node_id: String) -> Dictionary:
	return dialogue_nodes.get(node_id, {})

func get_start_node_for_npc(npc_id: String) -> Dictionary:
	for id in dialogue_nodes.keys():
		var node: Dictionary = dialogue_nodes[id]
		if String(node.get("speaker", "")) == npc_id and _conditions_met(node.get("conditions", {})):
			return node
	return {}

func get_available_choices(node: Dictionary) -> Array:
	var choices: Array = []
	for choice in node.get("choices", []):
		if _requirements_met(choice.get("requires", {})):
			choices.append(choice)
	return choices

func apply_choice(choice: Dictionary) -> Dictionary:
	_apply_effects(choice.get("effects", {}))
	var next_id := String(choice.get("next", ""))
	if next_id.is_empty():
		return {}
	return get_dialogue_node(next_id)

func _conditions_met(conditions: Dictionary) -> bool:
	if conditions.has("location") and String(conditions.location) != GameState.current_location:
		return false
	if conditions.has("time_min") and TimeManager.current_minutes < TimeManager.hhmm_to_minutes(String(conditions.time_min)):
		return false
	if conditions.has("time_max") and TimeManager.current_minutes > TimeManager.hhmm_to_minutes(String(conditions.time_max)):
		return false
	return _requirements_met(conditions)

func _requirements_met(requires: Dictionary) -> bool:
	for flag in requires.get("flags", requires.get("requires_flags", [])):
		if not GameState.has_flag(String(flag)):
			return false
	for evidence_id in requires.get("evidence", requires.get("requires_evidence", [])):
		if not GameState.has_evidence(String(evidence_id)):
			return false
	for evidence_id in requires.get("visible_evidence", []):
		if GameState.get_evidence_state(String(evidence_id)) not in ["visible", "collected"]:
			return false
	for npc_id in requires.get("min_trust", {}).keys():
		if GameState.get_trust(String(npc_id)) < int(requires.min_trust[npc_id]):
			return false
	for score_name in requires.get("min_scores", {}).keys():
		if GameState.get_score(String(score_name)) < int(requires.min_scores[score_name]):
			return false
	if requires.has("location") and String(requires.location) != GameState.current_location:
		return false
	return true

func _apply_effects(effects: Dictionary) -> void:
	for flag in effects.get("set_flags", []):
		GameState.set_flag(String(flag), true)
	for flag in effects.get("clear_flags", []):
		GameState.set_flag(String(flag), false)
	for score_name in effects.get("add_scores", {}).keys():
		GameState.add_score(String(score_name), int(effects.add_scores[score_name]))
	for npc_id in effects.get("add_trust", {}).keys():
		GameState.add_trust(String(npc_id), int(effects.add_trust[npc_id]))
	for evidence_id in effects.get("reveal_evidence", []):
		EvidenceManager.reveal_evidence(String(evidence_id))
	for evidence_id in effects.get("collect_evidence", []):
		EvidenceManager.collect_evidence(String(evidence_id))
	if effects.has("add_dimas_pressure"):
		GameState.add_dimas_pressure(int(effects.add_dimas_pressure))
	if effects.has("final_recommendation"):
		GameState.set_final_recommendation(String(effects.final_recommendation))
	if effects.has("advance_time"):
		TimeManager.advance_time(int(effects.advance_time))
	for tag in effects.get("risk_tags", []):
		RiskScoreManager.apply_choice_tags([tag])
