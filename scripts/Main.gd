extends Control

const PORTRAITS := {
	"raka": "res://assets/portraits/raka.png",
	"naya": "res://assets/portraits/naya.png",
	"ustadz_farid": "res://assets/portraits/ustadz_farid.png",
	"dimas": "res://assets/portraits/dimas.png"
}

const INK := Color(0.045, 0.067, 0.09, 1.0)
const INK_SOFT := Color(0.08, 0.11, 0.13, 0.96)
const PAPER := Color(0.92, 0.84, 0.68, 0.94)
const PAPER_DEEP := Color(0.75, 0.62, 0.39, 0.24)
const GOLD := Color(0.93, 0.69, 0.33, 1.0)
const EMERALD := Color(0.17, 0.48, 0.37, 1.0)
const AMBER := Color(0.92, 0.48, 0.18, 1.0)
const DANGER := Color(0.74, 0.18, 0.14, 1.0)
const TEXT_LIGHT := Color(0.98, 0.93, 0.82, 1.0)
const TEXT_MUTED := Color(0.72, 0.67, 0.57, 1.0)

var locations: Array = []
var current_dialogue: Dictionary = {}
var ending: Dictionary = {}

var location_list: VBoxContainer
var npc_list: VBoxContainer
var evidence_list: VBoxContainer
var choice_list: VBoxContainer
var status_label: Label
var speaker_label: Label
var dialogue_label: RichTextLabel
var portrait_rect: TextureRect
var portrait_frame: PanelContainer
var name_plate: Label
var background_rect: TextureRect
var background_dim: ColorRect
var mentor_panel: PanelContainer
var mentor_text: RichTextLabel
var ending_panel: PanelContainer
var ending_text: RichTextLabel
var time_label: Label
var location_label: Label
var risk_bar: ProgressBar
var sharia_bar: ProgressBar
var literacy_bar: ProgressBar
var trust_bar: ProgressBar
var pressure_bar: ProgressBar
var shell_container: MarginContainer
var root_container: HBoxContainer
var stage_panel: PanelContainer
var stage_node: Control
var scene_flash: ColorRect
var dialogue_panel: PanelContainer
var portrait_shadow: ColorRect
var last_speaker := ""
var last_location := ""
var last_evidence_count := 0
var previous_scores := {}
var first_render := true
var deadline_pulse_tween: Tween

func _ready() -> void:
	locations = DataLoader.load_json("res://data/locations.json", [])
	TimeManager.time_changed.connect(func(_minutes: int): _refresh())
	TimeManager.deadline_reached.connect(_on_deadline_reached)
	GameState.state_changed.connect(_refresh)
	GameState.location_changed.connect(func(_location: String): _refresh_background())
	_build_ui()
	_refresh()
	_start_intro()
	_animate_intro()

func _build_ui() -> void:
	add_child(_background_wash())

	shell_container = MarginContainer.new()
	shell_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell_container.add_theme_constant_override("margin_left", 18)
	shell_container.add_theme_constant_override("margin_top", 18)
	shell_container.add_theme_constant_override("margin_right", 18)
	shell_container.add_theme_constant_override("margin_bottom", 18)
	add_child(shell_container)

	root_container = HBoxContainer.new()
	root_container.add_theme_constant_override("separation", 16)
	shell_container.add_child(root_container)

	root_container.add_child(_build_case_board())
	root_container.add_child(_build_scene_column())
	root_container.add_child(_build_evidence_ledger())
	_build_modals()

func _background_wash() -> ColorRect:
	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.025, 0.035, 0.035, 1.0)
	return wash

func _build_case_board() -> Control:
	var panel := _ledger_panel("CASE BOARD", "Where to investigate next")
	panel.custom_minimum_size = Vector2(282, 0)

	var body := panel.find_child("Body", true, false) as VBoxContainer
	body.add_child(_section_label("Locations", "Movement costs 10 minutes"))
	location_list = VBoxContainer.new()
	location_list.add_theme_constant_override("separation", 8)
	body.add_child(location_list)

	body.add_child(_ledger_divider())
	body.add_child(_section_label("Available NPCs", "Talk costs 10 minutes"))
	npc_list = VBoxContainer.new()
	npc_list.add_theme_constant_override("separation", 8)
	body.add_child(npc_list)
	body.add_child(_spacer())

	var search_button := _action_button("Search Location  +20m", "caution")
	search_button.pressed.connect(_search_location)
	body.add_child(search_button)
	return panel

