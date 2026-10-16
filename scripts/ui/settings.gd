extends Control

signal closed

var _home: Control
var _keys: Control
var _list: VBoxContainer
var _prompt: Label
var _listening := false
var _action := ""
var _index := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_home()


func show_home() -> void:
	_listening = false
	_home.visible = true
	_keys.visible = false


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
	_add_title(_home, "Settings")
	var bindings := _menu_button("Keybindings")
	bindings.position = Vector2(180, 110)
	bindings.pressed.connect(_show_keys)
	_home.add_child(bindings)
	var home_back := _menu_button("Back")
	home_back.position = Vector2(180, 166)
	home_back.pressed.connect(_leave)
	_home.add_child(home_back)
	_add_title(_keys, "Keybindings")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 52)
	scroll.size = Vector2(528, 196)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_keys.add_child(scroll)
	_list = VBoxContainer.new()
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


func _show_keys() -> void:
	_listening = false
	_home.visible = false
	_keys.visible = true
	_prompt.text = "Click a binding, then press a key or button."
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()
	for action in Keybinds.actions():
		var events := Keybinds.bindings(action)
		for index in events.size():
			var title := "%s    %s" % [Keybinds.label(action), Keybinds.event_label(events[index])]
			var button := Button.new()
			button.text = title
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0, 30)
			ButtonStyle.apply(button)
			button.pressed.connect(_listen.bind(action, index))
			_list.add_child(button)


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
