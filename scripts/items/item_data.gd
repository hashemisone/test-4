extends Resource
class_name ItemData

enum Slot { WEAPON, ARMOR, ACCESSORY }

@export var display_name: String = ""
@export var slot: Slot = Slot.WEAPON
@export var health_bonus: int = 0
@export var melee_bonus: int = 0
@export var bolt_bonus: int = 0


func slot_title() -> String:
	match slot:
		Slot.WEAPON:
			return "Weapon"
		Slot.ARMOR:
			return "Armor"
		_:
			return "Accessory"


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
