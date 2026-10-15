extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false
	monitoring = false


func open() -> void:
	visible = true
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if not visible:
		return
	if body.is_in_group("player"):
		get_tree().paused = false
		get_tree().reload_current_scene()
