extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const SHOT_SCENE := preload("res://scenes/projectile/enemy_shot.tscn")
const SPEED := 62.0
const GRAVITY := 1600.0
const MAX_FALL := 900.0
const TOO_CLOSE := 130.0
const TOO_FAR := 220.0
const SHOT_DAMAGE := 6
const SHOT_COOLDOWN := 1.35
const TINT := Color(0.62, 0.72, 1.2)
const PICKUP_SCENE := preload("res://scenes/pickup/pickup.tscn")

@export var level := 1

@export var max_health := 22
var health := 22
var attack_left := 0.7
var alive := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health = max_health
	sprite.play("idle")
	sprite.modulate = TINT


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
		var distance := absf(dx)
		var same_floor := absf(player.global_position.y - global_position.y) < 48.0
		if same_floor and distance < TOO_CLOSE:
			direction = -signf(dx)
		elif same_floor and distance > TOO_FAR:
			direction = signf(dx)
		elif attack_left <= 0.0 and distance < 420.0:
			attack_left = SHOT_COOLDOWN
			_fire(dx)
	velocity.x = direction * SPEED
	move_and_slide()


func _fire(dx: float) -> void:
	var facing := 1 if dx >= 0.0 else -1
	muzzle.position = Vector2(28.0 * facing, -36.0)
	var shot: Node = SHOT_SCENE.instantiate()
	shot.set("direction", facing)
	shot.set("damage", SHOT_DAMAGE)
	var spawn_pos := muzzle.global_position
	get_parent().add_child(shot)
	shot.global_position = spawn_pos


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
	sprite.modulate = Color(1.0, 0.55, 0.5)
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", TINT, 0.12)


func _drop_loot() -> void:
	var pickup: Node = PICKUP_SCENE.instantiate()
	pickup.set("item", Loot.roll(level))
	var at := global_position + Vector2(0, -18)
	get_parent().add_child(pickup)
	pickup.global_position = at
