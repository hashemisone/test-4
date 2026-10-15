extends Node

signal changed

const BASE_STATS := preload("res://resources/stats/player_stats.tres")
const SWORD := preload("res://resources/items/sword.tres")
const ARMOR := preload("res://resources/items/armor.tres")
const CHARM := preload("res://resources/items/charm.tres")

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
	weapon = null
	armor = null
	accessory = null
	helmet = null
	boots = null
	offhand = null
	inventory = [SWORD, ARMOR, CHARM]
	current_health = max_health()
	changed.emit()


func max_health() -> int:
	return BASE_STATS.max_health + _bonus("health_bonus")


func melee_damage() -> int:
	return BASE_STATS.melee_damage + _bonus("melee_bonus")


func bolt_damage() -> int:
	return BASE_STATS.bolt_damage + _bonus("bolt_bonus")


func refill() -> void:
	current_health = max_health()
	changed.emit()


func equip(item: ItemData) -> void:
	if item == null:
		return
	var old_max := max_health()
	var previous := item_in_slot(item.slot)
	_set_slot(item.slot, item)
	inventory.erase(item)
	if previous != null:
		inventory.append(previous)
	_shift_health(old_max)
	changed.emit()


func unequip(slot: ItemData.Slot) -> void:
	var previous := item_in_slot(slot)
	if previous == null:
		return
	var old_max := max_health()
	_set_slot(slot, null)
	inventory.append(previous)
	_shift_health(old_max)
	changed.emit()


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
