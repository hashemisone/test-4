extends Area2D

@export var next_scene: PackedScene

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false
	monitoring = false


func open() -> void:
	visible = true
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if not visible or _used:
		return
	if not body.is_in_group("player"):
		return
	_used = true
	if next_scene != null:
		get_tree().paused = false
		get_tree().call_deferred("change_scene_to_packed", next_scene)
		return
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")
