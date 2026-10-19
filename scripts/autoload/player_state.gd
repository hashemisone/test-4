extends Node

signal changed

const BASE_STATS := preload("res://resources/stats/player_stats.tres")
const SWORD := preload("res://resources/items/sword.tres")
const ARMOR := preload("res://resources/items/armor.tres")
const PANTS := preload("res://resources/items/pants.tres")
const HEALTH_POTION := preload("res://resources/items/health_potion.tres")
const ATTACK_POTION := preload("res://resources/items/attack_potion.tres")

var inventory: Array[ItemData] = []
var weapon: ItemData
var armor: ItemData
var accessory: ItemData
var helmet: ItemData
var boots: ItemData
var offhand: ItemData
var cape: ItemData
var pants: ItemData
var bracelet: ItemData
var gloves: ItemData
var current_health := 100
var bonus_health := 0
var bonus_health_left := 0.0
var bonus_melee := 0
var bonus_melee_left := 0.0
var quick_health: ItemData
var quick_attack: ItemData
var coins := 0
var return_to_levels := false
var confirm_destroy := true
var confirm_sell_kept := true
var confirm_sell_equipped := true
var pending_scene := ""
var in_shop := false
var shop_market := false
var shop_refreshes := 0
var shop_stock: Array[ItemData] = []
var market_free_at := 0
var market_paid := 0
var _market_packed: Array = []

const COIN_SAVE := "user://coins.json"
const GEAR_SAVE := "user://permanent.json"
const OPTIONS_SAVE := "user://options.json"
const MARKET_SAVE := "user://market.json"
const MARKET_FREE_WAIT := 3600


func _ready() -> void:
	_load_coins()
	_load_options()
	_load_market()
	_load_permanent()
	start_run()


func start_run() -> void:
	end_run()
	_equip_starter(ItemData.Slot.WEAPON, SWORD)
	_equip_starter(ItemData.Slot.ARMOR, ARMOR)
	_equip_starter(ItemData.Slot.PANTS, PANTS)
	_add_starter_potion(HEALTH_POTION)
	_add_starter_potion(ATTACK_POTION)
	current_health = max_health()
	changed.emit()


func end_run() -> void:
	for slot in _all_slots():
		var worn := item_in_slot(slot)
		if worn != null and not worn.permanent:
			_set_slot(slot, null)
	if quick_health != null and not quick_health.permanent:
		quick_health = null
	if quick_attack != null and not quick_attack.permanent:
		quick_attack = null
	var kept: Array[ItemData] = []
	for item in inventory:
		if item.permanent:
			kept.append(item)
	inventory = kept
	bonus_health = 0
	bonus_health_left = 0.0
	bonus_melee = 0
	bonus_melee_left = 0.0
	current_health = mini(current_health, max_health())
	_save_permanent()
	changed.emit()


func _equip_starter(slot: ItemData.Slot, template: ItemData) -> void:
	if item_in_slot(slot) != null:
		return
	var item := template.lowest_copy()
	item.permanent = false
	_set_slot(slot, item)


func _add_starter_potion(template: ItemData) -> void:
	if _holds_kind(template.kind_id()):
		return
	var item := template.roll_copy()
	item.permanent = false
	add_item(item)


func _holds_kind(kind: String) -> bool:
	for slot in _all_slots():
		var worn := item_in_slot(slot)
		if worn != null and worn.kind_id() == kind:
			return true
	for item in inventory:
		if item.kind_id() == kind:
			return true
	if quick_health != null and quick_health.kind_id() == kind:
		return true
	if quick_attack != null and quick_attack.kind_id() == kind:
		return true
	return false


func _all_slots() -> Array[ItemData.Slot]:
	return [
		ItemData.Slot.WEAPON,
		ItemData.Slot.ARMOR,
		ItemData.Slot.ACCESSORY,
		ItemData.Slot.HELMET,
		ItemData.Slot.BOOTS,
		ItemData.Slot.OFFHAND,
		ItemData.Slot.CAPE,
		ItemData.Slot.PANTS,
		ItemData.Slot.BRACELET,
		ItemData.Slot.GLOVES,
	]


