extends Node

var rules: Array = []
var applied_evidence: Dictionary = {}

func _ready() -> void:
	rules = DataLoader.load_json("res://data/rules/risk_rules.json", [])

func apply_evidence(evidence_id: String) -> void:
	if applied_evidence.has(evidence_id):
		return
	var item := EvidenceManager.get_evidence(evidence_id)
	if item.is_empty():
		return
	applied_evidence[evidence_id] = true
	var weight := int(item.get("risk_weight", 0))
	if weight > 0:
		GameState.add_score("risk_awareness_score", weight)
	for tag in item.get("tags", []):
		GameState.set_flag("risk_%s_seen" % String(tag), true)

func apply_choice_tags(tags: Array) -> void:
	for tag in tags:
		if String(tag) == "trusted_hype":
			GameState.add_dimas_pressure(2)
		elif String(tag) == "challenged_pressure":
			GameState.add_score("risk_awareness_score", 1)

