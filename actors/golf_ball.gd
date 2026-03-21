extends RigidBody2D

func _ready() -> void:
	$DragLauncher.launch_requested.connect(_on_launch)
	$DragLauncher.drag_updated.connect($AimVisualizer.update_visuals)

func _on_launch(impulse: Vector2) -> void:
	apply_central_impulse(impulse)