func _build_scene_column() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)

	stage_panel = _plain_panel()
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.custom_minimum_size = Vector2(680, 430)
	stage_panel.add_theme_stylebox_override("panel", _scene_style())
	column.add_child(stage_panel)

	stage_node = Control.new()
	stage_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_panel.add_child(stage_node)

	background_rect = TextureRect.new()
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_node.add_child(background_rect)

	background_dim = ColorRect.new()
	background_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_dim.color = Color(0.02, 0.024, 0.022, 0.34)
	stage_node.add_child(background_dim)

	scene_flash = ColorRect.new()
	scene_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_flash.color = Color(0.95, 0.76, 0.42, 0.0)
	stage_node.add_child(scene_flash)

	var scene_badge := Label.new()
	scene_badge.position = Vector2(18, 16)
	scene_badge.add_theme_font_size_override("font_size", 14)
	scene_badge.add_theme_color_override("font_color", TEXT_LIGHT)
	scene_badge.add_theme_stylebox_override("normal", _chip_style(EMERALD, 0.88))
	scene_badge.text = "ACTIVE SCENE"
	stage_node.add_child(scene_badge)

	portrait_shadow = ColorRect.new()
	portrait_shadow.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	portrait_shadow.offset_left = 220
	portrait_shadow.offset_top = -74
	portrait_shadow.offset_right = -220
	portrait_shadow.offset_bottom = -34
	portrait_shadow.color = Color(0, 0, 0, 0.28)
	stage_node.add_child(portrait_shadow)

	portrait_frame = PanelContainer.new()
	portrait_frame.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	portrait_frame.offset_left = 158
	portrait_frame.offset_top = -400
	portrait_frame.offset_right = -110
	portrait_frame.offset_bottom = -8
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	stage_node.add_child(portrait_frame)

	var portrait_stack := VBoxContainer.new()
	portrait_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_stack.add_theme_constant_override("separation", 4)
	portrait_frame.add_child(portrait_stack)

	portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(420, 342)
	portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_stack.add_child(portrait_rect)

	name_plate = Label.new()
	name_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_plate.add_theme_font_size_override("font_size", 17)
	name_plate.add_theme_color_override("font_color", TEXT_LIGHT)
	name_plate.add_theme_stylebox_override("normal", _name_plate_style())
	portrait_stack.add_child(name_plate)

	dialogue_panel = _dialogue_panel()
	column.add_child(dialogue_panel)
	return column

func _dialogue_panel() -> PanelContainer:
	var panel := _plain_panel()
	panel.custom_minimum_size = Vector2(0, 230)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.052, 0.052, 0.98), GOLD, 18, 2))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 16)
	panel.add_child(box)

	speaker_label = Label.new()
	speaker_label.text = "ALIF"
	speaker_label.add_theme_font_size_override("font_size", 20)
	speaker_label.add_theme_color_override("font_color", GOLD)
	box.add_child(speaker_label)

	dialogue_label = RichTextLabel.new()
	dialogue_label.custom_minimum_size = Vector2(0, 94)
	dialogue_label.fit_content = false
	dialogue_label.bbcode_enabled = true
	dialogue_label.scroll_active = false
	dialogue_label.add_theme_font_size_override("normal_font_size", 18)
	dialogue_label.add_theme_color_override("default_color", TEXT_LIGHT)
	box.add_child(dialogue_label)

	choice_list = VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 7)
	box.add_child(choice_list)
	return panel