func max_health() -> int:
	return BASE_STATS.max_health + _bonus("health_bonus") + bonus_health


func melee_damage() -> int:
	return BASE_STATS.melee_damage + _bonus("melee_bonus") + bonus_melee


func _process(delta: float) -> void:
	var dirty := false
	if bonus_health_left > 0.0:
		var shown := ceili(bonus_health_left)
		bonus_health_left = maxf(bonus_health_left - delta, 0.0)
		if bonus_health_left == 0.0:
			bonus_health = 0
			current_health = mini(current_health, max_health())
			dirty = true
		elif ceili(bonus_health_left) != shown:
			dirty = true
	if bonus_melee_left > 0.0:
		var melee_shown := ceili(bonus_melee_left)
		bonus_melee_left = maxf(bonus_melee_left - delta, 0.0)
		if bonus_melee_left == 0.0:
			bonus_melee = 0
			dirty = true
		elif ceili(bonus_melee_left) != melee_shown:
			dirty = true
	if dirty:
		changed.emit()


func quick_potion(index: int) -> ItemData:
	return quick_health if index == 0 else quick_attack


func equip_quick_potion(item: ItemData) -> void:
	if item == null or not item.is_potion() or not inventory.has(item):
		return
	var index := 0 if item.heal_amount > 0 else 1
	var current := quick_potion(index)
	inventory.erase(item)
	if current != null and current.kind_id() == item.kind_id() and current.permanent == item.permanent:
		current.stack += item.stack
	else:
		if index == 0:
			quick_health = item
		else:
			quick_attack = item
		if current != null:
			add_item(current)
	_save_permanent()
	changed.emit()


func use_quick_potion(index: int) -> void:
	var item := quick_potion(index)
	if item == null:
		return
	item.stack -= 1
	if item.stack <= 0:
		if index == 0:
			quick_health = null
		else:
			quick_attack = null
	_apply_potion(item)
	_save_permanent()
	changed.emit()


func set_confirm_destroy(enabled: bool) -> void:
	confirm_destroy = enabled
	_save_options()


func set_confirm_sell_kept(enabled: bool) -> void:
	confirm_sell_kept = enabled
	_save_options()


func set_confirm_sell_equipped(enabled: bool) -> void:
	confirm_sell_equipped = enabled
	_save_options()


func roll_shop_stock(kept: bool = false) -> void:
	shop_market = kept
	shop_refreshes = 0
	_fill_shop_stock()


func prepare_market() -> void:
	shop_market = true
	_load_market()
	if _market_free_ready():
		market_free_at = int(Time.get_unix_time_from_system())
		market_paid = 0
		_fill_shop_stock()
		_save_market()
		return
	shop_stock.clear()
	var seen: Array[String] = []
	for entry in _market_packed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item := _unpack_item(entry)
		if item == null or seen.has(_item_name(item)):
			continue
		seen.append(_item_name(item))
		shop_stock.append(item)


func shop_refresh_cost() -> int:
	if shop_market:
		if _market_free_ready():
			return 0
		return (market_paid + 1) * 25
	return shop_refreshes * 5


func refresh_shop_stock() -> bool:
	var cost := shop_refresh_cost()
	if cost > 0 and coins < cost:
		return false
	if cost > 0:
		coins -= cost
		_save_coins()
	if shop_market:
		if cost == 0:
			market_free_at = int(Time.get_unix_time_from_system())
			market_paid = 0
		else:
			market_paid += 1
		_fill_shop_stock()
		_save_market()
	else:
		shop_refreshes += 1
		_fill_shop_stock()
	changed.emit()
	return true


func remember_market_stock() -> void:
	if shop_market:
		_save_market()


