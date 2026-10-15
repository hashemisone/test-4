extends Node2D


func _ready() -> void:
	var dummy := $Dummy
	var player := $Player
	var hud := $HUD
	dummy.health_changed.connect(hud.show_target)
	player.health_changed.connect(hud.show_player)
	dummy.died.connect(_on_room_clear)
	player.died.connect(func() -> void:
		hud.show_status("Down. Try again.")
	)
	hud.show_target(dummy.health, dummy.max_health)
	hud.show_player(player.health, player.stats.max_health)
	hud.show_offense(player.stats.melee_damage, player.stats.bolt_damage)


func _on_room_clear() -> void:
	$HUD.show_status("Room clear. Enter the exit.")
	$Exit.open()