func _build_evidence_ledger() -> Control:
	var panel := _ledger_panel("EVIDENCE LEDGER", "Proof, pressure, and reasoning")
	panel.custom_minimum_size = Vector2(340, 0)

	var body := panel.find_child("Body", true, false) as VBoxContainer
	time_label = _data_label("08:00", 26, GOLD)
	body.add_child(time_label)
	location_label = _data_label("Home", 15, TEXT_MUTED)
	body.add_child(location_label)

	status_label = Label.new()
	status_label.visible = false
	body.add_child(status_label)

	body.add_child(_ledger_divider())
	risk_bar = _score_bar("Risk Awareness", DANGER)
	body.add_child(risk_bar.get_parent())
	sharia_bar = _score_bar("Sharia Reasoning", EMERALD)
	body.add_child(sharia_bar.get_parent())
	literacy_bar = _score_bar("Literacy", GOLD)
	body.add_child(literacy_bar.get_parent())
	trust_bar = _score_bar("Raka Trust", Color(0.33, 0.62, 0.85, 1.0))
	body.add_child(trust_bar.get_parent())
	pressure_bar = _score_bar("Dimas Pressure", AMBER)
	body.add_child(pressure_bar.get_parent())

	body.add_child(_ledger_divider())
	body.add_child(_section_label("Collected Evidence", "New clues appear by location"))
	var evidence_scroll := ScrollContainer.new()
	evidence_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	evidence_scroll.custom_minimum_size = Vector2(0, 220)
	evidence_list = VBoxContainer.new()
	evidence_list.add_theme_constant_override("separation", 8)
	evidence_scroll.add_child(evidence_list)
	body.add_child(evidence_scroll)

	var mentor_button := _action_button("Ask Mentor  +5m", "primary")
	mentor_button.pressed.connect(_toggle_mentor)
	body.add_child(mentor_button)
	var final_button := _action_button("Make Final Recommendation", "danger")
	final_button.pressed.connect(_show_recommendations)
	body.add_child(final_button)

	var utility_row := HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 8)
	var save_button := _action_button("Save", "ghost")
	save_button.pressed.connect(func(): SaveManager.save_game())
	utility_row.add_child(save_button)
	var load_button := _action_button("Load", "ghost")
	load_button.pressed.connect(func(): SaveManager.load_game(); _refresh())
	utility_row.add_child(load_button)
	var reset_button := _action_button("Reset", "ghost")
	reset_button.pressed.connect(_reset_game)
	utility_row.add_child(reset_button)
	body.add_child(utility_row)
	return panel

func _build_modals() -> void:
	mentor_panel = _modal_panel("MentorPanel")
	var mentor_box := VBoxContainer.new()
	mentor_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mentor_box.add_theme_constant_override("separation", 10)
	mentor_panel.add_child(mentor_box)
	mentor_box.add_child(_section_label("MENTOR DOSSIER", "Educational notes only, not financial advice"))
	mentor_text = RichTextLabel.new()
	mentor_text.bbcode_enabled = true
	mentor_text.custom_minimum_size = Vector2(620, 340)
	mentor_text.add_theme_font_size_override("normal_font_size", 16)
	mentor_text.add_theme_color_override("default_color", TEXT_LIGHT)
	mentor_box.add_child(mentor_text)
	var close_mentor := _action_button("Close Mentor", "ghost")
	close_mentor.pressed.connect(func(): _hide_modal(mentor_panel))
	mentor_box.add_child(close_mentor)
	add_child(mentor_panel)
	mentor_panel.hide()

	ending_panel = _modal_panel("EndingPanel")
	var ending_box := VBoxContainer.new()
	ending_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_box.add_theme_constant_override("separation", 12)
	ending_panel.add_child(ending_box)
	ending_box.add_child(_section_label("CASE OUTCOME", "Your recommendation and evidence decide the result"))
	ending_text = RichTextLabel.new()
	ending_text.bbcode_enabled = true
	ending_text.custom_minimum_size = Vector2(620, 300)
	ending_text.add_theme_font_size_override("normal_font_size", 18)
	ending_text.add_theme_color_override("default_color", TEXT_LIGHT)
	ending_box.add_child(ending_text)
	var restart_button := _action_button("Restart Case", "primary")
	restart_button.pressed.connect(_reset_game)
	ending_box.add_child(restart_button)
	add_child(ending_panel)
	ending_panel.hide()

func _start_intro() -> void:
	_show_dialogue(DialogueManager.get_dialogue_node("intro"))

func _refresh() -> void:
	if location_list == null:
		return
	var old_location := last_location
	var old_evidence_count := last_evidence_count
	_refresh_locations()
	_refresh_npcs()
	_refresh_evidence()
	_refresh_status()
	_refresh_background()
	if not first_render and old_location != "" and old_location != GameState.current_location:
		_animate_scene_change()
	if not first_render and last_evidence_count > old_evidence_count:
		_animate_evidence_added()
	_update_deadline_pulse()
	first_render = false

func _refresh_locations() -> void:
	_clear_children(location_list)
	for loc in locations:
		var location_id := String(loc.get("id", ""))
		var button := _action_button(String(loc.get("name", location_id)), "selected" if location_id == GameState.current_location else "ghost")
		button.disabled = location_id == GameState.current_location
		button.tooltip_text = String(loc.get("description", ""))
		button.pressed.connect(_move_to_location.bind(location_id))
		location_list.add_child(button)

