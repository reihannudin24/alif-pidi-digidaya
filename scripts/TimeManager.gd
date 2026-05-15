extends Node

signal time_changed(current_minutes: int)
signal deadline_reached

const START_MINUTES := 8 * 60
const END_MINUTES := 16 * 60

var current_minutes := START_MINUTES
var deadline_emitted := false

func reset_time() -> void:
	current_minutes = START_MINUTES
	deadline_emitted = false
	time_changed.emit(current_minutes)

func hhmm_to_minutes(value: String) -> int:
	var parts := value.split(":")
	if parts.size() != 2:
		return START_MINUTES
	return int(parts[0]) * 60 + int(parts[1])

func minutes_to_hhmm(value: int = current_minutes) -> String:
	return "%02d:%02d" % [int(value / 60.0), value % 60]

func advance_time(minutes: int) -> void:
	if minutes <= 0:
		return
	current_minutes = mini(current_minutes + minutes, END_MINUTES)
	time_changed.emit(current_minutes)
	if current_minutes >= END_MINUTES and not deadline_emitted:
		deadline_emitted = true
		deadline_reached.emit()

func is_between(start_time: String, end_time: String) -> bool:
	return current_minutes >= hhmm_to_minutes(start_time) and current_minutes < hhmm_to_minutes(end_time)
