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
@onready var character_tab_button: Button = $CharacterTab
@onready var inventory_tab_button: Button = $InventoryTab
@onready var dimmer: ColorRect = $Dimmer
@onready var gear_panel: Panel = $GearPanel
@onready var character_page: Control = $GearPanel/CharacterPage
@onready var inventory_page: Control = $GearPanel/InventoryPage
@onready var health_label: Label = $GearPanel/CharacterPage/HealthLabel
@onready var melee_label: Label = $GearPanel/CharacterPage/MeleeLabel
@onready var bolt_label: Label = $GearPanel/CharacterPage/BoltLabel
@onready var goblin_label: Label = $GoblinLabel
@onready var shooter_label: Label = $ShooterLabel

var _slot_buttons: Array[Button] = []
var _slot_kinds: Array[ItemData.Slot] = []
var _slot_captions: Array[String] = []
var _bag_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_bind_slot($GearPanel/CharacterPage/HelmetButton, ItemData.Slot.HELMET, "helmet")
	_bind_slot($GearPanel/CharacterPage/SwordButton, ItemData.Slot.WEAPON, "sword")
	_bind_slot($GearPanel/CharacterPage/BootsButton, ItemData.Slot.BOOTS, "boots")
	_bind_slot($GearPanel/CharacterPage/ArmorButton, ItemData.Slot.ARMOR, "armor")
	_bind_slot($GearPanel/CharacterPage/OffhandButton, ItemData.Slot.OFFHAND, "sword/\nshield")
	_bind_slot($GearPanel/CharacterPage/TrinketButton, ItemData.Slot.ACCESSORY, "trinket")
	for index in 9:
		var slot_button := get_node("GearPanel/InventoryPage/Slot%d" % index) as Button
		_bag_buttons.append(slot_button)
		slot_button.pressed.connect(_equip_from_bag.bind(index))
	for button in _slot_buttons:
		_add_icon(button)
		ButtonStyle.apply(button)
	for button in _bag_buttons:
		_add_icon(button)
		ButtonStyle.apply(button)
	ButtonStyle.apply(gear_button)
	gear_button.pressed.connect(toggle_gear)
	character_tab_button.pressed.connect(_show_character_tab)
	inventory_tab_button.pressed.connect(_show_inventory_tab)
	PlayerState.changed.connect(_refresh_gear)
	_apply_open_state()


func _add_icon(button: Button) -> void:
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8
	icon.offset_top = 6
	icon.offset_right = -8
	icon.offset_bottom = -28
	icon.hide()


func _bind_slot(button: Button, slot: ItemData.Slot, caption: String) -> void:
	_slot_buttons.append(button)
	_slot_kinds.append(slot)
	_slot_captions.append(caption)
	button.pressed.connect(_unequip_slot.bind(slot))


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


func _unequip_slot(slot: ItemData.Slot) -> void:
	PlayerState.unequip(slot)


func _equip_from_bag(index: int) -> void:
	if index < 0 or index >= PlayerState.inventory.size():
		return
	PlayerState.equip(PlayerState.inventory[index])


func _apply_open_state() -> void:
	dimmer.visible = gear_open
	gear_panel.visible = gear_open
	character_tab_button.visible = gear_open
	inventory_tab_button.visible = gear_open
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
	_paint_tab(character_tab_button, character_tab)
	_paint_tab(inventory_tab_button, not character_tab)


func _paint_tab(button: Button, active: bool) -> void:
	if active:
		ButtonStyle.apply_selected(button)
	else:
		ButtonStyle.apply(button)


func _refresh_gear() -> void:
	if health_label == null:
		return
	health_label.text = "Health %d/%d" % [PlayerState.current_health, PlayerState.max_health()]
	melee_label.text = "Melee %d" % PlayerState.melee_damage()
	bolt_label.text = "Bolt %d" % PlayerState.bolt_damage()
	for index in _slot_buttons.size():
		var item := PlayerState.item_in_slot(_slot_kinds[index])
		var caption := _slot_buttons[index].get_node("Caption") as Label
		if item == null:
			caption.text = _slot_captions[index]
		else:
			caption.text = item.bonus_text()
		_show_item_icon(_slot_buttons[index], item)
	for index in _bag_buttons.size():
		var caption := _bag_buttons[index].get_node("Caption") as Label
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		var item: ItemData = null
		if index < PlayerState.inventory.size():
			item = PlayerState.inventory[index]
			caption.text = "%s\n%s" % [item.display_name, item.bonus_text()]
		else:
			caption.text = ""
		_show_item_icon(_bag_buttons[index], item)


func _show_item_icon(button: Button, item: ItemData) -> void:
	var icon := button.get_node_or_null("Icon") as TextureRect
	if icon == null:
		return
	if item != null and item.icon != null:
		icon.texture = item.icon
		icon.show()
	else:
		icon.hide()


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
