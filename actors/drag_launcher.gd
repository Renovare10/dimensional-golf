extends Node2D

signal launch_requested(impulse: Vector2)
signal drag_updated(power_ratio: float, direction: Vector2)

@export var max_power: float = 1200.0
@export var power_curve: float = 1.5
@export var drag_distance_for_max: float = 400.0

var mouse_held := false
var is_dragging := false   # "aiming mode is active" (ball is slow enough)

var ball: CharacterBody2D

func _ready() -> void:
	ball = get_parent() as CharacterBody2D
	if not ball:
		push_error("DragLauncher: parent is not a CharacterBody2D! Got: " + str(get_parent()))

# NEW: Check every frame – if you're already holding the mouse button and the ball
# just slowed down enough, activate dragging and show the visualizer immediately.
func _process(_delta: float) -> void:
	if not ball or not mouse_held or is_dragging:
		return
	
	if ball.velocity.length_squared() <= 400:
		is_dragging = true
		_update_drag_visuals()  # ← this makes the arrow appear right away

func _input(event: InputEvent) -> void:
	if not ball:
		return

	var mouse_pos = get_global_mouse_position()
	var vec_from_ball = mouse_pos - ball.global_position

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_held = true
			# Start immediately if the ball is already stopped
			if ball.velocity.length_squared() <= 400:
				is_dragging = true
				_update_drag_visuals()
		else:  # released
			mouse_held = false
			if is_dragging:
				is_dragging = false
				if vec_from_ball.length() >= 5.0:
					var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
					var dir = -vec_from_ball.normalized()
					var strength = max_power * power_ratio
					launch_requested.emit(dir * strength)
			# Always hide the visualizer after release
			drag_updated.emit(0.0, Vector2.ZERO)

	elif event is InputEventMouseMotion and is_dragging:
		_update_drag_visuals()

func _update_drag_visuals() -> void:
	if not ball:
		return
	var mouse_pos = get_global_mouse_position()
	var vec_from_ball = mouse_pos - ball.global_position
	
	if vec_from_ball.length() < 5.0:
		drag_updated.emit(0.0, Vector2.ZERO)
		return

	var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
	var dir = -vec_from_ball.normalized()
	drag_updated.emit(power_ratio, dir)
