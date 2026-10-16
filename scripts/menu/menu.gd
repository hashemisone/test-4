extends Control


func _ready() -> void:
	get_tree().paused = false
	ButtonStyle.apply($Panel/Play)
	ButtonStyle.apply($Panel/Level)
	ButtonStyle.apply($Panel/Quit)
	ButtonStyle.apply($Levels/Back)
	ButtonStyle.apply($Levels/Test)
	for number in 5:
		ButtonStyle.apply_blocked($Levels.get_node("Level%d" % (number + 1)))
	$Panel/Play.pressed.connect(_on_play)
	$Panel/Level.pressed.connect(_show_levels)
	$Panel/Quit.pressed.connect(_on_quit)
	$Levels/Back.pressed.connect(_show_title)
	$Levels/Test.pressed.connect(_on_play)


func _show_levels() -> void:
	$Panel.visible = false
	$Levels.visible = true


func _show_title() -> void:
	$Panel.visible = true
	$Levels.visible = false


func _on_play() -> void:
	PlayerState.start_run()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