func market_free_seconds_left() -> int:
	if market_free_at <= 0:
		return 0
	var left := MARKET_FREE_WAIT - (int(Time.get_unix_time_from_system()) - market_free_at)
	return maxi(left, 0)


func _market_free_ready() -> bool:
	return market_free_seconds_left() <= 0


func _fill_shop_stock() -> void:
	shop_stock.clear()
	var seen: Array[String] = []
	var guard := 0
	while shop_stock.size() < 4 and guard < 80:
		guard += 1
		var item := Loot.roll(1)
		if item.is_coin():
			continue
		var kind := _item_name(item)
		if seen.has(kind):
			continue
		item.permanent = shop_market
		shop_stock.append(item)
		seen.append(kind)


func _item_name(item: ItemData) -> String:
	if item.display_name != "":
		return item.display_name
	return item.kind_id()


func spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	_save_coins()
	changed.emit()
	return true


func destroy_item(item: ItemData, amount: int) -> void:
	if item == null:
		return
	var count := mini(maxi(amount, 0), item.stack)
	if count <= 0:
		return
	if count >= item.stack:
		_forget_item(item)
	else:
		item.stack -= count
	if item.permanent:
		_save_permanent()
	changed.emit()


func _forget_item(item: ItemData) -> void:
	inventory.erase(item)
	if quick_health == item:
		quick_health = null
	if quick_attack == item:
		quick_attack = null
	for slot in _all_slots():
		if item_in_slot(slot) == item:
			_set_slot(slot, null)


func _load_options() -> void:
	confirm_destroy = true
	confirm_sell_kept = true
	confirm_sell_equipped = true
	if not FileAccess.file_exists(OPTIONS_SAVE):
		return
	var file := FileAccess.open(OPTIONS_SAVE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("confirm_destroy"):
		confirm_destroy = bool(parsed["confirm_destroy"])
	if parsed.has("confirm_sell_kept"):
		confirm_sell_kept = bool(parsed["confirm_sell_kept"])
	if parsed.has("confirm_sell_equipped"):
		confirm_sell_equipped = bool(parsed["confirm_sell_equipped"])


func _load_market() -> void:
	market_free_at = 0
	market_paid = 0
	_market_packed = []
	if not FileAccess.file_exists(MARKET_SAVE):
		return
	var file := FileAccess.open(MARKET_SAVE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	market_free_at = int(parsed.get("free_at", 0))
	market_paid = maxi(int(parsed.get("paid", 0)), 0)
	var stock = parsed.get("stock", [])
	if typeof(stock) == TYPE_ARRAY:
		_market_packed = stock


func _save_market() -> void:
	var packed: Array = []
	for item in shop_stock:
		packed.append(_pack_item(item))
	_market_packed = packed
	var file := FileAccess.open(MARKET_SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"free_at": market_free_at,
		"paid": market_paid,
		"stock": packed,
	}))


func _save_options() -> void:
	var file := FileAccess.open(OPTIONS_SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"confirm_destroy": confirm_destroy,
		"confirm_sell_kept": confirm_sell_kept,
		"confirm_sell_equipped": confirm_sell_equipped,
	}))


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	_save_coins()
	changed.emit()


