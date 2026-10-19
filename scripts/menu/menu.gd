extends Control

var _return_to_levels := false


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
	ButtonStyle.apply($LevelMenu)
	ButtonStyle.apply($LevelInventory)
	ButtonStyle.apply($LevelCharacter)
	for hub_button in [$HubMenu/SettingsButton, $HubMenu/Cheat, $HubMenu/Quit, $HubMenu/Close]:
		ButtonStyle.apply(hub_button)
	for number in 5:
		ButtonStyle.apply_blocked($Levels.get_node("Level%d" % (number + 1)))
	$Panel/Play.pressed.connect(_on_play)
	$Panel/Level.pressed.connect(_show_levels)
	$Panel/Quit.pressed.connect(_on_quit)
	$Panel/SettingsButton.pressed.connect(_show_settings_from_title)
	$Panel/CheatButton.pressed.connect(_show_cheat_from_title)
	$CheatBack.pressed.connect(_show_title)
	$Settings.closed.connect(_show_title)
	$Levels/Back.pressed.connect(_show_title)
	$Levels/Test.pressed.connect(_on_play)
	$LevelMenu.pressed.connect(_toggle_hub_menu)
	$LevelInventory.pressed.connect(_open_inventory)
	$LevelCharacter.pressed.connect(_open_character)
	$HubMenu/SettingsButton.pressed.connect(_show_settings_from_levels)
	$HubMenu/Cheat.pressed.connect(_show_cheat_from_levels)
	$HubMenu/Quit.pressed.connect(_on_quit)
	$HubMenu/Close.pressed.connect(_show_levels)
	$HUD.hub_closed.connect(_show_levels)
	if PlayerState.return_to_levels:
		PlayerState.return_to_levels = false
		_show_levels()


func _show_levels() -> void:
	$Panel.visible = false
	$Levels.visible = true
	$HubMenu.visible = false
	$Settings.visible = false
	$CheatPage.visible = false
	$CheatBack.visible = false
	$HUD.visible = false
	_show_level_actions(true)
	_return_to_levels = false


func _show_level_actions(show: bool) -> void:
	$LevelMenu.visible = show
	$LevelInventory.visible = show
	$LevelCharacter.visible = show


func _show_title() -> void:
	if _return_to_levels:
		_show_levels()
		return
	$Panel.visible = true
	$Levels.visible = false
	$HubMenu.visible = false
	$Settings.visible = false
	$CheatPage.visible = false
	$CheatBack.visible = false
	$HUD.visible = false
	_show_level_actions(false)


func _toggle_hub_menu() -> void:
	$HubMenu.visible = not $HubMenu.visible


func _open_character() -> void:
	_open_sheet(true)


func _open_inventory() -> void:
	_open_sheet(false)


func _open_sheet(character: bool) -> void:
	$Levels.visible = false
	$HubMenu.visible = false
	_show_level_actions(false)
	$HUD.open_hub_sheet(character)


func _show_cheat_from_title() -> void:
	_return_to_levels = false
	_show_cheat()


func _show_cheat_from_levels() -> void:
	_return_to_levels = true
	_show_cheat()


func _show_cheat() -> void:
	$Panel.visible = false
	$Levels.visible = false
	$HubMenu.visible = false
	_show_level_actions(false)
	$Settings.visible = false
	$CheatPage.visible = true
	$CheatBack.visible = true
	$CheatPage.reset_folder()


func _show_settings_from_title() -> void:
	_return_to_levels = false
	_show_settings()


func _show_settings_from_levels() -> void:
	_return_to_levels = true
	_show_settings()


func _show_settings() -> void:
	$Panel.visible = false
	$Levels.visible = false
	$HubMenu.visible = false
	_show_level_actions(false)
	$Settings.visible = true
	$Settings.show_home()


func _on_play() -> void:
	PlayerState.start_run()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
