extends Node2D

signal launch_requested(impulse: Vector2)
signal drag_updated(power_ratio: float, direction: Vector2)

@export var max_power: float = 1200.0
@export var power_curve: float = 1.5
@export var drag_distance_for_max: float = 400.0

var is_dragging := false
var ball: CharacterBody2D     # ← change type here

func _ready() -> void:
	ball = get_parent() as CharacterBody2D
	# Optional safety check (very useful during development)
	if not ball:
		push_error("DragLauncher: parent is not a CharacterBody2D! Got: " + str(get_parent()))

func _input(event: InputEvent) -> void:
	# Early exit if ball reference is missing
	if not ball:
		return

	# Now safe to access velocity
	if ball.velocity.length_squared() > 400:          # ← .velocity instead of .linear_velocity
		return

	var mouse_pos = get_global_mouse_position()
	var ball_pos = ball.global_position
	var vec_from_ball = mouse_pos - ball_pos

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_updated.emit(0.0, Vector2.ZERO)
		else:
			is_dragging = false
			if vec_from_ball.length() < 5.0:
				drag_updated.emit(0.0, Vector2.ZERO)
				return

			var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
			var dir = -vec_from_ball.normalized()
			var strength = max_power * power_ratio
			launch_requested.emit(dir * strength)
			drag_updated.emit(0.0, Vector2.ZERO)

	elif event is InputEventMouseMotion and is_dragging:
		if vec_from_ball.length() < 5.0:
			drag_updated.emit(0.0, Vector2.ZERO)
			return

		var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
		var dir = -vec_from_ball.normalized()
		drag_updated.emit(power_ratio, dir)
