extends Area2D

@export var this_level: GameManager.LevelId = GameManager.LevelId.LEVEL_01

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		GameManager.complete_level(this_level)
		# Optional: disable further triggers, play sound/animation, etc.
