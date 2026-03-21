extends Line2D

@export var collision_thickness: float = 0.0  # unused now, but keep for future

var static_body: StaticBody2D

func _ready() -> void:
	# Create or get StaticBody2D
	static_body = get_node_or_null("StaticBody2D")
	if not static_body:
		static_body = StaticBody2D.new()
		add_child(static_body)
		static_body.name = "StaticBody2D"
		static_body.owner = self.owner  # For scene saving if needed

	update_collision()

	# Optional: call this if points change at runtime
	# points_changed.connect(update_collision)

func update_collision() -> void:
	# Clear old collision shapes
	for child in static_body.get_children():
		child.queue_free()

	if points.size() < 2:
		return

	for i in range(points.size() - 1):
		var shape = CollisionShape2D.new()
		var segment = SegmentShape2D.new()

		segment.a = points[i]
		segment.b = points[i + 1]

		shape.shape = segment
		static_body.add_child(shape)
		# Optional: shape.position = (segment.a + segment.b) / 2.0  # not needed for segments

	# Optional: add small CircleShape2D at endpoints if you want rounded corners
	# for end in [points[0], points[points.size()-1]]:
	#     var cap = CollisionShape2D.new()
	#     var circle = CircleShape2D.new()
	#     circle.radius = 6.0  # half your line width
	#     cap.shape = circle
	#     cap.position = end
	#     static_body.add_child(cap)