func _refresh_npcs() -> void:
	_clear_children(npc_list)
	for npc_id in NPCManager.get_available_npcs(GameState.current_location):
		var button := _action_button(NPCManager.get_display_name(npc_id), "primary")
		button.pressed.connect(_talk_to_npc.bind(npc_id))
		npc_list.add_child(button)
	if npc_list.get_child_count() == 0:
		npc_list.add_child(_muted_note("No one is available here."))

func _refresh_evidence() -> void:
	_clear_children(evidence_list)
	for item in EvidenceManager.get_evidence_at_location(GameState.current_location):
		var evidence_id := String(item.get("id", ""))
		var button := _action_button("Collect  %s  +10m" % String(item.get("title", "Evidence")), "caution")
		button.tooltip_text = String(item.get("description", ""))
		button.pressed.connect(_collect_evidence.bind(evidence_id))
		evidence_list.add_child(button)

	var any_collected := false
	for item in EvidenceManager.get_all_evidence():
		var id := String(item.get("id", ""))
		if GameState.has_evidence(id):
			any_collected = true
			evidence_list.add_child(_evidence_row(item))
	if not any_collected:
		evidence_list.add_child(_muted_note("No collected evidence yet. Search locations and talk to NPCs."))
	last_evidence_count = evidence_list.get_child_count() if any_collected else 0

func _refresh_status() -> void:
	var risk := GameState.get_score("risk_awareness_score")
	var sharia := GameState.get_score("sharia_compliance_score")
	var literacy := GameState.get_score("literacy_score")
	var trust := GameState.get_trust("raka")
	var pressure := GameState.dimas_pressure
	time_label.text = TimeManager.minutes_to_hhmm()
	location_label.text = "Current location: %s" % _get_location_name(GameState.current_location)
	_set_bar(risk_bar, risk, 10, "risk")
	_set_bar(sharia_bar, sharia, 8, "sharia")
	_set_bar(literacy_bar, literacy, 8, "literacy")
	_set_bar(trust_bar, trust, 5, "trust")
	_set_bar(pressure_bar, pressure, 8, "pressure")
	status_label.text = "Risk %d | Sharia %d | Literacy %d | Trust %d | Pressure %d" % [risk, sharia, literacy, trust, pressure]
	last_location = GameState.current_location

func _refresh_background() -> void:
	var path := "res://assets/backgrounds/%s.png" % GameState.current_location
	if ResourceLoader.exists(path):
		background_rect.texture = load(path)

func _move_to_location(location_id: String) -> void:
	GameState.set_location(location_id)
	TimeManager.advance_time(10)
	_show_dialogue({"speaker": "system", "text": "You travel to %s. Moving costs 10 minutes." % _get_location_name(location_id), "choices": []})

func _talk_to_npc(npc_id: String) -> void:
	var node := DialogueManager.get_start_node_for_npc(npc_id)
	if node.is_empty():
		_show_dialogue({"speaker": npc_id, "text": "They have nothing new to say right now.", "choices": []})
	else:
		_show_dialogue(node)
		TimeManager.advance_time(10)

func _show_dialogue(node: Dictionary) -> void:
	current_dialogue = node
	var speaker := String(node.get("speaker", "system"))
	var display_name := NPCManager.get_display_name(speaker) if speaker != "system" else "ALIF Case File"
	speaker_label.text = display_name
	name_plate.text = display_name
	dialogue_label.text = String(node.get("text", ""))
	if PORTRAITS.has(speaker) and ResourceLoader.exists(PORTRAITS[speaker]):
		portrait_rect.texture = load(PORTRAITS[speaker])
		portrait_frame.show()
		portrait_shadow.show()
	else:
		portrait_rect.texture = null
		portrait_frame.hide()
		portrait_shadow.hide()
	GameState.remember_dialogue(String(node.get("id", "")))
	_render_choices(node)
	if not first_render:
		_animate_dialogue_reveal(speaker != last_speaker)
	last_speaker = speaker

func _render_choices(node: Dictionary) -> void:
	_clear_children(choice_list)
	for choice in DialogueManager.get_available_choices(node):
		var button := _action_button(String(choice.get("text", "Continue")), "choice")
		button.pressed.connect(_choose.bind(choice))
		choice_list.add_child(button)
	if choice_list.get_child_count() == 0:
		choice_list.add_child(_muted_note("Choose a location, NPC, evidence action, or final recommendation."))
	_animate_choices()

