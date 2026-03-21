extends Node2D

signal launch_requested(impulse: Vector2)

@export var max_power: float = 1200.0
@export var power_curve: float = 1.5

var is_dragging := false
var drag_start := Vector2.ZERO
var ball: RigidBody2D

func _ready() -> void:
	ball = get_parent() as RigidBody2D

func _input(event: InputEvent) -> void:
	if ball.linear_velocity.length_squared() > 400:  # ball still moving → ignore input
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		if event.pressed:
			is_dragging = true
			drag_start = mouse_pos
		
		elif is_dragging:
			is_dragging = false
			var pull = mouse_pos - drag_start
			var strength = clamp(pull.length() * power_curve, 0.0, max_power)
			var direction = -pull.normalized()
			var impulse = direction * strength
			launch_requested.emit(impulse)
