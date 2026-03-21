extends Node

var safe_hulls: Array[PackedVector2Array] = []
var layers: Array[Node2D] = []

func generate_hulls(l: Array[Node2D], padding: float) -> void:
	layers = l
	safe_hulls.clear()
	for layer in layers:
		var points: PackedVector2Array = PackedVector2Array()
		_collect_wall_points(layer, points, layer)
		if points.size() >= 3:
			var hull = Geometry2D.convex_hull(points)
			safe_hulls.append(_expand_hull(hull, padding))
		else:
			safe_hulls.append(PackedVector2Array())

func is_ball_in_safe_area(index: int, ball: CharacterBody2D) -> bool:
	if index >= safe_hulls.size() or safe_hulls[index].size() < 3:
		return true
	var layer = layers[index]
	var local_pos = layer.to_local(ball.global_position)
	return Geometry2D.is_point_in_polygon(local_pos, safe_hulls[index])

func _collect_wall_points(node: Node, points: PackedVector2Array, layer: Node2D) -> void:
	for child in node.get_children():
		if child is Line2D:
			for p in child.points:
				points.append(layer.to_local(child.to_global(p)))
		_collect_wall_points(child, points, layer)

func _expand_hull(hull: PackedVector2Array, padding: float) -> PackedVector2Array:
	var expanded: PackedVector2Array = PackedVector2Array()
	if hull.size() < 3: return expanded
	var center = Vector2.ZERO
	for p in hull: center += p
	center /= hull.size()
	for p in hull:
		var dir = (p - center).normalized()
		expanded.append(p + dir * padding)
	return expanded