func _choose(choice: Dictionary) -> void:
	var next_node := DialogueManager.apply_choice(choice)
	if GameState.final_recommendation_made:
		_show_ending()
	if next_node.is_empty():
		_show_dialogue({"speaker": "system", "text": "You note the result and continue investigating.", "choices": []})
	else:
		_show_dialogue(next_node)
	_refresh()

func _collect_evidence(evidence_id: String) -> void:
	EvidenceManager.collect_evidence(evidence_id)
	TimeManager.advance_time(10)
	var item := EvidenceManager.get_evidence(evidence_id)
	_show_dialogue({"speaker": "system", "text": "Collected evidence: %s\n%s" % [item.get("title", evidence_id), item.get("description", "")], "choices": []})

func _search_location() -> void:
	var revealed := []
	for id in EvidenceManager.evidence.keys():
		var item: Dictionary = EvidenceManager.evidence[id]
		if item.get("location", "") == GameState.current_location and GameState.get_evidence_state(String(id)) == "hidden":
			EvidenceManager.reveal_evidence(String(id))
			revealed.append(item.get("title", id))
	TimeManager.advance_time(20)
	var message := "You search the area. No hidden evidence appears."
	if not revealed.is_empty():
		message = "You search carefully and reveal: %s." % ", ".join(revealed)
	_show_dialogue({"speaker": "system", "text": message, "choices": []})

func _toggle_mentor() -> void:
	TimeManager.advance_time(5)
	var topics := ["gharar", "maysir", "riba", "musyarakah", "sukuk", "cwls", "scam_red_flags"]
	var lines := ["[b][color=#E9C46A]Mentor Notes[/color][/b]"]
	for topic in topics:
		lines.append("[b]%s[/b]\n%s" % [topic.capitalize().replace("_", " "), ShariaComplianceManager.get_mentor_answer(topic)])
	mentor_text.text = "\n\n".join(lines)
	if mentor_panel.visible:
		_hide_modal(mentor_panel)
	else:
		_show_modal(mentor_panel)

func _show_recommendations() -> void:
	var node := DialogueManager.get_dialogue_node("final_recommendation")
	_show_dialogue(node)

func _on_deadline_reached() -> void:
	if not GameState.final_recommendation_made:
		_show_ending()

func _show_ending() -> void:
	ending = EndingEvaluator.evaluate()
	ending_text.text = "[b][color=#E9C46A]%s[/color][/b]\n\n%s\n\n[color=#F4E8C1]%s[/color]" % [ending.get("title", "Ending"), ending.get("summary", ""), ending.get("feedback", "")]
	_show_modal(ending_panel)

func _reset_game() -> void:
	GameState.reset_state()
	TimeManager.reset_time()
	EvidenceManager.load_evidence()
	ending_panel.hide()
	mentor_panel.hide()
	first_render = true
	last_speaker = ""
	last_location = ""
	last_evidence_count = 0
	previous_scores.clear()
	_start_intro()
	_animate_intro()

func _get_location_name(location_id: String) -> String:
	for loc in locations:
		if String(loc.get("id", "")) == location_id:
			return String(loc.get("name", location_id))
	return location_id

func _ledger_panel(title: String, subtitle: String) -> PanelContainer:
	var panel := _plain_panel()
	panel.add_theme_stylebox_override("panel", _panel_style(INK_SOFT, GOLD, 18, 1))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", GOLD)
	stack.add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.add_theme_font_size_override("font_size", 13)
	sub_label.add_theme_color_override("font_color", TEXT_MUTED)
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(sub_label)
	stack.add_child(_ledger_divider())

	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	stack.add_child(body)
	return panel

func _plain_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return panel

func _modal_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -240
	panel.offset_right = 350
	panel.offset_bottom = 240
	panel.z_index = 20
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.045, 0.045, 0.98), GOLD, 22, 2))
	return panel

func _section_label(text: String, caption: String = "") -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", TEXT_LIGHT)
	stack.add_child(label)
	if not caption.is_empty():
		var cap := Label.new()
		cap.text = caption
		cap.add_theme_font_size_override("font_size", 12)
		cap.add_theme_color_override("font_color", TEXT_MUTED)
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(cap)
	return stack

func _data_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _muted_note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	return label

func _ledger_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.28)
	return divider

func _spacer() -> Control:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return space

