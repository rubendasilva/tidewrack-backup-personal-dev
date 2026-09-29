extends Node
## Focused stair test. Uses a unique slot, never the player's user://save.json.
var _checks: int = 0
var _failures: int = 0
var _game: Node


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		printerr("FAIL: ", label)


func _tap(code: int = KEY_ENTER) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	event.pressed = false
	get_viewport().push_input(event)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _new_game(fail_transition: bool = false) -> void:
	if is_instance_valid(_game):
		_game.queue_free()
	_game = preload("res://scenes/game.tscn").instantiate()
	if fail_transition:
		_game.set_script(preload("res://tests/fixtures/failing_stair.gd"))
	get_tree().root.add_child(_game)
	# Keep this test runner alive while exercising real scene changes.
	get_tree().current_scene = _game
	_game._player.position = _game._interactables[2].position
	await _settle()


func _run() -> void:
	var original_path: String = GameState._save_path
	GameState._save_path = "user://stair-regression-%d.json" % Time.get_ticks_usec()
	GameState.new_game()
	GameState.set_flag("trusted_edith", false)
	await _new_game()
	_check(GameState.save_game(), "seed previous checkpoint")
	var previous := FileAccess.get_file_as_string(GameState._save_path)
	DirAccess.make_dir_absolute(GameState._save_path + ".tmp")
	print("EXPECT ERROR: blocked save temporary file")
	_tap()
	await _settle()
	_check(get_tree().current_scene == _game, "save failure keeps player downstairs")
	_check(not _game._transitioning and _game._player.can_move, "save failure restores controls for retry")
	_check(_game._save_notice.visible and _game._save_notice_title.text == "Save failed", "save failure is visible, never falsely says Game saved")
	_check(FileAccess.get_file_as_string(GameState._save_path) == previous, "failed autosave preserves previous checkpoint")
	DirAccess.remove_absolute(GameState._save_path + ".tmp")

	GameState.set_flag("radioed_tom", true)
	var started := Time.get_ticks_msec()
	_tap()
	_check(_game._transitioning and not _game._player.can_move, "retry saves and locks movement during confirmation")
	_check(not DialogueManager.is_active, "stair starts transition without obsolete placeholder dialogue")
	var saved_text := FileAccess.get_file_as_string(GameState._save_path)
	var saved: Dictionary = JSON.parse_string(saved_text)
	_check(saved.get("scene") == "res://scenes/game.tscn", "autosave records ground-floor checkpoint before switching")
	_check(saved.get("flags", {}).get("trusted_edith") == false and saved.get("flags", {}).get("radioed_tom") == true, "autosave preserves current choices including false flags")
	_check(not FileAccess.file_exists(GameState._save_path + ".tmp"), "save committed before Game saved confirmation")
	_tap()
	_tap(KEY_ESCAPE)
	_check(_game._transitioning and not _game._paused and not DialogueManager.is_active, "extra Enter and Esc cannot interrupt or duplicate transition")
	var position_before: Vector2 = _game._player.position
	Input.action_press("ui_left")
	_game._player._physics_process(0.1)
	Input.action_release("ui_left")
	_check(_game._player.position == position_before, "movement is frozen during confirmation")
	await get_tree().create_timer(0.2).timeout
	_check(get_tree().current_scene == _game and _game._save_notice.visible, "confirmation remains onscreen instead of vanishing with scene")
	_check(_game._save_notice_title.text == "Game saved", "confirmation uses requested Game saved wording")
	_check(_game._save_notice_detail.text.contains("ground-floor entrance"), "confirmation explains where Continue will resume")
	var panel: Rect2 = _game._save_notice.get_global_rect()
	var title: Rect2 = _game._save_notice_title.get_global_rect()
	_check(get_viewport().get_visible_rect().encloses(panel) and panel.encloses(title), "confirmation and heading fit inside the viewport")
	_check(_game._save_notice_title.get_theme_font_size("font_size") >= 28, "confirmation heading has readable type size")
	_check(FileAccess.get_file_as_string(GameState._save_path) == saved_text, "extra inputs do not rewrite the checkpoint")
	await get_tree().create_timer(1.0).timeout
	_check(get_tree().current_scene == _game and _game._save_notice.visible, "confirmation is still visible after one second")
	await get_tree().create_timer(1.0).timeout
	_check(Time.get_ticks_msec() - started >= 2000, "confirmation interval is at least two seconds")
	_check(get_tree().current_scene.scene_file_path == "res://scenes/lamp_room.tscn", "successful autosave switches to actual lamp-room scene")
	_check(GameState.current_scene == "res://scenes/lamp_room.tscn", "live scene state follows successful transition")
	_check(FileAccess.get_file_as_string(GameState._save_path) == saved_text, "lamp-room entry retains pre-transition checkpoint")

	# Exercise the real Continue callback after returning to the title screen.
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	await _settle()
	GameState.flags.clear()
	get_tree().current_scene._on_continue()
	await _settle()
	_game = get_tree().current_scene
	_check(_game.scene_file_path == "res://scenes/game.tscn" and _game._player.position == Vector2(640, 540), "Continue resumes at saved ground-floor entrance")
	_check(GameState.get_flag("trusted_edith", true) == false and GameState.get_flag("radioed_tom") == true, "Continue restores autosaved story choices")
	_game._player.position = _game._interactables[0].position
	await _settle()
	_tap()
	_check(DialogueManager.is_active and not _game._transitioning, "normal logbook dialogue does not trigger stair transition")
	DialogueManager._finish()
	_check(FileAccess.get_file_as_string(GameState._save_path) == saved_text, "ordinary dialogue does not autosave")

	await _new_game(true)
	_tap()
	await get_tree().create_timer(2.2).timeout
	_check(_game.change_attempts == 1 and get_tree().current_scene == _game, "failed scene load stays downstairs after a single attempt")
	_check(not _game._transitioning and _game._player.can_move, "failed scene load restores controls")
	_check(_game._save_notice_title.text == "Game saved" and _game._save_notice_detail.text.contains("could not load"), "load failure distinguishes a successful save from failed transition")
	_check(GameState.load_game() and GameState.current_scene == "res://scenes/game.tscn", "checkpoint remains loadable after scene-change failure")
	GameState.delete_save()
	GameState._save_path = original_path
	print("Stair autosave checks: %d passed, %d failed" % [_checks - _failures, _failures])
	get_tree().quit(1 if _failures else 0)
