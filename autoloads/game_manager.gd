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

func _ready() -> void:
	# Auto-detect and unlock the current level when launching any level directly (debug mode)
	_detect_and_unlock_current_level()

func complete_level(completed: LevelId) -> void:
	if completed == LevelId.NONE:
		return
	
	current = completed
	
	# Auto-unlock the next level (works even if you started on level 4+)
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

# Fully automatic — used by flags
func complete_current_level() -> void:
	var current_path = get_tree().current_scene.scene_file_path.get_file()  # just the filename
	var level_id: LevelId = LevelId.NONE
	
	for id in LEVEL_SCENES:
		if LEVEL_SCENES[id].get_file() == current_path:
			level_id = id
			break
	
	if level_id != LevelId.NONE:
		complete_level(level_id)
	else:
		push_error("Flag could not detect current level: " + current_path)

# Auto-unlock whatever level you launched directly (super useful for testing)
func _detect_and_unlock_current_level() -> void:
	var current_path = get_tree().current_scene.scene_file_path.get_file()
	for id in LEVEL_SCENES:
		if LEVEL_SCENES[id].get_file() == current_path:
			if id not in unlocked:
				unlocked.append(id)
			current = id
			return

func _deferred_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
