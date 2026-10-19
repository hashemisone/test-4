extends Control

signal closed

var _home: Control
var _keys: Control
var _options: Control
var _confirm_switch: CheckButton
var _sell_switch: CheckButton
var _list: VBoxContainer
var _prompt: Label
var _listening := false
var _action := ""
var _index := -1
var _tip: Panel
var _tip_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_home()


func show_home() -> void:
	_listening = false
	_hide_tip()
	_home.visible = true
	_keys.visible = false
	_options.visible = false


func _build() -> void:
	var panel := Panel.new()
	panel.position = Vector2(40, 24)
	panel.size = Vector2(560, 312)
	panel.add_theme_stylebox_override("panel", _frame())
	add_child(panel)
	_home = Control.new()
	_home.position = Vector2(40, 24)
	_home.size = Vector2(560, 312)
	_home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_home)
	_keys = Control.new()
	_keys.position = Vector2(40, 24)
	_keys.size = Vector2(560, 312)
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keys)
	_options = Control.new()
	_options.position = Vector2(40, 24)
	_options.size = Vector2(560, 312)
	_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_options)
	_add_title(_home, "Settings")
	var bindings := _menu_button("Keybindings")
	bindings.position = Vector2(180, 88)
	bindings.pressed.connect(_show_keys)
	_home.add_child(bindings)
	var options := _menu_button("Options")
	options.position = Vector2(180, 140)
	options.pressed.connect(_show_options)
	_home.add_child(options)
	var home_back := _menu_button("Back")
	home_back.position = Vector2(180, 192)
	home_back.pressed.connect(_leave)
	_home.add_child(home_back)
	_add_title(_options, "Options")
	var confirm_label := Label.new()
	confirm_label.position = Vector2(80, 120)
	confirm_label.size = Vector2(280, 32)
	confirm_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_label.text = "Destroy confirm"
	confirm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	confirm_label.add_theme_font_size_override("font_size", 16)
	_options.add_child(confirm_label)
	_confirm_switch = CheckButton.new()
	_confirm_switch.position = Vector2(372, 122)
	_confirm_switch.custom_minimum_size = Vector2(24, 24)
	_confirm_switch.size = Vector2(24, 24)
	_confirm_switch.text = ""
	_confirm_switch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_confirm_switch.toggled.connect(_on_confirm_toggled)
	_options.add_child(_confirm_switch)
	var sell_label := Label.new()
	sell_label.position = Vector2(80, 164)
	sell_label.size = Vector2(280, 32)
	sell_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sell_label.text = "Sell kept items"
	sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	sell_label.add_theme_font_size_override("font_size", 16)
	_options.add_child(sell_label)
	_sell_switch = CheckButton.new()
	_sell_switch.position = Vector2(372, 166)
	_sell_switch.custom_minimum_size = Vector2(24, 24)
	_sell_switch.size = Vector2(24, 24)
	_sell_switch.text = ""
	_sell_switch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_sell_switch.toggled.connect(_on_sell_toggled)
	_options.add_child(_sell_switch)
	var options_back := _menu_button("Back")
	options_back.position = Vector2(180, 192)
	options_back.pressed.connect(show_home)
	_options.add_child(options_back)
	_add_title(_keys, "Keybindings")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 52)
	scroll.size = Vector2(528, 196)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_keys.add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "BindingList"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	_prompt = Label.new()
	_prompt.position = Vector2(16, 252)
	_prompt.size = Vector2(320, 24)
	_prompt.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_keys.add_child(_prompt)
	var reset := _menu_button("Reset")
	reset.position = Vector2(250, 256)
	reset.size = Vector2(140, 40)
	reset.pressed.connect(_reset)
	_keys.add_child(reset)
	var keys_back := _menu_button("Back")
	keys_back.position = Vector2(404, 256)
	keys_back.size = Vector2(140, 40)
	keys_back.pressed.connect(show_home)
	_keys.add_child(keys_back)
	_tip = Panel.new()
	_tip.visible = false
	_tip.z_index = 20
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_theme_stylebox_override("panel", _frame())
	add_child(_tip)
	_tip_label = Label.new()
	_tip_label.position = Vector2(8, 6)
	_tip_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_tip_label.add_theme_font_size_override("font_size", 13)
	_tip.add_child(_tip_label)


