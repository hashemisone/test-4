extends Node2D


func _ready() -> void:
	var dummy := $Dummy
	dummy.health_changed.connect($HUD.show_target)
	$HUD.show_target(dummy.health, dummy.max_health)
