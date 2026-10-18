extends Control


func _ready() -> void:
	get_tree().paused = false
	ButtonStyle.apply($Panel/Play)
	ButtonStyle.apply($Panel/Level)
	ButtonStyle.apply($Panel/Quit)
	ButtonStyle.apply($Panel/SettingsButton)
	ButtonStyle.apply($Panel/CheatButton)
	ButtonStyle.apply($CheatBack)
	ButtonStyle.apply($Levels/Back)
	ButtonStyle.apply($Levels/Test)
	for number in 5:
		ButtonStyle.apply_blocked($Levels.get_node("Level%d" % (number + 1)))
	$Panel/Play.pressed.connect(_on_play)
	$Panel/Level.pressed.connect(_show_levels)
	$Panel/Quit.pressed.connect(_on_quit)
	$Panel/SettingsButton.pressed.connect(_show_settings)
	$Panel/CheatButton.pressed.connect(_show_cheat)
	$CheatBack.pressed.connect(_show_title)
	$Settings.closed.connect(_show_title)
	$Levels/Back.pressed.connect(_show_title)
	$Levels/Test.pressed.connect(_on_play)


func _show_levels() -> void:
	$Panel.visible = false
	$Levels.visible = true


func _show_title() -> void:
	$Panel.visible = true
	$Levels.visible = false
	$Settings.visible = false
	$CheatPage.visible = false
	$CheatBack.visible = false


func _show_cheat() -> void:
	$Panel.visible = false
	$Levels.visible = false
	$Settings.visible = false
	$CheatPage.visible = true
	$CheatBack.visible = true
	$CheatPage.reset_folder()


func _show_settings() -> void:
	$Panel.visible = false
	$Levels.visible = false
	$Settings.visible = true
	$Settings.show_home()


func _on_play() -> void:
	PlayerState.start_run()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