func _load_coins() -> void:
	coins = 0
	if not FileAccess.file_exists(COIN_SAVE):
		return
	var file := FileAccess.open(COIN_SAVE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("coins"):
		coins = maxi(int(parsed["coins"]), 0)


func _pack_item(item: ItemData) -> Dictionary:
	return {
		"path": item.kind_id(),
		"stack": item.stack,
		"health_bonus": item.health_bonus,
		"melee_bonus": item.melee_bonus,
		"bolt_bonus": item.bolt_bonus,
	}


func _unpack_item(data: Dictionary) -> ItemData:
	var path := str(data.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var template := load(path) as ItemData
	if template == null:
		return null
	var item := template.duplicate() as ItemData
	item.source_id = path
	item.permanent = true
	item.stack = maxi(int(data.get("stack", 1)), 1)
	item.health_bonus = int(data.get("health_bonus", item.health_bonus))
	item.melee_bonus = int(data.get("melee_bonus", item.melee_bonus))
	item.bolt_bonus = int(data.get("bolt_bonus", item.bolt_bonus))
	return item


func _save_permanent() -> void:
	var equipped := {}
	for slot in _all_slots():
		var worn := item_in_slot(slot)
		if worn != null and worn.permanent:
			equipped[str(int(slot))] = _pack_item(worn)
	var bag: Array = []
	for item in inventory:
		if item.permanent:
			bag.append(_pack_item(item))
	var body := {
		"equipped": equipped,
		"inventory": bag,
		"quick_health": _pack_item(quick_health) if quick_health != null and quick_health.permanent else null,
		"quick_attack": _pack_item(quick_attack) if quick_attack != null and quick_attack.permanent else null,
	}
	var file := FileAccess.open(GEAR_SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(body))


func _load_permanent() -> void:
	if not FileAccess.file_exists(GEAR_SAVE):
		return
	var file := FileAccess.open(GEAR_SAVE, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for slot in _all_slots():
		_set_slot(slot, null)
	inventory.clear()
	quick_health = null
	quick_attack = null
	var equipped = parsed.get("equipped", {})
	if typeof(equipped) == TYPE_DICTIONARY:
		for slot in _all_slots():
			var record = equipped.get(str(int(slot)), null)
			if typeof(record) == TYPE_DICTIONARY:
				_set_slot(slot, _unpack_item(record))
	var bag = parsed.get("inventory", [])
	if typeof(bag) == TYPE_ARRAY:
		for record in bag:
			if typeof(record) != TYPE_DICTIONARY:
				continue
			var item := _unpack_item(record)
			if item != null and inventory.size() < 16:
				inventory.append(item)
	var health_record = parsed.get("quick_health", null)
	var attack_record = parsed.get("quick_attack", null)
	if typeof(health_record) == TYPE_DICTIONARY:
		quick_health = _unpack_item(health_record)
	if typeof(attack_record) == TYPE_DICTIONARY:
		quick_attack = _unpack_item(attack_record)


func _save_coins() -> void:
	var file := FileAccess.open(COIN_SAVE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"coins": coins}))


func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	if item.is_coin():
		add_coins(item.coin_amount)
		return true
	if item.is_potion():
		for held in inventory:
			if held.is_potion() and held.kind_id() == item.kind_id() and held.permanent == item.permanent:
				held.stack += item.stack
				changed.emit()
				_save_permanent()
				return true
		var equipped := quick_health if item.heal_amount > 0 else quick_attack
		if equipped != null and equipped.kind_id() == item.kind_id() and equipped.permanent == item.permanent:
			equipped.stack += item.stack
			changed.emit()
			return true
	if inventory.size() >= 16:
		return false
	inventory.append(item)
	_save_permanent()
	changed.emit()
	return true


func _apply_potion(item: ItemData) -> void:
	if item.heal_amount > 0:
		var missing := maxi(max_health() - current_health, 0)
		var applied := mini(item.heal_amount, missing)
		var leftover := item.heal_amount - applied
		current_health += applied
		if leftover > 0:
			bonus_health += leftover
			bonus_health_left = item.buff_seconds
			current_health += leftover
	if item.buff_melee > 0:
		bonus_melee = item.buff_melee
		bonus_melee_left = item.buff_seconds


func bolt_damage() -> int:
	return BASE_STATS.bolt_damage + _bonus("bolt_bonus")


func owns(item: ItemData) -> bool:
	if item == null:
		return false
	var kind := item.kind_id()
	for held in [weapon, armor, accessory, helmet, boots, offhand, cape, pants, bracelet, gloves]:
		if _same_kind(held, item, kind):
			return true
	for held in inventory:
		if _same_kind(held, item, kind):
			return true
	return false


func _same_kind(held: ItemData, item: ItemData, kind: String) -> bool:
	if held == null:
		return false
	if held == item:
		return true
	return kind != "" and held.kind_id() == kind


func can_wield_offhand(item: ItemData) -> bool:
	if item == null or item.slot != ItemData.Slot.WEAPON or item.two_handed:
		return false
	return weapon != null and not weapon.two_handed and weapon != item


func collect(item: ItemData) -> bool:
	return add_item(item)


func refill() -> void:
	current_health = max_health()
	changed.emit()


func blocks_offhand() -> bool:
	return weapon != null and weapon.two_handed


func equip(item: ItemData) -> void:
	if item == null:
		return
	equip_to(item, item.slot)


func equip_to(item: ItemData, slot: ItemData.Slot) -> void:
	if item == null:
		return
	if slot == ItemData.Slot.OFFHAND and item.slot == ItemData.Slot.WEAPON:
		if not can_wield_offhand(item):
			return
	elif slot != item.slot:
		return
	if item.slot == ItemData.Slot.OFFHAND and blocks_offhand():
		return
	var old_max := max_health()
	if weapon == item and slot != ItemData.Slot.WEAPON:
		weapon = null
	if offhand == item and slot != ItemData.Slot.OFFHAND:
		offhand = null
	var previous := item_in_slot(slot)
	_set_slot(slot, item)
	inventory.erase(item)
	if previous != null and previous != item:
		inventory.append(previous)
	if item.two_handed and offhand != null:
		var held := offhand
		offhand = null
		inventory.append(held)
	_release_offhand_weapon()
	_shift_health(old_max)
	_save_permanent()
	changed.emit()


func unequip(slot: ItemData.Slot) -> void:
	var previous := item_in_slot(slot)
	if previous == null:
		return
	var old_max := max_health()
	_set_slot(slot, null)
	inventory.append(previous)
	_release_offhand_weapon()
	_shift_health(old_max)
	_save_permanent()
	changed.emit()


func _release_offhand_weapon() -> void:
	if offhand == null or offhand.slot != ItemData.Slot.WEAPON:
		return
	if weapon != null and not weapon.two_handed:
		return
	var held := offhand
	offhand = null
	inventory.append(held)


func item_in_slot(slot: ItemData.Slot) -> ItemData:
	match slot:
		ItemData.Slot.WEAPON:
			return weapon
		ItemData.Slot.ARMOR:
			return armor
		ItemData.Slot.ACCESSORY:
			return accessory
		ItemData.Slot.HELMET:
			return helmet
		ItemData.Slot.BOOTS:
			return boots
		ItemData.Slot.OFFHAND:
			return offhand
		ItemData.Slot.CAPE:
			return cape
		ItemData.Slot.PANTS:
			return pants
		ItemData.Slot.BRACELET:
			return bracelet
		ItemData.Slot.GLOVES:
			return gloves
		_:
			return null


func _set_slot(slot: ItemData.Slot, item: ItemData) -> void:
	match slot:
		ItemData.Slot.WEAPON:
			weapon = item
		ItemData.Slot.ARMOR:
			armor = item
		ItemData.Slot.ACCESSORY:
			accessory = item
		ItemData.Slot.HELMET:
			helmet = item
		ItemData.Slot.BOOTS:
			boots = item
		ItemData.Slot.OFFHAND:
			offhand = item
		ItemData.Slot.CAPE:
			cape = item
		ItemData.Slot.PANTS:
			pants = item
		ItemData.Slot.BRACELET:
			bracelet = item
		ItemData.Slot.GLOVES:
			gloves = item


func _bonus(property: String) -> int:
	var total := 0
	for item in [weapon, armor, accessory, helmet, boots, offhand, cape, pants, bracelet, gloves]:
		if item != null:
			total += int(item.get(property))
	return total


func _shift_health(old_max: int) -> void:
	var new_max := max_health()
	current_health = clampi(current_health + new_max - old_max, 1, new_max)
