extends "res://scripts/game.gd"

var change_attempts: int = 0


func _change_to_lamp_room() -> Error:
	change_attempts += 1
	return ERR_CANT_OPEN
