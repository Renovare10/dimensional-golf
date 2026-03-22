extends Node2D

signal dimension_changed(index: int, color: Color)

@export var dimension_colors: Array[Color] = [Color(1.0,0.2,0.2),Color(1.0,0.55,0.0),Color(1.0,1.0,0.2),Color(0.2,1.0,0.2),Color(0.2,0.65,1.0),Color(0.55,0.1,1.0),Color(0.85,0.1,0.9),Color(0.95,0.95,0.98)]
@export var transition_time: float = 0.22
@export var inactive_opacity: float = 0.38
@export var side_rotation_deg: float = 22.0
@export var side_offset_x: float = 85.0
@export var hull_padding: float = 45.0

var layers: Array[Node2D] = []
var current_index: int = 0
var check_safe_index: int = 0
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
	
	for child in get_children():
		if child is Node2D and child.name.begins_with("Layer"):
			layers.append(child)
			var idx = layers.size() - 1
			child.set_meta("dim_index", idx)
			child.set_meta("dim_color", dimension_colors[idx % dimension_colors.size()])
			_set_layer_collision_bit(child, idx)
	
	safe_area.generate_hulls(layers, hull_padding)
	visualizer.setup(layers, dimension_colors, transition_time, inactive_opacity, side_rotation_deg, side_offset_x)
	
	check_safe_index = current_index
	_update_ball_collision_mask()
	dimension_changed.emit(current_index, dimension_colors[0])

func _process(delta: float) -> void:
	grace_timer += delta
	transition_grace -= delta
	check_timer += delta
	
	if check_timer > 0.1:
		check_timer = 0.0
		if not ball or grace_timer <= 0.8: return
		
		if transition_grace > 0.0:
			# SEAMLESS: safe in old OR new dimension during transition
			var safe_old = safe_area.is_ball_in_safe_area(check_safe_index, ball)
			var safe_new = safe_area.is_ball_in_safe_area(current_index, ball)
			if not (safe_old or safe_new):
				ball.respawn()
				grace_timer = 0.0
			return
		
		# Normal check after transition
		if not safe_area.is_ball_in_safe_area(check_safe_index, ball):
			ball.respawn()
			grace_timer = 0.0

func _input(event: InputEvent) -> void:
	if is_transitioning: return
	
	if event.is_action_pressed("switch_layer_next"):
		_switch_to((current_index + 1) % layers.size())
	elif event.is_action_pressed("switch_layer_prev"):
		_switch_to((current_index - 1 + layers.size()) % layers.size())

func _switch_to(new_index: int) -> void:
	if is_transitioning or new_index == current_index: return
	is_transitioning = true
	
	var old_index = current_index
	current_index = new_index
	check_safe_index = old_index
	
	if ball:
		ball.collision_mask = 1 << current_index  # instant walls
	
	transition_grace = transition_time + 0.08
	visualizer.animate_switch(current_index, transition_time)
	
	get_tree().create_timer(transition_time + 0.12).timeout.connect(_on_transition_finished)
	
	dimension_changed.emit(current_index, dimension_colors[current_index % dimension_colors.size()])
	
	# Immediate safety net
	if ball and not safe_area.is_ball_in_safe_area(current_index, ball):
		ball.respawn()

func _on_transition_finished() -> void:
	check_safe_index = current_index
	is_transitioning = false

func _update_ball_collision_mask() -> void:
	if ball:
		ball.collision_layer = 1

func _set_layer_collision_bit(layer: Node2D, idx: int) -> void:
	var bit = 1 << idx
	for n in layer.get_children():
		if n is StaticBody2D: n.collision_layer = bit
		for s in n.get_children():
			if s is StaticBody2D: s.collision_layer = bit
			for ss in s.get_children():
				if ss is StaticBody2D: ss.collision_layer = bit
