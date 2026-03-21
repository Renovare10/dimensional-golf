extends RigidBody2D

func _ready() -> void:
	$DragLauncher.launch_requested.connect(_on_launch)
	
func _on_launch(impulse: Vector2) -> void:
	apply_central_impulse(impulse)
