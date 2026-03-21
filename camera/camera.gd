# BallFollowCamera.gd
extends Camera2D

@export var ball_group: String = "ball"              # ← matches your GolfBall group
@export var follow_speed: float = 5.0                # higher = faster catch-up (3–8 feels good)
@export var look_ahead_factor: float = 0.35         # 0 = strict center, 0.5–0.8 = looks ahead in direction of movement
@export var min_distance_to_snap: float = 4.0       # if ball is very close to center, don't move camera
@export var smoothing_enabled: bool = true          # set false for instant follow (mostly for debugging)

var target: Node2D = null


func _ready() -> void:
	make_current()  # make this the active camera
	find_ball()


func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		find_ball()
		return

	var ball_velocity = target.velocity
	var ball_pos = target.global_position

	# Optional: slight look-ahead in the direction the ball is moving
	var lookahead_offset = ball_velocity.normalized() * ball_velocity.length() * look_ahead_factor * 0.001
	var desired_position = ball_pos + lookahead_offset

	# Only move if ball is far enough from current center
	if global_position.distance_to(desired_position) > min_distance_to_snap:
		if smoothing_enabled:
			global_position = global_position.lerp(desired_position, follow_speed * delta)
		else:
			global_position = desired_position


func find_ball() -> void:
	var balls = get_tree().get_nodes_in_group(ball_group)
	if balls.size() > 0:
		target = balls[0] as Node2D
		if target:
			# Optional: snap to ball on first find (avoids slow start)
			global_position = target.global_position
