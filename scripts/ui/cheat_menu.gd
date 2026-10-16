extends Panel

const GOBLIN_SCENE := preload("res://scenes/enemy/dummy.tscn")
const SHOOTER_SCENE := preload("res://scenes/enemy/shooter.tscn")

var cheat_level := 1


func _ready() -> void:
	for button in [$Level1, $Level3, $Level5, $Goblin, $Shooter, $AddEach]:
		ButtonStyle.apply(button)
	$Level1.pressed.connect(_set_level.bind(1))
	$Level3.pressed.connect(_set_level.bind(3))
	$Level5.pressed.connect(_set_level.bind(5))
	$Goblin.pressed.connect(_spawn.bind(GOBLIN_SCENE, "goblin"))
	$Shooter.pressed.connect(_spawn.bind(SHOOTER_SCENE, "shooter"))
	$AddEach.pressed.connect(_add_one_of_each)
	_paint_levels()
	_build_list()


func _set_level(level: int) -> void:
	cheat_level = level
	_paint_levels()


func _paint_levels() -> void:
	_paint_level($Level1, 1)
	_paint_level($Level3, 3)
	_paint_level($Level5, 5)


func _paint_level(button: Button, level: int) -> void:
	if level == cheat_level:
		ButtonStyle.apply_selected(button)
	else:
		ButtonStyle.apply(button)


func _build_list() -> void:
	var box := $Scroll/List
	var items := _catalog()
	var bucket := -1
	for item in items:
		var next_bucket := _bucket(item)
		if next_bucket != bucket:
			bucket = next_bucket
			box.add_child(_header(_bucket_name(bucket)))
		box.add_child(_row(item))


func _catalog() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for family in Loot.FAMILIES:
		for path in family:
			items.append(load(path))
	items.sort_custom(_before)
	return items


func _before(a: ItemData, b: ItemData) -> bool:
	if _bucket(a) != _bucket(b):
		return _bucket(a) < _bucket(b)
	if a.two_handed != b.two_handed:
		return not a.two_handed
	if _type_rank(a) != _type_rank(b):
		return _type_rank(a) < _type_rank(b)
	if a.display_name != b.display_name:
		return a.display_name.nocasecmp_to(b.display_name) < 0
	return a.rarity < b.rarity


func _bucket(item: ItemData) -> int:
	if item.is_potion():
		return 2
	if item.slot == ItemData.Slot.WEAPON:
		return 0
	return 1


func _bucket_name(bucket: int) -> String:
	if bucket == 0:
		return "Weapons"
	if bucket == 1:
		return "Armor"
	return "Potions"


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


func _header(title: String) -> Label:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	return label


func _row(template: ItemData) -> Button:
	var button := Button.new()
	button.text = _row_title(template)
	button.custom_minimum_size = Vector2(0, 32)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ButtonStyle.apply(button)
	button.pressed.connect(_give.bind(template))
	return button


func _row_title(item: ItemData) -> String:
	if item.is_potion():
		return item.display_name
	var rarity := "Common" if item.rarity == ItemData.Rarity.COMMON else "Uncommon"
	return "%s    %s" % [item.display_name, rarity]


func _give(template: ItemData) -> void:
	if PlayerState.inventory.size() >= 16:
		_status("Inventory full.")
		return
	PlayerState.inventory.append(template.roll_copy())
	PlayerState.changed.emit()


func _add_one_of_each() -> void:
	var added := 0
	for template in _catalog():
		if PlayerState.inventory.size() >= 16:
			break
		if PlayerState.owns(template):
			continue
		PlayerState.inventory.append(template.roll_copy())
		added += 1
	if added > 0:
		PlayerState.changed.emit()
	elif PlayerState.inventory.size() >= 16:
		_status("Inventory full.")


func _spawn(packed: PackedScene, kind: String) -> void:
	var room := get_parent().get_parent()
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
