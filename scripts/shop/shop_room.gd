extends Node2D


func _ready() -> void:
	PlayerState.in_shop = true
	PlayerState.roll_shop_stock()
	$Exit.open()
	$HUD.setup_shop()
