extends CanvasLayer

@onready var target_label: Label = $TargetLabel


func show_target(current: int, maximum: int) -> void:
	if current <= 0:
		target_label.text = "Dummy down"
	else:
		target_label.text = "Dummy %d/%d" % [current, maximum]
