extends CanvasLayer

signal hub_closed

const HOVER_DELAY := 0.4

@export var hub := false

enum PauseView { CLOSED, MENU, SHEET, CHEAT, SETTINGS }

var pause_view := PauseView.CLOSED
var _hover_button: Button
var _hover_time := 0.0
var character_tab := true

@onready var hint_label: Label = $HintLabel
@onready var gear_button: Button = $GearButton
@onready var character_box: Button = $CharacterBox
@onready var inventory_box: Button = $InventoryBox
@onready var dimmer: ColorRect = $Dimmer
@onready var gear_panel: Panel = $GearPanel
@onready var character_page: Control = $GearPanel/CharacterPage
@onready var inventory_page: Control = $GearPanel/InventoryPage
@onready var health_label: Label = $GearPanel/CharacterPage/HealthLabel
@onready var melee_label: Label = $GearPanel/CharacterPage/MeleeLabel
@onready var bolt_label: Label = $GearPanel/CharacterPage/BoltLabel

var _slot_buttons: Array[Button] = []
var _slot_kinds: Array[ItemData.Slot] = []
var _slot_captions: Array[String] = []
var _bag_buttons: Array[Button] = []
var _choice_item: ItemData
var _choice_root: Control
var _choice_panel: Panel
var _choice_off: Button
var _destroy_item: ItemData
var _destroy_amount := 0
var _destroy_shade: ColorRect
var _destroy_menu: Panel
var _amount_menu: Panel
var _confirm_menu: Panel
var _amount_edit: LineEdit
var _dont_ask: CheckButton
var _tip_off: Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	_bind_slot($GearPanel/CharacterPage/HelmetButton, ItemData.Slot.HELMET, "helmet")
	_bind_slot($GearPanel/CharacterPage/TrinketButton, ItemData.Slot.ACCESSORY, "trinket")
	_bind_slot($GearPanel/CharacterPage/ArmorButton, ItemData.Slot.ARMOR, "armor")
	_bind_slot($GearPanel/CharacterPage/CapeButton, ItemData.Slot.CAPE, "cape")
	_bind_slot($GearPanel/CharacterPage/BraceletButton, ItemData.Slot.BRACELET, "bracelet")
	_bind_slot($GearPanel/CharacterPage/PantsButton, ItemData.Slot.PANTS, "pants")
	_bind_slot($GearPanel/CharacterPage/GlovesButton, ItemData.Slot.GLOVES, "gloves")
	_bind_slot($GearPanel/CharacterPage/SwordButton, ItemData.Slot.WEAPON, "main\nhand")
	_bind_slot($GearPanel/CharacterPage/BootsButton, ItemData.Slot.BOOTS, "boots")
	_bind_slot($GearPanel/CharacterPage/OffhandButton, ItemData.Slot.OFFHAND, "off\nhand")
	for index in 16:
		var slot_button := get_node("GearPanel/InventoryPage/Slot%d" % index) as Button
		_bag_buttons.append(slot_button)
		slot_button.pressed.connect(_equip_from_bag.bind(index))
		slot_button.gui_input.connect(_item_gui.bind("bag", index))
	for button in _slot_buttons:
		_add_icon(button)
		ButtonStyle.apply(button)
	for button in _bag_buttons:
		_add_icon(button)
		ButtonStyle.apply(button)
	ButtonStyle.apply(gear_button)
	gear_button.pressed.connect(toggle_gear)
	ButtonStyle.apply($BackButton)
	$BackButton.pressed.connect(_back_to_menu)
	for menu_button in [$PauseMenu/Resume, $PauseMenu/Quit]:
		ButtonStyle.apply(menu_button)
	$PauseMenu/Resume.pressed.connect(_resume)
	$PauseMenu/Quit.pressed.connect(_quit_run)
	ButtonStyle.apply(character_box)
	ButtonStyle.apply(inventory_box)
	character_box.pressed.connect(_toggle_character)
	inventory_box.pressed.connect(_toggle_inventory)
	ButtonStyle.apply($PauseMenu/Cheat)
	$PauseMenu/Cheat.pressed.connect(_open_cheat)
	ButtonStyle.apply($PauseMenu/SettingsButton)
	$PauseMenu/SettingsButton.pressed.connect(_open_settings)
	$Settings.closed.connect(_back_to_menu)
	PlayerState.changed.connect(_refresh_gear)
	_add_icon($Potion1)
	_add_icon($Potion2)
	ButtonStyle.apply($Potion1)
	ButtonStyle.apply($Potion2)
	$Potion1.pressed.connect(_use_quick_potion.bind(0))
	$Potion2.pressed.connect(_use_quick_potion.bind(1))
	$Potion1.gui_input.connect(_item_gui.bind("potion", 0))
	$Potion2.gui_input.connect(_item_gui.bind("potion", 1))
	_build_destroy_ui()
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
	_fit_icon(button)
	icon.hide()


