extends Resource
class_name ItemData

enum Slot { WEAPON, ARMOR, ACCESSORY, HELMET, BOOTS, OFFHAND }
enum Rarity { COMMON, UNCOMMON }

@export var display_name: String = ""
@export var icon: Texture2D
@export var slot: Slot = Slot.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var two_handed: bool = false
@export var source_id: String = ""
@export var health_min: int = 0
@export var health_max: int = 0
@export var melee_min: int = 0
@export var melee_max: int = 0
@export var bolt_min: int = 0
@export var bolt_max: int = 0
@export var health_bonus: int = 0
@export var melee_bonus: int = 0
@export var bolt_bonus: int = 0


func roll_copy() -> ItemData:
	var copy := duplicate() as ItemData
	if copy.source_id == "":
		copy.source_id = resource_path
	copy._roll_stats()
	return copy


func kind_id() -> String:
	if source_id != "":
		return source_id
	return resource_path


func _roll_stats() -> void:
	health_bonus = _roll_span(health_min, health_max)
	melee_bonus = _roll_span(melee_min, melee_max)
	bolt_bonus = _roll_span(bolt_min, bolt_max)


func _roll_span(low: int, high: int) -> int:
	if high <= 0:
		return 0
	return randi_range(mini(low, high), maxi(low, high))


func slot_title() -> String:
	match slot:
		Slot.WEAPON:
			return "Weapon"
		Slot.ARMOR:
			return "Armor"
		_:
			return "Accessory"


func bonus_text() -> String:
	if health_bonus != 0:
		return "Health +%d" % health_bonus
	if melee_bonus != 0:
		return "Melee +%d" % melee_bonus
	if bolt_bonus != 0:
		return "Bolt +%d" % bolt_bonus
	return ""


func summary() -> String:
	var bonus := ""
	if health_bonus != 0:
		bonus = "Health +%d" % health_bonus
	elif melee_bonus != 0:
		bonus = "Melee +%d" % melee_bonus
	elif bolt_bonus != 0:
		bonus = "Bolt +%d" % bolt_bonus
	if bonus == "":
		return display_name
	return "%s  %s" % [display_name, bonus]