func _show_options() -> void:
	_listening = false
	_hide_tip()
	_home.visible = false
	_keys.visible = false
	_options.visible = true
	_refresh_confirm_button()


func _on_confirm_toggled(enabled: bool) -> void:
	if enabled == PlayerState.confirm_destroy:
		return
	PlayerState.set_confirm_destroy(enabled)


func _on_sell_toggled(enabled: bool) -> void:
	if enabled == PlayerState.sell_kept:
		return
	PlayerState.set_sell_kept(enabled)


func _refresh_confirm_button() -> void:
	_confirm_switch.set_pressed_no_signal(PlayerState.confirm_destroy)
	_sell_switch.set_pressed_no_signal(PlayerState.sell_kept)


func _show_keys() -> void:
	_listening = false
	_home.visible = false
	_keys.visible = true
	_hide_tip()
	_prompt.text = "Click a keyboard or gamepad box, then press a new key or button."
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()
	for action in Keybinds.actions():
		var events := Keybinds.bindings(action)
		for index in events.size():
			_list.add_child(_binding_row(action, index, events[index]))


func _binding_row(action: String, index: int, event: InputEvent) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var keyboard := "—"
	var gamepad := "—"
	if event is InputEventKey:
		keyboard = Keybinds.event_label(event)
	else:
		gamepad = Keybinds.event_label(event)
	row.add_child(_binding_box(Keybinds.label(action), false, action, index))
	row.add_child(_binding_box(keyboard, event is InputEventKey, action, index))
	row.add_child(_binding_box(gamepad, not event is InputEventKey, action, index))
	return row


func _binding_box(text: String, clickable: bool, action: String, index: int) -> Button:
	var button := Button.new()
	button.text = text
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(168, 30)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	ButtonStyle.apply(button)
	button.set_meta("full_text", text)
	button.mouse_entered.connect(_hover_box.bind(button))
	button.mouse_exited.connect(_hide_tip)
	if clickable:
		button.pressed.connect(_listen.bind(action, index))
	return button


func _hover_box(button: Button) -> void:
	var full := str(button.get_meta("full_text"))
	if _fits(button, full):
		_hide_tip()
		return
	_tip_label.text = full
	_tip_label.size = _tip_label.get_minimum_size()
	_tip.size = _tip_label.size + Vector2(16, 12)
	var pos := button.get_global_rect().position + Vector2(0, button.size.y + 4)
	if pos.x + _tip.size.x > 628.0:
		pos.x = 628.0 - _tip.size.x
	if pos.y + _tip.size.y > 348.0:
		pos.y = button.get_global_rect().position.y - _tip.size.y - 4
	_tip.position = pos
	_tip.visible = true


func _fits(button: Button, text: String) -> bool:
	var font := button.get_theme_font("font")
	if font == null:
		return true
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	return width <= button.size.x - 12.0


func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false


func _listen(action: String, index: int) -> void:
	_action = action
	_index = index
	_listening = true
	_prompt.text = "Press a new key or button for %s." % Keybinds.label(action)


func _reset() -> void:
	_listening = false
	Keybinds.reset_defaults()
	_show_keys()


func _leave() -> void:
	_listening = false
	show_home()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not _listening or not visible:
		return
	if event is InputEventMouse or event.is_echo() or not event.is_pressed():
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5:
		return
	Keybinds.rebind(_action, _index, event)
	_listening = false
	_show_keys()
	get_viewport().set_input_as_handled()


func _add_title(parent: Control, title: String) -> void:
	var label := Label.new()
	label.position = Vector2(16, 12)
	label.size = Vector2(528, 32)
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	parent.add_child(label)


func _menu_button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.size = Vector2(200, 40)
	button.add_theme_font_size_override("font_size", 16)
	ButtonStyle.apply(button)
	return button


func _frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_border_width_all(4)
	style.border_color = Color(0, 0, 0, 1)
	return style
