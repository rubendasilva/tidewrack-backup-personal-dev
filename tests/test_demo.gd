extends Node
## Run with: godot --headless --path . tests/test_demo.tscn
## Save tests use a unique test slot, never user://save.json.

var _failures: int = 0
var _checks: int = 0
var _game: Node
var _box: CanvasLayer
var _accept_key: int = 0  # 0 = gamepad A


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)


func _accept(pressed: bool = true) -> void:
	var event: InputEvent
	if _accept_key == 0:
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A
		button.pressed = pressed
		event = button
	else:
		var key := InputEventKey.new()
		key.keycode = _accept_key
		key.pressed = pressed
		event = key
	get_viewport().push_input(event)


func _tap() -> void:
	_accept()
	_accept(false)


func _dialogue_checks() -> void:
	_game._player.position = _game._interactables[1].position
	await get_tree().process_frame
	await get_tree().process_frame
	# Real viewport dispatch includes focused GUI buttons and unhandled input.
	_tap()
	_check(DialogueManager.is_active, "first interaction starts radio dialogue")
	_tap()
	_check(not _box._typing, "accept reveals a typing linear line")
	_tap()
	_box._process(30.0)
	_check(_box._has_choices, "radio reaches a choice node")
	_tap()
	_check(not _box._has_choices, "accept chooses a branch")
	_tap()
	_check(not _box._typing, "next accept reaches new line before deferred deletion")
	await get_tree().process_frame
	_box._process(30.0)
	_tap()
	_check(not DialogueManager.is_active, "final accept closes without reopening dialogue")
	_check(_game._player.can_move, "movement is restored when dialogue closes")
	_check(get_viewport().gui_get_focus_owner() == null, "dialogue leaves no GUI focus owner")
	_tap()
	_check(DialogueManager.is_active, "first fresh input after close immediately interacts")
	DialogueManager._finish()
	_check(not _box._typing, "finishing during typing stops pending typewriter work")
	await get_tree().process_frame

	# Exercise a choice that ends the conversation directly, on button release.
	DialogueManager.start("res://tests/fixtures/dialogue_input.json")
	_box._process(30.0)
	_tap()
	_check(not DialogueManager.is_active, "terminal choice closes dialogue")
	_check(_box._choice_box.get_child_count() == 0, "finished choices detach immediately")
	_tap()
	_check(DialogueManager.is_active, "first input after terminal choice reaches gameplay")
	DialogueManager._finish()
	await get_tree().process_frame

	# Gameplay movement must work on the first physics step after close.
	var before: Vector2 = _game._player.position
	Input.action_press("ui_left")
	_game._player._physics_process(0.05)
	Input.action_release("ui_left")
	_check(_game._player.position.x < before.x, "movement responds immediately after dialogue")


func _binding_checks() -> void:
	var bindings := {
		KEY_ENTER: "ui_accept", KEY_SPACE: "ui_accept", KEY_ESCAPE: "ui_cancel",
		KEY_LEFT: "ui_left", KEY_RIGHT: "ui_right", KEY_UP: "ui_up", KEY_DOWN: "ui_down",
	}
	for keycode in bindings:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.pressed = true
		_check(event.is_action_pressed(bindings[keycode]), "keyboard binding: " + OS.get_keycode_string(keycode))
	var cancel := InputEventJoypadButton.new()
	cancel.button_index = JOY_BUTTON_B
	cancel.pressed = true
	_check(cancel.is_action_pressed("ui_cancel"), "gamepad B remains bound")
	for direction in [[0, -1.0, "ui_left"], [0, 1.0, "ui_right"], [1, -1.0, "ui_up"], [1, 1.0, "ui_down"]]:
		var event := InputEventJoypadMotion.new()
		event.axis = direction[0]
		event.axis_value = direction[1]
		_check(event.is_action_pressed(direction[2]), "stick binding: " + direction[2])


func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var button := _find_button(child, text)
		if button != null:
			return button
	return null


