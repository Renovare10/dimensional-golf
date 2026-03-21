extends Node

var layers: Array[Node2D] = []
var tween: Tween
var dimension_colors: Array[Color] = []
var transition_time: float
var inactive_opacity: float
var side_rotation_deg: float
var side_offset_x: float

func setup(l: Array[Node2D], colors: Array[Color], trans_time: float, in_opacity: float, rot_deg: float, off_x: float) -> void:
	layers = l
	dimension_colors = colors
	transition_time = trans_time
	inactive_opacity = in_opacity
	side_rotation_deg = rot_deg
	side_offset_x = off_x
	_update_visuals_instant()

func animate_switch(current_index: int) -> void:
	if tween and tween.is_running(): tween.kill()
	tween = get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for i in layers.size():
		var layer = layers[i]
		var rel = i - current_index
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		var target_rot = 0.0 if rel == 0 else side_rotation_deg * sign(rel) * (1.6 if abs(rel) >= 2 else 1.0)
		var target_offset = Vector2.ZERO if rel == 0 else Vector2(side_offset_x * sign(rel) * (1.8 if abs(rel) >= 2 else 1.0), 12 * sign(rel) if abs(rel) >= 2 else 0)
		var target_alpha = 1.0 if rel == 0 else (inactive_opacity * 0.45 if abs(rel) >= 2 else inactive_opacity)
		layer.z_index = 10 if rel == 0 else 0
		tween.tween_property(layer, "rotation_degrees", target_rot, transition_time)
		tween.tween_property(layer, "position", target_offset, transition_time)
		tween.tween_property(layer, "modulate:a", target_alpha, transition_time)
		_tint_layer(layer)

func _update_visuals_instant() -> void:
	for i in layers.size():
		var layer = layers[i]
		var rel = i - 0
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		if rel == 0:
			layer.rotation_degrees = 0
			layer.position = Vector2.ZERO
			layer.modulate.a = 1.0
			layer.z_index = 10
		elif abs(rel) == 1:
			layer.rotation_degrees = side_rotation_deg * sign(rel)
			layer.position = Vector2(side_offset_x * sign(rel), 0)
			layer.modulate.a = inactive_opacity
			layer.z_index = 0
		else:
			layer.rotation_degrees = side_rotation_deg * 1.6 * sign(rel)
			layer.position = Vector2(side_offset_x * 1.8 * sign(rel), 12 * sign(rel))
			layer.modulate.a = inactive_opacity * 0.45
			layer.z_index = 0
		_tint_layer(layer)

func _tint_layer(layer: Node2D) -> void:
	var base = layer.get_meta("dim_color", Color.WHITE)
	for n in layer.get_children():
		if n is Line2D or n is Sprite2D: n.modulate = base
		for s in n.get_children():
			if s is Line2D or s is Sprite2D: s.modulate = base
