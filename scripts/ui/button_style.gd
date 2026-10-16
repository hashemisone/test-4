extends RefCounted
class_name ButtonStyle


static func apply(button: Button) -> void:
	_assign(button, Color(1, 1, 1, 1), Color(0.75, 0.86, 0.9, 1), Color(0.58, 0.72, 0.76, 1), Color(0, 0, 0, 1))


static func apply_selected(button: Button) -> void:
	_assign(button, Color(0.12, 0.12, 0.12, 1), Color(0.3, 0.34, 0.36, 1), Color(0.05, 0.05, 0.05, 1), Color(1, 1, 1, 1))


static func _assign(button: Button, normal_fill: Color, hover_fill: Color, pressed_fill: Color, font: Color) -> void:
	button.add_theme_stylebox_override("normal", _box(normal_fill))
	button.add_theme_stylebox_override("hover", _box(hover_fill))
	button.add_theme_stylebox_override("pressed", _box(pressed_fill))
	button.add_theme_stylebox_override("focus", _box(hover_fill))
	button.add_theme_stylebox_override("disabled", _box(normal_fill))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(key, font)


static func _box(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(3)
	style.border_color = Color(0, 0, 0, 1)
	return style
