extends Area2D

var direction := 1
var damage := 1
var speed := 340.0
var life := 1.6

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.flip_h = direction < 0
	sprite.play("fly")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	life -= delta
	if life <= 0.0 or global_position.x < -48.0 or global_position.x > 688.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
