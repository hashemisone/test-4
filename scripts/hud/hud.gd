extends CanvasLayer

var gear_open := false
var character_tab := true
var goblin_health := 30
var goblin_max_health := 30
var shooter_health := 22
var shooter_max_health := 22
var show_shooter_row := true

@onready var hint_label: Label = $HintLabel
@onready var gear_button: Button = $GearButton
@onready var dimmer: ColorRect = $Dimmer
@onready var gear_panel: ColorRect = $GearPanel
@onready var character_page: Control = $GearPanel/CharacterPage
@onready var inventory_page: Control = $GearPanel/InventoryPage
@onready var health_label: Label = $GearPanel/CharacterPage/HealthLabel
@onready var melee_label: Label = $GearPanel/CharacterPage/MeleeLabel
@onready var bolt_label: Label = $GearPanel/CharacterPage/BoltLabel
@onready var weapon_button: Button = $GearPanel/CharacterPage/WeaponButton
@onready var armor_button: Button = $GearPanel/CharacterPage/ArmorButton
@onready var accessory_button: Button = $GearPanel/CharacterPage/AccessoryButton
@onready var item_buttons: Array[Button] = [
	$GearPanel/InventoryPage/ItemButton0,
	$GearPanel/InventoryPage/ItemButton1,
	$GearPanel/InventoryPage/ItemButton2,
]
@onready var goblin_label: Label = $GoblinLabel
@onready var shooter_label: Label = $ShooterLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	gear_button.pressed.connect(toggle_gear)
	$GearPanel/CharacterTab.pressed.connect(_show_character_tab)
	$GearPanel/InventoryTab.pressed.connect(_show_inventory_tab)
	weapon_button.pressed.connect(_unequip_weapon)
	armor_button.pressed.connect(_unequip_armor)
	accessory_button.pressed.connect(_unequip_accessory)
	for index in item_buttons.size():
		item_buttons[index].pressed.connect(_equip_from_bag.bind(index))
	PlayerState.changed.connect(_refresh_gear)
	_apply_open_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_stats"):
		toggle_gear()
		get_viewport().set_input_as_handled()


func show_player(_current: int, _maximum: int) -> void:
	_refresh_gear()


func show_target(current: int, maximum: int) -> void:
	goblin_health = current
	goblin_max_health = maximum
	_refresh_enemies()


func show_shooter(current: int, maximum: int) -> void:
	shooter_health = current
	shooter_max_health = maximum
	_refresh_enemies()


func hide_shooter() -> void:
	show_shooter_row = false
	_refresh_enemies()


func show_offense(_melee: int, _bolt: int) -> void:
	_refresh_gear()


func show_status(message: String) -> void:
	hint_label.text = message


func toggle_gear() -> void:
	gear_open = not gear_open
	_apply_open_state()


func _show_character_tab() -> void:
	character_tab = true
	_apply_tab()


func _show_inventory_tab() -> void:
	character_tab = false
	_apply_tab()


func _unequip_weapon() -> void:
	PlayerState.unequip(ItemData.Slot.WEAPON)


func _unequip_armor() -> void:
	PlayerState.unequip(ItemData.Slot.ARMOR)


func _unequip_accessory() -> void:
	PlayerState.unequip(ItemData.Slot.ACCESSORY)


func _equip_from_bag(index: int) -> void:
	if index < 0 or index >= PlayerState.inventory.size():
		return
	PlayerState.equip(PlayerState.inventory[index])


func _apply_open_state() -> void:
	dimmer.visible = gear_open
	gear_panel.visible = gear_open
	gear_button.text = "Close" if gear_open else "Gear"
	get_tree().paused = gear_open
	_apply_tab()
	_refresh_gear()
	_refresh_enemies()


func _apply_tab() -> void:
	if character_page == null:
		return
	character_page.visible = character_tab
	inventory_page.visible = not character_tab


func _refresh_gear() -> void:
	if health_label == null:
		return
	health_label.text = "Health %d/%d" % [PlayerState.current_health, PlayerState.max_health()]
	melee_label.text = "Melee %d" % PlayerState.melee_damage()
	bolt_label.text = "Bolt %d" % PlayerState.bolt_damage()
	_set_slot_button(weapon_button, ItemData.Slot.WEAPON)
	_set_slot_button(armor_button, ItemData.Slot.ARMOR)
	_set_slot_button(accessory_button, ItemData.Slot.ACCESSORY)
	for index in item_buttons.size():
		var button := item_buttons[index]
		if index < PlayerState.inventory.size():
			button.visible = true
			button.disabled = false
			button.text = PlayerState.inventory[index].summary()
		else:
			button.visible = false
			button.disabled = true


func _set_slot_button(button: Button, slot: ItemData.Slot) -> void:
	var item := PlayerState.item_in_slot(slot)
	var title := "Slot"
	match slot:
		ItemData.Slot.WEAPON:
			title = "Weapon"
		ItemData.Slot.ARMOR:
			title = "Armor"
		_:
			title = "Accessory"
	if item == null:
		button.text = "%s: Empty" % title
	else:
		button.text = "%s: %s" % [title, item.display_name]


func _refresh_enemies() -> void:
	if goblin_label == null:
		return
	if goblin_health <= 0:
		goblin_label.text = "Goblin down"
	else:
		goblin_label.text = "Goblin %d/%d" % [goblin_health, goblin_max_health]
	if shooter_label == null:
		return
	shooter_label.visible = show_shooter_row
	if shooter_health <= 0:
		shooter_label.text = "Shooter down"
	else:
		shooter_label.text = "Shooter %d/%d" % [shooter_health, shooter_max_health]