func _bind_slot(button: Button, slot: ItemData.Slot, caption: String) -> void:
	_slot_buttons.append(button)
	_slot_kinds.append(slot)
	_slot_captions.append(caption)
	button.pressed.connect(_unequip_slot.bind(slot))
	button.gui_input.connect(_item_gui.bind("slot", int(slot)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if hub and not visible:
		return
	if hub and (event.is_action_pressed("potion_1") or event.is_action_pressed("potion_2")):
		return
	if event.is_action_pressed("toggle_stats"):
		toggle_gear()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("potion_1"):
		_use_quick_potion(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("potion_2"):
		_use_quick_potion(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("character"):
		_toggle_character()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()


func show_player(_current: int, _maximum: int) -> void:
	_refresh_gear()


func show_offense(_melee: int, _bolt: int) -> void:
	_refresh_gear()


func show_status(message: String) -> void:
	hint_label.text = message


func toggle_gear() -> void:
	if hub:
		if pause_view != PauseView.CLOSED:
			_close_hub()
		return
	if pause_view == PauseView.CLOSED:
		pause_view = PauseView.MENU
	else:
		pause_view = PauseView.CLOSED
	_apply_open_state()


func open_hub_sheet(character: bool) -> void:
	hub = true
	visible = true
	character_tab = character
	pause_view = PauseView.SHEET
	_apply_open_state()


func _resume() -> void:
	pause_view = PauseView.CLOSED
	_apply_open_state()


func _toggle_character() -> void:
	if pause_view == PauseView.SHEET and character_tab:
		if hub:
			_close_hub()
			return
		pause_view = PauseView.CLOSED
	else:
		character_tab = true
		pause_view = PauseView.SHEET
	_apply_open_state()


func _toggle_inventory() -> void:
	if pause_view == PauseView.SHEET and not character_tab:
		if hub:
			_close_hub()
			return
		pause_view = PauseView.CLOSED
	else:
		character_tab = false
		pause_view = PauseView.SHEET
	_apply_open_state()


func _back_to_menu() -> void:
	if hub:
		_close_hub()
		return
	pause_view = PauseView.MENU
	_apply_open_state()


func _close_hub() -> void:
	pause_view = PauseView.CLOSED
	_apply_open_state()
	visible = false
	hub_closed.emit()


func _open_cheat() -> void:
	pause_view = PauseView.CHEAT
	_apply_open_state()


func _open_settings() -> void:
	pause_view = PauseView.SETTINGS
	$Settings.show_home()
	_apply_open_state()


func _quit_run() -> void:
	get_tree().paused = false
	PlayerState.end_run()
	PlayerState.return_to_levels = true
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _unequip_slot(slot: ItemData.Slot) -> void:
	PlayerState.unequip(slot)


func _equip_from_bag(index: int) -> void:
	if index < 0 or index >= PlayerState.inventory.size():
		return
	var item := PlayerState.inventory[index]
	if item.is_potion():
		_close_hand_choice()
		PlayerState.equip_quick_potion(item)
		return
	if item.slot == ItemData.Slot.WEAPON and not item.two_handed:
		if not PlayerState.can_wield_offhand(item):
			_close_hand_choice()
			PlayerState.equip_to(item, ItemData.Slot.WEAPON)
			return
		_open_hand_choice(item, _bag_buttons[index])
		return
	_close_hand_choice()
	PlayerState.equip(item)


func _apply_open_state() -> void:
	var open := pause_view != PauseView.CLOSED
	dimmer.visible = open
	$PauseMenu.visible = pause_view == PauseView.MENU
	gear_panel.visible = pause_view == PauseView.SHEET
	$CheatPage.visible = pause_view == PauseView.CHEAT
	$Settings.visible = pause_view == PauseView.SETTINGS
	$BackButton.visible = pause_view == PauseView.SHEET or pause_view == PauseView.CHEAT
	var show_boxes := pause_view != PauseView.CHEAT and pause_view != PauseView.SETTINGS
	character_box.visible = show_boxes
	inventory_box.visible = show_boxes
	_refresh_sheet_keys()
	gear_button.text = "Close" if open else "Menu"
	if hub:
		get_tree().paused = false
	else:
		get_tree().paused = open
	_apply_tab()
	_refresh_gear()
	if hub:
		_hide_fight_chrome()


func _hide_fight_chrome() -> void:
	$GearButton.visible = false
	$Potion1.visible = false
	$Potion2.visible = false
	$PlayerHealth.visible = false
	$CoinIcon.visible = false
	$CoinLabel.visible = false
	$HintLabel.visible = false
	$BuffLabel.visible = false


func _apply_tab() -> void:
	if character_page == null:
		return
	character_page.visible = character_tab
	inventory_page.visible = not character_tab
	_paint_sheet_button(character_box, pause_view == PauseView.SHEET and character_tab)
	_paint_sheet_button(inventory_box, pause_view == PauseView.SHEET and not character_tab)
	_close_hand_choice()
	_hover_button = null
	_hover_time = 0.0
	_hide_tip()


func _refresh_sheet_keys() -> void:
	_set_box_key(character_box, "character")
	_set_box_key(inventory_box, "inventory")


func _set_box_key(button: Button, action: String) -> void:
	var label := button.get_node("Key") as Label
	var shown := ""
	for event in Keybinds.bindings(action):
		if event is InputEventKey:
			shown = OS.get_keycode_string(event.physical_keycode)
			break
	label.text = shown


func _paint_sheet_button(button: Button, active: bool) -> void:
	if active:
		ButtonStyle.apply_selected(button)
	else:
		ButtonStyle.apply(button)
	var color := Color(1, 1, 1, 1) if active else Color(0, 0, 0, 1)
	for node_name in ["Key", "Caption"]:
		var label := button.get_node(node_name) as Label
		label.add_theme_color_override("font_color", color)


func _refresh_gear() -> void:
	if health_label == null:
		return
	health_label.text = "Health %d/%d" % [PlayerState.current_health, PlayerState.max_health()]
	_refresh_health_bar()
	var coin_label := get_node_or_null("CoinLabel") as Label
	if coin_label != null:
		coin_label.text = str(PlayerState.coins)
	melee_label.text = "Melee %d" % PlayerState.melee_damage()
	bolt_label.text = "Bolt %d" % PlayerState.bolt_damage()
	_refresh_buffs()
	_refresh_quick_potions()
	var blocks_offhand := PlayerState.blocks_offhand()
	for index in _slot_buttons.size():
		var item := PlayerState.item_in_slot(_slot_kinds[index])
		var caption := _slot_buttons[index].get_node("Caption") as Label
		caption.text = item.display_name if item != null else _slot_captions[index]
		_set_tip_item(_slot_buttons[index], item)
		_show_item_icon(_slot_buttons[index], item)
		var button := _slot_buttons[index]
		if _slot_kinds[index] == ItemData.Slot.OFFHAND and blocks_offhand:
			ButtonStyle.apply_blocked(button)
		else:
			button.disabled = false
			ButtonStyle.apply_item(button, item != null and item.rarity == ItemData.Rarity.UNCOMMON, item != null and item.permanent)
	for index in _bag_buttons.size():
		var caption := _bag_buttons[index].get_node("Caption") as Label
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		var item: ItemData = null
		if index < PlayerState.inventory.size():
			item = PlayerState.inventory[index]
			caption.text = _stack_name(item)
		else:
			caption.text = ""
		_set_tip_item(_bag_buttons[index], item)
		_show_item_icon(_bag_buttons[index], item)
		ButtonStyle.apply_item(_bag_buttons[index], item != null and item.rarity == ItemData.Rarity.UNCOMMON, item != null and item.permanent)


func _set_tip_item(button: Button, item: ItemData) -> void:
	if item == null:
		if button.has_meta("tip_item"):
			button.remove_meta("tip_item")
	else:
		button.set_meta("tip_item", item)


func _process(delta: float) -> void:
	if pause_view != PauseView.SHEET or (_choice_root != null and _choice_root.visible):
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


func _frame_box(fill: Color = Color(1, 1, 1, 1)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
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


func _stack_name(item: ItemData) -> String:
	if item.is_potion() and item.stack > 1:
		return "%s\nx%d" % [item.display_name, item.stack]
	return item.display_name


func _item_gui(event: InputEvent, kind: String, which: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_RIGHT:
		return
	var item := _clicked_item(kind, which)
	if item == null:
		return
	_open_destroy(item)
	get_viewport().set_input_as_handled()


func _clicked_item(kind: String, which: int) -> ItemData:
	if kind == "bag":
		if which < 0 or which >= PlayerState.inventory.size():
			return null
		return PlayerState.inventory[which]
	if kind == "potion":
		return PlayerState.quick_potion(which)
	return PlayerState.item_in_slot(which as ItemData.Slot)


func _build_destroy_ui() -> void:
	_destroy_shade = ColorRect.new()
	_destroy_shade.color = Color(0, 0, 0, 0.25)
	_destroy_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_destroy_shade.visible = false
	_destroy_shade.z_index = 40
	_destroy_shade.gui_input.connect(_close_destroy_event)
	add_child(_destroy_shade)
	_destroy_menu = _small_panel()
	var destroy := _destroy_button("Destroy")
	destroy.pressed.connect(_click_destroy)
	_destroy_menu.add_child(destroy)
	_amount_menu = _small_panel()
	var one := _destroy_button("Destroy 1")
	one.position = Vector2(8, 8)
	one.pressed.connect(_request_destroy.bind(1))
	_amount_menu.add_child(one)
	var all := _destroy_button("Destroy all")
	all.position = Vector2(8, 46)
	all.pressed.connect(_request_destroy_all)
	_amount_menu.add_child(all)
	_amount_edit = LineEdit.new()
	_amount_edit.position = Vector2(8, 88)
	_amount_edit.size = Vector2(86, 32)
	_amount_edit.placeholder_text = "Number"
	_amount_edit.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_amount_menu.add_child(_amount_edit)
	var ok := _destroy_button("Ok")
	ok.position = Vector2(98, 88)
	ok.size = Vector2(54, 32)
	ok.pressed.connect(_request_destroy_typed)
	_amount_menu.add_child(ok)
	_confirm_menu = _small_panel()
	_confirm_menu.size = Vector2(280, 168)
	var ask := Label.new()
	ask.position = Vector2(12, 12)
	ask.size = Vector2(256, 28)
	ask.text = "Are you sure?"
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	ask.add_theme_font_size_override("font_size", 18)
	_confirm_menu.add_child(ask)
	_dont_ask = CheckButton.new()
	_dont_ask.position = Vector2(24, 48)
	_dont_ask.size = Vector2(232, 28)
	_dont_ask.text = "Don't ask again"
	_dont_ask.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_confirm_menu.add_child(_dont_ask)
	var yes := _destroy_button("Yes")
	yes.position = Vector2(16, 96)
	yes.size = Vector2(116, 40)
	yes.pressed.connect(_confirm_destroy)
	_confirm_menu.add_child(yes)
	var no := _destroy_button("No")
	no.position = Vector2(148, 96)
	no.size = Vector2(116, 40)
	no.pressed.connect(_close_destroy)
	_confirm_menu.add_child(no)


func _small_panel() -> Panel:
	var panel := Panel.new()
	panel.visible = false
	panel.z_index = 41
	panel.size = Vector2(160, 128)
	panel.add_theme_stylebox_override("panel", _menu_frame())
	add_child(panel)
	return panel


func _menu_frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_border_width_all(3)
	style.border_color = Color(0, 0, 0, 1)
	return style


func _destroy_button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.position = Vector2(8, 8)
	button.size = Vector2(144, 32)
	button.add_theme_font_size_override("font_size", 14)
	ButtonStyle.apply(button)
	return button


func _open_destroy(item: ItemData) -> void:
	_destroy_item = item
	_destroy_amount = 0
	_amount_edit.text = ""
	_dont_ask.button_pressed = false
	_amount_menu.visible = false
	_confirm_menu.visible = false
	_destroy_menu.visible = true
	_destroy_shade.visible = true
	_place_popup(_destroy_menu, get_viewport().get_mouse_position())


func _click_destroy() -> void:
	if _destroy_item == null:
		_close_destroy()
		return
	if _destroy_item.stack > 1:
		_destroy_menu.visible = false
		_amount_menu.visible = true
		_place_popup(_amount_menu, _destroy_menu.position)
		return
	_request_destroy(1)


func _request_destroy_all() -> void:
	if _destroy_item == null:
		_close_destroy()
		return
	_request_destroy(_destroy_item.stack)


func _request_destroy_typed() -> void:
	var text := _amount_edit.text.strip_edges()
	if not text.is_valid_int():
		return
	var amount := int(text)
	if amount <= 0:
		return
	_request_destroy(amount)


func _request_destroy(amount: int) -> void:
	var item := _destroy_item
	if item == null:
		_close_destroy()
		return
	if item.permanent and PlayerState.confirm_destroy:
		_destroy_amount = amount
		_destroy_menu.visible = false
		_amount_menu.visible = false
		_confirm_menu.visible = true
		_confirm_menu.position = Vector2(180, 96)
		return
	PlayerState.destroy_item(item, amount)
	_close_destroy()


func _confirm_destroy() -> void:
	if _dont_ask.button_pressed:
		PlayerState.set_confirm_destroy(false)
	PlayerState.destroy_item(_destroy_item, _destroy_amount)
	_close_destroy()


func _place_popup(panel: Control, at: Vector2) -> void:
	var pos := at
	if pos.x + panel.size.x > 628.0:
		pos.x = 628.0 - panel.size.x
	if pos.y + panel.size.y > 348.0:
		pos.y = 348.0 - panel.size.y
	panel.position = pos


func _close_destroy_event(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_destroy()


func _close_destroy() -> void:
	_destroy_item = null
	_destroy_amount = 0
	_destroy_shade.visible = false
	_destroy_menu.visible = false
	_amount_menu.visible = false
	_confirm_menu.visible = false


func _use_quick_potion(index: int) -> void:
	PlayerState.use_quick_potion(index)


func _refresh_quick_potions() -> void:
	var buttons: Array[Button] = [$Potion1, $Potion2]
	var keys: Array[String] = ["1", "2"]
	for index in buttons.size():
		var item := PlayerState.quick_potion(index)
		var caption := buttons[index].get_node("Caption") as Label
		caption.text = _stack_name(item) if item != null else keys[index]
		_show_item_icon(buttons[index], item)
		if item != null:
			ButtonStyle.apply_item(buttons[index], false, item.permanent)


func _refresh_health_bar() -> void:
	var bar := get_node_or_null("PlayerHealth") as Control
	if bar == null:
		return
	var maximum := maxi(PlayerState.max_health(), 1)
	var current := clampi(PlayerState.current_health, 0, maximum)
	var bonus := clampi(PlayerState.bonus_health, 0, maximum)
	var outer := bar.size
	if outer.x < 1.0:
		outer = Vector2(bar.offset_right - bar.offset_left, bar.offset_bottom - bar.offset_top)
	var inset := 2.0
	var width := outer.x - inset * 2.0
	var height := outer.y - inset * 2.0
	var fill_w := clampf(width * float(current) / float(maximum), 0.0, width)
	var bonus_w := clampf(width * float(bonus) / float(maximum), 0.0, width)
	var bonus_x := inset + width - bonus_w
	var bonus_rect := bar.get_node("Bonus") as ColorRect
	bonus_rect.position = Vector2(bonus_x, inset)
	bonus_rect.size = Vector2(bonus_w, height)
	var fill := bar.get_node("Fill") as ColorRect
	fill.position = Vector2(inset, inset)
	fill.size = Vector2(fill_w, height)
	var bright := bar.get_node("BonusFill") as ColorRect
	var overlap := clampf(fill_w - (width - bonus_w), 0.0, bonus_w)
	bright.position = Vector2(bonus_x, inset)
	bright.size = Vector2(overlap, height)
	bright.visible = overlap > 0.5
	var value := bar.get_node("Value") as Label
	value.text = "%d/%d" % [current, maximum]


func _refresh_buffs() -> void:
	var label := get_node_or_null("BuffLabel") as Label
	if label == null:
		return
	var lines: PackedStringArray = []
	if PlayerState.bonus_health > 0:
		lines.append("Health +%d %ds" % [PlayerState.bonus_health, ceili(PlayerState.bonus_health_left)])
	if PlayerState.bonus_melee > 0:
		lines.append("Attack +%d %ds" % [PlayerState.bonus_melee, ceili(PlayerState.bonus_melee_left)])
	label.text = "\n".join(lines)
	label.visible = lines.size() > 0


func _show_tip(item: ItemData) -> void:
	if item.is_potion():
		if _tip_off != null:
			_tip_off.visible = false
		_place_one($HoverTip, _named_tip(item))
		return
	if item.slot == ItemData.Slot.WEAPON and not item.two_handed:
		_show_two_tips(item)
		return
	if _tip_off != null:
		_tip_off.visible = false
	var blocked := _offhand_blocked(item)
	_place_one($HoverTip, _tip_text(item), blocked)


func _show_two_tips(item: ItemData) -> void:
	var main_tip := $HoverTip as Panel
	var main_label := main_tip.get_node("Label") as RichTextLabel
	var off_label := _tip_off.get_node("Label") as RichTextLabel
	var off_blocked := _offhand_blocked(item)
	main_label.text = _hand_tip(item, ItemData.Slot.WEAPON)
	off_label.text = _hand_tip(item, ItemData.Slot.OFFHAND)
	_paint_tip(main_tip, false)
	_paint_tip(_tip_off, off_blocked)
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


func _offhand_blocked(item: ItemData) -> bool:
	if PlayerState.offhand == item:
		return false
	if item.slot == ItemData.Slot.WEAPON and not item.two_handed and PlayerState.weapon == item:
		return true
	if not PlayerState.blocks_offhand():
		return false
	if item.slot == ItemData.Slot.OFFHAND:
		return true
	return item.slot == ItemData.Slot.WEAPON and not item.two_handed


func _paint_tip(tip: Panel, blocked: bool) -> void:
	var fill := Color(0.75, 0.75, 0.75, 1) if blocked else Color(1, 1, 1, 1)
	tip.add_theme_stylebox_override("panel", _frame_box(fill))
	var label := tip.get_node("Label") as RichTextLabel
	var font := Color(0.35, 0.35, 0.35, 1) if blocked else Color(0, 0, 0, 1)
	label.add_theme_color_override("default_color", font)


func _place_one(tip: Panel, text: String, blocked: bool = false) -> void:
	var label := tip.get_node("Label") as RichTextLabel
	label.text = text
	_paint_tip(tip, blocked)
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


func _named_tip(item: ItemData) -> String:
	var text := "%s\n%s" % [item.display_name, item.durability_label()]
	var bonus := item.bonus_text()
	if bonus != "":
		text += "\n" + bonus
	return text


func _hand_tip(item: ItemData, slot: ItemData.Slot) -> String:
	var title := "Main" if slot == ItemData.Slot.WEAPON else "Off-hand"
	var text := "%s\n%s" % [title, _named_tip(item)]
	var equipped := PlayerState.item_in_slot(slot)
	if equipped == item:
		return text
	if equipped == null and slot == ItemData.Slot.OFFHAND and PlayerState.weapon == item:
		return text
	var worn := PlayerState.weapon == item or PlayerState.offhand == item
	var delta := _delta_line(item, equipped, worn and equipped != null, equipped == null)
	if delta != "":
		text += "\n" + delta
	return text


func _tip_text(item: ItemData) -> String:
	var text := _named_tip(item)
	var equipped := PlayerState.item_in_slot(item.slot)
	var removed := _offhand_removed_by(item)
	if equipped == null:
		var gain := _delta_line(item, null, false, true, removed)
		if gain != "":
			text += "\n" + gain
		return text
	if equipped != null and equipped != item:
		var delta := _delta_line(item, equipped, false, false, removed)
		if delta != "":
			text += "\n" + delta
	elif removed != null:
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


func _delta_line(item: ItemData, other: ItemData, losses_only: bool = false, against_empty: bool = false, removed: ItemData = null) -> String:
	if other == null and removed == null and not against_empty:
		return ""
	var parts: PackedStringArray = []
	var fields: Array[String] = ["health_bonus", "melee_bonus", "bolt_bonus"]
	var names: Array[String] = ["Health", "Melee", "Bolt"]
	for index in _stat_order(item):
		var now: int = int(item.get(fields[index]))
		var was := 0
		if other != null:
			was += int(other.get(fields[index]))
		if removed != null:
			was += int(removed.get(fields[index]))
		var diff := now - was
		if diff == 0 or (losses_only and diff > 0):
			continue
		var color := "#1b7f34" if diff > 0 else "#c0392b"
		var sign := "+" if diff > 0 else ""
		parts.append("[color=%s]%s%d %s[/color]" % [color, sign, diff, names[index]])
	return "\n".join(parts)


func _stat_order(item: ItemData) -> Array[int]:
	var primary := 0
	if item.melee_bonus != 0:
		primary = 1
	elif item.bolt_bonus != 0:
		primary = 2
	var order: Array[int] = [primary]
	for index in 3:
		if index != primary:
			order.append(index)
	return order


func _hide_tip() -> void:
	if has_node("HoverTip"):
		$HoverTip.visible = false
	if _tip_off != null:
		_tip_off.visible = false


func _fit_icon(button: Button) -> void:
	var icon := button.get_node_or_null("Icon") as TextureRect
	if icon == null:
		return
	var box := button.size
	if box.x < 1.0:
		box.x = button.offset_right - button.offset_left
	if box.y < 1.0:
		box.y = button.offset_bottom - button.offset_top
	var pad := maxf(2.0, round(box.x * 0.1))
	var caption := maxf(7.0, round(box.y * 0.22))
	icon.offset_left = pad
	icon.offset_top = pad
	icon.offset_right = -pad
	icon.offset_bottom = -caption


func _show_item_icon(button: Button, item: ItemData) -> void:
	var icon := button.get_node_or_null("Icon") as TextureRect
	if icon == null:
		return
	_fit_icon(button)
	if item != null and item.icon != null:
		icon.texture = item.icon
		icon.show()
	else:
		icon.hide()
