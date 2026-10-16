extends CanvasLayer

const HOVER_DELAY := 0.4

var gear_open := false
var _hover_button: Button
var _hover_time := 0.0
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
	icon.offset_bottom = -18
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
		caption.text = _slot_captions[index]
		_set_tip_item(_slot_buttons[index], item)
		_show_item_icon(_slot_buttons[index], item)
	for index in _bag_buttons.size():
		var caption := _bag_buttons[index].get_node("Caption") as Label
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		var item: ItemData = null
		if index < PlayerState.inventory.size():
			item = PlayerState.inventory[index]
			caption.text = item.display_name
		else:
			caption.text = ""
		_set_tip_item(_bag_buttons[index], item)
		_show_item_icon(_bag_buttons[index], item)


func _set_tip_item(button: Button, item: ItemData) -> void:
	if item == null:
		if button.has_meta("tip_item"):
			button.remove_meta("tip_item")
	else:
		button.set_meta("tip_item", item)


func _process(delta: float) -> void:
	if not gear_open:
		_hover_button = null
		_hover_time = 0.0
		_hide_tip()
		return
	var hovered := _button_under_mouse()
	if hovered != _hover_button:
		_hover_button = hovered
		_hover_time = 0.0
		_hide_tip()
	if _hover_button == null or not _hover_button.has_meta("tip_item"):
		return
	var hovered_item := _hover_button.get_meta("tip_item") as ItemData
	if hovered_item == null:
		return
	_hover_time += delta
	if _hover_time >= HOVER_DELAY:
		_show_tip(hovered_item)


func _button_under_mouse() -> Button:
	for button in _slot_buttons:
		if _contains_mouse(button):
			return button
	for button in _bag_buttons:
		if button.visible and _contains_mouse(button):
			return button
	return null


func _contains_mouse(button: Button) -> bool:
	return button.get_global_rect().has_point(button.get_global_mouse_position())


func _show_tip(item: ItemData) -> void:
	var tip := $HoverTip
	var label := $HoverTip/Label as RichTextLabel
	label.text = _tip_text(item)
	tip.visible = true
	var text_size := label.get_minimum_size() + Vector2(16, 12)
	if text_size.x < 88.0:
		text_size.x = 88.0
	tip.size = text_size
	var pos := get_viewport().get_mouse_position() + Vector2(14, 18)
	if pos.x + text_size.x > 628.0:
		pos.x = get_viewport().get_mouse_position().x - text_size.x - 8.0
	if pos.y + text_size.y > 348.0:
		pos.y = get_viewport().get_mouse_position().y - text_size.y - 8.0
	tip.position = pos


func _tip_text(item: ItemData) -> String:
	var body := "%s\n%s" % [item.display_name, item.bonus_text()]
	var equipped := PlayerState.item_in_slot(item.slot)
	if equipped == null:
		return body
	var other: ItemData = null if equipped == item else equipped
	var delta := _delta_line(item, other)
	if delta == "":
		return body
	return "%s\n%s" % [body, delta]


func _delta_line(item: ItemData, other: ItemData) -> String:
	var parts: PackedStringArray = []
	var fields: Array[String] = ["health_bonus", "melee_bonus", "bolt_bonus"]
	var names: Array[String] = ["Health", "Melee", "Bolt"]
	for index in fields.size():
		var now: int = int(item.get(fields[index]))
		var was: int = int(other.get(fields[index])) if other != null else 0
		var diff := now - was
		if diff == 0:
			continue
		var color := "#1b7f34" if diff > 0 else "#c0392b"
		var sign := "+" if diff > 0 else ""
		parts.append("[color=%s]%s%d %s[/color]" % [color, sign, diff, names[index]])
	return " ".join(parts)


func _hide_tip() -> void:
	if has_node("HoverTip"):
		$HoverTip.visible = false


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
