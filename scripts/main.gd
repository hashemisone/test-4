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
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.get_parent() != self:
			continue
		node.died.connect(_on_enemy_died)


func track_enemy(enemy: Node, _kind: String) -> void:
	enemy.died.connect(_on_enemy_died)
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
