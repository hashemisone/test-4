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

@export var level := 1
@export var max_health := 30
var health := 30

var attack_left := 0.0
var alive := true
var _turn_left := 0.0
var _notice_left := -1.0
var _alert := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = max_health
	sprite.play("idle")
	sprite.flip_h = EnemySight.random_facing()
	_turn_left = EnemySight.random_turn_wait()


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
	var on_screen := EnemySight.on_screen(sprite)
	var aware: bool = player != null and player.has_method("is_alive") and player.is_alive() and on_screen
	var attacking := false
	if aware and _alert:
		attacking = true
	elif aware and EnemySight.facing_player(sprite, global_position.x, player.global_position.x):
		if _notice_left < 0.0:
			_notice_left = EnemySight.NOTICE_TIME
		else:
			_notice_left = maxf(_notice_left - delta, 0.0)
		if _notice_left <= 0.001:
			_alert = true
			attacking = true
	else:
		_notice_left = -1.0
		if not on_screen:
			_alert = false
	if attacking:
		var dx := player.global_position.x - global_position.x
		sprite.flip_h = dx < 0.0
		var same_floor := absf(player.global_position.y - global_position.y) < 48.0
		if same_floor and absf(dx) <= ATTACK_RANGE:
			if attack_left <= 0.0:
				attack_left = ATTACK_COOLDOWN
				player.take_damage(ATTACK_DAMAGE)
		elif absf(dx) > 24.0:
			direction = signf(dx)
	elif _notice_left < 0.0:
		_turn_left -= delta
		if _turn_left <= 0.0:
			sprite.flip_h = not sprite.flip_h
			_turn_left = EnemySight.random_turn_wait()
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
	var pickup: Node = PICKUP_SCENE.instantiate()
	pickup.set("item", Loot.roll(level))
	var at := global_position + Vector2(0, -18)
	get_parent().add_child(pickup)
	pickup.global_position = at
