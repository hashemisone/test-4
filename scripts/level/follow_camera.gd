extends Camera2D


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	global_position = Vector2(player.global_position.x, 180.0)
