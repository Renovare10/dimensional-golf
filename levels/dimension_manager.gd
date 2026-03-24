extends Node2D

signal dimension_changed(index: int, color: Color)

@export var dimension_colors: Array[Color] = [
	Color(0.95, 0.95, 0.98, 1),
	Color(1, 0.2, 0.2, 1),
	Color(1, 0.55, 0, 1),
	Color(1, 1, 0.2, 1),
	Color(0.2, 1, 0.2, 1),
	Color(0.2, 0.65, 1, 1),
	Color(0.55, 0.1, 1, 1),
	Color(0.85, 0.1, 0.9, 1)
]

@export var transition_time: float = 0.22
@export var inactive_opacity: float = 0.38
@export var side_rotation_deg: float = 22.0
@export var side_offset_x: float = 85.0
@export var hull_padding: float = 45.0

var layers: Array[Node2D] = []
var current_index: int = 0
var transition_old_index: int = -1
var ball: CharacterBody2D
var check_timer: float = 0.0
var grace_timer: float = 1.2
var transition_grace: float = 0.0
var is_transitioning: bool = false

@onready var visualizer = $Visualizer
@onready var safe_area = $SafeAreaGenerator

func _ready() -> void:
	add_to_group("dimension_manager")
	ball = get_parent().get_node_or_null("GolfBall")
	
	# Collect any direct children named Layer0, Layer1, etc.
	for child in get_children():
		if child is Node2D and child.name.begins_with("Layer"):
			layers.append(child)
			var idx = layers.size() - 1
			child.set_meta("dim_index", idx)
			child.set_meta("dim_color", dimension_colors[idx % dimension_colors.size()])
			_set_layer_collision_bit(child, idx)
	
	safe_area.generate_hulls(layers, hull_padding)
	visualizer.setup(layers, dimension_colors, transition_time, inactive_opacity, side_rotation_deg, side_offset_x)
	
	_update_ball_collision_mask()
	dimension_changed.emit(current_index, dimension_colors[0])


func _process(delta: float) -> void:
	grace_timer += delta
	transition_grace -= delta
	check_timer += delta
	
	if check_timer > 0.1:
		check_timer = 0.0
		if not ball or grace_timer <= 0.8:
			return
		
		var is_safe := true
		
		if transition_grace > 0.0 and transition_old_index != -1:
			var safe_old = safe_area.is_ball_in_safe_area(transition_old_index, ball)
			var safe_new = safe_area.is_ball_in_safe_area(current_index, ball)
			is_safe = safe_old or safe_new
		else:
			is_safe = safe_area.is_ball_in_safe_area(current_index, ball)
		
		if not is_safe:
			if not safe_area.is_ball_in_safe_area(current_index, ball):
				ball.respawn()
				grace_timer = 0.0
				transition_old_index = -1
			return


func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
	
	if event.is_action_pressed("switch_layer_next"):
		_switch_to((current_index + 1) % layers.size())
	elif event.is_action_pressed("switch_layer_prev"):
		_switch_to((current_index - 1 + layers.size()) % layers.size())


func _switch_to(new_index: int) -> void:
	if is_transitioning or new_index == current_index:
		return
	is_transitioning = true
	
	var old_index = current_index
	current_index = new_index
	transition_old_index = old_index
	
	if ball:
		ball.collision_mask = 1 << current_index
	
	transition_grace = transition_time + 0.18
	
	visualizer.animate_switch(current_index, transition_time)
	
	get_tree().create_timer(transition_time + 0.15).timeout.connect(_on_transition_finished)
	
	dimension_changed.emit(current_index, dimension_colors[current_index % dimension_colors.size()])
	
	if ball and not safe_area.is_ball_in_safe_area(current_index, ball):
		ball.respawn()


func _on_transition_finished() -> void:
	is_transitioning = false
	transition_old_index = -1


func _update_ball_collision_mask() -> void:
	if ball:
		ball.collision_layer = 1


func _set_layer_collision_bit(layer: Node2D, idx: int) -> void:
	var bit = 1 << idx
	for n in layer.get_children():
		if n is StaticBody2D:
			n.collision_layer = bit
		for s in n.get_children():
			if s is StaticBody2D:
				s.collision_layer = bit
			for ss in s.get_children():
				if ss is StaticBody2D:
					ss.collision_layer = bit
