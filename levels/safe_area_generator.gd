extends Node2D

@export var debug_draw_hulls: bool = false:
	set(value):
		debug_draw_hulls = value
		queue_redraw()

var safe_hulls: Array[PackedVector2Array] = []
var layers: Array[Node2D] = []

func generate_hulls(l: Array[Node2D], _padding: float) -> void:
	layers = l
	safe_hulls.clear()
	
	for layer in layers:
		var points: PackedVector2Array = PackedVector2Array()
		_collect_wall_points_global(layer, points)
		
		if points.size() < 3:
			safe_hulls.append(PackedVector2Array())
			continue
		
		# Remove accidental duplicate consecutive points
		var cleaned: PackedVector2Array = PackedVector2Array()
		for p in points:
			if cleaned.is_empty() or cleaned[-1] != p:
				cleaned.append(p)
		
		# Close the polygon (most of your walls already end where they start)
		if cleaned.size() >= 3 and cleaned[0].distance_to(cleaned[-1]) > 5.0:
			cleaned.append(cleaned[0])
		
		safe_hulls.append(cleaned)
	
	queue_redraw()

func is_ball_in_safe_area(index: int, ball: CharacterBody2D) -> bool:
	if index >= safe_hulls.size() or safe_hulls[index].size() < 3:
		return true
	return Geometry2D.is_point_in_polygon(ball.global_position, safe_hulls[index])

func _collect_wall_points_global(node: Node, points: PackedVector2Array) -> void:
	for child in node.get_children():
		if child is Line2D:
			for p in child.points:
				points.append(child.to_global(p))
		_collect_wall_points_global(child, points)

func _process(_delta: float) -> void:
	if debug_draw_hulls:
		queue_redraw()

func _draw() -> void:
	if not debug_draw_hulls or safe_hulls.is_empty():
		return
	for i in safe_hulls.size():
		if safe_hulls[i].size() < 3:
			continue
		var alpha = 0.65 if i == get_parent().current_index else 0.28
		var color = Color(0.0, 1.0, 0.4, alpha) if i == get_parent().current_index else Color(1.0, 0.35, 0.0, alpha)
		var pts = safe_hulls[i].duplicate()
		for j in pts.size():
			pts[j] = to_local(pts[j])
		draw_colored_polygon(pts, color)
