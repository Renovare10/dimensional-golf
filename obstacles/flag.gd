extends Area2D

var required_dimension: int = 0

func _ready() -> void:
	monitoring = true
	collision_mask = 1
	call_deferred("_setup_dimension")

func _setup_dimension() -> void:
	var manager = get_tree().get_first_node_in_group("dimension_manager")
	if not manager or not manager.layers:
		return
	
	var my_layer = _find_my_layer()
	if my_layer:
		required_dimension = manager.layers.find(my_layer)
	
	if required_dimension == -1:
		required_dimension = 0   # safety fallback

func _find_my_layer() -> Node2D:
	var node = self
	while node:
		if node is Node2D and node.name.begins_with("Layer"):
			return node
		node = node.get_parent()
	return null

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	
	var manager = get_tree().get_first_node_in_group("dimension_manager")
	if manager and manager.current_index == required_dimension:
		GameManager.complete_current_level()
