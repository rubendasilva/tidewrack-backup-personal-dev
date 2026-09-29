extends Node
## Focus/timing regressions; run with tests/test_pr1_keyboard.tscn.
var _game: Node
var _box: Node
var _checks := 0
var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		printerr("FAIL: ", label)


func _key(code: int, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	get_viewport().push_input(event)


func _tap(code: int) -> void:
	_key(code)
	_key(code, false)


func _route(item: int, choices: Array, key: int) -> void:
	_game._player.position = _game._interactables[item].position
	await get_tree().process_frame
	await get_tree().process_frame
	_tap(key)
	var selected := 0
	var steps := 0
	while DialogueManager.is_active and steps < 20:
		steps += 1
		_box._process(30.0)
		if _box._has_choices:
			for i in choices[selected]:
				_tap(KEY_DOWN)
			selected += 1
		# Split key down/up across frames, like a physical keyboard.
		_key(key)
		await get_tree().process_frame
		_key(key, false)
		await get_tree().process_frame
	_check(not DialogueManager.is_active, "route finishes: item %d choices %s key %s" % [item, choices, OS.get_keycode_string(key)])
	_check(get_viewport().gui_get_focus_owner() == null, "no GUI focus remains at close")
	_tap(key)
	_check(DialogueManager.is_active, "first fresh keyboard press reaches gameplay")
	if DialogueManager.is_active:
		DialogueManager._finish()
	await get_tree().process_frame


func _pause_repro() -> void:
	# The preceding route ends in dialogue close. Exercise Esc around it.
	_tap(KEY_ESCAPE)
	_check(_game._paused, "Esc opens pause after dialogue")
	await get_tree().process_frame
	await get_tree().process_frame
	_tap(KEY_ESCAPE)
	_check(not _game._paused, "Esc clears paused state")
	await get_tree().process_frame
	_check(get_viewport().gui_get_focus_owner() == null, "Esc also releases pause-button focus")
	_tap(KEY_ENTER)
	_check(DialogueManager.is_active, "first Enter after dismissing pause interacts")
	if DialogueManager.is_active:
		DialogueManager._finish()
	await get_tree().process_frame
	_check(_game.get_node_or_null("PauseLayer") == null, "dismissed pause overlay is removed")


func _held_key() -> void:
	DialogueManager.start("res://data/dialogue/keeper_intro.json", "door")
	_box._process(30.0)
	_key(KEY_ENTER)
	_check(not DialogueManager.is_active, "key down closes final line")
	_key(KEY_ENTER, true, true)
	_check(not DialogueManager.is_active, "held-key echo does not reopen dialogue")
	_key(KEY_ENTER, false)
	_key(KEY_ENTER)
	_check(DialogueManager.is_active, "release then fresh key down interacts")
	_key(KEY_ENTER, false)
	if DialogueManager.is_active:
		DialogueManager._finish()
	await get_tree().process_frame


func _run() -> void:
	_game = preload("res://scenes/game.tscn").instantiate()
	add_child(_game)
	_box = _game.get_node("DialogueBox")
	for key in [KEY_ENTER, KEY_SPACE]:
		for choices in [[0, 0], [0, 1], [1, 0], [1, 1]]:
			await _route(0, choices, key)
		for choices in [[0], [1]]:
			await _route(1, choices, key)
		# The stair is now a guarded autosave/transition, tested separately.
	await _held_key()
	await _pause_repro()
	print("PR1 keyboard checks: %d passed, %d failed" % [_checks - _failures, _failures])
	get_tree().quit(1 if _failures else 0)
