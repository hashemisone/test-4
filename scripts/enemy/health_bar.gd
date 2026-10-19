extends Node2D

@onready var _fill: ColorRect = $Frame/Fill
@onready var _value: Label = $Frame/Value


func _ready() -> void:
	var enemy := get_parent()
	if enemy != null and enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_health)
	_show_enemy.call_deferred()


func _show_enemy() -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	_show(int(enemy.health), int(enemy.max_health))


func _on_health(current: int, maximum: int) -> void:
	_show(current, maximum)


func _show(current: int, maximum: int) -> void:
	var safe := maxi(maximum, 1)
	var amount := clampi(current, 0, safe)
	var width: float = _fill.get_parent().size.x - 4.0
	if width < 1.0:
		width = 56.0
	_fill.position = Vector2(2.0, 2.0)
	_fill.size = Vector2(width * float(amount) / float(safe), 12.0)
	_value.text = "%d/%d" % [amount, safe]
