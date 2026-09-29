extends Node
## Opt-in PR1 diagnostics: launch with -- --trace-input.
## Local stdout only; record gameplay keys, never dialogue text or save contents.

var enabled: bool = false
var _game: Node
var _box: Node


func _ready() -> void:
	enabled = OS.get_cmdline_user_args().has("--trace-input")
	set_process_input(enabled)
	set_process_unhandled_input(enabled)
	if enabled:
		get_tree().node_added.connect(_on_node_added)
		print("PR1_INPUT trace enabled; include the build SHA with this log.")


func bind_game(game: Node, box: Node) -> void:
	_game = game
	_box = box


func _on_node_added(node: Node) -> void:
	if node is Control:
		node.gui_input.connect(_on_gui_input.bind(node))


func _on_gui_input(event: InputEvent, control: Control) -> void:
	# Seeing a GUI event does not imply the control consumed it.
	record(str(control.get_path()), "gui_seen", event)


func _input(event: InputEvent) -> void:
	record("viewport", "raw", event)


func _unhandled_input(event: InputEvent) -> void:
	record("viewport", "unhandled_tail", event)


func record(owner: String, reason: String, event: InputEvent = null) -> void:
	if not enabled:
		return
	if event != null:
		var tracked := false
		for action in ["ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]:
			tracked = tracked or event.is_action(action)
		if not tracked:
			return
	var focus := get_viewport().gui_get_focus_owner()
	var entry := {
		"ms": Time.get_ticks_msec(), "frame": Engine.get_process_frames(),
		"owner": owner, "reason": reason,
		"focus": str(focus.get_path()) if focus != null else "",
		"focus_queued_for_deletion": focus.is_queued_for_deletion() if focus != null else false,
		"dialogue_active": DialogueManager.is_active,
		"dialogue_node": DialogueManager._current_id,
	}
	if event != null:
		entry["event_id"] = event.get_instance_id()
		entry["pressed"] = event.is_pressed()
		entry["echo"] = event.is_echo()
		if event is InputEventKey:
			entry["keycode"] = event.keycode
			entry["physical_keycode"] = event.physical_keycode
		elif event is InputEventJoypadButton:
			entry["button"] = event.button_index
		elif event is InputEventJoypadMotion:
			entry["axis"] = event.axis
			entry["axis_value"] = event.axis_value
	if is_instance_valid(_game):
		entry["paused"] = _game._paused
		entry["can_move"] = _game._player.can_move
		var cached: Node = _game._nearest
		var current: Node = _game._find_nearest()
		entry["cached_target"] = str(cached.get_path()) if is_instance_valid(cached) else ""
		entry["current_target"] = str(current.get_path()) if is_instance_valid(current) else ""
	if is_instance_valid(_box):
		entry["dialogue_visible"] = _box._root.visible
		entry["typing"] = _box._typing
		entry["has_choices"] = _box._has_choices
	print("PR1_INPUT ", JSON.stringify(entry))
