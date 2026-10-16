extends Node

const SAVE_PATH := "user://keybindings.json"

var _defaults := {}


func _ready() -> void:
	for action in InputMap.get_actions():
		if _hidden(action):
			continue
		var saved: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			saved.append(event.duplicate())
		_defaults[action] = saved
	_load()


func actions() -> PackedStringArray:
	var names: PackedStringArray = []
	for action in InputMap.get_actions():
		if _hidden(action):
			continue
		names.append(action)
	names.sort()
	return names


func bindings(action: String) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for event in InputMap.action_get_events(action):
		events.append(event)
	return events


func label(action: String) -> String:
	var words: PackedStringArray = []
	for part in action.split("_"):
		words.append(part.capitalize())
	return " ".join(words)


func event_label(event: InputEvent) -> String:
	return event.as_text()


func rebind(action: String, index: int, event: InputEvent) -> void:
	var replacement := _clean(event)
	if replacement == null or not InputMap.has_action(action):
		return
	_remove_matching(replacement)
	var events: Array[InputEvent] = bindings(action)
	if index < 0 or index >= events.size():
		return
	events[index] = replacement
	InputMap.action_erase_events(action)
	for kept in events:
		InputMap.action_add_event(action, kept)
	_save()


func reset_defaults() -> void:
	for action in _defaults:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event in _defaults[action]:
			InputMap.action_add_event(action, event.duplicate())
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _hidden(action: String) -> bool:
	return action.begins_with("ui_")


func _clean(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode
		if key.physical_keycode == 0:
			return null
		return key
	if event is InputEventJoypadButton:
		var button := InputEventJoypadButton.new()
		button.button_index = event.button_index
		return button
	if event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5:
		var motion := InputEventJoypadMotion.new()
		motion.axis = event.axis
		motion.axis_value = -1.0 if event.axis_value < 0.0 else 1.0
		return motion
	return null


func _remove_matching(event: InputEvent) -> void:
	for action in actions():
		var kept: Array[InputEvent] = []
		var removed := false
		for existing in bindings(action):
			if not removed and _same(existing, event):
				removed = true
				continue
			kept.append(existing)
		if removed:
			InputMap.action_erase_events(action)
			for kept_event in kept:
				InputMap.action_add_event(action, kept_event)


func _same(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


func _save() -> void:
	var data := {}
	for action in actions():
		var encoded: Array = []
		for event in bindings(action):
			var record := _encode(event)
			if not record.is_empty():
				encoded.append(record)
		data[action] = encoded
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for action in parsed:
		if not InputMap.has_action(action) or _hidden(action):
			continue
		var encoded: Array = parsed[action]
		if encoded.is_empty():
			continue
		InputMap.action_erase_events(action)
		for record in encoded:
			var event := _decode(record)
			if event != null:
				InputMap.action_add_event(action, event)


func _encode(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "code": event.physical_keycode}
	if event is InputEventJoypadButton:
		return {"type": "button", "button": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "axis", "axis": event.axis, "value": -1.0 if event.axis_value < 0.0 else 1.0}
	return {}


func _decode(record: Dictionary) -> InputEvent:
	match str(record.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(record.get("code", 0))
			if key.physical_keycode == 0:
				return null
			return key
		"button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(record.get("button", 0))
			return button
		"axis":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(record.get("axis", 0))
			motion.axis_value = float(record.get("value", 1.0))
			return motion
		_:
			return null
