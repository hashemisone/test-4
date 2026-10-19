extends Control

signal closed

@export var market := false

var _stock: Array[ItemData] = []
var _pending: ItemData
var _coins: Label
var _status: Label
var _stock_box: VBoxContainer
var _bag_box: VBoxContainer
var _popup: Panel
var _sell_switch: CheckButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	if not PlayerState.changed.is_connected(_refresh):
		PlayerState.changed.connect(_refresh)
	if not market:
		restock()
	else:
		_refresh()


func restock() -> void:
	_stock.clear()
	var guard := 0
	while _stock.size() < 4 and guard < 40:
		guard += 1
		var item := Loot.roll(1)
		if item.is_coin():
			continue
		item.permanent = market
		_stock.append(item)
	_refresh()


func _build() -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if market:
		panel.position = Vector2(16, 16)
		panel.size = Vector2(608, 328)
	else:
		panel.position = Vector2(8, 8)
		panel.size = Vector2(360, 344)
	panel.add_theme_stylebox_override("panel", _frame())
	add_child(panel)
	var title := Label.new()
	title.position = Vector2(12, 8)
	title.size = Vector2(panel.size.x - 24, 28)
	title.text = "Market" if market else "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	panel.add_child(title)
	_coins = Label.new()
	_coins.position = Vector2(12, 38)
	_coins.size = Vector2(panel.size.x - 24, 22)
	_coins.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	panel.add_child(_coins)
	var for_sale := _heading("For sale")
	for_sale.position = Vector2(12, 62)
	panel.add_child(for_sale)
	_stock_box = VBoxContainer.new()
	_stock_box.position = Vector2(12, 86)
	_stock_box.size = Vector2(panel.size.x - 24, 110)
	_stock_box.add_theme_constant_override("separation", 4)
	panel.add_child(_stock_box)
	var bag := _heading("Your bag")
	bag.position = Vector2(12, 200)
	panel.add_child(bag)
	_bag_box = VBoxContainer.new()
	_bag_box.position = Vector2(12, 224)
	_bag_box.size = Vector2(panel.size.x - 24, 80)
	_bag_box.add_theme_constant_override("separation", 4)
	panel.add_child(_bag_box)
	_status = Label.new()
	_status.position = Vector2(12, panel.size.y - 28)
	_status.size = Vector2(panel.size.x - 140, 22)
	_status.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	panel.add_child(_status)
	if market:
		var back := _row_button("Back")
		back.position = Vector2(panel.size.x - 112, panel.size.y - 36)
		back.pressed.connect(_leave)
		panel.add_child(back)
	else:
		var hint := Label.new()
		hint.position = Vector2(12, panel.size.y - 50)
		hint.size = Vector2(panel.size.x - 24, 20)
		hint.text = "The exit on the right continues."
		hint.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		panel.add_child(hint)
	_popup = Panel.new()
	_popup.visible = false
	_popup.z_index = 5
	_popup.position = Vector2(160, 90)
	_popup.size = Vector2(320, 150)
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.add_theme_stylebox_override("panel", _frame())
	add_child(_popup)
	var ask := Label.new()
	ask.position = Vector2(12, 12)
	ask.size = Vector2(296, 28)
	ask.text = "This is a kept item."
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.add_theme_font_size_override("font_size", 18)
	ask.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_popup.add_child(ask)
	var sell_label := Label.new()
	sell_label.position = Vector2(24, 56)
	sell_label.size = Vector2(200, 28)
	sell_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sell_label.text = "Sell kept items"
	sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	sell_label.add_theme_font_size_override("font_size", 16)
	_popup.add_child(sell_label)
	_sell_switch = CheckButton.new()
	_sell_switch.position = Vector2(240, 58)
	_sell_switch.custom_minimum_size = Vector2(24, 24)
	_sell_switch.size = Vector2(24, 24)
	_sell_switch.text = ""
	_sell_switch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_sell_switch.toggled.connect(_on_sell_switch)
	_popup.add_child(_sell_switch)
	var close := _row_button("Close")
	close.position = Vector2(100, 100)
	close.pressed.connect(_close_popup)
	_popup.add_child(close)


func _leave() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	if _coins == null:
		return
	_coins.text = "Coins %d" % PlayerState.coins
	_clear(_stock_box)
	for index in _stock.size():
		var item := _stock[index]
		_stock_box.add_child(_trade_row(item.display_name, "Buy %d" % _buy_price(item), _buy.bind(index)))
	_clear(_bag_box)
	for item in PlayerState.inventory:
		if market and not item.permanent:
			continue
		_bag_box.add_child(_trade_row(_stack_name(item), "Sell %d" % _sell_price(item), _sell.bind(item)))


func _trade_row(item_name: String, action: String, pressed: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = item_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	row.add_child(label)
	var button := _row_button(action)
	button.pressed.connect(pressed)
	row.add_child(button)
	return row


func _row_button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(92, 28)
	button.add_theme_font_size_override("font_size", 13)
	ButtonStyle.apply(button)
	return button


func _buy(index: int) -> void:
	if index < 0 or index >= _stock.size():
		return
	var item := _stock[index]
	var price := _buy_price(item)
	if PlayerState.coins < price:
		_status.text = "Not enough coins."
		return
	if not PlayerState.add_item(item):
		_status.text = "Inventory full."
		return
	PlayerState.spend_coins(price)
	_stock.remove_at(index)
	_status.text = ""
	_refresh()


func _sell(item: ItemData) -> void:
	if item == null or not PlayerState.inventory.has(item):
		_refresh()
		return
	if item.permanent and PlayerState.confirm_sell_kept:
		_pending = item
		_popup.visible = true
		_sell_switch.set_pressed_no_signal(false)
		return
	_complete_sale(item)


func _on_sell_switch(enabled: bool) -> void:
	if not enabled:
		return
	PlayerState.set_confirm_sell_kept(false)
	var item := _pending
	_close_popup()
	if item != null:
		_complete_sale(item)


func _complete_sale(item: ItemData) -> void:
	if item == null or not PlayerState.inventory.has(item):
		return
	var price := _sell_price(item)
	PlayerState.destroy_item(item, 1)
	PlayerState.add_coins(price)
	_status.text = ""
	_refresh()


func _close_popup() -> void:
	_pending = null
	_popup.visible = false


func _buy_price(item: ItemData) -> int:
	return ShopPrices.buy_price(item, market)


func _sell_price(item: ItemData) -> int:
	return ShopPrices.sell_price(item, market)


func _stack_name(item: ItemData) -> String:
	if item.stack > 1:
		return "%s x%d" % [item.display_name, item.stack]
	return item.display_name


func _heading(title: String) -> Label:
	var label := Label.new()
	label.text = title
	label.size = Vector2(200, 20)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	label.add_theme_font_size_override("font_size", 14)
	return label


func _clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.free()


func _frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_border_width_all(4)
	style.border_color = Color(0, 0, 0, 1)
	return style