func _action_button(text: String, variant: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_disabled_color", Color(0.92, 0.84, 0.68, 0.55))
	button.add_theme_stylebox_override("normal", _button_style(variant, false))
	button.add_theme_stylebox_override("hover", _button_style(variant, true))
	button.add_theme_stylebox_override("pressed", _button_style("pressed", false))
	button.add_theme_stylebox_override("disabled", _button_style("disabled", false))
	button.mouse_entered.connect(func(): _button_hover(button, true))
	button.mouse_exited.connect(func(): _button_hover(button, false))
	button.button_down.connect(func(): _button_press(button))
	return button

func _score_bar(label_text: String, fill_color: Color) -> ProgressBar:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 3)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	wrapper.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 10
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.add_theme_stylebox_override("background", _panel_style(Color(0.02, 0.026, 0.026, 1.0), Color(0, 0, 0, 0), 8, 0))
	bar.add_theme_stylebox_override("fill", _panel_style(fill_color, fill_color, 8, 0))
	wrapper.add_child(bar)
	return bar

func _set_bar(bar: ProgressBar, value: int, max_value: int, key: String) -> void:
	bar.max_value = max_value
	var target := clampi(value, 0, max_value)
	var previous := int(previous_scores.get(key, -1))
	if previous == -1 or first_render:
		bar.value = target
	else:
		_tween_value(bar, "value", target, 0.28)
		if target != previous:
			_pulse_node(bar.get_parent() as Control, 1.025)
	previous_scores[key] = target

