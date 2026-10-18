extends Node2D

@export var goal_text := "Kill the goblin, then enter the exit"


func _ready() -> void:
	var player := $Player
	var hud := $HUD
	player.health_changed.connect(hud.show_player)
	player.died.connect(func() -> void:
		hud.show_status("Down. Try again.")
	)
	hud.show_player(player.health, PlayerState.max_health())
	hud.show_offense(PlayerState.melee_damage(), PlayerState.bolt_damage())
	hud.show_status(goal_text)
	var saw_goblin := false
	var saw_shooter := false
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get_parent() != self:
			continue
		node.died.connect(_on_enemy_died)
		if node.get_node_or_null("Muzzle") != null:
			if not saw_shooter:
				node.health_changed.connect(hud.show_shooter)
				hud.show_shooter(node.health, node.max_health)
				saw_shooter = true
		elif not saw_goblin:
			node.health_changed.connect(hud.show_target)
			hud.show_target(node.health, node.max_health)
			saw_goblin = true
	if not saw_shooter:
		hud.hide_shooter()


func track_enemy(enemy: Node, kind: String) -> void:
	enemy.died.connect(_on_enemy_died)
	if kind == "shooter":
		enemy.health_changed.connect($HUD.show_shooter)
		$HUD.show_shooter(enemy.health, enemy.max_health)
	else:
		enemy.health_changed.connect($HUD.show_target)
		$HUD.show_target(enemy.health, enemy.max_health)
	if has_node("Exit"):
		$Exit.close()


func _on_enemy_died() -> void:
	var remaining := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get("alive") == true:
			remaining += 1
	if remaining == 0:
		$HUD.show_status("Room clear. Enter the exit.")
		$Exit.open()
