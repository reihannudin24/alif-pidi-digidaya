extends Node

var endings: Array = []

func _ready() -> void:
	endings = DataLoader.load_json("res://data/endings.json", [])

func evaluate() -> Dictionary:
	var recommendation := GameState.final_recommendation
	var risk_count := EvidenceManager.count_risk_evidence()
	var has_alt := GameState.has_evidence("sukuk_alternative_brochure") or GameState.has_evidence("musyarakah_explanation_note")
	var raka_trust := GameState.get_trust("raka")
	var sharia_score := GameState.get_score("sharia_compliance_score")
	var risk_score := GameState.get_score("risk_awareness_score")
	var ending_id := "partial_understanding"
	if TimeManager.current_minutes >= TimeManager.END_MINUTES and not GameState.final_recommendation_made:
		ending_id = "too_late"
	elif recommendation == "join_scheme" or (risk_score <= 2 and GameState.dimas_pressure >= 3):
		ending_id = "misled_by_hype"
	elif risk_count >= 5 and has_alt and raka_trust >= 3 and recommendation in ["avoid_with_alternative", "report_and_warn"]:
		ending_id = "responsible_redirect"
	elif risk_count >= 4 and raka_trust <= 1 and recommendation in ["avoid_risky", "report_and_warn"]:
		ending_id = "scam_prevented_relationship_damaged"
	elif recommendation in ["avoid_risky", "delay_verify", "avoid_with_alternative", "report_and_warn"] and sharia_score < 3:
		ending_id = "partial_understanding"
	elif recommendation in ["avoid_risky", "delay_verify"] and risk_count >= 3:
		ending_id = "partial_understanding"
	elif TimeManager.current_minutes >= TimeManager.END_MINUTES:
		ending_id = "too_late"
	return get_ending(ending_id)

func get_ending(ending_id: String) -> Dictionary:
	for ending in endings:
		if String(ending.get("id", "")) == ending_id:
			return ending
	return {
		"id": "partial_understanding",
		"title": "Partial Understanding",
		"summary": "You saw some warning signs, but the reasoning was incomplete.",
		"feedback": "Replay to gather stronger evidence and clearer sharia reasoning."
	}

