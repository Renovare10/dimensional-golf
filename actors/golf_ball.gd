extends CharacterBody2D

@export var gravity: float = 0.0
@export var bounce: float = 0.75
@export var side_friction: float = 0.98
@export var ground_friction: float = 0.92
@export var air_drag: float = 0.99

@export var stop_speed_squared: float = 60.0

var start_position: Vector2
var has_been_launched: bool = false   # ← NEW: tracks whether the ball has been shot this life

func _ready() -> void:
	$DragLauncher.launch_requested.connect(_on_launch)
	$DragLauncher.drag_updated.connect($AimVisualizer.update_visuals)
	start_position = global_position
	has_been_launched = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity *= air_drag

	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		var dot = velocity.dot(normal)
		if dot < 0:
			velocity = velocity.bounce(normal) * bounce
			velocity *= side_friction

	if is_on_floor():
		velocity.x *= ground_friction

	# Stop tiny movement so ball doesn't roll forever at crawling speed
	if velocity.length_squared() < stop_speed_squared:
		velocity = Vector2.ZERO

func _on_launch(impulse: Vector2) -> void:
	velocity = impulse
	has_been_launched = true          # ← Mark that the ball has now been shot

func respawn() -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	has_been_launched = false         # ← Reset so you can freely switch dimensions again after death
