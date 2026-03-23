extends Node

@export var nearby_opacity: float = 0.72
@export var distant_opacity: float = 0.28
@export var distant_rotation_deg: float = 14.0

var layers: Array[Node2D] = []
var original_rotations: Array[float] = []
var base_colors: Array[Color] = []
var tween: Tween

func setup(l: Array[Node2D], _colors: Array[Color], _t: float, _o: float, _r: float, _x: float) -> void:
	layers = l
	original_rotations.clear()
	base_colors.clear()
	
	for layer in layers:
		var base = layer.get_meta("dim_color", Color.WHITE)
		base_colors.append(base)
		original_rotations.append(layer.rotation_degrees)
		
		# One-time tint of all children (walls stay correct color forever)
		_tint_layer_once(layer, base)
	
	_update_visuals_instant()

func animate_switch(current_index: int, duration: float = 0.38) -> void:
	if tween and tween.is_running():
		tween.kill()
	
	tween = get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	for i in layers.size():
		var layer = layers[i]
		var rel = i - current_index
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		var target_alpha = 1.0
		var target_rot = original_rotations[i]
		var color_boost = 1.0
		
		if rel == 0:
			target_alpha = 1.0
		elif abs(rel) == 1:
			target_alpha = nearby_opacity
		else:
			target_alpha = distant_opacity
			target_rot += distant_rotation_deg * sign(rel)
			color_boost = 1.18  # subtle distant brightness (no flash)
		
		layer.z_index = 10 if rel == 0 else -abs(rel)
		
		# Smooth full-color lerp (alpha + boost) — no flash
		var target_modulate = base_colors[i] * Color(color_boost, color_boost, color_boost, target_alpha)
		tween.tween_property(layer, "modulate", target_modulate, duration)
		tween.tween_property(layer, "rotation_degrees", target_rot, duration)

func _update_visuals_instant() -> void:
	for i in layers.size():
		var layer = layers[i]
		var rel = i - 0
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		var target_alpha = 1.0
		var target_rot = original_rotations[i]
		var color_boost = 1.0
		
		if rel == 0:
			target_alpha = 1.0
		elif abs(rel) == 1:
			target_alpha = nearby_opacity
		else:
			target_alpha = distant_opacity
			target_rot += distant_rotation_deg * sign(rel)
			color_boost = 1.18
		
		layer.z_index = 10 if rel == 0 else -abs(rel)
		layer.rotation_degrees = target_rot
		
		# Apply correct starting state (only current layer full, others faded)
		var target_modulate = base_colors[i] * Color(color_boost, color_boost, color_boost, target_alpha)
		layer.modulate = target_modulate

func _tint_layer_once(layer: Node2D, base_color: Color) -> void:
	for n in layer.get_children():
		if n is Line2D or n is Sprite2D:
			n.modulate = base_color
		for s in n.get_children():
			if s is Line2D or s is Sprite2D:
				s.modulate = base_color
