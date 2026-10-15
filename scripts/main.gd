extends Node2D


func _ready() -> void:
	var dummy := $Dummy
	var shooter := $Shooter
	var player := $Player
	var hud := $HUD
	dummy.health_changed.connect(hud.show_target)
	shooter.health_changed.connect(hud.show_shooter)
	player.health_changed.connect(hud.show_player)
	dummy.died.connect(_on_enemy_died)
	shooter.died.connect(_on_enemy_died)
	player.died.connect(func() -> void:
		hud.show_status("Down. Try again.")
	)
	hud.show_target(dummy.health, dummy.max_health)
	hud.show_shooter(shooter.health, shooter.max_health)
	hud.show_player(player.health, player.stats.max_health)
	hud.show_offense(player.stats.melee_damage, player.stats.bolt_damage)


func _on_enemy_died() -> void:
	var remaining := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get("alive") == true:
			remaining += 1
	if remaining == 0:
		$HUD.show_status("Room clear. Enter the exit.")
		$Exit.open()
