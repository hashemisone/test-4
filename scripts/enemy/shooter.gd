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
var attack_left := 0.0
var alive := true
var _turn_left := 0.0
var _notice_left := -1.0
var _lost_left := -1.0
var _alert := false
var _home := Vector2.ZERO
var _returning := false
var _stuck_left := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health = max_health
	_home = global_position
	sprite.play("idle")
	sprite.modulate = TINT
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
	var was_alert := _alert
	var decision: Dictionary = EnemySight.decide(sprite, global_position.x, player, delta, _alert, _notice_left, _lost_left)
	_alert = bool(decision["alert"])
	_notice_left = float(decision["notice_left"])
	_lost_left = float(decision["lost_left"])
	var attacking: bool = bool(decision["attacking"])
	if was_alert and not _alert:
		_begin_return()
	if attacking:
		_returning = false
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
	elif _notice_left < 0.0 and _returning:
		direction = _walk_home()
	elif _notice_left < 0.0:
		_turn_left -= delta
		if _turn_left <= 0.0:
			sprite.flip_h = not sprite.flip_h
			_turn_left = EnemySight.random_turn_wait()
	var x_before := global_position.x
	velocity.x = direction * SPEED
	move_and_slide()
	_note_return(delta, x_before)


func _begin_return() -> void:
	_returning = not EnemySight.at_home(self, _home)
	_stuck_left = EnemySight.STUCK_TIME


func _walk_home() -> float:
	if EnemySight.at_home(self, _home):
		_returning = false
		return 0.0
	var dir := signf(_home.x - global_position.x)
	if dir == 0.0 or not EnemySight.floor_ahead(self, dir):
		_returning = false
		return 0.0
	sprite.flip_h = dir < 0.0
	return dir


func _note_return(delta: float, x_before: float) -> void:
	if not _returning:
		return
	if is_on_wall() or absf(global_position.x - x_before) < 0.4:
		_stuck_left -= delta
		if _stuck_left <= 0.0:
			_returning = false
	else:
		_stuck_left = EnemySight.STUCK_TIME


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
