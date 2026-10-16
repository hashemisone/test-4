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
var _choice_item: ItemData
var _choice_root: Control
var _choice_panel: Panel
var _choice_off: Button
var _tip_off: Panel


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
	_build_hand_choice()
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
	var item := PlayerState.inventory[index]
	if item.slot == ItemData.Slot.WEAPON and not item.two_handed:
		if PlayerState.weapon == null:
			_close_hand_choice()
			PlayerState.equip_to(item, ItemData.Slot.WEAPON)
			return
		_open_hand_choice(item, _bag_buttons[index])
		return
	_close_hand_choice()
	PlayerState.equip(item)


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
	_close_hand_choice()
	_hover_button = null
	_hover_time = 0.0
	_hide_tip()


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
	var blocks_offhand := PlayerState.blocks_offhand()
	for index in _slot_buttons.size():
		var item := PlayerState.item_in_slot(_slot_kinds[index])
		var caption := _slot_buttons[index].get_node("Caption") as Label
		caption.text = _slot_captions[index]
		_set_tip_item(_slot_buttons[index], item)
		_show_item_icon(_slot_buttons[index], item)
		var button := _slot_buttons[index]
		if _slot_kinds[index] == ItemData.Slot.OFFHAND and blocks_offhand:
			ButtonStyle.apply_blocked(button)
		else:
			button.disabled = false
			ButtonStyle.apply_item(button, item != null and item.rarity == ItemData.Rarity.UNCOMMON)
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
		ButtonStyle.apply_item(_bag_buttons[index], item != null and item.rarity == ItemData.Rarity.UNCOMMON)


func _set_tip_item(button: Button, item: ItemData) -> void:
	if item == null:
		if button.has_meta("tip_item"):
			button.remove_meta("tip_item")
	else:
		button.set_meta("tip_item", item)


func _process(delta: float) -> void:
	if not gear_open or (_choice_root != null and _choice_root.visible):
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
	var buttons: Array[Button] = _slot_buttons if character_tab else _bag_buttons
	for button in buttons:
		if button.is_visible_in_tree() and _contains_mouse(button):
			return button
	return null


func _contains_mouse(button: Button) -> bool:
	return button.get_global_rect().has_point(button.get_global_mouse_position())


func _build_hand_choice() -> void:
	_tip_off = $HoverTip.duplicate()
	_tip_off.name = "HoverTipOff"
	add_child(_tip_off)
	_tip_off.visible = false
	_choice_root = Control.new()
	_choice_root.name = "HandChoice"
	_choice_root.z_index = 30
	_choice_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_root.position = Vector2.ZERO
	_choice_root.size = Vector2(640, 360)
	_choice_root.visible = false
	add_child(_choice_root)
	var blocker := Button.new()
	blocker.flat = true
	blocker.position = Vector2.ZERO
	blocker.size = Vector2(640, 360)
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		blocker.add_theme_stylebox_override(state, empty)
	blocker.pressed.connect(_close_hand_choice)
	_choice_root.add_child(blocker)
	_choice_panel = Panel.new()
	_choice_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_panel.add_theme_stylebox_override("panel", _frame_box())
	_choice_panel.size = Vector2(108, 84)
	_choice_root.add_child(_choice_panel)
	var main_button := _choice_button("Main", Vector2(8, 8))
	main_button.pressed.connect(_choose_main)
	_choice_panel.add_child(main_button)
	_choice_off = _choice_button("Off-hand", Vector2(8, 44))
	_choice_off.pressed.connect(_choose_offhand)
	_choice_panel.add_child(_choice_off)


func _choice_button(label: String, at: Vector2) -> Button:
	var button := Button.new()
	button.text = label
	button.position = at
	button.size = Vector2(92, 32)
	button.add_theme_font_size_override("font_size", 13)
	ButtonStyle.apply(button)
	return button


func _frame_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_border_width_all(4)
	style.border_color = Color(0, 0, 0, 1)
	return style


func _open_hand_choice(item: ItemData, anchor: Button) -> void:
	_choice_item = item
	_choice_root.visible = true
	if PlayerState.can_wield_offhand(item):
		_choice_off.disabled = false
		ButtonStyle.apply(_choice_off)
	else:
		ButtonStyle.apply_blocked(_choice_off)
	var rect := anchor.get_global_rect()
	var pos := rect.position + Vector2(rect.size.x + 6.0, 0)
	if pos.x + _choice_panel.size.x > 628.0:
		pos.x = rect.position.x - _choice_panel.size.x - 6.0
	if pos.y + _choice_panel.size.y > 348.0:
		pos.y = 348.0 - _choice_panel.size.y
	_choice_panel.position = pos
	_hide_tip()


func _close_hand_choice() -> void:
	_choice_item = null
	if _choice_root != null:
		_choice_root.visible = false


func _choose_main() -> void:
	var item := _choice_item
	_close_hand_choice()
	if item != null:
		PlayerState.equip_to(item, ItemData.Slot.WEAPON)


func _choose_offhand() -> void:
	var item := _choice_item
	_close_hand_choice()
	if item != null:
		PlayerState.equip_to(item, ItemData.Slot.OFFHAND)


