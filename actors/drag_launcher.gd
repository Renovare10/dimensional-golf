extends Node2D

signal launch_requested(impulse: Vector2)
signal drag_updated(power_ratio: float, direction: Vector2)

@export var max_power: float = 1200.0
@export var power_curve: float = 1.5
@export var drag_distance_for_max: float = 400.0   # pixels from ball center to mouse for 100% power

var is_dragging := false
var ball: RigidBody2D

func _ready() -> void:
	ball = get_parent() as RigidBody2D

func _input(event: InputEvent) -> void:
	if ball.linear_velocity.length_squared() > 400:
		return

	var mouse_pos = get_global_mouse_position()
	var ball_pos = ball.global_position
	var vec_from_ball = mouse_pos - ball_pos

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_updated.emit(0.0, Vector2.ZERO)  # hide at start
		else:
			is_dragging = false
			if vec_from_ball.length() < 5.0:  # tiny threshold to avoid zero-division / no launch
				drag_updated.emit(0.0, Vector2.ZERO)
				return
			
			var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
			var dir = -vec_from_ball.normalized()  # opposite direction: pull away → shoot toward mouse
			var strength = max_power * power_ratio
			launch_requested.emit(dir * strength)
			drag_updated.emit(0.0, Vector2.ZERO)  # hide on release

	elif event is InputEventMouseMotion and is_dragging:
		if vec_from_ball.length() < 5.0:
			drag_updated.emit(0.0, Vector2.ZERO)
			return
		
		var power_ratio = clamp((vec_from_ball.length() / drag_distance_for_max) * power_curve, 0.0, 1.0)
		var dir = -vec_from_ball.normalized()
		drag_updated.emit(power_ratio, dir)
