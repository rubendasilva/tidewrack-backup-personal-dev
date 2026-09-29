extends Node
## GameState — global save/load and story flags.
##
## Autoloaded as `GameState`. Holds the narrative flags set by dialogue
## choices and persists them to user://save.json so "Continue" works.

signal state_changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

# Overridden by regression tests so they never touch the player's slot.
var _save_path: String = SAVE_PATH

## Story flags set during play, e.g. {"trusted_edith": true}.
var flags: Dictionary = {}
## Path of the scene the player should resume into.
var current_scene: String = "res://scenes/game.tscn"


func set_flag(name: String, value: Variant) -> void:
	flags[name] = value
	state_changed.emit()


func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func new_game() -> void:
	flags.clear()
	current_scene = "res://scenes/game.tscn"
	state_changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(_save_path)


func save_game() -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"scene": current_scene,
		"flags": flags,
	}
	# Commit a complete snapshot before replacing the previous manual save.
	var temporary_path := _save_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		push_error("GameState: could not finish writing save file.")
		return false
	var commit_error := DirAccess.rename_absolute(temporary_path, _save_path)
	if commit_error != OK:
		DirAccess.remove_absolute(temporary_path)
		push_error("GameState: could not replace save file.")
		return false
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		push_error("GameState: could not open save file for reading.")
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: save file is corrupt.")
		return false

	var data: Dictionary = parsed
	# Future-proofing: migrate older save versions here.
	var loaded_scene: Variant = data.get("scene", "res://scenes/game.tscn")
	var loaded_flags: Variant = data.get("flags", {})
	if data.get("version", 1) != SAVE_VERSION or typeof(loaded_scene) != TYPE_STRING or typeof(loaded_flags) != TYPE_DICTIONARY:
		push_error("GameState: unsupported or invalid save data.")
		return false
	if not ResourceLoader.exists(loaded_scene, "PackedScene"):
		push_error("GameState: saved scene is unavailable.")
		return false
	current_scene = loaded_scene
	flags = loaded_flags
	state_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(_save_path)
