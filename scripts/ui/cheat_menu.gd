extends Panel

const GOBLIN_SCENE := preload("res://scenes/enemy/dummy.tscn")
const SHOOTER_SCENE := preload("res://scenes/enemy/shooter.tscn")

var cheat_level := 1
var _path: PackedStringArray = []


func _ready() -> void:
	_show_folder()


func reset_folder() -> void:
	_path = PackedStringArray()
	_show_folder()


func _show_folder() -> void:
	$Path.text = "Cheat" if _path.is_empty() else " / ".join(_path)
	var box := $Scroll/List
	for child in box.get_children():
		box.remove_child(child)
		child.free()
	if not _path.is_empty():
		box.add_child(_button("Up", _up))
	if _path.is_empty():
		box.add_child(_button("Enemy", _enter.bind("Enemy")))
		box.add_child(_button("Items", _enter.bind("Items")))
		box.add_child(_button("Money", _enter.bind("Money")))
		box.add_child(_button("Room", _enter.bind("Room")))
		return
	if _path[0] == "Enemy":
		_show_enemies(box)
	elif _path[0] == "Items":
		_show_items(box)
	elif _path[0] == "Money":
		_show_money(box)
	elif _path[0] == "Room":
		_show_rooms(box)


func _show_enemies(box: VBoxContainer) -> void:
	box.add_child(_level_button(1))
	box.add_child(_level_button(3))
	box.add_child(_level_button(5))
	box.add_child(_button("Goblin", _spawn.bind(GOBLIN_SCENE, "goblin")))
	box.add_child(_button("Shooter", _spawn.bind(SHOOTER_SCENE, "shooter")))


func _show_items(box: VBoxContainer) -> void:
	if _path.size() == 1:
		box.add_child(_button("Run", _enter.bind("Run")))
		box.add_child(_button("Kept", _enter.bind("Kept")))
		box.add_child(_button("Add one of each", _add_one_of_each))
		return
	if _path.size() == 2:
		box.add_child(_button("Equipment", _enter.bind("Equipment")))
		box.add_child(_button("Potions", _enter.bind("Potions")))
		return
	var kept := _path[1] == "Kept"
	if _path[2] == "Potions":
		for item in _sorted_items(true, ItemData.Rarity.COMMON):
			box.add_child(_button(item.display_name, _give.bind(item, kept)))
		return
	if _path.size() == 3:
		box.add_child(_button("Common", _enter.bind("Common")))
		box.add_child(_button("Uncommon", _enter.bind("Uncommon")))
		return
	var rarity := ItemData.Rarity.COMMON if _path[3] == "Common" else ItemData.Rarity.UNCOMMON
	for item in _sorted_items(false, rarity):
		box.add_child(_button(item.display_name, _give.bind(item, kept)))


func _show_money(box: VBoxContainer) -> void:
	box.add_child(_button("+1", _add_coins.bind(1)))
	box.add_child(_button("+10", _add_coins.bind(10)))
	box.add_child(_button("+100", _add_coins.bind(100)))


func _add_coins(amount: int) -> void:
	PlayerState.add_coins(amount)


func _show_rooms(box: VBoxContainer) -> void:
	box.add_child(_button("Room 1", _go_room.bind("res://scenes/main.tscn")))
	box.add_child(_button("Room 2", _go_room.bind("res://scenes/room_2.tscn")))
	box.add_child(_button("Room 3", _go_room.bind("res://scenes/room_3.tscn")))


func _go_room(path: String) -> void:
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", path)


func _sorted_items(potions: bool, rarity: ItemData.Rarity) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for family in Loot.FAMILIES:
		for path in family:
			var item := load(path) as ItemData
			if item.is_coin():
				continue
			if item.is_potion() != potions:
				continue
			if not potions and item.rarity != rarity:
				continue
			items.append(item)
	items.sort_custom(_before)
	return items


func _before(a: ItemData, b: ItemData) -> bool:
	if a.slot == ItemData.Slot.WEAPON and b.slot == ItemData.Slot.WEAPON and a.two_handed != b.two_handed:
		return not a.two_handed
	if _type_rank(a) != _type_rank(b):
		return _type_rank(a) < _type_rank(b)
	return a.display_name.nocasecmp_to(b.display_name) < 0


func _type_rank(item: ItemData) -> int:
	match item.slot:
		ItemData.Slot.WEAPON:
			return 0
		ItemData.Slot.HELMET:
			return 1
		ItemData.Slot.ARMOR:
			return 2
		ItemData.Slot.PANTS:
			return 3
		ItemData.Slot.BOOTS:
			return 4
		ItemData.Slot.GLOVES:
			return 5
		ItemData.Slot.CAPE:
			return 6
		ItemData.Slot.BRACELET:
			return 7
		ItemData.Slot.OFFHAND:
			return 8
		ItemData.Slot.ACCESSORY:
			return 9
		_:
			return 10


func _enter(folder: String) -> void:
	_path.append(folder)
	_show_folder.call_deferred()


func _up() -> void:
	if _path.is_empty():
		return
	_path.remove_at(_path.size() - 1)
	_show_folder.call_deferred()


func _level_button(level: int) -> Button:
	var button := _button("Level %d" % level, _set_level.bind(level))
	if level == cheat_level:
		ButtonStyle.apply_selected(button)
	return button


func _set_level(level: int) -> void:
	cheat_level = level
	_show_folder.call_deferred()


func _button(title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 32)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ButtonStyle.apply(button)
	button.pressed.connect(action)
	return button


func _give(template: ItemData, kept: bool) -> void:
	var item := template.roll_copy()
	item.permanent = kept
	if not PlayerState.add_item(item):
		_status("Inventory full.")


func _add_one_of_each() -> void:
	var added := 0
	for rarity in [ItemData.Rarity.COMMON, ItemData.Rarity.UNCOMMON]:
		for template in _sorted_items(false, rarity):
			if PlayerState.owns(template):
				continue
			if not PlayerState.add_item(template.roll_copy()):
				_status("Inventory full.")
				return
			added += 1
	for template in _sorted_items(true, ItemData.Rarity.COMMON):
		if PlayerState.owns(template):
			continue
		if not PlayerState.add_item(template.roll_copy()):
			_status("Inventory full.")
			return
		added += 1
	if added > 0:
		PlayerState.changed.emit()
	elif PlayerState.inventory.size() >= 16:
		_status("Inventory full.")


func _spawn(packed: PackedScene, kind: String) -> void:
	var hud := get_parent()
	if hud == null or hud.get_parent() == null:
		return
	var room := hud.get_parent()
	var player := room.get_node_or_null("Player") as Node2D
	if player == null:
		return
	var enemy = packed.instantiate()
	enemy.level = cheat_level
	var pos := player.position + Vector2(72, 0)
	if pos.x > 560.0:
		pos.x = player.position.x - 72.0
	pos.x += (room.get_tree().get_nodes_in_group("enemy").size() % 4) * 28.0
	enemy.position = pos
	room.add_child(enemy)
	if room.has_method("track_enemy"):
		room.track_enemy(enemy, kind)


func _status(message: String) -> void:
	var hud := get_parent()
	if hud.has_method("show_status"):
		hud.show_status(message)
