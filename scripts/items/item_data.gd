extends Resource
class_name ItemData

enum Slot { WEAPON, ARMOR, ACCESSORY, HELMET, BOOTS, OFFHAND }

@export var display_name: String = ""
@export var icon: Texture2D
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
