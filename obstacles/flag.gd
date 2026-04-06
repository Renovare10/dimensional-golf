extends Area2D

var required_dimension: int = 0

func _ready() -> void:
	monitoring = true
	collision_mask = 1
	
	required_dimension = _find_dimension_index()

func _find_dimension_index() -> int:
	var node = self
	while node:
		if node.has_meta("dim_index"):
			return node.get_meta("dim_index")
		node = node.get_parent()
	
	var parent = get_parent()
	if parent and parent.name.begins_with("Layer"):
		var num_str = parent.name.substr(5)
		if num_str.is_valid_int():
			return num_str.to_int()
	
	return 0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	
	var manager = get_tree().get_first_node_in_group("dimension_manager")
	if manager and manager.current_index == required_dimension:
		GameManager.complete_current_level()
