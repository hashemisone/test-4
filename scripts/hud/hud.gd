extends CanvasLayer

var stats_open := false
var player_health := 100
var player_max_health := 100
var melee_damage := 0
var bolt_damage := 0
var goblin_health := 30
var goblin_max_health := 30
var shooter_health := 22
var shooter_max_health := 22

@onready var hint_label: Label = $HintLabel
@onready var stats_button: Button = $StatsButton
@onready var dimmer: ColorRect = $Dimmer
@onready var stats_panel: ColorRect = $StatsPanel
@onready var health_label: Label = $StatsPanel/HealthLabel
@onready var melee_label: Label = $StatsPanel/MeleeLabel
@onready var bolt_label: Label = $StatsPanel/BoltLabel
@onready var goblin_label: Label = $StatsPanel/GoblinLabel
@onready var shooter_label: Label = $StatsPanel/ShooterLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	stats_button.pressed.connect(toggle_stats)
	_apply_open_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_stats"):
		toggle_stats()
		get_viewport().set_input_as_handled()


func show_player(current: int, maximum: int) -> void:
	player_health = current
	player_max_health = maximum
	_refresh_stats()


func show_target(current: int, maximum: int) -> void:
	goblin_health = current
	goblin_max_health = maximum
	_refresh_stats()


func show_shooter(current: int, maximum: int) -> void:
	shooter_health = current
	shooter_max_health = maximum
	_refresh_stats()


func show_offense(melee: int, bolt: int) -> void:
	melee_damage = melee
	bolt_damage = bolt
	_refresh_stats()


func show_status(message: String) -> void:
	hint_label.text = message


func toggle_stats() -> void:
	stats_open = not stats_open
	_apply_open_state()


func _apply_open_state() -> void:
	dimmer.visible = stats_open
	stats_panel.visible = stats_open
	stats_button.text = "Close" if stats_open else "Stats"
	get_tree().paused = stats_open
	_refresh_stats()


func _refresh_stats() -> void:
	if health_label == null:
		return
	health_label.text = "Health %d/%d" % [player_health, player_max_health]
	melee_label.text = "Melee %d" % melee_damage
	bolt_label.text = "Bolt %d" % bolt_damage
	if goblin_health <= 0:
		goblin_label.text = "Goblin down"
	else:
		goblin_label.text = "Goblin %d/%d" % [goblin_health, goblin_max_health]
	if shooter_label == null:
		return
	if shooter_health <= 0:
		shooter_label.text = "Shooter down"
	else:
		shooter_label.text = "Shooter %d/%d" % [shooter_health, shooter_max_health]
