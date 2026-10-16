extends Area2D

var item: ItemData

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item != null and item.icon != null:
		sprite.texture = item.icon
	call_deferred("_collect_overlaps")


func _collect_overlaps() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node) -> void:
	if not is_inside_tree():
		return
	if not body.is_in_group("player"):
		return
	if PlayerState.collect(item):
		queue_free()
