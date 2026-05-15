extends Node

var rules: Dictionary = {}

func _ready() -> void:
	rules = DataLoader.load_json("res://data/rules/sharia_rules.json", {})

func apply_evidence(evidence_id: String) -> void:
	var item := EvidenceManager.get_evidence(evidence_id)
	for concept in item.get("sharia_relevance", []):
		var key := String(concept)
		if key in ["gharar", "maysir", "riba"]:
			GameState.add_score("sharia_compliance_score", 1)
		elif key in ["musyarakah", "sukuk", "cwls"]:
			GameState.add_score("literacy_score", 1)
			GameState.add_score("sharia_compliance_score", 1)

func get_mentor_answer(topic: String) -> String:
	var entry: Dictionary = rules.get(topic, {})
	if entry.is_empty():
		return "This prototype mentor only gives general education. Verify details with qualified professionals before real decisions."
	return String(entry.get("answer", ""))

