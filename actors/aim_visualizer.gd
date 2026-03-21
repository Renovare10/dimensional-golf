extends Node2D

@onready var line: Line2D = $ArrowLine

@export var max_length: float = 150.0

func _ready() -> void:
	if line.points.size() < 2:
		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
	
	hide()

func update_visuals(power_ratio: float, direction: Vector2) -> void:
	if power_ratio <= 0.02:
		hide()
		return

	show()
	rotation = direction.angle()
	
	line.set_point_position(1, Vector2(max_length * power_ratio, 0))
	
	line.default_color = Color.GREEN.lerp(Color.RED, power_ratio)