func _write_fixture(text: String) -> void:
	var file := FileAccess.open(GameState._save_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _save_checks() -> void:
	var original_path: String = GameState._save_path
	GameState._save_path = "user://regression-%d.json" % Time.get_ticks_usec()
	_game._player.position = _game._interactables[2].position
	GameState.set_flag("trusted_edith", false)
	GameState.set_flag("radioed_tom", true)
	_game._toggle_pause()
	var save := _find_button(_game, "Save — ground floor")
	_check(save != null, "pause menu names the saved room")
	if save != null:
		save.pressed.emit()
		_check(save.text == "Saved — ground floor ✓", "pause confirms successful save and location")
	_check(GameState.has_save(), "manual save creates a slot")
	var saved_text := FileAccess.get_file_as_string(GameState._save_path)
	var saved: Dictionary = JSON.parse_string(saved_text)
	_check(saved["scene"] == "res://scenes/game.tscn", "save before stair records ground floor")
	_check(saved["flags"]["trusted_edith"] == false, "false branch flag survives save")
	_check(not FileAccess.file_exists(GameState._save_path + ".tmp"), "successful save leaves no temporary file")
	_find_button(_game, "Resume").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_tap()
	_check(DialogueManager.is_active, "stair still opens its placeholder dialogue")
	DialogueManager._finish()
	_check(FileAccess.get_file_as_string(GameState._save_path) == saved_text, "stair does not silently autosave")
	GameState.flags.clear()
	_check(GameState.load_game(), "manual save loads")
	_check(GameState.get_flag("trusted_edith", true) == false and GameState.get_flag("radioed_tom") == true, "Continue restores saved story choices")
	var resumed: Node = load(GameState.current_scene).instantiate()
	add_child(resumed)
	_check(resumed._player.position == Vector2(640, 540), "Continue returns to ground-floor entrance, not stair position")
	resumed.queue_free()
	await get_tree().process_frame

	# A directory at the temporary-file path causes a real write-open failure.
	DirAccess.make_dir_absolute(GameState._save_path + ".tmp")
	GameState.set_flag("unsaved", true)
	print("EXPECT ERROR: save file cannot be opened for writing")
	_check(not GameState.save_game(), "failed save reports failure")
	_check(FileAccess.get_file_as_string(GameState._save_path) == saved_text, "failed save preserves the previous slot byte-for-byte")
	DirAccess.remove_absolute(GameState._save_path + ".tmp")
	_check(GameState.save_game(), "retry replaces the existing save successfully")
	_check(GameState.load_game() and GameState.get_flag("unsaved"), "replacement save loads its new flags")

	for bad_save in ["{", '{"version":99}', '{"scene":12}', '{"flags":[]}', '{"scene":"res://missing.tscn"}']:
		_write_fixture(bad_save)
		var before := GameState.flags.duplicate(true)
		var scene_before: String = GameState.current_scene
		print("EXPECT ERROR: corrupt, unsupported or unavailable save")
		_check(not GameState.load_game(), "invalid save is rejected: " + bad_save)
		_check(GameState.flags == before and GameState.current_scene == scene_before, "rejected save does not mutate the current game")
	var menu := preload("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	print("EXPECT ERROR: Continue cannot load the invalid scene")
	menu._on_continue()
	_check(menu._save_status.visible, "Continue failure is visible to the player")
	menu.queue_free()
	_write_fixture('{"scene":"res://scenes/game.tscn","flags":{"trusted_edith":false}}')
	_check(GameState.load_game() and not GameState.get_flag("trusted_edith", true), "legacy version-1 save loads without losing false flags")
	GameState.delete_save()
	_check(not GameState.has_save(), "test slot is cleaned up")
	GameState._save_path = original_path
	await get_tree().process_frame


func _run() -> void:
	GameState.new_game()
	_game = preload("res://scenes/game.tscn").instantiate()
	add_child(_game)
	_box = _game.get_node("DialogueBox")
	_binding_checks()
	for key in [0, KEY_ENTER, KEY_SPACE]:
		_accept_key = key
		print("INPUT: ", "gamepad A" if key == 0 else OS.get_keycode_string(key))
		await _dialogue_checks()
	await _save_checks()
	print("Demo checks: %d passed, %d failed" % [_checks - _failures, _failures])
	get_tree().quit(1 if _failures else 0)
