extends CharacterBody2D

const BOLT_SCENE := preload("res://scenes/projectile/magic_bolt.tscn")
const SPEED := 210.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1600.0
const MAX_FALL := 900.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.12
const ATTACK_WINDUP := 0.08
const ATTACK_ACTIVE := 0.14
const ATTACK_COOLDOWN := 0.42
const CAST_COOLDOWN := 0.38

@export var stats: PlayerStats

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var melee: Area2D = $MeleeHitbox
@onready var melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D
@onready var bolt_spawn: Marker2D = $BoltSpawn

var facing := 1
var health := 100
var coyote_left := COYOTE_TIME
var jump_buffer_left := 0.0
var attack_time := -1.0
var attack_cooldown_left := 0.0
var cast_cooldown_left := 0.0
var attack_queued := false
var cast_queued := false
var hit_ids: Array[int] = []


func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new()
	health = stats.max_health
	melee.monitoring = false
	melee.body_entered.connect(_on_melee_body_entered)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER
	elif event.is_action_pressed("attack"):
		attack_queued = true
	elif event.is_action_pressed("cast"):
		cast_queued = true


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	velocity.x = direction * SPEED
	if is_on_floor():
		coyote_left = COYOTE_TIME
		if velocity.y > 0.0:
			velocity.y = 0.0
	else:
		coyote_left -= delta
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_left = 0.0
		coyote_left = 0.0
	else:
		jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)
	_update_attack(delta)
	_update_cast(delta)
	_update_facing()
	move_and_slide()
	_update_animation()


func _update_facing() -> void:
	sprite.flip_h = facing < 0
	melee_shape.position.x = absf(melee_shape.position.x) * float(facing)


func _update_attack(delta: float) -> void:
	if attack_cooldown_left > 0.0:
		attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)
	if attack_time >= 0.0:
		attack_time += delta
		var strike_end := ATTACK_WINDUP + ATTACK_ACTIVE
		var striking := attack_time >= ATTACK_WINDUP and attack_time < strike_end
		melee.monitoring = attack_time < strike_end
		if striking:
			for body in melee.get_overlapping_bodies():
				_damage_once(body, stats.melee_damage)
		if attack_time >= strike_end:
			attack_time = -1.0
			melee.monitoring = false
			hit_ids.clear()
		return
	if attack_queued and attack_cooldown_left <= 0.0:
		attack_queued = false
		attack_time = 0.0
		attack_cooldown_left = ATTACK_COOLDOWN
		hit_ids.clear()
		melee.monitoring = true
		return
	attack_queued = false


func _update_cast(delta: float) -> void:
	if cast_cooldown_left > 0.0:
		cast_cooldown_left = maxf(cast_cooldown_left - delta, 0.0)
	if not cast_queued:
		return
	cast_queued = false
	if cast_cooldown_left > 0.0:
		return
	cast_cooldown_left = CAST_COOLDOWN
	var bolt: Node = BOLT_SCENE.instantiate()
	bolt.set("direction", facing)
	bolt.set("damage", stats.bolt_damage)
	var spawn_pos := bolt_spawn.global_position
	get_parent().add_child(bolt)
	bolt.global_position = spawn_pos


func _on_melee_body_entered(body: Node) -> void:
	var strike_end := ATTACK_WINDUP + ATTACK_ACTIVE
	if attack_time < ATTACK_WINDUP or attack_time >= strike_end:
		return
	_damage_once(body, stats.melee_damage)


func _damage_once(body: Node, amount: int) -> void:
	if not body.has_method("take_damage"):
		return
	var body_id := body.get_instance_id()
	if hit_ids.has(body_id):
		return
	hit_ids.append(body_id)
	body.take_damage(amount)


func _update_animation() -> void:
	if attack_time >= 0.0:
		_play("attack")
	elif absf(velocity.x) > 10.0 and is_on_floor():
		_play("run")
	else:
		_play("idle")


func _play(anim_name: String) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim_name):
		return
	if sprite.animation != anim_name:
		sprite.play(anim_name)