func _show_tip(item: ItemData) -> void:
	if item.slot == ItemData.Slot.WEAPON and not item.two_handed:
		_show_two_tips(item)
		return
	if _tip_off != null:
		_tip_off.visible = false
	_place_one($HoverTip, _tip_text(item))


func _show_two_tips(item: ItemData) -> void:
	var main_tip := $HoverTip as Panel
	var main_label := main_tip.get_node("Label") as RichTextLabel
	var off_label := _tip_off.get_node("Label") as RichTextLabel
	main_label.text = _hand_tip(item, ItemData.Slot.WEAPON)
	off_label.text = _hand_tip(item, ItemData.Slot.OFFHAND)
	var main_size := _tip_size(main_label)
	var off_size := _tip_size(off_label)
	main_tip.size = main_size
	_tip_off.size = off_size
	main_tip.visible = true
	_tip_off.visible = true
	var mouse := get_viewport().get_mouse_position()
	var gap := 6.0
	var total := main_size.x + gap + off_size.x
	var origin := mouse + Vector2(14, 18)
	if origin.x + total > 628.0:
		origin.x = mouse.x - total - 8.0
	var height := maxf(main_size.y, off_size.y)
	if origin.y + height > 348.0:
		origin.y = mouse.y - height - 8.0
	if origin.x < 4.0:
		origin.x = 4.0
	if origin.y < 4.0:
		origin.y = 4.0
	main_tip.position = origin
	_tip_off.position = origin + Vector2(main_size.x + gap, 0)


func _place_one(tip: Panel, text: String) -> void:
	var label := tip.get_node("Label") as RichTextLabel
	label.text = text
	tip.visible = true
	var text_size := _tip_size(label)
	tip.size = text_size
	var pos := get_viewport().get_mouse_position() + Vector2(14, 18)
	if pos.x + text_size.x > 628.0:
		pos.x = get_viewport().get_mouse_position().x - text_size.x - 8.0
	if pos.y + text_size.y > 348.0:
		pos.y = get_viewport().get_mouse_position().y - text_size.y - 8.0
	tip.position = pos


func _tip_size(label: RichTextLabel) -> Vector2:
	var text_size := label.get_minimum_size() + Vector2(16, 12)
	if text_size.x < 96.0:
		text_size.x = 96.0
	return text_size


func _hand_tip(item: ItemData, slot: ItemData.Slot) -> String:
	var title := "Main" if slot == ItemData.Slot.WEAPON else "Off-hand"
	var text := "%s\n%s\n%s" % [title, item.display_name, item.bonus_text()]
	var equipped := PlayerState.item_in_slot(slot)
	if equipped == null or equipped == item:
		return text
	var worn := PlayerState.weapon == item or PlayerState.offhand == item
	var delta := _delta_line(item, equipped, true, worn)
	if delta != "":
		text += "\n" + delta
	return text


func _tip_text(item: ItemData) -> String:
	var text := "%s\n%s" % [item.display_name, item.bonus_text()]
	var equipped := PlayerState.item_in_slot(item.slot)
	if equipped != null and equipped != item:
		var delta := _delta_line(item, equipped)
		if delta != "":
			text += "\n" + delta
	var removed := _offhand_removed_by(item)
	if removed != null:
		var loss := _loss_line(removed)
		if loss != "":
			text += "\n" + loss
	return text


func _offhand_removed_by(item: ItemData) -> ItemData:
	if not item.two_handed or PlayerState.item_in_slot(item.slot) == item:
		return null
	return PlayerState.item_in_slot(ItemData.Slot.OFFHAND)


func _loss_line(removed: ItemData) -> String:
	var parts: PackedStringArray = []
	var fields: Array[String] = ["health_bonus", "melee_bonus", "bolt_bonus"]
	var names: Array[String] = ["Health", "Melee", "Bolt"]
	for index in fields.size():
		var diff := -int(removed.get(fields[index]))
		if diff == 0:
			continue
		var color := "#1b7f34" if diff > 0 else "#c0392b"
		var sign := "+" if diff > 0 else ""
		parts.append("[color=%s]%s%d %s[/color]" % [color, sign, diff, names[index]])
	return "\n".join(parts)


func _delta_line(item: ItemData, other: ItemData, line_break: bool = false, losses_only: bool = false) -> String:
	if other == null:
		return ""
	var parts: PackedStringArray = []
	var fields: Array[String] = ["health_bonus", "melee_bonus", "bolt_bonus"]
	var names: Array[String] = ["Health", "Melee", "Bolt"]
	for index in fields.size():
		var now: int = int(item.get(fields[index]))
		var was: int = int(other.get(fields[index]))
		var diff := now - was
		if diff == 0 or (losses_only and diff > 0):
			continue
		var color := "#1b7f34" if diff > 0 else "#c0392b"
		var sign := "+" if diff > 0 else ""
		parts.append("[color=%s]%s%d %s[/color]" % [color, sign, diff, names[index]])
	if line_break:
		return "\n".join(parts)
	return " ".join(parts)


func _hide_tip() -> void:
	if has_node("HoverTip"):
		$HoverTip.visible = false
	if _tip_off != null:
		_tip_off.visible = false


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
