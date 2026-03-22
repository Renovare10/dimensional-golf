extends Node

@export var layer_spacing: float = 150.0
@export var nearby_opacity: float = 0.35
@export var distant_opacity: float = 0.08

@export var nearby_scale: float = 0.78
@export var distant_scale: float = 0.52

var layers: Array[Node2D] = []
var original_positions: Array[Vector2] = []
var tween: Tween

func setup(l: Array[Node2D], _colors: Array[Color], _t: float, _o: float, _r: float, _x: float) -> void:
	layers = l
	original_positions.clear()
	for layer in layers:
		original_positions.append(layer.position)  # store exact editor position
	_update_visuals_instant()

func animate_switch(current_index: int, duration: float = 0.38) -> void:
	if tween and tween.is_running(): tween.kill()
	tween = get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	for i in layers.size():
		var layer = layers[i]
		var rel = i - current_index
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		var offset_y = 0.0
		var target_scale = 1.0
		var target_alpha = 1.0
		
		if rel == 0:
			offset_y = 0
			target_scale = 1.0
			target_alpha = 1.0
		elif abs(rel) == 1:
			offset_y = rel * layer_spacing
			target_scale = nearby_scale
			target_alpha = nearby_opacity
		else:
			offset_y = rel * layer_spacing * 2.0
			target_scale = distant_scale
			target_alpha = distant_opacity
		
		var target_pos = original_positions[i] + Vector2(0, offset_y)
		
		layer.z_index = 10 if rel == 0 else -abs(rel)
		tween.tween_property(layer, "position", target_pos, duration)      # ← now uses real time
		tween.tween_property(layer, "scale", Vector2(target_scale, target_scale), duration)
		tween.tween_property(layer, "modulate:a", target_alpha, duration)
		_tint_layer(layer)

func _update_visuals_instant() -> void:
	for i in layers.size():
		var layer = layers[i]
		var rel = i - 0
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		var offset_y = 0.0
		if rel == 0:
			offset_y = 0
			layer.scale = Vector2(1, 1)
			layer.modulate.a = 1.0
			layer.z_index = 10
		elif abs(rel) == 1:
			offset_y = rel * layer_spacing
			layer.scale = Vector2(nearby_scale, nearby_scale)
			layer.modulate.a = nearby_opacity
			layer.z_index = -1
		else:
			offset_y = rel * layer_spacing * 2.0
			layer.scale = Vector2(distant_scale, distant_scale)
			layer.modulate.a = distant_opacity
			layer.z_index = -2
		
		layer.position = original_positions[i] + Vector2(0, offset_y)
		_tint_layer(layer)

func _tint_layer(layer: Node2D) -> void:
	var base = layer.get_meta("dim_color", Color.WHITE)
	for n in layer.get_children():
		if n is Line2D or n is Sprite2D: n.modulate = base
		for s in n.get_children():
			if s is Line2D or s is Sprite2D: s.modulate = base
