extends Node

var manager: Node2D
var ball: CharacterBody2D
var safe_area: Node

var check_timer: float = 0.0
var grace_timer: float = 1.2
var transition_grace: float = 0.0
var transition_old_index: int = -1

func setup(m: Node2D, b: CharacterBody2D, sa: Node, trans_time: float) -> void:
	manager = m
	ball = b
	safe_area = sa
	transition_grace = trans_time + 0.18

func on_dimension_switched(old_index: int) -> void:
	transition_old_index = old_index
	transition_grace = manager.transition_time + 0.18

func on_transition_finished() -> void:
	transition_old_index = -1

func _process(delta: float) -> void:
	grace_timer += delta
	transition_grace -= delta
	check_timer += delta
	
	if check_timer > 0.1:
		check_timer = 0.0
		_check_safety()

func _check_safety() -> void:
	if not ball or grace_timer <= 0.8:
		return
	
	var is_safe := true
	
	if transition_grace > 0.0 and transition_old_index != -1:
		var safe_old = safe_area.is_ball_in_safe_area(transition_old_index, ball)
		var safe_new = safe_area.is_ball_in_safe_area(manager.current_index, ball)
		is_safe = safe_old or safe_new
	else:
		is_safe = safe_area.is_ball_in_safe_area(manager.current_index, ball)
	
	if ball.has_been_launched and not is_safe:
		if not safe_area.is_ball_in_safe_area(manager.current_index, ball):
			manager.trigger_respawn()
			grace_timer = 0.0
			transition_old_index = -1