func _evidence_row(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.96, 0.87, 0.66, 0.10), Color(GOLD.r, GOLD.g, GOLD.b, 0.28), 10, 1))
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	panel.add_child(row)
	var title := Label.new()
	title.text = "✓ %s" % String(item.get("title", "Evidence"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", TEXT_LIGHT)
	row.add_child(title)
	var tags := Label.new()
	tags.text = "Tags: %s" % ", ".join(item.get("tags", []))
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tags.add_theme_font_size_override("font_size", 11)
	tags.add_theme_color_override("font_color", TEXT_MUTED)
	row.add_child(tags)
	return panel

func _panel_style(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button_style(variant: String, hover: bool) -> StyleBoxFlat:
	var bg := Color(0.10, 0.13, 0.13, 0.92)
	var border := Color(GOLD.r, GOLD.g, GOLD.b, 0.22)
	if variant == "primary":
		bg = EMERALD
		border = Color(GOLD.r, GOLD.g, GOLD.b, 0.44)
	elif variant == "caution":
		bg = Color(0.40, 0.23, 0.10, 0.94)
		border = AMBER
	elif variant == "danger":
		bg = Color(0.42, 0.13, 0.12, 0.96)
		border = DANGER
	elif variant == "choice":
		bg = Color(0.12, 0.16, 0.16, 0.96)
		border = Color(GOLD.r, GOLD.g, GOLD.b, 0.46)
	elif variant == "selected":
		bg = Color(0.22, 0.25, 0.19, 0.98)
		border = GOLD
	elif variant == "pressed":
		bg = Color(0.07, 0.09, 0.09, 1.0)
		border = GOLD
	elif variant == "disabled":
		bg = Color(0.08, 0.09, 0.08, 0.68)
		border = Color(GOLD.r, GOLD.g, GOLD.b, 0.16)
	if hover:
		bg = bg.lightened(0.12)
		border = border.lightened(0.18)
	return _panel_style(bg, border, 10, 1)

func _portrait_style() -> StyleBoxFlat:
	var style := _panel_style(Color(0.02, 0.025, 0.024, 0.58), Color(GOLD.r, GOLD.g, GOLD.b, 0.60), 20, 1)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 18
	return style

func _name_plate_style() -> StyleBoxFlat:
	return _panel_style(Color(0.05, 0.07, 0.07, 0.92), Color(GOLD.r, GOLD.g, GOLD.b, 0.38), 12, 1)

func _chip_style(color: Color, alpha: float) -> StyleBoxFlat:
	return _panel_style(Color(color.r, color.g, color.b, alpha), Color(GOLD.r, GOLD.g, GOLD.b, 0.25), 12, 1)

func _scene_style() -> StyleBoxFlat:
	var style := _panel_style(Color(0.0, 0.0, 0.0, 0.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.24), 24, 1)
	style.shadow_color = Color(0, 0, 0, 0.50)
	style.shadow_size = 24
	return style

func _animate_intro() -> void:
	if root_container == null:
		return
	root_container.modulate.a = 0.0
	root_container.position.y += 16
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(root_container, "modulate:a", 1.0, 0.38)
	tween.tween_property(root_container, "position:y", root_container.position.y - 16, 0.38)
	if dialogue_panel != null:
		dialogue_panel.scale = Vector2(0.985, 0.985)
		tween.tween_property(dialogue_panel, "scale", Vector2.ONE, 0.32)

func _animate_scene_change() -> void:
	if scene_flash == null or background_rect == null:
		return
	scene_flash.color = Color(0.95, 0.72, 0.35, 0.24)
	background_rect.modulate = Color(1.08, 1.04, 0.94, 1.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(scene_flash, "color:a", 0.0, 0.42)
	tween.tween_property(background_rect, "modulate", Color.WHITE, 0.42)
	if stage_panel != null:
		_pulse_node(stage_panel, 1.008, 0.32)

func _animate_dialogue_reveal(speaker_changed: bool) -> void:
	if dialogue_panel != null:
		dialogue_panel.modulate.a = 0.0
		dialogue_panel.position.y += 8
		var dialogue_tween := create_tween().set_parallel(true)
		dialogue_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		dialogue_tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.18)
		dialogue_tween.tween_property(dialogue_panel, "position:y", dialogue_panel.position.y - 8, 0.18)
	if speaker_changed and portrait_frame != null and portrait_frame.visible:
		portrait_frame.modulate.a = 0.0
		portrait_frame.position.x += 18
		portrait_shadow.modulate.a = 0.0
		var portrait_tween := create_tween().set_parallel(true)
		portrait_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		portrait_tween.tween_property(portrait_frame, "modulate:a", 1.0, 0.24)
		portrait_tween.tween_property(portrait_frame, "position:x", portrait_frame.position.x - 18, 0.28)
		portrait_tween.tween_property(portrait_shadow, "modulate:a", 1.0, 0.30)

func _animate_choices() -> void:
	var index := 0
	for child in choice_list.get_children():
		if child is Control:
			var control := child as Control
			control.modulate.a = 0.0
			control.position.x += 12
			var tween := create_tween().set_parallel(true)
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_interval(index * 0.035)
			tween.tween_property(control, "modulate:a", 1.0, 0.16)
			tween.tween_property(control, "position:x", control.position.x - 12, 0.16)
			index += 1

func _animate_evidence_added() -> void:
	if evidence_list == null or evidence_list.get_child_count() == 0:
		return
	var child := evidence_list.get_child(evidence_list.get_child_count() - 1)
	if child is Control:
		var control := child as Control
		control.scale = Vector2(0.95, 0.95)
		control.modulate = Color(1.0, 0.88, 0.48, 1.0)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(control, "scale", Vector2.ONE, 0.22)
		tween.tween_property(control, "modulate", Color.WHITE, 0.38)

func _show_modal(panel: PanelContainer) -> void:
	panel.show()
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.24)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.24)

func _hide_modal(panel: PanelContainer) -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.16)
	tween.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.16)
	tween.finished.connect(func():
		panel.hide()
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE
	)

func _pulse_node(node: Control, target_scale: float = 1.04, duration: float = 0.22) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(target_scale, target_scale), duration * 0.5)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.5)

func _button_hover(button: Button, entering: bool) -> void:
	if button.disabled:
		return
	var target := Vector2(1.012, 1.012) if entering else Vector2.ONE
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, 0.12)

func _button_press(button: Button) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.985, 0.985), 0.07)
	tween.tween_property(button, "scale", Vector2.ONE, 0.09)

func _tween_value(node: Object, property: String, value: Variant, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, property, value, duration)

func _update_deadline_pulse() -> void:
	if time_label == null:
		return
	if TimeManager.current_minutes >= TimeManager.hhmm_to_minutes("15:00"):
		if deadline_pulse_tween == null or not deadline_pulse_tween.is_running():
			deadline_pulse_tween = create_tween().set_loops()
			deadline_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			deadline_pulse_tween.tween_property(time_label, "modulate", Color(1.0, 0.52, 0.32, 1.0), 0.45)
			deadline_pulse_tween.tween_property(time_label, "modulate", Color.WHITE, 0.45)
	else:
		if deadline_pulse_tween != null:
			deadline_pulse_tween.kill()
			deadline_pulse_tween = null
		time_label.modulate = Color.WHITE

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
