extends Control


func _ready() -> void:
	get_tree().paused = false
	ButtonStyle.apply($Panel/Play)
	ButtonStyle.apply($Panel/Quit)
	$Panel/Play.pressed.connect(_on_play)
	$Panel/Quit.pressed.connect(_on_quit)


func _on_play() -> void:
	PlayerState.start_run()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
