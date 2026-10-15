extends StaticBody2D

signal health_changed(current: int, maximum: int)

@export var max_health := 30
var health := 30

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	sprite.play("idle")


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		queue_free()
		return
	sprite.modulate = Color(1.0, 0.5, 0.45)
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.12)
