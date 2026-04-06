extends Node2D

@export var debug_draw_hulls: bool = false:
	set(value):
		debug_draw_hulls = value
		queue_redraw()

var safe_polygons: Array = []  # [layer_index] → Array[PackedVector2Array] of properly closed polygons

func generate_hulls(l: Array[Node2D], _padding: float) -> void:
	safe_polygons.clear()
	
	for i in l.size():
		var layer = l[i]
		var layer_polys: Array[PackedVector2Array] = []
		_collect_closed_polygons(layer, layer_polys)
		safe_polygons.append(layer_polys)
	
	queue_redraw()

func _collect_closed_polygons(node: Node, polys: Array) -> void:
	for child in node.get_children():
		if child is Line2D and child.points.size() >= 3:
			var pts: PackedVector2Array = PackedVector2Array()
			for p in child.points:
				pts.append(child.to_global(p))
			
			if pts.size() < 3:
				continue
			
			# === FORCE-CLOSE EVERY POLYGON (this fixes Layers 2, 4, 5) ===
			var first = pts[0]
			var last = pts[-1]
			var dist = first.distance_to(last)
			
			if dist < 20.0:          # very tolerant — catches your ~1px gaps
				pts[-1] = first      # snap last point exactly to first
			else:
				pts.append(first)    # force close anyway
			
			if pts.size() >= 4:
				polys.append(pts)
			elif pts.size() == 3:
				# rare triangle case
				pts.append(pts[0])
				polys.append(pts)
		
		# Recurse (in case any walls are nested)
		_collect_closed_polygons(child, polys)

func is_ball_in_safe_area(index: int, ball: CharacterBody2D) -> bool:
	if index >= safe_polygons.size() or safe_polygons[index].is_empty():
		return true
	
	var pos = ball.global_position
	
	# Safe if inside ANY of the closed polygons belonging to this layer
	for poly in safe_polygons[index]:
		if Geometry2D.is_point_in_polygon(pos, poly):
			return true
	
	return false

func _process(_delta: float) -> void:
	if debug_draw_hulls:
		queue_redraw()

func _draw() -> void:
	if not debug_draw_hulls or safe_polygons.is_empty():
		return
	
	for i in safe_polygons.size():
		if safe_polygons[i].is_empty():
			continue
		
		var alpha = 0.65 if i == get_parent().current_index else 0.28
		var color = Color(0.0, 1.0, 0.4, alpha) if i == get_parent().current_index else Color(1.0, 0.35, 0.0, alpha)
		
		for poly in safe_polygons[i]:
			var local_pts: PackedVector2Array = PackedVector2Array()
			for p in poly:
				local_pts.append(to_local(p))
			draw_colored_polygon(local_pts, color)
