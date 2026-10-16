extends Node

signal changed

const BASE_STATS := preload("res://resources/stats/player_stats.tres")
const SWORD := preload("res://resources/items/sword.tres")
const ARMOR := preload("res://resources/items/armor.tres")
const CHARM := preload("res://resources/items/charm.tres")
const HELMET := preload("res://resources/items/helmet.tres")
const BOOTS := preload("res://resources/items/boots.tres")
const SHIELD := preload("res://resources/items/offhand.tres")
const GREATSWORD := preload("res://resources/items/greatsword.tres")
const SPARE_SWORD := preload("res://resources/items/sword_b.tres")

var inventory: Array[ItemData] = []
var weapon: ItemData
var armor: ItemData
var accessory: ItemData
var helmet: ItemData
var boots: ItemData
var offhand: ItemData
var current_health := 100


func _ready() -> void:
	start_run()


func start_run() -> void:
	weapon = SWORD.roll_copy()
	armor = ARMOR.roll_copy()
	accessory = CHARM.roll_copy()
	helmet = HELMET.roll_copy()
	boots = BOOTS.roll_copy()
	offhand = SHIELD.roll_copy()
	inventory = []
	inventory.append(GREATSWORD.roll_copy())
	inventory.append(SPARE_SWORD.roll_copy())
	current_health = max_health()
	changed.emit()


func max_health() -> int:
	return BASE_STATS.max_health + _bonus("health_bonus")


func melee_damage() -> int:
	return BASE_STATS.melee_damage + _bonus("melee_bonus")


func bolt_damage() -> int:
	return BASE_STATS.bolt_damage + _bonus("bolt_bonus")


func owns(item: ItemData) -> bool:
	if item == null:
		return false
	var kind := item.kind_id()
	for held in [weapon, armor, accessory, helmet, boots, offhand]:
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
	if item == null or owns(item) or inventory.size() >= 9:
		return false
	inventory.append(item)
	changed.emit()
	return true


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
		_:
			return offhand


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
		_:
			offhand = item


func _bonus(property: String) -> int:
	var total := 0
	for item in [weapon, armor, accessory, helmet, boots, offhand]:
		if item != null:
			total += int(item.get(property))
	return total


func _shift_health(old_max: int) -> void:
	var new_max := max_health()
	current_health = clampi(current_health + new_max - old_max, 1, new_max)
