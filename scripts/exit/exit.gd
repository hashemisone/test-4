extends Area2D

@export var next_scene: PackedScene
@export var to_pending := false

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false
	monitoring = false


func open() -> void:
	visible = true
	monitoring = true


func close() -> void:
	if _used:
		return
	visible = false
	monitoring = false


func _on_body_entered(body: Node) -> void:
	if not visible or _used:
		return
	if not body.is_in_group("player"):
		return
	_used = true
	get_tree().paused = false
	if to_pending:
		var path := PlayerState.pending_scene
		PlayerState.pending_scene = ""
		if path == "":
			PlayerState.end_run()
			PlayerState.return_to_levels = true
			get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")
			return
		get_tree().call_deferred("change_scene_to_file", path)
		return
	if next_scene != null:
		PlayerState.pending_scene = next_scene.resource_path
		get_tree().call_deferred("change_scene_to_file", "res://scenes/shop.tscn")
		return
	get_tree().paused = false
	PlayerState.end_run()
	PlayerState.return_to_levels = true
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu.tscn")
