extends CanvasLayer

@onready var player_label: Label = $PlayerLabel
@onready var target_label: Label = $TargetLabel
@onready var hint_label: Label = $HintLabel


func show_player(current: int, maximum: int) -> void:
	player_label.text = "You %d/%d" % [current, maximum]


func show_target(current: int, maximum: int) -> void:
	if current <= 0:
		target_label.text = "Goblin down"
	else:
		target_label.text = "Goblin %d/%d" % [current, maximum]


func show_status(message: String) -> void:
	hint_label.text = message
