extends Node2D

@export var goal_text := "Kill the goblin, then enter the exit"


func _ready() -> void:
	var player := $Player
	var hud := $HUD
	var dummy := $Dummy
	player.health_changed.connect(hud.show_player)
	player.died.connect(func() -> void:
		hud.show_status("Down. Try again.")
	)
	dummy.health_changed.connect(hud.show_target)
	dummy.died.connect(_on_enemy_died)
	hud.show_player(player.health, player.stats.max_health)
	hud.show_offense(player.stats.melee_damage, player.stats.bolt_damage)
	hud.show_target(dummy.health, dummy.max_health)
	hud.show_status(goal_text)
	var shooter := get_node_or_null("Shooter")
	if shooter == null:
		hud.hide_shooter()
		return
	shooter.health_changed.connect(hud.show_shooter)
	shooter.died.connect(_on_enemy_died)
	hud.show_shooter(shooter.health, shooter.max_health)


func _on_enemy_died() -> void:
	var remaining := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get("alive") == true:
			remaining += 1
	if remaining == 0:
		$HUD.show_status("Room clear. Enter the exit.")
		$Exit.open()
