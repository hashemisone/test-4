extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const SPEED := 78.0
const GRAVITY := 1600.0
const MAX_FALL := 900.0
const ATTACK_RANGE := 50.0
const ATTACK_DAMAGE := 8
const ATTACK_COOLDOWN := 0.9
const PICKUP_SCENE := preload("res://scenes/pickup/pickup.tscn")

@export var drop: ItemData
@export var max_health := 30
var health := 30

var attack_left := 0.0
var alive := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	attack_left = maxf(attack_left - delta, 0.0)
	var direction := 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.has_method("is_alive") and player.is_alive():
		var dx := player.global_position.x - global_position.x
		sprite.flip_h = dx < 0.0
		var same_floor := absf(player.global_position.y - global_position.y) < 48.0
		if same_floor and absf(dx) <= ATTACK_RANGE:
			if attack_left <= 0.0:
				attack_left = ATTACK_COOLDOWN
				player.take_damage(ATTACK_DAMAGE)
		elif absf(dx) > 24.0:
			direction = signf(dx)
	velocity.x = direction * SPEED
	move_and_slide()


func take_damage(amount: int) -> void:
	if not alive:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		alive = false
		died.emit()
		_drop_loot()
		queue_free()
		return
	sprite.modulate = Color(1.0, 0.5, 0.45)
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _drop_loot() -> void:
	if drop == null or PlayerState.owns(drop):
		return
	var pickup: Node = PICKUP_SCENE.instantiate()
	pickup.set("item", drop)
	var at := global_position + Vector2(0, -18)
	get_parent().add_child(pickup)
	pickup.global_position = at
