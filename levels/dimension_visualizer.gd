extends Node

@export var layer_spacing: float = 150.0
@export var nearby_opacity: float = 0.35
@export var distant_opacity: float = 0.08

var layers: Array[Node2D] = []
var tween: Tween

func setup(l: Array[Node2D], _colors: Array[Color], _t: float, _o: float, _r: float, _x: float) -> void:
	layers = l
	_update_visuals_instant()

func animate_switch(current_index: int) -> void:
	if tween and tween.is_running(): tween.kill()
	tween = get_tree().create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	for i in layers.size():
		var layer = layers[i]
		var rel = i - current_index
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		var target_y = 0.0
		var target_scale = 1.0
		var target_alpha = 1.0
		
		if rel == 0:
			target_y = 0
			target_scale = 1.0
			target_alpha = 1.0
		elif abs(rel) == 1:
			target_y = rel * layer_spacing
			target_scale = 0.78
			target_alpha = nearby_opacity
		else:
			target_y = rel * layer_spacing * 2.0
			target_scale = 0.52
			target_alpha = distant_opacity
		
		layer.z_index = 10 if rel == 0 else -abs(rel)
		tween.tween_property(layer, "position:y", target_y, 0.38)
		tween.tween_property(layer, "scale", Vector2(target_scale, target_scale), 0.38)
		tween.tween_property(layer, "modulate:a", target_alpha, 0.38)
		_tint_layer(layer)

func _update_visuals_instant() -> void:
	for i in layers.size():
		var layer = layers[i]
		var rel = i - 0
		if rel > layers.size() >> 1: rel -= layers.size()
		elif rel < -(layers.size() >> 1): rel += layers.size()
		
		if rel == 0:
			layer.position.y = 0
			layer.scale = Vector2(1, 1)
			layer.modulate.a = 1.0
			layer.z_index = 10
		elif abs(rel) == 1:
			layer.position.y = rel * layer_spacing
			layer.scale = Vector2(0.78, 0.78)
			layer.modulate.a = nearby_opacity
			layer.z_index = -1
		else:
			layer.position.y = rel * layer_spacing * 2.0
			layer.scale = Vector2(0.52, 0.52)
			layer.modulate.a = distant_opacity
			layer.z_index = -2
		_tint_layer(layer)

func _tint_layer(layer: Node2D) -> void:
	var base = layer.get_meta("dim_color", Color.WHITE)
	for n in layer.get_children():
		if n is Line2D or n is Sprite2D: n.modulate = base
		for s in n.get_children():
			if s is Line2D or s is Sprite2D: s.modulate = base
