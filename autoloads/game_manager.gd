extends Node

enum LevelId {
	NONE = -1,
	LEVEL_01,
	LEVEL_02,
	LEVEL_03,
	LEVEL_04,
	LEVEL_05,
	LEVEL_06,
	# Add more levels here as needed
	# LAST_LEVEL = LEVEL_XX  (optional — can use .size() instead)
}

const LEVEL_SCENES: Dictionary = {
	LevelId.LEVEL_01: "res://levels/level_01.tscn",
	LevelId.LEVEL_02: "res://levels/level_02.tscn",
	LevelId.LEVEL_03: "res://levels/level_03.tscn",
	LevelId.LEVEL_04: "res://levels/level_04.tscn",
	LevelId.LEVEL_05: "res://levels/level_05.tscn",
	LevelId.LEVEL_06: "res://levels/level_06.tscn",
}

var unlocked: Array[LevelId] = [LevelId.LEVEL_01]
var current: LevelId = LevelId.NONE

# In GameManager.gd
func complete_level(completed: LevelId) -> void:
	if completed not in unlocked or completed == LevelId.NONE:
		return
	
	current = completed
	
	var next_id = completed + 1
	if next_id < LevelId.size() and next_id not in unlocked:
		unlocked.append(next_id)
	
	if next_id < LevelId.size():
		var path = LEVEL_SCENES.get(next_id, "")
		if path != "":
			call_deferred("_deferred_change_scene", path)
		else:
			call_deferred("_deferred_change_scene", "res://menus/level_selector.tscn")
	else:
		call_deferred("_deferred_change_scene", "res://menus/level_selector.tscn")

func _deferred_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
